--[[
Title: KeepworkModManager
Author(s): pbb
Date: 2024.11.5
Desc: 获取keepwork网页的所有mod对象
------------------------------------------------------------
local KeepworkModManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Emscripten/KeepworkModManager.lua");
------------------------------------------------------------
]]
local EmscriptenAPI = NPL.load("(gl)script/apps/Aries/Creator/Game/Emscripten/EmscriptenAPI.lua");
local Emscripten = NPL.load("(gl)script/apps/Aries/Creator/Game/Emscripten/Emscripten.lua");
local KeepworkModManager = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

function KeepworkModManager:ctor()
    self.mods = {};
    self.mod_url = "";
    self.callback = nil;
    self:RegisterEvent();
    self:GetModUrl();
end

function KeepworkModManager:IsWebParacraftUrl(url) -- 判断是否为webparacraft的url
    if url and url ~= "" then
        local host = url:match("://([^/]+)");
        if host and (host:lower() == "emscripten.keepwork.com" or host:lower() == "webparacraft.keepwork.com") then
            return true;
        end
    end
    return false;
end

function KeepworkModManager:GetModUrl()
    EmscriptenAPI.GetParentWindowURL(function(data)
        local url = dana and data.url or "";
        if url and url ~= "" and not self:IsWebParacraftUrl(url) then --只有嵌入其他网站的页面才可以拿到mod列表
            self.mod_url = url;
            self:LoadMods();
        end
    end)
end

function KeepworkModManager:RegisterEvent()
    Emscripten:OnMsg("@webparacraft_GetModList", function(msgdata, msgid)
        self.mods = msgdata;
        if self.callback and type(self.callback) == "function" then
            self.callback(self.mods);
            self.callback = nil;
        end
        GameLogic.RunCommand("/sendevent LoadModList {finish = true,modUrl = " .. self.mod_url .."}")
    end)
end

function KeepworkModManager:LoadMods(callback)
    self.mods = {};
    self.callback = callback;
    Emscripten:SendMsg("@keepwork_GetModList",nil, nil, nil, "external")
end

function KeepworkModManager:RefreshMods(callback)
    self.mods = {};
    if callback then
        self.callback = callback;
    end
    Emscripten:SendMsg("@keepwork_GetModList",nil, nil, nil, "external")
end

function KeepworkModManager:UpdateMod(mod_id, data) -- 更新mod信息
    -- TODO: 这里需要调用keepwork的接口更新mod信息
    -- eventname: ModifyMod
end

function KeepworkModManager:GetMods()
    return self.mods;
end

KeepworkModManager:InitSingleton();