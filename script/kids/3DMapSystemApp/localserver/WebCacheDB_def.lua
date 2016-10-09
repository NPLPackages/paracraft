--[[
Title: Some header definition and functions for WebCacheDB. 
Author(s): LiXizhi
Date: 2008/2/22
Desc: Only included by the WebCacheDB.lua. it just make the file easy to read by splitting it to multiple files. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/WebCacheDB_def.lua");
-- call this function is you want to flush immediately. 
Map3DSystem.localserver.WebCacheDB:Flush();
-------------------------------------------------------
]]
local WebCacheDB = Map3DSystem.localserver.WebCacheDB;
local LOG = LOG;
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/sqldb_wrapper.lua");

-----------------------------
-- attributes
-----------------------------
-- the name of the local server database file
WebCacheDB.kFileName = "Database/localserver.db";
-- LXZ:2008.12.16: change WebCacheDB.kCurrentVersion to automatically upgrade db
WebCacheDB.kVersionFileName = "Database/localserver.ver";

-- whether to use lazy writing, when lazy writing is enabled, we will not commit to database immediately, but will batch many commit in a single Flush. 
-- it will increase the speed by 100 times, if we have many mini transactions to deal with. It is highly recommended to turn this on. 
WebCacheDB.EnableLazyWriting = true
-- if true, we will always acqure a lock even there is only read operation. This may create deadlock for multiple processes. 
WebCacheDB.EnableBatchMode = nil;
-- We will wait for this many milliseconds when meeting the first non-queued command before commiting to disk. So if there are many commits in quick succession, it will not be IO bound. 
WebCacheDB.AutoFlushInterval = 3000;

WebCacheDB.ServerType = {
    MANAGED_RESOURCE_STORE = 0,
    RESOURCE_STORE = 1,
    WEBSERVICE_STORE = 2,
    URLRESOURCE_STORE = 3,
};

WebCacheDB.VersionReadyState = {
    VERSION_DOWNLOADING = 0,
    VERSION_CURRENT = 1
};

-- current server state
WebCacheDB.UpdateStatus = {
    UPDATE_OK = 0,
    UPDATE_CHECKING = 1,
    UPDATE_DOWNLOADING = 2,
    UPDATE_FAILED = 3
};

-----------------------------
-- WebCacheDB.ServerInfo class
-----------------------------
-- a server is a set of dynamic or static web entries that are managed as a group. 
-- entries in a group usually shares the same server settings like minUpdateTime, etc. 
local ServerInfo = {
	-- int64 server id. 
	id = nil,
	-- temporarily enable or disable this server. 
    enabled = true,
    -- string: e.g. "www.paraengine.com"
    security_origin_url = "",
    -- string: server resource store name. e.g. "MyAppName"
    name = "",
    -- string: format same as http requery string. e.g."name=value&name2=value2"
    required_cookie = "",
    -- type of WebCacheDB.ServerType
    server_type = WebCacheDB.ServerType.RESOURCE_STORE,
    -- string: only used when server_type is MANAGED_RESOURCE_STORE, where the server represent 
    -- a static collection of web entries defined in the manifest file. 
    manifest_url = nil,
    -- type of WebCacheDB.UpdateStatus
    update_status = WebCacheDB.UpdateStatus.UPDATE_OK,
    -- string
    last_error_message=nil,
    -- int64
    last_update_check_time=0,
    -- string
    manifest_date_header=nil,
}
WebCacheDB.ServerInfo = ServerInfo;

function ServerInfo:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end

-----------------------------
-- WebCacheDB.VersionInfo class
-----------------------------
-- an URL resource may has be a version that is already downloaded, while having another newer version being downloaded. 
-- Hence, the same url has two version states. One can access the downloaded version while a newer version is being downloaded. 
-- usually after the newer version is downloaded, the old version is deleted, so that there is only one downloaded version left in the db thereafterwards. 
local VersionInfo = {
	-- int64
    id,
    -- int64
    server_id = 0,
    -- string
    version_string="",
    -- WebCacheDB.VersionReadyState
    ready_state = WebCacheDB.VersionReadyState.VERSION_DOWNLOADING,
    -- string
    session_redirect_url="",
};

WebCacheDB.VersionInfo = VersionInfo; 
function VersionInfo:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end

