--[[
Title: EmscriptenAPI
Author(s): wxa
Date: 2023.6.12
Desc: lua 与 js 通信
------------------------------------------------------------
local EmscriptenAPI = NPL.load("(gl)script/apps/Aries/Creator/Game/Emscripten/EmscriptenAPI.lua");
------------------------------------------------------------
]]
local Emscripten = NPL.load("(gl)script/apps/Aries/Creator/Game/Emscripten/Emscripten.lua");
local NPLJS = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NPLJS.lua");
local EmscriptenAPI = NPL.export()

function EmscriptenAPI.GetParentWindowURL(callback)
    Emscripten:SendMsg("GetParentWindowURL", nil, nil, callback);    
end

function EmscriptenAPI.DownloadCharactersDB(db_url, callback)
    db_url = db_url or "http://127.0.0.1:8088/npl/webparacraft/database/characters.db";
    -- db_url = db_url or "https://webparacraft.keepwork.com/Database/characters.db";
    NPL.load("(gl)script/apps/Aries/Creator/Game/API/FileDownloader.lua");
    local FileDownloader = commonlib.gettable("MyCompany.Aries.Creator.Game.API.FileDownloader");
    local downloader = FileDownloader:new();
    downloader:SetSilent(true)
    local filename = db_url:match("([^/]+)$");
    local diskDirectory = ParaIO.GetWritablePath() .. "Database/";  -- cp_old 用的 Database  win32 用的是 database
    local diskFilePath = diskDirectory .. filename;

    if(ParaIO.DoesFileExist(diskFilePath, true)) then
        LOG.std(nil, "info", "EmscriptenAPI", "db url %s already exist", db_url)
        if(callback) then
            callback(true)
        end
    else
        ParaIO.CreateDirectory(diskDirectory);
        downloader:Init(L"下载美术资源", db_url, diskFilePath, function(bSucceed, localFile)
			if(bSucceed and localFile) then
                GameLogic.FlushDiskIO();
            else
                LOG.std(nil, "warn", "WorldCommon", "failed to prepare asset url %s, because %s", assetUrl, tostring(localFile))
            end
            if(callback) then
                callback(bSucceed)
            end
        end, "access plus 1 year");
    end
end

function EmscriptenAPI.BindKeepworkPage(url, callback)
    local api = {};
    api.SendMsg = function(msgname, msgdata, msgid, callback)
        NPLJS:SendMsg(msgname, msgdata, msgid, callback);
    end
    api.OnMsg = function(msgname, callback)
        NPLJS:OnMsg(msgname, callback); 
    end

    NPLJS:Open(url, function()
        if (type(callback) == "function") then
            callback(api);
        end
    end);

    return api;
end

function EmscriptenAPI.ShowKeepworkPage(x, y, width, height)
    NPLJS:SetSize(x, y, width, height);
end

function EmscriptenAPI.CloseKeepworkPage()
    NPLJS:Close();
end

function EmscriptenAPI.BindParentKeepworkPage()
    local api = {};
    api.SendMsg = function(msgname, msgdata, msgid, callback)
        Emscripten:SendMsg(msgname, msgdata, msgid, callback, "external");
    end
    api.OnMsg = function(msgname, callback)
        Emscripten:OnMsg(msgname, callback); 
    end
    return api;
end

-- callback({filepaths = {filepath,...}})
function EmscriptenAPI.OpenFileDialog(callback, multiple, accept)
    Emscripten:SendMsg("OpenFileDialog", {multiple = multiple, accept = accept}, nil, callback);    
end