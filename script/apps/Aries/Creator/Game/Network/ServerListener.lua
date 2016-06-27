--[[
Title: ServerListener
Author(s): LiXizhi
Date: 2014/6/26
Desc: accept incoming connections. this is a singleton class
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ServerListener.lua");
local ServerListener = commonlib.gettable("MyCompany.Aries.Game.Network.ServerListener");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NetLoginHandler.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Connections.lua");
local Connections = commonlib.gettable("MyCompany.Aries.Game.Network.Connections");
local NetLoginHandler = commonlib.gettable("MyCompany.Aries.Game.Network.NetLoginHandler");
local NPLReturnCode = commonlib.gettable("NPLReturnCode");

local ServerListener = commonlib.gettable("MyCompany.Aries.Game.Network.ServerListener");

-- number of times we have accepted new connections. 
ServerListener.connectionCounter = 0;
-- active pending connection count
ServerListener.pendingConnectionCount = 0;
-- max pending connections. 
ServerListener.max_pending_connection = 1000;
-- list of all pending connections
ServerListener.pendingConnections = {};

-- whenever an unknown pending message is received. 
function ServerListener:OnAcceptIncomingConnection(msg, tunnelClient)
	local tid;
	if(msg and msg.tid) then
		tid = msg.tid;
	end
	if(tid) then
		if(self.pendingConnectionCount > self.max_pending_connection) then
			LOG.std(nil, "info", "ServerListener", "max pending connection reached ignored connection %s", tid);
		end
		self.connectionCounter = self.connectionCounter + 1;
		local login_handler = NetLoginHandler:new():Init(tid, tunnelClient);
		self:AddPendingConnection(tid, login_handler);
	end
end

-- this function is called periodically to remove any timed-out pending connections
function ServerListener:ProcessPendingConnections()
	local finished_connections;
	local pendingConnections = self.pendingConnections;
	local count=0;
	for tid, login_handler in pairs(pendingConnections) do
		login_handler:Tick();
		if(login_handler:IsFinishedProcessing()) then
			-- either authenticated or forcibily closed
			finished_connections = finished_connections or {};
			finished_connections[#finished_connections+1] = tid;
		else
			count = count + 1;
		end
	end
	self.pendingConnectionCount = count;
	if(finished_connections) then
		for i=1, #finished_connections do 
			pendingConnections[finished_connections[i]] = nil;
		end
	end
end

function ServerListener:AddPendingConnection(tid, login_handler)
	self.pendingConnections[tid] = login_handler;
end
