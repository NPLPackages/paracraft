--[[
Title: block material
Author(s): LiXizhi
Date: 2013/12/1
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Materials/block_material.lua");
local Materials = commonlib.gettable("MyCompany.Aries.Game.Materials");
Materials.RegisterAllMaterials();
-------------------------------------------------------
]]
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local Materials = commonlib.gettable("MyCompany.Aries.Game.Materials");

-- base class
local Material = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Materials.Material"));

-- Indicates if the material is translucent
Material.isTranslucent = false
-- Determines whether blocks with this material can be "overwritten" by other blocks when placed - eg snow, vines
-- and tall grass.
Material.replaceable = false;

-- The color used to draw the blocks of this material on maps.
-- it is overriden by block level attribute. 
Material.materialMapColor = "#cccccc";

-- Determines if the material can be harvested without a tool (or with the wrong tool)
Material.requiresNoTool = true;

-- Mobility information flag. 0 indicates that this block is normal, 1 indicates that it can't push other blocks, 2
-- indicates that it can't be pushed.
Material.mobilityFlag = 0;

Material.isAdventureModeExempt = nil;

-- static function:
function Materials.RegisterAllMaterials()
	if(Material.water) then
		return;
	end
	NPL.load("(gl)script/apps/Aries/Creator/Game/Materials/LocalTextures.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Materials/MaterialLiquid.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Materials/MaterialLogic.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Materials/MaterialTransparent.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Materials/MaterialPortal.lua");

	-- TODO: add more
	Materials.air = Materials.MaterialTransparent:new():Init();
	Materials.default = Material:new():Init();
	Materials.grass = Material:new():Init():setNoPushMobility();
	Materials.wood = Material:new():Init();
	Materials.rock = Material:new():Init();
	Materials.iron = Material:new():Init();
	Materials.lava = Material:new():Init():setNoPushMobility();
	Materials.water = Materials.MaterialLiquid:new():Init();
	Materials.leaves = Material:new():Init();
	Materials.plants = Material:new():Init();
	Materials.vine = Material:new():Init();
	Materials.fire = Materials.MaterialTransparent:new():Init();
	Materials.sand = Material:new():Init();
	Materials.circuits = Materials.MaterialLogic:new():Init();
	Materials.glass = Material:new():Init();
	Materials.ice = Material:new():Init();
	Materials.snow = Material:new():Init();
	Materials.clay = Material:new():Init();
	Materials.portal = Material:new():Init();
	Materials.web = Material:new():Init();
	Materials.piston = Material:new():Init();
	Materials.cornergrass = Material:new():Init():setNoPushMobility();
	Materials.carpet = Material:new():Init():setReplaceable();
	Materials.glass_carpet = Material:new():Init():setReplaceable();
end

function Material:ctor()
	-- self.isTranslucent = false;
end


function Material:Init()
	return self;
end

-- Returns if blocks of these materials are liquids.
function Material:isLiquid()
    return false;
end

function Material:isSolid()
    return true;
end

-- Will prevent grass from growing on dirt underneath and kill any grass below it if it returns true
function Material:getCanBlockGrass()
    return true;
end

-- Returns if this material is considered solid or not
function Material:blocksMovement()
    return true;
end

-- Marks the material as translucent
function Material:setTranslucent()
    self.isTranslucent = true;
    return self;
end

-- Makes blocks with this material require the correct tool to be harvested.
function Material:setRequiresTool()
    self.requiresNoTool = false;
    return this;
end

-- Set the canBurn bool to True and return the current object.
function Material:setCanBurn()
    self.canBurn = true;
    return self;
end

-- Returns if the block can burn or not.
function Material:getCanBurn()
    return self.canBurn;
end

function Material:setReplaceable()
    self.replaceable = true;
    return self;
end

-- Returns whether the material can be replaced by other blocks when placed - eg snow, vines and tall grass.
function Material:isReplaceable()
    return self.replaceable;
end

-- Indicate if the material is opaque
function Material:isOpaque()
    if(self.isTranslucent) then
		return false
	else
		return self.blocksMovement();
	end
end

-- Returns true if the material can be harvested without a tool (or with the wrong tool)
function Material:isToolNotRequired()
    return self.requiresNoTool;
end

-- Returns the mobility information of the material, 0 = free, 1 = can't push but can move over, 2 = total
-- immobility and stop pistons.
function Material:getMaterialMobility()
    return self.mobilityFlag;
end

-- self type of material can't be pushed, but pistons can move over it.
function Material:setNoPushMobility()
    self.mobilityFlag = 1;
    return self;
end

-- self type of material can't be pushed, and pistons are blocked to move.
function Material:setImmovableMobility()
    self.mobilityFlag = 2;
    return self;
end

function Material:setAdventureModeExempt()
    self.isAdventureModeExempt = true;
    return self;
end

-- Returns true if blocks with self material can always be mined in adventure mode.
function Material:isAdventureModeExempt()
    return self.isAdventureModeExempt;
end