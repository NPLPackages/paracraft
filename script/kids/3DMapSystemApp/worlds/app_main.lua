--[[
Title: worlds app for Paraworld
Author(s): LiXizhi
Date: 2008/2/14
Desc: 
this is an official application to load, save, download, publish, join, host users' worlds

---++ File.Open.LoadWorld
open the load world dialog

---++ File.SaveAndPublish
open the save and publish world dialog

<verbatim>
	-- toggle show/hide
	Map3DSystem.App.Commands.Call("File.SaveAndPublish");
</verbatim>

---++ File.New.World
open the new world wizard dialog

---++ File.EnterWorld
Host and/or Join a given homeworld using the lobby server.
| *Property*	| *Descriptions*				 |
| worldpath		| the downloaded local world path from which to load the world |
| role			| the role of the current user that will join the world. values may be "guest", "administrator", "poweruser", "friend". If this is nil, it will be default to "guest" or "administrator" depending on the server type. |
| server		| if this is nil, it will be loaded as an offline world unless autolobby is specified. if it is like "jgsl://username@domain", it will login to the server according to server type. In most cases, it is JGSL. |
| autolobby		| if this is true, paraworld.lobby.* api will be used to either host or join an existing world with given worldpath.|

The return boolean value res is in input params.

*example*
<verbatim>
	-- load an ordinary offline world
	Map3DSystem.App.Commands.Call(Map3DSystem.App.Commands.GetLoadWorldCommand(), {worldpath = "worlds/Templates/Empty/smallisland"});
	-- load an downloaded online world and join or host using paraworld.lobby API. 
	local params = {worldpath = "worlds/Templates/Empty/smallisland", autolobby=true}
	Map3DSystem.App.Commands.Call(Map3DSystem.App.Commands.GetLoadWorldCommand(), params);
	if(params.res) then
		-- succeed
	end
</verbatim>



db registration insert script
INSERT INTO apps VALUES (NULL, 'worlds_GUID', 'worlds', '1.0.0', 'http://www.paraengine.com/apps/worlds_v1.zip', 'YourCompany', 'enUS', 'script/kids/3DMapSystemApp/worlds/IP.xml', '', 'script/kids/3DMapSystemApp/worlds/app_main.lua', 'Map3DSystem.App.worlds.MSGProc', 1);
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/worlds/app_main.lua");
------------------------------------------------------------
]]
local L = CommonCtrl.Locale("ParaWorld");


-- requires

-- create class
commonlib.setfield("Map3DSystem.App.worlds", {});

-- this is true, it will automatically connect to another server or create server on its own if current connection is lost. 
Map3DSystem.App.worlds.EnableAutoLobby = nil;
-------------------------------------------
-- event handlers
-------------------------------------------

