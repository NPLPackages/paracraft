--[[
Title: ServerConfig
Author(s): LiXizhi
Date: 2014/7/31
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ServerConfig.lua");
local ServerConfig = commonlib.gettable("MyCompany.Aries.Game.Network.ServerConfig");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ServerListener.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Connections.lua");

local ServerConfig = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Network.ServerConfig"));

function ServerConfig:ctor()
	-- mapping from name to true. 
	self.theServerConfig = {};
end

-- Sets the NetHandler. Server-only.
function ServerConfig:Init(filename)
	-- TODO
	self.filename = filename;
	self:LoadServerConfig();
	return self;
end

function ServerConfig:isListActive()
	return self.bIslistActive;
end

function ServerConfig:isBanned(name)
    if (not self:isListActive()) then
        return false;
    else
        self:RemoveExpiredBans();
        return self.theServerConfig[par1Str];
    end
end

function ServerConfig:RemoveExpiredBans()
	-- TODO:
end

-- Loads the ban list from the file (adds every entry, does not clear the current list).
function ServerConfig:LoadServerConfig()
	-- TODO:
end

function ServerConfig:SaveToFile()
	-- TODO:
	self:RemoveExpiredBans();
end