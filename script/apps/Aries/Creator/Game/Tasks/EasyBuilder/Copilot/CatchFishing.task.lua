--[[
Title: CatchFishing Task
Author(s): Copilot
Date: 2025/12/16
Desc: A task that waits for the player to catch a fish.

use the lib:
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CatchFishing.task.lua");
local CatchFishing = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.CatchFishing");

]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotTaskBase.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotGUIGuide.lua")
local CopilotGUIGuide = commonlib.gettable("MyCompany.Aries.Game.Tasks.Copilot.CopilotGUIGuide")
local CopilotTaskBase = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.CopilotTaskBase")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager")
local SensitivityUI = commonlib.gettable("Paracraft.Official.SensitivityUI")
NPL.load("(gl)script/ide/System/Util/Iterators.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local Iterators = commonlib.gettable("System.Util.Iterators");

local CatchFishing = commonlib.inherit(
	CopilotTaskBase,
	commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.CatchFishing")
)

CatchFishing.name = "CatchFishing"

function CatchFishing:ctor()
	CatchFishing._super.ctor(self)
	self.guide_prop_btn = "minigame_user_item"
	self.guide_tool_btn = "userbag_item_fishing_rod"
	self.guide_entity_btn = "甩竿"
	self.guide_ui_btn = "fish_slot_1"
end

function CatchFishing:Init(copilot, params)
	CatchFishing._super.Init(self, copilot, params)

	if params then
		self.guide_prop_btn = params.guide_prop_btn or self.guide_prop_btn
		self.guide_tool_btn = params.guide_tool_btn or self.guide_tool_btn
		self.guide_entity_btn = params.guide_entity_btn or self.guide_entity_btn
		self.guide_ui_btn = params.guide_ui_btn or self.guide_ui_btn
	end

	return self
end

function CatchFishing:GetTaskName()
	return "CatchFishing"
end

function CatchFishing:CheckCompletedTask(fish_id)
	if self.receivedData and self.receivedData.id then
		if fish_id == nil or fish_id == 0 then
			return true
		else
			return tonumber(self.receivedData.id) == tonumber(fish_id)
		end
	end
	return false
end

function CatchFishing:ExecuteTask(copilot)
	local params = self.params or {}
	local startMsg = params.startMsg or "Go fishing nearby!"
	local finishMsg = params.finishMsg or "Nice catch!"
	local fish_id = params.fish_id
	if fish_id == 0 then
		fish_id = nil
	end

	copilot:Say(startMsg)
	self:RunGuideSteps(copilot, fish_id)
	copilot:Say(finishMsg)
end

function CatchFishing:GuideFishingRodState(copilot)
	local fishing_rod = EntityManager.GetEntity("fishing_rod")
	if fishing_rod then
		local player = EntityManager.GetPlayer()
		if player then
			local x, y, z = player:GetPosition()
			fishing_rod:SetPosition(x, y, z)
			fishing_rod:FallDown()
		end
		copilot:Wait(1)
		return true
	end
	return false
end

function CatchFishing:GuidePropButton(copilot)
	local prop_btn = self.guide_prop_btn
	local tool_btn = self.guide_tool_btn

	if prop_btn then
		self.inGuide = false
		-- Wait until tool_btn is visible (Inventory opened)
		if tool_btn then
			local wait_count = 0
			while not CopilotGUIGuide.IsUIObjectVisible(tool_btn) do
				if not self.inGuide then
					self.inGuide = true
					CopilotGUIGuide.GuideClickButton({
						copilot = copilot,
						buttonName = prop_btn,
						text = L("请点击道具按钮"),
					})
				end
				self:CheckPaused()
				copilot:Wait(0.5)
				wait_count = wait_count + 1
				if wait_count > 20 then
					wait_count = 0
					self.inGuide = false
				end
				if self:CheckStopRequested() then
					CopilotGUIGuide.GuideClickButton({})
					return true
				end
			end
		else
			copilot:Wait(1)
		end
	end
	return false
end

function CatchFishing:GuideToolButton(copilot)
	local tool_btn = self.guide_tool_btn

	if tool_btn then
		-- Wait for tool button to be visible (e.g. if inventory takes time to open, or if this is the first step)
		self.inGuide = false
		while not CopilotGUIGuide.IsUIObjectVisible(tool_btn) do
			self:CheckPaused()
			copilot:Wait(0.5)
			if self:CheckStopRequested() then
				CopilotGUIGuide.GuideClickButton({})
				return true
			end
		end

		self.inGuide = false
		-- Wait until tool button is hidden (Inventory closed)
		local wait_count = 0
		while true do
			if not self.inGuide and CopilotGUIGuide.IsUIObjectVisible(tool_btn) then
				self.inGuide = true
				CopilotGUIGuide.GuideClickButton({
					copilot = copilot,
					buttonName = tool_btn,
					text = L("请点击捕鱼道具"),
				})
			end
			self:CheckPaused()
			copilot:Wait(0.5)
			wait_count = wait_count + 1
			if wait_count > 20 then
				wait_count = 0
				self.inGuide = false
			end
			local fishing_rod = EntityManager.GetEntity("fishing_rod")
			if fishing_rod then
				break
			end
			if self:CheckStopRequested() then
				CopilotGUIGuide.GuideClickButton({})
				return true
			end
		end
	end
	return false
end

function CatchFishing:FindNearbyWater(copilot, radius)
	radius = radius or 50
	local player = GameLogic.EntityManager.GetPlayer()
	if not player then
		return
	end

	local px, py, pz = player:GetBlockPos()
	local BlockEngine = GameLogic.BlockEngine

	local function isWater(x, y, z)
		local block = BlockEngine:GetBlock(x, y, z)
		return block and block.material and block.material:isLiquid()
	end
	local tx, ty, tz
	for dx, dz in Iterators.SpiralCircle(radius) do
		local x = px + dx
		local z = pz + dz
		for dy = 0, -2, -1 do
			local y = py + dy
			if isWater(x, y, z) then
				-- Found water, now find a land spot next to it that is closest to the player
				local best_x, best_y, best_z
				local min_dist_sq = 999999999
				
				local dirs = {{0, 1}, {0, -1}, {1, 0}, {-1, 0}}
				for _, dir in ipairs(dirs) do
					local nx, nz = x + dir[1], z + dir[2]
					-- Check if neighbor is NOT water (land)
					if not isWater(nx, y, nz) then
						local dist_sq = (nx - px)^2 + (nz - pz)^2
						if dist_sq < min_dist_sq then
							min_dist_sq = dist_sq
							best_x, best_y, best_z = nx, y, nz
							
						end
					end
				end
				
				if best_x then
					tx, ty, tz = best_x, best_y, best_z
					break
				end
			end
		end
		if tx then
			break
		end
	end
	if tx then
		local entity = copilot.entity
		local  cx,cy,cz = entity:GetBlockPos()
		local facing = Direction.GetFacingFromOffset(cx - tx, 0, cz - tz)
		local target_x, target_y, target_z = tx + math.cos(facing) * 3, py, tz - math.sin(facing) * 3
		return target_x, target_y, target_z
	end
end

function CatchFishing:GuideEntityAction(copilot)
	local entity_btn = self.guide_entity_btn

	if entity_btn then
		-- Wait while the action is still available (entity not clicked)
		local target, actionIndex = CopilotGUIGuide.FindEntityByActionName(entity_btn)
		if target then
			local clicked = false
			local ActionNameDetector = commonlib.gettable("MyCompany.Aries.Game.Common.ActionNameDetector")
			if self.actionTriggerHandler then
				ActionNameDetector:Disconnect("actionTriggered", self.actionTriggerHandler)
			end
			self.actionTriggerHandler = function(entity, actionIndex, actionName)
				if entity == target and actionName == entity_btn then
					clicked = true
				end
			end
			ActionNameDetector:Connect("actionTriggered", self.actionTriggerHandler)

			self.inGuide = false
			local wait_count = 0
			while true do
				if not self.inGuide then
					self.inGuide = true
					CopilotGUIGuide.GuideClickEntity({
						copilot = copilot,
						entity = target,
						actionIndex = actionIndex,
						text = L("请点击甩竿"),
					})
				end

				if clicked then
					break
				end
				wait_count = wait_count + 1
				if wait_count > 20 then
					wait_count = 0
					self.inGuide = false
				end
				self:CheckPaused()
				copilot:Wait(0.5)
				if self:CheckStopRequested() then
					if self.actionTriggerHandler then
						ActionNameDetector:Disconnect("actionTriggered", self.actionTriggerHandler)
						self.actionTriggerHandler = nil
					end
					CopilotGUIGuide.GuideClickEntity({})
					return true
				end
			end

			if self.actionTriggerHandler then
				ActionNameDetector:Disconnect("actionTriggered", self.actionTriggerHandler)
				self.actionTriggerHandler = nil
			end
			if SensitivityUI and SensitivityUI.SetIsGuiding then
				SensitivityUI.SetIsGuiding(true)
			end
		else
			copilot:Wait(0.1)
		end
		CopilotGUIGuide.GuideClickEntity({})
	end
	return false
end

function CatchFishing:GuideFishUI(copilot)
	local ui_btn = self.guide_ui_btn

	if ui_btn then
		local target_btn = nil

		-- Wait for fish to be visible (stopped at a slot)
		while true do
			if SensitivityUI and SensitivityUI.fishVisible and SensitivityUI.activeSlot then
				target_btn = "fishing_slot_" .. SensitivityUI.activeSlot
				break
			end
			self:CheckPaused()
			copilot:Wait(0.03)
			if self:CheckStopRequested() then
				CopilotGUIGuide.GuideClickButton({})
				return true
			end
		end

		if target_btn then
			self.inGuide = false
			local clicked = false
			-- Wait until UI btn is hidden (clicked) or fish is gone
			if self.on_click_fishing_fishing_slot_callback then
				GameLogic.GetCodeGlobal()
					:UnregisterTextEvent("on_click_fishing_fishing_slot", self.on_click_fishing_fishing_slot_callback)
				self.on_click_fishing_fishing_slot_callback = nil
			end
			self.on_click_fishing_fishing_slot_callback = function(args, msg)
				local index = msg.index
				clicked = true
			end
			GameLogic.GetCodeGlobal()
				:RegisterTextEvent("on_click_fishing_fishing_slot", self.on_click_fishing_fishing_slot_callback)

			local wait_count = 0
			while true do
				if not self.inGuide and CopilotGUIGuide.IsUIObjectVisible(target_btn) and SensitivityUI.fishVisible then
					self.inGuide = true
					CopilotGUIGuide.GuideClickButton({
						copilot = copilot,
						buttonName = target_btn,
						text = L("请点击鱼出现的按钮"),
						ignoreWalk = true,
					})
				end
				self:CheckPaused()
				copilot:Wait(0.03)
				wait_count = wait_count + 1
				if wait_count > 300 then
					wait_count = 0
					self.inGuide = false
				end

				if clicked then
					break
				end

				if self:CheckStopRequested() then
					CopilotGUIGuide.GuideClickButton({})
					if self.on_click_fishing_fishing_slot_callback then
						GameLogic.GetCodeGlobal():UnregisterTextEvent(
							"on_click_fishing_fishing_slot",
							self.on_click_fishing_fishing_slot_callback
						)
						self.on_click_fishing_fishing_slot_callback = nil
					end
					return true
				end
			end
			if self.on_click_fishing_fishing_slot_callback then
				GameLogic.GetCodeGlobal()
					:UnregisterTextEvent("on_click_fishing_fishing_slot", self.on_click_fishing_fishing_slot_callback)
				self.on_click_fishing_fishing_slot_callback = nil
			end
			CopilotGUIGuide.GuideClickButton({})
		end
	end
	return false
end

function CatchFishing:WaitForCompletion(copilot, fish_id)
	while true do
		copilot:Wait(0.5)
		if self:CheckCompletedTask(fish_id) then
			break
		end
		self:CheckPaused()
		if self:CheckStopRequested() then
			CopilotGUIGuide.GuideClickButton({})
			return true
		end
	end
	return false
end

function CatchFishing:GetOrCreateEntity(arg)
    local name = arg.name
    local entity = GameLogic.EntityManager.GetEntity(name)
    if entity == nil then
        entity = GameLogic.EntityManager.EntityLiveModel:Create()
        entity:Attach()
        entity:SetName(name)
    end
    entity:SetModelFile(arg.modelFile or "model/blockworld/BlockModel/block_model_one.x")
    if arg.skin ~= "" and arg.skin ~= nil then
        entity:SetSkin(arg.skin)
    end
    if arg.pos then
        entity:SetPosition(arg.pos[1], arg.pos[2], arg.pos[3])
    end
    entity:setScale(arg.scale or 1)
    if arg.bx and arg.by and arg.bz then
        entity:SetBlockPos(arg.bx, arg.by, arg.bz)
    end
    entity:SetOnClickEvent(arg.onClick or "")
    entity:SetOnTickEvent(arg.onTick or "")
    if arg.say then
        entity:Say(arg.say, -1)
    end
    entity:SetFacing(arg.facing or 0)
    entity:SetLocked(arg.locked or false)
    entity:EnablePhysics(arg.physics or false)
    entity:SetCanDrag(arg.canDrag == nil and true or arg.canDrag)
    entity:SetPersistent(false);
    if arg.roll then
        entity:SetRoll(arg.roll)
    end
    return entity
end

function CatchFishing:ClearPaths()
	if self.pathPoints then
		for _, point in pairs(self.pathPoints) do
			point:Destroy()
		end
		self.pathPoints = {}
	end
	
end

function CatchFishing:GuideWater(copilot)
	local wait_count = 0
	self.inGuide = false
	while true do
		if not self.inGuide then
			self.inGuide = true
			local wx, wy, wz = self:FindNearbyWater(copilot, 50)
			if wx then
				copilot:Say(L("跟我来!"))
				copilot:PlayText(L("跟我来!"))
				copilot:WalkTo(wx, wy, wz)
				break
			else
				copilot:Say(L("请走到有水源的地方"))
				copilot:PlayText(L("请走到有水源的地方"))
			end
		end
		wait_count = wait_count + 1
		if wait_count > 20 then
			wait_count = 0
			self.inGuide = false
		end
		self:CheckPaused()
		if self:CheckStopRequested() then
			return true
		end
		copilot:Wait(0.5)
	end
	
	self.inGuide = false
	local wait_count = 0
	local player = GameLogic.GetPlayer()
	self.pathPoints = {}
	while true do	
		local px, py, pz = player:GetPosition()
		local tx, ty, tz = copilot.entity:GetPosition()
		local facing = Direction.GetFacingFromOffset(px - tx, 0, pz - tz)
		px, py, pz = px + math.cos(facing + math.pi) * 2, py, pz - math.sin(facing + math.pi) * 2
		local index = 0
		-- Draw moving arrow
		self.arrow_progress = (self.arrow_progress or 0) + 0.05
		if self.arrow_progress > 1 then
			self.arrow_progress = 0
		end
		local t = self.arrow_progress
		
		-- Interpolate position
		local tip_x = px * (1 - t) + tx * t
		local tip_y = py * (1 - t) + ty * t
		local tip_z = pz * (1 - t) + tz * t

		-- Arrow config
		local arrow_len = 1 
		local shaft_len = 2.0 
		local arrow_angle = math.rad(30)
		
		local dx = px - tx
		local dz = pz - tz
		local angle = facing

		-- Wing 1
		local w1x = tip_x + arrow_len * math.cos(angle + arrow_angle)
		local w1z = tip_z - arrow_len * math.sin(angle + arrow_angle)
		
		-- Wing 2
		local w2x = tip_x + arrow_len * math.cos(angle - arrow_angle)
		local w2z = tip_z - arrow_len * math.sin(angle - arrow_angle)
		
		-- Shaft tail
		local tail_x = tip_x + shaft_len * math.cos(angle)
		local tail_z = tip_z - shaft_len * math.sin(angle)

		-- Draw Shaft
		for i = 0, 1, 0.1 do
			index = index + 1
			local x = tail_x * (1 - i) + tip_x * i
			local z = tail_z * (1 - i) + tip_z * i
			if self.pathPoints[index] == nil then
				local point = self:GetOrCreateEntity({
					name = "guide_path_" .. index,
					pos = {x, tip_y, z},
					scale = 0.05,
				})
				self.pathPoints[index] = point
			else
				self.pathPoints[index]:SetPosition(x, tip_y, z)
			end
		end

		-- Draw Wing 1
		for i = 0, 1, 0.1 do
			index = index + 1
			local x = w1x * (1 - i) + tip_x * i
			local z = w1z * (1 - i) + tip_z * i
			if self.pathPoints[index] == nil then
				local point = self:GetOrCreateEntity({
					name = "guide_path_" .. index,
					pos = {x, tip_y, z},
					scale = 0.05,
				})
				self.pathPoints[index] = point
			else
				self.pathPoints[index]:SetPosition(x, tip_y, z)
			end
		end

		-- Draw Wing 2
		for i = 0, 1, 0.1 do
			index = index + 1
			local x = w2x * (1 - i) + tip_x * i
			local z = w2z * (1 - i) + tip_z * i
			if self.pathPoints[index] == nil then
				local point = self:GetOrCreateEntity({
					name = "guide_path_" .. index,
					pos = {x, tip_y, z},
					scale = 0.05,
				})
				self.pathPoints[index] = point
			else
				self.pathPoints[index]:SetPosition(x, tip_y, z)
			end
		end

		-- Hide unused points
		for i = index + 1, #self.pathPoints do
			if self.pathPoints[i] then
				self.pathPoints[i]:SetPosition(0, -1000, 0)
			end
		end
		if not self.inGuide then
			self.inGuide = true
			local wx, wy, wz = self:FindNearbyWater(copilot, 5)
			local yaw = GameLogic.RunCommand("/camerayaw")
			copilot:SetFacing(yaw+math.pi)
			if wx then
				self:ClearPaths()
				return true
			else
				copilot:Say(L("走到我这边来"))
				copilot:PlayText(L("走到我这边来"))
			end
		end
		copilot:Wait(0.08)
		wait_count = wait_count + 1
		if wait_count > 150 then
			wait_count = 0
			self.inGuide = false
		end
		self:CheckPaused()
		if self:CheckStopRequested() then
			self:ClearPaths()
			return true
		end
	end
end

function CatchFishing:RunGuideSteps(copilot, fish_id)
	if not self:GuideWater(copilot) then
		return
	end
	if not self:GuideFishingRodState(copilot) then
		if self:GuidePropButton(copilot) then
			return
		end
		if self:GuideToolButton(copilot) then
			return
		end
	end

	if self:GuideEntityAction(copilot) then
		return
	end

	if self:GuideFishUI(copilot) then
		return
	end

	if self:WaitForCompletion(copilot, fish_id) then
		return
	end

	self:SetTaskResult({
		success = true,
		fish_id = self.receivedData and self.receivedData.id,
		fish_data = self.receivedData
	})

	return true
end

function CatchFishing:OnPauseByUser()
	self.inGuide = false
	CopilotGUIGuide.GuideDragEntity({})
	CopilotGUIGuide.GuideClickButton({})
	CopilotGUIGuide.GuideClickEntity({})
end
