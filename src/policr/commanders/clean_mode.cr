module Policr
  commander CleanMode do
    alias DeleteTarget = CleanDeleteTarget

    def handle(msg, from_nav)
      reply_menu do
        create_menu({
          text:         paste_text,
          reply_markup: paste_markup,
        })
      end
    end

    MORE_SYMBOL = "»"
    SELECTED    = "■"
    UNSELECTED  = "□"

    def_markup do
      btn = ->(text : String, name : String) {
        Button.new(text: text, callback_data: "CleanMode:#{name}")
      }
      symbol = ->(delete_target : DeleteTarget) {
        cm = Model::CleanMode.where { (_chat_id == _group_id) & (_delete_target == delete_target.value) }.first
        if cm
          cm.status == EnableStatus::TurnOn.value ? SELECTED : UNSELECTED
        else
          UNSELECTED
        end
      }
      def_button_list ["timeout_verified", "wrong_verified", "welcome", "from", "halal", "report"]
    end

    def_text do
      t("clean_mode.desc")
    end

    macro def_button_list(target_list)
      {% for target_s in target_list %}
        {{ delete_target = target_s.camelcase }}
        _markup << 
        [
         btn.call("#{symbol.call(DeleteTarget::{{delete_target.id}})} #{t("clean_mode.{{target_s.id}}")}", {{target_s}}),
         btn.call("#{t("clean_mode.delay_time")} #{MORE_SYMBOL}", "{{target_s.id}}_delay_time")
        ]
      {% end %}
    end
  end
end
