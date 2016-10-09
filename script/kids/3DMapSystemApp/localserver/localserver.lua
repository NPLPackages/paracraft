--[[
Title: base class for local server (ResourceStores and ManagedResourceStores)
Author(s): LiXizhi
Date: 2008/2/25
Desc: 
A LocalServer represents a set of entries in the WebCacheDB and allows the set to be managed as a group. The identifying properties of a 
LocalServer are its domain, name, required_cookie, and server_type.
The webcache system supports two types of local servers: ResourceStores and ManagedResourceStores.
Note: use ResourceStores and ManagedResourceStores instead of this base class.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/localserver.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/kids/3DMapSystemApp/localserver/WebCacheDB.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/cache_policy.lua");

local WebCacheDB = Map3DSystem.localserver.WebCacheDB;

-- Represents an item in the store
local Item = {
	-- type of EntryInfo
	entry = nil,
	-- type of EntryPayload
	payload = nil,
}
  
local localserver = {
	-- the web database name. if nil, it will use the default database file at "Database/localserver.db"
	-- otherwise, it will use "Database/[db_name].db"
	db_name,
	-- true
	is_initialized_,
	-- type of SecurityOrigin
	security_origin_,
	-- string: server store name
	name_,
	-- string: 
	required_cookie_,
	-- type of WebCacheDB.ServerType
	server_type_ = WebCacheDB.ServerType.RESOURCE_STORE,
	-- service id in database
	server_id_,
	-- boolean
	store_might_exist_ = true,
	-- Represents an item in the store
	Item = Item,
	-- default policy
	Cache_policy = Map3DSystem.localserver.CachePolicy:new("access plus 1 hour"),
};
commonlib.setfield("Map3DSystem.localserver.localserver", localserver);

function localserver:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end

----------------------------------
-- public member and static functions: 
----------------------------------

-- Returns if the database has a response for the url at this time
function localserver.CanServeLocally(url)
	local web_db = WebCacheDB.GetDB();
	return web_db:CanService(url)
end

-- get the database instance 
function localserver:GetDB()
	self.web_db = self.web_db or WebCacheDB.GetDB(self.db_name);
	return self.web_db;
end

-- Removes the server from the DB, deleting all related rows from
-- the Servers, Versions, Entries, and Payloads tables
function localserver:Remove()
	assert(self.is_initialized_);
	local web_db = self:GetDB();
	return web_db:DeleteServer(self.server_id_)
end

-- Returns true if our server_id_ still exists in the DB.
function localserver:StillExistsInDB() 
	assert(self.is_initialized_);
    
	-- This is an optimization to avoid hitting the database.
	-- Once a store is removed, it can never come back with the same server id,
	-- so we cache this value and if it goes to false we don't hit the db on subsequent calls.
	if (self.store_might_exist_)  then 
		self.store_might_exist_ = self:GetServer();
	end
    return self.store_might_exist_;
end

-- Returns the SecurityOrigin that was passed into Init
function localserver:GetSecurityOrigin() 
    assert(self.is_initialized_);
    return self.security_origin_;
end

-- Returns the name passed into Init
function localserver:GetName() 
	assert(self.is_initialized_);
	return self.name_;
end

-- Returns the required_cookie passed into Init
function localserver:GetRequiredCookie() 
	assert(self.is_initialized_);
	return self.required_cookie_;
end

-- Returns true if local serving of entries in this LocalServer is enabled
function localserver:IsEnabled()
	local server = self:GetServer();
	if(server) then
		return server.enabled
	end
end

-- Enable or disable local serving of entries in this LocalServer. Returns
-- true if successfully modifies the setting.
function localserver:SetEnabled(enabled)
	assert(self.is_initialized_);
	local web_db = self:GetDB();
	return web_db:UpdateServer(self.server_id_, enabled)
end

-- Create/get the data directory path of this server. 
-- @return: the dir is returned. it ends with "/". 
function localserver:GetDataDir()
	if(not self.dataDir_) then
		assert(self.is_initialized_);
		local web_db = self:GetDB();
		self.dataDir_ = web_db:CreateDirectoryForServer(self.server_id_)
	end	
	return self.dataDir_;
end

-------------------------------------
-- protected functions: 
-------------------------------------
-- static function: if the server exists in the DB
-- @return server_id or nil if not found. 
function localserver:ExistsInDB(security_origin,name,required_cookie, serverType) 
	if(not name or not required_cookie) then return  end
	local web_db = self:GetDB();
	local server = web_db:FindServer(nil, nil, security_origin, name, required_cookie, serverType or self.server_type_)
	if(server) then
		return server.id
	end
end

-- get server info from database. 
-- @param server:  nil or a ServerInfo table. 
-- @return: nil or the ServerInfo table is returned. 
function localserver:GetServer(server)
	if(not self.is_initialized_) then 	return false end
	local web_db = self:GetDB();
	return web_db:FindServer(server_id_, server)
end

-- clone from input local_server
function localserver:Clone(local_server) 
	if(not local_server or not local_server.is_initialized_) then return end
	if (local_server.server_type_ ~= self.server_type_) then return end
	self.security_origin_ = commonlib.deepcopy(local_server.security_origin_)
	self.name_ = local_server.name_;
	self.required_cookie_ = local_server.required_cookie_;
	self.server_id_ = local_server.server_id_;
	return true;
end

-- Retrieves from the DB the server info for this instance using dentifier domain/name/required_cookie/serverType.
-- @return ServerInfo returned or nil if not found. 
function localserver:FindServer(security_origin,name,required_cookie, serverType) 
	if(not name or not required_cookie) then return  end
	local web_db = self:GetDB();
	return web_db:FindServer(nil, nil, security_origin, name, required_cookie, serverType or self.server_type_)
end

-- Retrieves from the DB the version info for the desired ready state|version string
-- @param arg1: desired ready state or version string
-- @return VersionInfo or nil if not found. 
function localserver:GetVersion(arg1) 
	assert(self.is_initialized_);
	local web_db = self:GetDB();
	return web_db:FindVersion(self.server_id_, arg1);
end

-- Initializes an instance given it's server_id. Pre: this instance must
-- be uninitialized and the server_id must exist in the DB. Upon return,
-- successful and otherwise, the  is_initialized_ data member will be setto false. 
-- @NOTE: Derived classes must set to true.
function localserver:Open(server_id)
	assert(server_id);
	if (self.is_initialized_) then
		log("warning: trying opening an initialized localserver instance.\n")
		return;
	end
	local web_db = self:GetDB();
	
	local server = web_db:FindServer(server_id);
	if (not server) then
		return;
	end
	if (server.server_type ~= self.server_type_) then
		log("warning: failed opening local server. Server type declared is different from the one in the database.\n")
		return;
	end
	self.server_id_ = server.id;
	self.name_ = server.name;
	self.required_cookie_ = server.required_cookie;
	self.security_origin_ = Map3DSystem.localserver.SecurityOrigin:new(server.security_origin_url);
end

-- Initializes an instance and inserts a row in the Servers table of
-- of DB if one is not already present. Pre: this instance must be
-- uninitialized.   Upon return, successful and otherwise, the 
-- is_initialized_ data member will be set to false. 
-- @NOTE: Derived classes must set to true.
function localserver:CreateOrOpen(security_origin, name, required_cookie) 
	if(not name or not required_cookie) then
		log("error: failed CreateOrOpen local server. Local server name and cookies can not be nil\n")
		return;
	end
	if (self.is_initialized_) then
		log("warning: trying CreateOrOpen an initialized localserver instance.\n")
		return;
	end
	if(type(security_origin) == "string") then
		security_origin = Map3DSystem.localserver.SecurityOrigin:new(security_origin);
	end
	self.security_origin_ = security_origin;
	self.name_ = name;
	self.required_cookie_ = required_cookie;
	
	local web_db = self:GetDB();
	
	-- We start a transaction here to guard against two threads calling InsertServer with the same ServerInfo.
	web_db:Begin();
	

	local server = web_db:FindServer(nil, nil, security_origin, name, required_cookie, self.server_type_);
	if(not server) then
		-- if no such server, create it in the database. 
		server = web_db.ServerInfo:new();
		server.server_type = self.server_type_;
		server.security_origin_url = self.security_origin_.url;
		server.name = self.name_;
		server.required_cookie = self.required_cookie_;
		server.last_update_check_time = 0;
		
		if (not web_db:InsertServer(server)) then
			server.id = nil
			log("error: failed inserting server info to database.\n")
		end
	end

	self.server_id_ = server.id;
	web_db:End();
	
	return (server.id~=nil)
end