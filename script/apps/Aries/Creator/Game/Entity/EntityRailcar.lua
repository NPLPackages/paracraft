--[[
Title: rail car
Author(s): LiXizhi
Date: 2014/6/8
Desc: a car that runs on rails. It will slow down immediately when on a non-powered PowerRail
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityRailcar.lua");
local EntityRailcar = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityRailcar")
local entity = EntityManager.EntityRailcar:Create({x=x,y=y,z=z, item_id = block_types.names["railcar"]});
entity:Attach();
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/mathlib.lua");
NPL.load("(gl)script/ide/math/math3d.lua");
local SoundManager = commonlib.gettable("MyCompany.Aries.Game.Sound.SoundManager");
local vector3d = commonlib.gettable("mathlib.vector3d");
local math3d = commonlib.gettable("mathlib.math3d");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockRailBase = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockRailBase")
local EntityMob = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityMob")
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local DamageSource = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld.DamageSource")
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
local mathlib = commonlib.gettable("mathlib");
local math_abs = math.abs;
local math_random = math.random;
local math_floor = math.floor;

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.Entity"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityRailcar"));
local EntityRailcar = Entity;

-- class name
Entity.class_name = "Railcar";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);
-- enabled frame move. 
Entity.framemove_interval = 1/20;
-- persistent object by default. 
Entity.is_persistent = true;
-- whether this object is trackable from the server side. 
Entity.isServerEntity = true;

Entity:Property({"group_id", GameLogic.SentientGroupIDs.Mob})
-- max number of collisions to process per frame. too many collisions will lead to HIGH CPU. 
Entity:Property({"max_collision_count", 2})
Entity.sentient_fields = {[GameLogic.SentientGroupIDs.Player] = true};

--private: 
Entity.targetX = 0;
Entity.targetY = 0;
Entity.targetZ = 0;
Entity.targetFacing = 0;
Entity.targetPitch = 0;
Entity.smoothFrames = 0;


-- mapping from direction data to from:{x,y,z} to:{x,y,z} where mc_id  pc_id
local RailDirMatrix = {
	[0] = {{ -1, 0, 0}, {1, 0, 0}}, -- 1 1
	-- x,z straight
	{{ -1, 0, 0}, {1, 0, 0}}, -- 1 1
	{{0, 0, -1}, {0, 0, 1}},  -- 0 2
	-- 4 corners
	{{0, 0, 1}, {1, 0, 0}}, -- 6 3
	{{0, 0, 1}, { -1, 0, 0}}, -- 7 4
	{{0, 0, -1}, { -1, 0, 0}}, -- 8 5
	{{0, 0, -1}, {1, 0, 0}}, -- 9 6
	-- 4 slopes
	{{ -1, -1, 0}, {1, 0, 0}}, -- 2 7
	{{0, -1, -1}, {0, 0, 1}}, -- 5 8
	{{ -1, 0, 0}, {1, -1, 0}}, -- 3 9
	{{0, 0, -1}, {0, -1, 1}}, -- 4 10
};

function Entity:ctor()
	self.rotationYaw = 0;
	self.rotationPitch = 0;
	self.prevRotationPitch = 0;
	self.prevRotationYaw = 0;
	self.motionX = 0;
	self.motionY = 0;
	self.motionZ = 0;
	self.rolling_amplitude = 0;
	self.rolling_direction = 1;
	self.MoveSoundVolume = 0;
	self.MoveSoundPitch = 0;
	self.RideSoundVolume = 0;
	self.SoundPitch = 0;
end

function Entity:GetPhysicsRadius()
	return 0.5;
end

function Entity:GetPhysicsHeight()
	return 1;
end

function Entity:GetMountedYOffset()
	return 0.3;
end

function Entity:IsOnGround()
	return self.onGround;
end

function Entity:CanTeleport()
	return true;
end

function Entity:CanBeMounted()
	return true;
end

-- @param Entity: the half radius of the object. 
function Entity:init()
	local item = self:GetItemClass();
	if(item) then
		self.rotationYaw = ((self.facing or 0)*180/math.pi)%360;

		local x, y, z = self:GetPosition();

		local skin = item:GetSkinFile();
		local ReplaceableTextures;
		if(skin) then
			ReplaceableTextures = {[2] = skin};
		end

		local obj = ObjEditor.CreateObjectByParams({
			name = self.name or self.class_name,
			IsCharacter = true,
			AssetFile = self:GetMainAssetPath(),
			ReplaceableTextures = ReplaceableTextures,
			x = x,
			y = y + item:GetOffsetY(),
			z = z,
			scaling = self.scaling or item:GetScaling(),
			facing = self.facing, 
			IsPersistent = false,
		});
		-- obj:SetField("GroupID", self.group_id);
		-- make it linear movement style
		obj:SetField("MovementStyle", 3);
		
		obj:SetField("PerceptiveRadius", item.PerceptiveRadius or 40);
		obj:SetField("Sentient Radius", item.SentientRadius or 40);
		obj:SetField("Gravity", GameLogic.options.Gravity*2);

		self.group_id = item.group_id or self.group_id;
		obj:SetField("GroupID", self.group_id);
		for field, _ in pairs(self.sentient_fields) do
			obj:SetSentientField(field, true); 
		end

		-- MESH_USE_LIGHT = 0x1<<7: use block ambient and diffuse lighting for this model. 
		obj:SetAttribute(128, true);

		self:SetInnerObject(obj);
		ParaScene.Attach(obj);	

		item:UpdateInWorldCount(1);
		self:UpdateBlockContainer();
		return self;
	else
		LOG.std(nil, "warn", "EntityRailcar", "item class not found. item_id: %d", self.item_id or 0);
	end
