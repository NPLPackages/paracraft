--[[
Title: the local server's db provider interface.
Author(s): LiXizhi
Date: 2008/2/21
Desc: 
This class provides a data access API for web capture data. The underlying repository is SQLite. This class encaplates the SQL required to insert, update, and delete records into the database.
Note: the interface resambles the google gear's localserver interface.
Usage: when calling paraworld API's webservice, one can assume that u can call them as often as you want and either online or offline. The local server app is developed, 
so that the app like the map does not need to have its own local db mirror, it just calls web services each time it wants something. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/WebCacheDB.lua");
local webDB = Map3DSystem.localserver.WebCacheDB.GetDB()
-------------------------------------------------------
]]

local WebCacheDB = commonlib.gettable("Map3DSystem.localserver.WebCacheDB");
local pairs = pairs
local ipairs = ipairs
local tostring = tostring
local tonumber = tonumber
local type = type

NPL.load("(gl)script/kids/3DMapSystemApp/localserver/http_constants.lua");
-- partial definition of WebCacheDB
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/WebCacheDB_def.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/WebCacheDB_store.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/WebCacheDB_permissions.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/sqldb_wrapper.lua");

local web_db_pools = {};
-- the default WebCacheDB instance
local web_db_default;

-- get the singleton instance of this database file. It will initialize the db if it is not yet initialized. 
-- Note: An instance of this class can only be accessed from a single thread.
-- @param db_name: if this is nil, it will get the default web db at "Database/localserver.db".
-- if not it will get the db at "Database/[db_name].db".
function WebCacheDB.GetDB(db_name)
	if(not db_name) then
		web_db_default = web_db_default or WebCacheDB:new({});
		return web_db_default;
	else
		web_db_pools[db_name] = web_db_pools[db_name] or WebCacheDB:new({
			kFileName = string.format("Database/%s.db", db_name),
		});
		return web_db_pools[db_name];
	end	

	--local self = WebCacheDB;
	--if(not self._db) then
		--self:Init();
	--end
	--return self;
end

-- flushing all database.
function WebCacheDB.FlushAll()
	log("flushing all local server databases ... ")
	local count = 0;
	if(web_db_default) then
		count = count + 1;
		web_db_default:Flush();
	end
	local _, webdb
	for _, webdb in pairs(web_db_pools) do
		count = count + 1;
		webdb:Flush();
	end
	log(tostring(count).." DONE\n")
end

-- Create a new instance of the database
-- @param o: must be nil or {kFileName = "Database/localserver.db"}, where kFileName is the file name. 
function WebCacheDB:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	if(not o._db) then
		o:Init();
	end
	return o
end

-------------------------------
-- resource service functions
-------------------------------
-- Returns if the database has a response for the url at this time
-- @param url: string
-- @return boolean.
function WebCacheDB:CanService(url)
	-- TODO:
	return false;
end

-- Returns a response for the url at this time, if head_only is requested
-- the payload's data will not be populated
-- @param url: string
-- @param head_only: boolean
-- @param payload: in|out. if nil, a new one is created. type of WebCacheDB.PayloadInfo
-- @return boolean, PayloadInfo . the first return value is true if succeed. 
function WebCacheDB:Service(url, head_only, payload)
	-- get payload id 
	local payload_id, redirect_url = WebCacheDB:Service_payloadID(url);
	
	if(payload_id) then 
		return  WebCacheDB:FindPayload(payload_id, payload, head_only);
	end
end

