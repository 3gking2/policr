module Policr
  class SettingsCallback < Callback
    NOT_MODIFIED = "Bad Request: message is not modified: specified new message content and reply markup are exactly the same as a current content and reply markup of the message"

    def initialize(bot)
      super(bot, "Settings")
    end

    def handle(query, msg, report)
      chat_id = msg.chat.id
      from_user_id = query.from.id
      name, _ = report

      # 检测权限
      role = DB.trust_admin?(msg.chat.id) ? :admin : :creator
      unless (user = msg.from) && bot.has_permission?(msg.chat.id, from_user_id, role)
        bot.answer_callback_query(query.id, text: t("callback.no_permission"), show_alert: true)
        return
      end

      case name
      when "enable_examine"
        selected = DB.enable_examine?(chat_id)
        selected ? DB.disable_examine(chat_id) : DB.enable_examine(chat_id)
        text = t "settings.desc", {last_change: def_change}
        bot.edit_message_text chat_id: chat_id, message_id: msg.message_id, text: text, disable_web_page_preview: true, parse_mode: "markdown", reply_markup: create_markup(chat_id)
        bot.answer_callback_query(query.id)
      when "trust_admin"
        selected = DB.trust_admin?(chat_id)
        selected ? DB.distrust_admin(chat_id) : DB.trust_admin(chat_id)
        text = t "settings.desc", {last_change: def_change}
        bot.edit_message_text chat_id: chat_id, message_id: msg.message_id, text: text, disable_web_page_preview: true, parse_mode: "markdown", reply_markup: create_markup(chat_id)
        bot.answer_callback_query(query.id)
      when "record_mode"
        selected = DB.record_mode?(chat_id)
        selected ? DB.clean_mode(chat_id) : DB.record_mode(chat_id)
        text = t "settings.desc", {last_change: def_change}
        bot.edit_message_text chat_id: chat_id, message_id: msg.message_id, text: text, disable_web_page_preview: true, parse_mode: "markdown", reply_markup: create_markup(chat_id)
        bot.answer_callback_query(query.id)
      when "enable_from"
        unless DB.get_from(chat_id)
          bot.answer_callback_query(query.id, text: t("settings.not_from"))
          return
        end
        selected = DB.enabled_from?(chat_id)
        selected ? DB.disable_from(chat_id) : DB.enable_from(chat_id)
        text = t "settings.desc", {last_change: def_change}
        bot.edit_message_text chat_id: chat_id, message_id: msg.message_id, text: text, disable_web_page_preview: true, parse_mode: "markdown", reply_markup: create_markup(chat_id)
        bot.answer_callback_query(query.id)
      end
    end

    macro def_change
      (selected ? t("settings.unselected") : t("settings.selected")) + t("settings.#{name}")
    end

    def create_markup(chat_id)
      if (commander = bot.commanders[:settings]?) && (commander.is_a?(SettingsCommander))
        commander.create_markup(chat_id)
      else
        Markup.new
      end
    end
  end
end
