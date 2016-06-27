--[[
Title: Snow Drop Effect
Author(s): LiPeng, LiXizhi
Date: 2014/5/12
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntitySnowEffect.lua");
local EntitySnowEffect = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntitySnowEffect")
local entity = EntitySnowEffect:new({x,y,z});
EntityManager.AddObject(entity)
-------------------------------------------------------
]]
local WeatherEffect = commonlib.gettable("MyCompany.Aries.Game.Effects.WeatherEffect");
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Materials = commonlib.gettable("MyCompany.Aries.Game.Materials");
local math_abs = math.abs;

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityWeatherEffect"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntitySnowEffect"));

Entity.class_name = "EntitySnowEffect";
Entity.is_dynamic = true;
Entity.miniSceneName = "snow_effect";
Entity.assetfile = "character/CC/05effect/snow/snow.x";

local math_random = math.random;

Entity.effect_textures = {
	"Texture/blocks/snow1.png",
	"Texture/blocks/snow2.png",
	"Texture/blocks/snow3.png",
	"Texture/blocks/snow4.png",
}

function Entity:ctor()
	-- echo("111111111: "..tostring(self.entityId));
end

function Entity:init(x,y,z)
	local r = WeatherEffect:GetSpeedRand();
	self.isFloating = if_else(r:randomDouble()>0.1,true,false);
	self.float_speed = (r:randomDouble()-r:randomDouble())*0.5;
	self.gravity = 9.81*0.03;
	return Entity._super.init(self, x,y,z);
end

function Entity:SetEffectTextureByIndex(nIndex)
	if(nIndex ~= 2) then
		self.scaling = (self.scaling or 0.1)*0.7;
	else
		self.scaling = (self.scaling or 0.1)*1.2;
	end

	Entity._super.SetEffectTextureByIndex(self,nIndex);
end

-- called every frame
function Entity:FrameMove(deltaTime)
	
	if(self.isFloating) then
		self.x = self.x + self.float_speed*deltaTime;
		self.z = self.z + self.float_speed*deltaTime;
	end
	
	Entity._super.FrameMove(self, deltaTime);
end