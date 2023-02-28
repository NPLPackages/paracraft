local EmailManager = NPL.export()
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local Email = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Email/Email.lua");
local EmailReward = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Email/EmailReward.lua" ) 
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
local httpwrapper_version = HttpWrapper.GetDevVersion() or "ONLINE"
EmailManager.email_list = {}
EmailManager.readed_ids_list = {}
EmailManager.del_ids_list = {}
EmailManager.reward_ids_list = {}
EmailManager.cur_email_content = {}
EmailManager.tutorial_emails = {
    ONLINE={},
    RELEASE={},
    LOCAL={[1112]=true,}, --[1114]=true,[1115]=true,[1113]=true,
    STAGE={}
} --体验课邮件
function EmailManager.Init(fromDock, init_cb)
    EmailManager.LoadEmailCfg()
    EmailManager.GetEmailList(fromDock, init_cb)
end

-- Mod.WorldShare.Utils.EncodeURIComponent
function EmailManager.IsTutorialEmail(id)
    local emails = EmailManager.LoadEmailCfg()--EmailManager.tutorial_emails[httpwrapper_version]
    local isTutorail =  emails and emails[id] ~= nil
    return isTutorail or EmailManager.IsCourseEmail(id)
end

function EmailManager.IsCourseEmail(id)
    local data = EmailManager.FindEmailDataById(id)
    return type(data) == "table"
end

function EmailManager.IsInCourseTime()
    local server_time = tonumber(QuestAction.GetServerTime())
    local CourseValidation = EmailManager.GetCourseValidationCfg() or {}
    local email_config = CourseValidation.email_config or {}
    local num = #email_config
    for i=1,num do
        local data = email_config[i]
        local dataNum = #data
        for j=1,dataNum do
            local email_data = data[j] or {}
            local start_time = tonumber(Email.getTimeStampByString(email_data.course_start_time))
            local end_time = tonumber(Email.getTimeStampByString(email_data.course_end_time))
            if System.options.isDevMode then
                print("course evalution time======",start_time,end_time,server_time)
            end
            if start_time and start_time > 0 and end_time and end_time > 0 and server_time >= start_time and server_time <= end_time then
                local dtEmails = email_data.data
                local isHaveEmail = false
                for i,v in ipairs(dtEmails) do
                    if EmailManager.IsRecvEmailById(v.id) then
                        isHaveEmail = true
                    end
                end
                if isHaveEmail then
                    return true
                end
            end
        end
    end
    return false
end


local email_map
function EmailManager.IsRecvEmailById(id)
    if not email_map then
        email_map = {}
        local recvList = EmailManager.email_list
        for i,v in ipairs(recvList) do
            email_map[v.id] = true
        end
    end
    return email_map[id]
end

function EmailManager.FindEmailDataById(id)
    local CourseValidation = EmailManager.GetCourseValidationCfg() or {}
    local email_config = CourseValidation.email_config or {}
    local num = #email_config
    for i=1,num do
        local data = email_config[i]
        local dataNum = #data
        for j=1,dataNum do
            local email_data = data[j].data or {}
            for k,v in pairs(email_data) do
               if id and tonumber(id) == tonumber(v.id) then
                v.course_name = data[j].course_name
                return v
               end
            end
        end
    end
end

function EmailManager.FindCourseDataByCode(code)
    local CourseValidation = EmailManager.GetCourseValidationCfg() or {}
    local courseCnf = CourseValidation and CourseValidation.course_config
    courseCnf = courseCnf or {}
    local num = #courseCnf
    for i=1,num do
        local course_Cnf = courseCnf[i]
        for j = 1,#course_Cnf do
            if course_Cnf and course_Cnf[j].course_name == code then
                return course_Cnf[j]
            end
        end
    end
end

function EmailManager.GetEmailList(formDock, init_cb)
    keepwork.email.email({
		["x-per-page"] = 400,
		["x-page"] = 1,
    },function(err, msg, data)
        if err == 200 then
            EmailManager.email_list = data.data
            -- echo(EmailManager.email_list,true)
            if not formDock then
                EmailManager.UpdateEmailList(true)                           
            end
            if init_cb then
                init_cb()
            end
        end
    end)
end

function EmailManager.SetEmailReaded(id)
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

