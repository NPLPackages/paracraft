local EmailManager = NPL.export()
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local Email = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Email/Email.lua");
local EmailReward = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Email/EmailReward.lua" ) 
EmailManager.email_list = {}
EmailManager.readed_ids_list = {}
EmailManager.del_ids_list = {}
EmailManager.reward_ids_list = {}
EmailManager.cur_email_content = {}
function EmailManager.Init(fromDock)
    EmailManager.GetEmailList(fromDock)
end

function EmailManager.GetEmailList(formDock)
    keepwork.email.email({},function(err, msg, data)
        if err == 200 then
            EmailManager.email_list = data.data
            if not formDock then
                EmailManager.UpdateEmailList(true)                           
            end
        end
    end)
end

function EmailManager.SetEamilReaded(id)
    local readIds = {}
    if type(id) == "number" then
        readIds[#readIds + 1] = id
    elseif type(id) == "table" then
        for i = 1,#id do
            readIds[#readIds + 1] = id[i]
        end
    end
    if #readIds <= 0 then
        GameLogic.AddBBS(nil,"邮件已经全部已读了~")
    end
    keepwork.email.setEmailReaded({
        ids = readIds,
    },function(err, msg, data)        
        if err == 200 then
            EmailManager.readed_ids_list = readIds
            EmailManager.UpdateEmailList(false)
        end
    end)
end

function EmailManager.UpdateEmailList(isNeedSort)
    --update read
    for i = 1,#EmailManager.email_list do
        for j = 1,#EmailManager.readed_ids_list do
            if EmailManager.email_list[i].id == EmailManager.readed_ids_list[j] then
                EmailManager.email_list[i].read = 1
            end
        end
    end
    EmailManager.readed_ids_list = {}

    -- update del
    for i = 1,#EmailManager.email_list do
        for j = 1,#EmailManager.del_ids_list do
            if EmailManager.email_list[i].id == EmailManager.del_ids_list[j] then          
                EmailManager.email_list[i].IsDel = true
            end
        end
    end
    EmailManager.del_ids_list = {}

    --update reward
    for i = 1,#EmailManager.email_list do
        for j = 1,#EmailManager.reward_ids_list do
            if EmailManager.email_list[i].id == EmailManager.reward_ids_list[j] then
                EmailManager.email_list[i].rewards = 1
            end
        end
    end
    EmailManager.reward_ids_list = {}
    --清除del的
    local temp = {}
    for i = 1 ,#EmailManager.email_list do
        if EmailManager.email_list[i].IsDel ~= true then
            temp[#temp + 1] = EmailManager.email_list[i]
        end
    end
    EmailManager.email_list = temp

    --sort
    local function sortEmail()
        local id_list = {}
        local readids = {}
        local unreadids = {}

        for i =1,#EmailManager.email_list do
            if EmailManager.email_list[i].read == 0 then
                unreadids[#unreadids + 1] = EmailManager.email_list[i]                
            else
                readids[#readids + 1] = EmailManager.email_list[i]
            end
        end
        id_list = {}
        for i = 1,#unreadids do
            id_list[#id_list + 1] = unreadids[i]
        end
        for i = 1,#readids do
            id_list[#id_list + 1] = readids[i]
        end
        EmailManager.email_list = id_list
    end

    if isNeedSort == nil then
        Email.SetEmailList(EmailManager.email_list)
        return
    end
    if isNeedSort then
        sortEmail() 
        Email.SetEmailList(EmailManager.email_list)
        Email.select_email_idx = EmailManager.email_list[1] and EmailManager.email_list[1].id or -1     
        Email.ClickEmailItem(Email.select_email_idx)
    else
        Email.SetEmailList(EmailManager.email_list)
        EmailManager.RefreshEmail()
    end    

end

function EmailManager.DeleteEmail(id)
    local deleteIds = {}
    if type(id) == "number" then
        deleteIds[#deleteIds + 1] = id
    elseif type(id) == "table" then
        for i = 1,#id do
            deleteIds[#deleteIds + 1] = id[i]
        end
    end
    if #deleteIds <= 0 then
        GameLogic.AddBBS(nil,"没有需要删除的邮件哟~")
    end
    keepwork.email.delEmail({
        ids = deleteIds,
    },function(err, msg, data)
        if err == 200 then
            EmailManager.del_ids_list = deleteIds
            EmailManager.UpdateEmailList(true)
        end
    end)
end

function EmailManager.ReadEamil(id)
    if id <= 0 then
        return 
    end
    keepwork.email.readEmail({
        router_params = {
            id = id,
        }
    },function(err, msg, data)
        if err == 200 then
            EmailManager.cur_email_content = data.data
            --print("email================")
            --echo(EmailManager.cur_email_content,true)
            if EmailManager.cur_email_content and EmailManager.cur_email_content[1] then
                local content = EmailManager.cur_email_content[1]
                if not content.rewards then
                    content.rewards = {}
                end
            end
            EmailManager.RefreshEmail()            
        end
    end)
end

function EmailManager.GetEmailReward(id)
    local rewardIds = {}
    if type(id) == "number" then
        rewardIds[#rewardIds + 1] = id
    elseif type(id) == "table" then
        for i = 1,#id do
            rewardIds[#rewardIds + 1] = id[i]
        end
    end
    if #rewardIds <= 0 then
        GameLogic.AddBBS(nil,"你的邮件奖励已经全部领取了~")
    end
    keepwork.email.getEmailReward({
        ids = rewardIds,
    },function(err, msg, data)
        if err == 200 then
            EmailManager.reward_ids_list = rewardIds
            EmailManager.UpdateEmailList()
            local rewards = data.data            
            EmailReward.ShowView(rewards)
            EmailManager.RefreshEmail()
            KeepWorkItemManager.GetFilter():apply_filters("KeepWorkItemManager_LoadItems");
        end
    end)
end

function EmailManager.RefreshEmail()
    if Email.isOpen and Email.IsShowEmail() then
        Email.OnRefresh()
    end
end

function EmailManager.IsHaveNew()
    local isHave = false
    for i = 1,#EmailManager.email_list do
        if EmailManager.email_list[i].read == 0 then
            isHave = true
        end    
    end
    return isHave
end

function EmailManager.GetAllUnReadEmailIds()
    local tempIds = {}
    for i = 1,#EmailManager.email_list do
        if EmailManager.email_list[i].read == 0 then
            tempIds[#tempIds + 1] = EmailManager.email_list[i].id
        end    
    end
    return tempIds
end

function EmailManager.GetAllUnGetRewardEmailIds()
    local tempIds = {}
    for i = 1,#EmailManager.email_list do
        if EmailManager.email_list[i].rewards == 0 then
            -- if #tempIds > 10 then
            --     break
            -- end
            tempIds[#tempIds + 1] = EmailManager.email_list[i].id            
        end
    end
    return tempIds
end

function EmailManager.GetAllEmailIds()
    local tempIds = {}
    for i = 1,#EmailManager.email_list do
        tempIds[#tempIds + 1] = EmailManager.email_list[i].id
    end
    return tempIds
end

function EmailManager.IsHaveReward(id)
    local isHave = false
    for i = 1,#EmailManager.email_list do
        if EmailManager.email_list[i].id == id and EmailManager.email_list[i].rewards == 0 then
            isHave = true
            break
        end
    end
    return isHave
end

function EmailManager.IsCanShowAllGet()
    local isHave = false
    for i = 1,#EmailManager.email_list do
        if EmailManager.email_list[i].rewards == 0  then
            isHave = true
            break
        end
    end
    return isHave
end

function EmailManager.GetItemInfo(gsId)
	local iteminfo = KeepWorkItemManager.GetItemTemplate(gsId)
	return iteminfo or {}
end