--[[
Title: public desktop functions 
Author(s): LiXizhi
Date: 2008/6/12
Desc: The following public desktop functions can be called by any application to change the desktop settings. 

---++ Desktop Mode
Desktop mode controls whether the scene objects are interactive or editable by the user. Please note that desktop mode only filters current user input, 
the actual action taken is still subject to user access right (user roles). This means that even desktop mode is not editable, 
application can still programatically edit objects as long as user access right does not prohibit it. 
Hence desktop mode is just a handy status mode that application developers can use to toggle the filtering of user inputs at the app system level. 
desktop mode is set to "game" before desktop switching, so an application usually need to change its desktop mode in its APP_ACTIVATE_DESKTOP event handler.

The most important modes are "edit" mode and "game" mode. "edit" mode can both edit and interact with the scene, where "game" mode can interact with but not edit the scene. 

*Example*: 
<verbatim>
	Map3DSystem.UI.AppDesktop.ChangeMode("game")
	Map3DSystem.UI.AppDesktop.ChangeMode("edit")
</verbatim>

---++ Desktop User
Whether user is logged in. 

*Example*: 
<verbatim>
	if(Map3DSystem.UI.AppDesktop.CheckUser()) then
		-- Do your function. 
	end
</verbatim>	

---++ Desktop Functions
More information, on following things, see code doc. 
<verbatim>
	local app_key = Map3DSystem.UI.AppDesktop.GetCurDesktopappkey()
</verbatim>	

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/Desktop/AppDesktop.lua");
Map3DSystem.UI.AppDesktop.OnInit()
Map3DSystem.UI.AppDesktop.LoadDesktop()
-------------------------------------------------------
]]

NPL.load("(gl)script/kids/3DMapSystemUI/InGame/Exit.lua");-- TODO: move this file to appdesktop
NPL.load("(gl)script/kids/3DMapSystemUI/Desktop/autotips.lua");

local libName = "AppDesktop";
local libVersion = "1.0";

local AppDesktop = commonlib.LibStub:NewLibrary(libName, libVersion)
Map3DSystem.UI.AppDesktop = AppDesktop;

-- current destop mode. 
Map3DSystem.UI.DesktopMode = {
	-- whether scene objects are editable, such as create and delete by the user, 
	IsEditable = false,
	-- whether scene objects are interactive, such as sitting on a chair, drive a char, etc.
	-- the right mouse popup menu will be disabled if this is false.
	IsInteractive = true,
	-- univeral selection is enabled.
	CanSelect = true,
	-- can select a character?
	CanSelectCharacter = true,
	-- can select a model?
	CanSelectModel = true,
	-- can left click on a model to select it. it only takes effect when CanSelectModel is true
	CanClickModel = true,
	-- can click on character?
	CanClickCharacter = true,
	-- can display right click context menu?
	CanContextMenu = true,
	-- can mount on the closest character usually by pressing the left shift key
	CanMountClosest = true,
	-- can click on the closest character usually by pressing the left control key
	CanClickClosest = true,
	-- can show nearby x-reference marker
	CanShowNearByXrefMarker = true,
	-- can show closet character marker
	CanShowClosestCharMarker = true,
};

-- predefined mode
AppDesktop.PredefinedMode = {
["game"]={
	IsEditable = false,
	IsInteractive = true,
	CanSelect = true,
	CanSelectCharacter = true,
	CanSelectModel = false,
	CanClickCharacter = true,
	CanContextMenu = false,
	CanMountClosest = false,
	CanClickClosest = false,
	CanShowNearByXrefMarker = false,
	CanShowClosestCharMarker = false,
	CanClickXrefMarker = false, 
	CanClickModelActionScript = false,
},
["chat"]={
	IsEditable = false,
	IsInteractive = true,
	CanSelect = false,
	CanSelectCharacter = false,
	CanSelectModel = false,
	CanClickCharacter = true,
	CanContextMenu = false,
	CanMountClosest = true,
	CanClickClosest = true,
	CanShowNearByXrefMarker = false,
	CanShowClosestCharMarker = true,
	CanClickXrefMarker = false, 
	CanClickModelActionScript = false,
},
["edit"]={
	IsEditable = true,
	IsInteractive = true,
	CanSelect = true,
	CanSelectCharacter = true,
	CanSelectModel = true,
	CanClickCharacter = true,
	CanContextMenu = true,
	CanMountClosest = true,
	CanClickClosest = true,
	CanShowNearByXrefMarker = true,
	CanShowClosestCharMarker = true,
	CanClickXrefMarker = true, 
	CanClickModelActionScript = true,
},
["localedit"]={
	IsEditable = true,
	IsInteractive = true,
	CanSelect = true,
	CanSelectCharacter = true,
	CanSelectModel = true,
	CanClickCharacter = true,
	CanContextMenu = true,
	CanMountClosest = true,
	CanClickClosest = true,
	CanShowNearByXrefMarker = true,
	CanShowClosestCharMarker = true,
	CanClickXrefMarker = true, 
	CanClickModelActionScript = true,
},
["dummy"]={
	IsEditable = false,
	IsInteractive = false,
	CanSelect = false,
	CanSelectCharacter = false,
	CanSelectModel = false,
	CanClickCharacter = false,
	CanContextMenu = false,
	CanMountClosest = false,
	CanClickClosest = false,
	CanShowNearByXrefMarker = false,
	CanShowClosestCharMarker = false,
	CanClickXrefMarker = false, 
	CanClickModelActionScript = false,
},
};

