--[[
Title: ItemBlockBone
Author(s): LiXizhi
Date: 2015/9/23
Desc: Alt+right click on bone block to cycle bone directions.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemBlockBone.lua");
local ItemBlockBone = commonlib.gettable("MyCompany.Aries.Game.Items.ItemBlockBone");
local item_ = ItemBlockBone:new({icon,});
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Scene/Overlays/ShapesDrawer.lua");
NPL.load("(gl)script/ide/System/Scene/Overlays/Overlay.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemToolBase.lua");
local Color = commonlib.gettable("System.Core.Color");
local Overlay = commonlib.gettable("System.Scene.Overlays.Overlay");
local ShapesDrawer = commonlib.gettable("System.Scene.Overlays.ShapesDrawer");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local ItemBlockBone = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.ItemToolBase"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemBlockBone"));

-- max distance to parent bone horizontally, we will stop finding parent bone after this length
ItemBlockBone.MaxBoneLengthHorizontal = 10;
-- max distance to parent bone vertically, we will stop finding parent bone after this length
ItemBlockBone.MaxBoneLengthVertical = 50;

block_types.RegisterItemClass("ItemBlockBone", ItemBlockBone);


local op_side_to_data = {
	[0] = 0, [1] = 1, [2] = 2, [3] = 3, [4] = 4, [5] = 5,
}		

-- @param template: icon
-- @param radius: the half radius of the object. 
function ItemBlockBone:ctor()
	self.boneLevelColor = 0xffffff;
end

-- Called whenever this item is equipped and the right mouse button is pressed.
-- @return the new item stack to put in the position.
function ItemBlockBone:OnItemRightClick(itemStack, entityPlayer)
	
end

-- virtual function: when selected in right hand
function ItemBlockBone:OnSelect(itemStack)
	GameLogic.SetStatus(L"箭头方向为父骨骼, 与其他方向连接的同色方块为皮肤");
	if(itemStack) then
		local color = itemStack.color32
		if(color) then
			color = Color.ToValue(color);
		end
		if(not color) then
			local data = itemStack:GetPreferredBlockData();
			if(data) then
				color = self:DataToColor(data);
			else
				color = itemStack:GetDataField("color")
				if(color) then
					color = Color.ToValue(color)
				else
					color = 0xffffff;
				end
			end
		end
		self:SetLevelColor(color)
	end
	ItemBlockBone._super.OnSelect(self);
end

function ItemBlockBone:OnDeSelect()
	GameLogic.SetStatus(nil);
	ItemBlockBone._super.OnDeSelect(self);
end

function ItemBlockBone:mousePressEvent(event)
	if(event:button() == "right" and GameLogic.GameMode:IsEditor()) then
		local result = Game.SelectionManager:MousePickBlock(true, false, false);
		if(result.blockX) then
			local x,y,z = result.blockX,result.blockY,result.blockZ;
			local block_template = BlockEngine:GetBlock(x,y,z);
			if(block_template and block_template.id == self.id) then
				if(event.alt_pressed) then
					-- alt + right click to cycle bone directions
					local block_data = BlockEngine:GetBlockData(x,y,z) or 0;
					local data = mathlib.bit.band(block_data, 0xf)
					block_data = (data + 1) % 6 + mathlib.bit.band(block_data, 0xfff0);

					NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ReplaceBlockTask.lua");
					local task = MyCompany.Aries.Game.Tasks.ReplaceBlock:new({blockX = x,blockY = y, blockZ = z, to_id = self.id or 0, to_data = block_data})
					task:Run();
					event:accept();
					return;
				end
			end
		end
	end
	return ItemBlockBone._super.mousePressEvent(self, event);
end

function ItemBlockBone:GetBlockLevelByData(data)
	return mathlib.bit.rshift(data or 0, 8);
end

--@return the parent block position and the side on which the parent is found. nil is returned if not found
function ItemBlockBone:SearchForParentBlock(cx, cy, cz, boneColorData)
	local boneLevel = self:GetBlockLevelByData(boneColorData)
	for i=1, self.MaxBoneLengthHorizontal do
		for side=0,5 do
			local dx, dy, dz = Direction.GetOffsetBySide(side);
			local x,y,z = cx+dx*i, cy+dy*i, cz+dz*i;
			if(BlockEngine:GetBlockId(x, y, z) == self.id) then
				local boneLevel1 = self:GetBlockLevelByData(BlockEngine:GetBlockData(x, y, z));
				if(boneLevel1 == boneLevel) then
					return x,y,z, side;
				end
				-- local parentSide = BlockEngine:GetBlockData(x, y, z) or 0;
				-- if two bones are opposite to each other, the lower one is the parent
				--if(Direction.directionToOpFacing[parentSide] ~= side or (dx+dy+dz) < 0) then
				--end
			end
		end
	end
