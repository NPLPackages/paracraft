--[[
Title: QuestWork
Author(s): yangguiyi
Date: 2021/3/3
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestWork.lua").Show();
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local QuestPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestPage.lua");
local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
local QuestWork = NPL.export();
local page
local server_time = 0

QuestWork.TypeIndex = 1

QuestWork.WorkData = {
    {name = "作业标题", desc = 0,}
}

function QuestWork.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = QuestWork.CloseView
end

function QuestWork.Show()
    QuestWork.TypeIndex = 1
    QuestWork.GetWorkList(QuestWork.ShowView)
end

function QuestWork.GetWorkList(cb)
    local status = QuestWork.TypeIndex == 1 and 0 or 1
    keepwork.quest_work_list.get({
        status = status, -- 0,未完成；1已完成
    },function(err, msg, data)
        -- print("dddddddddddddddd")
        -- echo(data, true)
        if err == 200 then
            local list_data = {}
            for i, v in ipairs(data.rows) do
                if v.aiHomework then
                    list_data[#list_data + 1] = v
                end
            end
            QuestWork.HandleData(list_data)
            if cb then
                cb()
            end
        end
    end)
end

function QuestWork.ShowView()
    if page and page:IsVisible() then
        return
    end
    
    
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Quest/QuestWork.html",
        name = "QuestWork.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 0,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,
        
        align = "_ct",
        x = -960/2,
        y = -580/2,
        width = 960,
        height = 580,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function QuestWork.FreshView()
    local parent  = page:GetParentUIObject()
end

function QuestWork.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
    QuestWork.FreshView()
end

function QuestWork.CloseView()
    QuestWork.ClearData()
end

function QuestWork.ClearData()
end

function QuestWork.HandleData(data)
    QuestWork.WorkData = {}
    QuestWork.ServerDataList = data
    for i, v in ipairs(data) do
        local item_data = {}
        local aiHomework = v.aiHomework
        item_data.name = aiHomework.name
        item_data.desc = aiHomework.description
        local time_stamp = commonlib.timehelp.GetTimeStampByDateTime(v.createdAt) 
        item_data.time_desc = os.date("%Y.%m.%d",time_stamp)

        QuestWork.WorkData[#QuestWork.WorkData + 1] = item_data
    end
end

function QuestWork.OnChangeType(index)
    index = tonumber(index)
    if index == QuestWork.TypeIndex then
        return
    end

    QuestWork.TypeIndex = index
    QuestWork.GetWorkList(QuestWork.OnRefresh)
end

function QuestWork.ToWork(index)
    local data = QuestWork.ServerDataList[index]
    if nil == data then
        return
    end

    if data.aiHomework == nil then
        return
    end

    if not GameLogic.GetFilters():apply_filters('service.session.is_real_name') then
        _guihelper.MessageBox("学习人工智能课程需要先完成实名认证，快去认证吧。", function()	
            GameLogic.GetFilters():apply_filters(
                'show_certificate',
                function(result)
                    if (result) then
                        local DockPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockPage.lua");
                        if DockPage.IsShow() then
                            DockPage.RefreshPage(0.01)
                        end
                        
                        GameLogic.QuestAction.AchieveTask("40006_1", 1, true)
                        QuestWork.ToWork(index)
                    end
                end
            );
        end)
        return
    end

    local work_data = data.aiHomework
    local type = work_data.type -- 0：更新世界类型，1：更新家园，2：作业世界
    local server_time = GameLogic.QuestAction.GetServerTime()
    local today_weehours = commonlib.timehelp.GetWeeHoursTimeStamp(server_time)

    -- 入校课程的话 需要每天四点半之后才能做
    if work_data.aiCourse and work_data.aiCourse.isForSchool == 1 then
        local week_day = QuestWork.GetWeekNum(server_time)
        if week_day ~= 6 and week_day ~= 7 then
            local limit_time_stamp = today_weehours + 16 * 60 * 60 + 30 * 60
            if server_time < limit_time_stamp then
                -- GameLogic.AddBBS(nil, "16:30之后才能做作业哦", 5000, "255 0 0");
                _guihelper.MessageBox("16:30之后才能做作业哦")
                return
            end
        end
    end

    if type == 0 then
        page:CloseWindow()
        QuestWork.CloseView()
        GameLogic.GetFilters():apply_filters('show_create_page')
    elseif type == 1 then
        page:CloseWindow()
        QuestWork.CloseView()
        local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")

        NPL.load("(gl)script/apps/Aries/Creator/Game/Login/LocalLoadWorld.lua");
        local LocalLoadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld")
        LocalLoadWorld.CreateGetHomeWorld();

        GameLogic.GetFilters():apply_filters('check_and_updated_before_enter_my_home', function()
            GameLogic.RunCommand("/loadworld home");
        end)
    else
        keepwork.quest_complete_homework.get({
            aiHomeworkId = work_data.id,
        },function(workerr, workmessage, workdata)
            -- print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>查询作业", err)
            -- echo(data, true)
            if workerr == 200 then
                local userAiHomework = workdata.userAiHomework
                -- if userAiHomework then
                --     return
                -- end
    
                -- local command = string.format("/loadworld -s -force %s", work_data.projectId)
                local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")
                local client_data = QuestAction.GetClientData()
                -- client_data.course_world_id = work_data.projectId
                client_data.course_id = work_data.aiCourseId
                client_data.home_work_id = work_data.id
                client_data.is_home_work = true

                client_data.course_step = 0
                if userAiHomework and userAiHomework.progress then
                    client_data.course_step = userAiHomework.progress.stepNum or 0
                end
    
                KeepWorkItemManager.SetClientData(QuestAction.task_gsid, client_data)
                
                page:CloseWindow()
                QuestWork.CloseView()
                GameLogic.GetFilters():apply_filters('cellar.common.common_load_world.enter_homework_world', work_data.id, false, work_data.projectReleaseId)
                -- CommandManager:RunCommand(command)
            end
    
        end)
    end
end

function QuestWork.Share(index)
    local data = QuestWork.ServerDataList[index]
    if nil == data then
        return
    end
    local work_data = data.aiHomework
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestWorkCode.lua").Show(work_data.wxacode);
end

--根据时间戳获取星期几
function QuestWork.GetWeekNum(time_stamp)
    time_stamp = time_stamp or 0
    local weekNum = os.date("*t",time_stamp).wday  -1
    if weekNum == 0 then
        weekNum = 7
    end
    return weekNum
end