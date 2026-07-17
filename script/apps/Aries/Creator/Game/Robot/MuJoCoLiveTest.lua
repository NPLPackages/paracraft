NPL.load("(gl)script/ide/timer.lua");
NPL.load("(gl)script/ide/AssetPreloader.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");

local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local MuJoCoLiveTest = NPL.export();
local MuJoCoH1VisualConfig = NPL.load("(gl)script/apps/Aries/Creator/Game/Robot/MuJoCoH1VisualConfig.lua");

local FixedStepSeconds = 0.002;
local TimerPeriodMs = 16;
local MaxCatchUpSteps = 50;
local BodyConfigs = MuJoCoH1VisualConfig.Bodies;
local TeleportUIName = "MuJoCoLiveTestTeleportUI";

local function getProxyName(bodyName)
	return "MuJoCoBodyProxy_" .. bodyName;
end

local function getDirectory(path)
	return path:match("^(.*[/\\])") or "";
end

function MuJoCoLiveTest.Stop()
	ParaUI.Destroy(TeleportUIName);
	if MuJoCoLiveTest.timer then
		MuJoCoLiveTest.timer:Change();
		MuJoCoLiveTest.timer = nil;
	end
	if MuJoCoLiveTest.assetLoader then
		MuJoCoLiveTest.assetLoader:Stop();
		MuJoCoLiveTest.assetLoader = nil;
	end
	for _, body in ipairs(MuJoCoLiveTest.bodies or {}) do
		if body.proxy and body.proxy:IsValid() then
			ParaScene.Delete(body.proxy);
		end
	end
	MuJoCoLiveTest.bodies = nil;
	if MuJoCoLiveTest.handle then
		ParaMuJoCo.DeleteModel(MuJoCoLiveTest.handle);
		MuJoCoLiveTest.handle = nil;
	end
end

function MuJoCoLiveTest.TeleportToRobot()
	local pelvis = MuJoCoLiveTest.bodies and MuJoCoLiveTest.bodies[1] and MuJoCoLiveTest.bodies[1].proxy;
	local player = ParaScene.GetPlayer();
	if not pelvis or not pelvis:IsValid() or not player or not player:IsValid() then
		return;
	end
	if not MuJoCoLiveTest.returnPosition then
		local returnX, returnY, returnZ = player:GetPosition();
		MuJoCoLiveTest.returnPosition = { returnX, returnY, returnZ };
		MuJoCoLiveTest.returnFacing = player:GetFacing();
	end
	local targetX, _, targetZ = pelvis:GetPosition();
	local _, playerY = player:GetPosition();
	local offsetX = 1.5;
	local offsetZ = 1.5;
	local destinationX = targetX + offsetX;
	local destinationZ = targetZ + offsetZ;
	player:SetPosition(destinationX, playerY, destinationZ);
	player:SetFacing(math.atan2(targetX - destinationX, targetZ - destinationZ) - math.pi / 2);
	LOG.std(nil, "info", "MuJoCoLiveTest", "teleported player near H1_2: target=(%.3f,%.3f)", targetX, targetZ);
end

function MuJoCoLiveTest.ReturnPlayer()
	local player = ParaScene.GetPlayer();
	if player and player:IsValid() and MuJoCoLiveTest.returnPosition then
		player:SetPosition(MuJoCoLiveTest.returnPosition[1], MuJoCoLiveTest.returnPosition[2], MuJoCoLiveTest.returnPosition[3]);
		player:SetFacing(MuJoCoLiveTest.returnFacing or 0);
		player:ToCharacter():SetFocus();
		MuJoCoLiveTest.returnPosition = nil;
		MuJoCoLiveTest.returnFacing = nil;
	end
end

