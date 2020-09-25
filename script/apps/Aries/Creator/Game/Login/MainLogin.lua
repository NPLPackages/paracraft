--[[
Title: MC Main Login Procedure
Author(s):  LiXizhi
Company: ParaEngine
Date: 2013.10.14
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/MainLogin.lua");
MyCompany.Aries.Game.MainLogin:start();
------------------------------------------------------------
]]
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

-- create class
local MainLogin = commonlib.gettable("MyCompany.Aries.Game.MainLogin");

-- the initial states in the state machine. 
-- Please see self:next_step() for more information on the meaning of these states. 
MainLogin.state = {
	CheckGraphicsSettings = nil,
	IsUpdaterStarted = nil,
	IsBrowserUpdaterStarted = nil,
	Loaded3DScene = nil,
	IsCommandLineChecked = nil,
	IsPackagesLoaded = nil,
	IsLoginModeSelected = nil,
	IsPluginLoaded = nil,
	HasSignedIn = nil,
	HasInitedTexture = nil,
	
	IsLoadMainWorldRequested = nil,
	IsCreateNewWorldRequested = nil,
	IsLoadTutorialWorldRequested = nil, -- NOT used
	
	-- the background 3d world path during login. This is set during Updater progress. We can display some news and movies in it. 
	login_bg_worldpath = nil,
};

-- start the login procedure. Only call this function once. 
-- @param init_callback: the one time init function to be called to load theme and config etc.
function MainLogin:start(init_callback)
	-- initial states
	MainLogin.state = {};
	self.init_callback = init_callback;
	
	NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/pe_mc_mcml.lua");
	MyCompany.Aries.Game.mcml_controls.register_all();

	-- register external functions for each login step. Each handler's first parameter is MainLogin class instance. 
	-- TODO: add your custom handlers here. 
	self.handlers = self.handlers or {
		-- check for graphics settings
		CheckGraphicsSettings = self.CheckGraphicsSettings,
		-- load the background 3d scene
		LoadBackground3DScene = self.LoadBackground3DScene,
		-- update the core ParaEngine and minimal art assets. The logo page is also displayed here. 
		UpdateCoreClient = self.UpdateCoreClient,
		-- update buildin chrome browser under win32
		UpdateCoreBrowser = self.UpdateCoreBrowser,
		-- check command line
		CheckCommandLine = self.CheckCommandLine,
		-- Load buildin packages and mod
		LoadPackages = self.LoadPackages,
		-- select local or internet game
		ShowLoginModePage = self.ShowLoginModePage,

		-- load all modules/plugins
		LoadPlugins = self.LoadPlugins,

		HasInitedTexture = self.HasInitedTexture,

		-- connect main world
		LoadMainWorld = self.LoadMainWorld,
		-- create new world
		ShowCreateWorldPage = self.ShowCreateWorldPage,
	}
	self:next_step();
	
end

-- invoke a handler 
function MainLogin:Invoke_handler(handler_name)
	if(self.handlers and self.handlers[handler_name]) then
		LOG.std("", "system","Login", "=====>Login Stage: %s", handler_name);
		self.handlers[handler_name](self);
	else
		LOG.std("", "error","Login", "error: unable to find login handler %s", handler_name);
	end
end