end

local validateNumber = mathlib.validateNumber;

function Entity:LoadFromXMLNode(node)
	Entity._super.LoadFromXMLNode(self, node);

	local attr = node.attr;
	if(attr) then
		if(attr.motionX) then
			self.motionX = validateNumber(tonumber(attr.motionX) or 0)
		end
		if(attr.motionY) then
			self.motionY = validateNumber(tonumber(attr.motionY) or 0)
		end
		if(attr.motionZ) then
			self.motionZ = validateNumber(tonumber(attr.motionZ) or 0)
		end
		if (attr.onGround) then
			self.onGround = attr.onGround == "true"
		end
		if (attr.rotationPitch) then
			self.rotationPitch = validateNumber(tonumber(attr.rotationPitch) or 0);
			self.prevRotationPitch = self.rotationPitch;
		end
		if (attr.rotationYaw) then
			self.rotationYaw = validateNumber(tonumber(attr.rotationYaw) or 0);
			self.prevRotationYaw = self.rotationYaw;
		end
	end
end

function Entity:SaveToXMLNode(node, bSort)
	node = Entity._super.SaveToXMLNode(self, node, bSort);

	local attr = node.attr;
	if(self.motionX) then
		attr.motionX = self.motionX
	end
	if(self.motionY) then
		attr.motionY = self.motionX
	end
	if(self.motionZ) then
		attr.motionZ = self.motionZ
	end
	if (self.onGround) then
		attr.onGround = self.onGround
	end
	if (self.rotationPitch) then
		attr.rotationPitch = self.rotationPitch;
	end
	if (self.rotationYaw) then
		attr.rotationYaw = self.rotationYaw;
	end

	return node;
end

function Entity:doesEntityTriggerPressurePlate()
	return true;
end

-- Returns true if the entity takes up space in its containing block, such as animals,mob and players. 
function Entity:CanBeCollidedWith(entity)
	return true;
end

-- Returns true if this entity should push and be pushed by other entities when colliding.
-- such as mob and players.
function Entity:CanBePushedBy(fromEntity)
    return true;
end

function Entity:Destroy()
	self:DestroyInnerObject();
	
	local item;
	if(self.item_id and self.item_id>0) then
		item = ItemClient.GetItem(self.item_id);
	end
	if(item) then
		item:UpdateInWorldCount(-1);
	end
	if(self.silent == false) then
		SoundManager:StopEntitySound(self);		
	end
	Entity._super.Destroy(self);
end

-- Sets the rolling amplitude the cart rolls 
function Entity:SetRollingAmplitude(value)
   self.rolling_amplitude = value;
end

-- Gets the rolling amplitude the cart rolls while being attacked.
function Entity:GetRollingAmplitude()
   return self.rolling_amplitude;
end

-- Sets the rolling direction. Can be 1 or -1.
function Entity:SetRollingDirection(dir)
	self.rolling_direction = dir;
end

-- Gets the rolling direction the cart rolls. Can be 1 or -1.
function Entity:GetRollingDirection()
    return self.rolling_direction;
end

local normal_ = {};
-- Sets the rotation of the entity
function Entity:SetRotation(yaw, pitch)
    self.rotationYaw = yaw % 360;
    self.rotationPitch = pitch % 360;
	local obj = self:GetInnerObject();
	if(obj) then
		self.facing = -self.rotationYaw*math.pi/180;
		obj:SetFacing(self.facing);

		local facing = self.facing;
		if(self.rotationYaw < 180) then
			facing = facing+math.pi;
		end
		if(pitch~=0) then
			pitch = self.rotationPitch*math.pi/180;
			normal_[1], normal_[2], normal_[3] = math.sin(pitch), math.cos(pitch), 0;
			normal_[1], normal_[2], normal_[3] = math3d.vec3Rotate(normal_[1], normal_[2], normal_[3],  0, facing, 0)
		else
			local roll = self:GetRollingAmplitude();
			if(roll~=0) then
				roll = roll*math.pi/180*self:GetRollingDirection();
				normal_[1], normal_[2], normal_[3] = 0, math.cos(roll), math.sin(roll);
				normal_[1], normal_[2], normal_[3] = math3d.vec3Rotate(normal_[1], normal_[2], normal_[3],  0, facing, 0)
			else
				normal_[1], normal_[2], normal_[3] = 0,1,0;
			end
		end
		
		obj:SetField("normal", normal_);
	end
