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
local RoomInfo = commonlib.gettable("MyCompany.Aries.Game.Network.RoomInfo");

local TunnelServer = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Network.TunnelServer"));

local s_singletonServer;

function TunnelServer:ctor()
	s_singletonServer = self;
	-- mapping from room_key to room_table
	self.rooms = {};
	self.userToNid = {};
	self.nidToUser = {};
	LOG.std(nil, "info", "TunnelServer", "tunnel server is started");
end

-- update and insert room. this function is usually asked by lobbyserver to dynamically allocate a room. 
function TunnelServer:updateInsertRoom(room_info)
	if(not room_info) then
		return;
	end
	self.rooms[room_info.room_key] = room_info;
end

function TunnelServer:GetRoom(room_key)
	return self.rooms[room_key];
end

function TunnelServer:GetUserNameFromNid(nid)
	return self.nidToUser[nid];
end

function TunnelServer:GetClientAddress(username)
	local nid = self.userToNid[username];
	if(nid) then
		return format("%s:%s", nid, "script/apps/Aries/Creator/Game/Network/TunnelService/TunnelClient.lua");
	end
end

function TunnelServer:handleReceive(msg)
	local msg_type = msg.type;
	local nid = msg.nid or msg.tid;
	
	if(not msg_type and msg.room_key and msg.dest) then
		-- relay message from source to destination on behalf of source user
		local src_username = self:GetUserNameFromNid(nid);
		if(not src_username) then
			return;
		end
		local room_key = msg.room_key;
		local room = self:GetRoom(room_key);
		if(room) then
			local dest_username = msg.dest;
			local user = room:GetUser(dest_username);
			local dest_addr = self:GetClientAddress(dest_username);
			if(not dest_addr) then
				-- TODO: no connection for user,...
				LOG.std(nil, "info", "TunnelServer", "no connection for user %s in room %s", dest_username, room_key);
			elseif(not user) then
				-- TODO: no valid user found,...
				LOG.std(nil, "info", "TunnelServer", "no valid dest (target) user %s in room %s", dest_username, room_key);
			else
				-- relay the message
				NPL.activate(dest_addr, {room_key = room_key, from = src_username, msg=msg.msg, });
			end
		else
			-- TODO: no room found,...
			NPL.reject(nid);
		end
	elseif(msg_type == "tunnel_login") then
		local room_key = msg.room_key or "";
		local room = self:GetRoom(room_key);
		if(room and msg.username) then
			local username = msg.username;
			-- TODO make unique and verify username with the one in the room
			self.userToNid[username] = nid;
			self.nidToUser[nid] = username;
			-- Remove this, since by logic, user should already exist when handling "update_room" message. 
			-- or should we allow any authenticated client to add users in the room?
			room:AddUser(username);
			LOG.std(nil, "info", "TunnelServer", "room: `%s` added client `%s` as %s", room_key, msg.username, nid);
			-- send reply
			local dest_addr = self:GetClientAddress(msg.username);
			if(dest_addr) then
				NPL.activate(dest_addr, {type="tunnel_login", result = true});
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