--[[
Title: EntityBlockDynamic 
Author(s): LiXizhi
Date: 2014/2/25
Desc: The base class for entity that is usually associated with a given block.
 It overwrite the Create() method to delay entity init() until the block is loaded. 
 Please note that a block entity saves to regional(512*512) xml file,  instead of global entity file.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityBlockDynamic.lua");
local EntityBlockDynamic = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockDynamic")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.Entity"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockDynamic"));

-- class name
Entity.class_name = "EntityBlockDynamic";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);
Entity.is_persistent = true;
-- always serialize to 512*512 regional entity file
Entity.is_regional = true;
-- enable frame move in seconds
Entity.framemove_interval = 0.03;

function Entity:ctor()
	-- force creating the physics object
	self:GetPhysicsObject();
end

-- virtual function: overwrite to customize physical object
function Entity:CreatePhysicsObject()
	local physic_obj = Entity._super.CreatePhysicsObject(self);
	physic_obj:SetRadius(BlockEngine.half_blocksize);
	physic_obj:SetSurfaceDecay(3);
	physic_obj:SetAirDecay(0);
	physic_obj:SetCanBounce(false);
	return physic_obj;
end

-- @param Entity: the half radius of the object. 
function Entity:init(x,y,z, block_id, block_data)
	self.bx, self.by, self.bz = x or self.bx, y or self.by, z or self.bz;
	self.block_id = block_id or self.block_id;
	self.block_data = block_data or self.block_data;
	self.sim_time = self.sim_time or 0;

	self.x, self.y, self.z = self:GetPosition();
	self:CreateInnerObject(self.x, self.y, self.z);
	self:UpdateBlockContainer();

	return Entity._super.init(self);
end

function Entity:Destroy()
	self:DestroyInnerObject();

	Entity._super.Destroy(self);
end

local offsets_map = {
	["model/blockworld/BlockModel/block_model_one.x"] = 0;
	["model/blockworld/BlockModel/block_model_four.x"] = 0;
	["model/blockworld/BlockModel/block_model_cross.x"] = 0;
	["model/blockworld/BlockModel/block_model_slab.x"] = 0;
	["model/blockworld/BlockModel/block_model_plate.x"] = 0;
	["model/blockworld/IconModel/IconModel_16x16.x"] = nil;
	[""] = 0;
}

-- create the raw 3d model ParaObject and return it. 
-- @param x,y,z: is real world position. 
function Entity:CreateInnerObject(x,y,z,facing, scaling)
	local item = ItemClient.GetItem(self.block_id);
	if(item) then
		local model_filename = item:GetItemModel();	
		local bUseIcon;
		if(not model_filename or model_filename == "icon") then
			model_filename = "model/blockworld/IconModel/IconModel_32x32.x";
			scaling = scaling or 1;
			bUseIcon = true;
		end
		if(model_filename) then
			self.offset_y = offsets_map[model_filename];
		end

		local obj = ObjEditor.CreateObjectByParams({
			name = "",
			IsCharacter = false,
			AssetFile = model_filename or "",
			x = x or self.x,
			y = (y or self.y) + self.offset_y,
			z = z or self.z,
			scaling = BlockEngine.blocksize, 
			facing = facing or self.facing,
			IsPersistent = false,
			EnablePhysics = false,
		});
		-- MESH_USE_LIGHT = 0x1<<7: use block ambient and diffuse lighting for this model. 
		obj:SetAttribute(128, true);
		-- OBJ_SKIP_PICKING = 0x1<<15:
		obj:SetAttribute(0x8000, true);
		obj:SetField("progress", 1);
		-- obj:SetField("persistent", false); 
		-- obj:SetScale(BlockEngine.blocksize);
		obj:SetField("RenderDistance", 160);

		if(model_filename and model_filename~="") then
			if(bUseIcon) then
				local tex = item:GetIconObject();
				if(tex) then
					obj:SetReplaceableTexture(2, tex);
				end
				obj:SetField("FaceCullingDisabled", true);
			else
				local block = item:GetBlock();
				if(block) then
					local tex = block:GetTextureObj();
					if(tex) then
						obj:SetReplaceableTexture(2, tex);
					end
				end
			end
		end
		
		ParaScene.Attach(obj);	
		self:SetInnerObject(obj);
		return obj;
	end
end

function Entity:LoadFromXMLNode(node)
	Entity._super.LoadFromXMLNode(self, node);

	local attr = node.attr;
	self.sim_time = tonumber(attr.sim_time) or 0;
	self.block_id = tonumber(attr.block_id) or 0;
	self.block_data = tonumber(attr.block_data) or 0;
end

function Entity:SaveToXMLNode(node)
	node = Entity._super.SaveToXMLNode(self, node);

	node.attr.sim_time = self.sim_time;
	node.attr.block_id = self.block_id;
	node.attr.block_data = self.block_data;
	return node;
end

-- push colliding entity in the direction of the current entity.
-- @return true if the current enity should be stopped. 
function Entity:CollideWithEntity(fromEntity, deltaTime)
    local vx, vy, vz = self:GetVelocity();
	local minSpeed = fromEntity:GetPhysicsObject():GetMinSpeed();
	if(vx~=0 and vy==0 and vz==0) then
		fromEntity:GetPhysicsObject():SetVelocity(minSpeed+vx*1.2, nil, nil);
	elseif(vx==0 and vy==0 and vz~=0) then
		fromEntity:GetPhysicsObject():SetVelocity(nil, nil, minSpeed+vz*1.2);
	elseif(vx==0 and vy~=0 and vz==0) then
		local dx, dy, dz = fromEntity:GetPosition();
		local x, y, z = self:GetPosition();
		if(dy<y and vy<0) then
			-- hitting down to fromEntity. stop self immediately.  
			self:GetPhysicsObject():SetVelocity(nil,-0.1, nil);
			return true;
		end
	else
		self:ApplyEntityCollision(fromEntity, deltaTime);
	end
end

-- turn into a static block again. 
function Entity:OnBecomeStaticBlock(x,y,z)
	local last_block = BlockEngine:GetBlock(x,y,z);
	if(last_block and last_block.id ~= self.block_id) then
		last_block:DropBlockAsItem(x,y,z);
	end

	BlockEngine:SetBlock(x,y,z, self.block_id, self.block_data, 3);
	self:SetDead();

	local block_template = block_types.get(self.block_id);
	if( block_template and block_template.OnFinishMove) then
		block_template:OnFinishMove(x,y,z);
	end 
end

-- called every frame
function Entity:FrameMove(deltaTime)
	local x,y,z = self:GetBlockPos();

	if(self.block_id == 0) then
		self:SetDead();
		return;
	end
	
	if(self.sim_time == 0) then
		if(BlockEngine:GetBlockId(x,y,z) ~= self.block_id) then
			self:SetDead();
			return;
		end
		BlockEngine:SetBlockToAir(x,y,z, 3);
	end

	

	-- checking collision with other entities
	local shouldStop;
	local entities = EntityManager.GetEntitiesByAABBExcept(self:GetCollisionAABB(), self);
	if(entities) then
		for _, entity in ipairs(entities) do
			if(entity:CanBePushedBy(self)) then
				shouldStop = self:CollideWithEntity(entity, deltaTime) or shouldStop;
			end
		end
	end

	if(not shouldStop) then
		self:SetFrameMoveInterval(Entity.framemove_interval);

		self:MoveEntity(deltaTime, true);

		-- if(self.physic_obj:IsOnGround()) then
		if(y <= 0 or not self:HasSpeed()) then
			self:OnBecomeStaticBlock(x,y,z);
			return;
		--elseif(self.sim_time > 12) then
			-- falling moving for two long will destroy the entity. 
			-- self:SetDead();
		end
	else
		self:SetFrameMoveInterval(0.2);
	end

	self.sim_time = self.sim_time + deltaTime;

	Entity._super.FrameMove(self, deltaTime);
end


