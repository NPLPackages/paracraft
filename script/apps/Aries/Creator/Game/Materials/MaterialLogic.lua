--[[
Title: material
Author(s): LiXizhi
Date: 2013/12/1
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Materials/MaterialLogic.lua");
local MaterialLogic = commonlib.gettable("MyCompany.Aries.Game.Materials.MaterialLogic");
MaterialLogic:new()
-------------------------------------------------------
]]
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local MaterialLogic = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Materials.Material"), commonlib.gettable("MyCompany.Aries.Game.Materials.MaterialLogic"));

function MaterialLogic:ctor()
	self:setAdventureModeExempt();
end

-- Returns if blocks of these materials are liquids.
function MaterialLogic:isLiquid()
    return false;
end

-- Will prevent grass from growing on dirt underneath and kill any grass below it if it returns true
function MaterialLogic:getCanBlockGrass()
    return false;
end

-- Returns if this material is considered solid or not
function MaterialLogic:blocksMovement()
    return false;
end