-- Change the desktop mode. desktop mode controls whether the scene objects are interactive or editable. 
-- it will also deselect any selected object when mode is changed
-- @param: The most important modes are "edit" mode, "game" mode and "dummy" mode. If mode is nil, it default to "game" mode.
-- more info, please see AppDesktop.PredefinedMode
function AppDesktop.ChangeMode(mode)
	local mode = AppDesktop.PredefinedMode[mode or "game"]
	if(mode) then
		commonlib.partialcopy(Map3DSystem.UI.DesktopMode, mode)
	end
	-- reset picking filter when mode changes
	Map3DSystem.PickObject(nil, nil);
	
	-- deselect any selected object when mode is changed
	local obj = Map3DSystem.obj.GetObjectParams("selection");
	if(obj ~= nil) then
		Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_DeselectObject, obj = nil});
	end	
end

-- one time init, call this only once when game engine start. It will init both menu and app task bar. 
function AppDesktop.OnInit()
	NPL.load("(gl)script/kids/3DMapSystemUI/Desktop/MainMenu.lua");
	Map3DSystem.UI.MainMenu.InitMainMenu();
			
	NPL.load("(gl)script/kids/3DMapSystemUI/Desktop/AppTaskBar.lua");
	Map3DSystem.UI.AppTaskBar.InitAppTaskBar();
	
	NPL.load("(gl)script/kids/3DMapSystemUI/Desktop/ContextMenu.lua");
end

-- show menu and app task bar. It will call application UI setup internally. 
-- @param bExclusiveMode: if true, it menu and taskbar will not be created
-- @note: call this function on LoadWorld function
function AppDesktop.LoadDesktop(bExclusiveMode)
	-- create the menu but immediately make it invisible
	if(not bExclusiveMode) then
		Map3DSystem.UI.MainMenu.SendMessage({type = Map3DSystem.UI.MainMenu.MSGTYPE.MENU_SHOW});
		Map3DSystem.UI.MainMenu.SendMessage({type = Map3DSystem.UI.MainMenu.MSGTYPE.MENU_SHOW, bShow = false});
	end	
	
	-- load UI for each installed applications for this world. 
	Map3DSystem.App.AppManager.SetupUI();
	
	-- show the task bar
	if(not bExclusiveMode) then
		Map3DSystem.UI.AppTaskBar.SendMessage({type = Map3DSystem.UI.AppTaskBar.MSGTYPE.SHOW_TASKBAR, bShow = true});
	end	
	
	-- TODO: shall we display some welcome window for first time user here?
	
	-- TODO: shall we display autotip on top of the screen with higher z-order?
	-- autotips.Show(); 
end

----------------------------------------
-- public functions 
----------------------------------------

-- @param cmdredirect: this is usually nil. otherwise it will be the name of the command to be called when user finished log in via UI.
--@return: return true, if user is logged in. otherwise it prompts the user to log in. 
function AppDesktop.CheckUser(cmdredirect)
	if(not Map3DSystem.User.IsAuthenticated) then
		-- display the default login dialog 
		Map3DSystem.App.Commands.Call(Map3DSystem.App.Commands.GetLoginCommand(), {
			title="您需要先登录才能使用此功能", cmdredirect = cmdredirect,
		});
		return false;
	end
	return true;
end	

-- @return: return the current app whose desktop is active. 
function AppDesktop.GetCurDesktopappkey()
	return Map3DSystem.UI.AppTaskBar.CurrentAppDesktop;
end

-- set the default app
-- @param app_key: app key. 
-- @param bSwitch: if true, we will activate it immediately.
function AppDesktop.SetDefaultApp(app_key, bSwitch)
	NPL.load("(gl)script/kids/3DMapSystemUI/Desktop/AppTaskBar.lua");
	if(Map3DSystem.UI.AppTaskBar.DefaultApp~=app_key) then
		Map3DSystem.UI.AppTaskBar.DefaultApp = app_key;
	end	
	if(bSwitch) then
		Map3DSystem.UI.AppTaskBar.SendMessage({type = Map3DSystem.UI.AppTaskBar.MSGTYPE.SWITCH_APP_DESKTOP, appkey = app_key});
	end	
end