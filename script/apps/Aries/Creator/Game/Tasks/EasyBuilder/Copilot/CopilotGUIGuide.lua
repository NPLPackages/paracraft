--[[
Title: Copilot GUI Guide
Author(s): LiXizhi
Date: 2025/12/16
Desc: Provides static functions to guide the user to click UI objects to reach a certain GUI state,
such as selecting a given block, opening a window, or testing if a given GUI state is reached.

This module is used by the Copilot AI system to:
1. Guide users through UI interactions with visual highlights
2. Detect current GUI state (e.g., is a specific block selected)
3. Programmatically trigger UI actions to reach desired states

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotGUIGuide.lua");
local CopilotGUIGuide = commonlib.gettable("MyCompany.Aries.Game.Tasks.Copilot.CopilotGUIGuide");

-- Example: Check if a specific block is selected
if CopilotGUIGuide.IsBlockSelected(62) then
    -- block 62 is selected in hand
end

-- Example: Guide user to select a block
CopilotGUIGuide.GuideSelectBlock(62);

CopilotGUIGuide.GuideClickButton("QuickSelectBar.btn5", 5, function()
    GameLogic.AddBBS(nil, "You clicked button 5!", 3000, "255 255 0");
end)

CopilotGUIGuide.GuideClickButtons({"QuickSelectBar.btn5", "EasyModel.ShowAllBlocks", "EasyModel.BlockCategory.5", "EasyModel.Blocks.10"});
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient")

local Application = commonlib.gettable("System.Windows.Application")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyModel.lua")
local EasyModel = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyModel")
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/ActionNameDetector.lua")
local ActionNameDetector = commonlib.gettable("MyCompany.Aries.Game.Common.ActionNameDetector")
NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/MobileMainPage.lua")
local MobileMainPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Mobile.MobileMainPage")
NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/MobileContext.lua")
local MobileContext = commonlib.gettable("MyCompany.Aries.Creator.Game.Mobile.MobileContext")

local CopilotGUIGuide = commonlib.gettable("MyCompany.Aries.Game.Tasks.Copilot.CopilotGUIGuide")
-----------------------------------------
-- GUI State Detection Functions
-----------------------------------------

-- Check if a specific block is currently selected in the player's right hand
-- @param blockId: number - the block ID to check, or nil to check if any block is selected
-- @return boolean: true if the block is selected
function CopilotGUIGuide.IsBlockSelected(blockId)
	local currentBlockId = GameLogic.GetBlockInRightHand()
	if currentBlockId == 10077 then
		-- easy builder
		if EasyModel.GetPickedBlockId and EasyModel.GetPickedBlockId() == blockId then
			return true
		end
	else
		return currentBlockId == blockId
	end
	return false
end

-- Get the currently selected block ID in the player's right hand
-- @return number: the block ID, or 0 if no block is selected
function CopilotGUIGuide.GetSelectedBlockId()
	local currentBlockId = GameLogic.GetBlockInRightHand()
	if currentBlockId == 10077 then
		-- easy builder
		if EasyModel.GetPickedBlockId then
			return EasyModel.GetPickedBlockId()
		else
			return 0
		end
	else
		return currentBlockId or 0
	end
end

-- Check if we are in edit mode
-- @return boolean: true if in editor mode
function CopilotGUIGuide.IsInBlockEditMode()
	local currentBlockId = GameLogic.GetBlockInRightHand()
	if currentBlockId == 10077 then
		-- easy builder
		local itemStack = GameLogic.GetPlayerController():GetItemStackInRightHand()
		if itemStack and itemStack:GetDataField("toolname") == "model" then
			return true
		else
			return false
		end
	else
		return GameLogic.GameMode:IsEditor()
	end
end

function CopilotGUIGuide.HasEasyBuilder()
	local playerEntity = EntityManager.GetPlayer()
	if playerEntity and playerEntity.inventory then
		local slotCount = playerEntity.inventory:GetSlotCount()
		for i = 0, slotCount - 1 do
			local itemStack = playerEntity.inventory:GetItem(i)
			if itemStack and type(itemStack) == "table" and itemStack:GetDataField("toolname") == "model" then
				return true, i
			end
		end
	end
	return false
end

function CopilotGUIGuide.TransformBottomBlockPosToScreenPos(blocks)
	if not blocks or #blocks == 0 then
		return
	end

	local player = EntityManager.GetFocus()
	if not player then
		return
	end

	local bx, by, bz = player:GetBlockPos()
	local minDis = math.huge
	local minBlock = nil
	local minY = math.huge

	for _, b in ipairs(blocks) do
		if b.by < minY then
			minY = b.by
			minBlock = b
			minDis = (b.bx - bx) ^ 2 + (b.by - by) ^ 2 + (b.bz - bz) ^ 2
		elseif b.by == minY then
			local dis = (b.bx - bx) ^ 2 + (b.by - by) ^ 2 + (b.bz - bz) ^ 2
			if dis < minDis then
				minDis = dis
				minBlock = b
			end
		end
	end

	if minBlock then
		local screen_pos = {}
		local x, y, z = BlockEngine:real(minBlock.bx, minBlock.by, minBlock.bz)
		ParaScene.GetScreenPosFrom3DPoint(x, y, z, screen_pos)
		screen_pos.y = screen_pos.y + 0.5
		return screen_pos, minBlock
	end
end

function CopilotGUIGuide.GuideTakeBlock(blockId)
	local hasEasyBuilder, slotIndex = CopilotGUIGuide.HasEasyBuilder()
	local buttons = {}
	local category_button, block_button = nil, nil
	if hasEasyBuilder then
		buttons = { "QuickSelectBar.btn5" }
		local categoryIndex = EasyModel.GetBlockCategory(blockId)
		local nHandIndex = EasyModel.GetHandIndexByBlockId(blockId)
		if nHandIndex then
			buttons[#buttons + 1] = string.format("EasyModel.block%d", nHandIndex)
		elseif categoryIndex then
			category_button = string.format("EasyModel.BlockCategory.%d", categoryIndex)
			block_button = string.format("EasyModel.Blocks.%d", blockId)
			buttons[#buttons + 1] = "EasyModel.ShowAllBlocks"
			buttons[#buttons + 1] = category_button
			buttons[#buttons + 1] = block_button
		end
	else
		local isEditMode = CopilotGUIGuide.IsInBlockEditMode()
		buttons = { "QuickSelectBar.btnInventory" }
		if not isEditMode then
			buttons[#buttons + 1] = "DesktopMenuPage.EditMode"
			buttons[#buttons + 1] = "QuickSelectBar.btnInventory"
		end
		local BuilderFramePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BuilderFramePage")
		local categoryIndex = BuilderFramePage.GetCategoryIndexByBlock(blockId)
		if categoryIndex then
			category_button = string.format("BuilderFramePage.category_%d", categoryIndex)
			block_button = string.format("BuilderFramePage.block_%d", blockId)
			buttons[#buttons + 1] = category_button
			buttons[#buttons + 1] = block_button
		end
	end
	CopilotGUIGuide.GuideClickButtons(buttons, 0)
	return category_button, block_button
end

function CopilotGUIGuide.GuideScrollTips()
	local hasEasyBuilder, slotIndex = CopilotGUIGuide.HasEasyBuilder()
	local IsMobileUIEnabled = GameLogic.GetFilters():apply_filters("MobileUIRegister.IsMobileUIEnabled", false)
	if not IsMobileUIEnabled then
		GameLogic.AddBBS("guideScrollTips", L("请滚动鼠标滚轮到目标方块"), 2000)
		local screenWidth = System.Windows.Screen:GetWidth()
		local screenHeight = System.Windows.Screen:GetHeight()
		if hasEasyBuilder then
			CopilotGUIGuide.GuideTextTip(
				L("请滚动鼠标滚轮直到显示目标方块"),
				screenWidth / 2,
				screenHeight / 2
			)
		else
			CopilotGUIGuide.GuideTextTip(
				L("请滚动鼠标滚轮直到显示目标方块"),
				screenWidth - 280,
				screenHeight / 2
			)
		end
		return
	end
	CopilotGUIGuide.GuideTextTip(L("在当前页面滑动直到显示目标方块"))
end

function CopilotGUIGuide.GuideTextTip(text, x, y)
	local overlayName = "CopilotGUIGuide.TextTipOverlay"
	local _gui = ParaUI.GetUIObject(overlayName)

	if not text or text == "" then
		if _gui:IsValid() then
			_gui.visible = false
		end
		return
	end

	local ctrlHeight = 48

	if not _gui:IsValid() then
		_gui = ParaUI.CreateUIObject("container", overlayName, "_lt", 0, 0, 100, ctrlHeight)
		_gui.background = ""
		_gui.zorder = 10002
		_gui:AttachToRoot()

		local _left = ParaUI.CreateUIObject("container", "left", "_lt", 0, 0, 50, ctrlHeight)
		_left.background = "Texture/Aries/Common/gradient_white_32bits.png#0 0 7 16"
		_left.colormask = "31 50 67 255"
		_left.enabled = false
		_gui:AddChild(_left)

		local _middle = ParaUI.CreateUIObject("container", "middle", "_lt", 50, 0, 10, ctrlHeight)
		_middle.background = "Texture/Aries/Common/gradient_white_32bits.png#7 0 1 16"
		_middle.colormask = "31 50 67 255"
		_middle.enabled = false
		_gui:AddChild(_middle)

		local _right = ParaUI.CreateUIObject("container", "right", "_lt", 60, 0, 50, ctrlHeight)
		_right.background = "Texture/Aries/Common/gradient_white_32bits.png#8 0 7 16"
		_right.colormask = "31 50 67 255"
		_right.enabled = false
		_gui:AddChild(_right)

		local _text = ParaUI.CreateUIObject("text", "text", "_lt", 0, 12, 100, 24)
		_text.font = "System;16;bold"
		_guihelper.SetFontColor(_text, "#ffffff")
		_gui:AddChild(_text)

		_gui:GetAttributeObject():SetField("ClickThrough", true)
		_left:GetAttributeObject():SetField("ClickThrough", true)
		_middle:GetAttributeObject():SetField("ClickThrough", true)
		_right:GetAttributeObject():SetField("ClickThrough", true)
	end

	local _text = _gui:GetChild("text")
	_text.text = text
	local textWidth = _guihelper.GetTextWidth(text, "System;16;bold")
	if textWidth < 20 then
		textWidth = math.ceil(ParaMisc.GetUnicodeCharNum(text) * 8 + 20)
	end
	_text.width = textWidth

	local ctrlWidth = textWidth + 80 -- 40px padding each side
	local sliceWidth = 50

	if ctrlWidth < sliceWidth * 2 then
		ctrlWidth = sliceWidth * 2
	end

	local root = ParaUI.GetUIObject("root")
	if not x or not y then
		x = math.floor((root.width - ctrlWidth) / 2)
		y = 150
	end

	_gui.x = x
	_gui.y = y
	_gui.width = ctrlWidth
	_gui.visible = true

	local _left = _gui:GetChild("left")
	local _middle = _gui:GetChild("middle")
	local _right = _gui:GetChild("right")

	_left.width = sliceWidth
	_middle.x = sliceWidth
	_middle.width = ctrlWidth - (sliceWidth * 2)
	_right.x = ctrlWidth - sliceWidth
	_right.width = sliceWidth

	_text.x = ctrlWidth / 2 - _text.width / 2
	_guihelper.SetUIFontFormat(_text, 5, "System;16;bold")
end

function CopilotGUIGuide.GuideKeyAndMouse(keyValue, mouseValue, x, y)
	local overlayName = "CopilotGUIGuide.KeyMouseOverlay"
	local _gui = ParaUI.GetUIObject(overlayName)

	if (not keyValue or keyValue == "") and (not mouseValue or mouseValue == "") then
		if _gui:IsValid() then
			_gui.visible = false
		end
		return
	end

	local height = 64

	if not _gui:IsValid() then
		_gui = ParaUI.CreateUIObject("container", overlayName, "_lt", 0, 0, 100, height)
		_gui.background = ""
		_gui.zorder = 10002
		_gui:AttachToRoot()

		-- Key Container
		local _key = ParaUI.CreateUIObject("container", "key", "_lt", 0, 0, 64, 64)
		_key.background = "Texture/Aries/Quest/keyboard_btn.png:10 10 10 16"
		_gui:AddChild(_key)

		local _keyText = ParaUI.CreateUIObject("text", "keyText", "_lt", 0, 0, 64, 20)
		_keyText.font = "System;20;bold"
		_guihelper.SetFontColor(_keyText, "#000000")
		_guihelper.SetUIFontFormat(_keyText, 37) -- center | vcenter | singleline
		_key:AddChild(_keyText)

		-- Plus Sign
		local _plus = ParaUI.CreateUIObject("text", "plus", "_lt", 0, 0, 30, height)
		_plus.text = "+"
		_plus.font = "System;30;bold"
		_guihelper.SetFontColor(_plus, "#000000")
		_guihelper.SetUIFontFormat(_plus, 37)
		_gui:AddChild(_plus)

		-- Mouse Icon
		local _mouse = ParaUI.CreateUIObject("button", "mouse", "_lt", 0, 0, 64, 64)
		_mouse.background = ""
		_mouse.enabled = false
		_gui:AddChild(_mouse)
	end

	local _key = _gui:GetChild("key")
	local _keyText = _key:GetChild("keyText")
	local _plus = _gui:GetChild("plus")
	local _mouse = _gui:GetChild("mouse")

	local currentX = 0
	local spacing = 10

	-- Setup Key
	if keyValue and keyValue ~= "" then
		_key.visible = true
		_keyText.text = keyValue

		local textWidth = _guihelper.GetTextWidth(keyValue, "System;20;bold")
		local keyWidth = math.max(50, textWidth + 30)
		local keyHeight = 50

		_key.width = keyWidth
		_key.height = keyHeight
		_key.y = (height - keyHeight) / 2

		_keyText.width = keyWidth
		_keyText.height = keyHeight

		currentX = keyWidth + spacing
	else
		_key.visible = false
	end

	-- Setup Mouse
	local hasMouse = false
	if mouseValue and mouseValue ~= "" then
		local bg = ""
		local w, h = 46, 60
		if mouseValue == "left" then
			bg = "Texture/Aries/Quest/TutorialMouse_LeftClick_small_32bits.png"
		elseif mouseValue == "right" then
			bg = "Texture/Aries/Quest/TutorialMouse_RightClick_small_32bits.png"
		elseif mouseValue == "middle" then
			bg = "Texture/Aries/Quest/gunlun_42x63_32bits.png"
			w, h = 42, 63
		end

		if bg ~= "" then
			hasMouse = true
			_mouse.visible = true
			_mouse.background = bg
			_mouse.width = w
			_mouse.height = h
			_mouse.y = (height - h) / 2
		else
			_mouse.visible = false
		end
	else
		_mouse.visible = false
	end

	-- Setup Plus
	if _key.visible and hasMouse then
		_plus.visible = true
		_plus.x = currentX
		currentX = currentX + _plus.width + spacing

		_mouse.x = currentX
		currentX = currentX + _mouse.width
	elseif _key.visible then
		_plus.visible = false
		currentX = currentX - spacing -- Remove trailing spacing
	elseif hasMouse then
		_plus.visible = false
		_mouse.x = 0
		currentX = _mouse.width
	end

	_gui.width = currentX

	local root = ParaUI.GetUIObject("root")
	if not x or not y then
		x = math.floor((root.width - _gui.width) / 2)
		y = 200
	end

	_gui.x = x
	_gui.y = y
	_gui.visible = true
end

-----------------------------------------
-- GUI Action Functions (Guide to reach a state)
-----------------------------------------

local function isLiquidBlock(block)
	return block.id == 75 or block.id == 76
end

local function getDiffBlocks(blocks1, blocks2)
	local diffBlocks = {}
	local blocksMaps1 = {}
	for _, block in ipairs(blocks1) do
		local key = string.format("%d_%d_%d", block.bx, block.by, block.bz)
		blocksMaps1[key] = block
	end
	for _, block in ipairs(blocks2) do
		local key = string.format("%d_%d_%d", block.bx, block.by, block.bz)
		if not blocksMaps1[key] and not isLiquidBlock(block) then
			table.insert(diffBlocks, block)
		end
	end
	return diffBlocks
end

local function normalizeBlocks(blocks)
	local normalizedBlocks = {}
	for _, block in ipairs(blocks) do
		if not block.bx and block[1] then
			normalizedBlocks[#normalizedBlocks + 1] = {
				bx = block[1],
				by = block[2],
				bz = block[3],
				id = block[4],
			}
		end
	end
	return normalizedBlocks
end

-- Guide the user to select one of the input blocks
-- This may open the block selection window and highlight the target block
-- @param blockId: number - the target block ID to select
-- @param callback: function - optional callback when block is selected
-- this is need run in coroutine
function CopilotGUIGuide.GuideSelectBlocks(blocks, copilot, task)
	if not blocks or not copilot then
		return false
	end
	local IsMobileUIEnabled = GameLogic.GetFilters():apply_filters("MobileUIRegister.IsMobileUIEnabled", false)
	local hasEasyBuilder, slotIndex = CopilotGUIGuide.HasEasyBuilder()
	local screen_pos, minBlock = CopilotGUIGuide.TransformBottomBlockPosToScreenPos(blocks)
	local select_task
	if screen_pos and screen_pos.x then
		while true do
			if task and task.CheckStopRequested and task:CheckStopRequested() then
				ParaTerrain.DeselectAllBlock(2)
				ParaTerrain.DeselectAllBlock(5)
				copilot:HideHeadOnBlock()
				CopilotGUIGuide.Stop()
				return
			end
			if task and task.CheckPaused then
				task:CheckPaused()
			end
			select_task = MyCompany.Aries.Game.Tasks.SelectBlocks.GetCurrentInstance()
			if select_task then
				CopilotGUIGuide.Stop()
				CopilotGUIGuide.GuideKeyAndMouse()
				CopilotGUIGuide.GuideTextTip("")

				CopilotGUIGuide.ShowGuideCursor(false)
				local selectedBlocks = normalizeBlocks(select_task.GetCurrentSelection() or {})
				if #selectedBlocks <= 1 then
					CopilotGUIGuide.GuideClickButton({
						buttonName = "SelectBlocksTask.btn_selectall",
						duration = 0,
						text = L("请点击这里"),
					})
					copilot:Wait(0.5)
				else
					local diffBlocks = getDiffBlocks(selectedBlocks, blocks)
					local diffNum = #diffBlocks
					if diffNum <= 3 then
						CopilotGUIGuide.Stop()
						break
					else
						screen_pos = CopilotGUIGuide.TransformBottomBlockPosToScreenPos(diffBlocks)
						local PosY = screen_pos.y - 80
						if PosY < 0 then
							PosY = screen_pos.y + 64
						end
						CopilotGUIGuide.GuideKeyAndMouse("Ctrl", "left", screen_pos.x, PosY)
						CopilotGUIGuide.ShowGuideCursor(true, screen_pos.x, screen_pos.y, 64, 64)
						copilot:Wait(0.5)
					end
				end
			else
				if hasEasyBuilder then
					if EasyModel.GetCurrentBrushMode() ~= "select" then
						local buttons = { "QuickSelectBar.btn5", "EasyModel.Select" }
						CopilotGUIGuide.GuideClickButtons(buttons, 0)
					else
						CopilotGUIGuide.Stop()
						screen_pos = CopilotGUIGuide.TransformBottomBlockPosToScreenPos(blocks)
						CopilotGUIGuide.ShowGuideCursor(true, screen_pos.x, screen_pos.y, 64, 64)
					end
				elseif IsMobileUIEnabled then
					local sceneContext = MobileMainPage.GetSceneContext()
					if not sceneContext or sceneContext ~= MOBILE_BUTTON_STATE.STATE_SELECT then
						local uiobj = ParaUI.GetUIObject("btn_xuanze")
						if uiobj and uiobj:IsValid() then
							local x, y = uiobj.x, uiobj.y
							CopilotGUIGuide.ShowGuideCursor(true, x, y, 64, 64)
							CopilotGUIGuide.GuideTextTip(L("按住选择按钮"), x, y - 60)
						end
					else
						screen_pos = CopilotGUIGuide.TransformBottomBlockPosToScreenPos(blocks)
						CopilotGUIGuide.GuideTextTip("")
						CopilotGUIGuide.ShowGuideCursor(true, screen_pos.x, screen_pos.y, 64, 64)
					end
				else
					screen_pos = CopilotGUIGuide.TransformBottomBlockPosToScreenPos(blocks)
					local PosY = screen_pos.y - 80
					if PosY < 0 then
						PosY = screen_pos.y + 64
					end
					CopilotGUIGuide.GuideKeyAndMouse("Ctrl", "left", screen_pos.x, PosY)
					CopilotGUIGuide.ShowGuideCursor(true, screen_pos.x, screen_pos.y, 64, 64)
				end
			end
			copilot:Wait(1)
		end
	end
	return true
end

-- Directly select a block in the player's right hand (programmatic, not guided)
-- @param blockId: number - the block ID to select
-- @return boolean: true if successful
function CopilotGUIGuide.SelectBlock(blockId)
	if not blockId then
		return false
	end
	local currentBlockId = GameLogic.GetBlockInRightHand()
	if currentBlockId == 10077 then
		-- easy builder
		EasyModel.TakeItem(blockId)
	else
		GameLogic.SetBlockInRightHand(blockId)
	end
	return CopilotGUIGuide.IsBlockSelected(blockId)
end

-- Internal state for the guide cursor
CopilotGUIGuide.cursorUIName = "CopilotGuideCursor"
CopilotGUIGuide.highlightedButtonName = nil
CopilotGUIGuide.visibilityCheckTimerId = nil
CopilotGUIGuide.visibilityCheckInterval = 500 -- ms
CopilotGUIGuide.durationTimerId = nil
CopilotGUIGuide.pulseAnimTimerId = nil
CopilotGUIGuide.pulseAnimInterval = 50 -- ms for animation frame update

-- Stop the pulse animation timer
local function StopPulseAnimation()
	if CopilotGUIGuide.pulseAnimTimerId then
		CopilotGUIGuide.pulseAnimTimerId:Change()
		CopilotGUIGuide.pulseAnimTimerId = nil
	end
end

-- Start the beeping pulse animation with scaling and alpha
-- Animates directly using ApplyAnim
local function StartPulseAnimation()
	StopPulseAnimation()

	local cursorName = CopilotGUIGuide.cursorUIName
	local animTime = 0
	local pulseDuration = 800 -- ms for one complete pulse cycle

	-- Create the pulse animation cycle
	local function DoPulse()
		local cursor = ParaUI.GetUIObject(cursorName)
		if not cursor:IsValid() or not cursor.visible then
			StopPulseAnimation()
			return
		end

		local circle = cursor:GetChild("img_mousecursor")
		if not circle:IsValid() then
			return
		end

		-- Calculate animation progress (0 to 1 for expand, 1 to 0 for contract)
		animTime = animTime + CopilotGUIGuide.pulseAnimInterval
		if animTime >= pulseDuration then
			animTime = 0
		end

		-- Use sine wave for smooth beeping effect
		local progress = math.sin(animTime / pulseDuration * math.pi)

		-- Interpolate scale (1.0 to 1.3) and alpha (1.0 to 0.6)
		local scale = 1.0 + 0.3 * progress
		local alpha = 1.0 - 0.4 * progress

		-- Apply the animation directly
		circle.scalingx = scale
		circle.scalingy = scale
		circle.colormask = string.format("255 255 255 %d", math.floor(alpha * 255))
		circle:ApplyAnim()
	end

	-- Start the first frame immediately
	DoPulse()

	-- Create timer for continuous animation
	CopilotGUIGuide.pulseAnimTimerId = commonlib.Timer:new({
		callbackFunc = function()
			DoPulse()
		end,
	})
	CopilotGUIGuide.pulseAnimTimerId:Change(CopilotGUIGuide.pulseAnimInterval, CopilotGUIGuide.pulseAnimInterval)
end

-- Similar to MacroPlayer.ShowCursor, using same UI effects as MacroPlayer.html
-- @param bShow: boolean - whether to show or hide the cursor
-- @param x: number - screen x position (optional)
-- @param y: number - screen y position (optional)
-- @param buttonWidth: number - width of the target button (optional, for scaling)
-- @param buttonHeight: number - height of the target button (optional, for scaling)
function CopilotGUIGuide.ShowGuideCursor(bShow, x, y, buttonWidth, buttonHeight)
	local cursorName = CopilotGUIGuide.cursorUIName
	local cursor = ParaUI.GetUIObject(cursorName)

	if bShow then
		-- Match MacroPlayer.html cursorClick container size (default 32px)
		local cursorSize = 32

		-- Calculate circle size based on button dimensions
		-- Scale circle to at least min(buttonWidth, buttonHeight), with a minimum of 64
		local baseCircleSize = 64
		local circleSize = baseCircleSize
		if buttonWidth and buttonHeight then
			local minButtonDim = math.min(buttonWidth, buttonHeight)
			circleSize = math.max(baseCircleSize, minButtonDim)
		end
		-- Calculate circle offset to center it on the cursor
		local circleOffset = -math.floor((circleSize - cursorSize) / 2)

		if not cursor:IsValid() then
			-- Create cursor container (similar to MacroPlayer.html cursorClick)
			cursor = ParaUI.CreateUIObject("container", cursorName, "_lt", 0, 0, cursorSize, cursorSize)
			cursor.background = ""
			cursor.enabled = false
			cursor.zorder = 10000 -- Use highest zorder to ensure cursor is always on top
			cursor:AttachToRoot()

			local circle = ParaUI.CreateUIObject(
				"button",
				"img_mousecursor",
				"_lt",
				circleOffset,
				circleOffset,
				circleSize,
				circleSize
			)
			circle.background = "Texture/Aries/Cursor/clicky.png"
			circle.enabled = false
			cursor:AddChild(circle)
		else
			-- Update existing circle size and position
			local circle = cursor:GetChild("img_mousecursor")
			if circle:IsValid() then
				circle.x = circleOffset
				circle.y = circleOffset
				circle.width = circleSize
				circle.height = circleSize
			end
		end

		cursor.visible = true
		if x and y then
			cursor.x = x - cursorSize / 2
			cursor.y = y - cursorSize / 2
		end

		-- Start the pulse animation
		if not CopilotGUIGuide.pulseAnimTimerId then
			StartPulseAnimation()
		end
	else
		if cursor:IsValid() then
			cursor.visible = false
		end
		-- Stop the pulse animation
		StopPulseAnimation()
	end
end

-- Get current guide cursor position
function CopilotGUIGuide.GetGuideCursorPos()
	local cursor = ParaUI.GetUIObject("CopilotGUIGuide.Cursor")
	if cursor and cursor:IsValid() and cursor.visible then
		local width = cursor.width
		local height = cursor.height
		return cursor.x + width / 2, cursor.y + height / 2
	end
	return nil, nil
end

-- Stop the duration timer
local function StopDurationTimer()
	if CopilotGUIGuide.durationTimerId then
		CopilotGUIGuide.durationTimerId:Change()
		CopilotGUIGuide.durationTimerId = nil
	end
end

-- Stop all guide related timers and hide cursor
function CopilotGUIGuide.Stop()
	-- Stop button sequence timer
	if CopilotGUIGuide.buttonsTimerId then
		CopilotGUIGuide.buttonsTimerId:Change()
		CopilotGUIGuide.buttonsTimerId = nil
	end

	-- Stop visibility check timer
	if CopilotGUIGuide.visibilityCheckTimerId then
		CopilotGUIGuide.visibilityCheckTimerId:Change()
		CopilotGUIGuide.visibilityCheckTimerId = nil
	end

	-- Stop entity click timer
	if CopilotGUIGuide.entityTimerId then
		CopilotGUIGuide.entityTimerId:Change()
		CopilotGUIGuide.entityTimerId = nil
	end

	-- Stop drag entity timer
	if CopilotGUIGuide.dragTimerId then
		CopilotGUIGuide.dragTimerId:Change()
		CopilotGUIGuide.dragTimerId = nil
	end

	local dragOverlay = ParaUI.GetUIObject("CopilotGUIGuide.DragOverlay")
	if dragOverlay:IsValid() then
		dragOverlay.visible = false
	end

	local textTipOverlay = ParaUI.GetUIObject("CopilotGUIGuide.TextTipOverlay")
	if textTipOverlay:IsValid() then
		textTipOverlay.visible = false
	end

	local keyMouseOverlay = ParaUI.GetUIObject("CopilotGUIGuide.KeyMouseOverlay")
	if keyMouseOverlay:IsValid() then
		keyMouseOverlay.visible = false
	end

	CopilotGUIGuide.highlightedButtonName = nil

	-- Stop duration timer
	StopDurationTimer()

	-- Hide cursor
	CopilotGUIGuide.ShowGuideCursor(false)
end

local function StopVisibilityCheck()
	if CopilotGUIGuide.visibilityCheckTimerId then
		CopilotGUIGuide.visibilityCheckTimerId:Change()
		CopilotGUIGuide.visibilityCheckTimerId = nil
	end
	if CopilotGUIGuide.entityTimerId then
		CopilotGUIGuide.entityTimerId:Change()
		CopilotGUIGuide.entityTimerId = nil
	end
	CopilotGUIGuide.highlightedButtonName = nil
	StopDurationTimer()
end

-- Check if the highlighted button is still visible
-- @param uiObjectName: string - the name of the button to check
-- @return boolean: true if the button is visible
function CopilotGUIGuide.IsUIObjectVisible(uiObjectName)
	if not uiObjectName then
		return false
	end

	-- Try ParaUI first
	local obj = ParaUI.GetUIObject(uiObjectName)
	if obj and obj:IsValid() then
		return obj.visible
	end

	-- Try System.Windows Application UI object (mcml v2)
	obj = Application.GetUIObject(uiObjectName)
	if obj then
		local window = obj:GetWindow()
		if window and window:testAttribute("WA_WState_Created") then
			return obj:isVisible()
		end
	end

	return false
end

-- Start periodic visibility check for the highlighted button
local function StartVisibilityCheck(uiObjectName)
	StopVisibilityCheck()
	CopilotGUIGuide.highlightedButtonName = uiObjectName

	CopilotGUIGuide.visibilityCheckTimerId = commonlib.Timer:new({
		callbackFunc = function()
			local x, y, width, height
			local obj = ParaUI.GetUIObject(uiObjectName)
			if obj and obj:IsValid() and obj.visible then
				x, y, width, height = obj:GetAbsPosition()
			else
				obj = Application.GetUIObject(uiObjectName)
				if obj then
					local window = obj:GetWindow()
					if window and window:testAttribute("WA_WState_Created") and obj:isVisible() then
						x, y, width, height = obj:GetAbsPosition()
					end
				end
			end

			if x and y and width and height then
				-- Check if position changed
				local currentX, currentY = CopilotGUIGuide.GetGuideCursorPos()
				local targetX = math.floor(x + width / 2)
				local targetY = math.floor(y + height / 2)

				-- Update position if it moved significantly
				if not currentX or math.abs(currentX - targetX) > 2 or math.abs(currentY - targetY) > 2 then
					CopilotGUIGuide.ShowGuideCursor(true, targetX, targetY, width, height)
				end
			else
				-- Button is no longer visible, hide the highlight
				CopilotGUIGuide.ShowGuideCursor(false)
				StopVisibilityCheck()
			end
		end,
	})
	CopilotGUIGuide.visibilityCheckTimerId:Change(
		CopilotGUIGuide.visibilityCheckInterval,
		CopilotGUIGuide.visibilityCheckInterval
	)
end

-- Guide the user to click a specific UI button by name
-- This will show a highlight cursor at the button position and wait for user click
-- Similar approach to MacroPlayer.SetClickTrigger but with independent rendering
-- @param params: table - {copilot=, buttonName=, duration=, text=}
-- @return boolean: true if button was found and highlight was shown
function CopilotGUIGuide.GuideClickButton(params)
	params = params or {}
	local copilot = params.copilot
	local buttonName = params.buttonName
	local duration = params.duration or 300
	local text = params.text or L("请点击圈圈")

	if not buttonName then
		-- Remove existing highlights by hiding the cursor (similar to MacroPlayer.ShowCursor(false))
		CopilotGUIGuide.ShowGuideCursor(false)
		StopVisibilityCheck()
		return false
	end

	if copilot then
		local ignoreWalk = params.ignoreWalk
		local camerayaw = GameLogic.RunCommand("/camerayaw")
		local camerayaw_opposite = camerayaw + math.pi
		if not ignoreWalk then
			local camerayaw_opposite_left = camerayaw_opposite - math.pi / 2
			local player = GameLogic.EntityManager.GetPlayer()
			local px, py, pz = player:GetPosition()
			local l_x = px + math.cos(camerayaw_opposite_left) * 2
			local l_z = pz - math.sin(camerayaw_opposite_left) * 2
			local l_bx, l_by, l_bz = GameLogic.BlockEngine:block(l_x, py, l_z)
			local bx, by, bz = player:GetBlockPos()
			local dist = copilot.entity:GetDistanceSq(px, py, pz)
			if math.sqrt(dist) > 3 then
				copilot:WalkTo(l_bx, by, l_bz)
			end
		end
		copilot:SetFacing(camerayaw_opposite)
		copilot:Say(text, 10)
		copilot:PlayText(text)
	end

	-- Try to find the button using ParaUI (native UI) first
	local obj = ParaUI.GetUIObject(buttonName)
	local x, y, width, height

	if obj and obj:IsValid() then
		x, y, width, height = obj:GetAbsPosition()
	else
		-- Try System.Windows Application UI object (mcml v2)
		obj = Application.GetUIObject(buttonName)
		if obj then
			local window = obj:GetWindow()
			if window and window:testAttribute("WA_WState_Created") then
				x, y, width, height = obj:GetAbsPosition()
			end
		end
	end

	if not x then
		return false
	end

	-- Calculate center position of the button
	local mouseX = math.floor(x + width / 2)
	local mouseY = math.floor(y + height / 2)

	CopilotGUIGuide.ShowGuideCursor(true, mouseX, mouseY, width, height)

	-- Start periodic check for button visibility
	StartVisibilityCheck(buttonName)

	-- Start duration timer if duration is specified
	if duration and duration > 0 then
		StopDurationTimer()
		CopilotGUIGuide.durationTimerId = commonlib.Timer:new({
			callbackFunc = function()
				CopilotGUIGuide.Stop()
			end,
		})
		CopilotGUIGuide.durationTimerId:Change(duration * 1000, nil)
	end
	return true
end

-- Show or hide the drag guide UI
-- @param bShow: boolean - whether to show
-- @param startX, startY: number - screen coordinates for start position
-- @param endX, endY: number - screen coordinates for end position
-- @param cursorX, cursorY: number - screen coordinates for cursor position
-- @param width, height: number - size of the target object (for circle sizing)
local function ShowDragGuide(bShow, startX, startY, endX, endY, cursorX, cursorY, width, height)
	local overlayName = "CopilotGUIGuide.DragOverlay"
	local _gui = ParaUI.GetUIObject(overlayName)

	if not bShow then
		if _gui:IsValid() then
			_gui.visible = false
		end
		return
	end

	width = width or 64
	height = height or 64
	-- Ensure the circle is at least 64x64, but maintain aspect ratio if larger
	local display_width = math.max(64, width)
	local display_height = math.max(64, height)

	if not _gui:IsValid() then
		_gui = ParaUI.CreateUIObject("container", overlayName, "_fi", 0, 0, 0, 0)
		_gui.background = ""
		_gui.zorder = 10001
		_gui.enabled = false
		_gui:AttachToRoot()

		-- Start Marker (Circle)
		local _start = ParaUI.CreateUIObject("button", "start", "_lt", 0, 0, display_width, display_height)
		_start.background = "Texture/Aries/Common/ThemeTeen/circle_32bits.png" -- Use circle texture
		_start.enabled = false
		_gui:AddChild(_start)

		-- End Marker (Circle)
		local _end = ParaUI.CreateUIObject("button", "end", "_lt", 0, 0, display_width, display_height)
		_end.background = "Texture/Aries/Common/ThemeTeen/circle_32bits.png"
		_end.enabled = false
		_gui:AddChild(_end)

		-- Cursor Icon
		local _cursor = ParaUI.CreateUIObject("button", "cursor", "_lt", 0, 0, 42, 42)
		_cursor.background = "Texture/Aries/Cursor/cursor_big_32bits.png;0 0 42 42"
		_cursor.enabled = false
		_gui:AddChild(_cursor)
	end
	_gui.visible = true

	-- Update Start Marker
	local _start = _gui:GetChild("start")
	if startX and startY then
		_start.visible = true
		_start.x = math.floor(startX - display_width / 2)
		_start.y = math.floor(startY - display_height / 2)
		_start.width = display_width
		_start.height = display_height
	else
		_start.visible = false
	end

	-- Update End Marker
	local _end = _gui:GetChild("end")
	if endX and endY then
		_end.visible = true
		_end.x = math.floor(endX - display_width / 2)
		_end.y = math.floor(endY - display_height / 2)
		_end.width = display_width
		_end.height = display_height
	else
		_end.visible = false
	end

	-- Update Cursor
	local _cursor = _gui:GetChild("cursor")
	if cursorX and cursorY then
		_cursor.visible = true
		-- Match CopilotGUIGuide.ShowGuideCursor offset logic:
		-- Container 32x32 centered at target -> top-left at target-16.
		-- CursorBtn at 12, 15 relative to container -> target-16+12 = target-4, target-16+15 = target-1.
		_cursor.x = math.floor(cursorX - 4)
		_cursor.y = math.floor(cursorY - 1)
	else
		_cursor.visible = false
	end
end

-- Guide the user to drag an entity to a target position
-- @param entityOrName: string or table - entity name or entity object
-- @param targetX, targetY, targetZ: number - target position (block coordinates or real coordinates)
-- @param duration: number - duration in seconds (default 2)
-- @param callback: function - optional callback when done
function CopilotGUIGuide.FindNearbySoil(x, y, z, radius)
	radius = radius or 5
	NPL.load("(gl)script/ide/System/Util/Iterators.lua")
	local Iterators = commonlib.gettable("System.Util.Iterators")

	local soilBlocks = { [13] = true, [55] = true, [279] = true }

	local function HasBlockingEntity(bx, by, bz)
		local entities = GameLogic.EntityManager.GetEntitiesByMinMax(bx, by, bz, bx, by + 2, bz)
		if entities then
			for _, entity in ipairs(entities) do
				if entity:IsPersistent() and entity:IsVisible() then
					return true
				end
			end
		end
		return false
	end

	for dx, dz in Iterators.SpiralSquare(radius) do
		if (dx * dx + dz * dz) > 4 then
			local bx, bz = x + dx, z + dz
			-- check range of y, usually ground level
			for dy = 0, 2 do
				local by = y + dy
				local blockId1 = BlockEngine:GetBlockId(bx, by, bz)
				local blockId = BlockEngine:GetBlockId(bx, by - 1, bz)

				local soilCarpet = blockId1 == 279
				local soilEarth = blockId1 == 0 and blockId ~= 0 and soilBlocks[blockId]

				if soilCarpet then
					-- Carpet is at 'by', so we want to plant above it: by + 1
					if not HasBlockingEntity(bx, by + 1, bz) then
						LOG.std(nil, "info", "CopilotGUIGuide", "FindNearbySoil found carpet at %d %d %d", bx, by, bz)
						return bx, by + 1, bz
					end
				elseif soilEarth then
					-- Soil is at 'by - 1', so we want to plant at 'by' (air above soil)
					if not HasBlockingEntity(bx, by, bz) then
						LOG.std(
							nil,
							"info",
							"CopilotGUIGuide",
							"FindNearbySoil found earth at %d %d %d",
							bx,
							by - 1,
							bz
						)
						return bx, by, bz
					end
				end
			end
		end
	end
	LOG.std(nil, "warn", "CopilotGUIGuide", "FindNearbySoil found nothing")
	return nil
end

-- Guide the user to drag an entity to a target position
-- @param params: table - {copilot=, entityOrName=, targetX=, targetY=, targetZ=, duration=, callback=, width=, height=, text=}
function CopilotGUIGuide.GuideDragEntity(params)
	params = params or {}
	local entityOrName = params.entityOrName
	local targetX = params.targetX
	local targetY = params.targetY
	local targetZ = params.targetZ
	local duration = params.duration
	local callback = params.callback
	local width = params.width
	local height = params.height
	local copilot = params.copilot
	local text = params.text or L("请拖动物体到目标位置")

	if not entityOrName then
		CopilotGUIGuide.Stop()
		if callback then
			callback(false)
		end
		return false
	end

	if copilot then
		local ignoreWalk = params.ignoreWalk
		local camerayaw = GameLogic.RunCommand("/camerayaw")
		local camerayaw_opposite = camerayaw + math.pi
		if not ignoreWalk then
			local camerayaw_opposite_left = camerayaw_opposite - math.pi / 2
			local player = GameLogic.EntityManager.GetPlayer()
			local px, py, pz = player:GetPosition()
			local l_x = px + math.cos(camerayaw_opposite_left) * 2
			local l_z = pz - math.sin(camerayaw_opposite_left) * 2
			local l_bx, l_by, l_bz = GameLogic.BlockEngine:block(l_x, py, l_z)
			local bx, by, bz = player:GetBlockPos()
			local dist = copilot.entity:GetDistanceSq(px, py, pz)
			if math.sqrt(dist) > 3 then
				copilot:WalkTo(l_bx, by, l_bz)
			end
		end
		copilot:SetFacing(camerayaw_opposite)
		copilot:Say(text, 10)
		copilot:PlayText(text)
	end

	CopilotGUIGuide.Stop()

	local entity = entityOrName
	local is3D = true
	local startX, startY, startZ
	local ui_width, ui_height

	if type(entity) == "string" then
		local name = entity
		entity = EntityManager.GetEntity(name)

		if not entity then
			local entityKeys = params.entityKeys
			if not entityKeys or #entityKeys == 0 then
				if callback then
					callback(false)
				end
				LOG.std(nil, "error", "CopilotGUIGuide", "entityKeys is nil or empty, name: %s", name)
				return
			end
			local allEntities = GameLogic.EntityManager.GetAllEntities()
			for _, _entity in pairs(allEntities) do
				local find = false
				if _entity:isa(GameLogic.EntityManager.EntityLiveModel) then
					local isMatch = true
					if entityKeys then
						for _, item in ipairs(entityKeys) do
							local key = item.key
							local value = item.value
							local val = _entity:GetTagField(key)
							if value == "nil or empty" then
								if val ~= nil and val ~= "" then
									isMatch = false
									break
								end
							else
								if val ~= value then
									isMatch = false
									break
								end
							end
						end
					end

					if isMatch then
						find = true
					end
				end
				if find then
					entity = _entity
					break
				end
			end
		end

		if not entity then
			-- Try to find the button using ParaUI (native UI) first
			local obj = ParaUI.GetUIObject(name)
			local x, y, w, h

			if obj and obj:IsValid() then
				x, y, w, h = obj:GetAbsPosition()
			else
				-- Try System.Windows Application UI object (mcml v2)
				obj = Application.GetUIObject(name)
				if obj then
					local window = obj:GetWindow()
					if window and window:testAttribute("WA_WState_Created") then
						x, y, w, h = obj:GetAbsPosition()
					else
						obj = nil
					end
				end
			end

			if obj and x then
				entity = obj
				is3D = false
				startX = x + w / 2
				startY = y + h / 2
				startZ = 0
				ui_width = w
				ui_height = h
			end
		end
	end

	if not entity then
		if callback then
			callback(false)
		end
		return
	end

	if is3D then
		startX, startY, startZ = entity:GetPosition()
	end

	-- Use passed width/height if available, else use detected UI size or default
	width = width or ui_width or 64
	height = height or ui_height or 64

	duration = duration or 10
	if duration <= 0 then
		duration = 0.1
	end -- Prevent division by zero
	-- convert to ms
	local durationMs = duration * 1000

	local start_bx, start_by, start_bz = entity:GetBlockPos()

	if not (targetX and targetY and targetZ) then
		local end_bx, end_by, end_bz = CopilotGUIGuide.FindNearbySoil(start_bx, start_by, start_bz, 10)
		if end_bx and end_by and end_bz then
			targetX, targetY, targetZ = GameLogic.BlockEngine:real_bottom(end_bx, end_by, end_bz)
		end
	end

	targetX = targetX or startX
	targetY = targetY or startY
	targetZ = targetZ or startZ

	LOG.std(
		nil,
		"info",
		"CopilotGUIGuide",
		"GuideDragEntity start: %.2f, %.2f, %.2f target: %.2f, %.2f, %.2f duration: %.2f width: %d height: %d",
		startX,
		startY,
		startZ,
		targetX,
		targetY,
		targetZ,
		duration,
		width,
		height
	)

	-- Ensure previous guide is hidden before starting new one (Stop() already does this but ShowDragGuide also handles it)
	ShowDragGuide(false)

	local startTime = commonlib.TimerManager.GetCurrentTime()
	local screen_pos = {}

	CopilotGUIGuide.dragTimerId = commonlib.Timer:new({
		callbackFunc = function(timer)
			local curTime = commonlib.TimerManager.GetCurrentTime()
			local elapsed = curTime - startTime

			-- Loop animation: 0 -> 1 over durationMs
			local percent = (elapsed % durationMs) / durationMs

			local x = startX + (targetX - startX) * percent
			local y = startY + (targetY - startY) * percent
			local z = startZ + (targetZ - startZ) * percent

			local sx, sy
			local startScreenX, startScreenY
			local endScreenX, endScreenY
			local cursorScreenX, cursorScreenY

			-- Calculate Start Marker Screen Pos
			if is3D then
				screen_pos.x = -9999
				screen_pos.y = -9999
				if ParaScene.GetScreenPosFrom3DPoint(startX, startY, startZ, screen_pos) and screen_pos.x ~= -9999 then
					startScreenX, startScreenY = screen_pos.x, screen_pos.y
				end
			else
				startScreenX, startScreenY = startX, startY
			end

			-- Calculate End Marker Screen Pos
			if is3D then
				screen_pos.x = -9999
				screen_pos.y = -9999
				if
					ParaScene.GetScreenPosFrom3DPoint(targetX, targetY, targetZ, screen_pos)
					and screen_pos.x ~= -9999
				then
					endScreenX, endScreenY = screen_pos.x, screen_pos.y
				end
			else
				endScreenX, endScreenY = targetX, targetY
			end

			-- Calculate Cursor Screen Pos
			if is3D then
				screen_pos.x = -9999
				screen_pos.y = -9999
				if ParaScene.GetScreenPosFrom3DPoint(x, y, z, screen_pos) and screen_pos.x ~= -9999 then
					cursorScreenX, cursorScreenY = screen_pos.x, screen_pos.y
				end
			else
				cursorScreenX, cursorScreenY = x, y
			end

			-- Update UI via helper
			ShowDragGuide(
				true,
				startScreenX,
				startScreenY,
				endScreenX,
				endScreenY,
				cursorScreenX,
				cursorScreenY,
				width,
				height
			)
		end,
	})
	CopilotGUIGuide.dragTimerId:Change(0, 30)

	return entity, targetX, targetY, targetZ
end

-- Guide the user to click a sequence of buttons by names
-- It will periodically update buttons to highlight, always searching in reverse order in the buttonNames array.
-- The first visible button found (from the end) will be highlighted.
-- It will try for at least 5 seconds if no button is found and then stop trying.
-- @param buttonNames: table - array of button names to click in sequence
-- @param duration: number - optional duration in seconds for the entire guide session, if duration is -1, then it will run indefinitely
-- Note: The logic "when player clicks all buttons" is interpreted here as "when the last button in the sequence has been shown and then disappeared/clicked".
function CopilotGUIGuide.GuideClickButtons(buttonNames, duration)
	duration = duration or 300

	if not buttonNames or #buttonNames == 0 then
		CopilotGUIGuide.Stop()
		return false
	end

	local updateInterval = 500 -- ms between update checks
	local noButtonFoundTime = 0 -- track time when no button is found
	local maxNoButtonTime = 5000 -- 5 seconds max when no button found
	local currentHighlightedButton = nil
	local lastButtonIndex = 0 -- Track the index of the button currently being highlighted
	local highestButtonIndexReached = 0 -- Track the furthest step reached
	local lastSwitchTime = 0
	local minStayTime = 1500 -- Minimum time to stay on a button if it is still visible

	-- Function to find the first visible button from the array
	local function FindVisibleButton()
		for i = lastButtonIndex + 1, #buttonNames do
			local buttonName = buttonNames[i]
			if buttonName and CopilotGUIGuide.IsUIObjectVisible(buttonName) then
				return buttonName, i
			end
		end
		for i = lastButtonIndex, 1, -1 do
			local buttonName = buttonNames[i]
			if buttonName and CopilotGUIGuide.IsUIObjectVisible(buttonName) then
				return buttonName, i
			end
		end
		return nil, 0
	end

	-- Function to update the highlight
	local function UpdateHighlight()
		local visibleButton, index = FindVisibleButton()

		if visibleButton then
			noButtonFoundTime = 0
			if visibleButton ~= currentHighlightedButton then
				local canSwitch = true
				local currentTime = commonlib.TimerManager.GetCurrentTime()

				-- If we are moving forward and currently highlighted button is still visible, check min stay time
				if currentHighlightedButton and index > lastButtonIndex then
					if CopilotGUIGuide.IsUIObjectVisible(currentHighlightedButton) then
						if (currentTime - lastSwitchTime) < minStayTime then
							canSwitch = false
						end
					end
				end

				if canSwitch then
					currentHighlightedButton = visibleButton
					lastButtonIndex = index
					lastSwitchTime = currentTime
					if index > highestButtonIndexReached then
						highestButtonIndexReached = index
					end
					CopilotGUIGuide.GuideClickButton({ buttonName = visibleButton, duration = 0 })
				end
			end
			return true
		else
			if highestButtonIndexReached == #buttonNames then
				CopilotGUIGuide.Stop()
				return false
			end

			-- No button found, hide cursor if we had one highlighted
			if currentHighlightedButton then
				CopilotGUIGuide.ShowGuideCursor(false)
				currentHighlightedButton = nil
			end
			return false
		end
	end

	-- Stop existing timer if any
	if CopilotGUIGuide.buttonsTimerId then
		CopilotGUIGuide.buttonsTimerId:Change()
		CopilotGUIGuide.buttonsTimerId = nil
	end

	-- Try immediately first
	local foundInitially = UpdateHighlight()

	-- Start periodic update timer
	CopilotGUIGuide.buttonsTimerId = commonlib.Timer:new({
		callbackFunc = function()
			local found = UpdateHighlight()

			if not found then
				-- If we haven't finished the sequence (checked inside UpdateHighlight), count timeout
				if not (highestButtonIndexReached == #buttonNames) then
					noButtonFoundTime = noButtonFoundTime + updateInterval
					if noButtonFoundTime >= maxNoButtonTime then
						-- No button found for too long, stop trying
						CopilotGUIGuide.Stop()
					end
				end
			end
		end,
	})
	CopilotGUIGuide.buttonsTimerId:Change(updateInterval, updateInterval)

	-- Set up duration timer to stop everything after duration expires
	if duration and duration > 0 then
		StopDurationTimer()
		CopilotGUIGuide.durationTimerId = commonlib.Timer:new({
			callbackFunc = function()
				CopilotGUIGuide.Stop()
			end,
		})
		CopilotGUIGuide.durationTimerId:Change(duration * 1000, nil)
	end

	return foundInitially
end

-- Find an entity by its action name (using ActionNameDetector)
function CopilotGUIGuide.FindEntityByActionName(actionName)
	if not ActionNameDetector or not actionName then
		return
	end
	local player = EntityManager.GetFocus()
	if not player then
		return
	end

	local nearby = ActionNameDetector:FindNearbyInteractableEntities(player)
	if nearby then
		for _, result in ipairs(nearby) do
			-- Check for exact match or if actionName is part of the string
			if
				result.actionName == actionName or (result.actionName and result.actionName:find(actionName, 1, true))
			then
				return result.entity, result.actionIndex
			end
		end
	end
	return nil
end

-- Guide the user to click a specific 3D entity
-- @param params: table - {copilot=, entity=, duration=, offset_y=, actionIndex=, text=}
function CopilotGUIGuide.GuideClickEntity(params)
	params = params or {}
	local copilot = params.copilot
	local entity = params.entity

	if not entity then
		CopilotGUIGuide.ShowGuideCursor(false)
		StopVisibilityCheck()
		return false
	end

	local duration = params.duration or 300
	local offset_y = params.offset_y
	local actionIndex = params.actionIndex
	local text = params.text or L("请点击圈圈")

	-- Resolve entity
	local targetEntity = entity
	if type(entity) == "string" then
		targetEntity, actionIndex = CopilotGUIGuide.FindEntityByActionName(entity)
	end

	if not targetEntity or not targetEntity:IsValid() then
		return false
	end

	if copilot then
		local ignoreWalk = params.ignoreWalk
		local camerayaw = GameLogic.RunCommand("/camerayaw")
		local camerayaw_opposite = camerayaw + math.pi
		if not ignoreWalk then
			local camerayaw_opposite_left = camerayaw_opposite - math.pi / 2
			local player = GameLogic.EntityManager.GetPlayer()
			local px, py, pz = player:GetPosition()
			local l_x = px + math.cos(camerayaw_opposite_left) * 2
			local l_z = pz - math.sin(camerayaw_opposite_left) * 2
			local l_bx, l_by, l_bz = GameLogic.BlockEngine:block(l_x, py, l_z)
			local bx, by, bz = player:GetBlockPos()
			local dist = copilot.entity:GetDistanceSq(px, py, pz)
			if math.sqrt(dist) > 3 then
				copilot:WalkTo(l_bx, by, l_bz)
			end
		end
		copilot:SetFacing(camerayaw_opposite)
		copilot:Say(text, 10)
		copilot:PlayText(text)
	end

	-- Stop other checks
	StopVisibilityCheck()
	if CopilotGUIGuide.buttonsTimerId then
		CopilotGUIGuide.buttonsTimerId:Change()
		CopilotGUIGuide.buttonsTimerId = nil
	end

	local updateInterval = 30 -- ms, smooth update

	-- Cached screen pos table
	local screen_pos = {}

	local function UpdateEntityPosition()
		if not targetEntity or not targetEntity:IsValid() then
			CopilotGUIGuide.ShowGuideCursor(false)
			StopVisibilityCheck()
			return
		end

		local ex, ey, ez
		if actionIndex then
			ex, ey, ez = targetEntity:GetActionPoint(actionIndex)
			ey = ey - 0.5
		end
		if not ex then
			ex, ey, ez = targetEntity:GetPosition()
			local entityHeight = targetEntity:GetHeight() or 1.0
			-- Default offset to center of entity (height/2) if not provided
			local y_offset = -0.5 -- offset_y or (entityHeight * 0.5);
			ey = ey + y_offset
		end

		screen_pos.x = -9999
		screen_pos.y = -9999

		local result = ParaScene.GetScreenPosFrom3DPoint(ex, ey, ez, screen_pos)

		local screenX = screen_pos.x
		local screenY = screen_pos.y

		-- Check if visible and in front of camera
		if result and screenX ~= -9999 then
			-- Use a default size for the entity "hitbox" for the cursor circle
			local size = 64
			CopilotGUIGuide.ShowGuideCursor(true, screenX, screenY, size, size)
		else
			CopilotGUIGuide.ShowGuideCursor(false)
		end
	end

	-- Initial update
	UpdateEntityPosition()

	-- Start timer
	CopilotGUIGuide.entityTimerId = commonlib.Timer:new({
		callbackFunc = function()
			UpdateEntityPosition()
		end,
	})
	CopilotGUIGuide.entityTimerId:Change(updateInterval, updateInterval)

	-- Duration timer
	if duration and duration > 0 then
		StopDurationTimer()
		CopilotGUIGuide.durationTimerId = commonlib.Timer:new({
			callbackFunc = function()
				CopilotGUIGuide.ShowGuideCursor(false)
				StopVisibilityCheck()
				if CopilotGUIGuide.buttonsTimerId then
					CopilotGUIGuide.buttonsTimerId:Change()
					CopilotGUIGuide.buttonsTimerId = nil
				end
			end,
		})
		CopilotGUIGuide.durationTimerId:Change(duration * 1000, nil)
	end

	return true
end