-- perform next step. 
-- @param state_update: This can be nil, it is a table to modify the current state. such as {IsLocalUserSelected=true}
function MainLogin:next_step(state_update)
	local state = self.state;
	if(state_update) then
		commonlib.partialcopy(state, state_update);

		if(not state.IsLoginModeSelected) then
			state.HasSignedIn = false;
		end
	end
	if(not state.IsInitFuncCalled) then
		if(self.init_callback) then
			self.init_callback();
		end
		System.options.version = "kids";
		if(not System.options.mc) then
			NPL.load("(gl)script/apps/Aries/Login/ExternalUserModule.lua");
			local ExternalUserModule = commonlib.gettable("MyCompany.Aries.ExternalUserModule");
			if(ExternalUserModule.Init) then
				ExternalUserModule:Init(true);
			end
		end
		NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
		self:next_step({IsInitFuncCalled = true});
	elseif(not state.IsPackagesLoaded) then
		self:Invoke_handler("LoadPackages");
	elseif(not state.CheckGraphicsSettings) then
		self:Invoke_handler("CheckGraphicsSettings");
	elseif(not state.Loaded3DScene) then
		if(not System.options.isAB_SDK) then
			-- uncomment to enable 3d bg scene during login
			-- state.login_bg_worldpath = "worlds/DesignHouse/CreatorLoginBG";
		end
		self:Invoke_handler("LoadBackground3DScene");
	elseif(not state.IsUpdaterStarted) then	
		self:Invoke_handler("UpdateCoreClient");
	elseif(not state.IsBrowserUpdaterStarted) then	
		self:Invoke_handler("UpdateCoreBrowser");
	elseif(not state.IsCommandLineChecked) then
		self:Invoke_handler("CheckCommandLine");
	elseif(not state.IsLoginModeSelected) then
		self:Invoke_handler("ShowLoginModePage");
	elseif(not state.IsPluginLoaded) then
		self:Invoke_handler("LoadPlugins");
	elseif(not state.HasInitedTexture) then
		self:Invoke_handler("HasInitedTexture");
	else
		-- already signed in 
		if(not state.IsLoadMainWorldRequested) then	
			self:Invoke_handler("LoadMainWorld");
		-- don't load the exsiting world ,can call   [[self:Invoke_handler("ShowCreateWorldPage")]]    enter the create new world page
		elseif(not state.IsCreateNewWorldRequested) then	
			self:Invoke_handler("ShowCreateWorldPage");
		end
	end
end

function MainLogin:UpdateCoreClient()
	local platform = System.os.GetPlatform();

	NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ClientUpdater.lua");
	local ClientUpdater = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ClientUpdater");
	
	local testCoreClient = false
	if(not testCoreClient and platform=="win32")then
		-- win32 will check for latest version, but will not force update instead it just pops up a dialog. 
		self:next_step({IsUpdaterStarted = true});
		if(not System.options.isAB_SDK and ParaEngine.GetAppCommandLineByParam("noclientupdate", "")=="") then
			local AutoUpdater = NPL.load("AutoUpdater");
			local updater = AutoUpdater:new();
			local gamename = "Paracraft"
			gamename = GameLogic.GetFilters():apply_filters('GameName', gamename)

			updater:onInit(ParaIO.GetWritablePath(), ClientUpdater:GetUpdateConfigFilename(), function(state)	end)
			updater:check(nil, function(bSucceed)
				if(bSucceed and updater:isNeedUpdate()) then
					System.App.Commands.Call("File.MCMLWindowFrame", {
						url = format("script/apps/Aries/Creator/Game/Login/ClientUpdateDialog.html?latestVersion=%s&curVersion=%s&curGame=%s", updater:getLatestVersion(), updater:getCurVersion(), gamename), 
						name = "ClientUpdateDialog", 
						isShowTitleBar = false,
						DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
						style = CommonCtrl.WindowFrame.ContainerStyle,
						zorder = 1,
						allowDrag = false,
						isTopLevel = true,
						directPosition = true,
							align = "_ct",
							x = -210,
							y = -100,
							width = 420,
							height = 250,
					});
				end
			end);
		end
		return
	end
	
	-- check for mini-allowed core nplruntime version
	local updater = ClientUpdater:new();

	local function CheckMiniVersion_(ver)
		local v1,v2,v3 = ver:match("(%d+)%D(%d+)%D(%d+)")
		if(v3) then
			v1,v2,v3 = tonumber(v1),tonumber(v2), tonumber(v3)
			-- NOTE: version here 0.7.509
			local isCodepku = ParaEngine.GetAppCommandLineByParam("isCodepku", "false") == "true"

			if(not isCodepku and (v1 < 0 or v2 < 7 or v3 < 510)) then
				_guihelper.MessageBox(format(L"您的版本%s低于最低要求,请尽快更新", ver), function(res)
					if(res and res == _guihelper.DialogResult.Yes) then
						ClientUpdater:OnClickUpdate()
					end
					self:next_step({IsUpdaterStarted = true});
				end, _guihelper.MessageBoxButtons.YesNo);
				return false
			end
		end
		return true;
	end

	if(System.options.paraworldapp == ClientUpdater.appname) then
		local ver = ParaEngine.GetAppCommandLineByParam("nplver", "")
		if(CheckMiniVersion_(ver)) then
			self:next_step({IsUpdaterStarted = true});
		end
		return
	end

	if (platform == 'mac' or System.os.GetPlatform() == "ios") then
		GameLogic.GetFilters():apply_filters("ShowClientUpdaterNotice")
	end

	updater:Check(function(bNeedUpdate, latestVersion)
		if (platform == 'mac' or System.os.GetPlatform() == "ios") then
			GameLogic.GetFilters():apply_filters("HideClientUpdaterNotice")
		end

		if(bNeedUpdate) then
			updater:Download(function(bSucceed)
				if(bSucceed) then
					updater:Restart()
				else
					self:next_step({IsUpdaterStarted = true});
				end
			end)
		else
			if(updater:GetCurrentVersion() ~= latestVersion) then
				updater:Restart()
			else
				self:next_step({IsUpdaterStarted = true});
			end
		end
	end);
