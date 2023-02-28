--[[
Title: RedSummerCampPPtPage
Author(s): yangguiyi
Date: 2021/9/16
Desc: 
Use Lib:
-------------------------------------------------------
local RedSummerCampPPtPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtPage.lua");
RedSummerCampPPtPage.Show();
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
-- local RedSummerCampPPtPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtPage.lua") or NPL.export();
local RedSummerCampPPtPage = NPL.export();
local ParacraftLearningRoomDailyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParacraftLearningRoom/ParacraftLearningRoomDailyPage.lua");
local RedSummerCampCourseScheduling = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCourseSchedulingV2.lua") 
local RedSummerCampMainWorldPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampMainWorldPage.lua");
local RedSummerCampPPtFullPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtFullPage.lua");
local ClassSchedule = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/ClassSchedule/ClassSchedule.lua") 
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/HelpPage.lua");
local HelpPage = commonlib.gettable("MyCompany.Aries.Game.Tasks.HelpPage");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestAction.lua");
local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
local Lan
-- 存储所有课程数据
RedSummerCampPPtPage.LessonsPPtData = {}
RedSummerCampPPtPage.CourseTaskData = {}
RedSummerCampPPtPage.PPtCacheData = {}
-- RedSummerCampPPtPage.LessonFolderList = {{},{},{}}
local page
RedSummerCampPPtPage.DiskFolder = nil
RedSummerCampPPtPage.SplitKey = "_pptindex_"
RedSummerCampPPtPage.ProjectIdToProjectData = {}
RedSummerCampPPtPage.ForbidVideoFunction = false

local key_to_report_name = {
	["ppt_L1"] = "org",		-- 机构课L1
	["ppt_L2"] = "org_L2",	-- 机构课L2
	["ppt_S1"] = "430",		-- 社团课S1
	["ppt_X1"] = "campus",	-- 校园课X1
	["ppt_Z1"] = "demo_lesson",
}
function RedSummerCampPPtPage.OnInit()
	page = document:GetPageCtrl();
	page.OnLoad = RedSummerCampPPtPage.OnLoad
	page.OnCreate = RedSummerCampPPtPage.OnCreate
	page.OnClose = RedSummerCampPPtPage.OnClose
end

function RedSummerCampPPtPage.OnLoad()
	RedSummerCampPPtPage.ChangeVideoVisible(RedSummerCampPPtPage.UseVideoPage())

	RedSummerCampPPtPage.CheckVideo()
end

function RedSummerCampPPtPage.SetisLoadVideo(flag)
	RedSummerCampPPtPage.isLoadVideo = flag
end

function RedSummerCampPPtPage.OnCreate()
	local f1_node = page:GetNode("div_f1")
	if f1_node then
		local f1_text = f1_node:GetInnerText()
		--local f1_text = "F1:“新手小屋”、“让角色向前走”"
		-- f1_text = string.gsub(f1_text, "、", "，")
		-- f1_text = string.gsub(f1_text, "[F1:“”]+", "")
		local str_list = commonlib.split_by_str(f1_text,"、")
		for k, v in pairs(str_list) do
			str_list[k] = string.gsub(str_list[k], "F1:", "")
			str_list[k] = string.gsub(str_list[k], "”", "")
			str_list[k] = string.gsub(str_list[k], "“", "")
		end
		HelpPage.SetSearchIndexStrList(str_list)
	end

	-- RedSummerCampPPtPage.RefreshSize()
	RedSummerCampPPtPage.StepNumKey = 0
	GameLogic.GetFilters():add_filter("starting_class",RedSummerCampPPtPage.OnClassStarted)
	GameLogic.GetFilters():add_filter("ending_class",RedSummerCampPPtPage.OnClassEnded)
	GameLogic.GetFilters():add_filter("nplbrowser_checked", RedSummerCampPPtPage.onNplbrowserChecked);
	RedSummerCampPPtPage.UpdateSectionsAuths()
end

function RedSummerCampPPtPage.OnClassStarted()
	--print("-------课程开始，刷新按钮",ClassSchedule.IsInClassNow())
	if page then
		page:Refresh(0)
	end
end

function RedSummerCampPPtPage.OnClassEnded()
	if page then
		page:Refresh(0)
	end
end

function RedSummerCampPPtPage.onNplbrowserChecked()
	commonlib.TimerManager.SetTimeout(function()
		RedSummerCampPPtPage.RefreshPage()
	end,500)
	
	commonlib.TimerManager.SetTimeout(function()
		if RedSummerCampPPtPage.isLoadVideo then
			return
		end
		if page then
			RedSummerCampPPtPage.ForbidVideoFunction = false
			GameLogic.GetFilters():apply_filters("cellar.common.msg_box.close");
			
			RedSummerCampPPtPage.RefreshPage()
		end
	end,4000)
end

function RedSummerCampPPtPage.ClosePage()
	if RedSummerCampPPtPage.OpenPageTimeStamp then
		local extend_data = {}
		extend_data.duration = QuestAction.GetServerTime() - RedSummerCampPPtPage.OpenPageTimeStamp
		local action = string.format("crsp.course.exit-%s", RedSummerCampPPtPage.CurCourseName)
		GameLogic.GetFilters():apply_filters('user_behavior', 1, action, RedSummerCampPPtPage.GetReportData(extend_data))
		RedSummerCampPPtPage.OpenPageTimeStamp = nil
	end

	RedSummerCampPPtPage.ChangeVideoVisible(false)
	if page then
		page:CloseWindow(true)
		page = nil
	end
end

function RedSummerCampPPtPage.IsVisible()
	return page~=nil
end

function RedSummerCampPPtPage.OnClose()
	if not RedSummerCampPPtPage.IsSaveIndex then
		RedSummerCampPPtPage.IsOpenPage = false
	end

	RedSummerCampPPtPage.ChangeVideoVisible(false)

	page = nil
	RedSummerCampPPtPage.IsSaveIndex = nil
	RedSummerCampMainWorldPage.SetOpenFromCommandMenu(false)

	RedSummerCampPPtPage.UpdateTimer:Change()
	RedSummerCampPPtPage.UpdateTimer = nil
	RedSummerCampPPtPage.is_in_debug = false	
	RedSummerCampPPtPage.is_preview = false
	RedSummerCampPPtPage.defaul_select_index = nil
	RedSummerCampPPtPage.is_in_create_world = false
	RedSummerCampPPtPage.InCloseAnim = false
	RedSummerCampPPtPage.DebugData = {}

	GameLogic.GetFilters():remove_filter("starting_class",RedSummerCampPPtPage.OnClassStarted)
	GameLogic.GetFilters():remove_filter("ending_class",RedSummerCampPPtPage.OnClassEnded)
	GameLogic.GetFilters():remove_filter("nplbrowser_checked", RedSummerCampPPtPage.onNplbrowserChecked);
	
end

-- 获取选中的章节的服务器数据
function RedSummerCampPPtPage.GetCurSelectLessonData(callback)
	if RedSummerCampPPtPage.SelectPPtData and RedSummerCampPPtPage.SelectPPtData.is_ppt_cover then
		if callback then
			callback()
		end
		return
	end

	local course_data = RedSummerCampPPtPage.CourseConfigData
	local lesson_index = RedSummerCampPPtPage.GetLessonServerIndex()

	if not course_data then
		return
	end

	keepwork.courses.getSectionStudyProgresses({
		sectionIndex = lesson_index,
		courseId = course_data.id,
		}, function(err, msg, data)

			if err == 200 then
				local lesson_data = data[1] or {}
				RedSummerCampPPtPage.CurLessonData = {
					courseId = lesson_data.courseId or course_data.id,
					status = lesson_data.status or 0,
					completedAt = lesson_data.completedAt,
					extra = lesson_data.extra or {},
					sectionIndex = lesson_data.sectionIndex or lesson_index,
					sectionId = lesson_data.sectionId or lesson_index,
					completedStepCount = lesson_data.completedStepCount,
					createdAt = lesson_data.createdAt,
				}
				if RedSummerCampPPtPage.CurLessonData.createdAt then
					RedSummerCampPPtPage.CurLessonData.start_time_stamp = commonlib.timehelp.GetTimeStampByDateTime(RedSummerCampPPtPage.CurLessonData.createdAt)
				end
			end

			if callback then
				callback(course_data, pptIndex)
			end
		end)
end

-- 设置选中的章节的服务器数据
function RedSummerCampPPtPage.SetSelectLessonData(callback)
	if not RedSummerCampPPtPage.CurLessonData then
		return
	end

	if not RedSummerCampPPtPage.CurLessonData.courseId or RedSummerCampPPtPage.CurLessonData.courseId == 0 then
		return
	end
	
	keepwork.courses.setSectionStudyProgresses(RedSummerCampPPtPage.CurLessonData, function(err, msg, data)
		if err == 200 then
			if not RedSummerCampPPtPage.CurLessonData.start_time_stamp then
				RedSummerCampPPtPage.CurLessonData.start_time_stamp = QuestAction.GetServerTime()
			end
			
			if callback then
				callback()
			end
		end
	end)
end

-- 获取当前的课程包数据
function RedSummerCampPPtPage.GetCurCourseData(callback)
	local course_data = RedSummerCampPPtPage.CourseConfigData

	if not course_data then
		return
	end
	keepwork.courses.getCourseStudyProgresses({
		courseId = course_data.id,
		}, function(err, msg, data)
			if err == 200 then
				RedSummerCampPPtPage.CurCourseData = {
					courseId = data.courseId or course_data.id,
					status = data.status or 0,
					completedAt = data.completedAt or 0,
					extra = data.extra or {},
					completedSectionCount = data.completedSectionCount or 0,
					completedStepCount = data.completedStepCount or 0,
				}

				if RedSummerCampPPtPage.CurCourseData.createdAt then
					RedSummerCampPPtPage.CurCourseData.start_time_stamp = commonlib.timehelp.GetTimeStampByDateTime(RedSummerCampPPtPage.CurCourseData.createdAt)
				end
			end

			if callback then
				callback()
			end
		end)
end

-- 设置当前的课程包数据
function RedSummerCampPPtPage.SetCurCourseData(callback)
	if not RedSummerCampPPtPage.CurCourseData then
		return
	end

	if not RedSummerCampPPtPage.CurLessonData.courseId or RedSummerCampPPtPage.CurLessonData.courseId == 0 then
		return
	end

	local data = {
		courseId = RedSummerCampPPtPage.CurCourseData.courseId,
		status = RedSummerCampPPtPage.CurCourseData.status,
		completedAt = RedSummerCampPPtPage.CurCourseData.completedAt,
		extra = RedSummerCampPPtPage.CurCourseData.extra,
	}
	keepwork.courses.setCourseStudyProgresses(data, function(err, msg, data)
		if err == 200 then
			if callback then
				callback()
			end
		end
	end)
end

function RedSummerCampPPtPage.CheckPPtConfigFile(course_data, pptIndex, callback)
	course_data = course_data or {}
	if not course_data.md5 then
		return
	end
	local course_name = course_data.code or "ppt_X1"
	RedSummerCampPPtPage.md5_file_name = course_data.md5

	local disk_folder = RedSummerCampPPtPage.GetPPTConfigDiskFolder()
	local filename = RedSummerCampPPtPage.md5_file_name .. ".xml"
	local file_path = string.format("%s/%s/%s", disk_folder, course_name, filename)
	if ParaIO.DoesFileExist(file_path, true) then
		if callback then
			callback(course_name, pptIndex)
		end
	else
		local course_id = course_data.id or 1
		keepwork.courses.course_info({
			router_params = {
				id = course_id,
			}
		},function(err, msg, data)
			if err == 200 then
				if data.xml then
					ParaIO.CreateDirectory(file_path)
					local file = ParaIO.open(file_path, "w");
					if(file) then
						file:write(data.xml, #data.xml);
						file:close();
					end
					-- 清除课包缓存
					if RedSummerCampPPtPage.PPtCacheData and RedSummerCampPPtPage.PPtCacheData[course_name] then
						RedSummerCampPPtPage.PPtCacheData[course_name] = nil
					end
					
					if callback then
						callback(course_name, pptIndex)
					end
				end
			end
		end)	
	end
end

function RedSummerCampPPtPage.Show(course_data, pptIndex, is_show_exit_bt, server_index)
	if not course_data then
		course_data = RedSummerCampPPtPage.CourseConfigData or "ppt_X1"
	end
	if not pptIndex then
		if RedSummerCampPPtPage.CourseConfigData and course_data then
			if RedSummerCampPPtPage.CourseConfigData.code ~= course_data.code then
				pptIndex = 1
			end
		end
	end
	RedSummerCampPPtPage.SectionAuths = nil
	RedSummerCampPPtPage.CourseConfigData = course_data
	RedSummerCampPPtPage.last_course_data = course_data
	if not Lan then
		Lan = NPL.load("Mod/GeneralGameServerMod/Command/Lan/Lan.lua");
	end
	RedSummerCampPPtPage.IsLockCourse = false
	RedSummerCampPPtPage.is_show_exit_bt = is_show_exit_bt
	if type(course_data) == "table" then
		RedSummerCampPPtPage.UseNewFilePath = true
		RedSummerCampPPtPage.IsLockCourse = not course_data.auth

		RedSummerCampPPtPage.CheckPPtConfigFile(course_data, pptIndex, function(course_name, pptIndex)
			RedSummerCampPPtPage.ShowPage(course_name, pptIndex, server_index)
		end)
	else
		RedSummerCampPPtPage.UseNewFilePath = false
		local course_name = course_data
		RedSummerCampPPtPage.ShowPage(course_name, pptIndex)
	end

end

function RedSummerCampPPtPage.ShowPage(course_name, pptIndex, server_index)
	GameLogic.GetFilters():apply_filters("OnShowPPTPage", bShow);
	if not RedSummerCampPPtPage.OpenPageTimeStamp then
		RedSummerCampPPtPage.OpenPageTimeStamp = QuestAction.GetServerTime()
	end
	
	if course_name == nil then
		course_name = RedSummerCampPPtPage.CurCourseName or "ppt_X1"
		
	end

	if pptIndex == nil then
		pptIndex = RedSummerCampPPtPage.SelectLessonIndex or 1
	end
	RedSummerCampPPtPage.SetIsFullPage(false)
	course_name = course_name or "ppt_X1"
	RedSummerCampPPtPage.SelectLessonIndex = pptIndex or 1
	if RedSummerCampPPtPage.defaul_select_index then
		RedSummerCampPPtPage.SelectLessonIndex = RedSummerCampPPtPage.defaul_select_index
	end

	RedSummerCampPPtPage.StepValueToProjectId = {}
	RedSummerCampPPtPage.SaveWorldStepList = {}
	RedSummerCampPPtPage.SyncWorldStepValue = nil
	RedSummerCampPPtPage.CurCourseName = course_name
	RedSummerCampPPtPage.StepNumKey = 0
	RedSummerCampPPtPage.CurCourseKey = RedSummerCampPPtPage.CurCourseName .. RedSummerCampPPtPage.SplitKey .. RedSummerCampPPtPage.SelectLessonIndex
	RedSummerCampPPtPage.InitData()

	-- 处理server_index 如果有 以传进来的服务器index为准
	if server_index then
		RedSummerCampPPtPage.SelectLessonIndex = RedSummerCampPPtPage.GetLessonClientIndexByServerIndex(server_index)
		local ppt_data = RedSummerCampPPtPage.LessonsPPtData[RedSummerCampPPtPage.SelectLessonIndex] or {}

		if RedSummerCampPPtPage.IsLockCourse and not ppt_data.is_ppt_cover then
			RedSummerCampPPtPage.SelectLessonIndex = 1
				-- local strTip = "你暂时没有该课程的访问权限，请联系客服或使用对应的激活码。"
				-- _guihelper.MessageBox(strTip,nil,_guihelper.MessageBoxButtons.OK_CustomLabel,nil,"script/apps/Aries/Creator/Game/GUI/DefaultMessageBox.lesson.html")
		else
			RedSummerCampPPtPage.SelectPPtData = ppt_data
		end
	end

    -- local parentDir = GameLogic.GetWorldDirectory();
    -- local path = string.format("%s%s", parentDir, "RedSummerCampPPtPage.html")
	local enable_esc_key = RedSummerCampPPtPage.is_in_debug
	local params = {
			-- url = path,
			url = "script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtPage.html",
			name = "RedSummerCampPPtPage.Show", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			enable_esc_key = enable_esc_key,
			cancelShowAnimation = true,
			click_through = false,
			--app_key = 0, 
			directPosition = true,
				align = "_fi",
				x = 0,
				y = 0,
				width = 0,
				height = 0,
		};

	if not (RedSummerCampPPtPage.is_in_debug and RedSummerCampPPtPage.is_preview) then
		params.DesignResolutionWidth = 1280
		params.DesignResolutionHeight = 720
	end

	System.App.Commands.Call("File.MCMLWindowFrame", params);

	-- RedSummerCampPPtPage.HandleErrorData()

	if not RedSummerCampPPtPage.BindFilter then
		RedSummerCampPPtPage.BindFilter = true
		GameLogic.GetFilters():add_filter("OnSaveWrold", RedSummerCampPPtPage.OnSaveWrold);
		GameLogic.GetFilters():add_filter("SyncWorldFinish", RedSummerCampPPtPage.OnSyncWorldFinish);
		GameLogic.GetFilters():add_filter("lessonbox_change_region_blocks",RedSummerCampPPtPage.ReportCreateBlockInCourse)
		GameLogic.GetFilters():add_filter("OnBeforeLoadWorld",RedSummerCampPPtPage.OnBeforeLoadWorld)

		GameLogic.GetFilters():add_filter("File.MCMLWindowFrame",RedSummerCampPPtPage.OnPageOpen)
		GameLogic.GetFilters():add_filter("File.MCMLWindowFrameClose",RedSummerCampPPtPage.OnPageClose)

		GameLogic:Connect("WorldLoaded", RedSummerCampPPtPage, RedSummerCampPPtPage.OnWorldLoaded, "UniqueConnection");
		-- GameLogic:Connect("OnBeforeLoadWorld", RedSummerCampPPtPage, RedSummerCampPPtPage.OnBeforeLoadWorld, "UniqueConnection");
		
		GameLogic:Connect("WorldUnloaded", RedSummerCampPPtPage, RedSummerCampPPtPage.OnWorldUnloaded, "UniqueConnection");

		NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
		local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
        local viewport = ViewportManager:GetSceneViewport();
        viewport:Connect("sizeChanged", CodeLessonTip, function()
			commonlib.TimerManager.SetTimeout(function()
				RedSummerCampPPtPage.RefreshSize()
			end, 100);
			
		end, "UniqueConnection");

		GameLogic.GetEvents():AddEventListener("CodeBlockWindowShow", RedSummerCampPPtPage.CodeWinChangeVisible, RedSummerCampPPtPage, "RedSummerCampPPtPage");
		
	end
	GameLogic.GetEvents():AddEventListener("createworld_callback", RedSummerCampPPtPage.CreateWorldCallback, RedSummerCampPPtPage, "RedSummerCampPPtPage");
	if RedSummerCampPPtFullPage.IsInFullPage then
		RedSummerCampPPtFullPage.Show(RedSummerCampPPtPage.GetPPtStr());
	end

	if RedSummerCampPPtPage.UpdateTimer == nil then
		RedSummerCampPPtPage.UpdateTimer = commonlib.Timer:new({callbackFunc = function(timer)
			RedSummerCampPPtPage.UpdateStudentNum()
		end})
		RedSummerCampPPtPage.UpdateTimer:Change(0, 1000);	
	end

	-- 上报
	local action = string.format("crsp.course.visit-%s", RedSummerCampPPtPage.CurCourseName)
	GameLogic.GetFilters():apply_filters('user_behavior', 1, action, RedSummerCampPPtPage.GetReportData())

	-- 上报
	local action = string.format("crsp.course.section.visit-%s-%s", RedSummerCampPPtPage.CurCourseName, RedSummerCampPPtPage.SelectLessonIndex)
	GameLogic.GetFilters():apply_filters('user_behavior', 1, action, RedSummerCampPPtPage.GetReportData({section = RedSummerCampPPtPage.SelectLessonIndex}))

	RedSummerCampPPtPage.GetProjectListData(function()
		RedSummerCampPPtPage.GetCurCourseData(function()
			RedSummerCampPPtPage.GetCurSelectLessonData(function()
				RedSummerCampPPtPage.RefreshPage()
			end)
		end)	
	end)

	page:CallMethod("slot_gridview", "ScrollToRow", RedSummerCampPPtPage.SelectLessonIndex)

	ClassSchedule.ReqScheduleOfWeek(nil,function()

		if page then
			page:Refresh(0)
		end
	end)

	RedSummerCampPPtPage.RefreshVideoSize()
end

function RedSummerCampPPtPage.CodeWinChangeVisible(event)
    RedSummerCampPPtPage.IsShowCodeWin = RedSummerCampPPtPage.IsEditorOpen()
    RedSummerCampPPtPage.RefreshSize()
end

function RedSummerCampPPtPage.CreateWorldCallback(_, event)
    if not page or not page:IsVisible() then
        return
    end
	local CreateWorldLoadingPgae = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/CreateWorldLoadingPgae.lua")
	if CreateWorldLoadingPgae.IsOpen() then
		CreateWorldLoadingPgae.SetSpecialFlag(true);
	end
	
	-- GameLogic.RunCommand(string.format('/loadworld %s', commonlib.Encoding.DefaultToUtf8(event.world_path)))
	
end

function RedSummerCampPPtPage.SetIsInDebug(flag)
	RedSummerCampPPtPage.is_in_debug = flag
end

function RedSummerCampPPtPage.SetIsPreview(flag)
	RedSummerCampPPtPage.is_preview = flag
end

function RedSummerCampPPtPage.RefreshSize()
    if not page or not page:IsVisible() then
        return
    end

	-- local Screen = commonlib.gettable("System.Windows.Screen");
	-- local win_width = Screen:GetWidth()
	-- local win_height = Screen:GetHeight()
	-- if RedSummerCampPPtPage.is_in_debug and RedSummerCampPPtPage.is_preview then
	-- 	local grid_node = page:GetNode("slot_gridview")
	-- 	local TreeViewNode = grid_node:GetChild("pe:treeview");
	-- 	local treeview_object = ParaUI.GetUIObject(TreeViewNode.control.name);
	-- 	if treeview_object:IsValid() then
	-- 		local VScrollBar = treeview_object:GetChild("VScrollBar");
	-- 		if VScrollBar:IsValid() then
	-- 			VScrollBar.visible = false
	-- 		end
	-- 	end

	-- 	local grid_node = page:GetNode("notes_gridview")
	-- 	if grid_node then
	-- 		local TreeViewNode = grid_node:GetChild("pe:treeview");
	-- 		local treeview_object = ParaUI.GetUIObject(TreeViewNode.control.name);
	-- 		if treeview_object:IsValid() then
	-- 			local VScrollBar = treeview_object:GetChild("VScrollBar");
	-- 			if VScrollBar:IsValid() then
	-- 				VScrollBar.visible = false
	-- 			end
	-- 		end
	-- 	end
		

	-- 	TreeViewNode:SetAttribute("HideVerticalScrollBar", true);
		
	-- 	NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
	-- 	local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
	-- 	-- local bShow = event.bShow
	-- 	local viewport = ViewportManager:GetSceneViewport();
	-- 	local view_x,view_y,view_width,view_height = viewport:GetUIRect()

	-- 	local page_root = ParaUI.GetUIObject("PPTPageRoot");
		
	-- 	local scale = view_width/1280
	-- 	page_root.x = -(win_width/2-win_width*scale/2)/scale
	-- 	page_root.y = -(win_height/2 - win_height*scale/2)/scale
	-- 	local root = page:GetRootUIObject()
	-- 	local att = ParaEngine.GetAttributeObject();
		
	-- 	root.scalingx = scale
	-- 	root.scalingy = scale
	-- 	root:ApplyAnim();
	-- 	root.enabled = false
		
	-- else
	-- 	local page_root = ParaUI.GetUIObject("PPTPageRoot");
	-- 	page_root.width = win_width
	-- 	page_root.height = win_height
	-- end

	RedSummerCampPPtPage.RefreshVideoSize()
end

-- 代码编辑器是否打开
function RedSummerCampPPtPage.IsEditorOpen()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockWindow.lua");
	local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
    return CodeBlockWindow.IsVisible();
end

function RedSummerCampPPtPage.RefreshPage()
	if page then
		RedSummerCampPPtPage.SetSyncWorldStepValue(nil)
		RedSummerCampPPtPage.StepNumKey = 0
		page:Refresh(0)
	end
end

function RedSummerCampPPtPage.GetCourseStrName()
	for key, v in pairs(RedSummerCampCourseScheduling.lessonCnf) do
		if v.key == RedSummerCampPPtPage.CurCourseName then
			return v.name
		end
	end
end

function RedSummerCampPPtPage.SetStepNumKey(key)
	RedSummerCampPPtPage.StepNumKey = key
end

function RedSummerCampPPtPage.GetStepNumKey()
	return RedSummerCampPPtPage.StepNumKey
end

function RedSummerCampPPtPage.InitPPtConfig(course_name)
	-- local ppt_mark_down_file = string.format("config/Aries/creator/lesson_ppt/%s.md.xml", course_name)
	local file_path = string.format("config/Aries/creator/lesson_ppt/%s.md.xml", course_name)
	if RedSummerCampPPtPage.UseNewFilePath then
		local disk_folder = RedSummerCampPPtPage.GetPPTConfigDiskFolder()
		local md5_file_name = RedSummerCampPPtPage.md5_file_name or ""
		local filename = md5_file_name .. ".xml"
		file_path = string.format("%s/%s/%s", disk_folder, course_name, filename)
	end

	local file = ParaIO.open(file_path, "r");
	if(file:IsValid() ~= true) then
		commonlib.log("error: failed loading card data list file: %s\n", course_name);
		return;
	end

	local strValue = file:readline();
	RedSummerCampPPtPage.PPtName = ""
	local ppt_data_list = {}
	local ppt_data = {}
	local is_div_str = false
	local max_step = 0
	local last_div_is_title = false
	local is_start_notes = false
	local is_start_knowledge_point = false
	local is_hide_div = false
	local profile = KeepWorkItemManager.GetProfile() or {}
	local has_power = RedSummerCampPPtPage.GetTeachingPlanPower()
	local function handle_div_str(ppt_data, strValue)
		if last_div_is_title then
			local str = string.gsub(strValue, "<br/>", "")
			if not string.find(str, "<") then
				strValue = string.format([[<div class="step_1_title">%s</div>]], strValue)
				local start_index = string.find(strValue, "《")
				local end_index = string.find(strValue, "》")
				if start_index and end_index then
					ppt_data.step_1_title = string.sub(strValue, start_index + 3, end_index - 1)
					ppt_data.step_1_title = string.gsub(ppt_data.step_1_title, "<br/>", "")
				end
			end
		end

		if RedSummerCampPPtPage.IsSupportVideo() and string.find(strValue, "nplbrowser_pptvideo") then
			ppt_data.IsUseVideoPage = true
			ppt_data.UseMiddleTitle = true
			-- local strValue = [[<pe:nplbrowser name="nplbrowser_pptvideo" min_width="802" min_height="452" url="https://www.baidu.com/" style="" visible="true"/>]]
			-- local temp_str = string.gsub(strValue, "%s+", "")
			-- local video_src = string.match(temp_str, 'url="(https://%w+/)"')
		end

		if string.find(strValue, 'class="F1"') then
			strValue = string.gsub(strValue, 'class="F1"', 'class="F1" name="div_f1"')
		end

		if string.find(strValue, '<step value="1">') then
			last_div_is_title = true
		else
			last_div_is_title = false
		end

		local is_end_hide = false
		local is_note_str;

		if string.find(strValue, "</step>") then
			strValue = strValue .. '<div style="height:16px;"></div>'
		end

		if string.find(strValue, "<step") then
			local step_value = tonumber(string.match(strValue, 'value="(%d)"'))
			local cur_step_value = ppt_data.max_step or 0
			if step_value and step_value > cur_step_value then
				ppt_data.max_step = step_value
			end
		end

		if string.find(strValue, "projectid") then
			local temp_str = string.gsub(strValue, "%s+", "")
			local project_id = tonumber(string.match(temp_str, 'projectid="(%d+)"'))
			if project_id then
				if RedSummerCampPPtPage.ProjectIdToProjectData[project_id] == nil then
					RedSummerCampPPtPage.ProjectIdToProjectData[project_id] = {}
				end
			end
		end

		if string.find(strValue, "</notes") then
			is_start_notes = false
			is_note_str = true;
			is_start_knowledge_point = false
			if is_hide_div then
				strValue = ""
				is_hide_div = false
			end
		end

		if is_hide_div then
			strValue = ""
		end
		
		if is_start_notes then
			if nil == ppt_data.notes_content then
				ppt_data.notes_content = ""
			end
			ppt_data.notes_content = ppt_data.notes_content .. strValue .. "\r\n"
			ppt_data.notes_content = string.gsub(ppt_data.notes_content, "</b>", "")
			ppt_data.notes_content = string.gsub(ppt_data.notes_content, "<b>", "")
			strValue = strValue .. "<br/>"

			if is_start_knowledge_point then
				if ppt_data.knowledge_point_desc == nil then
					ppt_data.knowledge_point_desc = ""
				end

				ppt_data.knowledge_point_desc = ppt_data.knowledge_point_desc .. strValue
			end

			if string.find(strValue, "知识点") then
				is_start_knowledge_point = true
			end
		end

		-- 处理
		
		if string.find(strValue, "<notes") then
			is_start_notes = true

			if string.match(strValue, 'display="(.+)"') == "teacher" and not has_power then
				is_hide_div = true
				strValue = ""
			end
		end

		if RedSummerCampPPtPage.IsLockCourse and string.find(strValue, "yellon_button") then
			strValue = string.gsub(strValue, "yellon_button", "gray_button") 
		end

		-- if string.find(strValue, "href") then
		-- 	ppt_data.has_link = true
		-- end
		if string.find(strValue, "ppt_cover") or string.find(strValue, "bg_img") then
			if string.find(strValue, "ppt_cover_div") then
				ppt_data.is_div_ppt_cover = true
			else
				if ppt_data.is_div_ppt_cover then
					strValue = string.gsub(strValue, "ppt_cover", "cover_right_img")
				end
			end
			ppt_data.is_ppt_cover = true
		end
		
		if(is_note_str or is_start_notes) then
			ppt_data.notes_str = (ppt_data.notes_str or "") .. strValue;
		else
			ppt_data.div_str = (ppt_data.div_str or "") .. strValue
		end		
	end

	-- this will merge multiple notes in ppt_data.notes_str into ppt_data.div_str
	local function formatNotesIntoPPT_()
		for _, ppt_data in ipairs(ppt_data_list) do
			if(ppt_data.notes_str) then
				-- local grid_width = ppt_data.is_ppt_cover and 825 or 855

				local div_gridview = [[<pe:gridview style="" name="notes_gridview" CellPadding="1" 
				VerticalScrollBarStep="36" VerticalScrollBarOffsetX="8" AllowPaging="false" 
				ItemsPerLine="1" RememberScrollPos="true" DefaultNodeHeight = "36" 
				DataSource='<%=NotesData %>'><Columns>]]

				ppt_data.grid_div_str = table.concat({
					div_gridview,
					ppt_data.notes_str,
					[[</Columns></pe:gridview>]]
				})
			end
		end
	end

	while(strValue)do
		local str;
		local item = {};

		if string.find(strValue, "### ") then
			if is_div_str then
				if ppt_data.div_str == nil then
					ppt_data.div_str = ""
				end
				local tab = commonlib.split(strValue,"###")
				strValue = tab[1]
				handle_div_str(ppt_data, "<b>"..strValue.."</b>")
			end

			last_div_is_title = false
		elseif string.find(strValue, "## ") then
			ppt_data = {}
			local tab = commonlib.split(strValue,"##")
			ppt_data.title = tab[1]
			ppt_data.show_title = commonlib.GetLimitLabel(ppt_data.title, 20)
			if string.find(ppt_data.title, "课程介绍") then
				ppt_data.is_div_ppt_cover_old = true
			end

			ppt_data_list[#ppt_data_list + 1] = ppt_data
			is_div_str = true
			last_div_is_title = false
		elseif is_div_str then
			handle_div_str(ppt_data, strValue)
		elseif string.find(strValue, "# ") then
			local tab = commonlib.split(strValue,"#")
			RedSummerCampPPtPage.PPtName = tab[1];
			ppt_data_list.PPtName = tab[1]
			last_div_is_title = false
		end
	
		strValue = file:readline();
	end
	file:close();

	formatNotesIntoPPT_()

	RedSummerCampPPtPage.PPtCacheData[course_name] = ppt_data_list
end

function RedSummerCampPPtPage.InitData()
	if RedSummerCampPPtPage.PPtCacheData == nil or RedSummerCampPPtPage.PPtCacheData[RedSummerCampPPtPage.CurCourseName] == nil then
		RedSummerCampPPtPage.InitPPtConfig(RedSummerCampPPtPage.CurCourseName)
	end
	
	local ppt_data_list = RedSummerCampPPtPage.PPtCacheData[RedSummerCampPPtPage.CurCourseName] or {}
	RedSummerCampPPtPage.LessonsPPtData = ppt_data_list
	RedSummerCampPPtPage.SelectPPtData = RedSummerCampPPtPage.LessonsPPtData[RedSummerCampPPtPage.SelectLessonIndex] or {}
end

function RedSummerCampPPtPage.SelectLesson(index)
	if index == RedSummerCampPPtPage.SelectLessonIndex then
		return
	end

	if RedSummerCampPPtPage.IsLock(index) then
		local NplBrowserPlugin = commonlib.gettable("NplBrowser.NplBrowserPlugin");
		local config = NplBrowserPlugin.GetCache("nplbrowser_pptvideo");
		local need_return_video = config and config.visible
		RedSummerCampPPtPage.ChangeVideoVisible(false)
		if System.options.isDevEnv or System.options.isDevMode or System.options.isAB_SDK or KeepWorkItemManager.IsTeacher() then
			GameLogic.AddBBS(nil,L"你是开发者模式可以看锁定的课程")
		else
			local strTip = RedSummerCampPPtPage.IsLockCourse and L"你暂时没有该课程的访问权限，请联系客服或使用对应的激活码。" or L"课程暂未解锁，请先学习已经解锁的内容吧！"
			_guihelper.MessageBox(strTip,function()
				if need_return_video then
					RedSummerCampPPtPage.ChangeVideoVisible(true)
				end
			end,_guihelper.MessageBoxButtons.OK_CustomLabel,nil,"script/apps/Aries/Creator/Game/GUI/DefaultMessageBox.lesson.html")
			return
		end
	end

	RedSummerCampPPtPage.SelectLessonIndex = index
	RedSummerCampPPtPage.SelectPPtData = RedSummerCampPPtPage.LessonsPPtData[RedSummerCampPPtPage.SelectLessonIndex]
	RedSummerCampPPtPage.CurCourseKey = RedSummerCampPPtPage.CurCourseName .. RedSummerCampPPtPage.SplitKey .. RedSummerCampPPtPage.SelectLessonIndex
	RedSummerCampPPtPage.StepValueToProjectId = {}
	RedSummerCampPPtPage.SaveWorldStepList = {}
	RedSummerCampPPtPage.SyncWorldStepValue = nil
	-- RedSummerCampPPtPage.HandleErrorData()
	RedSummerCampPPtPage.RefreshPage()
	RedSummerCampPPtPage.GetCurSelectLessonData(function(course_data, pptIndex)
		RedSummerCampPPtPage.RefreshPage()

		-- 上报
		local action = string.format("crsp.course.section.visit-%s-%s", RedSummerCampPPtPage.CurCourseName, index)
		GameLogic.GetFilters():apply_filters('user_behavior', 1, action, RedSummerCampPPtPage.GetReportData({section = index}))
	end)

end

function RedSummerCampPPtPage.GetPPtStr()
	local ppt_data = RedSummerCampPPtPage.SelectPPtData
	if ppt_data == nil then
		return ""
	end

	return ppt_data.div_str
end

function RedSummerCampPPtPage.GetPPtTitle()
	local ppt_data = RedSummerCampPPtPage.SelectPPtData
	if ppt_data == nil then
		return ""
	end

	return ppt_data.title
end

function RedSummerCampPPtPage.GetPPtGridStr()
	local ppt_data = RedSummerCampPPtPage.SelectPPtData
	if ppt_data == nil then
		return ""
	end
	return ppt_data.grid_div_str or ""
end

function RedSummerCampPPtPage.IsPPTCover()
	local ppt_data = RedSummerCampPPtPage.SelectPPtData
	return ppt_data and ppt_data.is_ppt_cover
end

function RedSummerCampPPtPage.IsForbidReport()
	local ppt_data = RedSummerCampPPtPage.SelectPPtData
	return ppt_data and (ppt_data.is_ppt_cover or ppt_data.is_div_ppt_cover_old)
end


function RedSummerCampPPtPage.GetCourseClientData()
	local clientData = KeepWorkItemManager.GetClientData(40007) or {};
	if clientData.CourseTaskData == nil then
		clientData.CourseTaskData = {}
	end
	return clientData.CourseTaskData
end
-- 获取某个步骤是否完成
function RedSummerCampPPtPage.GetStepIsComplete(step)
	-- local course_all_data = RedSummerCampPPtPage.GetCourseClientData()
	-- if course_all_data[RedSummerCampPPtPage.CurCourseKey] == nil then
	-- 	return false
	-- end

	-- local course_data = course_all_data[RedSummerCampPPtPage.CurCourseKey]
	-- if course_data and course_data[tostring(step)] then
	-- 	local value = course_data[tostring(step)]
	-- 	return tostring(value) == "1"
	-- end
	if RedSummerCampPPtPage.CurLessonData then
		step = tostring(step)
		local extra = RedSummerCampPPtPage.CurLessonData.extra
		if not extra or not extra.steps then
			return false
		end

		return extra.steps[step] and tostring(extra.steps[step].status) == "1"
	end

	return false
end
-- 上报章节完成
function RedSummerCampPPtPage.ReportLessonFinish()
	-- 上报完成一节课
	local action = string.format("crsp.course.section.finish-%s-%s", RedSummerCampPPtPage.CurCourseName, RedSummerCampPPtPage.SelectLessonIndex)
	local extend_data = {
		section = lesson_index,
		sectionName = RedSummerCampPPtPage.GetPPtTitle() or "",
		score_building = 0,
		score_animation = 0,
		score_coding = 0,
		score_overall = 0,
	}

	local lesson_data = RedSummerCampPPtPage.CurLessonData
	if not lesson_data then
		return
	end

	if lesson_data.start_time_stamp then
		local cur_time_stamp = QuestAction.GetServerTime()
		local second = cur_time_stamp - tonumber(lesson_data.start_time_stamp)
		extend_data.duration = second
	end
	GameLogic.GetFilters():apply_filters('user_behavior', 1, action, RedSummerCampPPtPage.GetReportData(extend_data))
end

-- 上报整个课包完成
function RedSummerCampPPtPage.ReportCourseFinish()
	if RedSummerCampPPtPage.IsForbidReport() then
		return
	end

	-- 上报整个课包完成
	local action = string.format("crsp.course.finish-%s", RedSummerCampPPtPage.CurCourseName)
	local extend_data = {
		score_building = 0,
		score_animation = 0,
		score_coding = 0,
		score_overall = 0,
	}

	local course_data = RedSummerCampPPtPage.CurCourseData or {}
	if course_data.start_time_stamp then
		local cur_time_stamp = QuestAction.GetServerTime()
		local second = cur_time_stamp - tonumber(course_data.start_time_stamp)
		extend_data.days = math.floor(second/60/60/24)
	end
	GameLogic.GetFilters():apply_filters('user_behavior', 1, action, RedSummerCampPPtPage.GetReportData(extend_data))
end

function RedSummerCampPPtPage.GetCurLessonStepNum()
	if not RedSummerCampPPtPage.SelectPPtData then
		return 0
	end

	local all_step_num = RedSummerCampPPtPage.SelectPPtData.max_step or 0
	-- if RedSummerCampPPtPage.SelectPPtData.has_daily_video then
	-- 	all_step_num = all_step_num + 1
	-- end
	-- if RedSummerCampPPtPage.SelectPPtData.has_link then
	-- 	all_step_num = all_step_num + 1
	-- end

	return all_step_num
end

-- 这个其实就是任务完成了
function RedSummerCampPPtPage.SetCourseClientData(key, value)
	if RedSummerCampPPtPage.IsForbidReport() then
		return
	end

	if RedSummerCampPPtPage.CurCourseData and RedSummerCampPPtPage.CurCourseData.status == 1 then
		return
	end

	key = tostring(key)
	value = tostring(value)
	-- 2022.5.12 改成新的接口
	if RedSummerCampPPtPage.CurLessonData then
		-- if RedSummerCampPPtPage.CurLessonData.status == 1 then
		-- 	return
		-- end

		local extra = RedSummerCampPPtPage.CurLessonData.extra

		if not extra or type(extra) ~= "table" then
			return
		end

		if extra.steps == nil then
			extra.steps = {}
		end
		extra.steps[key] = {status = value}

		-- 判断章节是否完成
		local finish_num = 0
		for key, v in pairs(extra.steps) do
			if tostring(v.status) == "1" then
				finish_num = finish_num + 1
			end
		end
		RedSummerCampPPtPage.CurLessonData.extra = extra

		-- 每次步骤完成的时候判断下当前章节是否完成
		if finish_num > 0 and finish_num >= RedSummerCampPPtPage.GetCurLessonStepNum() then
			RedSummerCampPPtPage.CurLessonData.status = 1

			RedSummerCampPPtPage.ReportLessonFinish()
		end
		RedSummerCampPPtPage.SetSelectLessonData(function()
			-- 每次章节完成的时候判断下课包是否完成
			RedSummerCampPPtPage.CurCourseData.completedSectionCount = RedSummerCampPPtPage.CurCourseData.completedSectionCount + 1
			local sectionCount = RedSummerCampPPtPage.CourseConfigData.sectionCount or 0
			if RedSummerCampPPtPage.CurCourseData.completedSectionCount >= sectionCount then
				RedSummerCampPPtPage.CurCourseData.status = 1
				RedSummerCampPPtPage.SetCurCourseData()

				RedSummerCampPPtPage.ReportCourseFinish()
			end
			
			RedSummerCampPPtPage.RefreshPage()
		end);
	end

	-- if RedSummerCampPPtPage.CurCourseKey == nil then
	-- 	return
	-- end

	-- local course_all_data = RedSummerCampPPtPage.GetCourseClientData()
	-- if course_all_data[RedSummerCampPPtPage.CurCourseKey] == nil then
	-- 	course_all_data[RedSummerCampPPtPage.CurCourseKey] = {}
	-- end

	-- RedSummerCampPPtPage.SaveKnowledgePoint()

	-- local course_data = course_all_data[RedSummerCampPPtPage.CurCourseKey]

	-- if course_data[key] == value then
	-- 	return
	-- end
	-- course_data.is_fix = true
	-- course_data[key] = value
	
	-- local clientData = KeepWorkItemManager.GetClientData(40007) or {};
	-- clientData.CourseTaskData = course_all_data

	-- -- 任务完成的话 判断是否全部完成
	-- if value == "1" then
	-- 	local finish_num = 0
	-- 	for key, v in pairs(course_data) do
	-- 		if tostring(v) == "1" then
	-- 			finish_num = finish_num + 1
	-- 		end
	-- 	end

	-- 	if finish_num >= RedSummerCampPPtPage.GetCurLessonStepNum() then
	-- 		RedSummerCampPPtPage.ReportCourseData("is_finish", 1)
	-- 	end
	-- end

    -- KeepWorkItemManager.SetClientData(40007, clientData, function()
    --     RedSummerCampPPtPage.RefreshPage()
    -- end);
end

function RedSummerCampPPtPage.SaveKnowledgePoint()
	if not RedSummerCampPPtPage.SelectPPtData then
		return
	end

	local ppt_title = RedSummerCampPPtPage.GetPPtTitle()
	local course_title = RedSummerCampPPtPage.CurPPtCourseTitle or ""

	local knowledge_point_desc = RedSummerCampPPtPage.SelectPPtData.knowledge_point_desc or course_title
	local content = string.format("%s <br/> 知识点：<br/>%s", ppt_title, knowledge_point_desc)
	RedSummerCampCourseScheduling.SetDayHistroy(RedSummerCampPPtPage.CurCourseName, content, RedSummerCampPPtPage.SelectLessonIndex)
end

function RedSummerCampPPtPage.SetStepValueToProjectId(step_value, projectid)
	if step_value == nil then
		return
	end

	RedSummerCampPPtPage.StepValueToProjectId[tostring(step_value)] = tostring(projectid)
end

function RedSummerCampPPtPage.SetSaveWorldStepValue(step_value)
	if step_value == nil then
		return
	end

	if RedSummerCampPPtPage.SaveWorldStepList == nil then
		RedSummerCampPPtPage.SaveWorldStepList = {}
	end

	RedSummerCampPPtPage.SaveWorldStepList[tostring(step_value)] = 1
end

function RedSummerCampPPtPage.SetSyncWorldStepValue(step_value)
	RedSummerCampPPtPage.SyncWorldStepValue = step_value
end

function RedSummerCampPPtPage.OnVisitWrold(projectid)
	if projectid and RedSummerCampPPtPage.StepValueToProjectId then
		-- projectid = tostring(projectid)
		-- local step_value
		-- for k, v in pairs(RedSummerCampPPtPage.StepValueToProjectId) do
		-- 	-- 只有第二步骤是访问才算完成了
		-- 	if v == projectid and tonumber(k) == 2 then
		-- 		step_value = k
		-- 		break
		-- 	end
		-- end
		-- if step_value then
		-- 	RedSummerCampPPtPage.SetCourseClientData(step_value, 1)
		-- 	RedSummerCampPPtPage.ReportFinishCurTask()
		-- end
	end
end

function RedSummerCampPPtPage.OnSaveWrold()
	if RedSummerCampPPtPage.SaveWorldStepList then
		for k, v in pairs(RedSummerCampPPtPage.SaveWorldStepList) do
			RedSummerCampPPtPage.SetCourseClientData(k, 1)
		end

		RedSummerCampPPtPage.ReportFinishCurTask()
	end

	-- local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
	-- local isHomeWorkWorld = WorldCommon.GetWorldTag("isHomeWorkWorld");
	-- if isHomeWorkWorld then
	-- 	RedSummerCampPPtPage.SysncWorld()
	-- end
end

function RedSummerCampPPtPage.OnSyncWorldFinish()
	local step_value = RedSummerCampPPtPage.SyncWorldStepValue
	if step_value then
		RedSummerCampPPtPage.SetCourseClientData(step_value, 1)
	
		RedSummerCampPPtPage.StartTask("share")
		RedSummerCampPPtPage.ReportFinishCurTask()
		return 
	end
	if RedSummerCampPPtPage.SaveWorldStepList then
		for k, v in pairs(RedSummerCampPPtPage.SaveWorldStepList) do
			RedSummerCampPPtPage.SetCourseClientData(k, 1)
		end
		local project_id = 0
		local world_data = GameLogic.GetFilters():apply_filters('store_get', 'world/currentWorld')
		if world_data and world_data.kpProjectId and world_data.kpProjectId ~= 0 then
			project_id = world_data.kpProjectId
		end

		if System.options.isDevMode then
			print("share reprot==============")
			print("project_id==================",project_id)
		end

		if tonumber(project_id) > 0  then
			RedSummerCampPPtPage.StartTask("share",2,project_id)
			RedSummerCampPPtPage.ReportFinishCurTask()
		end
	end
end

-- course_id 成长任务的天数
function RedSummerCampPPtPage.SetCurPPtCourseTitle(title)
	RedSummerCampPPtPage.CurPPtCourseTitle = title
end

function RedSummerCampPPtPage.SetIsReturnOpenPage(result)
	RedSummerCampPPtPage.IsOpenPage = result
end

function RedSummerCampPPtPage.GetIsReturnOpenPage()
	return RedSummerCampPPtPage.IsOpenPage
end

function RedSummerCampPPtPage.OnBeforeLoadWorld()
	-- 设置tag
	if RedSummerCampPPtPage.NeedSetTag then
		RedSummerCampPPtPage.NeedSetTag = nil
		local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
		WorldCommon.SetWorldTag("isHomeWorkWorld", true);
		WorldCommon.SaveWorldTag()
	end
end

function RedSummerCampPPtPage.OnWorldLoaded()
	if page then
		-- body
		page:CloseWindow(true)
		page = nil

		RedSummerCampPPtPage.SetIsReturnOpenPage(true)
	end
	
	GameLogic.events:AddEventListener("CreateBlockTask", RedSummerCampPPtPage.OnCreateBlockTask, RedSummerCampPPtPage, "RedSummerCampPPtPage");
	GameLogic.events:AddEventListener("CreateDiffIdBlockTask", RedSummerCampPPtPage.OnCreateBlockTask, RedSummerCampPPtPage, "RedSummerCampPPtPage");
end

function RedSummerCampPPtPage.SetIsFullPage(flag)
	RedSummerCampPPtPage.IsFullPage = flag
end

function RedSummerCampPPtPage.GetIsFullPage()
	return RedSummerCampPPtPage.IsFullPage
end

function RedSummerCampPPtPage.OpenFullPage()
	RedSummerCampPPtFullPage.Show(RedSummerCampPPtPage.GetPPtStr());
end

function RedSummerCampPPtPage.ExportPPt()
	if RedSummerCampPPtPage.IsLockCourse then
        local strTip = "你暂时没有该课程的访问权限，请联系客服或使用对应的激活码。"
        _guihelper.MessageBox(strTip,nil,_guihelper.MessageBoxButtons.OK_CustomLabel,nil,"script/apps/Aries/Creator/Game/GUI/DefaultMessageBox.lesson.html")
		return
	end

	local DefaultFilters = commonlib.gettable("MyCompany.Aries.Game.DefaultFilters");
	if DefaultFilters.Install == nil then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Mod/DefaultFilters.lua");
		local DefaultFilters = commonlib.gettable("MyCompany.Aries.Game.DefaultFilters");
		DefaultFilters:Install();
	end

	local ppt_data_list = RedSummerCampPPtPage.PPtCacheData[RedSummerCampPPtPage.CurCourseName]
	RedSummerCampPPtFullPage.Show(ppt_data_list[1].div_str, 9999, true);
	
	RedSummerCampPPtPage.export_ppt_data_list = ppt_data_list
	RedSummerCampPPtPage.export_ppt_data_index = 1
	RedSummerCampPPtPage.FlushExportFullPage()

	-- GameLogic.RunCommand("/open npl://console");
end

function RedSummerCampPPtPage.OpenLastPPtPage(is_show_exit_bt, is_use_close_anim)
	if RedSummerCampPPtPage.GetIsReturnOpenPage() then
		if not RedSummerCampCourseScheduling.IsOpen() then
			RedSummerCampCourseScheduling.ShowView()
		end
		local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
		RedSummerCampPPtPage.is_use_close_anim = is_use_close_anim and WorldCommon.GetWorldTag("isHomeWorkWorld")
		RedSummerCampPPtPage.Show(nil, nil, is_show_exit_bt)
	end
end

function RedSummerCampPPtPage.ClosePPtAllPage()
	RedSummerCampPPtPage.IsSaveIndex = true
	if RedSummerCampMainWorldPage.GetOpenFromCommandMenu() then
		RedSummerCampPPtPage.IsOpenPage = true
	end
	
	if RedSummerCampPPtPage.is_use_close_anim and not RedSummerCampPPtPage.IsFullPage then
		RedSummerCampPPtPage.is_use_close_anim = false
		RedSummerCampPPtPage.ChangeVideoVisible(false)
		commonlib.TimerManager.SetTimeout(function()
			RedSummerCampPPtPage.ClosePageWithAnim()
			RedSummerCampCourseScheduling.ClosePage()
			RedSummerCampMainWorldPage.ClosePage()
		end, 100);
	else
		RedSummerCampPPtPage.ClosePage()
		RedSummerCampCourseScheduling.ClosePage()
		RedSummerCampMainWorldPage.ClosePage()
	end	


	if RedSummerCampPPtPage.IsFullPage and RedSummerCampPPtPage.is_use_close_anim then
		RedSummerCampPPtPage.is_use_close_anim = false
		commonlib.TimerManager.SetTimeout(function()
			RedSummerCampPPtFullPage.ClosePageWithAnim()
		end, 100);
	else
		RedSummerCampPPtFullPage.ClosePage()
	end
	
end

function RedSummerCampPPtPage.ClosePageWithAnim()
	if RedSummerCampPPtPage.InCloseAnim then
		return
	end

	RedSummerCampPPtPage.InCloseAnim = true
	RedSummerCampPPtPage.ChangeVideoVisible(false)
	local root = ParaUI.GetUIObject("PPTPageRoot");
	root:ApplyAnim();
	-- root.width = 1280
	-- root.height = 720
	-- root.x = root.width/2
	-- root.y = root.height/2
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
	
	if not RedSummerCampPPtPage.CloseTimer then
		local ui_scale = 1
		RedSummerCampPPtPage.CloseTimer = commonlib.Timer:new({callbackFunc = function(timer)
			if ui_scale <= 0 or not page then
				ui_scale = 1
				RedSummerCampPPtPage.ClosePage()
				RedSummerCampPPtPage.CloseTimer:Change(nil);	
				return
			end

			ui_scale = ui_scale + scale_change_value
			-- local root = page:GetRootUIObject()
			root = ParaUI.GetUIObject("PPTPageRoot");
			root.scalingx = ui_scale
			root.scalingy = ui_scale
			
			root.translationx = root.translationx - 26
			root.translationy = root.translationy + 14
			root:ApplyAnim();
		end})
	end

	RedSummerCampPPtPage.CloseTimer:Change(0, interval);	

end

function RedSummerCampPPtPage.IsShowCloseAllPageBt()
	return true
end

function RedSummerCampPPtPage.GetContent(dataHistroy, course_data, callback)
	if not callback then
		return
	end

	local function get_content()
		local course_name, pptIndex = dataHistroy.key, dataHistroy.pptIndex
	
		if RedSummerCampPPtPage.PPtCacheData[course_name] == nil then
			RedSummerCampPPtPage.InitPPtConfig(course_name)
		end
	
		local ppt_data_list = RedSummerCampPPtPage.PPtCacheData[course_name]
		local ppt_data = ppt_data_list[pptIndex]
		if not ppt_data then
			callback(dataHistroy.content or "")
			return
		end
		
		local ppt_title = ppt_data.title or ""
		local knowledge_point_desc = ppt_data.knowledge_point_desc or ""
		local content = string.format("%s <br/> 知识点：<br/>%s", ppt_title, knowledge_point_desc)
		callback(content)
	end


	if course_data and type(course_data) == "table" then
		RedSummerCampPPtPage.CheckPPtConfigFile(course_data, dataHistroy.pptIndex, get_content)
	else
		get_content()
	end
	
end

function RedSummerCampPPtPage.HandleErrorData()
	local course_all_data = RedSummerCampPPtPage.GetCourseClientData()
	if course_all_data[RedSummerCampPPtPage.CurCourseKey] == nil then
		return
	end

	local course_data = course_all_data[RedSummerCampPPtPage.CurCourseKey]
	if course_data == nil then
		return
	end
	if not course_data.is_fix then
		if course_data["3"] and tostring(course_data["3"]) == "1" then
			course_data["4"] = 1
			--course_data["3"] = 0
		end

		if course_data["2.1"] and tostring(course_data["2.1"]) == "1" then
			course_data["3"] = 1
		end

		course_data.is_fix = true

		local clientData = KeepWorkItemManager.GetClientData(40007) or {};
		clientData.CourseTaskData = course_all_data
		KeepWorkItemManager.SetClientData(40007, clientData, function()
			-- RedSummerCampPPtPage.RefreshPage()
		end);
	end
end

-- local test_num = 0
function RedSummerCampPPtPage.UpdateStudentNum()
	if page then
		-- test_num = test_num + 1
		if Lan then
			local student_num_value = Lan:GetConnectionCount() or 0;
			-- student_num_value = test_num
			page:SetValue("student_num", string.format("学生(%s)", student_num_value))
		end
	end
end

function RedSummerCampPPtPage.GetExportData()
	local ppt_data_list = RedSummerCampPPtPage.PPtCacheData[RedSummerCampPPtPage.CurCourseName]
	local course_data = nil
	for key, v in pairs(RedSummerCampCourseScheduling.lessonCnf) do
		if v.code == RedSummerCampPPtPage.CurCourseName then
			course_data = v
			break
		end
	end
	return ppt_data_list or {}, course_data and course_data.name or "course"
end

function RedSummerCampPPtPage.FlushExportFullPage(index, ppt_data_list)
	local ppt_data_list = RedSummerCampPPtPage.export_ppt_data_list
	local index = RedSummerCampPPtPage.export_ppt_data_index
	if not index or not ppt_data_list then
		return
	end

	if index > #ppt_data_list then
	-- if true then
		RedSummerCampPPtFullPage.ClosePage()
		RedSummerCampPPtFullPage.IsInFullPage = false
		GameLogic.RunCommand("/open npl://console?isppt=true");
		return
	end

	local data = ppt_data_list[index]
	RedSummerCampPPtFullPage.title = data.title
	RedSummerCampPPtFullPage.InitData(data.div_str)
	RedSummerCampPPtFullPage.RefreshPage()
	local filepath = string.format("script/apps/WebServer/admin/pptimg/%s.jpg", "ppt" .. index)

	index = index + 1
	RedSummerCampPPtPage.export_ppt_data_index = index
	
	commonlib.TimerManager.SetTimeout(function()  
		ParaMovie.TakeScreenShot(filepath, 1280, 720);
		commonlib.TimerManager.SetTimeout(function()
			RedSummerCampPPtPage.FlushExportFullPage()
		end, 200);
	end, 300);
end

function RedSummerCampPPtPage.IsClose()
	return page == nil
end

function RedSummerCampPPtPage.IsLockScreen()
	if Lan then
		return Lan:GetSnapshot():IsLockScreen()
	end

	return false
end

function RedSummerCampPPtPage.LockScreen()
	if Lan then
		if RedSummerCampPPtPage.IsLockScreen() then
			Lan:GetSnapshot():UnlockScreen()
		else
			Lan:GetSnapshot():LockScreen()
		end

		RedSummerCampPPtPage.RefreshPage()
	end
end

function RedSummerCampPPtPage.OnWorldUnloaded()
	local projectid = GameLogic.options:GetProjectId()
	if projectid and RedSummerCampPPtPage.StepValueToProjectId then
		projectid = tostring(projectid)
		-- 完成步骤1
		local step_1_project_id = RedSummerCampPPtPage.StepValueToProjectId[1] or RedSummerCampPPtPage.StepValueToProjectId["1"]
		if (step_1_project_id and tonumber(step_1_project_id) == tonumber(projectid)) then
			RedSummerCampPPtPage.SetCourseClientData(1, 1)
			RedSummerCampPPtPage.ReportFinishCurTask()
		end

		local step_2_project_id = RedSummerCampPPtPage.StepValueToProjectId[2] or RedSummerCampPPtPage.StepValueToProjectId["2"]
		if (step_2_project_id and tonumber(step_2_project_id) == tonumber(projectid))  then
			RedSummerCampPPtPage.SetCourseClientData(2, 1)
			RedSummerCampPPtPage.ReportFinishCurTask()
		end
	end

	-- RedSummerCampPPtPage.last_course_data = nil
end

function RedSummerCampPPtPage.StartTask(task_type, step_value, world_id)
	if not RedSummerCampPPtPage.CurCourseName then
		return
	end

	-- 上报触发任务
	local action = string.format("crsp.course.progress.start-%s-%s-%s", RedSummerCampPPtPage.CurCourseName, RedSummerCampPPtPage.SelectLessonIndex, task_type)

	local extend_data = {
		section = RedSummerCampPPtPage.SelectLessonIndex,
		sectionName = RedSummerCampPPtPage.GetPPtTitle() or "",
		taskType = task_type,
		step = step_value or 0,
		world_id = world_id or 0,
	}

	RedSummerCampPPtPage.CurTaskData = {}
	for k, v in pairs(extend_data) do
		RedSummerCampPPtPage.CurTaskData[k] = v
	end
	RedSummerCampPPtPage.CurTaskData.start_time_stamp = QuestAction.GetServerTime()
	GameLogic.GetFilters():apply_filters('user_behavior', 1, action, RedSummerCampPPtPage.GetReportData(extend_data))
end

function RedSummerCampPPtPage.ReportFinishCurTask()
	if RedSummerCampPPtPage.IsForbidReport() then
		return
	end

	if not RedSummerCampPPtPage.CurTaskData then
		return
	end

	-- 上报结束任务
	local action = string.format("crsp.course.progress.finish-%s-%s-%s", RedSummerCampPPtPage.CurCourseName, RedSummerCampPPtPage.SelectLessonIndex, RedSummerCampPPtPage.CurTaskData.taskType)

	local extend_data = {
		section = RedSummerCampPPtPage.CurTaskData.section,
		sectionName = RedSummerCampPPtPage.CurTaskData.sectionName,
		taskType = RedSummerCampPPtPage.CurTaskData.taskType,
		step = RedSummerCampPPtPage.CurTaskData.step,
		world_id = RedSummerCampPPtPage.CurTaskData.world_id,
	}

	local cur_time_stamp = QuestAction.GetServerTime()
	local second = cur_time_stamp - RedSummerCampPPtPage.CurTaskData.start_time_stamp
	extend_data.duration = second
	-- 上课状态才会有的数据
	if ClassSchedule._curCourse and ClassSchedule._curCourse.course and ClassSchedule._curCourse.sections 
		and ClassSchedule._curCourse.sections[1] and RedSummerCampPPtPage.GetCourseTitle() == ClassSchedule._curCourse.course.name then
		local sections = ClassSchedule._curCourse.scheduleSections
		local step = RedSummerCampPPtPage.CurTaskData.step
		if sections and sections[1].sectionId and step and RedSummerCampPPtPage.GetLessonServerIndex() == ClassSchedule._curCourse.sections[1].index then
			local data = {
				scheduleId = ClassSchedule._curCourse.id,
				sectionId = sections[1].sectionId,
				step = step,
				status = 1,
				timeTotal = second,
			}
			keepwork.schedule.scheduleReports(data, function(err, msg, data)
				-- print("xxxxxxxxxeee", err)
				-- echo(data, true)
			end)
		end

	end

	RedSummerCampPPtPage.CurTaskData = nil
	GameLogic.GetFilters():apply_filters('user_behavior', 1, action, RedSummerCampPPtPage.GetReportData(extend_data))
end
function RedSummerCampPPtPage.OnCreateBlockTask()
	RedSummerCampPPtPage.ReportCreateBlockInCourse(1)
end

-- 只有老师点了上课才会上报
function RedSummerCampPPtPage.ReportCreateBlockInCourse(blocks, is_delete)
	if not ClassSchedule._curCourse then
		return blocks, is_delete
	end
	if is_delete then
		return blocks, is_delete
	end

	if not RedSummerCampPPtPage.CreateBlockNum then
		RedSummerCampPPtPage.CreateBlockNum = 0
	end

	if type(blocks) == "number" then
		RedSummerCampPPtPage.CreateBlockNum = RedSummerCampPPtPage.CreateBlockNum + blocks
	elseif type(blocks) == "table" then
		RedSummerCampPPtPage.CreateBlockNum = RedSummerCampPPtPage.CreateBlockNum + #blocks
	end
	if not RedSummerCampPPtPage.ReportBlockTimer then
		RedSummerCampPPtPage.ReportBlockTimer = commonlib.Timer:new({callbackFunc = function(timer)
			if RedSummerCampPPtPage.CreateBlockNum > 0 and ClassSchedule._curCourse then
				local sections = ClassSchedule._curCourse.scheduleSections
				if sections and sections[1].sectionId then
					local data = {
						scheduleId = ClassSchedule._curCourse.id,
						sectionId = sections[1].sectionId,
						createWorldTotal = RedSummerCampPPtPage.CreateBlockNum
					}
					keepwork.schedule.scheduleReports(data, function(err, msg, data)
						if err == 200 then
							RedSummerCampPPtPage.CreateBlockNum = 0
						end
					end)
				end				
			end
		end})
		RedSummerCampPPtPage.ReportBlockTimer:Change(1000 * 30, 1000 * 30);	
	end
	
	return blocks, is_delete
end

function RedSummerCampPPtPage.GetReportData(extra_data)
	local report_data = {
		lessonType =  RedSummerCampPPtPage.CurCourseName or "",
		lessonName = RedSummerCampPPtPage.GetCourseStrName() or "",
		user_id = GameLogic.GetFilters():apply_filters('store_get', 'user/userId'),
	}

	local profile = KeepWorkItemManager.GetProfile()
	local school_id = profile and profile.schoolId
	if school_id and school_id > 0 then
		report_data.school_id = school_id
	end

	if extra_data then
		for key, value in pairs(extra_data) do
			report_data[key] = value
		end
	end

	report_data.useNoId = true

	return report_data
end

function RedSummerCampPPtPage.OnClickAction(action_type, param1, param2, param3, param4)
	-- 判断时间规则
	if RedSummerCampPPtPage.CourseConfigData then
		local timeRules = RedSummerCampPPtPage.CourseConfigData.timeRules
		if timeRules then
			local UserPermission = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/UserPermission.lua");
			if not UserPermission.CheckTimeRules(timeRules) then
				local first_time_rule = timeRules[1]
				if first_time_rule then
					local function get_num_str(number)
						if number >= 10 then
							return number
						end
					
						return "0" .. number
					end
	
					local time_rule = timeRules[1]
					local start_time_t, end_time_t = UserPermission.GetTimeRuleStartEndTimeT(time_rule)
					if not start_time_t then
						return ""
					end
			
					local start_hour,start_min = get_num_str(start_time_t.start_hour), get_num_str(start_time_t.start_min)
					local end_hour,end_min = get_num_str(end_time_t.end_hour), get_num_str(end_time_t.end_min)
				
					local date_desc = UserPermission.GetTimeRuleDateTypeDesc(time_rule)
					-- local week_desc = ContactTeacherAlert.GetVipLimitWeekDesc()
					local desc = string.format("现在不是上课时间，请在上课时间内（%s%s:%s-%s:%s）再来吧。", date_desc, start_hour, start_min, end_hour, end_min)
					_guihelper.MessageBox(desc);
					return
				end
			end
		end
	end

	if action_type == "explore" or action_type == "button" then
		local step_value
		if action_type == "explore" then
			step_value = tonumber(param3) or 0
		end
	
		if action_type == "button" then
			step_value = tonumber(param4) or 0
		end
	
		local step_to_task_type = {
			[1]= "explore",
			[2]= "playworld",
		}
		
		local task_type = step_to_task_type[step_value]
		if task_type then
			local projectid = RedSummerCampPPtPage.StepValueToProjectId[tostring(step_value)]
			RedSummerCampPPtPage.StartTask(task_type, step_value, projectid)
		end
	end

	if action_type == "loadworld" then
		local step_value = param1
		RedSummerCampPPtPage.StartTask("creatworld", step_value)
	end

	if action_type == "button" or action_type == "explore" then
		local projectid = param1
		local commandStr = string.format("/loadworld -s -auto %s", projectid)
		local sendevent = param2
		if sendevent and sendevent ~= "" then
			commandStr = string.format("/loadworld -s -auto -inplace %s  | /sendevent %s", projectid,sendevent)
		end
		if RedSummerCampPPtPage.last_course_data and type(RedSummerCampPPtPage.last_course_data) == "table" and action_type == "button" then
			RedSummerCampPPtPage.last_course_data.ppt_to_projectid = projectid
			RedSummerCampPPtPage.last_course_data.ppt_index= RedSummerCampPPtPage.GetLessonServerIndex()
		end
		GameLogic.RunCommand(commandStr)
	elseif action_type == "loadworld" then
		local Opus = NPL.load("(gl)Mod/WorldShare/cellar/Opus/Opus.lua")
		Opus:Show()
	elseif action_type == "dailyVideo" then
		local course_id = param1
		ParacraftLearningRoomDailyPage.OnOpenWeb(tonumber(course_id),true)
	elseif action_type == "dailyVideoLink" then
		local link = param1
		local is_external_link = param2
		local title = param3
		RedSummerCampPPtPage.OpenVideoLink(link, is_external_link, title)
	elseif action_type == "link" then
		local link = param1
		local is_ues_token = param2
		local step_value = param3
		if is_ues_token then
			local use_token = System.User.keepworktoken or ""
			link = link .. "?token=" .. System.User.keepworktoken
		end
		RedSummerCampPPtPage.OpenVideoLink(link, true, title)	

		RedSummerCampPPtPage.StartTask("link", step_value)
		RedSummerCampPPtPage.SetCourseClientData(tonumber(step_value), 1)
		RedSummerCampPPtPage.ReportFinishCurTask()
		-- ParaGlobal.ShellExecute("open", link, "", "", 1); 
	end

end

function RedSummerCampPPtPage.OnCloseDailyVideo()
	if not RedSummerCampPPtPage.CurTaskData then
		return
	end

	local cur_time_stamp = QuestAction.GetServerTime()
	local second = cur_time_stamp - RedSummerCampPPtPage.CurTaskData.start_time_stamp
	if second < 20 then
		RedSummerCampPPtPage.CurTaskData = nil
		return
	end

	-- RedSummerCampPPtPage.SetCourseClientData("dailyVideo", 1)
	RedSummerCampPPtPage.ReportFinishCurTask()
end

function RedSummerCampPPtPage.GetPPTConfigDiskFolder()
    if(not RedSummerCampPPtPage.DiskFolder) then
		RedSummerCampPPtPage.DiskFolder = ParaIO.GetWritablePath().."temp/ppt_config"
   end
    
	return RedSummerCampPPtPage.DiskFolder
end

function RedSummerCampPPtPage.ToWorld(project_id, sendevent)
	if project_id then
		local commandStr = string.format("/loadworld -s -auto %s", project_id)
		if sendevent then
			commandStr = string.format("/loadworld -s -auto -inplace %s  | /sendevent %s", project_id, sendevent)
		end
		GameLogic.RunCommand(commandStr)
		if RedSummerCampPPtPage.last_course_data then
			RedSummerCampPPtPage.last_course_data.ppt_to_projectid = project_id
			RedSummerCampPPtPage.last_course_data.ppt_index= RedSummerCampPPtPage.GetLessonServerIndex()
		end
	end
end

function RedSummerCampPPtPage.IsLock(index)
	if RedSummerCampPPtPage.IsLockCourse then 
		return index > 1
	end
	if index == 1 and RedSummerCampPPtPage.IsHavePPTCover() then
		return false
	end
	if not RedSummerCampPPtPage.CourseConfigData.sectionAuths then
		return index > 1 and RedSummerCampPPtPage.IsLockCourse
	end
	local isLock = true
	if RedSummerCampPPtPage.GetSectionAuth(index) ~= nil then
		isLock = not RedSummerCampPPtPage.GetSectionAuth(index)
	end
	return isLock
	-- return index > 1 and RedSummerCampPPtPage.IsLockCourse
end


--更新课程章节权限
function RedSummerCampPPtPage.CheckSectionNeedUpdate()
	local sectionAuths = RedSummerCampPPtPage.CourseConfigData.sectionAuths
	if sectionAuths and sectionAuths.lessonCfg then
		--判断是否有当天的课
		local server_time_stamp = QuestAction.GetServerTime()
		local year = tonumber(os.date("%Y",server_time_stamp))
		local month = tonumber(os.date("%m", server_time_stamp))
		local day = tonumber(os.date("%d", server_time_stamp))
		local start_time_stamp = os.time({year = year, month = month, day = day, hour=0, min=0, sec=0})
		local end_time_stamp = os.time({year = year, month = month, day = day, hour=23, min=59, sec=0})
        local sections = {}
        local num = #sectionAuths.lessonCfg
		local bNeedUpdate,todatSectionIndex,lessonTime
        for i=1,num do
            local timeStamp = tonumber(RedSummerCampCourseScheduling.getTimeStampByString(sectionAuths.lessonCfg[i].time))
            if timeStamp and timeStamp > start_time_stamp and timeStamp < end_time_stamp and timeStamp > tonumber(server_time_stamp) then --当天有配置课程
                bNeedUpdate = true
				todatSectionIndex = sectionAuths.lessonCfg[i].index
				lessonTime = timeStamp
				break
            end
        end
		if System.options.isDevMode then
			print("CheckSectionNeedUpdate=================================")
			print("data============",bNeedUpdate,todatSectionIndex,start_time_stamp,end_time_stamp,lessonTime,server_time_stamp,year,month,day)
		end
		return bNeedUpdate,todatSectionIndex,start_time_stamp,end_time_stamp,lessonTime
	end
	return false
end

local function SetSectionData()
	local sectionAuths = RedSummerCampPPtPage.CourseConfigData.sectionAuths
	if sectionAuths and sectionAuths.lessonCfg then
		local config = sectionAuths.lessonCfg
		local server_time_stamp = QuestAction.GetServerTime()
		local sectionAuths = {}
		local num = #config
		for i=1,num do
			local timeStamp = tonumber(RedSummerCampCourseScheduling.getTimeStampByString(config[i].time))
			if timeStamp and timeStamp <= tonumber(server_time_stamp) then
				local server_index = config[i].index - 2
				sectionAuths[#sectionAuths + 1] = {courseId = RedSummerCampPPtPage.CourseConfigData.id,index = server_index,ppt_index = config[i].index}
			end
		end
		sectionAuths.lessonCfg = config
		RedSummerCampPPtPage.CourseConfigData.sectionAuths = sectionAuths
		RedSummerCampPPtPage.SectionAuths = nil
	end
end

function RedSummerCampPPtPage.UpdateSectionsAuths()
	local bNeedUpdate,todatSectionIndex,start_time_stamp,end_time_stamp,lessonTime = RedSummerCampPPtPage.CheckSectionNeedUpdate() 
	if bNeedUpdate and todatSectionIndex > 0 then
		RedSummerCampPPtPage.SectionUpdateTimer = RedSummerCampPPtPage.SectionUpdateTimer or commonlib.Timer:new({callbackFunc = function(timer)
			local server_time_stamp = QuestAction.GetServerTime()
			if lessonTime and tonumber(server_time_stamp) >= lessonTime  then
				SetSectionData()
				RedSummerCampPPtPage.RefreshPage()
				if RedSummerCampPPtPage.SectionUpdateTimer then
					RedSummerCampPPtPage.SectionUpdateTimer:Change()
					RedSummerCampPPtPage.SectionUpdateTimer = nil
				end
			end
		end})
		RedSummerCampPPtPage.SectionUpdateTimer:Change(0, 1000);
	else
		if RedSummerCampPPtPage.SectionUpdateTimer then
			RedSummerCampPPtPage.SectionUpdateTimer:Change()
			RedSummerCampPPtPage.SectionUpdateTimer = nil
		end
	end
end

function RedSummerCampPPtPage.GetSectionAuth(index)
	local sectionAuths = RedSummerCampPPtPage.CourseConfigData.sectionAuths
	if not RedSummerCampPPtPage.SectionAuths then
		RedSummerCampPPtPage.SectionAuths = {}
		-- echo(sectionAuths,true)
		for k,v in pairs(sectionAuths) do
			if v and v.index then
				local pptIndex = RedSummerCampPPtPage.GetLessonClientIndexByServerIndex(v.index)
				RedSummerCampPPtPage.SectionAuths[pptIndex] = true
			end
		end
	end
	return RedSummerCampPPtPage.SectionAuths[index]
end

function RedSummerCampPPtPage.CloseInDebug()
	if RedSummerCampPPtPage.is_in_debug then
		page:CloseWindow(true)
		page = nil
	end
end

function RedSummerCampPPtPage.GetLastCourseData()
	return RedSummerCampPPtPage.last_course_data
end

function RedSummerCampPPtPage.GetDebugData()
	RedSummerCampPPtPage.DebugData = {}
	
	if RedSummerCampPPtPage.LessonsPPtData then
		for index, v in ipairs(RedSummerCampPPtPage.LessonsPPtData) do
			RedSummerCampPPtPage.DebugData[index] = {text = v.title, value = index, selected = index == RedSummerCampPPtPage.SelectLessonIndex}
		end
	end
	return RedSummerCampPPtPage.DebugData
end

function RedSummerCampPPtPage.SetDefaulIndex(index)
	RedSummerCampPPtPage.defaul_select_index = index
end

function RedSummerCampPPtPage.IsOpen()
    return page and page:IsVisible()
end

function RedSummerCampPPtPage.GetLessonServerIndex()
	if not RedSummerCampPPtPage.LessonsPPtData then
		return
	end
	if RedSummerCampPPtPage.SelectLessonIndex==nil then
		return 0
	end
	local first_ppt_data = RedSummerCampPPtPage.LessonsPPtData[1] or {}
	if first_ppt_data and first_ppt_data.is_ppt_cover then
		return RedSummerCampPPtPage.SelectLessonIndex - 2
	end
	return RedSummerCampPPtPage.SelectLessonIndex - 1
end

function RedSummerCampPPtPage.GetLessonClientIndexByServerIndex(server_index)
	if not RedSummerCampPPtPage.LessonsPPtData then
		return
	end
	local first_ppt_data = RedSummerCampPPtPage.LessonsPPtData[1] or {}
	if first_ppt_data and first_ppt_data.is_ppt_cover then
		return server_index + 2
	end
	return server_index + 1
end

function RedSummerCampPPtPage.IsHavePPTCover()
	if not RedSummerCampPPtPage.LessonsPPtData then
		return false
	end
	local first_ppt_data = RedSummerCampPPtPage.LessonsPPtData[1] or {}
	if first_ppt_data and (first_ppt_data.is_ppt_cover or first_ppt_data.is_div_ppt_cover_old) then
		return true
	end
	return false
end

function RedSummerCampPPtPage.GetProjectListData(callback)
	local project_id_list = {}
	for project_id, v in pairs(RedSummerCampPPtPage.ProjectIdToProjectData) do
		if v.imageUrl == nil then
			project_id_list[#project_id_list + 1] = project_id
		end
	end

	if #project_id_list == 0 then
		if callback then
			callback()
		end
		return
	end

	keepwork.world.search({
		type = 1,
		id = {["$in"] = project_id_list},
	},function(err, msg, data)
		if err == 200 then
			for k, v in pairs(data.rows) do
				if v.extra then
					RedSummerCampPPtPage.ProjectIdToProjectData[tonumber(v.id)] = {imageUrl = v.extra.imageUrl, worldTagName = v.extra.worldTagName or v.name}
				end
			end
			
			if callback then
				callback()
			end
		end
	end)
end

function RedSummerCampPPtPage.GetProjectData(project_id)
	return RedSummerCampPPtPage.ProjectIdToProjectData[tonumber(project_id)] or {}
end

function RedSummerCampPPtPage.GetStepTitle()
	if RedSummerCampPPtPage.SelectPPtData then
		return RedSummerCampPPtPage.SelectPPtData.step_1_title
	end
end

function RedSummerCampPPtPage.GetCourseTitle()
	if RedSummerCampPPtPage.CourseConfigData then
		return RedSummerCampPPtPage.CourseConfigData.name or ""
	end

	return ""
end

function RedSummerCampPPtPage.GetTeachingPlanPower()
	-- if GameLogic.IsVip() then
	-- 	return true
	-- end

	local profile = KeepWorkItemManager.GetProfile() or {}
	if profile.tLevel == 1 then
		return true
	end

	local UserPermission = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/UserPermission.lua");
	if UserPermission.GetRoleData("organ_school_teacher") then
		return true
	end

	return false
end

function RedSummerCampPPtPage.OpenVideoLink(link, is_external_link, title)
	title = title or ""
	if System.os.GetPlatform() ~= 'win32' or not System.options.enable_npl_brower or is_external_link or System.os.IsWindowsXP() then
		-- 除了win32平台，使用默认浏览器打开视频教程
		if System.os.IsWindowsXP() then
			link = string.gsub(link, "https", "http")
		end
		local cmd = string.format("/open %s", link);
		GameLogic.RunCommand(cmd);

		return
	end

	NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/BackgroundMusic.lua");
	local BackgroundMusic = commonlib.gettable("MyCompany.Aries.Game.Sound.BackgroundMusic");
	BackgroundMusic:Silence()

	local NplBrowserManager = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserManager.lua");
	NplBrowserManager:CreateOrGet("PPtVideoLink"):Show(link, title, false, true, { scale_screen = "4:3:v", closeBtnTitle = L"退出" }, function(state)
		if(state == "ONCLOSE")then
			BackgroundMusic:Recover()
			NplBrowserManager:CreateOrGet("PPtVideoLink"):GotoEmpty();
		end
	end);
end

function RedSummerCampPPtPage.IsShetuanCourse()
	if not RedSummerCampPPtPage.CourseConfigData then
		return false
	end

	local name = RedSummerCampPPtPage.CourseConfigData.name
	return string.find(name, "社团课")
end

function RedSummerCampPPtPage.IsSupportVideo()
	if RedSummerCampPPtPage.ForbidVideoFunction then
		return false
	end

	if (System.os.GetPlatform() == "win32" or
	    System.os.GetPlatform() == "mac") then
		return true
	end
	if (System.os.GetPlatform() == "android" or
        System.os.GetPlatform() == "ios") then
		local runtimeVer, paraEngineMajorVer, paraEngineMinorVer = System.os.GetParaEngineVersion();

		if (paraEngineMajorVer and (paraEngineMajorVer >= 1 and paraEngineMinorVer >=2)) then --1.2.1.0才支持的 （2022/12/23）
			return true
		end
	end
	return false
end

function RedSummerCampPPtPage.UseMidTitle()
	local ppt_data = RedSummerCampPPtPage.LessonsPPtData[RedSummerCampPPtPage.SelectLessonIndex] or {}
	return ppt_data.UseMiddleTitle and RedSummerCampPPtPage.IsSupportVideo()
end

function RedSummerCampPPtPage.UseVideoPage()
	local ppt_data = RedSummerCampPPtPage.LessonsPPtData[RedSummerCampPPtPage.SelectLessonIndex] or {}
	return ppt_data.IsUseVideoPage and RedSummerCampPPtPage.IsSupportVideo()
end

function RedSummerCampPPtPage.RefreshVideoSize()
	if RedSummerCampPPtPage.IsFullPage then
		RedSummerCampPPtFullPage.RefreshVideoSize()
		return
	end
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

function RedSummerCampPPtPage.ChangeVideoVisible(flag)
	flag = flag or false
	if not page or not page:IsVisible() then
		local NplBrowserPlugin = commonlib.gettable("NplBrowser.NplBrowserPlugin");
		local config = NplBrowserPlugin.GetCache("nplbrowser_pptvideo");
		if config then
			config.visible = visible;
			NplBrowserPlugin.Show(config);
		end
		return
	end

	local browser_node = page:GetNode("nplbrowser_pptvideo")
	if browser_node then
		page:CallMethod("nplbrowser_pptvideo","SetVisible",flag)
	
		local NplBrowserManager = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserManager.lua");	
		if not flag then
			NplBrowserManager:PauseVideo()
		else
			NplBrowserManager:PlayVideo()
		end
	end	
end

function RedSummerCampPPtPage.SetUseCloseAnim(flag)
	RedSummerCampPPtPage.is_use_close_anim = flag
end

function RedSummerCampPPtPage.CreateWorld(node_name, mcml_node)
	if RedSummerCampPPtPage.is_in_create_world then
		return
	end

	RedSummerCampPPtPage.ChangeVideoVisible(false)
	RedSummerCampPPtPage.is_in_create_world = true

	commonlib.TimerManager.SetTimeout(function()
		-- local title  = string.gsub(RedSummerCampPPtPage.GetPPtTitle(), "%s+", "")
		local worldname = mcml_node:GetString("worldname")
		local fork_project_id = mcml_node:GetString("fork_project_id")
		local titleStr = worldname or RedSummerCampPPtPage.GetCourseTitle()
		local project_name = titleStr .. "作业世界"
	
			local currentEnterWorld = GameLogic.GetFilters():apply_filters('store_get', 'world/currentEnterWorld');
			if currentEnterWorld and currentEnterWorld.foldername == project_name and Game.is_started then
				RedSummerCampPPtPage.ClosePPtAllPage()
				return
			end
	
		local project_file_path = "worlds/DesignHouse"
		if GameLogic.GetFilters():apply_filters('is_signed_in') then
			project_file_path = GameLogic.GetFilters():apply_filters('service.local_service_world.get_user_folder_path')
		end
		local name = commonlib.Encoding.Utf8ToDefault(project_name)
		local world_path = project_file_path .. "/" .. name
		local full_path = ParaIO.GetWritablePath()..world_path
		full_path = string.gsub(full_path, "[/\\%s+]+$", "")
		full_path = string.gsub(full_path, "%s+", "")
	
		local is_file_exist = ParaIO.DoesFileExist(full_path, true)
		local desc_list = {desc1=string.format("正在为你加载《%s》作业世界", titleStr)}
		if is_file_exist then
			local worldPath = full_path;
			worldPath = string.gsub(full_path, "[/\\]$", "");
			local xmlRoot = ParaXML.LuaXML_ParseFile(worldPath .. "/tag.xml");
			if (xmlRoot) then
				local node;
				for node in commonlib.XPath.eachNode(xmlRoot, "/pe:mcml/pe:world") do
					if node.attr then
						local totalEditSeconds = node.attr.totalEditSeconds or 0
						local totalSingleBlocks = node.attr.totalSingleBlocks or 0
						local edit_hour = math.floor(totalEditSeconds/60/60)
						local edit_min = math.floor(totalEditSeconds/60)

						local edit_desc = edit_min .. " 分钟"
						if edit_min >= 120 then
							edit_desc = edit_hour .. " 小时"
						end
						desc_list.desc2 = string.format("你已在此世界中创作 %s，共创建 %s 个方块，请再接再厉，继续创作", edit_desc, totalSingleBlocks)
					end
					
					--totalEditSeconds
					--totalSingleBlocks
					break;
				end
			end
			
		end
	
		local loading_end_callback = function()
			RedSummerCampPPtPage.is_in_create_world = false
			if not is_file_exist then
				-- local CreateNewWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.CreateNewWorld")
				if fork_project_id then
					-- GameLogic.RunCommand(string.format([[/createworld -name "%s" -update -fork %d]], project_name, fork_project_id))
				else
					local CreateWorld = NPL.load('(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua')
					CreateWorld:CreateWorldByName(project_name, "superflat",false)
				end

				RedSummerCampPPtPage.NeedSetTag = true
			end
			local SyncWorld = NPL.load('(gl)Mod/WorldShare/cellar/Sync/SyncWorld.lua')
			SyncWorld:CheckAndUpdatedByFoldername(project_name,function ()
				GameLogic.RunCommand(string.format('/loadworld %s', project_file_path .. "/" .. project_name))
				local Progress = NPL.load('(gl)Mod/WorldShare/cellar/Sync/Progress/Progress.lua')
				Progress.syncInstance = nil
			end,"homework")
		end
	
		local action = string.format("crsp.course.progress.start-%s-%s-creatworld", RedSummerCampPPtPage.CurCourseName, RedSummerCampPPtPage.SelectLessonIndex)
		GameLogic.GetFilters():apply_filters('user_behavior', 1, action, RedSummerCampPPtPage.GetReportData({section = RedSummerCampPPtPage.SelectLessonIndex}))
		
		local CreateWorldLoadingPgae = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/CreateWorldLoadingPgae.lua")
		CreateWorldLoadingPgae.ShowView(loading_end_callback, desc_list);
		if not is_file_exist and fork_project_id then
			GameLogic.RunCommand(string.format([[/createworld -name "%s" -update -fork %d]], project_name, fork_project_id))			
			CreateWorldLoadingPgae.SetSpecialFlag(false);
		end
	end, 50);

end

function RedSummerCampPPtPage.IsShowFullScreenBt()
	local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
	local profile = KeepWorkItemManager.GetProfile() or {}
	return profile.tLevel and profile.tLevel == 1
end

function RedSummerCampPPtPage.OnPageOpen(params)
	commonlib.TimerManager.SetTimeout(function()
		if RedSummerCampPPtPage.IsFullPage then
			return
		end
		if not page or not page:IsVisible() then
			return
		end
		if not RedSummerCampPPtPage.IsTopPage() and params.name ~= "MsgBox" and params.name ~= "TeacherAgent.TeacherIcon.ShowPage"
		and params.name ~= "NplBrowserLoaderPage.ShowPage" then
			RedSummerCampPPtPage.ChangeVideoVisible(false)
		end
	end, 10);

	return params
end

function RedSummerCampPPtPage.OnPageClose()
	commonlib.TimerManager.SetTimeout(function()
		if RedSummerCampPPtPage.IsFullPage then
			return
		end
		if not page or not page:IsVisible() then
			return
		end

		if RedSummerCampPPtPage.IsTopPage() and RedSummerCampPPtPage.UseVideoPage() and not RedSummerCampPPtPage.InCloseAnim and RedSummerCampPPtPage.IsOpen() then
			RedSummerCampPPtPage.ChangeVideoVisible(true)
		end
	end, 10);
end

function RedSummerCampPPtPage.IsTopPage()
	if not page or not page:IsVisible() then
		return false
	end
	local _app = CommonCtrl.os.GetApp("WebBrowser_GUID")
	local _wnd = _app:FindWindow("RedSummerCampPPtPage.Show")
	if _wnd then
		local _wndFrame = _wnd:GetWindowFrame()
		return _wndFrame:IsTopFrame()
	end

	return false
end

function RedSummerCampPPtPage.CheckVideo()
	local ppt_data = RedSummerCampPPtPage.LessonsPPtData[RedSummerCampPPtPage.SelectLessonIndex] or {}
	if not ppt_data.IsUseVideoPage then
		return
	end

	local NplBrowserLoaderPage = commonlib.gettable("NplBrowser.NplBrowserLoaderPage");
	if not NplBrowserLoaderPage.IsLoaded() and not RedSummerCampPPtPage.isLoadVideo then
		GameLogic.GetFilters():apply_filters("cellar.common.msg_box.show", L"正在加载视频中，请稍候....", 180000);
		return
	end

	if not RedSummerCampPPtPage.ForbidVideoFunction and NplBrowserLoaderPage.IsLoaded() then
		RedSummerCampPPtPage.isLoadVideo = false;
		RedSummerCampPPtPage.loadVideoStartTime = commonlib.TimerManager.GetCurrentTime();
		GameLogic.GetFilters():apply_filters("cellar.common.msg_box.show", L"正在加载视频中，请稍候...", 15000);
	

		if not RedSummerCampPPtPage.videoTimer then
			RedSummerCampPPtPage.videoTimer = commonlib.Timer:new({
				callbackFunc = function(timer)
					if (RedSummerCampPPtPage.isLoadVideo) then
						GameLogic.GetFilters():apply_filters("cellar.common.msg_box.close");
						-- local NplBrowserPlugin = commonlib.gettable("NplBrowser.NplBrowserPlugin");
						-- NplBrowserPlugin.Show({ id = "nplbrowser_pptvideo", visible = true });
						RedSummerCampPPtPage.videoTimer:Change(nil, nil);
					else
						local curLoadingTime = commonlib.TimerManager.GetCurrentTime();
		
						local diffTime = curLoadingTime - RedSummerCampPPtPage.loadVideoStartTime;
						
						if (diffTime >= 15*1000) then
							RedSummerCampPPtPage.videoTimer:Change(nil, nil);
							local videoUrl = string.match(ppt_data.div_str, 'href=%"([^"]*)%"');
							ParaGlobal.ShellExecute("open", videoUrl, "", "", 1);
							GameLogic.GetFilters():apply_filters("cellar.common.msg_box.close");
							RedSummerCampPPtPage.ForbidVideoFunction = true
							RedSummerCampPPtPage.RefreshPage()
		
							-- 上报
							NPL.load("(gl)script/apps/Aries/Creator/Game/Common/ParacraftDebug.lua");
							local ParacraftDebug = commonlib.gettable("MyCompany.Aries.Game.Common.ParacraftDebug");
							ParacraftDebug:SendErrorLog("DevDebugLog", {
								desc = "ppt video load failed",
								errorMessage = "",
								debugTag = "RedSummerCampPPtPage",
								stackInfo = commonlib.debugstack()
							})
						end
					end
				end
			});
		end

	
		RedSummerCampPPtPage.videoTimer:Change(100, 100)
	end
end