--[[
Title: DockCampIcon
Author(s): yangguiyi
Date: 2021/01/28
Desc:  
Use Lib:
-------------------------------------------------------
local DockCampIcon = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockCampIcon.lua");
DockCampIcon.Show();
--]]
local QuestCoursePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestCoursePage.lua");

local DockCampIcon = NPL.export();
local page;

DockCampIcon.leftMin = 10;
DockCampIcon.leftMax = 128;
DockCampIcon.left = DockCampIcon.leftMin;
DockCampIcon.top = -120;
DockCampIcon.width = 400;
DockCampIcon.height = 200;

DockCampIcon.CourseTimeLimit = {
	{begain_time = {hour=10,min=30}, end_time = {hour=10,min=45}},
	{begain_time = {hour=13,min=30}, end_time = {hour=13,min=45}},
	{begain_time = {hour=16,min=0}, end_time = {hour=16,min=15}},
	{begain_time = {hour=18,min=0}, end_time = {hour=18,min=15}},
	{begain_time = {hour=19,min=0}, end_time = {hour=19,min=15}},
}

function DockCampIcon.OnInit()
	page = document:GetPageCtrl();
	page.OnClose = DockCampIcon.CloseView
	page.OnCreate = DockCampIcon.OnCreate
end

function DockCampIcon.OnCreate()
end

function DockCampIcon.CloseView()
	NPL.KillTimer(10087)
end

function DockCampIcon.Show()
	DockCampIcon.ShowView()
end

function DockCampIcon.ShowView()
	if page and page:IsVisible() then
		return
	end
	
	local left = DockCampIcon.left;
	local params = {
		url = "script/apps/Aries/Creator/Game/Tasks/Dock/DockCampIcon.html",
		name = "DockCampIcon.Show",
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = false,
		bShow = bShow,
		zorder = -1,
		ClickThrough = true,
		enable_esc_key = false,
		cancelShowAnimation = true,
		directPosition = true,
			align = "_ctl",
			x = left,
			y = DockCampIcon.top,
			width = DockCampIcon.width,
			height = DockCampIcon.height,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	NPL.SetTimer(10087, 3, ';NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockCampIcon.lua").UpdateTime()');
end

function DockCampIcon.UpdateTime()
	if page and not page:IsVisible() then
		DockCampIcon.CloseView()
		return
	end
	
	page:SetUIValue("cur_time", os.date("%H:%M"))

	local begain_day_weehours = os.time(QuestCoursePage.begain_time_t)
	if os.time() < begain_day_weehours then
		page:SetUIValue("cur_state", "自由探索")
	else
		local cur_time_stamp = os.time()
		if QuestCoursePage.IsGraduateTime(cur_time_stamp) then
			page:SetUIValue("cur_state", "自由探索")
		else
			local cur_state = DockCampIcon.CheckCourseTimeState(cur_time_stamp)
			local desc = cur_state == QuestCoursePage.ToCourseState.in_time and "上课" or "自由探索"
			page:SetUIValue("cur_state", desc)
		end
	end	
end

function DockCampIcon.CheckCourseTimeState(cur_time_stamp)
	local day_weehours = commonlib.timehelp.GetWeeHoursTimeStamp(cur_time_stamp)
	for i, v in ipairs(DockCampIcon.CourseTimeLimit) do
		local begain_time_stamp = day_weehours + v.begain_time.min * 60 + v.begain_time.hour * 3600
		local end_time_stamp = day_weehours + v.end_time.min * 60 + v.end_time.hour * 3600

		if cur_time_stamp >= begain_time_stamp and cur_time_stamp <= end_time_stamp then
			return QuestCoursePage.ToCourseState.in_time
		end

		if i == 1 and cur_time_stamp < begain_time_stamp then
			return QuestCoursePage.ToCourseState.before
		end
		-- print("saaaaaaaaaaaaaa", i, #DockCampIcon.CourseTimeLimit, cur_time_stamp, begain_time_stamp, cur_time_stamp > begain_time_stamp)
		if i == #DockCampIcon.CourseTimeLimit and cur_time_stamp > begain_time_stamp then
			return QuestCoursePage.ToCourseState.finish
		end
	end

	for i, v in ipairs(DockCampIcon.CourseTimeLimit) do
		local begain_time_stamp = day_weehours + v.begain_time.min * 60 + v.begain_time.hour * 3600
		local end_time_stamp = day_weehours + v.end_time.min * 60 + v.end_time.hour * 3600

		if cur_time_stamp < begain_time_stamp then
			return QuestCoursePage.ToCourseState.late, i
		end
	end

	return QuestCoursePage.ToCourseState.late
end