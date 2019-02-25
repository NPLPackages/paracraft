--[[
Title: a container of multiple animblock
Author(s): LiXizhi
Date: 2014/8/7
Desc: It has the same interface of AnimBlock, except that it is a container or multiple variables.
mapping from key to values{value1, value2, ...}

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/MultiAnimBlock.lua");
local MultiAnimBlock = commonlib.gettable("MyCompany.Aries.Game.Common.MultiAnimBlock");
local anims = MultiAnimBlock:new();
anims:AddMultiAnimBlock(anim)
-------------------------------------------------------
]]
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");


local MultiAnimBlock = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Common.MultiAnimBlock"));

function MultiAnimBlock:ctor()
	self.variables = commonlib.OrderedArraySet:new();
end

function MultiAnimBlock:GetChild()
end

-- @param anim: the AnimBlock instance. 
function MultiAnimBlock:AddVariable(variable)
	self.variables:add(variable);
end

function MultiAnimBlock:GetVariable(nIndex)
	return self.variables[nIndex];
end

-- variable is returned as an array of individual variable value at the given time. 
function MultiAnimBlock:getValue(anim, time)
	local o = {};
	for i=1, #(self.variables) do
		o[i] = self.variables[i]:getValue(anim, time);
	end
	return o;
end

function MultiAnimBlock:AddKey(time, data)
	local res;
	for i=1, #(self.variables) do
		res = self.variables[i]:AddKey(time, data[i]) or res;
	end
	return res;
end

function  MultiAnimBlock:GetLastTime()
	local max_last_time = 0;
	for i=1, #(self.variables) do
		local last_time = self.variables[i]:GetLastTime();
		if(last_time and max_last_time < last_time) then
			max_last_time = last_time;
		end 
	end
	return max_last_time;
end

function MultiAnimBlock:MoveKeyFrame(key_time, from_keytime)
	for i=1, #(self.variables) do
		self.variables[i]:MoveKeyFrame(key_time, from_keytime);
	end
end

function MultiAnimBlock:CopyKeyFrame(key_time, from_keytime)
	for i=1, #(self.variables) do
		self.variables[i]:CopyKeyFrame(key_time, from_keytime);
	end
end

-- Update or insert (Upsert) a key frame at given time.
-- @param data: data is cloned before updating. 
function MultiAnimBlock:UpsertKeyFrame(key_time, data)
	for i=1, #(self.variables) do
		if(data[i]) then
			self.variables[i]:UpsertKeyFrame(key_time, data[i]);
		end
	end
end

function MultiAnimBlock:RemoveKeyFrame(key_time)
	for i=1, #(self.variables) do
		self.variables[i]:RemoveKeyFrame(key_time);
	end
end

function MultiAnimBlock:ShiftKeyFrame(shift_begin_time, offset_time)
	for i=1, #(self.variables) do
		self.variables[i]:ShiftKeyFrame(shift_begin_time, offset_time);
	end
end

function MultiAnimBlock:RemoveKeysInTimeRange(fromTime, toTime)
	for i=1, #(self.variables) do
		self.variables[i]:RemoveKeysInTimeRange(fromTime, toTime);
	end
end

-- paste all key frames between [fromTime, toTime] to time
function MultiAnimBlock:PasteKeyFramesInRange(time, fromTime, toTime)
	for i=1, #(self.variables) do
		self.variables[i]:PasteKeyFramesInRange(time, fromTime, toTime)
	end
end

function MultiAnimBlock:TrimEnd(time)
	for i=1, #(self.variables) do
		self.variables[i]:TrimEnd(time);
	end
end

-- iterator that returns, all (time, values) pairs between (TimeFrom, TimeTo].  
-- the iterator works fine when there are identical time keys in the animation, like times={0,1,1,2,2,2,3,4}.  for time keys in range (0,2], 1,1,2,2,2, are returned. 
function  MultiAnimBlock:GetKeys_Iter(anim, TimeFrom, TimeTo)
	local iters = {};
	for i=1, #(self.variables) do
		iters[i] = self.variables[i]:GetKeys_Iter(anim, TimeFrom, TimeTo);
	end
	local times = {};
	local values = {};
	local last_values = {};

	return function ()
		local count = #(self.variables);
		local min_time, min_index;
		for i=1, count do
			local iter = iters[i]
			if(iter) then
				local time = times[i];
				if(not time) then
					time, value = iter();
					if(time == nil) then
						iters[i] = nil;
						times[i] = nil;
						values[i] = nil;
					else
						times[i] = time;
						values[i] = value;
					end
				end
				if(time and (not min_time or time<min_time)) then
					min_time = time;
					min_index = i;
				end
			end
		end
		if(min_time) then
			for i=1, count do
				local time = times[i];
				if(time == min_time) then
					times[i] = nil;
					last_values[i] = values[i];
				end
			end
			return min_time, last_values;
		end
	end
end
