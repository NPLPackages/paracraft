--[[
Title: Macro Button Click
Author(s): LiXizhi
Date: 2021/1/4
Desc: a macro for the clicking of a named button in GUI. 

Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Macro.lua");
local Macro = commonlib.gettable("MyCompany.Aries.Game.Macro");
-------------------------------------------------------
]]
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local MacroPlayer = commonlib.gettable("MyCompany.Aries.Game.Tasks.MacroPlayer");
local Application = commonlib.gettable("System.Windows.Application");
local Keyboard = commonlib.gettable("System.Windows.Keyboard");
local MouseEvent = commonlib.gettable("System.Windows.MouseEvent");
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros")

local function SetKeyboardFromButtonText(emulatedKeys, button)
	-- mouse_button is a global variable
	emulatedKeys.shift_pressed = button and button:match("shift") and true 
	emulatedKeys.alt_pressed = button and button:match("alt") and true
	emulatedKeys.ctrl_pressed = button and button:match("ctrl") and true
end

-- native ParaUIObject's onclick event
--@param btnName: button name
--@param button: "left", "right", "shift+left"
--@param eventname: nil or "onmouseup" or "onclick"
function Macros.ButtonClick(btnName, button, eventname)
	local obj = ParaUI.GetUIObject(btnName)
	if(obj and obj:IsValid()) then
		if(button:match("left")) then
			mouse_button = "left"
		elseif(button:match("right")) then
			mouse_button = "right"
		else
			mouse_button = "middle"
		end
		local emulatedKeys = Keyboard:GetEmulatedKeys()
		SetKeyboardFromButtonText(emulatedKeys, button)

		-- tricky: process special buttons 
		if(btnName == "MovieClipController.play") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieManager.lua");
			local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");
			local movieClip = MovieManager:GetActiveMovieClip()
			if(movieClip) then
				local focusEntity = EntityManager.GetFocus();
				if(focusEntity) then
					focusEntity:SetFocus();
					local obj = focusEntity:GetInnerObject();
					if(obj and obj.ToCharacter) then
						obj:ToCharacter():SetFocus();
					end
				end
			end
		end

		-- trickly: id is a global variable for _guihelper.GetLastUIObjectPos()
		id = obj.id; 
		__onuievent__(id, eventname or "onclick");

		SetKeyboardFromButtonText(emulatedKeys, "")
	end
end


function Macros.ContainerDragEnd(btnName, offsetX, offsetY)
	local obj = ParaUI.GetUIObject(btnName)
	if(obj and obj:IsValid()) then
		local x, y = obj:GetAbsPosition();
		mouse_x, mouse_y = x + offsetX, y + offsetY
		ParaUI.SetMousePosition(mouse_x, mouse_y);

		-- trickly: id is a global variable for _guihelper.GetLastUIObjectPos()
		id = obj.id; 
		__onuievent__(id, "ondragend");
	end
end


function Macros.ContainerMouseWheel(btnName, mouseWheel)
	local obj = ParaUI.GetUIObject(btnName)
	if(obj and obj:IsValid()) then
		mouse_wheel = mouseWheel
		id = obj.id; 
		__onuievent__(id, "onmousewheel");
	end
end

local function SetMouseEventFromButtonText(event, button)
	-- mouse_button is a global variable
	event.isEmulated= true;
	event.shift_pressed = button and button:match("shift") and true 
	event.alt_pressed = button and button:match("alt") and true
	event.ctrl_pressed = button and button:match("ctrl") and true
	if(button and button:match("left") ) then
		event.buttons_state = 1;
		event.mouse_button = "left"
	elseif(button and button:match("right") ) then
		event.buttons_state = 2;
		event.mouse_button = "right"
	elseif(button and button:match("middle") ) then
		event.buttons_state = 0;
		event.mouse_button = "middle"
	else
		event.buttons_state = 0;
	end
end

-- System.Window's click event
-- @param localX, localY: local mouse click position relative to the control
function Macros.WindowClick(btnName, button, localX, localY)
	local obj = Application.GetUIObject(btnName);
	if(obj) then
		local window = obj:GetWindow()
		if(window and window:testAttribute("WA_WState_Created")) then
			local x, y, width, height = obj:GetAbsPosition()
			
			if( not localX or (localX + 6) > width) then
				localX = math.floor(width/2+0.5)
			end

			if( not localY or (localY + 6) > height) then
				localY =  math.floor(height/2+0.5)
			end

			-- mouse_x, mouse_y, mouse_button are global variables
			mouse_x, mouse_y, mouse_button = x + localX, y + localY, button
			
			ParaUI.SetMousePosition(mouse_x, mouse_y);

			local emulatedKeys = Keyboard:GetEmulatedKeys()
			SetKeyboardFromButtonText(emulatedKeys, button)

			local event = MouseEvent:init("mousePressEvent", window)
			SetMouseEventFromButtonText(event, button)
			window:handleMouseEvent(event);

			local event = MouseEvent:init("mouseReleaseEvent", window)
			SetMouseEventFromButtonText(event, button)
			window:handleMouseEvent(event);

			window.isEmulatedFocus = true;
			window:handleActivateEvent(true)
			window.isEmulatedFocus = nil;

			SetKeyboardFromButtonText(emulatedKeys, "")
		end
	end
