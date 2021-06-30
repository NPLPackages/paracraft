--[[
Title: TeacherPage
Author(s): yangguiyi
Date: 2021/6/2
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SchoolCenter/TeacherPage.lua").Show();
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local KeepworkServiceSchoolAndOrg = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/SchoolAndOrg.lua")
local XcodePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SchoolCenter/XcodePage.lua")
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local QuestWork = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestWork.lua");
local TeacherPage = NPL.export();

local server_time = 0
local page

function TeacherPage.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = TeacherPage.CloseView

    if TeacherPage.show_callback then
        TeacherPage.show_callback(page)
        TeacherPage.show_callback = nil
    end

    TeacherPage.NameToFunction = {
        ["teaching_management_plaform"] = TeacherPage.OpenTeachingPlanCenter,
        ["online_plans"] = TeacherPage.OpenOnlinePlans,
        ["reset_password"] = TeacherPage.OpenResetPassWord,
        ["teach_statistics"] = TeacherPage.OpenTeachStatistics,
        ["lesson_progress"] = TeacherPage.OpenLessonProgress,
        ["work_progress"] = TeacherPage.OpenWorkProgress,
        ["3d_school"] = TeacherPage.Open3dSchool,
        ["school_page"] = TeacherPage.OpenSchoolPage,
        ["3d_school_management"] = TeacherPage.Open3dSchoolManagement,
        ["class_management"] = TeacherPage.OpenClassManagement,
        ["students_work"] = TeacherPage.OpenStudentsWork,
        ["my_work"] = TeacherPage.OpenMyWork,
        ["history_work"] = TeacherPage.OpenHistoryWork,
        ["my_project"] = TeacherPage.OpenMyProject,
        ["personal_data_statistics"] = TeacherPage.OpenPersonalDataStatistics,
        ["comple_rel_name"] = TeacherPage.OpenCompleRelName,
        ["comple_school_info"] = TeacherPage.OpenCompleSchoolInfo,
        ["comple_class_info"] = TeacherPage.OpenCompleClassInfo,
    }
end

function TeacherPage.Show(shcool_id)
    TeacherPage.shcool_id = shcool_id
    TeacherPage.ShowView()
end

function TeacherPage.ClosePage()
    page:CloseWindow(0)
    TeacherPage.CloseView()
end

function TeacherPage.ShowView()
    if page and page:IsVisible() then
        return
    end
    TeacherPage.HandleData()

    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/SchoolCenter/TeacherPage.html",
        name = "TeacherPage.Show", 
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

function TeacherPage.FreshView()
    local parent  = page:GetParentUIObject()
end

function TeacherPage.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
    TeacherPage.FreshView()
end

function TeacherPage.CloseView()
    TeacherPage.ClearData()
end

function TeacherPage.ClearData()
end

function TeacherPage.HandleData()
end

function TeacherPage.ClickBt(name)
    if TeacherPage.NameToFunction[name] then
        TeacherPage.NameToFunction[name]()
    end
end

function TeacherPage.OpenTeachingPlanCenter()
    if TeacherPage.shcool_id == nil then
        GameLogic.AddBBS(nil, L"请先加入学校", 3000, "255 0 0")
        return
    end

    KeepworkServiceSchoolAndOrg:GetUserAllOrgs(function(orgData)
        for key, item in ipairs(orgData) do
            if item.schoolId == TeacherPage.shcool_id then
                local userType = Mod.WorldShare.Store:Get('user/userType')
                if not userType or type(userType) ~= 'table' then
                    break
                end
                local orgUrl = item.orgUrl
        
                -- if userType.orgAdmin then
                --     local url = '/org/' .. orgUrl .. '/admin/packages'
                --     Mod.WorldShare.Utils.OpenKeepworkUrlByToken(url)
                -- end
                -- if userType.teacher then

                -- end
                local url = '/org/' .. orgUrl .. '/teacher/teach/'
                Mod.WorldShare.Utils.OpenKeepworkUrlByToken(url)
        
                -- if userType.student or userType.freeStudent then
                --     local url = '/org/' .. orgUrl .. '/student'
                --     Mod.WorldShare.Utils.OpenKeepworkUrlByToken(url)
                -- end

                return
            end
        end

        GameLogic.AddBBS(nil, L"请先加入学校", 3000, "255 0 0")
    end)
end

function TeacherPage.OpenOnlinePlans()
    GameLogic.AddBBS(nil, L"敬请期待", 3000, "255 0 0")
end

function TeacherPage.OpenResetPassWord()
    if TeacherPage.shcool_id == nil then
        GameLogic.AddBBS(nil, L"请先加入学校", 3000, "255 0 0")
        return
    end
    
    KeepworkServiceSchoolAndOrg:GetUserAllOrgs(function(orgData)
        for key, item in ipairs(orgData) do
            if item.schoolId == TeacherPage.shcool_id then
                -- local userType = Mod.WorldShare.Store:Get('user/userType')
                -- if not userType or type(userType) ~= 'table' then
                --     break
                -- end
                local orgUrl = item.orgUrl

                local url = '/org/' .. orgUrl .. '/admin/classes/student'
                Mod.WorldShare.Utils.OpenKeepworkUrlByToken(url)
                return
            end
        end

        GameLogic.AddBBS(nil, L"请先加入学校", 3000, "255 0 0")
    end)
end

function TeacherPage.OpenTeachStatistics()
    XcodePage.Show("teach_statistics")
end

function TeacherPage.OpenLessonProgress()
    XcodePage.Show("lesson_progress")
end

function TeacherPage.OpenWorkProgress()
    XcodePage.Show("work_progress")
end

function TeacherPage.Open3dSchool()
    if TeacherPage.shcool_id == nil then
        GameLogic.AddBBS(nil, L"请先加入学校", 3000, "255 0 0")
        return
    end
        
    KeepworkServiceSchoolAndOrg:GetUserAllOrgs(function(orgData)
        for key, item in ipairs(orgData) do
            if item.schoolId == TeacherPage.shcool_id then
                if item and item.paraWorld and item.paraWorld.projectId then
                
                    local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

                    TeacherPage.ClosePage()
                    local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")
                    if currentEnterWorld and currentEnterWorld.text then
                        _guihelper.MessageBox(
                            format(L"即将离开【%s】进入【%s】", currentEnterWorld.text, item.paraWorld.name),
                            function(res)
                                if res and res == _guihelper.DialogResult.Yes then
                                    UserConsole:HandleWorldId(item.paraWorld.projectId, true) 
                                end
                            end,
                            _guihelper.MessageBoxButtons.YesNo
                        )
                    else
                        UserConsole:HandleWorldId(item.paraWorld.projectId, true)
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

function TeacherPage.OpenSchoolPage()
    if TeacherPage.shcool_id == nil then
        GameLogic.AddBBS(nil, L"请先加入学校", 3000, "255 0 0")
        return
    end

    KeepworkServiceSchoolAndOrg:GetUserAllOrgs(function(orgData)
        for key, item in ipairs(orgData) do
            if item.schoolId == TeacherPage.shcool_id then
                local orgUrl = item.orgUrl or ""
        
                local url = KeepworkService:GetKeepworkUrl() .. "/org/" .. orgUrl .. "/index"

                ParaGlobal.ShellExecute("open", url, "", "", 1)

                return
            end
        end

        GameLogic.AddBBS(nil, L"请先加入学校", 3000, "255 0 0")
    end)
end

function TeacherPage.Open3dSchoolManagement()
    XcodePage.Show("3d_school_management")
end

function TeacherPage.OpenClassManagement()
    if TeacherPage.shcool_id == nil then
        GameLogic.AddBBS(nil, L"请先加入学校", 3000, "255 0 0")
        return
    end

    KeepworkServiceSchoolAndOrg:GetUserAllOrgs(function(orgData)
        for key, item in ipairs(orgData) do
            if item.schoolId == TeacherPage.shcool_id then
                -- local userType = Mod.WorldShare.Store:Get('user/userType')
                -- if not userType or type(userType) ~= 'table' then
                --     break
                -- end
                local orgUrl = item.orgUrl
        
                -- if userType.orgAdmin then
                --     local url = '/org/' .. orgUrl .. '/admin/packages'
                --     Mod.WorldShare.Utils.OpenKeepworkUrlByToken(url)
                -- end
                local url = '/org/' .. orgUrl .. '/teacher/teach/'
                Mod.WorldShare.Utils.OpenKeepworkUrlByToken(url)
                -- if userType.student or userType.freeStudent then
                --     local url = '/org/' .. orgUrl .. '/student'
                --     Mod.WorldShare.Utils.OpenKeepworkUrlByToken(url)
                -- end

                return
            end
        end

        GameLogic.AddBBS(nil, L"请先加入学校", 3000, "255 0 0")
    end)
end

function TeacherPage.OpenStudentsWork()
    -- KeepworkServiceSchoolAndOrg:GetUserAllOrgs(function(orgData)
    --     print("ccccccccccccc")
    --     echo(orgData, true)
    -- end)
    -- KeepworkServiceSchoolAndOrg:GetUserAllSchools(function(data, err)
    --     print("aaaaaaaaaaaaaaaaaa")
    --     echo(data, true)
    --     if not data or not data.id then
    --         return
    --     end

    --     KeepworkServiceSchoolAndOrg:GetMyClassList(data.id, function(data, err)
    --         print("bbbbbbbbbbbbbbbbbb")
    --         echo(data, true)
    --         if data and type(data) == 'table' then
    --             -- for key, item in ipairs(data) do
    --             --     self.classList[#self.classList + 1] = {
    --             --         id = item.id,
    --             --         name = item.name
    --             --     }
    --             -- end

    --             -- MainPagePage:GetNode('class_list'):SetUIAttribute("DataSource", self.classList)
    --         end
    --     end)
    -- end)

    GameLogic.GetFilters():apply_filters('show_offical_worlds_page')
    TeacherPage.ClosePage()
end

function TeacherPage.OpenMyWork()
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

function TeacherPage.OpenHistoryWork()
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

function TeacherPage.OpenMyProject()
    -- local page = NPL.load("Mod/GeneralGameServerMod/App/ui/page.lua");
    -- last_page_ctrl = page.ShowUserInfoPage({HeaderTabIndex="works"});
    local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua");
    Page.ShowUserInfoPage({HeaderTabIndex="works"});
end

function TeacherPage.OpenPersonalDataStatistics()
    XcodePage.Show("personal_data_statistics")
end

function TeacherPage.OpenCompleRelName()
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

function TeacherPage.OpenCompleSchoolInfo()
    local MySchool = NPL.load("(gl)Mod/WorldShare/cellar/MySchool/MySchool.lua")
    MySchool:ShowJoinSchool(function()
        KeepWorkItemManager.LoadProfile(false, function()
            local profile = KeepWorkItemManager.GetProfile()
            if profile and profile.schoolId and profile.schoolId > 0 then
                TeacherPage.shcool_id = profile.schoolId
                page:Refresh(0.01)
            end
        end)
    end)
end

function TeacherPage.OpenCompleClassInfo()
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

function TeacherPage.IsShowReimd()
    return TeacherPage.IsShowRealName() or TeacherPage.IsShowSchoolInfo() or TeacherPage.IsShowClassInfo()
end

function TeacherPage.IsShowRealName()
    if GameLogic.GetFilters():apply_filters('service.session.is_real_name') then
        return false
   end

   return true
end

function TeacherPage.IsShowSchoolInfo()
    local profile = KeepWorkItemManager.GetProfile()
    if profile and profile.schoolId and profile.schoolId > 0 then
        return false
   end

   return true
end

function TeacherPage.IsShowClassInfo()
    local profile = KeepWorkItemManager.GetProfile()

    if profile and profile.school and profile.school.type == "大学" then
       return false
   end

    if profile and profile.class ~= nil then
        return false
    end
    
    return true
end