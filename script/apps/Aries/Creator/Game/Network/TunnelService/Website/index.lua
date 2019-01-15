NPL.load("(gl)script/apps/Aries/Creator/Game/Network/TunnelService/LobbyTunnelServer.lua");
local LobbyTunnelServer = commonlib.gettable("MyCompany.Aries.Game.Network.LobbyTunnelServer");


local function getRoomInfo(room)
	return {name = room:GetRoomKey(), clients = room:GetClientCount(), maxcount = room:GetMaxClients(), password = room:hasPassword()};
end

local function run(req, res)
	
	local room_type = req:get("type");
	local json = {};
	
	local rooms = LobbyTunnelServer:GetSingleton():GetRooms();

	for k, room in pairs(rooms) do
		table.insert(json, getRoomInfo(room));
	end
	
	if room_type == "non-full" then
		rooms = LobbyTunnelServer:GetSingleton():GetLockRooms();
		for k, room in pairs(rooms) do
			table.insert(json, getRoomInfo(room));
		end
	elseif room_type == "all" then
		rooms = LobbyTunnelServer:GetSingleton():GetLockRooms();
		for k, room in pairs(rooms) do
			table.insert(json, getRoomInfo(room));
		end
		
		rooms = LobbyTunnelServer:GetSingleton():GetFullRooms();
		for k, room in pairs(rooms) do
			table.insert(json, getRoomInfo(room));
		end
	end
	
	
	res:send_json(json, 200);
end

local function activate()
	echo(msg);
	local req = WebServer.request:new():init(msg);
	run(req, req.response);
end
NPL.this(activate);