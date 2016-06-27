--[[
Title: AuthUserList
Author(s): LiXizhi
Date: 2014/7/31
Desc: base connection
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Auth/Config/AuthUserList.lua");
local AuthUserList = commonlib.gettable("MyCompany.Aries.Game.Network.AuthUserList");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ServerListener.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Connections.lua");

local AuthUserList = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Network.AuthUserList"));

function AuthUserList:ctor()
	-- mapping from name to true. 
	self.theAuthUserList = {};
end

-- Sets the NetHandler. Server-only.
function AuthUserList:Init(filename)
	-- TODO
	self.filename = filename;
	self:LoadAuthUserList();
	return self;
end

function AuthUserList:isListActive()
	return self.bIslistActive;
end

function AuthUserList:isBanned(name)
    if (not self:isListActive()) then
        return false;
    else
        self:RemoveExpiredBans();
        return self.theAuthUserList[par1Str];
    end
end

function AuthUserList:RemoveExpiredBans()
	-- TODO:
end

-- Loads the ban list from the file (adds every entry, does not clear the current list).
function AuthUserList:LoadAuthUserList()
	-- TODO:
end

function AuthUserList:SaveToFile()
	-- TODO:
	self:RemoveExpiredBans();
end