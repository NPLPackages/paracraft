--[[
Title: checkbox button
Author(s):  LiXizhi
Company: ParaEngine
Date: 2014.12.20
Desc: 
use the lib:
---++ pe:checkbox_button
mostly for mobile touch based checkbox. 

| *name* | *desc* |
| checked_text	| default to "On" |
| unchecked_text | default to "Off" |
| CheckedBG | background |
| CheckedBG_color | default to "#ffffffff" |
| UncheckedBG | background |
| UncheckedBG_color | default to "#ffffffff" | 

------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/pe_checkbox_button.lua");
local pe_checkbox_button = commonlib.gettable("MyCompany.Aries.Game.mcml.pe_checkbox_button");
------------------------------------------------------------
]]
-- create class
local pe_checkbox_button = commonlib.gettable("MyCompany.Aries.Game.mcml.pe_checkbox_button");

pe_checkbox_button.checked_bg = "Texture/Aries/Creator/Mobile/blocks_UI_32bits.png;240 2 32 32:12 12 12 12";
pe_checkbox_button.unchecked_bg = "Texture/Aries/Creator/Mobile/blocks_UI_32bits.png;240 2 32 32:12 12 12 12";
pe_checkbox_button.unchecked_bg_color = "#555555ff"
pe_checkbox_button.checked_bg_color = "#ffffffff";
pe_checkbox_button.checked_text = "ON";
pe_checkbox_button.unchecked_text = "OFF";

function pe_checkbox_button.render_callback(mcmlNode, rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)
	local width, height = right-left, bottom-top;
	local _this = ParaUI.CreateUIObject("button", "", "_lt", left, top, width, height)
	mcmlNode:SetObjId(_this.id);

	local checked_BG = mcmlNode:GetAttributeWithCode("CheckedBG") or pe_checkbox_button.checked_bg;
	local unchecked_BG = mcmlNode:GetAttributeWithCode("UncheckedBG") or pe_checkbox_button.unchecked_bg;

	local value = mcmlNode:GetAttributeWithCode("checked", nil, true);
	-- NOTE: some pages use checked="checked", some use checked="true"
	if(type(value) == "string") then
		mcmlNode.checked = (value == "true" or value == "checked");
	else
		mcmlNode.checked = value;
	end
	local font = mcmlNode:CalculateFont(css);
	if(font) then
		_this.font = font;
	end
	_this:SetScript("onclick", pe_checkbox_button.onclick, mcmlNode);
	if(mcmlNode:GetString("tooltip")) then
		_this.tooltip = mcmlNode:GetString("tooltip")
	end
	local IsEnabled = mcmlNode:GetBool("enabled")
	if(IsEnabled~=nil) then
		_this.enabled = IsEnabled;
	end

	if(css.color) then
		_guihelper.SetButtonFontColor(_this, css.color, css.color2);
	end

	_parent:AddChild(_this);
	pe_checkbox_button.UpdateUI(mcmlNode);

	-- ignore_onclick, ignore_background, ignore_tooltip
	return true, false, true;
end

-- this is just a temparory tag for offline mode
function pe_checkbox_button.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	return mcmlNode:DrawDisplayBlock(rootName, bindingContext, _parent, left, top, width, height, parentLayout, style, pe_checkbox_button.render_callback);
end

function pe_checkbox_button.UpdateUI(mcmlNode)
	local ctl = mcmlNode:GetControl();
	if(ctl) then
		if(not mcmlNode.checked) then
			ctl.background = mcmlNode:GetAttributeWithCode("UncheckedBG") or pe_checkbox_button.unchecked_bg;
			ctl.text = mcmlNode:GetAttributeWithCode("unchecked_text") or pe_checkbox_button.unchecked_text;
			_guihelper.SetUIColor(ctl, mcmlNode:GetAttributeWithCode("UncheckedBG_color") or pe_checkbox_button.unchecked_bg_color);
		else
			ctl.background = mcmlNode:GetAttributeWithCode("CheckedBG") or pe_checkbox_button.checked_bg;
			_guihelper.SetUIColor(ctl, mcmlNode:GetAttributeWithCode("CheckedBG_color") or pe_checkbox_button.checked_bg_color);
			ctl.text = mcmlNode:GetAttributeWithCode("checked_text") or pe_checkbox_button.checked_text;
		end
	end
end

-- user clicks the button. 
function pe_checkbox_button.onclick(uiobj, mcmlNode)
	mcmlNode.checked = not mcmlNode.checked;
	pe_checkbox_button.UpdateUI(mcmlNode);
	mcmlNode:OnPageEvent("onclick", mcmlNode.checked, mcmlNode);
end

-- get the MCML value on the node
function pe_checkbox_button.GetValue(mcmlNode)
	return mcmlNode:GetAttribute("checked");
end

-- get the MCML value on the node
function pe_checkbox_button.SetValue(mcmlNode, value)
	mcmlNode:SetAttribute("checked", value);
end

-- get the UI value on the node
function pe_checkbox_button.GetUIValue(mcmlNode, pageInstName)
	return mcmlNode.checked;
end

-- set the UI value on the node
function pe_checkbox_button.SetUIValue(mcmlNode, pageInstName, value)
	mcmlNode.checked = value;
	pe_checkbox_button.UpdateUI(mcmlNode);
end