-- OnConnection method is the obvious point to place your UI (menus, mainbars, tool buttons) through which the user will communicate to the app. 
-- This method is also the place to put your validation code if you are licensing the add-in. You would normally do this before putting up the UI. 
-- If the user is not a valid user, you would not want to put the UI into the IDE.
-- @param app: the object representing the current application in the IDE. 
-- @param connectMode: type of Map3DSystem.App.ConnectMode. 
function Map3DSystem.App.worlds.OnConnection(app, connectMode)
	if(connectMode == Map3DSystem.App.ConnectMode.UI_Setup) then
		-- place your UI (menus,toolbars, tool buttons) through which the user will communicate to the app
		-- e.g. MainBar.AddItem(), MainMenu.AddItem().
		
		-- e.g. Create a worlds command link in the main menu 
		local commandName = "File.Open.LoadWorld";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = L"加载3D世界", icon = "Texture/3DMapSystem/common/ViewFiles.png", });
			-- add command to mainmenu control, using the same folder as commandName. But you can use any folder you like
			local pos_category = commandName;
			-- add to front.
			command:AddControl("mainmenu", pos_category, 1);
			
			commandName = "File.Open.PersonalWorld";
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = L"我的星球", icon = "Texture/3DMapSystem/AppIcons/NewWorld_64.dds", });
			
			commandName = "File.Open.StarView";
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = L"星图", icon = "Texture/3DMapSystem/common/asterisk_orange.png", });

			commandName = "File.QuickSaveWorld";
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "Save World", icon = "Texture/3DMapSystem/common/save.png", });
				
			commandName = "Scene.Pasue";
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "Pause the Scene", });	
				
			commandName = "Scene.ToggleCamera";
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "Toggle camera", });		
				
			commandName = "Camera.LookAtShiftY_up";
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "look at up", });	
				
			commandName = "Camera.LookAtShiftY_down";
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "look at down", });	
				
			commandName = "Camera.ZoomIn";
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "zoom in", });	
				
			commandName = "Camera.ZoomOut";
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "zoom out", });		
				
			commandName = "Scene.FocusNextPlayer";
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "Focus Next Player", });		
										
			commandName = "File.SaveAndPublish";
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = L"保存 & 发布世界", icon = "Texture/3DMapSystem/common/save.png", });
			-- add command to mainmenu control, using the same folder as commandName. But you can use any folder you like
			pos_category = commandName;
			-- add to before group 2.
			command:AddControl("mainmenu", pos_category, Map3DSystem.App.Command.GetPosIndex("mainmenu", "File.Group2"));
			
			
			-- new world wizard
			commandName = "File.New.World";
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = L"新建世界向导", icon = "Texture/3DMapSystem/common/page_world.png", });
			-- add command to mainmenu control, using the same folder as commandName. But you can use any folder you like
			pos_category = commandName;
			-- add to before group 2.
			command:AddControl("mainmenu", pos_category);
			
			-- auto lobby page
			commandName = "File.AutoLobbyPage";       
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = L"世界服务器", icon = "Texture/3DMapSystem/common/transmit.png", });
		end
		
		local commandName = "File.Separator"
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, CommandStyle = Map3DSystem.App.CommandStyle.Separator,  });
		end	
		
		local commandName = "File.Separator1"
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, CommandStyle = Map3DSystem.App.CommandStyle.Separator,  });
		end
		
		-- hook into the "onsize" and update the main window
		CommonCtrl.os.hook.SetWindowsHook({hookType = CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 
			callback = Map3DSystem.App.worlds.Hook_GameMsg, 
			hookName = "GameMsgHook", appName = "scene", wndName = "game"});
		
	else
		-- place the app's one time initialization code here.
		-- during one time init, its message handler may need to update the app structure with static integration points, 
		-- i.e. app.about, HomeButtonText, HomeButtonText, HasNavigation, NavigationButtonText, HasQuickAction, QuickActionText,  See app template for more information.
		
		-- e.g. 
		app.about = "loading/saving publishing/downloading worlds"
		Map3DSystem.App.worlds.app = app; 
		app.HideHomeButton = true;
		app.Title = L"世界";
		app.icon = "Texture/3DMapSystem/AppIcons/NewWorld_64.dds"
		app.SubTitle = L"创建、发布3D世界向导";
		app:SetHelpPage("WelcomePage.html");
		
		NPL.load("(gl)script/kids/3DMapSystemApp/worlds/TeleportPortal.lua");
		
		--------------------------------------------
		-- add a desktop icons
		local commandName = "Offline.LoadWorld";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			--
			-- add a desktop icon in offline mode. 
			--
			commandName = "Offline.NewWorld";
			command = Map3DSystem.App.Commands.AddNamedCommand({name = commandName,app_key = app.app_key, 
				ButtonText = L"创建世界", icon = "Texture/3DMapSystem/AppIcons/NewWorld_64.dds", url="script/kids/3DMapSystemApp/worlds/NewWorldPage.html"});
			local pos_category = commandName;	
			command:AddControl("desktop", commandName);	
			
			commandName = "Offline.LoadWorld";
			command = Map3DSystem.App.Commands.AddNamedCommand({name = commandName,app_key = app.app_key, 
				ButtonText = L"载入世界", icon = "Texture/3DMapSystem/Worlds/LoadWorld_64.png", url="script/kids/3DMapSystemApp/worlds/PersonalWorldPage.html"});
			local pos_category = commandName;	
			command:AddControl("desktop", pos_category);
			
			--
			-- add a desktop icon in online mode. 
			--
			commandName = "Online.NewWorld";
			command = Map3DSystem.App.Commands.AddNamedCommand({name = commandName,app_key = app.app_key, 
				ButtonText = L"创建世界", icon = "Texture/3DMapSystem/AppIcons/NewWorld_64.dds", url="script/kids/3DMapSystemApp/worlds/NewWorldPage.html"});
			local pos_category = commandName;	
			command:AddControl("desktop", commandName);	
			
			commandName = "Online.LoadWorld";
			command = Map3DSystem.App.Commands.AddNamedCommand({name = commandName,app_key = app.app_key, 
				ButtonText = L"载入世界", icon = "Texture/3DMapSystem/Worlds/LoadWorld_64.png", url="script/kids/3DMapSystemApp/worlds/PersonalWorldPage.html"});
			local pos_category = commandName;	
			command:AddControl("desktop", pos_category);	
			
			--
			-- add common command 
			--
			commandName = "File.EnterWorld";
			command = Map3DSystem.App.Commands.AddNamedCommand({name = commandName,app_key = app.app_key, ButtonText = L"载入玩家家园世界"});
		end	
	end