-- return the payload ID for a given url. 
-- @param url: the url for which we are servicing. 
--  content after fragment identifier # is always ignored. 
--  content of query paramter ? is ignored only if there is no matching entry with the query string included.
-- @return payloadID  
-- TODO: lxz: a redirectUrl may be returned, If we found an entry that requires a cookie, and no cookie exists, and
--   specifies a redirect url for use in that case, then return the redirect url.
function WebCacheDB:Service_payloadID(url)
	-- If a fragment identifier '#'is appended to the url, ignore it. The fragment
	-- identifier is not part of the url and specifies a position within the
	-- resource, rather than the resource itself. So we remove the fragment
	-- identifier for the purpose of searching the database. The fragment
	-- identifier is separated from the URL by '#' and may contain reserved characters including '?'.
	url = string.gsub(url, "#.*$", "");

	-- If the requested url contains query parameters, we have to do additional
	-- work to respect the 'ignoreQuery' attribute which allows an entry to
	-- be hit for a url plus arbitrary query parameters. We do an additional
	-- search with the query parameters removed from the requested url.
	local url_without_query, query_string = string.find(url, "([^?]*)%?(.*)$");
	local sql;
	local stmt;
	if(query_string) then
		sql = [[SELECT s.ServerID, s.RequiredCookie, s.ServerType,
					v.SessionRedirectUrl, e.IgnoreQuery, e.PayloadID 
					FROM Entries e, Versions v, Servers s 
					WHERE (e.Url = ? OR (e.Url = ? AND e.IgnoreQuery = 1)) AND 
					VersionID = e.VersionID AND 
					v.ReadyState = ? AND 
					s.ServerID = v.ServerID AND 
					s.Enabled = 1
		]]
		stmt = assert(self._db:prepare(sql));
		stmt:bind(url, url_without_query, WebCacheDB.VersionReadyState.VERSION_CURRENT);
	else
		sql = [[SELECT s.ServerID, s.RequiredCookie, s.ServerType,
					v.SessionRedirectUrl, e.IgnoreQuery, e.PayloadID 
					FROM Entries e, Versions v, Servers s 
					WHERE e.Url = ? AND 
					VersionID = e.VersionID AND 
					v.ReadyState = ? AND 
					s.ServerID = v.ServerID AND 
					s.Enabled = 1
		]]
		stmt = assert(self._db:prepare(sql));
		stmt:bind(url, WebCacheDB.VersionReadyState.VERSION_CURRENT);
	end
	
	local RowFounded;
	local bBreak;
	
	-- Iterate looking for an entry with no cookie required or with the required cookie present.
	
	local cookie_map; -- we defer reading cookies until needed
	local row;
	for row in stmt:rows() do
		local is_cookie_required = (row.RequiredCookie ~= nil and row.RequiredCookie~="")
		local has_required_cookie;
		if(is_cookie_required) then
			if(cookie_map == nil) then
				cookie_map = Map3DSystem.localserver.CookieMap:new(url);
			end
			has_required_cookie = cookie_map:HasLocalServerRequiredCookie(row.required_cookie);
		end
		
		if (not is_cookie_required or has_required_cookie) then
			if(row.ServerType == WebCacheDB.ServerType.MANAGED_RESOURCE_STORE) then
				-- We found a match from a managed store, try to update it
				-- Note that a failure does not prevent servicing the request
				self:MaybeInitiateUpdateTask(row.ServerID);
			end
			if(row.IgnoreQuery) then
				-- Continue iterating to give preference to exact matches
				RowFounded = row;
			else
				-- extact match is found. so break immediately.
				RowFounded = row;
				break;
			end
		end
		-- TODO: Handle http redirection 3** responses.
	end
	stmt:close();
	
	if(RowFounded) then
		-- we have found a match, so return it without redirections. 
		return RowFounded.PayloadID;
	else
		-- TODO: Handle possible http redirection 3** responses. 
	end	
end


-------------------------------
-- payload related functions
-------------------------------

-- read from server database table row to PayloadInfo struct. 
local function ReadPayloadInfo(row, payload)
	payload.id = row.PayloadID;
	payload.creation_date = row.CreationDate;
	payload.headers = row.Headers;
	payload.status_line = row.StatusLine;
	payload.status_code = row.StatusCode;
end

-- Returns the payload with the given payload_id. 
-- @param payload_id: int64
-- @param info_only: if info_only is true, the data (response body) and cached_filepath fields will be empty
-- @param payload: in|out. if nil, a new one is created. type of WebCacheDB.PayloadInfo
-- @return payload. the payload is returned or nil if failed. 
function WebCacheDB:FindPayload(payload_id, info_only, payload)
	payload = payload or self.PayloadInfo:new();
	
	local stmt = assert(self._db:prepare([[SELECT PayloadID, CreationDate, Headers, StatusLine, StatusCode FROM Payloads WHERE PayloadID=?]]));
	stmt:bind(payload_id);
	local row;
	for row in stmt:rows() do
		ReadPayloadInfo(row, payload)
	end
	stmt:close();

	if(payload.id) then
		return self:ReadBody(payload, info_only);
	end	
