--[[
Title: MC Main Login Procedure
Author(s): LiXizhi, big
Company: ParaEngine
CreateDate: 2013.10.14
ModifyDate: 2022.1.5
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/MainLogin.lua");
local MainLogin = commonlib.gettable("MyCompany.Aries.Game.MainLogin");
MyCompany.Aries.Game.MainLogin:start();
------------------------------------------------------------
]]

local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/ParacraftDebug.lua");--收集报错信息，早发现，早治疗
local ParacraftDebug = commonlib.gettable("MyCompany.Aries.Game.Common.ParacraftDebug");
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

	IsPreloadedTextures = nil, -- added by leio
	IsPreloadedSocketIOUrl = nil, -- added by leio

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
		-- do some preloading work
		PrepareApp = self.PrepareApp,
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

		PreloadTextures = self.PreloadTextures,
		PreloadedSocketIOUrl = self.PreloadedSocketIOUrl,

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

function MainLogin:set_step(state_update)
	local state = self.state;
	if(state_update) then
		commonlib.partialcopy(state, state_update);
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
		ParacraftDebug:CheckSendCrashLog() --去检查有没有之前崩溃时备份的日志文件
	elseif(not state.IsPackagesLoaded) then
		self:Invoke_handler("LoadPackages");
	elseif(not state.CheckGraphicsSettings) then
		self:Invoke_handler("CheckGraphicsSettings");
	elseif (not state.PrepareApp) then
		self:Invoke_handler("PrepareApp")
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
	elseif(not state.IsPreloadedTextures) then
		self:Invoke_handler("PreloadTextures");
	elseif(not state.IsPreloadedSocketIOUrl) then
		self:Invoke_handler("PreloadedSocketIOUrl");
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
	if (System.os.GetPlatform() == "win32" and
		ParaEngine.GetAppCommandLineByParam("use_dev_ftp_updater", "") == "true") then
		NPL.load("(gl)script/apps/Aries/ParacraftCI/FtpUtil.lua",true);
		local DevUpdaterFromFtp = NPL.load("(gl)script/apps/Aries/Creator/Game/Login/Update/DevUpdaterFromFtp.lua",true);
		local _devUpdater = DevUpdaterFromFtp:new();

		_devUpdater:Check(function(needUpdate)
			LOG.std(nil, "info", "MainLogin:UpdateCoreClient", "DevUpdaterFromFtp needUpdate: %s", needUpdate);

			if (needUpdate) then
				_devUpdater:StartUpdate(function()
					self:next_step({IsUpdaterStarted = true});
				end)
			else
				self:next_step({IsUpdaterStarted = true});
			end
		end);

		return;
	else
		--以正常方式打开时，修复版本号，不然如果有更新的话，会获取不到差分资源列表
		local verStr = GameLogic.options.GetClientVersion();
		local _,n = verStr:gsub("%.",".");
		local patt = "%.%d%d%d%d%d%d%d%d%d%d%d%d%d%d$";

		if (n == 3 and verStr:match(patt)) then
			verStr = verStr:gsub(patt, "");
			ParaIO.CopyFile("version.txt", "version.txt.dev", true);
			commonlib.Files.WriteFile("version.txt", "ver=" .. verStr);
		end
	end

	self:checkAutoConnectTeacher();
	local platform = System.os.GetPlatform();

	local testCoreClient = false;

	if (not testCoreClient and platform == "win32" and not System.os.IsWindowsXP()) then
		local gamename = "Paracraft";
		gamename = GameLogic.GetFilters():apply_filters('GameName', gamename);
		

		if (System.options.isChannel_430) then -- 430windows版，还是下载到本目录
			NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ClientUpdater430.lua");
			local ClientUpdater430 = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ClientUpdater430");
			local _updater = ClientUpdater430:new({gamename = gamename});

			GameLogic.GetFilters():apply_filters("ShowClientUpdaterNotice");

			_updater:Check(function(bNeedUpdate, latestVersion, curVersion, bAllowSkip, needAppStoreUpdate)
				GameLogic.GetFilters():apply_filters("HideClientUpdaterNotice");
				LOG.std(nil, "info", "MainLogin:UpdateCoreClient", "bNeedUpdate: %s", bNeedUpdate);

				if (bNeedUpdate == nil) then -- 表示检查更新失败
					self:next_step({IsUpdaterStarted = true});
					GameLogic.AddBBS(nil, L"检查更新失败");
				elseif (bNeedUpdate) then -- 不是是最新版，作为局域网客户端开启，随时准备进行同步
					GameLogic.GetFilters():apply_filters(
						"start_lan_client",
						{
							realLatestVersion = latestVersion,
							isAutoInstall = not bAllowSkip,
							needShowDownloadWorldUI = not bAllowSkip,
							onUpdateError = function()
								self:next_step({IsUpdaterStarted = true});
							end
						}
					);

					if (bAllowSkip) then
						self:next_step({IsUpdaterStarted = true});
						_updater:checkNeedSlientDownload(); -- 局域网内，可以跳过更新的情况下，去看看是否需要静默更新
					else
						NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ClientUpdateDialog.lua");
						local ClientUpdateDialog = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ClientUpdateDialog")

						ClientUpdateDialog.Show(
							latestVersion,
							curVersion,
							gamename,
							function()
								local ret = GameLogic.GetFilters():apply_filters(
									'check_is_downloading_from_lan',
									{
										needShowDownloadWorldUI = true,
										installIfAlldownloaded = true
									}
								);

								if (ret and ret._hasStartDownloaded) then --点击更新按钮后，再查一遍是否已经再局域网开始更新了
									LOG.std(nil, "info", "MainLogin:UpdateCoreClient", "已经开始局域网更新了");
									return;
								end

								_updater:Download(true);
							end
						);
					end
				elseif (needAppStoreUpdate) then -- 需要跳转应用商店更新(windows不会走到此分支)
					self:next_step({IsUpdaterStarted = true});
					--TODO
					--显示跳转更新UI
				else
					--已经是最新版了，开启服务器
					GameLogic.GetFilters():apply_filters(
						"start_lan_server",
						{
							realLatestVersion = latestVersion,
							_updater = _updater
						}
					);

					self:next_step({IsUpdaterStarted = true});
				end
			end);

			return;
		end

		self:next_step({IsUpdaterStarted = true});

		-- set to true (default to false, since the login interface will check mini-version anyway and we allow offline paracraft)
		-- for all major windows system we will check for latest version, but will not force update 
		-- instead it just pops up a dialog and ask user to use launcher Paracraft.exe to update.  
		local checkVersionForWin32 = System.options.channelId_431;
		
		if (checkVersionForWin32 and not System.options.isAB_SDK and
			ParaEngine.GetAppCommandLineByParam("noclientupdate", "") == "") then
			
			NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ClientUpdater430.lua");
			local ClientUpdater430 = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ClientUpdater430");
			local _updater = ClientUpdater430:new({gamename = gamename});

			_updater:Check(function(bNeedUpdate, latestVersion, curVersion, bAllowSkip, needAppStoreUpdate)
				if (System.options.launcherVer and System.options.launcherVer >= 5) then
					if (bNeedUpdate == nil) then --表示检查更新失败
						GameLogic.AddBBS(nil, L"检查更新失败");
					elseif (bNeedUpdate) then
						if (System.options.isDevMode) then
							LOG.std(
								nil,
								"debug",
								"MainLogin:UpdateCoreClient",
								"bNeedUpdate: %s, latestVersion: %s, curVersion: %s, bAllowSkip: %s, needAppStoreUpdate: %s",
								bNeedUpdate,
								latestVersion,
								curVersion,
								bAllowSkip,
								needAppStoreUpdate
							);
						end

						NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ClientUpdateDialog.lua");
						local ClientUpdateDialog = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ClientUpdateDialog")
						
						ClientUpdateDialog.Show(
							latestVersion,
							curVersion,
							gamename,
							function()
								_updater:Download(true);
							end,
							bAllowSkip
						);
					elseif (needAppStoreUpdate) then -- 需要跳转应用商店更新(windows不会走到此分支)
						
					else
						
					end
				elseif (bNeedUpdate) then
					System.options.isParacraftNeedUpdate = true;

					if (GameLogic.GetFilters():apply_filters('cellar.client_update_dialog.show', false, _updater, gamename)) then
						return;
					end
				end
			end);
		end
	else
		-- For android, mac, iOS, winXP, it will always use latest version and download pkg to apps/haqi/ folder without updating executable. 
		-- check for mini-allowed core nplruntime version
		-- NOTE: version smaller than this are not allowed to run. one must upgrade the NPL runtime. 
		local minVer = {0, 7, 509};

		NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ClientUpdater.lua");
		local ClientUpdater = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ClientUpdater");
		local updater = ClientUpdater:new();

		if (ParaEngine.GetAppCommandLineByParam("noclientupdate", "") == "true") then
			self:next_step({IsUpdaterStarted = true});
			return;
		end

		local function CheckMiniVersion_(ver)
			local v1, v2, v3 = ver:match("(%d+)%D(%d+)%D(%d+)");

			if (v3) then
				v1,v2,v3 = tonumber(v1),tonumber(v2), tonumber(v3)

				local isCodepku = ParaEngine.GetAppCommandLineByParam("isCodepku", "false") == "true";

				if (not isCodepku and
					(v1 < minVer[1] or
					 (v1 == minVer[1] and v2 < minVer[2]) or
					 (v1 == minVer[1] and v2 == minVer[2] and v3 < minVer[3])
					)
				   ) then
					_guihelper.MessageBox(format(L"您的版本%s低于最低要求,请尽快更新", ver), function(res)
						if (res and res == _guihelper.DialogResult.Yes) then
							ClientUpdater:OnClickUpdate();
						end

						self:next_step({IsUpdaterStarted = true});
					end, _guihelper.MessageBoxButtons.YesNo);

					return false;
				end
			end

			return true;
		end

		if (System.options.paraworldapp == ClientUpdater.appname) then
			local ver = ParaEngine.GetAppCommandLineByParam("nplver", "");

			if (CheckMiniVersion_(ver)) then
				self:next_step({IsUpdaterStarted = true});
			end

			return;
		end

		GameLogic.GetFilters():apply_filters("ShowClientUpdaterNotice");

		updater:Check(function(bNeedUpdate, latestVersion, curVersion, bAllowSkip, needAppStoreUpdate)
			GameLogic.GetFilters():apply_filters("HideClientUpdaterNotice");

			if (bNeedUpdate == nil) then -- 表示更新失败
				self:next_step({IsUpdaterStarted = true});
				GameLogic.AddBBS(nil, L"检查更新失败");
			elseif (bNeedUpdate) then
				updater:Download(function(bSucceed)
					if (bSucceed) then
						updater:Restart();
					else
						self:next_step({IsUpdaterStarted = true});
					end
				end);
			elseif (needAppStoreUpdate) then --需要跳转应用商店更新
				if (bAllowSkip) then
					self:next_step({IsUpdaterStarted = true});
				else
					local jumpUrl = updater:getAppStoreUrl();
					NPL.load("(gl)script/apps/Aries/Creator/Game/Login/Update/JumpAppStoreDialog.lua");
					local JumpAppStoreDialog = commonlib.gettable("MyCompany.Aries.Game.Login.Update.JumpAppStoreDialog");
					JumpAppStoreDialog.Show(latestVersion, curVersion, jumpUrl);

					-- self:next_step({IsUpdaterStarted = true});
				end
			else
				local comparedVersion = updater:getComparedResult();

				if (comparedVersion == 100) then
					self:next_step({IsUpdaterStarted = true});
					return;
				end

				if (updater:GetCurrentVersion() ~= latestVersion) then
					updater:Restart();
				else
					self:next_step({IsUpdaterStarted = true});
				end
			end
		end);
	end
