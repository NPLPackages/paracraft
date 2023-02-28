--[[
Title: RedSummerCampPPtFullPage
Author(s): yangguiyi
Date: 2021/9/16
Desc: 
Use Lib:
-------------------------------------------------------
local RedSummerCampPPtFullPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtFullPage.lua");
RedSummerCampPPtFullPage.Show();
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local RedSummerCampPPtFullPage = NPL.export();
local ParacraftLearningRoomDailyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParacraftLearningRoom/ParacraftLearningRoomDailyPage.lua");
local RedSummerCampCourseScheduling = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCourseSchedulingV2.lua") 
local RedSummerCampPPtPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtPage.lua");
-- 存储所有课程数据
RedSummerCampPPtFullPage.LessonsPPtData = {}
RedSummerCampPPtFullPage.CourseTaskData = {}
-- RedSummerCampPPtFullPage.LessonFolderList = {{},{},{}}
local page
RedSummerCampPPtFullPage.DiskFolder = nil
RedSummerCampPPtFullPage.SplitKey = "_pptindex_"
function RedSummerCampPPtFullPage.OnInit()
	page = document:GetPageCtrl();
	page.OnCreate = RedSummerCampPPtFullPage.OnCreate
	page.OnClose = RedSummerCampPPtFullPage.OnClose
end

function RedSummerCampPPtFullPage.OnCreate()
	RedSummerCampPPtFullPage.StepNumKey = 0

	if RedSummerCampPPtFullPage.is_expore_mode then
		local rt_container = page:FindControl("rt_container")
		if rt_container then
			rt_container.visible=false
		end

		local export_mode_container = page:FindControl("export_mode_container")
		if export_mode_container then
			export_mode_container.visible=true
		end
	end

	RedSummerCampPPtFullPage.RefreshSize()
end

function RedSummerCampPPtFullPage.OnClose()
	-- RedSummerCampPPtFullPage.IsInFullPage = false
	RedSummerCampPPtPage.SetIsFullPage(false)
	RedSummerCampPPtPage.RefreshPage()

	if RedSummerCampPPtFullPage.CloseTimer then
		RedSummerCampPPtFullPage.CloseTimer:Change(nil)
		RedSummerCampPPtFullPage.CloseTimer = nil
	end
end

function RedSummerCampPPtFullPage.ClosePage()
	if page then
		page:CloseWindow(true)
		page = nil
	end
end

function RedSummerCampPPtFullPage.Show(div_str, zorder, is_expore_mode)
	div_str = div_str or ""
	RedSummerCampPPtPage.SetIsFullPage(true)
	-- RedSummerCampPPtFullPage.IsInFullPage = true
	RedSummerCampPPtFullPage.InitData(div_str)
	RedSummerCampPPtFullPage.is_expore_mode = is_expore_mode
	
	local enable_esc_key = System.options.isDevMode
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtFullPage.html",
			name = "RedSummerCampPPtFullPage.Show", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			enable_esc_key = enable_esc_key,
			cancelShowAnimation = true,
			-- DesignResolutionWidth = 1280,
			-- DesignResolutionHeight = 720,
			zorder=zorder or 0,
			--app_key = 0, 
			directPosition = true,
				align = "_fi",
				x = 0,
				y = 0,
				width = 0,
				height = 0,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
	local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
	local viewport = ViewportManager:GetSceneViewport();
	viewport:Connect("sizeChanged", CodeLessonTip, function()
		commonlib.TimerManager.SetTimeout(function()
			RedSummerCampPPtFullPage.RefreshSize()
		end, 50);
		
	end, "UniqueConnection");

	GameLogic.GetFilters():add_filter("File.MCMLWindowFrame",RedSummerCampPPtFullPage.OnPageOpen)
	GameLogic.GetFilters():add_filter("File.MCMLWindowFrameClose",RedSummerCampPPtFullPage.OnPageClose)
	GameLogic:Connect("WorldLoaded", RedSummerCampPPtFullPage, RedSummerCampPPtFullPage.OnWorldLoaded, "UniqueConnection");
end

function RedSummerCampPPtFullPage.RefreshSize()
    if not page or not page:IsVisible() then
        return
    end

	local Screen = commonlib.gettable("System.Windows.Screen");
	local win_width = Screen:GetWidth()
	local win_height = Screen:GetHeight()
	local page_root = ParaUI.GetUIObject("PPTFullPageRoot");
	page_root.width = win_width
	page_root.height = win_height

	-- commonlib.TimerManager.SetTimeout(function()
	-- 	RedSummerCampPPtFullPage.RefreshVideoSize()
	-- end, 100);
	
end

function RedSummerCampPPtFullPage.RefreshPage()
	if page then
		RedSummerCampPPtFullPage.StepNumKey = 0
		page:Refresh(0)
	end
end

function RedSummerCampPPtFullPage.InitData(div_str)
	RedSummerCampPPtFullPage.StepNumKey = 0
	RedSummerCampPPtFullPage.ShowDivStr = div_str
end


function RedSummerCampPPtFullPage.SetStepNumKey(key)
	RedSummerCampPPtFullPage.StepNumKey = key
end

function RedSummerCampPPtFullPage.GetStepNumKey()
	return RedSummerCampPPtFullPage.StepNumKey
end

function RedSummerCampPPtFullPage.GetPPtStr()
	return RedSummerCampPPtFullPage.ShowDivStr
end

function RedSummerCampPPtFullPage.GetPPtTitle()
	if RedSummerCampPPtFullPage.title then
		return RedSummerCampPPtFullPage.title
	end

	return RedSummerCampPPtPage.GetPPtTitle()
end

function RedSummerCampPPtFullPage.IsOpen()
	return page and page:IsVisible()
end

function RedSummerCampPPtFullPage.RefreshVideoSize()
	if not page then
		return
	end
	local contain_node = page:FindControl("pptvideo_container")
	if not contain_node or not contain_node:IsValid() then
		return
	end

	local Screen = commonlib.gettable("System.Windows.Screen");
	local win_width = Screen:GetWidth()
	local win_height = Screen:GetHeight()

	local browser_node = page:GetNode("nplbrowser_pptvideo")
	local NplBrowserPlugin = commonlib.gettable("NplBrowser.NplBrowserPlugin");
	local screen_x, screen_y, screen_width, screen_height = contain_node:GetAbsPosition();
	local uiScales = Screen:GetUIScaling(true);
	
	if (uiScales[1] ~= 1 or uiScales[2] ~= 1) then
		screen_x = math.floor(screen_x * uiScales[1]);
		screen_y = math.floor(screen_y * uiScales[2]);
		screen_width = math.floor(screen_width * uiScales[1]);
		screen_height = math.floor(screen_height * uiScales[2]);
	end
    -- local x = screen_x + 0;
	-- local y = screen_y + 0;
	NplBrowserPlugin.ChangePosSize({id = "nplbrowser_pptvideo", x = screen_x, y = screen_y, width = screen_width, height = screen_height, });
end

function RedSummerCampPPtFullPage.ChangeVideoVisible(flag)
	local browser_node = page:GetNode("nplbrowser_pptvideo")
	if browser_node then
		page:CallMethod("nplbrowser_pptvideo","SetVisible",flag)
		if not flag then
			local NplBrowserManager = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserManager.lua");	
			NplBrowserManager:PauseVideo()
		end
	end	
end

function RedSummerCampPPtFullPage.ClosePageWithAnim()
	RedSummerCampPPtFullPage.ChangeVideoVisible(false)
	local root = ParaUI.GetUIObject("PPTFullPageRoot");
	root:ApplyAnim();
	root.enabled = false
	local anim_time = 300 --ms
	local interval = 15 --ms
	local change_times = math.floor(anim_time/interval)

	-- local start_pos_x = root.width/2
	-- local start_pos_y = root.height/2
	-- local end_pos_x = 176
	-- local end_pos_y = 100

	-- local dis = math.sqrt((start_pos_y - end_pos_y) ^ 2 + (start_pos_x - end_pos_x) ^ 2)
	-- -- dis = string.format("%.1f",dis/change_times)
	-- local move_change_value = string.format("%.1f",dis/change_times)
	
	
	local scale_change_value = -string.format("%.2f",1/change_times)
	
	if not RedSummerCampPPtFullPage.CloseTimer then
		local ui_scale = 1
		RedSummerCampPPtFullPage.CloseTimer = commonlib.Timer:new({callbackFunc = function(timer)
			if ui_scale <= 0 or not page then
				ui_scale = 1
				RedSummerCampPPtFullPage.ClosePage()
				if RedSummerCampPPtFullPage.CloseTimer then
					RedSummerCampPPtFullPage.CloseTimer:Change(nil);	
				end
				
				return
			end

			ui_scale = ui_scale + scale_change_value
			-- local root = page:GetRootUIObject()
			root = ParaUI.GetUIObject("PPTFullPageRoot");
			root.scalingx = ui_scale
			root.scalingy = ui_scale
			
			root.x = root.x - 26
			root.y = root.y + 14
			root:ApplyAnim();
		end})
	end

	RedSummerCampPPtFullPage.CloseTimer:Change(0, interval);	

end

function RedSummerCampPPtFullPage.OnPageOpen(params)
	commonlib.TimerManager.SetTimeout(function()
		if not page or not page:IsVisible() then
			return
		end
	
		local _app = CommonCtrl.os.GetApp("WebBrowser_GUID")
		local _wnd = _app:FindWindow("RedSummerCampPPtFullPage.Show")
		local _wndFrame = _wnd:GetWindowFrame();
		if not _wndFrame:IsTopFrame() and params.name ~= "MsgBox" and params.name ~= "TeacherAgent.TeacherIcon.ShowPage" then
			RedSummerCampPPtFullPage.ChangeVideoVisible(false)
		end
	end, 10);
end

function RedSummerCampPPtFullPage.OnPageClose()
	commonlib.TimerManager.SetTimeout(function()
		if not page or not page:IsVisible() then
			return
		end
	
		local ppt_data = RedSummerCampPPtPage.LessonsPPtData[RedSummerCampPPtPage.SelectLessonIndex] or {}
		local _app = CommonCtrl.os.GetApp("WebBrowser_GUID")
		local _wnd = _app:FindWindow("RedSummerCampPPtFullPage.Show")
		local _wndFrame = _wnd:GetWindowFrame();
		if (_wndFrame:IsTopFrame() or RedSummerCampPPtPage.IsTopPage()) and ppt_data.IsUseVideoPage and RedSummerCampPPtFullPage.IsOpen() and not RedSummerCampPPtFullPage.CloseTimer then
			RedSummerCampPPtFullPage.ChangeVideoVisible(true)
		end
	end, 100);
end

function RedSummerCampPPtFullPage.OnWorldLoaded()
	if page then
		-- body
		page:CloseWindow(true)
		page = nil
	end
end