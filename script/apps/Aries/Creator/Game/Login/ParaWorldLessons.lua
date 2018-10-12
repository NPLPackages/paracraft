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
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/DownloadWorld.lua");
NPL.load("(gl)script/ide/Files.lua");
local DownloadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.DownloadWorld")
local ParaWorldLessons = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ParaWorldLessons")

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
end

-- init function. page script fresh is set to false.
function ParaWorldLessons.OnInit()
	ParaWorldLessons.StaticInit();
	ParaWorldLessons.page = document:GetPageCtrl();
end

ParaWorldLessons.settingsFilename = "temp/settings/bShowParaWorldLessons";
function ParaWorldLessons.IsShowOnStartup()
	if(ParaWorldLessons.bShowParaWorldLessons == nil) then
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

function ParaWorldLessons.OnClickClose()
	if(ParaWorldLessons.page) then
		ParaWorldLessons.page:CloseWindow();
		if(ParaWorldLessons.onCloseCallback) then
			ParaWorldLessons.onCloseCallback();
		end
	end
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
	ParaGlobal.ShellExecute("open", "https://keepwork.com/official/paracraft/index", "", "", 1)
end


function ParaWorldLessons.OnClickEnterWorld()
	if(ParaWorldLessons.page) then
		local txtLessonId = ParaWorldLessons.page:GetValue("txtLessonId", "");
		if(txtLessonId~="") then
			ParaWorldLessons.EnterWorldById(txtLessonId);
		else
			-- TODO: 
		end
	end
end

function ParaWorldLessons.OpenCurrentLessonUrl()
	if(ParaWorldLessons.GetCurrentLesson()) then
		ParaWorldLessons.GetCurrentLesson():OpenLessonUrl()
	end
end

function ParaWorldLessons.SetCurrentLesson(lesson)
	ParaWorldLessons.curLesson = lesson
end

function ParaWorldLessons.GetCurrentLesson()
	return ParaWorldLessons.curLesson;
end

-- @param id: a string of class id or lesson id. 
-- @param callbackFunc: function(bBeginLesson) end
-- @return true if we have processed the world id
function ParaWorldLessons.EnterWorldById(id, callbackFunc)
	id = tostring(id);
	local classId = id:match("^(%d+)$");
	local packageId, lessonId = id:match("^(%d+)[%D](%d+)$");
	if(classId) then
		classId = tonumber(classId);
		return true;
	elseif(packageId and lessonId) then
		packageId = tonumber(packageId);
		lessonId = tonumber(lessonId);
		local lessonUrl = format("https://keepwork.com/l/#/student/package/%d/lesson/%d", packageId, lessonId)
		local contentAPIUrl = format("https://api.keepwork.com/lesson/v0/lessons/%d/contents", lessonId)

		if(not ParaWorldLessons.isFetching) then
			ParaWorldLessons.isFetching = true;
			System.os.GetUrl(contentAPIUrl, function(err, msg, data)
				if(data and data.content) then
					NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ParaWorldLesson.lua");
					local ParaWorldLesson = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ParaWorldLesson")
					local lesson = ParaWorldLesson:new():Init(lessonId, lessonUrl, data.content)
					ParaWorldLessons.SetCurrentLesson(lesson);

					local worldUrl = lesson:GetFirstWorldUrl()
					if(worldUrl) then
						LOG.std(nil, "info", "ParaWorldLessons", "try entering world %s", worldUrl);

						NPL.load("(gl)script/apps/Aries/Creator/Game/Login/DownloadWorld.lua");
						local DownloadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.DownloadWorld")
						DownloadWorld.ShowPage(worldUrl);

						NPL.load("(gl)script/apps/Aries/Creator/Game/Login/RemoteWorld.lua");
						local RemoteWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.RemoteWorld");
						local world =RemoteWorld.LoadFromHref(worldUrl, "self");

						ParaWorldLessons.OpenCurrentLessonUrl()

						NPL.load("(gl)script/apps/Aries/Creator/Game/Login/InternetLoadWorld.lua");
						local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld");
						InternetLoadWorld.LoadWorld(world, nil, nil, function(bSucceed, localWorldPath)
							DownloadWorld.Close();
							if(bSucceed) then
								if(ParaWorldLessons.page) then
									ParaWorldLessons.page:CloseWindow();
									if(ParaWorldLessons.onCloseCallback) then
										ParaWorldLessons.onCloseCallback(true);
									end
								end
								if(callbackFunc) then
									callbackFunc(true);
								end
							end
						end)
					else
						-- there is no associated world, we will just open the web url
						LOG.std(nil, "info", "ParaWorldLessons", "there is no associated 3d world with %s", lessonUrl);
						ParaWorldLessons.OpenCurrentLessonUrl()
					end
				else
					_guihelper.MessageBox(format(L"没有找到课程%d", lessonId));
					LOG.std(nil, "warn", "ParaWorldLessons", "failed to fetch lesson from %s", contentAPIUrl);
					echo(msg);
				end
				ParaWorldLessons.isFetching = false;
			end);
		end
		return true;
	end
end