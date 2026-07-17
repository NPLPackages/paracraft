NPL.load("(gl)script/ide/AssetPreloader.lua");
NPL.load("(gl)script/ide/System/Scene/Assets/ParaXModelAttr.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");

local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local ParaXModelAttr = commonlib.gettable("System.Scene.Assets.ParaXModelAttr");
local MuJoCoParaXPrototype = NPL.export();
local ATTRIBUTE_FIELDTYPE = commonlib.gettable("System.Core.ATTRIBUTE_FIELDTYPE");

local ObjectName = "MuJoCoH1ParaXPrototype";
local TeleportUIName = "MuJoCoH1ParaXPrototypeUI";
local ExpectedBones = {
	{ name = "pelvis", paraxName = "Pelvis" },
	"left_hip_yaw_link",
	"right_hip_yaw_link",
	"torso_link",
	"left_shoulder_pitch_link",
};

function MuJoCoParaXPrototype.Stop()
	ParaUI.Destroy(TeleportUIName);
	if MuJoCoParaXPrototype.assetLoader then
		MuJoCoParaXPrototype.assetLoader:Stop();
		MuJoCoParaXPrototype.assetLoader = nil;
	end
	if MuJoCoParaXPrototype.object and MuJoCoParaXPrototype.object:IsValid() then
		ParaScene.Delete(MuJoCoParaXPrototype.object);
	end
	MuJoCoParaXPrototype.object = nil;
	MuJoCoParaXPrototype.asset = nil;
end

function MuJoCoParaXPrototype.TeleportToRobot()
	local object = MuJoCoParaXPrototype.object;
	local player = ParaScene.GetPlayer();
	if not object or not object:IsValid() or not player or not player:IsValid() then
		return;
	end
	local targetX, targetY, targetZ = object:GetPosition();
	player:SetPosition(targetX + 2, targetY, targetZ + 2);
	player:SetFacing(math.atan2(targetX - targetX - 2, targetZ - targetZ - 2) - math.pi / 2);
	LOG.std(nil, "info", "MuJoCoParaXPrototype", "teleported near model: target=(%.3f,%.3f,%.3f)", targetX, targetY, targetZ);
end

local function showTeleportUI()
	ParaUI.Destroy(TeleportUIName);
	local button = ParaUI.CreateUIObject("button", TeleportUIName, "_rt", -190, 155, 170, 40);
	button.text = L"前往 H1 ParaX";
	button.tooltip = L"瞬移到完整 ParaX 机器人旁边";
	button.zorder = 1000;
	button:SetScript("onclick", function()
		MuJoCoParaXPrototype.TeleportToRobot();
	end);
	button:AttachToRoot();
end

local function setBoneRotation(animInstance, boneAttr, quaternion)
	local rotationName = boneAttr:GetField("RotName", "");
	local timeName = boneAttr:GetField("TimeName", "");
	animInstance:AddDynamicField(rotationName, ATTRIBUTE_FIELDTYPE.FieldType_AnimatedQuaternion);
	animInstance:SetFieldKeyNums(rotationName, 1);
	animInstance:SetFieldKeyTime(rotationName, 0, 0);
	animInstance:SetFieldKeyValue(rotationName, 0, quaternion);
	animInstance:SetDynamicField(timeName, 0);
end

