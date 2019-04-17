module Policr
  class VerifyTimeSettingHandler < Handler
    alias TortureTimeType = Cache::TortureTimeType

    @time_type : TortureTimeType?
    @text : String?

    def match(msg)
      role = DB.trust_admin?(msg.chat.id) ? :admin : :creator

      if (user = msg.from) && (text = msg.text) && (reply_msg = msg.reply_to_message) && (reply_msg_id = reply_msg.message_id) && (time_type = Cache.torture_time_msg?(reply_msg_id)) && bot.has_permission?(msg.chat.id, user.id, role)
        @time_type = time_type
        @text = text
      end
    end

    def handle(msg)
      if (time_type = @time_type) && (text = @text)
        sec = case time_type
              when TortureTimeType::Sec
                text.to_i
              when TortureTimeType::Min
                (60 * (text.to_f)).to_i
              end
        DB.set_torture_sec(msg.chat.id, sec)
        bot.reply msg, "已完成设置。"
      end
    end
  end
end
