--[[
Title: ClientUpdater 
Author(s): LiXizhi
Date: 2018.7.26
Desc: for client update without NPLRuntime and dll
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ClientUpdater.lua");
local ClientUpdater = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ClientUpdater");
local updater = ClientUpdater:new();
updater:Check(function(bNeedUpdate, latestVersion)
	if(bNeedUpdate) then
		updater:Download(function(bSucceed)
			if(bSucceed) then
				updater:Restart()
			else
				self:next_step({IsUpdaterStarted = true});
			end
		end)
	else
		self:next_step({IsUpdaterStarted = true});
	end
end);
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/DownloadWorld.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ParaWorldLoginDocker.lua");
local ParaWorldLoginDocker = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ParaWorldLoginDocker")
local DownloadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.DownloadWorld")
local AutoUpdater = NPL.load("AutoUpdater");

local ClientUpdater = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.MainLogin.ClientUpdater"));

ClientUpdater.appname = "paracraftAppVersion";

function ClientUpdater:ctor()
	if(not ClientUpdater) then
		LOG.std(nil, "info", "ClientUpdater", "AutoUpdater not found");
		return;
	end
	local autoUpdater = AutoUpdater:new();
	self.autoUpdater = autoUpdater;

	autoUpdater:onInit(self:GetRedistFolder(), self:GetUpdateConfigFilename(), function(state)
	end)
end

-- static function:
-- this is the same folder as haqi
function ClientUpdater:GetRedistFolder()
	return ParaWorldLoginDocker.GetAppFolder(self.appname);
end

-- static function:
function ClientUpdater:GetUpdateConfigFilename()
	return ParaWorldLoginDocker.GetAppConfigByName(self.appname)
end

-- copy assets from package at first time
function ClientUpdater:CopyAssetsToWritablePath()
	local version = ParaIO.open(self:GetRedistFolder() .. 'version.txt', "r");
	if (version:IsValid()) then
		self.autoUpdater:loadLocalVersion()
		local root_curVer = self:GetCurrentVersion()
		local redist_curVer = self:getCurVersion()
		if self.autoUpdater:_compareVer(root_curVer,redist_curVer)>0 then --说明通过launcher更新过了，删除更新文件夹的文件，重新覆盖
			ParaIO.DeleteFile(self:GetRedistFolder())
		else
			return
		end
	end

	local fileList = {
		'version.txt',
		'assets_manifest.txt',
		'npl_packages/ParacraftBuildinMod.zip',
		'main.pkg',
		'main_mobile_res.pkg',
		'main150727.pkg',
	}

	for key, item in ipairs(fileList) do
		ParaIO.CopyFile(
			item,
			ParaIO.GetWritablePath() .. 'apps/haqi/' .. item,
			true
		)
	end
end

-- public function:
-- @param callbackFunc: function(bNeedUpdate, latestVersion)
function ClientUpdater:Check(callbackFunc)
	if(not self.autoUpdater) then
		if(callbackFunc) then
			callbackFunc(false);
		end
		return
	end

	self:CopyAssetsToWritablePath()

	self.autoUpdater:check(nil, function(bSucceed)
		if(not callbackFunc) then
			return
		end

		if(bSucceed) then
			if(self.autoUpdater:isNeedUpdate())then
				callbackFunc(
					true,
					self.autoUpdater:getLatestVersion(),
					self.autoUpdater._comparedVersion
				);
			else
				callbackFunc(
					false,
					self.autoUpdater:getLatestVersion(),
					self.autoUpdater._comparedVersion
				);
			end
		else
			LOG.std(nil, "info", "ClientUpdater", "version error");
			callbackFunc(nil, self.autoUpdater:getLatestVersion());
		end
	end);
end

-- public function:
-- @param callbackFunc: function(bSucceed)
function ClientUpdater:Download(callback)
	ParaWorldLoginDocker.InstallApp(self.appname, function(bInstalled)
		callback(bInstalled)
	end)
end
function ClientUpdater:OnClickUpdate()
	ParaGlobal.ShellExecute("open", L"https://www.paracraft.cn/download", "", "", 1);
end

--原始根目录下的version.txt
function ClientUpdater:GetCurrentVersion()
	NPL.load("(gl)script/apps/Aries/Creator/Game/game_options.lua");
	local options = commonlib.gettable("MyCompany.Aries.Game.GameLogic.options")
	return options.GetClientVersion() or ""
end

--更新路径（self:GetRedistFolder()）下的version.txt
function ClientUpdater:getCurVersion()
	return self.autoUpdater:getCurVersion()
end

function ClientUpdater:getLatestVersion()
	return self.autoUpdater:getLatestVersion()
end

--是否能跳过本次更新
function ClientUpdater:canAutoSkip()
	return self.autoUpdater:isAutoSkip()
end

function ClientUpdater:Restart()
	NPL.load("(gl)script/apps/Aries/Creator/Game/game_options.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Login/UrlProtocolHandler.lua");

	local UrlProtocolHandler = commonlib.gettable("MyCompany.Aries.Creator.Game.UrlProtocolHandler");

	local urlProtocol = UrlProtocolHandler:GetParacraftProtocol(ParaEngine.GetAppCommandLine() or '');
	local restartCmd = '';

	if (urlProtocol and type(urlProtocol) == 'string') then
		restartCmd = format('%s paraworldapp="%s" nplver="%s"', 'paracraft://' .. urlProtocol, self.appname, self:GetCurrentVersion())--ParaEngine.GetVersion()
	else
		restartCmd = format('paraworldapp="%s" nplver="%s"', self.appname, self:GetCurrentVersion())--ParaEngine.GetVersion()
	end

	ParaWorldLoginDocker.Restart(self.appname, restartCmd);
end