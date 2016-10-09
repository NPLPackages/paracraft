--[[
Title: creating instances of local servers
Author(s): LiXizhi
Date: 2008/2/27
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/factory.lua");
local store = Map3DSystem.localserver.CreateStore("WebserviceStore_sample", 2)
local store = Map3DSystem.localserver.CreateStore("ResourceStore_sample", 1)
local store = Map3DSystem.localserver.CreateStore("ManagedResourceStore_sample", 0)
-------------------------------------------------------
]]

if(not Map3DSystem) then Map3DSystem = {} end
if(not Map3DSystem.localserver) then Map3DSystem.localserver = {} end

NPL.load("(gl)script/kids/3DMapSystemApp/localserver/cache_policy.lua");

local _Stores = {};
local _Stores_pools = {};
-- create or get a resource store using the default security origin. 
-- @param name: if name is nil, a default name "_default_" will be used for the type of store. In most cases, one should use the default store name
-- @param ServerType: see WebCacheDB.ServerType. If nil or 1, for resource store; 2 for web service store, 3 for URLResource store, 0 for managed resource store. 
-- @param db_name: web database file to use.normally this should be nil, where the default web db at "Database/localserver.db" is used; or it can also be "Database/[db_name].db".
-- return the ResourceStore local server instance. or nil if failed. 
function Map3DSystem.localserver.CreateStore(name, serverType, db_name)
	serverType = serverType or 1;
	if(not name) then name = "_default_"..serverType end
	local serverStore;
	
	-- we cache the result in memory, so that this function can be called repeatedly
	local serverStore = Map3DSystem.localserver.GetStore(name, db_name);
	if(serverStore) then
		return serverStore;
	end
	
	if(serverType == 1) then
		NPL.load("(gl)script/kids/3DMapSystemApp/localserver/ResourceStore.lua");
		
		serverStore = Map3DSystem.localserver.ResourceStore:new({db_name = db_name});
		-- TODO: using origin of the login user's server domain, currently it is just paraengine.com 
		-- TODO: use user info for cookies.  
		if(serverStore:CreateOrOpen("http://paraengine.com", name, "")) then
		end
	elseif(serverType == 2) then
		NPL.load("(gl)script/kids/3DMapSystemApp/localserver/WebserviceStore.lua");
		serverStore = Map3DSystem.localserver.WebserviceStore:new({db_name = db_name});
		if(serverStore:CreateOrOpen("http://paraengine.com", name, "")) then
		end
	elseif(serverType == 3) then
		NPL.load("(gl)script/kids/3DMapSystemApp/localserver/URLResourceStore.lua");
		serverStore = Map3DSystem.localserver.URLResourceStore:new({db_name = db_name});
		if(serverStore:CreateOrOpen("http://paraengine.com", name, "")) then
		end	
	elseif(serverType == 0)	then
		NPL.load("(gl)script/kids/3DMapSystemApp/localserver/ManagedResourceStore.lua");
		serverStore = Map3DSystem.localserver.ManagedResourceStore:new({db_name = db_name});
		if(serverStore:CreateOrOpen("http://paraengine.com", name, "")) then
		end
	end	
	
	if(serverStore and serverStore.is_initialized_) then
		-- add to memory cache, so that the next time the store is returned from the cache. 
		if(db_name == nil) then
			_Stores[name] = serverStore;
		else
			_Stores_pools[db_name] = _Stores_pools[db_name] or {};
			_Stores_pools[db_name][name] = serverStore;
		end	
		return serverStore;
	end	
end

-- get the loaded store. if the store is not loaded,it will return nil. To CreateGet a store, use CreateStore() instead. 
-- @param name: if name is nil, a default name "_default_" will be used for the type of store. In most cases, one should use the default store name
-- @param db_name: web database file to use.normally this should be nil, where the default web db at "Database/localserver.db" is used; or it can also be "Database/[db_name].db".
-- @return: nil if no store is created brefore. 
function Map3DSystem.localserver.GetStore(name, db_name)
	if(db_name == nil) then
		if(_Stores[name]) then
			-- hit memory cache first
			return _Stores[name]
		end	
	else
		_Stores_pools[db_name] = _Stores_pools[db_name] or {};
		return _Stores_pools[db_name][name];
	end	
end

-- force flushing all opened database servers. We usually call this function before closing or restarting the game. 
function Map3DSystem.localserver.FlushAll()
	if(Map3DSystem.localserver.WebCacheDB and Map3DSystem.localserver.WebCacheDB.FlushAll) then
		Map3DSystem.localserver.WebCacheDB.FlushAll();
	end	
end