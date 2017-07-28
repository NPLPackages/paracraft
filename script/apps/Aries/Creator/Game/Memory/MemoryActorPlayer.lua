--[[
Title: Memory Actor Player
Author(s): LiXizhi
Date: 2017/6/2
Desc: Memory actor that is the host itself. 

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/MemoryActorPlayer.lua");
local MemoryActorPlayer = commonlib.gettable("MyCompany.Aries.Game.Memory.MemoryActorPlayer");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/MemoryActorNPC.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local MemoryActorPlayer = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Memory.MemoryActorNPC"), commonlib.gettable("MyCompany.Aries.Game.Memory.MemoryActorPlayer"));
MemoryActorPlayer:Property("Name", "MemoryActorPlayer");

function MemoryActorPlayer:ctor()
end

-- called every framemove. 
-- @param deltaTime: in millisecond ticks
function MemoryActorPlayer:FrameMove(deltaTime)
end
