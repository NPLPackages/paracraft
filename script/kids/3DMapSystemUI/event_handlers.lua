--[[
Title: The map system Event handlers
Author(s): LiXizhi(code&logic)
Date: 2006/1/26
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/event_handlers.lua");
Map3DSystem.ReBindEventHandlers();
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/event_mapping.lua");
NPL.load("(gl)script/ide/action_table.lua");
NPL.load("(gl)script/ide/GUI_inspector_simple.lua");
NPL.load("(gl)script/kids/3DMapSystemUI/MsgProc_AutoAction.lua");
NPL.load("(gl)script/kids/3DMapSystemUI/event_handlers_mouse.lua");
NPL.load("(gl)script/kids/3DMapSystemUI/event_handlers_keyboard.lua");
NPL.load("(gl)script/kids/3DMapSystemUI/event_handlers_network.lua");
NPL.load("(gl)script/kids/3DMapSystemUI/event_handlers_system.lua");

local Missile_Timer;

-------------------------------------------------------------
-- init related
-------------------------------------------------------------
-- rebind event handlers
-- @param params: if nil, it will rebind all. otherwise it can be a table. 
--  {bind_system = true, bind_mouse = false, bind_network=false, bind_key=false}
function Map3DSystem.ReBindEventHandlers(params)
	LOG.std("", "system", "events","System.ReBindEventHandlers called");

	-- register mouse picking event handler
	ParaScene.RegisterEvent("_mdown_map3d", ";Map3DSystem.OnMouseDown();");
	ParaScene.RegisterEvent("_mup_map3d", ";Map3DSystem.OnMouseUp();");
	ParaScene.RegisterEvent("_mmove_map3d", ";Map3DSystem.OnMouseMove();");
	ParaScene.RegisterEvent("_mwheel_map3d", ";Map3DSystem.OnMouseWheel();");
	-- register key event handler
	ParaScene.RegisterEvent("_k_map3d_keydown", ";Map3DSystem_OnKeyDownEvent();");
	ParaScene.RegisterEvent("_ku_map3d_keyup", ";Map3DSystem.OnKeyUpEvent();");
	-- register network event handler
	ParaScene.RegisterEvent("_n_map3d_network", ";Map3DSystem.OnNetworkEvent();");
	-- register system event handler
	ParaScene.RegisterEvent("_s_map3d_system", ";Map3DSystem_OnSystemEvent();");
	
	-- this prevent user from closing the application by alt-f4 or clicking the x button. Instead SYS_WM_CLOSE is fired. 
	ParaEngine.GetAttributeObject():SetField("IsWindowClosingAllowed", true);
	
	NPL.load("(gl)script/kids/3DMapSystemUI/HeadonDisplay.lua");
	local HeadonDisplay = commonlib.gettable("Map3DSystem.UI.HeadonDisplay")
	HeadonDisplay.InitHeadOnTemplates();
	
	-- register a timer for displaying markers: NPL.load("(gl)script/kids/3DMapSystemUI/MsgProc_AutoAction.lua");
	Map3DSystem.EnableAutoActionMarker(true);
	
	-- start UI animation framework.
	NPL.load("(gl)script/ide/UIAnim/UIAnimManager.lua");
	
	-- so that we can generate the onsize event in input application. 
	ParaUI.GetUIObject("root").onsize=";Map3DSystem.OnScreenSize();"
	-- register global message system 
	Map3DSystem.InitMessageSystem();
end

-------------------------------------------------------------
-- event related
-------------------------------------------------------------

-- called whenever the screen resolution changes. 
function Map3DSystem.OnScreenSize()
	-- send message to onsize window of input application. 
	local _, _, width, height = ParaUI.GetUIObject("root"):GetAbsPosition();
	
	Map3DSystem.ScreenResolution = Map3DSystem.ScreenResolution or {};
	Map3DSystem.ScreenResolution.screen_width, Map3DSystem.ScreenResolution.screen_height = width, height;

	NPL.load("(gl)script/ide/System/Windows/Screen.lua");
	local Screen = commonlib.gettable("System.Windows.Screen");
	Screen:OnSizeChange(width, height);

	-- call hook for "input" application
	if(CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROC, 0, "input", {wndName = "onsize", width=width, height=height}) ==nil) then
		return
	end
end