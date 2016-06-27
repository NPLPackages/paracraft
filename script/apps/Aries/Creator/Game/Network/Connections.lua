--[[
Title: Connections
Author(s): LiXizhi
Date: 2014/6/25
Desc: all connections
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Connections.lua");
local Connections = commonlib.gettable("MyCompany.Aries.Game.Network.Connections");
Connections:Init();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ConnectionBase.lua");

local Connections = commonlib.gettable("MyCompany.Aries.Game.Network.Connections");
commonlib.setfield("Connections_", Connections);

-- mapping from connection nid to connection object. 
local all_connections = {};
local next_connection_id = 1;

function Connections:GetNextConnectionId()
	next_connection_id = next_connection_id + 1;
	return next_connection_id;
end

function Connections:AddConnection(nid, connection)
	if(nid) then
		all_connections[nid] = connection;
	end
end

function Connections:GetConnection(nid)
	return all_connections[nid];
end

function Connections:RemoveConnection(nid)
	if(nid) then
		all_connections[nid] = nil;
	end
end

function Connections:Init()
	NPL.RegisterEvent(0, "_n_Connections_network", ";Connections_.OnNetworkEvent();");
end

-- c++ callback function. 
function Connections.OnNetworkEvent()
	local msg = msg;
	local code = msg.code;
	if(code == NPLReturnCode.NPL_ConnectionDisconnected) then
		Connections:OnConnectionLost(msg.nid or msg.tid);
	end	
end

-- connection lost
function Connections:OnConnectionLost(nid)
	-- LOG.std(nil, "info", "Connections", "nid %s disconnected", tostring(nid));
	local connection = Connections:GetConnection(nid);
	if(connection) then
		connection:OnConnectionLost();
		-- inform the netServerHandler about it.
		connection:OnError("OnConnectionLost");
	end
end