module Policr::Cache
  extend self

  # 运行周期内服务的群组列表
  @@group_list = Hash(Int64, Tuple(String, String)).new

  # 缓存管理员列表
  @@admins = Hash(Int64, Array(TelegramBot::ChatMember)).new

  macro def_carving(msg_type_s)

    {{msg_type_name = "#{msg_type_s.id}_msg"}}

    @@{{msg_type_name.id}} = Set(String).new

    def carving_{{msg_type_name.id}}(chat_id, msg_id)
      @@{{msg_type_name.id}} << "#{chat_id}_#{msg_id}"
    end

    def {{msg_type_name.id}}?(chat_id, msg_id)
      @@{{msg_type_name.id}}.includes? "#{chat_id}_#{msg_id}"
    end
  end

  macro def_carving_with_data(msg_type_s, data_type)

    {{msg_type_name = "#{msg_type_s.id}_msg"}}

    @@{{msg_type_name.id}} = Hash(String, {{data_type.id}}).new

    def carving_{{msg_type_name.id}}(key_1, key_2, data)
      @@{{msg_type_name.id}}["#{key_1}_#{key_2}"] = data
    end

    def {{msg_type_name.id}}?(key_1, key_2)
      @@{{msg_type_name.id}}["#{key_1}_#{key_2}"]?
    end
  end

  # 标记屏蔽内容设置消息
  def_carving "blocked_content"

  # 标记来源调查设置消息
  def_carving "from_setting"

  # 标记欢迎消息设置消息
  def_carving "welcome_setting"

  # 标记验证时间设置消息
  def_carving "torture_time"

  # 标记自定义验证设置消息
  def_carving "custom_setting"

  # 标记长度限制设置消息
  def_carving "max_length"

  # 标记举报详情消息
  def_carving_with_data "report_detail", TelegramBot::User

  # 标记新用户入群消息
  def_carving_with_data "user_join", Int32

  macro def_list(name, type)
    @@{{name.id}}_list = {{type.id}}.new

    def set_{{name.id}}s(data)
      @@{{name.id}}_list = data
    end

    def get_{{name.id}}s
      @@{{name.id}}_list
    end
  
  end

  # 图片（验证）集列表
  def_list "image", Array(Image)

  # 用户验证状态
  @@verification_status = Hash(String, VerificationStatus).new

  macro def_verification_status(status_list)
    {% for status_s in status_list %}
      def verification_{{status_s.id}}(chat_id, user_id)
        @@verification_status["#{chat_id}_#{user_id}"] = VerificationStatus::{{status_s.camelcase.id}}
      end
    {% end %}
  end

  def_verification_status ["passed", "init", "slowed", "next"]

  def verification?(chat_id, user_id)
    @@verification_status["#{chat_id}_#{user_id}"]?
  end

  def verification_status_clear(chat_id, user_id)
    @@verification_status.delete "#{chat_id}_#{user_id}"
  end

  def put_serve_group(chat, bot)
    unless @@group_list[chat.id]?
      username = chat.username
      link = begin
        username ? "t.me/#{username}" : bot.export_chat_invite_link(chat.id).to_s
      rescue e : TelegramBot::APIException
        _, reason = bot.parse_error(e)
        reason.to_s
      end
      @@group_list[chat.id] = {link, "#{chat.title}"}
    end
  end

  def serving_groups
    @@group_list
  end

  def get_admins(chat_id)
    @@admins[chat_id]?
  end

  def set_admins(chat_id, admins)
    @@admins[chat_id] = admins
  end
end
