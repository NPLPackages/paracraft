--[[
Title: http cookies and related helper functions. 
Author(s): LiXizhi
Date: 2008/2/23
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/http_cookies.lua");
local CookieMap = Map3DSystem.localserver.CookieMap:new("www.paraengine.com/get.asmx?name=value&name2=value2")
-------------------------------------------------------
]]

--------------------------
-- SecurityOrigin class
-- Class that represents the origin of a URL. The origin includes the scheme, host, and port.
--------------------------
-- A collection of cookie name and optional value pairs
local CookieMap = {
	-- an table of name to value map
	data = nil,
};
commonlib.setfield("Map3DSystem.localserver.CookieMap", CookieMap);

function CookieMap:new(full_url)
	local o = {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	if(full_url) then
		o:LoadMapForUrl(full_url);
	end
	return o
end

-- Retrieves the cookies for the specified URL and populates the
-- map with an entry for each value. Previous values in the map
-- are cleared prior to loading the new values. If the cookie string
-- cannot be retrieved, returns false and the map is not modified.
-- Ex. Given "name=value;cookie" the map is populated as follows
--     map["name"] = "value";
--     map["cookie"] = "";
-- @param url: string. 
-- @return: Returns true if successful. Only "file","http", and "https" urls are supported. In the case of a file url, the host will be set to kUnknownDomain.
function CookieMap:LoadMapForUrl(url)
	local cookie_string = CookieMap.GetCookieString(url);
	if(cookie_string) then
		-- clear old data
		self.data = {};
		-- fill new data
		local name_and_value
		for name_and_value in string.gfind(cookie_string, "[^&;]+") do
			local name,value = CookieMap.ParseCookieNameAndValue(name_and_value);
			if(name) then
				self.data[name] = value;
			end	
		end
	end
end

-- Returns true if the 'requiredCookie' attribute of a resource store is satisfied by the contents of this CookieMap. 
-- @param required_cookie: string. it can express either a particular cookie name/value pair, or the absence
-- of cookie with a particular name.
-- "foo=bar" --> a cookie name "foo" must have the value "bar"
-- "foo" | "foo=" --> "foo" must be present but have an empty value
-- "foo=;NONE;" --> the collection must not contain a cookie for "foo"
function CookieMap:HasLocalServerRequiredCookie(required_cookie)
	if(required_cookie == nil or required_cookie=="") then
		return true;
	end	
	local name, value = CookieMap.ParseCookieNameAndValue(required_cookie);
	if(name==nil) then
		return false;
	end

	if(value == ";NONE;") then
		return not self:HasCookie(name)
	else
		return self:HasSpecificCookie(name, value)
	end
end

-- Retrieves the value of the cookie named 'cookie_name'. If the cookie
-- is present but does not have a value, the value string will be empty.
-- @return cookie_vale
function CookieMap:GetCookie(cookie_name)
	if(self.data) then
		return self.data[cookie_name];
	end
end

-- @returns true if the map contains a cookie named 'cookie_name'
function CookieMap:HasCookie(cookie_name)
	if(self.data) then
		if(self.data[cookie_name]~=nil) then
			return true;
		end
	end
end

-- @return true if the map contains a cookie with 'cookie_name' having the value 'cookie_value'
function CookieMap:HasSpecificCookie(cookie_name, cookie_value)
	local value = self:GetCookie(cookie_name);
	if(value~=nil) then
		return (cookie_value == nil) or  (cookie_value == "") or (cookie_value == value)
	end
end
--------------------------------------  
-- static public functions: 
--------------------------------------
-- static public function: 
-- Parses a "name=value" string into its the name and value parts.
-- The split occurs at the first occurrence of the '=' character.
-- Both the name and value are trimmed of whitespace. If there is no
-- '=' delimiter, name will be populated with the entire input string,
-- trimmed of whitespace, and value will be an empty string.
-- @return: name, value as strings if succeed.  
function CookieMap.ParseCookieNameAndValue(name_and_value)
	local name, value
	local _, _, name, value = string.find(name_and_value, "([^=]+)=([^=]*)")
	
	if(value==nil) then
		name = string.gsub(name_and_value, "%s", "");
		value = "";
	else
		name = string.gsub(name, "%s", "")
		value = string.gsub(value, "%s", "")
	end
	return name, value
end

-- static public function: 
-- Retrieves the cookies for the specified URL. Cookies are represented as
-- strings of semi-colon or & delimited "name=value" pairs.
-- @return the string after ? separator in the url. it may return nil if no cookie string found
function CookieMap.GetCookieString(url)
	local _,_, cookie_string = string.find(url, "[^%?]%?(.*)$")
	return cookie_string;
end