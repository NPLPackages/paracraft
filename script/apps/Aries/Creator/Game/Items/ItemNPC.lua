--[[
Title: NPC item 
Author(s): LiXizhi
Date: 2013/11/28
Desc: mob is a hostile NPC that may attack you in real time or in a arena battle field. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemMob.lua");
local ItemNPC = commonlib.gettable("MyCompany.Aries.Game.Items.ItemNPC");
local item_ = ItemNPC:new({block_id, text, icon, tooltip, max_count, scaling, filename, gold_count, hp, respawn_time});
-------------------------------------------------------
]]
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
local ItemNPC = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.Item"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemNPC"));

block_types.RegisterItemClass("ItemNPC", ItemNPC);

-- health point
ItemNPC.hp = 100;
-- respawn in 300 000 ms. 
ItemNPC.respawn_time = 300*1000;

ItemNPC.CreateAtPlayerFeet = true;

function ItemNPC:ctor()
	self.hp = tonumber(self.hp);
	self.respawn_time = tonumber(self.respawn_time);
end

function ItemNPC:HasFacing()
	return true;
end


-- virtual function: use the item. 
function ItemNPC:OnUse()
end

-- virtual function: when selected in right hand
function ItemNPC:OnSelect()
	
end

-- virtual function: when deselected in right hand
function ItemNPC:OnDeSelect()
	
end

function ItemNPC:CanSpawn()
	return true;
end

-- called every frame
function ItemNPC:FrameMove(deltaTime)
end

-- virtual: convert entity to item stack. 
-- such as when alt key is pressed to pick a entity in edit mode. 
function ItemNPC:ConvertEntityToItem(entity)
	if(entity) then
		return ItemStack:new():Init(self.id, 1, entity:SaveToXMLNode());
	end
end

-- whether we can create item at given block position.
function ItemNPC:CanCreateItemAt(x,y,z)
	if(ItemNPC._super.CanCreateItemAt(self, x,y,z)) then
		if(not EntityManager.HasNonPlayerEntityInBlock(x,y,z) and not EntityManager.HasNonPlayerEntityInBlock(x,y+1,z)) then
			return true;
		end
	end
end

-- virtual function:
-- @param result: picking result. {side, blockX, blockY, blockZ}
-- @return bUsed, entityCreated: return true if created
function ItemNPC:OnCreate(result)
	if(result.blockX) then
		local bx,by,bz = result.blockX,result.blockY,result.blockZ;
		
		if(GameLogic.isRemote) then
			-- GameLogic.AddBBS("warn", L"目前只有Server可以创建此类物品", 4000, "255 0 0")
			-- send creation request packet to server
			local clientMP = EntityManager.GetPlayer();
			if(clientMP and clientMP.AddToSendQueue) then
				local x, y, z = BlockEngine:real_bottom(bx,by,bz);
				clientMP:AddToSendQueue(Packets.PacketEntityMobSpawn:new():Init({x=x,y=y,z=z, item_id = self.block_id}, 12));
				return true;
			end
			return;
		end

		if(self:CanCreateItemAt(bx,by,bz)) then 
			local xmlSavedNode; 
			if(result.itemStack) then
				xmlSavedNode = result.itemStack.serverdata;
			end
			-- ignore it if there is already an entity there. 
			local entity = MyCompany.Aries.Game.EntityManager.EntityNPC:Create({bx=bx,by=by,bz=bz, 
				item_id = self.block_id, facing=result.facing, can_random_move = false}, 
				xmlSavedNode);

			-- can not be pushed by other NPC
			-- entity:SetStaticBlocker(true);
			-- entity:SetDummy(true);
			-- entity:SetFacing(1.5);
			EntityManager.AddObject(entity);

			return true, entity;
		end
	end
end
