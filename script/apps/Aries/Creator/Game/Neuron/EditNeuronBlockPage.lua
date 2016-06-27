--[[
Title: Neuron Editor 
Author(s): LiXizhi
Date: 2013/3/17
Desc: editing the neuron, such as its dendrites, axon connections, neural coding, etc. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Neuron/EditNeuronBlockPage.lua");
local EditNeuronBlockPage = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditNeuronBlockPage");

local task = MyCompany.Aries.Game.Tasks.EditNeuronBlockPage:new({blockX = result.blockX,blockY = result.blockY, blockZ = result.blockZ})
task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
NPL.load("(gl)script/ide/TooltipHelper.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Neuron/NeuronBlock.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Neuron/NeuronManager.lua");
NPL.load("(gl)script/ide/math/vector.lua");
NPL.load("(gl)script/ide/math/ShapeAABB.lua");
local ShapeAABB = commonlib.gettable("mathlib.ShapeAABB");
local vector3d = commonlib.gettable("mathlib.vector3d");
local NeuronManager = commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronManager");
local NeuronBlock = commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronBlock");
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local EditNeuronBlockPage = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.EditNeuronBlockPage"));

-- for selection effect. 
local groupindex_hint = 3; 

-- this is always a top level task. 
EditNeuronBlockPage.is_top_level = true;
-- ms seconds to explode the terrain. 
local cur_instance;

function EditNeuronBlockPage:ctor()
	self.operation = self.operation or "EditNeuronBlockPage"
end

function EditNeuronBlockPage:Run()
	if(not self.blockX) then
		return;
	end
	if(not TaskManager.AddTask(self)) then
		-- ignore the task if there is other top-level tasks.
		return;
	end
	cur_instance = self;

	self:SelectNeuron(self.blockX, self.blockY, self.blockZ);

	EditNeuronBlockPage.finished = false;
	EditNeuronBlockPage.RegisterHooks();
	EditNeuronBlockPage.ShowPage();

	--if(self.operation == "connections") then
		--self:Op_EditNeuronConnections();
	--elseif(self.operation == "coding") then
		--self:Op_EditNeuronCoding();
	--end
end

function EditNeuronBlockPage:Op_EditNeuronConnections()
	
end

function EditNeuronBlockPage:Op_EditNeuronCoding()
	
end

function EditNeuronBlockPage:Redo()
	
end

function EditNeuronBlockPage:Undo()
	
end

function EditNeuronBlockPage:FrameMove()
	-- update the selector effect
	if(self.neuron and self.need_refresh) then
		local axons = self.neuron.axons;

		local selected = not self.finished

		local nx, ny, nz = self.neuron.x, self.neuron.y, self.neuron.z;

		-- select neuron body
		-- ParaTerrain.SelectBlock(nx, ny, nz, selected, groupindex_hint);

		-- select all axon-dendrites synapses
		local pt = axons:first();
		while (pt) do
			local x, y, z = nx + pt.x, ny + pt.y, nz + pt.z;
			ParaTerrain.SelectBlock(x, y, z, selected, groupindex_hint);
			pt = axons:next(pt)
		end
		if(not self.finished) then
			self:UpdateBlockNumber();
		end
		self.need_refresh = nil;
	end
end

function EditNeuronBlockPage:OnExit()
	EditNeuronBlockPage.EndEditing();
end

function EditNeuronBlockPage.EndEditing()
	if(cur_instance) then
		EditNeuronBlockPage.UnregisterHooks();
		local self = cur_instance;
		cur_instance = nil;
		self.finished = true;
		ParaTerrain.DeselectAllBlock(groupindex_hint);

		-- remove miniscene graph
		ParaScene.DeleteMiniSceneGraph("neuron_edit_canvas");
	end
	EditNeuronBlockPage.ClosePage();
end

function EditNeuronBlockPage.RegisterHooks()
	local self = cur_instance;
	self.sceneContext = self.sceneContext or Game.SceneContext.RedirectContext:new():RedirectInput(self);
	self.sceneContext:activate();
end

function EditNeuronBlockPage.UnregisterHooks()
	local self = cur_instance;
	if(self) then
		self.sceneContext:close();
	end
end

-- select to view another neuron
function EditNeuronBlockPage:SelectNeuron(x, y, z)
	-- TODO: push selection to a history of stack, so that we can use shortcut key to toggle selection. 
	self.blockX, self.blockY, self.blockZ = x,y,z;

	local scene = ParaScene.GetMiniSceneGraph("neuron_edit_canvas");
	
	scene:DestroyObject("cur_neuron");

	local cx,cy,cz = BlockEngine:real(self.blockX, self.blockY, self.blockZ)

	local obj = ObjEditor.CreateObjectByParams({
		name = "cur_neuron",
		AssetFile = "model/common/building_point/building_point.x",
		x = cx,
		y = cy,
		z = cz,
		scaling = 5,
	});
	scene:AddChild(obj);

	self.neuron = NeuronManager.GetNeuron(x, y, z, true);
	ParaTerrain.DeselectAllBlock();
	self:ClearAABBSelection();
	self.need_refresh = true;
	self:FrameMove();
end

function EditNeuronBlockPage:ClearAABBSelection()
	self.aabb = nil;
end

function EditNeuronBlockPage:AddAABBSelection(x, y, z, is_adding)
	if(not self.neuron) then
		return 
	end

	if(not self.aabb) then
		self.aabb = ShapeAABB:new();
		self.aabb:SetPointAABB(vector3d:new({x, y, z}));
	else
		self.aabb:Extend(vector3d:new({x, y, z}));
	end
	

	local min = self.aabb:GetMin();
	local max = self.aabb:GetMax();
	local bx, by, bz;
	for bx = min[1], max[1] do
		for by = min[2], max[2] do
			for bz = min[3], max[3] do
				if(is_adding) then
					if(not self.neuron:HasConnection(bx, by, bz)) then
						ParaTerrain.SelectBlock(bx, by, bz, true, groupindex_hint);
						self.neuron:ConnectBlock(bx, by, bz);
					end
				end
			end
		end
	end
end

function EditNeuronBlockPage:handleLeftClickScene(event)
	local neuron = self.neuron;
	local ctrl_pressed = event.ctrl_pressed;
	local is_shift_pressed = event.is_shift_pressed;

	local result = Game.SelectionManager:MousePickBlock();
	if(result.blockX) then
		local x, y, z = result.blockX,result.blockY,result.blockZ;
		if(x~=self.blockX or y~=self.blockY or z~=self.blockZ) then
				
			if(not ctrl_pressed) then
				self:ClearAABBSelection();
			end
			if(is_shift_pressed) then
				-- delete axons in aabb region
				self:AddAABBSelection(x, y, z, false);
				self:UpdateBlockNumber();
			elseif(ctrl_pressed) then
				-- select axons in aabb region 
				self:AddAABBSelection(x, y, z, true);
				self:UpdateBlockNumber();
			else
				self:ClearAABBSelection();

				-- left click to toggle connection
				if(neuron:HasConnection(x, y, z)) then
					ParaTerrain.SelectBlock(x, y, z, false, groupindex_hint);
					neuron:DisconnectBlock(x, y, z)
				else
					ParaTerrain.SelectBlock(x, y, z, true, groupindex_hint);
					neuron:ConnectBlock(x, y, z)
				end
				-- update the block number in the left panel page. 
				self:UpdateBlockNumber();
			end
		end
	end
end

function EditNeuronBlockPage:handleRightClickScene(event)
	local result = Game.SelectionManager:MousePickBlock();
	if(result.blockX) then
		local x, y, z = result.blockX,result.blockY,result.blockZ;
		if(x~=self.blockX or y~=self.blockY or z~=self.blockZ) then
			-- right click to switch to another neuron
			self:SelectNeuron(x, y, z);	
		end
	end
end

function EditNeuronBlockPage:keyPressEvent(event)
	local dik_key = event.keyname;

	if(dik_key == "DIK_ESCAPE")then
		-- cancel selection. 
		EditNeuronBlockPage.EndEditing();
	elseif(dik_key == "DIK_DELETE" or dik_key == "DIK_DECIMAL")then
		EditNeuronBlockPage.RemoveAllAxons();
	else
		self.sceneContext:keyPressEvent(event);
	end	
end

------------------------
-- page function 
------------------------
local page;
function EditNeuronBlockPage.ShowPage()
	-- display a page containing all operations that can apply to current selection, like deletion, extruding, coloring, etc. 
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Neuron/EditNeuronBlockPage.html", 
			name = "EditNeuronBlockPage.ShowPage", 
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
				y = 160,
				width = 128,
				height = 512,
		});
	MyCompany.Aries.Creator.ToolTipsPage.ShowPage(false);
	BroadcastHelper.PushLabel({id="EditNeuronBlockPage", label = L"点击左键, 增加或删除链接. Ctrl+左键批量添加", max_duration=5000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
	
end

function EditNeuronBlockPage.GetBlockId()
	local self = cur_instance;
	if(self) then
		if(self.blockX) then
			return BlockEngine:GetBlockId(self.blockX, self.blockY, self.blockZ);
		end
	end
end

function EditNeuronBlockPage.ClosePage()
	if(page) then
		page:CloseWindow();
	end
end

function EditNeuronBlockPage:UpdateBlockNumber()
	if(page and self.neuron) then
		local count = self.neuron.axons:size();
		if(self.axon_count ~= count) then
			self.axon_count = count
			page:SetUIValue("title", format(L"连接数:%d",count or 0));
		end
	end
end

function EditNeuronBlockPage.OnInit()
	page = document:GetPageCtrl();
end

-- remove all axons
function EditNeuronBlockPage.RemoveAllAxons()
	local self = cur_instance;
	if(page and self.neuron) then
		self.neuron:ClearAxons();
		ParaTerrain.DeselectAllBlock();
		self:UpdateBlockNumber();
	end
end

-- get the current connection number
function EditNeuronBlockPage.GetConnectionNumber()
	local self = cur_instance;
	if(page and self.neuron) then
		local count = self.neuron.axons:size();
		if(self.axon_count ~= count) then
			self.axon_count = count
		end
		return self.axon_count;
	end
end

function EditNeuronBlockPage.Show3DEffect(name,bx,by,bz, assetfile, lifetime)
	local scene = ParaScene.GetMiniSceneGraph("neuron_edit_canvas");
	scene:DestroyObject(name);
	local cx,cy,cz = BlockEngine:real(bx,by,bz)
	local isCharacter;
	if(assetfile:match("^[cC]haracter/")) then
		isCharacter = true;
	end
	local obj = ObjEditor.CreateObjectByParams({
		name = name,
		IsCharacter = isCharacter,
		AssetFile = assetfile,
		x = cx,
		y = cy,
		z = cz,
	});
	scene:AddChild(obj);
	local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
		local scene = ParaScene.GetMiniSceneGraph("neuron_edit_canvas");
		scene:DestroyObject(name);
	end});
	mytimer:Change(lifetime or 1000,nil);
