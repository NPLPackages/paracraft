--[[
Title: Aries app_main
Author(s):  WangTian, LiXizhi
Company: ParaEngine
Date: 2009/4/7
Desc: Project Aries app_main

---++ Profile.Aries.Restart
| *name* | *value* |
| method | if "soft", we will just restart without killing the process. if "hard" or nil, it will restart the hard way by killing the software |
| startup_msg | nil, or a string of message to shown in the message box after restart. It can also be a table {autorecover=true, last_user_nid=string, gs_nid=string, ws_id=string}, where we will automatically signin as the given user to the given server. |
Map3DSystem.App.Commands.Call("Profile.Aries.Restart", {method="soft"});

---++ Profile.Aries.OnCloseApp
Map3DSystem.App.Commands.Call("Profile.Aries.OnCloseApp");

---++ File.EnterAriesWorld
The default load world command. 
| *name* | *value* |
| name | name of the worlds as defined in AriesGameWorlds.config.xml file. this will be used to locate the worldpath, so that the wordlpath can be omitted.  |
| worldpath | defaults to official world. |
| world_size| the movable region, if nil, it will be infinite | 
| tag		| if "MyLocalWorld", it will be local world, if "Tutorial", it will be a standalone world | 
| role		| role of the signed in user.  | 
| movie		| the initial movie script to play | 
| loader_movie_file | the movie to play during asset loading. |
| PosX,PosY,PosZ | the initial character position |
| PosRadius | a radius around PosX,PosY,PosZ that will be used as the random born pos | 
| bIsLocal | whether this is a local world that should not connect with game server |
| nid | if there is nid, it will be dispatched to a global home server, unless is_local_instance is true |
| is_local_instance | boolean, force using grid node of the current world thread on the server side. Good for single player game world. |
| room_key | any string or number key, that all clients must have in order to login to a given world. |
| create_join | true, if we want the server to automatically pick a free server for us. |
| match_info | a table containing the match_info to be forwarded to gridnode.  |
| mode | nil or [1,3] the difficulty level for instanced world in case the server support multple difficulties. |

---++ Profile.Aries.SysCommandLine
The default system command line command. 

params is the command line string, which must end with "paraenginearies://(.*)[/]?"
That trailing part is called URL command. which can be ";" separated name, value pairs, such as "paraenginearies://nid=79012120;worldpath=ABC;"
supported name values in the URL command line is.
| *name* | *value* |
| nid	| the user nid of which homeland to visit. |
| worldpath	| optional fields of world path. |

Please note that we will init a one time SysCommandLine 5 seconds after we signed in to a given world if there is one on the application command line. 
The windows registry key, value to start SysCommandLine is following. we usually redirect to development path during debugging
| *name* | *value* |
| HKEY_CLASSES_ROOT\paraenginearies\shell\open\command | "D:\lxzsrc\ParaEngine\ParaWorld\ParaEngineClient.exe" single="true" bootstrapper="script/apps/Aries/bootstrapper.xml" %1 |

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/app_main.lua");
------------------------------------------------------------
]]
-- requires
if(not System.options.mc) then
	NPL.load("(gl)script/apps/Aries/Desktop/AriesDesktop.lua");
	NPL.load("(gl)script/apps/Aries/VIP/main.lua");
	NPL.load("(gl)script/apps/Aries/Player/main.lua");
	NPL.load("(gl)script/apps/Aries/CombatRoom/LobbyClient.lua");
	NPL.load("(gl)script/apps/Aries/Quest/QuestClientLogics.lua");
	NPL.load("(gl)script/apps/Aries/Login/WorldAssetPreloader.lua");
	NPL.load("(gl)script/apps/Aries/Scene/AutoCameraController.lua");
	NPL.load("(gl)script/apps/Aries/Team/TeamClientLogics.lua");
	NPL.load("(gl)script/apps/Aries/Partners/PartnerPlatforms.lua");
	NPL.load("(gl)script/apps/Aries/Movie/ReplayMode.lua");
	NPL.load("(gl)script/kids/3DMapSystemApp/Assets/AssetManager.lua");
end

NPL.load("(gl)script/ide/EventDispatcher.lua");
NPL.load("(gl)script/ide/FileLoader.lua");
NPL.load("(gl)script/kids/3DMapSystemUI/MiniGames/SwfLoadingBarPage.lua");
NPL.load("(gl)script/ide/TooltipHelper.lua");
NPL.load("(gl)script/apps/Aries/Scene/WorldManager.lua");
local QuestClientLogics = commonlib.gettable("MyCompany.Aries.Quest.QuestClientLogics");
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local AutoCameraController = commonlib.gettable("MyCompany.Aries.AutoCameraController");
local TeamClientLogics = commonlib.gettable("MyCompany.Aries.Team.TeamClientLogics");
local FileLoader = commonlib.gettable("CommonCtrl.FileLoader")
local LobbyClient = commonlib.gettable("MyCompany.Aries.CombatRoom.LobbyClient");
local Platforms = commonlib.gettable("MyCompany.Aries.Partners.Platforms");
-- create class
local Aries = commonlib.gettable("MyCompany.Aries");
local ReplayMode = commonlib.gettable("MyCompany.Aries.Movie.ReplayMode");
local Player = commonlib.gettable("MyCompany.Aries.Player");
-- whether to use flash loader
local bUseFlashLoader = true;
local WorldManager = commonlib.gettable("MyCompany.Aries.WorldManager");
local ItemManager = commonlib.gettable("Map3DSystem.Item.ItemManager");
-------------------------------------------
-- event handlers
-------------------------------------------
local event_ = commonlib.inherit(commonlib.EventSystem, commonlib.gettable("MyCompany.Aries.event"));
event_:ctor();

-- OnConnection method is the obvious point to place your UI (menus, mainbars, tool buttons) through which the user will communicate to the app. 
-- This method is also the place to put your validation code if you are licensing the add-in. You would normally do this before putting up the UI. 
-- If the user is not a valid user, you would not want to put the UI into the IDE.
-- @param app: the object representing the current application in the IDE. 
-- @param connectMode: type of System.App.ConnectMode. 
function MyCompany.Aries.OnConnection(app, connectMode)
	if(connectMode == System.App.ConnectMode.UI_Setup) then
		-- TODO: place your UI (menus,toolbars, tool buttons) through which the user will communicate to the app
		-- e.g. MainBar.AddItem(), MainMenu.AddItem().
		
		-- e.g. Create a Aries command link in the main menu 
		local commandName = "Profile.Aries.Login";
		local command = System.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = System.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = L"登录", icon = app.icon, });
			
			--commandName = "Profile.Aries.Register";
			--command = System.App.Commands.AddNamedCommand(
				--{name = commandName, app_key = app.app_key, ButtonText = L"注册新用户",  icon = app.icon, });			
				--
			--commandName = "Profile.Aries.HomePage";
			--command = System.App.Commands.AddNamedCommand(
				--{name = commandName,app_key = app.app_key, ButtonText = "Aries Front Page", icon = app.icon, });	
				--
			--commandName = "Profile.Aries.Rooms";
			--command = System.App.Commands.AddNamedCommand(
				--{name = commandName,app_key = app.app_key, ButtonText = "Aries Rooms Page", icon = app.icon, });		
				--
			--commandName = "Profile.Aries.Actions";
			--command = System.App.Commands.AddNamedCommand(
				--{name = commandName,app_key = app.app_key, ButtonText = "Actions Page", icon = app.icon, });	
				--
			--commandName = "Profile.Aries.CreateRoom";
			--command = System.App.Commands.AddNamedCommand(
				--{name = commandName,app_key = app.app_key, ButtonText = "Create Room Page", icon = app.icon, });
			--
			--commandName = "Profile.Aries.MyIncome";
			--command = System.App.Commands.AddNamedCommand(
				--{name = commandName,app_key = app.app_key, ButtonText = "My income page", icon = app.icon, });	
				--
			--commandName = "Profile.Aries.ShowAssetBag";	
			--command = System.App.Commands.AddNamedCommand(
				--{name = commandName,app_key = app.app_key, icon = app.icon, });	
			--
			--commandName = "Profile.Aries.ShowBCSBag";	
			--command = System.App.Commands.AddNamedCommand(
				--{name = commandName,app_key = app.app_key, icon = app.icon, });		
				--
			--commandName = "Profile.Aries.AddSelectionToAssetBag";	
			--command = System.App.Commands.AddNamedCommand(
				--{name = commandName, app_key = app.app_key, icon = app.icon, });		
				
			commandName = "Profile.Aries.FireKey";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });
			commandName = "Profile.Aries.Teen_ToggleChatTab";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });
			-- Local Map
			commandName = "Profile.Aries.LocalMap";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });
			commandName = "Profile.Aries.ShowQuestList";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });
			
			commandName = "Profile.Aries.ShowCombatPetPage";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });

			commandName = "Profile.Aries.ShowMagicStarPage";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });

			commandName = "Profile.Aries.ShowShopPage";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });
			commandName = "Profile.Aries.ShowLobbyPage";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });

			commandName = "Profile.Aries.SpecialAreaShow";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });

			commandName = "Profile.Aries.CharInfo";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });
				
			-- basic actions
			commandName = "Profile.Aries.ToggleFly";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });
				
			commandName = "Profile.Aries.Jump";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });
			
			-- Action
			
			commandName = "Profile.Aries.DoAvatarAction";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });
			commandName = "Profile.Aries.DoMountPetAction";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });
			commandName = "Profile.Aries.PlayAnimationFromValue";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });
				
			-- ThrowableWnd
						
			commandName = "Profile.Aries.ThrowableWnd";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });
				
			-- InventoryWnd
						
			commandName = "Profile.Aries.InventoryWnd";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });
				
			commandName = "Profile.Aries.PurchaseItemWnd";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });
			
			-- Friends
			
			commandName = "Profile.Aries.FriendsWnd";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });
				
			commandName = "Profile.Aries.ChatWithFriendImmediate";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });
				
			--commandName = "Profile.Aries.ChatMainWnd";
			--command = System.App.Commands.AddNamedCommand(
				--{name = commandName, app_key = app.app_key, icon = app.icon, });
				
			-- Family
			
			commandName = "Profile.Aries.MyFamilyWnd";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });
				
			commandName = "Profile.Aries.FamilyChatWnd";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });
				
			-- HomeLand
				
			commandName = "Profile.Aries.MyHomeLand";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });
				
			commandName = "Profile.Aries.GotoHomeLand";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });
			
			-- Profile
			commandName = "Profile.Aries.ShowFullProfile";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });
				
			commandName = "Profile.Aries.ShowMiniProfile";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });
				
			commandName = "Profile.Aries.ShowMountPetProfile";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });
				
			commandName = "Profile.Aries.ShowCurrentFollowPetProfile";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });
				
			commandName = "Profile.Aries.ShowSelectedFollowPetInfoInHomeland";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });
			
			commandName = "Profile.Aries.ShowNPCDialog_Menu";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });
			commandName = "Profile.Aries.ShowNPCDialog_Teen_Native";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });
			commandName = "Profile.Aries.TalkToNearestNPC";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });
			-- Quest
			commandName = "Profile.Aries.ShowNPCDialog";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });
				
			-- System
			commandName = "Profile.Aries.OnCloseApp";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });
				
			--commandName = "Profile.Aries.DoSkill";
			--command = System.App.Commands.AddNamedCommand(
				--{name = commandName, app_key = app.app_key, icon = app.icon, });			
				--
			commandName = "Profile.Aries.EnterChat";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });
				
			commandName = "Profile.Aries.ComeHere";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });					
			commandName = "Profile.Aries.ComeHereByTeamChat";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });
			--commandName = "Profile.Aries.Task";
			--command = System.App.Commands.AddNamedCommand(
				--{name = commandName, app_key = app.app_key, icon = app.icon, });					
			
			commandName = "Aries.Movie.VideoRecorder";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });
			commandName = "Aries.Quest.DoAddValue";
			command = System.App.Commands.AddNamedCommand(
				{name = commandName, app_key = app.app_key, icon = app.icon, });
		end
			
	else
		-- TODO: place the app's one time initialization code here.
		-- during one time init, its message handler may need to update the app structure with static integration points, 
		-- i.e. app.about, HomeButtonText, HomeButtonText, HasNavigation, NavigationButtonText, HasQuickAction, QuickActionText,  See app template for more information.
		
		System.options.ignorePlayerAsset = true;

		-- e.g. 
		MyCompany.Aries.app = app; -- keep a reference
		app.about = "Project Aries";
		app.HomeButtonText = "Aries";
		app:SetHelpPage("script/apps/Aries/Desktop/WelcomePage.html");
		
		---- enabled the audio bank
		--ParaAudio.LoadInMemoryWaveBank("Audio/Haqi/Haqi.InMemory.xwb");
		--ParaAudio.LoadStreamWaveBank("Audio/Haqi/Haqi.Stream.xwb");
		--ParaAudio.LoadSoundBank("Audio/Haqi/Haqi.xsb");
		
		-- set official world directory
		MyCompany.Aries.OfficialWorldDir = "worlds/MyWorlds/61HaqiTown";
		
		-- set default homeland world directory
		MyCompany.Aries.DefaultHomelandWorldDir = "worlds/MyWorlds/0920_homeland";
		
		local commandName = "File.EnterAriesWorld";
		local command = System.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = System.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "Enter Aries World", icon = app.icon, });
		end
		local commandName = "File.ConnectAriesWorld";
		local command = System.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = System.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "Connect Aries World", icon = app.icon, });
		end

		local commandName = "File.Reconnect";
		local command = System.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = System.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "File.Reconnect", icon = app.icon, });
		end
		
		local commandName = "File.ConnectAriesQuest";
		local command = System.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = System.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "Connect Aries World", icon = app.icon, });
		end
		
		local commandName = "File.Aries.Settings";
		local command = System.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = System.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "System Settings", icon = app.icon, });
		end
		
		local commandName = "Profile.Aries.SwitchApp";
		local command = System.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = System.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "Switch App", icon = app.icon, });
		end
		
		-- restart if connection is lost	
		commandName = "Profile.Aries.Restart";
		command = System.App.Commands.AddNamedCommand(
			{name = commandName, app_key = app.app_key, icon = app.icon, });
			
		-- mobile version restart if want to exit	
		commandName = "Profile.Aries.MobileRestart";
		command = System.App.Commands.AddNamedCommand(
			{name = commandName, app_key = app.app_key, icon = app.icon, });	

		commandName = "Profile.Aries.SysCommandLine";	
		command = System.App.Commands.AddNamedCommand(
			{name = commandName, app_key = app.app_key, icon = app.icon, });

		commandName = "Profile.Aries.SYS_WM_DROPFILES";	
		command = System.App.Commands.AddNamedCommand(
			{name = commandName, app_key = app.app_key, icon = app.icon, });

		commandName = "Profile.Aries.SYS_WM_SETTINGCHANGE";	
		command = System.App.Commands.AddNamedCommand(
			{name = commandName, app_key = app.app_key, icon = app.icon, });

		if(not System.options.mc) then
			NPL.load("(gl)script/apps/Aries/Chat/BadWordFilter.lua");
			MyCompany.Aries.Chat.BadWordFilter.Init();
		end
	end
end

