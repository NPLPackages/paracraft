--[[
Title: ItemUserPoint
Author(s): LiXizhi
Date: 2025/11/3
Desc: User point item that inherits from ItemLiveModel
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemUserPoint.lua");
local ItemUserPoint = commonlib.gettable("MyCompany.Aries.Game.Items.ItemUserPoint");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemLiveModel.lua");
local ItemLiveModel = commonlib.gettable("MyCompany.Aries.Game.Items.ItemLiveModel");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local ItemUserPoint = commonlib.inherit(ItemLiveModel, commonlib.gettable("MyCompany.Aries.Game.Items.ItemUserPoint"));

block_types.RegisterItemClass("ItemUserPoint", ItemUserPoint);

ItemUserPoint.CreateAtPlayerFeet = true;
ItemUserPoint.auto_equip = false;
ItemUserPoint.can_pick = false;

function ItemUserPoint:ctor()
	ItemUserPoint._super.ctor(self);

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
function ItemUserPoint:OnUse()
end

-- virtual function: when selected in right hand
function ItemUserPoint:OnSelect()
	
end

-- virtual function: when deselected in right hand
function ItemUserPoint:OnDeSelect()
end

-- virtual function:
-- @param result: picking result. {side, blockX, blockY, blockZ}
-- @return: return true if created
function ItemUserPoint:OnCreate(result)
	if(result.blockX) then
		local bx,by,bz = result.blockX,result.blockY,result.blockZ;
		if(not EntityManager.HasNonPlayerEntityInBlock(bx,by,bz)) then 
			if(GameLogic.isRemote) then
				local clientMP = EntityManager.GetPlayer();
				if(clientMP and clientMP.AddToSendQueue) then
					local x, y, z = BlockEngine:real_bottom(bx,by,bz);
					clientMP:AddToSendQueue(Packets.PacketEntityMobSpawn:new():Init({x=x,y=y,z=z, item_id = self.block_id}, 14));
					return true;
				end
			else
				-- ignore it if there is already an entity there. 
				local entity_class = EntityManager.GetEntityClass(self.entity_class or "EntityUserPoint");
				if(entity_class) then
					local entity = entity_class:Create({bx=bx,by=by,bz=bz, item_id = self.block_id, name = self.name});
					if(entity) then
						entity:Attach();

                        -- add to history command
                        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DragEntityTask.lua");
                        local task = MyCompany.Aries.Game.Tasks.DragEntity:new({})
                        task:CreateEntity(entity);
                        
						return true;
					end
				end
			end
		end
	end
end

-- called every frame
function ItemUserPoint:OnObtain()
end