local function showTeleportUI()
	ParaUI.Destroy(TeleportUIName);
	local container = ParaUI.CreateUIObject("container", TeleportUIName, "_rt", -190, 115, 170, 92);
	container.background = "Texture/whitedot.png;0 0 0 0";
	container.zorder = 1000;
	container:AttachToRoot();

	local goButton = ParaUI.CreateUIObject("button", "GoToH1", "_lt", 0, 0, 170, 40);
	goButton.text = L"前往 H1_2";
	goButton.tooltip = L"瞬移到 MuJoCo 机器人旁边";
	goButton:SetScript("onclick", function()
		MuJoCoLiveTest.TeleportToRobot();
	end);
	container:AddChild(goButton);

	local returnButton = ParaUI.CreateUIObject("button", "ReturnFromH1", "_lt", 0, 48, 170, 40);
	returnButton.text = L"返回原位";
	returnButton.tooltip = L"返回瞬移前的位置";
	returnButton:SetScript("onclick", function()
		MuJoCoLiveTest.ReturnPlayer();
	end);
	container:AddChild(returnButton);
end

local function createProxy(config)
	local proxyName = getProxyName(config.name);
	local oldProxy = ParaScene.GetObject(proxyName);
	if oldProxy and oldProxy:IsValid() then
		ParaScene.Delete(oldProxy);
	end
	local visualPath = MuJoCoLiveTest.modelDirectory .. "visual/" .. config.mesh .. ".fbx";
	local proxy;
	local asset = MuJoCoLiveTest.visualAssets[config.mesh];
	local isVisual = asset and asset:IsValid() and asset:IsLoaded();
	if isVisual then
		local box = asset:GetBoundingBox({});
		local sizeX = box.min_x and box.max_x - box.min_x or 1;
		local sizeY = box.min_y and box.max_y - box.min_y or 1;
		local sizeZ = box.min_z and box.max_z - box.min_z or 1;
		proxy = ParaScene.CreateMeshPhysicsObject(proxyName, asset, sizeX, sizeY, sizeZ, false, "1,0,0,0,1,0,0,0,1,0,0,0");
	else
		local fallbackAsset = ParaAsset.LoadStaticMesh("", "model/common/editor/z.x");
		proxy = ParaScene.CreateMeshPhysicsObject(proxyName, fallbackAsset, config.scale, config.scale, config.scale, false, "1,0,0,0,1,0,0,0,1,0,0,0");
	end
	if proxy and proxy:IsValid() then
		proxy:SetScale(isVisual and 1 or config.scale);
		proxy:SetHeadOnText(isVisual and "" or "MuJoCo " .. config.label, 0);
		proxy:SetVisible(true);
		proxy:SetField("SkipRender", false);
		proxy:SetField("FaceCullingDisabled", true);
		proxy:SetField("RenderDistance", 1000);
		return proxy, isVisual;
	end
end

local function updateProxies()
	local handle = MuJoCoLiveTest.handle;
	if not handle then
		return;
	end
	for _, body in ipairs(MuJoCoLiveTest.bodies) do
		local proxy = body.proxy;
		if proxy and proxy:IsValid() then
			local bodyId = body.id;
			local positionX = MuJoCoLiveTest.originX + ParaMuJoCo.GetBodyParaPosition(handle, bodyId, 0);
			local positionY = MuJoCoLiveTest.originY + ParaMuJoCo.GetBodyParaPosition(handle, bodyId, 1);
			local positionZ = MuJoCoLiveTest.originZ + ParaMuJoCo.GetBodyParaPosition(handle, bodyId, 2);
			proxy:SetPosition(positionX, positionY, positionZ);
			proxy:SetRotation({
				x = ParaMuJoCo.GetBodyParaQuaternion(handle, bodyId, 0),
				y = ParaMuJoCo.GetBodyParaQuaternion(handle, bodyId, 1),
				z = ParaMuJoCo.GetBodyParaQuaternion(handle, bodyId, 2),
				w = ParaMuJoCo.GetBodyParaQuaternion(handle, bodyId, 3),
			});
		end
	end
end