end

--430版本，自动连接教师服务器（教师服务器开启以后，会周期性发送局域网广播）
function MainLogin:checkAutoConnectTeacher()
	if System.options.isChannel_430 then 
        GameLogic.RunCommand("/lan -auto_find_teacher=true")
    end
end

function MainLogin:UpdateCoreBrowser()
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

function MainLogin:SetWindowTitle()
	local titlename = System.options.channelId_431 and GameLogic.GetFilters():apply_filters('GameName', L"帕拉卡智慧教育") or GameLogic.GetFilters():apply_filters('GameName', L"帕拉卡 Paracraft")
	local version = GameLogic.options.GetClientVersion()
	local desc =GameLogic.GetFilters():apply_filters('GameDescription', L"3D动画编程创作工具")
	if System.options.isPapaAdventure then
		titlename = "Paracraft" .. L"帕帕奇遇记"
		desc = L"3D动画编程学习工具"
		local web_version =  GameLogic.GetPlayerController():LoadLocalData("_papa_web_version_", "", true);
		if web_version ~= "" then
			version = web_version
		end
	end
	System.options.WindowTitle =  string.format("%s -- ver %s", titlename,version);
	if System.options.channelId_431 then
		ParaEngine.SetWindowText(System.options.WindowTitle);
	else
		ParaEngine.SetWindowText(format("%s : %s", System.options.WindowTitle, desc));
	end
