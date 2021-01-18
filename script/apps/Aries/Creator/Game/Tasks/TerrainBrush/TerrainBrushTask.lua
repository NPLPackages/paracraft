--[[
Title: TerrainBrush Task/Command
Author(s): LiXizhi
Date: 2016/7/16
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TerrainBrush/TerrainBrushTask.lua");
local TerrainBrushTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.TerrainBrushTask");
local task = TerrainBrushTask:new();
task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
NPL.load("(gl)script/ide/math/vector.lua");
NPL.load("(gl)script/ide/System/Windows/Keyboard.lua");
local Keyboard = commonlib.gettable("System.Windows.Keyboard");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local vector3d = commonlib.gettable("mathlib.vector3d");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local TerrainBrushTask = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.TerrainBrushTask"));

local groupindex_hint = 6; 

local curInstance;

-- this is always a top level task. 
TerrainBrushTask.is_top_level = true;

TerrainBrushTask.default_toolname = "raise";

TerrainBrushTask.tools = {
    {name="raise", tooltip=L"提升地形, 按住Shift点击为下降", icon="Texture/blocks/items/raise.png"},
    {name="smooth", tooltip=L"平滑地形, 按住Shift点击为锐化", icon="Texture/blocks/items/rough.png"},
    {name="flatten", tooltip=L"铲平地形", icon="Texture/blocks/items/flatten.png"},
	{name="flood", tooltip=L"按住左键并拖动填充水, 按住Shift可移除水", icon="Texture/blocks/items/waterfeet.png"},
	{name="remove", tooltip=L"删除表层方块", icon="Texture/blocks/items/wood_axe.png"},
}

function TerrainBrushTask:ctor()
	self.position = vector3d:new(0,0,0);
end

function TerrainBrushTask:Init(item)
	self.item = item;
	return self;
end

local page;
function TerrainBrushTask.InitPage(Page)
	page = Page;
end

-- get current instance
function TerrainBrushTask.GetInstance()
	return curInstance;
end

function TerrainBrushTask.OnClickTool(name)
	local self = curInstance;
	self:SelectToolByName(name);
	if(page) then
		page:Refresh(0.01);
	end
end

function TerrainBrushTask.OnChangeStrength(actualText)
	local self = curInstance;
    actualText = tonumber(actualText);
    self:SetBrushStrength(actualText);
end

function TerrainBrushTask:SelectToolByName(name)
	local self = curInstance;
	self.item:SetToolName(name);
end

function TerrainBrushTask:GetRadius()
	return self.item:GetPenRadius();
end

function TerrainBrushTask:GetBrushStrength()
	return self.item and self.item:GetBrushStrength() or 0.5;
end

function TerrainBrushTask:SetBrushStrength(value)
	value = tonumber(value);
	if(value and value>=0 and value<=1) then
		return self.item and self.item:SetBrushStrength(value);
	end
end


function TerrainBrushTask.GetTools()
	return (curInstance or TerrainBrushTask).tools;
end

function TerrainBrushTask:GetCurrentToolIcon()
	local name = self:GetToolName();
	for i, tool in self.GetTools() do
		if(tool.name == name) then
			return tool.icon;
		end
	end
end

function TerrainBrushTask:GetToolName()
	return self.item:GetToolName() or self.default_toolname;
end

function TerrainBrushTask:CreateToolTask()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TerrainBrush/TerrainFilterTask.lua");
	local task = MyCompany.Aries.Game.Tasks.TerrainFilter:new()
	-- TODO: get TerrainFilterTask object and initialize with current tool settings
	return task;
end

function TerrainBrushTask:GetToolTask()
	return self.tool_task;
end

-- do operation at given block position with current selected tool
function TerrainBrushTask:BeginOperation()
	self:EndOperation();
	self.tool_task = self:CreateToolTask();
	self.last_step_time = 0;
	self.begin_x, self.begin_y, self.begin_z = self:GetCenterBlockPos();
	self.begin_side = self.last_side;
	self.timer = self.timer or commonlib.Timer:new({callbackFunc = function(timer)
		if(self:GetToolTask()) then
			if(self:UpdateCenterPosition()) then
				self:StepOperation();
			end
		end
	end})
	self.timer:Change(200,200);
end

function TerrainBrushTask:GetCenterBlockPos()
	local x, y, z = unpack(self.item:GetPosition());
	x,y,z = BlockEngine:block(x, y-0.1, z);
	return x,y,z;
end

-- Must be called between BeginOperation and EndOperation to perform one step of the operation. 
function TerrainBrushTask:StepOperation()
	local task = self:GetToolTask();
	if(not task or not self.item) then return end

	local x, y, z = self:GetCenterBlockPos();

	local block_template = BlockEngine:GetBlock(x,y,z);
	if(not block_template) then
		return;
	end

	local curTime = ParaGlobal.timeGetTime();
	if(curTime > (self.last_step_time or 0) + (task.step_duration or 300)) then
		self.last_step_time = curTime;
	else
		return;
	end

	local toolname = self:GetToolName();
	if(toolname == "flatten") then
		if(Keyboard:IsShiftKeyPressed()) then
			task:Flatten(task.FlattenOperation.ShaveTop_Op, self.begin_y or y, x, z, self:GetRadius(), self:GetBrushStrength());
		else
			task:Flatten(task.FlattenOperation.Fill_Op, self.begin_y or y, x, z, self:GetRadius(), self:GetBrushStrength());
		end
	elseif(toolname == "raise") then
		if(Keyboard:IsShiftKeyPressed()) then
			-- lower
			task:GaussianHill(y, x, z, self:GetRadius(), -0.5, self:GetBrushStrength(), 0.6);
		else
			-- raise
			task:GaussianHill(y, x, z, self:GetRadius(), 0.5, self:GetBrushStrength(), 0.6);
		end
	elseif(toolname == "smooth") then
		if(Keyboard:IsShiftKeyPressed()) then
			-- roughen
			task:Roughen_Smooth(y, x, z, self:GetRadius(), true, 4, self:GetBrushStrength());
		else
			-- smooth
			task:Roughen_Smooth(y, x, z, self:GetRadius(), false, 4, self:GetBrushStrength());
		end
	elseif(toolname == "paint") then
		local block_id = self:GetSelectedBlockId();
		local block_template = block_types.get(block_id);
		if(block_template and block_template:isNormalCube()) then
			task:PaintBlocks(task.PaintOperation.Replace_Op, self:GetSelectedBlockId(), self:GetSelectedBlockData(), x, y, z, self:GetRadius(), self:GetBrushStrength());
		else
			task:PaintBlocks(task.PaintOperation.Ontop_Op, self:GetSelectedBlockId(), self:GetSelectedBlockData(), x, y, z, self:GetRadius(), self:GetBrushStrength());
		end
	elseif(toolname == "remove") then
		task:PaintBlocks(task.PaintOperation.Replace_Op, 0, nil, x, y, z, self:GetRadius(), 1);
	elseif(toolname == "flood") then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/WaterFloodTask.lua");
		x,y,z = BlockEngine:GetBlockIndexBySide(x, self.begin_y or y, z, self.begin_side)
		if(Keyboard:IsShiftKeyPressed()) then
			-- unflood
			local task = MyCompany.Aries.Game.Tasks.WaterFlood:new({blockX = x,blockY = y, blockZ = z, fill_id = 0, radius = self:GetRadius()})
			task:Run();
		else
			-- flood
			local task = MyCompany.Aries.Game.Tasks.WaterFlood:new({blockX = x,blockY = y, blockZ = z, fill_id = nil, radius = self:GetRadius()})
			task:Run();
		end
	elseif(toolname == "flood_paint") then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/WaterFloodTask.lua");
		x,y,z = BlockEngine:GetBlockIndexBySide(x, self.begin_y or y, z, self.begin_side)
		local task = MyCompany.Aries.Game.Tasks.WaterFlood:new({blockX = x,blockY = y, blockZ = z, fill_id = self:GetSelectedBlockId(), radius = self:GetRadius()})
		task:Run();
	end
end

function TerrainBrushTask:GetSelectedBlockId()
	return self.item and self.item:GetSelectedBlockId();
end

function TerrainBrushTask:GetSelectedBlockData()
	return self.item and self.item:GetSelectedBlockData();
end

function TerrainBrushTask:EndOperation()
	if(self.timer) then
		self.timer:Change();
	end
	if(self.tool_task) then
		self.tool_task:AddToUndoManager();
		self.tool_task = nil;
	end
	self.begin_x, self.begin_y, self.begin_z = nil, nil, nil;
	self.begin_side = nil;
end

function TerrainBrushTask:Run()
	curInstance = self;
	GameLogic.SetStatus(L"+/-键或Shift+滚轮改变半径");
	self.finished = false;
	self:LoadSceneContext();
	self:GetSceneContext():setMouseTracking(true);
	self:GetSceneContext():setCaptureMouse(true);
	self:SelectToolByName(self:GetToolName());
	self:ShowPage();
end

function TerrainBrushTask:OnExit()
	self:EndOperation();
	GameLogic.SetStatus(nil);
	self:SetFinished();
	ParaTerrain.DeselectAllBlock();
	self:UnloadSceneContext();
	self:CloseWindow();
	curInstance = nil;
end

function TerrainBrushTask:UpdateManipulators()
	self:DeleteManipulators();

	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TerrainBrush/TerrainBrushManipContainer.lua");
	local TerrainBrushManipContainer = commonlib.gettable("MyCompany.Aries.Game.Manipulators.TerrainBrushManipContainer");
	local manipCont = TerrainBrushManipContainer:new();
	manipCont:init();
	self:AddManipulator(manipCont);
	manipCont:connectToDependNode(self.item);
end

function TerrainBrushTask:Redo()
end

function TerrainBrushTask:Undo()
end

function TerrainBrushTask:ShowPage()
	NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
	local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
	local viewport = ViewportManager:GetSceneViewport();
	local parent = viewport:GetUIObject(true)

	local window = self:CreateGetToolWindow();
	window:Show({
		name="TerrainBrushTask", 
		url="script/apps/Aries/Creator/Game/Tasks/TerrainBrush/TerrainBrushTask.html",
		alignment="_ctb", left=0, top=-55, width = 256, height = 64, parent = parent
	});
end

function TerrainBrushTask:PickBlockAtMouse(result)
	local result = result or Game.SelectionManager:MousePickBlock(true, false, false);
	if(result.blockX) then
		local x,y,z = result.blockX,result.blockY,result.blockZ;
		local block_id, block_data = BlockEngine:GetBlockFull(x,y,z);
		if(block_id and block_id>0) then
			self.item:SetSelectedBlockId(block_id);
			self.item:SetSelectedBlockData(block_data);
		end
	end
end

function TerrainBrushTask:mousePressEvent(event)
	if(not GameLogic.GameMode:IsEditor()) then
		return;
	end
	if(event:button() == "left") then
		if(self:UpdateCenterPosition()) then
			if(event.alt_pressed and not event.shift_pressed) then
				self:PickBlockAtMouse();
			else
				self:BeginOperation();
				self:StepOperation(x,y,z);
			end
		end
		event:accept();
	else
		self:GetSceneContext():mousePressEvent(event);
	end
end

-- return true if position is set at current mouse position. 
function TerrainBrushTask:UpdateCenterPosition()
	local result = Game.SelectionManager:MousePickBlock(true, false, false);
	if(result.blockX) then
		local x,y,z = result.blockX,result.blockY,result.blockZ;
		local rx, ry, yz = BlockEngine:real_top(x,y,z);
		self.position:set(rx, ry, yz);
		self.item:SetPosition(self.position);
		self.last_side = result.side;
		return true;
	end
end

function TerrainBrushTask:mouseReleaseEvent(event)
	if(event:button() == "left") then
		self:EndOperation();
		event:accept();
	else
		self:GetSceneContext():mouseReleaseEvent(event);
	end
end

function TerrainBrushTask:mouseMoveEvent(event)
	if(self:UpdateCenterPosition()) then
		event:accept();
	else
		self:GetSceneContext():mouseMoveEvent(event);
	end
end

function TerrainBrushTask:mouseWheelEvent(event)
	if(event.shift_pressed) then
		-- shift+mousewheel to change radius size
		local delta = event:GetDelta();
		-- radius
		self.item:SetPenRadius(self.item:GetPenRadius()*(delta>0 and 1.1 or 0.9));
		event:accept();
	else
		self:GetSceneContext():mouseWheelEvent(event);
	end
end

function TerrainBrushTask:keyPressEvent(event)
	local dik_key = event.keyname;
	if(dik_key == "DIK_ADD" or dik_key == "DIK_EQUALS") then
		-- increase radius
		self.item:SetPenRadius(self.item:GetPenRadius()*1.1);
		event:accept();
	elseif(dik_key == "DIK_SUBTRACT" or dik_key == "DIK_MINUS") then
		-- decrease radius
		self.item:SetPenRadius(self.item:GetPenRadius()*0.9);
		event:accept();
	elseif(dik_key == "DIK_Z")then
		UndoManager.Undo();
		event:accept();
	elseif(dik_key == "DIK_Y")then
		UndoManager.Redo();
		event:accept();
	elseif(dik_key == "DIK_ESCAPE")then
		self:OnExit();
		event:accept();
		return;
	end
	self:GetSceneContext():keyPressEvent(event);
end