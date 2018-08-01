--[[
Title: ClientUpdater 
Author(s): LiXizhi
Date: 2018.7.26
Desc: for client update on mobile devices
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ClientUpdater.lua");
local ClientUpdater = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ClientUpdater");
local updater = ClientUpdater:new();
updater:Check(function(bNeedUpdate, latestVersion)
end);
------------------------------------------------------------
]]
local AssetsManager = NPL.load("AutoUpdater");

-- create class
local ClientUpdater = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.MainLogin.ClientUpdater"));

function ClientUpdater:ctor()
	if(not AssetsManager) then
		LOG.std(nil, "info", "ClientUpdater", "AutoUpdater not found");
		return;
	end
	self.autoUpdater = AssetsManager:new();

	self.autoUpdater:onInit(ParaIO.GetWritablePath(), "config/autoupdater/paracraft_win32.xml", function(state)
		self:OnEvent(state);
	end)
end

-- @param callbackFunc: function(bNeedUpdate, latestVersion)
function ClientUpdater:Check(callbackFunc)
	if(not self.autoUpdater) then
		return
	end
	
	self.autoUpdater:check(nil, function()
		if(not callbackFunc) then
			return
		end
		-- echo({self.autoUpdater:getCurVersion(), self.autoUpdater:getLatestVersion()});
		if(self.autoUpdater:isNeedUpdate())then
			-- self.autoUpdater:download();
			callbackFunc(true, self.autoUpdater:getLatestVersion());
		else
			callbackFunc(false);
		end
	end);
end

function ClientUpdater:OnEvent(state)
	local a = self.autoUpdater;
	if(state)then
        if(state == AssetsManager.State.PREDOWNLOAD_VERSION)then
            echo("=========PREDOWNLOAD_VERSION");
        elseif(state == AssetsManager.State.DOWNLOADING_VERSION)then
            echo("=========DOWNLOADING_VERSION");
        elseif(state == AssetsManager.State.VERSION_CHECKED)then
            echo("=========VERSION_CHECKED");
        elseif(state == AssetsManager.State.VERSION_ERROR)then
            echo("=========VERSION_ERROR");
        elseif(state == AssetsManager.State.PREDOWNLOAD_MANIFEST)then
            echo("=========PREDOWNLOAD_MANIFEST");
        elseif(state == AssetsManager.State.DOWNLOADING_MANIFEST)then
            echo("=========DOWNLOADING_MANIFEST");
        elseif(state == AssetsManager.State.MANIFEST_DOWNLOADED)then
            echo("=========MANIFEST_DOWNLOADED");
        elseif(state == AssetsManager.State.MANIFEST_ERROR)then
            echo("=========MANIFEST_ERROR");
        elseif(state == AssetsManager.State.PREDOWNLOAD_ASSETS)then
            echo("=========PREDOWNLOAD_ASSETS");
            self.timer = commonlib.Timer:new({callbackFunc = function(timer)
                echo(a:getPercent());
            end})
            self.timer:Change(0, 100)
        elseif(state == AssetsManager.State.DOWNLOADING_ASSETS)then
            echo("=========DOWNLOADING_ASSETS");
        elseif(state == AssetsManager.State.ASSETS_DOWNLOADED)then
            echo("=========ASSETS_DOWNLOADED");
            echo(a:getPercent());
            if(self.timer)then
                self.timer:Change();
            end
            -- a:apply();
        elseif(state == AssetsManager.State.ASSETS_ERROR)then
            echo("=========ASSETS_ERROR");
        elseif(state == AssetsManager.State.PREUPDATE)then
            echo("=========PREUPDATE");
        elseif(state == AssetsManager.State.UPDATING)then
            echo("=========UPDATING");
        elseif(state == AssetsManager.State.UPDATED)then
            echo("=========UPDATED");
        elseif(state == AssetsManager.State.FAIL_TO_UPDATED)then
            echo("=========FAIL_TO_UPDATED");
        end    
    end
end

function ClientUpdater:OnClickUpdate()
	ParaGlobal.ShellExecute("open", L"http://paracraft.keepwork.com/download?lang=zh", "", "", 1);
end