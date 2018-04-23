--[[
Title: Application Task Bar for paraworld
Author(s): LiXizhi
Date: 2008/5/13
Desc: App task bar is docked at the bottom of the screen and has four functional area from left to right. 
   1. App start icon: It will toggle on/off the application lists at the bottom of the display. When application list is displayed, users can also drag applications to the quick launch bar. 
   1. App quick launch bar: Users can quickly switch to a frequently used application exclusive desktop mode. application exclusive desktop mode is a mode 
		where only windows of the given application are shown and application specific toolbars are displayed on the task bar. 
		This allows the applications to make full use of the entire rectangle display area without worrying about UI overlay from other applications' windows. 
		Content is left aligned. overflow toolbar items can be accessed via extension button ">>".
   1. App toolbar: When in an application desktop mode, it displays the application specific toolbar. Application specific toolbar icons are by default displayed 
		with text and an optional icon to help both new and old user to quickly identify the most important tasks relavent to an application. 
		The app toolbar will by default display all application menu items, unless an application explicitly specifies its display content via AppTaskBar.AddCommand in its APP_ACTIVATE_DESKTOP message handler. 
		The app toolbar is by default a fixed-width (512px) region and centered (or float to the left of quick launch bar). Content is left aligned. overflow toolbar items can be accessed via extension button ">>".
   1. CommonStatusBar: 	This section on the task bar provides a place to place common icons (functions) that are always shown regardless of the current application desktop. E.g. social content, chat users, mini-feed.
		Content is right aligned. overflow toolbar items can be accessed via extension button "<<".
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/Desktop/AppTaskBar.lua");
Map3DSystem.UI.AppTaskBar.InitAppTaskBar();
Map3DSystem.UI.AppTaskBar.SendMessage({type = Map3DSystem.UI.AppTaskBar.MSGTYPE.SHOW_TASKBAR, bShow = true});
Map3DSystem.UI.AppTaskBar.SendMessage({type = Map3DSystem.UI.AppTaskBar.MSGTYPE.SWITCH_APP_DESKTOP, appkey = Map3DSystem.App.appkeys["worlds"]});
--Map3DSystem.UI.AppTaskBar.SendMessage({type = Map3DSystem.UI.AppTaskBar.MSGTYPE.SWITCH_APP_DESKTOP, appkey = Map3DSystem.App.appkeys["profiles"]});
------------------------------------------------------------
]]

local libName = "AppTaskBar";
local libVersion = "1.0";
local L = CommonCtrl.Locale("ParaWorld");

local AppTaskBar = commonlib.LibStub:NewLibrary(libName, libVersion)
Map3DSystem.UI.AppTaskBar = AppTaskBar;

NPL.load("(gl)script/kids/3DMapSystemUI/Desktop/MainMenu.lua");

-- automaticly load the status bar
NPL.load("(gl)script/kids/3DMapSystemUI/Desktop/StatusBar.lua");

-- the start app page. 
NPL.load("(gl)script/kids/3DMapSystemUI/Desktop/StartAppPage.lua");
--
-- attributes
--

-- the default app to load at start up. 
AppTaskBar.DefaultApp = Map3DSystem.App.appkeys["MyDesktop"];
-- app_key of the current app desktop. 
AppTaskBar.CurrentAppDesktop = AppTaskBar.DefaultApp;
-- app list window name
AppTaskBar.AppListName = libName..".applist";

-- some theme related things, replace this table to change theme. 
local theme = {
	-- left most start bar background. it just contains the start app button
	StartBar = "Texture/3DMapSystem/Desktop/AppTaskBar.png;0 15 80 49",
	-- the start button on start bar
	StartBarButton = "Texture/3DMapSystem/Desktop/AppTaskBar.png;216 24 40 40",
	-- quick action bar bg
	QuickActionBar = "Texture/3DMapSystem/Desktop/AppTaskBar.png;81 32 58 32:19 0 37 0",
	-- application tool bar bg
	AppToolBar = "Texture/3DMapSystem/Desktop/AppTaskBar.png;140 26 41 38:17 0 17 0",
	-- application toolbar button hover style.
	ToolBarBtnHoverBG = "Texture/3DMapSystem/common/href.png:2 2 2 2";
	-- right most common status bar bg
	CommonStatusBar = "Texture/3DMapSystem/Desktop/AppTaskBar.png;182 32 34 32:31 0 2 0",
	-- The app start page bg. 
	AppStartPage = "Texture/3DMapSystem/Desktop/AppStartPage.png:13 85 13 13",
	-- default application icon if none is provided. 
	DefaultAppIcon = "Texture/3DMapSystem/common/info.png";
	-- whether to play animation to popup application list and fade the background. 
	bUseAnimation = false,
	-- if bUseAnimation is true, this is the background fade animation file 
	BackgroundGreyOutSlowMotionData = "script/kids/3DMapSystemUI/styles/BackgroundGreyOutSlowMotionData.xml",
	-- if bUseAnimation is true, this is the start page popup animation file
	TaskBarAppListPopupMotionData = "script/kids/3DMapSystemUI/styles/TaskBarAppListPopupMotionData.xml",
};

-- messge types
AppTaskBar.MSGTYPE = {
	-- toggle on/off the application lists at the bottom of the display. When application list is displayed, users can also drag applications to the quick launch bar. 
	-- msg = {bShow = true, bUseAnim = true}
	SHOW_APP_LIST = 1000,
	-- show/hide the task bar, 
	-- msg = {bShow = true}
	SHOW_TASKBAR = 1001,
	-- switch to an given application exclusive desktop, we can save last screen to buffer for switching back.
	-- msg = {appkey = "XXX", bSaveLastScreen = false, }
	SWITCH_APP_DESKTOP = 1002,
};