end

-- native ParaUIObject's onclick event
--@param btnName: button name
--@param button: "left", "right", default to "left"
function Macros.ButtonClickTrigger(btnName, button, eventName)
	local obj = ParaUI.GetUIObject(btnName)
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

function Macros.ContainerDragEndTrigger(btnName, offsetX, offsetY)
	local obj = ParaUI.GetUIObject(btnName)
	if(obj and obj:IsValid()) then
		local x, y, width, height = obj:GetAbsPosition();
		local startX = math.floor(x + width / 2 + 0.5)
		local startY = math.floor(y + height / 2 + 0.5)
		local endX, endY = x + offsetX, y + offsetY

		local callback = {};
		MacroPlayer.SetDragTrigger(startX, startY, endX, endY, "left", function()
			if(callback.OnFinish) then
				callback.OnFinish();
			end
		end);
		return callback;
	end
end

function Macros.ContainerMouseWheelTrigger(btnName, mouseWheel)
	local obj = ParaUI.GetUIObject(btnName)
	if(obj and obj:IsValid()) then
		local x, y, width, height = obj:GetAbsPosition();
		local mouseX = math.floor(x + width /2)
		local mouseY = math.floor(y + height /2)
		local callback = {};
		MacroPlayer.SetMouseWheelTrigger(mouseWheel, mouseX, mouseY, function()
			if(callback.OnFinish) then
				callback.OnFinish();
			end
		end);
		return callback;
	end
end

-- System.Window's click event
-- @param localX, localY: local mouse click position relative to the control
function Macros.WindowClickTrigger(btnName, button, localX, localY)
	local obj = Application.GetUIObject(btnName);
	if(obj) then
		local window = obj:GetWindow()
		if(window and window:testAttribute("WA_WState_Created")) then
			local x, y, width, height = obj:GetAbsPosition()
			
			if( not localX or (localX + 6) > width) then
				localX = math.floor(width/2+0.5)
			end

			if( not localY or (localY + 6) > height) then
				localY =  math.floor(height/2+0.5)
			end

			local mouseX = x + localX
			local mouseY = y + localY
			
			local callback = {};
			MacroPlayer.SetClickTrigger(mouseX, mouseY, button, function()
				if(callback.OnFinish) then
					callback.OnFinish();
				end
			end);
			return callback;
		end
	end
end


-- when saving bmax model, a message box may popup asking the user to click yes to overwrite if file exists. 
-- we will automatically confirm such message box, if the next macro is not message box trigger button. 
function Macros.ConfirmNextMessageBoxClick()
	-- we will do nothing, if next trigger is DefaultMessageBox
	local nOffset = 0;
	local targetText = "";
	while(true) do
		nOffset = nOffset + 1;
		local nextMacro = Macros:PeekNextMacro(nOffset)
		if(nextMacro) then
			if(nextMacro:IsTrigger()) then
				if(nextMacro.name == "ButtonClickTrigger") then
					local nextUIName = nextMacro:GetParams()[1];
					if(nextUIName and nextUIName:match("^DefaultMessageBox")) then
						return;
					end
				end
			end
		else
			break;
		end
	end
	-- we will automatically confirm such message box, if the next macro is not message box trigger button. 
	local obj = ParaUI.GetUIObject("DefaultMessageBox.ClosePage")
	if(obj and obj:IsValid()) then
		local btnName;
		if(ParaUI.GetUIObject("DefaultMessageBox.Yes"):IsValid()) then
			btnName = "DefaultMessageBox.Yes"
		elseif(ParaUI.GetUIObject("DefaultMessageBox.OK"):IsValid()) then
			btnName = "DefaultMessageBox.OK"
		end

		if(btnName) then
			local callback = {};
			local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
				Macros.ButtonClick(btnName, "left");
				if(callback.OnFinish) then
					callback.OnFinish();
				end
			end})
			mytimer:Change(1000);
			return callback;
		end
	end
end