end

-- insert payload to db 
function WebCacheDB:InsertPayload(server_id, url, payload) 
	if(not server_id or not url or not payload) then
		return 
	end
	local res;
	self:Begin("insert pay load")
		payload.creation_date= ParaGlobal.GetSysDateTime();
		
		local stmt = assert(self._db:prepare([[INSERT INTO Payloads (CreationDate, Headers, StatusLine, StatusCode) VALUES (?, ?, ?, ?)]]));
		stmt:bind(payload.creation_date, payload.headers, payload.status_line, payload.status_code);
		stmt:exec();
		stmt:close();
		-- get row id. 
		payload.id = self._db:last_insert_rowid()
		
		-- Save the body in the bodies store. The full path of the file
		-- created is returned in payload.cached_filepath
		res = self:InsertBody(server_id, url, payload)
	self:End()
	
	return res;
end

-- only delete an payload if there is no entry referencing it. 
function WebCacheDB:MaybeDeletePayload(payload_id) 
	local res = true;
	self:Begin();
	
	-- get the number of entry referencing it. 
	local stmt = assert(self._db:prepare([[SELECT COUNT(*) FROM Entries WHERE PayloadID=?]]));
	stmt:bind(payload_id);
	local count = stmt:first_cols()
	stmt:close();
	
	-- only delete an payload if there is no entry referencing it. 
	if (count and count == 0) then
		res = self:DeletePayload(payload_id)
	end
	self:End();
	return res;
end

-- delete an payload by its id. 
function WebCacheDB:DeletePayload(payload_id)
	local res
	self:Begin("DeletePayload");
		local stmt = assert(self._db:prepare([[DELETE FROM Payloads WHERE PayloadID=?]]));
		stmt:bind(payload_id);
		stmt:exec();
		stmt:close();
		-- Delete the response body.
		res = self:DeleteBody(payload_id)
	self:End();
	return res;
end

-- delete all payload that are not referenced by any entry. 
function WebCacheDB:DeleteUnreferencedPayloads() 
	self:Begin("DeleteUnreferencedPayloads");
		-- Delete from the Payloads table
		self._db:exec([[DELETE FROM Payloads WHERE PayloadID NOT IN (SELECT DISTINCT PayloadID FROM Entries)]]);
		-- Now delete the response bodies
		self:DeleteUnreferencedBodies()
	self:End();
end

function WebCacheDB:FindMostRecentPayload(server_id, url) 
	if(not url) then return end

	local stmt = assert(self._db:prepare([[SELECT p.PayloadID, p.CreationDate, p.Headers,p.StatusLine, p.StatusCode 
		FROM Payloads p, Entries e, Versions v 
		WHERE v.ServerID=? AND v.VersionID=e.VersionID AND e.PayloadID=p.PayloadID AND (e.Src=? OR (e.Src IS NULL AND e.Url=?)) 
		ORDER BY p.CreationDate LIMIT 1
		]]));
	stmt:bind(server_id, url, url);

	local payload;
	local row;
	for row in stmt:rows() do
		payload = self.PayloadInfo:new();
		ReadPayloadInfo(row, payload);
		break;
	end
	stmt:close();
	return payload
end

-------------------------------
-- server related functions
-------------------------------

-- read from server database table row to ServerInfo struct. 
local function ReadServerInfo(row, server)
	server.id = row.ServerID;
	server.enabled = (row.Enabled == 1);
	server.security_origin_url = row.SecurityOriginUrl;
	server.name = row.Name;
	server.required_cookie = row.RequiredCookie;
	server.server_type = row.ServerType;
	server.manifest_url = row.ManifestUrl;
	server.update_status = row.UpdateStatus;
	server.last_update_check_time = row.LastUpdateCheckTime;
	server.manifest_date_header = row.ManifestDateHeader;
	server.last_error_message = row.LastErrorMessage;
