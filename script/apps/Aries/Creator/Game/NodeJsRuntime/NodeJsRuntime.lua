--[[
Title: NodeJsRuntime
Author(s): leio
Date: 2019.12.25
Desc: 
use the lib:
------------------------------------------------------------
local NodeJsRuntime = NPL.load("(gl)script/apps/Aries/Creator/Game/NodeJsRuntime/NodeJsRuntime.lua");
NodeJsRuntime.Check()
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/timer.lua");

NPL.load("(gl)script/ide/System/Util/ZipFile.lua");
local ZipFile = commonlib.gettable("System.Util.ZipFile");


local AutoUpdateLoaderPageManager = NPL.load("(gl)script/apps/Aries/Creator/Game/AutoUpdateLoader/AutoUpdateLoaderPageManager.lua");

local NodeJsRuntime = NPL.export();

function NodeJsRuntime.GetRoot()
	return ParaIO.GetCurDirectory(0).."NodeJsRuntime";
end
function NodeJsRuntime.Check(callback)
    if(not NodeJsRuntime.OsSupported())then
	    LOG.std(nil, "info", "NodeJsRuntime", "NodeJsRuntime isn't supported on %s", System.os.GetPlatform());
        return
    end
    local nodejs_loader_page = AutoUpdateLoaderPageManager.CreateOrGet_NodeJsRuntime();
    nodejs_loader_page:Check(function(v,downloadUnits)
        local need_unzip = false;
        if(downloadUnits)then
            local k,v;
            for k,v in ipairs(downloadUnits) do
                local customId = v.customId;
                if(customId)then
                    customId = string.lower(customId);
                    if(string.match(customId,"node_modules.zip"))then
                        
                        need_unzip = true;
                        break;
                    end
                end
            end
        end
        if(need_unzip)then
            _guihelper.MessageBox(L"第一次安装NodeJs Runtime比较慢，请耐心等待！");
            local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
                NodeJsRuntime.UnZip_node_modules();
                _guihelper.MessageBox(L"成功安装NodeJs Runtime！");

                if(v and callback)then
                    callback();
                end
            end})
            mytimer:Change(2000, nil)
        else
            if(v and callback)then
                callback();
            end
        end
        
    end)
end
function NodeJsRuntime.IsValid()
    local nodejs_loader_page = AutoUpdateLoaderPageManager.CreateOrGet_NodeJsRuntime();
    return nodejs_loader_page:MainFilesExisted(nodejs_loader_page.dest_folder);
end
function NodeJsRuntime.UnZip_node_modules()
    local filename = "NodeJsRuntime/node_modules.zip";
    if(ParaIO.DoesFileExist(filename))then
        local zipFile = ZipFile:new();
        if(zipFile:open(filename)) then
	        zipFile:unzip(NodeJsRuntime.GetRoot() .. "/",100000);
	        zipFile:close();
        end
    end
end

function NodeJsRuntime.OsSupported()
    local platform = System.os.GetPlatform();
    if(platform == "win32")then
        return true;
    end
    return false;
end