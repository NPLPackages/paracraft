--[[
Title: Select blocks task
Author(s): LiXizhi
Date: 2013/2/8
Desc: Ctrl+left click to select all blocks in the AABB. right click anywhere or esc key to deselect and exit the selection mode. 
when a group of blocks are selected, the following commands can be applied. 
   * hit the del key to delete all selected blocks. 
   * esc key to cancel selection.  
   * shift+left click a place to translate the current selection to a new position. (multiple clicks will create multiple copies)
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
local SelectBlocks = commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectBlocks");
local task = MyCompany.Aries.Game.Tasks.SelectBlocks:new({blockX = result.blockX,blockY = result.blockY, blockZ = result.blockZ, blocks=nil})
task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
NPL.load("(gl)script/ide/math/vector.lua");
NPL.load("(gl)script/ide/math/ShapeAABB.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TransformWnd.lua");
local TransformWnd = commonlib.gettable("MyCompany.Aries.Game.Tasks.TransformWnd");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local ShapeAABB = commonlib.gettable("mathlib.ShapeAABB");
local vector3d = commonlib.gettable("mathlib.vector3d");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");

local SelectBlocks = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectBlocks"));

SelectBlocks:Property({"PivotPoint", {0,0,0}, "GetPivotPoint", "SetPivotPoint"})
SelectBlocks:Property({"position", {0,0,0}, "GetPosition", "SetPosition"})
SelectBlocks:Property({"PivotPointColor", "#00ffff",})

SelectBlocks:Signal("valueChanged");

local groupindex_hint = 6; 

-- this is always a top level task. 
SelectBlocks.is_top_level = true;
-- picking filter
SelectBlocks.filter = 4294967295;
-- whether to use the player's y position as the pivot point. 
-- use "/UsePlayerPivotY" command
-- SelectBlocks.UsePlayerPivotY = true;

local cur_instance;
local cur_selection;
-- user can press Ctrl+D to select/deselect last selection. 
local last_instance;

-----------------------------------
-- select blocks class
-----------------------------------
function SelectBlocks:ctor()
	self.aabb = self.aabb or ShapeAABB:new();
	-- all blocks that is being selected. 
	self.blocks = self.blocks or {};
	self.cursor = vector3d:new();
	self.PivotPoint = vector3d:new(0,0,0);
	self.position = vector3d:new(0,0,0);

	GameLogic.GetFilters():add_filter("file_exported", SelectBlocks.filter_file_exported);
end

-- filter callback
function SelectBlocks.filter_file_exported(id, filename)
	local self = cur_instance;
	if(not self) then
		return id;
	end
	if(id == "bmax" and filename) then
		GameLogic.RunCommand(string.format("/take BlockModel {tooltip=%q}", filename));
	end
	SelectBlocks.CancelSelection();
	return id;
end

-- static function
function SelectBlocks.GetCurrentSelection()
	return cur_selection;
end

-- static function
function SelectBlocks.GetCurrentInstance()
	return cur_instance;
end

-- static function
function SelectBlocks.GetLastInstance()
	return last_instance;
end

-- static function
function SelectBlocks.ToggleLastInstance()
	if(SelectBlocks.GetLastInstance() == SelectBlocks.GetCurrentInstance()) then
		SelectBlocks.CancelSelection();
	elseif(SelectBlocks.GetLastInstance()) then
		SelectBlocks.GetLastInstance():Run(true);
	end
end

function SelectBlocks.RegisterHooks()
	local self = cur_instance;
	self.sceneContext = self.sceneContext or Game.SceneContext.RedirectContext:new():RedirectInput(self);
	self.sceneContext:activate();
	self.sceneContext:UpdateManipulators();
end

function SelectBlocks.UnregisterHooks()
	local self = cur_instance;
	if(self and self.sceneContext) then
		self.sceneContext:close();
	end
	ParaTerrain.DeselectAllBlock(groupindex_hint);
	GameLogic.AddBBS("SelectBlocks", nil);
end

-- redirected function from self.sceneContext:UpdateManipulators()
function SelectBlocks:UpdateManipulators()
	self.sceneContext:DeleteManipulators();

	NPL.load("(gl)script/ide/System/Scene/Manipulators/BlockPivotManipContainer.lua");
	local BlockPivotManipContainer = commonlib.gettable("System.Scene.Manipulators.BlockPivotManipContainer");
	local manipCont = BlockPivotManipContainer:new()
	manipCont.radius = 0.5;

	manipCont.xColor = self.PivotPointColor;
	manipCont.yColor = self.PivotPointColor;
	manipCont.zColor = self.PivotPointColor;
	-- manipCont.showArrowHead = false;
	manipCont:init();
	manipCont:SetPivotPointPlugName("PivotPoint");
	self.sceneContext:AddManipulator(manipCont);
	manipCont:connectToDependNode(self);

	local BlockPivotManipContainer = commonlib.gettable("System.Scene.Manipulators.BlockPivotManipContainer");
	local manipCont = BlockPivotManipContainer:new():init();
	manipCont:SetPivotPointPlugName("position");
	self.sceneContext:AddManipulator(manipCont);
	-- Use first block as position.
	local b = self.blocks[1];
	if(b) then
		self:SetManipulatorPosition({b[1], b[2], b[3]});
	elseif(self.blockX) then
		self:SetManipulatorPosition({self.blockX, self.blockY, self.blockZ});
	end
	manipCont:connectToDependNode(self);
end

-- change manipulator position, but does not translate the blocks
function SelectBlocks:SetManipulatorPosition(vec)
	if(vec and not self.position:equals(vec)) then
		self.position:set(vec);
		self:valueChanged();
	end
end

-- translate blocks to a new position.  This function is mostly called from the translate manipulator.
-- use SetManipulatorPosition() if one only wants to change the manipulator display location. 
function SelectBlocks:SetPosition(vec)
	if(vec and not self.position:equals(vec)) then
		local dx, dy, dz = vec[1] - self.position[1], vec[2] - self.position[2], vec[3] - self.position[3];
		self.position:set(vec);
		self:valueChanged();

		if(not TransformWnd:IsVisible()) then
			SelectBlocks.ShowTransformWnd();
		end
		TransformWnd:Translate(dx, dy, dz);
		GameLogic.AddBBS("SelectBlocks", L"回车键确认操作");
	end
end

function SelectBlocks:GetPosition()
	return self.position;
end

-- set pivot point vector3d in block coordinate system
function SelectBlocks:SetPivotPoint(vec)
	if(not vec) then
		vec = {EntityManager.GetPlayer():GetBlockPos()};
	end
	if(not self.PivotPoint:equals(vec)) then
		self.PivotPoint:set(vec);
		SelectBlocks.GetEventSystem():DispatchEvent({type = "OnSelectionChanged" , data = "pivot"});
		self:valueChanged();
	end
end

-- get pivot point vector3d in block coordinate system
function SelectBlocks:GetPivotPoint()
	return self.PivotPoint;
end

function SelectBlocks:CheckCanSelectNow()
	if(not TaskManager.AddTask(self)) then
		-- ignore the task if there is other top-level tasks, unless it is also SelectBlock tasks
		local task = TaskManager.GetTopLevelTask();
		if(task and task:isa(SelectBlocks)) then
			if(self.blockX) then
				task.aabb:SetPointAABB(vector3d:new({self.blockX,self.blockY,self.blockZ}))
				task:RefreshDisplay();
				SelectBlocks.UpdateBlockNumber(#(task.blocks));
			end
		end
		return;
	end
	return true;
end

function SelectBlocks:PrepareData()
	if(self.blockX) then
		self.aabb:SetPointAABB(vector3d:new({self.blockX,self.blockY,self.blockZ}))
		self:RefreshDisplay()
	else
		self.aabb:SetInvalid();
		if(#(self.blocks) > 0) then
			self.need_refresh = false;
			ParaTerrain.DeselectAllBlock();

			local _, b;
			b = self.blocks[1];
			local min_x, min_y, min_z = b[1], b[2], b[3];
			local max_x, max_y, max_z = min_x, min_y, min_z;

			
			for _, b in ipairs(self.blocks) do
				local x, y, z = b[1], b[2], b[3]
				b[4] = b[4] or ParaTerrain.GetBlockTemplateByIdx(x,y,z);
				b[5] = b[5] or ParaTerrain.GetBlockUserDataByIdx(x,y,z);
				
				if(x < min_x) then
					min_x = x;
				end
				if(y < min_y) then
					min_y = y;
				end
				if(z < min_z) then
					min_z = z;
				end

				if(x > max_x) then
					max_x = x;
				end
				if(y > max_y) then
					max_y = y;
				end
				if(z > max_z) then
					max_z = z;
				end
				ParaTerrain.SelectBlock(x, y, z, true);
			end
			self.aabb:SetMinMax(vector3d:new({min_x, min_y, min_z}), vector3d:new({max_x, max_y, max_z}));
		end
	end
end

-- @param bIsDataPrepared: true if data is prepared. if nil, we will prepare the data from input params.
function SelectBlocks:Run(bIsDataPrepared)
	if(not self:CheckCanSelectNow()) then
		return;
	end
	cur_instance = self;
	last_instance = self;

	if(not bIsDataPrepared) then
		self:PrepareData();
	else
		self:RefreshDisplay();
	end

	cur_selection = self.blocks;
	SelectBlocks.finished = false;
	SelectBlocks.RegisterHooks();
	SelectBlocks.ShowPage();
	self:SetPivotPoint();

	if(#(self.blocks) > 0) then
		SelectBlocks.UpdateBlockNumber(#(self.blocks));
	end
end

function SelectBlocks:ReplaceSelection(blocks)
	if(not blocks) then
		return;
	end
	ParaTerrain.DeselectAllBlock();
	self.blocks = blocks;
	cur_selection = blocks;
end


-- @param bCommitChange: true to commit all changes made 
function SelectBlocks.CancelSelection()
	SelectBlocks.finished = true;
	ParaTerrain.DeselectAllBlock();
	SelectBlocks.UnregisterHooks();
	SelectBlocks.ClosePage();

	-- canceled the selection. 	
	cur_selection = nil;

	if(cur_instance) then
		local self = cur_instance;
		cur_instance = nil;
	end
end

function SelectBlocks:Redo()
end

function SelectBlocks:Undo()
end

-- refresh the 3d view 
function SelectBlocks:RefreshDisplay(bImmediateUpdate)
	self.need_refresh = true;
	self.blocks = {};
	cur_selection = self.blocks;
	ParaTerrain.DeselectAllBlock();
	self.cursor = self.aabb:GetMin();
	self.min = self.aabb:GetMin();
	self.max = self.aabb:GetMax();
	if(bImmediateUpdate) then
		self:RefreshImediately();
	end
end

function SelectBlocks:RefreshImediately()
	while(self.need_refresh) do
		self:FrameMove();
	end
end

-- static function:
-- select all blocks connected with current selection but not below current selection. 
-- @param max_new_count: max number of blocks to be added. default to 20000
function SelectBlocks.SelectAll(bImmediateUpdate, max_new_count)
	max_new_count = max_new_count or 20000;
	local self = cur_instance;
	if(not self) then
		return
	end 
	local baseBlockCount = #(self.blocks);
	local blockIndices = {}; -- mapping from block index to true for processed bones
	local block = self.blocks[1];
	if(not block) then
		return;
	end
	local cx, cy, cz = block[1], block[2], block[3];
	local min_y = 9999;
	for i, block in ipairs(self.blocks) do
		local x, y, z = block[1], block[2], block[3];
		local boneIndex = BlockEngine:GetSparseIndex(x-cx,y-cy,z-cz)
		blockIndices[boneIndex] = true;
		if(y < min_y) then
			min_y = y;
		end
	end
	local function IsBlockProcessed(x, y, z)
		local boneIndex = BlockEngine:GetSparseIndex(x-cx,y-cy,z-cz);
		return blockIndices[boneIndex];
	end
	local newlyAddedCount = 0;
	local function AddBlock(x, y, z)
		local boneIndex = BlockEngine:GetSparseIndex(x-cx,y-cy,z-cz)
		if(not blockIndices[boneIndex]) then
			blockIndices[boneIndex] = true;
			local block_id = ParaTerrain.GetBlockTemplateByIdx(x,y,z);
			if(block_id > 0) then
				local block = block_types.get(block_id);
				if(block) then
					local block_data = ParaTerrain.GetBlockUserDataByIdx(x,y,z);
					self:SelectSingleBlock(x,y,z, block_id, block_data);
					newlyAddedCount = newlyAddedCount + 1;
					return true;
				end
			end
		end
	end
	local breadthFirstQueue = commonlib.Queue:new();
	local function AddConnectedBlockRecursive(cx,cy,cz)
		if(newlyAddedCount < max_new_count) then
			for side=0,5 do
				local dx, dy, dz = Direction.GetOffsetBySide(side);
				local x, y, z = cx+dx, cy+dy, cz+dz;
				if(y >= min_y and AddBlock(x, y, z)) then
					breadthFirstQueue:pushright({x,y,z});
				end
			end
		end
	end
	
	for i = 1, baseBlockCount do
		local block = self.blocks[i];
		local x, y, z = block[1], block[2], block[3];
		AddConnectedBlockRecursive(x,y,z);
	end

	while (not breadthFirstQueue:empty()) do
		local block = breadthFirstQueue:popleft();
		AddConnectedBlockRecursive(block[1], block[2], block[3]);
	end

	self:OnSelectionRefreshed();
	SelectBlocks.UpdateBlockNumber(#(self.blocks));
end

-- return a table containing all blocks that has been selected. 
-- if may return nil if no blocks are selected or not all blocks have finished iterating and marked. 
function SelectBlocks:GetAllBlocks()
	if(not self.need_refresh) then
		return self.blocks;
	end
end

-- get block id
-- @param typeIndex: the type id. 1 is first type, 2 is second type. 
function SelectBlocks.GetBlockId(typeIndex)
	if(cur_instance) then
		local self = cur_instance;
		local nCurType = 0;
		local nLastTypeId;
		for i, b in ipairs(self.blocks) do
			if(nLastTypeId ~= b[4]) then
				nLastTypeId = b[4];
				nCurType = nCurType + 1;
				if(nCurType == typeIndex) then
					return nLastTypeId;
				end
			end
		end
		if(#(self.blocks) >= typeIndex) then
			return nLastTypeId
		end
	end
end

-- add a single block to selection. 
function SelectBlocks:SelectSingleBlock(x,y,z, block_id, block_data)
	self.blocks[#(self.blocks)+1] = {x,y,z, block_id, block_data};
	ParaTerrain.SelectBlock(x,y,z,true);
end

-- highligh all blocks that are selected. Each frame we will only select a limited number of blocks for framerate. 
function SelectBlocks:FrameMove()
	local min, max, cursor = self.min, self.max, self.cursor;
	if(not self.need_refresh or not min or not cursor) then
		return;
	end

	-- already selected all;
	--if(self.max and self.cursor and cursor:equals(max) ) then
		--return;
	--end

	local x,y,z = cursor[1], cursor[2], cursor[3];

	local count = 0;
	local max_block_per_frame = 500;

	local function TryAddBlock(x,y,z)
		cursor[1], cursor[2], cursor[3] = x,y,z
		local block_id = ParaTerrain.GetBlockTemplateByIdx(x,y,z);
		if(block_id > 0) then
			local block = block_types.get(block_id);
			if(block) then
				-- TODO: check for tasks
				count = count + 1;

				if(count < max_block_per_frame) then
					local block_data = ParaTerrain.GetBlockUserDataByIdx(x,y,z);
					self:SelectSingleBlock(x,y,z, block_id, block_data);
					return true;
				else
					return false;
				end
			end
		end

	end

	
	for x = cursor[1], max[1] do
		if(TryAddBlock(x,y,z) == false) then
			return;
		end
	end

	for z = cursor[3]+1, max[3] do
		for x = min[1], max[1] do
			if(TryAddBlock(x,y,z) == false) then
				return;
			end
		end
	end

	for y = cursor[2]+1, max[2] do
		for z = min[3], max[3] do
			for x = min[1], max[1] do
				if(TryAddBlock(x,y,z) == false) then
					return;
				end
			end
		end
	end
	
	if(cursor:equals(max)) then
		self:OnSelectionRefreshed();
		SelectBlocks.UpdateBlockNumber(#(self.blocks));
	end
end

function SelectBlocks:OnSelectionRefreshed()
	self.need_refresh = nil;
	SelectBlocks.GetEventSystem():DispatchEvent({type = "OnSelectionChanged" , data = "pivot"});
end

function SelectBlocks:OnExit()
	SelectBlocks.GetEventSystem():ClearAllEvents();
	SelectBlocks.CancelSelection();
end

-- filter only blocks of the given type in selection. 
function SelectBlocks.FilterOnlyBlock(x, y, z)
	local self = cur_instance;
	if(not self) then
		return
	end 
	local block_id = BlockEngine:GetBlockId(x,y,z);
	local blocks = {};
	ParaTerrain.DeselectAllBlock();
	
	for i, b in pairs(self.blocks) do
		if(b[4] == block_id) then
			blocks[#blocks+1] = b;
			ParaTerrain.SelectBlock(b[1],b[2],b[3],true);
		end
	end
	self.blocks = blocks;
	cur_selection = blocks;
	SelectBlocks.UpdateBlockNumber(#(blocks));
	self:OnSelectionRefreshed();
end

function SelectBlocks:mouseWheelEvent(event)
	-- disable other mouse wheel event 
	if(self.sceneContext) then
		self.sceneContext:handleCameraWheelEvent(event);
	end
end

function SelectBlocks:handleLeftClickScene(event)
	local self = cur_instance;
	local ctrl_pressed = event.ctrl_pressed;
	local alt_pressed = event.alt_pressed;
	local shift_pressed = event.shift_pressed;

	if(ctrl_pressed) then
		-- pick any scene object
		local result = {};
		result = ParaTerrain.MousePick(GameLogic.GetPickingDist(), result, self.filter);
		
		if(result.blockX) then
			if(shift_pressed) then
				-- ctrl+shift+ left click to toggle a single block's selection state
				SelectBlocks.ToggleBlockSelection(result.blockX,result.blockY,result.blockZ)
			elseif(alt_pressed) then
				-- ctrl+alt+ left click to filter the given block in the current selection. 
				SelectBlocks.FilterOnlyBlock(result.blockX,result.blockY,result.blockZ)
			else
				SelectBlocks.ExtendAABB(result.blockX,result.blockY,result.blockZ)
				self:SetManipulatorPosition({result.blockX,result.blockY,result.blockZ});
			end
		end
	elseif(alt_pressed) then
		local result = {};
		result = ParaTerrain.MousePick(GameLogic.GetPickingDist(), result, self.filter);

		if(result.blockX) then
			self:SetPivotPoint({result.blockX,result.blockY,result.blockZ});
		end

	elseif(shift_pressed) then
		local result = Game.SelectionManager:MousePickBlock();

		if(result.blockX) then
			local x,y,z
			if(result.side) then
				x,y,z = BlockEngine:GetBlockIndexBySide(result.blockX,result.blockY,result.blockZ,result.side);
			else
				x,y,z = result.blockX,result.blockY,result.blockZ;
			end

			local pivot_x, pivot_y, pivot_z = self:GetSelectionPivot();
			local dx, dy, dz = x - pivot_x,y - pivot_y,z - pivot_z;
			if (dx~=0 or dy ~=0 or dz~=0) then
				SelectBlocks.TransformSelection(dx,dy,dz);
				self.aabb:Offset(dx,dy,dz);
			end
		end	
	else
		-- clicking without ctrl key will cancel the selection mode. 
		SelectBlocks.CancelSelection();
	end
end

function SelectBlocks:keyPressEvent(event)
	local dik_key = event.keyname;

	if(dik_key == "DIK_ESCAPE")then
		-- cancel selection. 
		SelectBlocks.CancelSelection();
	elseif(dik_key == "DIK_DELETE" or dik_key == "DIK_DECIMAL")then
		SelectBlocks.DeleteSelection();
	elseif(dik_key == "DIK_EQUALS")then
		if(event.ctrl_pressed) then
			SelectBlocks.TransformSelection(nil,nil,nil, nil, 2,2,2)
		else
			SelectBlocks.AutoExtrude(true);
		end
	elseif(dik_key == "DIK_MINUS")then
		if(event.ctrl_pressed) then
			SelectBlocks.TransformSelection(nil,nil,nil, nil, 0.5, 0.5, 0.5)
		else
			SelectBlocks.AutoExtrude(false);
		end
	elseif(dik_key == "DIK_LBRACKET")then
		SelectBlocks.TransformSelection(nil,nil,nil, 1.57)
	elseif(dik_key == "DIK_RBRACKET")then
		SelectBlocks.TransformSelection(nil,nil,nil, -1.57)
	elseif(dik_key == "DIK_A" and event.ctrl_pressed)then
		SelectBlocks.SelectAll(true)
	elseif(dik_key == "DIK_C" or dik_key == "DIK_V" or dik_key == "DIK_X" )then
		if(event.ctrl_pressed) then
			if(dik_key == "DIK_C")then
				self:CopyBlocks();
			elseif(dik_key == "DIK_X")then
				self:CopyBlocks(true);
			else
				self:PasteBlocks();
			end
		end
	elseif(dik_key == "DIK_Z")then
		if(event.ctrl_pressed) then
			self:PopAABB();
		elseif(dik_key == "DIK_Z") then
			UndoManager.Undo();
		end
	elseif(dik_key == "DIK_Y")then
		UndoManager.Redo();
	elseif(dik_key == "DIK_RETURN" or dik_key == "DIK_NUMPADENTER")then
		if(TransformWnd:IsVisible()) then
			TransformWnd.TransformSelection();
			event:accept();
		end
	else
		self.sceneContext:keyPressEvent(event);
	end	
end

------------------------
-- page function 
------------------------
local page;
function SelectBlocks.ShowPage(bShow)
	SelectBlocks.selected_count = 0;
	-- display a page containing all operations that can apply to current selection, like deletion, extruding, coloring, etc. 
	local x, y, width, height = 0, 160, 120, 330;
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.html", 
			name = "SelectBlocksTask.ShowPage", 
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			isShowTitleBar = false,
			DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
			style = CommonCtrl.WindowFrame.ContainerStyle,
			zorder = 1,
			allowDrag = false,
			click_through = true,
			directPosition = true,
				align = "_lt",
				x = x,
				y = y,
				width = width,
				height = height,
		});
	MyCompany.Aries.Creator.ToolTipsPage.ShowPage(false);
	GameLogic:UserAction("select blocks");
end

function SelectBlocks.ShowEditPage()
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Tasks/SelectBlocksEditor.mobile.html", 
			name = "SelectBlocksTask.ShowEditPage", 
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			isShowTitleBar = false,
			DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
			style = CommonCtrl.WindowFrame.ContainerStyle,
			zorder = -2,
			allowDrag = false,
			click_through = true,
			directPosition = true,
				align = "_ct",
				x = -340/2,
				y = -290/2,
				width = 340,
				height = 290,
		});
end

function SelectBlocks.ClosePage()
	if(page) then
		page:CloseWindow();
	end
end

-- update the block number in the left panel page. 
function SelectBlocks.UpdateBlockNumber(count)
	if(page) then
		if(SelectBlocks.selected_count ~= count) then
			if( not (count > 1 and SelectBlocks.selected_count>1) ) then
				SelectBlocks.selected_count = count;
				page:Refresh(0.01);
			else
				SelectBlocks.selected_count = count;
				page:SetUIValue("title", format(L"选中了%d块",count or 1));
			end
		end
	end
end


function SelectBlocks.OnInit()
	page = document:GetPageCtrl();
	if(System.options.mc) then
		page.OnClose = function () 
			TransformWnd.ClosePage();
			
			NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/MirrorWnd.lua");
			local MirrorWnd = commonlib.gettable("MyCompany.Aries.Game.GUI.MirrorWnd");
			MirrorWnd.ClosePage();
		end	
	end
end

function SelectBlocks.GetEventSystem()
	SelectBlocks.events = SelectBlocks.events or commonlib.EventSystem:new();
	return SelectBlocks.events;
end

function SelectBlocks.DoClick(name)
	local self = SelectBlocks;
	if(name == "delete")then
		self.DeleteSelection()
	elseif(name == "btn_selectall")then
		self.SelectAll(true);
	elseif(name == "save_template" or name == "btn_template")then
		GameLogic.RunCommand("export");
		-- self.SaveToTemplate();
	elseif(name == "extrude_negY")then
		self.AutoExtrude(false);
	elseif(name == "extrude_posY")then
		-- can we scale like vectors so that we can resize a hollow room without making the wall thicke?
		self.AutoExtrude(true);
	elseif(name == "btnTransform" or name == "btn_transform")then
		SelectBlocks.ShowTransformWnd();
	elseif(name == "left_rot" or name == "btn_rotate_left")then
		SelectBlocks.TransformSelection(nil,nil,nil, 1.57)
	elseif(name == "right_rot" or name == "btn_rotate_right")then
		SelectBlocks.TransformSelection(nil,nil,nil, -1.57)
	elseif(name == "dx_positive" or name == "btn_moveto_front")then
		SelectBlocks.TransformSelection(1,nil,nil)
	elseif(name == "dx_negative" or name == "btn_moveto_back")then
		SelectBlocks.TransformSelection(-1,nil,nil)
	elseif(name == "dy_positive" or name == "btn_moveto_up")then
		SelectBlocks.TransformSelection(nil,1,nil)
	elseif(name == "dy_negative" or name == "btn_moveto_down")then
		SelectBlocks.TransformSelection(nil,-1,nil)
	elseif(name == "dz_positive" or name == "btn_moveto_left")then
		SelectBlocks.TransformSelection(nil,nil, 1)
	elseif(name == "dz_negative" or name == "btn_moveto_right")then
		SelectBlocks.TransformSelection(nil,nil, -1)
	elseif(name == "dz_negative" or name == "btn_mirror")then
		SelectBlocks.MirrorSelection()
	end
end

-- get the pivot point at the bottom center of the aabb
function SelectBlocks:GetSelectionPivot()
	local mCenter = self.aabb:GetCenter();
	local mMin = self.aabb:GetMin();
	mCenter[2] = mMin[2];
	return math.floor(mCenter[1]), math.floor(mCenter[2]), math.floor(mCenter[3]);
end

-- get the current selected blocks and pivot
-- @return blocks, pi
function SelectBlocks:GetSelectedBlocks()
	return cur_selection;
end

-- Get a copy of blocks including block's server data
-- @param pivot: the pivot point vector, if nil, it will default to self:GetPivotPoint()
-- this can be {0,0,0} which will retain absolute position. 
-- @return blocks: array of {x,y,z,id, data, entity_data}
function SelectBlocks:GetCopyOfBlocks(pivot)
	pivot = pivot or self:GetPivotPoint()
	local pivot_x,pivot_y,pivot_z = unpack(pivot);
	
	self:UpdateSelectionEntityData();

	local blocks = {};
	for i = 1, #(cur_selection) do
		-- x,y,z,block_id, data, serverdata
		local b = cur_selection[i];
		blocks[i] = {b[1]-pivot_x, b[2]-pivot_y, b[3]- pivot_z, b[4], if_else(b[5] == 0, nil, b[5]), b[6]};
	end
	return blocks;
end

function SelectBlocks.SaveToTemplate()
	if(cur_selection and cur_instance) then
		local self = cur_instance;

		-- all relative to pivot point. 
		local pivot_x, pivot_y, pivot_z = self:GetSelectionPivot();
		if(self.UsePlayerPivotY) then
			local x,y,z = ParaScene.GetPlayer():GetPosition();
			local _, by, _ = BlockEngine:block(0,y+0.1,0);
			pivot_y = by;
		end
		local pivot = {pivot_x, pivot_y, pivot_z};

		local blocks = self:GetCopyOfBlocks(pivot);
		
		NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BlockTemplatePage.lua");
		local BlockTemplatePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BlockTemplatePage");
		BlockTemplatePage.ShowPage(true, blocks, pivot);
	end
end

function SelectBlocks:PushAABB()
	self.history_aabbs = self.history_aabbs or commonlib.List:new();
	
	if(self.aabb) then
		local aabb = self.history_aabbs:last();
		if(not aabb or not self.aabb:equals(aabb.aabb)) then
			self.history_aabbs:push_back({aabb=self.aabb:clone()});
		end
	end
end

function SelectBlocks:PopAABB()
	if(self.history_aabbs) then
		local aabb = self.history_aabbs:last();
		if(aabb) then
			self.history_aabbs:remove(aabb);
			self.aabb = aabb.aabb;
			self:RefreshDisplay();
		end
	end
end

-- toggle block selection. 
function SelectBlocks.ToggleBlockSelection(x,y,z)
	local self = cur_instance;
	if(not self) then
		return
	end 
	
	for i, block in pairs(self.blocks) do
		if(block[1] == x and block[2] == y and block[3] == z) then
			commonlib.removeArrayItem(self.blocks, i);
			ParaTerrain.SelectBlock(x,y,z,false);
			SelectBlocks.UpdateBlockNumber(#(self.blocks));
			return;
		end
	end
	self:SelectSingleBlock(x,y,z, BlockEngine:GetBlockId(x,y,z), BlockEngine:GetBlockData(x,y,z));
	SelectBlocks.UpdateBlockNumber(#(self.blocks));
end

-- extend AABB
function SelectBlocks.ExtendAABB(bx,by,bz, bImmediateUpdate )
	local self = cur_instance;
	if(not self) then
		return
	end 

	if(bx) then
		if(by<0) then
			by = 0;
		end
		if(by>=256) then
			by = 255;
		end
		self:PushAABB();
		if(self.aabb:Extend(vector3d:new({bx,by,bz}))) then
			self:RefreshDisplay(bImmediateUpdate);
		end
	end
end

-- automatically extruding according to a direction. The chosen direction is always the direction which the lagest aabb extent. 
-- @param isPositiveDirection:true for positive direction. 
function SelectBlocks.AutoExtrude(isPositiveDirection)
	if(cur_instance and cur_instance.aabb and cur_instance.aabb:IsValid() and #cur_selection > 0) then
		local self = cur_instance;
		local mExtents = cur_instance.aabb.mExtents;
		if(mExtents) then
			local dx,dy,dz = 0,0,0;
			local params = {blocks = cur_selection};
			-- extending according to whichever direction has most blocks. 
			if(mExtents[2] <= mExtents[1] and mExtents[2] <= mExtents[3]) then
				dy = if_else(isPositiveDirection, 1, -1);
			elseif(mExtents[1] <= mExtents[2] and mExtents[1] <= mExtents[3]) then
				dx = if_else(isPositiveDirection, 1, -1);
			elseif(mExtents[3] <= mExtents[2] and mExtents[3] <= mExtents[1]) then
				dz = if_else(isPositiveDirection, 1, -1);
			end

			SelectBlocks.ExtrudeSelection(dx,dy,dz);
		end
	end
end

function SelectBlocks.ExtrudeSelection(dx, dy, dz)
	if(cur_instance and cur_instance.aabb and cur_instance.aabb:IsValid() and #cur_selection > 0) then
		local self = cur_instance;
		dx,dy,dz = (dx or 0), (dy or 0), (dz or 0);
		self.px, self.py, self.pz = (self.px or 0), (self.py or 0), (self.pz or 0);
		if( (dx~=0) or (dy~=0) or (dz~=0)) then
			self:UpdateSelectionEntityData();
			local params = {blocks = cur_selection};

			-- tricky: only allow extruding one direction.
			if(self.px*dx <= 0) then
				self.px = 0
			end
			if(self.py*dy <= 0) then
				self.py = 0;
			end
			if(self.pz*dz <= 0) then
				self.pz = 0;
			end

			self.px = self.px + dx;
			params.dx = self.px;

			self.py = self.py + dy;
			params.dy = self.py;

			self.pz = self.pz + dz;
			params.dz = self.pz;

			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ExtrudeBlocksTask.lua");
			local task = MyCompany.Aries.Game.Tasks.ExtrudeBlocks:new(params)
			task:Run();
		end
	end
end

-- global function to delete a group of blocks. 
-- @param bFastDelete: if true, we will delete blocks without generating new undergound blocks. 
function SelectBlocks.DeleteSelection(bFastDelete)
	if(bFastDelete) then
		SelectBlocks.FillSelection(0);

	elseif(cur_selection and #cur_selection > 0) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DestroyNearbyBlocksTask.lua");
		local task = MyCompany.Aries.Game.Tasks.DestroyNearbyBlocks:new({
			explode_time=200, 
			destroy_blocks = cur_selection,
		})
		SelectBlocks.CancelSelection();
		task:Run();
	end
end

-- update entity data for each selected block
function SelectBlocks:UpdateSelectionEntityData()
	if(#cur_selection > 0) then
		for i = 1, #(cur_selection) do
			-- x,y,z,block_id, data, serverdata
			local b = cur_selection[i];
			b[6] = BlockEngine:GetBlockEntityData(b[1], b[2], b[3]);
		end
	end
end

function SelectBlocks:CopyBlocks(bRemoveOld)
	if(self.aabb:IsValid() and #cur_selection > 0) then
		local mExtents = self.aabb.mExtents;
		local center = self.aabb:GetCenter();

		self:UpdateSelectionEntityData();

		self.copy_task = { blocks = commonlib.copy(cur_selection), aabb = cur_instance.aabb:clone()};

		if(not bRemoveOld) then
			self.copy_task.operation = "add";
		end

		BroadcastHelper.PushLabel({id="BuildMinimap", label = L"保存成功! Ctrl+V在鼠标所在位置粘贴！", max_duration=5000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
	end
end

-- paste at current mouse position
-- @param bx, by, bz: center of the blocks. if nil, the current mouse pick block is used. 
function SelectBlocks:PasteBlocks(bx, by, bz)
	if(not self.copy_task) then
		self:CopyBlocks();
	end

	if(self.copy_task) then
		local copy_task = {blocks = self.copy_task.blocks, aabb =  self.copy_task.aabb:clone(), operation = self.copy_task.operation};
		
		if(not bx) then
			local result = Game.SelectionManager:MousePickBlock();
			if(result.blockX and result.side) then
				bx, by, bz = BlockEngine:GetBlockIndexBySide(result.blockX, result.blockY, result.blockZ, result.side)
				copy_task.x, copy_task.y, copy_task.z = bx, by, bz;
			end
		end

		if(copy_task.x) then
			-- whether to confirm with ui
			local g_bUI_Confirm = true;
			if(g_bUI_Confirm) then
				self:SetManipulatorPosition({bx, by, bz});
				
				NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TransformBlocksTask.lua");
				local dx,dy,dz = MyCompany.Aries.Game.Tasks.TransformBlocks:GetDeltaPosition(copy_task.x,copy_task.y,copy_task.z, copy_task.aabb);
				
				TransformWnd.ShowPage(copy_task.blocks, {x=dx, y=dy, z=dz, facing=0, method=copy_task.operation}, function(trans, res)
					if(trans and res == "ok") then
						copy_task.dx = trans.x;
						copy_task.dy = trans.y;
						copy_task.dz = trans.z;
						copy_task.x,copy_task.y,copy_task.z = nil, nil, nil;
						copy_task = MyCompany.Aries.Game.Tasks.TransformBlocks:new(copy_task);
						copy_task:Run();
					end
				end)
			else
				NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TransformBlocksTask.lua");
				copy_task = MyCompany.Aries.Game.Tasks.TransformBlocks:new(copy_task);
				copy_task:Run();
			end
			if(self.copy_task.operation == "move") then
				self.copy_task.operation = "add";
			end
		end
	end
end

local function OnMirrorSelectionChanged()
	local self = cur_instance;
	if(self and cur_selection) then
		local pivot_x,pivot_y,pivot_z = unpack(self:GetPivotPoint());
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/MirrorWnd.lua");
		local MirrorWnd = commonlib.gettable("MyCompany.Aries.Game.GUI.MirrorWnd");

		MirrorWnd.UpdateHintLocation(cur_selection, pivot_x, pivot_y, pivot_z);
	end
end

function SelectBlocks.MirrorSelection()
	local self = cur_instance;
	if(self) then
		local pivot_x,pivot_y,pivot_z = unpack(self:GetPivotPoint());
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/MirrorWnd.lua");
		local MirrorWnd = commonlib.gettable("MyCompany.Aries.Game.GUI.MirrorWnd");
		
		SelectBlocks.GetEventSystem():AddEventListener("OnSelectionChanged", OnMirrorSelectionChanged, nil, "MirrorWnd");

		MirrorWnd.ShowPage(cur_selection, pivot_x,pivot_y,pivot_z, function(settings, result)
			SelectBlocks.GetEventSystem():RemoveEventListener("OnSelectionChanged", OnMirrorSelectionChanged);
			if(result) then
				NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MirrorBlocksTask.lua");
				local task = MyCompany.Aries.Game.Tasks.MirrorBlocks:new({method=settings.method, from_blocks=MirrorWnd.blocks, pivot_x=MirrorWnd.pivot_x,pivot_y=MirrorWnd.pivot_y,pivot_z=MirrorWnd.pivot_z, mirror_axis=settings.xyz, })
				task:Run();
			end
		end);
	end
end

local function OnTransformSelectionChanged()
	local self = cur_instance;
	if(self and cur_selection) then
		TransformWnd.UpdateHintLocation(cur_selection);
	end
end

function SelectBlocks.ShowTransformWnd()
	if(cur_instance and cur_instance.aabb and cur_instance.aabb:IsValid() and #cur_selection > 0) then
		local self = cur_instance;
		
		SelectBlocks.GetEventSystem():AddEventListener("OnSelectionChanged", OnTransformSelectionChanged, nil, "TransformWnd");
		TransformWnd.ShowPage(cur_selection, {x=0, y=0, z=0, facing=0}, function(trans, res)
			SelectBlocks.GetEventSystem():RemoveEventListener("OnSelectionChanged", OnTransformSelectionChanged);
			if(trans and res == "ok") then
				SelectBlocks.TransformSelection(trans.x, trans.y, trans.z, trans.facing*3.14/180, trans.scalingX, trans.scalingY, trans.scalingZ, trans.method);
			end
		end)
	end
end

-- @param method: nil or "clone"
function SelectBlocks.TransformSelection(dx,dy,dz, rot_y, scalingX, scalingY, scalingZ, method)
	if(cur_instance and cur_instance.aabb and cur_instance.aabb:IsValid() and #cur_selection > 0) then
		local self = cur_instance;
		local mExtents = cur_instance.aabb.mExtents;

		local shift_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LSHIFT) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RSHIFT);
		if(not shift_pressed) then
			self:UpdateSelectionEntityData();
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TransformBlocksTask.lua");
			local task = MyCompany.Aries.Game.Tasks.TransformBlocks:new({dx = dx, dy=dy, dz=dz, rot_y=rot_y, scalingX=scalingX, scalingY=scalingY, scalingZ=scalingZ, blocks=cur_selection, aabb=cur_instance.aabb, operation = method})
			task:Run();

			self:ReplaceSelection(commonlib.clone(task.final_blocks));
		else
			-- if shift is pressed, we will extrude
			SelectBlocks.ExtrudeSelection(dx, dy, dz);
		end
	end
end

function SelectBlocks.ConvertBlocksToRealTerrain()
	if(cur_instance and cur_instance.aabb and cur_instance.aabb:IsValid() and #cur_selection > 0) then
		local self = cur_instance;
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateTerrainHoleTask.lua");

		local mExtents = self.aabb.mExtents;
		local center = self.aabb:GetCenter();

		local task = MyCompany.Aries.Game.Tasks.CreateTerrainHole:new({operation="BlocksToRealTerrain", 
			blockX = center[1], blockY = center[2], blockZ = center[3], 
		});
		task:Run();
	end
end

function SelectBlocks.EnterNeuronEditMode()
	if(cur_instance) then
		local self = cur_instance;
		local bx, by, bz = self.blockX, self.blockY, self.blockZ;
		SelectBlocks.CancelSelection();
		TaskManager.RemoveTask(self);

		NPL.load("(gl)script/apps/Aries/Creator/Game/Neuron/EditNeuronBlockPage.lua");
		local EditNeuronBlockPage = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditNeuronBlockPage");
		local task = MyCompany.Aries.Game.Tasks.EditNeuronBlockPage:new({blockX = bx,blockY = by, blockZ = bz})
		task:Run();
	end
end

-- global function to fill selection with given blocks. 
-- TODO: making this function with undo manager
-- @param fill_block_id: if nil, it will be the current block.  if 0, it is fast delete. 
function SelectBlocks.FillSelection(fill_block_id)
	if(cur_instance and cur_instance.aabb and cur_instance.aabb:IsValid()) then
		local self = cur_instance;
		local min = self.aabb:GetMin();
		local max = self.aabb:GetMax();

		fill_block_id = fill_block_id or GameLogic.GetBlockInRightHand()
		local x, y, z;
		for x = min[1], max[1] do
			for y = min[2], max[2] do
				for z = min[3], max[3] do
					BlockEngine:SetBlock(x,y,z,fill_block_id);
				end
			end
		end
	end
end

-- global function to delete a group of blocks. 
-- TODO: making this function with undo manager
function SelectBlocks.ReplaceBlocks(from_block_id, to_block_id)
	if(from_block_id and to_block_id and from_block_id~=to_block_id) then
		if(cur_instance and cur_instance.aabb and cur_instance.aabb:IsValid() and #cur_selection > 0) then
			local self = cur_instance;
			local min = self.aabb:GetMin();
			local max = self.aabb:GetMax();

			local block_in_hand = GameLogic.GetBlockInRightHand()
			local x, y, z;
			for x = min[1], max[1] do
				for y = min[2], max[2] do
					for z = min[3], max[3] do
						if( ParaTerrain.GetBlockTemplateByIdx(x,y,z) == from_block_id) then
							BlockEngine:SetBlock(x,y,z, to_block_id);
						end
					end
				end
			end
		end
	end
end