-- default quick launch bar app_keys, we will only show quick launch icons if their app_key is installed on the target computer. 
AppTaskBar.DefaultQuickLaunchApps = {
	{ nLineIndex=1, app_key = Map3DSystem.App.appkeys["Creator"],},
	{ nLineIndex=1, app_key = Map3DSystem.App.appkeys["MyDesktop"],},
	{ nLineIndex=1, app_key = Map3DSystem.App.appkeys["Env"],},
	{ nLineIndex=1, app_key = Map3DSystem.App.appkeys["CCS"],},
	{ nLineIndex=1, app_key = Map3DSystem.App.appkeys["chat"],},
	--{ nLineIndex=1, app_key = Map3DSystem.App.appkeys["profiles"],},
	
	{ nLineIndex=2, app_key = Map3DSystem.App.appkeys["profiles"],},
	{ nLineIndex=2, app_key = Map3DSystem.App.appkeys["worlds"],},
	--{ nLineIndex=2, app_key = Map3DSystem.App.appkeys["EBook"],},
	{ nLineIndex=2, app_key = Map3DSystem.App.appkeys["Blueprint"],},
	{ nLineIndex=2, app_key = Map3DSystem.App.appkeys["screenshot"],},
	{ nLineIndex=2, app_key = Map3DSystem.App.appkeys["Developers"],},
};

-- call this only once at the beginning of the game. 
-- init main bar: this does not show the task bar, it just builds the data structure and messaging system.
function AppTaskBar.InitAppTaskBar()
	if(AppTaskBar.IsInit) then return end
	AppTaskBar.IsInit = true;
	AppTaskBar.name = libName;
	
	-- create the root node for data keeping.
	AppTaskBar.RootNode = CommonCtrl.TreeNode:new({Name = "root", Icon = "", });
	AppTaskBar.ApplistNode = AppTaskBar.RootNode:AddChild(CommonCtrl.TreeNode:new({Text = "applist", Name = "applist"}));
	AppTaskBar.QuickLaunchBarNode = AppTaskBar.RootNode:AddChild(CommonCtrl.TreeNode:new({Text = "quicklaunchbar", Name = "quicklaunchbar"}));
	AppTaskBar.ToolbarNode = AppTaskBar.RootNode:AddChild(CommonCtrl.TreeNode:new({Text = "toolbar", Name = "toolbar"}));
	AppTaskBar.StatusBarNode = AppTaskBar.RootNode:AddChild(CommonCtrl.TreeNode:new({Text = "statusbar", Name = "statusbar"}));
	
	-- populate quick launch bar from MyDesktop app settings (if it is installed). 
	local function OnClickQuickLaunchItem(treeNode)
		AppTaskBar.SwitchAppDesktop(treeNode.Name);
	end
	local QuickLaunchApps;
	if(Map3DSystem.App.MyDesktop and Map3DSystem.App.MyDesktop.app) then
		QuickLaunchApps = Map3DSystem.App.MyDesktop.app:ReadConfig("quicklaunchapps", AppTaskBar.DefaultQuickLaunchApps);
	else
		QuickLaunchApps = AppTaskBar.DefaultQuickLaunchApps;
	end
	local index, value
	for index, value in ipairs(QuickLaunchApps) do
		local app = Map3DSystem.App.AppManager.GetApp(value.app_key);
		if(app) then
			local node = AppTaskBar.QuickLaunchBarNode:GetChild(value.nLineIndex);
			if(node == nil) then
				node = AppTaskBar.QuickLaunchBarNode:AddChild(CommonCtrl.TreeNode:new({Text = tostring(value.nLineIndex), Name = tostring(value.nLineIndex),}));
			end
			node:AddChild(CommonCtrl.TreeNode:new({Text = app.Title or app.SubTitle or app.name, Name = app.app_key, Icon = app.icon or theme.DefaultAppIcon, onclick = OnClickQuickLaunchItem}));
		end	
	end
	
	-- populate status bar with some predefined commands. 
	-- application can also add commands to status bar when their UI are connected, here we just hard-code some command here for testing purposes.  
	
	
	-- create windows for message handling
	NPL.load("(gl)script/ide/os.lua");
	local _app = CommonCtrl.os.CreateGetApp(AppTaskBar.name);
	AppTaskBar.App = _app;
	AppTaskBar.MainWnd = _app:RegisterWindow("main", nil, AppTaskBar.MSGProc);
end

-- add a task bar command at given position. the parent folders must be created beforehand, otherwise it will be inserted to the first unfound folder.
-- if there is already an object at the position, the add command will do nothing. 
-- @param command; type of Map3DSystem.App.Command, or it can be string of existing command name. 
-- @param position: this is a tree path string of folder names separated by dot. There are some predefined categories which correspond to the four display sections on the task bar. See following.
--  e.g. "applist.APP_GUID", "quicklaunchbar.APP_GUID", "toolbar.CreateWorld", "statusbar.minifeed". If this is nil, it will be the same as "toolbar." plus the last name of command.name.
-- @param posIndex: if position is a item in another folder, this is the index at which to add the item. 
-- if nil, it is added to end, if 1 it is the beginning. Please note, for right aligned section(common status bar), the first position is the right most position. 
-- @return: return the command object if added successfully. 
function AppTaskBar.AddCommand(command, position, posIndex)
	if(type(command) == "string") then
		command = Map3DSystem.App.Commands.GetCommand(command);
	end
	
	if(command and AppTaskBar.RootNode~=nil)then
		local node = AppTaskBar.RootNode;
		local nodeName;
		if(position == nil) then
			position = "toolbar."..string.match(command.name, "(%w+)$");
		end
		
		for nodeName in string.gfind(position, "([^%.]+)") do
			local subnode = node:GetChildByName(nodeName);	
			if(subnode == nil) then
				if( command.CommandStyle ~= Map3DSystem.App.CommandStyle.Separator) then
					-- taskbar command is inserted to the first unfound folder in position
					node:AddChild(CommonCtrl.TreeNode:new({Name = nodeName, Text = command.ButtonText, Icon = command.icon, tooltip=command.tooltip,
						AppCommand = command, onclick = AppTaskBar.OnClickCommand}), posIndex);
				else
					-- it is just a separator. 
					node:AddChild(CommonCtrl.TreeNode:new({Name = nodeName, Type = "separator", NodeWidth=5}));
				end		
				break;
			else
				node = subnode;
			end
		end
		return command;
	end
end

