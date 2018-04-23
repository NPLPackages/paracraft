--[[
Title: ScreenShot app for Paraworld
Author(s): LiXizhi
Date: 2008/1/5
Desc: 
db registration insert script
INSERT INTO apps VALUES (NULL, 'ScreenShot_GUID', 'ScreenShot', '1.0.0', 'http://www.paraengine.com/apps/ScreenShot_v1.zip', 'YourCompany', 'enUS', 'script/kids/3DMapSystemUI/ScreenShot/IP.xml', '', 'script/kids/3DMapSystemUI/ScreenShot/app_main.lua', 'MyCompany.Apps.ScreenShot.MSGProc', 1);
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/ScreenShot/app_main.lua");
------------------------------------------------------------
]]
local L = CommonCtrl.Locale("ParaWorld");


-- requires

-- create class
commonlib.setfield("MyCompany.Apps.ScreenShot", {});

-------------------------------------------
-- event handlers
-------------------------------------------

-- OnConnection method is the obvious point to place your UI (menus, mainbars, tool buttons) through which the user will communicate to the app. 
-- This method is also the place to put your validation code if you are licensing the add-in. You would normally do this before putting up the UI. 
-- If the user is not a valid user, you would not want to put the UI into the IDE.
-- @param app: the object representing the current application in the IDE. 
-- @param connectMode: type of Map3DSystem.App.ConnectMode. 
function MyCompany.Apps.ScreenShot.OnConnection(app, connectMode)
	if(connectMode == Map3DSystem.App.ConnectMode.UI_Setup) then
		-- place your UI (menus,toolbars, tool buttons) through which the user will communicate to the app
		-- e.g. MainBar.AddItem(), MainMenu.AddItem().
		
		-- e.g. Create a ScreenShot command link in the main menu 
		local commandName = "File.ScreenShot";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = L"快速截图 (F11)", icon = "Texture/3DMapSystem/common/page_white_camera.png", });
			-- add command to mainmenu control, using the same folder as commandName. But you can use any folder you like
			local pos_category = commandName;
			
			-- insert after File.Group2.
			local index = Map3DSystem.UI.MainMenu.GetItemIndex("File.Group2");
			if(index ~= nil) then
				index = index+1;
			end
			command:AddControl("mainmenu", pos_category, index);
		end
			
		local commandName = "File.Separator"
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, CommandStyle = Map3DSystem.App.CommandStyle.Separator,  });
		end		
		local commandName = "ScreenShot.HideAllUI"
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, CommandStyle = Map3DSystem.App.CommandStyle.Separator,  });
		end	
	else
		-- place the app's one time initialization code here.
		-- during one time init, its message handler may need to update the app structure with static integration points, 
		-- i.e. app.about, HomeButtonText, HomeButtonText, HasNavigation, NavigationButtonText, HasQuickAction, QuickActionText,  See app template for more information.
		
		MyCompany.Apps.ScreenShot.app = app;
		app.HideHomeButton = true;
		app.about =  "screen shot applications"
		app.Title = L"电影与截图";
		app.icon = "Texture/3DMapSystem/AppIcons/VideoRecorder_64.dds"
		app.SubTitle = L"电影拍摄,屏幕截图";
		app:SetSettingPage("SnapshotPage.html?tab=setting", L"屏幕截图");
		app:SetHelpPage("WelcomePage.html");
		
		local hook = CommonCtrl.os.hook.SetWindowsHook({hookType=CommonCtrl.os.hook.HookType.WH_CALLWNDPROC, 
		callback = MyCompany.Apps.ScreenShot.OnKeyDownProc, hookName = "screenshot", appName="input", wndName = "key_down"});
	end
end

-- Receives notification that the Add-in is being unloaded.
function MyCompany.Apps.ScreenShot.OnDisconnection(app, disconnectMode)
	if(disconnectMode == Map3DSystem.App.DisconnectMode.UserClosed or disconnectMode == Map3DSystem.App.DisconnectMode.WorldClosed)then
		-- TODO: remove all UI elements related to this application, since the IDE is still running. 
		
		-- e.g. remove command from mainbar
		local command = Map3DSystem.App.Commands.GetCommand("File.ScreenShot");
		if(command == nil) then
			command:Delete();
		end
	end
	-- TODO: just release any resources at shutting down. 
end

-- This is called when the command's availability is updated
-- When the user clicks a command (menu or mainbar button), the QueryStatus event is fired. 
-- The QueryStatus event returns the current status of the specified named command, whether it is enabled, disabled, 
-- or hidden in the CommandStatus parameter, which is passed to the msg by reference (or returned in the event handler). 
-- @param commandName: The name of the command to determine state for. Usually in the string format "Category.SubCate.Name".
-- @param statusWanted: what status of the command is queried. it is of type Map3DSystem.App.CommandStatusWanted
-- @return: returns according to statusWanted. it may return an integer by adding values in Map3DSystem.App.CommandStatus.
function MyCompany.Apps.ScreenShot.OnQueryStatus(app, commandName, statusWanted)
	if(statusWanted == Map3DSystem.App.CommandStatusWanted) then
		-- TODO: return an integer by adding values in Map3DSystem.App.CommandStatus.
		if(commandName == "File.ScreenShot") then
			-- return enabled and supported 
			return (Map3DSystem.App.CommandStatus.Enabled + Map3DSystem.App.CommandStatus.Supported)
		end
	end
