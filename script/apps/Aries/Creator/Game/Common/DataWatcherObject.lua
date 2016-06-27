--[[
Title: DataWatcherObject
Author(s): LiXizhi
Date: 2014/7/14
Desc: used for tracking modified data fields between ticks. Each data has a small integer key and a string key. 
-----------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/DataWatcherObject.lua");
local DataWatcherObject = commonlib.gettable("MyCompany.Aries.Game.Common.DataWatcherObject");
local data = DataWatcherObject:new():Init(id, datavalue);
----------------------------------------------
]]
local DataWatcherObject = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Common.DataWatcherObject"))

function DataWatcherObject:ctor()
end

function DataWatcherObject:Init(id, dataObj)
	self.dataValueId = id;
    self.watchedObject = dataObj;
    self.watched = true;
	return self;
end

function DataWatcherObject:GetId()
	return self.dataValueId;
end

function DataWatcherObject:IsWatched()
    return self.watched;
end

function DataWatcherObject:SetWatched(bWatched)
    self.watched = bWatched;
end

-- get the object value. 
function DataWatcherObject:GetObject()
	return self.watchedObject;
end

function DataWatcherObject:SetObject(obj)
	self.watchedObject = obj;
end

function DataWatcherObject:UpdateObject(obj)
	if(obj ~= self.watchedObject) then
		self.watchedObject = obj;
		self.watched = true;
	end
end