-- return a task item index by its position. This function is mosted called before AddMenuCommand to determine where to insert a new command. 
-- @param position: this is a tree path string of folder names separated by dot. There are some predefined categories which correspond to the four display sections on the task bar. See following.
--  e.g. "applist.APP_GUID", "quicklaunchbar.APP_GUID", "toolbar.CreateWorld", "statusbar.minifeed"
-- @return nil if not found, other the item index integer is returned. please note that the index may change when new items are added later on. 
function AppTaskBar.GetItemIndex(position)
	local index;
	if(AppTaskBar.RootNode~=nil)then
		local node = AppTaskBar.RootNode;
		local nodeName;
		
		for nodeName in string.gfind(position, "([^%.]+)") do
			node = node:GetChildByName(nodeName);	
			if(node == nil) then
				break;
			end
		end
		if(node ~= nil) then
			index = node.index;
		end
	end
	return index; 
end

-- call the task bar command
function AppTaskBar.OnClickCommand(treeNode)
	if(treeNode~=nil and treeNode.AppCommand~=nil)then
		local name = treeNode.AppCommand.name;
		local category = string.match(name, "^(%w+)%.");
		if(category == "applist") then
			-- TODO: switch to  application treeNode.AppCommand.app_key
			
		elseif(category == "quicklaunchbar") then
			-- TODO: switch to  application treeNode.AppCommand.app_key
			
		elseif(category == "toolbar") then
			treeNode.AppCommand:Call();
			
		elseif(category == "statusbar") then
			treeNode.AppCommand:Call();
		else	
			-- in case it is menu command
			treeNode.AppCommand:Call();
		end
	end
end


-- send a message to AppTaskBar:main window handler
-- AppTaskBar.SendMessage({type = AppTaskBar.MSGTYPE.MENU_SHOW});
function AppTaskBar.SendMessage(msg)
	msg.wndName = "main";
	AppTaskBar.App:SendMessage(msg);
end


-- AppTaskBar window handler
function AppTaskBar.MSGProc(window, msg)
	if(msg.type == AppTaskBar.MSGTYPE.SHOW_APP_LIST) then
		-- toggle on/off the application lists at the bottom of the display. When application list is displayed, users can also drag applications to the quick launch bar. 
		-- msg = {bShow = true, bUseAnim = true}
		AppTaskBar.ToggleAppList(msg.bShow, msg.bUseAnim);
	elseif(msg.type == AppTaskBar.MSGTYPE.SHOW_TASKBAR) then
		-- show/hide the task bar, 
		-- msg = {bShow = true}
		AppTaskBar.Show(msg.bShow);
	elseif(msg.type == AppTaskBar.MSGTYPE.SWITCH_APP_DESKTOP) then
		-- switch to an given application exclusive desktop, we can save last screen to buffer for switching back.
		-- msg = {appkey = "XXX", bSaveLastScreen = false, }
		AppTaskBar.SwitchAppDesktop(msg.appkey, msg.bSaveLastScreen);
	end
end

-------------------------
-- protected
-------------------------
-- the alpha value of all task bar backgrounds
AppTaskBar.BG_alpha = "220";

-- show or hide task bar UI
function AppTaskBar.Show(bShow)
	local _bar, _this, _parent;
	local left,top,width,height;
	
	_this = ParaUI.GetUIObject(libName);
	if(_this:IsValid())then
		if(bShow==nil) then
			_this.visible = not _this.visible;
		else
			_this.visible = bShow;
		end
	else
		if( bShow == false)then
			return;
		end
		local left,top,width, height = 2,2, 48,48;
		_this = ParaUI.CreateUIObject("container", libName, "_mb", 0, 0, 0, 75);
		_this.background = "";
		_this.zorder = 5; -- make it stay on top. 
		_this:AttachToRoot();
		_parent = _this;
		
		-- main background
		_this = ParaUI.CreateUIObject("button", "main background", "_lt", 0, 0, 422, 75)
		_this.background = "Texture/3DMapSystem/Desktop/TaskBar_32bits.png; 0 0 422 75";
		_this.enabled = false;
		_guihelper.SetUIColor(_this, "255 255 255 "..AppTaskBar.BG_alpha)
		_parent:AddChild(_this);
		
		left = 13;
		top = 13;

		--
		-- big 2 buttons
		--
		_this = ParaUI.CreateUIObject("button", "bigBtn1", "_lt", left, top, width, width)
		--_this.background = theme.StartBarButton;
		_this.background = "Texture/3DMapSystem/Desktop/StartPage.png";
		_this.onclick = ";Map3DSystem.UI.Desktop.StartAppPage.OnClickApp(\"profiles_GUID\")";
		_this.tooltip = L"我的首页";
		_parent:AddChild(_this);
		left = left + width + 13;
		
		_this = ParaUI.CreateUIObject("button", "bigBtn2", "_lt", left, top, width, width)
		--_this.background = theme.StartBarButton;
		_this.background = "Texture/3DMapSystem/Desktop/StarMap.png";
		_this.onclick = ";Map3DSystem.UI.Desktop.StartAppPage.OnClickApp(\"worlds_GUID\", \"File.Open.StarView\")";
		_this.tooltip = L"星图";
		_parent:AddChild(_this);
		left = left + width + 22;
		
		--
		-- quick launch bar
		--
		-- line number text
		_this = ParaUI.CreateUIObject("text", "linetext1", "_lt", left+5, top+3, 16, 16)
		_this.text = "1";
		--_guihelper.SetFontColor(_this, "0 0 0")
		_parent:AddChild(_this);
		_this = ParaUI.CreateUIObject("text", "linetext2", "_lt", left+5, top+24+9, 16, 16)
		_this.text = "2";
		--_guihelper.SetFontColor(_this, "0 0 0")
		_parent:AddChild(_this);
		left = left + 18;
		
		width = 5*33; -- 6 * (24px icons + 4 spacing)
		_this = ParaUI.CreateUIObject("container", "quicklaunchbar", "_lt", left, top-4, width, height+2)
		_this.background = "";
		_parent:AddChild(_this);
		left = left + width;
		
		width = 16;
		_this = ParaUI.CreateUIObject("button", "rowUp", "_lt", left, top, width, 16)
		_this.background = "Texture/3DMapSystem/Desktop/QuickLaunchUpArrow.png";
		_this.animstyle = 12;
		_parent:AddChild(_this);
		_this = ParaUI.CreateUIObject("button", "rowAll", "_lt", left, top+16, width, 16)
		_this.background = "Texture/3DMapSystem/Desktop/QuickLaunchLock.png";
		_this.tooltip = L"锁定/解锁应用程序按钮";
		_this.animstyle = 12;
		_parent:AddChild(_this);
		_this = ParaUI.CreateUIObject("button", "rowDown", "_lt", left, top+32, width, 16)
		_this.background = "Texture/3DMapSystem/Desktop/QuickLaunchDownArrow.png";
		_this.animstyle = 12;
		_parent:AddChild(_this);
		left = left + width + 20;
		
		--
		-- application toolbar
		--
		width = 48;
		_this = ParaUI.CreateUIObject("button", "curAppIcon", "_lt", left, top, width, width)
		_this.background = "";
		_this.tooltip = L"当前应用程序桌面";
		_this.onclick = string.format(";Map3DSystem.UI.AppTaskBar.ToggleAppList(nil, %s);", tostring(theme.bUseAnimation));
		_parent:AddChild(_this);
		_guihelper.SetUIColor(_this, "255 255 255")
		left = left + width + 11;
		
		width = 314;
		_this = ParaUI.CreateUIObject("container", "toolbar", "_lt", left, 0, width, 75)
		_this.background = "";
		_parent:AddChild(_this);
		left = left + width;
		
		--
		-- common status bar
		--
		_this = ParaUI.CreateUIObject("button", "bg", "_rb", -256, -30, 256, 30)
		_this.background = "Texture/3DMapSystem/Desktop/StatusBarBG_32bits.png;0 0 64 41: 12 12 12 12";
		--_this.background = "Texture/3DMapSystem/Desktop/StatusBarBG2_32bits.png;0 0 32 24: 12 12 12 11";
		_this.enabled = false;
		_guihelper.SetUIColor(_this, "255 255 255 "..AppTaskBar.BG_alpha)
		_parent:AddChild(_this);
		
		_this = ParaUI.CreateUIObject("container", "statusbar", "_fi", left, 75-30+3, 5, 3)
		_this.background = "";
		_parent:AddChild(_this);
		
		-- contacts bar is a container that keep all the contact minimized icons. 
		--	And new messages are shown with a bubble if the chat window is minimized(not visible).
		--	For more information, see Chat application
		--
		-- common contacts bar
		--
		_this = ParaUI.CreateUIObject("container", "contactsbar", "_fi", left, 12, 0, 24)
		_this.background = "";
		_parent:AddChild(_this);
		
		
		-- refresh
		AppTaskBar.RefreshQuickLaunchBar();
		-- update items according to the current application desktop.
		--AppTaskBar.RefreshToolbar();
		
		
		-- automaticly show the status bar
		NPL.load("(gl)script/kids/3DMapSystemUI/Desktop/StatusBar.lua");
		local _statusBar = ParaUI.GetUIObject(AppTaskBar.name):GetChild("statusbar");
		Map3DSystem.UI.AppTaskBar.StatusBar.Refresh(_statusBar);
		
		
		-- automaticly show the contacts bar
		NPL.load("(gl)script/kids/3DMapSystemUI/Chat/ContactsBar.lua");
		local _contactsBar = ParaUI.GetUIObject(AppTaskBar.name):GetChild("contactsbar");
		Map3DSystem.App.Chat.ContactsBar.Refresh(_contactsBar);
		
		---- refresh
		--AppTaskBar.RefreshStatusBar()
		
		-- switch to default app. TODO: shall we switch to last app. 
		AppTaskBar.SwitchAppDesktop(AppTaskBar.DefaultApp)
	end