end

-- Returns server info for the given server_id
-- @param server_id: int64, if nil the third to sixth parameters are used
-- @param server: in|out. if nil, a new one is created and returned. type of WebCacheDB.ServerInfo
-- @param security_origin, name, required_cookie, server_type: in case server_id is nil, these parameters are used together to find a server.
-- @return server.  or nil if failed
function WebCacheDB:FindServer(server_id, server, security_origin, name, required_cookie, server_type)
	server = server or self.ServerInfo:new();
	
	local stmt;
	if(server_id~=nil) then
		stmt = assert(self._db:prepare([[SELECT * FROM Servers WHERE ServerID=?]]));
		stmt:bind(server_id);
	else
		stmt = assert(self._db:prepare([[SELECT * FROM Servers WHERE SecurityOriginUrl=? AND Name=? AND RequiredCookie=? AND ServerType=?]]));
		local url;
		if(type(security_origin) == "string") then
			security_origin = Map3DSystem.localserver.SecurityOrigin:new(security_origin)
		end
		if(type(security_origin) == "table") then
			url = security_origin.url;
		end
		stmt:bind(url, name, required_cookie, server_type);
	end	
	
	local row;
	for row in stmt:rows() do
		ReadServerInfo(row, server)
		break;
	end
	stmt:close();

	if(server.id) then
		return server;
	end	
end

-- return a list of servers having the same origin
-- @param security_origin: type of Map3DSystem.localserver.SecurityOrigin or an URL string
-- @return: an array of ServerInfo is returned. 
function WebCacheDB:FindServersForOrigin(security_origin) 
	local servers = {};
	local url;
	if(type(security_origin) == "string") then
		security_origin = Map3DSystem.localserver.SecurityOrigin:new(security_origin)
	end
	if(type(security_origin) == "table") then
		url = security_origin.url;
	end
		
	local stmt;
	stmt = assert(self._db:prepare([[SELECT * FROM Servers WHERE SecurityOriginUrl=?]]));
	stmt:bind(url);

	local row;
	for row in stmt:rows() do
		local server = self.ServerInfo:new();
		ReadServerInfo(row, server)
		table.insert(servers, server);
	end
	stmt:close();
	return servers;
end

-- Inserts a new row into the Servers table. The id field of the server
-- parameter is updated with the id of the inserted row.
-- @param server: type of ServerInfo
-- @return nil if failed, or server object. 
function WebCacheDB:InsertServer(server)
	if(not server) then return end
	
	if (not Map3DSystem.localserver.UrlHelper.IsStringValidPathComponent(server.name)) then
		-- invalid user-defined name
		log("warning: invalid server name "..server.name.."\n")
		return
	end
	-- verify security origin
	if (not self:IsOriginAllowed(server.security_origin_url)) then
		log("security origin not allowed for the server: "..server.security_origin_url.."\n")
		return;
	end
	
	local _, err;
	self:Begin("insert server")
		
		local stmt = assert(self._db:prepare([[INSERT INTO Servers (Enabled, SecurityOriginUrl, Name, RequiredCookie,
				ServerType, ManifestUrl, UpdateStatus, LastErrorMessage, LastUpdateCheckTime, ManifestDateHeader)
				VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)]]));
		local enabled;
		if(server.enabled) then  enabled = 1 else	enabled = 0	end
		
		stmt:bind(enabled, server.security_origin_url, server.name, server.required_cookie,
			server.server_type, server.manifest_url, server.update_status, 
			server.last_error_message, server.last_update_check_time, server.manifest_date_header);
		_, err = stmt:exec();
		stmt:close();
		-- get row id. 
		server.id = self._db:last_insert_rowid()
		
	self:End()
	
	if(not err) then
		return server
	end
end

-- Deletes all servers and associated data for the given origin
function WebCacheDB:DeleteServersForOrigin(origin) 
	self:Begin("delete servers")
		local servers = self:FindServersForOrigin(origin);
		if(servers) then
			local _, server
			for _, server in ipairs(servers) do
				self:DeleteServer(server.id)
			end
		end	
	self:End()
