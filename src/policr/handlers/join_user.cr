module Policr
  class JoinUserHandler < Handler
    alias VerifyStatus = Cache::VerifyStatus

    def match(msg)
      all_pass? [
        DB.enable_examine?(msg.chat.id),
        msg.new_chat_members,
      ]
    end

    def handle(msg)
      chat_id = msg.chat.id

      if (members = msg.new_chat_members) && (halal_message_handler = bot.handlers[:halal_message]?) && halal_message_handler.is_a?(HalalMessageHandler)
        members.select { |m| m.is_bot == false }.each do |member|
          # 管理员拉入，放行
          if (user = msg.from) && (user.id != member.id) && bot.is_admin?(msg.chat.id, user.id)
            if (sended_msg = bot.reply(msg, t("add_from_admin"))) && (message_id = sended_msg.message_id)
              Schedule.after(5.seconds) { bot.delete_message(chat_id, message_id) } unless DB.record_mode?(chat_id)
            end
            return
          end
          # 关联并缓存入群消息
          Cache.associate_join_msg(member.id, msg.chat.id, msg.message_id)
          # 判断清真
          name = bot.display_name(member)
          if halal_message_handler.is_halal(name)
            halal_message_handler.kick_halal_with_receipt(msg, member)
          else
            start_torture(msg, member)
          end
        end
      end
    end

    def add_banned_menu(user_id, username, is_halal = false)
      markup = Markup.new
      markup << Button.new(text: t("baned_menu.unban"), callback_data: "BanedMenu:#{user_id}:#{username}:unban")
      markup << Button.new(text: t("baned_menu.whitelist"), callback_data: "BanedMenu:#{user_id}:#{username}:whitelist") if is_halal
      markup
    end

    AFTER_EVENT_SEC = 60 * 15

    def start_torture(msg, member)
      if (Time.utc.to_unix - msg.date) > AFTER_EVENT_SEC
        # 事后审核不立即验证，采取人工处理
        # 禁言用户
        bot.restrict_chat_member(msg.chat.id, member.id, can_send_messages: false)
        markup = Markup.new
        btn = ->(text : String, item : String) {
          Button.new(text: text, callback_data: "AfterEvent:#{member.id}:#{member.username}:#{item}:#{msg.message_id}")
        }

        markup << [btn.call(t("after_event.torture"), "torture")]
        markup << [btn.call(t("after_event.unban"), "unban"), btn.call(t("after_event.kick"), "kick")]

        bot.send_message(msg.chat.id, t("after_event.tip"), reply_to_message_id: msg.message_id, reply_markup: markup)
      else
        chat_id = msg.chat.id
        msg_id = msg.message_id
        member_id = member.id
        username = member.username
        promptly_torture(chat_id, msg_id, member_id, username)
      end
    end

    def promptly_torture(chat_id, msg_id, member_id, username)
      Cache.verify_init(member_id)
      default =
        {
          1,
          t("questions.title"),
          [
            t("questions.answer_1"),
            t("questions.answer_2"),
          ],
        }
      custom = DB.custom(chat_id)

      _, title, answers = custom ? custom : default

      # 禁言用户
      bot.restrict_chat_member(chat_id, member_id, can_send_messages: false)

      torture_sec = DB.get_torture_sec(chat_id) || DEFAULT_TORTURE_SEC
      question =
        if torture_sec > 0
          t("torture.default_reply", {torture_sec: torture_sec, title: title})
        else
          t("torture.no_time_reply", {title: title})
        end
      reply_id = msg_id

      btn = ->(text : String, chooese_id : Int32) {
        Button.new(text: text, callback_data: "Torture:#{member_id}:#{username}:#{chooese_id}")
      }
      markup = Markup.new
      answer_list = answers.map_with_index { |answer, i| [btn.call(answer, i + 1)] }
      answer_list.shuffle.each { |answer_btn| markup << answer_btn } # 乱序答案列表
      pass_text = t("admin_ope_menu.pass")
      ban_text = t("admin_ope_menu.ban")
      markup << [btn.call(pass_text, 0), btn.call(ban_text, -1)]
      sended_msg = bot.send_message(chat_id, question, reply_to_message_id: reply_id, reply_markup: markup)

      ban_task = ->(message_id : Int32) {
        if Cache.verify?(member_id) == VerifyStatus::Init
          bot.log "User '#{username}' torture time expired and has been banned"
          Cache.verify_slowed(member_id)
          unverified_with_receipt(chat_id, message_id, member_id, username)
        end
      }

      ban_timer = ->(message_id : Int32) { Schedule.after(torture_sec.seconds) { ban_task.call(message_id) } }
      if sended_msg && (message_id = sended_msg.message_id)
        # 存在验证时间，定时任务调用
        ban_timer.call(message_id) if torture_sec > 0
      end
    end

    def unverified_with_receipt(chat_id, message_id, user_id, username, admin = false)
      Cache.verify_status_clear user_id
      bot.log "Username '#{username}' has not been verified and has been banned"
      begin
        bot.kick_chat_member(chat_id, user_id)
      rescue ex : TelegramBot::APIException
        text = t "verify_result.error"
        bot.edit_message_text(chat_id: chat_id, message_id: message_id,
          text: text)
      else
        text = t "verify_result.failure"
        text = t("verify_result.admin_ban") if admin
        bot.edit_message_text(chat_id: chat_id, message_id: message_id,
          text: text, reply_markup: add_banned_menu(user_id, username))
      end
    end
  end
end