end

-- switch to a given application exclusive desktop mode. We can optionally save last screen to texture for switching back display.
-- internally it just send APP_DEACTIVATE_DESKTOP message to the old app, and APP_ACTIVATE_DESKTOP message to the new application.
-- The new application is expected to add commands to app toolbar via AppTaskBar.AddCommand() before the message returns. 
-- Note1: The app toolbar will by default display all application menu items, unless an application explicitly 
--  specifies its toolbar content inside APP_ACTIVATE_DESKTOP message handler. 
-- Note2: The application can change the toolbar content at any time, by calling AppTaskBar.ClearToolBar(), adding new commands and then calling AppTaskBar.RefreshToolbar()
-- @param appkey: the application key. if key is the same as current, it will refresh anyway. if nil, it will clear desktop(but not refreshing its UI). 
-- @param bSaveLastScreen: whether saving screen to texture
function AppTaskBar.SwitchAppDesktop(appkey, bSaveLastScreen)
	if(bSaveLastScreen) then
		-- TODO: save screen to texture
	end	
	if(AppTaskBar.CurrentAppDesktop and (AppTaskBar.CurrentAppDesktop ~= appkey)) then
		-- Deactivate the old desktop
		local app = Map3DSystem.App.AppManager.GetApp(AppTaskBar.CurrentAppDesktop);
		if(app) then
			app:SendMessage({type = Map3DSystem.App.MSGTYPE.APP_DEACTIVATE_DESKTOP});
		end
	end
	
	AppTaskBar.CurrentAppDesktop = appkey;
	
	-- clear toolbar since we will rebuild them
	AppTaskBar.ClearToolBar();
	
	-- remove all idle tips when application switched. ?? what time to enable all idle tips
	-- leio changes at 2008/6/30
	if(autotips) then
		--autotips.RemoveIdeTips()
		--autotips.DoDisable()
	end	
	-- load default desktop settings, such as desktop mode is set to "game" for all applications. 
	-- load default desktop mode
	Map3DSystem.UI.AppDesktop.ChangeMode("game")
	
	if(not AppTaskBar.CurrentAppDesktop) then return end
	
	local app = Map3DSystem.App.AppManager.GetApp(AppTaskBar.CurrentAppDesktop);
	if(not app) then return end
	
	-- TODO: Hide all application windows whose app key is not appkey.
	-- NOTE: by andy, hide all the window frames except the pinned window frames, and show the windows in OnActivateDesktop()
	NPL.load("(gl)script/ide/WindowFrame.lua");
	CommonCtrl.WindowFrame.HideAllExceptPinned()
	
	-- toggle off the StartAppPage if user trigger the application from quicklaunch with the StartAppPage open
	AppTaskBar.ToggleAppList(false, false);
	
	-- send a activate desktop message to the current application, we will expect the application to have added toolbar commands after this message returns.
	app:SendMessage({type = Map3DSystem.App.MSGTYPE.APP_ACTIVATE_DESKTOP});
	
	if(AppTaskBar.ToolbarNode:GetChildCount() == 0) then
		-- if the current application does not provide any toolbar commands inside its APP_ACTIVATE_DESKTOP message handler, 
		-- we will extract all menu commands related to this application. If there is still none, the menu bar will be refreshed empty. 
		AppTaskBar.AddAppMenuItemsToToolBar(AppTaskBar.CurrentAppDesktop);
	end
	-- refresh toolbar for this application. 
	AppTaskBar.RefreshToolbar();
