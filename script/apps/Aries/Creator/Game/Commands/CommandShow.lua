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
	quick_ref=[[/show [desktop|player|boundingbox|wireframe|perf|info|touch|terrain|
mod|physics|vision|quickselectbar|tips|map] [on|off]], 
	desc = [[show different type of things.
Other show filters: 
/show desktop.builder.[static|movie|character|playerbag|gear|deco|tool|template|env] [on|off]
/show movie.controller
/show desktop.builder.movie
/show vision   : AI memory vision
/show keyboard   show keyboard for touch device
/show overlaybuffer    show overlay picking buffer on left top corner
/show quickselectbar
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
		elseif(name == "player") then
			EntityManager.GetPlayer():SetVisible(true);
		elseif(name == "physics") then
			if(bIsShow == nil) then
				bIsShow = true;
			end
			ParaScene.GetAttributeObject():SetField("PhysicsDebugDrawMode", bIsShow and -1 or 0);
		elseif(name == "mod" or name=="plugin") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Login/SelectModulePage.lua");
			local SelectModulePage = commonlib.gettable("MyCompany.Aries.Game.MainLogin.SelectModulePage")
			SelectModulePage.ShowPage();
		elseif(name == "") then
			ParaScene.GetAttributeObject():SetField("ShowMainPlayer", true);
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
		end
	end,
};


-- hide the current player, desktop, etc. 
Commands["hide"] = {
	name="hide", 
	quick_ref=[[/hide [desktop|player|boundingbox|wireframe|touch|terrain|
vision|ui|keyboard|quickselectbar|tips|map]], 
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
		elseif(name == "touch") then
			GameLogic.options:ShowTouchPad(false);
		elseif(name == "player") then
			EntityManager.GetPlayer():SetVisible(false);
		elseif(name == "") then
			ParaScene.GetAttributeObject():SetField("ShowMainPlayer", false);
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
		end
	end,
};