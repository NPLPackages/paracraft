--[[
Title: Macro Key Press
Author(s): LiXizhi
Date: 2021/1/4
Desc: a macro for key(s) press. 

Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Macros.lua");
-------------------------------------------------------
]]
local KeyEvent = commonlib.gettable("System.Windows.KeyEvent");
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros")

-- @param event: key press event object
-- @return string like "ctrl+DIK_C", ""
function Macros.GetButtonTextFromKeyEvent(event)
	local buttons = event.keyname or "";
	if(event.ctrl_pressed) then
		buttons = "ctrl+"..buttons;
	end
	if(event.alt_pressed) then
		buttons = "alt+"..buttons;
	end
	if(event.shift_pressed) then
		buttons = "shift+"..buttons;
	end
	return buttons;
end

local function SetKeyEventFromButtonText(event, button)
	-- mouse_button is a global variable
	event.isEmulated= true;
	event.keyname = button:match("(DIK_%w+)");
	event.shift_pressed = button:match("shift") and true 
	event.alt_pressed = button:match("alt") and true
	event.ctrl_pressed = button:match("ctrl") and true
	event.key_sequence = event:GetKeySequence();
end

--@param button: string like "C" or "ctrl+C"
function Macros.KeyPress(button)
	local event = KeyEvent:init("keyPressEvent")
	SetKeyEventFromButtonText(event, button)
	local ctx = GameLogic.GetSceneContext()
	ctx:keyPressEvent(event);
end





