--[[
Title: Weather Effect Manager
Author(s): LiPeng, LiXizhi
Date: 2014/5/12
Desc: rain, snow, ...
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/WeatherEffect.lua");
local WeatherEffect = commonlib.gettable("MyCompany.Aries.Game.Effects.WeatherEffect");
WeatherEffect:SetStrength(1, GetRainStrength());
WeatherEffect:SetStrength(2, GetSnowStrength());
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/FastRandom.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Ticks.lua");
local Ticks = commonlib.gettable("MyCompany.Aries.Game.Common.Ticks");
local FastRandom = commonlib.gettable("MyCompany.Aries.Game.Common.CustomGenerator.FastRandom");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local WeatherEffect = commonlib.gettable("MyCompany.Aries.Game.Effects.WeatherEffect");

-- whether to use c++ implementation of weather effect. 
WeatherEffect.use_cpp_impl = true;

WeatherEffect.weather_info = {
	{type = "rain",opening = false,strength = 3, spawnRadius = 20, textureRowsCols={1,4}, texture="Texture/blocks/particle_rain.png"},
	{type = "snow",opening = false,strength = 3, spawnRadius = 20, textureRowsCols={2,2}, texture="Texture/blocks/particle_snow.png"},
	{type = "rain_splash",opening = false,strength = 3, spawnRadius = 20, textureRowsCols={2,2}, texture="Texture/blocks/particle_rain_splash.png"},
}

-- public: set rain, snow strength
-- @param indexOrType: 1 for rain, 2 for snow. 
-- @param strength_value: [0-10]  0 is disable.
function WeatherEffect:SetStrength(indexOrType,strength_value)
	local item = self:GetWeatherItem(indexOrType)
	item.opening = (strength_value and strength_value > 0);
	item.strength = strength_value;
	self:RefreshItem(item);
end

-- private: get the C++ effect object. 
function WeatherEffect:CreateGetWeatherEffect()
	local att = ParaScene.GetAttributeObject("WeatherEffect");
	if(not att:IsValid()) then
		LOG.std(nil, "info", "WeatherEffect", "CWeatherEffect created and added to scene");
		local root_scene = ParaScene.GetObject("<root>");
		local weatherEffect = ParaScene.CreateObject("CWeatherEffect", "WeatherEffect",0,0,0);
		root_scene:AddChild(weatherEffect);
		return weatherEffect:GetAttributeObject();
	else
		return att;
	end
end

-- private: refresh rain or snow parameters.
function WeatherEffect:RefreshItem(item)
	if(self.use_cpp_impl) then
		local att = self:CreateGetWeatherEffect();
		if(item.type == "snow") then
			att = att:GetChild("snow");
		elseif(item.type == "rain") then
			att = att:GetChild("rain");
		end
		att:SetField("Enable", item.opening);
		att:SetField("Strength", item.strength);
		att:SetField("Texture", item.texture);
		att:SetField("TextureRowsCols", item.textureRowsCols);
		att:SetField("SpawnRadius", item.spawnRadius);
	end
end

------------------------------------
-- 
-- ALL CODE BELOW are DEPRECATED!
-- 
------------------------------------
local EntityRainEffect, EntitySnowEffect;
if(not WeatherEffect.use_cpp_impl) then
	-- deprecated
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityRainEffect.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntitySnowEffect.lua");
	EntityRainEffect = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityRainEffect")
	EntitySnowEffect = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntitySnowEffect")
end

WeatherEffect.miniscenes = {};

local default_strength = 4;

local spawnRand, speedRand;

-- blocks height. should be the top most block. 
local sky_height = 255;

local math_random = math.random;

local spawn_tick_fps = 20;

function WeatherEffect:ctor()
end

--function WeatherEffect:Init()
	--self.weather_info = {
	--{type = "rain",opening = false,strength = 3, spawnRadius = 20},
	--{type = "snow",opening = false,strength = 3, spawnRadius = 20},
--}
--end

function WeatherEffect:IsRainOrSnow()
	for i = 1,#WeatherEffect.weather_info do
		local item = WeatherEffect.weather_info[i];
		if(item.opening) then
			return true;
		end
	end
	return false;
end

-- get rain strength
function WeatherEffect:GetRainStrength()
	local item = self:GetWeatherItem("rain");
	if(item and item.opening) then
		return item.strength;
	else
		return 0;
	end
end

-- @param _indexOrType: number or "rain", "snow", etc. 
function WeatherEffect:GetWeatherItem(_indexOrType)
	local indexOrType = _indexOrType or "rain";
	local weather_item;
	if(indexOrType) then
		for i = 1,#WeatherEffect.weather_info do
			local item = WeatherEffect.weather_info[i];
			if(indexOrType == i or indexOrType == item.type) then
				weather_item = item;
				break;
			end
		end
	end
	return weather_item;
end


-- DEPRECATED:
-- @param indexOrType: 1 for rain , 2 for snow. nil to close both
function WeatherEffect:SetStatus(indexOrType,beOpen)
	
	indexOrType = indexOrType or "rain";
	for i = 1,#WeatherEffect.weather_info do
		local item = WeatherEffect.weather_info[i];
		if(indexOrType == i or indexOrType == item.type) then
			item.opening = beOpen;
			--self.cur_weather = if_else(item.opening,item.type,nil);
		else
			item.opening = false;
		end
		self:RefreshItem(item);
	end
end

-- get cached mini scene graph
function WeatherEffect:GetMiniSceneGraph(name)
	local scene = self.miniscenes[name];
	if(not scene) then
		scene = ParaScene.GetMiniSceneGraph(name);
		self.miniscenes[name] = scene;
	end
	return scene;
end

-- called when world exit
function WeatherEffect:Clear()
	self.miniscenes = {};

	for i = 1,#WeatherEffect.weather_info do
		local item = WeatherEffect.weather_info[i];
		item.opening = false;
	end
end

-- set current effect item. 
function WeatherEffect:ChangeStatus(indexOrType)
	local opening = self:GetStatus(indexOrType);
	local beOpen = not opening;
	self:SetStatus(indexOrType,beOpen);
	--indexOrType = indexOrType or "rain";
	--for i = 1,#WeatherEffect.weather_info do
		--local item = WeatherEffect.weather_info[i];
--
		--if(indexOrType == i or indexOrType == item.type) then
			--item.opening = not item.opening;
			----self.cur_weather = if_else(item.opening,item.type,nil);
		--else
			--item.opening = false;
		--end
	--end
end

function WeatherEffect:GetStatus(_indexOrType)
	local indexOrType = _indexOrType or "rain";
	local item = self:GetWeatherItem(indexOrType)
	return item.opening;
end

function WeatherEffect:AddParticle(x,y,z,weatherType)
	local entity;
	local type = weatherType or "rain";
	if(type == "rain") then
		entity = EntityRainEffect:CreateFromPool():init(x,y,z);	
	elseif(type == "snow") then
		entity = EntitySnowEffect:CreateFromPool():init(x,y,z);	
	end
	if(entity) then
		EntityManager.AddObject(entity);
	end
end

-- whether this is a tick
function WeatherEffect:IsTick(deltaTime)
	if(not self.ticks) then
		self.ticks = Ticks:new():Init(20);
	end
	return self.ticks:IsTick(deltaTime)
end

-- DEPRECATED: 
-- add Weather particles call this every frame move. 
function WeatherEffect:FrameMove(deltaTime) 
	if(not self.use_cpp_impl) then
		if(not self:IsTick(deltaTime)) then
			return;
		end
		if(self:IsRainOrSnow()) then
			self:SpawnAllParticles(spawn_tick_fps);
		end
	end
end

-- strength decides the density of rain or snow. 
function WeatherEffect:GetStrength(indexOrType)
	local item = self:GetWeatherItem(indexOrType or "rain")
	return item.strength or default_strength;
end

-- get the highest solid block information in coordinate x,z
function WeatherEffect:GetTerrainHighestBlock(x,z)
	local y = sky_height;
	local dist = ParaTerrain.FindFirstBlock(x,y,z,5,y,13); -- 13 for filtering obstruction, or solid or liquid block. 
	if(dist) then
		y = y - dist;
		local block_id = BlockEngine:GetBlockId(x,y,z);
		return block_id, y;
	end
	return nil;
end

function WeatherEffect:GetSpawnRand()
	if(not spawnRand) then
		spawnRand = FastRandom:new({_seed = 1234});
	end
	return spawnRand;
end

function WeatherEffect:GetSpeedRand()
	if(not speedRand) then
		speedRand = FastRandom:new({_seed = 1234});
	end
	return speedRand;
end

local eye_pos = {0,0,0};

-- DEPRECATED: 
-- spawn particles for the given weather item
-- @param weather_item: can be snow or rain item info. 
function WeatherEffect:SpawnParticlesForItem(weather_item, strength, spawn_tick_fps)
	commonlib.npl_profiler.perf_begin("WeatherEffect:SpawnParticlesForItem");
	local r = self:GetSpawnRand();

	local spawnRadius = weather_item.spawnRadius;
	local soundOffsetX = 0;
	local soundOffsetY = 0;
	local soundOffsetZ = 0;
	local count = 0;
	local HowManyDropsPerTick = math.ceil(math.min(300, 3 * strength * strength));
		
	local eye_pos = ParaCamera.GetAttributeObject():GetField("Eye position", eye_pos);

	local camera_x = eye_pos[1];
	local camera_y = eye_pos[2];
	local camera_z = eye_pos[3];		

	for rainTimes = 0, HowManyDropsPerTick do
		local particle_pos_x = camera_x + (r:randomDouble()-r:randomDouble())*spawnRadius;
		local particle_pos_y = camera_y + (r:randomDouble()-r:randomDouble())*spawnRadius;
		local particle_pos_z = camera_z + (r:randomDouble()-r:randomDouble())*spawnRadius;

		local particle_pos_bx,particle_pos_by,particle_pos_bz = BlockEngine:block(particle_pos_x,particle_pos_y,particle_pos_z);

		local terrainBlockID,terrainHeight = self:GetTerrainHighestBlock(particle_pos_bx,particle_pos_bz);
		if(terrainBlockID and terrainBlockID > 0 and terrainHeight >= particle_pos_by) then
			-- TODO: add effect which the rain hit the ground block
		else
			self:AddParticle(particle_pos_x,particle_pos_y,particle_pos_z,weather_item.type)
		end
	end
	commonlib.npl_profiler.perf_end("WeatherEffect:SpawnParticlesForItem");
end

-- DEPRECATED: 
function WeatherEffect:SpawnAllParticles(spawn_tick_fps)
	for i = 1,#self.weather_info do
		local weather_item = self.weather_info[i];
		if(weather_item.opening) then
			local strength = self:GetStrength(i);
			if (strength ~= 0) then
				self:SpawnParticlesForItem(weather_item, strength, spawn_tick_fps);
			end		
		end
	end
end

function WeatherEffect:SetCurWeather(weather_info)
	local cur_weather_info = WeatherEffect.weather_info or self.weather_info;
	for i = 1,#weather_info do
		local item = weather_info[i];
		local cur_item = cur_weather_info[i]
		if(item and cur_item) then
			self:SetStatus(i,item.opening)

			--cur_item.opening = item.opening;
		end
	end
end