--[[
Title: Sky entity
Author(s): LiXizhi
Date: 2015/8/1
Desc: There is only one active sky entity in the world. 
Sky entity is now persistent.
public:
	UseSimulatedSky()
		SetMoonSize()
		SetSunSize()

	UseSkybox(filename)
		SetSkyTexture(filename)

	AddSubMesh(filename)
	Refresh()
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntitySky.lua");
local EntitySky = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntitySky");
local sky = GameLogic.GetSkyEntity();
sky:UseSimulatedSky();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/InventoryBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ContainerView.lua");
NPL.load("(gl)script/ide/math/math3d.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/WeatherEffect.lua");
local WeatherEffect = commonlib.gettable("MyCompany.Aries.Game.Effects.WeatherEffect");
local InventoryBase = commonlib.gettable("MyCompany.Aries.Game.Items.InventoryBase");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.Entity"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntitySky"));

-- this is singleton entity. 
Entity.name = "sky";
Entity.is_persistent = true;
Entity.is_regional = false;
-- class name
Entity.class_name = "EntitySky";
-- register class
EntityManager.RegisterEntityClass(Entity.class_name, Entity);

-- is simulated
Entity.IsSimulatedSky = true;
-- default sky box name, if "" it means no sky now
Entity.filename = "";
Entity.rainStrength = 0;
Entity.snowStrength = 0;
Entity.default_skyfilename = "model/blockworld/Sky/sky.x";
Entity.maxSubMeshCount = 1;

-- internal skybox by index
local skyboxes = {
	[1] = {name = "sim1", is_simulated=true, file = ""},
	[2] = {name = "skybox15", file = "model/skybox/skybox15/skybox15.x", },
	[3] = {name = "skybox6", file = "model/skybox/skybox6/skybox6.x", },
	[4] = {name = "skybox7", file = "model/skybox/skybox7/skybox7.x", },
	[5] = {name = "rain_1", file = "model/skybox/skybox16/skybox16.x", },
	[6] = {name = "rain_2", file = "model/skybox/skybox17/skybox17.x", },
	[7] = {name = "rain_3", file = "model/skybox/skybox38/skybox38.x", },
	[8] = {name = "rain_4", file = "model/skybox/skybox54/skybox54.x", },
};

function Entity:ctor()
	self:SetDummy(true);
end

function Entity:init()
	if(not Entity._super.init(self)) then
		return;
	end
	self:Refresh();
	return self;
end

function Entity:Destroy()
	WeatherEffect:Clear();
	Entity._super.Destroy(self);
end


function Entity:SaveToXMLNode(node)
	node = Entity._super.SaveToXMLNode(self, node);
	local attr = node.attr;
	attr.snowStrength = self:GetSnowStrength();
	attr.rainStrength = self:GetRainStrength();
	attr.filename = self.filename;
	attr.skyTexture = self.skyTexture;
	attr.IsSimulatedSky = self.IsSimulatedSky;
	return node;
end

function Entity:LoadFromXMLNode(node)
	Entity._super.LoadFromXMLNode(self, node);
	local attr = node.attr;
	self.snowStrength = tonumber(attr.snowStrength);
	self.rainStrength = tonumber(attr.rainStrength);
	self.filename = attr.filename;
	self.skyTexture = attr.skyTexture;
	if(attr.IsSimulatedSky) then
		self.IsSimulatedSky = attr.IsSimulatedSky == "true";
	end
end

-- set sun size in simulated sky
function Entity:SetSunSize(sun_size, sun_glow)
	local sky = self:GetSkyAttr();
	sky:SetField("SunSize", {sun_size or 500, sun_glow or 12});
end

-- set moon size in simulated sky
function Entity:SetMoonSize(moon_size, moon_glow)
	local sky = self:GetSkyAttr();
	sky:SetField("SunSize", {moon_size or 500, moon_glow or 12});
end

-- refresh the sky box according to current settings. 
function Entity:RefreshSky()
	local filename;

	local bCloudySky = self:IsSnowing() or self:IsRaining();
	if(bCloudySky) then
		-- set cloudy sky
		filename = self:GetSkyTemplate(8);
	else
		if(self.IsSimulatedSky) then
			filename = nil;
		else
			filename = self:GetSkyTemplate(self.filename) or self.filename;
		end
	end

	local sky = self:GetSkyAttr();
	if(filename) then
		sky:SetField("SimulatedSky", false);
		sky:SetField("SkyFogAngleFrom", 0);
		sky:SetField("SkyFogAngleTo", 0.2);
		sky:SetField("SkyMeshFile", filename);
		GameLogic.world_sim:OnTickDayLight(true);
	else
		sky:SetField("SimulatedSky", true);
		sky:SetField("SkyColor", {1, 1, 1});
	end
	GameLogic.world_sim:OnTickDayLight(true);