-- Receives notification that the Add-in is being unloaded.
function MyCompany.Aries.OnDisconnection(app, disconnectMode)
	if(disconnectMode == System.App.DisconnectMode.UserClosed or disconnectMode == System.App.DisconnectMode.WorldClosed)then
		-- TODO: remove all UI elements related to this application, since the IDE is still running. 
		
		-- e.g. remove command from mainbar
		local command = System.App.Commands.GetCommand("Profile.Aries.Login");
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
-- @param statusWanted: what status of the command is queried. it is of type System.App.CommandStatusWanted
-- @return: returns according to statusWanted. it may return an integer by adding values in System.App.CommandStatus.
function MyCompany.Aries.OnQueryStatus(app, commandName, statusWanted)
	if(statusWanted == System.App.CommandStatusWanted) then
		-- TODO: return an integer by adding values in System.App.CommandStatus.
		--if(commandName == "Profile.Aries.Login") then
			-- return enabled and supported 
			return (System.App.CommandStatus.Enabled + System.App.CommandStatus.Supported)
		--end
	end
end

-- @param cmdline: parse command line params. 
-- @return: table[1] contains the url, and table.fieldname contains other fields. it will return nil if no url is found in command line
local function GetURLCmds(cmdline)
	local cmdURL = string.match(cmdline or "", "[%w]+://(.*)");
	
	local params = {};
	if(cmdURL) then
		cmdURL = string.gsub(cmdURL, "/$", ""); -- remove the trailing slash
		local section
		for section in string.gfind(cmdURL, "[^;]+") do
			local name, value = string.match(section, "%s*([%w_]+)%s*=%s*(.*)");
			if(not name) then
				table.insert(params, section);
			else
				params[name] = value;
			end
		end
		return params;
	end
end

-- command line params
-- @param cmdline: parse command line params. such as single='true'
-- @return: nil or a table containing name value pairs
local function GetExeCmds(cmdline)
	local params = {};
	local name, value
	for name, value in string.gmatch(cmdline or "", "(%S+)=(%S+)") do
		value = value:gsub("^['\"]", "")
		value = value:gsub("['\"]$", "")
		params[name] = value;
	end
	return params;
end

local command_line_processed;

-- load URL world if it is started with "paraenginearies://nid=79012120", etc. if will return true for the first time a url is found. 
local function LoadURLWorldIfNot()
	if( not command_line_processed ) then
		-- if this is the first time we login, we will try process URL command line, and jump to the world immediately. 
		command_line_processed = true;
		-- such as command line such as "paraenginearies://nid=79012120"
		local commandLine = ParaEngine.GetAppCommandLine();
		local url_cmdParams = GetURLCmds(commandLine);
		if(url_cmdParams) then
			LOG.std("", "system", "aries", "URL command line is seen %s", commandLine)
			LOG.std("", "system", "aries", url_cmdParams);
			
			local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
				-- in case there is an url command, we will send to system command line and stops loading the world. 
				System.App.Commands.Call("Profile.Aries.SysCommandLine", commandLine);
			end})
			-- delay loading for some seconds. 
			mytimer:Change(3000, nil);
			return true
		end
	end	
end
local last_world_game_server_presence = nil;


-- @param state: true to freeze camera.
local function SetPlayerFreeze(state)
	local player = Player.GetPlayer();
	local playerChar = player:ToCharacter();
	if(state == true)then
		playerChar:Stop();
		System.KeyBoard.SetKeyPassFilter(System.KeyBoard.enter_key_filter);
		System.Mouse.SetMousePassFilter(System.Mouse.disable_filter);
		ParaCamera.GetAttributeObject():SetField("BlockInput", true);
	else
		System.KeyBoard.SetKeyPassFilter(nil);
		System.Mouse.SetMousePassFilter(nil);
		ParaScene.GetAttributeObject():SetField("BlockInput", false);
		ParaCamera.GetAttributeObject():SetField("BlockInput", false);
	end
end

