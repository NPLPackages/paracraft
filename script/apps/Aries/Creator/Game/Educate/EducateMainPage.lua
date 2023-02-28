--[[
    author:{pbb}
    time:2023-02-14 19:42:52
    uselib:
        local EducateMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/EducateMainPage.lua")
        EducateMainPage.ShowPage()
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
local EducateProject = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Project/EducateProject.lua")
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
local EducateProjectManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Project/EducateProjectManager.lua")
local EducateMainPage = NPL.export()
EducateMainPage.tab_view_index = 1 --侧边按钮的索引
EducateMainPage.tab_index = 1 --iframe的索引
EducateMainPage.curr_course_page = 1 --新手入门当前页
EducateMainPage.taburls = {
    {url="",index = 1},
}
local page
--#82B0FF #FFFFFF
EducateMainPage.tab_buttons = {
    {value = "我的作品"},
    {value = "新手入门"},
    {value = "大赛详情"}
}
EducateMainPage.IsGetLessonData = false
EducateMainPage.LessonData = nil
EducateMainPage.IsShowLesson = false
function EducateMainPage.OnInit()
    page = document:GetPageCtrl()
    page.OnCreate = EducateMainPage.OnCreate
    GameLogic.GetFilters():add_filter("click_create_new_world",EducateMainPage.SetShowCreateWorld)
    GameLogic.GetFilters():add_filter("show_my_works",EducateMainPage.ChangeTabIndex)
    GameLogic.GetFilters():add_filter("OnWorldCreate",  EducateMainPage.OnWorldCreated)
end

function EducateMainPage.OnCreate()
    EducateMainPage.CheckShowLesson()
end

function EducateMainPage.OnWorldCreated(worldPath)
    if worldPath and worldPath ~= "" then
        EducateMainPage.ResetParams()
    end
    return worldPath
end

function EducateMainPage.ResetParams()
    EducateMainPage.isShowCreateWorld = false
    EducateMainPage.tab_view_index = nil
end

function EducateMainPage.SetShowCreateWorld()
    EducateMainPage.isShowCreateWorld = true
    EducateMainPage.tab_view_index = nil
    EducateMainPage.RefreshPage(true)
end

function EducateMainPage.ShowPage()
    if GameLogic.GetFilters():apply_filters('is_signed_in') then
        EducateMainPage.ShowView()
        return
    end
    
    GameLogic.GetFilters():apply_filters('check_signed_in', L"请先登录", function(result)
        if result == true then
            commonlib.TimerManager.SetTimeout(function()
                EducateMainPage.ShowView()
            end, 1000)
        end
    end)
end

function EducateMainPage.ShowView()
    CustomCharItems:Init();

	local Game = commonlib.gettable("MyCompany.Aries.Game")
	if(Game.is_started) then
		Game.Exit()
	end

    EducateMainPage.IsGetLessonData = false
    EducateMainPage.LessonData = nil
    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Educate/EducateMainPage.html",
        name = "EducateMainPage.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = false,
        zorder = 0,
        directPosition = true,
        cancelShowAnimation = true,
        DesignResolutionWidth = 1280,
		DesignResolutionHeight = 720,
        align = "_fi",
            x = view_width,
            y = view_height,
            width = -view_width/2,
            height = -view_height/2,
    };
    
    EducateProject.ShowCreate()
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    if(params._page ) then
		params._page.OnClose = function(bDestroy)
			EducateProject.CloseCreate()
		end
	end

    if(not KeepWorkItemManager.IsLoaded())then
		KeepWorkItemManager.GetFilter():add_filter("loaded_all", function ()
            local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
            local profile = KeepWorkItemManager.GetProfile()
            if not profile or not profile.portrait then
                return 
            end
            page:SetValue("img_protrait",profile.portrait)
            page:SetValue("txt_user",EducateMainPage.GetUserName())
		end)
	end
end

function EducateMainPage.RefreshPage(bCloseWorldList)
    if page then
        page:Refresh(0)
    end
    if bCloseWorldList then
        EducateProject.CloseCreate()
    end
end

function EducateMainPage.ChangeTabIndex(name)
    local index = tonumber(name)
    if index and index == 3 then
        EducateMainPage.OpenCompeleteUrl()
        return
    end
    EducateMainPage.isShowCreateWorld = false
    if index and index > 0 and index ~= EducateMainPage.tab_view_index then
        EducateMainPage.tab_view_index = index
        if index ~= 1 then
            EducateProject.CloseCreate()
        else
            EducateMainPage.SetWorldSize()
        end
        if EducateMainPage.tab_view_index == 2 then
            EducateMainPage.curr_course_page = 1
        end
        EducateMainPage.RefreshPage()
    end
end

function EducateMainPage.CheckShowLesson()
    local lessonNode = ParaUI.GetUIObject("lesson_button_bg")
    if not lessonNode:IsValid() then
        return 
    end
    if not EducateMainPage.IsGetLessonData then
        EducateMainPage.IsGetLessonData = true
        keepwork.classrooms.query({}, function(err, msg, data)
            if err == 200 then
                EducateMainPage.IsShowLesson = false
                if data and data.rows and #data.rows > 0 and data.count> 0 then
                    EducateMainPage.LessonData = data
                    EducateMainPage.IsShowLesson = true                    
                end
                lessonNode.visible = EducateMainPage.IsShowLesson
                return
            end
            EducateMainPage.IsShowLesson = false
            lessonNode.visible = EducateMainPage.IsShowLesson
        end)
    else
        lessonNode.visible = EducateMainPage.IsShowLesson
    end
end

function EducateMainPage.OnClickLesson()
    NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Project/ClassSelectPage.lua").ShowView(EducateMainPage.LessonData);
end

function EducateMainPage.ClosePage()
    if page then
        page:CloseWindow();
        local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepWorkService/KeepworkServiceSession.lua')
        KeepworkServiceSession:Logout(nil, function()
        Mod.WorldShare.MsgBox:Close()
            local CreateNewWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.CreateNewWorld")
            CreateNewWorld.profile = nil
            EducateMainPage.ResetParams()
            MyCompany.Aries.Game.MainLogin:next_step({IsLoginModeSelected = false})
        end)
        page = nil
    end
end

function EducateMainPage.OpenWebUrl()
    local token = commonlib.getfield("System.User.keepworktoken")
    local baseurl = "http://edu-dev.kp-para.cn/login?"
    local url = ""
    local http_env = HttpWrapper.GetDevVersion()
    if http_env == "LOCAL" or http_env == "STAGE" then
        baseurl = "http://edu-dev.kp-para.cn/login?"
    elseif http_env == "RELEASE" then
        baseurl = "http://edu-dev.kp-para.cn/login?"
    else
        baseurl = "http://edu.palaka.cn/login?"
    end
    url = baseurl.."token="..token.."&type=PC"
    GameLogic.RunCommand("/open "..url)

end

function EducateMainPage.OpenCompeleteUrl()
    local token = commonlib.getfield("System.User.keepworktoken")
    local baseurl = "https://keepwork.com/cp/home?"
    local url = baseurl.."token="..token
    GameLogic.RunCommand("/open "..url)
end

function EducateMainPage.SetWorldSize()
    EducateProject.GetUserWorldUsedSize()
end

function EducateMainPage.GetUserName()
    local profile = KeepWorkItemManager.GetProfile()
    if profile and profile.info and profile.info.name and profile.info.name ~= "" then
        return profile.info.name
    end
    return System.User.username
end

function EducateMainPage.LoginOutByErrToken(err)
    local err = err or 0
    local str = "请求数据失败，错误码是"..err
    if err == 401 then
        str = str .. "，请退出重新登陆"
    elseif err == 0 then
        str = "你的网络质量差"
    end
    GameLogic.AddBBS(nil,str)
    commonlib.TimerManager.SetTimeout(function()
        if err and err == 401 then
            EducateMainPage.ClosePage()          
        end
    end, 2000)
end

function EducateMainPage.CheckLoadBackWorld()
    if not EducateMainPage.check then
        if EducateProjectManager.CheckResumeUserWorld() then
            _guihelper.MessageBox(format(L"检测到非正常退出，是否恢复到系统自动保存的存档？", commonlib.Encoding.DefaultToUtf8(folderName)), function(res)
                if(res and res == _guihelper.DialogResult.Yes) then
                    GameLogic.AddBBS(nil,"确定")
                    -- EducateProjectManager.ResumeUserWorld()
                end
                if res and res == _guihelper.DialogResult.No then
                    GameLogic.AddBBS(nil,"取消")
                    -- EducateProjectManager.DeleteUserWorldBacks()
                end
            end, _guihelper.MessageBoxButtons.YesNo);
        end
        EducateMainPage.check = true
    end
end