local function onTimer(timer)
	local elapsedSeconds = math.min(timer:GetDelta(100), 100) / 1000;
	MuJoCoLiveTest.accumulator = MuJoCoLiveTest.accumulator + elapsedSeconds;
	local stepCount = math.min(math.floor(MuJoCoLiveTest.accumulator / FixedStepSeconds), MaxCatchUpSteps);
	if stepCount > 0 then
		ParaMuJoCo.Step(MuJoCoLiveTest.handle, stepCount);
		MuJoCoLiveTest.accumulator = MuJoCoLiveTest.accumulator - stepCount * FixedStepSeconds;
		updateProxies();
	end
	if not MuJoCoLiveTest.hasLogged and ParaMuJoCo.GetTime(MuJoCoLiveTest.handle) >= 1 then
		MuJoCoLiveTest.hasLogged = true;
		local validProxyCount = 0;
		local visualCount = 0;
		for _, body in ipairs(MuJoCoLiveTest.bodies) do
			if body.proxy and body.proxy:IsValid() then
				validProxyCount = validProxyCount + 1;
				if body.isVisual then
					visualCount = visualCount + 1;
				end
			end
		end
		local pelvis = MuJoCoLiveTest.bodies[1].proxy;
		local pelvisX, pelvisY, pelvisZ = pelvis:GetPosition();
		local pelvisRotation = pelvis:GetRotation({});
		LOG.std(nil, "info", "MuJoCoLiveTest", "running: handle=%d time=%.3f proxies=%d visuals=%d fallbacks=%d pelvis=(%.3f,%.3f,%.3f) quat=(%.3f,%.3f,%.3f,%.3f)",
			MuJoCoLiveTest.handle,
			ParaMuJoCo.GetTime(MuJoCoLiveTest.handle),
			validProxyCount,
			visualCount,
			validProxyCount - visualCount,
			pelvisX, pelvisY, pelvisZ,
			pelvisRotation.x, pelvisRotation.y, pelvisRotation.z, pelvisRotation.w);
	end
end

local function logVisualState()
	local validProxyCount = 0;
	local visualCount = 0;
	for _, body in ipairs(MuJoCoLiveTest.bodies) do
		if body.proxy and body.proxy:IsValid() then
			validProxyCount = validProxyCount + 1;
			if body.isVisual then
				visualCount = visualCount + 1;
			end
		end
	end
	local pelvis = MuJoCoLiveTest.bodies[1].proxy;
	local pelvisX, pelvisY, pelvisZ = pelvis:GetPosition();
	local pelvisRotation = pelvis:GetRotation({});
	local pelvisAsset = MuJoCoLiveTest.visualAssets.pelvis;
	local box = pelvisAsset and pelvisAsset:GetBoundingBox({}) or {};
	LOG.std(nil, "info", "MuJoCoLiveTest", "visible: handle=%d simulate=%s proxies=%d visuals=%d fallbacks=%d pelvis=(%.3f,%.3f,%.3f) quat=(%.3f,%.3f,%.3f,%.3f) aabb=(%.3f,%.3f,%.3f)",
		MuJoCoLiveTest.handle,
		tostring(MuJoCoLiveTest.simulate),
		validProxyCount,
		visualCount,
		validProxyCount - visualCount,
		pelvisX, pelvisY, pelvisZ,
		pelvisRotation.x, pelvisRotation.y, pelvisRotation.z, pelvisRotation.w,
		box.min_x and box.max_x - box.min_x or 0,
		box.min_y and box.max_y - box.min_y or 0,
		box.min_z and box.max_z - box.min_z or 0);
end

