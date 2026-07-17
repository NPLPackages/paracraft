--[[
    author: pbb
    date: 2024-05-16
    desc: 消息通知管理器
    useLib:
        local NotificationManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/Notification/NotificationManager.lua")
]]
local NotificationManager = NPL.export()
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local CommunityNotification = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/Notification/CommunityNotification.lua")
local EmailReward = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Email/EmailReward.lua" ) 
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local httpwrapper_version = HttpWrapper.GetDevVersion() or "ONLINE"
NotificationManager.email_list = {}
NotificationManager.readed_ids_list = {}
NotificationManager.del_ids_list = {}
NotificationManager.reward_ids_list = {}
NotificationManager.cur_email_content = {}

function NotificationManager.Init(fromDock, init_cb)
    NotificationManager.GetEmailList(fromDock, init_cb)
end

local email_map
function NotificationManager.IsRecvEmailById(id)
    if not email_map then
        email_map = {}
        local recvList = NotificationManager.email_list
        for i,v in ipairs(recvList) do
            email_map[v.id] = true
        end
    end
    return email_map[id]
end

function NotificationManager.GetEmailList(formDock, init_cb)
    keepwork.email.email({
		["x-per-page"] = 400,
		["x-page"] = 1,
    },function(err, msg, data)
        if err == 200 then
            NotificationManager.email_list = data.data
            if not formDock then
                NotificationManager.UpdateEmailList(true)                           
            end
            if init_cb then
                init_cb()
            end
        end
    end)
end

function NotificationManager.SetEmailReaded(id)
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
            NotificationManager.readed_ids_list = readIds
            NotificationManager.UpdateEmailList(false)
        end
    end)
end

 --sort
 local function sortEmail(emails)
    local emails = emails or {}
    local id_list = {}
    local readids = {}
    local unreadids = {}

    for i =1,#emails do
        if emails[i].read == 0 then
            unreadids[#unreadids + 1] = emails[i]                
        else
            readids[#readids + 1] = emails[i]
        end
    end
    id_list = {}
    for i = 1,#unreadids do
        id_list[#id_list + 1] = unreadids[i]
    end
    for i = 1,#readids do
        id_list[#id_list + 1] = readids[i]
    end
    return id_list
end

function NotificationManager.UpdateEmailList(isNeedSort)
    if not NotificationManager.email_list then
        return 
    end
    --update read
    for i = 1,#NotificationManager.email_list do
        for j = 1,#NotificationManager.readed_ids_list do
            if NotificationManager.email_list[i].id == NotificationManager.readed_ids_list[j] then
                NotificationManager.email_list[i].read = 1
            end
        end
    end
    NotificationManager.readed_ids_list = {}

    -- update del
    for i = 1,#NotificationManager.email_list do
        for j = 1,#NotificationManager.del_ids_list do
            if NotificationManager.email_list[i].id == NotificationManager.del_ids_list[j] then          
                NotificationManager.email_list[i].IsDel = true
            end
        end
    end
    NotificationManager.del_ids_list = {}

    --update reward
    for i = 1,#NotificationManager.email_list do
        for j = 1,#NotificationManager.reward_ids_list do
            if NotificationManager.email_list[i].id == NotificationManager.reward_ids_list[j] then
                NotificationManager.email_list[i].rewards = 1
            end
        end
    end
    NotificationManager.reward_ids_list = {}
    --清除del的
    local temp = {}
    for i = 1 ,#NotificationManager.email_list do
        if NotificationManager.email_list[i].IsDel ~= true then
            temp[#temp + 1] = NotificationManager.email_list[i]
        end
    end
    NotificationManager.email_list = temp

    if isNeedSort == nil then
        CommunityNotification.SetEmailList(NotificationManager.email_list)
        return
    end
    if isNeedSort then
        CommunityNotification.SetEmailList(NotificationManager.email_list)
        CommunityNotification.select_email_idx = NotificationManager.email_list[1] and NotificationManager.email_list[1].id or -1     
        CommunityNotification.ClickEmailItem(CommunityNotification.select_email_idx)
    else
        CommunityNotification.SetEmailList(NotificationManager.email_list)
        NotificationManager.RefreshEmail()
    end    
    GameLogic.GetFilters():apply_filters("UpdateEmailList")
end


function NotificationManager.DeleteEmail(id)
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
            NotificationManager.del_ids_list = deleteIds
            NotificationManager.UpdateEmailList(true)
        end
    end)
end

function NotificationManager.ReadEmail(id)
    if id <= 0 then
        return 
    end
    keepwork.email.readEmail({
        router_params = {
            id = id,
        }
    },function(err, msg, data)
        if err == 200 then
            NotificationManager.cur_email_content = data.data
            if NotificationManager.cur_email_content and NotificationManager.cur_email_content[1] then
                local content = NotificationManager.cur_email_content[1]
                if not content.rewards then
                    content.rewards = {}
                end
            end
            NotificationManager.RefreshEmail()            
        end
    end)
end

function NotificationManager.GetEmailReward(id)
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
            NotificationManager.reward_ids_list = rewardIds
            NotificationManager.UpdateEmailList()
            local rewards = data.data            
            EmailReward.ShowView(rewards)
            NotificationManager.RefreshEmail()
            KeepWorkItemManager.GetFilter():apply_filters("KeepWorkItemManager_LoadItems");
        end
    end)
end

function NotificationManager.RefreshEmail()
    CommunityNotification.OnRefresh()
end

function NotificationManager.IsHaveNew()
    local isHave = false
    if NotificationManager.email_list then
        for i = 1,#NotificationManager.email_list do
            if NotificationManager.email_list[i].read == 0 then
                isHave = true
            end    
        end
    end
    return isHave
end

function NotificationManager.GetAllUnReadEmailIds()
    local tempIds = {}
    if NotificationManager.email_list then
        for i = 1,#NotificationManager.email_list do
            if NotificationManager.email_list[i].read == 0 then
                tempIds[#tempIds + 1] = NotificationManager.email_list[i].id
            end    
        end
    end
    return tempIds
end

function NotificationManager.GetAllUnGetRewardEmailIds()
    local tempIds = {}
    if NotificationManager.email_list then
        for i = 1,#NotificationManager.email_list do
            if NotificationManager.email_list[i].rewards == 0 then
                tempIds[#tempIds + 1] = NotificationManager.email_list[i].id            
            end
        end
    end
    return tempIds
end

function NotificationManager.GetAllEmailIds()
    local tempIds = {}
    if NotificationManager.email_list then
        for i = 1,#NotificationManager.email_list do
            tempIds[#tempIds + 1] = NotificationManager.email_list[i].id
        end
    end
    return tempIds
end

function NotificationManager.IsHaveReward(id)
    local isHave = false
    if NotificationManager.email_list then
        for i = 1,#NotificationManager.email_list do
            if NotificationManager.email_list[i].id == id and NotificationManager.email_list[i].rewards == 0 then
                isHave = true
                break
            end
        end
    end
    return isHave
end

function NotificationManager.IsCanShowAllGet()
    local isHave = false
    if NotificationManager.email_list then
        for i = 1,#NotificationManager.email_list do
            if NotificationManager.email_list[i].rewards == 0  then
                isHave = true
                break
            end
        end
    end
    return isHave
end

function NotificationManager.GetItemInfo(gsId)
	local iteminfo = KeepWorkItemManager.GetItemTemplate(gsId)
	return iteminfo or {}
end
