--[[
Title: Entity Animation Model Generator
Author(s): Cheng Yuanchu, LiXizhi
Date: 2018/9/10
Desc: When this block is placed next to a group of connected color blocks, we will convert the blocks into an animated model
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityAnimModel.lua");
local EntityAnimModel = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityAnimModel")
-------------------------------------------------------
]]
NPL.load("(gl)Mod/ParaXExporter/BMaxModel.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/ModelTemplatesFile.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local ModelTemplatesFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.ModelTemplatesFile")
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local names = commonlib.gettable("MyCompany.Aries.Game.block_types.names");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local vector3d = commonlib.gettable("mathlib.vector3d");
local ShapeAABB = commonlib.gettable("mathlib.ShapeAABB");

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockBase"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityAnimModel"));

-- class name
Entity.class_name = "EntityAnimModel";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);
Entity.is_persistent = true;
-- always serialize to 512*512 regional entity file
Entity.is_regional = true;
Entity.thinkTickInterval = 1000;

-- we will only allow this number of connected code block to share the same movie entity
local maxConnectedCodeBlockCount = 255;

function Entity:ctor()
end

function Entity:OnRemoved()
	Entity._super.OnRemoved(self);
	self:DeleteOutputCharacter();
	self:DeleteThinkerEntity();
	if(self:IsBuilding())then
		self:SetBuilding(false);
	end
end

function Entity:OnNeighborChanged(x,y,z, from_block_id)
	if(not GameLogic.isRemote) then
		-- self:ScheduleRefresh(x,y,z);
	end
end

function Entity:SaveToXMLNode(node, bSort)
	node = Entity._super.SaveToXMLNode(self, node, bSort);
	if(self.filename and self.filename~="") then
		node.attr.filename = self.filename;
	end
	return node;
end

function Entity:LoadFromXMLNode(node)
	Entity._super.LoadFromXMLNode(self, node);
	self.filename = node.attr.filename;
end

function Entity:ScheduleRefresh(x,y,z)
	if(not x) then
		x,y,z = self:GetBlockPos();
	end
	GameLogic.GetSim():ScheduleBlockUpdate(x, y, z, self:GetBlockId(), 1);
end

-- called when the user clicks on the block
-- @return: return true if it is an action block and processed . 
function Entity:OnClick(x, y, z, mouse_button, entity, side)
	if(GameLogic.isRemote) then
		return true;
	else
		if(GameLogic.GameMode:CanEditBlock()) then
			self:OpenEditor("entity", entity);
		end
	end
	return true;
end

function Entity:OpenEditor(editor_name, entity)
	if(Files.FileExists(self:GetFilename())) then
		self:CreateOutputCharacter();
		local charEntity = self:GetOutputCharacter();
		if(charEntity) then
			local filename = self:GetFilename();
			local result = Files.ResolveFilePath(filename);
			filename = commonlib.Encoding.DefaultToUtf8(result.relativeToWorldPath or filename);
			charEntity:Say(filename, nil, true);
		end
		_guihelper.MessageBox(format(L"是否重新生成 %s?", commonlib.Encoding.DefaultToUtf8(self:GetFilename())), function(res)
			if(res and res == _guihelper.DialogResult.Yes) then
				self:TryRebuild();
			end
		end, _guihelper.MessageBoxButtons.YesNo);
	else
		self:TryRebuild();
	end
end

-- Ticks the block if it's been scheduled
function Entity:updateTick(x,y,z)
end

function Entity:OnBlockAdded(x,y,z)
	self._super.OnBlockAdded(x,y,z);
	self:TryRebuild();
end

-- static function
function Entity:GetTempBMaxFilepath()
	if(not Entity.tempTargetFilepath) then
		Entity.tempTargetFilepath = ParaIO.GetWritablePath().."temp/auto_anim_target.bmax";
		ParaIO.CreateDirectory(Entity.tempTargetFilepath);
	end
	return Entity.tempTargetFilepath;
end

function Entity:GetTempOutputFilename()
	if(not self.outputFilename) then
		self.outputFilename = format("%stemp/auto_anim_output.x", ParaIO.GetWritablePath());
		ParaIO.CreateDirectory(self.outputFilename);
	end
	return self.outputFilename;
end

-- by default each entity has a unique name according to its position
function Entity:GetFilename()
	if(self.filename == "") then
		self.filename = nil;
	end
	if(not self.filename and not self.defaultFilename) then
		local bx,by,bz = self:GetBlockPos();
		self.defaultFilename = format("%sblocktemplates/auto_anim%d_%d_%d.x", GameLogic.GetWorldDirectory(), bx,by,bz);
		ParaIO.CreateDirectory(self.defaultFilename);
	end
	return self.filename or self.defaultFilename;
