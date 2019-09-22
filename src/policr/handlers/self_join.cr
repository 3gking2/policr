module Policr
  INCOMPATIBLE_BOTS = [
    380207703, # AntiServiceMessageBot
    201180152, # TGCN-群组频道索引
    176365905, # Group Butler
    261244309, # Group Butler [beta]
    # @BabelFishBot => #config service off
    609517172, # @MissRose_bot
    389340481, # @BanhammerMarie_bot
  ]

  handler SelfJoin do
    match do
      all_pass? [
        msg.new_chat_members,
      ]
    end

    handle do
      chat_id = msg.chat.id

      if members = msg.new_chat_members
        members.select { |m| m.is_bot }.select { |m| m.id == bot.self_id }.each do |member| # 自己被拉入群组？
          if user = msg.from
            # 不允许黑名单用户邀请和使用本机器人
            if report = Model::Report.first_valid(user.id)
              text = t "add_to_group.no_right_to_invite", {user: FromUser.new(user).markdown_link}
              spawn { bot.send_message chat_id, text }
              bot.leave_chat chat_id
              return
            end
            markup = Markup.new
            make_btn = ->(text : String, item : String) {
              Button.new(text: text, callback_data: "SelfJoin:#{item}")
            }
            markup << [make_btn.call t("add_to_group.leave"), "leave"]
            markup << [Button.new(text: t("add_to_group.subscription_update"), url: "https://t.me/policr_changelog")]

            is_admin = bot.is_admin?(chat_id, user.id)
            spawn check_group_owner(chat_id) # 检查群主是否存在
            mention = FromUser.new(user).mention
            text =
              if is_admin
                t "add_to_group.from_admin", {mention: mention}
              else
                t "add_to_group.from_user", {mention: mention}
              end

            sended_msg = bot.send_message chat_id, text, reply_markup: markup
            if sended_msg
              message_id = sended_msg.message_id
              # 自动离开定时任务
              Schedule.after((60*30).seconds) {
                bot.refresh_admins chat_id # 强制刷新管理员缓存

                unless bot.is_admin?(chat_id, bot.self_id, dirty: false) # 仍然没有管理员权限
                  bot.delete_message chat_id, message_id
                  bot.leave_chat chat_id
                end
              } unless is_admin
            end
            # 发送快速入门
            spawn bot.send_message chat_id, t("getting_started")
            spawn check_incompatible_bots chat_id
          end
        end
      end
    end

    def check_group_owner(chat_id)
      admin_list = bot.get_chat_administrators chat_id
      has_creator = false
      admin_list.each do |admin|
        has_creator = true if admin.status == "creator"
      end

      # 没有管理员，自动启用信任管理
      unless has_creator
        Model::Toggle.enable! chat_id, ToggleTarget::TrustedAdmin
        text = t "add_to_group.no_creator"
        bot.send_message chat_id, text
      end
    end

    # 检查有冲突的机器人
    def check_incompatible_bots(chat_id)
      INCOMPATIBLE_BOTS.each do |id|
        spawn conflict_warning chat_id, id
      end
    end

    def conflict_warning(chat_id, id)
      member = bot.get_chat_member(chat_id, id)
      bot.send_message(
        chat_id,
        t("incompatible.id.#{id}", {mention: FromUser.new(member.user).markdown_link})
      ) if member.status == "member" || member.status == "administrator"
    end
  end
end
