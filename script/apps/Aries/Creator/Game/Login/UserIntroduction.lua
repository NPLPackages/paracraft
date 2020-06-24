--[[
Title: UserIntroduction.html code-behind script
Author(s): ChenJinxian
Date: 
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/UserIntroduction.lua");
local UserIntroduction = commonlib.gettable("MyCompany.Aries.Game.MainLogin.UserIntroduction")
UserIntroduction.StaticInit()

UserIntroduction.ShowPage()
-------------------------------------------------------
]]
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local UserIntroduction = commonlib.gettable("MyCompany.Aries.Game.MainLogin.UserIntroduction")

UserIntroduction.page= nil;
UserIntroduction.showOnStart = false;

-- call this once at game logic start up. 
function UserIntroduction.StaticInit()
	GameLogic:Connect("WorldLoaded", UserIntroduction, UserIntroduction.OnWorldLoaded, "UniqueConnection");
end

function UserIntroduction.OnWorldLoaded()
	local revision = GameLogic.options:GetRevision()
	if((not revision or revision < 2) and GameLogic.GetMode() == "editor" and not GameLogic.IsRemoteWorld()) then
		local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
			UserIntroduction.CheckShowOnStartup()
		end})
		mytimer:Change(3000, nil);
	end
end

function UserIntroduction.OnInit()
	UserIntroduction.page = document:GetPageCtrl();
end

function UserIntroduction.ShowPage()
	System.App.Commands.Call("File.MCMLWindowFrame", {
		url = "script/apps/Aries/Creator/Game/Login/UserIntroduction.html", 
		name = "CreateMCNewWorld", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		isTopLevel = true,
		allowDrag = false,
		directPosition = true,
			align = "_ct",
			x = -660/2,
			y = -500/2,
			width = 660,
			height = 500,
		cancelShowAnimation = true,
	});
end

UserIntroduction.settingsFilename = "temp/settings/bShowUserIntroduction";
function UserIntroduction.IsShowOnStartup()
	if(UserIntroduction.bShowUserIntroduction == nil) then
		UserIntroduction.bShowUserIntroduction = true;
		local file = ParaIO.open(UserIntroduction.settingsFilename, "r")
		if(file:IsValid()) then
			local text = file:GetText();
			if(text and text:match("false")) then
				UserIntroduction.bShowUserIntroduction = false;
			end
			file:close();
		end
	end
	return UserIntroduction.bShowUserIntroduction;
end

function UserIntroduction.SetShowOnStartup(bShow)
	ParaIO.CreateDirectory(UserIntroduction.settingsFilename);
	local file = ParaIO.open(UserIntroduction.settingsFilename, "w")
	if(file:IsValid()) then
		UserIntroduction.bShowUserIntroduction = bShow;
		file:WriteString(bShow and "true" or "false");
		file:close()
	else
		LOG.std(nil, "warn", "UserIntroduction", "failed to write settings to %s", UserIntroduction.settingsFilename);
	end
end

function UserIntroduction.OnChangeShowOnStartup()
	if(UserIntroduction.page) then
		local bShowIntroduction = UserIntroduction.page:GetValue("showOnStart", true) == true;
		if (not bShowIntroduction) then
			_guihelper.MessageBox(L"可以从菜单栏的帮助选项卡中【欢迎页面与新手引导】入口重新打开此页面");
		end
		if(UserIntroduction.IsShowOnStartup() ~= bShowIntroduction) then
			UserIntroduction.SetShowOnStartup(bShowIntroduction);
		end
	end
end

function UserIntroduction.CheckShowOnStartup()
	if (UserIntroduction.IsShowOnStartup()) then
		UserIntroduction.ShowPage();
	end
end

function UserIntroduction.OnClickBlock()
	local url = "https://keepwork.com/official/docs/references/features/3d_modeling";
	ParaGlobal.ShellExecute("open", url, "", "", 1);
end

function UserIntroduction.OnClickBone()
	local url = "https://keepwork.com/official/docs/references/features/animation";
	ParaGlobal.ShellExecute("open", url, "", "", 1);
end

function UserIntroduction.OnClickMovie()
	local url = "https://keepwork.com/official/docs/references/features/movie_making";
	ParaGlobal.ShellExecute("open", url, "", "", 1);
end

function UserIntroduction.OnClickProgramming()
	local url = "https://keepwork.com/official/docs/references/features/programming";
	ParaGlobal.ShellExecute("open", url, "", "", 1);
end

function UserIntroduction.ShowUserGuide()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Login/UserGuide.lua");
	local UserGuide = commonlib.gettable("MyCompany.Aries.Game.MainLogin.UserGuide");
	UserGuide.Step1();
	UserIntroduction.page:CloseWindow();
end

function UserIntroduction.CloseWindow()
	UserIntroduction.page:CloseWindow();
end