end

-- extract all menu commands related to this application and add them to toolbar. 
-- this function can be called to automatically add the menu items to toolbar for the given app.
-- @param appkey: it will search the current menu and append all menu items whose application key is appkey to the current app toolbar.
function AppTaskBar.AddAppMenuItemsToToolBar(appkey)
	local appCommand;
	local count = 0;
	for appCommand in Map3DSystem.UI.MainMenu.GetAppCommands(appkey) do
		if(appCommand.ButtonText) then
			count = count + 1;
			-- only display those with at least text and an optional icon. 
			AppTaskBar.AddCommand(appCommand, "toolbar.menu"..count)
		end	
	end
end

-- toggle on/off the application lists at the bottom of the display. When application list is displayed, users can also drag applications to the quick launch bar. 
-- @param bShow: toggle on/off the application lists
-- @param bUseAnim: true to play a popup animation. 
-- @param destoryUI_ID: ui object to destroy. only used when bShow is false. 
function AppTaskBar.ToggleAppList(bShow, bUseAnim, destoryUI_ID)
	local _this,_parent;
	local left,top,width,height;
	_this = ParaUI.GetUIObject(AppTaskBar.AppListName);
	if(_this:IsValid())then
		if(bShow==nil) then
			bShow = not _this.visible;
		end
		_this.visible = bShow;
		
		if(bShow) then
			-- update the app start page if the user changes, such as from unsigned to signed in. 
			if(AppTaskBar.LastUserID~=Map3DSystem.App.profiles.ProfileManager.GetUserID()) then
				AppTaskBar.LastUserID = Map3DSystem.App.profiles.ProfileManager.GetUserID();
				if(AppTaskBar.StartAppPage) then
					AppTaskBar.StartAppPage:Refresh(0.01);
				end
			end
		end
	else
		if(bShow == false) then return end
		bShow = true;
		
		local listHeight = 500;
		_this = ParaUI.CreateUIObject("container", AppTaskBar.AppListName, "_mb", 0, 0, 0, listHeight)
		_this.background = theme.AppStartPage;
		_this.zorder = 4;
		_this:AttachToRoot();
		_parent = _this;
		
		NPL.load("(gl)script/kids/3DMapSystemApp/mcml/PageCtrl.lua");
		AppTaskBar.StartAppPage = AppTaskBar.StartAppPage or Map3DSystem.mcml.PageCtrl:new({url="script/kids/3DMapSystemUI/Desktop/StartAppPage.html"});
		AppTaskBar.StartAppPage:Create("StartAppPage", _parent, "_fi", 5, 11, 5, 62)
--[[		
		-- create icon and text for all applications
		-- TODO: we may sort by app.category and then display with category information.
		local left,top,width, height,iconsize = 10,10,0,36,32;
		local _,_, maxWidth = ParaUI.GetUIObject("root"):GetAbsPosition();
		local key, app, icon;
		for key, app in Map3DSystem.App.AppManager.GetNextApp() do
			icon = app.icon;
			if(icon==nil or icon=="") then
				icon = theme.DefaultAppIcon;
			end
			
			if(app.icon and app.icon~="")  then
				width = iconsize;
				-- word wrapping
				if((left+width)>=maxWidth) then 	
					left = 10;	
					top = top + height
					if(top>=listHeight) then break end
				end	
				_this = ParaUI.CreateUIObject("button", "b", "_lt", left, top, width, width)
				_this.animstyle = 12;
				_this.background = AppCategory.icon;
				_parent:AddChild(_this);
				left = left + width;
			end
			if(app.name) then
				width = _guihelper.GetTextWidth(app.name)+4;
				-- word wrapping
				if((left+width)>=maxWidth) then 	
					left = 10;	
					top = top + height
					if(top>=listHeight) then break end
				end	
				_this = ParaUI.CreateUIObject("button", "toolbarBtn", "_lt", left, top+8, width, 20)
				_guihelper.SetVistaStyleButton(_this, "", theme.ToolBarBtnHoverBG) --use vista style
				_this.text = app.name;
				_parent:AddChild(_this);
				left = left + width;
			end
		end
]]		
	end

	if(bUseAnim) then
		-- fade in/out according to visibility.
		if(bShow) then
			-- play popup animation
			_parent = ParaUI.CreateUIObject("container","applist_bg_grey_canvas1", "_fi",0,0,0,0);
			_parent:AttachToRoot();
			_parent.background = "Texture/whitedot.png";
			_parent.onmouseup = string.format(";Map3DSystem.UI.AppTaskBar.CancelAppList(%d);", _parent.id);
			ParaUI.GetUIObject(AppTaskBar.AppListName):BringToFront();
			
			if(not AppTaskBar.PopupMotion_) then
				-- create animation if not create before. 
				NPL.load("(gl)script/ide/Motion/AnimatorEngine.lua");
				AppTaskBar.PopupMotion_ = CommonCtrl.Motion.AnimatorEngine:new({framerate=24});
				local groupManager = CommonCtrl.Motion.AnimatorManager:new();
				local layerManager = CommonCtrl.Motion.LayerManager:new();
				local layerBGManager = CommonCtrl.Motion.LayerManager:new();
				local PopupAnimator = CommonCtrl.Motion.Animator:new();
				PopupAnimator:Init(theme.TaskBarAppListPopupMotionData, AppTaskBar.AppListName);
				local BgGreyOutAnimator = CommonCtrl.Motion.Animator:new();
				BgGreyOutAnimator:Init(theme.BackgroundGreyOutSlowMotionData, "applist_bg_grey_canvas1");
				
				layerManager:AddChild(PopupAnimator);
				layerBGManager:AddChild(BgGreyOutAnimator);
				groupManager:AddChild(layerManager);
				groupManager:AddChild(layerBGManager);
				AppTaskBar.PopupMotion_:SetAnimatorManager(groupManager);
			end	
			
			-- play animation
			AppTaskBar.PopupMotion_:doPlay();
		else
			-- play fade out animation
		end
	else
		if(bShow) then
			_parent = ParaUI.CreateUIObject("container","applist_bg_grey_canvas1", "_fi",0,0,0,0);
			_parent.background = "";
			_parent.onmouseup = string.format(";Map3DSystem.UI.AppTaskBar.CancelAppList(%d);", _parent.id);
			_parent:AttachToRoot();
			ParaUI.GetUIObject(AppTaskBar.AppListName):BringToFront();
		end
	end	
	if(not bShow) then
		-- terminate any animations and related UI 
		if(AppTaskBar.PopupMotion_) then AppTaskBar.PopupMotion_:doEnd(); end
		ParaUI.Destroy("applist_bg_grey_canvas1");
		if(destoryUI_ID) then
			ParaUI.Destroy(destoryUI_ID);
		end	
	end