end

-- login handler
function MainLogin:LoadBackground3DScene()
	if(System.options.servermode) then
		return self:next_step({Loaded3DScene = true});
	end
	
	self:SetWindowTitle()

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

	local cmdline = ParaEngine.GetAppCommandLine();

	if (not UrlProtocolHandler:GetParacraftProtocol(cmdline) and
		(not System.options.cmdline_world or
		 System.options.cmdline_world == "")) then
		-- only install url protocol when the world is empty
		UrlProtocolHandler:CheckInstallUrlProtocol();
	end

	UrlProtocolHandler:ParseCommand(cmdline);

	if (System.options.servermode) then
		-- TODO: for server only world
		if (not System.options.cmdline_world or
			System.options.cmdline_world == "") then
			System.options.cmdline_world = "worlds/DesignHouse/defaultserverworld";
			LOG.std(nil, "warn", "serverworld", "no server world specified, we will use %s", System.options.cmdline_world);
		end
	end

	-- in case, a request comes when application is already running. 
	commonlib.EventSystem.getInstance():AddEventListener("CommandLine", function(self, msg)
		UrlProtocolHandler:ParseCommand(msg.msg);

		if (System.options.cmdline_world) then
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
				NplBrowserManager:PreLoadWindows({
					{ name = "DailyCheckBrowser", url = nil, is_show_control = false, },
				})
			end
		end
	end
end

-- load predefined mod packages if any
function MainLogin:LoadPackages()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Login/BuildinMod.lua");
	local BuildinMod = commonlib.gettable("MyCompany.Aries.Game.MainLogin.BuildinMod");
	BuildinMod.AddBuildinMods();

	-- disable preload cef3 window
	--self:PreloadDailyCheckinAndTeachingWnd();

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
		Screen:ChangeUIDesignResolution(1280, 720, callbackFunc)
	end
end

local PapaUrls = {
	STAGE = "http://adventure-dev.kp-para.cn/",
	RELEASE = "http://adventure-rls.kp-para.cn/",
	ONLINE = "https://papa.palaka.cn/"
}
function MainLogin:LoadPapaAdventure()
	if (System.options.isPapaAdventure) then
		local env = string.upper(ParaEngine.GetAppCommandLineByParam("http_env", "ONLINE"))
		local papaUrl = ParaEngine.GetAppCommandLineByParam("papa_url", "")
		LOG.std(nil,"MainLogin","MainLogin:LoadPapaAdventure----channelId===%s",env)
		local url = PapaUrls[env]
		if papaUrl and papaUrl ~= "" and string.find(papaUrl,"http") then
			url = papaUrl
		end
		ParaEngine.GetAttributeObject():SetField("Icon",'icon_papa.ico')
		NPL.load("(gl)script/apps/Aries/Creator/Game/PapaAdventures/PapaAdventuresMain.lua");
        local PapaAdventuresMain = commonlib.gettable("MyCompany.Aries.Creator.Game.PapaAdventures.Main")
		--写具体的链接 "http://10.27.1.115:5173/"
		PapaAdventuresMain:OpenBrowser("papa_browser",url,function()
			
		end)
		return
	end
end

function MainLogin:ShowLoginModePage()
	self:AutoAdjustUIScalingForTouchDevice(function()
		-- self:CheckShowTouchVirtualKeyboard();
	end);
	
	if (System.options.cmdline_world and
		System.options.cmdline_world ~= "") then
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

		--local ClassManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/ClassManager.lua");
		--ClassManager.StaticInit();
	end

	if(not System.options.isSchool) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/game_options.lua");
		local options = commonlib.gettable("MyCompany.Aries.Game.GameLogic.options")
		options:SetSchoolMode();
	end
	
	if (System.options.isPapaAdventure) then
		MainLogin:LoadPapaAdventure();
		MainLogin:set_step({HasInitedTexture = true}); 
		MainLogin:set_step({IsPreloadedTextures = true}); 
		MainLogin:set_step({IsLoadMainWorldRequested = true}); 
		MainLogin:set_step({IsCreateNewWorldRequested = true});
		MainLogin:next_step({IsLoginModeSelected = true}); 
		return
	end

	if(GameLogic.GetFilters():apply_filters("cellar.main_login.show_login_mode_page", {})) then
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
	local cmdline_world = System.options.cmdline_world;

	if (cmdline_world and
		cmdline_world ~= "" and
		(not self.cmdWorldLoaded or bForceLoad)) then
		self.cmdWorldLoaded = true;

		if (GameLogic.GetFilters():apply_filters(
			"cellar.common.common_load_world.check_load_world_from_cmd_line",
			cmdline_world) == true) then
			return true;
		end
		
		local customPath = GameLogic.GetFilters():apply_filters("load_world_from_cmd_precheck", cmdline_world);
		if (customPath) then
			cmdline_world = customPath;
		end
		
		if (System.options.servermode) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/main.lua");
			local Game = commonlib.gettable("MyCompany.Aries.Game");

			Game.Start(cmdline_world, nil, 0, nil, nil, function()
				LOG.std(nil, "info", "MainLogin", "server mode load world: %s", cmdline_world);
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
		elseif(cmdline_world:match("^https?://")) then
			LOG.std(nil, "info", "MainLogin", "loading world: %s", cmdline_world);
			GameLogic.RunCommand("loadworld", cmdline_world);
		else
			NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
			local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
			WorldCommon.OpenWorld(cmdline_world, true);	
		end

		return true;
	end
end

function MainLogin:PreloadedSocketIOUrl()
	if(System.options.servermode) then
		self:next_step({IsPreloadedSocketIOUrl = true});
        return
	end
	if(System.options.cmdline_world) then
		self:next_step({IsPreloadedSocketIOUrl = true});
	else
		local KpChatChannel = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/KpChatChannel.lua");
		KpChatChannel.PreloadSocketIOUrl(function()
			self:next_step({IsPreloadedSocketIOUrl = true});
		end);
	end
end

function MainLogin:PreloadTextures()
	local skipPreloadTextures = true
	if(System.options.servermode or skipPreloadTextures) then
		self:next_step({IsPreloadedTextures = true});
        return
	end
    local DockAssetsPreloader = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockAssetsPreloader.lua");
    DockAssetsPreloader.Start(function()
		self:next_step({IsPreloadedTextures = true});
    end);
end

function MainLogin:LoadMainWorld()
	if (self:CheckLoadWorldFromCmdLine() or System.options.servermode) then
		return;
	end

	if (not System.options.isCodepku) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldLoginAdapter.lua");
		local ParaWorldLoginAdapter = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaWorld.ParaWorldLoginAdapter");

		-- 新用户进入新手世界
		local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
		local isFirstLogin = KeepWorkItemManager.HasGSItem(37);
		local tutorial = ParaEngine.GetAppCommandLineByParam("tutorial", "false");
		if (GameLogic.GetFilters():apply_filters('is_signed_in')  and (tutorial == "true" or (tutorial ~= "false" and isFirstLogin))) then
			return GameLogic.RunCommand(string.format("/loadworld %s", 24062)); 
		end

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
		if System.options.isPapaAdventure then
			url = "script/apps/Aries/Creator/Game/Login/LoginBackgroundPage.papa.html?"
		end
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

function MainLogin:PrepareApp()
	if System.options.isPapaAdventure then
		self:next_step({PrepareApp = true});
		return
	end
	if((System.options.cmdline_world or "") == "") then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Login/PrepareApp/PrepareApp.lua");
		local PrepareApp = commonlib.gettable("MyCompany.Aries.Game.PrepareApp");
		if true then --System.options.isDevMode
			if System.os.GetPlatform()~="win32" then
				PrepareApp.LoadScripts()
				self:next_step({PrepareApp = true});
			else
				PrepareApp.start()
			end
		else
			PrepareApp.LoadScripts()
			self:next_step({PrepareApp = true});
		end
	else
		self:next_step({PrepareApp = true});
	end
end