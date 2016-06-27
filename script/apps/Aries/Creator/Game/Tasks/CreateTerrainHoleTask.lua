--[[
Title: Create a terrain hold on the real world terrain. 
Author(s): LiXizhi
Date: 2013/1/22
Desc: 
Deprecated Usage: Place an TNT on the ground, once the user pressed space key within 10 seconds, the real world terrain will be exploded. 
New usage: 
 we no long support creating terrain holes, instead we allow the user to convert a blocks to real terrain, and real terrain to blocks. 
- Usually we select real terrain and convert it to blocks
- And we select several blocks and convert them to real terrain. 

This provides us a handy function to block based terrain. 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateTerrainHoleTask.lua");
local CreateTerrainHole = commonlib.gettable("MyCompany.Aries.Game.Tasks.CreateTerrainHole");
local task = MyCompany.Aries.Game.Tasks.CreateTerrainHole:new({operation="SelectBlockTerrain", blockX = result.blockX,blockY = result.blockY, blockZ = result.blockZ})
task:Run();

-- create a hole
local task = MyCompany.Aries.Game.Tasks.CreateTerrainHole:new({operation="CreateTerrainHole", blockX = result.blockX,blockY = result.blockY, blockZ = result.blockZ})
task:Run();

-- convert real world terrain to blocks
local task = MyCompany.Aries.Game.Tasks.CreateTerrainHole:new({operation="RealTerrainToBlocks", blockX = result.blockX,blockY = result.blockY, blockZ = result.blockZ})
task:Run();

-- convert blocks to real world terrain
local task = MyCompany.Aries.Game.Tasks.CreateTerrainHole:new({operation="BlocksToRealTerrain", blockX = result.blockX,blockY = result.blockY, blockZ = result.blockZ})
task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/TooltipHelper.lua");
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
NPL.load("(gl)script/ide/math/vector.lua");
NPL.load("(gl)script/ide/math/ShapeAABB.lua");
local ShapeAABB = commonlib.gettable("mathlib.ShapeAABB");
local vector3d = commonlib.gettable("mathlib.vector3d");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");

local CreateTerrainHole = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.CreateTerrainHole"));

-- ms seconds to explode the terrain. 
local explode_time = 5000;
local cur_instance;

function CreateTerrainHole:ctor()
	
end


function CreateTerrainHole:Run()
	if(not self.blockX) then
		return;
	end
	
	self:AddSelectionPoint(self.blockX, self.blockY, self.blockZ, true)
		
	if(self.operation == "CreateTerrainHole") then
		self:Op_CreateTerrainHole();
	elseif(self.operation == "RealTerrainToBlocks") then
		self:Op_RealTerrainToBlocks();
	elseif(self.operation == "BlocksToRealTerrain") then
		self:Op_BlocksToRealTerrain();
	else
		-- this is the default UI selection task.
		self:Op_SelectRealTerrain();
	end
end

function CreateTerrainHole.RegisterHooks()
	local self = cur_instance;
	self.sceneContext = self.sceneContext or Game.SceneContext.RedirectContext:new():RedirectInput(self);
	self.sceneContext:activate();
end

function CreateTerrainHole.UnregisterHooks()
	local self = cur_instance;
	if(self) then
		self.sceneContext:close();
	end
end

function CreateTerrainHole:AddSelectionPoint(bx,by,bz,bNoUISelection)
	local blocksize = BlockEngine.blocksize;
	local cx, cy, cz = BlockEngine:real(bx,by,bz);

	self.terrain_points = self.terrain_points or {};

	local i, j, k;
	local x,y,z;
	-- get the min, max elevation that we need to fill in.
	local fMinElevation, fMaxElevation;
	local radius = 7;
	local offset_x, offset_z = (bx%8), (bz%8);

	local pt_x, pt_z = bx - offset_x, bz - offset_z;
	local _, pt = self.terrain_points;
	for _, pt in ipairs(self.terrain_points) do
		if(pt.x == pt_x and pt.z == pt_z) then
			-- we have already added this point. 
			return;
		end
	end
	
	self.hole_blocks = self.hole_blocks or {};
	local hole_blocks = self.hole_blocks;
	local count = 0;
	for i = 0, 7 do 
		for j = 0, 7 do 
			x = cx + (i-offset_x) * blocksize;
			z = cz + (j-offset_z) * blocksize;
			if(not ParaTerrain.IsHole(x,z)) then
				local fElev = ParaTerrain.GetElevation(x,z);
				if(not fMinElevation or fElev<fMinElevation) then
					fMinElevation = fElev;
				end
				if(not fMaxElevation or fElev>fMaxElevation) then
					fMaxElevation = fElev;
				end
				local bx,by,bz = BlockEngine:block(x, fElev+0.1, z);
				hole_blocks[#hole_blocks+1] = {bx,by,bz}
				count = count + 1;
				if(not bNoUISelection) then
					-- highlight it
					ParaTerrain.SelectBlock(bx,by,bz, true);
				end
			end
		end
	end

	if(count>0) then
		self.terrain_points[#(self.terrain_points)+1] = {x = pt_x, z = pt_z, hit_point = {bx,by,bz} };
	end
end

function CreateTerrainHole:FrameMove()
	-- update the selector effect
	if(self.hole_blocks) then
		local selected = not self.finished
		local b;
		for _, b in ipairs(self.hole_blocks) do
			ParaTerrain.SelectBlock(b[1],b[2],b[3], selected);
		end
	end
end

-- convert blocks to real terrain. i.e. undo any holes on the terrain. 
function CreateTerrainHole:Op_BlocksToRealTerrain()
	local blocksize = BlockEngine.blocksize;
	local cx, cy, cz = BlockEngine:real(self.blockX, self.blockY, self.blockZ);

	if(ParaTerrain.IsHole(cx, cz)) then
		ParaTerrain.SetHole(cx, cz, false);
		ParaTerrain.UpdateHoles(cx, cz);
		BroadcastHelper.PushLabel({id="CreateTerrainHole", label = L"实数地表已经生成", max_duration=5000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
	end
	CreateTerrainHole.EndEditing();
	-- TaskManager.AddTask(self);
end


-- create terrain holes on the selection terrain
function CreateTerrainHole:Op_CreateTerrainHole()
	if(self.terrain_points and #(self.terrain_points)>0) then
		CreateTerrainHole.EndEditing();

		local _, pt = self.terrain_points;
		for _, pt in ipairs(self.terrain_points) do
			if(pt.hit_point) then
				local hit_point = pt.hit_point;
				block.RemoveTerrainBlock(hit_point[1],hit_point[2],hit_point[3]);
			end
		end
		UndoManager.PushCommand(self);
	end
end

-- convert selected terrain to blocks
function CreateTerrainHole:Op_RealTerrainToBlocks()
	if(self.terrain_points and #(self.terrain_points)>0) then
		CreateTerrainHole.EndEditing();

		local b;
		for _, b in ipairs(self.hole_blocks) do
			block.FillTerrainBlock(b[1],b[2],b[3]);
		end

		local _, pt = self.terrain_points;
		for _, pt in ipairs(self.terrain_points) do
			if(pt.hit_point) then
				local hit_point = pt.hit_point;
				local cx, cy, cz = BlockEngine:real(hit_point[1],hit_point[2],hit_point[3]);
				-- set hole on real terrain
				ParaTerrain.SetHole(cx, cz, true);
				ParaTerrain.UpdateHoles(cx, cz);
			end
		end
		UndoManager.PushCommand(self);
	end	
end

-- with UI selection page
function CreateTerrainHole:Op_SelectRealTerrain()
	self.is_top_level = true;
	if(not TaskManager.AddTask(self)) then
		-- ignore the task if there is other top-level tasks.
		return;
	end
	cur_instance = self;

	CreateTerrainHole.finished = false;
	CreateTerrainHole.RegisterHooks();
	CreateTerrainHole.ShowPage();

	BroadcastHelper.PushLabel({id="CreateTerrainBlocks", label = L"Ctrl+左键 新增选择区域", max_duration=100000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
	TaskManager.AddTask(self);
end

function CreateTerrainHole:Redo()
	
end

function CreateTerrainHole:Undo()
	
end

function CreateTerrainHole.EndEditing()
	if(cur_instance) then
		CreateTerrainHole.UnregisterHooks();
		local self = cur_instance;
		cur_instance = nil;
		self.finished = true;

		ParaTerrain.DeselectAllBlock();
		BroadcastHelper.Clear("CreateTerrainBlocks");
	end
	CreateTerrainHole.ClosePage();
end

function CreateTerrainHole:mouseReleaseEvent(event)
	self.sceneContext:mouseReleaseEvent(event);

	if(event.mouse_button == "left") then
		-- left click to cancel selection.
		if(event.ctrl_pressed) then
			local result = Game.SelectionManager:MousePickBlock();
			if(result.blockX) then
				self:AddSelectionPoint(result.blockX,result.blockY,result.blockZ);
			end	
		else
			CreateTerrainHole.EndEditing();
		end
	end
end

function CreateTerrainHole:keyPressEvent(event)
	local dik_key = event.keyname;

	if(dik_key == "DIK_ESCAPE")then
		-- cancel selection. 
		CreateTerrainHole.EndEditing();
	elseif(dik_key == "DIK_DELETE" or dik_key == "DIK_DECIMAL")then
		CreateTerrainHole.DeleteSelection();
	elseif(dik_key == "DIK_EQUALS")then
		CreateTerrainHole.AutoExtrude(true);
	elseif(dik_key == "DIK_MINUS")then
		CreateTerrainHole.AutoExtrude(false);
	elseif(dik_key == "DIK_LBRACKET")then
		CreateTerrainHole.TransformSelection(nil,nil,nil, 1.57)
	elseif(dik_key == "DIK_RBRACKET")then
		CreateTerrainHole.TransformSelection(nil,nil,nil, -1.57)
	else
		self.sceneContext:keyPressEvent(event);
	end	
end

------------------------
-- page function 
------------------------
local page;
function CreateTerrainHole.ShowPage()
	-- display a page containing all operations that can apply to current selection, like deletion, extruding, coloring, etc. 
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Tasks/CreateTerrainHoleTask.html", 
			name = "CreateTerrainHole.ShowPage", 
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			isShowTitleBar = false,
			DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
			style = CommonCtrl.WindowFrame.ContainerStyle,
			zorder = 1,
			allowDrag = false,
			click_through = true,
			directPosition = true,
				align = "_lt",
				x = 0,
				y = 80,
				width = 128,
				height = 512,
		});
	MyCompany.Aries.Creator.ToolTipsPage.ShowPage(false);
end

function CreateTerrainHole.ClosePage()
	if(page) then
		page:CloseWindow();
	end
end


function CreateTerrainHole.OnInit()
	page = document:GetPageCtrl();
end

function CreateTerrainHole.DoClick(name)
	local self = cur_instance;
	if(not self) then
		return
	end 

	if(name == "CreateTerrainHole") then
		self:Op_CreateTerrainHole();
	elseif(name == "RealTerrainToBlocks") then
		self:Op_RealTerrainToBlocks();
	elseif(name == "BlocksToRealTerrain") then
		self:Op_BlocksToRealTerrain();
	end
end