end

-- toggle off app list
-- @param destoryUIID: nil or the id of the UI object to delete
function AppTaskBar.CancelAppList(destoryUI_ID)
	AppTaskBar.ToggleAppList(false, nil, destoryUI_ID);
end

-- it simply clear application list causing the next AppTaskBar.ToggleAppList() method to rebuilt its UI
-- this function is rarely used, unless user has newly installed applications and do not want to restart ParaEngine to see it takes effect. 
function AppTaskBar.ClearAppList()
	ParaUI.Destroy(AppTaskBar.AppListName);
end

-------------------------
-- methods 
-------------------------
-- clear the tool bar.  
-- The application can change the toolbar content at any time, by adding commands and then calling AppTaskBar.RefreshToolbar()
-- @param ClearToolBar: if true, UI is refreshed. 
function AppTaskBar.ClearToolBar(bRefreshUI)
	AppTaskBar.ToolbarNode:ClearAllChildren();
	if(bRefreshUI) then
		AppTaskBar.RefreshToolbar();
	end
end

-- refresh application toolbar according to the current toolbar data 
-- a toolbar item may contain icon, text or both.
function AppTaskBar.RefreshToolbar()
	local _parent = ParaUI.GetUIObject(AppTaskBar.name);
	if(not _parent:IsValid()) then return end
	
	-- set the currernt application icon
	local app = Map3DSystem.App.AppManager.GetApp(AppTaskBar.CurrentAppDesktop);
	if(app) then 
		local _this = _parent:GetChild("curAppIcon")
		_this.background = app.icon or "";
		_this.tooltip = app.Title or L"当前应用程序桌面";
	else
		_parent:GetChild("curAppIcon").background = "";
	end
	
	_parent = _parent:GetChild("toolbar");
	if(not _parent:IsValid()) then return end
	
	-- remove all children,since we will rebuild all. 
	_parent:RemoveAll();
	
	local nCount = table.getn(AppTaskBar.ToolbarNode.Nodes);
	local width = nCount*36 + 24;
	
	local _this = ParaUI.CreateUIObject("button", "BG", "_lt", 0, 0, width, 75)
	_this.background = "Texture/3DMapSystem/Desktop/TaskBar_32bits.png; 422 0 62 75: 30 66 30 8";
	_this.enabled = false;
	_guihelper.SetUIColor(_this, "255 255 255 "..AppTaskBar.BG_alpha)
	_parent:AddChild(_this);
	
	-- we will use an extension button for overflow items.
	local maxWidth = _parent.width - 24;
	
	-- for each quick action node, create an icon.
	local _this, bNoSpaceLeft;
	local left, top, width, iconsize = 8,32,24, 24;
	local count = 0; -- number of icon created. 
	local index, node
	for index, node in ipairs(AppTaskBar.ToolbarNode.Nodes) do
		if(node.Type == "separator") then
			left = left + 10;
		elseif(node.AppCommand) then
			if(node.Icon)  then
				width = iconsize;
				if((left+width)<maxWidth) then
					_this = ParaUI.CreateUIObject("button", "BG", "_lt", left, top, width + 8, width + 8)
					_this.background = "Texture/3DMapSystem/Desktop/ToolbarIconBG.png";
					_this.enabled = false;
					_guihelper.SetUIColor(_this, "255 255 255 "..AppTaskBar.BG_alpha)
					_parent:AddChild(_this);
					
					_this = ParaUI.CreateUIObject("button", "toolbarBtn", "_lt", left+4, top+4, width, width)
					_this.animstyle = 12;
					_this.background = node.Icon;
					_this.tooltip = node.tooltip or node.Text
					_parent:AddChild(_this);
					_this.onclick = string.format(";Map3DSystem.UI.AppTaskBar.OnClickToolbar(%d);", index);
					left = left + width + 12;
				else
					bNoSpaceLeft = true;	
				end	
			elseif(node.Text) then
				width = _guihelper.GetTextWidth(node.Text)+4;
				if((left+width)<maxWidth) then
					_this = ParaUI.CreateUIObject("button", "toolbarBtn", "_lt", left, top+2, width, 20)
					_guihelper.SetVistaStyleButton(_this, "", theme.ToolBarBtnHoverBG) --use vista style
					_this.onclick = string.format(";Map3DSystem.UI.AppTaskBar.OnClickToolbar(%d);", index);
					_this.text = node.Text;
					if(node.tooltip) then
						_this.tooltip = node.tooltip
					end
					_parent:AddChild(_this);
					left = left + width;
				else
					bNoSpaceLeft = true;	
				end	
			end
			
			count = count + 1;
			if(bNoSpaceLeft) then
				-- show extension button >> using a popup menu control.
				AppTaskBar.ToolbarNode.ExtensionItemIndex = index;
				
				_this = ParaUI.CreateUIObject("button", "extBtn", "_rt", -23, top+5, 16, 16)
				_this.background = "Texture/3DMapSystem/Desktop/ext_left.png";
				_this.rotation = 3.14159;
				_this.animstyle = 12;
				_this.onclick = ";Map3DSystem.UI.AppTaskBar.ShowToolbarExtensionMenu();"
				_parent:AddChild(_this);
				break;
			end
		end	
	end
	
	_parent:GetChild("BG").width = left + 16;
end

