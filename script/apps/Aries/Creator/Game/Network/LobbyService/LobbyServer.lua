--[[
Title: LobbyServer
Author(s): LiXizhi
Date: 2018/12/19
Desc: all LobbyServer
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/LobbyService/LobbyServer.lua");
local LobbyServer = commonlib.gettable("MyCompany.Aries.Game.Network.LobbyServer");
-------------------------------------------------------
]]
local bTest = true;

NPL.load("(gl)script/ide/event_mapping.lua");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local NPLReturnCode = commonlib.gettable("NPLReturnCode");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")

local LobbyMessageType = commonlib.gettable("MyCompany.Aries.Game.Network.LobbyMessageType");



--[[
	udp 
	{name = keepworkUsername, projectId = 900, version = 1001, editMode = true/false}
--]]
LobbyMessageType.REQUEST_ECHO			= 1;  

--[[
	udp
	{port = 8099, name = keepworkUsername}
]]
LobbyMessageType.RESPONSE_ECHO			= 2;

--[[
	tcp
	{name = keepworkUsername, nickname = nickname}
]]
LobbyMessageType.REQUEST_CONNECT		= 3;
--[[
	tcp
	{name = keepworkUsername, nickname = nickname}
]]
LobbyMessageType.RESPONSE_CONNECT		= 4;

--[[
	tcp
	{title = "custom title", data = anytype}
]]
LobbyMessageType.USER_DATA				= 5;
--[[
	udp
]]
LobbyMessageType.CUSTOM					= 6;


local LobbyServer = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Network.LobbyServer"));

LobbyServer:Signal("handleMessage");
LobbyServer:Signal("started");

local s_search_time = 5 * 1000;
local callbacks = {};

function LobbyServer.InitCallback()
	callbacks[LobbyMessageType.REQUEST_ECHO] = LobbyServer.onRequestEcho;
	callbacks[LobbyMessageType.RESPONSE_ECHO] = LobbyServer.onResponseEcho;
	callbacks[LobbyMessageType.REQUEST_CONNECT] = LobbyServer.onRequestConnect;
	callbacks[LobbyMessageType.RESPONSE_CONNECT] = LobbyServer.onResponseConnect;
	callbacks[LobbyMessageType.USER_DATA] = LobbyServer.onUserData;
	callbacks[LobbyMessageType.CUSTOM] = LobbyServer.onCustom;
end

local g_instance;
function LobbyServer.GetSingleton()
	if(g_instance) then
		return g_instance;
	else
		LobbyServer.InitCallback();
		g_instance = LobbyServer:new();
		return g_instance;
	end
end


function LobbyServer:ctor()
	if bTest then
		NPL.AddPublicFile("script/apps/Aries/Creator/Game/Network/LobbyService/LobbyServer.lua", 301);
	end
	
	self.m_discoveryTimer = nil;
	self._clients = {};
	self._ExternalIPList = nil;
	self._bStart = false;
end

function LobbyServer:IsStarted()
	return self._bStart;
end

function LobbyServer:Start()
	if self._bStart then
		return
	end

	do
		local att = NPL.GetAttributeObject();
		local ipList = att:GetField("ExternalIPList");
		ipList = commonlib.split(ipList, ",");
		self._ExternalIPList = ipList;
	end
	
	ParaScene.RegisterEvent("_n_paracraft_lobby", ";_OnLobbyServerNetworkEvent();");
	
	self._bStart = true;
	self:started();
end

function LobbyServer:StopAll()
	if not self._bStart then
		return;
	end
	LOG.std(nil, "info", "LobbyServer", "stopped");
	self:StopDiscovery();
	
	ParaScene.UnregisterEvent("_n_paracraft_lobby");
	
	for keepworkUsername, v in pairs(self._clients) do
		NPL.reject(v.nid);
	end
	
	self._clients = {};
	
	self._bStart = false;
end



function LobbyServer:StopDiscovery()
	if self.m_discoveryTimer then
		self.m_discoveryTimer:Change();
		self.m_discoveryTimer = nil;
	end