-- This is called when the command is invoked.The Exec is fired after the QueryStatus event is fired, assuming that the return to the statusOption parameter of QueryStatus is supported and enabled. 
-- This is the event where you place the actual code for handling the response to the user click on the command.
-- @param commandName: The name of the command to determine state for. Usually in the string format "Category.SubCate.Name".
function MyCompany.Aries.OnExec(app, commandName, params)
	if(commandName == "Profile.Aries.ComeHere") then
		NPL.load("(gl)script/apps/Aries/CombatRoom/LobbyClientServicePage.lua");
		local LobbyClientServicePage = commonlib.gettable("MyCompany.Aries.CombatRoom.LobbyClientServicePage");
		if(params and params.nids)then
			if(not LobbyClientServicePage.CanCallUser())then
				_guihelper.MessageBox("当前世界不能召唤队友!");
				return
			end
			local k,nid;
			for k,nid in ipairs(params.nids) do
				LobbyClientServicePage.DoCallUser(nid)
			end
			_guihelper.MessageBox("召唤已经发出，请稍等！");
		end
	elseif(commandName == "Profile.Aries.ComeHereByTeamChat") then
		NPL.load("(gl)script/apps/Aries/CombatRoom/LobbyClientServicePage.lua");
		local LobbyClientServicePage = commonlib.gettable("MyCompany.Aries.CombatRoom.LobbyClientServicePage");
		if(params and params.nids)then
			if(not LobbyClientServicePage.CanCallUser())then
				_guihelper.MessageBox("当前世界不能召唤队友!");
				return
			end
			local address = WorldManager:GetWorldAddress();
			TeamClientLogics:SendTeamChatMessage({type="summon_members", address=address})
			_guihelper.MessageBox("召唤已经发出，请稍等！");
		end
	--elseif(commandName == "Profile.Aries.Login") then
		--local title, cmdredirect;
		--if(type(params) == "string") then
			--title = params;
		--elseif(type(params) == "table")	then
			--title = params.title;
			--cmdredirect = params.cmdredirect;
		--end
		--System.App.Commands.Call("File.MCMLWindowFrame", {
			--url=System.localserver.UrlHelper.BuildURLQuery("script/apps/Aries/Desktop/LoginPage.html", {cmdredirect=cmdredirect}), 
			--name="AriesLogin.Wnd", 
			--app_key=app.app_key, 
			--text = title or "登陆窗口",
			--icon = "Texture/3DMapSystem/common/lock.png",
			--
			--directPosition = true,
				--align = "_ct",
				--x = -320/2,
				--y = -230/2,
				--width = 320,
				--height = 230,
				--bAutoSize=true,
			--zorder=3,
		--});
	elseif(commandName == "Profile.Aries.SYS_WM_DROPFILES") then		
		-- whenever drop file is received. 
		local filelist = params;
		if(filelist) then
			local _, filename;
			for _, filename in ipairs(filelist) do
				NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandDropFile.lua");
				local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
				filename = commonlib.Encoding.DefaultToUtf8(filename);
				LOG.std("", "system", "wm_dropfiles", filename);
				Commands.dropfile.handler("dropfile", filename);
			end
			return;
		end
	elseif(commandName == "Profile.Aries.SYS_WM_SETTINGCHANGE") then
		if(System.options.mc) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandManager.lua");
			local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
			CommandManager:RunCommand("/system settingchange");
		end
	elseif(commandName == "Profile.Aries.SysCommandLine") then		
		-- this function is called when the engine receives an external command, such as internet web browser to login to a given world. 
		local url_cmdParams = GetURLCmds(params);
		local exe_cmdParams = GetExeCmds(params);
		LOG.std("", "system", "aries", {"Profile.Aries.SysCommandLine is called with ", url_cmdParams, exe_cmdParams, params})
		
		if(url_cmdParams) then
			if(url_cmdParams.nid and not url_cmdParams.worldpath) then
				-- for url like : "paraenginearies://nid=79012120", we will go to the home land of the given user.
				--System.App.Commands.Call("Profile.Aries.GotoHomeLand", {nid = url_cmdParams.nid});
			elseif(url_cmdParams.worldpath) then
				-- for url like : "paraenginearies://worldpath=myworlds/nid/20100210"
				-- TODO: for personal home land
			else
				-- TODO: 
			end
			-- _guihelper.MessageBox({url_cmdParams, params});

			-- 使用其它平台的帐户登录的代码
			if url_cmdParams.plat then
				local _plat = tonumber(url_cmdParams.plat); -- 平台ID，1:Facebook；2:QQ
				-- _guihelper.MessageBox(url_cmdParams.nid);
				local _nid = tonumber(url_cmdParams.nid) or -1; -- 平台绑定的NID，如果为-1，则表示还未有与NID绑定
				-- _guihelper.MessageBox(_nid);
				local _uid = url_cmdParams.uid; -- 平台的用户ID，如QQ的OpenID，Facebook的EMail.....
				-- _guihelper.MessageBox(url_cmdParams.uid);
				local _token = url_cmdParams.token; -- 平台的认证凭证
				local _appid = url_cmdParams.app_id; -- 平台的AppID
				NPL.load("(gl)script/apps/Aries/Partners/PartnerPlatforms.lua");
				local Platforms = commonlib.gettable("MyCompany.Aries.Partners.Platforms");
				local _bl = false;
				
				local function OnLoggedIn_()
					if(_bl) then
						_bl = false;
						Platforms.SetPlat(_plat);
						Platforms.SetOID(_uid);
						Platforms.SetToken(_token);
						Platforms.SetAppId(_appid);
						-- invoke callback.
						Platforms.OnLoginCallback();
					end
				end

				if _nid < 0 then -- 未与NID绑定
					if System.User.IsAuthenticated then -- 当前为登录状态
						if not paraworld.users.NIDRelationOtherAccount then
							paraworld.create_wrapper("paraworld.users.NIDRelationOtherAccount", "%MAIN%/API/Users/NIDRelationOtherAccount",
								function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
									LOG.std(nil, "debug", "NIDRelationOtherAccount", "begin binding");
								end,
								function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
									LOG.std(nil, "debug", "NIDRelationOtherAccount", "end binding");
								end
							);
						end
						_guihelper.MessageBox("我们需要将您的哈奇角色与外部分享帐号建立关联, 方便您下次分享. 是否同意？", function()
							paraworld.users.NIDRelationOtherAccount({plat = _plat, oid = _uid}, "users.NIDRelationOtherAccount", function(msg)
								local _err = msg.errorcode;
								if _err == 0 then -- 帐户绑定成功
									_bl = true;
									-- TODO: 给用户提示
									_guihelper.MessageBox("您的角色已经成功绑定了账户, 可以开始分享了！");
									OnLoggedIn_()
								elseif _err == 417 then -- 该NID已绑定过此平台帐户
									-- TODO: 给用户提示
									_guihelper.MessageBox("您的角色已绑定过此平台的其他帐户，请用您绑定的账户登陆");
								elseif _err == 433 then -- 该平台帐户已被其它NID绑定
									-- TODO: 给用户提示
									_guihelper.MessageBox("您输入的帐户已经与其他哈奇角色绑定过了, 请用其他账户分享");
								else -- 其它错误
									-- TODO: 给用户提示
									_guihelper.MessageBox("登录出错了, 位置错误:%s"..tostring(_err));
								end
							end);
						end)
						
					else -- 当前为未登录状态
						-- TODO: 系统自动为其注册一个米米号，默认密码。
						-- 注册成功后，告知用户其米米号及密码。
						-- 使用米米号登录，登录参数中须包含以下几个参数：plat:平台ID;oid:平台的用户ID
						_bl = true;
						_guihelper.MessageBox("请先用一个角色登录再分享！");
					end
				else
					if System.User.IsAuthenticated then -- 当前为登录状态
						if _nid == tonumber(Map3DSystem.User.nid) then
							 -- _guihelper.MessageBox("已经绑定过了，不必重复绑定！");
							_bl = true;
							
						else
							_guihelper.MessageBox("您刚刚输入的账号已经与其它角色绑定过了！目前暂时不支持一个帐号分享多个角色～");
						end
					else
						NPL.load("(gl)script/kids/3DMapSystemApp/API/ParaworldAPI.lua");
						paraworld.auth.AuthUser({loginplat = _plat, token = _token, oid = _uid});
						-- TODO: go on with login procedure
					end
				end

				if _bl then
					OnLoggedIn_();
				end
			end
			-- End 使用其它平台的帐户登录的代码

		elseif(not exe_cmdParams or exe_cmdParams.single == nil or exe_cmdParams.single=="true") then
			-- we now support opening multiple instance of the game
			--_guihelper.MessageBox("是否打开另外一个游戏进程？", function()
				ParaGlobal.ShellExecute("open", ParaIO.GetCurDirectory(0).."ParaEngineClient.exe", "single=\"false\"", "", 1); 
			--end)
		end	
	elseif(commandName == "Profile.Aries.EnterChat") then
		MyCompany.Aries.Desktop.Dock.OnEnterChat();
	elseif(commandName == "Profile.Aries.FireKey") then
		if(params and params.key) then
			local Dock = commonlib.gettable("MyCompany.Aries.Desktop.Dock");
			if(Dock.FireKey)then
				Dock.FireKey(params.key);
			end
		end
	elseif(commandName == "Profile.Aries.LocalMap") then
		local msg = { aries_type = "OnOpenLocalMap", wndName = "main"};
		CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", msg);
		-- local map
		NPL.load("(gl)script/apps/Aries/Map/LocalMap.lua");
		local tab_name;
		if(type(params) == "table" and params.tab_name) then
			tab_name = params.tab_name;
		end
		MyCompany.Aries.Desktop.LocalMap.Show(tab_name);

	elseif(commandName == "Profile.Aries.SpecialAreaShow") then
		if(params and params.id) then
			if(System.options.version == "kids") then
				MyCompany.Aries.Desktop.Dock.ShowCharPage(params.id);
			else
				-- teen backward compatible. 
				if(params.id == 3) then
					MyCompany.Aries.Desktop.Dock.FireCmd("CharacterBagPage.ShowPage");
				end
			end
		end
	elseif(commandName == "Profile.Aries.ShowQuestList") then
		MyCompany.Aries.Desktop.QuestArea.ShowQuestListPage();
	elseif(commandName == "Profile.Aries.ShowCombatPetPage") then
		NPL.load("(gl)script/apps/Aries/CombatPet/CombatPetPage.lua");
		local CombatPetPage = commonlib.gettable("MyCompany.Aries.CombatPet.CombatPetPage");
		CombatPetPage.ShowPage(nil);
	elseif(commandName == "Profile.Aries.ShowShopPage") then
		NPL.load("(gl)script/apps/Aries/HaqiShop/HaqiShop.lua");
		local tab1,tab2;
		if(params and type(params) == "table") then
			tab1,tab2 = params.tab1,params.tab2;
		end	
		MyCompany.Aries.HaqiShop.ShowMainWnd(tab1,tab2)
	elseif(commandName == "Profile.Aries.ShowMagicStarPage") then
		MyCompany.Aries.Desktop.Dock.ShowCharPage(5);

	elseif(commandName == "Profile.Aries.ShowLobbyPage") then
		NPL.load("(gl)script/apps/Aries/CombatRoom/LobbyClientServicePage.lua");
		local LobbyClientServicePage = commonlib.gettable("MyCompany.Aries.CombatRoom.LobbyClientServicePage");
		local game_type = "PvE";
		if(params and type(params) == "table") then
			game_type = params.game_type;
		end	
		LobbyClientServicePage.selected_game_type = game_type;
		LobbyClientServicePage.ShowPage();
	elseif(commandName == "Profile.Aries.CharInfo") then
		MyCompany.Aries.Desktop.CombatCharacterFrame.ShowMainWnd();

	elseif(commandName == "Profile.Aries.PlayAnimationFromValue") then
		if(type(params) == "table") then
			NPL.load("(gl)script/apps/Aries/Player/main.lua");
			MyCompany.Aries.Player.PlayAnimationFromValue(params.nid, params.value);
		end
		
	elseif(commandName == "Profile.Aries.DoAvatarAction") then
		-- play action in world scene
		if(type(params) == "table") then
			NPL.load("(gl)script/apps/Aries/Pet/main.lua");
			local player = MyCompany.Aries.Pet.GetUserCharacterObj(params.nid);
			if(player and player:IsValid() == true) then
				-- play animation
				if(params.anim) then
					System.Animation.PlayAnimationFile(params.anim, player);
				end	
				-- change headonmodel or headonchar
				if(params.headonmodel or params.headonchar) then
					player:ToCharacter():RemoveAttachment(11);
					local asset;
					if(params.headonmodel) then 
						asset = ParaAsset.LoadStaticMesh("", params.headonmodel);
					elseif(params.headonchar) then 
						asset = ParaAsset.LoadParaX("", params.headonchar);
					end	
					if(asset~=nil and asset:IsValid()) then
						player:ToCharacter():AddAttachment(asset, 11);
					end
				else
					player:ToCharacter():RemoveAttachment(11);
				end
				
				-- play effect, as well
				-- TODO: demo effects. 
				--ParaScene.FireMissile(headon_speech.GetAsset("tag"), distH/0.6, to_x, to_y+distH, to_z, to_x, to_y, to_z);
			end
		end
	elseif(commandName == "Profile.Aries.DoMountPetAction") then
		-- play action in world scene
		if(type(params) == "table") then
			NPL.load("(gl)script/apps/Aries/Pet/main.lua");
			local mountPet = MyCompany.Aries.Pet.GetUserMountObj(params.nid);
			if(mountPet and mountPet:IsValid() == true) then
				
				local function play()
					local mountPet = MyCompany.Aries.Pet.GetUserMountObj(params.nid);
					if(mountPet and mountPet:IsValid() == true) then
						if(params.anim) then
							System.Animation.PlayAnimationFile({params.anim, 0}, mountPet);
						end	
						-- change headonmodel or headonchar
						if(params.headonmodel or params.headonchar) then
							mountPet:ToCharacter():RemoveAttachment(19);
							local asset;
							if(params.headonmodel) then 
								asset = ParaAsset.LoadStaticMesh("", params.headonmodel);
							elseif(params.headonchar) then 
								asset = ParaAsset.LoadParaX("", params.headonchar);
							end	
							if(asset~=nil and asset:IsValid()) then
								mountPet:ToCharacter():AddAttachment(asset, 19);
							end
						end
					end
				end
				local function stop()
					local mountPet = MyCompany.Aries.Pet.GetUserMountObj(params.nid);
					if(mountPet and mountPet:IsValid() == true) then
						mountPet:ToCharacter():RemoveAttachment(19);
						System.Animation.PlayAnimationFile(0, mountPet);
					end
				end
				NPL.load("(gl)script/ide/Transitions/TweenLite.lua");
				
				local self = MyCompany.Aries;
				if(not self.tween)then
					local tween=CommonCtrl.TweenLite:new{
						duration = 4000,-- millisecond
						OnStartFunc = function(self)
							stop();
							play();
						end,
						OnUpdateFunc = function(self)
							
						end,
						OnEndFunc = function(self)
							stop();
						end,
					}
					self.tween = tween;
				end
				self.tween:Start();
				-- play effect, as well
				-- TODO: demo effects. 
				--ParaScene.FireMissile(headon_speech.GetAsset("tag"), distH/0.6, to_x, to_y+distH, to_z, to_x, to_y, to_z);
			end
		end
		
	elseif(commandName == "Profile.Aries.ThrowableWnd") then
		-- show the throwable window
		NPL.load("(gl)script/apps/Aries/Inventory/Throwable.lua");
		MyCompany.Aries.Inventory.ThrowablePage.Show();
		
	elseif(commandName == "Profile.Aries.InventoryWnd") then
		-- show the inventory window
		NPL.load("(gl)script/apps/Aries/Inventory/MainWnd.lua");
		MyCompany.Aries.Inventory.ShowMainWnd();
		
	elseif(commandName == "Profile.Aries.PurchaseItemWnd") then
		NPL.load("(gl)script/apps/Aries/HaqiShop/HaqiShop.lua");
		MyCompany.Aries.HaqiShop.PurchaseItem(params);

	elseif(commandName == "Profile.Aries.FriendsWnd") then
		-- show friends main window
		if(System.options.version == "kids") then
			NPL.load("(gl)script/apps/Aries/Friends/Main.lua");
			MyCompany.Aries.Friends.ShowMainWnd();
		else
			MyCompany.Aries.Desktop.Dock.FireCmd("FriendsPage.ShowPage");
		end
	elseif(commandName == "Profile.Aries.MyFamilyWnd") then
		if(System.options.version == "kids" and MyCompany.Aries.Player.GetLevel() < 15) then
			_guihelper.MessageBox("家族功能15级开启， 你的等级不够，快做任务升级吧");
		else
			NPL.load("(gl)script/apps/Aries/NPCs/TownSquare/30341_HaqiGroupManage.lua");
			MyCompany.Aries.Quest.NPCs.HaqiGroupManage.ShowPage();
		end
	elseif(commandName == "Profile.Aries.FamilyChatWnd") then
		-- show family main window
		NPL.load("(gl)script/apps/Aries/Chat/FamilyChatWnd.lua");
		MyCompany.Aries.Chat.FamilyChatWnd.Show(true);
		
	elseif(commandName == "Profile.Aries.ChatWithFriendImmediate") then
		if(System.options.version ~= "kids")then
			NPL.load("(gl)script/apps/Aries/Chat/ChatPage.lua");
			local ChatPage = commonlib.gettable("MyCompany.Aries.ChatPage");
			-- chat with contact immediate
			if(not params.JID and (params.uid or params.nid)) then
				System.App.profiles.ProfileManager.GetJID((params.uid or params.nid), function(jid)
					local chatPageInstance = ChatPage.GetPageInstance(jid)
					chatPageInstance:ShowPage();
				end)
			elseif(params.JID) then
				local chatPageInstance = ChatPage.GetPageInstance(params.JID)
				chatPageInstance:ShowPage();
			end	
		else
			-- chat with contact immediate
			if(not params.JID and (params.uid or params.nid)) then
				System.App.profiles.ProfileManager.GetJID((params.uid or params.nid), function(jid)
					NPL.load("(gl)script/kids/3DMapSystemUI/Chat/MainWnd2.lua");
					LOG.std("", "system", "aries", {"ChatWithFriendImmediate", jid});
					MyCompany.Aries.Chat.MainWnd.ChatWithContactImmediate(jid);
				end)
			elseif(params.JID) then
				NPL.load("(gl)script/kids/3DMapSystemUI/Chat/MainWnd2.lua");
				MyCompany.Aries.Chat.MainWnd.ChatWithContactImmediate(params.JID);
			end	
		end
	--elseif(commandName == "Profile.Aries.ChatMainWnd") then
		---- show main chat window
		--NPL.load("(gl)script/apps/Aries/Chat/MainWnd.lua");
		--MyCompany.Aries.Chat.MainWnd.ShowMainWnd();
		
	elseif(string.find(commandName, "Profile.Aries.ToggleChatTab")) then
			local ID = string.sub(commandName, string.len("Profile.Aries.ToggleChatTab.") + 1, -1);
			MyCompany.Aries.Chat.ChatWnd.OnToggleChatTab(ID);
	elseif(commandName == "Profile.Aries.Teen_ToggleChatTab") then
		System.App.Commands.Call("Profile.Aries.ChatWithFriendImmediate", {JID = params.JID,});
	elseif(commandName == "Profile.Aries.MyHomeLand") then
		-- goto my homeland
		NPL.load("(gl)script/apps/Aries/Creator/Game/GameMarket/OtherPeopleWorlds.lua");
		local OtherPeopleWorlds = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.OtherPeopleWorlds");
		OtherPeopleWorlds.OnHandleGotoHomeLandCmd({nid = System.User.nid});

	elseif(commandName == "Profile.Aries.GotoHomeLand") then
		NPL.load("(gl)script/apps/Aries/Creator/Game/GameMarket/OtherPeopleWorlds.lua");
		local OtherPeopleWorlds = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.OtherPeopleWorlds");
		OtherPeopleWorlds.OnHandleGotoHomeLandCmd(params);
		
	elseif(commandName == "Profile.Aries.ShowMiniProfile") then
		local nid;
		if(type(params) == "table" and params.nid) then	
			nid = params.nid;
		elseif(type(params) == "table" and params.uid) then	
			local uid = params.uid;
			System.App.profiles.ProfileManager.GetUserInfo(uid, "Profile.Aries.ShowMiniProfile_"..uid, function (msg)
				if(msg and msg.users and msg.users[1]) then
					local nid = msg.users[1].nid;
					System.App.Commands.Call("Profile.Aries.ShowMiniProfile", {nid = nid});
				end
			end);
			return;
		end
		System.App.Commands.Call("File.MCMLWindowFrame", {
			name="Aries.ViewMiniProfile", app_key = app.app_key, bShow = false});
		System.App.Commands.Call("File.MCMLWindowFrame", {
			-- TODO:  Add uid to url
			url = System.localserver.UrlHelper.BuildURLQuery("script/apps/Aries/Profile/MiniProfile.html", {nid=nid}), 
			name = "Aries.ViewMiniProfile", 
			app_key = app.app_key, 
			isShowTitleBar = false,
			DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
			enable_esc_key = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			zorder = 2,
			directPosition = true,
				align = "_ct",
				x = -360/2,
				y = -500/2,
				width = 361,
				height = 469,
		});
		
	elseif(commandName == "Profile.Aries.ShowFullProfile") then
		local nid;
		local zorder = 1999; -- top level message box is zorder 2000, just stay below the top leveled layers
		local mouse_button = mouse_button;
		if(type(params) == "table" and params.mouse_button) then	
			mouse_button = params.mouse_button;
		end
		
		if(type(params) == "table" and params.nid) then	
			nid = params.nid;
			if(params.profile_zorder) then
				zorder = params.profile_zorder;
			end
		elseif(type(params) == "string") then	
			System.App.Commands.Call("Profile.Aries.ShowFullProfile", {uid = params});
			return;
		elseif(type(params) == "table" and params.uid) then	
			local uid = params.uid;
			System.App.profiles.ProfileManager.GetUserInfo(uid, "Profile.Aries.ShowFullProfile_"..uid, function (msg)
				if(msg and msg.users and msg.users[1]) then
					local nid = msg.users[1].nid;
					System.App.Commands.Call("Profile.Aries.ShowFullProfile", {nid = nid});
				end
			end);
			return;
		else
			return;
		end
		System.App.Commands.Call("File.MCMLWindowFrame", {
			name = "Aries.ViewFullProfile", app_key = app.app_key, bShow = false});
		
		local url = System.localserver.UrlHelper.BuildURLQuery("script/apps/Aries/Profile/FullProfile.html", {nid=nid});
		local isGM = MyCompany.Aries.Scene.IsGMAccount(nid);
		if(false and isGM) then
			url = "script/apps/Aries/Profile/FullProfile_TownChiefRodd.html";

			System.App.Commands.Call("File.MCMLWindowFrame", {
				-- TODO:  Add uid to url
				url = url, 
				name = "Aries.ViewFullProfile", 
				app_key = app.app_key, 
				isShowTitleBar = false,
				DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
				style = CommonCtrl.WindowFrame.ContainerStyle,
				enable_esc_key = true,
				zorder = zorder,
				directPosition = true,
					align = "_ct",
					x = -360/2,
					y = -500/2,
					width = 361,
					height = 469,
			});

		else
			local options = commonlib.gettable("System.options");
			if(options.version=="teen")then
				NPL.load("(gl)script/apps/Aries/NewProfile/ProfilePane.lua");
				local ProfilePane = commonlib.gettable("MyCompany.Aries.ProfilePane");
				ProfilePane.ShowPage(nid,nil,zorder);
				return;
			end
			NPL.load("(gl)script/apps/Aries/NewProfile/NewProfileMain.lua");
			local NewProfileMain = commonlib.gettable("MyCompany.Aries.NewProfileMain");
			NewProfileMain.ShowPage(nid,nil,zorder, mouse_button);
		end
		
	elseif(commandName == "Profile.Aries.ShowMountPetProfile") then
		-- show the mount window  仅适用于儿童版
		if(System.options.version=="kids") then
			NPL.load("(gl)script/apps/Aries/Inventory/MainWnd.lua");
			local MyCardsManager = commonlib.gettable("MyCompany.Aries.Inventory.Cards.MyCardsManager");
			MyCompany.Aries.Inventory.ShowMainWnd(true, 2);
		end
	elseif(commandName == "Profile.Aries.ShowCurrentFollowPetProfile") then
		local item = System.Item.ItemManager.GetItemByBagAndPosition(0, 32);
		if(item and item.guid > 0) then
			local url = string.format("script/apps/Aries/CombatPet/CombatPetInfoPage.html?gsid=%d",item.gsid);
			System.App.Commands.Call("File.MCMLWindowFrame", {
				-- TODO:  Add uid to url
				url = url,
				--url = "script/apps/Aries/Inventory/CurrentFollowPetInfo.html", 
				name = "Aries.ViewCurrentFollowPetInfo", 
				app_key = app.app_key, 
				isShowTitleBar = false,
				DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
				style = CommonCtrl.WindowFrame.ContainerStyle,
				zorder = 2,
				enable_esc_key = true,
				directPosition = true,
					align = "_ct",
					--x = -360/2,
					--y = -500/2,
					--width = 361,
					--height = 469,
					x = -400/2,
					y = -475/2,
					width = 400,
					height = 485,

			});
		else
			_guihelper.MessageBox("你没有携带任何宠物，记得挑一只带出来！<br/>如果你还没有宠物，可以去跳跳农场看看！");
			return;
		end
	elseif(commandName == "Profile.Aries.ShowSelectedFollowPetInfoInHomeland") then
		if(params)then
			local nid = params.nid or System.App.profiles.ProfileManager.GetNID();
			local gsid = params.gsid;
			if(not gsid)then
				local guid = params.guid;
				if(guid)then
					local item;
					local ItemManager = System.Item.ItemManager;
					if(nid == System.App.profiles.ProfileManager.GetNID()) then
						item = ItemManager.GetItemByGUID(guid);
					else
						item = ItemManager.GetOPCItemByGUID(nid, guid);
					end
					if(item)then
						gsid = item.gsid;
					end
				end
			end	
			if(nid and gsid)then
				local url = string.format("script/apps/Aries/CombatPet/CombatPetInfoPage.html?gsid=%d&nid=%s",gsid,tostring(nid));
				System.App.Commands.Call("File.MCMLWindowFrame", {
					-- TODO:  Add uid to url
					url = url,
					--url = System.localserver.UrlHelper.BuildURLQuery("script/apps/Aries/Inventory/FollowPetInfoInHomeland.html", {guid = params.guid, nid = params.nid,}), 
					name = "Aries.ViewCurrentFollowPetInfo", 
					app_key = app.app_key, 
					isShowTitleBar = false,
					DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
					enable_esc_key = true,
					style = CommonCtrl.WindowFrame.ContainerStyle,
					zorder = 2,
					directPosition = true,
						align = "_ct",
						--x = -360/2,
						--y = -500/2,
						--width = 361,
						--height = 469,
						x = -400/2,
						y = -475/2,
						width = 400,
						height = 485,
				});
			end		
		end
	elseif(commandName == "File.Aries.Settings") then
		System.App.Commands.Call("File.MCMLWindowFrame", {
				url = if_else(System.options.version=="kids", "script/apps/Aries/Desktop/AriesSettingsPage.kids.html", "script/apps/Aries/Desktop/AriesSettingsPage.teen.html"), 
				name = "Aries.Settings", 
				app_key = app.app_key, 
				isShowTitleBar = false,
				DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
				enable_esc_key = true,
				style = CommonCtrl.WindowFrame.ContainerStyle,
				zorder = 2,
				directPosition = true,
					align = "_ct",
					x = -500/2,
					y = -320/2,
					width = 500,
					height = 320,
			});
	elseif(commandName == "Aries.Movie.VideoRecorder") then
		--NPL.load("(gl)script/apps/Aries/Movie/VideoRecorder.lua");
		--MyCompany.Aries.Movie.VideoRecorder.Show();
		NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/VideoRecorder.lua");
		local VideoRecorder = commonlib.gettable("MyCompany.Aries.Game.Movie.VideoRecorder");
		VideoRecorder.ToggleRecording();
	elseif(commandName == "Profile.Aries.TalkToNearestNPC") then
		MyCompany.Aries.Dialog.OnTalkToNearestNPC();
	elseif(commandName == "Profile.Aries.ShowNPCDialog_Menu") then
		MyCompany.Aries.Dialog.ShowNPCDialog_Menu(params);
	elseif(commandName == "Profile.Aries.ShowNPCDialog_Teen_Native") then
		MyCompany.Aries.Dialog.ShowNPCDialog_Teen_Native(params);
	elseif(commandName == "Profile.Aries.ShowNPCDialog") then
		MyCompany.Aries.Dialog.ShowNPCDialog(params);

	elseif(commandName == "File.EnterAriesWorld") then
		Aries.Handle_LoadWorld_Command(params);
	elseif(commandName == "File.ConnectAriesWorld") then
		NPL.load("(gl)script/apps/Aries/FamilyServer/ServerSelect.lua");
		local ServerSelect = commonlib.gettable("MyCompany.Aries.FamilyServer.ServerSelect");
			
		local world_info = WorldManager:GetCurrentWorld();
		if(System.options.auto_select_server and
			WorldManager:IsInPublicWorld() and 
			not params.gs_nid and not params.ws_id and 
			not ServerSelect.IsCurrentServerMatchLevel()) then

			LOG.std("", "info","File.ConnectAriesWorld", "try finding a most fit server to connnect to ");

			-- we will need to verify the current server
			ServerSelect.AutoSelectServer(nil, function(msg)
				if(msg and msg.best_server) then
					-- is best server
					local best_server = msg.best_server
					params.gs_nid = best_server.gs_nid;
					params.ws_id = best_server.ws_id;
					params.ws_seqid = best_server.id;
					params.ws_text = best_server.text;
					
					if( best_server.gs_nid == Map3DSystem.GSL_client.gameserver_nid and best_server.ws_id == Map3DSystem.GSL_client.worldserver_id) then
						MyCompany.Aries.Handle_ConnectWorld_Command(params);
					else
						-- we need to connect to the server first. 
						LOG.std(nil, "info", "WorldManager", "teleporting across servers. break connection and connect again");
						-- if the game server is on a different server, we need to break the previous connection and login again. 
						local function ConnectFail(reasonText)
							_guihelper.CloseMessageBox();
							_guihelper.MessageBox(reasonText or "无法连接这台服务器, 请重新登录并试试其他服务器", function()
									Map3DSystem.App.Commands.Call("Profile.Aries.Restart", {method="soft"});
								end)
						end

						----------------------------
						-- switch game server and authenticate using old account
						----------------------------
						local rest_client = GameServer.rest.client;
						Map3DSystem.GSL_client:LogoutServer();
						-- disconnect first
						Map3DSystem.GSL_client:Disconnect();
						GameServer.rest.client:disconnect();

						-- here we will wait 5 seconds before proceeding. 
						-- if target is on a different game server, diconnect old and connect to the new one and sign in using the same account. 
						local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
							GameServer.rest.client:connect({nid=params.gs_nid, world_id=params.ws_id,}, nil, function(msg) 
								if(msg.connected) then
									LOG.std(nil, "system", "worldmanager", "connection with game server %s is established", params.gs_nid)
					
									-- authenticate again with the new game server using existing account. 
									paraworld.auth.AuthUser(Map3DSystem.User.last_login_msg or {username = tostring(System.User.username), password = System.User.Password,}, "login", function (msg)
										if(msg==nil) then
											ConnectFail("这台服务器无法认证, 请试试其他服务器");
										elseif(msg.issuccess) then	
											MyCompany.Aries.Handle_ConnectWorld_Command(params);
										else
											ConnectFail("服务器认证失败了, 请重新登录");
										end
									end, nil, 20000, function(msg)
										-- timeout request
										commonlib.applog("Proc_Authentication timed out")
										ConnectFail("用户验证超时了, 可能服务器太忙了, 或者您的网络质量不好.");
									end);
								else
									ConnectFail("无法连接这台服务器, 请试试其他服务器");
								end
							end)
						end})
						mytimer:Change(5000,nil);
					end
				else
					MyCompany.Aries.Handle_ConnectWorld_Command(params);
				end
				
			end)
		else
			MyCompany.Aries.Handle_ConnectWorld_Command(params);
		end
	elseif(commandName == "File.Reconnect") then
		MyCompany.Aries.Handle_Reconnect_Command(params);

	elseif(commandName == "File.ConnectAriesQuest") then
		-- connecting to Aries quest server using NPL activate
		-- Note: calling this multiple times, will disconnect previous gateway and reconnect. 
		-- this function is called whenever connection is established.
		params = params or {};
		
		LOG.std("", "system", "aries", "File.ConnectAriesQuest is called for %s", ParaWorld.GetWorldDirectory());
		
		-- never connect for initial empty world or worlds outside "worlds/" directory. 
		if(not string.match(ParaWorld.GetWorldDirectory(), "^worlds")) then
			return;
		end
		
		-- auto connect the quest world
		NPL.load("(gl)script/apps/Aries/Quest/main.lua");
		MyCompany.Aries.Quest.AutoConnectQuestWorld();
	
	elseif(commandName == "Profile.Aries.Restart") then
		local method;
		if(type(params) == "table") then
			method = params.method;
		end
		method = method or "hard";
		
		-- uncomment the following statement to use normal restart
		-- force hard restart
		--method = "hard";

		if(not System.options.mc) then
			-- stop all music
			MyCompany.Aries.Scene.StopRegionBGMusic();
			MyCompany.Aries.Scene.StopGameBGMusic();
		end

		-- aries restart
		LOG.std(nil, "system", "app_main", "Profile.Aries.Restart");

		if(method == "hard") then
			-- hard reboot
			ParaEngine.GetAttributeObject():SetField("IsWindowClosingAllowed", true);
			if(System.options.IsWebBrowser) then
				commonlib.app_ipc.ActivateHostApp("restart_game");
				ParaGlobal.ExitApp();
			else	
				NPL.activate("AutoUpdater.dll", {cmd="restartonly"});
				ParaGlobal.ExitApp();
			end	
		else
			if(System.options.mc) then
				System.reset();
				-- flush all local server 
				if(System.localserver) then
					System.localserver.FlushAll();
				end	
				ParaScene.UnregisterAllEvent();
				local restart_code = [[ParaUI.ResetUI();ParaScene.Reset();NPL.load("(gl)script/apps/Aries/main_loop.lua");NPL.activate("(gl)script/apps/Aries/main_loop.lua");]];
				__rts__:Reset(restart_code);
				return;
			end
			MyCompany.Aries.Desktop.Dock.LeaveTown(function() 
				
				ParaEngine.GetAttributeObject():SetField("IsWindowClosingAllowed", true);
				
				-- soft reboot
				if(System.GSL_client) then
					--System.GSL_client:LogoutServer(true);
					System.GSL_client:Disconnect();
				end
				if(GameServer and GameServer.rest and GameServer.rest.client) then
					GameServer.rest.client:disconnect();
				end	
			
				-- reset chat
				if(System.App and System.App.Chat and System.App.Chat.CleanUp) then
					System.App.Chat.CleanUp()
				end
				-- reset user database
				System.User.Reset();
				-- reset all UI. 
				System.reset();
			
				if(MyCompany.Aries.Desktop and MyCompany.Aries.Desktop.CleanUp) then
					MyCompany.Aries.Desktop.CleanUp()
				end
			
				-- flush all local server 
				if(System.localserver) then
					System.localserver.FlushAll();
				end	
			
				-- whether we will reset the entire state 
				local reset_main_state = true;	
				if(reset_main_state) then
					-- restart completely by reset main runtime state.
					-- ParaAsset.UnloadAll();
					-- ParaAsset.UnloadDatabase();
					JabberClientManager.CloseJabberClient("");
					ParaScene.UnregisterAllEvent();
					local restart_code = [[ParaUI.ResetUI();ParaScene.Reset();NPL.load("(gl)script/apps/Aries/main_loop.lua");NPL.activate("(gl)script/apps/Aries/main_loop.lua");]];
				
					if(type(params)=="table" and params.startup_msg) then
						if(type(params.startup_msg) == "table") then
							params.startup_msg = commonlib.serialize_compact(params.startup_msg);
						elseif(type(params.startup_msg) == "string") then
							params.startup_msg = string.format("%q", params.startup_msg);
						else
							params.startup_msg = tostring(params.startup_msg);
						end
						restart_code = string.format([[%s commonlib.setfield("MyCompany.Aries.MainLogin.startup_msg", %s);]], restart_code, params.startup_msg);
					end
					__rts__:Reset(restart_code);
				else
					commonlib.echo(MyCompany.Aries.MainLogin.startup_msg)
					-- start login procedure
					 MyCompany.Aries.MainLogin:start();
					-- TODO: this is not 100% working, if user account changes, shall we use the last account to login the second time?	
				end	
			end)
		end
	elseif(commandName == "Profile.Aries.MobileRestart") then
		-- aries restart
		LOG.std(nil, "system", "app_main", "Profile.Aries.MobileRestart");

		if(not System.options.mc) then
			-- stop all music
			MyCompany.Aries.Scene.StopRegionBGMusic();
			MyCompany.Aries.Scene.StopGameBGMusic();

			-- soft reboot
			if(System.GSL_client) then
				--System.GSL_client:LogoutServer(true);
				System.GSL_client:Disconnect();
			end
			if(GameServer and GameServer.rest and GameServer.rest.client) then
				GameServer.rest.client:disconnect();
			end	
		end
				
		ParaEngine.GetAttributeObject():SetField("IsWindowClosingAllowed", true);

		-- reset user database
		System.User.Reset();
		-- reset all UI. 
		System.reset();
			
		-- flush all local server 
		if(System.localserver) then
			System.localserver.FlushAll();
		end	
			
		-- whether we will reset the entire state 
		local reset_main_state = true;	
		if(reset_main_state) then
			-- restart completely by reset main runtime state.
			-- ParaAsset.UnloadAll();
			-- ParaAsset.UnloadDatabase();
			ParaScene.UnregisterAllEvent();
			local restart_code = [[ParaUI.ResetUI();ParaScene.Reset();NPL.activate("(gl)script/mobile/paracraft/main.lua");]];
				
			if(type(params)=="table" and params.startup_msg) then
				if(type(params.startup_msg) == "table") then
					params.startup_msg = commonlib.serialize_compact(params.startup_msg);
				elseif(type(params.startup_msg) == "string") then
					params.startup_msg = string.format("%q", params.startup_msg);
				else
					params.startup_msg = tostring(params.startup_msg);
				end
				restart_code = string.format([[%s commonlib.setfield("ParaCraft.Mobile.MainLogin.startup_msg", %s);]], restart_code, params.startup_msg);
			end
			__rts__:Reset(restart_code);
		end	
		
	elseif(commandName == "Profile.Aries.OnCloseApp") then
		if(type(params) == "table" and params.IsDestroy) then
			LOG.std(nil, "info", "main", "windows is being destroyed");
			-- this will also flush any previous data to disk. 
			if(commonlib.getfield("MyCompany.Aries.Player.RecordLastPosition")) then
				MyCompany.Aries.Player.RecordLastPosition(true);
				-- MyCompany.Aries.Player.SaveLocalData("LastCloseTime", ParaGlobal.timeGetTime());
			end
		else
			if(System.options.mc) then
				NPL.load("(gl)script/apps/Aries/Creator/Game/GameDesktop.lua");
				local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
				Desktop.OnExit();
			else
				MyCompany.Aries.Desktop.Dock.OnExit();
			end
		end
	elseif(commandName == "Profile.Aries.ToggleFly") then
		local worldinfo = WorldManager:GetCurrentWorld();
		if(worldinfo.can_jump == true) then
			-- press "F" key to toggle fly mode
			MyCompany.Aries.Player.ToggleFly();
		end
	elseif(commandName == "Profile.Aries.Jump") then
		-- press "Space" key to jump
		MyCompany.Aries.Player.Jump();
		
	elseif(commandName == "Aries.Quest.DoAddValue") then
		NPL.load("(gl)script/apps/Aries/Quest/QuestClientLogics.lua");
		local QuestClientLogics = commonlib.gettable("MyCompany.Aries.Quest.QuestClientLogics");
		if(params and params.increment)then
			local increment = params.increment;
			QuestClientLogics.DoAddValue_FromClient(increment)
		end

	elseif(System.UI.AppDesktop.CheckUser(commandName)) then	
		-- all functions below requres user is logged in. 	
		if(commandName == "Profile.Aries.HomePage") then
			-- System.App.Commands.Call("File.MCMLBrowser", {url="script/apps/Aries/Desktop/LoggedInHomePage.html", name="HelloPage", title="我的首页", DisplayNavBar = true});
		elseif(commandName == "Profile.Aries.Rooms") then
			System.App.Commands.Call("File.MCMLBrowser", {url="script/apps/Aries/Desktop/RoomsPage.html", name="HelloPage", title="邻居聊天室", DisplayNavBar = true});
		elseif(commandName == "Profile.Aries.Actions") then
			System.App.Commands.Call("File.MCMLBrowser", {url="script/apps/Aries/Desktop/ActionsPage.html", name="HelloPage", title="动作", DisplayNavBar = true});
		elseif(commandName == "Profile.Aries.MyIncome") then	
			System.App.Commands.Call("File.MCMLBrowser", {url="script/apps/Aries/Desktop/MyIncome.html", name="HelloPage", title="我的收益", DisplayNavBar = true});
		end
	elseif(app:IsHomepageCommand(commandName)) then
		MyCompany.Aries.GotoHomepage();
	elseif(app:IsNavigationCommand(commandName)) then
		MyCompany.Aries.Navigate();
	elseif(app:IsQuickActionCommand(commandName)) then	
		MyCompany.Aries.DoQuickAction();
	end
