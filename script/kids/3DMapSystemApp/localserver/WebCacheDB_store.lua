--[[
Title: A WebCacheDB_Store is partial implementation of WebCacheDB to store the response bodies in the database
Author(s): LiXizhi
Date: 2008/2/23
Desc: 
-- A WebCacheBlobStore is used by a WebCacheDB to store the response
-- bodies in the SQLite database as blobs. At this time, all HTTP post is stored as flat files in the
-- file system and all web service responses are stored in database as the blob data
-- This file is only used by WebCacheDB
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/WebCacheDB_store.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/http_constants.lua");
local WebCacheDB = Map3DSystem.localserver.WebCacheDB;
local HttpConstants = Map3DSystem.localserver.HttpConstants;

-- data directory where to store temporary local server files. 
WebCacheDB.dataDir_ = "temp/webcache"


-- Inserts a response body into the store
function WebCacheDB:InsertBody(server_id, url, payload)
	if(not server_id or not url or not payload) then
		return 
	end
	
	-- We only store the bodies of successful responses
	if(payload.status_code ~= HttpConstants.HTTP_OK ) then
		return true;
	end

	-- Insert a row in the ResponseBodies table containing the data. Note
	-- that BodyID is the same as PayloadID in the Payloads table.
	
	local stmt = assert(self._db:prepare([[INSERT INTO ResponseBodies (BodyID, FilePath, Data) VALUES (?, ?, ?)]]));
	if(type(payload.data) == "table") then
		payload.data = commonlib.serialize_compact(payload.data)
	end
	stmt:bind(payload.id, payload.cached_filepath, payload.data);
	local _, err = stmt:exec();
	stmt:close();

	if(err == nil) then
		return true;
	end
end

-- Reads a body from the store
-- @param payload: in|out table
-- @param info_only: boolean
-- @return payload is returned.  
function WebCacheDB:ReadBody(payload, info_only)
	if(info_only) then
		-- it does nothing. 
	else
		-- retrieve from database
		local stmt = assert(self._db:prepare([[SELECT FilePath, Data FROM ResponseBodies WHERE BodyID=?]]));
		stmt:bind(payload.id);
		local row;
		for row in stmt:rows() do
			payload.cached_filepath = row.FilePath
			payload.data = row.Data
		end
		stmt:close();
	end
	return payload
end

-- Deletes a body from the store
function WebCacheDB:DeleteBody(payload_id)
	local stmt = assert(self._db:prepare([[DELETE FROM ResponseBodies WHERE BodyID=?]]));
	stmt:bind(payload_id);
	local _, err = stmt:exec();
	stmt:close();
	if(err == nil) then
		return true;
	end
end
  
-- Deletes all unreferenced bodies from the store
function WebCacheDB:DeleteUnreferencedBodies()
	local _, err = self._db:exec("DELETE FROM ResponseBodies WHERE BodyID NOT IN (SELECT DISTINCT PayloadID FROM Payloads)")
	if(err == nil) then
		return true;
	end
end

--------------------------------
-- file store related 
--------------------------------
-- get directory name for a given security origin. 
-- @param origin: securityOrigin object. 
-- @param path: path of base directory. if nil, it will use WebCacheDB.dataDir_
function WebCacheDB.GetDataDirectory(origin, path)
	-- Files for a given origin under basePath/host/scheme_port
	-- This makes it easy to find all "www.paraengine.com" folders in a dir list,
	-- regardless scheme (http/https) or port.
	if(path == nil) then
		path = WebCacheDB.dataDir_
	end
	path = string.format("%s/%s/%s_%s", path, origin.host, origin.scheme, origin.port_string or "")
	return path;
end

-- Note: it ends with "/"
-- return the full path of the directory containing files associated with server_id. 
function WebCacheDB:GetDirectoryPathForServer(server_id)
	-- Determine the directory we'll put files in based on the security
	-- origin, name, and type of the store. The directory path
	-- also includes the server_id. Ex.
	-- <data_dir>/<directory_for_origin>/Name[15]_localserver
	-- <data_dir>/<directory_for_origin>/Name_managed[27]_localserver

	-- Get "<data_dir>/<directory_for_origin>", a full directory path
	local server = self:FindServer(server_id);
	if(not server) then return end
	local security_origin = Map3DSystem.localserver.SecurityOrigin:new(server.security_origin_url)
	local server_dir = WebCacheDB.GetDataDirectory(security_origin);
	
	-- Form the "Name[id]" part of the path
	local server_dir_name = server.name;
	if(server.server_type == WebCacheDB.ServerType.MANAGED_RESOURCE_STORE) then
		server_dir_name = server_dir_name.."_managed"
	end
	server_dir_name = string.format("%s[%d]", server_dir_name, server_id)

	-- Stitch the two together, and append the "_localserver" suffix
	return string.format("%s/%s_localserver/", server_dir, server_dir_name)
end

-- Creates a directory to contain the files associated with server_id. 
function WebCacheDB:CreateDirectoryForServer(server_id)
	local server_dir = self:GetDirectoryPathForServer(server_id);
	if(server_dir) then
		ParaIO.CreateDirectory(server_dir);
		return server_dir
	end
end
  
-- Delete the directory associated with server_id. 
function WebCacheDB:DeleteDirectoryForServer(server_id)
	local server_dir = self:GetDirectoryPathForServer(server_id);
	if(server_dir) then
		if(string.find(server_dir, "^temp/")) then
			log("deleting server cache files: "..server_dir.."\n")
			ParaIO.DeleteFile(server_dir.."*.*")
			-- TODO: delete directory as well. 
		end
	end
end