end

-- Receives notification that the Add-in is being unloaded.
function Map3DSystem.App.worlds.OnDisconnection(app, disconnectMode)
	if(disconnectMode == Map3DSystem.App.DisconnectMode.UserClosed or disconnectMode == Map3DSystem.App.DisconnectMode.WorldClosed)then
		-- TODO: remove all UI elements related to this application, since the IDE is still running. 
		
		-- e.g. remove command from mainbar
		local command = Map3DSystem.App.Commands.GetCommand("File.Open.LoadWorld");
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
function Map3DSystem.App.worlds.OnQueryStatus(app, commandName, statusWanted)
	if(statusWanted == Map3DSystem.App.CommandStatusWanted) then
		-- TODO: return an integer by adding values in Map3DSystem.App.CommandStatus.
		return (Map3DSystem.App.CommandStatus.Enabled + Map3DSystem.App.CommandStatus.Supported)
	end
end

-- nil FollowMode, 1 FreeCameraMode. Used by the C key
local LastCameraMode = nil; 

-- This is called when the command is invoked.The Exec is fired after the QueryStatus event is fired, assuming that the return to the statusOption parameter of QueryStatus is supported and enabled. 
-- This is the event where you place the actual code for handling the response to the user click on the command.
-- @param commandName: The name of the command to determine state for. Usually in the string format "Category.SubCate.Name".
function Map3DSystem.App.worlds.OnExec(app, commandName, params)
	if(commandName == "File.Open.LoadWorld") then
		Map3DSystem.App.Commands.Call("File.MCMLBrowser", {url="script/kids/3DMapSystemApp/worlds/LoadWorldPage.html", name="LoadWorldPage", title=L"加载3D世界"});
		
	elseif(commandName == "File.SaveAndPublish") then
		-- show the save and publish page. 
		Map3DSystem.App.Commands.Call("File.MCMLWindowFrame", {
			url="script/kids/3DMapSystemApp/worlds/PublishWorldPage.html", name="PublishWorldPage", 
			app_key = app.app_key, 
			bToggleShowHide = true,
			icon = "Texture/3DMapSystem/common/save.png",
			text = L"保存&发布世界",
			DestroyOnClose = true,
			directPosition = true,
				align = "_ct",
				x = -510/2,
				y = -340/2,
				width = 510,
				height = 340,
		});
	elseif(commandName == "File.QuickSaveWorld") then
		-- full save the world
		commonlib.applog("world is quick-saved")
		local disable_save;
		if(Map3DSystem.SystemInfo) then
			if(Map3DSystem.SystemInfo.GetField("name") == "Aries") then
				disable_save = true;
			end
		end
		if(not disable_save) then
			Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.SCENE_SAVE})
		else
			LOG.std(nil, "info", "File.QuickSaveWorld", "quick save world is disabled.")
		end
	
	elseif(commandName == "Scene.Pasue") then
		-- usually the alt + 'P' key to pause/resume the game
		if(ParaScene.IsScenePaused() == true) then
			ParaScene.PauseScene(false);
			autotips.AddTips("pause", nil)
		else
			ParaScene.PauseScene(true);
			autotips.AddTips("pause", "程序被暂停了. 请按 Alt + P 键继续程序")
		end	
	
	elseif(commandName == "Scene.FocusNextPlayer") then
		-- usually Alt +  '0' key to cycle player. 
		ParaScene.TogglePlayer();
		
	elseif(commandName == "Scene.ToggleCamera") then
		-- usually the Ctrl + Alt + 'C' key to change to camera follow mode
		if(LastCameraMode==nil) then
			ParaCamera.GetAttributeObject():CallField("FreeCameraMode");
			autotips.AddTips("camera", "您进入了自由摄影机模式. 请按 Ctrl+Alt+C 键返回跟随摄影机模式")
			
			LastCameraMode = 1;
		else	
			ParaCamera.GetAttributeObject():CallField("FollowMode");
			LastCameraMode = nil;
			autotips.AddTips("camera", nil)
		end	
	elseif(commandName == "Camera.LookAtShiftY_up") then
		local last_value = ParaCamera.GetAttributeObject():GetField("LookAtShiftY", 0);
		ParaCamera.GetAttributeObject():SetField("LookAtShiftY", last_value+0.03);
		
	elseif(commandName == "Camera.LookAtShiftY_down") then
		local last_value = ParaCamera.GetAttributeObject():GetField("LookAtShiftY", 0);
		ParaCamera.GetAttributeObject():SetField("LookAtShiftY", last_value-0.03);
		
	elseif(commandName == "Camera.ZoomIn") then
		local last_value = ParaCamera.GetAttributeObject():GetField("CameraObjectDistance", 0)*0.9;
		if(last_value > 20) then last_value=20 end
		if(last_value < 2) then last_value=2 end
		ParaCamera.GetAttributeObject():SetField("CameraObjectDistance", last_value);
		
	elseif(commandName == "Camera.ZoomOut") then
		local last_value = ParaCamera.GetAttributeObject():GetField("CameraObjectDistance", 0)*1.1;
		if(last_value > 20) then last_value=20 end
		if(last_value < 2) then last_value=2 end
		ParaCamera.GetAttributeObject():SetField("CameraObjectDistance", last_value);
	
	elseif(commandName == "File.New.World") then
		--Map3DSystem.App.Commands.Call("File.MCMLBrowser", {url="script/kids/3DMapSystemApp/worlds/NewWorldPage.html", name="NewWorldPage", title=L"新建3D世界"});
		Map3DSystem.App.Commands.Call("File.MCMLWindowFrame", {name="PersonalWorld", 
			url="script/kids/3DMapSystemApp/worlds/NewWorldPage.html", 
			app_key = app.app_key, 
			DestroyOnClose = true,
			icon = "Texture/3DMapSystem/common/page_world.png",
			text = L"新建3D世界",
			directPosition = true,
				align = "_ct",
				x = -1020/2,
				y = -500/2,
				width = 1020,
				height = 500,
		});
	elseif(commandName == "File.Open.StarView") then
		Map3DSystem.App.Commands.Call("File.MCMLWindowFrame", {name="PersonalWorld", 
			url="script/kids/3DMapSystemApp/worlds/StarViewPage.html", 
			app_key = app.app_key, 
			DestroyOnClose = true,
			icon = "Texture/3DMapSystem/common/ViewFiles.png",
			text = L"星图",
			directPosition = true,
				align = "_ct",
				x = -1020/2,
				y = -500/2,
				width = 1020,
				height = 500,
		});
		
	elseif(commandName == "File.Open.PersonalWorld") then
		Map3DSystem.App.Commands.Call("File.MCMLWindowFrame", {name="PersonalWorld", 
			url="script/kids/3DMapSystemApp/worlds/PersonalWorldPage.html", 
			app_key = app.app_key, 
			DestroyOnClose = true,
			icon = "Texture/3DMapSystem/common/ViewFiles.png",
			text = L"我的星球",
			directPosition = true,
				align = "_ct",
				x = -1020/2,
				y = -500/2,
				width = 1020,
				height = 500,
		});
	
	elseif(commandName == "File.EnterWorld") then
		if(type(params) ~= "table" or params.worldpath == nil) then return end
		ParaNetwork.EnableNetwork(false, "","");
		local res = Map3DSystem.LoadWorld(params.worldpath);
		params.res = res;
		if(res==true) then
			-- Do something after the load	
			if(not params.role) then
				-- no role is specified. 
				if(Map3DSystem.World.readonly) then
					Map3DSystem.User.SetRole("poweruser");
				else
					Map3DSystem.User.SetRole("administrator");
				end
			else
				-- role is specified. 
				Map3DSystem.User.SetRole(params.role);
				if(params.role == "administrator") then
					if(Map3DSystem.World.readonly) then
						Map3DSystem.User.SetRole("poweruser");
					end
				end
			end
			
			-- when client and server connect, they must exchange their session keys. By regenerating session keys, we 
			-- will reject any previous established JGSL game connections. we need to regenerate session when we load a different world.
			NPL.load("(gl)script/kids/3DMapSystemNetwork/JGSL.lua");
			Map3DSystem.JGSL.Reset();
			
			if(params.server or params.autolobby) then
				if(Map3DSystem.JGSL.GetJC() == nil) then
					Map3DSystem.SendMessage_game({type = Map3DSystem.msg.GAME_LOG, text=L"还没有建立同游戏服务的链接, 请稍候尝试连接"})
					return 
				end 
			end	
			
			if(params.autolobby) then
				-- if lobby is on,  paraworld.lobby.* api will be used to either host or join an existing world with given worldpath
				-- connect to the lobby server
				Map3DSystem.App.worlds.EnableAutoLobby = params.autolobby;
			
				if(not params.uid or not params.server) then	
					NPL.load("(gl)script/kids/3DMapSystemApp/worlds/AutoLobbyPage.lua");
					Map3DSystem.App.worlds.AutoLobbyPage.Reset();
					Map3DSystem.App.worlds.AutoLobbyPage.AutoJoinRoom();
				end	
			elseif(params.uid or params.server) then
				if(not string.match(params.server, "^%w+://")) then
					params.server = "jgsl://"..params.server; -- this allow input to ignore jgsl:// header
				end
				NPL.load("(gl)script/kids/3DMapSystemApp/worlds/AutoLobbyPage.lua");
				Map3DSystem.App.worlds.AutoLobbyPage.Reset();
				Map3DSystem.App.worlds.AutoLobbyPage.JoinRoom(params.uid, params.server)
			end	
		
		elseif(type(res) == "string") then
			-- show the error message
			_guihelper.MessageBox(res);
		end
	elseif(commandName == "File.AutoLobbyPage") then
		-- show the auto lobby panel
		Map3DSystem.App.Commands.Call("File.MCMLWindowFrame", {
			url="script/kids/3DMapSystemApp/worlds/AutoLobbyPage.html", name="AutoLobbyPage", 
			app_key = app.app_key, 
			DestroyOnClose = true,
			icon = "Texture/3DMapSystem/common/transmit.png",
			text = L"连接",
			directPosition = true,
				align = "_rt",
				x = -370,
				y = 0,
				width = 370,
				height = 600,
			--initialPosX = 450, 
			--initialPosY = 20, 
			--initialWidth = 400, -- initial width of the window client area
			--initialHeight = 570, -- initial height of the window client area
		});
	elseif(app:IsHomepageCommand(commandName)) then
		Map3DSystem.App.worlds.GotoHomepage();
	elseif(app:IsNavigationCommand(commandName)) then
		Map3DSystem.App.worlds.Navigate();
	elseif(app:IsQuickActionCommand(commandName)) then	
		Map3DSystem.App.worlds.DoQuickAction();
	end