local function inspectBones(object)
	local objectAttr = object:GetAttributeObject();
	local animInstance = objectAttr and objectAttr:GetChildAt(1, 1);
	if not animInstance or not animInstance:IsValid() then
		LOG.std(nil, "error", "MuJoCoParaXPrototype", "animation instance is unavailable");
		return false;
	end

	local foundBones = {};
	local boneAttrs = {};
	local boneNames = {};
	local boneCount = animInstance:GetChildCount(1);
	for index = 0, boneCount - 1 do
		local boneAttr = animInstance:GetChildAt(index, 1);
		if boneAttr and boneAttr:IsValid() then
			local name = boneAttr:GetField("name", "");
			foundBones[name] = true;
			boneAttrs[name] = boneAttr;
			boneNames[#boneNames + 1] = name;
		end
	end

	local missingBones = {};
	for _, expected in ipairs(ExpectedBones) do
		local sourceName = type(expected) == "table" and expected.name or expected;
		local paraxName = type(expected) == "table" and expected.paraxName or expected;
		if not foundBones[paraxName] then
			missingBones[#missingBones + 1] = sourceName;
		end
	end
	if #missingBones > 0 then
		LOG.std(nil, "error", "MuJoCoParaXPrototype", "missing bones: %s actual=%s", table.concat(missingBones, ","), table.concat(boneNames, ","));
		return false;
	end

	MuJoCoParaXPrototype.animInstance = animInstance;
	MuJoCoParaXPrototype.boneAttrs = boneAttrs;
	if ParaEngine.GetAppCommandLineByParam("mujoco_parax_test_pose", "true") == "true" then
		local angle = math.rad(35);
		setBoneRotation(animInstance, boneAttrs.left_shoulder_pitch_link, { 0, math.sin(angle / 2), 0, math.cos(angle / 2) });
		animInstance:CallField("UpdateModel");
	end
	LOG.std(nil, "info", "MuJoCoParaXPrototype", "ready: bones=%d expected=%d missing=0", boneCount, #ExpectedBones);
	return true;
end

local function createCharacter()
	local oldObject = ParaScene.GetObject(ObjectName);
	if oldObject and oldObject:IsValid() then
		ParaScene.Delete(oldObject);
	end

	local object = ParaScene.CreateCharacter(ObjectName, MuJoCoParaXPrototype.asset, "", true, 0.45, 0, 1);
	if not object or not object:IsValid() then
		LOG.std(nil, "error", "MuJoCoParaXPrototype", "failed creating ParaX character");
		return;
	end

	local player = ParaScene.GetPlayer();
	local playerX, playerY, playerZ = player:GetPosition();
	local facing = player:GetFacing();
	local assetBox = MuJoCoParaXPrototype.asset:GetBoundingBox({});
	local groundOffset = assetBox.min_y and -assetBox.min_y or 1.03;
	object:SetPosition(playerX + 3 * math.cos(facing), playerY + groundOffset, playerZ - 3 * math.sin(facing));
	object:SetVisible(true);
	object:SetField("SkipRender", false);
	object:SetField("RenderDistance", 1000);
	object:CallField("UpdateGeometry");
	ParaScene.Attach(object);
	MuJoCoParaXPrototype.object = object;
	local bonesReady = inspectBones(object);
	showTeleportUI();
	local assetAttr = MuJoCoParaXPrototype.asset:GetAttributeObject();
	local modelAttr = assetAttr and assetAttr:GetChildAt(0);
	local savePath = ParaEngine.GetAppCommandLineByParam("mujoco_parax_save", "");
	if modelAttr and savePath ~= "" then
		ParaIO.CreateDirectory(savePath);
		modelAttr:SetField("SaveToDisk", savePath);
		LOG.std(nil, "info", "MuJoCoParaXPrototype", "saved native ParaX model: %s", savePath);
	end
	local renderPassCount = modelAttr and modelAttr:GetField("RenderPassesCount", 0) or 0;
	local geosetCount = modelAttr and modelAttr:GetField("GeosetsCount", 0) or 0;
	local textureCount = modelAttr and modelAttr:GetChildCount(1) or 0;
	local loadedTextureCount = 0;
	local validTextureCount = 0;
	local textureNames = {};
	for index = 0, textureCount - 1 do
		local textureAttr = modelAttr:GetChildAt(index, 1);
		if textureAttr and textureAttr:IsValid() then
			if textureAttr:GetField("IsLoaded", false) then
				loadedTextureCount = loadedTextureCount + 1;
			end
			if textureAttr:GetField("IsValid", false) then
				validTextureCount = validTextureCount + 1;
			end
			textureNames[#textureNames + 1] = textureAttr:GetField("LocalFileName", "");
		end
	end
	local viewBox = object:GetViewBox({});
	local objectX, objectY, objectZ = object:GetPosition();
	LOG.std(nil, "info", "MuJoCoParaXPrototype", "visible-check: bones=%s object=(%.3f,%.3f,%.3f) assetAABB=(%.3f,%.3f,%.3f) viewboxPos=(%.3f,%.3f,%.3f) viewboxSize=(%.3f,%.3f,%.3f)",
		tostring(bonesReady), objectX, objectY, objectZ,
		assetBox.min_x and assetBox.max_x - assetBox.min_x or 0,
		assetBox.min_y and assetBox.max_y - assetBox.min_y or 0,
		assetBox.min_z and assetBox.max_z - assetBox.min_z or 0,
		viewBox.pos_x or 0, viewBox.pos_y or 0, viewBox.pos_z or 0,
		viewBox.obb_x or 0, viewBox.obb_y or 0, viewBox.obb_z or 0);
	LOG.std(nil, "info", "MuJoCoParaXPrototype", "render-state: passes=%d geosets=%d textures=%d loaded=%d valid=%d names=%s",
		renderPassCount, geosetCount, textureCount, loadedTextureCount, validTextureCount, table.concat(textureNames, ","));
	LOG.std(nil, "info", "MuJoCoParaXPrototype", "technique-state: object=%d assetY=(%.3f,%.3f) groundOffset=%.3f",
		object:GetField("render_tech", 0),
		assetBox.min_y or 0, assetBox.max_y or 0, groundOffset);
end

function MuJoCoParaXPrototype.Start()
	MuJoCoParaXPrototype.Stop();
	local modelPath = ParaEngine.GetAppCommandLineByParam("mujoco_parax_model", "");
	if modelPath == "" then
		LOG.std(nil, "error", "MuJoCoParaXPrototype", "mujoco_parax_model is not specified");
		return;
	end
	if not ParaIO.DoesAssetFileExist(modelPath, true) then
		LOG.std(nil, "error", "MuJoCoParaXPrototype", "ParaX model does not exist: %s", modelPath);
		return;
	end

	local asset = ParaAsset.LoadParaX(modelPath, modelPath);
	MuJoCoParaXPrototype.asset = asset;
	MuJoCoParaXPrototype.assetLoader = commonlib.AssetPreloader:new({
		callbackFunc = function(itemsLeft)
			if itemsLeft == 0 then
				MuJoCoParaXPrototype.assetLoader = nil;
				if asset:IsValid() and asset:IsLoaded() then
					createCharacter();
				else
					LOG.std(nil, "error", "MuJoCoParaXPrototype", "failed loading ParaX model: %s", modelPath);
				end
			end
		end,
	});
	MuJoCoParaXPrototype.assetLoader:AddAssets(asset);
	MuJoCoParaXPrototype.assetLoader:Start();
	LOG.std(nil, "info", "MuJoCoParaXPrototype", "loading: %s", modelPath);
end

GameLogic:Connect("WorldUnloaded", MuJoCoParaXPrototype, MuJoCoParaXPrototype.Stop, "UniqueConnection");
MuJoCoParaXPrototype.Start();

return MuJoCoParaXPrototype;