--[[
Title: Weather Particle Drop Effect
Author(s): LiXizhi, LiPeng
Date: 2014/5/12
Desc: always create from pool
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityWeatherEffect.lua");
local EntityWeatherEffect = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityWeatherEffect")
local entity = EntityWeatherEffect:CreateFromPool(x,y,z);
EntityManager.AddObject(entity)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityPool.lua");
local EntityPool = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityPool");
local WeatherEffect = commonlib.gettable("MyCompany.Aries.Game.Effects.WeatherEffect");
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Materials = commonlib.gettable("MyCompany.Aries.Game.Materials");
local math_abs = math.abs;

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.Entity"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityWeatherEffect"));

Entity.is_dynamic = true;
Entity.class_name = "EntityWeatherEffect";
Entity.lifetime = 2;
Entity.radius = 0.2;
Entity.is_dummy = true;
Entity.miniSceneName = "rain_effect";
Entity.assetfile = "character/CC/05effect/Snow/snow.x";
local max_pool_size = 5000;

-- static function: one also needs to overwrite the :Destroy function such that destroyed objects are recollected
function Entity:CreateFromPool()
	local pool_manager = EntityPool:CreateGet(self, max_pool_size);
	return pool_manager:CreateEntity();
end

-- @param x,y,z: initial real world position. 
-- @param Entity: the half radius of the object. 
function Entity:ctor()
	self.obj_name = tostring(self.entityId);
	-- life time is between 2-10 seconds. 
	--self.lifetime = 2 / (WeatherEffect:GetSpeedRand()*0.08 + 0.02);
	self.scaling= self.scaling or 0.1; -- Maybe random?
	self.gravity = self.gravity or 9.81;
end

function Entity:GetParticlePool(miniSceneName, assetfile)
	local poolname = miniSceneName..assetfile;
end

local params = {
	ReplaceableTextures = {};
}

function Entity:init(x,y,z)
	if(not Entity._super.init(self)) then
		return
	end
	self.speed_x = self.speed_x or 0;
	-- between [1, 2]
	self.speed_y = self.speed_y or -(WeatherEffect:GetSpeedRand():randomDouble()*2 + 0.3); 
	self.speed_z = self.speed_z or 0;

	self.x = x or self.x;
	self.y = y or self.y;
	self.z = z or self.z;
	self:SetEffectTextureByIndex(WeatherEffect:GetSpeedRand():random(1,4));
	
	params.name = self.obj_name;
	params.IsCharacter = true;
	params.AssetFile = self.assetfile;
	params.ReplaceableTextures[2] = self.texture; -- can be nil
	params.x = self.x;
	params.y = self.y;
	params.z = self.z;
	params.facing = 1.57;
	params.scaling = self.scaling;

	local obj = ObjEditor.CreateObjectByParams(params);
	if(obj) then
		obj:SetField("billboarded", true);
		obj:SetField("ShadowCaster", false);
		local scene = WeatherEffect:GetMiniSceneGraph(self.miniSceneName);
		scene:AddChild(obj);
	end
	self.obj = obj;
	return self;
end

function Entity:Reset()
	self.speed_x = nil;
	self.speed_y = nil; 
	self.speed_z = nil;
	self.scaling = nil;
	Entity._super.Reset(self);
end

function Entity:SetEffectTextureByIndex(nIndex)
	nIndex = (nIndex % 4) + 1;
	self.texture = self.effect_textures[nIndex];
end

function Entity:DestroyInnerObject()
	local scene = WeatherEffect:GetMiniSceneGraph(self.miniSceneName);
	if(self.obj) then
		scene:DestroyObject(self.obj);
		-- this is slow
		-- scene:DestroyObject(self.obj_name);
		self.obj = nil;
	end
end

function Entity:Destroy()
	self:DestroyInnerObject();
	Entity._super.Destroy(self);
end

function Entity:SetFallOnGround()
	self:SetDead();
end

-- called every frame
function Entity:FrameMove(deltaTime)
	self.speed_y = self.speed_y  - self.gravity * deltaTime;
	self.y = self.y + self.speed_y * deltaTime;
	if(self.obj) then
		self.obj:SetPosition(self.x, self.y, self.z);
		local bx, by, bz = BlockEngine:block(self.x, self.y, self.z);
		local block_class = BlockEngine:GetBlock(bx, by, bz)
		if(block_class and (block_class.solid or block_class.liquid or block_class.obstruction)) then
			local surface_height = BlockEngine:realY(by) + BlockEngine.blocksize;
			if (self.y < surface_height) then
				self:SetFallOnGround();
			end
		end
	end

	if(self.lifetime) then
		self.lifetime = self.lifetime - deltaTime;
		if(self.lifetime < 0) then
			self:SetDead();
		end
	end
end