end

-- set user defined filename
function Entity:SetFilename(filename)
	self.filename = filename;
	local entity = self:GetOutputCharacter();
	if(entity) then
		filename = Files.GetWorldFilePath(filename);
		entity:SetMainAssetPath(filename);
	end
end

function Entity:IsBuilding()
	return Entity.isBuilding;
end

function Entity:SetBuilding(bBuilding)
	if(Entity.isBuilding ~= bBuilding) then
		if(not bBuilding) then
			GameLogic.AddBBS("AnimModel", nil);
		end
		Entity.isBuilding = bBuilding;
		if(Entity.isBuilding) then
			self.startTime = commonlib.TimerManager.GetCurrentTime();
		end
	end
end

-- since there can be only one thread that is building, we will ignore concurrent calls.
function Entity:TryRebuild()
	if(not self:IsBuilding()) then
		return self:Rebuild();
	end
end

-- static function: this is mostly a singleton object
-- get and initialize the auto rigger in C++ game engine for model generation
function Entity:CreateGetAutoRigger()
	-- matching and rigging
	if(not Entity.autoRigger or not Entity.autoRigger:IsValid()) then
		local autoRigger = ParaScene.CreateObject("CAutoRigger", "MyAutoRigger",0,0,0);
		ParaScene.Attach(autoRigger);
		Entity.autoRigger = autoRigger;
		-- add template models to the AutoRigger if not added yet
		local models = ModelTemplatesFile:GetTemplates() or {};
		for _, template in ipairs(ModelTemplatesFile:GetTemplates()) do
			autoRigger:SetField("AddModelTemplate", template.filename);
		end
		LOG.std(nil, "info", "AnimModel", "a new auto rigger created and initialized with %d models", #models);
	end
	return Entity.autoRigger;
end

function Entity:LoadAsset(callback)

end

-- rebuild all connected blocks into a model
function Entity:Rebuild()
	local blocks = self:SelectAllConnectedColorBlocks();
	if(blocks and #blocks == 0) then
		GameLogic.AddBBS("AnimModel", L"需要放在一组彩色方块的旁边才能生成模型", 20);
		self:ShowThinkerText(L"我的附近没有发现像模型的彩色方块")
		return;
	end
	self:AutoOrientBlocks(blocks);

	local worldDir = ParaWorld.GetWorldDirectory();
	
	-- create target bmax model from color blocks that connected with current anim block
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
	local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
	local task = BlockTemplate:new({operation = BlockTemplate.Operations.Save, filename = self:GetTempBMaxFilepath(), blocks = blocks});
	if( task:Run() ) then
		LOG.std(nil, "info", "AnimBlock", "successfully saved %d blocks to bmax file %s", #blocks, self:GetTempBMaxFilepath());
	else
		LOG.std(nil, "info", "AnimBlock", "Failed to save target bmax model!");
		return;
	end

	-- matching and rigging
	local autoRigger = self:CreateGetAutoRigger();
	if(autoRigger) then
		-- set target file name, the target file is a bmax file that stores the cubes created by user as an input file to auto-rigger
		autoRigger:SetField("SetTargetModel", self:GetTempBMaxFilepath());
		-- set the rigged file name or the output file name
		autoRigger:SetField("SetOutputFilePath", self:GetTempOutputFilename());
		-- set callback to add the rigged target x file to the world 
		autoRigger:SetField("On_AddRiggedFile", format(";MyCompany.Aries.Game.EntityManager.EntityAnimModel.OnAddRiggedFile_s(%d);", self.entityId));
		-- start rigging
		autoRigger:SetField("AutoRigModel", "");
		self:SetBuilding(true);
		GameLogic.AddBBS("AnimModel", format(L"正在为%d个方块生产动画模型，可能需要10-20秒, 请耐心等待", #blocks), 20000);
		self:ShowThinkerText(L"我在思考中,需要10-20秒");
		self:TickThinking();
		return true;
	end
end

function Entity:GetElapsedTime()
	return commonlib.TimerManager.GetCurrentTime() - self:GetBuildStartTime();
end

function Entity:GetBuildStartTime()
	return self.startTime or commonlib.TimerManager.GetCurrentTime();
end

function Entity:TickThinking()
	if(self:IsBuilding()) then
		self:ShowThinkerText(format(L"我在思考中: %d秒", math.floor(self:GetElapsedTime()/1000)));
		commonlib.TimerManager.SetTimeout(function()  
			if(self:IsBuilding()) then
				self:ShowNextThinkerModel()
				self:TickThinking();
			end
		end, self.thinkTickInterval)
	end
end

-- we will get nearby color block to compute the model facing
--@return {0, angleY, angleZ}
function Entity:ComputeModelFacing()
	local x0,y0,z0 = self:GetBlockPos();
	local x1,y1,z1;
	for side=0,5 do
		local dx, dy, dz = Direction.GetOffsetBySide(side);
		local x, y, z = x0+dx, y0+dy, z0+dz;
		local block_id = ParaTerrain.GetBlockTemplateByIdx(x,y,z);
		local block_data = ParaTerrain.GetBlockUserDataByIdx(x,y,z);
		if( y >= y0 and block_id == block_types.names.ColorBlock ) then
			x1 = x;
			y1 = y;
			z1 = z;
			break;
		end
	end
	local angle = 0
	local around_y_axis = false;
	if(x1) then
		local dir = vector3d:new({x0-x1,y0-y1,z0-z1});
		dir:normalize();

		local x_positive = vector3d:new(1,0,0);
		angle = dir:angleAbsolute(x_positive);
		
		if( math.abs(dir:dot(vector3d:new(0,1,0))) < 0.00001 ) then
			around_y_axis = true;
		end
	end

	local angles;
	if(around_y_axis) then
		angles = {0, angle, 0};
	else
		angles = {0, 0, angle};
	end

	return angles;
end

-- auto rotate blocks around y axis so that the model is facing positive x 
function Entity:AutoOrientBlocks(blocks)
	local aabb = ShapeAABB:new();
	for i,block in ipairs(blocks) do
		aabb:Extend(block[1], block[2], block[3]);
	end
	local center = aabb:GetCenter();
	for i,block in ipairs(blocks) do
		block[1] = block[1] - center[1];
		block[2] = block[2] - center[2];
		block[3] = block[3] - center[3];
	end

	local angles = self:ComputeModelFacing();

	--LOG.std(nil, "info", "Morph", "angle: %f!", angle);

	for i,block in ipairs(blocks) do
		local p = vector3d:new({block[1], block[2], block[3]});
		p:rotate(angles[1],angles[2],angles[3]);
		block[1] = p[1];
		block[2] = p[2];
		block[3] = p[3];
	end
end

-- static script callback function
function Entity.OnAddRiggedFile_s(entityId)
	local entity = EntityManager.GetEntityById(entityId)
	if(entity) then
		entity:OnAddRiggedFile(msg.count, msg.filenames, msg.msg);
	end
end

-- @param count: number of output, could be 0 or 1. if 0, msg is error message. 
-- @param filenames: output filenames separated by ;
-- @param msg: error message or the template's model filename
function Entity:OnAddRiggedFile(count, filenames, msg)
	self:SetBuilding(false);
	LOG.std(nil, "info", "AutoAnim", "Auto Rigging done: Count:%d filenames:%s msg: %s" , count or 0, filenames or "", msg or "");
	if(count>0) then
		local outputFile = Files.GetWorldFilePath(self:GetFilename()) or self:GetFilename();
		if(ParaIO.CopyFile(self:GetTempOutputFilename(), outputFile, true)) then
			LOG.std(nil, "info", "Morph", "auto rigged file generated to %s", commonlib.Encoding.DefaultToUtf8(outputFile));

			local modelTemplateFilename = msg;
			-- show what it looks like 
			local displayName = self:GetTemplateModelNameByFilename(modelTemplateFilename)
			if(displayName) then
				GameLogic.AddBBS(nil, format(L"它看起来有点像 %s", displayName));
				self:ShowThinkerText(format(L"它看起来有点像 %s", displayName));
				self:SetThinkerModel(modelTemplateFilename);
			else
				self:ShowThinkerText(nil);
			end

			-- show saved world path
			local result = Files.ResolveFilePath(self:GetFilename());
			GameLogic.AddBBS("AnimModel", format(L"人物模型已经保存到%s", commonlib.Encoding.DefaultToUtf8(result.relativeToWorldPath) or ""));

			-- create temporary character for further interaction
			self:CreateOutputCharacter();
			local entity = self:GetOutputCharacter();
			if(entity) then
				entity:Say(L"点击我", 10, true);
				local x, y, z = EntityManager.GetPlayer():GetPosition()
				entity:SetPosition(x, y, z);
			end
		else
			GameLogic.AddBBS("AnimModel", format(L"无法覆盖文件%s", commonlib.Encoding.DefaultToUtf8(self:GetFilename())));
			self:ShowThinkerText(L"出错了");
		end
	else
		GameLogic.AddBBS("AnimModel", L"没有找到匹配的模型");
		self:ShowThinkerText(L"没有找到匹配的模型");
	end
end

-- return display name or nil
function Entity:GetTemplateModelNameByFilename(filename)
	local template = ModelTemplatesFile:GetTemplateByFilename(filename);
	return template and template.name;
end

function Entity:GetOutputCharacter()
	return self.outputEntity;
end

function Entity:CreateOutputCharacter()
	if(self.outputEntity and self.outputEntity:GetInnerObject()) then
		-- already created, the engine will auto refresh or we will refresh it here
		return;
	end
	local x, y, z = EntityManager.GetPlayer():GetPosition()
	local entity = EntityManager.EntityAnimCharacter:Create({x=x,y=y,z=z, item_id = block_types.names.TimeSeriesNPC});
	
	entity:SetMainAssetPath(Files.GetWorldFilePath(self:GetFilename()));
	entity:SetFacing(self:ComputeModelFacing()[2]);
	entity:SetAnimModelEntity(self);
	entity:Attach();
	self.outputEntity = entity;
end

function Entity:DeleteOutputCharacter()
	if(self.outputEntity) then
		self.outputEntity:Destroy();
		self.outputEntity = nil;
	end
end


function Entity:SelectAllConnectedColorBlocks()
	local x0,y0,z0 = self:GetBlockPos();
	local num_selected = 0;
	local max_selected = 65535;
	local blocks = {};
	local block_indices = {};
	local block_queue = commonlib.Queue:new();
	local function AddConnectedBlockRecursive(cx,cy,cz)
		if( num_selected <= max_selected ) then
			for side=0,5 do
				local dx, dy, dz = Direction.GetOffsetBySide(side);
				local x, y, z = cx+dx, cy+dy, cz+dz;
				local block_id = ParaTerrain.GetBlockTemplateByIdx(x,y,z);
				local block_data = ParaTerrain.GetBlockUserDataByIdx(x,y,z);
				local index = BlockEngine:GetSparseIndex(x,y,z)
				if( not block_indices[index] and y >= y0 and block_id == 10 ) then
					blocks[#(blocks)+1] = {x,y,z, block_id, block_data};
					block_indices[index] = true;
					ParaTerrain.SelectBlock(x,y,z,true); -- debug use
					block_queue:pushright({x,y,z});
					num_selected = num_selected + 1;
				end
			end
		end
	end
	AddConnectedBlockRecursive(x0,y0,z0);
	while (not block_queue:empty()) do
		local block = block_queue:popleft();
		ParaTerrain.SelectBlock(block[1], block[2], block[3],true);
		AddConnectedBlockRecursive(block[1], block[2], block[3]);
	end
	ParaTerrain.DeselectAllBlock();
	return blocks;
end

-- a thinker entity is a dummy entity showing some tips to the user
function Entity:CreateGetThinkerEntity()
	if(not self.thinkerEntity or not self.thinkerEntity:GetInnerObject()) then
		local x, y, z = self:GetPosition();
		local entity = EntityManager.EntityNPC:Create({x=x,y = y + BlockEngine.blocksize,z=z, item_id = block_types.names.TimeSeriesNPC});
		entity:SetPersistent(false);
		entity:SetCanRandomMove(false);
		entity:SetDummy(true);
		entity:SetFacing(self:ComputeModelFacing()[2]);
		entity:Attach();
		entity.OnClick = function(entity, x,y,z, mouse_button)
			self:OnClickThinker();
			return true;
		end
		self.thinkerEntity = entity;	

		self:ShowNextThinkerModel();
	end
	return self.thinkerEntity;
end

function Entity:OnClickThinker(entity)
	self:OpenEditor();
end

function Entity:DeleteThinkerEntity()
	if(self.thinkerEntity) then
		self.thinkerEntity:Destroy();
		self.thinkerEntity = nil;
	end
end

function Entity:ShowThinkerText(text, duration)
	local entity = self:CreateGetThinkerEntity()
	if(entity) then
		entity:Say(text, duration or 10, true);
	end
end

function Entity:SetThinkerModel(filename)
	local entity = self:CreateGetThinkerEntity()
	if(entity) then
		entity:SetMainAssetPath(filename);
	end
end

function Entity:ShowNextThinkerModel()
	local entity = self:CreateGetThinkerEntity()
	if(entity) then
		local templates = ModelTemplatesFile:GetTemplates()
		self.modelIndex = ((self.modelIndex or -1) +1) % (#templates);
		local template = templates[self.modelIndex+1];
		if(template) then
			entity:SetMainAssetPath(template.filename);	
		end
	end
end
