--[[
    authored by: pbb
    created on: 2024-04-22 16:30:00
    description:
        This file contains the API for the Community function.
    uselibs:
         NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/CommunityAPI.lua");
         local CommunityAPI = commonlib.gettable("MyCompany.Aries.Creator.Game.Tasks.Community.CommunityAPI");
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserPlugin.lua");
local NplBrowserPlugin = commonlib.gettable("NplBrowser.NplBrowserPlugin");

local CommunityAPI = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"),commonlib.gettable("MyCompany.Aries.Creator.Game.Tasks.Community.CommunityAPI"))

CommunityAPI:Signal("displayModeChanged");

function CommunityAPI:ctor()
    self.events = commonlib.EventSystem:new();
    self:RegisterEvent("setDisplayMode", function(msg)
        self:OnDisplayModeChange(msg and msg.mode)
    end)
end

function CommunityAPI:Init(browser_name)
    self.browser_name = browser_name;
    GameLogic.GetFilters():remove_filter("community.vip.notice", CommunityAPI.VipExchangeResultCallback);
	GameLogic.GetFilters():add_filter("community.vip.notice", CommunityAPI.VipExchangeResultCallback);
end

function CommunityAPI.VipExchangeResultCallback(payload)
    CommunityAPI:SendEvent("VipNotice", payload);
end

function CommunityAPI:OnDisplayModeChange(mode)
    self:displayModeChanged(mode);
    -- notify display mode changed to CommunityAPI.ts
    self:SendEvent("setDisplayMode", {
        mode = mode
    });
end
------------------------------
-- low level event related functions 
------------------------------
-- @param callbackUniqueName: can be nil. if not, only one callback can be set per callbackUniqueName. 
function CommunityAPI:RegisterEvent(name, callbackFunc, callbackUniqueName)
    self.events:AddEventListener(name, function(self, event)
        callbackFunc(event.msg)
    end, events, callbackUniqueName);
end

function CommunityAPI:UnregisterEvent(name)
    self.events:RemoveEventListener(name);
end

function CommunityAPI:DispatchLocalEvent(name, msg)
    self.events:DispatchEvent({
        type = name,
        msg = msg
    });
end

-- send a remote event to webview  
function CommunityAPI:SendEvent(name, msg, callbackFunc)
    -- TODO: SendMessage
    if not msg then
        return
    end
    if msg.msg then -- delete the msg data receive from webview
        msg.msg = nil
    end
    msg.name = name or ""
    self:SendMessage(msg)
end

function CommunityAPI:SendMessage(message)
    if not message then
        return
    end
    local p = NplBrowserPlugin.GetWindowState(self.browser_name)
    if not p then
        p = {
            id = self.browser_name
        }
    end
    if p then
        local sendMsg = {}
        if type(message) == "table" then
            sendMsg = message
            sendMsg.jsFile = "CommunityAPI.ts"
        end
        if type(message) == "string" then
            sendMsg.jsFile = "CommunityAPI.ts"
            sendMsg.msg = message
        end
        NplBrowserPlugin.SendMessage(p, sendMsg)
    end
end

function CommunityAPI.GetUrlDecodeData(data)
    if type(data) == "string" then
        local str = commonlib.Encoding.url_decode(data)
        return commonlib.Json.Decode(str)
    end

    if type(data) == "table" then
        local jsonStr = commonlib.Json.Encode(data)
        jsonStr = commonlib.Encoding.url_decode(jsonStr)
        return commonlib.Json.Decode(jsonStr)
    end
end

-- receiving a message from webview 
function CommunityAPI:OnReceiveMessageFromWebView(msg)
    local data = msg and msg.msg
    if msg.callbackSessionId then
        data.callbackId = msg.callbackSessionId
    end
    print("CommunityAPI.OnReceiveMessageFromWebView========")
    echo(msg,true)
	self:DispatchLocalEvent(msg.eventName, data);
end

local function activate()
    
    local msg = NplBrowserPlugin.TranslateJsMessage(msg);
    CommunityAPI:OnReceiveMessageFromWebView(msg);
end

-- receiver for javascript:
-- NPL.activate("CommunityAPI.lua", {eventName:string, msg:table, ...})
NPL.this(activate, {filename = "CommunityAPI.lua"})

CommunityAPI:InitSingleton();