end

function EditNeuronBlockPage.OnFireLearnSignal()
	local self = cur_instance;
	if(page and self.neuron) then
		if(self.neuron:GetAxonsCount() > 0) then
			self.neuron:Activate({type="click", action="addmem"});

			BroadcastHelper.PushLabel({id="EditNeuronBlockPage", label = L"学习成功! 可以点击测试按钮看效果", max_duration=5000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});

			-- show the signal in 3d scene
			EditNeuronBlockPage.Show3DEffect("fire_signal", self.blockX, self.blockY, self.blockZ, "character/v6/09effect/Combat_Ice/Ice_Casting_ShanKaiXian.x", 1000)
		else
			_guihelper.MessageBox(L"请先建立与其他方块的链接。 左键点击其它方块建立连接，Ctrl+左键批量添加。");
		end
	end
end

function EditNeuronBlockPage.OnClearBlocksInAxons()
	local self = cur_instance;
	if(page and self.neuron) then
		EditNeuronBlockPage.Show3DEffect("fire_signal", self.blockX, self.blockY, self.blockZ, "character/v6/09effect/Combat_Ice/Ice_Casting_ShanKaiXian.x", 1000);
		self.neuron:Activate({type="click", action = "reset_to_zero"});
	end
end

function EditNeuronBlockPage.OnClickNeuron()
	local self = cur_instance;
	if(page and self.neuron) then
		self.neuron:Activate({type="click"});
	end