-- clicks a toolbar item. 
function Map3DSystem.UI.AppTaskBar.OnClickToolbar(index)
	local node = AppTaskBar.ToolbarNode:GetChild(index);
	if(node) then
		if(type(node.onclick) == "function") then
			node.onclick(node);
		elseif(node.AppCommand) then
			node.AppCommand:Call();
		end	
	end
end

-- this function is called when quick launch bar is recreated or new item is added to it. 
-- TODO: If user made changes to it, remember to save to "MyDesktop" app's config file. 
function AppTaskBar.RefreshQuickLaunchBar()
	local _parent = ParaUI.GetUIObject(AppTaskBar.name):GetChild("quicklaunchbar");
	if(not _parent:IsValid()) then return end
	
	-- remove all children,since we will rebuild all. 
	_parent:RemoveAll();
	
	-- for each quick action node, create an icon.
	local _this;
	local left, top, width = 0,0,24;
	
	local index, node
	local nLineIndex, LineNode
	for nLineIndex, LineNode in ipairs(AppTaskBar.QuickLaunchBarNode.Nodes) do
		left = 4;
		local count = 0; -- number of icons created. 
		for index, node in ipairs(LineNode.Nodes) do
			local app = Map3DSystem.App.AppManager.GetApp(node.Name);
			if(app) then
				count = count + 1;
				-- 6 is maximum quick launch icon number
				if(count<=6) then
					_this = ParaUI.CreateUIObject("button", "quicklaunchBtn", "_lt", left, top, width, width)
					_this.tooltip = node.Text;
					_this.animstyle = 14;
					_this.onclick = string.format(";Map3DSystem.UI.AppTaskBar.OnClickQuickLaunchBar(%d, %d);", nLineIndex, index);
					if(app.icon)  then
						_this.background = app.icon;
					else
						_this.background = theme.DefaultAppIcon;
					end
					_parent:AddChild(_this);
					
					left = left + width + 9;
				else
					-- show extension button >> using a popup menu control.
					LineNode.ExtensionItemIndex = index+1;
					
					_this = ParaUI.CreateUIObject("button", "extBtn", "_rt", -29, 5, 16, 16)
					_this.background = "Texture/3DMapSystem/Desktop/ext_right.png";
					_this.animstyle = 12;
					_this.onclick = string.format(";Map3DSystem.UI.AppTaskBar.ShowQuickLaunchExtensionMenu(%d);", nLineIndex);
					_parent:AddChild(_this);
					break;
				end
			end	
		end
		top = top + width + 7;
	end	
end

-- callback
function AppTaskBar.OnClickQuickLaunchBar(nLineIndex, index)
	local node = AppTaskBar.QuickLaunchBarNode:GetChild(nLineIndex);
	if(node) then
		node = node:GetChild(index);
		if(node and type(node.onclick) == "function") then
			node.onclick(node);
		end
	end
end

------------ DEPARACATED ------------
-- add a status bar item.
-- @param command; type of Map3DSystem.App.Command
-- @param priority: number
--		Priority defines the position of the given command in the status bar. Higher priority shown on the right.
--		For those items with the same priority, the more recent added has lower priority which shows on the left.
-- Here are some default priorities for official applications:
--		Feed: 10, ChatWindow: 3, OfficalAppStatus: 8, DefaultPriority: 5
function AppTaskBar.AddStatusBarCommand(command, priority)
	-- default priority
	priority = priority or 5;
	
	if(AppTaskBar.StatusBarNode:GetChildByName(command.name)) then
		log("Command: "..command.name.." already added into the status bar\n");
		return;
	end
	
	AppTaskBar.StatusBarNode:AddChild(CommonCtrl.TreeNode:new({
		Name = command.name, 
		priority = priority,
		AppCommand = command,
		}));
	AppTaskBar.StatusBarNode:SortChildren(CommonCtrl.TreeNode.GenerateGreaterCFByField("priority"));
	
	-- refresh the status bar
	AppTaskBar.RefreshStatusBar();
	--AppTaskBar.StatusBarNode:SortChildren(CommonCtrl.TreeNode.GenerateLessCFByField("priority"));
end

-- remove command from the status bar
-- @param command: the command to be removed from the status bar
function AppTaskBar.RemoveStatusBarCommand(command)
	if(AppTaskBar.StatusBarNode:GetChildByName(command.name)) then
		AppTaskBar.StatusBarNode:RemoveChildByName(command.name);
		
		-- refresh the status bar
		AppTaskBar.RefreshStatusBar();
	end
end

-- remove all commands in status bar
function AppTaskBar.ClearStatusBarCommands()
	log("All statusBar commands cleared\n")
	AppTaskBar.StatusBarNode:ClearAllChildren();
end

