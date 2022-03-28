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
local RedSummerCampCourseScheduling = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCourseScheduling.lua") 
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
RedSummerCampPPtPage.ProjectIdToPPtData = {}

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
			-- print("ddddddddddddddeee", err)
			-- echo(data, true)
			if err == 200 then
				if data.xml then
					ParaIO.CreateDirectory(file_path)
					local file = ParaIO.open(file_path, "w");
					if(file) then
						file:write(data.xml, #data.xml);
						file:close();
					end

					if callback then
						callback(course_name, pptIndex)
					end
				end
			end
		end)	
	end
end

function RedSummerCampPPtPage.Show(course_data, pptIndex)
	if not course_data then
		course_data = RedSummerCampPPtPage.LastParam or "ppt_X1"
	end
	
	RedSummerCampPPtPage.LastParam = course_data

	if not Lan then
		Lan = NPL.load("Mod/GeneralGameServerMod/Command/Lan/Lan.lua");
	end

	if type(course_data) == "table" then
		RedSummerCampPPtPage.UseNewFilePath = true
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
	RedSummerCampPPtPage.StepValueToProjectId = {}
	RedSummerCampPPtPage.SaveWorldStepList = {}
	RedSummerCampPPtPage.SyncWorldStepValue = nil
	RedSummerCampPPtPage.CurCourseName = course_name
	RedSummerCampPPtPage.StepNumKey = 0
	RedSummerCampPPtPage.CurCourseKey = RedSummerCampPPtPage.CurCourseName .. RedSummerCampPPtPage.SplitKey .. RedSummerCampPPtPage.SelectLessonIndex
	RedSummerCampPPtPage.InitData()
	local enable_esc_key = false
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
			DesignResolutionWidth = 1280,
			DesignResolutionHeight = 720,
			--app_key = 0, 
			directPosition = true,
				align = "_fi",
				x = 0,
				y = 0,
				width = 0,
				height = 0,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	RedSummerCampPPtPage.HandleErrorData()

	if not RedSummerCampPPtPage.BindFilter then
		RedSummerCampPPtPage.BindFilter = true
		GameLogic.GetFilters():add_filter("OnSaveWrold", RedSummerCampPPtPage.OnSaveWrold);
		GameLogic.GetFilters():add_filter("SyncWorldFinish", RedSummerCampPPtPage.OnSyncWorldFinish);
		GameLogic:Connect("WorldLoaded", RedSummerCampPPtPage, RedSummerCampPPtPage.OnWorldLoaded, "UniqueConnection");
		GameLogic:Connect("WorldUnloaded", RedSummerCampPPtPage, RedSummerCampPPtPage.OnWorldUnloaded, "UniqueConnection");
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
	local has_power = profile.tLevel == 1 or GameLogic.IsVip()
	local function handle_div_str(ppt_data, strValue)
		if last_div_is_title then
			strValue = string.format([[<div style="margin-left: 50px;margin-top: 12px;color: #e17a15;font-weight: bold;">%s</div>]], strValue)
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
			local project_id = tonumber(string.match(strValue, 'projectid="(%d+)"'))
			if project_id then
				if RedSummerCampPPtPage.ProjectIdToPPtData[project_id] == nil then
					RedSummerCampPPtPage.ProjectIdToPPtData[project_id] = {}
				end
	
				local export_data = {}
				export_data.course_name = course_name
				export_data.step_value = ppt_data.max_step
				export_data.course_index = #ppt_data_list
	
				local export_project_data = RedSummerCampPPtPage.ProjectIdToPPtData[project_id]
				export_project_data[#export_project_data + 1] = export_data
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

		if string.find(strValue, "dailyVideo") then
			ppt_data.has_daily_video = true
		end

		-- if string.find(strValue, "href") then
		-- 	ppt_data.has_link = true
		-- end
		
		if(is_note_str or is_start_notes) then
			ppt_data.notes_str = (ppt_data.notes_str or "") .. strValue;
		else
			ppt_data.div_str = (ppt_data.div_str or "") .. strValue
		end

		ppt_data.is_ppt_cover = string.find(strValue, "ppt_cover") ~= nil
	end

	-- this will merge multiple notes in ppt_data.notes_str into ppt_data.div_str
	local function formatNotesIntoPPT_()
		for _, ppt_data in ipairs(ppt_data_list) do
			if(ppt_data.notes_str) then
				ppt_data.div_str = (ppt_data.div_str or "") .. table.concat({
					[[<pe:gridview style="margin-left:0px;width:825px;height: 114px; " name="notes_gridview" CellPadding="1" VerticalScrollBarStep="36" VerticalScrollBarOffsetX="8" AllowPaging="false" ItemsPerLine="1" RememberScrollPos="true" DefaultNodeHeight = "36" DataSource='<%=NotesData %>'><Columns>]],
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

	RedSummerCampPPtPage.SelectLessonIndex = index
	RedSummerCampPPtPage.SelectPPtData = RedSummerCampPPtPage.LessonsPPtData[RedSummerCampPPtPage.SelectLessonIndex]
	RedSummerCampPPtPage.CurCourseKey = RedSummerCampPPtPage.CurCourseName .. RedSummerCampPPtPage.SplitKey .. RedSummerCampPPtPage.SelectLessonIndex
	RedSummerCampPPtPage.StepValueToProjectId = {}
	RedSummerCampPPtPage.SaveWorldStepList = {}
	RedSummerCampPPtPage.SyncWorldStepValue = nil
	-- 修复序号改动引发的数据不对的问题
	RedSummerCampPPtPage.HandleErrorData()
	RedSummerCampPPtPage.RefreshPage()

	-- 上报
	local action = string.format("crsp.course.section.visit-%s-%s", RedSummerCampPPtPage.CurCourseName, index)
	GameLogic.GetFilters():apply_filters('user_behavior', 1, action, RedSummerCampPPtPage.GetReportData({section = index}))
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
	local course_all_data = RedSummerCampPPtPage.GetCourseClientData()
	if course_all_data[RedSummerCampPPtPage.CurCourseKey] == nil then
		return false
	end

	local course_data = course_all_data[RedSummerCampPPtPage.CurCourseKey]
	if course_data and course_data[tostring(step)] then
		local value = course_data[tostring(step)]
		return tostring(value) == "1"
	end

	return false
end
-- 保存一些上报数据 比如这个课包的开始时间 这个课包是否完成 跟之前的逻辑区分开

--[[
	course_all_data格式
	{
		-- 课包名
		["ppt_L1"] = {
			start_time_stamp = 0,
			[1] = {
				start_time_stamp = 0,
				is_finish = 1, 
			}
		}
	}
]]
function RedSummerCampPPtPage.SetCourseReportClientData(key, value)
	value = tostring(value)
	local course_all_data = RedSummerCampPPtPage.GetCourseClientData()
	if not course_all_data[RedSummerCampPPtPage.CurCourseName] then
		course_all_data[RedSummerCampPPtPage.CurCourseName] = {}
	end
	local course_data = course_all_data[RedSummerCampPPtPage.CurCourseName]
	if course_data.start_time_stamp == nil then
		course_data.start_time_stamp = QuestAction.GetServerTime()
	end
	-- if course_data.lesson_num == nil then
	-- 	course_data.lesson_num = #RedSummerCampPPtPage.LessonsPPtData
	-- end

	if not course_data[RedSummerCampPPtPage.SelectLessonIndex] then
		course_data[RedSummerCampPPtPage.SelectLessonIndex] = {}
	end

	local lesson_data = course_data[RedSummerCampPPtPage.SelectLessonIndex]
	-- if not lesson_data.task_num then
	-- 	lesson_data.task_num = RedSummerCampPPtPage.GetCurCourseTaskNum()
	-- end
	if lesson_data[key] == value then
		return
	end

	lesson_data[key] = value

	local clientData = KeepWorkItemManager.GetClientData(40007) or {};
	clientData.CourseTaskData = course_all_data

    KeepWorkItemManager.SetClientData(40007, clientData, function()
    end);

	-- 上报完成一节课
	if key == "is_finish" and value == "1" then
		-- 上报完成一节课
		local action = string.format("crsp.course.section.finish-%s-%s", RedSummerCampPPtPage.CurCourseName, RedSummerCampPPtPage.SelectLessonIndex)
		local extend_data = {
			section = RedSummerCampPPtPage.SelectLessonIndex,
			sectionName = RedSummerCampPPtPage.GetPPtTitle() or "",
			score_building = 0,
			score_animation = 0,
			score_coding = 0,
			score_overall = 0,
		}

		if lesson_data.start_time_stamp then
			local cur_time_stamp = QuestAction.GetServerTime()
			local second = cur_time_stamp - tonumber(lesson_data.start_time_stamp)
			extend_data.duration = second
		end

		GameLogic.GetFilters():apply_filters('user_behavior', 1, action, RedSummerCampPPtPage.GetReportData(extend_data))
	end	

	local finish_num = 0
	for key, v in pairs(course_data) do
		if type(v) =="table" and v.is_finish and tostring(v.is_finish) == "1" then
			finish_num = finish_num + 1
		end
	end

	-- 上报完成课包
	if finish_num >= #RedSummerCampPPtPage.LessonsPPtData then
		-- 上报完成一节课
		local action = string.format("crsp.course.finish-%s", RedSummerCampPPtPage.CurCourseName)
		local extend_data = {
			score_building = 0,
			score_animation = 0,
			score_coding = 0,
			score_overall = 0,
		}

		if course_data.start_time_stamp then
			local cur_time_stamp = QuestAction.GetServerTime()
			local second = cur_time_stamp - tonumber(course_data.start_time_stamp)
			extend_data.days = math.floor(second/60/60/24)
		end
		GameLogic.GetFilters():apply_filters('user_behavior', 1, action, RedSummerCampPPtPage.GetReportData(extend_data))
	end
end

function RedSummerCampPPtPage.GetCurCourseTaskNum()
	if not RedSummerCampPPtPage.SelectPPtData then
		return 0
	end

	local all_step_num = RedSummerCampPPtPage.SelectPPtData.max_step or 0
	if RedSummerCampPPtPage.SelectPPtData.has_daily_video then
		all_step_num = all_step_num + 1
	end
	if RedSummerCampPPtPage.SelectPPtData.has_link then
		all_step_num = all_step_num + 1
	end

	return all_step_num
end

-- 这个其实就是任务完成了
function RedSummerCampPPtPage.SetCourseClientData(key, value)
	key = tostring(key)
	value = tostring(value)

	if RedSummerCampPPtPage.CurCourseKey == nil then
		return
	end

	local course_all_data = RedSummerCampPPtPage.GetCourseClientData()
	if course_all_data[RedSummerCampPPtPage.CurCourseKey] == nil then
		course_all_data[RedSummerCampPPtPage.CurCourseKey] = {}
	end

	local course_data = course_all_data[RedSummerCampPPtPage.CurCourseKey]

	if course_data[key] == value then
		return
	end
	course_data.is_fix = true
	course_data[key] = value
	
	local clientData = KeepWorkItemManager.GetClientData(40007) or {};
	clientData.CourseTaskData = course_all_data

	-- 任务完成的话 判断是否全部完成
	if value == "1" then
		local finish_num = 0
		for key, v in pairs(course_data) do
			if tostring(v) == "1" then
				finish_num = finish_num + 1
			end
		end

		if finish_num >= RedSummerCampPPtPage.GetCurCourseTaskNum() then
			RedSummerCampPPtPage.SetCourseReportClientData("is_finish", 1)
		end
	end

    KeepWorkItemManager.SetClientData(40007, clientData, function()
        RedSummerCampPPtPage.RefreshPage()
    end);

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
	commonlib.TimerManager.SetTimeout(function()  
		RedSummerCampPPtPage.FlushExportFullPage()
	end, 300);

	-- GameLogic.RunCommand("/open npl://console");
end

function RedSummerCampPPtPage.OpenLastPPtPage()
	if RedSummerCampPPtPage.GetIsReturnOpenPage() then
		RedSummerCampCourseScheduling.ShowView()
		RedSummerCampPPtPage.Show()
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
		if v.key == RedSummerCampPPtPage.CurCourseName then
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
		ParaMovie.TakeScreenShot_Async(filepath,true,  1280, 720, string.format("NPL.load('(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtPage.lua').FlushExportFullPage();%d",4))
	end, 100);
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
		if step_1_project_id and step_1_project_id == projectid then
			RedSummerCampPPtPage.SetCourseClientData(1, 1)
			RedSummerCampPPtPage.ReportFinishCurTask()
		end
	end
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

	-- 记录当前课包任务的开始时间
	RedSummerCampPPtPage.SetCourseReportClientData("start_time_stamp", RedSummerCampPPtPage.CurTaskData.start_time_stamp)
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

function RedSummerCampPPtPage.OnClickAction(action_type)
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

	RedSummerCampPPtPage.SetCourseClientData("dailyVideo", 1)
	RedSummerCampPPtPage.ReportFinishCurTask()
end

function RedSummerCampPPtPage.GetPPTConfigDiskFolder()
    if(not RedSummerCampPPtPage.DiskFolder) then
		RedSummerCampPPtPage.DiskFolder = ParaIO.GetWritablePath().."temp/ppt_config"
   end
    
	return RedSummerCampPPtPage.DiskFolder
end