--[[
Title: The world database functions for paraworld
Author(s): LiXizhi
Date: 2006/1/26, revised by LiXizhi 2008.6.28
Desc:

---++ public properties
<verbatim>
-- if the world is a zip file, it will be the local zip file name or it will be nil. 
Map3DSystem.world.worldzipfile; 
</verbatim>

---++ public functions
Check if a given world path exists
<verbatim>
	Map3DSystem.world:DoesWorldExist("worlds/myworld/", true)
</verbatim>

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemData/world_db.lua");
local Settings = commonlib.gettable("Map3DSystem.World.Settings");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/commonlib.lua");

local L = CommonCtrl.Locale("IDE");

-- Map3DSystem: 
if(not Map3DSystem) then Map3DSystem = {}; end

NPL.load("(gl)script/kids/3DMapSystemData/user_db.lua");

-------------------------------------------------
-- world db table
-------------------------------------------------

if(not Map3DSystem.world) then Map3DSystem.world = {}; end
local world = Map3DSystem.world;
Map3DSystem.World = world; -- alias

local Settings = commonlib.gettable("Map3DSystem.World.Settings");

-- world information
Map3DSystem.worlddir = "worlds/";
world.defaultskymesh = CommonCtrl.Locale("IDE")("asset_defaultSkyboxModel");--the snow sky box
world.worldzipfile = nil; -- if the world is a zip file, it will be the local file name
world.name = "_noname";
world.shortname = "_noname";
world.sConfigFile = "";
world.sNpcDbFile = "";
world.sAttributeDbFile = "";
world.sBaseWorldCfgFile = "_emptyworld/_emptyworld.worldconfig.txt";
world.sBaseWorldAttFile = "_emptyworld/_emptyworld.attribute.db"
world.sBaseWorldNPCFile = "_emptyworld/_emptyworld.NPC.db"
world.createtime = "2006-1-26";
world.author = "ParaEngine";
world.desc = L"create world description";
world.terrain = {type=0, basetex=0, commontex=0};
world.env_set = 0;
world.sky = 0;
world.readonly = nil;
-- the default player position if the player has never been here before.
world.defaultPos = {x=20000,y=20000};--{x=130,y=95};
world.IsOwner = false;
-- the view count of the world
world.Views = 0;
-- owner level of the visiting space
world.OwnerLevel = 0;
-- space URL
world.SpaceURL = "Unknown";


---------------------------------
-- world db functions
---------------------------------
function world:new()
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end

-- the left one is secretely replaced by right one, for upgrading purposes. 	
local CharReplaceMap = {
	["character/v3/Human/Female/HumanFemale.x"] = "character/v3/Human/Female/HumanFemale.xml",
	["character/v3/Human/Male/HumanMale.x"] = "character/v3/Human/Male/HumanMale.xml",
}
	
--[[ populate Map3DSystem.world struct from database 
if (name,password)==(_init_, paraengine), then the default world settings will be loaded from database.
we can also reserve some other world settings accounts.
]]
function world:LoadWorldFromDB(name, password)
	local att;
	-- set the default NPC db
	ParaWorld.SetAttributeProvider(self.sAttributeDbFile);
	ParaWorld.SetNpcDB(self.sNpcDbFile);
	
	-- use default sky and fog
	ParaScene.CreateSkyBox ("MySkyBox", ParaAsset.LoadStaticMesh ("", self.defaultskymesh), 160,160,160, 0);
	ParaScene.SetFog(true, "0.7 0.7 1.0", 40.0, 120.0, 0.7);
	
	-- load last player location
	local db = ParaWorld.GetAttributeProvider();
	db:SetTableName("WorldInfo");
	local x,y,z;
	x = db:GetAttribute("PlayerX", self.defaultPos.x);
	y = db:GetAttribute("PlayerY", 0);
	z = db:GetAttribute("PlayerZ", self.defaultPos.y);
	Settings.PlayerX = x;
	Settings.PlayerY = y;
	Settings.PlayerZ = z;

	-- ocean level
	local OceanEnabled = db:GetAttribute("OceanEnabled", false);
	local OceanLevel = db:GetAttribute("OceanLevel", 0);
	ParaScene.SetGlobalWater(OceanEnabled, OceanLevel);
	att = ParaScene.GetAttributeObjectOcean();
	att:SetField("OceanColor", {db:GetAttribute("OceanColor_R", 0.2), db:GetAttribute("OceanColor_G", 0.3), db:GetAttribute("OceanColor_B", 0.3)});
	att:SetField("RenderTechnique", db:GetAttribute("RenderTechnique", 3));
	
	-- load sky
	att = ParaScene.GetAttributeObjectSky();
	att:SetField("SkyMeshFile", db:GetAttribute("SkyMeshFile", self.defaultskymesh));
	att:SetField("SkyColor", {db:GetAttribute("SkyColor_R", 1), db:GetAttribute("SkyColor_G", 1), db:GetAttribute("SkyColor_B", 1)});
	att:SetField("SkyFogAngleFrom", db:GetAttribute("SkyFogAngleFrom", -0.05));
	att:SetField("SkyFogAngleTo", db:GetAttribute("SkyFogAngleTo", 0.6));
	
	-- sky simulated 
	att:SetField("SimulatedSky", db:GetAttribute("SimulatedSky", false));
	att:SetField("IsAutoDayTime", db:GetAttribute("IsAutoDayTime", true));
	att:SetField("SunGlowTexture", db:GetAttribute("SunGlowTexture", nil));
	att:SetField("CloudTexture", db:GetAttribute("CloudTexture", nil));
	
	-- sun light
	local att = ParaScene.GetAttributeObjectSunLight();
	att:SetField("DayLength", db:GetAttribute("DayLength", 10000));
	att:SetField("TimeOfDaySTD", db:GetAttribute("TimeOfDaySTD", 0.1));
	att:SetField("MaximumAngle", db:GetAttribute("MaximumAngle", 1.5));
	att:SetField("AutoSunColor", db:GetAttribute("AutoSunColor", false));
	local r,g,b = db:GetAttribute("Ambient", "0.59 0.59 0.59"):match("^(%S+)%s(%S+)%s(%S+)")
	att:SetField("Ambient", {tonumber(r), tonumber(g), tonumber(b)} );
	local r,g,b = db:GetAttribute("Diffuse", "1 1 1"):match("^(%S+)%s(%S+)%s(%S+)")
	att:SetField("Diffuse", {tonumber(r), tonumber(g), tonumber(b)} );
	att:SetField("ShadowFactor",db:GetAttribute("ShadowFactor",0.35));

	-- load fog 
	att = ParaScene.GetAttributeObject();
	att:SetField("FogEnd", db:GetAttribute("FogEnd", 120));
	att:SetField("FogStart", db:GetAttribute("FogStart", 40));
	att:SetField("FogDensity", db:GetAttribute("FogDensity", 0.69));
	att:SetField("FogColor", {db:GetAttribute("FogColor_R", 1), db:GetAttribute("FogColor_G", 1), db:GetAttribute("FogColor_B", 1)});
	
	-- load fullscreen glow effect
	att:SetField("Glowness", {db:GetAttribute("Glowness_R", 1), db:GetAttribute("Glowness_G", 1), db:GetAttribute("Glowness_B", 1),db:GetAttribute("Glowness_A", 1)})
	att:SetField("GlowIntensity", db:GetAttribute("GlowIntensity", 0.8));
	att:SetField("GlowFactor", db:GetAttribute("GlowFactor", 1));
	--att:SetField("FullScreenGlow", db:GetAttribute("FullScreenGlow", false));
	
	-- load camera settings
	att = ParaCamera.GetAttributeObject();
	att:SetField("FarPlane", db:GetAttribute("CameraFarPlane", 120));
	att:SetField("NearPlane", db:GetAttribute("CameraNearPlane", 0.5));
	att:SetField("FieldOfView", db:GetAttribute("FieldOfView", 1.0472));
	
	-- editor attributes
	local attributes = {};
	local function save_attr(name, value)
		attributes[name] = value;
	end
	self.attributes = attributes;
	att = ParaEngine.GetAttributeObject();
	save_attr("Effect Level", db:GetAttribute("Effect Level", att:GetField("Effect Level", 0)));
	local size = att:GetField("ScreenResolution", {1024,768});
	save_attr("ScreenResolution.width", db:GetAttribute("ScreenResolution.width", size[1]));
	save_attr("ScreenResolution.height", db:GetAttribute("ScreenResolution.height", size[2]));
	save_attr("TextureLOD", db:GetAttribute("TextureLOD", att:GetField("TextureLOD", 0)));
	att = ParaScene.GetAttributeObjectOcean();
	save_attr("EnableTerrainReflection", db:GetAttribute("EnableTerrainReflection", att:GetField("EnableTerrainReflection", false)))
	save_attr("EnableMeshReflection", db:GetAttribute("EnableMeshReflection", att:GetField("EnableMeshReflection", false)))
	save_attr("EnablePlayerReflection", db:GetAttribute("EnablePlayerReflection", att:GetField("EnablePlayerReflection", false)))
	save_attr("EnableCharacterReflection", db:GetAttribute("EnableCharacterReflection", att:GetField("EnableCharacterReflection", false)))
	att = ParaScene.GetAttributeObject();
	save_attr("SetShadow", db:GetAttribute("SetShadow", att:GetField("SetShadow", false)))
	save_attr("FullScreenGlow", db:GetAttribute("FullScreenGlow", att:GetField("FullScreenGlow", false)))

	-- create the default player
	local PlayerAsset = db:GetAttribute("PlayerAsset", L"asset_defaultPlayerModel");
		
	if(CharReplaceMap[PlayerAsset]) then
		commonlib.log("warning: player asset %s is replaced by %s. save the scene again to avoid this warning\n", PlayerAsset, CharReplaceMap[PlayerAsset]);
		PlayerAsset = CharReplaceMap[PlayerAsset];
	end
	if(System.options and System.options.ignorePlayerAsset) then
		PlayerAsset = "";
	end
	local asset = ParaAsset.LoadParaX("", PlayerAsset);
	
	local player;
	local playerChar;
	Map3DSystem.player.name = tostring(Map3DSystem.User.nid or Map3DSystem.User.Name);
	player = ParaScene.CreateCharacter (Map3DSystem.player.name, asset, "", true, 0.35, db:GetAttribute("PlayerFacing", 3.9), 1.0);
	player:SetPosition(x, y, z);
	--player:SnapToTerrainSurface(0);
	player:GetAttributeObject():SetField("SentientField", 65535);--senses everybody including its own kind.
	
	--------------------------------------------------------
	--player:GetAttributeObject():SetField("GroupID", 1);
	--player:GetAttributeObject():SetField("AlwaysSentient", true);
	--player:GetAttributeObject():SetField("Sentient", true);
	--------------------------------------------------------
	
	-- set movable region: it will apply to all characters in this concise version.
	-- player:SetMovableRegion(16000,0,16000, 16000,16000,16000);
	ParaScene.Attach(player);
	playerChar = player:ToCharacter();
	playerChar:SetFocus();
	ParaCamera.ThirdPerson(0, db:GetAttribute("CameraObjectDistance", 5), db:GetAttribute("CameraLiftupAngle", 0.4), db:GetAttribute("CameraRotY", 0));
	
	-- apply avatar CCS info string
	local ccsinfo = db:GetAttribute("AvatarCCSInfo", "");
	if(not commonlib.getfield("MyCompany.Aries")) then
		-- skip the ccs information because the ccs info string is different to the original ccs info string
		Map3DSystem.UI.CCS.ApplyCCSInfoString(ParaScene.GetPlayer(), ccsinfo);
	end
	
	-- always reset history when world is reloaded. 
	Map3DSystem.obj.ResetHistory()
	Map3DSystem.Env.ResetHistory()
end

-- attributes with self.attributes will be applied.
function world:ApplyEditorAttributes()
	if(not self.attributes) then
		return
	end
	local attributes = self.attributes;

	local att = ParaEngine.GetAttributeObject();
	if(attributes["Effect Level"]~=nil) then
		att:SetField("Effect Level", attributes["Effect Level"]);
	end
	if(attributes["ScreenResolution.width"]~=nil) then
		att:SetField("ScreenResolution", {attributes["ScreenResolution.width"], attributes["ScreenResolution.height"]});
	end
	if(attributes["TextureLOD"]~=nil) then
		att:SetField("TextureLOD", attributes["TextureLOD"]);
	end
	att = ParaScene.GetAttributeObjectOcean();
	if(attributes["EnableTerrainReflection"]~=nil) then
		att:SetField("EnableTerrainReflection", attributes["EnableTerrainReflection"]);
	end
	if(attributes["EnableMeshReflection"]~=nil) then
		att:SetField("EnableMeshReflection", attributes["EnableMeshReflection"]);
	end
	if(attributes["EnablePlayerReflection"]~=nil) then
		att:SetField("EnablePlayerReflection", attributes["EnablePlayerReflection"]);
	end
	if(attributes["EnableCharacterReflection"]~=nil) then
		att:SetField("EnableCharacterReflection", attributes["EnableCharacterReflection"]);
	end
	att = ParaScene.GetAttributeObject();
	if(attributes["SetShadow"]~=nil) then
		att:SetField("SetShadow", attributes["SetShadow"]);
	end
	if(attributes["FullScreenGlow"]~=nil) then
		att:SetField("FullScreenGlow", attributes["FullScreenGlow"]);
	end
end

-- save world info to db 
function world:SaveWorldToDB(name, password)
	local att, color;
	
	ParaWorld.SetAttributeProvider(self.sAttributeDbFile);
	ParaWorld.SetNpcDB(self.sNpcDbFile);
	
	-- save last player location
	local db = ParaWorld.GetAttributeProvider();
	db:ExecSQL("BEGIN")
	db:SetTableName("WorldInfo");
	local x,y,z = ParaScene.GetPlayer():GetPosition();
	db:UpdateAttribute("PlayerAsset", ParaScene.GetPlayer():GetPrimaryAsset():GetKeyName());
	db:UpdateAttribute("PlayerX", x);
	db:UpdateAttribute("PlayerY", y);
	db:UpdateAttribute("PlayerZ", z);
	db:UpdateAttribute("PlayerFacing", ParaScene.GetPlayer():GetFacing());
	if(Map3DSystem.UI and Map3DSystem.UI.CCS and Map3DSystem.UI.CCS.GetCCSInfoString) then
		local ccsinfo = Map3DSystem.UI.CCS.GetCCSInfoString(ParaScene.GetPlayer());
		db:UpdateAttribute("AvatarCCSInfo", ccsinfo);
	end
	
	--save ocean level.
	db:UpdateAttribute("OceanEnabled", ParaScene.IsGlobalWaterEnabled());
	db:UpdateAttribute("OceanLevel", ParaScene.GetGlobalWaterLevel());
	att = ParaScene.GetAttributeObjectOcean();
	color = att:GetField("OceanColor", {1, 1, 1});
	db:UpdateAttribute("OceanColor_R", color[1]);
	db:UpdateAttribute("OceanColor_G", color[2]);
	db:UpdateAttribute("OceanColor_B", color[3]);
	db:UpdateAttribute("RenderTechnique", att:GetField("RenderTechnique", 3));
	
	-- save sky
	att = ParaScene.GetAttributeObjectSky();
	local str = att:GetField("SkyMeshFile", self.defaultskymesh);
	db:UpdateAttribute("SkyMeshFile", str);
	color = att:GetField("SkyColor", {1, 1, 1});
	db:UpdateAttribute("SkyColor_R", color[1]);
	db:UpdateAttribute("SkyColor_G", color[2]);
	db:UpdateAttribute("SkyColor_B", color[3]);
	db:UpdateAttribute("SkyFogAngleFrom", att:GetField("SkyFogAngleFrom", -0.05));
	db:UpdateAttribute("SkyFogAngleTo", att:GetField("SkyFogAngleTo", 0.6));
	
	-- sky simulated
	db:UpdateAttribute("SimulatedSky", att:GetField("SimulatedSky", false));
	db:UpdateAttribute("IsAutoDayTime", att:GetField("IsAutoDayTime", true));
	db:UpdateAttribute("SunGlowTexture", att:GetField("SunGlowTexture", ""));
	db:UpdateAttribute("CloudTexture", att:GetField("CloudTexture", ""));
	
	-- sun light
	local att = ParaScene.GetAttributeObjectSunLight();
	db:UpdateAttribute("DayLength", att:GetField("DayLength", 10000));
	db:UpdateAttribute("TimeOfDaySTD", att:GetField("TimeOfDaySTD", 0.4));
	db:UpdateAttribute("MaximumAngle", att:GetField("MaximumAngle", 1.5));
	db:UpdateAttribute("AutoSunColor", att:GetField("AutoSunColor", false));
	local color = att:GetField("Ambient", {0.3, 0.3, 0.3});
	db:UpdateAttribute("Ambient", string.format("%f %f %f", color[1], color[2], color[3]));
	local color = att:GetField("Diffuse", {1, 1, 1});
	db:UpdateAttribute("Diffuse", string.format("%f %f %f", color[1], color[2], color[3]));
	db:UpdateAttribute("ShadowFactor",att:GetField("ShadowFactor",0.35));

	-- save fog 
	att = ParaScene.GetAttributeObject();
	db:UpdateAttribute("FogEnd", att:GetField("FogEnd", 120));
	db:UpdateAttribute("FogStart", att:GetField("FogStart", 40));
	db:UpdateAttribute("FogDensity", att:GetField("FogDensity", 0.69));
	color = att:GetField("FogColor", {1, 1, 1});
	db:UpdateAttribute("FogColor_R", color[1]);
	db:UpdateAttribute("FogColor_G", color[2]);
	db:UpdateAttribute("FogColor_B", color[3]);
	
	-- save fullscreen glow effect
	db:UpdateAttribute("GlowIntensity", att:GetField("GlowIntensity", 0.8));
	db:UpdateAttribute("GlowFactor", att:GetField("GlowFactor", 1));
	color = att:GetField("Glowness", {1,1,1,1});
	db:UpdateAttribute("Glowness_R", color[1]);
	db:UpdateAttribute("Glowness_G", color[2]);
	db:UpdateAttribute("Glowness_B", color[3]);
	db:UpdateAttribute("Glowness_A", color[4]);
	--db:UpdateAttribute("FullScreenGlow", att:GetField("FullScreenGlow", false));
	
	-- save camera settings
	att = ParaCamera.GetAttributeObject();
	db:UpdateAttribute("CameraFarPlane", att:GetField("FarPlane", 120));
	db:UpdateAttribute("CameraNearPlane", att:GetField("NearPlane", 0.5));
	db:UpdateAttribute("FieldOfView", att:GetField("FieldOfView", 1.0472));
	
	db:UpdateAttribute("CameraObjectDistance", att:GetField("CameraObjectDistance", 5));
	db:UpdateAttribute("CameraLiftupAngle", att:GetField("CameraLiftupAngle", 0.4));
	db:UpdateAttribute("CameraRotY", att:GetField("CameraRotY", 0));
	
	-- Editor only attribute
	att = ParaEngine.GetAttributeObject();
	db:UpdateAttribute("Effect Level", att:GetField("Effect Level", 0));
	local size = att:GetField("ScreenResolution", {1024,768});
	db:UpdateAttribute("ScreenResolution.width", size[1]);
	db:UpdateAttribute("ScreenResolution.height", size[2]);
	db:UpdateAttribute("TextureLOD", att:GetField("TextureLOD", 0));
	att = ParaScene.GetAttributeObjectOcean();
	db:UpdateAttribute("EnableTerrainReflection", att:GetField("EnableTerrainReflection", false))
	db:UpdateAttribute("EnableMeshReflection", att:GetField("EnableMeshReflection", false))
	db:UpdateAttribute("EnablePlayerReflection", att:GetField("EnablePlayerReflection", false))
	db:UpdateAttribute("EnableCharacterReflection", att:GetField("EnableCharacterReflection", false))
	att = ParaScene.GetAttributeObject();
	db:UpdateAttribute("SetShadow", att:GetField("SetShadow", false))
	db:UpdateAttribute("FullScreenGlow", att:GetField("FullScreenGlow", false))

	db:ExecSQL("END")
end


--[[set the world name from which a new world is derived
@param name: a world name or nil or "". if "_emptyworld", a new world will be created if not exists.
@return : true if succeeded, nil if not.]]
function world:SetBaseWorldName(name)
	if(name == nil or name == "") then
		self.sBaseWorldCfgFile = "";
		self.sBaseWorldAttFile = nil;
		self.sBaseWorldNPCFile = nil;
		if(not ParaIO.DoesAssetFileExist("_emptyworld/flat.raw", true)) then	
			ParaWorld.NewEmptyWorld("_emptyworld", 533.3333, 64);
		end
		return true;
	elseif(name == "_emptyworld") then
		-- if the empty world does not exist, the empty world will be created and used as the base world
		self.sBaseWorldCfgFile = ParaWorld.NewEmptyWorld("_emptyworld", 533.3333, 64);
		log(self.sBaseWorldCfgFile.."\n does not exist. _emptyworld is created and used as the base world to create the new world;\n");
	end

	local sWorldConfigName = self:GetDefaultWorldConfigName(name);
	local sWorldAttName = self:GetDefaultAttributeDatabaseName(name);
	local sWorldNPCFile = self:GetDefaultNPCDatabaseName(name);
	
	if(ParaIO.DoesAssetFileExist(sWorldAttName, true)) then	
		self.sBaseWorldAttFile = sWorldAttName;
	else	
		self.sBaseWorldAttFile = nil;
	end
	
	if(ParaIO.DoesAssetFileExist(sWorldNPCFile, true)) then	
		self.sBaseWorldNPCFile = sWorldNPCFile;
	else	
		self.sBaseWorldNPCFile = nil;
	end
	
	if(ParaIO.DoesAssetFileExist(sWorldConfigName, true) == true) then	
		self.sBaseWorldCfgFile = sWorldConfigName;
		return true;
	end
end

function world:SetDefaultFileMapping(name)
	if(not name)then
		name = self.name;
	end
	self.sConfigFile = self:GetDefaultWorldConfigName(name);
	self.sNpcDbFile = self:GetDefaultNPCDatabaseName(name);
	self.sAttributeDbFile = self:GetDefaultAttributeDatabaseName(name);
end

-- use default world config name, npc db and attribute db.
function world:UseDefaultFileMapping()
	self:UseDefaultWorldConfigName();
	self:UseDefaultNPCDatabase();
	self:UseDefaultAttributeDatabase();
end

-- update world config file name from the world name
function world:UseDefaultWorldConfigName()
	if(self.name == "") then
		self.sConfigFile = "";
	else
		local name = self.name;
		self.sConfigFile = self:GetDefaultWorldConfigName(self.name, true);
	end
end

-- update npc database file name from the world name
function world:UseDefaultNPCDatabase()
	if(self.name == "") then
		self.sNpcDbFile = "";
	else
		self.sNpcDbFile = self:GetDefaultNPCDatabaseName(self.name);
	end
end
-- update attribute database file name from the world name
function world:UseDefaultAttributeDatabase()
	if(self.name == "") then
		self.sAttributeDbFile = "";
	else
		self.sAttributeDbFile = self:GetDefaultAttributeDatabaseName(self.name)
	end
end

---------------------------------
-- static public functions
---------------------------------
-- @param worldpath: such as worlds/worldname or worlds/worldname/ 
-- @param bSearchZipFile:true to search in zip files. 
-- return true if worldpath is a world directory. 
function world:DoesWorldExist(worldpath, bSearchZipFile)
	if(worldpath) then
		worldpath = string.gsub(worldpath, "[/\\]+$", "")
		local sWorldConfigName = self:GetDefaultWorldConfigName(worldpath, bSearchZipFile);
		if(ParaIO.DoesAssetFileExist(sWorldConfigName, bSearchZipFile)) then
			return true;
		end
	end	
end

-- if [world_dir]/[filename] does not exist, we will try [world_dir]/[worldname].[filename]. 
-- @param filename: such as "worldconfig.txt", "NPC.db"
function world:TryGetWorldFilePath(world_dir, filename, bSearchZipFile)
	if(bSearchZipFile == nil) then
		bSearchZipFile = true;
	end
	local sFileName = world_dir.."/"..filename;
	if(ParaIO.DoesAssetFileExist(sFileName, bSearchZipFile)) then
		return sFileName;
	else
		local sOldFileName = world_dir.."/"..ParaIO.GetFileName(world_dir).."."..filename;	
		if(ParaIO.DoesAssetFileExist(sOldFileName, bSearchZipFile)) then
			return sOldFileName;
		else
			return sFileName;
		end
	end
end

--@param name: world directory name. such as "world/demo"
function world:GetDefaultWorldConfigName(name, bSearchZipFile)
	return self:TryGetWorldFilePath(name, "worldconfig.txt", bSearchZipFile);
end

--@param name: world directory name. such as "world/demo"
function world:GetDefaultNPCDatabaseName(name, bSearchZipFile)
	return self:TryGetWorldFilePath(name, "NPC.db", bSearchZipFile);
end

--@param name: world directory name. such as "world/demo"
function world:GetDefaultAttributeDatabaseName(name, bSearchZipFile)
	return self:TryGetWorldFilePath(name, "attribute.db", bSearchZipFile);
end