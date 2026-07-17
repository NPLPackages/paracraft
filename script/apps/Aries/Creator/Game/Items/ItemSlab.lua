--[[
Title: ItemSlab
Author(s): LiXizhi
Date: 2014/1/20
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemSlab.lua");
local ItemSlab = commonlib.gettable("MyCompany.Aries.Game.Items.ItemSlab");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/vector.lua");
NPL.load("(gl)script/ide/math/bit.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local band = mathlib.bit.band;
local bor = mathlib.bit.bor;

local ItemSlab = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.ItemColorBlock"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemSlab"));

block_types.RegisterItemClass("ItemSlab", ItemSlab);

local block_id_map;

local function GetBoxBlockBySlabID(slab_id)
	if(not block_id_map)then
		block_id_map = {
			[block_types.names.Stone_Slab] = block_types.names.Double_Stone_Slab,
			[block_types.names.Sandstone_Slab] = block_types.names.Smooth_Sandstone,
			[block_types.names.Oak_Wood_Slab] = block_types.names.Oak_Wood_Planks,
			[block_types.names.Cobblestone_Slab] = block_types.names.Cobblestone,
			[block_types.names.Brick_Slab] = block_types.names.Brick,
			[block_types.names.StoneBrick_Slab] = block_types.names.StoneBrick,
			[block_types.names.NetherBrick_Slab] = block_types.names.NetherBrick,
			[block_types.names.Quartz_Slab] = block_types.names.Block_Of_Quartz,

			[block_types.names.Spruce_Wood_Slab] = block_types.names.Spruce_Wood_Planks,
			[block_types.names.Birch_Wood_Slab] = block_types.names.Birch_Wood_Planks,
			[block_types.names.Jungle_Wood_Slab] = block_types.names.Jungle_Wood_Planks,
			[block_types.names.ColorBlock_Slab] = block_types.names.ColorBlock,
			[block_types.names.TransparentColorBlock_Slab] = block_types.names.TransparentColorBlock,
			[block_types.names.MetalBlock_Slab] = block_types.names.MetalBlock,
			
		}
	end
	return block_id_map[slab_id];
end

-- @param template: icon
-- @param radius: the half radius of the object. 
function ItemSlab:ctor()
end

function ItemSlab:OnSelect(itemStack)
	ItemSlab._super.OnSelect(self, itemStack);
	GameLogic.SetStatus(L"Alt+右键改变形状");
end
function ItemSlab:OnDeSelect()
	ItemSlab._super.OnDeSelect(self);
	GameLogic.SetStatus(nil);
end

-- Right clicking in 3d world with the block in hand will trigger this function. 
-- Alias: OnUseItem;
-- @param itemStack: can be nil
-- @param entityPlayer: can be nil
-- @return isUsed: isUsed is true if something happens.
function ItemSlab:TryCreate(itemStack, entityPlayer, x,y,z, side, data, side_region)
	if (itemStack and itemStack.count == 0) then
		return;
	elseif (entityPlayer and not entityPlayer:CanPlayerEdit(x,y,z, data, itemStack)) then
		return;
	elseif (self:CanPlaceOnSide(x,y,z,side, data, side_region, entityPlayer, itemStack)) then
		local x_, y_, z_ = BlockEngine:GetBlockIndexBySide(x,y,z,BlockEngine:GetOppositeSide(side));
		local last_block_id = BlockEngine:GetBlockId(x_, y_, z_);
		local block_id = self.block_id;
		local isReplacing;
		if(last_block_id == block_id) then
			local last_block_data = ParaTerrain.GetBlockUserDataByIdx(x_, y_, z_);
			local color_data = band(last_block_data, 0xff00);
			last_block_data = band(last_block_data, 0x00ff);

			if last_block_id==281 or last_block_id==284 or last_block_id==287 then
				-- color_data = self:DataToColor(color_data,8)
				-- color_data = self:ColorToData(color_data,16)
				color_data = itemStack:GetPreferredBlockData() or 0
				color_data = self:DataToColor(color_data,8)
				color_data = self:ColorToData(color_data,16)
			end
			
			if(last_block_data == 0) then
				if(side == 5 or data == 1) then
					-- replace last block id
					if(BlockEngine:SetBlock(x_, y_, z_, GetBoxBlockBySlabID(last_block_id) or block_id, color_data, 3)) then
						isReplacing = true;
					end
				end
			else
				if(side == 4 or data == 0) then
					-- replace last block id
					if(BlockEngine:SetBlock(x_, y_, z_, GetBoxBlockBySlabID(last_block_id) or block_id, color_data, 3)) then
						isReplacing = true;
					end
				end	
			end	
		end
		if(isReplacing) then
			local block_template = block_types.get(block_id);
			if(block_template) then
				self:PaintBlock(x_, y_, z_, self:GetPenColor(itemStack))
				block_template:play_create_sound();

				block_template:OnBlockPlacedBy(x_, y_, z_, entityPlayer);
				if(itemStack) then
					itemStack.count = itemStack.count - 1;
				end
				return true;
			end
		else
			local block_id = self.block_id;
			local block_template = block_types.get(block_id);

			if(block_template) then
				if(not data) then
					data = block_template:GetMetaDataFromEnv(x, y, z, side, side_region);
					data = block_template:CalculatePreferredData(data, itemStack:GetPreferredBlockData());
				end

				if(BlockEngine:SetBlock(x, y, z, block_id, data, 3)) then
					self:PaintBlock(x,y,z, self:GetPenColor(itemStack))
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

function ItemSlab:mouseReleaseEvent(event)
	if(event:isAccepted()) then
		return
	end
	if(event:button() == "right" and GameLogic.GameMode:IsEditor()) then
		if(event.alt_pressed and not event.shift_pressed and not event.ctrl_pressed) then
			-- alt + right click to change its shape
			event:accept();
			local result = Game.SelectionManager:MousePickBlock(true, false, false);
			if(result.blockX) then
				local x,y,z = result.blockX,result.blockY,result.blockZ;
				local block_template = BlockEngine:GetBlock(x,y,z);
				if(block_template and block_template.shape == "slab") then
					self:SwitchSlabShape(x,y,z)
					event:accept();
				end
			end
		end
	end
end

local shapeSwitchTable;
function ItemSlab:GetShapeSwitchTable()
	if(not shapeSwitchTable) then
		shapeSwitchTable = {
			[0] = 1, [1] = 2, [2] = 3, [3] = 4, [4] = 5, [5] = 0,
		}
	end
	return shapeSwitchTable;
end

function ItemSlab:SwitchSlabShape(x,y,z)
	local block_template = BlockEngine:GetBlock(x,y,z);
	if(block_template and block_template.shape == "slab") then
		local data = BlockEngine:GetBlockData(x, y, z);
		local shapes = self:GetShapeSwitchTable()
		
		local data2 = shapes[band(data, 0xff)]
		if(data2) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ReplaceBlockTask.lua");
			local task = MyCompany.Aries.Game.Tasks.ReplaceBlock:new({blockX = x,blockY = y, blockZ = z, 
				to_id = self.id, to_data=bor(data2, band(data, 0xffffff00)), max_radius = 0, preserveRotation=false})
			task:Run();
		end
	end
end