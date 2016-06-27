--[[
Title: Base dynamic object in in block physical world
Author(s): LiXizhi
Date: 2013/1/23
Desc: A dynamic object in pure block world. The base implementation support the object is a sphere with a radius. 
One can framemove dynamic object by themselves instead of calling attach(). E.g. All Entity calls framemove by themselves. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Physics/DynamicObject.lua");
local DynamicObject = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld.DynamicObject")
local obj = PhysicsWorld.DynamicObject:new({x,y,z,radius, speed_x, speed_y, speed_z});
obj:Attach();
-------------------------------------------------------
]]
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");


local DynamicObject = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld.DynamicObject"));

local math_abs = math.abs;
local default_min_speed = 0.3;
local default_surface_decay = 0.5;
local default_air_decay = 0.02;
local default_gravity = 18.36; -- almost 2G = 9.81*2
-- lost half speed for each rebounce
local default_speedlost_perbounce = 0.5;
DynamicObject.x, DynamicObject.y, DynamicObject.z = 1,1,1;
DynamicObject.can_bounce = true;
DynamicObject.speed_x = 0;
-- we will stop the object when its speed is smaller than this value. 
DynamicObject.min_speed = nil;
DynamicObject.speed_y = 0;
DynamicObject.speed_z = 0;
DynamicObject.radius = 0.1;
-- acceleration
DynamicObject.accel_x = 0;
DynamicObject.accel_y = 0;
DynamicObject.accel_z = 0;



DynamicObject.is_stopped = nil;
DynamicObject.is_persistent = nil;

-- @param x,y,z: initial real world position. 
-- @param radius: the half radius of the object. 
function DynamicObject:ctor()
end

-- please note that y is at center not the bottom
function DynamicObject:Init(x,y,z, radius, speed_x, speed_y, speed_z)
	self.x = x or self.x;
	self.y = y or self.y;
	self.z = z or self.z;
	self.radius = radius or self.radius;
	self.speed_x = speed_x or self.speed_x;
	self.speed_y = speed_y or self.speed_y;
	self.speed_z = speed_z or self.speed_z;

	self:UpdateParams();
	return self;
end

-- whether the object will rebounce when hitting the ground. 
function DynamicObject:SetCanBounce(value)
	self.can_bounce = value;
end

-- set radius
function DynamicObject:SetRadius(radius)
	self.radius = radius;
end

-- attach to physics world. 
-- One can framemove dynamic object by themselves instead of calling attach(). 
-- E.g. Most Entity classes call framemove by themselves in entity's framemove function. 
function DynamicObject:Attach()
	PhysicsWorld.AddDynamicObject(self);
end

function DynamicObject:Destroy()
	self.is_destroyed = true;
end

-- update position from the entity to this object. 
function DynamicObject:UpdateFromEntity(entity)
	local x, y, z = entity:GetPosition();
	-- entity y is at bottom, we need to shift to center
	y = y + self.radius;
	if(self.x ~= x or self.y~=y or self.z ~= z) then
		self.x, self.y, self.z = x, y, z;
		self:UpdateParams();
	end
end

function DynamicObject:UpdateToEntity(entity)
	if(self.x~=entity.x or (self.y-self.radius)~=entity.y or self.z~=entity.z)  then
		entity:SetPosition(self.x, self.y-self.radius, self.z);
	end
end

function DynamicObject:GetVelocity()
	return self.speed_x, self.speed_y, self.speed_z;
end

-- Adds to the current velocity of the entity. 
-- @param x,y,z: velocity in x,y,z direction. 
function DynamicObject:AddVelocity(x,y,z)
    self.speed_x = self.speed_x + x;
    self.speed_y = self.speed_y + y;
    self.speed_z = self.speed_z + z;
	self.is_stopped = false;
end

-- set velocity
function DynamicObject:SetVelocity(x,y,z)
	self.speed_x = x or self.speed_x;
    self.speed_y = y or self.speed_y;
    self.speed_z = z or self.speed_z;
	if(self.speed_x ~= 0 or self.speed_y~=0 or self.speed_z~=0) then
		self.is_stopped = false;
	else
		self.is_stopped = true;
	end
end

-- whether has speed or acceleration. 
function DynamicObject:HasSpeed()
	if(self.is_stopped~=nil) then
		return not self.is_stopped;
	else
		return self.speed_x~=0 or self.speed_y~=0 or self.speed_z~=0; 
	end
end

-- whether landing on ground. 
function DynamicObject:IsOnGround()
	return self.isOnGround;
end

function DynamicObject:UpdateParams()
	local bx, by, bz = BlockEngine:block(self.x, self.y, self.z);
	self.bx, self.by, self.bz = bx, by, bz;
	
	self.cx, self.cy, self.cz = BlockEngine:real(bx, by, bz);
	
	self.offset_x = self.x - self.cx;
	self.offset_y = self.y - self.cy;
	self.offset_z = self.z - self.cz;
end

function DynamicObject:SetOnGround()
	self.isOnGround = true;
	if(not self.can_bounce) then
		self.speed_y = 0;
	end
end

-- set surface speed decay. speed lost per second when sliding on surface of other block. 
function DynamicObject:SetSurfaceDecay(surface_decay)
	self.surface_decay = surface_decay;
end

-- set air decay. speed lost per second when in air
function DynamicObject:SetAirDecay(air_decay)
	self.air_decay = air_decay;
end

function DynamicObject:SetMinSpeed(stopSpeed)
	self.min_speed = stopSpeed;
