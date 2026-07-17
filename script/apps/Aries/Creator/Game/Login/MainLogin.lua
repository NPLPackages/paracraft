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
local PapaUtils = NPL.load("(gl)script/apps/Aries/Creator/Game/PapaAdventures/PapaUtils.lua");
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

--Android端，如果同意了用户许可协议，则调用此函数
function MainLogin:OnAgreeUserPrivacy()
	local PlatformBridge = NPL.load("(gl)script/ide/PlatformBridge/PlatformBridge.lua");
	if PlatformBridge.IsAgreePrivacy() then
		PlatformBridge.onAgreeUserPrivacy()
	end
end

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
	self:UpdateIcon()
	self:OnAgreeUserPrivacy()
	self:next_step();
end

function MainLogin:UpdateIcon()
	if (System.options.isEducatePlatform) then
		ParaEngine.GetAttributeObject():SetField("Icon",'lancher_educate.ico')
		return
	end
	if (System.options.isPapaAdventure) then
		ParaEngine.GetAttributeObject():SetField("Icon",'icon_papa.ico')
		return
	end
end

-- this will prevent call stack too deep issue on iOS web browser. 
function MainLogin:Invoke_handler(handler_name)
	commonlib.TimerManager.SetTimeout(function()  
		self:Invoke_handler_imp(handler_name)
	end, 1)
end

-- invoke a handler 
function MainLogin:Invoke_handler_imp(handler_name)
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

