--[[
Title: Memory Actor Camera
Author(s): LiXizhi
Date: 2017/6/2
Desc: It is a type of camera eye actor (for matching memory clips)
It is just for efficiency of matching algorithm because we always observe the world from an angle. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/MemoryActorCamera.lua");
local MemoryActorCamera = commonlib.gettable("MyCompany.Aries.Game.Memory.MemoryActorCamera");
-------------------------------------------------------
]]
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local MemoryActorCamera = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Memory.MemoryActor"), commonlib.gettable("MyCompany.Aries.Game.Memory.MemoryActorCamera"));
MemoryActorCamera:Property("Name", "MemoryActorCamera");

function MemoryActorCamera:ctor()
end

-- called when enter block world. 
function MemoryActorCamera:Init()
end

function MemoryActorCamera:Reset()
end

-- called every framemove. 
-- @param deltaTime: in millisecond ticks
function MemoryActorCamera:FrameMove(deltaTime)
end