local function createVisualObjects()
	for _, body in ipairs(MuJoCoLiveTest.bodies) do
		body.proxy, body.isVisual = createProxy(body.config);
		if not body.proxy then
			MuJoCoLiveTest.Stop();
			LOG.std(nil, "error", "MuJoCoLiveTest", "failed creating body proxy: %s", body.config.name);
			return;
		end
		local bodyId = body.id;
		body.proxy:SetPosition(
			MuJoCoLiveTest.originX + ParaMuJoCo.GetBodyParaPosition(MuJoCoLiveTest.handle, bodyId, 0),
			MuJoCoLiveTest.originY + ParaMuJoCo.GetBodyParaPosition(MuJoCoLiveTest.handle, bodyId, 1),
			MuJoCoLiveTest.originZ + ParaMuJoCo.GetBodyParaPosition(MuJoCoLiveTest.handle, bodyId, 2));
		body.proxy:SetRotation({
			x = ParaMuJoCo.GetBodyParaQuaternion(MuJoCoLiveTest.handle, bodyId, 0),
			y = ParaMuJoCo.GetBodyParaQuaternion(MuJoCoLiveTest.handle, bodyId, 1),
			z = ParaMuJoCo.GetBodyParaQuaternion(MuJoCoLiveTest.handle, bodyId, 2),
			w = ParaMuJoCo.GetBodyParaQuaternion(MuJoCoLiveTest.handle, bodyId, 3),
		});
		ParaScene.Attach(body.proxy);
	end
	ParaMuJoCo.Forward(MuJoCoLiveTest.handle);
	updateProxies();
	showTeleportUI();
	logVisualState();
	if MuJoCoLiveTest.simulate then
		MuJoCoLiveTest.timer = commonlib.Timer:new({ callbackFunc = onTimer });
		MuJoCoLiveTest.timer:Change(0, TimerPeriodMs);
	end
	LOG.std(nil, "info", "MuJoCoLiveTest", "started: handle=%d proxies=%d simulate=%s", MuJoCoLiveTest.handle, #MuJoCoLiveTest.bodies, tostring(MuJoCoLiveTest.simulate));
end

local function preloadVisualAssets()
	MuJoCoLiveTest.visualAssets = {};
	MuJoCoLiveTest.assetLoader = commonlib.AssetPreloader:new({
		callbackFunc = function(itemsLeft)
			if itemsLeft == 0 then
				MuJoCoLiveTest.assetLoader = nil;
				createVisualObjects();
			end
		end,
	});
	for _, config in ipairs(BodyConfigs) do
		if not MuJoCoLiveTest.visualAssets[config.mesh] then
			local visualPath = MuJoCoLiveTest.modelDirectory .. "visual/" .. config.mesh .. ".fbx";
			if ParaIO.DoesAssetFileExist(visualPath, true) then
				local asset = ParaAsset.LoadStaticMesh(visualPath, visualPath);
				MuJoCoLiveTest.visualAssets[config.mesh] = asset;
				MuJoCoLiveTest.assetLoader:AddAssets(asset);
			end
		end
	end
	MuJoCoLiveTest.assetLoader:Start();
end

function MuJoCoLiveTest.Start()
	MuJoCoLiveTest.Stop();
	local modelPath = ParaEngine.GetAppCommandLineByParam("mujoco_model", "");
	local handle = ParaMuJoCo.LoadModel(modelPath);
	if handle == 0 then
		LOG.std(nil, "error", "MuJoCoLiveTest", "failed loading model: %s", ParaMuJoCo.GetLastError(0));
		return;
	end
	local bodies = {};
	for _, config in ipairs(BodyConfigs) do
		local bodyId = ParaMuJoCo.FindBody(handle, config.name);
		if bodyId < 0 then
			ParaMuJoCo.DeleteModel(handle);
			LOG.std(nil, "error", "MuJoCoLiveTest", "model has no body: %s", config.name);
			return;
		end
		bodies[#bodies + 1] = { id = bodyId, config = config };
	end

	local player = ParaScene.GetPlayer();
	local originX, originY, originZ = player:GetPosition();
	local distance = tonumber(ParaEngine.GetAppCommandLineByParam("mujoco_visual_distance", "3")) or 3;
	local facing = player:GetFacing();
	MuJoCoLiveTest.handle = handle;
	MuJoCoLiveTest.bodies = bodies;
	MuJoCoLiveTest.modelDirectory = getDirectory(modelPath);
	MuJoCoLiveTest.originX = originX + distance * math.cos(facing);
	MuJoCoLiveTest.originY = originY;
	MuJoCoLiveTest.originZ = originZ - distance * math.sin(facing);
	MuJoCoLiveTest.accumulator = 0;
	MuJoCoLiveTest.hasLogged = false;
	MuJoCoLiveTest.simulate = ParaEngine.GetAppCommandLineByParam("mujoco_live_simulate", "false") == "true";
	preloadVisualAssets();
end

GameLogic:Connect("WorldUnloaded", MuJoCoLiveTest, MuJoCoLiveTest.Stop, "UniqueConnection");
MuJoCoLiveTest.Start();

return MuJoCoLiveTest;