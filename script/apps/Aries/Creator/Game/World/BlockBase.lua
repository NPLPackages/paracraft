--[[
Title: Block Base
Author(s): LiXizhi
Date: 2013/8/27
Desc: 16*16(*256) block columns
-----------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/BlockBase.lua");
local BlockBase = commonlib.gettable("MyCompany.Aries.Game.World.BlockBase")
local StructBlock = commonlib.gettable("MyCompany.Aries.Game.World.StructBlock")
-----------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/UniversalCoords.lua");
local UniversalCoords = commonlib.gettable("MyCompany.Aries.Game.Common.UniversalCoords");

local tostring = tostring;
local format = format;
local type = type;
local BlockBase = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.World.BlockBase"))

---------------------------------------
-- BlockBase
---------------------------------------
function BlockBase:ctor()
end

---------------------------------------
-- StructBlock
---------------------------------------
local StructBlock = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.World.StructBlock"))

function StructBlock:ctor()
end

function StructBlock.FromPos(worldX, worldY, worldZ, blockId, world)
	return StructBlock:new({coords = UniversalCoords:new():FromWorld(worldX, worldY, worldZ), block_id = blockId,  world = world});
end

function StructBlock.FromCoord(coords, blockId, world)
	return StructBlock:new({coords = coords, block_id = blockId,  world = world});
end

StructBlock.Empty = StructBlock.FromPos(0,0,0,0);