end

-- update the entity position when it is not on the track (rail)
-- @param maxSpeed: actually max dist in this tick
function Entity:updateNotOnTrack(deltaTime, maxSpeed)
    if (self.motionX < -maxSpeed) then
        self.motionX = -maxSpeed;
    end

    if (self.motionX > maxSpeed) then
        self.motionX = maxSpeed;
    end

    if (self.motionZ < -maxSpeed) then
        self.motionZ = -maxSpeed;
    end

    if (self.motionZ > maxSpeed) then
        self.motionZ = maxSpeed;
    end

    if (self.onGround) then
        self.motionX = self.motionX * 0.5;
        self.motionY = self.motionY * 0.5;
        self.motionZ = self.motionZ * 0.5;
    end

    self:MoveEntityByDisplacement(self.motionX, self.motionY, self.motionZ);

    if (not self.onGround) then
		self.motionX = self.motionX * 0.949999988079071;
        self.motionY = self.motionY * 0.949999988079071;
        self.motionZ = self.motionZ * 0.949999988079071;
    end
end

-- virtual: Called every tick the car is on an activator rail.
function Entity:OnActivatorRailPass(bx, by, bz, bDataSet)
end

-- Sets the entity's position and rotation in the next smoothFrames. 
-- @param smoothFrames: smoothed frames. we will move to x,y,z in this number of ticks. If nil, it means no frames
function Entity:SetPositionAndRotation2(x,y,z,yaw, pitch, smoothFrames)
	self.targetX = x;
	self.targetY = y;
	self.targetZ = z;
	self.targetYaw = yaw or self.targetYaw;
	self.targetPitch = pitch or self.targetPitch;
	self.smoothFrames = (smoothFrames or -2) + 2;
end

