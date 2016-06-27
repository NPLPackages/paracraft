--[[
Title: Item Star 
Author(s): LiXizhi
Date: 2013/7/14
Desc: any type of collectables that can convert to gold coin. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemCollectable.lua");
local ItemCollectable = commonlib.gettable("MyCompany.Aries.Game.Items.ItemCollectable");
local item_ = ItemCollectable:new({block_id, text, icon, tooltip, max_count, scaling, filename, gold_count, name[optional, global name]});
-------------------------------------------------------
]]
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local ItemCollectable = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.Item"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemCollectable"));

block_types.RegisterItemClass("ItemCollectable", ItemCollectable);

ItemCollectable.CreateAtPlayerFeet = true;
ItemCollectable.auto_equip = false;
ItemCollectable.can_pick = true;

function ItemCollectable:ctor()
	if(type(self.can_pick) == "string") then
		self.can_pick = self.can_pick == "true";
	end
	if(type(self.auto_equip) == "string") then
		self.auto_equip = self.auto_equip == "true";
	end
	if(type(self.CreateAtPlayerFeet) == "string") then
		self.CreateAtPlayerFeet = self.CreateAtPlayerFeet == "true";
	end
end

-- virtual function: use the item. 
function ItemCollectable:OnUse()
end

-- virtual function: when selected in right hand
function ItemCollectable:OnSelect()
	
end

-- virtual function: when deselected in right hand
function ItemCollectable:OnDeSelect()
	
end

-- virtual function:
-- @param result: picking result. {side, blockX, blockY, blockZ}
-- @return: return true if created
function ItemCollectable:OnCreate(result)
	if(result.blockX) then
		local bx,by,bz = result.blockX,result.blockY,result.blockZ;
		if(not EntityManager.HasNonPlayerEntityInBlock(bx,by,bz)) then 
			-- ignore it if there is already an entity there. 
			local entity_class = EntityManager.GetEntityClass(self.entity_class or "collectable")
			if(entity_class) then
				local entity = entity_class:Create({bx=bx,by=by,bz=bz, item_id = self.block_id, name = self.name});
				EntityManager.AddObject(entity)
			end
		end
	end
end

-- called every frame
function ItemCollectable:OnObtain()
end