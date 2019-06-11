module Policr
  class WelcomeCommander < Commander
    def initialize(bot)
      super(bot, "welcome")
    end

    def handle(msg)
      role = DB.trust_admin?(msg.chat.id) ? :admin : :creator
      if (user = msg.from) && bot.has_permission?(msg.chat.id, user.id, role)
        sended_msg = bot.send_message(msg.chat.id, t("welcome.hint"), reply_to_message_id: msg.message_id, disable_web_page_preview: true, parse_mode: "markdown")
        if sended_msg
          Cache.carying_welcome_setting_msg sended_msg.message_id
        end
      else
        bot.delete_message(msg.chat.id, msg.message_id)
      end
    end
  end
end
