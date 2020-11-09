--[[
Title: Select Block Manipulator
Author(s): LiXizhi@yeah.net
Date: 2017/9/12
Desc: select block manipulator, this is used in EditContext when ctrl or shift or alt key is pressed. 
- Ctrl and left drag mouse to select blocks
- Ctrl and right drag mouse to select objects
- Shift and left drag mouse to delete blocks
- Shift and right drag mouse to create blocks
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/Manipulators/SelectBlocksManipContainer.lua");
local SelectBlocksManipContainer = commonlib.gettable("MyCompany.Aries.Game.Manipulators.SelectBlocksManipContainer");
local manip = SelectBlocksManipContainer:new();
manip:init();
self:AddManipulator(manip);
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Scene/Manipulators/ManipContainer.lua");
NPL.load("(gl)script/ide/System/Scene/Overlays/ShapesDrawer.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/SelectionManager.lua");
local Keyboard = commonlib.gettable("System.Windows.Keyboard");
local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");
local ShapesDrawer = commonlib.gettable("System.Scene.Overlays.ShapesDrawer");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local SelectBlocksManipContainer = commonlib.inherit(commonlib.gettable("System.Scene.Manipulators.ManipContainer"), commonlib.gettable("MyCompany.Aries.Game.Manipulators.SelectBlocksManipContainer"));
SelectBlocksManipContainer:Property({"Name", "SelectBlocksManipContainer", auto=true});
SelectBlocksManipContainer:Property({"EnablePicking", true});
SelectBlocksManipContainer:Property({"PenWidth", 0.02});
SelectBlocksManipContainer:Property({"mainColor", "#333333"});
SelectBlocksManipContainer:Property({"fillColor", "#ffffff55"});
-- we will always use camera position so that it will always be drawn. 
SelectBlocksManipContainer:Property({"UseCameraPos", true});

function SelectBlocksManipContainer:ctor()
	self.from_pos = nil;
	self.to_pos = nil;
	self.dragging = false;
	-- if true, we will select the block next to the mouse touch face, if false, we will select the block where the mouse touches.
	self.isFaceMode = false;
	self.op_mode = "select"; -- select, create, delete
end

---------------------------------
-- class AxisManip: draw a readonly axis indicator
---------------------------------
NPL.load("(gl)script/ide/System/Scene/Manipulators/TranslateManip.lua");
local AxisManip = commonlib.inherit(commonlib.gettable("System.Scene.Manipulators.TranslateManip"), {});

function AxisManip:ctor()
	self:SetFixOrigin(true);
end

function AxisManip:paintEvent(painter)
	if(not self.parent.dragging or not self.parent.from_pos or not self.parent.to_pos) then
		return;
	end
	if(self:IsPickingPass()) then
		return;
	end
	-- always draw relative to parent position
	local cx,cy,cz = self.parent:GetPosition();
	local to_x, to_y, to_z = BlockEngine:real(unpack(self.parent.to_pos));
	painter:TranslateMatrix(to_x-cx, to_y-cy, to_z-cz);
	AxisManip._super.paintEvent(self, painter);
end

function SelectBlocksManipContainer:createChildren()
	self.axisManip = AxisManip:new():init(self);
end

function SelectBlocksManipContainer:mousePressEvent(event)
	self.isFaceMode = false;
	self.op_mode = nil;
	self.from_pos = nil;
	self.to_pos = nil;
	local mouse_setting_list = GameLogic.options:GetMouseSettingList();
	local mouse_event = event:button() or ""
	local setting = mouse_setting_list[mouse_event]

	-- 按住ctrl的时候 还是按照以前使用左键的逻辑 以前左键是用作 DeleteBlock
	if event.ctrl_pressed and mouse_setting_list["left"] == "CreateBlock" then
		if setting == "CreateBlock" then
			setting = "DeleteBlock"
		elseif setting == "DeleteBlock" then
			setting = "CreateBlock"
		end
	end

	if(setting == "CreateBlock") then
		if(Keyboard:IsShiftKeyPressed())  then
			self.isFaceMode = true;
			self.op_mode = "create";
		elseif(Keyboard:IsCtrlKeyPressed())  then
			self.op_mode = "selectobj";
			NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/ScreenRectSelector.lua");
			local ScreenRectSelector = commonlib.gettable("MyCompany.Aries.Game.GUI.Selectors.ScreenRectSelector");
			self.selector = ScreenRectSelector:new():Init(5,5,"right");
			self.selector:BeginSelect(function(mode, left, top, width, height)
				NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/ObjectSelectPage.lua");
				local ObjectSelectPage = commonlib.gettable("MyCompany.Aries.Game.GUI.ObjectSelectPage");
				if(mode == "selected") then
					ObjectSelectPage.SelectByScreenRect(left, top, width, height);
				else
					ObjectSelectPage.CloseWindow();
				end
			end)
		end
	elseif(setting == "DeleteBlock") then
		if(Keyboard:IsShiftKeyPressed())  then
			self.op_mode = "delete";
		elseif(Keyboard:IsCtrlKeyPressed())  then
			self.op_mode = "select";
		end
	end

	if(self.op_mode and self.op_mode~="selectobj") then
		local result = SelectionManager:MousePickBlock();
		if(result.blockX) then
			local x, y, z = result.blockX, result.blockY, result.blockZ;
			self.block_id = result.block_id;
			self.block_data = BlockEngine:GetBlockData(x,y,z);
			if(self.isFaceMode) then
				x,y,z = BlockEngine:GetBlockIndexBySide(x, y, z, result.side)
			end
			self.from_pos = {x, y, z};
			self.dragging = true;
		end
	end
end

function SelectBlocksManipContainer:mouseReleaseEvent(event)
	self.dragging = false;
	local selected_blocks = self:GetSelectedBlocks();
	if(#selected_blocks == 0) then
		return;
	end
	if(self.op_mode == "delete") then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DestroyNearbyBlocksTask.lua");
		local task = MyCompany.Aries.Game.Tasks.DestroyNearbyBlocks:new({
			explode_time=200, 
			destroy_blocks = selected_blocks,
		})	
		task:Run();
		event:accept();
	elseif(self.op_mode == "create") then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateBlockTask.lua");
		for i, b in ipairs(selected_blocks) do
			b[4] = self.block_id;
			b[5] = self.block_data;
		end
		local task = MyCompany.Aries.Game.Tasks.CreateBlock:new({blocks = selected_blocks})
		task:Run();
		event:accept();
	elseif(self.op_mode == "select") then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
		local SelectBlocks = commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectBlocks");
		local task = MyCompany.Aries.Game.Tasks.SelectBlocks:new({blocks=selected_blocks})
		task:Run();
		event:accept();
	elseif(self.op_mode == "selectobj") then
		if(self.selector and self.selector:OnUpdate() == "selected") then
			event:accept();
		end
	end
end

function SelectBlocksManipContainer:mouseMoveEvent(event)
	if(self.dragging and self.from_pos) then
		local result = SelectionManager:MousePickBlock();
		if(result.blockX) then
			local x, y, z = result.blockX, result.blockY, result.blockZ;
			if(self.isFaceMode) then
				x,y,z = BlockEngine:GetBlockIndexBySide(x, y, z, result.side)
			end
			
			if((x ~= self.from_pos[1] or y ~= self.from_pos[2] or z ~= self.from_pos[3]) ) then
				self.to_pos = self.to_pos or {};
				self.to_pos[1], self.to_pos[2], self.to_pos[3] = x, y, z;
			end
		end
	end
end


function SelectBlocksManipContainer:GetSelectedBlocks()
	local blocks = {};
	if(self.from_pos and self.to_pos) then
		NPL.load("(gl)script/ide/math/ShapeBox.lua");
		local ShapeBox = commonlib.gettable("mathlib.ShapeBox");
		local aabb = ShapeBox:new();
		aabb:Extend(unpack(self.from_pos));
		aabb:Extend(unpack(self.to_pos));
		local min, max = aabb:GetMin(), aabb:GetMax();
		for x = min[1], max[1] do
			for y = min[2], max[2] do
				for z = min[3], max[3] do
					if( self.isFaceMode ) then
						blocks[#blocks+1] = {x,y,z};
					elseif(BlockEngine:GetBlockId(x,y,z) ~= 0) then
						blocks[#blocks+1] = {x,y,z};
					end
				end
			end
		end
	end
	return blocks;
end

function SelectBlocksManipContainer:paintEvent(painter)
	SelectBlocksManipContainer._super.paintEvent(self, painter);

	if(not self.dragging or not self.from_pos or not self.to_pos) then
		return;
	end
	if(self:IsPickingPass()) then
		return
	end

	local from_x,from_y,from_z = BlockEngine:real(unpack(self.from_pos));
	local to_x, to_y, to_z = BlockEngine:real(unpack(self.to_pos));
	
	self.pen.width = self.PenWidth;
	painter:SetPen(self.pen);
	

	local cx,cy,cz = self:GetPosition();
	-- draw block AABB
	from_x, from_y, from_z = from_x-cx, from_y-cy, from_z-cz;
	to_x, to_y, to_z = to_x-cx, to_y-cy, to_z-cz;

	local half_size = BlockEngine.half_blocksize + 0.05;
	local min_x, min_y, min_z, max_x, max_y, max_z;
	min_x = math.min(from_x-half_size, to_x-half_size);
	min_y = math.min(from_y-half_size, to_y-half_size);
	min_z = math.min(from_z-half_size, to_z-half_size);
	max_x = math.max(from_x+half_size, to_x+half_size);
	max_y = math.max(from_y+half_size, to_y+half_size);
	max_z = math.max(from_z+half_size, to_z+half_size);

	self:SetColorAndName(painter, self.fillColor);
	ShapesDrawer.DrawAABB(painter, min_x, min_y, min_z, max_x, max_y, max_z, true);

	self:SetColorAndName(painter, self.mainColor);
	local penSize = self.PenWidth*0.5;
	ShapesDrawer.DrawAABB(painter, min_x-penSize, min_y-penSize, min_z-penSize, max_x+penSize, max_y+penSize, max_z+penSize, false);
end