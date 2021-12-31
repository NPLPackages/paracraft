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

local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

-- show the current player 
Commands["show"] = {
	name="show", 
	quick_ref=[[/show [desktop|player|boundingbox|wireframe|perf|info|touch|mobile|playertouch
terrain|mod|physics|vision|quickselectbar|tips|map|camera|anim|paralife|
dock|dock_left_top|dock_right_top|dock_center_bottom|dock_right_bottom|miniuserinfo] [on|off]], 
	desc = [[show different type of things.
Other show filters: 
/show desktop.builder.[static|movie|character|playerbag|gear|deco|tool|template|env] [on|off]
/show movie.controller
/show desktop.builder.movie
/show vision   : AI memory vision
/show overlaybuffer    show overlay picking buffer on left top corner
/show quickselectbar
/show playertouch   : a simple touch controller for kids
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local DockPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockPage.lua");
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
			GameLogic.options:ShowTouchPad(true);
		elseif(name == "mobile") then
			System.options.IsTouchDevice = true;
			GameLogic.options:ShowTouchPad(true);
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
			EntityManager.GetPlayer():SetVisible(true);
		elseif(name == "camera" ) then
			local entity = EntityManager.GetFocus();
			if(entity and entity:isa(EntityManager.EntityCamera)) then
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
		elseif(name == "dock") then
			DockPage.Show(true);
		elseif(name == "dock_left_top") then
			DockPage.SetUIVisible_LeftTop(true);
		elseif(name == "dock_right_top") then
			DockPage.SetUIVisible_RightTop(true);
		elseif(name == "dock_center_bottom") then
			DockPage.SetUIVisible_CenterBottom(true);
		elseif(name == "dock_right_bottom") then
			DockPage.SetUIVisible_RightBottom(true);
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
			local player_ctr = GameLogic.GetPlayerController()
			player_ctr:SetEnableDragPlayerToMove(true)

			NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/TouchMiniKeyboard.lua");
			local TouchMiniKeyboard = commonlib.gettable("MyCompany.Aries.Game.GUI.TouchMiniKeyboard");
			TouchMiniKeyboard.GetSingleton():SetRockerMod()
		elseif (name == "paralife") then
			local ParaLife = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLife")
			ParaLife:Init()
			ParaLife:Show();
		end
	end,
};


-- hide the current player, desktop, etc. 
Commands["hide"] = {
	name="hide", 
	quick_ref=[[/hide [desktop|player|boundingbox|wireframe|touch|mobile|playertouch|
terrain|vision|ui|keyboard|quickselectbar|tips|map|info|camera|paralife|
dock|dock_left_top|dock_right_top|dock_center_bottom|dock_right_bottom|miniuserinfo
]], 
	desc=[[hide different type of things.e.g.
/hide quickselectbar
/hide desktop
/hide player
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local DockPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockPage.lua");
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
			GameLogic.options:ShowTouchPad(false);
		elseif(name == "mobile") then
			System.options.IsTouchDevice = false;
			GameLogic.options:ShowTouchPad(false);
		elseif(name == "player" or name=="") then
			EntityManager.GetPlayer():SetVisible(false);
		elseif(name == "camera" ) then
			local entity = EntityManager.GetFocus();
			if(entity and entity:isa(EntityManager.EntityCamera)) then
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
		elseif(name == "dock") then
			DockPage.Hide();
		elseif(name == "dock_left_top") then
			DockPage.SetUIVisible_LeftTop(false);
		elseif(name == "dock_right_top") then
			DockPage.SetUIVisible_RightTop(false);
		elseif(name == "dock_center_bottom") then
			DockPage.SetUIVisible_CenterBottom(false);
		elseif(name == "dock_right_bottom") then
			DockPage.SetUIVisible_RightBottom(false);
		elseif (name == "miniuserinfo") then
			local MiniWorldUserInfo = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/MiniWorldUserInfo.lua");
			MiniWorldUserInfo.ClosePage()
		elseif (name == "world2in1") then
			local World2In1 = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/World2In1.lua");
			World2In1.HidePage();
		elseif (name == "playertouch") then
			local player_ctr = GameLogic.GetPlayerController()
			player_ctr:SetEnableDragPlayerToMove(false)

			NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/TouchMiniKeyboard.lua");
			local TouchMiniKeyboard = commonlib.gettable("MyCompany.Aries.Game.GUI.TouchMiniKeyboard");
			TouchMiniKeyboard.GetSingleton():SetKeyboardMod()
		elseif (name == "paralife") then
			local ParaLife = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLife")
			ParaLife:Hide();
		end
	end,
};