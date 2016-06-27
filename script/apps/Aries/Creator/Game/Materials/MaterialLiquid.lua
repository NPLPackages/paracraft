--[[
Title: material
Author(s): LiXizhi
Date: 2013/12/1
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Materials/MaterialLiquid.lua");
local MaterialLiquid = commonlib.gettable("MyCompany.Aries.Game.Materials.MaterialLiquid");
MaterialLiquid:new()
-------------------------------------------------------
]]
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local MaterialLiquid = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Materials.Material"), commonlib.gettable("MyCompany.Aries.Game.Materials.MaterialLiquid"));

function MaterialLiquid:ctor()
	self:setReplaceable();
    self:setNoPushMobility();
end

-- Returns if blocks of these materials are liquids.
function MaterialLiquid:isLiquid()
    return true;
end

-- Returns if this material is considered solid or not
function MaterialLiquid:blocksMovement()
    return false;
end

function MaterialLiquid:isSolid()
    return false;
end