-----------------------------
-- WebCacheDB.EntryInfo class
-----------------------------
-- an URL web resource entry
local EntryInfo = {
	-- int64 
	id,
	-- int64 
    version_id,
    -- string
    url="",
    -- string
    src,
    -- string
    redirect = nil,
    ignore_query = false,
    -- int64 
    payload_id = nil,
};

WebCacheDB.EntryInfo = EntryInfo; 
function EntryInfo:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end


-----------------------------
-- WebCacheDB.PayloadInfo class
-----------------------------
-- the body data of the web resource entry
local PayloadInfo = {
	-- int64 
	id,
	-- int64 
    creation_date = 0,
    -- int: see Map3DSystem.localserver.HttpConstants. Default to HTTP_OK
    status_code = 200,
    -- string
    status_line = nil,
    -- string: Must be terminated with a blank line
    headers = nil,
    ---------------------------------
    -- The following fields are empty for info_only queries
    ---------------------------------
    -- the cached file path that contains the body data. Only applicable to file type urls. 
    cached_filepath = nil,
    -- the body response data itself. Only applicable to webservices where the response is stored as strings in the database instead of local file system. 
    data = nil,
    is_synthesized_http_redirect = false,
};

WebCacheDB.PayloadInfo = PayloadInfo; 
function PayloadInfo:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end

-- Returns a particular header value. may return nil if not found. 
function PayloadInfo:GetHeader(name)
	if (not name or not self.headers) then return end
	local value;
	local n,v
	for n,v in string.gfind(self.headers, "%s*(%S+)%s*:%s*([^\r\n]*)\r\n") do
		if(n == name) then
			value = v;
		end
	end
	return value
end

-- this function is assumed that the member data is a message table possible from the reponse of a web service.
-- @return the self.data as a table. 
function PayloadInfo:GetMsgData()
	if(type(self.data) == "string") then
		-- TODO: security check. shall we call NPL.IsSCodePureData(self.data) here again? 
		-- this is done at insertion time, however the database may be altered after insertion.
		return commonlib.LoadTableFromString(self.data)
	end
end


  
----------------------------
-- WebCacheDB class
----------------------------
-- Name of NameValueTable created to store version and browser information
WebCacheDB.kSystemInfoTableName = "SystemInfo";
-- Names of various other tables
WebCacheDB.kServersTable = "Servers";
WebCacheDB.kVersionsTable = "Versions";
WebCacheDB.kEntriesTable = "Entries";
WebCacheDB.kPayloadsTable = "Payloads";
WebCacheDB.kResponseBodiesTable = "ResponseBodies";

-- SQL create table command columns
WebCacheDB.kWebCacheTables =
{
	{ table_name = WebCacheDB.kServersTable,
	columns = [[
	(ServerID INTEGER PRIMARY KEY AUTOINCREMENT,
	Enabled INT CHECK(Enabled IN (0, 1)),
	SecurityOriginUrl TEXT NOT NULL,
	Name TEXT NOT NULL,
	RequiredCookie TEXT,
	ServerType INT CHECK(ServerType IN (0, 1 , 2, 3)),
	ManifestUrl TEXT,
	UpdateStatus INT CHECK(UpdateStatus IN (0,1,2,3)),
	LastUpdateCheckTime INTEGER DEFAULT 0,
	ManifestDateHeader TEXT,
	LastErrorMessage TEXT)]]},

	{ table_name = WebCacheDB.kVersionsTable,
	columns = [[
	(VersionID INTEGER PRIMARY KEY AUTOINCREMENT,
	ServerID INTEGER NOT NULL,
	VersionString TEXT NOT NULL,
	ReadyState INTEGER CHECK(ReadyState IN (0, 1)),
	SessionRedirectUrl TEXT)]]},
	
	-- src is The manifest file entry's src attribute
	{ table_name = WebCacheDB.kEntriesTable,
	columns = [[
	(EntryID INTEGER PRIMARY KEY AUTOINCREMENT,
	VersionID INTEGER,
	Url TEXT NOT NULL,
	Src TEXT, 
	PayloadID INTEGER,
	Redirect TEXT,
	IgnoreQuery INTEGER CHECK(IgnoreQuery IN (0, 1)))]]},

	{ table_name = WebCacheDB.kPayloadsTable,
	columns = [[
	(PayloadID INTEGER PRIMARY KEY AUTOINCREMENT,
	CreationDate INTEGER,
	Headers TEXT,
	StatusCode INTEGER,
	StatusLine TEXT)]]},

	-- BodyID is the same ID as the payloadID
	-- With USE_FILE_STORE, bodies are stored as discrete files, otherwise as blobs in the DB
	{ table_name = WebCacheDB.kResponseBodiesTable,
	columns = [[
	(BodyID INTEGER PRIMARY KEY, 
	FilePath TEXT, 
	Data BLOB)]]},    
};

