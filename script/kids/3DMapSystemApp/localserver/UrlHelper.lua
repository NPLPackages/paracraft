--[[
Title: some utility functions for making URLs
Author(s): LiXizhi
Date: 2008/2/22
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/UrlHelper.lua");
Map3DSystem.localserver.UrlHelper.WS_to_REST("www.paraengine.com/getPos.asmx", {uid=123, pos = {x=1, y=2}}, {"uid", "pos.x", "pos.y"});
Map3DSystem.localserver.UrlHelper.BuildURLQuery("profile.html", {uid=123, show=true});
Map3DSystem.localserver.UrlHelper.IsDefaultPort("http", 80)
-------------------------------------------------------
]]

NPL.load("(gl)script/kids/3DMapSystemApp/localserver/http_constants.lua");

local UrlHelper = commonlib.gettable("Map3DSystem.localserver.UrlHelper");

-- converting a web service request to a REST-like url. (REST stands for RESTFUL web)
-- @param wsUrl: web service url, e.g. "www.paraengine.com/getPos.asmx"
-- @param msg: the input msg table of the web service. e.g. {uid=123, pos = {x=1, y=2}}
-- @param fields: an array of text fields in msg. it may contain dot for depth child names. e.g. {"uid", "pos.x", "pos.y"}
-- @return: a unique url is returned, encoding all web service input to a REST url. 
-- in the above case, it is "www.paraengine.com/getPos.asmx?uid=123&pos.x=1&pos.y=2"
function UrlHelper.WS_to_REST(wsUrl, msg, fields)
	local url;
	if(msg and fields) then
		local _, name, value;
		for _, name in ipairs(fields) do
			value = commonlib.getfield(name, msg);
			if(value~=nil) then
				if(not url) then
					url = string.format("?%s=%s", name, tostring(value));
				else
					url = string.format("%s&%s=%s", url, name, tostring(value));
				end
			end	
		end
	end
		
	if(url) then
		return (wsUrl..url);
	else
		return wsUrl;
	end
end

-- Use: NPL.EncodeURLQuery instead if you want encoded url query that can be feed directly to a rest call. 
-- build url query string. should sort in alphabetic order
-- @param baseUrl: base url such as "paraengine.com/index.aspx"
-- @param params: name, value pairs , such as {id=10, time=20}
-- @return: a unique url is returned such as "paraengine.com/index.aspx?id=10&time=20"
function UrlHelper.BuildURLQuery(baseUrl, params)
	local url;
	local name, value;
	for name, value in pairs(params) do
		if(type(value)=="string" or type(value)=="number") then
			if(not url) then
				url = string.format("?%s=%s", name, tostring(value));
			else
				url = string.format("%s&%s=%s", url, name, tostring(value));
			end
		end	
	end
	if(baseUrl) then
		if(url) then
			return baseUrl..url;
		else
			return baseUrl
		end
	else
		return url;
	end	
end

-- return true if the url is for a web service. 
function UrlHelper.IsWebSerivce(url)
	if(url and string.find(url, "%.asmx")) then
		return true
	end
end

-- return true if the url is for a web page request, such as RSS feed, HTML, xml, or http REST call. 
function UrlHelper.IsWebPage(url)
	if(url) then
		if(string.find(url, "%.html?")) then
			return true
		end
		-- TODO: more styles, like .xml, name?params
	end
end

-- return true if the url is for a file request, such as zip, jpg, png, etc 
function UrlHelper.IsFileUrl(url)
	if(url) then
		if(string.find(url, "%.zip") or string.find(url, "%.jpg") or string.find(url, "%.png")) then
			return true
		end
		-- TODO: more styles
	end
end

-- @param scheme: string "http", "https", "file"
-- @param port: int. 80
-- @return true if mapped. 
function UrlHelper.IsDefaultPort(scheme, port) 
	return (Map3DSystem.localserver.HttpConstants.DefaultSchemePortMapping[scheme] == port)
end

-----------------------------------------
-- string utility functions
-----------------------------------------

-- Returns true if and only if the entire string (other than terminating null)
-- consists entirely of characters meeting the following criteria:
-- - visible ASCII
-- - None of the following characters: / \ : * ? " < > | ; ,
-- - Doesn't start with a dot.
-- - Doesn't end with a dot.
function UrlHelper.IsStringValidPathComponent(s)
	if(not s) then return end
	-- an empty string is considered valid, callers depend on this
	if(s == "") then return true end

	-- Does it start with a dot?
	if(string.find(s, "^%.")) then return end

	-- Is every char valid?
	if(string.find(s, "[/\\:%*%?\"<>|;,]")) then return end
  
	-- Does it end with a dot?
	if(string.find(s, "%.$")) then return end
	
	return true
end

-- @return a modified string, replacing characters that are not valid in a file path
-- component with the '_' character. Also replaces leading and trailing dots with the '_' character
-- See IsCharValidInPathComponent
function UrlHelper.EnsureStringValidPathComponent(s) 
	if(s and s~="") then
		-- Does it start with a dot?
		s = string.gsub(s, "^(%.+)", "_")
		-- Is every char valid?
		s = string.gsub(s, "[/\\:%*%?\"<>|;,]+", "_")
		-- Does it end with a dot?
		s = string.gsub(s, "(%.+)$", "_")
	end
	return s;
end

-- UNTESTED: Decode an URL-encoded string
-- (Note that you should only decode a URL string after splitting it; this allows you to correctly process quoted "?" characters in the query string or base part, for instance.) 
function UrlHelper.url_decode(str)
  str = string.gsub (str, "+", " ")
  str = string.gsub (str, "%%(%x%x)",
      function(h) return string.char(tonumber(h,16)) end)
  str = string.gsub (str, "\r\n", "\n")
  return str
end

-- UNTESTED: URL-encode a string
function UrlHelper.url_encode(str)
  if (str) then
    str = string.gsub (str, "\n", "\r\n")
    str = string.gsub (str, "([^%w ])",
        function (c) return string.format ("%%%02X", string.byte(c)) end)
    str = string.gsub (str, " ", "+")
  end
  return str	
end

-- get request url parameter by its name. for example if page url is "www.paraengine.com/user?id=10&time=20", then GetRequestParam("id") will be "10".
-- @param request_url: url to from which to get parameters 
-- @param paramName: parameter name. 
-- @return: nil or string value.
function UrlHelper.url_getparams(request_url, paramName)
	local res;
	if(request_url) then
		request_url = string.gsub(request_url, "^([^%?]*%?)", "");
		local name, value;
		for name, value in string.gfind(request_url, "%s*([^=]+)%s*=%s*([^&]*)&?") do
			value = string.gsub(value, "%s*$", "");
			if(name == paramName) then
				res = value
				break;
			end
		end
	end
	return res;	
end

-- get a table containing all name, value pairs. 
-- @return it may return nil if url does not contain any params. 
function UrlHelper.url_getparams_table(request_url)
	local params;
	local res;
	if(request_url) then
		request_url = string.gsub(request_url, "^([^%?]*%?)", "");
		local name, value;
		for name, value in string.gfind(request_url, "%s*([^=]+)%s*=%s*([^&]*)&?") do
			value = string.gsub(value, "%s*$", "");
			params = params or {};
			params[name] = value
		end
	end
	return params;	
end

-- UNTESTED: Match Email addresses
function UrlHelper.ValidateEmailAddress(email)
	local nFound = string.find(email, "[A-Za-z0-9%.%%%+%-]+@[A-Za-z0-9%.%%%+%-]+%.%w%w%w?%w?")
	return nFound;
end	

