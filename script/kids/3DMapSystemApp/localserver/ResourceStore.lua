--[[
Title: ResourceStore : public <localserver>
Author(s): LiXizhi
Date: 2008/2/25
Desc: 
A ResourceStore represents a set of entries in the WebCacheDB and allows the set to be managed as a group. 
The identifying properties of a LocalServer are its domain, name, required_cookie, and server_type.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/ResourceStore.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/kids/3DMapSystemApp/localserver/localserver.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/capture_task.lua");
local WebCacheDB = commonlib.gettable("Map3DSystem.localserver.WebCacheDB");
local LOG = LOG;
------------------------------------------
-- ResourceStore : public <localserver>
------------------------------------------
local ResourceStore = commonlib.inherit(commonlib.gettable("Map3DSystem.localserver.localserver"), commonlib.gettable("Map3DSystem.localserver.ResourceStore"));

-- type of WebCacheDB.ServerType
ResourceStore.server_type_ = WebCacheDB.ServerType.RESOURCE_STORE;
	
-- int64: The rowid of the version record in the DB associated with this
-- ResourceStore. Each ResourceStore has exactly one related
-- version record. The schema requires that Servers contain Versions
-- contain Entries in order to support the other class of Server, the
-- ManagedResourceStore. To satisfy the schema, this class manages
-- the lifecyle of this record in the version table. When the Server
-- record is inserted and delete, the Version record goes in lock step.
ResourceStore.version_id_ = nil;
-- default policy
ResourceStore.Cache_policy = Map3DSystem.localserver.CachePolicy:new("access plus 1 day");

ResourceStore.DuplicatedMsg = {DownloadState="duplicated_call"};

-- private helper function
function ResourceStore.AppendHeader(headers, name, value) 
	headers = string.format("%s%s: %s\r\n", headers, name, tostring(value))
end

----------------------------------
-- major API functions: 
----------------------------------

-- retrieve all url files using the local server. 
-- @param Cache_policy: nil or Map3DSystem.localserver.CachePolicy
-- @param urls: url string or an array of urls. It will be retrieved one after another.
-- @param callbackFunc: the call back function(entry, callbackContext or url) end will be called for each url in input urls.
-- @param callbackContext: this is an optional parameter that is passed to callbackFunc
--  where the entry is a table of {entry, payload, IsFromCache}. Normally, one can access the disk file 
--  containing the reponse data by entry.payload.cached_filepath
--  and other info by entry.payload:GetHeader(Map3DSystem.localserver.HttpConstants.kXXX);
-- @param callbackProgressFunc: this is an optional function that is called whenever a fraction of a url is downloaded
-- the format is function(msg, callbackContext or url), where msg is {DownloadState=""|"complete"|"terminated"|"duplicated_call", totalFileSize=number, currentFileSize=number, PercentDone=number}
-- @return return true if it is fetching data or data is already available. false if url is already being downloaded by the previous call.
function ResourceStore:GetFile(Cache_policy, urls, callbackFunc, callbackContext, callbackProgressFunc) 
	Cache_policy = Cache_policy or self.Cache_policy;
	
	if (type(urls)=="string") then
		urls = {urls};
	end
	--
	-- First, check if the url is in the local server database, if so, serve immediately from local store
	--
	-- never retrieve from local server if ExpireTime is 0. 
	if(Cache_policy.ExpireTime > 0) then
		local i = 1; 
		local url = urls[i];
		while url do
			local entry = self:GetItem(url);
			if(entry) then
				if(not Cache_policy:IsExpired(entry.payload.creation_date)) then
					commonlib.removeArrayItem(urls, i);
					log("Unexpired local version is used for "..url.."\n")

					if(callbackFunc) then
						entry.IsFromCache = true;
						callbackFunc(entry, callbackContext)
					end
				else
					i=i+1;
				end
			else
				i=i+1;
			end
			url = urls[i];
		end	
		if(table.getn(urls)==0) then
			return true;
		end
	end
	
	--
	-- Second, download and save the result to local server database
	--
	-- never retrieve from remote server if ExpireTime is over 1 year.
	if(Cache_policy.ExpireTime < 47959200) then
		-- download and save the result to local server and invoke callback.
		local request = Map3DSystem.localserver.TaskManager:new_request(urls)
		if(request) then
			-- add message
			request.callbackFunc = callbackFunc;
			request.callbackContext = callbackContext;
			request.callbackProgressFunc = callbackProgressFunc;
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

----------------------------------
-- member functions: 
----------------------------------
-- Initializes an instance and inserts rows in the Servers and Versions table of the DB if needed
-- @return true if succeed or nil if failed. 
function ResourceStore:CreateOrOpen(security_origin, name, required_cookie) 
	local web_db = self:GetDB();
	
	-- We start a transaction here to guard against two threads calling InsertServer with the same ServerInfo.
	web_db:Begin(nil, "deferred");

	if (not Map3DSystem.localserver.localserver.CreateOrOpen(self, security_origin, name, required_cookie)) then
		web_db:End(true);
		return;
	end

	-- We set is_initialized_ here so GetVersion will function for us
	self.is_initialized_ = true;
	
	local version = self:GetVersion(WebCacheDB.VersionReadyState.VERSION_CURRENT);
	if (not version) then
		version = WebCacheDB.VersionInfo:new();
		version.ready_state = WebCacheDB.VersionReadyState.VERSION_CURRENT;
		version.server_id = self.server_id_;
		if (not web_db:InsertVersion(version)) then
			self.is_initialized_ = false;  -- have to reset, initialization has failed
			web_db:End(true);
			return;
		end
	end
	self.version_id_ = version.id;

	-- tricky here, we will flush immediately.
	web_db:End(nil, true); 

	self.is_initialized_ = true
	
	return self.is_initialized_;
end

-- Initializes an instance from its server_id. Will not insert rows into
-- the Servers or Versions table of the DB. If the expected rows are not
-- present in the Servers and Versions table, this method fails and returns false.
-- @return nil if failed. true if succeed. 
function ResourceStore:Open(server_id)
	if (not Map3DSystem.localserver.localserver.Open(self, server_id)) then
		return;
	end
	self.is_initialized_ = true;
	local version = self:GetVersion(WebCacheDB.VersionReadyState.VERSION_CURRENT);
	if (not version) then
		self.is_initialized_ = false;  -- have to reset, initialization has failed
		return false;
	end
	self.version_id_ = version.id;
	return true;
end

-- Gets an item from the store including or not the response body
-- @param info_only: If info_only is true, the response body of it is not retrieved.
-- @return the localserver.Item {entry, payload}is returned or nil if not found. 
function ResourceStore:GetItem(url, info_only)
	if(not url) then return end
	
	if (not self.is_initialized_) then
		log("warning: localserver instance uninitialized.\n")
		return;
	end

	if(self.is_memory_mode) then
		local mem_db = self:GetMemDB();
		-- LOG.std("", "debug","localserver",{"DBGetURL", url})
		return mem_db[url];
	end

	local web_db = self:GetDB();

	local entry = web_db:FindEntry(self.version_id_, url);
	if (not entry) then
		return
	end

	-- All entries in a ResourceStore are expected to have a payload
	if(entry.payload_id == nil or entry.payload_id == 0) then
		log("warning: ResourceStore item "..url.." are expected to have a payload. But it does not.\n")
		return
	end

	local payload = web_db:FindPayload(entry.payload_id, info_only)
	
	-- TODO: lxz 2008.2.27 shall we cache a copy of this table in memory?
	return {entry = entry, payload=payload}
end

-- Gets an item from the store without retrieving the response body
function ResourceStore:GetItemInfo(url)
    return self:GetItem(url, true)
end

-- all following read/write queries are made in-memory
function ResourceStore:SetMemoryMode(bEnable)
	if(bEnable) then
		LOG.std("", "system", "localserver", "localserver: %s enters memory mode", tostring(self.db_name))
	end
	self.is_memory_mode = bEnable;
end

-- create get the mem db. 
function ResourceStore:GetMemDB()
	local mem_db = self.mem_db;
	if(mem_db) then
		return mem_db;
	else
		mem_db = {};
		self.mem_db = mem_db;
		return mem_db;
	end
end
-- Puts an item in the store. If an item already exists for this url, it is overwritten.
-- @param the localserver.Item {entry, payload}
-- @param bForceFlush: default to nil, if true, it will be flushed to database immediately. 
-- @return true if succeed
function ResourceStore:PutItem(item, bForceFlush) 
	if (not item or not self.is_initialized_) then
		log("warning: localserver instance uninitialized.\n")
		return;
	end
	if(self.is_memory_mode) then
		local mem_db = self:GetMemDB();
		LOG.std("", "debug","localserver",{"ResourceStore:PutItem memory mode", item.entry.url})
		item.payload.creation_date= ParaGlobal.GetSysDateTime();
		mem_db[item.entry.url] = item;
		return true;
	end

	local web_db = self:GetDB();
	
	web_db:Begin("ResourceStore:PutItem")

	if (not self:StillExistsInDB()) then
		log("warning: server no longer in db when ResourceStore:PutItem\n")
		web_db:End(true)
		return;
	end

	web_db:DeleteEntry2(self.version_id_, item.entry.url);

	if (not web_db:InsertPayload(self.server_id_, item.entry.url, item.payload)) then
		log("warning: insert payload failed. when ResourceStore:PutItem\n")
		web_db:End(true)
		return;
	end

	item.entry.version_id = self.version_id_;
	item.entry.payload_id = item.payload.id;
	if (not web_db:InsertEntry(item.entry)) then
		log("warning: insert InsertEntry failed. when ResourceStore:PutItem\n")
		web_db:End(true)
		return;
	end
	
	web_db:End(nil, bForceFlush);
	return true;
end

-- Deletes all items in the store.
-- @return: return true if succeed
function ResourceStore:DeleteAll() 
	if (not self.is_initialized_) then return end
	local web_db = self:GetDB();
	local succeed = web_db:DeleteEntries(self.version_id_);
	web_db:DeleteDirectoryForServer(self.server_id_)
	return succeed
end

-- Deletes a single item in the store.
-- @return: return true if succeed
function ResourceStore:Delete(url) 
	if (not url or not self.is_initialized_) then return end

	local web_db = self:GetDB();
	return web_db:DeleteEntry2(self.version_id_, url);
end

-- Renames an item in  the store. If an item already exists for new_url, the pre-existing item is deleted.
-- @return: return true if succeed
function ResourceStore:Rename(orig_url, new_url) 
	if( not orig_url or not new_url or not self.is_initialized_) then return end
	
	local web_db = self:GetDB();
	web_db:Begin("ResourceStore:Rename")

	if (not self:IsCaptured(orig_url)) then
		log("warning: trying to rename an orig_url "..orig_url.." that is not captured.\n")
		web_db:End();
		return
	end

	-- Delete any pre-existing entry stored under the new_url
	-- Note: delete does not fail is there is no entry for new_url
	if (not web_db:DeleteEntry2(self.version_id_, new_url)) then
		log("warning: calling delete new_url failed in Rename.\n")
		web_db:End();
		return
	end

	if (not web_db:UpdateEntry(self.version_id_, orig_url, new_url)) then
		log("warning: can not update an url during Rename. \n")
		web_db:End();
		return
	end

	web_db:End();
	return true;
end

-- Copies an item in  the store. If an item already exists for dst_url, the pre-existing item is deleted.
function ResourceStore:Copy(src_url, dst_url)
	if(not src_url or not dst_url or not self.is_initialized_) then return end
  
	local web_db = self:GetDB();
	web_db:Begin("ResourceStore:Copy")

	local item = self:GetItemInfo(src_url);
	if (not item) then
		web_db:End();
		return
	end

	-- Delete any pre-existing entry stored under the dst_url
	-- Note: delete does not fail is there is no entry for dst_url
	if (not web_db:DeleteEntry(self.version_id_, dst_url)) then
		web_db:End();
		return
	end

	-- Insert a new entry for dst_url that references the same payload
	item.entry.id = nil;
	item.entry.url = dst_url;
	item.entry.version_id = self.version_id_;
	if (not web_db:InsertEntry(item.entry)) then
		web_db:End();
		return
	end

	web_db:End();
	return true;
end

-- Returns true if an item is captured for url.
function ResourceStore:IsCaptured(url)
	return self:GetItemInfo(url);
end

-- Returns the filename of a captured local file.
-- return nil if failed, return empty string if not found.
function ResourceStore:GetCapturedFileName(url)
	local item = self:GetItemInfo(url);
	if (not item) then
		return;
	end

	-- If this resource was not captured via captureFile, we return an empty string instead of an error.
	return item.payload:GetHeader(self.HttpConstants.kXCapturedFilenameHeader) or "";
end

-- Returns all http headers for url
function ResourceStore:GetAllHeaders(url) 
	local item = self:GetItemInfo(url);
	if (not item) then
		return;
	end
	return item.payload.headers;
end

-- flush all transactions to database. 
-- @param bNoLog: if true, no log is printed. 
-- return true if committed. 
function ResourceStore:Flush(bNoLog)
	local web_db = self:GetDB();
	if(web_db) then
		return web_db:Flush(bNoLog);
	end
end
