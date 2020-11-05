--[[
Title: entry point of the game UI
Author(s): LiXizhi
Date: 2012/12/28
Desc:  script/apps/Aries/Creator/Game/GameDesktop.html
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GameDesktop.lua");
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
Desktop.OnActivateDesktop("game");
Desktop.GetChatGUI():PrintChatMessage(msg);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BuilderDock.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/GameDock.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/QuickSelectBar.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BlockMinimap.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/GoalTracker.lua");
NPL.load("(gl)script/apps/Aries/Creator/ToolTipsPage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/DesktopMenuPage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Mod/ModManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/AllContext.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldLoginAdapter.lua");
local ParaWorldLoginAdapter = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaWorld.ParaWorldLoginAdapter");

local TeamMembersPage = commonlib.gettable("MyCompany.Aries.Team.TeamMembersPage");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BuilderDock = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BuilderDock");
local GameDock = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.GameDock");
local BlockMinimap = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BlockMinimap");
local GoalTracker = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.GoalTracker");
local CameraController = commonlib.gettable("MyCompany.Aries.Game.CameraController")
local DesktopMenuPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.DesktopMenuPage");
local ModManager = commonlib.gettable("Mod.ModManager");
local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");
local AllContext = commonlib.gettable("MyCompany.Aries.Game.AllContext");
	
local ToolTipsPage = commonlib.gettable("MyCompany.Aries.Creator.ToolTipsPage")
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");

local Game = commonlib.gettable("MyCompany.Aries.Game")

local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
Desktop.name = "taurus_mc";

-- messge types
local MSGTYPE = commonlib.createtable("MyCompany.Aries.Creator.Game.Desktop.MSGTYPE", {
	-- show/hide the task bar, 
	-- msg = {bShow = true}
	SHOW_DESKTOP = 1001,

	-- invoked when desktop ui is shown. 
	-- {level = number:player level}
	ON_ACTIVATE_DESKTOP = 1003,
});


-- call this only once at the beginning
-- init desktop components
function Desktop.InitDesktop()
	if(Desktop.IsInit) then 
		return 
	end
	Desktop.IsInit = true;

	-- create windows for message handling
	NPL.load("(gl)script/ide/os.lua");
	local _app = CommonCtrl.os.CreateGetApp(Desktop.name);
	_app.app_key = Desktop.name;
	Desktop.App = _app;
	Desktop.MainWnd = _app:RegisterWindow("main", nil, Desktop.MSGProc);

	-- hook into the "onsize" and update the main window
	CommonCtrl.os.hook.SetWindowsHook({hookType = CommonCtrl.os.hook.HookType.WH_CALLWNDPROC, 
		callback = Desktop.OnScreenSizeChanged, 
		hookName = "CreatorDesktopOnSizeHook", appName = "input", wndName = "onsize"});

	Desktop.DoAutoAdjustUIScaling();

	-- init all scene context
	AllContext:Init();

	-- init chat 
	NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/GUIChat.lua");
	local GUIChat = commonlib.gettable("MyCompany.Aries.Game.GUI.GUIChat");
	commonlib.setfield("MyCompany.Aries.Creator.Game.Desktop.GUI.chat", GUIChat:new());

	-- init desktop gui
	Desktop.bSkipDefaultDesktop = false;
	Desktop.bSkipDefaultDesktop = GameLogic.GetFilters():apply_filters("InitDesktop", Desktop.bSkipDefaultDesktop);
	if(not Desktop.bSkipDefaultDesktop) then
		-- init default desktop gui
		NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/CreatorDesktop.lua");
		local CreatorDesktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.CreatorDesktop");
		CreatorDesktop.StaticInit();	
	end
end

function Desktop.UnselectSceneContext()
	local context = GameLogic.GetSceneContext()
	if(context) then
		return context:deactivate();
	else
		return true;
	end
end

function Desktop.SelectSceneContext(mode)
	GameLogic.ActivateDefaultContext();
end

-- whenever user switched world and desktop is activated. 
-- refresh all user interfaces here. 
-- @param mode: "editor", "game", if nil it will toggle the mode. 
function Desktop.OnActivateDesktop(mode)
	Desktop.InitDesktop();
	
	if(not Desktop.UnselectSceneContext()) then
		return false;
	end

	local isToggleMode;
	if(mode == nil or mode=="") then
		isToggleMode = true;
		if(Desktop.mode~="editor") then
			Desktop.last_game_mode = Desktop.mode;
			mode = "editor";
		else
			mode = Desktop.last_game_mode or "game";
		end
	end
	Desktop.mode = mode;
	
	if(mode == "game" or mode== "adventure") then
		GameLogic.EnterGameMode();
	elseif(mode == "strictgame" ) then
		GameLogic.EnterGameMode(false, true);
	elseif(mode == "editor" or mode=="creative") then
		GameLogic.EnterEditorMode();
	elseif(mode == "tutorial") then
		GameLogic.EnterTutorialMode();
	elseif(mode == "survival") then
		GameLogic.EnterGameMode(true);
	elseif(mode == "movie") then
		GameLogic.EnterMovieMode();
	end

	if(mode == "movie") then
		CameraController.SetFPSMouseUIMode(true, "movie");
	else
		CameraController.SetFPSMouseUIMode(false, "movie");
	end
	
	-- try join the home land server if any
	if(type(commonlib.getfield("Map3DSystem.App.HomeLand.HomeLandGateway.GoWorld")) == "function") then
		Map3DSystem.App.HomeLand.HomeLandGateway.GoWorld();
	end

	-- hide all aries desktop if any
	if(not System.options.mc and type(commonlib.getfield("MyCompany.Aries.Desktop.HideAllAreas")) == "function") then
		MyCompany.Aries.Desktop.HideAllAreas();
		MyCompany.Aries.Desktop.NotificationArea.Show(true);
		MyCompany.Aries.Desktop.TargetArea.Show(true);
		if(TeamMembersPage.ShowPage) then
			TeamMembersPage.ShowPage(true);
		end
	end

	Desktop.SelectSceneContext();
	GameLogic.GetPlayerController():InitMainPlayerHandTool();

	if(not System.options.mc and type(commonlib.getfield("MyCompany.Aries.Pet.EnterIndoorMode")) == "function") then
		MyCompany.Aries.Pet.EnterIndoorMode(System.User.nid);
	end

	LOG.std(nil, "system", "GameDesktop", "OnActivateDesktop %s", mode);
	-- not view mode by default.
	GameLogic.GameMode:SetViewMode(false);

	local bIgnoreDefaultDesktop = false;
	bIgnoreDefaultDesktop = GameLogic.GetFilters():apply_filters("ActivateDesktop", bIgnoreDefaultDesktop, mode);

	if(bIgnoreDefaultDesktop) then
		return;
	end

	if(not Desktop.bSkipDefaultDesktop) then
		Desktop.ShowAllAreas();
		if(isToggleMode) then
			if(Desktop.mode == "editor") then
				GameLogic.AddBBS("desktop", L"进入编辑模式", 3000, "0 255 0");
			else
				GameLogic.GetFilters():apply_filters("user_behavior", 2, "editWorld");
				GameLogic.AddBBS("desktop", L"进入播放模式", 3000, "255 255 0");
			end
		end
		Desktop.mode = mode;
	end
end

-- get Desktop.mode
function Desktop.GetDesktopMode()
	return Desktop.mode;
end

-- only call this to remove all ui. 
function Desktop.CleanUp()
	if(Desktop.IsInit) then 
		Desktop.HideAllAreas();
	end

	-- Desktop.IsInit = false;
	Desktop.UnselectSceneContext();
	Desktop.mode = nil;
	Desktop.last_game_mode = nil;
end

-- send a message to Desktop:main window handler
-- Desktop.SendMessage({type = Desktop.MSGTYPE.MENU_SHOW});
function Desktop.SendMessage(msg)
	msg.wndName = "main";
	Desktop.App:SendMessage(msg);
end

-- Desktop window handler
function Desktop.MSGProc(window, msg)
	if(msg.type == MSGTYPE.SHOW_DESKTOP) then
		-- show/hide the task bar, 
		-- msg = {bShow = true}
		-- Desktop.Show(msg.bShow);

	else
		
		
	end
end

-------------------------
-- protected
-------------------------

-- show or hide task bar UI
function Desktop.Show(bShow)
	if(Desktop.IsInit == false) then return end
end

function Desktop.OnScreenSizeChanged(nCode, appName, msg)
	Desktop.DoAutoAdjustUIScaling();
end

local last_width, last_height = nil;

-- adjust ui according to size
function Desktop.DoAutoAdjustUIScaling(bForceUpdate)
	if(System.options.IsTouchDevice or (not GameLogic.options.EnableAutoUIScaling and not bForceUpdate)) then
		return;
	end

	if(not ParaEngine.GetAttributeObject():GetField("IgnoreWindowSizeChange",false)) then
		local screen_size = ParaUI.GetUIObject("root"):GetAttributeObject():GetField("BackBufferSize", {800, 600});
		width, height = screen_size[1], screen_size[2];

		if(bForceUpdate or last_width ~= width or last_height ~= height) then
			last_width, last_height = width, height;
			
			local scale = {1,1}
			if(GameLogic.options.EnableAutoUIScaling and height > GameLogic.options.max_screen_height) then
				scale[1] = height / GameLogic.options.max_screen_height;
				scale[2] = scale[1];
			else
			end
			ParaUI.GetUIObject("root"):GetAttributeObject():SetField("UIScale", scale);
		end
	end

	if(System.options.mc) then
		ParaUI.GetUIObject("root"):GetAttributeObject():SetField("UIScale", {1, 1});
	end
end

function Desktop.ShowAllAreas()
	if(Desktop.bSkipDefaultDesktop) then
		return;
	end
	local mode = Desktop.mode;
	local MainUIButtons = GameLogic.GetFilters():apply_filters('MainUIButtons', nil);
	if(mode == "editor") then
		GameDock.ShowPage(false);
		BuilderDock.ShowPage(true);
		QuickSelectBar.ShowPage(true)
		BlockMinimap.ShowPage(true);
		DesktopMenuPage.ShowPage(true);
		GoalTracker.ShowPage(true);
		if MainUIButtons ~= nil then
			MainUIButtons.ShowPage();
		end
	else
		BuilderDock.ShowPage(false);
		GameDock.ShowPage(true);
		QuickSelectBar.ShowPage(true)
		BlockMinimap.ShowPage(true);
		GoalTracker.ShowPage(true);
		DesktopMenuPage.ShowPage(true);
		ToolTipsPage.ShowPage(false);
		if MainUIButtons ~= nil then
			MainUIButtons.ShowPage();
		end
	end
	GameLogic.GameMode:SetViewMode(false);
end

function Desktop.HideAllAreas()
	GameDock.ShowPage(false);
	BuilderDock.ShowPage(false);
	QuickSelectBar.ShowPage(false);
	BlockMinimap.ShowPage(false);
	GoalTracker.ShowPage(false);
	GameLogic.GameMode:SetViewMode(true);
end

-- return true if desktop is currently visible. 
function Desktop.IsVisible()
	return Desktop.IsVisible;
end

function Desktop.OnShowRankingPage()
	local GoldRankingListMain = commonlib.gettable("MyCompany.Aries.GoldRankingList.GoldRankingListMain");
    if(GoldRankingListMain.ShowPage) then
        if(System.options.version == "kids") then
            GoldRankingListMain.ShowPage("PEMineCraft_follower", nil, "pets")
        else
            GoldRankingListMain.ShowPage("mc_rank", nil, "combat")
        end
    end
end

-- Change the UI and Camera mode.
-- @param IsFPSView: nil to toggle, otherwise to set
function Desktop.SetCameraMode(IsFPSView)
	GameLogic.ToggleCamera(IsFPSView)
	if( Desktop.mode == "game" ) then
		GameDock.HideAllWindows()
	elseif( Desktop.mode == "editor" ) then
		BuilderDock.HideAllWindows();
	end
end

-- Leave the current world.
function Desktop.OnLeaveWorld(bForceExit, bRestart)
	if(System.User.nid == 0 or System.options.mc) then
		Desktop.OnExit(bForceExit, bRestart);
	else
		Game.Exit();
		NPL.load("(gl)script/apps/Aries/Scene/WorldManager.lua");
		local WorldManager = commonlib.gettable("MyCompany.Aries.WorldManager");
		WorldManager:TeleportBack();
	end
end

-- when the user clicks the close button on the window title. 
function Desktop.OnExit(bForceExit, bRestart)
	if(ModManager:OnClickExitApp(bForceExit, bRestart)) then
		return
	end

	local function checkLockWorld(callback)
        local currentEnterWorld = Mod.WorldShare.Store:Get("world/currentEnterWorld")
        if (currentEnterWorld and currentEnterWorld.project and currentEnterWorld.project.memberCount or 0) > 1 then
            Mod.WorldShare.MsgBox:Show(L"请稍后...")
			local KeepworkServiceWorld = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/World.lua")
            KeepworkServiceWorld:UnlockWorld(function()
                if (callback) then
                    callback()
                end
            end)
		else
			if (callback) then
				callback()
			end
        end
	end
	if(GameLogic.IsReadOnly()) then
		if(bForceExit or Desktop.is_exiting) then
			-- double click to exit without saving. 
			if (not System.options.isCodepku) then
				checkLockWorld(function()
					local KeepworkServiceSession = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Session.lua")
					KeepworkServiceSession:Logout();
					Desktop.ForceExit();
				end);
			else
				Desktop.ForceExit();
			end
		else
			Desktop.is_exiting = true;

			local projectId = GameLogic.options:GetProjectId();
			if (projectId and tonumber(projectId) == ParaWorldLoginAdapter.MainWorldId and GameLogic.IsReadOnly()) then
				ParaWorldLoginAdapter.ShowExitWorld(true);
				return true;
			end

			local dialog = {
				text = L"确定要退出当前世界么？", 
				callback = function(res)
					Desktop.is_exiting = false;
					if(res and res == _guihelper.DialogResult.Yes) then
						GameLogic.GetFilters():apply_filters("user_behavior", 2, "stayWorld");

						if (not System.options.isCodepku) then
							ParaWorldLoginAdapter:EnterWorld(true);
						else
							Desktop.ForceExit(bRestart);
						end
					elseif(res and res == _guihelper.DialogResult.No) then
						if (not System.options.isCodepku) then
							ParaWorldLoginAdapter:EnterWorld(true);
						else
							Desktop.ForceExit(bRestart);
						end
					end
				end
			};
			local dialog = GameLogic.GetFilters():apply_filters("ShowExitDialog", dialog, bRestart);			
			if(dialog and dialog.callback and dialog.text) then
				_guihelper.MessageBox(dialog.text, 
					dialog.callback,dialog.messageBoxButton or _guihelper.MessageBoxButtons.YesNoCancel);
			end
		end
	else
		if(bForceExit or Desktop.is_exiting) then
			-- double click to exit without saving. 
			if(Desktop.is_exiting) then
				-- GameLogic.QuickSave();
			end
			if (not System.options.isCodepku) then
				checkLockWorld(function()
					local KeepworkServiceSession = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Session.lua")
					KeepworkServiceSession:Logout();
					Desktop.ForceExit();
				end);
			else
				Desktop.ForceExit();
			end
		else
			Desktop.is_exiting = true;
			local projectId = GameLogic.options:GetProjectId();
			if (projectId and tonumber(projectId) == ParaWorldLoginAdapter.MainWorldId and GameLogic.IsReadOnly()) then
				ParaWorldLoginAdapter.ShowExitWorld(true);
				return true;
			end

			local dialog = {
				text = string.format(L"%d秒内您没有保存过世界. <br/>退出前, 是否保存世界？", GameLogic.options:GetElapsedUnSavedTime()/1000), 
				callback = function(res)
					Desktop.is_exiting = false;
					if(res and res == _guihelper.DialogResult.Yes) then
						GameLogic.QuickSave();
						if (not System.options.isCodepku) then
							checkLockWorld(function()
								ParaWorldLoginAdapter:EnterWorld(true);
							end);
						else
							Desktop.ForceExit(bRestart);
						end
					elseif(res and res == _guihelper.DialogResult.No) then
						if (not System.options.isCodepku) then
							checkLockWorld(function()
								ParaWorldLoginAdapter:EnterWorld(true);
							end);
						else
							Desktop.ForceExit(bRestart);
						end
					end
				end
			};
			-- use this filter to display a dialog when user exits the application, return nil if one wants to replace the implementation.
			dialog = GameLogic.GetFilters():apply_filters("ShowExitDialog", dialog);

			if(dialog and dialog.callback and dialog.text) then
				_guihelper.MessageBox(dialog.text, 
					dialog.callback, dialog.messageBoxButton or _guihelper.MessageBoxButtons.YesNoCancel);
			end
		end
	end
end

-- exit the process 
function Desktop.ForceExit(bRestart)
	GameLogic.GetFilters():apply_filters("user_event_stat", "desktop", "ForceExit", nil, nil);

	local platform = System.os.GetPlatform();
	if(platform == "android" or platform == "ios" ) then
		GameLogic.events:DispatchEvent({type = "OnWorldUnload"});	
		-- disable close on these platform. 
		MyCompany.Aries.Game.Exit();
		-- soft restart the NPL runtime state to login screen. 
		System.App.Commands.Call("Profile.Aries.Restart", {method="soft"});
	elseif(System.options.IsMobilePlatform) then
		GameLogic.events:DispatchEvent({type = "OnWorldUnload"});	
		MyCompany.Aries.Game.Exit();
		-- soft restart the NPL runtime state to login screen. 
		Map3DSystem.App.Commands.Call("Profile.Aries.MobileRestart");
	else
		ParaEngine.GetAttributeObject():SetField("IsWindowClosingAllowed", true);
		if(bRestart) then
			GameLogic.events:DispatchEvent({type = "OnWorldUnload"});	
			Game.Exit();
			System.App.Commands.Call("Profile.Aries.Restart", {method="soft"});
		else
			local ClassManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/ClassManager.lua");
			ClassManager.OnExitApp();
			Game.Exit();
			ParaGlobal.ExitApp();
		end
	end
end

-- get the chat GUI object
function Desktop.GetChatGUI()
	return Desktop.GUI.chat;
end

-- obsoleted: now mobile and desktop are the same.
function Desktop.ShowMobileDesktop(bShow)
	QuickSelectBar.ShowPage(bShow);
	NPL.load("(gl)script/mobile/paracraft/Areas/SystemMenuPage.lua");
	local SystemMenuPage = commonlib.gettable("ParaCraft.Mobile.Desktop.SystemMenuPage");
	SystemMenuPage.ShowPage(bShow);
end

-- Restart the entire NPLRuntime to a different application. e.g.
-- Desktop.Restart("haqi")
-- Desktop.Restart("paracraft")
-- @param appName: nil default to "paracraft", it can also be "haqi"
function Desktop.Restart(appName)
	GameLogic.BeforeRestart(appName);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ParaWorldLoginDocker.lua");
	local ParaWorldLoginDocker = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ParaWorldLoginDocker")
	ParaWorldLoginDocker.Restart(appName)
end
