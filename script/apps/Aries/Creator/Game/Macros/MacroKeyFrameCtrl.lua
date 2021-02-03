--[[
Title: Macro for KeyFrameCtrl
Author(s): LiXizhi
Date: 2021/1/15
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

function Macros.KeyFrameCtrlClick(name, time, mouseButton)
	local ctl = CommonCtrl.GetControl(name)
	if(ctl and ctl.handleEvent) then
		mouse_button = mouseButton;
		-- trickly: id is a global variable for _guihelper.GetLastUIObjectPos()
		id = ctl:GetCurTimeButtonId() or id;
		ctl:handleEvent("ClickKeyFrame", time);
	end
end

function Macros.KeyFrameCtrlClickTrigger(name, time, mouseButton)
	local ctl = CommonCtrl.GetControl(name)
	if(ctl and ctl.handleEvent) then
		local mouseX, mouseY = ctl:GetXYPosByTime(time)
		if(mouseX) then
			local callback = {};
			MacroPlayer.SetClickTrigger(mouseX, mouseY, mouseButton, function()
				if(callback.OnFinish) then
					callback.OnFinish();
				end
			end);
			return callback;
		end
	end
end

function Macros.KeyFrameCtrlClickTimeLine(name, time)
	local ctl = CommonCtrl.GetControl(name)
	if(ctl and ctl.handleEvent) then
		mouse_button = "left";
		-- trickly: id is a global variable for _guihelper.GetLastUIObjectPos()
		id = ctl:GetCurTimeButtonId() or id;
		ctl:handleEvent("ClickTimeLine", time);
	end
end

function Macros.KeyFrameCtrlClickTimeLineTrigger(name, time)
	local ctl = CommonCtrl.GetControl(name)
	if(ctl and ctl.handleEvent) then
		local mouseX, mouseY = ctl:GetXYPosByTime(time)
		if(mouseX) then
			local callback = {};
			MacroPlayer.SetClickTrigger(mouseX, mouseY, "left", function()
				if(callback.OnFinish) then
					callback.OnFinish();
				end
			end);
			return callback;
		end
	end
end

function Macros.KeyFrameCtrlRemove(name, time)
	local ctl = CommonCtrl.GetControl(name)
	if(ctl and ctl.handleEvent) then
		ctl:handleEvent("RemoveKeyFrame", time);
	end
end

function Macros.KeyFrameCtrlRemoveTrigger(name, time)
	local ctl = CommonCtrl.GetControl(name)
	if(ctl and ctl.handleEvent) then
		local mouseX, mouseY = ctl:GetXYPosByTime(time)
		if(mouseX) then
			local callback = {};
			MacroPlayer.SetClickTrigger(mouseX, mouseY, "shift+left", function()
				if(callback.OnFinish) then
					callback.OnFinish();
				end
			end);
			return callback;
		end
	end
end

function Macros.KeyFrameCtrlMove(name, new_time, begin_shift_time)
	local ctl = CommonCtrl.GetControl(name)
	if(ctl and ctl.handleEvent) then
		ctl:handleEvent("MoveKeyFrame", new_time, begin_shift_time);
	end
end

function Macros.KeyFrameCtrlMoveTrigger(name, new_time, begin_shift_time)
	local ctl = CommonCtrl.GetControl(name)
	if(ctl and ctl.handleEvent) then
		local startX, startY = ctl:GetXYPosByTime(begin_shift_time)
		local endX, endY = ctl:GetXYPosByTime(new_time)
		if(startX) then
			local callback = {};
			MacroPlayer.SetDragTrigger(startX, startY, endX, endY, "alt+left", function()
				if(callback.OnFinish) then
					callback.OnFinish();
				end
			end);
			return callback;
		end
	end
end

function Macros.KeyFrameCtrlShift(name, begin_shift_time, offset_time)
	local ctl = CommonCtrl.GetControl(name)
	if(ctl and ctl.handleEvent) then
		ctl:handleEvent("ShiftKeyFrame", begin_shift_time, offset_time);
	end
end

function Macros.KeyFrameCtrlShiftTrigger(name, begin_shift_time, offset_time)
	local ctl = CommonCtrl.GetControl(name)
	if(ctl and ctl.handleEvent) then
		local startX, startY = ctl:GetXYPosByTime(begin_shift_time)
		local endX, endY = ctl:GetXYPosByTime(begin_shift_time+offset_time)
		if(startX) then
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

function Macros.KeyFrameCtrlCopy(name, new_time, shift_begin_time)
	local ctl = CommonCtrl.GetControl(name)
	if(ctl and ctl.handleEvent) then
		ctl:handleEvent("CopyKeyFrame", new_time, shift_begin_time);
	end
end

function Macros.KeyFrameCtrlCopyTrigger(name, new_time, begin_shift_time)
	local ctl = CommonCtrl.GetControl(name)
	if(ctl and ctl.handleEvent) then
		local startX, startY = ctl:GetXYPosByTime(begin_shift_time)
		local endX, endY = ctl:GetXYPosByTime(new_time)
		if(startX) then
			local callback = {};
			MacroPlayer.SetDragTrigger(startX, startY, endX, endY, "ctrl+left", function()
				if(callback.OnFinish) then
					callback.OnFinish();
				end
			end);
			return callback;
		end
	end
end