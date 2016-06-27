--[[
Title: DataWatcher
Author(s): LiXizhi
Date: 2014/7/14
Desc: used for tracking modified data fields between ticks. Each data has a small integer key and a string key. 
-----------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/DataWatcher.lua");
local DataWatcher = commonlib.gettable("MyCompany.Aries.Game.Common.DataWatcher");
local dataWatcher = DataWatcher:new();
dataWatcher:AddField(1, nil)
dataWatcher:SetField(1, "value")
echo(dataWatcher:GetField(1) == "value")
----------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/DataWatcherObject.lua");
local DataWatcherObject = commonlib.gettable("MyCompany.Aries.Game.Common.DataWatcherObject");
local DataWatcher = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Common.DataWatcher"))

-- true if one or more object was changed 
DataWatcher.objectChanged = nil;
-- When isBlank is true the DataWatcher is not watching any objects 
DataWatcher.isBlank = true;
DataWatcher.nextId = 1;

function DataWatcher:ctor()
	-- mapping from data field id to DataWatcherObject objects
	self.watchedObjects = {};
end

-- @param id: number or string key. if nil, the id will be generated and returned. 
-- @param initial_value: can be nil.
-- @return id
function DataWatcher:AddField(id, initial_value)
	if(not id) then
		id = self.nextId;
		self.nextId = self.nextId + 1;
	end
	self.watchedObjects[id] = DataWatcherObject:new():Init(id, initial_value);
	return id;
end

-- get datawatcherobject by id. 
function DataWatcher:GetObject(id)
	return self.watchedObjects[id];
end

-- get field value by id
function DataWatcher:GetField(id)
	local obj = self:GetObject(id);
	if(obj) then
		return obj:GetObject();
	end
end

-- updates an already existing object
function DataWatcher:SetField(id, value)
    local obj = self:GetObject(id);

    if (obj and obj:GetObject() ~= value) then
		obj:SetObject(value);
		obj:SetWatched(true);
		self.objectChanged = true;
    end
end

function DataWatcher:HasChanges()
    return self.objectChanged;
end

-- call this function between ticks to send changed data to network, etc. 
function DataWatcher:UnwatchAndReturnAllWatched()
    local listObj;

    if (self.objectChanged) then
        local id, obj = next(self.watchedObjects, nil);
        while (id) do
            if (obj:IsWatched()) then
                obj:SetWatched(false);
				listObj = listObj or {};
                listObj[#listObj+1] = obj;
            end
			id, obj = next(self.watchedObjects, id);
        end
    end

    self.objectChanged = false;
    return listObj;
end

-- return all objects (including both watched and unwatched) in a list. 
function DataWatcher:GetAllObjectList()
    local listObj;
    
	local id, obj = next(self.watchedObjects, nil);
	if(id) then
		listObj = {};
		while (id) do
			listObj[#listObj+1] = obj;
			id, obj = next(self.watchedObjects, id);
		end
	end
    return listObj;
end

-- static function: read data from pure data (from network packet) and return a list of WatchebleObject. 
function DataWatcher.ReadWatchebleObjects(data)
    local listObj;
	if(data and #data>0) then
		listObj = {}; 
		for i=1, #data do
			local obj = data[i]
			listObj[#listObj+1] = DataWatcherObject:new():Init(obj[1], obj[2]);
		end
	end
    return listObj;
end

-- @param data: this is the output data table. 
function DataWatcher:WriteWatchebleObjects(data)
    local id, obj = next(self.watchedObjects, nil);
	if(id) then
		while (id) do
			DataWatcher.WriteWatchebleObject(data, obj);
			id, obj = next(self.watchedObjects, id);
		end
	end
end

-- static function: write watcher object to data for network transmission.   
function DataWatcher.WriteWatchebleObject(data, watcherObj)
	data[#data+1] = {watcherObj:GetId(), watcherObj:GetObject()};
end

-- static function: writes every object in passed list to data output table
-- @param data: a input/output data table. if nil, a new table will be created if there is data. 
-- @return the data object
function DataWatcher.WriteObjectsInListToData(listObj, data)
	if(listObj) then
		data = data or {};
		for i=1, #listObj do
			DataWatcher.WriteWatchebleObject(data, listObj[i]);
		end
	end
	return data;
end

-- @param listObj: array of DataWatcherObject. 
function DataWatcher:UpdateWatchedObjectsFromList(listObj)
	if(listObj) then
		for i=1, #listObj do
			local from_obj = listObj[i];
			local to_obj = self.watchedObjects[from_obj:GetId()];

			if (to_obj) then
				to_obj:UpdateObject(from_obj:GetObject());
			end
		end
		self.objectChanged = true;
	end
end