end

-- Deletes the Server row and all related versions and entries and no longer referenced payloads.
-- @param id: server id. 
-- @return true if succeed
function WebCacheDB:DeleteServer(id)
	local _, err;
	self:Begin("delete server")
		self:DeleteDirectoryForServer(id);
		self:DeleteVersions(id)
		-- Now delete the server row 
		local stmt = assert(self._db:prepare([[DELETE FROM Servers WHERE ServerID=?]]));
		stmt:bind(id);
		_, err = stmt:exec();
		stmt:close();
		
	self:End()
	if(not err) then return true end
end

-- update server according to the second parameter type, see local functions inside. 
function WebCacheDB:UpdateServer(id, ...)
	local stmt;
	local arg = {...};
	-- Updates the  Enabled column of Server row
	local function UpdateServer_enabled(enabled)
		stmt = assert(self._db:prepare([[UPDATE Servers SET Enabled=? WHERE ServerID=?]]));
		if(enabled) then enabled = 1 else	enabled = 0		end
		stmt:bind(enabled, id);
	end
	
	-- Updates the ManifestUrl column of the Server row and resets the
	-- ManifestDateHeader and LastUpdateCheckTime columns.
	local function UpdateServer_manifest_url(manifest_url)
		stmt = assert(self._db:prepare([[UPDATE Servers SET ManifestUrl=?, ManifestDateHeader="" WHERE ServerID=?]]));
		stmt:bind(manifest_url, id);
	end
	
	-- Updates the UpdateStatus, LastUpdateCheckTime and optionally the
	-- ManifestDateHeader columns of the Servers row.  If
	-- manifest_date_header is not null, that column is updated.
	local function UpdateServer_status(update_status, last_update_check_time, manifest_date_header, error_message)
		local params = {update_status, last_update_check_time}
		local sql = "UPDATE Servers SET UpdateStatus=?, LastUpdateCheckTime=? "
		if(manifest_date_header) then
			sql = sql..", ManifestDateHeader=?"
			table.insert(params, manifest_date_header);
		end
		if(error_message) then
			sql = sql..", LastErrorMessage=?"
			table.insert(params, error_message);
		end
		sql = sql.." WHERE ServerID=?"
		table.insert(params, id);
		
		stmt = assert(self._db:prepare(sql));
		stmt:bind(unpack(params));
	end
	
	local type1 = type(arg[1]);
	if(type1 == "boolean" or type1 == "nil") then
		UpdateServer_enabled(arg[1])
	elseif(type1 == "string") then	
		UpdateServer_manifest_url(arg[1])
	elseif(type1 == "number" and type(arg[2])=="number") then	
		UpdateServer_status(arg[1], arg[2], arg[3], arg[4])
	else
		log("warning: unknown input to WebCacheDB:UpdateServer\n")
	end
	
	if(stmt) then
		local _, err = stmt:exec();
		stmt:close();
		if(not err) then
			return true
		end
	end	
end

----------------------------
-- version related. 
----------------------------

-- translate database row to version info struct. 
local function ReadVersionInfo(row, version)
	version.id = row.VersionID;
	version.server_id = row.ServerID;
	version.version_string = row.VersionString;
	version.ready_state = row.ReadyState;
	version.session_redirect_url = row.SessionRedirectUrl;
end

-- Inserts a new row into the Versions table. The id field of the version
-- parameter is updated with the id of the inserted row.
-- @param version: type of VersionInfo
-- @return: return nil if failed and true if succeed. 
function WebCacheDB:InsertVersion(version) 
	if(not version) then return end
	-- insert the row 
	local stmt = assert(self._db:prepare([[INSERT INTO Versions (ServerID, VersionString, ReadyState,SessionRedirectUrl) VALUES(?, ?, ?, ?)]]));
	stmt:bind(version.server_id, version.version_string, version.ready_state, version.session_redirect_url);
	_, err = stmt:exec();
	stmt:close();
	version.id = self._db:last_insert_rowid();
	if(not err) then
		return true;
	end	
end

