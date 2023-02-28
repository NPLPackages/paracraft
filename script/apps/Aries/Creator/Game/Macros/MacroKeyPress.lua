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
local MacroPlayer = commonlib.gettable("MyCompany.Aries.Game.Tasks.MacroPlayer");
local Application = commonlib.gettable("System.Windows.Application");
local MouseEvent = commonlib.gettable("System.Windows.MouseEvent");
local Keyboard = commonlib.gettable("System.Windows.Keyboard");
local KeyEvent = commonlib.gettable("System.Windows.KeyEvent");
local InputMethodEvent = commonlib.gettable("System.Windows.InputMethodEvent");
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros");

local ConvertToWebMode = NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/ConvertToWebMode/ConvertToWebMode.lua");

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

-- @param buttons: nil or a string to append button text. 
-- @return string like "ctrl+shift", ""
function Macros.GetButtonTextFromKeyboard(buttons)
	buttons = buttons or "";
	if(Keyboard:IsCtrlKeyPressed()) then
		buttons = "ctrl+"..buttons;
	end
	if(Keyboard:IsAltKeyPressed()) then
		buttons = "alt+"..buttons;
	end
	if(Keyboard:IsShiftKeyPressed()) then
		buttons = "shift+"..buttons;
	end
	buttons = buttons:gsub("%+$", "")
	return buttons;
end


local function SetKeyEventFromButtonText(event, button)
	-- mouse_button is a global variable
	event.isEmulated= true;
	if(button == "DIK_ADD") then
		button = "shift+DIK_EQUALS";
	elseif(button == "DIK_SUBSTRACT") then
		button = "DIK_MINUS";
	end
	event.keyname = button:match("(DIK_[%w_]+)");
	event.shift_pressed = button:match("shift") and true 
	event.alt_pressed = button:match("alt") and true
	event.ctrl_pressed = button:match("ctrl") and true
	event.key_sequence = event:GetKeySequence();
end

local nextKeyPressMouseX, nextKeyPressMouseY;


function Macros.GetNextKeyPressWithMouseMove()
	return nextKeyPressMouseX, nextKeyPressMouseY
end
function Macros.SetNextKeyPressWithMouseMove(mouseX, mouseY)
	nextKeyPressMouseX, nextKeyPressMouseY = mouseX, mouseY
end

-- this macro will force the next key stroke to have a given mouse position. 
-- such as some ctrl+C and ctrl+v operations in the scene. 
function Macros.NextKeyPressWithMouseMove(angleX, angleY)
	nextKeyPressMouseX, nextKeyPressMouseY = Macros.MouseAngleToScreenPos(angleX, angleY);
end

local function AdjustMousePosition_()
	if(nextKeyPressMouseX and nextKeyPressMouseY) then
		-- mouse_x, mouse_y, mouse_button are global variables
		mouse_x, mouse_y = nextKeyPressMouseX, nextKeyPressMouseY;
		ParaUI.SetMousePosition(mouse_x, mouse_y);
		nextKeyPressMouseX, nextKeyPressMouseY = nil, nil;
	end
end

--@param button: string like "C" or "ctrl+C"
function Macros.KeyPress(button)
	AdjustMousePosition_();

	local event = KeyEvent:init("keyPressEvent")
	SetKeyEventFromButtonText(event, button)
	local ctx = GameLogic.GetSceneContext()
	ctx:handleKeyEvent(event);

	MacroPlayer.Focus();
end

-- System.Window's key down event
function Macros.WindowKeyPress(ctrlName, button)
	local obj = Application.GetUIObject(ctrlName);
	if(obj) then
		local window = obj:GetWindow()
		if(window and window:testAttribute("WA_WState_Created")) then
			window.isEmulatedFocus = true;
			window:handleActivateEvent(true)
			window.isEmulatedFocus = nil;

			local event = KeyEvent:init("keyPressEvent")
			SetKeyEventFromButtonText(event, button)

			window:HandlePagePressKeyEvent(event);
			if(not event:isAccepted()) then
				Application:sendEvent(window:focusWidget(), event);
			end
			
			MacroPlayer.Focus();
		end
	end
end

-- System.Window's input method event
function Macros.WindowInputMethod(ctrlName, commitString)
	local obj = Application.GetUIObject(ctrlName);
	if(obj) then
		local window = obj:GetWindow()
		if(window and window:testAttribute("WA_WState_Created")) then
			window.isEmulatedFocus = true;
			window:handleActivateEvent(true)
			window.isEmulatedFocus = nil;

			local event = InputMethodEvent:new():init(commitString);
			Application:sendEvent(window:focusWidget(), event);

			MacroPlayer.Focus();
		end
	end
end