end


function LobbyServer:AutoDiscovery(broadcast_address_list)
	self:StopDiscovery();
	local server_addr_list = {};
	
	if not broadcast_address_list then
		table.insert(server_addr_list, "(gl)*8099:script/apps/Aries/Creator/Game/Network/LobbyService/LobbyServer.lua");
		
		local att = NPL.GetAttributeObject();
		broadcast_address_list = att:GetField("BroadcastAddressList");
		broadcast_address_list = commonlib.split(broadcast_address_list, ",");
	end
	
	for k, v in pairs(broadcast_address_list) do
		table.insert(server_addr_list, string.format("(gl)\\\\%s 8099:script/apps/Aries/Creator/Game/Network/LobbyService/LobbyServer.lua", v));
	end
	
	local data = {type = LobbyMessageType.REQUEST_ECHO
		, name = System.User.keepworkUsername
		, editMode = not GameLogic.IsReadOnly()
		, projectId = WorldCommon.GetWorldTag("kpProjectId")
		, version = GameLogic.options:GetRevision()
		};

	NPL.load("(gl)script/ide/timer.lua");
	local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
		for k, server_addr in pairs(server_addr_list) do
			NPL.activate(server_addr, data, 1, 2, 0);
		end
		timer:Change(s_search_time);
	end})
	
	mytimer:Change(0);
	self.m_discoveryTimer = mytimer;

	LOG.std(nil, "info", "LobbyServer", "auto discovery started with %s", table.concat(broadcast_address_list or {}, ","));
end


-- send message via Lobby server to another Lobby client
-- @param keepworkUsername: keepworkUsername of the target sLobby client. 
-- @param title: msg title
-- @param data: the raw message table {id=packet_id, .. }. 
function LobbyServer:SendTo(keepworkUsername, title, data)
	local client = self._clients[keepworkUsername];
	if not client then
		return;
	end
	
	local user_addr = string.format("(gl)%s:script/apps/Aries/Creator/Game/Network/LobbyService/LobbyServer.lua",  client.nid);
	NPL.activate(user_addr, {type = LobbyMessageType.USER_DATA
		, title = title
		, data = data
		});
end

function LobbyServer:BroadcastMessage(title, data)
	local user_addr;
	local msg = {type = LobbyMessageType.USER_DATA
			, title = title
			, data = data
			};
			
	for k, v in pairs(self._clients) do
		user_addr = string.format("(gl)%s:script/apps/Aries/Creator/Game/Network/LobbyService/LobbyServer.lua",  v.nid);
		NPL.activate(user_addr, msg);
	end
end

function LobbyServer:SendOriginalMessage(addr, msgStr)
	addr = string.format("(gl)%s:script/apps/Aries/Creator/Game/Network/LobbyService/LobbyServer.lua",  addr);
	NPL.activate(addr, "\0" .. msgStr, 1, 2, 0);
end

function LobbyServer:onMsg(msg)
	if not msg.type then
		if msg.isUDP then
			self:handleMessage("__original", msg);
		end

		return 
	end
	
	local cb = callbacks[msg.type];

	if cb then
		cb(self, msg);
	end
end

function LobbyServer:onCustom(msg)
	
end

function LobbyServer:onUserData(msg)
	local nid = msg.nid;
	local keepworkUsername = string.match(nid, "LobbyServer_(%w+)");
	if not keepworkUsername then
		return;
	end
	
	local client = self._clients[keepworkUsername];
	if not client then
		return;
	end
	
	local data = msg.data;
	data.userinfo = client;
	
	self:handleMessage(msg.title or "unname", data);	
end

function LobbyServer:GetClients()
	return self._clients;
end