WebCacheDB.kSchemaVersionName = "version";
WebCacheDB.kSchemaBrowserName = "browser";
-- The values stored in the system_info table
WebCacheDB.kCurrentVersion = 2;
WebCacheDB.kCurrentBrowser = "NPL";

-- sql db object. 
WebCacheDB._db = nil;
-- how many queued(uncommitted) transactions are there, if lazy writing is used. 
WebCacheDB.queued_transaction_count = 0;

-- create open database
function WebCacheDB:Init()
	if(self._db) then
		return 
	end

	-- private: 
	self.transaction_count_ = 0
	self.transaction_labels_ = {}
	self.queued_transaction_count = 0;

	local bNeedUpdate = true;
	if( ParaIO.DoesFileExist( self.kVersionFileName )) then
		local file = ParaIO.open(self.kVersionFileName, "r");
		if(file:IsValid()) then
			local text = file:GetText();
			local FileVersion = tonumber(text);
			if(FileVersion and FileVersion >= WebCacheDB.kCurrentVersion) then
				bNeedUpdate = false
			end
			file:close();
		end
	end
	
	if( not bNeedUpdate and ParaIO.DoesFileExist( self.kFileName,true) )then
		local err;
		self._db, err = sqlite3.open( self.kFileName);
		if( self._db == nil)then
			LOG.std("", "error", "localserver", "failed connecting to localserver db"..tostring(err));
		end
	end
	if(not self._db) then
		self:CreateOrUpgradeDatabase()
	else
		self.system_info_table_ = Map3DSystem.localserver.NameValueTable:new(self._db, self.kSystemInfoTableName);
	end
	
	if(self._db) then
		self.timer = self.timer or commonlib.Timer:new({callbackFunc = function(timer)
			if(self:Flush()) then
				timer:Change();
			end
		end})
		if(self.EnableLazyWriting and self.EnableBatchMode) then
			-- use lazy writing, start a begin transaction at the very beginning so that the cache is never cleared.
			self._db:exec("BEGIN")
		end	
		LOG.std("", "system", "localserver", "localserver: %s is opened", self.kFileName);
	end
end

-- flush all transactions to database. 
-- @param bNoLog: if true, no log is printed. 
-- return true if committed. 
function WebCacheDB:Flush(bNoLog)
	if(self._db and self.queued_transaction_count > 0 and self.transaction_count_ == 0) then
		if(not bNoLog) then
			LOG.std("", "system", "localserver", "flushing %d queued database transactions to localserver:%s", self.queued_transaction_count, self.kFileName);
		end
		self.queued_transaction_count = 0;
		-- flush now
		self._db:exec("END")
		
		if(self.EnableBatchMode) then
			-- batching new transactions again. 
			self._db:exec("BEGIN");
		end	
		return true;
	end
end

-- currently only supporting creating a new database. 
function WebCacheDB:CreateOrUpgradeDatabase()
	if(self._db) then
		self._db:close();
	end
	-- create the database. 
	local err;
	self._db, err = sqlite3.open( self.kFileName);
	if( self._db == nil)then
		LOG.std("", "error", "localserver", "error: failed connecting to localserver db"..tostring(err));
	end
	-- drop all tables. 
	Map3DSystem.localserver.SqlDb.DropAllObjects(self._db);

	-- create all tables
	self:CreateTables();
	
	-- insert version infos
	local insert_stmt = assert(self._db:prepare("INSERT INTO SystemInfo (Name, Value) VALUES(?, ?)"));
	insert_stmt:bind(WebCacheDB.kSchemaVersionName, WebCacheDB.kCurrentVersion);
	insert_stmt:exec();
	
	insert_stmt:bind(WebCacheDB.kSchemaBrowserName, WebCacheDB.kCurrentBrowser);
	insert_stmt:exec();
	
	insert_stmt:close();
	
	LOG.std("", "system", "localserver", "localserver: %s is recreated either because it does not exist or needs update", self.kFileName);
	-- write the db version 
	local file = ParaIO.open(self.kVersionFileName, "w");
	if(file:IsValid()) then
		file:WriteString(tostring(WebCacheDB.kCurrentVersion));
		file:close();
	end
