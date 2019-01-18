NPL.load("(gl)script/apps/Aries/Creator/Game/Network/TunnelService/LobbyTunnelServer.lua");
NPL.load("(gl)script/apps/WebServer/mem_cache.lua");
local LobbyTunnelServer = commonlib.gettable("MyCompany.Aries.Game.Network.LobbyTunnelServer");

local mem_cache = commonlib.gettable("WebServer.mem_cache");
local obj_cache = mem_cache:GetInstance();

local CACHE_TIME = 10;

local function getRoomInfo(room)
	return {name = room:GetRoomKey(), clients = room:GetClientCount(), maxcount = room:GetMaxClients(), password = room:hasPassword()};
end

--[[
	@param projectId : "all"/projectId/nil, default is get the room_group with the name "default".
	@param type:  "all"/"non-full"/nil, default is get non-full and unlock rooms .
]]
local function run(req, res)
	
	local room_type = req:get("type") or "unlock";
	local projectId = req:get("projectId") or "default";
	
	local cache = obj_cache:get(projectId, room_type);
	
	if not cache then
		local json = {};
		local room_groups = LobbyTunnelServer:GetSingleton():GetRoomGroups();
	
		local function GenerateRoomGroupInfo(_projectId, room_group)
			local groupInfo = {};
			json[_projectId] = groupInfo;
			
			local rooms = room_group:GetRooms();
			for k, room in pairs(rooms) do
				table.insert(groupInfo, getRoomInfo(room));
			end
			
			if room_type == "non-full" then
				rooms = room_group:GetLockRooms();
				for k, room in pairs(rooms) do
					table.insert(groupInfo, getRoomInfo(room));
				end
			elseif room_type == "all" then
				rooms = room_group:GetLockRooms();
				for k, room in pairs(rooms) do
					table.insert(groupInfo, getRoomInfo(room));
				end
				
				rooms = room_group:GetFullRooms();
				for k, room in pairs(rooms) do
					table.insert(groupInfo, getRoomInfo(room));
				end
			end
			
		end
		
		if projectId == "all" then
			for _projectId, room_group in pairs(room_groups) do
				GenerateRoomGroupInfo(_projectId, room_group);
			end
		else
			local room_group = room_groups[projectId];
			if room_group then
				GenerateRoomGroupInfo(projectId, room_group);
			end
		end
		
		cache = commonlib.Json.Encode(json);
		obj_cache:set(projectId, cache, room_type, CACHE_TIME);
	end
	
	res:set_header('Content-Type', 'application/json');
	res:SetReturnCode(200);
	res:SetContent(cache);
	res:finish();
end

local function activate()
	--echo(msg);
	local req = WebServer.request:new():init(msg);
	run(req, req.response);
end
NPL.this(activate);