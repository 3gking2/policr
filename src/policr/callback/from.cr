module Policr
  class FromCallback < Callback
    def initialize(bot)
      super(bot, "From")
    end

    def handle(query, msg, report)
      chat_id = msg.chat.id
      from_user_id = query.from.id
      target_id, target_username, chooese = report

      chooese_id = chooese.to_i
      target_user_id = target_id.to_i
      message_id = msg.message_id

      unless from_user_id == target_user_id
        bot.log "Unrelated User ID '#{from_user_id}' click to From Investigate button"
        bot.answer_callback_query(query.id, text: t("unrelated_click"), show_alert: true)
        return
      end

      bot.log "Username '#{target_username}' has selected from: #{chooese_id}"

      all_from = Array(String).new
      if from_list = DB.get_chat_from(chat_id)
        from_list.each do |btn_list|
          btn_list.each { |btn_text| all_from << btn_text }
        end
      end
      bot.edit_message_text(chat_id: chat_id, message_id: message_id,
        text: t("from", {from: all_from[chooese_id]?}))
    end
  end
end
