# 2019-07-18 此文件需要重构！！！

module Policr
  callbacker Torture do
    alias DeleteTarget = CleanDeleteTarget
    alias AntiTarget = AntiMessageDeleteTarget

    def handle(query, msg, report)
      chat_id = msg.chat.id
      from_user_id = query.from.id
      target_id, target_username, chooese, photo = report

      is_photo = photo.to_i == 1
      chooese_i = chooese.to_i
      target_user_id = target_id.to_i
      message_id = msg.message_id

      join_msg_id =
        if reply_msg = msg.reply_to_message
          reply_msg.message_id
        else
          nil
        end

      if chooese_i <= 0 # 管理员菜单

        if bot.is_admin? chat_id, from_user_id
          bot.log "The administrator ended the torture by: #{chooese_i}"
          case chooese_i
          when 0
            passed(query, msg.chat, target_user_id, target_username, message_id, admin: FromUser.new(query.from), photo: is_photo, reply_id: join_msg_id)
          when -1
            failed(chat_id, message_id, target_user_id, target_username, admin: FromUser.new(query.from), photo: is_photo, reply_id: join_msg_id)
          end
        else
          bot.answer_callback_query(query.id, text: t("callback.no_permission"), show_alert: true)
        end
      else
        if target_user_id != from_user_id # 无关人士
          bot.log "Irrelevant User ID '#{from_user_id}' clicked on the verification inline keyboard button"
          bot.answer_callback_query(query.id, text: t("unrelated_warning"), show_alert: true)
          return
        end

        if Model::TrueIndex.contains?(chat_id, msg.message_id, chooese) # 通过验证
          status = Cache.verification?(chat_id, target_user_id)
          unless status
            Cache.verification_init chat_id, target_user_id
            midcall UserJoinHandler do
              spawn bot.delete_message chat_id, message_id
              handler.promptly_torture chat_id, join_msg_id, target_user_id, target_username, re: true
              return
            end
          end
          passed = ->{
            passed(query, msg.chat, target_user_id,
              target_username, message_id,
              photo: is_photo, reply_id: join_msg_id)
          }
          case status
          when VerificationStatus::Init
            if KVStore.enabled_fault_tolerance?(chat_id) && !KVStore.custom(chat_id) # 容错模式处理
              if Model::ErrorCount.counting(chat_id, target_user_id) > 0             # 继续验证
                Cache.verification_next chat_id, target_user_id                      # 更新验证状态避免超时
                Model::ErrorCount.destory chat_id, target_user_id                    # 销毁错误记录
                midcall UserJoinHandler do
                  spawn bot.delete_message chat_id, message_id
                  handler.promptly_torture chat_id, join_msg_id, target_user_id, target_username, re: true
                  return
                end
              else
                passed.call
              end
            else
              passed.call
            end
          when VerificationStatus::Next
            if Model::ErrorCount.counting(chat_id, target_user_id) > 0 # 继续验证
              Cache.verification_next chat_id, target_user_id          # 更新验证状态避免超时
              Model::ErrorCount.destory chat_id, target_user_id        # 销毁错误记录
              midcall UserJoinHandler do
                spawn bot.delete_message chat_id, message_id
                handler.promptly_torture chat_id, join_msg_id, target_user_id, target_username, re: true
                return
              end
            else
              passed.call
            end
          when VerificationStatus::Slowed
            slow_with_receipt(query, chat_id, target_user_id, target_username, message_id)
          end
        else                                                                       # 未通过验证
          if KVStore.enabled_fault_tolerance?(chat_id) && !KVStore.custom(chat_id) # 容错模式处理
            fault_tolerance chat_id, target_user_id, message_id, query.id, target_username, join_msg_id, is_photo
          else
            bot.log "Username '#{target_username}' did not pass verification"
            bot.answer_callback_query(query.id, text: t("no_pass_alert"), show_alert: true)
            failed(chat_id, message_id, target_user_id, target_username, photo: is_photo, reply_id: join_msg_id)
          end
        end
      end
    end

    def fault_tolerance(chat_id, user_id, message_id, query_id, username, join_msg_id, is_photo)
      count = Model::ErrorCount.counting chat_id, user_id
      if count == 0                                 # 继续验证
        Cache.verification_next chat_id, user_id    # 更新验证状态避免超时
        Model::ErrorCount.one_time chat_id, user_id # 错误次数加一
        midcall UserJoinHandler do
          spawn bot.delete_message chat_id, message_id
          handler.promptly_torture chat_id, join_msg_id, user_id, username, re: true
          return
        end
      else # 验证失败
        bot.log "User '#{user_id}' did not pass verification"
        bot.answer_callback_query(query_id, text: t("no_pass_alert"), show_alert: true)
        failed(chat_id, message_id, user_id, username, photo: is_photo, reply_id: join_msg_id)
      end
    end

    def passed(query : TelegramBot::CallbackQuery,
               chat : TelegramBot::Chat,
               target_user_id : Int32,
               target_username : String,
               message_id : Int32,
               admin : FromUser? = nil,
               photo = false,
               reply_id : Int32? = nil)
      chat_id = chat.id

      Cache.verification_passed chat_id, target_user_id # 更新验证状态
      Model::ErrorCount.destory chat_id, target_user_id # 销毁错误记录
      # 异步调用
      spawn bot.answer_callback_query(query.id, text: t("pass_alert")) unless admin

      unless KVStore.enabled_welcome? chat_id
        text =
          if admin
            t("pass_by_admin", {user_id: target_user_id, admin: admin.markdown_link})
          else
            t("pass_by_self", {user_id: target_user_id})
          end

        if photo
          spawn bot.delete_message chat_id, message_id
          spawn {
            sended_msg = bot.send_message(
              chat_id,
              text: text,
              reply_to_message_id: reply_id,
              reply_markup: nil
            )

            if sended_msg && !KVStore.enabled_record_mode?(chat_id)
              msg_id = sended_msg.message_id
              Schedule.after(5.seconds) { bot.delete_message(chat_id, msg_id) }
            end
          }
        else
          spawn {
            bot.edit_message_text(
              chat_id,
              message_id: message_id,
              text: text,
              reply_markup: nil
            )

            unless KVStore.enabled_record_mode?(chat_id)
              Schedule.after(5.seconds) { bot.delete_message(chat_id, message_id) }
            end
          }
        end
      else
        bot.send_welcome chat, message_id, FromUser.new(query.from), photo, reply_id
      end
      # 初始化用户权限
      spawn bot.restrict_chat_member(chat_id, target_user_id, can_send_messages: true, can_send_media_messages: true, can_send_other_messages: true, can_add_web_page_previews: true)
      is_enabled_from = KVStore.enabled_from? chat_id
      # 删除入群消息
      if !is_enabled_from && (_delete_msg_id = reply_id)
        Model::AntiMessage.working chat_id, AntiTarget::JoinGroup do
          bot.delete_message(chat_id, _delete_msg_id)
        end
      end

      # 来源调查
      from_enquire(chat_id, message_id, target_username, target_user_id) if is_enabled_from
    end

    def from_enquire(chat_id, message_id, username, user_id)
      if from_list = KVStore.get_from(chat_id)
        index = -1
        btn = ->(text : String) {
          Button.new(text: text, callback_data: "From:#{user_id}:#{username}:#{index += 1}")
        }
        markup = Markup.new
        from_list.each do |btn_text_list|
          markup << btn_text_list.map { |text| btn.call(text) }
        end
        reply_to_message_id = Cache.user_join_msg? user_id, chat_id
        sended_msg = bot.send_message(
          chat_id,
          text: t("from.question"),
          reply_to_message_id: reply_to_message_id,
          reply_markup: markup
        )
        # 根据干净模式数据延迟清理来源调查
        if sended_msg
          msg_id = sended_msg.message_id
          Model::CleanMode.working(chat_id, DeleteTarget::From) { bot.delete_message(chat_id, msg_id) }
        end
        # 清理入群消息
        if _delete_msg_id = reply_to_message_id
          Model::AntiMessage.working chat_id, AntiTarget::JoinGroup do
            bot.delete_message(chat_id, _delete_msg_id)
          end
        end
      end
    end

    private def slow_with_receipt(query, chat_id, target_user_id, target_username, message_id)
      bot.log "Username '#{target_username}' verification is a bit slower"

      # 异步调用
      spawn bot.answer_callback_query(query.id, text: t("pass_slow_alert"))
      spawn { bot.edit_message_text(
        chat_id,
        message_id: message_id,
        text: t("pass_slow_receipt"),
        reply_markup: nil
      ) }
      bot.unban_chat_member(chat_id, target_user_id)
    end

    def failed(chat_id, message_id, user_id, username, admin : FromUser? = nil, timeout = false, photo = false, reply_id : Int32? = nil)
      Model::ErrorCount.destory chat_id, user_id # 销毁错误记录
      midcall UserJoinHandler do
        handler.failed(chat_id, message_id, user_id, username, admin: admin, timeout: timeout, photo: photo, reply_id: reply_id)
      end
    end
  end
end