-- called every frame
function Entity:FrameMove(deltaTime)
	-- LOG.std(nil, "debug", "railcar tick", deltaTime);
	local bx, by, bz = self:GetBlockPos();
	if(by <= 0) then
		self:SetDead();
	end
	self:OnUpdateSound();

	if (self:GetRollingAmplitude() > 0) then
       self:SetRollingAmplitude(self:GetRollingAmplitude() - 1);
	end

	-- recover damage by 1 each tick. 
	if (self:GetDamage() > 0.0) then
        self:SetDamage(self:GetDamage() - 1.0);
    end
	
	if(GameLogic.isRemote) then
		if (self.smoothFrames > 0) then
            local newX = self.x + (self.targetX - self.x) / self.smoothFrames;
            local newY = self.y + (self.targetY - self.y) / self.smoothFrames;
            local newZ = self.z + (self.targetZ - self.z) / self.smoothFrames;

            self.rotationYaw = (self.rotationYaw + mathlib.WrapAngleTo180(self.targetYaw - self.rotationYaw) / self.smoothFrames);
            self.rotationPitch = (self.rotationPitch + mathlib.WrapAngleTo180(self.targetPitch - self.rotationPitch) / self.smoothFrames);
			self.smoothFrames = self.smoothFrames - 1;

			self:SetPosition(newX, newY, newZ);
        else
			local newX = self.targetX or self.x;
			local newY = self.targetY or self.y;
			local newZ = self.targetZ or self.z;
			self.rotationYaw = self.targetYaw or self.rotationYaw;
			self.rotationPitch = self.targetPitch or self.rotationPitch;
            self:SetPosition(newX, newY, newZ);
        end
		if(self.prevRotationPitch~=self.rotationPitch or self.rotationYaw~=self.prevRotationYaw) then
			self.prevRotationPitch = self.rotationPitch;
			self.prevRotationYaw = self.rotationYaw;
			self:SetRotation(self.rotationYaw, self.rotationPitch);
		end
	else
		local x, y, z = self:GetPosition();	
	
		self.prevPosX = x;
		self.prevPosY = y;
		self.prevPosZ = z;
		self.prevRotationPitch = self.rotationPitch;
		self.prevRotationYaw = self.rotationYaw;

		-- basic gravity
		self.motionY = self.motionY - 0.04;
    
		if (BlockRailBase.isRailBlockAt(bx, by - 1, bz)) then
			by = by - 1;
		end

		local maxSpeed = 0.4;
		local slopeDecayFactor = 0.0078125;
		local curBlockId = BlockEngine:GetBlockId(bx, by, bz);

		self.rotationPitch = 0.0;
		if (BlockRailBase.isRailBlock(curBlockId)) then
			-- entity is on rail
			local blockData = BlockEngine:GetBlockData(bx, by, bz);
			self:UpdateOnTrack(deltaTime, bx, by, bz, maxSpeed, slopeDecayFactor, curBlockId, blockData);

			if (curBlockId == block_types.names.RailActivator) then
				self:OnActivatorRailPass(bx, by, bz, blockData>=16);
			end
		else
			-- not on rail
			self:updateNotOnTrack(deltaTime, maxSpeed);
		end
    
		self:NotifyBlockCollisions();
    
		x, y, z = self:GetPosition();	
		local dirX = self.prevPosX - x;
		local dirZ = self.prevPosZ - z;

		if ((dirX * dirX + dirZ * dirZ) > 0.001) then
			self.rotationYaw = (math.atan2(dirZ, dirX) * 180.0 / math.pi);
			if (self.isInReverse) then
				self.rotationYaw = self.rotationYaw + 180.0;
			end
		end

		local  deltaRotYaw = mathlib.WrapAngleTo180(self.rotationYaw - self.prevRotationYaw);
		if (deltaRotYaw < -170.0 or deltaRotYaw >= 170.0) then
			self.rotationYaw = self.rotationYaw + 180.0;
			self.isInReverse = not self.isInReverse;
		end
	
		if((self.prevRotationPitch - self.rotationPitch)>180) then
			self.prevRotationPitch = self.prevRotationPitch - 360;
		elseif((self.rotationPitch - self.prevRotationPitch) > 180) then
			self.prevRotationPitch = self.prevRotationPitch + 360;
		end
		local pitchSpeed = 20;
		if((self.prevRotationPitch - self.rotationPitch) >= pitchSpeed) then
			self.rotationPitch = self.prevRotationPitch - pitchSpeed;
		elseif((self.rotationPitch - self.prevRotationPitch) >= pitchSpeed) then
			self.rotationPitch = self.prevRotationPitch + pitchSpeed;
		end
	
		self:SetRotation(self.rotationYaw, self.rotationPitch);
	
		local collisionList = EntityManager.GetEntitiesByAABBExcept(self:GetCollisionAABB(), self);

		if (collisionList and (#collisionList)>0) then
			for i=1, math.min(self.max_collision_count, #collisionList) do
				local entityObj = collisionList[i]
				if (entityObj:isa(EntityRailcar) and entityObj ~= self.riddenByEntity) then
					entityObj:ApplyEntityCollision(self, deltaTime);
				end
			end
		end

		if (self.riddenByEntity and self.riddenByEntity:IsDead()) then
			if (self.riddenByEntity.ridingEntity == self) then
				self.riddenByEntity.ridingEntity = nil;
			end
			self.riddenByEntity = nil;
		end
	end
end

function Entity:ApplySpeedDecay()
    if (self.riddenByEntity) then
        self.motionX = self.motionX * 0.996999979019165;
        self.motionY = 0;
        self.motionZ = self.motionZ * 0.996999979019165;
    else
        self.motionX = self.motionX * 0.9599999785423279;
        self.motionY = 0;
        self.motionZ = self.motionZ * 0.9599999785423279;
    end
end


-- get the location of car on the current rail block. 
-- @param isInputBlockIndex: true if posX, posY, posZ is floating block and the returned value is also floating point
-- please note that posY must be center of boundingbox(i.e. self.y + 0.5)
-- @return x,y,z: location on the frame.  
function Entity:GetRailPointFromPos(posX, posY, posZ, isInputBlockIndex)
	local bx, by, bz;
	if(isInputBlockIndex) then
		bx, by, bz = math.floor(posX), math.floor(posY), math.floor(posZ);
	else
		bx, by, bz = BlockEngine:block(posX, posY, posZ);
		posX, posY, posZ = BlockEngine:block_float(posX, posY, posZ);
	end

    if (BlockRailBase.isRailBlockAt(bx, by - 1, bz)) then
        by = by - 1;
    end

    local curBlockId = BlockEngine:GetBlockId(bx, by, bz);

    if (BlockRailBase.isRailBlock(curBlockId)) then
		-- entity is on rail
        local blockData = BlockEngine:GetBlockData(bx, by, bz);

        posY = by;

        if (block_types.get(curBlockId):CanHasPower()) then
            blockData = mathlib.bit.band(blockData, 15);
        end

        -- sloped rail
		if (blockData >= 7 and blockData <= 10) then
			posY = by + 1;
		end

		local matRotRail = RailDirMatrix[blockData];

		-- relative distance traveled on the rail.  
        local distTraveled = 0;
        local fromX = bx + 0.5 + matRotRail[1][1] * 0.5;
        local fromY = by + 0.5 + matRotRail[1][2] * 0.5;
        local fromZ = bz + 0.5 + matRotRail[1][3] * 0.5;
        local toX = bx + 0.5 + matRotRail[2][1] * 0.5;
        local toY = by + 0.5 + matRotRail[2][2] * 0.5;
        local toZ = bz + 0.5 + matRotRail[2][3] * 0.5;
        local dirX = toX - fromX;
        local dirY = (toY - fromY) * 2.0;
        local dirZ = toZ - fromZ;

        if (dirX == 0) then
            distTraveled = posZ - bz;
        elseif (dirZ == 0) then
            distTraveled = posX - bx;
        else
            local dx = posX - fromX;
            local dz = posZ - fromZ;
            distTraveled = (dx * dirX + dz * dirZ) * 2;
        end

        posX = fromX + dirX * distTraveled;
        posY = fromY + dirY * distTraveled;
        posZ = fromZ + dirZ * distTraveled;

        if (dirY < 0) then
            posY = posY + 1;
        elseif (dirY > 0) then
            posY = posY + 0.5;
        end
		if(not isInputBlockIndex) then
			posX, posY, posZ = BlockEngine:real_min(posX, posY, posZ);
		end
        return posX, posY, posZ;
    end
end

function Entity:UpdateOnTrack(deltaTime, bx, by, bz, maxSpeed, slopeDecayFactor, curBlockId, blockData)
    self.fallDistance = 0;
	local posX, posY, posZ = self:GetPosition();
    -- convert to block index float
	posX, posY, posZ = BlockEngine:block_float(posX, posY, posZ);
	posY = posY + 0.5;
	local vecLastRailPosX, vecLastRailPosY, vecLastRailPosZ = self:GetRailPointFromPos(posX, posY, posZ, true);
    posY = by;
    local bAccelerate = false;
    local bDecelerate = false;

    if (curBlockId == block_types.names.RailPowered) then
        bAccelerate = blockData >= 16;
        bDecelerate = not bAccelerate;
    end

    if (block_types.get(curBlockId):CanHasPower()) then
        blockData = mathlib.bit.band(blockData, 15);
    end

	-- sloped rail
    if (blockData >= 7 and blockData <= 10) then
        posY = by + 1;
		if(blockData == 7 or blockData == 8) then
			self.rotationPitch = 45;
		else
			self.rotationPitch = -45;
		end
    end

	-- posX is higher
    if (blockData == 7) then
        self.motionX = self.motionX - slopeDecayFactor;
    end

	-- negX is higher
    if (blockData == 9) then
        self.motionX = self.motionX + slopeDecayFactor;
    end

	-- negZ is higher
    if (blockData == 10) then
        self.motionZ = self.motionZ + slopeDecayFactor;
    end

	-- posZ is higher
    if (blockData == 8) then
        self.motionZ = self.motionZ - slopeDecayFactor;
    end

    local matRotRail = RailDirMatrix[blockData];
    local dirX = (matRotRail[2][1] - matRotRail[1][1]);
    local dirZ = (matRotRail[2][3] - matRotRail[1][3]);
    local dirLength = math.sqrt(dirX * dirX + dirZ * dirZ);
    local dotMotionDir = self.motionX * dirX + self.motionZ * dirZ;

    if (dotMotionDir < 0) then
        dirX = -dirX;
        dirZ = -dirZ;
    end

    local curMotionSpeed = math.sqrt(self.motionX * self.motionX + self.motionZ * self.motionZ);

	-- do not go too fast
    if (curMotionSpeed > 2.0) then
        curMotionSpeed = 2.0;
    end

	-- adjust direction according to rail track direction
	if(dirLength>0.001) then
		self.motionX = curMotionSpeed * dirX / dirLength;
		self.motionZ = curMotionSpeed * dirZ / dirLength;
	else
		self.motionX = 0;
		self.motionZ = 0;
	end
    local deltaDistWalked;
    
    if (self.riddenByEntity) then
		-- player on the rail can slowly move the car
        deltaDistWalked = self.riddenByEntity.moveForward;
        if (deltaDistWalked and deltaDistWalked > 0) then
            local motionScale = self.motionX * self.motionX + self.motionZ * self.motionZ;
            if (motionScale < 0.01) then
				local facing = self.riddenByEntity:GetFacing();
				local dirXEntity = -math.sin(facing);
				local dirZEntity = math.cos(facing);
                self.motionX = self.motionX + dirXEntity * 0.1;
                self.motionZ = self.motionZ + dirZEntity * 0.1;
                bDecelerate = false;
            end
        end
    end

    if (bDecelerate) then
		-- slow down the car, such as on a not-activated PoweredRail. 
        deltaDistWalked = math.sqrt(self.motionX * self.motionX + self.motionZ * self.motionZ);

        if (deltaDistWalked < 0.03) then
            self.motionX = 0;
            self.motionY = 0;
            self.motionZ = 0;
        else
            self.motionX = self.motionX * 0.5;
            self.motionY = 0;
            self.motionZ = self.motionZ * 0.5;
        end
    end

    deltaDistWalked = 0;
    local fromX = bx + 0.5 + matRotRail[1][1] * 0.5;
    local fromZ = bz + 0.5 + matRotRail[1][3] * 0.5;
    local toX = bx + 0.5 + matRotRail[2][1] * 0.5;
    local toZ = bz + 0.5 + matRotRail[2][3] * 0.5;
    dirX = toX - fromX;
    dirZ = toZ - fromZ;

    if (dirX == 0) then
        posX = bx + 0.5;
        deltaDistWalked = posZ - bz;
    elseif (dirZ == 0) then
        posZ = bz + 0.5;
        deltaDistWalked = posX - bx;
    else
        deltaDistWalked = ((posX - fromX) * dirX + (posZ - fromZ) * dirZ) * 2.0;
    end

    posX = fromX + dirX * deltaDistWalked;
    posZ = fromZ + dirZ * deltaDistWalked;

	self:SetPosition(BlockEngine:real_min(posX, posY, posZ));
    local motionDX = self.motionX;
    local motionDZ = self.motionZ;

    if (self.riddenByEntity) then
        motionDX = motionDX * 0.75;
        motionDZ = motionDZ * 0.75;
    end

    if (motionDX < -maxSpeed) then
        motionDX = -maxSpeed;
    end

    if (motionDX > maxSpeed) then
        motionDX = maxSpeed;
    end

    if (motionDZ < -maxSpeed) then
        motionDZ = -maxSpeed;
    end

    if (motionDZ > maxSpeed) then
        motionDZ = maxSpeed;
    end

    self:MoveEntityByDisplacement(motionDX, 0, motionDZ);
	posX, posY, posZ = self:GetPosition();
	local old_x, old_z = posX, posZ;
	posX, posY, posZ = BlockEngine:block_float(posX, posY, posZ);
	posY = posY + 0.5;
	local oldPosY = posY;
	-- we have reached either ends of a sloped rail, adjust the Y. 
    if (matRotRail[1][2] ~= 0 and (math.floor(posX) - bx) == matRotRail[1][1] and (math.floor(posZ) - bz) == matRotRail[1][3]) then
		posY = posY + matRotRail[1][2];
        self:SetPosition(old_x, BlockEngine:realY(posY-0.5), old_z);
    elseif (matRotRail[2][2] ~= 0 and (math.floor(posX) - bx) == matRotRail[2][1] and (math.floor(posZ) - bz) == matRotRail[2][3]) then
		posY = posY + matRotRail[2][2]
        self:SetPosition(old_x, BlockEngine:realY(posY-0.5), old_z);
    end

    self:ApplySpeedDecay();

	local vecOnRailPtX, vecOnRailPtY, vecOnRailPtZ = self:GetRailPointFromPos(posX, posY, posZ, true);

    if (vecOnRailPtY and vecLastRailPosY ) then
        local dirY = (vecLastRailPosY - vecOnRailPtY) * 0.05;
        curMotionSpeed = math.sqrt(self.motionX * self.motionX + self.motionZ * self.motionZ);

        if (curMotionSpeed > 0.0001 and dirY~=0) then
            self.motionX = self.motionX / curMotionSpeed * (curMotionSpeed + dirY);
            self.motionZ = self.motionZ / curMotionSpeed * (curMotionSpeed + dirY);
        end
        self:SetPosition(old_x, BlockEngine:realY(vecOnRailPtY-0.5), old_z);
    end
	
    local newBX = math.floor(posX);
    local newBZ = math.floor(posZ);

	-- ensure we are moving to a new block with the current motion speed in the direction traveled. 
    if (newBX ~= bx or newBZ ~= bz) then
        curMotionSpeed = math.sqrt(self.motionX * self.motionX + self.motionZ * self.motionZ);
        self.motionX = curMotionSpeed * (newBX - bx);
        self.motionZ = curMotionSpeed * (newBZ - bz);
    end

    if (bAccelerate) then
        local curSpeed = math.sqrt(self.motionX * self.motionX + self.motionZ * self.motionZ);

        if (curSpeed > 0.01) then
			-- increase 6% every tick
            local accelSpeedPercent = 0.06;
            self.motionX = self.motionX + self.motionX / curSpeed * accelSpeedPercent;
            self.motionZ = self.motionZ + self.motionZ / curSpeed * accelSpeedPercent;
        elseif (blockData == 1) then
			-- accelerate with big speed when powered rail has one end connecting to normal cube block
            if (BlockEngine:isBlockNormalCube(bx - 1, by, bz)) then
                self.motionX = 0.02;
            elseif (BlockEngine:isBlockNormalCube(bx + 1, by, bz)) then
                self.motionX = -0.02;
			end            
        elseif (blockData == 2) then
			-- accelerate with big speed when powered rail has one end connecting to normal cube block
            if (BlockEngine:isBlockNormalCube(bx, by, bz - 1)) then
                self.motionZ = 0.02;
            elseif (BlockEngine:isBlockNormalCube(bx, by, bz + 1)) then
                self.motionZ = -0.02;
            end
        end
    end
end

-- type 2 is a heavy car that will slow down other cars when collided. 
function Entity:GetCarType()
	return 0;
end

-- may mount the entity if the car runs on to it. 
-- if multiple cars collide together, it will form a train
function Entity:ApplyEntityCollision(fromEntity, deltaTime)
	if(GameLogic.isRemote) then
		return
	end
	if(not self:IsTick("ApplyEntityCollision", deltaTime, nil)) then
		return
	end
	if (fromEntity ~= self.riddenByEntity) then
		
        if (fromEntity:isa(EntityMob) and self:GetCarType() == 0 and (self.motionX * self.motionX + self.motionZ * self.motionZ) > 0.01 and not self.riddenByEntity and not fromEntity.ridingEntity) then
            fromEntity:MountEntity(self);
        end

        local from_x, from_y, from_z = fromEntity:GetPosition();
		local x,y,z = self:GetPosition();
		local dX = from_x - x;
		local dZ = from_z - z;

        local dist = dX * dX + dZ * dZ;

        if (dist >= 0.001) then
            dist = math.sqrt(dist);
            dX = dX / dist;
			dZ = dZ / dist;
			local invert_dist = 1 / dist;

			if (invert_dist > 1) then
				invert_dist = 1;
			end

			local delta = invert_dist * 0.05 * (1.0 - self.entityCollisionReduction)
			dX = dX * delta;
			dZ = dZ * delta;

            if (fromEntity:isa(EntityRailcar)) then
				-- when railcar collide with another rail car, it will form a train by gradually averaging their speed. 
                local dx1 = from_x - x;
                local dz1 = from_z - z;
                
				local vecDir = vector3d:new_from_pool(dx1, 0, dz1):normalize();
				local facing = self.facing or 0;
                local cosAngle = math.abs(vecDir:dot(math.cos(facing), 0, math.sin(facing)));

                if (cosAngle < 0.800000011920929) then
                    return;
                end

                local motionX = fromEntity.motionX + self.motionX;
                local motionZ = fromEntity.motionZ + self.motionZ;

                if (fromEntity:GetCarType() == 2 and self:GetCarType() ~= 2) then
					-- car type 2 will be slowed down 
                    self.motionX = self.motionX * 0.20000000298023224;
                    self.motionZ = self.motionZ * 0.20000000298023224;
                    self:AddMotion(fromEntity.motionX - dX, 0.0, fromEntity.motionZ - dZ);
                    fromEntity.motionX = fromEntity.motionX * 0.949999988079071;
                    fromEntity.motionZ = fromEntity.motionZ * 0.949999988079071;
                elseif (fromEntity:GetCarType() ~= 2 and self:GetCarType() == 2) then
					-- car type 2 will be slowed down
                    fromEntity.motionX = fromEntity.motionX * 0.20000000298023224;
                    fromEntity.motionZ = fromEntity.motionZ * 0.20000000298023224;
                    fromEntity:AddMotion(self.motionX + dX, 0, self.motionZ + dZ);
                    self.motionX = self.motionX * 0.949999988079071;
                    self.motionZ = self.motionZ * 0.949999988079071;
                else
					-- for other cars, the two cars will tend to have the same speed. 
                    motionX = motionX * 0.5;
                    motionZ = motionZ * 0.5;
                    self.motionX = self.motionX * 0.20000000298023224;
                    self.motionZ = self.motionZ * 0.20000000298023224;
                    self:AddMotion(motionX - dX, 0, motionZ - dZ);
                    fromEntity.motionX = fromEntity.motionX * 0.20000000298023224;
                    fromEntity.motionZ = fromEntity.motionZ * 0.20000000298023224;
                    fromEntity:AddMotion(motionX + dX, 0.0, motionZ + dZ);
                end
            else
                self:AddMotion(-dX, 0, -dZ);
                fromEntity:AddMotion(dX / 4.0, 0, dZ / 4.0);
            end
        end
    end
end

-- right click to show item
function Entity:OnClick(x, y, z, mouse_button)
	if(mouse_button == "left") then
		if(not GameLogic.isRemote) then
			-- left click to delete it
			self:AttackEntityFrom(DamageSource:CausePlayerDamage(EntityManager.GetPlayer()), 1);
		end
		
	elseif(mouse_button == "right") then
		-- right click to ride on it
		local player = EntityManager.GetFocus();
		if(player) then
			-- check distance
			local bx,by,bz = player:GetBlockPos();
			if(self:DistanceSqTo(bx,by,bz) > 3*3) then
				BroadcastHelper.PushLabel({id="Mount", label = "距离太远", max_duration=5000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
			else
				BroadcastHelper.PushLabel({id="Mount", label = "SHIFT键下来", max_duration=5000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
				local player = EntityManager.GetFocus();
				if(player) then
					if(GameLogic.isRemote) then
						GameLogic.GetPlayer():AddToSendQueue(GameLogic.Packets.PacketEntityAction:new():Init(1, self));
					else
						player:MountEntity(self);	
					end
				end
			end
		end
	end
	return true;
end


-- Sets the current amount of damage the car has taken. 
-- Decreases over time. The cart breaks when this is over 40.
function Entity:SetDamage(amount)
	self.amount = amount;
end

function Entity:GetDamage()
    return self.amount or 0;
end

function Entity:DoKillSelf(damageSource, bDropItem)
	self:SetDead();
	-- play break animation. 
	local item = ItemClient.GetItem(self.item_id);
	if(item) then
		item:CreateBlockPieces(self.bx, self.by, self.bz);
	end
	-- drop item if any
	if(bDropItem) then
		local itemStack = ItemStack:new():Init(self.item_id, 1);
		self:EntityDropItem(itemStack, 0.0);
	end
end

 -- Called when the entity is attacked.
 function Entity:AttackEntityFrom(damageSource, amount)
    if (not GameLogic.isRemote and not self:IsDead()) then
        if (self:IsEntityInvulnerable()) then
            return false;
        else
            self:SetRollingDirection(-self:GetRollingDirection());
            self:SetRollingAmplitude(10);
            self:SetBeenAttacked();
            self:SetDamage(self:GetDamage() + amount * 10.0);
			
            local isPlayerCreativeMode = damageSource:GetEntity() and damageSource:GetEntity():isa(EntityManager.EntityPlayer) and damageSource:GetEntity().capabilities:IsCreativeMode();

            if (isPlayerCreativeMode or self:GetDamage() > 40.0) then
                if (self.riddenByEntity) then
                    self.riddenByEntity:MountEntity(self);
                end

                if (isPlayerCreativeMode) then
                    self:DoKillSelf(damageSource, false);
                else
                    self:DoKillSelf(damageSource, true);
                end
            end
            return true;
		end
    else
        return true;
    end
end

-- updating the sound. 
function Entity:OnUpdateSound()
	local bFirstSoundPlaying = false;
    local bLastIsRidden = self.IsRidden;
    local bLastIsDead = self.RailCarIsDead;
    local bLastIsMoving = self.isMoving;
    local fLastMoveSoundVolume = self.MoveSoundVolume;
    local fLastSoundPitch = self.SoundPitch;
    local fLastRideSoundVolume = self.RideSoundVolume;
    local fLastSpeed = self.curSpeed;
    self.curSpeed = math.sqrt(self.motionX * self.motionX + self.motionZ * self.motionZ);
    self.isMoving = self.curSpeed >= 0.01;
	-- check if it is ridden by current player. 
	self.IsRidden = self.riddenByEntity and self.riddenByEntity.ridingEntity == self and self.riddenByEntity:isa(EntityManager.EntityPlayer);
	self.RailCarIsDead = self:IsDead();

    if (bLastIsRidden and not self.IsRidden) then
        SoundManager:StopEntitySound(self.thePlayer);
    end

    if (self.RailCarIsDead or not self.silent and self.MoveSoundVolume == 0.0 and self.RideSoundVolume == 0.0) then
        if (not bLastIsDead) then
            SoundManager:StopEntitySound(self);
			if (bLastIsRidden or self.IsRidden) then
                SoundManager.StopEntitySound(self);
            end
        end
        self.silent = true;

        if (self.RailCarIsDead) then
            return;
        end
    end

    if (not SoundManager:IsEntitySoundPlaying(self) and self.MoveSoundVolume > 0) then
        SoundManager:PlayEntitySound("railcar_base", self, self.MoveSoundVolume, self.SoundPitch, false);
        self.silent = false;
        bFirstSoundPlaying = true;
    end

    if (self.IsRidden and not SoundManager:IsEntitySoundPlaying(self) and self.RideSoundVolume > 0.0) then
        SoundManager:PlayEntitySound("railcar_inside", self, self.RideSoundVolume, 1.0, true);
        self.silent = false;
        bFirstSoundPlaying = true;
    end

    if (self.isMoving) then
        if (self.SoundPitch < 1.0) then
            self.SoundPitch = self.SoundPitch + 0.0025;
        end

        if (self.SoundPitch > 1.0) then
            self.SoundPitch = 1.0;
        end

        local fMotionScale = mathlib.clamp(self.curSpeed, 0, 4) / 4;
        self.RideSoundVolume = 0.0 + fMotionScale * 0.75;
        fMotionScale = mathlib.clamp(fMotionScale * 2, 0.0, 1.0);
        self.MoveSoundVolume = 0.0 + fMotionScale * 0.7;
    elseif (bLastIsMoving) then
        self.MoveSoundVolume = 0;
        self.SoundPitch = 0;
        self.RideSoundVolume = 0;
    end

    if (not self.silent) then
        if (self.SoundPitch ~= fLastSoundPitch) then
            SoundManager:SetEntitySoundPitch(self, self.SoundPitch);
        end

        if (self.MoveSoundVolume ~= fLastMoveSoundVolume) then
            SoundManager:SetEntitySoundVolume(self, self.MoveSoundVolume);
        end

        if (self.RideSoundVolume ~= fLastRideSoundVolume) then
            SoundManager:SetEntitySoundVolume(self, self.RideSoundVolume);
        end
    end

    if ((self.MoveSoundVolume > 0 or self.RideSoundVolume > 0)) then
		if(not bFirstSoundPlaying) then
			SoundManager:UpdateSoundLocation(self);
			if (self.IsRidden) then
				SoundManager:UpdateSoundLocation(self, self);
			end
		end
    else
        if (SoundManager:IsEntitySoundPlaying(self)) then
            SoundManager:StopEntitySound(self);
        end

        if (self.IsRidden and SoundManager:IsEntitySoundPlaying(self)) then
            SoundManager:StopEntitySound(self);
        end
    end
end