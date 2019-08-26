module Policr
  abstract class Commander
    getter name : String
    getter bot : Bot

    def initialize(bot, name)
      @bot = bot
      @name = name
    end

    macro match(name)
      def initialize(bot)
        @bot = bot
        @name = {{name}}.to_s
      end
    end

    abstract def handle(msg, from_nav : Bool = false)

    BOT_NOT_INIT = "Forbidden: bot can't initiate conversation with a user"
    BOT_BLOCKED  = "Forbidden: bot was blocked by the user"

    CAPTURE_PRIVATE_SETTING_ISSUES = [BOT_NOT_INIT, BOT_BLOCKED]

    macro reply_menu
      _chat_id = msg.chat.id
      _group_id = msg.chat.id
      _reply_msg_id = msg.message_id

      if _chat_id > 0
        unless from_nav 
          bot.send_message _chat_id, text: t("only_group"), reply_to_message_id: _reply_msg_id
          return
        else # 来自导航的私聊，获取 group_id
          if %group_id = Model::PrivateMenu.find_group_id _chat_id, _reply_msg_id
            _group_id = %group_id
          end
        end
      end


      %role = KVStore.enabled_trust_admin?(_group_id) ? :admin : :creator
      if (%user = msg.from) && bot.has_permission?(_group_id, %user.id, %role)
        if KVStore.enabled_privacy_setting?(_group_id)
          _chat_id = %user.id unless from_nav # 私信导航已存在用户 chat_id
          _group_name = msg.chat.title
          _reply_msg_id = nil unless from_nav # 私信导航不需要提示用户已私聊
        end

        unless _reply_msg_id # 私信设置
          spawn bot.delete_message _group_id, msg.message_id
          spawn {
            %sended_msg =  bot.send_message _group_id, text: t("private_settings_sended")
            if %sended_msg
              %msg_id = %sended_msg.message_id
              Schedule.after(3.seconds) { bot.delete_message _group_id, %msg_id }
            end
          }
        end

        begin
          if %sended_msg = {{yield}}
            Model::PrivateMenu.add(_chat_id, 
                                   %sended_msg.message_id,
                                   _group_id,
                                   _group_name) if _chat_id > 0
          end
        rescue %ex : TelegramBot::APIException
          _, %reason = bot.parse_error %ex
          %error_msg = 
            if CAPTURE_PRIVATE_SETTING_ISSUES.includes? %reason
              t "private_setting.contact_me"
            else
              bot.log "Private setting failed: #{%reason}"
              t "private_setting.unknown_reason"
            end
          _chat_id = _group_id

          bot.send_message _chat_id, text: %error_msg
          {{yield}}
        end
      else
        bot.delete_message(_chat_id, msg.message_id)
      end
    end

    macro paste_text
      create_text(_group_id, _group_name)
    end

    macro paste_markup
      create_markup(_group_id, _group_name, from_nav: from_nav)
    end

    macro reply(args)
      bot.send_message(
        _chat_id,
        reply_to_message_id: _reply_msg_id,
        {{**args}}
      )
    end

    macro jump(args)
      bot.edit_message_text(
        _chat_id,
        message_id: msg.message_id,
        {{**args}}
      )
      msg
    end

    macro create_menu(args)
      if from_nav
        jump({{args}})
      else
        reply({{args}})
      end
    end
  end
end