end

function DynamicObject:GetMinSpeed()
	return self.min_speed;
end

-- default to 9.81
function DynamicObject:SetGravity(value)
	self.gravity = value;
end

-- called every frame
function DynamicObject:FrameMove(deltaTime)
	if(self.is_stopped) then
		return
	end

	local half_blocksize = BlockEngine.half_blocksize;
	local radius = self.radius;
	local bx, by, bz = self.bx, self.by, self.bz;
	local is_stopped = true;

	self.isOnGround = false;

	local min_speed = self.min_speed or default_min_speed;
	local gravity = - (self.gravity or default_gravity);
	-- apply gravity in y direction. and compute new position.  
	--if(self.speed_y ~= 0 ) then
		self.speed_y = self.speed_y + gravity * deltaTime;
		self.last_y = self.y;
		local offset_y = self.offset_y + self.speed_y*deltaTime;
		if(self.speed_y < 0) then
			if( (offset_y-radius) < -half_blocksize and PhysicsWorld.IsBlocked(bx, by-1, bz)) then
				self.speed_y = -self.speed_y*default_speedlost_perbounce;
				if((math_abs(self.speed_y) < (min_speed+math_abs(gravity*deltaTime)) )) then
					self.speed_y = 0;
					offset_y = radius - half_blocksize;
					self.y = self.cy + offset_y;
				else
					is_stopped = false;
				end
				self:SetOnGround();
			else
				self.offset_y = offset_y;
				self.y = self.cy + offset_y;
				is_stopped = false;
			end
		else
			if( (offset_y+radius) > half_blocksize and PhysicsWorld.IsBlocked(bx, by+1, bz)) then
				self.speed_y = -self.speed_y*default_speedlost_perbounce;
			else
				self.offset_y = offset_y;
				self.y = self.cy + offset_y;
			end
			is_stopped = false;
		end
	
		-- is_stopped = false;
		--if(math_abs(self.last_y - self.y) < 0.0001 and (math_abs(self.speed_y) < min_speed)) then
			--self.speed_y = 0;
		--else
			--is_stopped = false;
		--end
	--end

	-- apply accelaration in x,z plane if y speed is 0. 
	local speed_decay;
	if(self.speed_y == 0) then
		speed_decay = self.surface_decay or default_surface_decay
	else
		speed_decay = self.air_decay or default_air_decay
	end
	if(self.speed_x<0) then
		self.speed_x = self.speed_x + speed_decay * deltaTime;
		if(self.speed_x>0) then
			self.speed_x = 0;
		end
	elseif(self.speed_x>0) then
		self.speed_x = self.speed_x - speed_decay * deltaTime;
		if(self.speed_x<0) then
			self.speed_x = 0;
		end
	end
	if(self.speed_z<0) then
		self.speed_z = self.speed_z + speed_decay * deltaTime;
		if(self.speed_z>0) then
			self.speed_z = 0;
		end
	elseif(self.speed_z>0) then
		self.speed_z = self.speed_z - speed_decay * deltaTime;
		if(self.speed_z<0) then
			self.speed_z = 0;
		end
	end

	-- x direction
	--if(self.speed_x ~= 0 ) then
		local offset_x = self.offset_x + self.speed_x*deltaTime;
		if(self.speed_x < 0) then
			if( (offset_x-radius) < -half_blocksize and PhysicsWorld.IsBlocked(bx-1, by, bz)) then
				self.speed_x = -self.speed_x*default_speedlost_perbounce;
			else
				self.offset_x = offset_x;
				self.x = self.cx + offset_x;
			end
		else
			if( (offset_x+radius) > half_blocksize and PhysicsWorld.IsBlocked(bx+1, by, bz)) then
				self.speed_x = -self.speed_x*default_speedlost_perbounce;
			else
				self.offset_x = offset_x;
				self.x = self.cx + offset_x;
			end
		end
		
		if(math_abs(self.speed_x) < min_speed) then
			self.speed_x = 0;
		else
			is_stopped = false;
		end
	--end

	-- z direction
	--if(self.speed_z ~= 0 ) then
		local offset_z = self.offset_z + self.speed_z*deltaTime;
		if(self.speed_z < 0) then
			if( (offset_z-radius) < -half_blocksize and PhysicsWorld.IsBlocked(bx, by, bz-1)) then
				self.speed_z = -self.speed_z*default_speedlost_perbounce;
			else
				self.offset_z = offset_z;
				self.z = self.cz + offset_z;
			end
		else
			if( (offset_z+radius) > half_blocksize and PhysicsWorld.IsBlocked(bx, by, bz+1)) then
				self.speed_z = -self.speed_z*default_speedlost_perbounce;
			else
				self.offset_z = offset_z;
				self.z = self.cz + offset_z;
			end
		end
		
		if(math_abs(self.speed_z) < min_speed) then
			self.speed_z = 0;
		else
			is_stopped = false;
		end
	--end
	if(not is_stopped) then
		if(not ((math_abs(self.offset_x) < half_blocksize and math_abs(self.offset_y) < half_blocksize and math_abs(self.offset_z) < half_blocksize))) then
			self:UpdateParams();

			if(PhysicsWorld.IsBlocked(self.bx, self.by, self.bz)) then
				self.speed_x = 0;
				self.speed_y = 0;
				self.speed_z = 0;
				self.is_stopped = true;
				self:SetOnGround();
			end	
		end
	end
	self.is_stopped = is_stopped;
end