end

-- destroy all neurons connected with the current neuron, and then click the neuron to recreate all connection according to last memory. 
function EditNeuronBlockPage.OnTestNeuron()
	local self = cur_instance;
	if(page and self.neuron) then
		local axon_blocks = {};
		local pt, neuron;
		for pt, neuron in self.neuron:EachAxonNeuron() do
			if(neuron:GetAxonsCount() == 0) then
				local last_block_id = neuron:GetCurrentBlockID()
				if(last_block_id > 0) then
					axon_blocks[#axon_blocks+1] = {neuron = neuron, last_block_id = last_block_id};
				end
			end
		end

		local is_all_removed;
		local from = 0;
		local interval = 50;
		EditNeuronBlockPage.Show3DEffect("fire_signal", self.blockX, self.blockY, self.blockZ, "character/v6/09effect/Combat_Ice/Ice_Casting_ShanKaiXian.x", 1000);

		local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
			if(is_all_removed) then
				self.neuron:Activate({type="click"});
				timer:Change();
			else
				from = from + 1;
				local block = axon_blocks[from];

				if(block) then
					local neuron = block.neuron;
					local block_template = block.neuron:GetBlockTemplate();

					-- character/v6/09effect/Combat_Ice/Ice_Casting_ShanKaiXian.x
					-- character/v6/09effect/Combat_Ice/Ice_Casting_JuJiXing.x
					-- character/v6/09effect/Combat_Myth/Myth_Casting_JuJiXing.x
					-- character/v6/09effect/Combat_Ice/Ice_Casting_XuanZhuanGuang01.x

					-- no effect is needed since physics is wrong. 
					--if(from%5 == 1) then
						--if(block_template) then
							--block_template:CreateBlockPieces(neuron.x, neuron.y, neuron.z, 0.2);
						--end
					--end
					if(block_template) then
						BlockEngine:SetBlockToAir(neuron.x, neuron.y, neuron.z);
					end
				else
					is_all_removed = true;
					timer:Change(1000,0)
				end
			end
		end})
		mytimer:Change(interval, interval);
	end
