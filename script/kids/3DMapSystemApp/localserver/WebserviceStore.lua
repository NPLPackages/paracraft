--[[
Title: WebserviceStore : public <ResourceStore>: public <localserver>
Author(s): LiXizhi
Date: 2008/2/28
Desc: 
A WebserviceStore represents a set of web service response entries in the WebCacheDB and allows the set to be managed as a group. 
The identifying properties of a LocalServer are its domain, name, required_cookie, and server_type.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/WebserviceStore.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/kids/3DMapSystemApp/localserver/ResourceStore.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/capture_task.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/UrlHelper.lua");

local WebCacheDB = Map3DSystem.localserver.WebCacheDB;

------------------------------------------
-- WebserviceStore : public <localserver>
------------------------------------------
local WebserviceStore = commonlib.inherit(Map3DSystem.localserver.ResourceStore, {
	-- type of WebCacheDB.ServerType
	server_type_ = WebCacheDB.ServerType.WEBSERVICE_STORE,
	-- default policy
	Cache_policy = Map3DSystem.localserver.CachePolicy:new("access plus 1 hour"),
	Cache_policy_REST = Map3DSystem.localserver.CachePolicy:new("access plus 1 week"),
});

commonlib.setfield("Map3DSystem.localserver.WebserviceStore", WebserviceStore);

----------------------------------
-- functions: 
----------------------------------
-- call a HTML or other text page from the local server, using a local_cache_policy
-- If there is already a completed HTML pagebefore, we will return the response immediately. And then still proceed to do the update check if expired. 
-- @param Cache_policy: nil or default Cache_policy_REST. (one week time)
-- @param url: url of the HTML page
-- @param callbackFunc: the call back function(entry, callbackContext or url) end, 
--  entry.payload.cached_filepath is name of the file that contains the text returned via HTTP, usually it is xml, html, mcml, etc. so caller can construct an xml tree from it. 
--  Note that the callbackFunc may be called before this function returns since the request may be served locally. 
-- @param callbackContext: this is an optional parameter that is passed to callbackFunc
-- @return return true if it is fetching data or data is already available. it return nil or paraworld.errorcode, if web service can not be called at this time, due to error or too many concurrent calls.
function WebserviceStore:CallRestEx(Cache_policy, url, callbackFunc, callbackContext)
	Cache_policy = Cache_policy or self.Cache_policy_REST;
	return self:GetFile(Cache_policy, url, callbackFunc, callbackContext)
end


-- Same as CallRestEx. the only difference is that callbackFunc(xmlRootNode, entry, callbackContext) contains the xml table, instead of entry object. 
function WebserviceStore:CallXML(Cache_policy, url, callbackFunc, callbackContext)
	return self:CallRestEx(Cache_policy, url, WebserviceStore.CallXML_callback, {callbackFunc = callbackFunc, callbackContext = callbackContext})
end

function WebserviceStore.CallXML_callback(entry, callbackContext)
	local xmlRoot;
	if(entry and entry.payload and entry.payload.cached_filepath) then
		xmlRoot = ParaXML.LuaXML_ParseFile(entry.payload.cached_filepath)
	end
	if(type(callbackContext)=="table" and callbackContext.callbackFunc) then
		callbackContext.callbackFunc(xmlRoot, entry, callbackContext.callbackContext)
	end
end

-- call a web service from the local server, using a local_cache_policy
-- If there is already a completed response before, we will return the response immediately. And then still proceed to do the update check  if expired.  
-- @param Cache_policy: nil or Map3DSystem.localserver.CachePolicy
-- @param url: url of the web service
-- @param msg: an NPL table to be sent. 
-- @param REST_policy: an array of variable names in the msg from which the web service request is converted to a REST style url.
-- a REST style url encodes both the web services url and msg data. see UrlHelper for details. 
-- @param callbackFunc: the call back function(msg, callbackContext or url) end, 
--  Note that the callbackFunc may be called before this function returns since the request may be served locally. 
-- @param callbackContext: this is an optional parameter that is passed to callbackFunc
-- @return return true if it is fetching data or data is already available. 
function WebserviceStore:CallWebserviceEx(Cache_policy, url, msg, REST_policy, callbackFunc, callbackContext) 
	-- get request url from input
	local requestUrl = Map3DSystem.localserver.UrlHelper.WS_to_REST(url, msg, REST_policy);
	if(not requestUrl) then
		log("warning: invalid request url when calling WebserviceStore:CallWebservice:"..url.."\n");
		return 
	end
	
	Cache_policy = Cache_policy or self.Cache_policy;
	
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
		local entry = self:GetItem(requestUrl);
		if(entry) then
			if(type(entry.payload.data) == "string") then
				-- TODO: security check. shall we call NPL.IsSCodePureData(entry.payload.data) here again? 
				-- this is done at insertion time, however the database may be altered after insertion.
				if(callbackFunc) then
					callbackFunc(entry.payload:GetMsgData(), callbackContext or url)
				end	
			else
				if(callbackFunc) then
					callbackFunc(nil, callbackContext or url)
				end
			end
			if(not Cache_policy:IsExpired(entry.payload.creation_date)) then
				commonlib.log("Unexpired local version is used for %s\n", requestUrl)
				return true;
			end
		end
	end
	--
	-- Third, call the web service and save the result to local server database and memory table. 
	--
	-- never retrieve from remote server if ExpireTime is over 1 year.
	if(Cache_policy.ExpireTime < 47959200) then
		-- call the web services and save the result to local server and invoke callback.
		
		local request = Map3DSystem.localserver.TaskManager:new_request(requestUrl)
		if(request) then
			-- add message
			request.msg = msg;
			request.callbackFunc = callbackFunc;
			request.callbackContext = callbackContext;
			--request.OnTaskComplete = nil;
			
			local task = Map3DSystem.localserver.CaptureTask:new(self, request);
			if(task) then
				task:Run();
			end
		else
			log("warning: update ignored, since there is already a same request being processed. \n")
		end
	end	
	return true;
end