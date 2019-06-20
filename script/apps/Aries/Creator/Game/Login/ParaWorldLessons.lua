--[[
Title: ParaWorldLessons
Author(s): LiXizhi
Date: 2018/9/16
Desc: 

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ParaWorldLessons.lua");
local ParaWorldLessons = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ParaWorldLessons")
ParaWorldLessons.CheckShowOnStartup(callbackFunc)
ParaWorldLessons.ShowPage()
ParaWorldLessons.EnterWorldById("2x27")
ParaWorldLessons.EnterWorldById("12345678")
local lesson = ParaWorldLessons.GetCurrentLesson()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/DownloadWorld.lua");
NPL.load("(gl)script/ide/Files.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/TeacherAgent/TeacherAgent.lua");
local TeacherAgent = commonlib.gettable("MyCompany.Aries.Creator.Game.Teacher.TeacherAgent");
local DownloadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.DownloadWorld")
local ParaWorldLessons = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ParaWorldLessons")

local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua");

ParaWorldLessons.page = nil;

local lesson_worlds = {
	{
		displayname = L"编辑模式", 
		title = L"动画1教程：安装，活动和编辑模式", 
		icon = "Texture/Aries/AppIcons/eggy.png",
		tooltip = L"告知用户如何安装软件，以及基本的一些操作快捷键和命令。",
		lession_id = "8X27",
	},
	{
		displayname = L"夏天游泳", 
		title = L"动画6教程：课堂实例夏天游泳", 
		icon = "Texture/Aries/AppIcons/summerswim.png",
		tooltip = L"运用之前所学的知识点，实例做出属于自己的短片：建造一个场景，在场景中加入演员角色以及动作编号，并完成拍摄。",
		lession_id = "8X32",
	},
	{
		displayname = L"简易动画开头", 
		title = L"动画7教程：进阶实例制作简易动画开头", 
		icon = "Texture/Aries/AppIcons/beautifulmind.png",
		tooltip = L"运用之前所学的知识点，实例做出属于自己的短片：调整演员的骨骼动作，和学习新的拍摄技巧，最后做出动画开头。",
		lession_id = "8X33",
	},
	{
		displayname = L"简易bmax小吉他", 
		title = L"动画9教程：课堂实例简易bmax小吉他", 
		icon = "Texture/Aries/AppIcons/bmax_guitar.png",
		tooltip = L"运用之前所学的知识点，实例做出属于自己的短片：做出bmax静态模型，将其保存后变成演员，利用人物动作+bmax道具拍摄出更多元化的小片段。",
		lession_id = "8X35",
	},
	{
		displayname = L"简易bmax小动画", 
		title = L"动画10教程：进阶实例简易bmax小动画", 
		icon = "Texture/Aries/AppIcons/bmax_anim.png",
		tooltip = L"运用之前所学的知识点，实例做出属于自己的短片：将bmax变成演员，让它成为主角，并有属于自己的动作。",
		lession_id = "8X36",
	},

	{
		displayname = L"编程基础", 
		title = L"编程教学：编程基础", 
		icon = "Texture/Aries/AppIcons/codeblock.png",
		tooltip = L"学会使用代码方块，并学习使用代码控制演员。",
		lession_id = "6x18",
	},

	{
		displayname = L"乒乓球游戏", 
		title = L"编程教学：乒乓球游戏", 
		icon = "Texture/Aries/AppIcons/pong.png",
		tooltip = L"大概1960年，人类最早的一款计算机游戏就是乒乓游戏，我们来学习制作一下。本节课我们学习多个代码方块控制不同角色完成一个小游戏以及掌握paracraft里多个函数和控制语句。",
		lession_id = "6x20",
	},

	{
		displayname = L"迷宫游戏", 
		title = L"编程教学：迷宫游戏", 
		icon = "Texture/Aries/AppIcons/maze.png",
		tooltip = L"制作迷宫场景。本节课学习让角色上下左右的移动，检测是否接触以及如何控制摄影机视角。",
		lession_id = "6x22",
	},

	{
		displayname = L"钢琴", 
		title = L"编程教学：钢琴", 
		icon = "Texture/Aries/AppIcons/piano.png",
		tooltip = L"制作一个可以演奏的钢琴。本节课学习使用clone函数来克隆角色实现有多个重复角色的游戏。",
		lession_id = "6x21",
	},
	{
		displayname = L"双重机关与事件", 
		title = L"编程教学：双重机关与事件", 
		icon = "Texture/Aries/AppIcons/doorkeys.png",
		tooltip = L"实现一个密码锁和双重机关。本节课学习如何使用全局变量和如何发布广播消息和接收广播消息。",
		lession_id = "6x24",
	},
	{
		displayname = L"全局变量", 
		title = L"编程教学：全局变量", 
		icon = "Texture/Aries/AppIcons/clickme.png",
		tooltip = L"本节课学习如何使用全局变量，学习如何获取用户输入。",
		lession_id = "6x23",
	},

	{
		displayname = L"创建方块", 
		title = L"动画2教程：创建方块", 
		icon = "Texture/Aries/AppIcons/hungry.png",
		tooltip = L"熟悉掌握更多的基础操作和命令，认识方块以及如何搭建方块。",
		lession_id = "8X28",
	},
	{
		displayname = L"批量操作", 
		title = L"动画3教程：批量操作", 
		icon = "Texture/Aries/AppIcons/apple.png",
		tooltip = L"掌握更多有用的热键和操作，和一些在搭建中所用到的工具等，让你开始像专业人士一样创建3D世界。",
		lession_id = "8X29",
	},
	{
		displayname = L"电影方块", 
		title = L"动画4教程：电影方块", 
		icon = "Texture/Aries/AppIcons/roundstory2.png",
		tooltip = L"介绍电影方块，学习如何在时间轴上用关键帧移动相机来进行拍摄、加入字幕、添加演员角色等知识。",
		lession_id = "8X30",
	},
	{
		displayname = L"演员和动画", 
		title = L"动画5教程：演员和动画", 
		icon = "Texture/Aries/AppIcons/guitar.png",
		tooltip = L"重点介绍角色演员骨骼的使用方法，以及如何给予人物动作，让他在我们的电影片段中做出想要的动作。",
		lession_id = "8X31",
	},
	
	{
		displayname = L"BMAX模型", 
		title = L"动画8教程：BMAX模型", 
		icon = "Texture/Aries/AppIcons/inventor.png",
		tooltip = L"认识BMAX模型并去学习它如何搭建、保存以及使用。",
		lession_id = "8X34",
	},

	{
		displayname = L"制作图形界面", 
		title = L"编程教学：制作图形界面", 
		icon = "Texture/Aries/AppIcons/brush.png",
		tooltip = L"本节课学习制作图形界面动画和响应事件。",
		lession_id = "6x25",
	},

	{
		displayname = L"代码方块的输出", 
		title = L"编程教学：代码方块的输出", 
		icon = "Texture/Aries/AppIcons/code_output.png",
		tooltip = L"本节课学习如何实现代码方块的输出和实现不用点击开关激活方块就可以开始游戏。",
		lession_id = "6x26",
	},
	{
		displayname = L"跳一跳", 
		title = L"编程教学：跳一跳", 
		icon = "Texture/Aries/AppIcons/frogjump.png",
		tooltip = L"制作跳一跳游戏，随机出现方块,并跳跃过去。 本节课学习使用多个代码方块和电影方块编写复杂点的小游戏和学习广播消息的大量运用。",
		lession_id = "6x37",
	},

	{
		displayname = L"编程基础2", 
		title = L"编程教学：编程基础2", 
		icon = "Texture/Aries/AppIcons/codeblock.png",
		tooltip = L"这节课里我们学习如何创建和控制多个角色",
		lession_id = "6x19",
	},
};

function ParaWorldLessons.StaticInit()
	if(ParaWorldLessons.inited) then
		return;
	end
	ParaWorldLessons.inited = true;
	NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
	local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
	GameLogic.GetFilters():add_filter("OnWorldLoaded", ParaWorldLessons.OnWorldLoaded);
end

-- init function. page script fresh is set to false.
function ParaWorldLessons.OnInit()
	ParaWorldLessons.StaticInit();
	ParaWorldLessons.page = document:GetPageCtrl();
end

ParaWorldLessons.settingsFilename = "temp/settings/bShowParaWorldLessons";
function ParaWorldLessons.IsShowOnStartup()
	if(ParaWorldLessons.bShowParaWorldLessons == nil) then
		if(true) then
			ParaWorldLessons.bShowParaWorldLessons = false;
		else
			ParaWorldLessons.bShowParaWorldLessons = true;
			local file = ParaIO.open(ParaWorldLessons.settingsFilename, "r")
			if(file:IsValid()) then
				local text = file:GetText();
				if(text and text:match("false")) then
					ParaWorldLessons.bShowParaWorldLessons = false;
				end
				file:close();
			end
		end
	end
	return ParaWorldLessons.bShowParaWorldLessons;
end

function ParaWorldLessons.SetShowOnStartup(bShow)
	ParaIO.CreateDirectory(ParaWorldLessons.settingsFilename);
	local file = ParaIO.open(ParaWorldLessons.settingsFilename, "w")
	if(file:IsValid()) then
		ParaWorldLessons.bShowParaWorldLessons = bShow;
		file:WriteString(bShow and "true" or "false");
		file:close()
	else
		LOG.std(nil, "warn", "ParaWorldLessons", "failed to write settings to %s", ParaWorldLessons.settingsFilename);
	end
end

function ParaWorldLessons.OnChangeShowOnStartup()
	if(ParaWorldLessons.page) then
		local bShowParaWorldLessons = ParaWorldLessons.page:GetValue("showOnStart", true) == true;
		if(ParaWorldLessons.IsShowOnStartup() ~= bShowParaWorldLessons) then
			ParaWorldLessons.SetShowOnStartup(bShowParaWorldLessons);
		end
	end
end

-- @param callbackFunc: function(bBeginLessons) end
function ParaWorldLessons.CheckShowOnStartup(callbackFunc)
	if(ParaWorldLessons.IsShowOnStartup() and not ParaWorldLessons.isShownOnce) then
		ParaWorldLessons.ShowPage(callbackFunc);
	else
		if(callbackFunc) then
			callbackFunc(false);
		end
	end
end

-- show page
function ParaWorldLessons.ShowPage(callbackFunc)
	ParaWorldLessons.isShownOnce = true;
	ParaWorldLessons.onCloseCallback = callbackFunc;
	local params = {
		url = "script/apps/Aries/Creator/Game/Login/ParaWorldLessons.html", 
		name = "ParaWorldLessons.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = false,
		bShow = true,
		zorder = 2,
		isTopLevel = true,
		-- click_through = false, 
		directPosition = true,
			align = "_fi",
			x = 0,
			y = 0,
			width = 0,
			height = 0,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function ParaWorldLessons.ShowLoginModal()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ParaWorldLoginDocker.lua");
	local ParaWorldLoginDocker = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ParaWorldLoginDocker")
	ParaWorldLoginDocker.SignIn(L"登陆后才能访问课程系统, 请先登录", function(bSucceed)
		if not ParaWorldLessons.classId then
			return false
		end

		local lesson = ParaWorldLessons.GetCurrentLesson()

		if (not lesson) then
			ParaWorldLessons.EnterClassImp(ParaWorldLessons.classId)
			ParaWorldLessons.JoinClass()
		else
			ParaWorldLessons.JoinClass()
		end

	end)
end

function ParaWorldLessons.OnClickClose()
	ParaWorldLessons.CloseWindow()
end

function ParaWorldLessons.LessonWorldsDs(index)
	if(not index) then
		return #lesson_worlds
	else
		return ParaWorldLessons.GetLessonByIndex(index);
	end
end

function ParaWorldLessons.GetLessonByIndex(index)
	return lesson_worlds[index];
end

function ParaWorldLessons.GetTootipByIndex(index)
	return "page://script/apps/Aries/Creator/Game/Login/ParaWorldLessonTooltip.html?index="..tostring(index);
end

function ParaWorldLessons.OnClickWorld(index)
	local lesson = ParaWorldLessons.GetLessonByIndex(index)
	if(lesson) then
		ParaWorldLessons.EnterWorldById(lesson.lession_id);
	end
end

function ParaWorldLessons.OnClickMoreLessons()
	local url = format("%s/official/docs/index", KeepworkService:GetKeepworkUrl())
	ParaGlobal.ShellExecute("open", url, "", "", 1)
end

function ParaWorldLessons.OnClickEnterWorld()
	if(ParaWorldLessons.page) then
		local txtLessonId = ParaWorldLessons.page:GetValue("txtLessonId", "");

		if(txtLessonId and txtLessonId~="") then
			local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")
			local pid = UserConsole:GetProjectId(txtLessonId)
			if pid then
				UserConsole:HandleWorldId(pid)
			else
				ParaWorldLessons.EnterWorldById(txtLessonId);
			end
		end
	end
end

function ParaWorldLessons.OpenCurrentLessonUrl()
	if not KeepworkService:IsSignedIn() then
		ParaWorldLessons.ShowLoginModal()
		return false
	end

	if(ParaWorldLessons.GetCurrentLesson()) then
		ParaWorldLessons.GetCurrentLesson():OpenLessonUrl()
		TeacherAgent:ShowTipText();
	end
end

function ParaWorldLessons.SetCurrentLesson(lesson)
	ParaWorldLessons.curLesson = lesson
end

function ParaWorldLessons.GetCurrentLesson()
	return ParaWorldLessons.curLesson;
end

-- @param callback: function(err, msg, data)
function ParaWorldLessons.UrlRequest(url, method, params, callback)
	if(not ParaWorldLessons.isFetching) then
		_guihelper.MessageBox(L"请求中，请稍等...", nil, _guihelper.MessageBoxButtons.Nothing)
		ParaWorldLessons.isFetching = true;

		local token = KeepworkService:GetToken()
		local params_ = {
			url = url,
			method = method or 'GET',
			json = true,
			form = params
		}
		if(token) then
			params_.headers= { Authorization = format("Bearer %s", token) }
		end
	
		System.os.GetUrl(params_, function(...)
			ParaWorldLessons.isFetching = false;
			_guihelper.CloseMessageBox(true);
			callback(...)
		end)
	end
end

-- @param username: custom username 
function ParaWorldLessons.EnterClassImp(classId, username)
	if not classId then
		return false
	end

	local url = format("%s/classrooms/getByKey?key=%s", KeepworkService:GetLessonApi(), classId)

	ParaWorldLessons.UrlRequest(url, "GET", nil, function(err, msg, data)
		if err ~= 200 then
			LOG.std(nil, 'info', 'ParaWorldLessons', 'failed to fetch class %d: err: %d', classId, err)
			_guihelper.MessageBox(format(L'获取课堂信息失败。错误码: %d', err))
		end

		if not data or not data.packageId or not data.lessonId then
			return false
		end

		ParaWorldLessons.EnterLessonImp(data.packageId, data.lessonId, classId)
	end)
end

function ParaWorldLessons.JoinClass()
	local classId = ParaWorldLessons.classId

	if not classId then
		return false
	end

	local url = format("%s/classrooms/join", KeepworkService:GetLessonApi())

	ParaWorldLessons.UrlRequest(url, "POST", {key=tostring(classId), username = username}, function(err, msg, data)
		if(err ~= 200) then
			LOG.std(nil, "info", "ParaWorldLessons", "failed to join class %d: err: %d", classId, err);
			-- _guihelper.MessageBox(format(L"无法加入课堂. 错误码: %d", err))
			return
		end
	
		if(data and data.code == 2) then
			_guihelper.MessageBox(L"课堂人数已满")
		end

		if(data and data.lessonId) then
			-- {lessonId=27,id=850,extra={},state=0,createdAt="2018-10-13T15:23:38.000Z",updatedAt="2018-10-13T15:23:38.000Z",classroomId=38,userId=1,packageId=8,}
			LOG.std(nil, "info", "ParaWorldLessons JoinClass", data);
			-- ParaWorldLessons.EnterLessonImp(data.packageId, data.lessonId, classId, data.id, data.userId, data.token, username);
		end
	end)
end

function ParaWorldLessons.CloseWindow(bEntered)
	if(ParaWorldLessons.page) then
		ParaWorldLessons.page:CloseWindow();
		ParaWorldLessons.page = nil;
		if(ParaWorldLessons.onCloseCallback) then
			ParaWorldLessons.onCloseCallback(bEntered);
		end
	end
end

-- @param classId: if nil, it will be 
function ParaWorldLessons.EnterLessonImp(packageId, lessonId, classId, recordId, userId, userToken, username)
	local contentAPIUrl = format("%s/lessons/%d/contents", KeepworkService:GetLessonApi(), lessonId)
	local lessonAPIUrl = format("%s/lessons/%d", KeepworkService:GetLessonApi(), lessonId)

	NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ParaWorldLesson.lua")
	local ParaWorldLesson = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ParaWorldLesson")
	local lesson = ParaWorldLesson:new():Init(lessonId, packageId)

	local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
	local SetCurLesson = Store:Action("lesson/SetCurLesson")
	SetCurLesson(lesson)

	if(classId) then
		lesson:SetClassId(classId);
	end
	if(userId) then
		lesson:SetUserId(userId);
	end
	if(recordId) then
		lesson:SetRecordId(recordId);
	end
	if(userToken) then
		lesson:SetUserToken(userToken);
	end
	
	ParaWorldLessons.UrlRequest(lessonAPIUrl , "GET", nil, function(err, msg, data)
		if(data and data.id) then
			lesson:SetClientData(data.extra)
			lesson:SetGoals(data.goals);
			lesson:SetName(data.lessonName);
			if(username) then
				lesson:SetUserName(username);
			end

			ParaWorldLessons.UrlRequest(contentAPIUrl, "GET", nil, function(err, msg, data)
				if(data and data.content) then
					lesson:SetContent(data.content);
					ParaWorldLessons.SetCurrentLesson(lesson);

					lesson:GetFirstWorldUrl(function(worldUrl) 
						if(worldUrl and worldUrl~="") then
							lesson:EnterWorld(function(bSucceed, localWorldPath)
								if(bSucceed) then
									ParaWorldLessons.CloseWindow(true);
								end
							end)
						else
							-- there is no associated world, we will just open the web url
							LOG.std(nil, "info", "ParaWorldLessons", "there is no associated 3d world with lession %s", tostring(lessonId));
							ParaWorldLessons.OpenCurrentLessonUrl()
						end
					end)
				else
					_guihelper.MessageBox(format(L"没有找到课程%d", lessonId));
					LOG.std(nil, "warn", "ParaWorldLessons", "failed to fetch lesson content from %s", contentAPIUrl);
					echo(msg);
				end
			end);
		else
			_guihelper.MessageBox(format(L"没有找到课程%d", lessonId));
			LOG.std(nil, "warn", "ParaWorldLessons", "failed to fetch lesson content from %s", lessonAPIUrl);
		end
	end);
end

-- @param id: a string of class id or lesson id. 
-- @param callbackFunc: function(bBeginLesson) end
-- @return true if we have processed the world id
function ParaWorldLessons.EnterWorldById(id, callbackFunc)
	ParaWorldLessons.StaticInit()
	id = tostring(id);
	id = id:gsub("%s", "");
	local classId = id:match("^[cC](%d+)$") or id:match("^(%d+)$");
	local packageId, lessonId = id:match("^(%d+)[%D](%d+)$");
	if(classId) then
		classId = tonumber(classId);
		ParaWorldLessons.classId = classId

		if KeepworkService:IsSignedIn() then
			ParaWorldLessons.EnterClassImp(classId)
			ParaWorldLessons.JoinClass()
		end

		if not KeepworkService:IsSignedIn() then
			ParaWorldLessons.ShowLoginModal()
		end

		return true;
	elseif(packageId and lessonId) then
		packageId = tonumber(packageId);
		lessonId = tonumber(lessonId);
		ParaWorldLessons.EnterLessonImp(packageId, lessonId);
		return true;
	end
end

function ParaWorldLessons.OnWorldLoaded()
	local lesson = ParaWorldLessons.GetCurrentLesson()

	if(lesson) then
		local nQuizCount = lesson:GetQuizCount();
		local text = L"点击图标打开课程学习页面";
		if(nQuizCount>0) then
			text = text.."<br/>"..lesson:GetSummaryMCML();
		end
		text = text.."<br/><div style='color:#cc3300'>"..(L"学习完毕可领取奖励~").."</div>";

		TeacherAgent:AddTaskButton("OpenLesson", "Texture/3DMapSystem/AppIcons/png/Intro_64.png", ParaWorldLessons.OpenCurrentLessonUrl, nQuizCount, 100, text)
		TeacherAgent:SetEnabled(true);
	end
end