local function sortEmailByLesson()
    local temp1,temp2 = {},{}
    for i = 1,#EmailManager.email_list do
        local id = EmailManager.email_list[i].id
        if EmailManager.IsTutorialEmail(id)  then
            temp1[#temp1 + 1] = EmailManager.email_list[i]
        else
            temp2[#temp2 + 1] = EmailManager.email_list[i]
        end
    end
    temp2 = sortEmail(temp2)
    EmailManager.email_list = temp1
    for i=1,#temp2 do
        EmailManager.email_list[#EmailManager.email_list + 1] = temp2[i]
    end
end

function EmailManager.UpdateEmailList(isNeedSort)
    if not EmailManager.email_list then
        return 
    end
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

    sortEmailByLesson()
    if isNeedSort == nil then
        Email.SetEmailList(EmailManager.email_list)
        return
    end
    if isNeedSort then
        -- sortEmail() 
        -- sortEmailByLesson()
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
        if not EmailManager.IsTutorialEmail(id) then
            deleteIds[#deleteIds + 1] = id
        end
    elseif type(id) == "table" then
        for i = 1,#id do
            if not EmailManager.IsTutorialEmail(id[i]) then
                deleteIds[#deleteIds + 1] = id[i]
            end
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

function EmailManager.ReadEmail(id)
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
    if EmailManager.email_list then
        for i = 1,#EmailManager.email_list do
            if EmailManager.email_list[i].read == 0 then
                isHave = true
            end    
        end
    end
    return isHave
end

function EmailManager.GetAllUnReadEmailIds()
    local tempIds = {}
    if EmailManager.email_list then
        for i = 1,#EmailManager.email_list do
            if EmailManager.email_list[i].read == 0 then
                tempIds[#tempIds + 1] = EmailManager.email_list[i].id
            end    
        end
    end
    return tempIds
end

function EmailManager.GetAllUnGetRewardEmailIds()
    local tempIds = {}
    if EmailManager.email_list then
        for i = 1,#EmailManager.email_list do
            if EmailManager.email_list[i].rewards == 0 then
                tempIds[#tempIds + 1] = EmailManager.email_list[i].id            
            end
        end
    end
    return tempIds
end

function EmailManager.GetAllEmailIds()
    local tempIds = {}
    if EmailManager.email_list then
        for i = 1,#EmailManager.email_list do
            tempIds[#tempIds + 1] = EmailManager.email_list[i].id
        end
    end
    return tempIds
end

function EmailManager.IsHaveReward(id)
    local isHave = false
    if EmailManager.email_list then
        for i = 1,#EmailManager.email_list do
            if EmailManager.email_list[i].id == id and EmailManager.email_list[i].rewards == 0 then
                isHave = true
                break
            end
        end
    end
    return isHave
end

function EmailManager.IsCanShowAllGet()
    local isHave = false
    if EmailManager.email_list then
        for i = 1,#EmailManager.email_list do
            if EmailManager.email_list[i].rewards == 0  then
                isHave = true
                break
            end
        end
    end
    return isHave
end

function EmailManager.GetItemInfo(gsId)
	local iteminfo = KeepWorkItemManager.GetItemTemplate(gsId)
	return iteminfo or {}
end

function EmailManager.LoadEmailCfg()
    -- if not EmailManager.tutorials then --httpwrapper_version
    --     local filename = "config/Aries/creator/email/email_"..httpwrapper_version..".xml"
    --     print("LoadEmailCfg file====",filename)
    --     local temp = {}
    --     local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
    --     if xmlRoot then
    --         for each_node in commonlib.XPath.eachNode(xmlRoot, "/email_data/email") do
    --             local attr = each_node and each_node.attr
    --             local id = tonumber(attr.id)
    --             temp[id] = {}
    --             temp[id].ppt_index = tonumber(attr.pptIndex) or -1
    --             temp[id].projectId = tonumber(attr.projectId) or 0
    --             temp[id].course_name = attr.course_name or "yyz_course"
    --         end
    --     end
    --     EmailManager.tutorials = temp
    -- end
    return EmailManager.tutorials
end

function EmailManager.SetEmailCfg(config)
    if config then
        EmailManager.tutorials = config
    end
end

function EmailManager.SetExtraConfig(config)
    if config then
        EmailManager.extra_config = config
    end
end

function EmailManager.GetExtraConfig()
    return EmailManager.extra_config
end

function EmailManager.GetCourseValidationCfg()
    return EmailManager.CourseValidationCfg
end

function EmailManager.SetCourseValidationCfg(config)
    if config then
        EmailManager.CourseValidationCfg = config
    end
end