end


function Entity:UseSimulatedSky()
	self.IsSimulatedSky = true;
	self:RefreshSky();
end

-- do not show primary skybox, use submeshes only.
function Entity:UseNoneSky()
	self.IsSimulatedSky = false;
	self.filename = "";
	self:RefreshSky();
end

-- use given skybox
-- @param filename: can be number [1-8] or any parax file name. 
function Entity:UseSkybox(filename)
	self.IsSimulatedSky = false;
	self.filename = filename;
	self:RefreshSky();
end

-- set replacable texture of the sky mesh
function Entity:SetSkyTexture(filename)
	self.filename = self.default_skyfilename;
	self.skyTexture = filename;
	self.IsSimulatedSky = false;
	self:RefreshSky();
end

-- predefined template. 
-- @param skyName: value in [1-8]
-- @return nil or filename
function Entity:GetSkyTemplate(skyName)
	local nIndex = tonumber(skyName);
	local sky;
	if(nIndex) then
		sky = skyboxes[nIndex];
	else
		sky = skyboxes[skyName];
	end
	if(sky and sky.file) then
		return sky.file;
	end
end

-- remove all child meshes
function Entity:ClearSubMeshes()
	local sky = self:GetSkyAttr();
	sky:CallField("DestroyChildren");
end

-- it will replace the last added mesh if child count exceeded self.maxSubMeshCount.
-- all sub mesh model are assumed to be centered at 0,0,0 and with height +/-0.5
-- @param file: must be parax model file. (x or fbx files)
function Entity:AddSubMesh(filename)
	local sky = self:GetSkyAttr();
	local childCount = sky:GetChildCount();
	if(childCount < self.maxSubMeshCount) then
		local submesh = ParaScene.CreateObject("BMaxObject", filename, 0,0,0);
		submesh:SetField("assetfile", filename);
		sky:AddChild(submesh:GetAttributeObject());
	elseif(childCount >0) then
		local submesh = sky:GetChildAt(childCount-1);
		submesh:SetField("assetfile", filename);
		-- LOG.std(nil, "warn", "EntitySky", "can not adde more than %d meshes", self.maxSubMeshCount)
	end
end


-- this will return the sky attribute object. 
function Entity:GetSkyAttr()
	if(not self.m_sky or not self.m_sky:IsValid()) then
		self.m_sky = ParaScene.GetAttributeObjectSky();
	end
	return self.m_sky;
end

-- refresh everything.
function Entity:Refresh()
	self.m_sky = ParaScene.GetAttributeObjectSky();
	self:RefreshWeather();
	self:RefreshSky();
end

function Entity:RefreshWeather()
	WeatherEffect:SetStrength(1, self:GetRainStrength());
	WeatherEffect:SetStrength(2, self:GetSnowStrength());
end

-- called every frame
function Entity:FrameMove(deltaTime)
end

-- @param strength: [0-10], if nil, it will toggle raining. 
function Entity:SetRain(strength)
	if(not strength) then
		-- toggle rain
		strength = if_else(self.rainStrength > 0, 0, 3);
	end
	self.rainStrength = strength;
	if(self.rainStrength > 0) then
		self.snowStrength = 0;
	end
	self:Refresh();
end

function Entity:IsRaining()
	return self.rainStrength > 0;
end

function Entity:GetRainStrength()
	return self.rainStrength
end

-- @param strength: [0-10], if nil, it will toggle snowing. 
function Entity:SetSnow(strength)
	if(not strength) then
		-- toggle rain
		strength = if_else(self.snowStrength > 0, 0, 3);
	end
	self.snowStrength = strength;
	if(self.snowStrength > 0) then
		self.rainStrength = 0;
	end
	self:Refresh();
end

function Entity:IsSnowing()
	return self.snowStrength > 0;
end

function Entity:GetSnowStrength()
	return self.snowStrength;
end

function Entity:FrameMove(deltaTime)
	WeatherEffect:FrameMove(deltaTime);
end
