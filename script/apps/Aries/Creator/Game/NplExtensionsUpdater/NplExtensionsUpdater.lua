--[[
Title: NplExtensionsUpdater
Author(s): leio
Date: 2021/8/17
Desc: auto update npl_extentions
use the lib:
------------------------------------------------------------
local NplExtensionsUpdater = NPL.load("(gl)script/apps/Aries/Creator/Game/NplExtensionsUpdater/NplExtensionsUpdater.lua");
NplExtensionsUpdater.Check()
------------------------------------------------------------
]]
local AutoUpdateLoaderPageManager = NPL.load("(gl)script/apps/Aries/Creator/Game/AutoUpdateLoader/AutoUpdateLoaderPageManager.lua");
local NplExtensionsUpdater = NPL.export();

NplExtensionsUpdater.name = "npl_extensions"; 
NplExtensionsUpdater.loaded = false
function NplExtensionsUpdater.GetRoot()
	return ParaIO.GetCurDirectory(0)..NplExtensionsUpdater.name;
end
function NplExtensionsUpdater.IsLoaded()
	return NplExtensionsUpdater.loaded;
end
function NplExtensionsUpdater.Check(callback)
    if(not NplExtensionsUpdater.OsSupported())then
	    LOG.std(nil, "info", "NplExtensionsUpdater", "NplExtensionsUpdater isn't supported on %s", System.os.GetPlatform());
        return
    end
    local loader_page = AutoUpdateLoaderPageManager.CreateOrGet_NplExtensions(NplExtensionsUpdater.name);
    loader_page:Check(function(v, downloadUnits)
		if(v and not NplExtensionsUpdater.loaded)then
            GameLogic.AddBBS("statusBar", L"NPL代码库下载完成", 5000, "0 255 0");
		end
		NplExtensionsUpdater.loaded = v;
		if(callback)then
			callback(v, downloadUnits);
		end
    end)
end

function NplExtensionsUpdater.OsSupported()
    local platform = System.os.GetPlatform();
    if(platform == "win32")then
        return true;
    end
    return false;
end