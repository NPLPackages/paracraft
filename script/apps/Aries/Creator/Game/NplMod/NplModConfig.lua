--[[
Title: NplModConfig
Author(s): leio
Date: 2021/1/7
Desc: define nplm config 
use the lib:
------------------------------------------------------------
local NplModConfig = NPL.load("(gl)script/apps/Aries/Creator/Game/NplMod/NplModConfig.lua");
------------------------------------------------------------
--]]
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
local NplModConfig = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

function NplModConfig:ctor()
    self.name = nil; -- global name for all modules
    self.version = nil;
    self.description = nil;
    self.dependencies = {};

end
function NplModConfig:parse(object)
    if(not object)then
        return
    end
    self.name = object.name;
    self.version = object.version;
    self.description = object.description;
    -- clear dependencies
    self.dependencies = {};
    if(object.dependencies)then
        for k,v in ipairs(object.dependencies) do
            self.dependencies[k] = commonlib.copy(v);
        end
    end
    
end
function NplModConfig:getDepByIndex(index)
    return self.dependencies[index];
end
function NplModConfig:getDepLen()
    return #self.dependencies;
end
function NplModConfig:toJson()
    local object = {};
    object.name = self.name;
    object.version = self.version;
    object.description = self.description;

    object.dependencies = {};
    for k,v in ipairs(self.dependencies) do
        object.dependencies[k] = commonlib.copy(v);
    end
    return object;
end