end


function MainLogin:UpdateCoreBrowser()
	local platform = System.os.GetPlatform();
	if(platform=="win32")then
		NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserLoaderPage.lua");
        local NplBrowserLoaderPage = commonlib.gettable("NplBrowser.NplBrowserLoaderPage");
        NplBrowserLoaderPage.CheckOnce()
	end
	MainLogin:next_step({IsBrowserUpdaterStarted = true});
end

function MainLogin:CheckGraphicsSettings()
	if(System.options.mc or System.options.servermode) then
		MainLogin:next_step({CheckGraphicsSettings = true});
		return;
	end
	-- check for graphics settings, this step is moved here so that it will show up in web browser as well.
	NPL.load("(gl)script/apps/Aries/Desktop/AriesSettingsPage.lua");
	MyCompany.Aries.Desktop.AriesSettingsPage.CheckMinimumSystemRequirement(true, function(result, sMsg)
		if(result >=0 ) then
			self:AutoAdjustGraphicsSettings();
		else
			-- exit because PC is too old. 
		end
	end);
end 

function MainLogin:AutoAdjustGraphicsSettings()
	if(System.options.mc or System.options.servermode) then
		MainLogin:next_step({CheckGraphicsSettings = true});
		return;
	end
	MyCompany.Aries.Desktop.AriesSettingsPage.AutoAdjustGraphicsSettings(false, 
		function(bChanged) 
			if(ParaEngine.GetAttributeObject():GetField("HasNewConfig", false)) then
				ParaEngine.GetAttributeObject():SetField("HasNewConfig", false);
				_guihelper.MessageBox(L"您上次运行时更改了图形设置. 是否保存目前的显示设置.", function(res)	
					if(res and res == _guihelper.DialogResult.Yes) then
						-- pressed YES
						ParaEngine.WriteConfigFile("config/config.txt");
					end
					MainLogin:next_step({CheckGraphicsSettings = true});
				end, _guihelper.MessageBoxButtons.YesNo)
			else
				MainLogin:next_step({CheckGraphicsSettings = true});
			end
		end,
		-- OnChangeCallback, return false if you want to dicard the changes. 
		function(params)
			if(System.options.IsWebBrowser) then
				if(params.new_effect_level) then
					MyCompany.Aries.Desktop.AriesSettingsPage.AdjustGraphicsSettingsByEffectLevel(params.new_effect_level)
				end
				if(params.new_screen_resolution) then
					local x,y = params.new_screen_resolution[1], params.new_screen_resolution[2];
					if(x == 800) then  x = 720 end
					if(y == 533) then y = 480 end
					commonlib.log("ask web browser host to change resolution to %dx%d\n", x,y);
					commonlib.app_ipc.ActivateHostApp("change_resolution", nil, x, y);
				end
				return false;
			end
		end);
end