end

-- Change and render the 3D world with mcml data that is usually retrieved from the current user's profile page for this application. 
function Map3DSystem.App.worlds.OnRenderBox(mcmlData)
end


-- called when the user wants to nagivate to the 3D world location relavent to this application
function Map3DSystem.App.worlds.Navigate()
end

-- called when user clicks to check out the homepage of this application. Homepage usually includes:
-- developer info, support, developer worlds information, app global news, app updates, all community user rating, active users, trade, currency transfer, etc. 
function Map3DSystem.App.worlds.GotoHomepage()
end

-- called when user clicks the quick action for this application. 
function Map3DSystem.App.worlds.DoQuickAction()
end

-- return true, if this application does not allow immediate closing. Such as asking the user to save the current modified world. 
function Map3DSystem.App.worlds.OnWorldClosing()
	-- check to see if we need to show the save and publish world page. If so return true and display the publish world wizard. 
	
	--if( Map3DSystem.App.worlds.confirmed==nil and Map3DSystem.User.HasRight("Save") and ParaTerrain.IsModified() )then
		--Map3DSystem.App.worlds.confirmed = true;
		--_guihelper.MessageBox("您刚刚对世界做了修改, 是否现在保存修改?")
		--return true;
	--end
end


-- Add terrain, sky and ocean button to the toolbar. 
function Map3DSystem.App.worlds.OnActivateDesktop()
	Map3DSystem.UI.AppTaskBar.AddCommand("File.New.World");
	
	Map3DSystem.UI.AppTaskBar.AddCommand("File.Separator")
	
	Map3DSystem.UI.AppTaskBar.AddCommand("File.Open.StarView");
	Map3DSystem.UI.AppTaskBar.AddCommand("File.Open.PersonalWorld");
	
	Map3DSystem.UI.AppTaskBar.AddCommand("File.Separator1")
	
	Map3DSystem.UI.AppTaskBar.AddCommand("File.SaveAndPublish");
	--Map3DSystem.UI.AppTaskBar.AddCommand("Profile.VisitWorld");
	
	--Map3DSystem.App.Commands.Call("File.WelcomePage", {url="script/kids/3DMapSystemApp/worlds/WelcomePage.html"})
	
	autotips.AddIdleTips(L"你可以从别人创建的世界中派生自己的世界")
	autotips.AddIdleTips(L"你需要发布世界, 其他玩家才能进入你的世界和你共同创造交流")
	autotips.AddIdleTips(L"请经常保存您的世界")
