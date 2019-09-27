module Policr
  callbacker BlockRule do
    alias BlockRule = Model::BlockRule

    def handle(query, msg, data)
      chat_id = msg.chat.id
      msg_id = msg.message_id

      action, id = data
      id = id.to_i

      rule = BlockRule.find id

      if rule == nil
        bot.answer_callback_query(query.id, text: "没有找到这条规则～", show_alert: true)
        return
      end

      rule = rule.not_nil!

      role = Model::Toggle.trusted_admin?(rule.chat_id) ? :admin : :creator
      unless bot.has_permission?(rule.chat_id, query.from.id, role)
        bot.answer_callback_query(query.id, text: "您没有权限操作此内容～", show_alert: true)
        return
      end

      case action
      when "delete"
        BlockRule.delete id

        async_response

        bot.delete_message chat_id, msg_id
      when "enable"
        # 检测规则合法性
        begin
          RuleEngine.parse! rule.expression
        rescue e : Exception
          bot.answer_callback_query(query.id, text: "规则不合法，启用失败～", show_alert: true)
          return
        end
        BlockRule.enable! rule.id
        updated_text, updated_markup = updated_preview_settings rule.reload

        async_response

        bot.edit_message_text(
          chat_id,
          message_id: msg_id,
          text: updated_text,
          reply_markup: updated_markup
        )
      when "disable"
        BlockRule.disable rule.id
        updated_text, updated_markup = updated_preview_settings rule.reload

        async_response

        bot.edit_message_text(
          chat_id,
          message_id: msg_id,
          text: updated_text,
          reply_markup: updated_markup
        )
      else
        invalid_keyboard
      end
    end

    def updated_preview_settings(block_content)
      midcall StartCommander do
        {
          _commander.create_block_rule_text(block_content),
          _commander.create_block_rule_markup(block_content),
        }
      end || {nil, nil}
    end
  end
end