end

-- Change and render the 3D world with mcml data that is usually retrieved from the current user's profile page for this application. 
function MyCompany.Aries.OnRenderBox(mcmlData)
end


-- called when the user wants to nagivate to the 3D world location relavent to this application
function MyCompany.Aries.Navigate()
end

-- called when user clicks to check out the homepage of this application. Homepage usually includes:
-- developer info, support, developer worlds information, app global news, app updates, all community user rating, active users, trade, currency transfer, etc. 
function MyCompany.Aries.GotoHomepage()
end

-- called when user clicks the quick action for this application. 
function MyCompany.Aries.DoQuickAction()
end

-- whenever this application becomes active. Init UI of this app.
function MyCompany.Aries.OnActivateDesktop()
	local world_info = WorldManager:GetCurrentWorld();
	if(System.options.mc or (world_info and (world_info.disable_desktop_ui or System.User.nid == 0))) then
		return;
	end

	-- load short cut gsids
	System.Item.ItemManager.OnLoadItemShortcutGSIDs()

	NPL.load("(gl)script/apps/Aries/Quest/NPCList.lua");
	MyCompany.Aries.Quest.NPCList.Init();

	MyCompany.Aries.Desktop.InitDesktop();
	MyCompany.Aries.Desktop.SendMessage({type = MyCompany.Aries.Desktop.MSGTYPE.SHOW_DESKTOP, bShow = true});
	
	NPL.load("(gl)script/apps/Aries/Dialog/main.lua");
	MyCompany.Aries.Dialog.Init();
	
	NPL.load("(gl)script/apps/Aries/Player/main.lua");
	MyCompany.Aries.Player.Init();
	
	NPL.load("(gl)script/apps/Aries/Pet/main.lua");
	MyCompany.Aries.Pet.Init();
	
	NPL.load("(gl)script/apps/Aries/Quest/main.lua");
	MyCompany.Aries.Quest.Init();
	
	NPL.load("(gl)script/apps/Aries/Quest/NPCBagManager.lua");
	MyCompany.Aries.Quest.NPCBagManager.ResetBagsFetchedInCurrentSession();
	
	NPL.load("(gl)script/apps/Aries/Scene/main.lua");
	MyCompany.Aries.Scene.Init();

	NPL.load("(gl)script/apps/Aries/Combat/main.lua");
	MyCompany.Aries.Combat.Init();
	
	NPL.load("(gl)script/apps/Aries/Instance/main.lua");
	MyCompany.Aries.Instance.Init();

	NPL.load("(gl)script/apps/Aries/BBSChat/ChatSystem/ChatChannel.lua");
	MyCompany.Aries.ChatSystem.ChatChannel.Init();
	
	---- TODO: strange BUG: if load the friends/main.lua the buddylistpage will got nil
	--NPL.load("(gl)script/apps/Aries/Friends/main.lua");
	MyCompany.Aries.Friends.InitPositionQueryWaitTimer();
	
	NPL.load("(gl)script/apps/Aries/Scene/EffectManager.lua");
	MyCompany.Aries.EffectManager.Init();
	
	NPL.load("(gl)script/kids/3DMapSystemUI/MiniGames/AntiIndulgence.lua");
	System.App.MiniGames.AntiIndulgence.Start();
	
	local MyCardsManager = commonlib.gettable("MyCompany.Aries.Inventory.Cards.MyCardsManager");
	MyCardsManager.GetRemoteCombatBag();

	---- register timer for user name and profile picture update
	--MyCompany.Aries.Desktop.RegisterDoFillUIObjectTimer();
	
	---- update the self profile user name
	--MyCompany.Aries.Desktop.Profile.UpdateUserName();
	--MyCompany.Aries.Desktop.Profile.UpdateUserPhoto();
	--MyCompany.Aries.Desktop.Profile.UpdateUserApperence();
	--
	---- update the minimap world name
	--MyCompany.Aries.Desktop.MiniMap.UpdateWorldName();
	System.UI.AppDesktop.ChangeMode("game");
	
	NPL.load("(gl)script/kids/3DMapSystemUI/Desktop/autotips.lua");
	autotips.Show(false);

	NPL.load("(gl)script/apps/Aries/Scene/AutoCameraController.lua");
	MyCompany.Aries.AutoCameraController:Init();

	NPL.load("(gl)script/apps/Aries/Team/TeamClientLogics.lua");
	local TeamClientLogics = commonlib.gettable("MyCompany.Aries.Team.TeamClientLogics");
	TeamClientLogics:Init()
	TeamClientLogics:EnableWorldTeamTimer();

	NPL.load("(gl)script/apps/Aries/Scene/AriesSoundEffect.lua");
	AudioEngine.AriesSoundManager.Init();
	
	NPL.load("(gl)script/apps/Aries/Combat/SpellPlayer.lua");
	MyCompany.Aries.Combat.SpellPlayer.Init();

	MyCompany.Aries.Desktop.OnActivateDesktop();
