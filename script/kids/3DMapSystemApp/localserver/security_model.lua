--[[
Title: URL security model
Author(s): LiXizhi
Date: 2008/2/22
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/security_model.lua");
local secureOrigin = Map3DSystem.localserver.SecurityOrigin:new()
-------------------------------------------------------
]]

NPL.load("(gl)script/kids/3DMapSystemApp/localserver/UrlHelper.lua");

--------------------------
-- SecurityOrigin class
-- Class that represents the origin of a URL. The origin includes the scheme, host, and port.
--------------------------

local SecurityOrigin = {
	-- whether initialized from an URL
	initialized = false,
	-- string:  A url that contains the information representative of the security
	-- origin and nothing more. The path is always empty. The port number is
	-- not included for for the default port case. Eg. http://host:99, http://host
	url="",
	-- string: such as "http", "https", "file", if none is specified, it defaults to http. 
	scheme = "http",
	-- string: such as "www.paraengine.com"
	host,
	-- int: if nil it means the default port for the scheme, such as 80 for http. 
	port,
	-- string: it is tostring(port)
	port_string,
	-- private: string:  The full url the origin was initialized with. This should be removed in future. 
	full_url,
};

commonlib.setfield("Map3DSystem.localserver.SecurityOrigin", SecurityOrigin);

function SecurityOrigin:new(full_url)
	local o = {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	if(full_url) then
		o:InitFromUrl(full_url);
	end
	return o
end

-- Extacts the scheme, host, and port of the 'full_url'.
-- @param full_url: string. 
-- @return: Returns true if successful. Only "file","http", and "https" urls are supported. In the case of a file url, the host will be set to kUnknownDomain.
function SecurityOrigin:InitFromUrl(full_url)
	-- to lower case
	full_url = string.lower(string.gsub(full_url, "\\", "/"));
	self.full_url = full_url;
	local _, scheme, host, port, nextpart;
	
	-- extract scheme
	_, _, scheme, nextpart = string.find(full_url, "([%w]*)://(.*)$")
	if(scheme and nextpart) then
		full_url = nextpart;
		self.scheme = scheme;
	else
		self.scheme = "http";
	end
	
	-- extract host(domain name) and port
	_, _, self.host,port = string.find(full_url, "([^/:]*):(%d+).*$")
	if(port) then
		port = tonumber(port);
		-- only set port if not default mapping. 
		if(not Map3DSystem.localserver.UrlHelper.IsDefaultPort(self.scheme, port)) then
			self.port = port;
			self.port_string = tostring(port);
		else	
			self.port = nil;
			self.port_string = nil;
		end
	else
		_, _, self.host = string.find(full_url, "([^/:]*).*$")
		self.port = nil;
		self.port_string = nil;
	end
	self.url = self.scheme.."://";
	if(self.host) then
		self.url = self.url..self.host;
	end
	if(self.port) then
		self.url = self.url..":"..self.port;
	end
end

-- @param other: another instance of SecurityOrigin or the full url string of another security origin
-- @return: true if 'other' and 'this' represent the same origin. If either origin is not initalized, returns false. 
function SecurityOrigin:IsSameOrigin(other)
	if(type(other) == "string") then
		other = SecurityOrigin:new(other);
	end
	if(type(other) == "table") then
		return self.initialized and other.initialized and (self.port == other.port) and
			   (self.scheme == other.scheme) and (self.host == other.host);
	end
end