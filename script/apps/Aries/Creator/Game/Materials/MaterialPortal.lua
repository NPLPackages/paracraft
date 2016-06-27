--[[
Title: material
Author(s): LiXizhi
Date: 2013/12/1
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Materials/MaterialPortal.lua");
local MaterialPortal = commonlib.gettable("MyCompany.Aries.Game.Materials.MaterialPortal");
MaterialPortal:new()
-------------------------------------------------------
]]
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local MaterialPortal = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Materials.Material"), commonlib.gettable("MyCompany.Aries.Game.Materials.MaterialPortal"));

function MaterialPortal:ctor()
end

-- Returns if blocks of these materials are liquids.
function MaterialPortal:isLiquid()
    return false;
end

-- Will prevent grass from growing on dirt underneath and kill any grass below it if it returns true
function MaterialPortal:getCanBlockGrass()
    return false;
end

-- Returns if this material is considered solid or not
function MaterialPortal:blocksMovement()
    return false;
end