end

function MyCompany.Aries.OnDeactivateDesktop()
	LOG.std(nil, "debug", "main", "OnDeactivateDesktop");
end

-- user clicks to register
function MyCompany.Aries.OnUserRegister(btnName, values, bindingContext)
	if(btnName == "register") then
		local errormsg = "";
		-- validate name
		if(string.len(values.username)<3) then
			errormsg = errormsg.."名字太短了\n"
		end
		-- validate password
		if(string.len(values.password)<6) then
			errormsg = errormsg.."密码太短了\n"
		elseif(values.password~=values.password_confirm) then
			errormsg = errormsg.."确认密码与密码不一致\n"
		end
		-- validate email
		values.email = string.gsub(values.email, "^%s*(.-)%s*$", "%1")
		if(not string.find(values.email, "^%s*[%w%._%-]+@[%w%.%-]+%.[%a]+%s*$")) then
			errormsg = errormsg.."Email地址格式不正确\n"
		end
		if(errormsg~="") then
			paraworld.ShowMessage(errormsg)
		else
			local msg = {
				-- is this app key needed?
				appkey = "fae5feb1-9d4f-4a78-843a-1710992d4e00",
				username = values.username,
				password = values.password,
				email = values.email,
				referrer = values.referrer,
			};
			paraworld.ShowMessage("正在连接注册服务器, 请等待")
			paraworld.users.Registration(msg, "login", function(msg)
				if(paraworld.check_result(msg, true)) then
					paraworld.ShowMessage("恭喜！注册成功！\n 请您查收Email激活您的登录帐号.");
					-- start login procedure
					--NPL.load("(gl)script/kids/3DMapSystemApp/Login/LoginProcedure.lua");
					--System.App.Login.Proc_Authentication(values);
				end	
			end);
		end
	end
end

function MyCompany.Aries.OnWorldLoad()	
	local world_info = WorldManager:GetCurrentWorld();
	if(not System.options.mc) then
		-- always show head on text
		local player = Player.GetPlayer();
		local att = player:GetAttributeObject()
		att:SetDynamicField("AlwaysShowHeadOnText", true);
	
		-- show nickname and family
		local ProfileManager = System.App.profiles.ProfileManager;
		local Player = MyCompany.Aries.Player;
		local myinfo = ProfileManager.GetUserInfoInMemory(ProfileManager.GetNID());
		if(myinfo and not System.options.mc) then
			player:GetAttributeObject():SetDynamicField("name", myinfo.nickname);
			player:GetAttributeObject():SetDynamicField("family", myinfo.family or "");
			local headon_text = Player.GetHeadonTextString(player);
			System.ShowHeadOnDisplay(true, player, headon_text, Player.HeadOnDisplayColor, Player.FamilyDisplayColor);
		end
	
		-- force activate the enviroment timer function to give the scene an immediate look
		MyCompany.Aries.Player.ForceActivateEnvTimerFunction();
	end
	
	-- set the fog range and far plane from the current ViewDistance
	local att = ParaScene.GetAttributeObject();
	att:SetField("persistent", false);
	local FarPlane = tonumber(ParaEngine.GetAttributeObject():GetDynamicField("ViewDistance", 200));
	local FogStart, FogRange;
	local FarPlane_range = {from=100,to=420}
	local FogStart_range = {from=50,to=80}
	local FogEnd_range	 = {from=70,to=130}

	---- NOTE 2012/2/2: skip read the world fog config from world data
	--local value = (FarPlane-FarPlane_range.from) / (FarPlane_range.to- FarPlane_range.from);
	--att:SetField("FogEnd", FogEnd_range.from + (FogEnd_range.to - FogEnd_range.from) * value);
	--att:SetField("FogStart", FogStart_range.from + (FogStart_range.to - FogStart_range.from) * value);
	--ParaCamera.GetAttributeObject():SetField("FarPlane", FarPlane);
	if(not System.options.mc and System.options.IsTouchDevice) then
		att:SetField("FogEnd", 52);
		att:SetField("FogStart", 42);
		ParaCamera.GetAttributeObject():SetField("FarPlane", 56);
	end

	if( not System.options.is_mcworld and world_info.share_global_weather ) then
		att:SetField("FogColor", {187/255, 230/255, 255/255});
	end	
	
	if(System.options.version == "kids") then
		att:SetField("FogDensity", 1.0);

		att:SetField("GlowIntensity", 0.8)
		att:SetField("GlowFactor", 1)
		att:SetField("Glowness", {1,1,1,1})
		att:SetField("FieldOfView", 60/180*3.1415926)
	
		-- set sky parameters
		local att = ParaScene.GetAttributeObjectSky()
		att:SetField("SkyFogAngleFrom", 0)
		att:SetField("SkyFogAngleTo", 0.2)
	end

	-- mid noon
	local att = ParaScene.GetAttributeObjectSunLight();
	if( world_info.share_global_weather ) then
		-- set day length of the day in minutes
		if(not System.options.is_mcworld ) then
			att:SetField("DayLength", 10000);
			-- set some time of day on each world load
			att:SetField("TimeOfDaySTD", 0.4);
		end
		
		att:SetField("MaximumAngle", 1.5);
		att:SetField("AutoSunColor", false)
		att:SetField("Ambient", {150/255, 150/255, 150/255});
		att:SetField("Diffuse", {188/255, 188/255, 188/255});
		
		ParaScene.GetAttributeObjectSky():SetField("SkyFogAngleFrom", -0.03)
		ParaScene.GetAttributeObjectSky():SetField("SkyFogAngleTo", 0)
		
		-- ocean color
		local att = ParaScene.GetAttributeObjectOcean();
		att:SetField("OceanColor", {0, 1, 1});
	end
	
	-- LiXizhi 2009.9.24: background async asset loader indicator
	NPL.load("(gl)script/kids/3DMapSystemApp/Assets/AsyncLoaderProgressBar.lua");
	Map3DSystem.App.Assets.AsyncLoaderProgressBar.CreateDefaultAssetBar(true);
	
	--NPL.load("(gl)script/apps/Aquarius/Quest/Quest_NPCStatus.lua");
	---- get all nearby NPCs
	--MyCompany.Aquarius.Quest_NPCStatus.GetNearbyNPCs();

	if(not System.options.mc) then			
		-- hook mouse event	
		NPL.load("(gl)script/apps/Aries/EventHandler_Mouse.lua");
		CommonCtrl.os.hook.SetWindowsHook({hookType = CommonCtrl.os.hook.HookType.WH_CALLWNDPROC, 
			hookName = "aries_mouse_up_hook", appName = "input", wndName = "mouse_down", callback=MyCompany.Aries.HandleMouse.OnMouseDown});

		CommonCtrl.os.hook.SetWindowsHook({hookType = CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 
			hookName = "aries_mouse_move_hook", appName = "input", wndName = "mouse_move", callback=MyCompany.Aries.HandleMouse.OnMouseMove});

		CommonCtrl.os.hook.SetWindowsHook({hookType = CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 
			hookName = "aries_mouse_up_hook", appName = "input", wndName = "mouse_up", callback=MyCompany.Aries.HandleMouse.OnMouseUp});
	
		-- hook key event
		NPL.load("(gl)script/apps/Aries/EventHandler_Keyboard.lua");
		CommonCtrl.os.hook.SetWindowsHook({hookType=CommonCtrl.os.hook.HookType.WH_CALLWNDPROC, 
			callback = MyCompany.Aries.HandleKeyboard.OnKeyDownProc, priority=1, hookName = "aries_keydown", appName="input", wndName = "key_down"});
	
		NPL.load("(gl)script/apps/Aries/Chat/Main.lua");
		-- register OnRoster message handler timer
		MyCompany.Aries.Chat.MainWnd.RegisterDoPendingMSGTimer();
	
		NPL.load("(gl)script/apps/Aries/BBSChat/BBSChatWnd.lua");
		--MyCompany.Aries.BBSChatWnd.ClearChannelMessges();
		--MyCompany.Aries.BBSChatWnd.UpdateChannelName();
	
		NPL.load("(gl)script/kids/3DMapSystemApp/worlds/TeleportPortal.lua");
		System.App.worlds.TeleportPortal.HideAllTeleportDestHelpers();
	
		-- show dock
		MyCompany.Aries.Desktop.Dock.Show(true);
	
		-- init family chat window
		NPL.load("(gl)script/apps/Aries/Chat/FamilyChatWnd.lua");
		MyCompany.Aries.Chat.FamilyChatWnd.Init();

		-- open the region radar
		NPL.load("(gl)script/kids/3DMapSystemApp/worlds/RegionRadar.lua");
		System.App.worlds.Global_RegionRadar.Start();

		NPL.load("(gl)script/apps/Aries/Scene/main.lua");
		MyCompany.Aries.Scene.OnWorldLoad();

		NPL.load("(gl)script/apps/Aries/Instance/main.lua");
		MyCompany.Aries.Instance.OnWorldLoad();

		-- start player action recording
		MyCompany.Aries.ResetTimeReverseMode();

		NPL.load("(gl)script/apps/Aries/Combat/main.lua");
		MyCompany.Aries.Combat.OnWorldLoad();
	end
	
	-- "UseRightButtonBipedFacing" boolean attribute is added to ParaCamera.
	-- set this to false to use the new one, default true
	ParaCamera.GetAttributeObject():SetField("UseRightButtonBipedFacing", false);
	
	-- this prevent user from closing the application by alt-f4 or clicking the x button. Instead SYS_WM_CLOSE is fired. 
	ParaEngine.GetAttributeObject():SetField("IsWindowClosingAllowed", false);
	
	-- falldown to ground, mainly for enter official world from a previous sky position
	--Player.GetPlayer():ToCharacter():FallDown();
	
	-- whether to allow slope collision for terrain. 
	ParaTerrain.GetAttributeObject():SetField("AllowSlopeCollision", world_info.allow_terrain_slope_collision == true);
	
	-- whether to show head on text in case the world is anonymous. 
	ParaScene.GetAttributeObject():SetField("ShowHeadOnDisplay", not world_info.is_anonymous);

	-- call hook for OnWorldLoad
	local msg = { aries_type = "OnWorldLoad", gsid = gsid, count = count, wndName = "main"};
	CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", msg);
	
	-- load URL world if any. 
	LoadURLWorldIfNot()
