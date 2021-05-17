--[[
    author:pbb
    date:2021.4.8
    Desc:
    use lib:
    local HomeWorkTip = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/HomeWork/HomeWorkTip.lua") 
    HomeWorkTip.Show()
]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local DockPopupControl = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockPopupControl.lua")
local HomeWorkTip = NPL.export();
HomeWorkTip.homeWork_Name = ""
local page = nil

function HomeWorkTip.OnInit()
    page = document:GetPageCtrl()
end

function HomeWorkTip.ShowView(name)
    HomeWorkTip.homeWork_Name = name or ""
    local view_width = 600
    local view_height = 340
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/HomeWork/HomeWorkTip.html",
        name = "HomeWorkTip.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = -1,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key,
        directPosition = true,
        align = "_ct",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    
end

function HomeWorkTip.Show()
    GameLogic.QuestAction.RequestAiHomeWork(function()
        local ai_homework = GameLogic.QuestAction.GetAiHomeWork()
        --echo(ai_homework,true)
        if #ai_homework > 0 then
            DockPopupControl.popup_num = DockPopupControl.popup_num + 1
            local curhome = ai_homework[1]
            HomeWorkTip.cur_home_work = curhome
            HomeWorkTip.ShowView(curhome.aiHomework.name)
        else
            DockPopupControl.GotoNextPopup()
        end
    end)
end

function HomeWorkTip.CheckCanDoHomeWork()
    local data = HomeWorkTip.cur_home_work
    local server_time = GameLogic.QuestAction.GetServerTime()
    local today_weehours = commonlib.timehelp.GetWeeHoursTimeStamp(server_time)
    local work_data = data.aiHomework
    -- 入校课程的话 需要每天四点半之后才能做
    if work_data.aiCourse and work_data.aiCourse.isForSchool == 1 then
        local week_day = HomeWorkTip.GetWeekNum(server_time)
        if week_day ~= 6 and week_day ~= 7 then
            local limit_time_stamp = today_weehours + 16 * 60 * 60 + 30 * 60
            local limit_time_end_stamp = today_weehours + 22 * 60 * 60 + 30 * 60
            if server_time < limit_time_stamp or server_time > limit_time_end_stamp then
                return false
            end
        end
    end
    return true
end

function HomeWorkTip.CloseView()
    if page then
        page:CloseWindow()
        page = nil        
    end
end

function HomeWorkTip.GoNextPage()
    DockPopupControl.GotoNextPopup()
end

--根据时间戳获取星期几
function HomeWorkTip.GetWeekNum(time_stamp)
    time_stamp = time_stamp or 0
    local weekNum = os.date("*t",time_stamp).wday  -1
    if weekNum == 0 then
        weekNum = 7
    end
    return weekNum
end

function HomeWorkTip.ToWork()
    local data = HomeWorkTip.cur_home_work
    if nil == data then
        return
    end

    if data.aiHomework == nil then
        return
    end

    if not GameLogic.GetFilters():apply_filters('service.session.is_real_name') then
        _guihelper.MessageBox("课后练习需完成实名认证才可进行，快去认证吧。", function()	
            GameLogic.GetFilters():apply_filters(
                'show_certificate',
                function(result)
                    if (result) then
                        local DockPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockPage.lua");
                        if DockPage.IsShow() then
                            DockPage.RefreshPage(0.01)
                        end
                        
                        GameLogic.QuestAction.AchieveTask("40006_1", 1, true)
                        HomeWorkTip.ToWork()
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
        local week_day = HomeWorkTip.GetWeekNum(server_time)
        if week_day ~= 6 and week_day ~= 7 then
            local limit_time_stamp = today_weehours + 16 * 60 * 60 + 30 * 60
            local limit_time_end_stamp = today_weehours + 22 * 60 * 60 + 30 * 60
            if server_time < limit_time_stamp or server_time > limit_time_end_stamp then
                -- GameLogic.AddBBS(nil, "16:30之后才能做作业哦", 5000, "255 0 0");
                _guihelper.MessageBox("16:30之后才能做作业哦")
                return
            end
        end
    end

    if type == 0 then
        page:CloseWindow()
        HomeWorkTip.CloseView()
        GameLogic.GetFilters():apply_filters('show_create_page')
    elseif type == 1 then
        page:CloseWindow()
        HomeWorkTip.CloseView()
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
                local client_data = GameLogic.QuestAction.GetClientData()
                -- client_data.course_world_id = work_data.projectId
                client_data.course_id = work_data.aiCourseId
                client_data.home_work_id = work_data.id
                client_data.is_home_work = true

                client_data.course_step = 0
                if userAiHomework and userAiHomework.progress then
                    client_data.course_step = userAiHomework.progress.stepNum or 0
                end
    
                KeepWorkItemManager.SetClientData(GameLogic.QuestAction.task_gsid, client_data)
                
                HomeWorkTip.CloseView()
                GameLogic.GetFilters():apply_filters('cellar.common.common_load_world.enter_homework_world', work_data.id, false, work_data.projectReleaseId)
                -- CommandManager:RunCommand(command)
            end
    
        end)
    end
end