end

-- This is called when the command is invoked.The Exec is fired after the QueryStatus event is fired, assuming that the return to the statusOption parameter of QueryStatus is supported and enabled. 
-- This is the event where you place the actual code for handling the response to the user click on the command.
-- @param commandName: The name of the command to determine state for. Usually in the string format "Category.SubCate.Name".
function MyCompany.Apps.ScreenShot.OnExec(app, commandName, params)
	
	if(commandName == "File.ScreenShot") then
		-- actual code of processing the command goes here. 
		--Map3DSystem.App.Commands.Call("File.MCMLBrowser", {url="script/kids/3DMapSystemUI/ScreenShot/SnapshotPage.html", name="SnapshotPage", title=L"屏幕截图", left=0, top=50, width=265, height=500, zorder=4});
		Map3DSystem.App.Commands.Call("File.MCMLWindowFrame", {
			url="script/kids/3DMapSystemUI/ScreenShot/SnapshotPage.html", name="SnapshotPage", 
			app_key=app.app_key, 
			text = L"屏幕截图",
			icon = "Texture/3DMapSystem/common/page_white_camera.png",
			isShowTitleBar = true, 
			allowResize = false,
			initialPosX = 0,
			initialPosY = 70,
			initialWidth = 265,
			initialHeight = 500,
			bToggleShowHide = true,
		});
	elseif(app:IsHomepageCommand(commandName)) then
		MyCompany.Apps.ScreenShot.GotoHomepage();
	elseif(app:IsNavigationCommand(commandName)) then
		MyCompany.Apps.ScreenShot.Navigate();
	elseif(app:IsQuickActionCommand(commandName)) then	
		MyCompany.Apps.ScreenShot.DoQuickAction();
	elseif(commandName == "ScreenShot.HideAllUI") then
		MyCompany.Apps.ScreenShot.HideAllUI();
	end
end

-- Change and render the 3D world with mcml data that is usually retrieved from the current user's profile page for this application. 
function MyCompany.Apps.ScreenShot.OnRenderBox(mcmlData)
end


-- called when the user wants to nagivate to the 3D world location relavent to this application
function MyCompany.Apps.ScreenShot.Navigate()
end

-- called when user clicks to check out the homepage of this application. Homepage usually includes:
-- developer info, support, developer worlds information, app global news, app updates, all community user rating, active users, trade, currency transfer, etc. 
function MyCompany.Apps.ScreenShot.GotoHomepage()
end

-- called when user clicks the quick action for this application. 
function MyCompany.Apps.ScreenShot.DoQuickAction()
end

local is_hide_ui = false;
function MyCompany.Apps.ScreenShot.HideAllUI()
	if(is_hide_ui)then
		is_hide_ui = false;
		ParaUI.ShowCursor(true);
		ParaUI.GetUIObject("root").visible = true;
		--ParaScene.EnableMiniSceneGraph(true);
	else
		is_hide_ui = true;
		ParaUI.GetUIObject("root").visible = false;
		ParaUI.ShowCursor(false);
		--ParaScene.EnableMiniSceneGraph(false);
		ParaEngine.ForceRender();ParaEngine.ForceRender(); 
	end
end
function MyCompany.Apps.ScreenShot.ShowAllUI()
	if(is_hide_ui)then
		MyCompany.Apps.ScreenShot.HideAllUI();
	end
end
-- Not used (just provide an example): key down callback. Hook for F11 key.
function MyCompany.Apps.ScreenShot.OnKeyDownProc(nCode, appName, msg)
	-- return the nCode to be passed to the next hook procedure in the hook chain. 
	-- in most cases, if nCode is nil, the hook procedure should do nothing. 
	if(nCode==nil) then return end
	
	--if(msg.virtual_key == Event_Mapping.EM_KEY_F11) then
		--nCode = nil;
		--NPL.load("(gl)script/kids/3DMapSystemUI/ScreenShot/SnapshotPage.lua");
		---- take screen shot
		--local filename = "Screen Shots/Snapshot_"..ParaGlobal.GenerateUniqueID()..".jpg";
		--local IncludeUI = MyCompany.Apps.ScreenShot.app:ReadConfig("IncludeUI", false)
		--local resolution = MyCompany.Apps.ScreenShot.app:ReadConfig("ImageResolution", "")
		--local width, height;
		--if(resolution~=nil and resolution~="") then
			--width = tonumber(MyCompany.Apps.ScreenShot.app:ReadConfig("SnapshotWidth", 600))
			--height = tonumber(MyCompany.Apps.ScreenShot.app:ReadConfig("SnapshotHeight", 400))
		--end
	--
		--if(not MyCompany.Apps.ScreenShot.SnapshotPage.TakeSnapshot(filename, width, height, IncludeUI)) then
			--_guihelper.MessageBox(L"无法保存截图");
		--end
	--end	
	if(msg.virtual_key == Event_Mapping.EM_KEY_ESCAPE) then
		if(is_hide_ui)then
			MyCompany.Apps.ScreenShot.HideAllUI();
		end
	end
	return nCode
