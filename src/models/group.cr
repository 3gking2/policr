module Policr::Model
  class Group < Jennifer::Model::Base
    alias Status = ReportStatus

    with_timestamps

    mapping(
      id: Primary32,
      chat_id: Int64,
      title: String,
      link: String?,
      managed: Bool,
      created_at: Time?,
      updated_at: Time?
    )

    has_and_belongs_to_many :admins, Admin

    def self.fetch_by_chat_id!(chat_id : Int64, data : NamedTuple = nil)
      if g = where { _chat_id == chat_id }.first
        if data
          title = data[:title]?
          link = data[:link]?
          managed = data[:managed]?

          g.update_column(:title, title) if title
          g.update_column(:link, link) if link
          g.update_column(:managed, managed) if managed != nil
        end
        g
      else
        data ||= NamedTuple.new
        data = data.merge({chat_id: chat_id})
        create! data
      end
    end

    def self.update_title!(chat_id : Int64, title : String)
      g = fetch_by_chat_id! chat_id, {title: title, managed: true}
      g.update_column :title, title
    end

    def self.cancel_manage(chat_id : Int64)
      if g = where { _chat_id == chat_id }.first
        g.update_column :managed, false
      end
    end

    def reset_admins(all : Array(Admin))
      # 应该添加的管理员集合
      add_list = all.select do |a1|
        # 如果在已有的列表中不存在
        admins.select { |a2| a2.id == a1.id }.size == 0
      end

      # 应该删除的管理员集合
      del_list = admins.select do |a1|
        # 如果已有的数据不存在
        all.select { |a2| a2.id == a1.id }.size == 0
      end

      add_list.each { |a| add_admins(a) }

      del_list.each { |a| remove_admins(a) }
    end

    def self.load_list(offset : Int32, limit : Int32)
      where { _managed == true }
        .offset(offset)
        .limit(limit)
        .order({{@type}}._updated_at.asc)
        .to_a
    end
  end
end
