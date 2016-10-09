--[[
Title: ManagedResourceStore : public <localserver>
Author(s): LiXizhi
Date: 2008/2/25
Desc: 
A ManagedResourceStore represents a set of entries in the WebCacheDB and allows the set to be managed as a group. 
The identifying properties of a LocalServer are its domain, name, required_cookie, and server_type.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/ManagedResourceStore .lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/kids/3DMapSystemApp/localserver/localserver.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/capture_task.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/UrlHelper.lua");

local WebCacheDB = Map3DSystem.localserver.WebCacheDB;

------------------------------------------
-- ManagedResourceStore  : public <localserver>
------------------------------------------
local ManagedResourceStore = commonlib.inherit(Map3DSystem.localserver.localserver, {
	-- type of WebCacheDB.ServerType
	server_type_ = WebCacheDB.ServerType.MANAGED_RESOURCE_STORE,

	-- default policy
	Cache_policy = Map3DSystem.localserver.CachePolicy:new("access plus 1 month"),
});

commonlib.setfield("Map3DSystem.localserver.ManagedResourceStore", ManagedResourceStore);

function ManagedResourceStore:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end

----------------------------------
-- public member functions: 
----------------------------------
-- Initializes an instance and inserts rows in the Servers and Versions table of the DB if needed
function ManagedResourceStore:CreateOrOpen(security_origin, name, required_cookie) 
	if (ManagedResourceStore._super.CreateOrOpen(self,security_origin, name, required_cookie)) then
		self.is_initialized_ = true;
	end
	return self.is_initialized_;
end

-- Initializes an instance from its server_id. Will not insert rows into
-- the Servers or Versions table of the DB. If the expected rows are not
-- present in the Servers and Versions table, this method fails and returns false.
function ManagedResourceStore:Open(server_id)
	if (ManagedResourceStore._super.Open(self,server_id)) then
		self.is_initialized_ = true;
	end
	return self.is_initialized_;
end

-- Get the manifest url for this store
-- @param manifest_url: string
-- @return: the manifest url (maybe ""), it returns nil if failed. 
function ManagedResourceStore:GetManifestUrl(manifest_url)
	local server = self:GetServer();
	if (server) then
		return server.manifest_url or "";
	end
end

-- Sets the manifest url for this store
-- @param manifest_url: string
function ManagedResourceStore:SetManifestUrl(manifest_url)
	if(not manifest_url) then return end
	existing_manifest_url = self:GetManifestUrl();
	if (not existing_manifest_url) then
		return;
	end

	if (existing_manifest_url ~= manifest_url) then
		local web_db = self:GetDB();
		if (not web_db:UpdateServer(self.server_id_, manifest_url)) then
			return;
		end
	end
	return true;
end

-- returns if the application has a version in the desired state or a version string. 
-- @param state: it int, it is WebCacheDB.VersionReadyState, if string, it is the version string. 
function ManagedResourceStore:HasVersion(state) 
	if(self:GetVersion(state)) then
		return true;
	end
end

-- Retrieves the update info for this store
-- @param return: status, last_time, manifest_date_header, update_error
function ManagedResourceStore:GetUpdateInfo() 
	local status, last_time, manifest_date_header, update_error;
	local server = self:GetServer();
	if (server) then
		-- If the DB indicates that a task is running, and but the runtime indicates that no task is running, translate the value to UPDATE_FAILED
		if ((server.update_status == WebCacheDB.UpdateStatus.UPDATE_CHECKING or
			 server.update_status == WebCacheDB.UpdateStatus.UPDATE_DOWNLOADING) and
			not Map3DSystem.localserver.IsUpdateTaskForStoreRunning(self.server_id_)) then
		  server.update_status = WebCacheDB.UpdateStatus.UPDATE_FAILED;
		end
		status = server.update_status;
		last_time = server.last_update_check_time;
		manifest_date_header = server.manifest_date_header;
		

		-- There can only be an error message if we are in the failed state
		if (status == WebCacheDB.UpdateStatus.UPDATE_FAILED) then
			update_error = server.last_error_message;
		end
		return status, last_time, manifest_date_header, update_error;
	end
end

-- Sets the update info for this applicaiton
function ManagedResourceStore:SetUpdateInfo(status, last_time, manifest_date_header, update_error) 
	local status, last_time, manifest_date_header, update_error;
	local server = self:GetServer();
	if (server) then
		local web_db = self:GetDB();
		return web_db:UpdateServer(server.id, status, last_time, manifest_date_header, update_error);
	end
end
