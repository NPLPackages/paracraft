--[[
Title: Cooking Task
Author(s): Copilot
Date: 2025/12/25
Desc: A task that waits for the player to cook something.

use the lib:
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/Cooking.task.lua");
local Cooking = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.Cooking");
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotTaskBase.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotGUIGuide.lua")
local CopilotGUIGuide = commonlib.gettable("MyCompany.Aries.Game.Tasks.Copilot.CopilotGUIGuide")
local CopilotTaskBase = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.CopilotTaskBase")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")

local Cooking =
	commonlib.inherit(CopilotTaskBase, commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.Cooking"))

Cooking.name = "Cooking"

function Cooking:ctor()
	Cooking._super.ctor(self)
	self.guide_prop_btn = "minigame_user_item"
	self.guide_tool_btn = "userbag_item_cooking"
	self.guide_entity_btn = "烹饪"
end

function Cooking:Init(copilot, params)
	Cooking._super.Init(self, copilot, params)
	if params then
		self.guide_prop_btn = params.guide_prop_btn or self.guide_prop_btn
	end
	return self
end

function Cooking:GetTaskName()
	return "Cooking"
end

function Cooking:OnPauseByUser()
	self.inGuide = false
	CopilotGUIGuide.GuideDragEntity({})
	CopilotGUIGuide.GuideClickButton({})
	CopilotGUIGuide.GuideClickEntity({})
end

function Cooking:OnRemove()
	CopilotGUIGuide.GuideDragEntity({})
	CopilotGUIGuide.GuideClickButton({})
	CopilotGUIGuide.GuideClickEntity({})
	Cooking._super.OnRemove(self)
end

function Cooking:CheckCompletedTask(cook_id)
	if self.receivedData and self.receivedData.id ~= nil then
		if cook_id == nil then
			return true
		else
			return cook_id == self.receivedData.id
		end
	end
	return false
end

function Cooking:ExecuteTask(copilot)
	local params = self.params or {}
	local startMsg = params.startMsg or "Go cooking nearby!"
	local finishMsg = params.finishMsg or "Nice cooking!"
	local cook_id = params.recipe_id
	if cook_id == 0 then
		cook_id = nil
	end

	copilot:Say(startMsg)
	self:RunGuideSteps(copilot, cook_id)
	copilot:Say(finishMsg)
end

--检查并定位现有的烹饪实体。
function Cooking:CheckAndPositionEntity(copilot)
	local entity_btn = self.guide_entity_btn
	local found_entity = nil
	if entity_btn then
		local allEntities = GameLogic.EntityManager.GetAllEntities()
		for _, entity in pairs(allEntities) do
			local actionName = entity:GetTagField("actionname", "")
			if actionName and (actionName == entity_btn or actionName:find(entity_btn, 1, true)) then
				found_entity = entity
				break
			end
		end

		if found_entity then
			local player = GameLogic.EntityManager.GetPlayer()
			local camerayaw = GameLogic.RunCommand("/camerayaw")
			local camerayaw_opposite = camerayaw + math.pi
			local camerayaw_opposite_left = camerayaw_opposite + math.pi / 2
			local px, py, pz = player:GetPosition()
			local l_x = px + math.cos(camerayaw_opposite_left) * 2
			local l_z = pz - math.sin(camerayaw_opposite_left) * 2
			found_entity:SetPosition(l_x, py, l_z)
		end
	end
	return found_entity
end

--引导点击道具按钮（打开背包）。
function Cooking:GuidePropButton(copilot)
	local prop_btn = self.guide_prop_btn
	local tool_btn = self.guide_tool_btn

	-- Step 1: Guide Props Button
	if prop_btn then
		self.inGuide = false
		-- Wait until tool_btn is visible (Inventory opened)
		local wait_count = 0
		if tool_btn then
			while true do
				if not self.inGuide and not CopilotGUIGuide.IsUIObjectVisible(tool_btn) then
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
					self.inGuide = false
					wait_count = 0
				end
				if CopilotGUIGuide.IsUIObjectVisible(tool_btn) then
					break
				end
				if self:CheckStopRequested() then
					CopilotGUIGuide.GuideClickButton({})
					return true
				end
			end
		else
			copilot:Wait(1)
		end
	else
		return true
	end
	return false
end

--引导点击烹饪道具按钮
function Cooking:GuideToolButton(copilot)
	local tool_btn = self.guide_tool_btn

	-- Step 2: Guide Tool,点击背包中的烹饪按钮
	if tool_btn then
		local wait_count = 0
		self.inGuide = false
		-- Wait until tool button is hidden (Inventory closed)
		while true do
			if not self.inGuide and CopilotGUIGuide.IsUIObjectVisible(tool_btn) then
				self.inGuide = true
				CopilotGUIGuide.GuideClickButton({
					copilot = copilot,
					buttonName = tool_btn,
					text = L("请点击烹饪按钮"),
				})
			end
			self:CheckPaused()
			copilot:Wait(0.5)
			wait_count = wait_count + 1
			if wait_count > 20 then
				self.inGuide = false
				wait_count = 0
			end
			local entity = GameLogic.EntityManager.GetEntity("__easy_stove_base__")
			if entity then
				break
			end
			if self:CheckStopRequested() then
				CopilotGUIGuide.GuideClickButton({})
				return true
			end
		end
	else
		return true
	end
	return false
end

--引导点击场景中的烹饪实体按钮
function Cooking:GuideEntityAction(copilot)
	local entity_btn = self.guide_entity_btn

	-- Step 3: Guide Entity,点击场景中的锅上面的烹饪按钮
	if entity_btn then
		-- Wait while the action is still available (entity not clicked)
		local wait_count = 0
		local target, actionIndex
		while true do
			self:CheckPaused()
			copilot:Wait(0.1)
			target, actionIndex = CopilotGUIGuide.FindEntityByActionName(entity_btn)
			wait_count = wait_count + 1
			if wait_count > 5000 or target ~= nil then
				break
			end
			if self:CheckStopRequested() then
				CopilotGUIGuide.GuideClickButton({})
				return true
			end
		end

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
						text = L("请点击烹饪按钮或者锅"),
					})
				end

				if clicked then
					break
				end
				self:CheckPaused()
				copilot:Wait(0.5)
				wait_count = wait_count + 1
				if wait_count > 20 then
					self.inGuide = false
					wait_count = 0
				end
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
		else
			copilot:Wait(5)
		end
		CopilotGUIGuide.GuideClickEntity({})
	end
	return false
end

--等待烹饪任务完成
function Cooking:WaitForCompletion(copilot, cook_id)
	while true do
		copilot:Wait(0.5)
		if self:CheckStopRequested() then
			return true
		end
		if self:CheckCompletedTask(cook_id) then
			break
		end
	end
	return false
end

function Cooking:RunGuideSteps(copilot, cook_id)
	local found_entity = self:CheckAndPositionEntity(copilot)

	if not found_entity then
		if self:GuidePropButton(copilot) then return end
		if self:GuideToolButton(copilot) then return end
	end

	if self:GuideEntityAction(copilot) then return end

	if self:WaitForCompletion(copilot, cook_id) then return end

	self:SetTaskResult({
		success = true,
		recipe_id = self.receivedData and self.receivedData.id,
		recipe_data = self.receivedData
	})
	return true
end
