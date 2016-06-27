--[[
Title: Rain Drop Effect
Author(s): LiXizhi, LiPeng
Date: 2014/5/12
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityRainEffect.lua");
local EntityRainEffect = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityRainEffect")
local entity = EntityRainEffect:new({x,y,z});
EntityManager.AddObject(entity)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityWeatherEffect.lua");
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local WeatherEffect = commonlib.gettable("MyCompany.Aries.Game.Effects.WeatherEffect");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Materials = commonlib.gettable("MyCompany.Aries.Game.Materials");
local math_abs = math.abs;

--local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.Entity"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityRainEffect"));
local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityWeatherEffect"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityRainEffect"));

Entity.class_name = "EntityRainEffect";
Entity.is_dynamic = true;
Entity.radius = 0.2;
Entity.scaling = 0.2;
Entity.is_dummy = true;
Entity.miniSceneName = "rain_effect";
Entity.assetfile = "character/CC/05effect/Rain/Rain.x";
Entity.splash_assetfile = "character/CC/05effect/Rain/Rain_efx.x"
Entity.effect_textures = {
	"Texture/blocks/Rain1.png",
	"Texture/blocks/Rain2.png",
	"Texture/blocks/Rain3.png",
	"Texture/blocks/Rain4.png",
}

-- @param x,y,z: initial real world position. 
-- @param Entity: the half radius of the object. 
function Entity:ctor()
end

function Entity:SplashEffect(y)
	if(self.splashingtime) then
		return;
	end
	self.splashingtime = 0;
	self.scaling= 1;
	local scene = WeatherEffect:GetMiniSceneGraph(self.miniSceneName);
	self:DestroyInnerObject();

	local obj = ObjEditor.CreateObjectByParams({
		name = self.obj_name,
		IsCharacter = true,
		AssetFile = self.splash_assetfile,
		x = self.x,
		y = self.y,
		z = self.z,
		facing = 1.57,
		scaling = self.scaling,
	});
	if(obj) then
		--obj:SetField("billboarded", true);
		--obj:SetField("ShadowCaster", false);
		scene:AddChild(obj);
	end
	self.obj = obj;
end

function Entity:SetFallOnGround()
	self:SplashEffect();
end

function Entity:init(x,y,z)
	self.splashingtime = nil;
	self.scaling = 0.2;
	return Entity._super.init(self, x,y,z);
end

-- called every frame
function Entity:FrameMove(deltaTime)
	if(self.splashingtime) then
		self.splashingtime = self.splashingtime + deltaTime;
		if(self.splashingtime < 0.2) then
			-- only play the splash animation for 0.2 second. 
			return;
		else
			self:SetDead();
		end
	else
		Entity._super.FrameMove(self, deltaTime);
	end
end
