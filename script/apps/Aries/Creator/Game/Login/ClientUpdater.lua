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

function ClientUpdater:CopyAssetsToWritablePath()
	local version = ParaIO.open(ParaIO.GetWritablePath() .. 'apps/haqi/version.txt', "r");

	if (version:IsValid()) then
		return
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

	if System.os.GetPlatform() == 'android' then
		self:CopyAssetsToWritablePath()
	end

	self.autoUpdater:check(nil, function(bSucceed)
		if(not callbackFunc) then
			return
		end

		if(bSucceed) then
			-- we will not update for mac if software version heighter then remote version
			if System.os.GetPlatform() == 'mac' or System.os.GetPlatform() == "ios" then
				local function CompareVersion(a, b)
					-- a < b return -1
					-- a == b return 0
					-- a > b return 1
					-- format error return nil
					local function GetVersions(versionStr)
						local result = {};
						for s in string.gfind(versionStr, "%d+") do
							table.insert(result, tonumber(s));
						end
						return result;
					end
				
					local aVersionList = GetVersions(a);
					local bVersionList = GetVersions(b);
				
					if (#aVersionList < 3 or #bVersionList < 3) then
						return nil;
					end

					if (aVersionList[1] < bVersionList[1])then
						return -1;
					elseif (aVersionList[1] == bVersionList[1]) then
						if (aVersionList[2] < bVersionList[2]) then
							return -1;
						elseif (aVersionList[2] == bVersionList[2]) then
							if (aVersionList[3] < bVersionList[3]) then
								return -1;
							elseif (aVersionList[3] == bVersionList[3]) then
								return 0;
							else
								return 1;
							end
						else
							return 1;
						end
					else
						return 1;
					end
				end

				local compareResult = CompareVersion(self:GetCurrentVersion(), self.autoUpdater:getLatestVersion())

				if (compareResult == 1 or compareResult == 0) then
					callbackFunc(false, self:GetCurrentVersion());
					return true
				end
			end

			if(self.autoUpdater:isNeedUpdate())then
				callbackFunc(true, self.autoUpdater:getLatestVersion());
			else
				callbackFunc(false, self.autoUpdater:getLatestVersion());
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