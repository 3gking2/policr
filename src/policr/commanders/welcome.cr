module Policr
  commander Welcome do
    def handle(msg, from_nav)
      reply_menu do
        sended_msg = create_menu({
          text:         paste_text,
          reply_markup: paste_markup,
        })

        if sended_msg
          Cache.carving_welcome_setting_msg _chat_id, sended_msg.message_id
        end

        sended_msg
      end
    end

    def_text do
      welcome_text =
        if welcome = KVStore.get_welcome(_group_id)
          welcome
        else
          t "welcome.none"
        end

      t("welcome.hint", {welcome_text: welcome_text})
    end

    SELECTED   = "■"
    UNSELECTED = "□"

    def_markup do
      make_status = ->(name : String) {
        case name
        when "disable_link_preview"
          KVStore.disabled_welcome_link_preview?(_group_id) ? SELECTED : UNSELECTED
        when "welcome"
          KVStore.enabled_welcome?(_group_id) ? SELECTED : UNSELECTED
        else
          UNSELECTED
        end
      }
      make_btn = ->(text : String, name : String) {
        Button.new(text: text, callback_data: "Welcome:#{name}")
      }

      _markup << def_btn_list ["welcome", "disable_link_preview"]
    end

    macro def_btn_list(list)
      [
      {% for name in list %}
        make_btn.call(make_status.call({{name}}) + " " + t("welcome.{{name.id}}"), {{name}}),
      {% end %}
      ]
    end
  end
end