end

function Map3DSystem.App.worlds.OnDeactivateDesktop()
end


-- hook to game msg so that we get informed of server connections. 
function Map3DSystem.App.worlds.Hook_GameMsg(nCode, appName, msg)
	if(msg.type == Map3DSystem.msg.GAME_JGSL_SIGNEDIN) then
		-- connection to remote server is established. 
	elseif(msg.type == Map3DSystem.msg.GAME_JOIN_JGSL) then	
		
	elseif(msg.type == Map3DSystem.msg.GAME_JGSL_SIGNEDOUT) then
		-- user signed out. 
	elseif(msg.type == Map3DSystem.msg.GAME_JGSL_SERVER_ERROR or msg.type == Map3DSystem.msg.GAME_JGSL_CONNECTION_TIMEOUT) then
		commonlib.log("remote connection closed or timed out\n")
		-- if connection to server is lost and autolobby is enabled, we will reconnect. 
		if(Map3DSystem.App.worlds.EnableAutoLobby) then
			NPL.load("(gl)script/kids/3DMapSystemApp/worlds/AutoLobbyPage.lua");
			Map3DSystem.App.worlds.AutoLobbyPage.AutoJoinRoom();
		end
	elseif(msg.type == Map3DSystem.msg.GAME_JGSL_USER_COME) then
		
	elseif(msg.type == Map3DSystem.msg.GAME_JGSL_USER_LEAVE) then
	end
	return nCode