-- login handler
function MainLogin:LoadBackground3DScene()
	if(System.options.servermode) then
		return self:next_step({Loaded3DScene = true});
	end

	local titlename = GameLogic.GetFilters():apply_filters('GameName', L"帕拉卡 Paracraft")
	local desc = GameLogic.GetFilters():apply_filters('GameDescription', L"3D动画编程创作工具")

	System.options.WindowTitle = string.format("%s -- ver %s", titlename, GameLogic.options.GetClientVersion());
	ParaEngine.SetWindowText(format("%s : %s", System.options.WindowTitle, desc));

	-- just in case it is from web browser. inform to switch to 3d display. 
	if(System.options.IsWebBrowser) then
		commonlib.app_ipc.ActivateHostApp("preloader", "", 100, 1);
	end

	-- always disable AA for mc. 
	if(ParaEngine.GetAttributeObject():GetField("MultiSampleType", 0)~=0) then
		ParaEngine.GetAttributeObject():SetField("MultiSampleType", 0);
		LOG.std(nil, "info", "FancyV1", "MultiSampleType must be 0 in order to use deferred shading. We have set it for you. you must restart. ");
		ParaEngine.WriteConfigFile("config/config.txt");
	end

	local FancyV1 = GameLogic.GetShaderManager():GetFancyShader();
	if(false and FancyV1.IsHardwareSupported()) then
		GameLogic.GetShaderManager():SetShaders(2);
		GameLogic.GetShaderManager():SetUse3DGreyBlur(true);
	end

	if(self.state.login_bg_worldpath) then
		local world
		Map3DSystem.UI.LoadWorld.LoadWorldImmediate(self.state.login_bg_worldpath, true, true, function(percent)
				if(percent == 100) then
					local worldpath = ParaWorld.GetWorldDirectory();

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

						NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
						local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
						GameLogic.StaticInit(1);
					end

					-- block user input
					ParaScene.GetAttributeObject():SetField("BlockInput", true);
					--ParaCamera.GetAttributeObject():SetField("BlockInput", true);

					-- MyCompany.Aries.WorldManager:PushWorldEffectStates({ bUseShadow = true, bFullScreenGlow=true})

					-- replace main character with dummy
					local player = ParaScene.GetPlayer();
					player:ToCharacter():ResetBaseModel(ParaAsset.LoadParaX("", ""));
					player:SetDensity(0); -- make it flow in the air
					--ParaScene.GetAttributeObject():SetField("ShowMainPlayer", false);
				end
			end)
	else
		self:ShowLoginBackgroundPage(true, true, true, true);
	end	
	self:next_step({Loaded3DScene = true});
end

function MainLogin:HasInitedTexture()
	if(System.options.servermode) then
		return self:next_step({HasInitedTexture = true});
	end
	NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/TextureModPage.lua");
	local TextureModPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.TextureModPage");

	TextureModPage.OnInitDS()
	self:next_step({HasInitedTexture = true});
end


function MainLogin:CheckCommandLine()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Login/UrlProtocolHandler.lua");
	local UrlProtocolHandler = commonlib.gettable("MyCompany.Aries.Creator.Game.UrlProtocolHandler");
	UrlProtocolHandler:CheckInstallUrlProtocol();
	UrlProtocolHandler:ParseCommand(ParaEngine.GetAppCommandLine());
	if(System.options.servermode) then
		-- TODO: for server only world
		if(not System.options.cmdline_world or System.options.cmdline_world=="") then
			System.options.cmdline_world = "worlds/DesignHouse/defaultserverworld";
			LOG.std(nil, "warn", "serverworld", "no server world specified, we will use %s", System.options.cmdline_world);
		end
	end

	-- in case, a request comes when application is already running. 
	commonlib.EventSystem.getInstance():AddEventListener("CommandLine", function(self, msg)
		local curWorldpath = System.options.cmdline_world;
		UrlProtocolHandler:ParseCommand(msg.msg);
		if(System.options.cmdline_world) then
			-- TODO: shall we ask the user to confirm before automatically download and login. 
			self:CheckLoadWorldFromCmdLine(true);
		end
		return true;
	end, self);

	self:next_step({IsCommandLineChecked = true});	
end