-- Returns the version info for the given server_id and ready_state|version_string
-- @param server_id
-- @param arg1: ready_state or version_string
-- @return version info or nil if failed. 
function WebCacheDB:FindVersion(server_id, arg1)
	local stmt
	
	-- Returns the version info for the given server_id and ready_state
	local function FindVersion_ReadyState(ready_state)
		stmt = assert(self._db:prepare([[SELECT * FROM Versions WHERE ServerID=? AND ReadyState=?]]));
		stmt:bind(server_id, ready_state);
	end
	
	-- Returns the version info for the given server_id and version_string
	local function FindVersion_VersionString(version_string)
		stmt = assert(self._db:prepare([[SELECT * FROM Versions WHERE ServerID=? AND VersionString=?]]));
		stmt:bind(server_id, version_string);
	end
	if(type(arg1) == "number") then
		FindVersion_ReadyState(arg1)
	elseif(type(arg1) == "string") then
		FindVersion_VersionString(arg1)
	else
		log("warning: unknown arg1 in FindVersion\n");
		return
	end
	local version;
	local row;
	for row in stmt:rows() do
		version = self.VersionInfo:new();
		ReadVersionInfo(row, version);
		break;
	end
	stmt:close();
	return version
end

-- Returns an array of version info for all versions associated with the given server_id
-- @param server_id
-- @return: an array of VersionInfo is returned. or empty table if no one is found. 
function WebCacheDB:FindVersions(server_id) 
	local versions = {};
	
	local stmt = assert(self._db:prepare([[SELECT * FROM Versions WHERE ServerID=?]]));
	stmt:bind(server_id);

	local row;
	for row in stmt:rows() do
		local version = self.VersionInfo:new();
		ReadVersionInfo(row, version);
		table.insert(versions, version);
	end
	stmt:close();
	return versions;
end

-- Updates the ReadyState column for the given version_id
-- @param id: version id
-- @param ready_state: 0|1 or WebCacheDB.VersionReadyState
function WebCacheDB:UpdateVersion(id, ready_state) 
	local stmt;
	stmt = assert(self._db:prepare([[UPDATE Versions SET ReadyState=? WHERE VersionID=?]]));
	stmt:bind(ready_state, id);
	_, err = stmt:exec();
	stmt:close();
	
	if(not err) then
		return true;
	end	
end

-- Deletes the Version row and all related entries and no longer referenced payloads
function WebCacheDB:DeleteVersion(version_id)
	return self:DeleteVersions({version_id})
end

-- Deletes the Version row and all related entries and no longer referenced payloads
function WebCacheDB:DeleteVersions(arg1)
	if(type(arg1) == "number") then
		-- Deletes all versions related to the given server_id, and all related entries and no longer referenced payloads
		local server_id = arg1
		self:Begin("DeleteVersions");
			local versions = self:FindVersions(server_id);
			local _, version
			local version_ids = {};
			for _, version in ipairs(versions) do
				table.insert(version_ids, version.id);
			end
			if(table.getn(version_ids) > 0) then
				self:DeleteVersions(version_ids);
			end	
		self:End();
	elseif(type(arg1) == "table") then
		-- Deletes the given version_ids and related entries and no longer referenced payloads
		local version_ids = arg1;
		local version_id_count = table.getn(version_ids)
		if(version_id_count == 0) then
			return 
		end
		self:Begin("DeleteVersions");
			-- Delete all entries and no longer referenced payloads for these versions
			if (not self:DeleteEntries(version_ids)) then
				log("warning: DeleteEntries returns nil when DeleteVersions\n")
			end
			-- Now delete the version rows
			local sql = "DELETE FROM Versions WHERE VersionID IN (";
			local i;
			for i = 1, version_id_count do 
				if (i == version_id_count) then
					sql = sql.."?";
				else
					sql = sql.."?, ";
				end
			end	
			sql = sql..")";
			local stmt = assert(self._db:prepare(sql));
			stmt:bind(unpack(version_ids));
			_, err = stmt:exec();
			stmt:close();
		self:End();
	end
end

