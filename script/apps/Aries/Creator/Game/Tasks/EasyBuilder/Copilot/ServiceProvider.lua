--[[
Title: ServiceProvider
Author(s): copilot,pbb
Date: 2026/03/18
Desc: Typed service container for dependency injection into tool handlers.
Pure key-value store — no signals, no inheritance beyond NPL.export().

Usage:
    local ServiceProvider = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/ServiceProvider.lua");
    local sp = ServiceProvider:new();
    sp:Register("tts", ttsManagerInstance);
    local tts = sp:Get("tts");  -- returns instance or nil
    sp:Has("tts");              -- returns true
    sp:Unregister("tts");
]]

local ServiceProvider = commonlib.inherit(nil, NPL.export());

function ServiceProvider:ctor()
    self._services = {};
end

--[[
    Register a service instance by name.
    @param name: string — service identifier
    @param instance: any — service instance
]]
function ServiceProvider:Register(name, instance)
    if not name then
        LOG.std(nil, "warn", "ServiceProvider", "Register: name is required");
        return;
    end
    self._services[name] = instance;
end

--[[
    Get a service by name.
    @param name: string
    @return any|nil — service instance or nil if not registered
]]
function ServiceProvider:Get(name)
    return self._services[name];
end

--[[
    Check if a service is registered.
    @param name: string
    @return boolean
]]
function ServiceProvider:Has(name)
    return self._services[name] ~= nil;
end

--[[
    Remove a service registration.
    @param name: string
]]
function ServiceProvider:Unregister(name)
    self._services[name] = nil;
end
