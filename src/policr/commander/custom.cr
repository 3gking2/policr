module Policr
  class CustomCommander < Commander
    def initialize(bot)
      super(bot, "custom")
    end

    def handle(msg)
      role = DB.trust_admin?(msg.chat.id) ? :admin : :creator
      if (user = msg.from) && bot.has_permission?(msg.chat.id, user.id, role)
        sended_msg = bot.send_message(msg.chat.id, t("custom.reply_tip"), reply_to_message_id: msg.message_id, parse_mode: "markdown")
        if sended_msg
          Cache.carying_custom_msg sended_msg.message_id
        end
      else
        bot.delete_message(msg.chat.id, msg.message_id)
      end
    end
  end
end