function MainLogin:PreloadDailyCheckinAndTeachingWnd()
	if(not System.options.cmdline_world or System.options.cmdline_world == "") then
		local platform = System.os.GetPlatform();
		if(platform=="win32")then
			local NplBrowserManager = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserManager.lua");
			local cef_preshow = ParaEngine.GetAppCommandLineByParam("cef_preshow", "true");
			if(cef_preshow == "true")then
				-- TODO: shall we move preloader to a later phase, no need to be on startup!
				NplBrowserManager:PreShowWnd("DailyCheckBrowser")
				NplBrowserManager:PreShowWnd("TeachingQuest_BrowserPage")
			end
		end
	end
end

-- load predefined mod packages if any
function MainLogin:LoadPackages()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Login/BuildinMod.lua");
	local BuildinMod = commonlib.gettable("MyCompany.Aries.Game.MainLogin.BuildinMod");
	BuildinMod.AddBuildinMods();

	self:PreloadDailyCheckinAndTeachingWnd();

	self:next_step({IsPackagesLoaded = true});
end

function MainLogin:CheckShowTouchVirtualKeyboard()
	if(System.options.IsTouchDevice) then
		local TouchVirtualKeyboardIcon = GameLogic.GetFilters():apply_filters("TouchVirtualKeyboardIcon");
		if not TouchVirtualKeyboardIcon then
			NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/TouchVirtualKeyboardIcon.lua");
			TouchVirtualKeyboardIcon = commonlib.gettable("MyCompany.Aries.Game.GUI.TouchVirtualKeyboardIcon");
		end

		TouchVirtualKeyboardIcon.ShowSingleton(true);
	end
end

-- call this before any UI is drawn
function MainLogin:AutoAdjustUIScalingForTouchDevice(callbackFunc)
	if(System.options.IsTouchDevice) then
		NPL.load("(gl)script/ide/System/Windows/Screen.lua");
		local Screen = commonlib.gettable("System.Windows.Screen");

		local function AutoAdjustUIScaling_()
			local touch_ui_height = 680;
			local frame_size = ParaEngine.GetAttributeObject():GetField("ScreenResolution", {1020,680});
			local frame_height = frame_size[2];
			if(frame_height == 0) then
				frame_height = Screen:GetHeight();
				LOG.std(nil, "error", "TouchDevice", "ScreenResolution not implemented");
			end
			LOG.std(nil, "info", "TouchDevice", {frame_size, ui_height = Screen:GetHeight()});
			scaling = frame_height / touch_ui_height;
			if(scaling ~= 1) then	
				LOG.std(nil, "info", "TouchDevice", "set UIScale to %s for TouchDevice", scaling);
				ParaUI.GetUIObject("root"):SetField("UIScale", {scaling, scaling});
			end
		end

		NPL.load("(gl)script/ide/timer.lua");
		local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
			if(Screen:GetWidth() > 0) then
				timer:Change();
				
				AutoAdjustUIScaling_();

				if(callbackFunc) then
					callbackFunc();
				end

				Screen:Connect("sizeChanged", function(width, height)
					AutoAdjustUIScaling_();
				end);
			end
		end})
		mytimer:Change(0,300);
	end
end

function MainLogin:ShowLoginModePage()
	self:AutoAdjustUIScalingForTouchDevice(function()
		self:CheckShowTouchVirtualKeyboard();
	end);
	

	if(System.options.cmdline_world and System.options.cmdline_world~="") then
		System.options.loginmode = "local";
		self:next_step({IsLoginModeSelected = true});
		return;
	end

	NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
    local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

	
	if (not System.options.isCodepku) then
		local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
		KeepWorkItemManager.StaticInit();

		local KpChatChannel = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/KpChatChannel.lua");
		KpChatChannel.StaticInit();

		local ClassManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/ClassManager.lua");
		ClassManager.StaticInit();
	end

	if(not System.options.isSchool) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/game_options.lua");
		local options = commonlib.gettable("MyCompany.Aries.Game.GameLogic.options")
		options:SetSchoolMode();
	end

	if(GameLogic.GetFilters():apply_filters("ShowLoginModePage", {})) then
		System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Login/SelectLoginModePage.html", 
			name = "ShowLoginModePage", 
			isShowTitleBar = false,
			DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
			style = CommonCtrl.WindowFrame.ContainerStyle,
			zorder = -1,
			allowDrag = false,
			directPosition = true,
				align = "_fi",
				x = 0,
				y = 0,
				width = 0,
				height = 0,
			cancelShowAnimation = true,
		});
	end