end

function EditNeuronBlockPage.OnHelp()
	_guihelper.MessageBox(L"左键点击建立连接，Ctrl+左键批量添加。 再点击学习。 右键切换目标");
end

function EditNeuronBlockPage.GetScriptFileName()
	local self = cur_instance;
	if(self.neuron) then
		return self.neuron.filename;
	end
end

function EditNeuronBlockPage.OnReloadScript()
	local self = cur_instance;
	if(self.neuron) then
		if(self.neuron.filename) then
			-- reload
			self.neuron:CheckLoadScript(true);
		end
	end
end

function EditNeuronBlockPage.OnEditScript()
	local self = cur_instance;
	if(self.neuron) then
		if(self.neuron.filename) then
			-- open the script using a text editor
			local full_path = NeuronManager.GetScriptFullPath(self.neuron.filename);
			-- instead of open file, just open the containing directory. 
			Map3DSystem.App.Commands.Call("File.WinExplorer", {filepath = full_path:gsub("[^/\\]+$", ""), silentmode=true});
			-- ParaGlobal.ShellExecute("open", ParaIO.GetCurDirectory(0)..full_path, "", "", 1); 
		else
			-- create a new script file. 
		end
	end
end

-- let the user select another script to be associated with this script. 
function EditNeuronBlockPage.OnChangeScript()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Neuron/CreateNewNeuronScriptFile.lua");
	local CreateNewNeuronScriptFile = commonlib.gettable("MyCompany.Aries.Game.Tasks.CreateNewNeuronScriptFile");
	CreateNewNeuronScriptFile.ShowPage(function(filename)
		if(filename) then
			local self = cur_instance;
			if(self.neuron) then
				self.neuron:SetScript(filename);
				page:Refresh(0.1);
			end
		end
	end)
end