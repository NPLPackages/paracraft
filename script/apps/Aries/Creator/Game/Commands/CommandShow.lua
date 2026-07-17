--[[
Title: show command
Author(s): LiXizhi
Date: 2014/7/28
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandShow.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/MobileUIRegister.lua")
local MobileUIRegister = commonlib.gettable("MyCompany.Aries.Creator.Game.Mobile.MobileUIRegister");

local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

-- show the current player 
Commands["show"] = {
	name="show", 
	quick_ref=[[/show [desktop|player|boundingbox|wireframe|perf|info|touch|mobile|mobilepad|playertouch|
terrain|mod|physics|vision|quickselectbar|tips|map|camera|anim|paralife|axis|
miniuserinfo|chatwindow|serialport|privacywindow|actionbutton|minigame.tabbar|builder|easybuilder|editableworld
dock|dock_left_top|dock_right_top|dock_center_bottom|dock_right_bottom] [on|off]], 
	desc = [[show different type of things.
Other show filters: 
/show desktop.builder.[static|movie|character|playerbag|gear|deco|tool|template|env] [on|off]
/show movie.controller
/show desktop.builder.movie
/show vision   : AI memory vision
/show overlaybuffer    show overlay picking buffer on left top corner
/show quickselectbar
/show playertouch   : a simple touch controller for kids
/show paralife
/show paralife -showplayer : show the default player
/show mobilepad only show _lb(left bottom) and _rb(right bottom) zone,if is win32 will not show virtual keyboard when click the move_button_touch
/show privacywindow -event eventname : show the privacy window with callback eventname
/show objviewer : show the objviewer
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local name, bIsShow;
		name, cmd_text = CmdParser.ParseString(cmd_text);
		bIsShow, cmd_text = CmdParser.ParseBool(cmd_text);
		name = name or "";

		-- apply the show filter
		name = GameLogic.GetFilters():apply_filters("show", name, bIsShow);
		if(not name) then
			-- filter handles it already
		elseif(name == "desktop") then
			local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
			Desktop.ShowAllAreas();
		elseif(name == "quickselectbar") then
			local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");
			QuickSelectBar.ShowPage(true);
		elseif(name == "boundingbox") then
			GameLogic.options:ShowBoundingBox(true);
		elseif(name == "wireframe") then
			GameLogic.options:ShowWireframe(true);
		elseif(name == "perf") then
			NPL.load("(gl)script/ide/Debugger/NPLProfiler.lua");
			local npl_profiler = commonlib.gettable("commonlib.npl_profiler");
			npl_profiler.perf_show();
		elseif(name == "info") then
			if(bIsShow == nil) then
				bIsShow = not GameLogic.options:IsShowInfoWindow();
			end
			GameLogic.options:SetShowInfoWindow(bIsShow);
		elseif(name == "touch") then
			local options
			options, cmd_text = CmdParser.ParseOptions(cmd_text);
			if not options.useOld and MobileUIRegister.GetIsDevMode() then
				MobileUIRegister.SetMobileUIEnable(true)
			else
				MobileUIRegister.SetMobileUIEnable(false)
				GameLogic.options:ShowTouchPad(true);
			end
		elseif(name == "mobile") then
			local options
			options, cmd_text = CmdParser.ParseOptions(cmd_text);
			if not options.useOld and MobileUIRegister.GetIsDevMode() then
				MobileUIRegister.SetMobileUIEnable(true)
			else
				MobileUIRegister.SetMobileUIEnable(false)
				System.options.IsTouchDevice = true;
				GameLogic.options:ShowTouchPad(true);
			end
		elseif(name == "mobilepad") then
			local options
			options, cmd_text = CmdParser.ParseOptions(cmd_text);
			if not options.useOld and MobileUIRegister.GetIsDevMode() then
				NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/MobileMainPage.lua")
				local MobileMainPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Mobile.MobileMainPage");
				MobileUIRegister.SetMobileUIEnable(true)
				MobileMainPage.ShowButtonsByAlign("_lt",false)
				MobileMainPage.ShowButtonsByAlign("_rt",false)
			else
				MobileUIRegister.SetMobileUIEnable(false)
				System.options.IsTouchDevice = true;
				GameLogic.options:ShowTouchPad(true);
			end
		elseif(name == "terrain") then
			if(bIsShow == nil) then
				bIsShow = true;
			end
			if(bIsShow) then
				GameLogic.RunCommand("/terrain -show")
			else
				GameLogic.RunCommand("/terrain -hide")
			end
		elseif(name == "player" or name=="") then
			if EntityManager.GetPlayer() then
				EntityManager.GetPlayer():SetVisible(true);
				EntityManager.GetPlayer():SetSkipPicking(true)
			end
		elseif(name == "camera" ) then
			local entity = EntityManager.GetFocus();
			if(entity and entity:isa(EntityManager.EntityCamera)) then
				entity:SetAlwaysHidden(false);	
				entity:SetVisible(true);
			end
		elseif(name == "physics") then
			if(bIsShow == nil) then
				bIsShow = true;
			end
			ParaScene.GetAttributeObject():SetField("PhysicsDebugDrawMode", bIsShow and -1 or 0);
		elseif(name == "mod" or name=="plugin") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Login/SelectModulePage.lua");
			local SelectModulePage = commonlib.gettable("MyCompany.Aries.Game.MainLogin.SelectModulePage")
			SelectModulePage.ShowPage();
		elseif(name == "vision") then
			local memoryContext = EntityManager.GetPlayer():GetMemoryContext();
			if(memoryContext) then
				memoryContext:SetVisible(true);
			end
		elseif(name == "ui" or name == "UI") then
			System.App.Commands.Call("ScreenShot.HideAllUI");
		elseif(name == "tips") then
			GameLogic.options:ShowSystemTips(true);
		elseif(name == "keyboard") then
			local TouchVirtualKeyboardIcon = GameLogic.GetFilters():apply_filters("TouchVirtualKeyboardIcon");
			if not TouchVirtualKeyboardIcon then
				NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/TouchVirtualKeyboardIcon.lua");
				TouchVirtualKeyboardIcon = commonlib.gettable("MyCompany.Aries.Game.GUI.TouchVirtualKeyboardIcon");
			end
			TouchVirtualKeyboardIcon.ShowSingleton(true);
		elseif(name == "overlaybuffer") then
			NPL.load("(gl)script/ide/System/Scene/Overlays/OverlayPicking.lua");
			local OverlayPicking = commonlib.gettable("System.Scene.Overlays.OverlayPicking");
			OverlayPicking:DebugShow("_lt", 10, 10, 256, 256);
		elseif(name == "map") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldMinimapWnd.lua");
			local ParaWorldMinimapWnd = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaWorld.ParaWorldMinimapWnd");
			ParaWorldMinimapWnd:Show();
		elseif (name == "miniuserinfo") then
			local MiniWorldUserInfo = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/MiniWorldUserInfo.lua");
			MiniWorldUserInfo.ShowInMiniWorld();
		elseif (name == "world2in1") then
			local World2In1 = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/World2In1.lua");
			World2In1.ShowPage();
		elseif (name == "anim") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/ActorAnimationsDialog.lua");
			local ActorAnimationsDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.ActorAnimationsDialog");
			local entity = EntityManager.GetPlayer();
			ActorAnimationsDialog.ShowPageForEntity(entity, function(animId)   
				if(animId and entity) then
					entity:SetAnimation(animId)
				end
			end)
		elseif (name == "playertouch") then
			if MobileUIRegister.GetMobileUIEnabled() then
				return
			end
			local player_ctr = GameLogic.GetPlayerController()
			player_ctr:SetEnableDragPlayerToMove(true)

			NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/TouchMiniKeyboard.lua");
			local TouchMiniKeyboard = commonlib.gettable("MyCompany.Aries.Game.GUI.TouchMiniKeyboard");
			TouchMiniKeyboard.CheckShow(false);
			-- TouchMiniKeyboard.GetSingleton():SetRockerMod()
		elseif (name == "paralife") then
			local options
			options, cmd_text = CmdParser.ParseOptions(cmd_text);
			
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLife.lua");
			local ParaLife = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLife")
			ParaLife:SetShowPlayer(options.showplayer==true)
			ParaLife:SetEnabled(true)
		elseif (name == "axis") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/InfoWorldAxisWindow.lua");
			local InfoWorldAxisWindow = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.InfoWorldAxisWindow");
			InfoWorldAxisWindow.GetInstance():Show(true);
		elseif(name == "chatwindow") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ChatWindow.lua");
			MyCompany.Aries.ChatSystem.ChatWindow.ShowAllPage(true);
			GameLogic.options:SetShowChatWnd(true)
		elseif(name == "serialport") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Code/SerialPort/SerialPortConnector.lua");
			local SerialPortConnector = commonlib.gettable("MyCompany.Aries.Game.Code.SerialPortConnector");
			SerialPortConnector.Show()
		elseif(name == "privacywindow") then
			local eventname
			local pre_cmd_text = cmd_text	
			local options, cmd_text = CmdParser.ParseOptions(cmd_text);
			if options and options.event then
				local text,cmd_text = CmdParser.ParseString(pre_cmd_text);
				eventname,cmd_text = CmdParser.ParseString(cmd_text);
			end
			local UserProtocolPre = NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/UserProtocolPre.lua");
			UserProtocolPre.CheckShow(function()
				if eventname and eventname ~= "" then
					GameLogic.RunCommand("/sendevent "..eventname) 
				end
			end);
		elseif (name == "objviewer") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ObjectViewer/ObjectViewer.lua");
			local ObjectViewer = commonlib.gettable("MyCompany.Aries.Game.Tasks.ObjectViewer");	
			ObjectViewer:Open(nil, CmdParser.ParseString(cmd_text));
		elseif (name == "window.role")	then
			local isSigned = GameLogic.GetFilters():apply_filters("is_signed_in")
			if isSigned then
				local UserInfoPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/AIGC/UserInfoPage.lua")
				UserInfoPage.ShowPage()
			else
				local UserInfoOfflinePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/AIGC/UserInfoOfflinePage.lua")
				UserInfoOfflinePage.ShowPage()
			end
		elseif (name == "paralife.bag") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeBMaxSelectorPage.lua");
			local ParaLifeBMaxSelectorPage = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLifeBMaxSelectorPage");
			ParaLifeBMaxSelectorPage.ShowPage(true,true)
		elseif (name == "minigame.tabbar") then
			local MiniGameMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameMainPage.lua");
			if MiniGameMainPage and MiniGameMainPage.ShowPage then
				MiniGameMainPage.ShowPage()
			end
		elseif(name == "actionbutton") then
			local ActionNameDetector = commonlib.gettable("MyCompany.Aries.Game.Common.ActionNameDetector");
			if(ActionNameDetector.SetEnabled) then
				ActionNameDetector:SetEnabled(true);
				ActionNameDetector:SetShow3DMarker(true);
			end
		elseif(name == "builder") then
			GameLogic.ShowBuilder(true)
		elseif(name == "easybuilder") then
			GameLogic.RunCommand('/show actionbutton')
			GameLogic.RunCommand('/take EasyBuilder -replace -pin -bag 1 {toolname="map"}')
			GameLogic.RunCommand('/take 0 -replace -bag 2')
			GameLogic.RunCommand('/take EasyBuilder -select -replace -pin -bag 3 {toolname="play"}') 
			GameLogic.RunCommand('/take EasyBuilder -select -replace -pin -bag 4 {toolname="livemodel"}') 
			GameLogic.RunCommand('/take EasyBuilder -replace -pin -bag 5 {toolname="model"}') 
			GameLogic.RunCommand('/take EasyBuilder -replace -pin -bag 6 {toolname="char"}')
			GameLogic.RunCommand('/take EasyBuilder -replace -pin -bag 7 {toolname="action"}')
			GameLogic.RunCommand('/take EasyBuilder -replace -pin -bag 8 {toolname="env"}')
			GameLogic.RunCommand('/take EasyBuilder -replace -pin -bag 9 {toolname="bag"}')
			local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");
			if(QuickSelectBar.ShowRightButtons) then
				QuickSelectBar.ShowRightButtons(false, false)
			end

		elseif(name == "editableworld") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyEditableWorld.lua");
			local EasyEditableWorld = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyEditableWorld");
			EasyEditableWorld:new({operation="Load", worldName = nil}):Run();
		end
	end,
};

-- hide the current player, desktop, etc. 
Commands["hide"] = {
	name="hide", 
	quick_ref=[[/hide [desktop|player|boundingbox|wireframe|touch|mobile|playertouch|
terrain|vision|ui|keyboard|quickselectbar|tips|map|info|camera|paralife|axis|
miniuserinfo|chatwindow|serialport|codewindow|actionbutton|easybuilder|builder|
dock|dock_left_top|dock_right_top|dock_center_bottom|dock_right_bottom|
]], 
	desc=[[hide different type of things.e.g.
/hide quickselectbar
/hide desktop
/hide player
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local name;
		name, cmd_text = CmdParser.ParseString(cmd_text);
		name = name or "";
		-- apply the hide filter
		name = GameLogic.GetFilters():apply_filters("hide", name);
		if(not name) then
			-- filter handles it already
		elseif(name == "desktop") then
			local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
			Desktop.HideAllAreas();
		elseif(name == "quickselectbar") then
			local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");
			QuickSelectBar.ShowPage(false);
		elseif(name == "boundingbox") then
			GameLogic.options:ShowBoundingBox(false);
		elseif(name == "wireframe") then
			GameLogic.options:ShowWireframe(false);
		elseif(name == "info") then
			GameLogic.options:SetShowInfoWindow(false);
		elseif(name == "touch") then
			if System.os.IsMobilePlatform() then
				GameLogic.options:ShowTouchPad(false);
				return
			end
			if MobileUIRegister.GetIsDevMode() then
				MobileUIRegister.SetMobileUIEnable(false)
			else
				GameLogic.options:ShowTouchPad(false);
			end
		elseif(name == "mobile") then
			if System.os.IsMobilePlatform() then
				GameLogic.options:ShowTouchPad(false);
				return
			end
			if MobileUIRegister.GetIsDevMode() then
				MobileUIRegister.SetMobileUIEnable(false)
			else
				System.options.IsTouchDevice = false;
				GameLogic.options:ShowTouchPad(false);
			end
		elseif(name == "mobilepad") then
			if System.os.IsMobilePlatform() then
				GameLogic.options:ShowTouchPad(false);
				return
			end
			if MobileUIRegister.GetIsDevMode() then
				MobileUIRegister.SetMobileUIEnable(false)
			else
				System.options.IsTouchDevice = false;
				GameLogic.options:ShowTouchPad(false);
			end
		elseif(name == "player" or name=="") then
			if EntityManager.GetPlayer() then
				EntityManager.GetPlayer():SetVisible(false);
				EntityManager.GetPlayer():SetSkipPicking(true)
			end
		elseif(name == "camera" ) then
			local entity = EntityManager.GetFocus();
			if(entity and entity:isa(EntityManager.EntityCamera)) then
				entity:SetAlwaysHidden(true);	
				entity:SetVisible(false);
			end
		elseif(name == "vision") then
			local memoryContext = EntityManager.GetPlayer():GetMemoryContext();
			if(memoryContext) then
				memoryContext:SetVisible(false);
			end
		elseif(name == "tips") then
			GameLogic.options:ShowSystemTips(false);
		elseif(name == "ui" or name == "UI") then
			System.App.Commands.Call("ScreenShot.HideAllUI");
		elseif(name == "keyboard") then
			local TouchVirtualKeyboardIcon = GameLogic.GetFilters():apply_filters("TouchVirtualKeyboardIcon");
            if not TouchVirtualKeyboardIcon then
                NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/TouchVirtualKeyboardIcon.lua");
                TouchVirtualKeyboardIcon = commonlib.gettable("MyCompany.Aries.Game.GUI.TouchVirtualKeyboardIcon");
            end
			TouchVirtualKeyboardIcon.ShowSingleton(false);
		elseif(name == "terrain") then
			GameLogic.RunCommand("/terrain -hide")
		elseif(name == "map") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldMinimapWnd.lua");
			local ParaWorldMinimapWnd = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaWorld.ParaWorldMinimapWnd");
			ParaWorldMinimapWnd:Close();
		elseif (name == "miniuserinfo") then
			local MiniWorldUserInfo = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/MiniWorldUserInfo.lua");
			MiniWorldUserInfo.ClosePage()
		elseif (name == "world2in1") then
			local World2In1 = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/World2In1.lua");
			World2In1.HidePage();
		elseif (name == "playertouch") then
			if MobileUIRegister.GetMobileUIEnabled() then
				return
			end
			local player_ctr = GameLogic.GetPlayerController()
			player_ctr:SetEnableDragPlayerToMove(false)
			-- TouchMiniKeyboard.GetSingleton():SetKeyboardMod()
			local isMobile = System.options.IsTouchDevice or GameLogic.options:HasTouchDevice()
			if isMobile then
				NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/TouchMiniKeyboard.lua");
				local TouchMiniKeyboard = commonlib.gettable("MyCompany.Aries.Game.GUI.TouchMiniKeyboard");
				TouchMiniKeyboard.CheckShow(true)
			end
		elseif (name == "paralife") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLife.lua");
			local ParaLife = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLife")
			ParaLife:SetEnabled(false)
		elseif (name == "axis") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/InfoWorldAxisWindow.lua");
			local InfoWorldAxisWindow = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.InfoWorldAxisWindow");
			InfoWorldAxisWindow.GetInstance():Show(false);
		elseif(name == "chatwindow") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ChatWindow.lua");
			MyCompany.Aries.ChatSystem.ChatWindow.HideAll();
			MyCompany.Aries.ChatSystem.ChatWindow.HideEdit();
			GameLogic.options:SetShowChatWnd(false)
		elseif(name == "codewindow") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockWindow.lua");
			local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
			CodeBlockWindow.Close()
		elseif(name == "serialport") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Code/SerialPort/SerialPortConnector.lua");
			local SerialPortConnector = commonlib.gettable("MyCompany.Aries.Game.Code.SerialPortConnector");
			SerialPortConnector.Close()
		elseif (name == "objviewer") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ObjectViewer/ObjectViewer.lua");
			local ObjectViewer = commonlib.gettable("MyCompany.Aries.Game.Tasks.ObjectViewer");	
			ObjectViewer:Close();	
		elseif (name == "ggsuserinfo") then
			local TeamPlayerPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/TeamPlayerPage.lua");
			TeamPlayerPage.ClosePage()
		elseif (name == "window.role")	then
			local UserInfoPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/AIGC/UserInfoPage.lua")
			UserInfoPage.ClosePage()
			local UserInfoOfflinePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/AIGC/UserInfoOfflinePage.lua")
			UserInfoOfflinePage.ClosePage()		
		elseif (name == "paralife.bag") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeBMaxSelectorPage.lua");
			local ParaLifeBMaxSelectorPage = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLifeBMaxSelectorPage");
			ParaLifeBMaxSelectorPage.ShowPage(false);
		elseif(name == "actionbutton") then
			local ActionNameDetector = commonlib.gettable("MyCompany.Aries.Game.Common.ActionNameDetector");
			if(ActionNameDetector.SetEnabled) then
				ActionNameDetector:SetEnabled(false);
			end
		elseif(name == "builder") then
			GameLogic.ShowBuilder(false)
		elseif(name == "easybuilder") then
			GameLogic.RunCommand('/show actionbutton')
    		GameLogic.RunCommand("/clearbag")
			local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");
			if(QuickSelectBar.ShowRightButtons) then
				QuickSelectBar.ShowRightButtons(true, true)
			end
		end
	end,
};