end

function MyCompany.Apps.ScreenShot.OnActivateDesktop()
	--Map3DSystem.UI.AppTaskBar.AddCommand("File.NewMovie")
	Map3DSystem.UI.AppTaskBar.AddCommand("File.MovieList")
	Map3DSystem.UI.AppTaskBar.AddCommand("File.MovieAssets")
	
	Map3DSystem.UI.AppTaskBar.AddCommand("File.Separator")
	
	Map3DSystem.UI.AppTaskBar.AddCommand("File.ScreenShot")
	--Map3DSystem.UI.AppTaskBar.AddCommand("File.ScreenShot"):Call();
	Map3DSystem.UI.AppTaskBar.AddCommand("File.VideoRecorder")
	--Map3DSystem.UI.AppTaskBar.AddCommand("Profile.CCS.FaceCamera");
	--Map3DSystem.App.Commands.Call("File.WelcomePage", {url="script/kids/3DMapSystemUI/ScreenShot/WelcomePage.html"})
end

------------------------------------------
-- all related messages
------------------------------------------
-----------------------------------------------------
-- APPS can be invoked in many ways: 
--	Through app Manager 
--	mainbar or menu command or buttons
--	Command Line 
--  3D World installed apps
-----------------------------------------------------
function MyCompany.Apps.ScreenShot.MSGProc(window, msg)
	----------------------------------------------------
	-- application plug-in messages here
	----------------------------------------------------
	if(msg.type == Map3DSystem.App.MSGTYPE.APP_CONNECTION) then	
		-- Receives notification that the Add-in is being loaded.
		MyCompany.Apps.ScreenShot.OnConnection(msg.app, msg.connectMode);
		
	elseif(msg.type == Map3DSystem.App.MSGTYPE.APP_DISCONNECTION) then	
		-- Receives notification that the Add-in is being unloaded.
		MyCompany.Apps.ScreenShot.OnDisconnection(msg.app, msg.disconnectMode);

	elseif(msg.type == Map3DSystem.App.MSGTYPE.APP_QUERY_STATUS) then
		-- This is called when the command's availability is updated. 
		-- NOTE: this function returns a result. 
		msg.status = MyCompany.Apps.ScreenShot.OnQueryStatus(msg.app, msg.commandName, msg.statusWanted);
		
	elseif(msg.type == Map3DSystem.App.MSGTYPE.APP_EXEC) then
		-- This is called when the command is invoked.
		MyCompany.Apps.ScreenShot.OnExec(msg.app, msg.commandName, msg.params);
				
	elseif(msg.type == Map3DSystem.App.MSGTYPE.APP_RENDER_BOX) then	
		-- Change and render the 3D world with mcml data that is usually retrieved from the current user's profile page for this application. 
		MyCompany.Apps.ScreenShot.OnRenderBox(msg.mcml);
		
	elseif(msg.type == Map3DSystem.App.MSGTYPE.APP_NAVIGATION) then
		-- Receives notification that the user wants to nagivate to the 3D world location relavent to this application
		MyCompany.Apps.ScreenShot.Navigate();
	
	elseif(msg.type == Map3DSystem.App.MSGTYPE.APP_HOMEPAGE) then
		-- called when user clicks to check out the homepage of this application. 
		MyCompany.Apps.ScreenShot.GotoHomepage();
	
	elseif(msg.type == Map3DSystem.App.MSGTYPE.APP_QUICK_ACTION) then
		-- called when user clicks the quick action for this application. 
		MyCompany.Apps.ScreenShot.DoQuickAction();
		
	elseif(msg.type == Map3DSystem.App.MSGTYPE.APP_ACTIVATE_DESKTOP) then
		MyCompany.Apps.ScreenShot.OnActivateDesktop();
	
	----------------------------------------------------
	-- normal windows messages here
	----------------------------------------------------
	elseif(msg.type == CommonCtrl.os.MSGTYPE.WM_CLOSE) then
		
		
	elseif(msg.type == CommonCtrl.os.MSGTYPE.WM_SIZE) then
		
		
	elseif(msg.type == CommonCtrl.os.MSGTYPE.WM_HIDE) then
		
		
	elseif(msg.type == CommonCtrl.os.MSGTYPE.WM_SHOW) then
		
	end
end