----------------------------------------
-- entries related functions. 
----------------------------------------
-- translate from database row to EntryInfo struct.
local function ReadEntryInfo(row, entry)
	entry.id = row.EntryID;
	entry.version_id = row.VersionID;
	entry.url = row.Url;
	entry.src = row.Src;
	entry.payload_id = row.PayloadID;
	entry.redirect = row.Redirect;
	entry.ignore_query = row.IgnoreQuery;
end

-- Inserts a new row into the Entries table. The id field of the entry
-- parameter is updated with the id of the inserted row.
-- @param entry: type of EntryInfo
-- @return true if succeed;
function WebCacheDB:InsertEntry(entry) 
	if(not entry or entry.url=="") then return end
	if(entry.ignore_query and string.find(entry.url, "?")) then 
		log("warning: InsertEntry: if entry.ignore_query is true, url can not contain query strings.\n")
		return
	end
	if(string.find(entry.url, "#")) then
		log("warning: InsertEntry: if entry.url can not contain # \n")
		return
	end
	-- insert the row 
	local stmt = assert(self._db:prepare([[INSERT INTO Entries (VersionID, Url, Src, PayloadID, Redirect, IgnoreQuery) VALUES (?, ?, ?, ?, ?, ?)]]));
	local ignore_query;
	if(entry.ignore_query) then ignore_query=1 else ignore_query=0 end
	stmt:bind(entry.version_id, entry.url, entry.src, entry.payload_id, entry.redirect, entry.ignore_query);
	_, err = stmt:exec();
	stmt:close();
	
	entry.id = self._db:last_insert_rowid();
	if(not err) then
		return true;
	end
end

-- Deletes all entries with the given version_id|version_ids. Does not fail if there are no matching entries.
-- @param arg1: version_id or an array of version_ids
function WebCacheDB:DeleteEntries(arg1)
	if(type(arg1) == "number") then
		-- Deletes all entries with the given version_id. Does not fail if there are no matching entries.
		local version_id = arg1
		return self:DeleteEntries({version_id});
		
	elseif(type(arg1) == "table") then
		-- Deletes all entries for an array of given version_ids. Does not fail if there are no matching entries.
		local version_ids = arg1;
		local version_id_count = table.getn(version_ids)
		if(version_id_count == 0) then
			return 
		end
		local _,err;
		self:Begin("DeleteVersions");
			-- Delete all Entries table rows for version_ids
			
			local sql = "DELETE FROM Entries WHERE VersionID IN (";
			local i;
			for i = 1, version_id_count do 
				if (i == version_id_count) then
					sql = sql.."?";
				else
					sql = sql.."?, ";
				end
			end	
			sql = sql..")";
			local stmt = assert(self._db:prepare(sql));
			stmt:bind(unpack(version_ids));
			_, err = stmt:exec();
			stmt:close();
			
			-- Now delete all unreferenced payloads
			self:DeleteUnreferencedPayloads();
		self:End();
		if(not err) then 
			return true
		end
	end
end

 -- Deletes the entry with the given entry_id. Does not fail if there is no matching entry.
 -- @param id: the entry id if url is nil. if url is string, this is the version id. 
function WebCacheDB:DeleteEntry(id, url)
	if(not id) then return end
	if(type(url) == "string") then
		return self:DeleteEntry2(id, url)
	end
	local _,err;
	self:Begin()
  
	-- Get the payload ID for this entry.
	local stmt = assert(self._db:prepare([[Select PayloadID FROM Entries WHERE EntryID=?]]));
	stmt:bind(id);

	local payload_id;
	local row;
	for row in stmt:rows() do
		payload_id = row.PayloadID;
		break;
	end
	stmt:close();
	--[[if(not payload_id) then
		-- If there's no match, commit the database transaction and return.
		self:End();
		return true;
	end]]
	
	-- delete the entry
	local stmt = assert(self._db:prepare([[DELETE FROM Entries WHERE EntryID=?]]));
	stmt:bind(id);
	_, err = stmt:exec();
	stmt:close();

	--	The payload_id may be NULL if the payload has not yet been inserted.
	if (payload_id == 0) then
		log("WebCacheDB.DeleteEntry - payload_id is NULL\n");
		self:End();
		return true;
	end

	-- Delete the payload if it may be orphaned.
	if (not self:MaybeDeletePayload(payload_id)) then
		log("warning: WebCacheDB.DeleteEntry failed\n");
	end

	return self:End();