------------ DEPARACATED ------------
-- this function is called when status bar is recreated or new item is added to it. 
function AppTaskBar.RefreshStatusBar()
	local _parent = ParaUI.GetUIObject(AppTaskBar.name):GetChild("statusbar");
	if(not _parent:IsValid()) then return end
	
	Map3DSystem.App.ActionFeed.StatusBar.Show(_parent)
	
	do return end
	
	-- remove all children,since we will rebuild all. 
	_parent:RemoveAll();
	
	-- for each quick action node, create an icon.
	local _this;
	local left, top, width = 0, 6, 24;
	-- we will use an extension button for overflow items.
	local _,_, maxWidth = _parent:GetAbsPosition();
	maxWidth = maxWidth - 22;
	local bNoSpaceLeft;
	local defaultTextAreaWidth = 48;
	local defaultItemCont = nil;
	
	local count = 0; -- number of icon created. 
	local index, node
	for index, node in ipairs(AppTaskBar.StatusBarNode.Nodes) do
		if(node.AppCommand) then
			local statusItemWidth;
			if(node.AppCommand.ButtonText) then
				statusItemWidth = width + defaultTextAreaWidth;
			else
				statusItemWidth = width;
			end
			if((left + statusItemWidth) < maxWidth) then
				if(node.AppCommand.ButtonText) then
					-- item with icon and text
					local _item = ParaUI.CreateUIObject("container", "statusBtn_"..node.AppCommand.name, 
							"_rt", -(left+width+defaultTextAreaWidth), top, width + defaultTextAreaWidth, width);
					_item.background = defaultItemCont;
					_parent:AddChild(_item);
							
					_this = ParaUI.CreateUIObject("button", "icon", "_lt", 0, 0, width, width)
					_this.tooltip = node.AppCommand.tooltip;
					_this.animstyle = 12;
					if(node.AppCommand.icon) then
						_this.background = node.AppCommand.icon;
					else
						_this.background = theme.DefaultAppIcon;
					end
					_this.onclick = string.format(";Map3DSystem.App.Commands.Call(%q);", node.AppCommand.name);
					_item:AddChild(_this);
					
					_this = ParaUI.CreateUIObject("button", "text", "_lt", width, 0, defaultTextAreaWidth, width);
					_this.text = node.AppCommand.ButtonText;
					_this.background = "";
					_this.tooltip = node.AppCommand.tooltip;
					_this.onclick = string.format(";Map3DSystem.App.Commands.Call(%q);", node.AppCommand.name);
					_item:AddChild(_this);
				else
					-- item with only icon
					local _item = ParaUI.CreateUIObject("container", "statusBtn_"..node.AppCommand.name, "_rt", -(left+width), top, width, width)
					_item.background = defaultItemCont;
					_parent:AddChild(_item);
					
					_this = ParaUI.CreateUIObject("button", "icon", "_lt", 0, 0, width, width)
					_this.tooltip = node.AppCommand.tooltip;
					_this.animstyle = 12;
					if(node.AppCommand.icon)  then
						_this.background = node.AppCommand.icon;
					else
						_this.background = theme.DefaultAppIcon;
					end
					_this.onclick = string.format(";Map3DSystem.App.Commands.Call(%q);", node.AppCommand.name);
					_item:AddChild(_this);
				end
				
				left = left + statusItemWidth + 2;
			else
				bNoSpaceLeft = true;
			end	
			
			count = count + 1;
			-- 5 is maximum status bar icon number
			if(bNoSpaceLeft) then
				-- show extension button << using a popup menu control.
				AppTaskBar.StatusBarNode.ExtensionItemIndex = index;
				
				_this = ParaUI.CreateUIObject("button", "extBtn", "_rt", -(left+width), 5, 16, 16)
				_this.background = "Texture/3DMapSystem/Desktop/ext_left.png";
				_this.animstyle = 12;
				_this.onclick = ";Map3DSystem.UI.AppTaskBar.ShowStatusBarExtensionMenu();"
				_parent:AddChild(_this);
				break;
			end
		end	
	end
end

-- bring up a context menu for selecting extension items. 
function AppTaskBar.ShowQuickLaunchExtensionMenu(nLineIndex)
	local ctl = CommonCtrl.GetControl("quicklaunchbar.ExtensionMenu");
	if(ctl==nil)then
		ctl = CommonCtrl.ContextMenu:new{
			name = "quicklaunchbar.ExtensionMenu",
			width = 130,
			height = 150,
			DefaultIconSize = 24,
			DefaultNodeHeight = 26,
			container_bg = "Texture/3DMapSystem/Desktop/ExtensionMenu.png:8 8 8 8",
			AutoPositionMode = "_lb",
		};
	end
	local _this = ParaUI.GetUIObject(AppTaskBar.name):GetChild("quicklaunchbar"):GetChild("extBtn");
	if(_this:IsValid()) then
		local x,y,width,height = _this:GetAbsPosition();
		
		ctl.RootNode:ClearAllChildren();
		
		local index, node
		local LineNode = AppTaskBar.QuickLaunchBarNode:GetChild(nLineIndex)
		if(LineNode) then
			local nSize = LineNode:GetChildCount();
			for index = LineNode.ExtensionItemIndex, nSize do
				ctl.RootNode:AddChild(CommonCtrl.TreeNode:new(LineNode:GetChild(index)));
			end
		end
		ctl:Show(x, y);
	end	
end

-- bring up a context menu for selecting extension items. 
function AppTaskBar.ShowToolbarExtensionMenu()
	
	local ctl = CommonCtrl.GetControl("toolbar.ExtensionMenu");
	if(ctl==nil)then
		ctl = CommonCtrl.ContextMenu:new{
			name = "toolbar.ExtensionMenu",
			width = 130,
			height = 150,
			DefaultIconSize = 24,
			DefaultNodeHeight = 26,
			container_bg = "Texture/3DMapSystem/Desktop/ExtensionMenu.png:8 8 8 8",
			AutoPositionMode = "_lb",
			onclick = function(treeNode)
				AppTaskBar.OnClickToolbar(treeNode.index);
			end
		};
	end
	local _this=ParaUI.GetUIObject(AppTaskBar.name):GetChild("toolbar"):GetChild("extBtn");
	if(_this:IsValid()) then
		local x,y,width,height = _this:GetAbsPosition();
		
		ctl.RootNode:ClearAllChildren();
		
		local index, node
		local nSize = AppTaskBar.ToolbarNode:GetChildCount();
		for index = AppTaskBar.ToolbarNode.ExtensionItemIndex, nSize do
			ctl.RootNode:AddChild(CommonCtrl.TreeNode:new(AppTaskBar.ToolbarNode:GetChild(index)));
		end
		
		ctl:Show(x, y);
	end	
end

-- bring up a context menu for selecting extension items. 
function AppTaskBar.ShowStatusBarExtensionMenu()
	local ctl = CommonCtrl.GetControl("statusbar.ExtensionMenu");
	if(ctl==nil)then
		ctl = CommonCtrl.ContextMenu:new{
			name = "statusbar.ExtensionMenu",
			width = 130,
			height = 150,
			DefaultIconSize = 24,
			DefaultNodeHeight = 26,
			container_bg = "Texture/3DMapSystem/Desktop/ExtensionMenu.png:8 8 8 8",
			AutoPositionMode = "_lb",
		};
	end
	local _this=ParaUI.GetUIObject(AppTaskBar.name):GetChild("statusbar"):GetChild("extBtn");
	if(_this:IsValid()) then
		local x,y,width,height = _this:GetAbsPosition();
		
		ctl.RootNode:ClearAllChildren();
		
		local index, node
		local nSize = AppTaskBar.StatusBarNode:GetChildCount();
		for index = AppTaskBar.StatusBarNode.ExtensionItemIndex, nSize do
			ctl.RootNode:AddChild(CommonCtrl.TreeNode:new(AppTaskBar.StatusBarNode:GetChild(index)));
		end
		
		ctl:Show(x, y);
	end	
end