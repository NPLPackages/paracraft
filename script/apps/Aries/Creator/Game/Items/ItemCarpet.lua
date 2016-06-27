--[[
Title: ItemCarpet
Author(s): LiXizhi
Date: 2015/10/16
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemCarpet.lua");
local ItemCarpet = commonlib.gettable("MyCompany.Aries.Game.Items.ItemCarpet");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/vector.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local ItemCarpet = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.Item"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemCarpet"));

block_types.RegisterItemClass("ItemCarpet", ItemCarpet);

local side_to_data = {[0] = 4, [1] = 3, [2] = 5, [3] = 1, [4] = 2, [5] = 0, } 
local data_to_side = {[0] = 5, [1] = 3, [2] = 4, [3] = 1, [4] = 0, [5] = 2, } 

local side_to_second_data = { [0]=1, [1]=0, [2]=3, [3]=2};

-- @param template: icon
-- @param radius: the half radius of the object. 
function ItemCarpet:ctor()
end

-- Right clicking in 3d world with the block in hand will trigger this function. 
-- Alias: OnUseItem;
-- @param itemStack: can be nil
-- @param entityPlayer: can be nil
-- @return isUsed: isUsed is true if something happens.
function ItemCarpet:TryCreate(itemStack, entityPlayer, x,y,z, side, data, side_region)
	if (itemStack and itemStack.count == 0) then
		return;
	elseif (entityPlayer and not entityPlayer:CanPlayerEdit(x,y,z, data, itemStack)) then
		return;
	elseif (self:CanPlaceOnSide(x,y,z,side, data, side_region, entityPlayer, itemStack)) then
		local last_block_id = BlockEngine:GetBlockId(x, y, z);
		local block_id = self.block_id;
		local newBlockData;
		if(last_block_id == block_id and side) then
			local last_block_data = ParaTerrain.GetBlockUserDataByIdx(x, y, z);
			
			if(last_block_data>=0 and last_block_data<6) then
				local last_side = data_to_side[last_block_data];
				if(last_side>=4 and side<4) then
					-- add side plate
					local from_id = 6;
					if(last_side == 4) then
						from_id = from_id + 4;
					end
					from_id = from_id + side_to_second_data[side];
					newBlockData = from_id;
				elseif(last_side<4 and side>=4) then
					-- add ground or ceiling plate
					local from_id = 6;
					if(side == 4) then
						from_id = from_id + 4;
					end
					from_id = from_id + side_to_second_data[last_side];
					newBlockData = from_id;
				end
			elseif(last_block_data>=6 and last_block_data<14) then
				if(last_block_data<10) then
					-- one plate on ground, two on side
					local from_id = 14;
					local last_side = side_to_second_data[last_block_data - 6];
					if((side == 0 and last_side == 3) or (last_side == 0 and side == 3)) then
						newBlockData = from_id + 2;
					elseif((side == 0 and last_side == 2) or (last_side == 0 and side == 2)) then
						newBlockData = from_id + 1;
					elseif((side == 1 and last_side == 2) or (last_side == 1 and side == 2)) then
						newBlockData = from_id + 3;
					elseif((side == 1 and last_side == 3) or (last_side == 1 and side == 3)) then
						newBlockData = from_id + 0;
					end
				else
					-- one plate on ceiling, two on side
					local from_id = 18;
					local last_side = side_to_second_data[last_block_data - 10];
					if((side == 0 and last_side == 3) or (last_side == 0 and side == 3)) then
						newBlockData = from_id + 2;
					elseif((side == 0 and last_side == 2) or (last_side == 0 and side == 2)) then
						newBlockData = from_id + 1;
					elseif((side == 1 and last_side == 2) or (last_side == 1 and side == 2)) then
						newBlockData = from_id + 3;
					elseif((side == 1 and last_side == 3) or (last_side == 1 and side == 3)) then
						newBlockData = from_id + 0;
					end
				end
			end
		end
		if(newBlockData) then
			local block_template = block_types.get(block_id);
			if(block_template) then
				BlockEngine:SetBlockData(x,y,z, newBlockData, 3);

				block_template:play_create_sound();
				block_template:OnBlockPlacedBy(x,y,z, entityPlayer);
				if(itemStack) then
					itemStack.count = itemStack.count - 1;
				end
				return true;
			end
		else
			local block_id = self.block_id;
			local block_template = block_types.get(block_id);

			if(block_template) then
				data = data or block_template:GetMetaDataFromEnv(x, y, z, side, side_region);

				if(BlockEngine:SetBlock(x, y, z, block_id, data, 3)) then
					block_template:play_create_sound();

					block_template:OnBlockPlacedBy(x,y,z, entityPlayer);
					if(itemStack) then
						itemStack.count = itemStack.count - 1;
					end
				end
				return true;
			end
		end
	end
end