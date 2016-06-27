--[[
Title: BanList
Author(s): LiXizhi
Date: 2014/6/27
Desc: base connection
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Config/BanList.lua");
local BanList = commonlib.gettable("MyCompany.Aries.Game.Network.BanList");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ServerListener.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Connections.lua");

local BanList = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Network.BanList"));

function BanList:ctor()
	-- mapping from name to true. 
	self.theBanList = {};
end

-- Sets the NetHandler. Server-only.
function BanList:Init(filename)
	-- TODO
	self.filename = filename;
	self:LoadBanList();
	return self;
end

function BanList:isListActive()
	return self.bIslistActive;
end

function BanList:isBanned(name)
    if (not self:isListActive()) then
        return false;
    else
        self:RemoveExpiredBans();
        return self.theBanList[par1Str];
    end
end

function BanList:RemoveExpiredBans()
	-- TODO:
end

-- Loads the ban list from the file (adds every entry, does not clear the current list).
function BanList:LoadBanList()
	-- TODO:
end

function BanList:SaveToFile()
	-- TODO:
	self:RemoveExpiredBans();
end