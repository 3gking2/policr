module Policr
  commander Report do
    alias Reason = ReportReason

    FILE_EXCLUDES = [".gif", ".mp4"]

    def self.is_file?(reply_msg : TelegramBot::Message)
      (doc = reply_msg.document) &&
        (filename = doc.file_name) &&
        !FILE_EXCLUDES.includes?(File.extname(filename))
    end

    def handle(msg)
      if (user = msg.from) && (reply_msg = msg.reply_to_message) && (target_user = reply_msg.from)
        author_id = user.id
        target_user_id = target_user.id
        target_msg_id = reply_msg.message_id
        chat_id = msg.chat.id

        if error_msg = check_legality(author_id, target_user_id)
          bot.send_message chat_id, error_msg, reply_to_message_id: msg.message_id
          return
        end

        # 创建举报原因内联键盘
        markup = Markup.new
        btn = ->(text : String, reason : ReportReason) {
          Button.new(text: text, callback_data: "Report:#{author_id}:#{target_user_id}:#{target_msg_id}:#{reason.value}")
        }

        if ReportCommander.is_file? reply_msg
          markup << [btn.call(t("report.virus_file"), Reason::VirusFile)]
          markup << [btn.call(t("report.promo_file"), Reason::PromoFile)]
        else
          markup << [btn.call(t("report.mass_ad"), Reason::MassAd)]
          markup << [btn.call(t("report.halal"), Reason::Halal)]
          markup << [btn.call(t("report.hateful"), Reason::Hateful)]
          markup << [btn.call(t("report.adname"), Reason::Adname)]
        end

        text = t "report.admin_reply", {user_id: target_user_id, voting_channel: bot.voting_channel}
        bot.send_message(
          msg.chat.id,
          text: text,
          reply_to_message_id: msg.message_id,
          reply_markup: markup
        )
        # 缓存被举报用户
        Cache.carving_report_target_msg chat_id, target_msg_id, target_user
      else
        bot.delete_message(msg.chat.id, msg.message_id)
      end
    end

    def check_legality(author_id, target_user_id)
      if author_id == target_user_id # 不能举报自己
        t "report.author_cant_self"
      elsif target_user_id == bot.self_id # 不能举报本机器人
        t "report.target_user_cant_the_bot"
      elsif target_user_id == 777000 # 举报目标用户无效
        t "report.target_user_invalid"
      end
    end
  end
end
