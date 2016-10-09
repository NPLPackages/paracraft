--[[
Title: partial implementation of WebCacheDB for security origin permissions
Author(s): LiXizhi
Date: 2008/2/24
Desc: generally, it verifies if an url security origin can be serviced. 
A white url list and a black url list can be edited in this file or added dynamically at runtime. 
Currently, it allows all http request. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/WebCacheDB_permissions.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/kids/3DMapSystemApp/localserver/security_model.lua");

local WebCacheDB = Map3DSystem.localserver.WebCacheDB;

-- url in the white list is always serviced
-- format is identical to regular expression as in string.find. 
local whiteList = {
	-- currently we allow all http urls. 
	"http://",
}

-- url in the black list is always blocked, 
-- format is identical to regular expression as in string.find. see examples below
local blackList = {
	-- "192%.168%.0%.100",
	-- "192.*",
	-- "https://*.",
	-- "http://[^:]:%d+",
	-- "http://[^:]:60001",
}

-- whether the given url's securtiy origin is allowed. 
-- @param securityOrigin: type of Map3DSystem.localserver.SecurityOrigin or an URL string
-- @return boolean
function WebCacheDB:IsOriginAllowed(securityOrigin)
	if(type(securityOrigin) == "string") then
		securityOrigin = Map3DSystem.localserver.SecurityOrigin:new(securityOrigin)
	end
	if(type(securityOrigin) ~= "table") then
		return true; -- if securityOrigin is nil, it is always returned true. 
	end
	
	-- whether the origin is found in the white or black list. 
	local bInWhite, bInBlack;
	local _, v;
	for _, v in ipairs(whiteList) do
		if(string.find(securityOrigin.url, v)) then
			bInWhite = true
			break;
		end
	end
	
	for _, v in ipairs(blackList) do
		if(string.find(securityOrigin.url, v)) then
			bInBlack = true
			break;
		end
	end
	
	return not bInBlack and bInWhite;
end

function WebCacheDB:AddToWhiteList(url)
	-- TODO: add unique: commonlib.AddUniqueArrayItem
end

function WebCacheDB:RemoveFromWhiteList(url)
	-- TODO:
end

function WebCacheDB:AddToBlackList(url)
	-- TODO: add unique: commonlib.AddUniqueArrayItem
end

function WebCacheDB:RemoveFromBlackList(url)
	-- TODO:
end