end


-------------------------------------------
-- client world database function helpers.
-------------------------------------------

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
function Map3DSystem.App.worlds.MSGProc(window, msg)
	----------------------------------------------------
	-- application plug-in messages here
	----------------------------------------------------
	if(msg.type == Map3DSystem.App.MSGTYPE.APP_CONNECTION) then	
		-- Receives notification that the Add-in is being loaded.
		Map3DSystem.App.worlds.OnConnection(msg.app, msg.connectMode);
		
	elseif(msg.type == Map3DSystem.App.MSGTYPE.APP_DISCONNECTION) then	
		-- Receives notification that the Add-in is being unloaded.
		Map3DSystem.App.worlds.OnDisconnection(msg.app, msg.disconnectMode);

	elseif(msg.type == Map3DSystem.App.MSGTYPE.APP_QUERY_STATUS) then
		-- This is called when the command's availability is updated. 
		-- NOTE: this function returns a result. 
		msg.status = Map3DSystem.App.worlds.OnQueryStatus(msg.app, msg.commandName, msg.statusWanted);
		
	elseif(msg.type == Map3DSystem.App.MSGTYPE.APP_EXEC) then
		-- This is called when the command is invoked.
		Map3DSystem.App.worlds.OnExec(msg.app, msg.commandName, msg.params);
				
	elseif(msg.type == Map3DSystem.App.MSGTYPE.APP_RENDER_BOX) then	
		-- Change and render the 3D world with mcml data that is usually retrieved from the current user's profile page for this application. 
		Map3DSystem.App.worlds.OnRenderBox(msg.mcml);
		
	elseif(msg.type == Map3DSystem.App.MSGTYPE.APP_NAVIGATION) then
		-- Receives notification that the user wants to nagivate to the 3D world location relavent to this application
		Map3DSystem.App.worlds.Navigate();
	
	elseif(msg.type == Map3DSystem.App.MSGTYPE.APP_HOMEPAGE) then
		-- called when user clicks to check out the homepage of this application. 
		Map3DSystem.App.worlds.GotoHomepage();
	
	elseif(msg.type == Map3DSystem.App.MSGTYPE.APP_QUICK_ACTION) then
		-- called when user clicks the quick action for this application. 
		Map3DSystem.App.worlds.DoQuickAction();
	
	elseif(msg.type == Map3DSystem.App.MSGTYPE.APP_ACTIVATE_DESKTOP) then
		Map3DSystem.App.worlds.OnActivateDesktop();
		
	elseif(msg.type == Map3DSystem.App.MSGTYPE.APP_DEACTIVATE_DESKTOP) then
		Map3DSystem.App.worlds.OnDeactivateDesktop();
			
	elseif(msg.type == Map3DSystem.App.MSGTYPE.APP_WORLD_CLOSING) then
		msg.DisableClosing = Map3DSystem.App.worlds.OnWorldClosing();
	
	----------------------------------------------------
	-- normal windows messages here
	----------------------------------------------------
	elseif(msg.type == CommonCtrl.os.MSGTYPE.WM_CLOSE) then
		
		
	elseif(msg.type == CommonCtrl.os.MSGTYPE.WM_SIZE) then
		
		
	elseif(msg.type == CommonCtrl.os.MSGTYPE.WM_HIDE) then
		
		
	elseif(msg.type == CommonCtrl.os.MSGTYPE.WM_SHOW) then
		
	end
end