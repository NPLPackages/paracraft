--[[
Title: Mob item 
Author(s): LiXizhi
Date: 2013/7/28
Desc: mob is a hostile NPC that may attack you in real time or in a arena battle field. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemMob.lua");
local ItemMob = commonlib.gettable("MyCompany.Aries.Game.Items.ItemMob");
local item_ = ItemMob:new({block_id, text, icon, tooltip, max_count, scaling, filename, gold_count, hp, respawn_time});
-------------------------------------------------------
]]
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local ItemMob = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.Item"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemMob"));

block_types.RegisterItemClass("ItemMob", ItemMob);

-- health point
ItemMob.hp = 100;
-- respawn in 300 000 ms. 
ItemMob.respawn_time = 300*1000;

ItemMob.CreateAtPlayerFeet = true;

function ItemMob:ctor()
	self.hp = tonumber(self.hp);
	self.respawn_time = tonumber(self.respawn_time);
end

-- virtual function: use the item. 
function ItemMob:OnUse()
end

-- virtual function: when selected in right hand
function ItemMob:OnSelect()
	
end

-- virtual function: when deselected in right hand
function ItemMob:OnDeSelect()
	
end

function ItemMob:CanSpawn()
	return true;
end

function ItemMob:CanPlaceOnSide(x,y,z,side, data, side_region, entityPlayer, itemStack)
    if (not EntityManager.HasNonPlayerEntityInBlock(x,y,z) and not BlockEngine:isBlockNormalCube(x,y,z)) then
        return true;
    end
end

-- virtual function:
-- @param result: picking result. {side, blockX, blockY, blockZ}
-- @return: return true if created
function ItemMob:OnCreate(result)
	if(result.blockX) then
		local bx,by,bz = result.blockX,result.blockY,result.blockZ;
		
		if(not EntityManager.HasNonPlayerEntityInBlock(bx,by,bz)) then 
			if(GameLogic.isRemote) then
				-- GameLogic.AddBBS("warn", L"目前只有Server可以创建此类物品", 4000, "255 0 0")
				local clientMP = EntityManager.GetPlayer();
				if(clientMP and clientMP.AddToSendQueue) then
					local x, y, z = BlockEngine:real_bottom(bx,by,bz);
					clientMP:AddToSendQueue(Packets.PacketEntityMobSpawn:new():Init({x=x,y=y,z=z, item_id = self.block_id}, 11));
					return true;
				end
				return;
			else
				-- ignore it if there is already an entity there. 
				local entity = MyCompany.Aries.Game.EntityManager.EntityMob:Create({bx=bx,by=by,bz=bz, item_id = self.block_id});
				EntityManager.AddObject(entity);
				return true;
			end
		end
	end
end

-- called every frame
function ItemMob:FrameMove(deltaTime)
end