--判断是否多开应用
function MainLogin:CheckMoreProcess(callback)
	if (System.os.GetPlatform() ~= "win32") then
		if (callback and type(callback) == "function") then
			callback(true);
		end
		return
	end
	local curProcessId = System.os.GetCurrentProcessId()
	local LuaCallbackHandler = NPL.load("(gl)script/ide/PlatformBridge/LuaCallbackHandler.lua");
	local cmdStr = [[wmic process where name="ParaEngineClient.exe" get processid,executablepath,name]]
	ParaGlobal.ShellExecute("popen",cmdStr,"isAsync",LuaCallbackHandler.createHandler(function(msg)
		local vals_arr = {};
		local out = msg.ret;
		local arr1 = commonlib.split(out,"\n")
		for j=#arr1,1,-1 do
			if arr1[j]=="" then
				table.remove(arr1,j)
			else
				arr1[j] = arr1[j]:gsub("^[\"\'%s]+", ""):gsub("[\"\'%s]+$", "") --去掉字符串首尾的空格、引号
			end
		end
		local retMap = {}
		if #arr1 > 0 then
			local keys = commonlib.split(arr1[1],"(%s+)")
			for i=2,#arr1 do
				local datas =  commonlib.split(arr1[i],"(%s+)") or {}
				if #datas == #keys then
					local temp = {}
					for j = 1,#datas do
						local key = string.lower(keys[j])
						local value = ""
						if key== "processid" then
							value =tonumber(datas[j])
						else
							value = ParaMisc.EncodingConvert("gb2312", "utf-8", datas[j])
						end
						temp[key] = value
					end
					retMap[#retMap + 1] =temp
				end
			end
		end
		local curProcedata
		local pathMaps = {}
		for i=1,#retMap do
			if (curProcessId == retMap[i].processid) then
				curProcedata = retMap[i]
			else
				local executablepath = retMap[i].executablepath or "";
				pathMaps[executablepath] = true
			end
		end
		if (curProcedata and curProcedata.executablepath and pathMaps[curProcedata.executablepath]) then
			if (callback and type(callback) == "function") then
				callback(false,curProcedata);
			end
			return
		end
		if (callback and type(callback) == "function") then
			callback(true);
		end
	end));
end

function MainLogin:ShowUpdatePage(bShowUpdatePage)
	if not self._updater then
		return
	end
	if self.m_bNeedUpdate and not self.m_bAllowSkip then
		self._updater:Download(true);
		return
	end
	if (bShowUpdatePage) then
		local params = {
			curVersion = self.m_curVersion,
			latestVersion = self.m_latestVersion,
			gamename = "Paracraft",
			miniVersion = self._updater:getMiniVersion(),
			updater = self._updater,
			bAllowSkip = self.m_bAllowSkip,
		}
	
		local ChangeVersion = NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ClientUpdate/ChangeVersion.lua");
		ChangeVersion.ShowPage(params,function()
			self._updater:Download(true);
		end)
	end
	
end

function MainLogin:UpdateCoreClient()
	if self:CheckEnterWorldCommand() or System.os.IsEmscripten() then
		self:next_step({IsUpdaterStarted = true});
		return 
	end
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
		self:next_step({IsUpdaterStarted = true});

		-- set to true (default to false, since the login interface will check mini-version anyway and we allow offline paracraft)
		-- for all major windows system we will check for latest version, but will not force update 
		-- instead it just pops up a dialog and ask user to use launcher Paracraft.exe to update.  
		local checkVersionForWin32 = not System.options.isPapaAdventure
		
		if (checkVersionForWin32 and not System.options.isAB_SDK and
			ParaEngine.GetAppCommandLineByParam("noclientupdate", "") == "") then
			
			NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ClientUpdater430.lua");
			local ClientUpdater430 = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ClientUpdater430");
			local _updater = ClientUpdater430:new({gamename = gamename});
			local second = 12
			local updateCheckTimer = commonlib.TimerManager.SetTimeout(function()
				LOG.std(nil, "waring", "MainLogin.UpdateCoreClient", "CheckClientUpdate timeout,second:%s", second);
				self:next_step({IsUpdaterStarted = true});
				GameLogic.AddBBS(nil, L"检查更新失败");
			end,second*1000)
			self._updater = _updater
			_updater:Check(function(bNeedUpdate, latestVersion, curVersion, bAllowSkip, needAppStoreUpdate)
				if (updateCheckTimer) then
					updateCheckTimer:Change()
					updateCheckTimer = nil;
				end
				self.m_bNeedUpdate = bNeedUpdate;
				self.m_latestVersion = latestVersion;
				self.m_curVersion = curVersion;
				self.m_bAllowSkip = bAllowSkip;
				print("update client version==============",System.options.launcherVer,bNeedUpdate, latestVersion, curVersion, bAllowSkip, needAppStoreUpdate)
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
						
						--多开不能更新，会出现问题
						self:CheckMoreProcess(function(result,processData)
							if result then
								self:ShowUpdatePage()
								if System.options.isEducatePlatform then
									local MainLoginLoginPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.Login')
									if MainLoginLoginPage then
										MainLoginLoginPage:Refresh(0.1)
									end
								else
									local MainLoginExtraPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.Extra')
									if MainLoginExtraPage then
										MainLoginExtraPage:Refresh(0.1)
									end
								end
							else
								local appName = L"帕拉卡社区版"
								if System.options.channelId_431 then
									appName = L"智慧教育客户端"
								end
								if System.options.isShenzhenAi5 then
									appName = L"深教AI4客户端"
								end
								_guihelper.MessageBox(L"更新失败了，"..appName..L"开了多个窗口了，请关闭其他窗口后再试。(如果正在编辑世界，请保存)");
							end
						end)					
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

		-----------------------------------------------------------------------------------
		local second = 12
		local updateCheckTimer = commonlib.TimerManager.SetTimeout(function()
			LOG.std(nil, "waring", "MainLogin.UpdateCoreClient", "CheckClientUpdate timeout,second:%s", second);
			GameLogic.GetFilters():apply_filters("HideClientUpdaterNotice");
			self:next_step({IsUpdaterStarted = true});
			GameLogic.AddBBS(nil, L"检查更新失败"); 
		end,second*1000)
		--------------------------防止更新接口超时没有返回，卡住启动逻辑-------------------------

		updater:Check(function(bNeedUpdate, latestVersion, curVersion, bAllowSkip, needAppStoreUpdate)
			GameLogic.GetFilters():apply_filters("HideClientUpdaterNotice");
			if updateCheckTimer then
				updateCheckTimer:Change()
				updateCheckTimer = nil
			end
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
	local titlename = GameLogic.GetFilters():apply_filters('GameName', L"Paracraft 帕拉卡")
	if System.options.channelId_431 then
		titlename = GameLogic.GetFilters():apply_filters('GameName', L"帕拉卡智慧教育")
	end
	if System.options.isShenzhenAi5 then
		titlename = GameLogic.GetFilters():apply_filters('GameName', L"深教AI4客户端")
	end
	local version = GameLogic.options.GetClientVersion()
	local desc = GameLogic.GetFilters():apply_filters('GameDescription', L"3D动画编程创作工具")
	if System.options.isPapaAdventure then
		titlename = "Paracraft" .. L"帕帕奇遇记"
		desc = L"3D动画编程学习工具"
		local web_version =  GameLogic.GetPlayerController():LoadLocalData("_papa_web_version_", "", true);
		if web_version ~= "" then
			version = web_version
		end
	end
	System.options.WindowTitle = string.format("%s -- ver %s", titlename,version);
	if System.options.isEducatePlatform then
		ParaEngine.SetWindowText(System.options.WindowTitle);
		if System.options.isOffline then
			ParaEngine.SetWindowText(System.options.WindowTitle .. L" (离线模式)");
		end
	elseif System.options.isCommunity then
		local text = format("%s : %s", System.options.WindowTitle, desc)
		if System.options.isOffline then
			text = text .. L" (离线模式)"
		end
		--print("set window title==============", text)
		ParaEngine.SetWindowText(text);
	else
		if (System.os.GetPlatform() == "mac" and System.options.isPapaAdventure) then
			System.options.WindowTitle = "帕帕奇遇记";
			ParaEngine.SetWindowText(System.options.WindowTitle);
		else
			ParaEngine.SetWindowText(format("%s : %s", System.options.WindowTitle, desc));
		end
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

function MainLogin:CheckEnterWorldCommand()
	local cmdline_world =  ParaEngine.GetAppCommandLineByParam("world","")
	if (cmdline_world and cmdline_world ~= "") then
		return true
	end
	return false
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
		self:ParseCommandLine(msg);
		-- UrlProtocolHandler:ParseCommand(msg.msg);

		-- if (System.options.cmdline_world) then
		-- 	self:CheckLoadWorldFromCmdLine(true);
		-- end
		return true;
	end, self);

	self:next_step({IsCommandLineChecked = true});	
end

-- cmdline add debounced function to avoid multiple loading world at the same time. 
function MainLogin:ParseCommandLine(msg)
	if not self.ParseCommandLineImpFunction then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Login/UrlProtocolHandler.lua");
		local UrlProtocolHandler = commonlib.gettable("MyCompany.Aries.Creator.Game.UrlProtocolHandler");
		self.ParseCommandLineImpFunction = commonlib.debounce(function(msg)
			UrlProtocolHandler:ParseCommand(msg.msg);
			if (System.options.cmdline_world) then
				self:CheckLoadWorldFromCmdLine(true);
			end
		end,2000)
	end
	self.ParseCommandLineImpFunction(msg)
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

function MainLogin:SetFutureLoadworld(kpProjectId,isLoad)
	self.kpProjectId = kpProjectId
	if isLoad then
		self:LoadPapaAdventure(isLoad)
	end
end

function MainLogin:LoadPapaAdventure(isLoad)
	if (System.options.isPapaAdventure) then
		local url = PapaUtils.GetPapaClientUrl()
		local papaUrl = ParaEngine.GetAppCommandLineByParam("papa_url", "")
		if papaUrl and papaUrl ~= "" and string.find(papaUrl,"http") then
			url = papaUrl
		end
		
		NPL.load("(gl)script/apps/Aries/Creator/Game/PapaAdventures/PapaAdventuresMain.lua");
        local PapaAdventuresMain = commonlib.gettable("MyCompany.Aries.Creator.Game.PapaAdventures.Main")
		--写具体的链接 "http://10.27.1.115:5173/"
		if self.kpProjectId  and tonumber(self.kpProjectId) > 0 then
			url = url.."?projectId="..self.kpProjectId
			self.kpProjectId = nil
		end
		if (System.os.IsEmscripten()) then
			url = "https://papacross.palaka.cn/client/"
		end
		LOG.std(nil,"info","MainLogin","MainLogin:LoadPapaAdventure----url===="..url)
		if isLoad then
			PapaAdventuresMain:OpenUrl(url)
			return
		end
		PapaAdventuresMain:OpenBrowser("papa_browser",url,function()
			
		end)
		return
	end
end

function MainLogin:GetDownLoadUrl()
	if (System.options.channelId == "papa") then
		jumpUrl = PapaUtils.GetPapaDownUrl().."?appId="..(System.options.appId or "paracraft-android_tatfook_papa");
	else
		jumpUrl = PapaUtils.GetParacraftDownUrl().."?projectName=palaka&appId="..(System.options.appId or "paracraft-android_palaka");
	end
	return jumpUrl
end

function MainLogin:ShowLoginModePage()
	self:AutoAdjustUIScalingForTouchDevice(function()
		-- self:CheckShowTouchVirtualKeyboard();
	end);
	if System.os.IsEmscripten() then
		-- local KeepworkModManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Emscripten/KeepworkModManager.lua");
	end
	if (System.options.cmdline_world and System.options.cmdline_world ~= "") then
		if System.options.isPapaAdventure then
			local futureId = tonumber(System.options.cmdline_world)
			if futureId and futureId > 0 then
				self:SetFutureLoadworld(futureId)
			else
				self:next_step({IsLoginModeSelected = true});
				return;
			end
		else
			self:next_step({IsLoginModeSelected = true});
			return;
		end
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

		NPL.load("(gl)script/apps/Aries/Creator/Game/Mqtt/MqttManager.lua")
        local MqttManager = commonlib.gettable("MyCompany.Aries.Creator.Game.MqttManager");
        MqttManager:StaticInit()
	end
	if(not System.options.isSchool) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/game_options.lua");
		local options = commonlib.gettable("MyCompany.Aries.Game.GameLogic.options")
		options:SetSchoolMode();
	end
	NPL.load('(gl)Mod/WorldShare/cellar/JumpAppStoreDialog/JumpAppStoreDialog.lua');
	local JumpAppStoreDialog = commonlib.gettable('Mod.WorldShare.cellar.JumpAppStoreDialog');
	-- big 2023.8.14: Temporary logic, will be removed in subsequent versions.
	local platform = System.os.GetPlatform()
    if (platform ~= 'win32' and not System.os.IsEmscripten()) then
		local versionStr = System.options.isPapaAdventure and "1.5.1.0" or "1.7.1.0"
		if platform == "mac" then
			versionStr = "1.5.1.0"
		end
		if (platform == "mac" or platform == "ios") and System.options.isPapaAdventure then
			versionStr = "1.1.0.0" --ios 和 mac的帕帕奇遇记暂时不做比较
		end
        if (not System.os.CompareParaEngineVersion(versionStr)) then
			local jumpUrl = self:GetDownLoadUrl();
			if (not JumpAppStoreDialog.ignore) then
				JumpAppStoreDialog.style = 2;
				JumpAppStoreDialog.ignoreCallback = function()
					Mod.WorldShare.Store:Set('user/clientForceUpdated', false)
					self:ShowLoginModePage()
				end
				JumpAppStoreDialog.Show(0, 0, jumpUrl);
	
				Mod.WorldShare.Store:Set('user/clientForceUpdated', true)
	
				return;
			end
        end
    end
	if (System.options.isPapaAdventure) then
		self:LoadPapaAdventure();
		self:set_step({HasInitedTexture = true}); 
		self:set_step({IsPreloadedTextures = true}); 
		self:set_step({IsLoadMainWorldRequested = true}); 
		self:set_step({IsCreateNewWorldRequested = true});
		self:next_step({IsLoginModeSelected = true}); 
		return
	end
	local isShowDefaultLoginPage = GameLogic.GetFilters():apply_filters("cellar.main_login.show_login_mode_page", {})
	if(isShowDefaultLoginPage) then
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
	else
		self:LoadProtocolFromFile()
	end
end

function MainLogin:LoadPlugins()
	NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
    local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
    GameLogic.InitMod();
	self:next_step({IsPluginLoaded = true});
end


function MainLogin:CheckNeedUpdate(callback)
	if System.os.IsEmscripten() then
		if callback and type(callback) == "function" then
			callback();
		end
		return
	end
	NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ClientUpdater430.lua");
	local ClientUpdater430 = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ClientUpdater430");
	local _updater = ClientUpdater430:new({gamename = gamename});
	_updater:Check(function(bNeedUpdate, latestVersion, curVersion, bAllowSkip, needAppStoreUpdate)
		if callback and type(callback) == "function" then
			callback(bNeedUpdate,bAllowSkip);
		end
	end)
end

function MainLogin:WriteProtocolToFile()
	if (not System.options.isEducatePlatform) then
		return
	end
	local filename = "temp/palaka_protocol.txt"
	if not ParaIO.DoesFileExist(filename) then
		ParaIO.CreateDirectory(filename)
	end
	local cmdline = ParaEngine.GetAppCommandLine();
	if cmdline and cmdline ~= "" then
		local write = ParaIO.open(filename, "w")
		write:write(cmdline, #cmdline)
		write:close()
	end
end

function MainLogin:LoadProtocolFromFile()
	if (not System.options.isEducatePlatform) then
		return
	end
	local filename = "temp/palaka_protocol.txt"
	if not ParaIO.DoesFileExist(filename) then
		return
	end
	NPL.load("(gl)script/apps/Aries/Creator/Game/Login/UrlProtocolHandler.lua");
	local UrlProtocolHandler = commonlib.gettable("MyCompany.Aries.Creator.Game.UrlProtocolHandler");
	local readFile = ParaIO.open(filename, 'r')

    if readFile:IsValid() then
        local content = readFile:GetText(0, -1)
		if content and content ~= "" then
			local cmdline = content
			if cmdline and cmdline ~= "" then
				UrlProtocolHandler:ParseCommand(cmdline);
				if (System.options.cmdline_world and System.options.cmdline_world ~= "") then
					self:CheckLoadWorldFromCmdLine(true);
				else
					-- 判断是否有world=""
					local worldValue = cmdline:match('world="(.-)"')
					if worldValue and worldValue ~= "" then
						ParaEngine.SetAppCommandLine(cmdline);
						System.options.cmdline_world = ParaEngine.GetAppCommandLineByParam("world","")
						if (System.options.cmdline_world and System.options.cmdline_world ~= "") then
							self:CheckLoadWorldFromCmdLine(true);
						end
					end
				end
			end
		end
		readFile:close()
		ParaIO.DeleteFile(filename)
	end
end

function MainLogin:CheckLoadWorldFromCmdLineImp(bForceLoad)
	local cmdline_world = System.options.cmdline_world;
	if(cmdline_world and cmdline_world:match("^/?text2world")) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Emscripten/Emscripten.lua");
		local MainLogin_MainLogin = NPL.load('(gl)Mod/WorldShare/cellar/MainLogin/MainLogin.lua');
		MainLogin_MainLogin:CmdAutoLogin();
		if (System.os.IsEmscripten()) then return true end
		NPL.load("(gl)script/apps/Aries/Creator/Game/Code/TextToWorld/TextToWorld.lua");
		local TextToWorld = commonlib.gettable("MyCompany.Aries.Game.Code.TextToWorld.TextToWorld")
		TextToWorld:new():PrepareTextWorld();
		return true
	end
	if (cmdline_world and cmdline_world ~= "" and (not self.cmdWorldLoaded or bForceLoad)) then
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

-- return true if loaded
function MainLogin:CheckLoadWorldFromCmdLine(bForceLoad)
	local cmdline_world = System.options.cmdline_world;
	local noclientupdate = ParaEngine.GetAppCommandLineByParam("noclientupdate", "") == "true"
	local bRet = (cmdline_world and cmdline_world ~= "" and (not self.cmdWorldLoaded or bForceLoad)) or (cmdline_world and cmdline_world:match("^/?text2world"))
	if (System.options.isEducatePlatform and (cmdline_world and cmdline_world ~= "") and not noclientupdate) then
		LOG.std(nil, "info", "MainLogin", "save temp cmdline: %s", cmdline_world);
		self:CheckNeedUpdate(function(bNeedUpdate,bAllowSkip)
			if(bNeedUpdate) then
				if bAllowSkip then
					self:CheckLoadWorldFromCmdLineImp(bForceLoad);
				else
					self:WriteProtocolToFile()
				end
			else
				self:CheckLoadWorldFromCmdLineImp(bForceLoad);
			end
		end)
	else
		self:CheckLoadWorldFromCmdLineImp(bForceLoad);
	end
	return bRet;
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
	local isOffline = ParaEngine.GetAppCommandLineByParam("Offline", "false") == "true"
	if System.options.isDevEnv or System.options.isPapaAdventure or isOffline then
		self:next_step({PrepareApp = true});
		return
	end
	if((System.options.cmdline_world or "") == "") then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Login/PrepareApp/PrepareApp.lua");
		local PrepareApp = commonlib.gettable("MyCompany.Aries.Game.PrepareApp");
		if System.os.GetPlatform()~="win32" then
			PrepareApp.LoadScripts()
			self:next_step({PrepareApp = true});
		else
			PrepareApp.start()
		end
	else
		self:next_step({PrepareApp = true});
	end
end