end

-- create tables in the database 
function WebCacheDB:CreateTables()
	self.system_info_table_ = Map3DSystem.localserver.NameValueTable:new(self._db, self.kSystemInfoTableName);
	self.system_info_table_:MaybeCreateTable();
	
	local _, table
	for _, table in ipairs(WebCacheDB.kWebCacheTables) do
		local sql = "CREATE TABLE ";
		sql = sql..table.table_name.." "
		sql = sql..table.columns;
		self._db:exec(sql)
	end
end

-------------------------------------
-- database transaction related functions
-------------------------------------

-- begin transaction: it emulates nested transactions. 
-- lazy writing is employed (which means that we do not commit changes immediately)
-- @param label: nil or a string label for debugging purposes
-- @param mode: nil, or "deferred". default to nil. 
function WebCacheDB:Begin(label, mode)
	self.transaction_count_ = self.transaction_count_+1;
	self.transaction_labels_[self.transaction_count_] = label;
	
	if(self.transaction_count_ == 1) then
		if(self.EnableLazyWriting) then
			if(not self.EnableBatchMode) then
				if(self.queued_transaction_count == 0) then
					-- lxz: this can not be "BEGIN",otherwise if select command in the transaction, a deadlock may appear with multiple process
					if(not mode) then
						self._db:exec("BEGIN IMMEDIATE")
						self.last_transaction_mode = nil;
					else
						self._db:exec("BEGIN")
						self.last_transaction_mode = "deferred";
					end	
				elseif(self.last_transaction_mode ~= mode) then
					if(not mode) then
						-- switch to immediate mode. 
						self.last_transaction_mode = nil;
						self._db:exec("END")
						self._db:exec("BEGIN IMMEDIATE")
						LOG.std("", "system", "localserver", "sql promoting to RESERVERD lock in WebCacheDB:Begin()");
					end
				end	
			end
		else
			self._db:exec("BEGIN")
		end	
		
		if(label) then
			LOG.std("", "debug","localserver","Begin transaction: %s", label);
			--commonlib.log("time: %s\n", ParaGlobal.timeGetTime())
		end
	end	
	return true;
end

-- end transaction
-- @param bRollback: if true, it will rollback on last root pair. 
-- @param bForceFlush: default to nil. if true, we will flush to database immediate when nested transaction is 0.
function WebCacheDB:End(bRollback, bForceFlush)
	if(bRollback) then
		self.needs_rollback_ = true;
	end
	if(bForceFlush) then
		self.bForceFlush = true;
	end
	if(self.transaction_count_ == 0) then
		LOG.std("", "warning", "localserver", "warning: SQLDatabase in WebCacheDB: unbalanced transactions");
	end
	self.transaction_count_ = self.transaction_count_-1;
	local _,err;
	if(self.transaction_count_ == 0) then
		self.last_transaction_mode = nil;
		if(not self.needs_rollback_) then
			-- we are closing the last transaction, commit provided rollback has not been called.
			if(self.EnableLazyWriting) then
				self.queued_transaction_count = self.queued_transaction_count + 1;
				if(self.bForceFlush) then
					self.bForceFlush = false;
					if(self:Flush(true)) then
						LOG.std("", "debug", "localserver", "force flush called for %s", self.kFileName);
						self.timer:Change();
					end
				else
					if(not self.timer:IsEnabled()) then
						-- The logics is changed: we will start the timer at fixed interval.
						-- self.timer:Change(self.AutoFlushInterval, nil);
						self.timer:Change(self.AutoFlushInterval, self.AutoFlushInterval);
					end	
				end
			else
				_,err = self._db:exec("END")
			end	
		else
			-- Rollback is necessary, 
			_,err = self._db:exec("ROLLBACK")
		end
		local label = self.transaction_labels_[self.transaction_count_+1];
		if(label) then
			if(not self.needs_rollback_) then
				LOG.std("", "debug","localserver","End transaction: %s", label)
				--commonlib.log("time: %s\n", ParaGlobal.timeGetTime())
			else
				LOG.std("", "error","localserver","ROLLBACK transaction: %s", label)
			end	
		end
		self.needs_rollback_ = false;
	end	
	if(not err) then
		return true;
	end
end

-------------------------------
-- common functions:
-------------------------------
function WebCacheDB:MaybeInitiateUpdateTask()
	-- TODO: 
end