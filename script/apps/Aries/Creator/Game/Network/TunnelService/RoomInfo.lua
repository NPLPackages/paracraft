--[[
Title: RoomInfo
Author(s): LiXizhi
Date: 2016/3/4
Desc: room contains 
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

function RoomInfo:AddUser(username)
	self.users:add(username, {username = username, last_tick=0});
end

function RoomInfo:GetUser(username)
	if(username == "_admin") then
		return self.users:at(1);
	end
	return self.users:get(username);
end


function RoomInfo:RemoveUser(username)
	self.users:remove(username);
end

-- if a user does not send any message in certain time, we will need to time out and remove the user. 
function RoomInfo:CheckTimeout()
	-- check time out
	for key, room_info in self.users:pairs() do
		
	end
end
