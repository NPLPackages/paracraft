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
local RedSummerCampPPtPage = NPL.export();
local ParacraftLearningRoomDailyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParacraftLearningRoom/ParacraftLearningRoomDailyPage.lua");
local RedSummerCampCourseScheduling = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCourseSchedulingV2.lua") 
local RedSummerCampMainWorldPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampMainWorldPage.lua");
local RedSummerCampPPtFullPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtFullPage.lua");
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

local key_to_report_name = {
	["ppt_L1"] = "org",		-- 机构课L1
	["ppt_L2"] = "org_L2",	-- 机构课L2
	["ppt_S1"] = "430",		-- 社团课S1
	["ppt_X1"] = "campus",	-- 校园课X1
	["ppt_Z1"] = "demo_lesson",
}
function RedSummerCampPPtPage.OnInit()
	page = document:GetPageCtrl();
	page.OnCreate = RedSummerCampPPtPage.OnCreate
	page.OnClose = RedSummerCampPPtPage.OnClose
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

	RedSummerCampPPtPage.RefreshSize()
	RedSummerCampPPtPage.StepNumKey = 0
end

function RedSummerCampPPtPage.ClosePage()
	if RedSummerCampPPtPage.OpenPageTimeStamp then
		local extend_data = {}
		extend_data.duration = QuestAction.GetServerTime() - RedSummerCampPPtPage.OpenPageTimeStamp
		local action = string.format("crsp.course.exit-%s", RedSummerCampPPtPage.CurCourseName)
		GameLogic.GetFilters():apply_filters('user_behavior', 1, action, RedSummerCampPPtPage.GetReportData(extend_data))
		RedSummerCampPPtPage.OpenPageTimeStamp = nil
	end

	if page then
		page:CloseWindow(true)
		page = nil
	end
end

function RedSummerCampPPtPage.OnClose()

	if not RedSummerCampPPtPage.IsSaveIndex then
		RedSummerCampPPtPage.IsOpenPage = false
	end

	page = nil
	RedSummerCampPPtPage.IsSaveIndex = nil
	RedSummerCampMainWorldPage.SetOpenFromCommandMenu(false)

	RedSummerCampPPtPage.UpdateTimer:Change()
	RedSummerCampPPtPage.UpdateTimer = nil
	RedSummerCampPPtPage.is_in_debug = false	
	RedSummerCampPPtPage.is_preview = false
	RedSummerCampPPtPage.defaul_select_index = nil
	RedSummerCampPPtPage.DebugData = {}
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
	local lesson_index = RedSummerCampPPtPage.GetLessonIndex()

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

function RedSummerCampPPtPage.Show(course_data, pptIndex, is_show_exit_bt)
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
			RedSummerCampPPtPage.ShowPage(course_name, pptIndex)
		end)
	else
		RedSummerCampPPtPage.UseNewFilePath = false
		local course_name = course_data
		RedSummerCampPPtPage.ShowPage(course_name, pptIndex)
	end

end

