--[[
Title: Memory Context
Author(s): LiXizhi
Date: 2017/5/19
Desc: Memory context of a given player entity. This is like the AI brain of the player entity. 
Memory is stored in memory clips which is a form of distributed data representation. 
Memory clips can be played in parallel but always in one direction.
EmotionContext is used to control the replay threshold of memory clips. Without emotion, working memory tends
to disappear until new input arrives. Emotion is the driving power when there is not much external inputs. 

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/MemoryContext.lua");
local MemoryContext = commonlib.gettable("MyCompany.Aries.Game.Memory.MemoryContext");
local context = MemoryContext:new():Init();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/PlayerContext.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/MemoryClip.lua");
local MemoryClip = commonlib.gettable("MyCompany.Aries.Game.Memory.MemoryClip");
local PlayerContext = commonlib.gettable("MyCompany.Aries.Game.Memory.PlayerContext");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local MemoryContext = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Memory.MemoryContext"));
MemoryContext:Property("Name", "MemoryContext");
-- show/hide memory vision in 3d scene mostly for debugging purposes
MemoryContext:Property({"visible", false, "IsVisible", "SetVisible"});

MemoryContext:Signal("activeMemoryClipChanged", function(clip) end);

function MemoryContext:ctor()
	-- clips that is being played
	self.active_clips = commonlib.UnorderedArraySet:new();
	-- working memory is memory that has just been played back into the virtual world
	-- it is sentient and ready to elicit other long term memory to become new memory. 
	self.working_memory = commonlib.UnorderedArraySet:new();
	-- mapping from 3d position key to all long term memory clips
	self.longterm_memory = {};
end

-- called when enter block world. 
function MemoryContext:Init(playerEntity)
	GameLogic:Connect("WorldUnloaded", self, self.Reset, "UniqueConnection")
	if(playerEntity) then
		self:SetPlayer(playerEntity);
	end
	return self;
end

function MemoryContext:GetPosIndex(bX, bY, bZ)
	return BlockEngine:GetSparseIndex(bX, bY, bZ);
end

-- add a memory clip to working memory set. 
function MemoryContext:AddToWorkingMemory(memoryClip)
	if(self.working_memory:contains(memoryClip)) then
		self.working_memory:removeByValue(memoryClip)
	end
	-- this ensures that the memory is at the last 
	self.working_memory:push_back(memoryClip);
end

-- add memory clip to long term memory
function MemoryContext:AddMemoryClip(bX, bY, bZ, memoryClip)
	self.longterm_memory[self:GetPosIndex(bX, bY, bZ)] = memoryClip;
end

function MemoryContext:CreateMemoryClip()
	return MemoryClip:new():Init(self);
end

-- get memory clip from long term memory
function MemoryContext:GetMemoryClip(bX, bY, bZ)
	local nIndex = self:GetPosIndex(bX, bY, bZ);
	return self.longterm_memory[nIndex];
end

function MemoryContext:Reset()
	self.active_clips:clear();
	self.working_memory:clear();
	self.longterm_memory = {};
	GameLogic:Disconnect("WorldUnloaded", self, self.Reset)
end

-- if there are active memory clips that is being played back into the working memory. work 
function MemoryContext:HasAttention()
	return not self.active_clips:empty();
end

-- set the host player entity that this memory manager belongs to 
function MemoryContext:SetPlayer(player_entity)
	self.player = player_entity;
end

-- get the host player
function MemoryContext:GetPlayer()
	return self.player;
end

-- update context from 3d scene into this context
function MemoryContext:UpdateContext()
	-- update player
	self:UpdatePlayerContext();
	-- update vision according to player position
	self:GetVisionContext():Update(self:GetPlayerContext());
	self:GetVisionContext():SetVisible(self:IsVisible());
end

function MemoryContext:UpdatePlayerContext()
	local ctx = self.playerContext;
	if(not ctx) then
		ctx = PlayerContext:new();
		self.playerContext = ctx;
	end
	ctx:Update(self:GetPlayer());
	return ctx;
end

function MemoryContext:GetPlayerContext()
	if(not self.playerContext) then
		self:UpdatePlayerContext();
	end
	return self.playerContext;
end

function MemoryContext:GetVisionContext()
	if(not self.visionContext) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/VisionContext.lua");
		local VisionContext = commonlib.gettable("MyCompany.Aries.Game.Memory.VisionContext");
		self.visionContext = VisionContext:new();
	end
	return self.visionContext;
end

-- only used for debugging to repeat the last working memory clip
function MemoryContext:ActivateRecentWorkingMemoryClip()
	local lastMemoryClip = self.working_memory:last();
	if(lastMemoryClip) then
		lastMemoryClip:Activate(self);
	end
end

-- show/hide debug draw
function MemoryContext:SetVisible(bVisible)
	self.visible = bVisible;
end

-- show/hide debug draw
function MemoryContext:IsVisible(bVisible)
	return self.visible;
end

-- called every framemove by the containing entity. 
-- @param deltaTime: in millisecond ticks
-- @return true if the entity is controlled by memory context
function MemoryContext:FrameMove(deltaTime)
	self:UpdateContext();
end
