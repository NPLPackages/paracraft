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
		
	elseif( string.match(url,"^p?c?:?/?/?[^%.:]+%.[^%:]+")) then
		self:ParseRemoteServer();
	else
		return;
	end
	if(self:IsValid()) then
		return self;
	end
end

-- private function:
function RemoteUrl:ParseRemoteServer()
	local host, port = string.match(self.url,"^p?c?:?/?/?([^%.:]+%.[^%:]+):?(.*)$");
	if(host and port) then
		port = port:match("^%d+");
		if(port) then
			port = tonumber(port);
		end
		self.host = host;
		self.port = port;
	end
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