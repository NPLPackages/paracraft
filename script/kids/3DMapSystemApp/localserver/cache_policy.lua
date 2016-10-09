--[[
Title: cache policy
Author(s): LiXizhi
Date: 2008/3/2
Desc: 
In NPL local server, there is a single cache policy which is slight different from standard HTTP cache 
(The official version is here: http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.9)

---++ NPL local server caching policy
 The cache policy by NPL local server (and represented by this CachePolicy class) is stated below:
   * find the entry in the local server. If a completed entry is found, it is always returned immediately, regardless of whether it has expired or not. 
   * if no entry is found or the entry expired, a new entry will be fetched via remote server and updated in the local server. 
   * When a entry is updated in the store, it will be returned to all callback functions registered to it. 
__Note1__: It means that the same request might be returned twice. The first time is the local version at the time of call; and the second time is when the entry is just updated via the server. 
The second call is skipped if the server can verify that the content has not changed and only update the last access time in the local store. 
__Note2__: If the relative expire time is 0, the first call is ignored. 
__Note3__: If the relative expire time is larger than a year, the second call is always ignored. 
__Note4__: This same policy applies to ResourceStore, ManagedResourceStore, and WebserviceStore.For WebserviceStore, only access base time type is permitted. The server policy can be overwritten by local server policy, local server policy can be overwritten by per function policy

To increase efficiency, one can create several different cache policy objects and share them for all local stores and related function calls. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/cache_policy.lua");
local cache_policy = Map3DSystem.localserver.CachePolicy:new("access plus 1 month");
cache_policy:IsExpired(ParaGlobal.GetSysDateTime()-80000);

-- there are some premade policies, which can be retrieve from Map3DSystem.localserver.CachePolicies, see below
local cp = Map3DSystem.localserver.CachePolicies["never"];
local cp = Map3DSystem.localserver.CachePolicies["always"];
local cp = Map3DSystem.localserver.CachePolicies["1 hour"];
local cp = Map3DSystem.localserver.CachePolicies["1 day"];
-------------------------------------------------------
]]

--------------------------
-- CachePolicy class
--------------------------

local CachePolicy = {
	-- The base time is either the last modification time of the file, or the time of the client's access to the document.
	-- 0 means that the file's last modification time should be used as the base time, 
	-- 1 means the client's access time should be used.
	-- nil Expiration is not enabled. 
	BaseTime = 1,
	-- Time in seconds to expire relative to BaseTime. e.g. 2592000 is a month, which is good for asset and images.  604800 is a week which is good for profile and content pages. 
	ExpireTime = 604800,
};

commonlib.setfield("Map3DSystem.localserver.CachePolicy", CachePolicy);

-- create the object and init from initCode. 
-- format of initCode, please see Init() function. 
function CachePolicy:new(initCode)
	local o = {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	if(initCode) then
		o:Init(initCode);
	end
	return o
end

--[[ Extacts the policy base time type expire time from an input string. 
@param initCode: string: it has the following syntax
"<base> [plus] {<num> <type>}*"
where <base> is one of: access, now (equivalent to 'access'), modification 
The plus keyword is optional <num> should be an integer value, and <type> is one of: years months weeks days hours minutes seconds 
For example, any of the following can be used to make entries expire 1 month after being accessed:
	- "access plus 1 month"
	- "access plus 4 weeks"
	- "access plus 30 days" 
The expiry time can be fine-tuned by adding several '<num> <type>' clauses:
	- "access plus 1 month 15 days 2 hours"
	- "modification plus 5 hours 3 minutes" 
@return: Returns true if successful. 
]]
function CachePolicy:Init(initCode)
	if(type(initCode) ~= "string") then return end
	
	local _, scheme, host, port, nextpart;
	
	-- extract scheme
	local _, _, basePart, expirePart = string.find(initCode, "^(%S+)%s[%S]*(.*)$");
	if (basePart) then
		if(basePart == "access" or basePart == "now"  or basePart == "a") then
			self.BaseTime = 1;
		elseif(basePart == "modification" or basePart == "m") then
			self.BaseTime = 0;
		end
	end
	
	if (expirePart) then
		self.ExpireTime = 0;
		local num, type
		for num, type in string.gfind(expirePart, "(%d+)%s*(s?[^s%A]*)s?%s*") do
			num = tonumber(num);
			if(type == "minute") then
				self.ExpireTime = self.ExpireTime + 60*num;
			elseif(type == "hour") then
				self.ExpireTime = self.ExpireTime + 3600*num;
			elseif(type == "day") then
				self.ExpireTime = self.ExpireTime + 86400*num;
			elseif(type == "week") then
				self.ExpireTime = self.ExpireTime + 604800*num;
			elseif(type == "month") then
				self.ExpireTime = self.ExpireTime + 2592000*num;
			elseif(type == "year") then
				self.ExpireTime = self.ExpireTime + 31104000*num;
			else -- if(type == "second") then
				self.ExpireTime = self.ExpireTime + num;
			end
		end
	end
end

-- whether time is expired.
-- @param Basetime: the base time in second
-- @return: true if input time is expired
function CachePolicy:IsExpired(Basetime)
	if(self.ExpireTime == 0) then
		return true;
	end
	return ((Basetime+self.ExpireTime)<ParaGlobal.GetSysDateTime())
end

-- @return whether cache is enabled. i.e. self.ExpireTime is not 0. 
function CachePolicy:IsCacheEnabled()
	return (self.ExpireTime ~= 0)
end

-- @return whether cache is always used. i.e. self.ExpireTime over 1 year. 
function CachePolicy:IsCacheAlwaysUsed()
	return (self.ExpireTime >= 47959200)
end

--------------------------
-- static cache instances: common used cache policies. 
--------------------------
local CachePolicies = {
	-- never cache
	["never"] = Map3DSystem.localserver.CachePolicy:new("access plus 0"),
	-- common cache policies
	["1 hour"] = Map3DSystem.localserver.CachePolicy:new("access plus 1 hour"),
	["1 day"] = Map3DSystem.localserver.CachePolicy:new("access plus 1 day"),
	["1 month"] = Map3DSystem.localserver.CachePolicy:new("access plus 1 month"),
	["1 week"] = Map3DSystem.localserver.CachePolicy:new("access plus 1 week"),
	-- always from cache
	["always"] = Map3DSystem.localserver.CachePolicy:new("access plus 1 year"),
} 
commonlib.setfield("Map3DSystem.localserver.CachePolicies", CachePolicies);
