--[[
Title: Macro for Dropdown listbox
Author(s): LiXizhi
Date: 2021/1/29
Desc: 

Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/Macros.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroPlayer.lua");
NPL.load("(gl)script/ide/dropdownlistbox.lua");
local MacroPlayer = commonlib.gettable("MyCompany.Aries.Game.Tasks.MacroPlayer");
local Keyboard = commonlib.gettable("System.Windows.Keyboard");
local MouseEvent = commonlib.gettable("System.Windows.MouseEvent");
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros")


function Macros.DropdownTextChange(name, text)
	local ctl = CommonCtrl.GetControl(name)
	if(ctl and ctl.handleEvent) then
		if(ctl:GetText() ~= text) then
			ctl:SetText(text);
			ctl:handleEvent("OnTextChange");
		end
	end
end

function Macros.DropdownTextChangeTrigger(name, text)
	local ctl = CommonCtrl.GetControl(name)
	if(ctl and ctl.handleEvent) then
		if(ctl:GetText() ~= text) then
			local _parent = ctl:GetParentUIObject()
			if(_parent) then
				local editbox = _parent:GetChild("e")
				local x, y, width, height = editbox:GetAbsPosition();
				local mouseX, mouseY = math.floor(x + width/2), math.floor(y + height/2);
		
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
end

function Macros.DropdownClickDropDownButton(name)
	local ctl = CommonCtrl.GetControl(name)
	if(ctl and ctl.handleEvent) then
		ctl:handleEvent("OnClickDropDownButton");
	end
end

function Macros.DropdownClickDropDownButtonTrigger(name)
	local ctl = CommonCtrl.GetControl(name)
	if(ctl and ctl.handleEvent) then
		if(ctl:GetText() ~= text) then
			local _parent = ctl:GetParentUIObject()
			if(_parent) then
				local editbox = _parent:GetChild("b")
				local x, y, width, height = editbox:GetAbsPosition();
				local mouseX, mouseY = math.floor(x + width/2), math.floor(y + height/2);
		
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
end

function Macros.DropdownListBoxCont(name)
	local ctl = CommonCtrl.GetControl(name)
	if(ctl and ctl.handleEvent) then
		ctl:handleEvent("OnMouseUpListBoxCont");
	end
end

function Macros.DropdownSelect(name, value)
	local ctl = CommonCtrl.GetControl(name)
	if(ctl and ctl.handleEvent) then
		local listBoxCont = ctl:GetListBoxContainer()
		listBoxCont.text = tostring(value);
		ctl:handleEvent("OnSelectListBox");
		ctl:SetValue(value);
	end
end

function Macros.DropdownSelectTrigger(name, value)
	local ctl = CommonCtrl.GetControl(name)
	if(ctl and ctl.handleEvent) then
		MacroPlayer.SetTopLevel()
		if(ctl:GetText() ~= text) then
			local _parent = ctl:GetParentUIObject()
			if(_parent) then
				-- tricky: do not display over macro player itself.
				local overlay = ctl:GetListBoxContainerOverlay();
				overlay.zorder = 999;

				local listBoxCont = ctl:GetListBoxContainer()
				local x, y, width, height = listBoxCont:GetAbsPosition();
				local mouseX, mouseY = math.floor(x + width/2), math.floor(y + height/2);

				local index = ctl:GetItemIndexByValue(value);
				if(index) then
					local top = math.floor((index-0.5) * 19);
					if(top < height) then
						mouseY = top + y;
					end
				end
		
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
end


function Macros.DropdownMouseUpClose(name)
	local ctl = CommonCtrl.GetControl(name)
	if(ctl and ctl.handleEvent) then
		ctl:handleEvent("OnMouseUpClose");
	end
end