end

-- Deletes the entry with the given version_id and url. Does not fail if there is no matching entry.
function WebCacheDB:DeleteEntry2(version_id, url)
	if(not url) then return end
	
	self:Begin("WebCacheDB:DeleteEntry")
	--  Get the entry ID for the requested URL and version.
	local stmt = assert(self._db:prepare([[SELECT EntryID FROM Entries WHERE VersionID=? AND Url=?]]));
	stmt:bind(version_id, url);
	
	local row;
	local num_matches = 0;
	--[[ cannot delete during select?
	for row in stmt:rows() do
		if(not self:DeleteEntry(row.EntryID)) then
			log("warning:WebCacheDB.DeleteEntry failed\n");
			break;
		end
		num_matches = num_matches +1;
	end
	stmt:close();
	]]
	local entries = {};
	for row in stmt:rows() do
		table.insert(entries, row.EntryID)
		num_matches = num_matches +1;
	end
	stmt:close();
	
	local _, id
	for _, id in ipairs(entries) do
		if(not self:DeleteEntry(id)) then
			log("warning:WebCacheDB.DeleteEntry failed\n");
			break;
		end
	end
	
	if (num_matches > 1) then
		log("warning: WebCacheDB.DeleteEntry - multiple matches for requested URL. This should never happen.\n");
	end
	return self:End();
end

-- Returns the entry for the given version_id and url
function WebCacheDB:FindEntry(version_id, url) 
	if(not url) then return end

	local stmt = assert(self._db:prepare([[SELECT * FROM Entries WHERE VersionID=? AND Url=?]]));
	stmt:bind(version_id, url);

	local entry;
	local row;
	for row in stmt:rows() do
		entry = self.EntryInfo:new();
		ReadEntryInfo(row, entry);
		break;
	end
	stmt:close();
	return entry
end

-- Returns an array of entries for version_id that do no have an associated payload or a redirect specified.
function WebCacheDB:FindEntriesHavingNoResponse(version_id) 
	local entries = {};
	
	local stmt = assert(self._db:prepare([[SELECT * FROM Entries WHERE VersionId=? AND PayloadId IS NULL]]));
	stmt:bind(version_id);

	local row;
	for row in stmt:rows() do
		local entry = self.EntryInfo:new();
		ReadEntryInfo(row, entry);
		table.insert(entries, entry);
	end
	stmt:close();
	return entries
end

-- Counts the number of entries for the given version_id. nil is returned if failed.
function WebCacheDB:CountEntries(version_id) 
	local stmt = assert(self._db:prepare([[SELECT COUNT(*) FROM Entries WHERE VersionID=?]]));
	stmt:bind(version_id);
	local count = stmt:first_cols()
	stmt:close();
	return count;
end

-- Updates the entry for the given version_id and orig_url to associate
-- it with new_url. Does not fail if there is no matching orig entry.
function WebCacheDB:UpdateEntry(version_id, orig_url, new_url) 
	if(not orig_url or not new_url) then return end
	
	local stmt = assert(self._db:prepare([[UPDATE Entries SET Url=? WHERE VersionID=? AND Url=?]]));
	stmt:bind(new_url, version_id, orig_url);
	local _, err = stmt:exec();
	stmt:close();
	
	if(not err) then
		return true;
	end
end

-- Updates all entries for the given version_id and url (or src) to
-- associate them with the given payload_id and redirect_url.
function WebCacheDB:UpdateEntriesWithNewPayload(version_id, url,payload_id, redirect_url) 
	if(not url or payload_id==0) then return end
	
	local stmt = assert(self._db:prepare([[UPDATE Entries SET PayloadId=?, Redirect=? WHERE VersionId=? AND PayloadId IS NULL AND (Src=? OR (Src IS NULL AND Url=?))]]));
	stmt:bind(payload_id, redirect_url, version_id, url, url);
	local _, err = stmt:exec();
	stmt:close();
	
	if(not err) then
		return true;
	end
end

