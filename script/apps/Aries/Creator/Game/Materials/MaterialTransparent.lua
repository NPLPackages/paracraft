--[[
Title: material
Author(s): LiXizhi
Date: 2013/12/1
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Materials/MaterialTransparent.lua");
local MaterialTransparent = commonlib.gettable("MyCompany.Aries.Game.Materials.MaterialTransparent");
MaterialTransparent:new()
-------------------------------------------------------
]]
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local MaterialTransparent = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Materials.Material"), commonlib.gettable("MyCompany.Aries.Game.Materials.MaterialTransparent"));

function MaterialTransparent:ctor()
	self:setReplaceable();
end

-- Returns if blocks of these materials are liquids.
function MaterialTransparent:isLiquid()
    return false;
end

-- Will prevent grass from growing on dirt underneath and kill any grass below it if it returns true
function MaterialTransparent:getCanBlockGrass()
    return false;
end

-- Returns if this material is considered solid or not
function MaterialTransparent:blocksMovement()
    return false;
end

