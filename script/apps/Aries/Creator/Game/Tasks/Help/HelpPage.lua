--[[
Title: HelpPage
Author(s): yangguiyi
Date: 2021/2/2
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Help/HelpPage.lua").Show("role");
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local HelpConfig = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Help/HelpConfig.lua")
local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
local HelpPage = NPL.export();
local page
local server_time = 0

function HelpPage.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = HelpPage.CloseView
end

function HelpPage.Show(help_type)
    HelpPage.help_type = help_type
    -- HelpPage.help_type = "create_world"
    HelpPage.InitData()
    HelpPage.ShowView()
    if HelpPage.IdList and #HelpPage.IdList > 0 then
        local id_str = ""

        for i, v in ipairs(HelpPage.IdList) do
            if i ~= HelpPage.IdList then
                id_str = id_str .. v .. ","
            else
                id_str = id_str .. v
            end
        end

        keepwork.quest_course.search({
            ids=id_str,
        }, function(err, msg, data)
            if err == 200 then
                HelpPage.HandleCourseData(data)
                HelpPage.OnRefresh()
            end
        end)
    end

end

function HelpPage.ShowView()
    if page and page:IsVisible() then
        HelpPage.OnRefresh()
        return
    end
    
    
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Help/HelpPage.html",
        name = "HelpPage.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 2,
        -- app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,
        
        align = "_ct",
        x = -632/2,
        y = -352/2,
        width = 632,
        height = 352,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function HelpPage.FreshView()
end

function HelpPage.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
    HelpPage.FreshView()
end

function HelpPage.CloseView()
    HelpPage.ClearData()
end

function HelpPage.ClearData()
end

function HelpPage.InitData()
    if HelpPage.help_type == nil then
        return
    end

    local help_desc = HelpConfig.GetDesc(HelpPage.help_type)
    HelpPage.DataSource = {{help_desc = help_desc}}

    HelpPage.IdList = HelpConfig.GetCourseIdList(HelpPage.help_type)
    HelpPage.CourseData = {}
end

function HelpPage.HandleCourseData(data)
    HelpPage.ServerData = data
    HelpPage.CourseData = {}
    for i, v in ipairs(data) do
        local course_data = {}
        course_data.name = HelpPage.GetLimitLabel(v.name)
        course_data.id = v.id
        course_data.projectReleaseId = v.projectReleaseId
        HelpPage.CourseData[#HelpPage.CourseData + 1] = course_data
    end
end

function HelpPage.GetLimitLabel(text)
    local maxCharCount = 8;
    local len = ParaMisc.GetUnicodeCharNum(text);
    if(len >= maxCharCount)then
	    text = ParaMisc.UniSubString(text, 1, maxCharCount-2) or "";
        return text .. "...";
    else
        return text;
    end
end

function HelpPage.ToCourse(index)
    local data = HelpPage.ServerData[index]
    if data == nil then
        return
    end

    keepwork.quest_complete_course.get({
        aiCourseId = data.id,
    }, function(err2, msg2, data2)
        if err2 == 200 then
            local work_data = data.aiHomework or {}
                
            local client_data = QuestAction.GetClientData()

            client_data.course_id = data.id
            client_data.home_work_id = work_data.id or -1
            client_data.is_home_work = false
            
            client_data.course_step = 0
            if data2.userAiCourse and data2.userAiCourse.progress then
                client_data.course_step = data2.userAiCourse.progress.stepNum or 0
            end
            KeepWorkItemManager.SetClientData(QuestAction.task_gsid, client_data)

            page:CloseWindow()
            GameLogic.GetFilters():apply_filters('cellar.common.common_load_world.enter_course_world', data.id, false, data.projectReleaseId)
        end
    end)
end