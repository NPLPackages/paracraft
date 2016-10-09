--[[
Title: testing web cache db
Author(s): LiXizhi
Date: 2008/2/21
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/test/test_webcachedb.lua");
test.test_entries_db()
test.test_versions_db()
test.test_servers_db()
test.test_permissions()
test.test_Payload()
test.test_CreateOrUpgradeDatabase()
-------------------------------------------------------
]]

NPL.load("(gl)script/kids/3DMapSystemApp/localserver/WebCacheDB.lua");

if(not test) then test ={} end
-- passed by LiXizhi 2008.2.21
function test.test_CreateOrUpgradeDatabase()
	local webDB = Map3DSystem.localserver.WebCacheDB.GetDB()
	
	webDB:CreateOrUpgradeDatabase();
end

-- passed by LiXizhi 2008.2.24
function test.test_Payload()
	local webDB = Map3DSystem.localserver.WebCacheDB.GetDB()
	
	log("test InsertPayload\n")
	-- test insert NOT found payload
	local payload = webDB.PayloadInfo:new({
		status_code = 0,
		cached_filepath = "temp/test.xml",
	});
	webDB:InsertPayload(0, "http://www.paraengine.com/", payload)
	log(commonlib.serialize(payload));
	
	-- test insert HTTP_OK payload
	payload = webDB.PayloadInfo:new({
		status_code = Map3DSystem.localserver.HttpConstants.HTTP_OK,
		cached_filepath = "temp/test2.xml",
	});
	webDB:InsertPayload(0, "http://www.paraengine.com/", payload)
	log(commonlib.serialize(payload));
	
	log("test FindPayload \n")
	-- find payload
	local p1 = webDB:FindPayload(payload.id, false);
	log(commonlib.serialize(p1));
	local p2 = webDB:FindPayload(payload.id, true);
	log(commonlib.serialize(p2));
end

-- passed by LiXizhi 2008.2.24
function test.test_permissions()
	local webDB = Map3DSystem.localserver.WebCacheDB.GetDB()
	log("testing IsOriginAllowed: \n");
	
	local testcases = {
		"http://www.paraengine.com/get.asmx",
		"www.paraengine.com/get.asmx",
		"file://www.paraengine.com/get.asmx",
		"https://www.paraengine.com/get.asmx",
	}
	local i, case
	for i, case in ipairs(testcases) do
		log("case: "..case.."\n")
		if(webDB:IsOriginAllowed(case)) then
			log("TRUE\n")
		else
			log("FALSE\n")
		end
	end
end

-- passed by LiXizhi 2008.2.24
function test.test_servers_db()
	local webDB = Map3DSystem.localserver.WebCacheDB.GetDB()
	
	log("test InsertServer\n")
	-- insert server
	local server = webDB.ServerInfo:new({
		name = "TestApp",
		security_origin_url = "http://www.paraengine.com",
	});
	webDB:InsertServer(server)
	log(commonlib.serialize(server));

		-- update server
		log("test update server enabled \n")
		webDB:UpdateServer(server.id, false);
		-- update server
		log("test update server UpdateServer_manifest_url \n")
		webDB:UpdateServer(server.id, "manifest_url updated");
		-- update server
		log("test update server UpdateServer_status \n")
		webDB:UpdateServer(server.id, 1, 3);
		-- update server
		log("test update server UpdateServer_status \n")
		webDB:UpdateServer(server.id, 2, 4, "header", "error message");
		
	-- find server by id
	log("test find server by id. \n")
	local p1 = webDB:FindServer(server.id);
	log(commonlib.serialize(p1));
		
	
	-- find server by name and others. 
	log("test find server by name and others. \n")
	local p1 = webDB:FindServer(nil, nil, server.security_origin_url, server.name, server.required_cookie or "", server.server_type);
	log(commonlib.serialize(p1));
	
	-- find server list by origin. 
	log("test FindServersForOrigin\n")
	local servers = webDB:FindServersForOrigin(server.security_origin_url);
	log(commonlib.serialize(servers));
	
	--test delete server
	log("test DeleteServersForOrigin\n")
	webDB:DeleteServersForOrigin(server.security_origin_url);
	
	-- find server by id
	log("test delete result by id. Should return nil\n")
	local p1 = webDB:FindServer(server.id);
	log(commonlib.serialize(p1));
end

-- passed by LiXizhi 2008.2.25
function test.test_versions_db()
	local webDB = Map3DSystem.localserver.WebCacheDB.GetDB()
	
	log("test InsertVersion\n")
	-- insert version
	local version = webDB.VersionInfo:new({
		server_id = 10,
		version_string = "1.0",
	});
	webDB:InsertVersion(version)
	
	version.version_string = "2.0";
	webDB:InsertVersion(version)
	-- update version
	log("test update version by ready state\n")
	local p1= webDB:UpdateVersion(version.id, 1);
	log(commonlib.serialize(p1));
		
	-- find version by id
	log("test find version by server id. \n")
	local p1 = webDB:FindVersion(version.server_id, 0);
	log(commonlib.serialize(p1));
		
	-- find version by version_string
	log("test find version version_string \n")
	local p1 = webDB:FindVersion(version.server_id, version.version_string);
	log(commonlib.serialize(p1));
	
	-- find version by server id
	log("test find array of versions by server id\n")
	local p1 = webDB:FindVersions(version.server_id);
	log(commonlib.serialize(p1));
	
	--test delete versions
	log("test delete versions \n")
	webDB:DeleteVersions(version.server_id);
end

-- passed by LiXizhi 2008.2.25
function test.test_entries_db()
	local webDB = Map3DSystem.localserver.WebCacheDB.GetDB()
	
	log("test InsertEntry\n")
	-- insert entries without payload
	local entry = webDB.EntryInfo:new({
		url = "http://www.paraengine.com/image.jpg",
		version_id = 10,
	});
	webDB:InsertEntry(entry)
	
	-- insert payload
	local payload = webDB.PayloadInfo:new({
		status_code = Map3DSystem.localserver.HttpConstants.HTTP_OK,
		cached_filepath = "temp/test2.xml",
	});
	webDB:InsertPayload(0, "http://www.paraengine.com/", payload)
	
	-- insert entry referencing the payload
	local entry = webDB.EntryInfo:new({
		url = "http://www.paraengine.com/image.jpg",
		payload_id = payload.id,
		version_id = 10,
	});
	webDB:InsertEntry(entry)
	
	-- find entry by id
	log("test find entry for the given version_id and url \n")
	local p1 = webDB:FindEntry(entry.version_id, entry.url);
	log(commonlib.serialize(p1));
	
	-- update entries url. 
	log("test update entries url. \n")
	local p1 = webDB:UpdateEntry(entry.version_id, entry.url, "http://www.paraengine.com/NewURL.jpg")
	log(commonlib.serialize(p1));
		
	-- find entry by FindEntriesHavingNoResponse
	log("test find FindEntriesHavingNoResponse \n")
	local p1 = webDB:FindEntriesHavingNoResponse(entry.version_id);
	log(commonlib.serialize(p1));
	
	-- count entries
	log("test count entries \n")
	local p1 = webDB:CountEntries(entry.version_id);
	log(commonlib.serialize(p1));
	
	--test delete entries
	log("test delete DeleteEntry \n")
	webDB:DeleteEntry(entry.id);
	
	log("test delete DeleteEntries by version id \n")
	webDB:DeleteEntries(entry.version_id);
end