end

function MainLogin:LoadPlugins()
	NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
    local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
    GameLogic.InitMod();
	self:next_step({IsPluginLoaded = true});
end

-- return true if loaded
function MainLogin:CheckLoadWorldFromCmdLine(bForceLoad)
	local worldpath = System.options.cmdline_world;
	if(worldpath and worldpath~="" and (not self.cmdWorldLoaded or bForceLoad)) then
		self.cmdWorldLoaded = true;
		local customPath = GameLogic.GetFilters():apply_filters("load_world_from_cmd_precheck", worldpath);
		if customPath then
			worldpath = customPath;
		end
	
		if(System.options.servermode) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/main.lua");
			local Game = commonlib.gettable("MyCompany.Aries.Game")
			Game.Start(worldpath, nil, 0, nil, nil, function()
				LOG.std(nil, "info", "MainLogin", "server mode load world: %s", worldpath);
				NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandManager.lua");
				local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
				CommandManager:Init();
				local ip = ParaEngine.GetAppCommandLineByParam("ip", "0.0.0.0");
				local port = ParaEngine.GetAppCommandLineByParam("port", "");
				local autosaveInterval = ParaEngine.GetAppCommandLineByParam("autosave", "");
				-- Fixed onsoleted code, we have done this in c++: UseAsyncLoadWorld must be set to false in server mode, otherwise server chunks can not be served properly. 
				-- GameLogic.RunCommand("property", "UseAsyncLoadWorld false");
				GameLogic.RunCommand("startserver", ip.." "..port);
				
				if(autosaveInterval and autosaveInterval~="") then
					if(autosaveInterval == "true") then
						autosaveInterval = "";
						GameLogic.RunCommand("autosave", "on");
					elseif(autosaveInterval:match("^%d+$")) then
						GameLogic.RunCommand("autosave", "on "..autosaveInterval);
					else
						GameLogic.RunCommand("autosave", autosaveInterval);
					end
				end
			end);

		elseif(worldpath:match("^https?://")) then
			LOG.std(nil, "info", "MainLogin", "loading world: %s", worldpath);
			NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandManager.lua");
			local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
			CommandManager:Init();
			GameLogic.RunCommand("loadworld", worldpath);
		else
			NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
			local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
			WorldCommon.OpenWorld(worldpath, true);	
		end
		return true;
	end
end

function MainLogin:LoadMainWorld()
	if(self:CheckLoadWorldFromCmdLine() or System.options.servermode) then
		return;
	end
	if (not System.options.isCodepku) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldLoginAdapter.lua");
		local ParaWorldLoginAdapter = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaWorld.ParaWorldLoginAdapter");
		ParaWorldLoginAdapter:EnterWorld();
	else
		NPL.load("(gl)script/apps/Aries/Creator/Game/Login/InternetLoadWorld.lua");
		local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld");
		InternetLoadWorld.ShowPage();
	end
end

function MainLogin:ShowCreateWorldPage()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Login/CreateNewWorld.lua");
	local CreateNewWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.CreateNewWorld")
	CreateNewWorld.ShowPage();
end

function MainLogin:ShowLoginBackgroundPage(bShow, bShowCopyRight, bShowLogo, bShowBg)
	if (GameLogic.GetFilters():apply_filters("ShowLoginBackgroundPage", {})) then
		local url = "script/apps/Aries/Creator/Game/Login/LoginBackgroundPage.html?"
		if(bShow) then
			if(bShowCopyRight) then
				url = url.."showcopyright=true&";
			end
			if(bShowLogo) then
				url = url.."showtoplogo=true&";
			end
			if(not self.state.login_bg_worldpath and bShowBg==false) then
				url = url.."showbg=false&";
			end
		end

		System.App.Commands.Call("File.MCMLWindowFrame", {
			url = url, 
			name = "LoginBGPage", 
			isShowTitleBar = false,
			DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			zorder = -2,
			bShow = bShow,
			directPosition = true,
				align = "_fi",
				x = 0,
				y = 0,
				width = 0,
				height = 0,
			cancelShowAnimation = true,
		});
	end
end