--[[
Title: statistics about the user
Author(s): LiXizhi
Date: 2013/11/20
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/API/UserStat.lua");
local UserStat = commonlib.gettable("MyCompany.Aries.Creator.Game.API.UserStat");
local stat = UserStat:new():Init(profile, name, value);
-------------------------------------------------------
]]

local UserStat = commonlib.gettable("MyCompany.Aries.Creator.Game.API.UserStat");

-- @param flush_count: the value must increase by this ammount before flushing to db. if nil, stat is flushed to db on change. 
local stats_names = {
	["blocks_created"] = {flush_count = 30, },
	["blocks_destroyed"] = {flush_count = 30, },
	["distance_walked"] = {flush_count = 30, },
}

-- create a new profile. the profile's filename must not be nil. 
function UserStat:new(o)
	o = o or {}; -- create object if user does not provide one
	
	setmetatable(o, self);
	self.__index = self;

	return o;
end

-- @param profile: UserProfile object
-- @return nil if failed. 
function UserStat:Init(profile, name, value)
	if(stats_names[name]) then
		local stat_info = stats_names[name];
		self.profile = profile;
		self.name = name;
		self.value = self.profile:LoadData(self.name, value or 0);
		self.last_flush_value = self.value;
		self.flush_count = stat_info.flush_count;
		return self;
	else
		LOG.std(nil, "warn", "UserStat", "unknown stat %s", name or "");
	end
end

function UserStat:GetValue(default_value)
	return self.value or default_value;
end

function UserStat:AddValue(value)
	self.value =  self.value + value;

	if( not self.flush_count or (self.value - self.last_flush_value) >= self.flush_count) then
		self.last_flush_value = self.value;
		self.profile:SaveData(self.name, self.value);
	end
end