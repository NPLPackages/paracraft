--[[
Title: Macro for SlideBar Click
Author(s): LiXizhi
Date: 2021/1/14
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
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros")


-- native ParaUIObject's onclick event
--@param btnName: button name
--@param button: "left", "right", "shift+left"
--@param eventname: nil or "onmouseup" or "onclick"
function Macros.SliderBarMouseWheel(name, mouseWheel)
	local ctl = CommonCtrl.GetControl(name)
	if(ctl and ctl.handleEvent) then
		mouse_wheel = mouseWheel;
		ctl:handleEvent("OnMouseWheel");
	end
end

function Macros.SliderBarMouseWheelTrigger(name, mouseWheel)
	local ctl = CommonCtrl.GetControl(name)
	if(ctl and ctl.handleEvent) then
		local _this = ctl:GetInnerControl()
		if(_this) then
			local x, y, width, height = _this:GetAbsPosition();
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
end

function Macros.SliderBarMouseUp(name, value)
	local ctl = CommonCtrl.GetControl(name)
	if(ctl and ctl.handleEvent) then
		if(ctl:GetValue() ~= value) then
			ctl:SetValue(value)
			ctl:OnChange();
		end
	end
end

function Macros.SliderBarMouseUpTrigger(name, value)
	local ctl = CommonCtrl.GetControl(name)
	if(ctl and ctl.handleEvent) then
		if(ctl:GetValue() ~= value) then
			local startX, startY = ctl:GetButtonCenterByValue(ctl:GetValue())
			local endX, endY = ctl:GetButtonCenterByValue(value)

			if(startX and endX) then
				local callback = {};
				MacroPlayer.SetDragTrigger(startX, startY, endX, endY, "left", function()
					if(callback.OnFinish) then
						callback.OnFinish();
					end
				end);
				return callback;
			end
		end
	end
end

function Macros.SliderBarClickButton(name, mouseButton)
	local ctl = CommonCtrl.GetControl(name)
	if(ctl and ctl.handleEvent) then
		mouse_button = mouseButton;
		ctl:handleEvent("OnClickButton");
	end
end

function Macros.SliderBarClickButtonTrigger(name, mouseButton)
	local ctl = CommonCtrl.GetControl(name)
	if(ctl and ctl.handleEvent) then
		local mouseX, mouseY= ctl:GetButtonCenterByValue(ctl:GetValue())
		
		local callback = {};
		MacroPlayer.SetClickTrigger(mouseX, mouseY, mouseButton, function()
			if(callback.OnFinish) then
				callback.OnFinish();
			end
		end);
		return callback;
	end
end