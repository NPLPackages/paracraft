--[[
Title: Tick Entry Used in WorldSim
Author(s): LiXizhi
Date: 2012/12/1
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/TickEntry.lua");
local TickEntry = commonlib.gettable("MyCompany.Aries.Game.TickEntry")
local entry = TickEntry:new():Init(x,y,z,block_id, scheduledTime, priority);
-------------------------------------------------------
]]
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local block = commonlib.gettable("MyCompany.Aries.Game.block")

---------------------------
-- Tick Entry class
---------------------------
local TickEntry = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.TickEntry"));

local nextTickEntryID = 0;

-- x,y,z,block_id
function TickEntry:ctor()
	nextTickEntryID = nextTickEntryID + 1;
	self.tickEntryID = nextTickEntryID;
end

function TickEntry:Init(x,y,z,block_id, scheduledTime, priority)
	self.x = x;
	self.y = y;
	self.z = z;
	self.block_id = block_id;
	self.scheduledTime = scheduledTime;
	self.priority = priority;
	return self;
end

function TickEntry:equals(other)
    return self.x == other.x and self.y == other.y and self.z == other.z and block_types.IsAssociatedBlockID(self.block_id, other.block_id);
end    

function TickEntry:GetHashCode()
	if(not self.hash_code) then
		self.hash_code = self:hashCode();
	end
	return self.hash_code;
end

function TickEntry:IsBlock(x,y,z)
	return self.x == x and self.y==y and self.z==z;
end

-- static function:
function TickEntry.GetHashCodeFrom(x,y,z)
	return (x * 1024 * 1024 + z * 1024 + y);
end

function TickEntry:hashCode()
	return (self.x * 1024 * 1024 + self.z * 1024 + self.y);
end    

function TickEntry:SetScheduledTime(scheduledTime)
	self.scheduledTime = scheduledTime;
end

function TickEntry:setPriority(priority)
    self.priority = priority;
end

-- Compares this tick entry to another tick entry for sorting purposes. Compared first based on the scheduled time
-- and second based on tickEntryID.
function TickEntry:compare(other)
	if(self.scheduledTime < other.scheduledTime) then
		return -1;
	elseif(self.scheduledTime > other.scheduledTime) then
		return 1;
	elseif(self.priority ~= other.priority) then
		return self.priority - other.priority;
	elseif(self.tickEntryID < other.tickEntryID) then
		return -1
	elseif(self.tickEntryID > other.tickEntryID) then
		return 1
	else
		return 0;
	end
end

function TickEntry:__tostring()
    return self.blockID + ": (" + self.x + ", " + self.y + ", " + self.z + "), " + self.scheduledTime + ", " + self.priority + ", " + self.tickEntryID;
end