--@param button: string like "C" or "ctrl+C"
function Macros.KeyPressTrigger(button)
	if (button and button ~= "") then
		local callback = {};

		if (Macros.GetHelpLevel() == -2) then
			ConvertToWebMode:StopComputeRecordTime();

			local macro = Macros.macros[Macros.curLine];

			if (macro) then
				macro.processTime = ConvertToWebMode.processTime;
			end
        end

		MacroPlayer.SetKeyPressTrigger(button, nil, function()
			if (callback.OnFinish) then
				if (Macros.GetHelpLevel() == -2) then
					local nextNextLine = Macros.macros[Macros.curLine + 2];

					if (nextNextLine and
						nextNextLine.name ~= "Broadcast" and
						nextNextLine.params ~= "macroFinished") then
						commonlib.TimerManager.SetTimeout(function()
							ConvertToWebMode:StopCapture();

							MacroPlayer.ShowKeyboard(true, button);

							if (MacroPlayer.page.keyboardWnd and
								MacroPlayer.page.keyboardWnd.keylayout) then
								for key, item in ipairs(MacroPlayer.page.keyboardWnd.keylayout) do
									for keyI, itemI in ipairs(item) do
										if (itemI and
										    type(itemI) == "table" and
										    itemI.name) then
											local keyName;
											
											if (itemI.char) then
												keyName = Macros.TextToKeyName(itemI.char);
											end

											if (not keyName) then
												local keyUpperName = itemI.name:upper();

												if (keyUpperName == "TAB") then
													keyName = "DIK_TAB";
												elseif (keyUpperName == "ENTER") then
													keyName = "DIK_RETURN";
												end
											end
	
											if (keyName == button) then
												local macro = Macros.macros[Macros.curLine];

												if (macro) then
													macro.mousePosition = {
														posX = itemI.pos_x,
														posY = itemI.pos_y
													};
												end

												break;
											end
										end
									end
								end
							end

							MacroPlayer.ShowKeyboard(false);

							ConvertToWebMode:StartComputeRecordTime();
							ConvertToWebMode:BeginCapture(function()
								callback.OnFinish();
							end);
						end, 3000);
					else
						callback.OnFinish();
					end
				else
					callback.OnFinish();
				end
			end
		end);

		return callback;
	end
end

function Macros.WindowKeyPressTrigger(ctrlName, button)
	if (button and button ~= "") then
		-- get final text in editbox
		local nOffset = 0;
		local targetText = "";

		while (true) do
			nOffset = nOffset + 1;
			local nextMacro = Macros:PeekNextMacro(nOffset);

			if (nextMacro and
			    (nextMacro.name == "Idle" or
				 nextMacro.name == "WindowKeyPressTrigger" or
				 nextMacro.name == "WindowInputMethod" or
				 nextMacro.name == "WindowKeyPress")) then
				if (nextMacro.name ~= "Idle") then
					local nextUIName = nextMacro:GetParams()[1];

					if (nextUIName == ctrlName) then
						if (nextMacro.name == "WindowKeyPress") then
							local text = nextMacro:GetParams()[2];

							if (not text or not Macros.IsButtonLetter(text)) then
								break;
							end
						elseif (nextMacro.name == "WindowInputMethod") then
							local text = nextMacro:GetParams()[2];

							if (text) then
								targetText = targetText..text;
							else
								break;
							end
						end
					else
						break;
					end
				end
			else
				break;
			end
		end

		if (targetText and targetText ~= "") then
			local nOffset = 0;

			while (true) do
				nOffset = nOffset - 1;
				local nextMacro = Macros:PeekNextMacro(nOffset);

				if (nextMacro and
					(nextMacro.name == "Idle" or
					 nextMacro.name == "WindowKeyPressTrigger" or
					 nextMacro.name == "WindowInputMethod" or
					 nextMacro.name == "WindowKeyPress")) then
					if (nextMacro.name ~= "Idle") then
						local nextUIName = nextMacro:GetParams()[1];

						if (nextUIName == ctrlName) then
							if (nextMacro.name == "WindowKeyPress") then
								local text = nextMacro:GetParams()[2];

								if (not text or not Macros.IsButtonLetter(text)) then
									break;
								end
							elseif (nextMacro.name == "WindowInputMethod") then
								local text = nextMacro:GetParams()[2];

								if (text) then
									targetText = text..targetText;
								else
									break;
								end
							end
						else
							break;
						end
					end
				else
					break;
				end
			end
		end

		if (Macros.GetHelpLevel() == -2) then
			ConvertToWebMode:StopComputeRecordTime();

			local macro = Macros.macros[Macros.curLine];

			if (macro) then
				macro.processTime = ConvertToWebMode.processTime;
			end
        end

		local callback = {};

		MacroPlayer.SetKeyPressTrigger(button, targetText, function()
			if (callback.OnFinish) then
				if (Macros.GetHelpLevel() == -2) then
					local nextNextLine = Macros.macros[Macros.curLine + 2];

					if (nextNextLine and
						nextNextLine.name ~= "Broadcast" and
						nextNextLine.params ~= "macroFinished") then
						commonlib.TimerManager.SetTimeout(function()
							ConvertToWebMode:StopCapture();

							MacroPlayer.ShowKeyboard(true, button);

							if (MacroPlayer.page.keyboardWnd and
								MacroPlayer.page.keyboardWnd.keylayout) then
								for key, item in ipairs(MacroPlayer.page.keyboardWnd.keylayout) do
									for keyI, itemI in ipairs(item) do
										if (itemI and
										    type(itemI) == "table" and
										    itemI.name) then
											local keyName;
											
											if (itemI.char) then
												keyName = Macros.TextToKeyName(itemI.char);
											end

											if (not keyName) then
												local keyUpperName = itemI.name:upper();

												if (keyUpperName == "TAB") then
													keyName = "DIK_TAB";
												elseif (keyUpperName == "ENTER") then
													keyName = "DIK_RETURN";
												end
											end
	
											if (keyName == button) then
												local macro = Macros.macros[Macros.curLine];

												if (macro) then
													macro.mousePosition = {
														posX = itemI.pos_x,
														posY = itemI.pos_y
													};
												end

												break;
											end
										end
									end
								end
							end

							MacroPlayer.ShowKeyboard(false);

							ConvertToWebMode:StartComputeRecordTime();
							ConvertToWebMode:BeginCapture(function()
								callback.OnFinish();
							end);
						end, 3000);
					else
						callback.OnFinish();
					end
				else 
					callback.OnFinish();
				end
			end
		end);

		return callback;
	end
end

function Macros.SetClipboard(text)
	ParaMisc.CopyTextToClipboard(text);
end


