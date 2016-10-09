--[[
Title: helper functions of sql database. 
Author(s): LiXizhi
Date: 2008/2/21
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/sqldb_wrapper.lua");
Map3DSystem.localserver.SqlDb.DropAllObjects(_db)
local table = Map3DSystem.localserver.NameValueTable:new(_db, "MyTable");
table:MaybeCreateTable();
-------------------------------------------------------
]]

local SqlDb = {};
commonlib.setfield("Map3DSystem.localserver.SqlDb", SqlDb);

-- drop all tables in the given database. 
function SqlDb.DropAllObjects(_db)
	if(not _db) then return end
	
	-- use a transaction
	_db:exec("BEGIN")
		local tablenames = {};
		
		local row;
		for row in _db:rows("SELECT name FROM sqlite_master WHERE type = 'table'") do
			-- Some tables internal to sqlite may not be dropped, for example sqlite_sequence. We ignore this error.
			if(string.find(row.name, "^sqlite_sequence")) then
			else
				table.insert(tablenames, row.name);
			end
		end
		
		local _, name;
		for _, name in ipairs(tablenames) do
			_db:exec("DROP TABLE "..name);
			log("table: "..name.." is removed from db.\n")
		end
	_db:exec("END") -- commit changes
end

----------------------------
-- a table with just name value pairs. 
----------------------------
local NameValueTable = 
{
	-- A pointer to the SQLDatabase our table will be created in.
	_db, 
	-- The name of the table we will be storing name/value pairs in.
	table_name,
}
Map3DSystem.localserver.NameValueTable = NameValueTable;

-- Creates an instance for the specified database and table name.
function NameValueTable:new(db, table_name)
	local o = {_db = db, table_name = table_name }
	setmetatable(o, self)
	self.__index = self
	return o
end

-- Creates the table if it doesn't already exist.
function NameValueTable:MaybeCreateTable()
	-- No datatype on Value column -- we use SQLite's "manifest typing" to store
	-- values of different types in here.
	if(self._db and self.table_name) then
		local _, err = self._db:exec(string.format("CREATE TABLE IF NOT EXISTS %s (Name TEXT UNIQUE, Value) ", self.table_name))
		if(err) then
			log("warning: failed when creating namevalue table "..tostring(err).."\n")
		end
	end
end