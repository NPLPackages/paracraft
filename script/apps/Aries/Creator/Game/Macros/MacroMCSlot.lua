--[[
Title: Macro for pe_mc_slot drag target
Author(s): LiXizhi
Date: 2021/1/16
Desc: 

Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/Macros.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroPlayer.lua");
local MacroPlayer = commonlib.gettable("MyCompany.Aries.Game.Tasks.MacroPlayer");
local Keyboard = commonlib.gettable("System.Windows.Keyboard");
local MouseEvent = commonlib.gettable("System.Windows.MouseEvent");
local pe_mc_slot = commonlib.gettable("MyCompany.Aries.Game.mcml.pe_mc_slot");
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros")


function Macros.MCSlotDragTarget(targetName, button)
	local obj = ParaUI.GetUIObject(targetName)
	if(obj and obj:IsValid()) then
		local x, y, width, height = obj:GetAbsPosition();
		local mouseX = math.floor(x + width /2)
		local mouseY = math.floor(y + height /2)

		if(button:match("left")) then
			mouse_button = "left"
		elseif(button:match("right")) then
			mouse_button = "right"
		else
			mouse_button = "middle"
		end
		pe_mc_slot.OnClickDragCanvas(mouseX, mouseY, mouse_button)
	end
end

function Macros.MCSlotDragTargetTrigger(targetName, button)
	local obj = ParaUI.GetUIObject(targetName)
	if(obj and obj:IsValid()) then
		local x, y, width, height = obj:GetAbsPosition();
		local mouseX = math.floor(x + width /2)
		local mouseY = math.floor(y + height /2)

		local callback = {};
		MacroPlayer.SetClickTrigger(mouseX, mouseY, button, function()
			if(callback.OnFinish) then
				callback.OnFinish();
			end
		end);
		return callback;
	end
end

