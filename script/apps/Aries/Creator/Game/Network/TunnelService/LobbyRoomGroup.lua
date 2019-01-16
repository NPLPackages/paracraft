--[[
Title: LobbyRoomGroup

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/TunnelService/LobbyRoomGroup.lua");
local LobbyRoomGroup = commonlib.gettable("MyCompany.Aries.Game.Network.LobbyRoomGroup");
local room_group = LobbyRoomGroup:new():init()
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Network/TunnelService/LobbyRoomInfo.lua");
local LobbyRoomInfo = commonlib.gettable("MyCompany.Aries.Game.Network.LobbyRoomInfo");

local LobbyRoomGroup = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Network.LobbyRoomGroup"));

function LobbyRoomGroup:ctor()
	-- non full and unlock rooms 
	self._rooms = {};
	-- non full and lock rooms
	self._lock_rooms = {};
	-- full rooms
	self._fullrooms = {};
	
	self._projectId = nil;
end

function LobbyRoomGroup:init(projectId)
	self._projectId = projectId;

	return self;
end

function LobbyRoomGroup:GetRooms()
	return self._rooms;
end

function LobbyRoomGroup:GetLockRooms()
	return self._lock_rooms;
end

function LobbyRoomGroup:GetFullRooms()
	return self._fullrooms;
end

function LobbyRoomGroup:GetNotFullRoom(room_key)
	return self._rooms[room_key];
end

function LobbyRoomGroup.GetLockRoom(room_key)
	return self._lock_rooms[room_key];
end

function LobbyRoomGroup:GetFullRoom(room_key)
	return self._fullrooms[room_key];
end

function LobbyRoomGroup:SetRoomFull(room_key, bFull)
	if bFull then
		local room = self._rooms[room_key];
		if room then
			self._rooms[room_key] = nil;
			self._fullrooms[room_key] = room;
			return ;
		end
		
		room = self._lock_rooms[room_key];
		if room then
			self._lock_rooms[room_key] = nil;
			self._fullrooms[room_key] = room;
		end
	else
		local room = self._fullrooms[room_key];
		if room then
			self._fullrooms[room_key] = nil;
			if room:hasPassword() then
				self._lock_rooms[room_key] = room;
			else
				self._rooms[room_key] = room;
			end
		end
	end
end

function LobbyRoomGroup:GetAnyNoneFull()
	return next(self._rooms);
end

function LobbyRoomGroup:Log(text, ...)
	LOG.std(nil, "info", "LobbyRoomGroup", text, ...);
end

function LobbyRoomGroup:CreateRoom(room_key, password)
	self:Log("create a new room key = %s, password = %s", tostring(room_key), tostring(password));

	local room = LobbyRoomInfo:new():Init(self._projectId, self, room_key, password);
	
	room_key = room_key or room:GetRoomKey();
	
	if room:hasPassword() then
		self._lock_rooms[room_key] = room;
	else
		self._rooms[room_key] = room;
	end
	return room;
end