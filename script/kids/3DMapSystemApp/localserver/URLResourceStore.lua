--[[
Title: URLResourceStore : public <ResourceStore>
Author(s): LiXizhi
Date: 2008/12/12
Desc: 
A URLResourceStore represents a set of URL response entries in the WebCacheDB and allows the set to be managed as a group. 
The identifying properties of a LocalServer are its domain, name, required_cookie, and server_type.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/URLResourceStore.lua");

local ls = Map3DSystem.localserver.CreateStore(nil, 3);
if(ls) then
	ls:GetURL(Map3DSystem.localserver.CachePolicy:new("access plus 1 week"),
		"http://www.paraengine.com", commonlib.echo, "SecondUserParam"
	);
else
	log("error: unable to open default local server store \n");
end
-------------------------------------------------------
]]

NPL.load("(gl)script/kids/3DMapSystemApp/localserver/ResourceStore.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/capture_task.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/UrlHelper.lua");

local WebCacheDB = Map3DSystem.localserver.WebCacheDB;

------------------------------------------
-- URLResourceStore : public <localserver>
------------------------------------------
local URLResourceStore = commonlib.inherit(Map3DSystem.localserver.ResourceStore, {
	-- type of WebCacheDB.ServerType
	server_type_ = WebCacheDB.ServerType.URLRESOURCE_STORE,
	-- default policy
	Cache_policy = Map3DSystem.localserver.CachePolicy:new("access plus 1 hour"),
	Cache_policy_REST = Map3DSystem.localserver.CachePolicy:new("access plus 1 week"),
});

commonlib.setfield("Map3DSystem.localserver.URLResourceStore", URLResourceStore);

----------------------------------
-- functions: 
----------------------------------
-- http get of a given url from the local server, using a local_cache_policy
-- If there is already a completed HTML page before, we will return the response immediately. And then still proceed to do the update check if expired. 
-- If there is already a completed response before, we will return the response immediately. And then still proceed to do the update check  if expired.  
-- @param Cache_policy: nil or Map3DSystem.localserver.CachePolicy, or string like "access plus 1 week"
-- @param url: url of the web service
-- @param callbackFunc: the call back function(msg, callbackContext or url) end, 
--  where msg = {code, header, data}, the msg.code should be 0 if succeed. msg.header is the http header. msg.data is the response body text. 
--		Note that the callbackFunc may be called before this function returns since the request may be served locally. 
-- @param callbackContext: this is an optional parameter that is passed to callbackFunc
-- @param funcMsgTranslator: if not nil, it translate the input msg={header, code, data} before it is passed to callbackFunc
--     if nil, input is always {header, code, data}. commonly used translators are 
--         paraworld.JsonTranslator
-- @param bUseExpire: if true, the expired version will be returned which may result in callbackFunc() being called twice. 
--	Default to nil, which only returns unexpired version, unless HTTP error occurs and expired local server version may be returned. 
-- @return return true if it is fetching data or data is already available. false if url is already being downloaded by the previous call.
function URLResourceStore:GetURL(Cache_policy, url, callbackFunc, callbackContext, funcMsgTranslator, bUseExpire)
	if(paraworld.OfflineMode) then
		Cache_policy = Map3DSystem.localserver.CachePolicies["always"];
	end
	-- get request url from input
	if(type(Cache_policy) == "string") then
		Cache_policy = Map3DSystem.localserver.CachePolicy:new(Cache_policy);
	else
		Cache_policy = Cache_policy or self.Cache_policy_REST;
	end
	
	--
	-- Whenever a result is ready in the following steps, the function calls the callback and returns 
	--
	
	-- First, check if the url is in a memory table. 
	-- TODO: Currently, this step is not implemented. we will hit the database for each request. 
	
	--
	-- Second, check if the url is in the local server database, if so, save to memory table.
	--
	-- never retrieve from local server if ExpireTime is 0. 
	if(Cache_policy.ExpireTime > 0) then
		local entry = self:GetItem(url);
		if(entry) then
			local bIsExpired = Cache_policy:IsExpired(entry.payload.creation_date);
			if(bUseExpire or not bIsExpired) then
				if(callbackFunc) then
					local msg = {data = entry.payload.data, header=entry.payload.headers, code=0, rcode=200};
					if(funcMsgTranslator) then
						msg = funcMsgTranslator(msg)
					end
					callbackFunc(msg, callbackContext or url)
				end
			end	
			if(not bIsExpired) then
				commonlib.log("Unexpired local version is used for %s\n", url)
				return true;
			end
		end
	end
	--
	-- Third, get the url and save the result to local server database and memory table. 
	--
	-- never retrieve from remote server if ExpireTime is over 1 year.
	if(Cache_policy.ExpireTime < 47959200) then
		local request = Map3DSystem.localserver.TaskManager:new_request(url, 1)
		if(request) then
			-- add message
			request.funcMsgTranslator = funcMsgTranslator;
			request.callbackFunc = callbackFunc;
			request.callbackContext = callbackContext;
			--request.OnTaskComplete = nil;
			
			local task = Map3DSystem.localserver.CaptureTask:new(self, request);
			if(task) then
				task:Run();
			end
		else
			log("warning: update ignored, since there is already a same request being processed. \n")
			return false;
		end
	end	
	return true;
end

