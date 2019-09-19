module Policr::Model
  class BlockContent < Jennifer::Model::Base
    with_timestamps

    mapping(
      id: Primary32,
      chat_id: Int64,
      version: String,
      alias_s: String,
      expression: String,
      is_enabled: Bool,
      created_at: Time?,
      updated_at: Time?
    )

    def self.enabled?(chat_id : Int64)
      where { (_chat_id == chat_id) & (_is_enabled == true) }.count > 0
    end

    def self.disable_all(chat_id : Int64)
      where { (_chat_id == chat_id) & (_is_enabled == true) }.update { {:is_enabled => false} }
    end

    def self.update_expression(chat_id, expression)
      bc = where { (_chat_id == chat_id) }.first
      bc ||= create({
        chat_id:    chat_id.to_i64,
        version:    "v1",
        alias_s:    "未命名",
        expression: expression,
        is_enabled: false,
      })

      bc.update_column(:expression, expression)
    end

    def self.load_list(chat_id : Int64)
      where { _chat_id == chat_id }
        .offset(0)
        .limit(5)
        .to_a
    end
  end
end