end



-- show a temporary line
function ItemBlockBone:BlinkBoneConnection(from_x, from_y, from_z, to_x, to_y, to_z)
	-- destroy previous one
	if(self.overlayAnim) then
		self.overlayAnim:Destroy();
		self.overlayAnim = nil;
	end

	local overlayAnim = Overlay:new():init();
	self.overlayAnim = overlayAnim;
	overlayAnim.EnablePicking = false;
	
	from_x, from_y, from_z = BlockEngine:real(from_x, from_y, from_z);
	to_x, to_y, to_z = BlockEngine:real(to_x, to_y, to_z);

	overlayAnim:SetPosition(from_x, from_y, from_z);

	local pen_connection = {width=0.05};
	local bone_radius = 0.3;
	overlayAnim.paintEvent = function(self, painter)
		self:SetColorAndName(painter, "#00ff00");
		painter:SetPen(pen_connection);
		local px,py,pz = to_x-from_x, to_y-from_y, to_z-from_z;
		ShapesDrawer.DrawLine(painter, 0,0,0, px,py,pz)
	end

	self.timer = self.timer or commonlib.Timer:new({callbackFunc = function(timer)
		if(self.overlayAnim) then
			self.overlayAnim:Destroy();
			self.overlayAnim = nil;
		end
	end})
	-- show for 0.5 seconds
	self.timer:Change(500, nil);
end

-- search for a direction. 
function ItemBlockBone:TryCreate(itemStack, entityPlayer, x,y,z, side, data, side_region)
	if (itemStack and itemStack.count == 0) then
		return;
	elseif (entityPlayer and not entityPlayer:CanPlayerEdit(x,y,z, data, itemStack)) then
		return;
	elseif (self:CanPlaceOnSide(x,y,z,side, data, side_region, entityPlayer, itemStack)) then
		local x_, y_, z_ = BlockEngine:GetBlockIndexBySide(x,y,z,BlockEngine:GetOppositeSide(side));
		local last_block_id = BlockEngine:GetBlockId(x_, y_, z_);
		local block_id = self.block_id;

		local block_template = block_types.get(block_id);
		if(block_template) then
			data = data or block_template:GetMetaDataFromEnv(x, y, z, side, side_region);

			local boneColorData = self:ColorToData(self:GetLevelColor(itemStack))
			-- always facing to a possible parent bone. 
			local px, py, pz, pside = self:SearchForParentBlock(x, y, z, boneColorData);
			if(pside) then
				data = op_side_to_data[pside] or data;
				self:BlinkBoneConnection(x, y, z, px, py, pz);
			end
			data = data + boneColorData;

			if(BlockEngine:SetBlock(x, y, z, block_id, data, 3)) then
				GameLogic.AddBBS("ItemBlockBone", L"Alt+右键点击骨骼可改变方向");
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

-- get current selected bone color
function ItemBlockBone:GetLevelColor(itemStack)
	itemStack = itemStack or self:GetSelectedItemStack();
	if(itemStack) then
		local color = itemStack.color32
		if(not color) then
			local data = itemStack:GetPreferredBlockData();
			if(data) then 
				color = self:DataToColor(data);
			else
				color = itemStack:GetDataField("color")
				if(color) then
					color = Color.ToValue(color)
				end
			end
			color = color or self.boneLevelColor
			itemStack.color32 = color
		end
		return Color.ToValue(color);
	else
		return self.boneLevelColor;
	end
end

-- @param color: either 0xffffff, or string like "#ff0000"
function ItemBlockBone:SetLevelColor(color)
	color = Color.ToValue(color);
	if(color and color ~= self:GetLevelColor()) then
		self.boneLevelColor = color;
		local itemStack = self:GetSelectedItemStack();
		if(itemStack) then
			local data = self:ColorToData(color);
			if(data) then
				itemStack:SetPreferredBlockData(data)
			end
			itemStack.color32 = color
		end
	end
end


-- virtual function: 
function ItemBlockBone:CreateTask(itemStack)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BoneBlock/SelectBone.lua");
	local SelectBone = commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectBone");
	local task = SelectBone:new();
	task:SetLevelColor(self:GetLevelColor(itemStack))
	task:Connect("levelColorSelected", self, self.SetLevelColor);
	return task;
end
