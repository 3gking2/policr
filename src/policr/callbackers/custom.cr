module Policr
  callbacker Custom do
    NOT_MODIFIED = "Bad Request: message is not modified: specified new message content and reply markup are exactly the same as a current content and reply markup of the message"

    def handle(query, msg, data)
      target_group do
        way = data[0]

        case way
        when "default"
          KVStore.default _group_id
          text = t "captcha.default"
          bot.edit_message_text(
            _chat_id,
            message_id: msg.message_id,
            text: text(_group_id, text, group_name: _group_name),
            reply_markup: create_markup(_group_id)
          )
          bot.answer_callback_query(query.id)
        when "dynamic"
          KVStore.enable_dynamic_captcha _group_id
          text = t "captcha.dynamic"
          bot.edit_message_text(
            _chat_id,
            message_id: msg.message_id,
            text: text(_group_id, text, group_name: _group_name),
            reply_markup: create_markup(_group_id)
          )
          bot.answer_callback_query(query.id)
        when "image"
          back_to_default = ->{
            KVStore.disable_image_captcha _group_id
            text = t "captcha.switch_image_failed"
            spawn {
              bot.edit_message_text(
                _chat_id,
                message_id: msg.message_id,
                text: text(_group_id, text, group_name: _group_name),
                reply_markup: create_markup(_group_id)
              )
            }
          }
          # 前提1：数据集数量大于等于3
          if Cache.get_images.size < 3
            back_to_default.call
            bot.answer_callback_query query.id, text: "服务器没有足够的图片数据集，已被禁用", show_alert: true
            return
          end
          # 前提2：验证时间要大于1分半钟
          torture_sec =
            if sec = KVStore.get_torture_sec _group_id
              sec
            else
              DEFAULT_TORTURE_SEC
            end
          if torture_sec > 0 && torture_sec < 90
            back_to_default.call
            bot.answer_callback_query query.id, text: "验证时间必须大于1分半钟", show_alert: true
            return
          end

          KVStore.enable_image_captcha _group_id
          text = t "captcha.image"
          bot.edit_message_text(
            _chat_id,
            message_id: msg.message_id,
            text: text(_group_id, text, group_name: _group_name),
            reply_markup: create_markup(_group_id)
          )
          bot.answer_callback_query(query.id)
        when "chessboard"
          KVStore.enable_chessboard_captcha _group_id
          text = t "captcha.chessboard"
          bot.edit_message_text(
            _chat_id,
            message_id: msg.message_id,
            text: text(_group_id, text, group_name: _group_name),
            reply_markup: create_markup(_group_id)
          )
          bot.answer_callback_query(query.id)
        when "custom"
          # 缓存此消息
          Cache.carving_custom_setting_msg _chat_id, msg.message_id

          begin
            bot.edit_message_text(
              _chat_id,
              message_id: msg.message_id,
              text: custom_text(_group_id, _group_name),
              reply_markup: create_markup(_group_id)
            )
            bot.answer_callback_query(query.id)
          rescue e : TelegramBot::APIException
            _, reason = bot.parse_error e
            bot.answer_callback_query(query.id, text: t("custom.reply_hint")) if reason == NOT_MODIFIED
          end
        end
      end
    end

    def_text text, text do
      text
    end

    def create_markup(group_id)
      midcall CustomCommander do
        _commander.create_markup(group_id)
      end
    end

    def custom_text(group_id, group_name)
      midcall CustomCommander do
        _commander.custom_text group_id, group_name
      end
    end
  end
end
