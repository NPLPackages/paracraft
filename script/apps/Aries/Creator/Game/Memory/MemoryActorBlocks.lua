--[[
Title: Memory Actor Blocks
Author(s): LiXizhi
Date: 2017/6/2
Desc: It is a type of static actor with blocks (matching for static scenes)

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/MemoryActorBlocks.lua");
local MemoryActorBlocks = commonlib.gettable("MyCompany.Aries.Game.Memory.MemoryActorBlocks");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/MemoryActor.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local MemoryActorBlocks = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Memory.MemoryActor"), commonlib.gettable("MyCompany.Aries.Game.Memory.MemoryActorBlocks"));
MemoryActorBlocks:Property("Name", "MemoryActorBlocks");

function MemoryActorBlocks:ctor()
end

-- called when enter block world. 
function MemoryActorBlocks:Init()
end

function MemoryActorBlocks:Reset()
end

-- called every framemove. 
-- @param deltaTime: in millisecond ticks
function MemoryActorBlocks:FrameMove(deltaTime)
end
