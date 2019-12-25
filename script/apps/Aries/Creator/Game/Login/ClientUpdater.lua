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

-- this is the same folder as haqi
function ClientUpdater:GetRedistFolder()
	return ParaWorldLoginDocker.GetAppFolder(self.appname);
end

function ClientUpdater:GetUpdateConfigFilename()
	return ParaWorldLoginDocker.GetAppConfigByName(self.appname)
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
	
	self.autoUpdater:check(nil, function()
		if(not callbackFunc) then
			return
		end
		-- echo({self.autoUpdater:getCurVersion(), self.autoUpdater:getLatestVersion()});
		if(self.autoUpdater:isNeedUpdate())then
			callbackFunc(true, self.autoUpdater:getLatestVersion());
		else
			callbackFunc(false, self.autoUpdater:getLatestVersion());
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
	ParaGlobal.ShellExecute("open", L"http://paracraft.keepwork.com/download?lang=zh", "", "", 1);
end

function ClientUpdater:GetCurrentVersion()
	NPL.load("(gl)script/apps/Aries/Creator/Game/game_options.lua");
	local options = commonlib.gettable("MyCompany.Aries.Game.GameLogic.options")
	return options.GetClientVersion() or ""
end

function ClientUpdater:Restart()
	NPL.load("(gl)script/apps/Aries/Creator/Game/game_options.lua");
	local options = commonlib.gettable("MyCompany.Aries.Game.GameLogic.options")
	ParaWorldLoginDocker.Restart(self.appname, format('paraworldapp="%s" nplver="%s"', self.appname, self:GetCurrentVersion()));
end