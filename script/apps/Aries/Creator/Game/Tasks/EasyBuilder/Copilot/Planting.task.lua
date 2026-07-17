--[[
Title: Planting Task
Author(s): Copilot
Date: 2025/12/17
Desc: A task that waits for the player to plant something.

use the lib:
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/Planting.task.lua");
local Planting = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.Planting");
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotTaskBase.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotGUIGuide.lua")
local CopilotGUIGuide = commonlib.gettable("MyCompany.Aries.Game.Tasks.Copilot.CopilotGUIGuide")
local CopilotTaskBase = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.CopilotTaskBase")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
NPL.load("(gl)script/ide/System/Util/Iterators.lua")
local Iterators = commonlib.gettable("System.Util.Iterators")
local InventoryManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/InventoryManager.lua")

local Planting =
	commonlib.inherit(CopilotTaskBase, commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.Planting"))

Planting.name = "Planting"

local function FindPlantInfoSafe(plantEntity)
	local Plant = commonlib.gettable("paracraft.offical.maisi.Plant")
	if not Plant then
		return
	end

	if Plant.FindPlantInfo then
		local id, idx, info = Plant.FindPlantInfo(plantEntity)
		if info then
			return id, idx, info
		end
	end

	-- Fallback: try manual search if FindPlantInfo returns nil (e.g. id="0")
	local list
	if Plant.LoadPlantsData then
		list = Plant.LoadPlantsData()
	end

	if not list then
		local PersonalPageStore = commonlib.gettable("MyCompany.Aries.Creator.Game.KeepWork.PersonalPageStore")
		if PersonalPageStore and PersonalPageStore.personalPageData then
			local pageData = PersonalPageStore.personalPageData["maisi_plant_system"]
			if pageData then
				if pageData.plant and pageData.plant.plants then
					list = pageData.plant.plants
				elseif PersonalPageStore.LoadPageData then
					-- Trigger load if not present
					PersonalPageStore:LoadPageData("maisi_plant_system", "plant.plants", function() end)
				end
			end
		end
	end

	if list then
		local plantName = plantEntity:GetTagField("plantName")
		if plantName then
			for i, v in pairs(list) do
				if type(v) == "table" then
					local name = v.name or v[1]
					if tostring(name) == tostring(plantName) then
						local id = v.id or v[2] or "0"
						return tostring(id), i, v
					end
				end
			end
		end
	end
end

function Planting:ctor()
	Planting._super.ctor(self)
	self.guide_prop_btn = "minigame_user_item"
end

function Planting:Init(copilot, params)
	Planting._super.Init(self, copilot, params)
	if params then
		self.guide_prop_btn = params.guide_prop_btn or self.guide_prop_btn
	end
	return self
end

function Planting:GetTaskName()
	return "Planting"
end

function Planting:OnPauseByUser()
	self.inGuide = false
	CopilotGUIGuide.GuideDragEntity({})
	CopilotGUIGuide.GuideClickButton({})
	CopilotGUIGuide.GuideClickEntity({})
end

function Planting:OnRemove()
	CopilotGUIGuide.GuideDragEntity({})
	CopilotGUIGuide.GuideClickButton({})
	CopilotGUIGuide.GuideClickEntity({})
	Planting._super.OnRemove(self)
end

function Planting:CheckCompletedTask(plant_id)
	if self.receivedData and self.receivedData.id ~= nil then
		if plant_id == nil then
			return true
		else
			return plant_id == self.receivedData.id
		end
	end
	return false
end

function Planting:AutoWater(copilot, use, target)
	copilot:Say(L("让我先找找看是什么作物需要浇水！"))
	-- Find Water Can
	local waterCanEntity = nil
	local allEntities = GameLogic.EntityManager.GetAllEntities()

	if use then
		for _, ent in pairs(allEntities) do
			if ent:GetTagField("realName") == use or ent:GetTagField("name") == use then
				waterCanEntity = ent
				break
			end
		end
	end

	if not waterCanEntity then
		for _, ent in pairs(allEntities) do
			if ent:GetTagField("wateringCan") then
				waterCanEntity = ent
				break
			end
		end
	end

	if not waterCanEntity then
        waterCanEntity = self:GuideToPrepareWaterCan(copilot)
	end

	if not waterCanEntity then
		copilot:Say(L("我找不到水壶，请先准备好水壶。"))
		return
	end

	-- Find Plants
	local waterPlants = {}
	local cx, cy, cz = copilot:GetEntity():GetPosition()
	local Plant = commonlib.gettable("paracraft.offical.maisi.Plant")
    
    local target_real_name
	if Plant and Plant.GetPlantInfoFromConfig and target then
		target_real_name = Plant.GetPlantInfoFromConfig(target)
	else
		target_real_name = target
	end

	local playerX, playerY, playerZ = copilot:GetEntity():GetBlockPos()
	for dx, dz in Iterators.SpiralCircle(50) do
		local blockX = playerX + dx
		local blockZ = playerZ + dz
		local entitiesInBlock = GameLogic.EntityManager.GetEntitiesInBlock(blockX, playerY, blockZ)
		if entitiesInBlock then
			for ent, _ in pairs(entitiesInBlock) do
				if ent:isa(GameLogic.EntityManager.EntityLiveModel) then
					local plantDataIndex = ent:GetTagField("plantDataIndex")
					local actionname = ent:GetTagField("actionname")
                    local realName = ent:GetTagField("realName")
                    local matchTarget = true
                    if target_real_name and target_real_name ~= "" then
                        matchTarget = (realName and string.find(realName, target_real_name, 1, true))
                    end

					if plantDataIndex and actionname ~= "收获" and matchTarget then
						table.insert(waterPlants, ent)
					end
				end
			end
		end
	end

	if #waterPlants == 0 then
        if target and target ~= "" then
		    copilot:Say(string.format(L("附近没有需要浇水的 %s。"), target))
        else
            copilot:Say(L("附近没有需要浇水的作物。"))
        end
		return
	end

	copilot:Say(string.format(L("发现了 %d 个需要浇水的作物，开始浇水！"), #waterPlants))

	-- Sort by distance
	table.sort(waterPlants, function(a, b)
		local ax, ay, az = a:GetPosition()
		local bx, by, bz = b:GetPosition()
		return ((ax - cx) ^ 2 + (az - cz) ^ 2) < ((bx - cx) ^ 2 + (bz - cz) ^ 2)
	end)

	for i, plantEntity in ipairs(waterPlants) do
		if plantEntity:IsValid() then
			local pbx, pby, pbz = plantEntity:GetBlockPos()
			local destX, destY, destZ = copilot:GetFreeBlockPos(pbx, pby, pbz, true, true)
			if destX then
				copilot:WalkTo(destX, destY, destZ)
			else
				copilot:WalkTo(pbx - 1, pby, pbz - 1)
			end

			copilot:GetEntity():FaceTarget(pbx, pby, pbz)
			copilot:Wait(0.5)

			local old_x, old_y, old_z = waterCanEntity:GetPosition()
			local px, py, pz = plantEntity:GetPosition()
			local target_x, target_y, target_z = px, py + 0.5, pz

			local start_x, start_y, start_z = old_x, old_y, old_z
			local dist_sq = (px - old_x) ^ 2 + (pz - old_z) ^ 2
			if dist_sq > 10 then
				local camerayaw = GameLogic.RunCommand("/camerayaw")
				local camerayaw_opposite = camerayaw + math.pi
				local camerayaw_opposite_left = camerayaw_opposite + math.pi * 0.5
				local radius = 2 + math.random() * 2
				start_x = px + radius * math.cos(camerayaw_opposite_left)
				start_y = py
				start_z = pz - radius * math.sin(camerayaw_opposite_left)
				waterCanEntity:SetPosition(start_x, start_y, start_z)
			end

			local speed = 2
			local step_delay = 0.05
			local dist = math.sqrt((target_x - start_x) ^ 2 + (target_y - start_y) ^ 2 + (target_z - start_z) ^ 2)
			local steps = math.floor(dist / (speed * step_delay))

			for k = 1, steps do
				local alpha = k / steps
				local cur_x = start_x + (target_x - start_x) * alpha
				local cur_y = start_y + (target_y - start_y) * alpha
				local cur_z = start_z + (target_z - start_z) * alpha
				waterCanEntity:SetPosition(cur_x, cur_y, cur_z)
				copilot:Wait(step_delay)
			end

			waterCanEntity.isDragging = true
			waterCanEntity:BroadcastEvents(
				"watering_begindrag",
				{ x = target_x, y = target_y, z = target_z, name = waterCanEntity.name }
			)

			if plantEntity.OnHover then
				plantEntity:OnHover(waterCanEntity)
			end

			copilot:Wait(2)
			waterCanEntity.isDragging = false
			waterCanEntity:SetPosition(old_x, old_y, old_z)
		end
	end

	copilot:Say(L("浇水完成！"))
end

function Planting:AutoHarvest(copilot, target)
    copilot:Say(L("让我看看有哪些作物成熟了..."))
    local maturePlants = {}
    local allEntities = GameLogic.EntityManager.GetAllEntities()
	local Plant = commonlib.gettable("paracraft.offical.maisi.Plant")
	local target_real_name, plant_id
	if Plant and Plant.GetPlantInfoFromConfig then
		target_real_name, plant_id = Plant.GetPlantInfoFromConfig(target)
	else
		target_real_name = target
	end

    local playerX, playerY, playerZ = copilot:GetEntity():GetBlockPos()
    for dx, dz in Iterators.SpiralCircle(50) do
        local blockX = playerX + dx
        local blockZ = playerZ + dz
        local entitiesInBlock = GameLogic.EntityManager.GetEntitiesInBlock(blockX, playerY, blockZ)
        if entitiesInBlock then
            for ent, _ in pairs(entitiesInBlock) do
                if ent:isa(GameLogic.EntityManager.EntityLiveModel) then
                    local plantDataIndex = ent:GetTagField("plantDataIndex")
                    local actionname = ent:GetTagField("actionname")
                    local realName = ent:GetTagField("realName")
                    local matchTarget = true
                    if target_real_name and target_real_name ~= "" then
                        matchTarget = (realName and string.find(realName, target_real_name, 1, true)) 
                    end

                    if plantDataIndex and actionname == "收获" and matchTarget then
                        table.insert(maturePlants, ent)
                    end
                end
            end
        end
    end

    if #maturePlants == 0 then
        if target and target ~= "" then
            copilot:Say(string.format(L("附近没有成熟的 %s。"), target))
        else
            copilot:Say(L("附近没有成熟的作物。"))
        end
        return
    end

    copilot:Say(string.format(L("发现了 %d 个成熟作物，开始收获！"), #maturePlants))

	local cx, cy, cz = copilot:GetEntity():GetPosition()
	table.sort(maturePlants, function(a, b)
		local ax, ay, az = a:GetPosition()
		local bx, by, bz = b:GetPosition()
		return ((ax - cx) ^ 2 + (az - cz) ^ 2) < ((bx - cx) ^ 2 + (bz - cz) ^ 2)
	end)

	for i, plant in ipairs(maturePlants) do
		if plant:IsValid() then
			local pbx, pby, pbz = plant:GetBlockPos()
			local destX, destY, destZ = copilot:GetFreeBlockPos(pbx, pby, pbz, true, true)
			if destX then
				copilot:WalkTo(destX, destY, destZ)
			else
				copilot:WalkTo(pbx - 1, pby, pbz - 1)
			end

			copilot:GetEntity():FaceTarget(pbx, pby, pbz)
			copilot:Wait(0.5)

			plant:BroadcastEvents("onClickPlantToHarvest", { name = plant.name })

			copilot:GetEntity():SetAnimation(4)
			copilot:Wait(1)
		end
	end

	copilot:Say(L("收获完成！"))
end

function Planting:FindPlantingSpot(copilot, range)
	local Plant = commonlib.gettable("paracraft.offical.maisi.Plant")
	local soilBlocks = { [13] = true, [55] = true, [279] = true }
	if Plant and Plant.soilBlocks then
		soilBlocks = Plant.soilBlocks
	end

	local playerX, playerY, playerZ = copilot:GetEntity():GetBlockPos()
	for dx, dz in Iterators.SpiralCircle(range or 50) do
		local bx = playerX + dx
		local bz = playerZ + dz
		-- check current block and block below
		local blockId1 = GameLogic.BlockEngine:GetBlockId(bx, playerY, bz)
		local blockId2 = GameLogic.BlockEngine:GetBlockId(bx, playerY - 1, bz)

		local isSoil = false
		local targetY = playerY

		if soilBlocks[blockId1] then
			isSoil = true
			targetY = playerY
		elseif soilBlocks[blockId2] then
			isSoil = true
			targetY = playerY - 1
		end

		if isSoil then
			-- Check if occupied
			local occupied = false
			local entities = GameLogic.EntityManager.GetEntitiesInBlock(bx, targetY + 1, bz)
			if entities then
				for ent, _ in pairs(entities) do
					if ent:isa(GameLogic.EntityManager.EntityLiveModel) then
						occupied = true
						break
					end
				end
			end

			if not occupied then
				return bx, targetY + 1, bz
			end
		end
	end
	return nil
end

function Planting:AutoPlant(copilot, plant_name, target_pos)
	if not plant_name then
		copilot:Say(L("请告诉我你要种什么？"))
		return
	end

	local Plant = commonlib.gettable("paracraft.offical.maisi.Plant")
	local real_name, plant_id
	if Plant and Plant.GetPlantInfoFromConfig then
		real_name, plant_id = Plant.GetPlantInfoFromConfig(plant_name)
	else
		real_name = plant_name
	end

	copilot:Say(string.format(L("准备种植 %s..."), plant_name))

	-- 1. Find Target Position
	local bx, by, bz
	if target_pos then
		bx, by, bz = target_pos.x, target_pos.y, target_pos.z
	else
		bx, by, bz = self:FindPlantingSpot(copilot, 50)
	end

	if not bx then
		copilot:Say(L("附近找不到可以种植的空地。"))
		return
	end

	-- Move to target position
	local destX, destY, destZ = copilot:GetFreeBlockPos(bx, by, bz, true, true)
	if destX then
		copilot:WalkTo(destX, destY, destZ)
	else
		copilot:WalkTo(bx - 1, by, bz - 1)
	end
	copilot:GetEntity():FaceTarget(bx, by, bz)
	copilot:Wait(0.5)

	-- 2. Prepare Seed (Scene -> Inventory -> Shop)
	local seedEntity = nil

	-- Check Scene
	local allEntities = GameLogic.EntityManager.GetAllEntities()
	for _, ent in pairs(allEntities) do
		if ent:isa(GameLogic.EntityManager.EntityLiveModel) then
			local realName = ent:GetTagField("realName")
			local plantDataIndex = ent:GetTagField("plantDataIndex")
			-- Find seed bag that is not planted (no data index)
			if realName == real_name and (not plantDataIndex or plantDataIndex == "") then
				seedEntity = ent
				break
			end
		end
	end
	if not seedEntity then
		-- Check Inventory
		local has_seed = self:LoadUserItems(copilot, real_name)
		if not has_seed then
			-- Buy from Shop
			if not self:GuideToBuyItem(copilot, plant_id, real_name, L("请点击购买种子")) then
				copilot:Say(L("购买种子失败。"))
				return
			end
		end
		-- Use from Inventory
		if not self:GuideToUseItem(copilot, real_name, L("请点击种子袋")) then
			copilot:Say(L("取出种子失败。"))
			return
		end

		-- Find entity again after using item
		allEntities = GameLogic.EntityManager.GetAllEntities()
		for _, ent in pairs(allEntities) do
			if ent:isa(GameLogic.EntityManager.EntityLiveModel) then
				local realName = ent:GetTagField("realName")
				local plantDataIndex = ent:GetTagField("plantDataIndex")
				if realName == real_name and (not plantDataIndex or plantDataIndex == "") then
					seedEntity = ent
					break
				end
			end
		end
	end

	if not seedEntity then
		copilot:Say(L("找不到种子袋。"))
		return
	end

	-- 3. Drag to Plant
	local tx, ty, tz = GameLogic.BlockEngine:real_bottom(bx, by + 1, bz)

	-- Teleport seed entity to copilot first if it's far away
	local cx, cy, cz = copilot:GetEntity():GetPosition()
	if seedEntity:GetDistanceSq(cx, cy, cz) > 25 then
		seedEntity:SetPosition(cx + 3, cy, cz + 3)
	end

	local old_x, old_y, old_z = seedEntity:GetPosition()
	local start_x, start_y, start_z = old_x, old_y, old_z
	local target_x, target_y, target_z = tx, ty, tz

	-- Animation
	local speed = 2
	local step_delay = 0.05
	local dist = math.sqrt((target_x - start_x) ^ 2 + (target_y - start_y) ^ 2 + (target_z - start_z) ^ 2)
	local steps = math.floor(dist / (speed * step_delay))

	if steps > 0 then
		for k = 1, steps do
			local alpha = k / steps
			local cur_x = start_x + (target_x - start_x) * alpha
			local cur_y = start_y + (target_y - start_y) * alpha
			local cur_z = start_z + (target_z - start_z) * alpha
			seedEntity:SetPosition(cur_x, cur_y, cur_z)
			copilot:Wait(step_delay)
		end
	end

	local msg
	-- Do Plant
	if Plant and Plant.DoPlant and Plant.plants then
		local plantGrow = Plant.plants[real_name]
		if plantGrow then
			local success = Plant.DoPlant(plantGrow, bx, by, bz, 1, seedEntity)
			if not success then
				msg = L("不好意思，种植失败,请尝试手动种植一下吧~")
			else
				msg = L("种植完成！")
			end
		else
			msg = L("配置错误：找不到植物生长数据") .. tostring(real_name)
		end
	end

	copilot:Wait(1)
	seedEntity:SetPosition(old_x, old_y, old_z)
	if msg then
		copilot:Say(msg)
	end
end

function Planting:HandleLLMResult(result)
	local tool_name, args
	if type(result) == "table" and result.tool_calls and result.tool_calls[1] then
		local tool = result.tool_calls[1]
		if tool["function"] then
			tool_name = tool["function"].name
			args = tool["function"].arguments
			if type(args) == "string" then
				args = commonlib.Json.Decode(args)
			end
		end
	elseif type(result) == "string" then
		local json_res = commonlib.Json.Decode(result)
		if json_res and json_res.tool_calls and json_res.tool_calls[1] then
			local tool = json_res.tool_calls[1]
			if tool["function"] then
				tool_name = tool["function"].name
				args = tool["function"].arguments
				if type(args) == "string" then
					args = commonlib.Json.Decode(args)
				end
			end
		end
	end

	if tool_name == "water" then
		self:AutoWater(self.copilot, args.use, args.target)
	else
		if type(result) == "string" then
			self.copilot:Say(result)
		elseif type(result) == "table" and result.content then
			self.copilot:Say(result.content)
		end
	end
end

function Planting:ExecuteTask(copilot)
	if self.params.action ~= nil and self.params.action ~= "" then
		if self.params.action == L("帮我浇水") then
			self:AutoWater(copilot, self.params.use, self.params.target)
		elseif self.params.action == L("帮我收获") then
			self:AutoHarvest(copilot,self.params.target)
		elseif self.params.action == L("帮我种植") then
			local plant = self.params.plant
			local pos = nil
			if self.params.x and self.params.y and self.params.z then
				pos = { x = self.params.x, y = self.params.y, z = self.params.z }
			end
			self:AutoPlant(copilot, plant, pos)
		end
		return
	end
	local params = self.params or {}
	local startMsg = params.startMsg or "Go planting nearby!"
	local finishMsg = params.finishMsg or "Nice planting!"
	local plant_id = params.plant_id
	if plant_id == 0 then
		plant_id = nil
	end

	copilot:Say(startMsg)
	self:RunGuideSteps(copilot, plant_id)
	copilot:Say(finishMsg)
end

function Planting:LoadUserItems(copilot, name)
	local result = nil
	local finished = false
	local function check_inventory()
		if InventoryManager and InventoryManager.LoadUserItems then
			InventoryManager.LoadUserItems(function()
				if InventoryManager.userItems then
					for _, item in ipairs(InventoryManager.userItems) do
						if item.name == name or item.name == name or string.find(item.name, name, 1, true) then
							result = item
							break
						end
					end
				end
				finished = true
				copilot:Resume()
			end)
		else
			LOG.std(nil, "warn", "PlantingTask", "InventoryManager or LoadUserItems missing")
			finished = true
			copilot:Resume()
		end
	end

	check_inventory()
	if not finished then
		copilot:Yield()
	end

	local wait_inv = 0
	-- Wait up to 50 seconds
	while not finished and wait_inv < 500 do
		copilot:Wait(0.1)
		wait_inv = wait_inv + 1
	end

	LOG.std(nil, "info", "PlantingTask", "check_inventory finished. wait_inv: %d", wait_inv)

	if not finished then
		LOG.std(nil, "warn", "PlantingTask", "LoadUserItems timed out")
		return
	end
	return result
end

function Planting:GuideToBuyItem(copilot, item_id, item_name, buy_text)
	local shop_item_btn = "shop_item_" .. item_id
	local PlantShopWindow = commonlib.gettable("paracraft.offical.maisi.Plant.Shop.Window")
	if PlantShopWindow and PlantShopWindow.GetItemUIName then
		local uiname = PlantShopWindow.GetItemUIName(item_id)
		if uiname then
			shop_item_btn = uiname
		end
	end

	-- 1. Click Keeper
	local keeper = copilot:GetEntity()
	if keeper then
		self.inGuide = false
		while not CopilotGUIGuide.IsUIObjectVisible("easy_char_chat") do
			if not self.inGuide then
				self.inGuide = true
				CopilotGUIGuide.GuideClickEntity({
					copilot = copilot,
					entity = keeper,
					text = L("请点击小管家或者互动按钮"),
				})
			end
			self:CheckPaused()
			copilot:Wait(0.5)
			if self:CheckStopRequested() then
				CopilotGUIGuide.GuideClickEntity({})
				return false
			end
		end
	else
		return false
	end

	-- 2. Click Chat Button
	if CopilotGUIGuide.IsUIObjectVisible("easy_char_chat") then
		self.inGuide = false
		local wait_count = 0
		while not CopilotGUIGuide.IsUIObjectVisible("easy_ai_quick_reply_buy_seed") do
			if not self.inGuide and CopilotGUIGuide.IsUIObjectVisible("easy_char_chat") then
				self.inGuide = true
				CopilotGUIGuide.GuideClickButton({
					copilot = copilot,
					buttonName = "easy_char_chat",
					text = L("请点击对话按钮"),
				})
			end
			wait_count = wait_count + 1
			if wait_count > 20 then
				self.inGuide = false
				wait_count = 0
			end
			self:CheckPaused()
			copilot:Wait(0.5)
			if self:CheckStopRequested() then
				CopilotGUIGuide.GuideClickButton({})
				return false
			end
		end
	end

	-- 3. Click Shop Button (Buy Seed)
	if CopilotGUIGuide.IsUIObjectVisible("easy_ai_quick_reply_buy_seed") then
		local wait_shop = 0
		self.inGuide = false
		while not CopilotGUIGuide.IsUIObjectVisible("shop_next_page") do
			if not self.inGuide then
				self.inGuide = true
				CopilotGUIGuide.GuideClickButton({
					copilot = copilot,
					buttonName = "easy_ai_quick_reply_buy_seed",
					text = L("请点击种子商店按钮"),
				})
			end
			self:CheckPaused()
			copilot:Wait(0.5)
			wait_shop = wait_shop + 1
			if wait_shop > 20 then
				self.inGuide = false
				wait_shop = 0
			end
			if self:CheckStopRequested() then
				CopilotGUIGuide.GuideClickButton({})
				return false
			end
		end

		-- Page Navigation
		local PlantShopWindow = commonlib.gettable("paracraft.offical.maisi.Plant.Shop.Window")
		if PlantShopWindow and PlantShopWindow.GetItemPageIndex then
			local target_page = PlantShopWindow.GetItemPageIndex(item_id)
			local wait_next_page = 0
			self.inGuide = false
			while PlantShopWindow.currentPage and PlantShopWindow.currentPage < target_page do
				if not self.inGuide then
					self.inGuide = true
					CopilotGUIGuide.GuideClickButton({
						copilot = copilot,
						buttonName = "shop_next_page",
						text = L("请点击下一页按钮"),
					})
				end
				wait_next_page = wait_next_page + 1
				if wait_next_page > 20 then
					self.inGuide = false
					wait_next_page = 0
				end
				self:CheckPaused()
				copilot:Wait(0.5)
				if self:CheckStopRequested() then
					CopilotGUIGuide.GuideClickButton({})
					return false
				end
			end
		end
	end

	-- 4. Click Item to Buy
	if CopilotGUIGuide.IsUIObjectVisible(shop_item_btn) then
		self.inGuide = false
		local wait_count = 0
		local completed = false
		while true do
			if not self.inGuide and CopilotGUIGuide.IsUIObjectVisible(shop_item_btn) then
				self.inGuide = true
				CopilotGUIGuide.GuideClickButton({
					copilot = copilot,
					buttonName = shop_item_btn,
					text = buy_text or (L("请点击购买") .. (item_name or "")),
				})
			end
			wait_count = wait_count + 1
			if wait_count > 20 then
				self.inGuide = false
				wait_count = 0
			end

			if not CopilotGUIGuide.IsUIObjectVisible(shop_item_btn) then
				-- Check if item is in bag
				local result = self:LoadUserItems(copilot, item_name)
				if result then
					completed = true
				end
			end

			if completed then
				break
			end

			self:CheckPaused()
			copilot:Wait(0.5)
			if self:CheckStopRequested() then
				CopilotGUIGuide.GuideClickButton({})
				return false
			end
		end
	end
	return true
end

function Planting:GuideToUseItem(copilot, item_name, use_text)
	local seed_bag_btn = "userbag_item_" .. item_name

	-- 1. Open Bag
	if CopilotGUIGuide.IsUIObjectVisible(self.guide_prop_btn) then
		self.inGuide = false
		local wait_count = 0
		while true do
			if not self.inGuide and not CopilotGUIGuide.IsUIObjectVisible(seed_bag_btn) then
				self.inGuide = true
				CopilotGUIGuide.GuideClickButton({
					copilot = copilot,
					buttonName = self.guide_prop_btn,
					text = L("请点击道具按钮"),
				})
			end
			if CopilotGUIGuide.IsUIObjectVisible("user_bag_ui") then
				CopilotGUIGuide.GuideClickButton({})
				break
			end
			self:CheckPaused()
			wait_count = wait_count + 1
			if wait_count > 20 then
				self.inGuide = false
				wait_count = 0
			end
			copilot:Wait(0.5)
			if self:CheckStopRequested() then
				CopilotGUIGuide.GuideClickButton({})
				return false
			end
		end
	end

	-- 2. Click Item
	self.inGuide = false
	local completed = false
	if self.on_clicked_user_bag_item_callback then
		GameLogic.GetCodeGlobal()
			:UnregisterTextEvent("on_clicked_user_bag_item", self.on_clicked_user_bag_item_callback)
		self.on_clicked_user_bag_item_callback = nil
	end
	self.on_clicked_user_bag_item_callback = function(args, msg)
		if msg and msg.msg and msg.msg.name == item_name then
			completed = true
		end
	end
	GameLogic.GetCodeGlobal():RegisterTextEvent("on_clicked_user_bag_item", self.on_clicked_user_bag_item_callback)

	local wait_count = 0
	while true do
		if CopilotGUIGuide.IsUIObjectVisible(seed_bag_btn) then
			if not self.inGuide then
				self.inGuide = true
				CopilotGUIGuide.GuideClickButton({
					copilot = copilot,
					buttonName = seed_bag_btn,
					text = use_text or (L("请点击") .. (item_name or "")),
				})
			end
		end
		if completed then
			break
		end
		wait_count = wait_count + 1
		if wait_count > 20 then
			self.inGuide = false
			wait_count = 0
		end
		self:CheckPaused()
		copilot:Wait(0.5)
		if self:CheckStopRequested() then
			CopilotGUIGuide.GuideClickButton({})
			if self.on_clicked_user_bag_item_callback then
				GameLogic.GetCodeGlobal()
					:UnregisterTextEvent("on_clicked_user_bag_item", self.on_clicked_user_bag_item_callback)
				self.on_clicked_user_bag_item_callback = nil
			end
			return false
		end
	end

	if self.on_clicked_user_bag_item_callback then
		GameLogic.GetCodeGlobal()
			:UnregisterTextEvent("on_clicked_user_bag_item", self.on_clicked_user_bag_item_callback)
		self.on_clicked_user_bag_item_callback = nil
	end
	return true
end

function Planting:GuideDragEntity(copilot, entity_or_name, targetX, targetY, targetZ, text)
	local completed = false
	self.inGuide = false
	local entity, _targetX, _targetY, _targetZ
	local wait_count = 0
	while not completed do
		if not self.inGuide then
			self.inGuide = true
			entity, _targetX, _targetY, _targetZ = CopilotGUIGuide.GuideDragEntity({
				copilot = copilot,
				entityOrName = entity_or_name,
				targetX = targetX,
				targetY = targetY,
				targetZ = targetZ,
				duration = 2,
				text = text,
				entityKeys = {
					{ key = "realName", value = entity_or_name },
					{ key = "plantDataIndex", value = "nil or empty" },
				},
			})
		end
		if self:CheckStopRequested() then
			CopilotGUIGuide.GuideDragEntity({})
			return nil
		end
		if entity and _targetX and _targetY and _targetZ then
			local dist = entity:GetDistanceSq(_targetX, _targetY, _targetZ)
			if dist < 1 then
				completed = true
				CopilotGUIGuide.GuideDragEntity({})
				break
			end
		end
		wait_count = wait_count + 1
		if wait_count > 20 then
			self.inGuide = false
			wait_count = 0
		end
		self:CheckPaused()
		copilot:Wait(0.5)
	end
	return entity, _targetX, _targetY, _targetZ
end

function Planting:WaitForPlantDataUpdate(copilot, plantEntity)
	local Plant = commonlib.gettable("paracraft.offical.maisi.Plant")
	if not Plant or not Plant.FindPlantInfo then
		return
	end

	local confId, idx, info
	local retry = 0
	-- Try up to 5 seconds to sync data
	while retry < 1 do
		confId, idx, info = FindPlantInfoSafe(plantEntity)
		-- Check for valid timestamp (server data has non-zero timestamp at index 6)
		if info and (info[6] or 0) > 0 then
			LOG.std(nil, "info", "PlantingTask", "Plant data synced: %s", commonlib.serialize_compact(info))
			return confId, idx, info
		end

		-- Try to trigger data refresh if possible (placeholder for actual sync logic)
		if plantEntity and plantEntity.MarkForUpdate then
			plantEntity:MarkForUpdate()
		end

		copilot:Wait(0.03)
		retry = retry + 1
	end
	LOG.std(nil, "warn", "PlantingTask", "Plant data sync timed out or failed")
	return confId, idx, info
end

-- 1. Prepare Seed: Check entity -> Check Bag -> Buy -> Use
function Planting:GuideToPrepareSeed(copilot, plant_id, seed_name)
	-- Check for existing seed entity in scene
	local found_seed_entity = false
	local allEntities = GameLogic.EntityManager.GetAllEntities()
	for _, _entity in pairs(allEntities) do
		if _entity:isa(GameLogic.EntityManager.EntityLiveModel) then
			local realName = _entity:GetTagField("realName", "")
			local plantDataIndex = _entity:GetTagField("plantDataIndex", "")
			if realName == seed_name and (plantDataIndex == "" or plantDataIndex == nil) then
				found_seed_entity = true
				local player = GameLogic.EntityManager.GetPlayer()
				local px, py, pz = player:GetBlockPos()
				local camerayaw = GameLogic.RunCommand("/camerayaw")
				local camerayaw_opposite = camerayaw + math.pi
				local px, py, pz = player:GetPosition()
				local l_x = px + math.cos(camerayaw_opposite) * 2
				local l_z = pz - math.sin(camerayaw_opposite) * 2
				local l_bx, l_by, l_bz = GameLogic.BlockEngine:block(l_x, py, l_z)
				local bx, by, bz = player:GetBlockPos()
				_entity:SetBlockPos(l_bx, by, l_bz)
				break
			end
		end
	end

	-- If not found, check inventory. If not in inventory, buy it. Then use it.
	if not found_seed_entity then
		local has_seed = self:LoadUserItems(copilot, seed_name) ~= nil
		if not has_seed then
			if not self:GuideToBuyItem(copilot, plant_id, seed_name, L("请点击购买种子袋")) then
				return false
			end
		end
		if not self:GuideToUseItem(copilot, seed_name, L("请点击种子袋")) then
			return false
		end
	end
	return true
end

-- 2. Plant Seed: Drag seed to target
function Planting:GuideToPlantSeed(copilot, seed_name)
	return self:GuideDragEntity(copilot, seed_name, nil, nil, nil, L("请拖动种子袋到目标位置"))
end

-- 3. Prepare Water Can: Find entity -> Check Bag -> Buy -> Use
function Planting:GuideToPrepareWaterCan(copilot)
	local waterCanEntity = nil
	local allEntities = GameLogic.EntityManager.GetAllEntities()
	for _, ent in pairs(allEntities) do
		if ent:GetTagField("wateringCan") then
			waterCanEntity = ent
			break
		end
	end

	local water_can_name = "purple_wateringCan"
	local water_can_id = 101

	if not waterCanEntity then
		local waterCanItem = self:LoadUserItems(copilot, "wateringCan")
		if waterCanItem then
			water_can_name = waterCanItem.name
			water_can_id = waterCanItem.id
		end

		if not waterCanItem then
			if not self:GuideToBuyItem(copilot, water_can_id, water_can_name, L("请点击购买水壶")) then
				return nil
			end
			waterCanItem = self:LoadUserItems(copilot, "wateringCan")
			if waterCanItem then
				water_can_name = waterCanItem.name
				water_can_id = waterCanItem.id
			end
		end

		if not self:GuideToUseItem(copilot, water_can_name, L("请点击水壶")) then
			return nil
		end

		-- Find the entity now
		allEntities = GameLogic.EntityManager.GetAllEntities()
		for _, ent in pairs(allEntities) do
			if ent:GetTagField("wateringCan") then
				waterCanEntity = ent
				break
			end
		end
	end
	return waterCanEntity
end

-- 4. Water Plant: Drag water can to plant
function Planting:GuideToWaterPlant(copilot, waterCanEntity, targetX, targetY, targetZ)
	if waterCanEntity then
		local camerayaw = GameLogic.RunCommand("/camerayaw")
		local camerayaw_opposite = camerayaw + math.pi
		local camerayaw_opposite_left = camerayaw_opposite - math.pi / 2
		local radius = 2 + math.random() * 3
		local wx = targetX + radius * math.cos(camerayaw_opposite_left)
		local wz = targetZ - radius * math.sin(camerayaw_opposite_left)
		waterCanEntity:SetPosition(wx, targetY, wz)

		self:GuideDragEntity(
			copilot,
			waterCanEntity,
			targetX,
			targetY,
			targetZ,
			L("请拖动水壶到种子上方位置")
		)
	end
end

-- Check if plant is mature
function Planting:CheckIsMature(copilot, plantEntity)
	local Plant = commonlib.gettable("paracraft.offical.maisi.Plant")
	if Plant and Plant.CheckIsMature then
		return Plant.CheckIsMature(plantEntity)
	end
	return false
end

-- 5. Harvest: Wait for maturity and guide click
function Planting:GuideToHarvest(copilot, seed_name, targetX, targetY, targetZ)
	local Plant = commonlib.gettable("paracraft.offical.maisi.Plant")
	if not Plant or not Plant.FindPlantInfo then
		return
	end

	local bx, by, bz = GameLogic.BlockEngine:block(targetX, targetY + 0.1, targetZ)
	local entities = GameLogic.EntityManager.GetEntitiesByMinMax(
		bx,
		by - 1,
		bz,
		bx,
		by,
		bz,
		GameLogic.EntityManager.EntityLiveModel,
		nil
	)
	local plantEntity = nil
	if entities and #entities > 0 then
		for i = 1, #entities do
			local entity2 = entities[i]
			if entity2:GetTagField("realName") == seed_name then
				plantEntity = entity2
				break
			end
		end
	end

	if plantEntity then
		local confId, idx, info = self:WaitForPlantDataUpdate(copilot, plantEntity)
		if info then
			local remainingTime = 0
			-- 获取服务器时间
			local time_stamp = GameLogic.GetFilters():apply_filters("service.session.get_current_server_time")
			local time = time_stamp or os.time()

			-- Use info[6] directly if available to avoid potential issues with function call
			if type(info) == "table" and info[6] then
				remainingTime = info[6] - time
			elseif Plant.GetRemainingMaturityTime then
				remainingTime = Plant.GetRemainingMaturityTime(info)
			else
				print("Error: Plant.GetRemainingMaturityTime is nil and info[6] is missing")
			end

			local plantName = plantEntity:GetTagField("realName")
			local plantGrow = Plant.plants and Plant.plants[plantName]
			local stageCount = plantGrow and #plantGrow or 3
			local currentStage = tonumber(plantEntity:GetTagField("plantStage")) or 1

			LOG.std(
				nil,
				"debug",
				"PlantingTask",
				"Plant Info: name=%s, stage=%d/%d, remaining=%d",
				tostring(plantName),
				currentStage,
				stageCount,
				remainingTime
			)

			if currentStage >= stageCount and remainingTime <= 0 then
				self.inGuide = false
				local clicked = false
				local ActionNameDetector = commonlib.gettable("MyCompany.Aries.Game.Common.ActionNameDetector")
				if self.actionTriggerHandler then
					ActionNameDetector:Disconnect("actionTriggered", self.actionTriggerHandler)
				end
				self.actionTriggerHandler = function(entity, actionIndex, actionName)
					if entity == plantEntity and actionName == "收获" then
						clicked = true
					end
				end
				ActionNameDetector:Connect("actionTriggered", self.actionTriggerHandler)
				local wait_count = 0
				while true do
					if not self.inGuide then
						self.inGuide = true
						CopilotGUIGuide.GuideClickEntity({
							copilot = copilot,
							entity = plantEntity,
							text = L("点击收获成熟作物"),
						})
					end
					if clicked then
						break
					end
					self:CheckPaused()
					copilot:Wait(0.5)
					wait_count = wait_count + 1
					if wait_count >= 20 then
						self.inGuide = false
						wait_count = 0
					end
					if self:CheckStopRequested() then
						if self.actionTriggerHandler then
							ActionNameDetector:Disconnect("actionTriggered", self.actionTriggerHandler)
							self.actionTriggerHandler = nil
						end
						CopilotGUIGuide.GuideClickEntity({})
						return
					end
				end
				if self.actionTriggerHandler then
					ActionNameDetector:Disconnect("actionTriggered", self.actionTriggerHandler)
					self.actionTriggerHandler = nil
				end
			end
		end
	end
end

function Planting:RunGuideSteps(copilot, plant_id)
	if plant_id == nil or plant_id == 0 or plant_id == "" then
		return
	end

	local findPlantEntity = nil
	local allEntities = GameLogic.EntityManager.GetAllEntities()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua")
	local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
	for _, entity in pairs(allEntities) do
		if entity:isa(GameLogic.EntityManager.EntityLiveModel) then
			local taskInfo = entity:GetTagField("taskInfo")
			if taskInfo and taskInfo.id == plant_id then
				local bx, by, bz = entity:GetBlockPos()
				local x, y, z = entity:GetPosition()
				local copilot_entity = self.copilot.entity
				local cx, cy, cz = copilot_entity:GetPosition()
				local dx, dy, dz = x - cx, y - cy, z - cz
				local facing = Direction.GetFacingFromOffset(dx, dy, dz) + math.pi
				local tx, ty, tz = x + math.cos(facing) * 2, y, z - math.sin(facing) * 2
				local tbx, tby, tbz = GameLogic.BlockEngine:block(tx, ty + 0.1, tz)
				self.copilot:WalkTo(tbx, tby, tbz)
				findPlantEntity = entity
				break
			end
		end
	end

	local seed_name = nil
	if findPlantEntity then
		seed_name = findPlantEntity:GetTagField("realName")
	else
		local PlantShopWindow = commonlib.gettable("paracraft.offical.maisi.Plant.Shop.Window")
		if PlantShopWindow and PlantShopWindow.GetItemName then
			seed_name = PlantShopWindow.GetItemName(plant_id)
		end
	end

	if not seed_name or seed_name == "" then
		return
	end

	local targetX, targetY, targetZ
	if findPlantEntity then
		targetX, targetY, targetZ = findPlantEntity:GetPosition()
		local isMature = self:CheckIsMature(copilot, findPlantEntity)
		if isMature then
			self.copilot:PlayText(L("快来点击收获吧！"))
			self:GuideToHarvest(copilot, seed_name, targetX, targetY, targetZ)
		else
			local waterCanEntity = self:GuideToPrepareWaterCan(copilot)
			if not waterCanEntity then
				return
			end
			self:GuideToWaterPlant(copilot, waterCanEntity, targetX, targetY, targetZ)
			self:GuideToHarvest(copilot, seed_name, targetX, targetY, targetZ)
		end
	else
		-- 1. Prepare Seed
		if not self:GuideToPrepareSeed(copilot, plant_id, seed_name) then
			return
		end

		-- 2. Plant Seed
		local seedEntity
		seedEntity, targetX, targetY, targetZ = self:GuideToPlantSeed(copilot, seed_name)
		if not seedEntity then
			return
		end

		-- 3. Prepare Water Can
		local waterCanEntity = self:GuideToPrepareWaterCan(copilot)
		if not waterCanEntity then
			return
		end

		-- 4. Water Plant
		self:GuideToWaterPlant(copilot, waterCanEntity, targetX, targetY, targetZ)

		-- 5. Harvest
		self:GuideToHarvest(copilot, seed_name, targetX, targetY, targetZ)
	end

	while true do
		copilot:Wait(0.5)
		if self:CheckStopRequested() then
			return
		end
		self:CheckPaused()
		if self:CheckCompletedTask(plant_id) then
			break
		end
	end
	self:SetTaskResult({
		success = true,
		plant_id = self.receivedData and self.receivedData.id,
		plant_data = self.receivedData
	})
	return true
end