end

function MyCompany.Aries.OnWorldClosing()
	-- call hook for OnWorldClosing
	local msg = { aries_type = "OnWorldClosing", gsid = gsid, count = count, wndName = "main"};
	CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", msg);
	
	if(not System.options.mc) then
		-- open the region radar
		NPL.load("(gl)script/kids/3DMapSystemApp/worlds/RegionRadar.lua");
		System.App.worlds.Global_RegionRadar.End()
	
		NPL.load("(gl)script/apps/Aries/Scene/main.lua");
		MyCompany.Aries.Scene.OnWorldClosing();
	
		NPL.load("(gl)script/apps/Aries/Quest/NPC.lua");
		MyCompany.Aries.Quest.NPC.OnWorldClosing();
	
		MyCompany.Aries.Scene.StopRegionBGMusic();
		MyCompany.Aries.Scene.StopGameBGMusic();
	end
end

function MyCompany.Aries.OnWorldClosed()
	--NPL.load("(gl)script/apps/Aquarius/EventHandler_Mouse.lua");
	---- unregister event mouse cursor and right click handler
	-- close all windows before world load
	if(not System.options.mc) then
		MyCompany.Aries.Desktop.Dock.HideAllWindows();
	
		-- hide all arrows after world close
		MyCompany.Aries.Desktop.GUIHelper.ArrowPointer.HideAllArrows();
	end
end

function MyCompany.Aries.OnConnectionDisconnected(nid, reason)
	if(not System.User.IsRedirecting) then
		if(not System.options.mc) then
			MyCompany.Aries.Desktop.Dock.OnDisconnected(nid, reason)
		end
	end	
end

	
-------------------------------------------
-- client world database function helpers.
-------------------------------------------

------------------------------------------
-- all related messages
------------------------------------------

local MSGTYPE = commonlib.gettable("System.App.MSGTYPE");
-----------------------------------------------------
-- APPS can be invoked in many ways: 
--	Through app Manager 
--	mainbar or menu command or buttons
--	Command Line 
--  3D World installed apps
-----------------------------------------------------
function MyCompany.Aries.MSGProc(window, msg)
	----------------------------------------------------
	-- application plug-in messages here
	----------------------------------------------------
	local msg_type = msg.type;
	
	if(msg_type == MSGTYPE.APP_CONNECTION) then	
		-- Receives notification that the Add-in is being loaded.
		MyCompany.Aries.OnConnection(msg.app, msg.connectMode);
		
	elseif(msg_type == MSGTYPE.APP_DISCONNECTION) then	
		-- Receives notification that the Add-in is being unloaded.
		MyCompany.Aries.OnDisconnection(msg.app, msg.disconnectMode);

	elseif(msg_type == MSGTYPE.APP_QUERY_STATUS) then
		-- This is called when the command's availability is updated. 
		-- NOTE: this function returns a result. 
		msg.status = MyCompany.Aries.OnQueryStatus(msg.app, msg.commandName, msg.statusWanted);
		
	elseif(msg_type == MSGTYPE.APP_EXEC) then
		-- This is called when the command is invoked.
		MyCompany.Aries.OnExec(msg.app, msg.commandName, msg.params);
				
	elseif(msg_type == MSGTYPE.APP_RENDER_BOX) then	
		-- Change and render the 3D world with mcml data that is usually retrieved from the current user's profile page for this application. 
		MyCompany.Aries.OnRenderBox(msg.mcml);
		
	elseif(msg_type == MSGTYPE.APP_NAVIGATION) then
		-- Receives notification that the user wants to nagivate to the 3D world location relavent to this application
		MyCompany.Aries.Navigate();
	
	elseif(msg_type == MSGTYPE.APP_HOMEPAGE) then
		-- called when user clicks to check out the homepage of this application. 
		MyCompany.Aries.GotoHomepage();
	
	elseif(msg_type == MSGTYPE.APP_QUICK_ACTION) then
		-- called when user clicks the quick action for this application. 
		MyCompany.Aries.DoQuickAction();
	
	elseif(msg_type == MSGTYPE.APP_ACTIVATE_DESKTOP) then
		MyCompany.Aries.OnActivateDesktop();
		
	elseif(msg_type == MSGTYPE.APP_DEACTIVATE_DESKTOP) then
		MyCompany.Aries.OnDeactivateDesktop();
		
	elseif(msg_type == MSGTYPE.APP_WORLD_LOAD) then
		-- called whenever a new world is loaded (just before the 3d scene is enabled, yet after world data is loaded). 
		MyCompany.Aries.OnWorldLoad();
		
	elseif(msg_type == MSGTYPE.APP_WORLD_CLOSING) then
		-- called whenever a world is closing
		MyCompany.Aries.OnWorldClosing();
		
	elseif(msg_type == MSGTYPE.APP_WORLD_CLOSED) then
		-- called whenever a world is being closed.
		MyCompany.Aries.OnWorldClosed();
		
	elseif(msg_type == MSGTYPE.APP_CONNECTION_DISCONNECTED) then
		-- called whenever a world is being closed.
		MyCompany.Aries.OnConnectionDisconnected(msg.nid, msg.reason);
		
	----------------------------------------------------
	-- normal windows messages here
	----------------------------------------------------
	elseif(msg_type == CommonCtrl.os.MSGTYPE.WM_CLOSE) then
		
		
	elseif(msg_type == CommonCtrl.os.MSGTYPE.WM_SIZE) then
		
		
	elseif(msg_type == CommonCtrl.os.MSGTYPE.WM_HIDE) then
		
		
	elseif(msg_type == CommonCtrl.os.MSGTYPE.WM_SHOW) then
		
	end
end

local shader_version = nil;
-- shader version
function MyCompany.Aries.GetShaderVersion()
	if(not shader_version) then
		local att = ParaEngine.GetAttributeObject();
		local ps_Version = att:GetField("PixelShaderVersion", 0);
		local vs_Version = att:GetField("VertexShaderVersion", 0);
		shader_version = 0;
		if(vs_Version > ps_Version) then
			shader_version = ps_Version;
		else
			shader_version = vs_Version;
		end
	end	
	return shader_version;
end




--------------------------------------
-- replay mode related
--------------------------------------

-- call this function at world load time. 
function MyCompany.Aries.ResetTimeReverseMode()
	ReplayMode.moviekey_timer = ReplayMode.moviekey_timer or commonlib.Timer:new({callbackFunc = function(timer)
		if(not ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LSHIFT)) then
			-- shift key released
			if(ReplayMode.IsRecording()) then
				-- we shall stop timer if it is recording.  
				ReplayMode.moviekey_timer:Change();
				ReplayMode.StopEffect();
				LOG.std("", "system", "aries", "moviekey_timer stopped");
			elseif(ReplayMode.IsReversePlaying()) then
				-- we shall forward playing, if shift key is released.   
				ReplayMode.Play();
			end	
		else
			-- shift key is being pressed, we shall start reverse playing if not. 	
			if(not ReplayMode.IsReversePlaying()) then
				ReplayMode.ReversePlay();
			end
		end
	end})
	
	-- start player action recording
	ReplayMode.Restart();

	if(ReplayMode.moviekey_timer:IsEnabled()) then
		-- kill timer
		ReplayMode.moviekey_timer:Change();
	end
	ReplayMode.isFreezeReverse = false;
end

function MyCompany.Aries.EnterFreezeReverseMode()
	local worldinfo = WorldManager:GetCurrentWorld();
	if(worldinfo.can_reverse_time) then
		ReplayMode.isFreezeReverse = true;
		-- immediately stop the replay timer, and resume recording
		if(ReplayMode.moviekey_timer:IsEnabled()) then
			-- resume recording if user hit any key. 
			ReplayMode.moviekey_timer:Change();
			ReplayMode.ResumeRecord();
		end
	end
end

function MyCompany.Aries.LeaveFreezeReverseMode()
	ReplayMode.isFreezeReverse = false;
end


local last_connection_params;
local autorecover_timer;
local last_reconnect_time;
local max_reconnect_times = 3;
local reconnect_times = 0;
local function ForceDisconnectMsg()
	local last_world_session = MyCompany.Aries.WorldManager:SaveSessionCheckPoint();
	if(last_world_session) then
		Map3DSystem.App.Commands.Call("Profile.Aries.Restart", {method="soft", startup_msg={
				autorecover=true, last_user_nid=last_world_session.last_user_nid, 
				gs_nid = last_world_session.gs_nid, ws_id = last_world_session.ws_id,
				ws_seqid = last_world_session.ws_seqid, ws_text=last_world_session.ws_text,
			}});
	else
		Map3DSystem.App.Commands.Call("Profile.Aries.Restart", {method="soft", startup_msg=[[温馨提示：刚刚网络状态不太好， 请重新登录]]});
	end
end