function LobbyServer:onRequestConnect(msg)
	local keepworkUsername = msg.name;
	
	if not keepworkUsername then
		return;
	end
	
	if self._clients[keepworkUsername] then
		-- already connect
		return;
	end

	local nid = "LobbyServer_" .. keepworkUsername;
	NPL.accept(msg.tid, nid);
	
	self._clients[keepworkUsername] = {nid = nid, nickname = msg.nickname, keepworkUsername = keepworkUsername};
	
	local user_addr = string.format("(gl)%s:script/apps/Aries/Creator/Game/Network/LobbyService/LobbyServer.lua",  nid);
	
	NPL.activate(user_addr, {type = LobbyMessageType.RESPONSE_CONNECT
		, name = System.User.keepworkUsername
		, nickname = System.User.NickName
		});
	
	self:handleMessage("connect", {userinfo = self._clients[keepworkUsername]});	
end

function LobbyServer:onResponseConnect(msg)
	local keepworkUsername = msg.name;
	
	if not keepworkUsername then
		return;
	end
	
	if self._clients[keepworkUsername] then
		-- already connect
		return;
	end
	
	local nid = "LobbyServer_" .. keepworkUsername;
	self._clients[keepworkUsername] = {nid = nid, nickname = msg.nickname, keepworkUsername = keepworkUsername};
	
	self:handleMessage("connect", {userinfo = self._clients[keepworkUsername]});
end

function LobbyServer:onResponseEcho(msg)
	
	local keepworkUsername = msg.name;
	
	if not keepworkUsername then
		return;
	end
	
	if self._clients[keepworkUsername] then
		-- already connect
		return;
	end
	
	local user_id = msg.tid or msg.nid;
	local ip, _ = string.match(user_id, "~udp(%d+.%d+.%d+.%d+)_(%d+)");
	local port = msg.port;
	
	local nid = "LobbyServer_" .. keepworkUsername;
	NPL.AddNPLRuntimeAddress({host = ip, port = tostring(port), nid = nid});
	local user_addr = string.format("(gl)%s:script/apps/Aries/Creator/Game/Network/LobbyService/LobbyServer.lua",  nid);
	
	NPL.activate(user_addr, {type = LobbyMessageType.REQUEST_CONNECT, name = System.User.keepworkUsername, nickname = System.User.NickName});
end

function LobbyServer:onRequestEcho(msg)
	if (not msg.name or msg.name == System.User.keepworkUsername)  
		or (not msg.projectId or msg.projectId ~= WorldCommon.GetWorldTag("kpProjectId")) 
		or ((msg.version ~= GameLogic.options:GetRevision()) and not (msg.editMode and not GameLogic.IsReadOnly()))then
		return;
	end

	if self._clients[msg.name] then
		return 
	end

	local att = NPL.GetAttributeObject();
	local port = tonumber(att:GetField("HostPort"));
	local user_id = msg.tid or msg.nid;
	local user_addr = string.format("(gl)%s:script/apps/Aries/Creator/Game/Network/LobbyService/LobbyServer.lua",  user_id);
	
	NPL.activate(user_addr, {type = LobbyMessageType.RESPONSE_ECHO, port = port, name = System.User.keepworkUsername}, 1, 2, 0);
end

function LobbyServer:onDisconnected(nid)
	if not nid then
		return;
	end
	
	local keepworkUsername = string.match(nid, "LobbyServer_(%w+)");
	
	if not keepworkUsername then
		return;
	end
	
	if self._clients[keepworkUsername] then
		self:handleMessage("disconnect", {userinfo = self._clients[keepworkUsername]});
		self._clients[keepworkUsername] = nil;
	end
end

function LobbyServer:onNetworkEvent(msg)
	if msg.code == NPLReturnCode.NPL_ConnectionDisconnected then
		self:onDisconnected(msg.nid)
	end
end

function _OnLobbyServerNetworkEvent()
	local LobbyServer = commonlib.gettable("MyCompany.Aries.Game.Network.LobbyServer");
	LobbyServer.GetSingleton():onNetworkEvent(msg);
end

local function activate()
	local msg = msg;
	if g_instance and g_instance._bStart then
		g_instance:onMsg(msg);
	end
end
NPL.this(activate);