module Policr
  class TokenCommander < Commander
    def initialize(bot)
      super(bot, "token")
    end

    def handle(msg)
      if msg.chat.type != "private"
        bot.reply msg, "only_private"
        return
      end

      if (user = msg.from) && (groups = DB.managed_groups(user.id))
        token = DB.gen_token(user.id)

        bot.send_message(msg.chat.id, "`#{token}`", parse_mode: "markdown")
      else
        bot.send_message(msg.chat.id, t("no_managed_groups"))
      end
    end
  end
end
