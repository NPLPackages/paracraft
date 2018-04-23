--[[
Title: Star (galaxy) scene manager 
Author(s): LiXizhi
Date: 2008/8/14
Desc: switch between a galaxy scene and the current game scene without unloading the current game scene. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/worlds/StarSceneManager.lua");
Map3DSystem.App.worlds.StarSceneManager.SwitchToGalaxy()
Map3DSystem.App.worlds.StarSceneManager.SwitchToGame()
-------------------------------------------------------
]]
if(not Map3DSystem.App.worlds.StarSceneManager) then Map3DSystem.App.worlds.StarSceneManager={}; end

-- a place to hold the current game scene paramters, so when we switch back to game scene, these values are restored.
local gameScene = {
	-- whether the scene paramters in this table will be restored. 
	NeedRestore = false,
};

local galaxyScene= {
	SkyMeshFile = "model/Skybox/Skybox6/Skybox6.x",
	EnableFog = false,
	OceanEnabled = false,
};

-- show the wizard
function Map3DSystem.App.worlds.StarSceneManager.SwitchToGalaxy()
	--
	-- save current scene settings.
	--
	local att;
	local sceneAttr = {};
	sceneAttr.TimeOfDaySTD = ParaScene.GetTimeOfDaySTD();
	
	att = ParaScene.GetAttributeObjectSky();
	sceneAttr.SkyMeshFile = att:GetField("SkyMeshFile", "");
	sceneAttr.SkyFogAngleFrom = att:GetField("SkyFogAngleFrom", -0.05);
	sceneAttr.SkyFogAngleTo = att:GetField("SkyFogAngleTo", 0.6);
	sceneAttr.SkyColor = att:GetField("SkyColor", {1, 1, 1});
	
	sceneAttr.OceanEnabled = ParaScene.IsGlobalWaterEnabled();
	sceneAttr.OceanLevel = ParaScene.GetGlobalWaterLevel();
	
	att = ParaScene.GetAttributeObject();
	sceneAttr.EnableFog = att:GetField("EnableFog", true);
	sceneAttr.FogEnd = att:GetField("FogEnd", 120);
	sceneAttr.FogStart = att:GetField("FogStart", 40);
	sceneAttr.FogDensity = att:GetField("FogDensity", 0.69);
	sceneAttr.FogColor = att:GetField("FogColor", {1, 1, 1});
	sceneAttr.ShowSky = att:GetField("ShowSky", true);
	
	att = ParaCamera.GetAttributeObject();
	sceneAttr.FarPlane = att:GetField("FarPlane", 120);
	sceneAttr.NearPlane = att:GetField("NearPlane", 0.5);
	sceneAttr.FieldOfView = att:GetField("FieldOfView", 1.0472);
	sceneAttr.CameraObjectDistance = att:GetField("CameraObjectDistance", 5);
	sceneAttr.CameraLiftupAngle = att:GetField("CameraLiftupAngle", 0.4);
	sceneAttr.CameraRotY = att:GetField("CameraRotY", 0);
	
	sceneAttr.NeedRestore = not commonlib.partialcompare(sceneAttr, galaxyScene);
	if(sceneAttr.NeedRestore) then
		local player = ParaScene.GetPlayer();
		sceneAttr.playername = player.name;
		
		commonlib.partialcopy(gameScene, sceneAttr)
		
		--
		-- apply the galaxy scene settings. 
		--
		local x,y,z = player:GetPosition();
		y = y + 400;
		local dummyCam = ParaCamera.GetDummyObject();
		dummyCam:SetPosition(x,y,z)
		ParaCamera.FollowObject(dummyCam)
		--ParaCamera.ThirdPerson(0, height, facing, angle);
		ParaCamera.ThirdPerson(0, 1, 0, -0.5);
		
		ParaScene.SetGlobalWater(galaxyScene.OceanEnabled, 0);
		att = ParaScene.GetAttributeObjectSky();
		att:SetField("SkyMeshFile", galaxyScene.SkyMeshFile);
		
		att = ParaScene.GetAttributeObject();
		att:SetField("EnableFog", galaxyScene.EnableFog);
		
	end
end


function Map3DSystem.App.worlds.StarSceneManager.SwitchToGame()
	-- restore the game settings. 
	if(gameScene.NeedRestore) then
		gameScene.NeedRestore = false;
		
		-- set biped
		ParaScene.GetObject(gameScene.playername):ToCharacter():SetFocus();
		
		local att;
		ParaScene.SetTimeOfDaySTD(gameScene.TimeOfDaySTD);
		att = ParaScene.GetAttributeObjectSky();
		att:SetField("SkyMeshFile", gameScene.SkyMeshFile);
		att:SetField("SkyFogAngleFrom", gameScene.SkyFogAngleFrom);
		att:SetField("SkyFogAngleTo", gameScene.SkyFogAngleTo);
		att:SetField("SkyColor", gameScene.SkyColor);
		
		ParaScene.SetGlobalWater(gameScene.OceanEnabled, gameScene.OceanLevel);
		
		att = ParaScene.GetAttributeObject();
		att:SetField("EnableFog", gameScene.EnableFog);
		att:SetField("FogEnd", gameScene.FogEnd);
		att:SetField("FogStart", gameScene.FogStart);
		att:SetField("FogDensity", gameScene.FogDensity);
		att:SetField("FogColor", gameScene.FogColor);
		att:SetField("ShowSky", gameScene.ShowSky);
		
		att = ParaCamera.GetAttributeObject();
		att:SetField("FarPlane", gameScene.FarPlane);
		att:SetField("NearPlane", gameScene.NearPlane);
		att:SetField("FieldOfView", gameScene.FieldOfView);
		att:SetField("CameraObjectDistance", gameScene.CameraObjectDistance);
		att:SetField("CameraLiftupAngle", gameScene.CameraLiftupAngle);
		att:SetField("CameraRotY", gameScene.CameraRotY);
	end
end

