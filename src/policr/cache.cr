module Policr::Cache
  extend self

  enum VerifyStatus
    Init; Pass; Slow
  end

  @@torture_time_msg = Hash(Int32, TortureTimeType).new
  @@from_setting_msg = Set(Int32).new
  @@verify_status = Hash(Int32, VerifyStatus).new
  @@custom_msg = Set(Int32).new
  @@new_join_user_msg = Hash(String, Int32).new
  # 运行周期内服务的群组列表
  @@group_list = Hash(Int64, Tuple(String, String)).new
  # 动态问题缓存，正确答案与消息关联
  @@dynamic_list = Hash(String, Int32).new
  # 欢迎消息设置缓存
  @@welcome_setting_msg = Set(Int32).new
  # 图片（验证）集列表
  @@image_list = Array(Image).new

  def carving_torture_time_msg_sec(message_id)
    @@torture_time_msg[message_id] = TortureTimeType::Sec
  end

  def torture_time_msg?(message_id)
    @@torture_time_msg[message_id]?
  end

  # 此类方法日后使用宏生成

  def carying_from_setting_msg(message_id)
    @@from_setting_msg << message_id
  end

  def from_setting_msg?(message_id)
    @@from_setting_msg.includes? message_id
  end

  def carying_welcome_setting_msg(message_id)
    @@welcome_setting_msg << message_id
  end

  def welcome_setting_msg?(message_id)
    @@welcome_setting_msg.includes? message_id
  end

  def carying_custom_msg(message_id)
    @@custom_msg << message_id
  end

  def custom_msg?(message_id)
    @@custom_msg.includes? message_id
  end

  def verify_passed(user_id)
    @@verify_status[user_id] = VerifyStatus::Pass
  end

  def verify_init(user_id)
    @@verify_status[user_id] = VerifyStatus::Init
  end

  def verify_slowed(user_id)
    @@verify_status[user_id] = VerifyStatus::Slow
  end

  def verify?(user_id)
    @@verify_status[user_id]?
  end

  def verify_status_clear(user_id)
    @@verify_status.delete user_id
  end

  def associate_join_msg(user_id, chat_id, msg_id)
    @@new_join_user_msg["#{user_id}_#{chat_id}"] = msg_id
  end

  def find_join_msg_id(user_id, chat_id)
    @@new_join_user_msg["#{user_id}_#{chat_id}"]?
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

  def put_dynamic_result(chat_id, message_id, answer)
    @@dynamic_list["#{chat_id}_#{message_id}"] = answer
  end

  def dynamic_result(chat_id, message_id)
    @@dynamic_list["#{chat_id}_#{message_id}"]?
  end

  def set_images(images)
    @@image_list = images
  end

  def get_images
    @@image_list
  end
end
