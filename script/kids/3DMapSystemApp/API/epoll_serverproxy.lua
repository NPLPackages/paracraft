--[[
Title: epolling style server proxy for client communicating with REST server. 
Author(s): LiXizhi
Date: 2009/1/1
Desc: Event polling implements a messaging pattern that the client only send another packet when server replies or server times out. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/epoll_serverproxy.lua");
local proxy = paraworld.epoll_serverproxy:new({
	KeepAliveInterval = 5000,
	ServerTimeOut = 20000,
});

-- call this, to force to read state, initially it is none state 
proxy:MakeReady();

proxy:Call(paraworld.lobby.GetBBS, msg, "GetBBSChatMessages", function(msg)
	if(msg) then
		proxy:OnRespond();
	end
end)

-- in a timer function, we usually do following
if(proxy:CanSendUpdate()) then
end

-- some other state check functions are
if((proxy:IsReady() and proxy:IsKeepAlive()) or proxy:IsTimeOut()) then
	-- send again
end
------------------------------------------------------------
]]

if(not paraworld) then paraworld = {} end

-- proxy status
local proxystate = {
	-- proxy is reset
	none = nil,
	-- waiting for server response
	waiting = 1,
	-- server already responded, the client can send message at anytime
	ready = 2,
}

------------------------------------
-- a server proxy is used by client to communicate with a epoll server. 
------------------------------------
local epoll_serverproxy = {
	-- nil means we are ready to send a packet.
	state = proxystate.none,
	-- the last time the client sends message to a server proxy, this is measured by the local clock.  
	LastSendTime,
	-- the last time the client receives message from the server, this is measured by the local clock. 
	LastReceiveTime,
	-- default server timeout time
	-- usually if the server is not responding in 20 seconds, we will report to user about connecion lost or unsuccessful. 
	ServerTimeOut = 20000,
	-- default keep alive interval
	KeepAliveInterval = 5000,
}

paraworld.epoll_serverproxy = epoll_serverproxy;

function epoll_serverproxy:new (o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end

-- it will send CS_Logout if old connection contains cookies
function epoll_serverproxy:Reset()
	-- reset cookis and state
	self.state = proxystate.none;
	self.LastSendTime = nil;
	self.LastReceiveTime = nil;
	self.cookies = nil;
	self.SignedIn = nil;
end

-- send a message to server using this proxy. 
-- once the epoll returns successfully, one needs to call self:OnRespond();
-- @param func: make a polling call to a function 
function epoll_serverproxy:Call(func, ...)
	-- make the proxy waiting for reply
	self.state = proxystate.waiting;
	self.LastSendTime = ParaGlobal.GetGameTime();
	func(...);
end

-- call this function whenever the proxy has a response from the server. 
-- it makes the proxy ready to send another message. 
function epoll_serverproxy:OnRespond()
	self.LastReceiveTime = ParaGlobal.GetGameTime();
	self.state = proxystate.ready;
end

-- whether the proxy is in ready state
-- ready state means that the proxy is connected and not waiting for response. 
function epoll_serverproxy:IsReady()
	return self.state == proxystate.ready;
end

-- force the proxy to ready state
function epoll_serverproxy:MakeReady()
	self.state = proxystate.ready;
end

-- manually set the last sent time relative to the current time, this is usually a negative value to emulated a recently sent packet. 
-- please note, normally self.LastSendTime is automatically set to current time when self:Call() is called. 
-- only call this function when wants to achieve special effect like an immediate KeepAlive 
-- e.g. proxy:OffsetLastSendTime(100-proxy.KeepAliveInterval) -- this will force IsKeepAlive to be true after 100 millseconds.
-- @param deltaTime: negative in milliseconds. the last sent time is set to current time plus this delta time. 
function epoll_serverproxy:OffsetLastSendTime(deltaTime)
	if(self.LastSendTime) then
		self.LastSendTime = ParaGlobal.GetGameTime() + deltaTime;
	end
end

-- whether deltaTime is passed since the last time that we send message to server.
-- if return true, we usually need to send a normal update to server to keep the client alive. 
-- @param deltaTime: in milliseconds. If nil, self.KeepAliveInterval is used. 
function epoll_serverproxy:IsKeepAlive(deltaTime)
	if(self.LastSendTime) then
		local timeElapsed = ParaGlobal.GetGameTime()-self.LastSendTime
		if(timeElapsed>(deltaTime or self.KeepAliveInterval)) then
			return true;
		end
	end
end

-- this function will return true, if the server is ready and should send keep alive message or never sent message before or server is timed out. 
function epoll_serverproxy:CanSendUpdate()
	return ( (self:IsReady() and self:IsKeepAlive()) or self:IsTimeOut() or not self.LastSendTime)
end

-- return true if we are not receiving server response for too long
function epoll_serverproxy:IsTimeOut()
	if( self.LastSendTime ) then 
		local timeElapsed = ParaGlobal.GetGameTime()-self.LastSendTime;
		if(timeElapsed > self.ServerTimeOut) then
			-- report server time out. 
			return true;
		end
	end	
end