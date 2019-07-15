module Policr
  class ReportCallback < Callback
    alias Reason = ReportReason
    alias Status = ReportStatus
    alias UserRole = ReportUserRole

    TARGET_MSG_NOT_EXISTS = "Bad Request: MESSAGE_ID_INVALID"

    def initialize(bot)
      super(bot, "Report")
    end

    def handle(query, msg, data)
      chat_id = msg.chat.id
      from_user_id = query.from.id

      author_id, target_user_id, target_msg_id, reason_value = data
      author_id = author_id.to_i
      target_user_id = target_user_id.to_i
      target_msg_id = target_msg_id.to_i
      reason_value = reason_value.to_i

      unless from_user_id == author_id.to_i
        bot.answer_callback_query(query.id, text: t("unrelated_warning"), show_alert: true)
        return
      end

      make_report chat_id, msg.message_id, target_msg_id, target_user_id, from_user_id, reason_value, query: query
    end

    def make_report(chat_id, msg_id, target_msg_id, target_user_id, from_user_id, reason_value, query : TelegramBot::CallbackQuery? = nil)
      # 转发举报消息
      begin
        snapshot_message = bot.forward_message(
          chat_id: "@#{bot.snapshot_channel}",
          from_chat_id: chat_id,
          message_id: target_msg_id
        )
      rescue e : TelegramBot::APIException
        _, reason = bot.parse_error(e)
        reason =
          case reason
          when TARGET_MSG_NOT_EXISTS
            t "report.message_not_exists"
          else
            reason
          end
        err_msg = t("report.forward_error", {reason: reason})
        if query
          bot.answer_callback_query(query.id, text: err_msg)
        else
          bot.send_message chat_id, err_msg, reply_to_message_id: msg_id
        end
        return
      end

      # 并获得举报人角色
      role =
        if bot.is_admin?(chat_id, from_user_id)
          if bot.has_permission?(chat_id, from_user_id, :creator, dirty: false)
            UserRole::Creator
          elsif KVStore.trust_admin?(chat_id) # 受信管理员
            UserRole::TrustedAdmin
          else
            UserRole::Admin
          end
        elsif is_private_chat?(chat_id)
          UserRole::Unknown
        else
          UserRole::Member
        end

      # 生成举报并入库
      if snapshot_message
        begin
          data =
            {
              author_id:          from_user_id.to_i64,
              post_id:            0, # 临时 post id，举报消息发布以后更新
              target_snapshot_id: snapshot_message.message_id,
              target_user_id:     target_user_id.to_i64,
              target_msg_id:      target_msg_id,
              reason:             reason_value,
              status:             Status::Begin.value,
              role:               role.value,
              from_chat_id:       chat_id.to_i64,
            }
          r = Model::Report.create!(data)
        rescue e : Exception
          bot.log "Save reporting data failed: #{e.message}"
          err_msg = t("report.storage_error")
          if query
            bot.answer_callback_query(query.id, text: err_msg)
          else
            bot.send_message chat_id, err_msg, reply_to_message_id: msg_id
          end
          return
        end
      end
      # 生成投票
      if r
        text = make_text(r.author_id, r.role, r.target_snapshot_id, target_user_id, r.reason, r.status, nil)

        report_id = r.id
        markup = Markup.new
        make_btn = ->(text : String, voting_type : String) {
          Button.new(text: text, callback_data: "Voting:#{report_id}:#{voting_type}")
        }
        markup << [
          make_btn.call("👍", "agree"),
          make_btn.call("🙏", "abstention"),
          make_btn.call("👎", "oppose"),
        ]
        begin
          voting_msg = bot.send_message "@#{bot.voting_channel}", text, reply_markup: markup
        rescue e : TelegramBot::APIException
          # 回滚已入库的举报
          Model::Report.delete(r.id)
          _, reason = bot.parse_error(e)
          err_msg = t("report.generate_voting_error", {reason: reason})
          if query
            bot.answer_callback_query(query.id, text: err_msg)
          else
            bot.send_message chat_id, err_msg, reply_to_message_id: msg_id
          end
          return
        end
      end

      # 响应举报生成结果
      if voting_msg && r
        r.update_column(:post_id, voting_msg.message_id) # 更新举报消息 ID
        text = t "report.generated", {
          voting_channel:    bot.voting_channel,
          voting_message_id: voting_msg.message_id,
          user_id:           from_user_id,
        }
        begin
          bot.edit_message_text(
            chat_id: chat_id,
            message_id: msg_id,
            text: text,
            disable_web_page_preview: true,
            parse_mode: "markdown"
          )
        rescue e : TelegramBot::APIException
          # 回滚已入库的举报
          Model::Report.delete(r.id)
          # 回滚已转发的快照
          voting_msg_id = voting_msg.message_id
          spawn { bot.delete_message bot.voting_channel, voting_msg_id }
          _, reason = bot.parse_error(e)
          err_msg = t("report.update_result_error", {reason: reason})
          if query
            bot.answer_callback_query(query.id, text: err_msg)
          else
            bot.send_message chat_id, err_msg, reply_to_message_id: msg_id
          end
          return
        end

        # 若举报人具备权限，删除消息并封禁用户
        if role == UserRole::Creator || role == UserRole::TrustedAdmin || role == UserRole::Admin
          spawn bot.delete_message(chat_id, target_msg_id)
          spawn bot.kick_chat_member(chat_id, target_user_id)
        end
      end
    end

    def make_text(authod_id, role_value, snapshot_id, target_id, reason_value, status_value, detail : String?)
      inject_data = {
        author_id: authod_id,
        role:      make_role(role_value),
        snapshot:  make_snapshot(snapshot_id),
        target_id: target_id,
        reason:    make_reason(reason_value),
        status:    make_status(status_value),
        detail:    detail ? "\n\n#{detail}\n" : "无",
      }
      t "report.voting_message", inject_data
    end

    def make_role(role_value)
      case UserRole.new(role_value)
      when UserRole::Unknown
        t("report.role.unknown")
      when UserRole::Creator
        t("report.role.creator")
      when UserRole::TrustedAdmin
        t("report.role.trusted_admin")
      when UserRole::Admin
        t("report.role.admin")
      when UserRole::Member
        t("report.role.member")
      end
    end

    def make_reason(reason_value)
      case Reason.new(reason_value)
      when Reason::Unknown
        t("report.reason.unknown")
      when Reason::Spam
        t("report.reason.spam")
      when Reason::Halal
        t("report.reason.halal")
      when Reason::Other
        t("report.reason.other")
      end
    end

    def make_status(status_value)
      case Status.new(status_value)
      when Status::Unknown
        t("report.status.unknown")
      when Status::Begin
        t("report.status.begin")
      when Status::Reject
        t("report.status.reject")
      when Status::Accept
        t("report.status.accept")
      when Status::Unban
        t("report.status.unban")
      end
    end

    def make_snapshot(snapshot_id)
      if snapshot_id != 0
        "[#{snapshot_id}](https://t.me/#{bot.snapshot_channel}/#{snapshot_id})"
      else
        "无"
      end
    end
  end
end
