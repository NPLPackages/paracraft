--[[
Title: Remote Url parser
Author(s): LiXizhi
Date: 2014/7/24
Desc: 
---++ wiki url
http://[anyurl] 
---++ user nid
[nid:number]
---++ disk file
local
---++ remote server
pc://127.0.0.1:8099
127.0.0.1
127.0.0.1:8099

Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/RemoteUrl.lua");
local RemoteUrl = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.RemoteUrl");
local url = RemoteUrl:new():Init("127.0.0.1:8099");
if(url:IsRemoteServer()) then
	echo({url:GetHost(), url:GetPort()})
end
-------------------------------------------------------
]]
local RemoteUrl = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Creator.Game.Login.RemoteUrl"));

function RemoteUrl:ctor()
end

-- @param url
function RemoteUrl:Init(url)
	self.url = url;
		
	if( string.match(url,"^http") ) then
		self.http_url = url;
	elseif( string.match(url,"^%d+$") ) then
		self.nid = tonumber(url);
	elseif( string.match(url,"^local")) then
		self.isLocalDisk = true;
	elseif( string.match(url,"^online")) then

	elseif( string.match(url,"^/")) then
		-- skip commands
	elseif( string.match(url,"^@.+")) then
		self:ParseUserName()
	elseif( string.match(url,"%.")) then
		self:ParseRemoteServer();
	else
		return;
	end
	if(self:IsValid()) then
		return self;
	end
end

function RemoteUrl:ParseUserName()
	self.relativePath = self.url;
	self.host = "t1.tunnel.keepwork.com";
	self.port = 8099
end

-- private function:
function RemoteUrl:ParseRemoteServer()
	self.url_protocol = self.url:match("^(%w+)://");
	local url = self.url:gsub("^%w+://", "");
	local host, port, relativePath = url:match("^([^:%s]+)[:%s]?(%d*)(.*)");

	if(host and port) then
		port = port:match("^%d+");
		if(port) then
			port = tonumber(port);
		end
		self.host = host;
		self.port = port;
		self.relativePath = relativePath
	end
end

function RemoteUrl:GetRelativePath()
	return self.relativePath
end

function RemoteUrl:GetUrlProtocol()
	return self.url_protocol
end

function RemoteUrl:IsValid()
	return true;
end

function RemoteUrl:IsLocalDisk()
	return self.isLocalDisk;
end

function RemoteUrl:IsRemoteServer()
	return self:GetHost() ~= nil;
end

function RemoteUrl:GetUrl()
	return self.url;
end

function RemoteUrl:GetHttpUrl()
	return self.http_url;
end

function RemoteUrl:GetNid()
	return self.nid;
end

function RemoteUrl:GetHost()
	return self.host;
end

function RemoteUrl:GetPort()
	return self.port;
end