function RedSummerCampPPtPage.ShowPage(course_name, pptIndex)
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
	
	local enable_esc_key = RedSummerCampPPtPage.is_in_debug
	local params = {
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
		GameLogic:Connect("WorldLoaded", RedSummerCampPPtPage, RedSummerCampPPtPage.OnWorldLoaded, "UniqueConnection");
		GameLogic:Connect("WorldUnloaded", RedSummerCampPPtPage, RedSummerCampPPtPage.OnWorldUnloaded, "UniqueConnection");

		NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
		local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
        local viewport = ViewportManager:GetSceneViewport();
        viewport:Connect("sizeChanged", CodeLessonTip, function()
			commonlib.TimerManager.SetTimeout(function()
				RedSummerCampPPtPage.RefreshSize()
			end, 500);
			
		end, "UniqueConnection");

		GameLogic.GetEvents():AddEventListener("CodeBlockWindowShow", RedSummerCampPPtPage.CodeWinChangeVisible, RedSummerCampPPtPage, "RedSummerCampPPtPage");
	end
	
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
end

function RedSummerCampPPtPage.CodeWinChangeVisible(event)
    RedSummerCampPPtPage.IsShowCodeWin = RedSummerCampPPtPage.IsEditorOpen()
    RedSummerCampPPtPage.RefreshSize()
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

	local Screen = commonlib.gettable("System.Windows.Screen");
	local win_width = Screen:GetWidth()
	local win_height = Screen:GetHeight()
	if RedSummerCampPPtPage.is_in_debug and RedSummerCampPPtPage.is_preview then
		local grid_node = page:GetNode("slot_gridview")
		local TreeViewNode = grid_node:GetChild("pe:treeview");
		local treeview_object = ParaUI.GetUIObject(TreeViewNode.control.name);
		if treeview_object:IsValid() then
			local VScrollBar = treeview_object:GetChild("VScrollBar");
			if VScrollBar:IsValid() then
				VScrollBar.visible = false
			end
		end

		local grid_node = page:GetNode("notes_gridview")
		if grid_node then
			local TreeViewNode = grid_node:GetChild("pe:treeview");
			local treeview_object = ParaUI.GetUIObject(TreeViewNode.control.name);
			if treeview_object:IsValid() then
				local VScrollBar = treeview_object:GetChild("VScrollBar");
				if VScrollBar:IsValid() then
					VScrollBar.visible = false
				end
			end
		end
		

		TreeViewNode:SetAttribute("HideVerticalScrollBar", true);
		
		NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
		local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
		-- local bShow = event.bShow
		local viewport = ViewportManager:GetSceneViewport();
		local view_x,view_y,view_width,view_height = viewport:GetUIRect()

		local page_root = ParaUI.GetUIObject("PPTPageRoot");
		
		local scale = view_width/1280
		page_root.x = -(win_width/2-win_width*scale/2)/scale
		page_root.y = -(win_height/2 - win_height*scale/2)/scale
		local root = page:GetRootUIObject()
		local att = ParaEngine.GetAttributeObject();
		
		root.scalingx = scale
		root.scalingy = scale
		root:ApplyAnim();
		root.enabled = false
		
	else

		local page_root = ParaUI.GetUIObject("PPTPageRoot");
		page_root.width = win_width
		page_root.height = win_height
	end
end

-- 代码编辑器是否打开
function RedSummerCampPPtPage.IsEditorOpen()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockWindow.lua");
	local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
    return CodeBlockWindow.IsVisible();
end

function RedSummerCampPPtPage.RefreshPage()
	if page then
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
			strValue = string.format([[<div class="step_1_title">%s</div>]], strValue)
			local start_index = string.find(strValue, "《")
			local end_index = string.find(strValue, "》")
			if start_index and end_index then
				ppt_data.step_1_title = string.sub(strValue, start_index + 3, end_index - 1)
				ppt_data.step_1_title = string.gsub(ppt_data.step_1_title, "<br/>", "")
			end
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
				local grid_margin_left = ppt_data.is_ppt_cover and 30 or 0
				local grid_margin_top = ppt_data.is_ppt_cover and -32 or 8
				local notes_data_str = '<%=NotesData %>'
				-- local grid_width = ppt_data.is_ppt_cover and 825 or 855

				local div_gridview = string.format([[<pe:gridview style="margin-left:%s;margin-top:%s;width:%s;height: 114px; " name="notes_gridview" CellPadding="1" 
				VerticalScrollBarStep="36" VerticalScrollBarOffsetX="8" AllowPaging="false" 
				ItemsPerLine="1" RememberScrollPos="true" DefaultNodeHeight = "36" 
				DataSource='%s'><Columns>]], grid_margin_left, grid_margin_top, 834, notes_data_str)

				ppt_data.div_str = (ppt_data.div_str or "") .. table.concat({
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
        local strTip = "你暂时没有该课程的访问权限，请联系客服或使用对应的激活码。"
        _guihelper.MessageBox(strTip,nil,_guihelper.MessageBoxButtons.OK_CustomLabel,nil,"script/apps/Aries/Creator/Game/GUI/DefaultMessageBox.lesson.html")
		return
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

function RedSummerCampPPtPage.IsPPTCover()
	local ppt_data = RedSummerCampPPtPage.SelectPPtData
	return ppt_data and ppt_data.is_ppt_cover
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
	local lesson_index = RedSummerCampPPtPage.GetLessonIndex() + 1
	local action = string.format("crsp.course.section.finish-%s-%s", RedSummerCampPPtPage.CurCourseName, lesson_index)
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
		if finish_num >= RedSummerCampPPtPage.GetCurLessonStepNum() then
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
	if step_value == nil then
		return
	end

	RedSummerCampPPtPage.SyncWorldStepValue = step_value
end

function RedSummerCampPPtPage.OnVisitWrold(projectid)
	echo(RedSummerCampPPtPage.StepValueToProjectId, true)
	if projectid and RedSummerCampPPtPage.StepValueToProjectId then
		projectid = tostring(projectid)
		local step_value
		for k, v in pairs(RedSummerCampPPtPage.StepValueToProjectId) do
			-- 只有第二步骤是访问才算完成了
			if v == projectid and tonumber(k) == 2 then
				step_value = k
				break
			end
		end
		if step_value then
			RedSummerCampPPtPage.SetCourseClientData(step_value, 1)
			RedSummerCampPPtPage.ReportFinishCurTask()
		end
	end
end

function RedSummerCampPPtPage.OnSaveWrold()
	if RedSummerCampPPtPage.SaveWorldStepList then
		for k, v in pairs(RedSummerCampPPtPage.SaveWorldStepList) do
			RedSummerCampPPtPage.SetCourseClientData(k, 1)
		end
	end

	RedSummerCampPPtPage.ReportFinishCurTask()
end

function RedSummerCampPPtPage.OnSyncWorldFinish()
	local step_value = RedSummerCampPPtPage.SyncWorldStepValue or "4"
	RedSummerCampPPtPage.SetCourseClientData(step_value, 1)
	
	RedSummerCampPPtPage.StartTask("share")
	RedSummerCampPPtPage.ReportFinishCurTask()
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

function RedSummerCampPPtPage.OnWorldLoaded()
	if page then
		-- body
		page:CloseWindow(true)
		page = nil

		RedSummerCampPPtPage.SetIsReturnOpenPage(true)
	end
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

function RedSummerCampPPtPage.OpenLastPPtPage(is_show_exit_bt)
	if RedSummerCampPPtPage.GetIsReturnOpenPage() then
		if not RedSummerCampCourseScheduling.IsOpen() then
			RedSummerCampCourseScheduling.ShowView()
		end
		
		RedSummerCampPPtPage.Show(nil, nil, is_show_exit_bt)
	end
end

function RedSummerCampPPtPage.ClosePPtAllPage()
	RedSummerCampPPtPage.IsSaveIndex = true
	if RedSummerCampMainWorldPage.GetOpenFromCommandMenu() then
		RedSummerCampPPtPage.IsOpenPage = true
	end
	
	RedSummerCampPPtPage.ClosePage()

	RedSummerCampCourseScheduling.ClosePage()

	RedSummerCampMainWorldPage.ClosePage()

	RedSummerCampPPtFullPage.ClosePage()
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
		if step_1_project_id and tonumber(step_1_project_id) == tonumber(projectid) then
			RedSummerCampPPtPage.SetCourseClientData(1, 1)
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

	RedSummerCampPPtPage.CurTaskData = nil
	GameLogic.GetFilters():apply_filters('user_behavior', 1, action, RedSummerCampPPtPage.GetReportData(extend_data))
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

function RedSummerCampPPtPage.OnClickAction(action_type, param1, param2, param3)
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
			step_value = 1
		end
	
		if action_type == "button" then
			step_value = 2
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
		RedSummerCampPPtPage.StartTask("creatworld")
	end
	-- if action_type == "dailyVideo" then
	-- 	RedSummerCampPPtPage.StartTask("dailyVideo")
	-- end

	if action_type == "button" or action_type == "explore" then
		local projectid = param1
		local commandStr = string.format("/loadworld -s -auto %s", projectid)
		local sendevent = param2
		if sendevent and sendevent ~= "" then
			commandStr = string.format("/loadworld -s -auto -inplace %s  | /sendevent %s", projectid,sendevent)
		end
		if RedSummerCampPPtPage.last_course_data and action_type == "button" then
			RedSummerCampPPtPage.last_course_data.ppt_to_projectid = projectid
			RedSummerCampPPtPage.last_course_data.ppt_index= RedSummerCampPPtPage.GetLessonIndex()
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
		
		-- ParaGlobal.ShellExecute("open", link, "", "", 1); 
		if System.os.GetPlatform() ~= 'win32' or not System.options.enable_npl_brower or is_external_link then
			-- 除了win32平台，使用默认浏览器打开视频教程
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

function RedSummerCampPPtPage.ToWorld(project_id)
	if project_id then
		local commandStr = string.format("/loadworld -s -auto %s", project_id)
		GameLogic.RunCommand(commandStr)
		if RedSummerCampPPtPage.last_course_data then
			RedSummerCampPPtPage.last_course_data.ppt_to_projectid = project_id
			RedSummerCampPPtPage.last_course_data.ppt_index= RedSummerCampPPtPage.GetLessonIndex()
		end
	end
end

function RedSummerCampPPtPage.IsLock(index)
	return index > 1 and RedSummerCampPPtPage.IsLockCourse
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

function RedSummerCampPPtPage.GetLessonIndex()
	if not RedSummerCampPPtPage.LessonsPPtData then
		return
	end
	local first_ppt_data = RedSummerCampPPtPage.LessonsPPtData[1] or {}
	if first_ppt_data and first_ppt_data.is_ppt_cover then
		return RedSummerCampPPtPage.SelectLessonIndex - 2
	end
	return RedSummerCampPPtPage.SelectLessonIndex - 1
end

function RedSummerCampPPtPage.GetProjectListData(callback)
	local project_id_list = {}
	for project_id, v in pairs(RedSummerCampPPtPage.ProjectIdToProjectData) do
		if v.imageUrl == nil then
			project_id_list[#project_id_list + 1] = project_id
		end
	end

	if #project_id_list == 0 then
		return
	end

	keepwork.world.search({
		type = 1,
		id = {["$in"] = project_id_list},
	},function(err, msg, data)
		--print("aaaaaaaaaaaaaaaaxx")
		--commonlib.echo(data, true)
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