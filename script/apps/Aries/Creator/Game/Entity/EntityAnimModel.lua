--[[
Title: Entity Animation Model Generator
Author(s): LiXizhi
Date: 2018/5/16
Desc: Code block 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityAnimModel.lua");
local EntityAnimModel = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityAnimModel")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlock.lua");
NPL.load("(gl)Mod/ParaXExporter/BMaxModel.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
NPL.load("(gl)script/ide/Files.lua");

local CodeBlock = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlock");
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

-- we will only allow this number of connected code block to share the same movie entity
local maxConnectedCodeBlockCount = 255;

local output_file_name = "";
local num_outputs = 0;

function Entity:ctor()
end

function Entity:OnNeighborChanged(x,y,z, from_block_id)
	if(not GameLogic.isRemote) then
		-- self:ScheduleRefresh(x,y,z);
	end
end

function Entity:SaveToXMLNode(node, bSort)
	node = Entity._super.SaveToXMLNode(self, node, bSort);
	node.attr.filename = self.filename;
	return node;
end

function Entity:LoadFromXMLNode(node)
	Entity._super.LoadFromXMLNode(self, node);
	self:SetAllowGameModeEdit(node.attr.allowGameModeEdit == "true");
	self.filename = node.attr.filename;
end

function Entity:ScheduleRefresh(x,y,z)
	if(not x) then
		x,y,z = self:GetBlockPos();
	end
	GameLogic.GetSim():ScheduleBlockUpdate(x, y, z, self:GetBlockId(), 1);
end


function Entity:GetFilename()
	return self.filename;
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
	_guihelper.MessageBox(L"TODO");
end

-- Ticks the block if it's been scheduled
function Entity:updateTick(x,y,z)
end

function Entity:OnBlockAdded(x,y,z)
	self._super.OnBlockAdded(x,y,z);
	local blocks = self:SelectAllConnectedColorBlocks();
	self:RotateBlocks(blocks);

	local worldDir = ParaWorld.GetWorldDirectory();
	
	-- create target bmax model from color blocks that connected with current anim block
	local target_file_name = format("%s%s", worldDir, "target.bmax");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
	local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
	local task = BlockTemplate:new({operation = BlockTemplate.Operations.Save, filename = target_file_name, blocks = blocks});
	if( not task:Run() ) then
		LOG.std(nil, "info", "Animation Block", "Failed to save target bmax model!");
	end

	-- matching and rigging
	output_file_name = format("%smorph_result%d.x", worldDir, num_outputs);
	num_outputs = num_outputs + 1;
	local AutoRigger = ParaScene.CreateObject("CAutoRigger", "CAutoRigger",0,0,0);
	local attr = AutoRigger:GetAttributeObject();

	-- get templates model file(s) name list
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/ModelTemplatesFile.lua");
	local ModelTemplatesFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.ModelTemplatesFile")
	ModelTemplatesFile:Init();
	local models = ModelTemplatesFile:GetTemplates();
	if( attr ~= nil and next(models) ~= nil) then
		-- add template models to the AutoRigger if not added yet
		for i = 1,#models do
			attr:SetField("AddModelTemplate", models[i]);
		end
		-- set target file name, the target file is a bmax file that stores the cubes created by user as an input file to auto-rigger
		attr:SetField("SetTargetModel", target_file_name);
		-- set the rigged file name or the output file name
		attr:SetField("SetOutputFilePath", output_file_name);
		-- set callback to add the rigged target x file to the world 
		attr:SetField("On_AddRiggedFile", format(";MyCompany.Aries.Game.EntityManager.EntityAnimModel.OnAddRiggedFile_s(%d);", self.entityId));
		-- start rigging
		attr:SetField("AutoRigModel", "");
	end	
end

function Entity:RotateBlocks(blocks)
	-- rotate the blocks
	local x0,y0,z0 = self:GetBlockPos();
	local x1,y1,z1;
	for side=0,5 do
		local dx, dy, dz = Direction.GetOffsetBySide(side);
		local x, y, z = x0+dx, y0+dy, z0+dz;
		local block_id = ParaTerrain.GetBlockTemplateByIdx(x,y,z);
		local block_data = ParaTerrain.GetBlockUserDataByIdx(x,y,z);
		if( y >= y0 and block_id == 10 ) then
			x1 = x;
			y1 = y;
			z1 = z;
			break;
		end
	end
	
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

	local dir = vector3d:new({x0-x1,y0-y1,z0-z1});
	dir:normalize();
	local x_positive = vector3d:new(1,0,0);
	local angle = dir:angleAbsolute(x_positive);
	local around_y_axis = false;
	if( math.abs(dir:dot(vector3d:new(0,1,0))) < 0.00001 ) then
		around_y_axis = true;
	end
	
	local angles;
	if(around_y_axis) then
		angles = {0, angle, 0};
	else
		angles = {0, 0, angle};
	end

	--LOG.std(nil, "info", "Morph", "angle: %f!", angle);

	for i,block in ipairs(blocks) do
		local p = vector3d:new({block[1], block[2], block[3]});
		p:rotate(angles[1],angles[2],angles[3]);
		block[1] = p[1];
		block[2] = p[2];
		block[3] = p[3];
	end
	
end

function Entity:GetOutputFilename()
	return output_file_name or "";
end

-- static script callback function
function Entity.OnAddRiggedFile_s(entityId)
	local entity = EntityManager.GetEntityById(entityId)
	if(entity) then
		entity:OnAddRiggedFile();
	end
end

function Entity:OnAddRiggedFile()
	local x, y, z = EntityManager.GetPlayer():GetPosition()
	local entity = EntityManager.EntityNPC:Create({x=x,y=y,z=z, item_id = block_types.names.TimeSeriesNPC});
	entity:SetMainAssetPath(self:GetOutputFilename());
	entity:SetPersistent(false);
	entity:SetCanRandomMove(false);
	entity:SetDummy(true);
	entity:Attach();

	GameLogic.AddBBS(nil, format(L"人物模型已经保存到%s", self:GetOutputFilename()));
	LOG.std(nil, "info", "Morph", "auto rigged file generated to %s", self:GetOutputFilename());
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