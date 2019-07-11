module Policr
  class PrivateForwardCallback < Callback
    def initialize(bot)
      super(bot, "PrivateForward")
    end

    def handle(query, msg, data)
      chat_id = msg.chat.id
      from_user_id = query.from.id
      chooese = data[0]

      message_id = msg.message_id

      case chooese
      when "report"
        if (from_user = query.from) && (reply_msg = msg.reply_to_message) && (target_user = reply_msg.forward_from)
          error_msg = midcall ReportCommander do
            author_id = from_user.id
            target_user_id = target_user.id
            commander.check_legality(author_id, target_user_id)
          end

          if error_msg # 如果举报不合法响应错误
            bot.answer_callback_query(query.id, text: error_msg, show_alert: true)
            return
          end
        end
        markup = Markup.new
        make_btn = ->(text : String, reason : ReportReason) {
          Button.new(text: text, callback_data: "PrivateForwardReport:#{reason.value}")
        }
        markup << [make_btn.call(t("private_forward.spam"), ReportReason::Spam)]
        markup << [make_btn.call(t("private_forward.halal"), ReportReason::Halal)]
        markup << [make_btn.call(t("private_forward.other"), ReportReason::Other)]

        text = t "private_forward.report_reason_chooese"
        bot.edit_message_text(chat_id: chat_id, message_id: message_id,
          text: text, disable_web_page_preview: true, reply_markup: markup, parse_mode: "markdown")
      end
    end
  end
end
