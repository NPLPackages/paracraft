--[[
Title: time series is a group of variables
Author(s): LiXizhi
Date: 2014/3/16
Desc: time series can have child time series. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/TimeSeries.lua");
local TimeSeries = commonlib.gettable("MyCompany.Aries.Game.Common.TimeSeries");
local ts = TimeSeries:new();
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/TimeSeries/AnimBlock.lua");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local AnimBlock = commonlib.gettable("AnimBlock");

local type = type;

local TimeSeries = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Common.TimeSeries"));

function TimeSeries:ctor()
	self.data = {};
	self.key_array = {};
	self.key_index_map = {};
end

-- load time series from a given file or table. It does not clear existing ones in the current time series, but will overwrite if name are the same as in the file. 
-- @param filename: data or the filename
function TimeSeries:LoadFromTable(data)
	if(not data) then
		return;
	end
	self.children = nil;
	self.data = data;
	
	for varName, v in pairs(data) do
		if(type(v) == "table") then
			if(v.isContainer) then
				self.children = self.children or {};
				local child = TimeSeries:new();
				child:LoadFromTable(v);
				self.children[varName] = child;
			else
				self:CreateVariable(v);
			end
		end
	end
end

-- get child timeseries
function TimeSeries:GetChild(name)
	if(self.children) then
		return self.children[name];
	end
end

-- remove a child time series object. 
function TimeSeries:RemoveChild(name)
	local child = self:GetChild(name)
	if(child) then
		self.children[name] = nil;
		self.data[name] = nil;
	end
end

-- create child timeseries
function TimeSeries:CreateChild(name)
	local child = self:GetChild(name);
	if(child) then
		return child;
	end
	self.children = self.children or {};
	local child = TimeSeries:new();
	local data = {isContainer = true, };
	child:LoadFromTable(data);
	self.data[name] = data;
	self.children[name] = child;
	return child;
end

-- save time series to a given file. 
-- @param filename: the filename 
function TimeSeries:GetData()
	return self.data;
end

-- Applies to all variables: trim end, so that there are no time value that is smaller than time.
function TimeSeries:TrimEnd(time)
	for k,v in pairs(self.data) do
		if(type(v) == "table" and v.tableType == "AnimBlock") then
			v:TrimEnd(time);
		end	
	end
end

-- shifting keyframes from shift_begin_time to end by the amount of offset_time. 
function TimeSeries:ShiftKeyFrame(shift_begin_time, offset_time)
	for k,v in pairs(self.data) do
		if(type(v) == "table" and v.tableType == "AnimBlock") then
			v:ShiftKeyFrame(shift_begin_time, offset_time);
		end	
	end
end

-- remove the key frame at key_time if there is a key frame. 
function TimeSeries:RemoveKeyFrame(keytime)
	for k,v in pairs(self.data) do
		if(type(v) == "table" and v.tableType == "AnimBlock") then
			v:RemoveKeyFrame(keytime);
		end	
	end
end

-- copy keyframe from from_keytime to keytime
function TimeSeries:CopyKeyFrame(keytime, from_keytime)
	for k,v in pairs(self.data) do
		if(type(v) == "table" and v.tableType == "AnimBlock") then
			v:CopyKeyFrame(keytime, from_keytime);
		end	
	end
end

-- move keyframe from from_keytime to keytime
function TimeSeries:MoveKeyFrame(keytime, from_keytime)
	for k,v in pairs(self.data) do
		if(type(v) == "table" and v.tableType == "AnimBlock") then
			v:MoveKeyFrame(keytime, from_keytime);
		end	
	end
end

-- remove all keys in the [fromTime, toTime]
function TimeSeries:RemoveKeysInTimeRange(fromTime, toTime)
	for k,v in pairs(self.data) do
		if(type(v) == "table" and v.tableType == "AnimBlock") then
			v:RemoveKeysInTimeRange(fromTime, toTime);
		end	
	end
end

-- add a new variable to the time series. It there is an existing variable, the old one will be replaced. 
-- @param params: {name="", type="Linear"|"Discrete"}. It is actually passed to the new function of AnimBlock. More info see AnimBlock. 
function TimeSeries:CreateVariable(params)
	if(params.name == nil) then return end
	self.data[params.name] = AnimBlock:new(params);
	self.key_array[#(self.key_array)+1] = params.name;
	self.key_index_map[params.name] = #(self.key_array);
end

function TimeSeries:CreateVariableIfNotExist(name, type_)
	if(not self.data[name]) then
		self.data[name] = AnimBlock:new({name=name, type=type_});
		self.key_array[#(self.key_array)+1] = name;
		self.key_index_map[name] = #(self.key_array);
	end
	return self.data[name];
end

-- remove variable, the internal key index of child variables after the removed one may be changed
function TimeSeries:RemoveVariable(name)
	local var = self:GetVariable(name)
	if(var) then
		self.data[name] = nil;
		local lastIndex = self.key_index_map[name];
		commonlib.removeArrayItem(self.key_array, lastIndex);
		self.key_index_map[name] = nil;
		for i=lastIndex, #(self.key_array) do
			self.key_index_map[self.key_array[i]] = i;
		end
	end
end

-- get timeseries variable.
function TimeSeries:GetVariable(name)
	if(self.key_index_map[name]) then
		return self.data[name];
	end
end

function TimeSeries:GetVariableCount()
	return #(self.key_array);
end

function TimeSeries:GetVariableName(nIndex)
	return self.key_array[nIndex];
end

function TimeSeries:GetVariableByIndex(nIndex)
	local name = self:GetVariableName(nIndex);
	if(name) then
		return self:GetVariable(name);
	end
end

function TimeSeries:GetVariableIndex(name)
	return self.key_index_map[name];
end

-- @param varName: variable name
-- @param animID: range index
function TimeSeries:GetStartFrame(varName, animID)
	local timesID = self.data[varName].ranges[animID][1];
	return self.data[varName].times[timesID];
end

-- @param varName: variable name
-- @param animID: range index
function TimeSeries:GetEndFrame(varName, animID)
	local timesID = self.data[varName].ranges[animID][2];
	return self.data[varName].times[timesID];
end
