--[[
Title: TunnelServer
Author(s): LiXizhi
Date: 2016/3/4
Desc: A tunnel server, receives relays message from one tunnel client to another tunnel client. 
All tunnel client must provide a valid room_key and username. 

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/TunnelService/TunnelServer.lua");
local TunnelServer = commonlib.gettable("MyCompany.Aries.Game.Network.TunnelServer");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/TunnelService/RoomInfo.lua");
NPL.load("(gl)script/ide/STL.lua");
local RoomInfo = commonlib.gettable("MyCompany.Aries.Game.Network.RoomInfo");

local TunnelServer = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Network.TunnelServer"));
TunnelServer:Property({"maxRoomCount", 50, "GetMaxRoomCount", "SetMaxRoomCount", auto=true})
TunnelServer:Property({"maxUserPerRoom", 100, "GetMaxUserPerRoom", "SetMaxUserPerRoom", auto=true})
TunnelServer:Property({"allowClientRoomCreation", true, "IsAllowClientRoomCreation", "SetAllowClientRoomCreation", auto=true})

local s_singletonServer;

function TunnelServer:ctor()
	s_singletonServer = self;
	-- array map
	self.rooms = commonlib.ArrayMap:new();
	self.nidToRoom = {};
	LOG.std(nil, "info", "TunnelServer", "tunnel server is started");
	NPL.RegisterEvent(0, "_n_TunnelServer_network", ";MyCompany.Aries.Game.Network.TunnelServer.OnNetworkEvent();");
end

-- c++ callback function. 
function TunnelServer.OnNetworkEvent()
	local self = s_singletonServer;
	local msg = msg;
	local code = msg.code;
	local msg_msg = msg.msg;
	if(code == NPLReturnCode.NPL_ConnectionDisconnected) then
		local nid = msg.nid or msg.tid;
		self:RemoveUserByNid(nid, "connection lost");
	end
end

-- remove a user from a room and inform everyone in that room. 
--@param reason: nil or a string to notify other clients
function TunnelServer:RemoveUserByNid(nid, reason)
	local room = self:GetRoomByNid(nid)
	if(room) then
		local username = room:RemoveUserByNid(nid);
		if(username) then
			-- inform everyone in the room that a user left.
			for key, user in room:pairs() do
				self:sendMsg(user.nid, {type="tunnel_user_disconnect", username = username, reason=reason});
			end
		end
		LOG.std(nil, "info", "TunnelServer", "user (%s) removed", username or "", nid or "");
	end
	self.nidToRoom[nid] = nil;
end

function TunnelServer:GetRoomByNid(nid)
	return self.nidToRoom[nid]
end

-- return true if succeed, false, if room is full
function TunnelServer:AddUserToRoom(username, nid, room)
	-- a single nid can only be in one room
	local old_room = self:GetRoomByNid(nid)
	if(old_room and old_room ~= room) then
		self:RemoveUserByNid(nid, "duplicated rooms");
	end
	self.nidToRoom[nid] = room;

	-- duplicated names in the same room not allowed, we will kick the previous one. 
	local user = room:GetUser(username);
	if(user) then
		if(user.nid~=nid) then
			-- kick the old user.
			self:RemoveUserByNid(user.nid, "duplicated usernames");
			NPL.reject(user.nid);
		else
			-- user already in the room
			return true;
		end
	end
	if(room:GetUsersCount() < self:GetMaxUserPerRoom()) then
		room:AddUser(username, nid);
		return true;
	else
		return false;
	end
end

-- @param room_key: new room_key
-- @param nid: the creator's nid. 
-- @return room, errMsg
function TunnelServer:TryCreateRoom(room_key, nid)
	if(not room_key) then
		return;
	end
	local room = self:GetRoom(room_key);
	if(not room) then
		if(self:GetRoomCount() >= self:GetMaxRoomCount()) then
			self:ClearEmptyRooms()
		end
		if(self:GetRoomCount() < self:GetMaxRoomCount()) then
			room = RoomInfo:new():Init(room_key)
			self:updateInsertRoom(room)
		else
			return nil, "max room count reached";
		end
	end
	return room;
end

function TunnelServer:ClearEmptyRooms()
	local emptyRooms;
	for room_key, room in self.rooms:pairs() do
		if(room:GetUsersCount() == 0) then
			emptyRooms = emptyRooms or {};
			emptyRooms[#emptyRooms+1] = room_key;
		end
	end
	if(emptyRooms) then
		for _, room_key in ipairs(emptyRooms) do
			self.rooms:remove(room_key);
			LOG.std(nil, "debug", "TunnelServer", "empty room (%s) is removed", room_key);
		end
	end
end

-- update and insert room. this function is usually asked by lobbyserver to dynamically allocate a room. 
function TunnelServer:updateInsertRoom(room_info)
	if(not room_info) then
		return;
	end
	self.rooms:add(room_info.room_key, room_info);
	LOG.std(nil, "debug", "TunnelServer", "room (%s) is created", room_info.room_key);
end

function TunnelServer:GetRoom(room_key)
	return self.rooms:get(room_key);
end

function TunnelServer:GetRoomCount()
	return self.rooms:size();
end

function TunnelServer:GetClientAddress(nid)
	return format("%s:%s", nid, "script/apps/Aries/Creator/Game/Network/TunnelService/TunnelClient.lua");
end


-- private: relay a message to dest
function TunnelServer:sendMessageToDest(dest_username, msg, src_username, room_key, room)
	if(dest_username) then
		local user = room:GetUser(dest_username);
		if(user) then
			-- relay the message
			self:sendMsg(user.nid, {room_key = room_key, from = src_username, msg=msg, });
		else
			-- no valid user found, assume it is disconnected
			LOG.std(nil, "debug", "TunnelServer", "no valid dest (target) user %s in room %s", dest_username, room_key);
			local src_user = room:GetUser(src_username);
			if(src_user) then
				self:sendMsg(src_user.nid, {type="tunnel_user_disconnect", username = dest_username, reason="user not found"});
			end
		end
	end
end

function TunnelServer:sendMsg(nid, msg)
	return NPL.activate(self:GetClientAddress(nid), msg);
end

function TunnelServer:handleReceive(msg)
	local msg_type = msg.type;
	local nid = msg.nid or msg.tid;
	
	if(not msg_type and msg.room_key) then
		-- relay message from source to destination on behalf of source user
		
		local room_key = msg.room_key;
		local room = self:GetRoom(room_key);
		if(room) then
			local src_username = room:GetUserNameFromNid(nid);
			if(not src_username) then
				-- source username not valid
				return;
			end

			if(msg.dest) then
				self:sendMessageToDest(msg.dest, msg.msg, src_username, room_key, room)
			elseif(msg.dests) then
				local dests = msg.dests;
				for i=1, #dests do
					self:sendMessageToDest(dests[i], msg.msg, src_username, room_key, room)
				end
			else
				-- no destination in message, should never goes here
			end
		else
			-- TODO: no room found,...
			NPL.reject(nid);
		end
	elseif(msg_type == "tunnel_login") then
		local room_key = msg.room_key;
		if(not room_key or room_key=="") then
			self:sendMsg(nid, {type="tunnel_login", result = false, error="room key is required"});
			return;
		end

		local room = self:GetRoom(room_key);
		if(not room) then
			if(self:IsAllowClientRoomCreation()) then
				local errMsg;
				room, errMsg = self:TryCreateRoom(room_key, nid);
				if(not room) then
					self:sendMsg(nid, {type="tunnel_login", result = false, error = errMsg});
				end
			else
				-- otherwise, room can only be created via a lobby server in the trusted intranet 
				self:sendMsg(nid, {type="tunnel_login", result = false, error="room does not exist"});
			end
		end
		
		if(room and msg.username) then
			local username = msg.username;
			-- make unique and verify username with the one in the room
			if(self:AddUserToRoom(username, nid, room)) then
				LOG.std(nil, "info", "TunnelServer", "room: `%s` added client `%s` as %s", room_key, username, nid);
				-- send reply
				self:sendMsg(nid, {type="tunnel_login", result = true})
			else
				self:sendMsg(nid, {type="tunnel_login", result = false, error="room is full"})
			end
		end
	elseif(msg_type == "update_room" and msg.nid) then
		-- usually sent from lobby Server to update valid rooms
		-- TODO: call :updateInsertRoom(room_info);
	end
end


local function activate()
	local msg = msg;
	-- echo({"TunnelServer:receive--------->", msg})
	if(s_singletonServer and msg) then
		s_singletonServer:handleReceive(msg)
	end
end
NPL.this(activate);