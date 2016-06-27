--[[
Title: ItemDoor
Author(s): LiXizhi
Date: 2014/5/6
Desc: when BlockImage is destroyed, it will generate an ItemDoor whose tooltip contains its filepath. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemDoor.lua");
local ItemDoor = commonlib.gettable("MyCompany.Aries.Game.Items.ItemDoor");
local item = ItemDoor:new({icon,});
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/vector.lua");
local Player = commonlib.gettable("MyCompany.Aries.Player");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local ItemDoor = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.Item"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemDoor"));

block_types.RegisterItemClass("ItemDoor", ItemDoor);

-- @param template: icon
-- @param radius: the half radius of the object. 
function ItemDoor:ctor()
end

local door_to_window_map = {
	[232] = 108,
	[233] = 109,
	[230] = 194,
	[231] = 195,
}

-- just incase the tooltip contains the image path
function ItemDoor:TryCreate(itemStack, entityPlayer, x,y,z, side, data, side_region)
	if(ItemDoor._super.TryCreate(self, itemStack, entityPlayer, x,y,z, side, data, side_region)) then
		-- create a window on top of the current block
		local block_id = BlockEngine:GetBlockId(x,y+1,z)
		if(not block_id or block_id == 0) then
			local window_block_id = BlockEngine:GetBlockId(x,y,z);
			local block_data = BlockEngine:GetBlockData(x,y,z);
			local block_template = BlockEngine:GetBlock(x,y,z);
			window_block_id = door_to_window_map[window_block_id or 0];
			if(window_block_id) then
				BlockEngine:SetBlock(x,y+1,z, window_block_id, block_data, 3);
			end
		end
		return true;
	end
end