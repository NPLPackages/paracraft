--[[
Title: testing helper functions of sql database. 
Author(s): LiXizhi
Date: 2008/2/21
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/test/test_sqldb_wrapper.lua");
test_DropAllObjects()
-------------------------------------------------------
]]
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/sqldb_wrapper.lua");

-- create and return a test db. 
function CreateTestDB()
	local _db, err = sqlite3.open( "temp/test.db");
	if( _db ~= nil)then
		-- populate db with any data
		_db:exec([[
CREATE TABLE [apps] (
[listorder] INTEGER DEFAULT 0, 
[app_key] VARCHAR(128) NOT NULL, 
[name] VARCHAR, 
[version] VARCHAR, 
[url] VARCHAR, 
[author] VARCHAR, 
[lang] VARCHAR, 
[IP] VARCHAR, 
[packageList] VARCHAR, 
[onloadscript] VARCHAR, 
[callbackfunction] VARCHAR,
[UserAdded] INTEGER);

INSERT INTO apps VALUES (NULL, 'EditApps_GUID', 'EditApps', '1.0.0', 'http://www.paraengine.com/apps/EditApps_v1.zip', 'YourCompany', 'enUS', 'script/kids/3DMapSystemApp/EditApps/IP.xml', '', 'script/kids/3DMapSystemApp/EditApps/app_main.lua', 'Map3DSystem.App.EditApps.MSGProc', 1);				  
INSERT INTO apps VALUES (NULL, 'Map_GUID', 'Map', '1.0.0', 'http://www.paraengine.com/apps/Map_v1.zip', 'YourCompany', 'enUS', 'script/kids/3DMapSystemUI/Map/IP.xml', '', 'script/kids/3DMapSystemUI/Map/app_main.lua', 'Map3DSystem.App.Map.MSGProc', 1);
]])	

		log("a new test db created with some data\n");
	else
		log("error: creating test db. \n");
	end
	return _db
end

-- passed by LiXizhi 2008.2.21
function test_DropAllObjects()
	local _db = CreateTestDB();
	if(_db) then
		-- test drop all objects
		Map3DSystem.localserver.SqlDb.DropAllObjects(_db)
		_db:close();
	end
end