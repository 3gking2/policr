module Policr
  class WelcomeSettingHandler < Handler
    allow_edit # 处理编辑消息

    @reply_msg_id : Int32?

    def match(msg)
      role = KVStore.trust_admin?(msg.chat.id) ? :admin : :creator

      all_pass? [
        (user = msg.from),
        (reply_msg = msg.reply_to_message),
        (@reply_msg_id = reply_msg.message_id),
        Cache.welcome_setting_msg?(msg.chat.id, @reply_msg_id), # 回复目标为设置欢迎消息指令？
        bot.has_permission?(msg.chat.id, user.id, role),
      ]
    end

    def handle(msg)
      if reply_msg_id = @reply_msg_id
        chat_id = msg.chat.id

        KVStore.set_welcome(msg.chat.id, msg.text)

        updated_text, updated_markup = updated_settings_preview(chat_id)
        spawn { bot.edit_message_text(
          chat_id,
          message_id: reply_msg_id,
          text: updated_text,
          reply_markup: updated_markup
        ) }

        setting_complete_with_delay_delete msg
      end
    end

    def updated_settings_preview(chat_id)
      midcall WelcomeCommander do
        {_commander.text(chat_id), _commander.markup(chat_id)}
      end || {nil, nil}
    end
  end
end
