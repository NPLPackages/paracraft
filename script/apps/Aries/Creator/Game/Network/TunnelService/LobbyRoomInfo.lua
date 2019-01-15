--[[
Title: LobbyRoomInfo

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/TunnelService/LobbyRoomInfo.lua");
local LobbyRoomInfo = commonlib.gettable("MyCompany.Aries.Game.Network.LobbyRoomInfo");
local room_info = LobbyRoomInfo:new():init(room_key)
-------------------------------------------------------
]]
local LobbyRoomInfo = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Network.LobbyRoomInfo"));

LobbyRoomInfo:Property({"MaxClients", 8, "GetMaxClients", "SetMaxClients", auto=true});

function LobbyRoomInfo:ctor()
	self._room_key = nil;
	self._password = nil;
	self._clients_count = 0;
	self._users = {};
end

local next_room_key = 0;

-- static function
function LobbyRoomInfo.GenerateRoomKey()
	next_room_key = next_room_key + 1;
	return "room" .. next_room_key;
end

-- @param room_key: if nil, we will dynamically generate a room key
function LobbyRoomInfo:Init(room_key, password)
	self._room_key = room_key or LobbyRoomInfo.GenerateRoomKey();
	self._password = password;
	return self;
end

function LobbyRoomInfo:isFull()
	return self._clients_count >= self:GetMaxClients();
end

function LobbyRoomInfo:GetClientCount()
	return self._clients_count;
end

function LobbyRoomInfo:hasPassword()
	return self._password ~= nil;
end

function LobbyRoomInfo:canJoin(password)
	if self._password then
		return password == self._password;
	else
		return true;
	end
end

function LobbyRoomInfo:AddClient(keepworkUsername, client)
	self._users[keepworkUsername] = client;
	self._clients_count = self._clients_count + 1;
end

function LobbyRoomInfo:GetClient(keepworkUsername)
	return self._users[keepworkUsername];
end

function LobbyRoomInfo:GetClients()
	return self._users;
end

function LobbyRoomInfo:RemoveClient(keepworkUsername)
	self._users[keepworkUsername] = nil;
	self._clients_count = self._clients_count - 1;
end



function LobbyRoomInfo:GetRoomKey()
	return self._room_key;
end
