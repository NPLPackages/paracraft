--[[
Title: RoomInfo
Author(s): LiXizhi
Date: 2016/3/4
Desc: a room contains a group of users. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/TunnelService/TRoomInfo.lua");
local RoomInfo = commonlib.gettable("MyCompany.Aries.Game.Network.RoomInfo");
local room_info = RoomInfo:new():init(room_key)
-------------------------------------------------------
]]
local RoomInfo = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Network.RoomInfo"));

function RoomInfo:ctor()
	-- array of all users. 
	self.users = commonlib.ArrayMap:new();
	self.nid_to_username = {};
end

local next_room_key = 0;

-- static function
function RoomInfo.GenerateRoomKey()
	next_room_key = next_room_key + 1;
	return "room"..next_room_key;
end


-- @param room_key: if nil, we will dynamically generate a room key
function RoomInfo:Init(room_key)
	self.room_key = room_key or RoomInfo.GenerateRoomKey();
	return self;
end

-- it will overwrite existing user of the same name
function RoomInfo:AddUser(username, nid)
	self.users:add(username, {username = username, nid=nid, last_tick=0});
	self.nid_to_username[nid] = username;
end

function RoomInfo:RemoveUser(username)
	local user = self:GetUser(username);
	if(user) then
		self.users:remove(username);
		self.nid_to_username[user.nid] = nil;
	end
end

function RoomInfo:RemoveUserByNid(nid)
	local username = self:GetUserNameFromNid(nid);
	if(username) then
		self:RemoveUser(username)
	end
	return username;
end

function RoomInfo:GetUserNameFromNid(nid)
	return self.nid_to_username[nid];
end

function RoomInfo:GetUser(username)
	return self.users:get(username);
end

function RoomInfo:GetUserByNid(nid)
	local username = self:GetUserNameFromNid(nid);
	if(username) then
		return self:GetUser(username);
	end
end

-- return ArrayMap. 
function RoomInfo:GetUsers()
	return self.users;
end

function RoomInfo:pairs()
	return self.users:pairs();
end

function RoomInfo:GetUsersCount()
	return self.users:size();
end

-- if a user does not send any message in certain time, we will need to time out and remove the user. 
function RoomInfo:CheckTimeout()
	-- check time out
	for key, room_info in self.users:pairs() do
		
	end
end