local function ShowManualDisconnectMsg()
	_guihelper.MessageBox("本次连接已经断开，无法自动重连，请退出游戏并重新登陆！");
	BroadcastHelper.PushLabel({id="exit", label = "本次连接已经断开，无法自动重连，请退出游戏并重新登陆！", max_duration=200000000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
end

-- reconnect every 20 seconds, on fail a message box is popped up, on success, a reconnection tip is displayed. 
-- if the user has never logged in a world before, it will simply inform the user to restart. 
function MyCompany.Aries.Handle_Reconnect_Command(params)
	if(not last_connection_params) then
		ForceDisconnectMsg()
		return;
	end

	LOG.std("", "system", "aries", "File.Reconnect is called");

	-- whether we have shown the reconnect dialog to the user
	local is_reconnect_page_shown = false;
	
	autorecover_timer = autorecover_timer or commonlib.Timer:new({callbackFunc = function(timer)
		
		last_reconnect_time = ParaGlobal.timeGetTime();

		NPL.load("(gl)script/apps/Aries/Login/MainLogin.lua");
		MyCompany.Aries.MainLogin:RecoverConnection(function(msg)
			reconnect_times = (reconnect_times or 0) + 1;
			if (msg.connected) then	
				reconnect_times = 0;
				is_reconnect_page_shown = false;

				BroadcastHelper.PushLabel({id="exit", label = "刚刚您的网络状态不太好，我们帮您重新建立了服务器连接", max_duration=20000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
				LOG.std("", "system", "aries", "connection is re-established. Now connect to GSL again");
				if(last_connection_params) then
					MyCompany.Aries.Handle_ConnectWorld_Command(last_connection_params, true);
				end
			else
				local reason = msg.reason;
				if(reason == 444 or reason == 447 or reason == 446 or reason == 413) then
					ShowManualDisconnectMsg();
				else
					if( (reconnect_times or 0) < max_reconnect_times) then
						BroadcastHelper.PushLabel({id="exit", label = format("本次连接已经断开，正在尝试修复连接(第%d次)！", reconnect_times or 0), max_duration=20000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
						-- reconnect again every 20 seconds. 
						autorecover_timer:Change(20000, nil);
					else
						ShowManualDisconnectMsg();
					end
				end
			end
		end);
	end})
	
	if(not autorecover_timer:IsEnabled()) then
		if( (reconnect_times or 0) < max_reconnect_times) then
			-- reconnect immediately the first time we lost connection. 
			if(last_reconnect_time and (ParaGlobal.timeGetTime()-last_reconnect_time)<20000) then
				BroadcastHelper.PushLabel({id="exit", label = "本次连接已经断开，正在尝试修复连接！", max_duration=20000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
				autorecover_timer:Change(20000, nil)
			else
				autorecover_timer:Change(2000,nil)
			end	
		else
			ShowManualDisconnectMsg();
		end
	end	

end


-- handle "File.ConnectAriesWorld"
function MyCompany.Aries.Handle_ConnectWorld_Command(params, isReconnecting)
	-- connecting to Aries world server for the current world using GSL server
	-- Note: calling this multiple times, will disconnect previous gateway and reconnect. 
	-- this function is called whenever Jabber connection is established. 
	params = params or {};
	
	local worldpath = ParaWorld.GetWorldDirectory();
	LOG.std("", "system", "aries", "File.ConnectAriesWorld is called for %s", worldpath);
		
	-- never connect for initial empty world or worlds outside "worlds/" directory. 
	if(not string.match(worldpath, "worlds/")) then
		LOG.std("", "error", "aries", "File.ConnectAriesWorld is not possible for worlds outside worlds/ directory");
		-- make it ready anyway
		System.User.is_ready = true;
		return;
	end
	local SwfLoadingBarPage =  commonlib.gettable("Map3DSystem.App.MiniGames.SwfLoadingBarPage");
	-- LXZ: 2010.2.10 in case there is a design house, we will secretly change world path on the server side. 
	if(string.match(worldpath, "worlds/DesignHouse/")) then
		-- ensure there is always nid
		if(string.match(worldpath, "worlds/DesignHouse/userworlds/")) then
			local nid, slot_id, revision = (params.worldpath or worldpath):match("worlds/DesignHouse/userworlds/(%d+)_(%d+)_(%d+)%.zip$")
			if(nid) then
				params.nid = tonumber(nid);
				worldpath = format("worlds/DesignHouse/Local/%s/", slot_id);
				LOG.std("", "system", "File.ConnectAriesWorld", "load user world nid %s slot_id: %s", nid, slot_id);
			end
		else
			params.nid = params.nid or System.User.nid;
			worldpath = "worlds/DesignHouse/Local/";
		end
	end
		
	-- TODO: if world.gs_nid is different from the gateway nid, we need to establish a new connection to the game server.
	-- currently we will assume connection is established. 
		
	-- set the current game server and world server. 
	params.gs_nid = params.gs_nid or Map3DSystem.User.gs_nid;
	params.ws_id = params.ws_id or Map3DSystem.User.ws_id;
	Map3DSystem.User.gs_nid = params.gs_nid;
	Map3DSystem.User.ws_id = params.ws_id;
		
	local world_info = WorldManager:GetCurrentWorld();
	-- when client and server connect. Login to the server
	if(params.gs_nid and params.ws_id) then
		QuestClientLogics.Reset();
		NPL.load("(gl)script/apps/GameServer/GSL.lua");
		if(world_info) then
			Map3DSystem.GSL_client.RealtimePositionUpdateInterval = world_info.RealtimePositionUpdateInterval;
		end
		Map3DSystem.GSL_client:LoginServer(params.gs_nid, params.ws_id, worldpath, 
			{nid=params.nid, gridrule_id=params.gridnoderule_id, mode=params.mode, create_join=params.create_join, combat_is_started=params.combat_is_started, is_local_instance=params.is_local_instance, room_key=params.room_key, match_info = params.match_info});

		SwfLoadingBarPage.is_gsl_connecting_ = true;
		
		local function GetUserReadTextTime()
			if(params.start_time) then
				local min_user_read_text_time = if_else(System.options.isAB_SDK or Player.GetLevel()>45, 1000, 5000); -- always give the user 5 seconds to read text. 
				local end_time = ParaGlobal.timeGetTime();
				if( (end_time - params.start_time) <min_user_read_text_time) then
					return (math.max(1000, min_user_read_text_time - (end_time - params.start_time)))
				end
			end
			return 1000;
		end
		Map3DSystem.GSL_client:AddEventListener("OnLoginNode", function(client, proxy)
			NPL.load("(gl)script/apps/Aries/Chat/FamilyChatWnd.lua");
			MyCompany.Aries.Chat.FamilyChatWnd.ConnectToMyFamilyChatRoom();
				
			NPL.load("(gl)script/apps/Aries/NPCs/TownSquare/30341_HaqiGroupClient.lua");
			MyCompany.Aries.Quest.NPCs.HaqiGroupClient.Init();

			SwfLoadingBarPage.UpdateText("正在初始化任务模块");

			local bNoQuestForceFinished;
			local function on_finished_post_login()
				System.User.is_ready = true;
			end

			last_connection_params = commonlib.clone(params);

			if(world_info.ignore_quest) then 
				SwfLoadingBarPage.TryClosePageIfTrue("is_gsl_connecting_", "成功登录", GetUserReadTextTime(), on_finished_post_login);
			else
				QuestClientLogics.CallInit(function(bSucceed) 
					if(bNoQuestForceFinished) then
						BroadcastHelper.PushLabel({id="quest", label = format("任务系统初始化完毕"), max_duration=12000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
					end
					SwfLoadingBarPage.TryClosePageIfTrue("is_gsl_connecting_", "成功登录", GetUserReadTextTime(), on_finished_post_login);
					
					if(world_info.ticket_gsid) then
						local gsItem = ItemManager.GetGlobalStoreItemInMemory(world_info.ticket_gsid);
						if(gsItem) then
							local maxdailycount = gsItem.maxdailycount;
							local bHas, guid, bag, copies = ItemManager.IfOwnGSItem(world_info.ticket_gsid);
							BroadcastHelper.PushLabel({id="ticket", label = format("消耗门票一张. 今日剩余%d张免费门票", (copies or 1) -1), max_duration=6000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
						end
					end

					if(not bSucceed) then
						_guihelper.MessageBox("任务初始化失败了, 是否重新登录？", function(res)
							if(res and res == _guihelper.DialogResult.Yes) then
								System.App.Commands.Call("Profile.Aries.Restart", {method="soft"});
							end
						end, _guihelper.MessageBoxButtons.YesNo);
					end
				end);
				-- tricky: just in case that quest never returns and we forget to set world_info.ignore_quest to true, we will close after 10 seconds anyway.
				SwfLoadingBarPage.TryClosePageIfTrue("is_gsl_connecting_", nil, GetUserReadTextTime()+10000, function()
					LOG.std(nil,"error", "quest init", "quest never returns we will close after 10 seconds anyway.")
					BroadcastHelper.PushLabel({id="quest", label = format("任务系统还在初始化, 请再等一会儿"), max_duration=12000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
					bNoQuestForceFinished = true;
					on_finished_post_login();
				end);
			end

			NPL.load("(gl)script/apps/Aries/Team/TeamClientLogics.lua");
			local TeamClientLogics = commonlib.gettable("MyCompany.Aries.Team.TeamClientLogics");
			TeamClientLogics:QueryTeam()

			-- set max hp 
			Map3DSystem.GSL_client:SetAgentItem("mhp", MyCompany.Aries.Player.GetMaxHP());
		end)
			
		Map3DSystem.GSL_client:AddEventListener("OnLoginNodeRecover", function(client, msg)
			-- any login code that needs server recover should goes here. 
			LOG.std(nil, "system", "QuestClientLogics", "recover quest client logics");
			QuestClientLogics.CallInit();
		end)

		-- check for jc roster and not homeland gsl connect
		if(MyCompany.Aries.Chat and not params.nid) then
			-- only set presence if changed
			local presence = params.ws_id.."@"..params.gs_nid;
			if(presence ~= last_world_game_server_presence) then
				-- may be initiated before MyCompany.Aries.Chat is init
				local jc = MyCompany.Aries.Chat.GetConnectedClient();
				if(jc) then
					jc:SetPresence(-1, "", presence, 0);
				end
			end
		end
	else
		_guihelper.MessageBox("Server gsid or world_id not specified")
		System.User.is_ready = true;
	end	

	if(params.ws_text) then
		Map3DSystem.User.WorldServerName = params.ws_text;
		MyCompany.Aries.WorldServerName = params.ws_text;
	end
	if(params.ws_seqid) then
		Map3DSystem.User.WorldServerSeqId = params.ws_seqid;
		MyCompany.Aries.WorldServerSeqId = params.ws_seqid;
	end
end

-- handle "File.EnterAriesWorld"
-- @param params: 
function MyCompany.Aries.Handle_LoadWorld_Command(params)
	if(System.options.isAB_SDK) then
		-- Note: uncomment this to test loader movie and swf loader UI. 
		-- params.test_loader_movie = true;
	end
	-- Our custom load world function
	if(type(params) ~= "table") then return end
		
	-- close all battle related timers. 
	if(not System.options.mc and not System.options.IsTouchDevice) then
		-- we shall log out silently. 
		Map3DSystem.GSL_client:EnableReceive(false);
	
		NPL.load("(gl)script/apps/Aries/NPCs/Combat/39000_BasicArena.lua");
		MyCompany.Aries.Quest.NPCs.BasicArena.EnableGlobalTimer(false);

		-- reset combat msg handler. 
		NPL.load("(gl)script/apps/Aries/Combat/MsgHandler.lua");
		local MsgHandler = commonlib.gettable("MyCompany.Aries.Combat.MsgHandler");
		MsgHandler.ResetUI()
	end

	System.User.is_ready = false;
	System.options.is_mcworld = nil;

	local SwfLoadingBarPage =  commonlib.gettable("Map3DSystem.App.MiniGames.SwfLoadingBarPage");
	SwfLoadingBarPage.is_gsl_connecting_ = nil;

	if(LobbyClient.SetMatchInfo) then
		LobbyClient:SetMatchInfo(params.match_info);
	end
		
	local old_worldinfo = WorldManager:GetCurrentWorld();
	if(old_worldinfo and old_worldinfo.can_save_location and old_worldinfo.local_map_url) then
		-- remember the current player location before we load another world
		-- record the last visit world and position
		-- Bug Fix: double check world path, in case _emptyworld/ is used. 
		if(string.lower(ParaWorld.GetWorldDirectory()) == string.lower(old_worldinfo.worldpath).."/") then
			WorldManager:SetTeleportBackPosition();
			WorldManager:SetTeleportBackCamera(ParaCamera.GetEyePos());
		end
	end

	local worldinfo = WorldManager:GetWorldInfo(params.name or params.worldpath)
	params.worldpath = params.worldpath or worldinfo.worldpath;
	params.loader_movie_file = params.loader_movie_file or worldinfo.loader_movie_file;
	params.loader_asset_list = params.loader_asset_list or worldinfo.loader_asset_list;

	WorldManager:SaveWorldSession(params, worldinfo.allow_recover_connection);
	local is_standalone = params.is_standalone or worldinfo.is_standalone;
	if(not System.User.nid or System.User.nid == 0) then
		LOG.std(nil, "info", "Aries", "Forcing standalone mode since user is not connected. ")
		is_standalone = true;
	end

	local loadtxt= params.loadtxt or worldinfo.loading_text or L"加载当中,请稍等(首次需要3-5分钟)";
	
	local world_config_file = System.world:GetDefaultWorldConfigName(params.worldpath, true);

	if( not ParaIO.DoesAssetFileExist(params.worldpath or "", true) and 
		not ParaIO.DoesAssetFileExist(world_config_file or "", true)) then
		LOG.std(nil, "error", "Aries", params.worldpath.." does not exist. A default world is used instead.")
		-- TODO: if the world is not downloaded or does not exist, use a default world and download in the background. 
		return
	end
		
	-- terrain is not editable for non-local world in aries. This consumes less memory. 
	local is_terrain_editable = (params.tag == "MyLocalWorld" or params.tag == "MCWorld");
	ParaTerrain.GetAttributeObject():SetField("IsEditor", is_terrain_editable);
	if(is_terrain_editable) then
		ParaTerrain.GetAttributeObject():SetField("UseGeoMipmapLod", false);
	--elseif(System.options.version == "teen") then
	end

	local worldpath_lower = string.lower(params.worldpath);
	System.options.worldpath = params.worldpath;

	-- load asset replace file
	if(worldinfo.asset_replace_file) then
		ParaIO.LoadReplaceFile(worldinfo.asset_replace_file, false);
	end
		
	-- state machine memory		
	local stage_states = {};		
	local OnNextStage = nil; -- predefine function. 

	local is_movie_mode;
	local enter_movie_mode;
	local leave_movie_mode;
	local preloader;
	local play_movie_while_bg_loading = false;
	local start_time = ParaGlobal.timeGetTime();

	local canvas_ui_id;
	-- white canvas is used to hide async loading scene.
	local function create_white_canvas()
		if(not canvas_ui_id) then
			local _this = ParaUI.CreateUIObject("container", "screen_loader.canvas", "_fi", 0,0,0,0);
			_this.background = "Texture/whitedot.png";
			_this.zorder = 10;
			_this:AttachToRoot();
			canvas_ui_id = _this.id;
		end
	end
	local function fadeout_white_canvas()
		if(canvas_ui_id) then
			UIAnimManager.ChangeAlpha("screen_loader.canvas", ParaUI.GetUIObject(canvas_ui_id), 0, 64)
		end
	end
	local function remove_white_canvas()
		if(canvas_ui_id) then
			ParaUI.Destroy(canvas_ui_id);
		end
	end

	local function stage_preworld_loader()
		if(System.options.IsMobilePlatform or System.options.mc) then
			Map3DSystem.App.MiniGames.SwfLoadingBarPage.ShowPage(
				{ top = -50, show_background = true, worldname = worldinfo.name }
			);
			local SwfLoadingBarPage =  commonlib.gettable("Map3DSystem.App.MiniGames.SwfLoadingBarPage");
			SwfLoadingBarPage.UpdateText(L"正在加载请耐心等待");
			stage_states.preworld_loader = "done";
			local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
				OnNextStage();
			end})
			mytimer:Change(100, nil)
			return;
		end
		stage_states.preworld_loader = "waiting";
		-- world preloader
		if(bUseFlashLoader)then
			Map3DSystem.App.MiniGames.SwfLoadingBarPage.ShowPage(
				{ top = -50, show_background = true, worldname = worldinfo.name }
			);
			local SwfLoadingBarPage =  Map3DSystem.App.MiniGames.SwfLoadingBarPage;
			SwfLoadingBarPage.UpdateText(L"下载世界资源，请稍等(首次需要3-5分钟)");
		end
		--if(params.tag == "MCWorld") then
			---- mc world does not load any preworld assets
			--LOG.std("", "system", "preloader", "skipped loading preworld asset for paracraft worlds");
			--stage_states.preworld_loader = "done";
			--OnNextStage();
			--return;
		--end
		local loader = MyCompany.Aries.WorldAssetPreloader.GetLoaderForWorld(worldinfo.name or params.worldpath, params.worldpath)
		loader.callbackFunc = function(nItemsLeft, loader)
			LOG.std("", "system", "preloader", nItemsLeft.." assets remaining");
			local total_count = loader:GetAssetsCount();
			if(bUseFlashLoader)then
				local percent = (total_count-nItemsLeft)/(total_count+1);
				local SwfLoadingBarPage =  Map3DSystem.App.MiniGames.SwfLoadingBarPage;
				SwfLoadingBarPage.Update(percent);
			end
			if(nItemsLeft <= 0) then
				-- only continue real world loading after all preworld assets is loaded. 
				stage_states.preworld_loader = "done";
				OnNextStage();
			end
		end
		loader:Start();
	end

	-- try start the loader asset file if any
	local function stage_loader_asset_list()
		if(params.loader_asset_list and not (System.options.IsMobilePlatform or System.options.mc)) then
			stage_states.loader_asset_list = "waiting";
			
			-- Motion ------------------------------------------------------------
			NPL.load("(gl)script/ide/MotionEx/MotionFactory.lua");
			
			local player_name = "aries_scene_loading";
			local MotionFactory = commonlib.gettable("MotionEx.MotionFactory");
			local MotionRender = commonlib.gettable("MotionEx.MotionRender");
			local motion_player = MotionFactory.GetPlayer(player_name)

			LOG.std("", "system", "bgloader", "starting the background loader file :%s associated with this world", params.loader_asset_list);
			preloader = FileLoader.CreateGetLoader(params.loader_asset_list);
			preloader.logname = "log/Aries_PreloadList";
				
			--通知后台空闲下载开启
			preloader:AddEventListener("finish_ex",function(self,event)
				if(params.test_loader_movie) then
					return;
				end
				stage_states.loader_asset_list = "done";
				if(play_movie_while_bg_loading)then
					--后台下载
					--NPL.load("(gl)script/kids/3DMapSystemUI/MiniGames/BackgroundLoader.lua");
					--Map3DSystem.App.MiniGames.BackgroundLoader.Load();
					motion_player:Stop();
					MotionRender.ForceEnd();
				end
				LOG.std("", "system", "bgloader", "background loader file :%s finished. is_playing_before:%s", params.loader_asset_list, tostring(play_movie_while_bg_loading));
				OnNextStage()
			end,{});
			preloader:Start();
		else
			stage_states.loader_asset_list = "done";
		end
		OnNextStage();
	end
		

	local function stage_loadworld_immediate()
		stage_states.loadworld_immediate = "waiting";
		-- close music
		AudioEngine.StopAllSounds();

		local res;

		-- this will ensure that data is reset. 
		local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
		if(BroadcastHelper.Reset) then
			BroadcastHelper.Reset();
		end

		-- close any existing message box.
		_guihelper.CloseMessageBox(true);

		if(params.tag == "MCWorld") then
			System.options.is_mcworld = true;
			if(System.options.mc) then
				LOG.std(nil, "info", "LoadWorld", "real terrain is totally disabled for block world");
				ParaTerrain.GetAttributeObject():SetField("EnableTerrain", false);
			end
		else
			if(System.options.mc) then
				ParaTerrain.GetAttributeObject():SetField("EnableTerrain", true);
			end
		end

		-- pop any previous world effect 
		WorldManager:PopWorldEffectStates();
		
		res = System.LoadWorld({
				worldpath = params.worldpath,
				-- use exclusive desktop mode
				bExclusiveMode = true,
				OnProgress = function(percent)
					-- tricky: this may be called multiple times to ensure it is set even before the app onload event. 
					WorldManager:SetCurrentWorld(worldinfo)
						
					if(bUseFlashLoader)then
						if(percent == 0)then
							Map3DSystem.App.MiniGames.SwfLoadingBarPage.ShowPage(
								{ top = -50, show_background = true, worldname = worldinfo.name }
							);
						end
						SwfLoadingBarPage.UpdateText(loadtxt);
						SwfLoadingBarPage.Update(percent/100);
							
						if(percent >= 100)then
							commonlib.echo("load world 90% before render:----->"..tostring(ParaGlobal.timeGetTime()));
							SwfLoadingBarPage.Update(0.90);
							-- Force render takes a lot of time on first use, since it will load terrain and script, etc. 
							-- ParaEngine.ForceRender(); 
							commonlib.echo("load world 90% after render:----->"..tostring(ParaGlobal.timeGetTime()));
						else
							ParaEngine.ForceRender();
						end
					end
				end
			}, 
			-- perserve all user interface
			true,
			-- hide progress bar UI
			bUseFlashLoader)
		params.res = res;
		
		if(res == true) then
			-- load world is finished;
			stage_states.loadworld_immediate = "done";

			-- switch to Aries app_main desktop and make it default.
			System.UI.AppDesktop.SetDefaultApp("Aries_GUID", true);
				
			-- Do something after the load	
			if(not params.role) then
				-- no role is specified. 
				if(System.World.readonly) then
					System.User.SetRole("poweruser");
				else
					System.User.SetRole("administrator");
				end
			else
				-- role is specified. 
				System.User.SetRole(params.role);
				if(params.role == "administrator") then
					if(System.World.readonly) then
						System.User.SetRole("poweruser");
					end
				end
			end
				
			if(params.movie and params.movie~="") then
				System.App.Commands.Call("File.PlayMovieScript", params.movie);
			end

			ParaTerrain.GetBlockAttributeObject():SetField("IsRemote", params.isRemoteWorld == true);

			ParaScene.GetAttributeObject():SetField("MinPopUpDistance", worldinfo.MinPopUpDistance or 50);

			ParaScene.GetAttributeObject():SetField("UseDropShadow", not ParaScene.GetAttributeObject():GetField("SetShadow", false));

			local worldpath = ParaWorld.GetWorldDirectory();
			if(params.tag == "MCWorld") then
				System.options.is_mcworld = true;
			else
				-- leave previous block world.
				ParaTerrain.LeaveBlockWorld();

				if(commonlib.getfield("MyCompany.Aries.Game.is_started")) then
					-- if the MC block world is started before, exit it. 
					NPL.load("(gl)script/apps/Aries/Creator/Game/main.lua");
					local Game = commonlib.gettable("MyCompany.Aries.Game")
					Game.Exit();
				end

				-- we will load blocks if exist. 
				if(	ParaIO.DoesAssetFileExist(format("%sblockWorld.lastsave/blockTemplate.xml", worldpath), true) or
					ParaIO.DoesAssetFileExist(format("%sblockWorld/blockTemplate.xml", worldpath), true) ) then	

					if(params.tag == "MyLocalWorld") then					
						-- this fix a bug that initial position is set to a fixed value instead of reading from world for old creative space 
						local Settings = commonlib.gettable("Map3DSystem.World.Settings");
						if(Settings.PlayerX) then
							params.PosX, params.PosY, params.PosZ = Settings.PlayerX, Settings.PlayerY, Settings.PlayerZ;
							--ParaScene.GetPlayer():SetPosition(Settings.PlayerX, Settings.PlayerY, Settings.PlayerZ);
						end
					end

					NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
					local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
					GameLogic.StaticInit();
				end

				-- set player density if any
				if(worldinfo and not is_standalone) then
					Player.RefreshDensity();
				end
			end
		else
			if(type(res) == "string") then
				-- show the error message
				_guihelper.MessageBox(res);
			end
			stage_states.loadworld_immediate = "failed";
		end
		OnNextStage();
	end
	
	local function state_pre_login_motion_file()
		stage_states.pre_login_motion_file = "done";
		if(System.options.mc) then
			OnNextStage();
			return
		end

		NPL.load("(gl)script/ide/MotionEx/MotionXmlToTable.lua");
		local MotionXmlToTable = commonlib.gettable("MotionEx.MotionXmlToTable");

		if(params.cg_movie_file) then
			create_white_canvas();
		end
		if(worldinfo.pre_login_motion_file and MotionXmlToTable.CanPlayMovie(worldinfo.pre_login_motion_file)) then
			create_white_canvas();
		end

		if(worldinfo.pre_login_motion_file and MotionXmlToTable.CanPlayMovie(worldinfo.pre_login_motion_file)) then
			if(play_movie_while_bg_loading) then
				LOG.std(nil, "warn", "app_main", "pre_login_motion_file and loader_asset_list can not coexist. pre_login_motion_file is ignored.")
			else
				stage_states.pre_login_motion_file = "waiting";
				enter_movie_mode();
				SwfLoadingBarPage.ClosePage(); -- close swf loading bar when playing pre_login movie. 
				
				-- we will play the motion file to end and then connect to the GSL gridnode. 
				
				-- disable camera collision
				ParaCamera.GetAttributeObject():SetField("PhysicsGroupMask", 268435456); -- 0x10000000

				MotionXmlToTable.PlayCombatMotion(worldinfo.pre_login_motion_file, function()
					stage_states.pre_login_motion_file = "done";

					-- re-enable camera collision
					ParaCamera.GetAttributeObject():SetField("PhysicsGroupMask", 4294967295);

					if(bUseFlashLoader and not System.User.is_ready)then
						SetPlayerFreeze(true);
						Map3DSystem.App.MiniGames.SwfLoadingBarPage.ShowPage(
							{ top = -50, show_background = false, worldname = worldinfo.name }
						);
					end
					OnNextStage();
				end);
			end
		end
		OnNextStage();
	end

	local function stage_connect_world()
		-- we will enable rest keep alive only if it is a standalone world. 
		if(GameServer and GameServer.rest and GameServer.rest.client) then
			GameServer.rest.client:EnableKeepAlive(is_standalone);
		end
		params.world_size = params.world_size or worldinfo.locked_world_size;

		
		if(bUseFlashLoader)then
			commonlib.echo("load world 99%:----->"..tostring(ParaGlobal.timeGetTime()));
			SwfLoadingBarPage.Update(0.99);	-- ParaEngine.ForceRender();
			SwfLoadingBarPage.UpdateText("正在登录游戏服务器");
		end

		if(is_standalone) then
			stage_states.connect_world = "done";
			-- standalone mode will just log out the server. 
			local GSL_client = commonlib.gettable("Map3DSystem.GSL_client");
			if(GSL_client.LogoutServer) then
				GSL_client:LogoutServer(true);
			end
			System.User.is_ready = true;
			last_connection_params = nil;
		else
			NPL.load("(gl)script/apps/Aries/Player/OPC.lua");
			MyCompany.Aries.OPC.OnWorldLoaded();
			stage_states.connect_world = "waiting";
			params.gridnoderule_id = params.gridnoderule_id or worldinfo.gridnoderule_id;

			-- whether it is the local instance. 
			if(params.is_local_instance == nil) then
				params.is_local_instance = worldinfo.is_local_instance;
			end

			-- in case it is multi-user instance world, we may force a given nid. 
			params.nid = params.force_nid or worldinfo.force_nid or params.nid;
					
			if(params.create_join or worldinfo.create_join) then
				params.create_join = params.create_join or worldinfo.create_join;
				-- lock player movement in 40 meters range
				-- Tricky: if both create_join and is_local_instance is true, we will use the local server to find best fit instance game world
				if(params.is_local_instance or worldinfo.is_local_instance) then
					params.nid = nil;
					params.is_local_instance = nil;
				end
			end
			params.start_time = start_time;

			-- connect to GSL server
			System.App.Commands.Call("File.ConnectAriesWorld", params);
			-- connect to quest server
			System.App.Commands.Call("File.ConnectAriesQuest", params);

			if(System.User.is_ready) then
				stage_states.connect_world = "done";
			else
				local timer = commonlib.Timer:new({callbackFunc = function(timer)
					if(System.User.is_ready) then
						timer:Change();
						stage_states.connect_world = "done";
						OnNextStage();
					end
				end})
				timer:Change(500,500);
			end
		end
		OnNextStage();
	end

	local function LoadInitialPlayerPos()
		if(System.options.mc) then
			return;
		end
		local player = Player.GetPlayer();
			
		if(params.PosX and params.PosZ) then
			local x, z = params.PosX, params.PosZ;
			if(params.PosRadius) then
				local radius = params.PosRadius;
				x = x + (math.random()*2-1)*radius;
				z = z + (math.random()*2-1)*radius;
			end
			if(params.PosY) then
				player:SetPosition(x, params.PosY, z);
			else
				player:SetPosition(x, 0, z);
				player:SnapToTerrainSurface(0);
			end
			if(params.PosFacing) then
				player:SetFacing(params.PosFacing);
			end
		elseif(worldinfo.born_pos) then
			local x,y,z = worldinfo.born_pos.x, worldinfo.born_pos.y, worldinfo.born_pos.z;
			local radius = worldinfo.born_pos.radius;
			local facing = worldinfo.born_pos.facing;
			if(radius) then
				x = x + (math.random()*2-1)*radius;
				z = z + (math.random()*2-1)*radius;
			end
			if(y and not radius) then
				player:SetPosition(x, y, z);
			else
				player:SetPosition(x, 0, z);
				player:SnapToTerrainSurface(0);
			end
			if(facing) then
				player:SetFacing(facing);
			end
		end
		if(params.CameraObjectDistance and params.CameraLiftupAngle and params.CameraRotY) then
			local att = ParaCamera.GetAttributeObject();
			att:SetField("CameraObjectDistance", params.CameraObjectDistance);
			att:SetField("CameraLiftupAngle", params.CameraLiftupAngle);
			att:SetField("CameraRotY", params.CameraRotY);
		else
			AutoCameraController:RestoreCamera();
		end

		if(params.world_size) then
			-- set the world size. 
			local x, y, z = player:GetPosition();
			local world_radius = params.world_size / 2;
			player:SetMovableRegion(worldinfo.world_center_x or x, y, worldinfo.world_center_z or z, world_radius,world_radius,world_radius);
			LOG.std("", "system", "aries", "player MovableRegion is changed to radius: %d", world_radius)
		else
			LOG.std("", "system", "aries", "player MovableRegion is changed to radius: %d", 8000)
			player:SetMovableRegion(16000,0,16000, 16000,16000,16000);
		end	
	end

	local function stage_set_initial_player_position()
		stage_states.set_initial_player_position = "done";

		LoadInitialPlayerPos();

		-- for local world, enter edit mode directly, for other people's world, we may only enter normal mode. 
		NPL.load("(gl)script/apps/Aries/Creator/MainToolBar.lua");
		if(params.tag == "MyLocalWorld") then
			MyCompany.Aries.Creator.MainToolBar.EnterEditMode();
					
			NPL.load("(gl)script/apps/Aries/Creator/AI/LocalNPC.lua");
			local LocalNPC = commonlib.gettable("MyCompany.Aries.Creator.AI.LocalNPC")
			LocalNPC:Init();
			if(LocalNPC:LoadFromFile()) then
				-- local NPC file loaded. 
			end
		else
			if(not System.options.mc) then
				MyCompany.Aries.Creator.MainToolBar.ExitEditMode();
			end
		end	

		OnNextStage();
	end

	local function stage_play_cg_movie()
		if(params.cg_movie_file) then
			stage_states.play_cg_movie= "waiting";
			NPL.load("(gl)script/ide/MotionEx/MotionXmlToTable.lua");
			local MotionXmlToTable = commonlib.gettable("MotionEx.MotionXmlToTable");
	
			enter_movie_mode();
			SwfLoadingBarPage.ClosePage(); -- close loader when movie is playing

			MotionXmlToTable.PlayCombatMotion(params.cg_movie_file, function()
				stage_states.play_cg_movie= "done";
				
				OnNextStage();
			end);
		else
			stage_states.play_cg_movie= "done";
		end
		OnNextStage();
	end

	local function stage_play_loader_movie()
		stage_states.play_loader_movie = "done";
		-- bind downloader to UI, only start if bigger than 2048 KB
		-- Note: uncomment this to test loader movie and swf loader UI. 
		
		if(  params.loader_movie_file and preloader and 
			(params.test_loader_movie or ((not preloader.isFinished) and preloader:GetAllFileSize() > 2048)) )then
			play_movie_while_bg_loading = true;
			enter_movie_mode();

			-- Motion ------------------------------------------------------------
			NPL.load("(gl)script/ide/MotionEx/MotionFactory.lua");
			local player_name = "aries_scene_loading";
			local MotionFactory = commonlib.gettable("MotionEx.MotionFactory");
			local MotionRender = commonlib.gettable("MotionEx.MotionRender");
			local motion_player = MotionFactory.GetPlayer(player_name)
			
			--循环播放
			motion_player:AddEventListener("end",function()
				motion_player:Play();
			end,{});
			MotionFactory.CreateCameraMotionFromFile(player_name, params.loader_movie_file);
			motion_player:Play();

			Map3DSystem.App.MiniGames.SwfLoadingBarPage.BindLoaderAndShowPage({ align="_ctt", top=35, left=0, downloader = preloader, state = "advanced", notShowTxt = true, });
		end

		OnNextStage();
	end

	local function stage_finished()
		stage_states.finished = "done";
		
		leave_movie_mode();

		SwfLoadingBarPage.ClosePage(); -- close swf loader

		if(type(params.on_finish) == "function") then
			params.on_finish(res);
		end
	end

	enter_movie_mode = function()
		MyCompany.Aries.Desktop.HideAllAreas();
		SetPlayerFreeze(true);
		is_movie_mode = true;
		fadeout_white_canvas();
	end

	leave_movie_mode = function()
		if(is_movie_mode) then
			is_movie_mode = nil;
			LoadInitialPlayerPos();
			MyCompany.Aries.Desktop.ShowAllAreas();
					
			local player = Player.GetPlayer();
			if(player and player:IsValid())then
				player:ToCharacter():SetFocus();
			end
			SetPlayerFreeze(false);
		end
		remove_white_canvas();
	end

	-- state machine processor. 
	OnNextStage = function()
		LOG.std(nil, "debug", "LoadWorld_stage_change", stage_states);
		if(stage_states.preworld_loader == nil) then
			stage_preworld_loader();
		elseif(stage_states.loader_asset_list == nil) then
			stage_loader_asset_list();
		elseif(stage_states.loadworld_immediate == nil) then
			stage_loadworld_immediate();
		elseif(stage_states.loadworld_immediate == "failed") then
			return;
		elseif(stage_states.loadworld_immediate == "done") then
			if(stage_states.pre_login_motion_file == nil) then
				state_pre_login_motion_file();
			elseif(stage_states.set_initial_player_position == nil) then
				stage_set_initial_player_position();
			elseif(stage_states.pre_login_motion_file == "done") then
				if(stage_states.connect_world == nil) then
					stage_connect_world();
				elseif(stage_states.connect_world == "done") then
					if(stage_states.play_loader_movie == nil) then
						stage_play_loader_movie();
					elseif(stage_states.play_loader_movie == "done" and (not params.loader_movie_file or stage_states.loader_asset_list == "done") ) then
						-- not if there is no loader_movie_file, we will not wait loader_asset_list to finish before continue. 
						if(stage_states.play_cg_movie == nil) then
							stage_play_cg_movie();
						elseif(stage_states.play_cg_movie == "done") then
							if(stage_states.finished == nil) then
								-- everything is finished now
								stage_finished();
							end
						end
					end
				end
			end
		end
	end

	-- now start the state machine
	OnNextStage();
end
