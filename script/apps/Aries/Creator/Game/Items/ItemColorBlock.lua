--[[
Title: ItemColorBlock
Author(s): LiXizhi
Date: 2015/6/25
Desc: paint with current selected pen.

Usage:
   * alt + left mouse click: pick the color of the current mouse block.
   * mouse wheel: change color saturation
   * +/- key: change color lightness

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemColorBlock.lua");
local ItemColorBlock = commonlib.gettable("MyCompany.Aries.Game.Items.ItemColorBlock");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/Color.lua");
local Color = commonlib.gettable("System.Core.Color");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local ItemColorBlock = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.Item"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemColorBlock"));

block_types.RegisterItemClass("ItemColorBlock", ItemColorBlock);

-- receive mouse move event even mouse down is not pressed. 
-- ItemColorBlock.mouseTracking = true;

-- initial pen color
ItemColorBlock.pen_color = 0xffffff;

-- step of HSL change delta
ItemColorBlock.colorStep = 4/256;

-- picking from backbuffer directly
ItemColorBlock.use_buffer_picking = true;

--private:
ItemColorBlock.lastBlinkTime = 0;

-- @param template: icon
-- @param radius: the half radius of the object. 
function ItemColorBlock:ctor()
	self.m_bIsOwnerDrawIcon = true;
end

