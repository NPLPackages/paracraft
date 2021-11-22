--[[
Title: StudentPage
Author(s): yangguiyi
Date: 2021/6/2
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SchoolCenter/StudentPage.lua").Show();
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local KeepworkServiceSchoolAndOrg = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/SchoolAndOrg.lua")
local XcodePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SchoolCenter/XcodePage.lua")
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local QuestWork = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestWork.lua");
local StudentPage = NPL.export();

local server_time = 0
local page

function StudentPage.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = StudentPage.CloseView
    if StudentPage.show_callback then
        StudentPage.show_callback(page)
        StudentPage.show_callback = nil
    end

    StudentPage.NameToFunction = {
        ["3d_school"] = StudentPage.Open3dSchool,
        ["school_page"] = StudentPage.OpenSchoolPage,
        ["3d_school_management"] = StudentPage.Open3dSchoolManagement,
        ["my_classmate"] = StudentPage.OpenMyClassMate,
        ["students_work"] = StudentPage.OpenStudentsWork,
        ["my_work"] = StudentPage.OpenMyWork,
        ["history_work"] = StudentPage.OpenHistoryWork,
        ["my_project"] = StudentPage.OpenMyProject,
        ["personal_data_statistics"] = StudentPage.OpenPersonalDataStatistics,
        ["comple_rel_name"] = StudentPage.OpenCompleRelName,
        ["comple_school_info"] = StudentPage.OpenCompleSchoolInfo,
        ["comple_class_info"] = StudentPage.OpenCompleClassInfo,
    }
end

function StudentPage.Show(shcool_id)
    StudentPage.shcool_id = shcool_id
    StudentPage.ShowView()
end

function StudentPage.ClosePage()
    page:CloseWindow(0)
    StudentPage.CloseView()
end

function StudentPage.ShowView()
    if page and page:IsVisible() then
        return
    end
    StudentPage.HandleData()

    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/SchoolCenter/StudentPage.html",
        name = "StudentPage.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 0,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,
        
        align = "_ct",
        x = -1062/2,
        y = -614/2,
        width = 1062,
        height = 614,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function StudentPage.FreshView()
    local parent  = page:GetParentUIObject()
end

function StudentPage.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
    StudentPage.FreshView()
end

function StudentPage.CloseView()
    StudentPage.ClearData()
end

function StudentPage.ClearData()
end

function StudentPage.HandleData()
end

function StudentPage.ClickBt(name)
    if StudentPage.NameToFunction[name] then
        StudentPage.NameToFunction[name]()
    end
end

function StudentPage.Open3dSchool()
    KeepworkServiceSchoolAndOrg:GetUserAllOrgs(function(orgData)
        for key, item in ipairs(orgData) do
            if item.schoolId == StudentPage.shcool_id then
                if item and item.paraWorld and item.paraWorld.projectId then
                
                    local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

                    StudentPage.ClosePage()

                    if currentEnterWorld and currentEnterWorld.text then
                        _guihelper.MessageBox(
                            format(L"即将离开【%s】进入【%s】", currentEnterWorld.text, item.paraWorld.name),
                            function(res)
                                if res and res == _guihelper.DialogResult.Yes then
                                    GameLogic.RunCommand("/loadworld -auto " .. item.paraWorld.projectId)
                                end
                            end,
                            _guihelper.MessageBoxButtons.YesNo
                        )
                    else
                        GameLogic.RunCommand("/loadworld -auto " .. item.paraWorld.projectId)
                    end
    
                    return
                end
                GameLogic.AddBBS(nil, L"学校暂无3d校园", 3000, "255 0 0")
                return
            end
        end

        GameLogic.AddBBS(nil, L"请先加入学校", 3000, "255 0 0")
    end)
end

function StudentPage.OpenSchoolPage()
    KeepworkServiceSchoolAndOrg:GetUserAllOrgs(function(orgData)
        for key, item in ipairs(orgData) do
            if item.schoolId == StudentPage.shcool_id then
                local orgUrl = item.orgUrl or ""
        
                local url = KeepworkService:GetKeepworkUrl() .. "/org/" .. orgUrl .. "/index"

                ParaGlobal.ShellExecute("open", url, "", "", 1)

                return
            end
        end

        GameLogic.AddBBS(nil, L"请先加入学校", 3000, "255 0 0")
    end)
end

function StudentPage.Open3dSchoolManagement()
    XcodePage.Show("3d_school_management")
end

function StudentPage.OpenMyClassMate()
    local FriendsPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendsPage.lua");
    FriendsPage.Show(3);
end

function StudentPage.OpenStudentsWork()
    GameLogic.GetFilters():apply_filters('show_offical_worlds_page')
    StudentPage.ClosePage()
end

function StudentPage.OpenMyWork()
    local status = 0
    keepwork.quest_work_list.get({
        status = status, -- 0,未完成；1已完成
    },function(err, msg, data)
        -- print("dddddddddddddddd")
        -- echo(data, true)
        if err == 200 then
            if data.rows and #data.rows == 0 then
                GameLogic.AddBBS(nil, L"暂无练习", 3000, "255 0 0")
                return
            end
            
            QuestWork.Show(1)
        end
    end)
end

function StudentPage.OpenHistoryWork()
    local status = 1
    keepwork.quest_work_list.get({
        status = status, -- 0,未完成；1已完成
    },function(err, msg, data)
        -- print("dddddddddddddddd")
        -- echo(data, true)
        if err == 200 then
            if data.rows and #data.rows == 0 then
                GameLogic.AddBBS(nil, L"暂无历史成绩", 3000, "255 0 0")
                return
            end
            
            QuestWork.Show(2)
        end
    end)
end

function StudentPage.OpenMyProject()
    local page = NPL.load("Mod/GeneralGameServerMod/App/ui/page.lua");
    last_page_ctrl = page.ShowUserInfoPage({HeaderTabIndex="works", username = System.User.keepworkUsername});
end

function StudentPage.OpenPersonalDataStatistics()
    -- GameLogic.AddBBS(nil, L"敬请期待", 3000, "255 0 0")
    XcodePage.Show("personal_data_statistics")
end

function StudentPage.OpenCompleRelName()
    GameLogic.GetFilters():apply_filters(
        'show_certificate',
        function(result)
            if (result) then
                if page then
                    page:Refresh(0.01)
                end
            end
        end
    );
end

function StudentPage.OpenCompleSchoolInfo()
    local MySchool = NPL.load("(gl)Mod/WorldShare/cellar/MySchool/MySchool.lua")
    MySchool:ShowJoinSchool(function()
        KeepWorkItemManager.LoadProfile(false, function()
            local profile = KeepWorkItemManager.GetProfile()
            if profile and profile.schoolId and profile.schoolId > 0 then
                StudentPage.shcool_id = profile.schoolId
                page:Refresh(0.01)
            end
        end)
    end)
end

function StudentPage.OpenCompleClassInfo()
    local profile = KeepWorkItemManager.GetProfile()
    if not profile or not profile.schoolId or profile.schoolId == 0 then
        GameLogic.AddBBS(nil, L"请先选择学校", 3000, "255 0 0")
        return
   end

    local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua");
    Page.Show({OnFinish = function()
        GameLogic.AddBBS(nil, L"加入班级成功", 3000, "0 255 0")
        page:Refresh(0.01)
    end}, {url = "%vue%/Page/User/EditClass.html"});
    -- ShowWindow({
    --     OnFinish = function(className)
    --         -- self.className = className or "";
    --         -- self.isPrefectUserInfo = Keepwork:IsPrefectUserInfo();
    --     end
    -- }, {
    --     url = "%vue%/Page/User/EditClass.html",
    --     draggable = false,
    -- })
end

function StudentPage.IsShowReimd()
    return StudentPage.IsShowRealName() or StudentPage.IsShowSchoolInfo() or StudentPage.IsShowClassInfo()
end

function StudentPage.IsShowRealName()
    if GameLogic.GetFilters():apply_filters('service.session.is_real_name') then
        return false
   end

   return true
end

function StudentPage.IsShowSchoolInfo()
    local profile = KeepWorkItemManager.GetProfile()
    if profile and profile.schoolId and profile.schoolId > 0 then
        return false
   end

   return true
end

function StudentPage.IsShowClassInfo()
    local profile = KeepWorkItemManager.GetProfile()

    if profile and profile.school and profile.school.type == "大学" then
       return false
   end

    if profile and profile.class ~= nil then
        return false
    end
    
    return true
end