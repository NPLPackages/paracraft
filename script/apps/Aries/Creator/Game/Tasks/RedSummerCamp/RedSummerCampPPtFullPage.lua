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
local RedSummerCampCourseScheduling = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCourseScheduling.lua") 
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
end

function RedSummerCampPPtFullPage.OnClose()
	RedSummerCampPPtPage.SetIsFullPage(false)
	RedSummerCampPPtPage.RefreshPage()
end

function RedSummerCampPPtFullPage.ClosePage()
	if page then
		page:CloseWindow(true)
		page = nil
	end
end

function RedSummerCampPPtFullPage.Show(div_str)
	div_str = div_str or ""
	RedSummerCampPPtPage.SetIsFullPage(true)
	RedSummerCampPPtFullPage.IsInFullPage = true
	RedSummerCampPPtFullPage.InitData(div_str)
	
	
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
end

function RedSummerCampPPtFullPage.RefreshPage()
	if page then
		RedSummerCampPPtFullPage.StepNumKey = 0
		page:Refresh(0)
	end
end

function RedSummerCampPPtFullPage.InitData(div_str)
	-- local text = string.gsub(div_str, 'style="margin-left: 50px', 'style="margin-left: 80px')
	-- print("ffffffffffffffff", string.find(div_str, 'style="margin-left: 50px'))
	-- print("ddddddddd", text)
	RedSummerCampPPtFullPage.StepNumKey = 0
	RedSummerCampPPtFullPage.ShowDivStr = div_str
end


function RedSummerCampPPtFullPage.SetStepNumKey(key)
	RedSummerCampPPtFullPage.StepNumKey = key
end

function RedSummerCampPPtFullPage.GetStepNumKey()
	return RedSummerCampPPtFullPage.StepNumKey
end
function RedSummerCampPPtFullPage.RefreshPage()
	if page then
		page:Refresh(0)
	end
end

function RedSummerCampPPtFullPage.GetPPtStr()
	return RedSummerCampPPtFullPage.ShowDivStr
end