local random_colors = {
	0xffffff, 0xff0000, 0x00ff00, 0x0000ff,
}
local last_random_index = 0;
function ItemColorBlock:GetRandomColor()
	last_random_index = (last_random_index % (#random_colors)) + 1;
	return random_colors[last_random_index];
end

-- get current selected pen color
function ItemColorBlock:GetPenColor()
	return self.pen_color;
end

-- @param color: either 0xffffff, or string like "#ff0000"
function ItemColorBlock:SetPenColor(color)
	color = Color.ToValue(color);
	if(color and color ~= self.pen_color) then
		self.pen_color = color;
	end
end

function ItemColorBlock:GetTooltipFromItemStack(itemStack)
	local text = self:GetTooltip();
	return string.format("%s Color:#%06x", text or "", self:GetPenColor());
end

function ItemColorBlock:PaintBlock(x,y,z, color)
	color = self:ColorToData(color);
	if(color) then
		BlockEngine:SetBlockData(x,y,z, color);
	end
end

-- static function: from color to data
function ItemColorBlock:ColorToData(color)
	return Color.convert32_16(color);
end

function ItemColorBlock:DataToColor(data)
	return Color.convert16_32(data);
end

-- Right clicking in 3d world with the block in hand will trigger this function. 
-- Alias: OnUseItem;
-- @param itemStack: can be nil
-- @param entityPlayer: can be nil
-- @return isUsed: isUsed is true if something happens.
function ItemColorBlock:TryCreate(itemStack, entityPlayer, x,y,z, side, data, side_region)
	data = self:ColorToData(self:GetPenColor());

	-- create with currently selected pen
	return ItemColorBlock._super.TryCreate(self, itemStack, entityPlayer, x,y,z, side, data, side_region);
end

function ItemColorBlock:BlinkPenColor(bForceBlink)
	local curTime = commonlib.TimerManager.GetCurrentTime();
	if(bForceBlink or (curTime-self.lastBlinkTime) > 1000) then
		self.lastBlinkTime = curTime;
		color = self:GetPenColor();
		local mouse_x, mouse_y = ParaUI.GetMousePosition();
		NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/ObtainItemEffect.lua");
		local ObtainItemEffect = commonlib.gettable("MyCompany.Aries.Game.Effects.ObtainItemEffect");
		local color_str = string.format("#%06x", color);
		ObtainItemEffect:new({background="Texture/whitedot.png", color=color_str, width=32,height=32, 
			from_2d={x=mouse_x,y=mouse_y-32-5}, to_2d={x=mouse_x,y=mouse_y-64}, duration=1000, fadeOut=150}):Play();
	end
end

-- when alt key is pressed to pick a block in edit mode. 
function ItemColorBlock:PickItemFromPosition(x,y,z)
	self:PickPenColorAtPos(x,y,z);
	return self._super.PickItemFromPosition(self, x,y,z);
end

function ItemColorBlock:PickPenColorAtPos(x,y,z)
	local block_template = BlockEngine:GetBlock(x,y,z);
	if(block_template) then
		local color = block_template:GetBlockColor(x,y,z);
		self:SetPickColor(color);
	end
end

function ItemColorBlock:SetPickColor(color)
	if(color and self:GetPenColor() ~= color) then
		self:SetPenColor(color);
		self:BlinkPenColor(true);
	else
		self:BlinkPenColor(false);
	end
end

function ItemColorBlock:PickPenColorAtMouse(result)
	if(self.use_buffer_picking) then
		result = result or Game.SelectionManager:MousePickBlock(true, false, false);
		if(result.blockX) then
			local x,y,z = result.blockX,result.blockY,result.blockZ;
			local block_template = BlockEngine:GetBlock(x,y,z);
			if(block_template) then
				if(block_template.color_data) then
					local color = self:DataToColor(BlockEngine:GetBlockData(x,y,z));
					self:SetPickColor(color);
					return 
				end
			end
		end

		NPL.load("(gl)script/ide/System/Scene/BufferPicking.lua");
		local BufferPicking = commonlib.gettable("System.Scene.BufferPicking");
		local result = BufferPicking:Pick();
		if(result and result[1]) then
			local color = result[1];
			local r,g,b,a = Color.DWORD_TO_RGBA(color);
			color = Color.RGBA_TO_DWORD(r, g, b, 0);
			self:SetPickColor(color);
		end
	else
		result = result or Game.SelectionManager:MousePickBlock(true, false, false);
		if(result.blockX) then
			local x,y,z = result.blockX,result.blockY,result.blockZ;
			self:PickPenColorAtPos(x,y,z);
		end
	end
end

-- virtual function: when selected in right hand
function ItemColorBlock:OnSelect()
	GameLogic.SetStatus(L"Alt+鼠标左键可拾取颜色. Shift+滚轮调节亮度. +/-饱和度");
end

function ItemColorBlock:OnDeSelect()
	GameLogic.SetStatus(nil);
end


function ItemColorBlock:keyPressEvent(event)
	if(event.keyname == "DIK_ADD" or event.keyname == "DIK_EQUALS") then
		-- increase color saturation
		self:ChangePenColor(self.colorStep, 0);
	elseif(event.keyname == "DIK_SUBTRACT" or event.keyname == "DIK_MINUS") then
		-- decrease color saturation
		self:ChangePenColor(-self.colorStep, 0);
	end
end

-- change pen color with a delta HSV value
-- @param dSaturation: 
-- @param dLightness: 
function ItemColorBlock:ChangePenColor(dSaturation, dLightness)
	local h,s,l = Color.ColorToHSL(self:GetPenColor())
	if(h) then
		s = mathlib.clamp(s + (dSaturation or 0), 0, 1);
		l = mathlib.clamp(l + (dLightness or 0), 0, 1);
		local color = Color.HSLToColor(h,s,l, 0);
		if(self:GetPenColor() ~= color) then
			self:SetPenColor(color);
			self:BlinkPenColor(true);
		else
			self:BlinkPenColor(false);
		end
	end
end

function ItemColorBlock:mousePressEvent(event)
	if(event.alt_pressed and not event.shift_pressed and event:button() == "left") then
		event:accept();
		self:PickPenColorAtMouse();
	end
	if(event:button() == "right" and GameLogic.GameMode:IsEditor()) then
		local result = Game.SelectionManager:MousePickBlock(true, false, false);
		if(result.blockX) then
			local x,y,z = result.blockX,result.blockY,result.blockZ;
			local block_template = BlockEngine:GetBlock(x,y,z);
			if(block_template) then
				if(event.alt_pressed) then
					-- replace one or more blocks. alt+shift to replace recusively
					local data = self:ColorToData(self:GetPenColor());
					NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ReplaceBlockTask.lua");
					local task = MyCompany.Aries.Game.Tasks.ReplaceBlock:new({blockX = x,blockY = y, blockZ = z, 
						to_id = self.id, to_data=data, max_radius = if_else(event.shift_pressed, 30, 0)})
					task:Run();
					event:accept();
				elseif(event.shift_pressed) then
					-- fill line
					self:PickPenColorAtMouse(result);
					local data = self:ColorToData(self:GetPenColor());
					NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/FillLineTask.lua");
					local task = MyCompany.Aries.Game.Tasks.FillLine:new({blockX = x,blockY = y, blockZ = z, side = result.side,
						fill_id = self.id, fill_data = data})
					task:Run();
					event:accept();
				else
					
				end
			end
		end
	end
end

function ItemColorBlock:mouseMoveEvent(event)
	if(event.alt_pressed) then
		
	end
end

function ItemColorBlock:mouseWheelEvent(event)
	if(event.shift_pressed) then
		local delta = event:GetDelta();
		-- saturation
		self:ChangePenColor(0, delta*self.colorStep);
		event:accept();
	end
end

-- virtual function: try to get block date from itemStack. 
-- in most cases, this return nil
-- @return nil or a number 
function ItemColorBlock:GetBlockData(itemStack)
	return self:ColorToData(self:GetPenColor());
end

-- called whenever this item is clicked on the user interface when it is holding in hand of a given player (current player). 
function ItemColorBlock:OnClickInHand(itemStack, entityPlayer)
	-- if there is selected blocks, we will replace selection with current block in hand. 
	if(GameLogic.GameMode:IsEditor() and entityPlayer == EntityManager.GetPlayer()) then
		local selected_blocks = Game.SelectionManager:GetSelectedBlocks();
		if(selected_blocks) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ReplaceBlockTask.lua");
			local data = self:GetBlockData(itemStack);
			local task = MyCompany.Aries.Game.Tasks.ReplaceBlock:new({blocks = commonlib.clone(selected_blocks), 
				to_id = self.id, to_data=data});
			task:Run();
		end
	end
end

-- virtual: draw icon with given size at current position (0,0)
-- @param width, height: size of the icon
-- @param itemStack: this may be nil. or itemStack instance. 
function ItemColorBlock:DrawIcon(painter, width, height, itemStack)
	painter:SetPen(Color.ChangeOpacity(self:GetPenColor()));
	painter:DrawRect(0,0,width, height);
	ItemColorBlock._super.DrawIcon(self, painter, width, height, itemStack);
end