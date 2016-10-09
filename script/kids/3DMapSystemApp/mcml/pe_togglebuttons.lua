--[[
Title: 
Author(s): leio
Date: 2012/4/20
Desc: 

DataSource = {
        { label="aaaa",SelectedMenuItemBG = nil, UnSelectedMenuItemBG = nil,  },
        { label="bbb",selected = true, },
        { label="ccc" },
        { label="ddd" },
}
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_togglebuttons.lua");
-------------------------------------------------------
]]
local mcml_controls = commonlib.gettable("Map3DSystem.mcml_controls");
-----------------------------------
-- pe:tabs control:
-- attribute <pe:tab-item onclick=""> where onclick is a function (tabpagename) end
-----------------------------------
local pe_togglebuttons = commonlib.gettable("Map3DSystem.mcml_controls.pe_togglebuttons");


-- tab pages are only created when clicked. 
function pe_togglebuttons.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local ds = mcmlNode:GetAttributeWithCode("DataSource",nil,true);
	if(not ds)then return end
	parentLayout:NewLine();
	local left, top, width, height = parentLayout:GetPreferredRect();
	
	local css = mcmlNode:GetStyle(mcml_controls.pe_css.default["pe:togglebuttons"] or mcml_controls.pe_html.css["pe:togglebuttons"]) or {};
	local padding_left, padding_top, padding_bottom, padding_right = 
		(css["padding-left"] or css["padding"] or 0),(css["padding-top"] or css["padding"] or 0),
		(css["padding-bottom"] or css["padding"] or 0),(css["padding-right"] or css["padding"] or 0);
	local margin_left, margin_top, margin_bottom, margin_right = 
			(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
			(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	
	if(css.width) then
		if((left + css.width)<width) then
			width = left + css.width
		end
	end
	if(css.height) then
		if((top + css.height)<height) then
			height = top + css.height
		end
	end
	parentLayout:AddObject(width-left, height-top);
	parentLayout:NewLine();
	
	left = left + margin_left
	top = top + margin_top;
	width = width - margin_right;
	height = height - margin_bottom;

	local instName = mcmlNode:GetInstanceName(rootName);

	local ButtonWidth = mcmlNode:GetNumber("ButtonWidth")  or css.ButtonWidth or 60;
	local ButtonHeight = mcmlNode:GetNumber("ButtonHeight") or css.ButtonHeight  or 25;
	local ItemSpacing = mcmlNode:GetNumber("ItemSpacing") or css.ItemSpacing or 5;
	local UnSelectedMenuItemBG = mcmlNode:GetString("UnSelectedMenuItemBG") or css.UnSelectedMenuItemBG;
	local SelectedMenuItemBG = mcmlNode:GetString("SelectedMenuItemBG") or css.SelectedMenuItemBG;
	local TextColor = mcmlNode:GetString("TextColor") or css.TextColor;
	local font = mcmlNode:GetString("TextFont") or css.TextFont;
	local SelectedTextColor = mcmlNode:GetString("SelectedTextColor") or css.SelectedTextColor or "0 0 0";
	mcmlNode.UnSelectedMenuItemBG = UnSelectedMenuItemBG;
	mcmlNode.SelectedMenuItemBG = SelectedMenuItemBG;

	local len = #ds;
	local _this = ParaUI.CreateUIObject("container", instName.."_container", "_lt", left, top, (ItemSpacing + ButtonWidth) * len ,ButtonHeight)
	_this.background = "";
	_parent:AddChild(_this);

	_parent = _this;

	local k,v;
	for k,v in ipairs(ds) do
		local label = v.label or "";
		local selected = v.selected;
		local x = (k - 1) * (ItemSpacing + ButtonWidth)
		local sName = string.format("%s_b_%d",instName or "",k);
		local _this = ParaUI.CreateUIObject("button", sName, "_lt", x, 0, ButtonWidth, ButtonHeight)
		SelectedMenuItemBG = v.SelectedMenuItemBG or SelectedMenuItemBG;
		UnSelectedMenuItemBG = v.UnSelectedMenuItemBG or UnSelectedMenuItemBG;
		_this.text = label;
		if(font) then
			_this.font = font;
		end	
		if(TextColor) then
			_guihelper.SetFontColor(_this, TextColor)
		end
		if(selected)then
			_this.background = SelectedMenuItemBG;
			if(SelectedTextColor) then
				_guihelper.SetFontColor(_this, SelectedTextColor)
			end
		else
			_this.background = UnSelectedMenuItemBG;
		end
		if(css["text-offset-x"]) then
			_this:GetAttributeObject():SetField("TextOffsetX", tonumber(css["text-offset-x"]) or 0)
		end
		if(css["text-offset-y"]) then
			_this:GetAttributeObject():SetField("TextOffsetY", tonumber(css["text-offset-y"]) or 0)
		end
		if(mcmlNode:GetBool("shadow") or css["text-shadow"]) then
			_this.shadow = true;
			if(css["shadow-quality"]) then
				_this:GetAttributeObject():SetField("TextShadowQuality", tonumber(css["shadow-quality"]) or 0);
			end
			if(css["shadow-color"]) then
				_this:GetAttributeObject():SetField("TextShadowColor", _guihelper.ColorStr_TO_DWORD(css["shadow-color"]));
			end
		end
		_this:SetScript("onclick", pe_togglebuttons.on_click, mcmlNode, ds, k);
		
		_parent:AddChild(_this);
	end
	
end
function pe_togglebuttons.on_click(uiobj, mcmlNode, ds, index)
	if(not mcmlNode or not uiobj or not ds or not index) then
		return
	end
	local node = ds[index];
	if(not node or node.selected)then return end
	local k,v;
	for k,v in ipairs(ds) do
		if(k == index)then
			v.selected = true;
		else
			v.selected = false;
		end
	end
	local onclick = mcmlNode.onclickscript or mcmlNode:GetString("onclick");
	if(onclick == "")then
		onclick = nil;
	end
	if(onclick) then
		Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onclick, ds, index, node, mcmlNode)
	end
end
-- get the MCML value on the node. value is is the node name or text or index of the tab item node. 
function pe_togglebuttons.GetValue(mcmlNode)
	
end

-- set the MCML value on the node. value is is the node name or text or index of the tab item node. 
function pe_togglebuttons.SetValue(mcmlNode, value)
	
end

-- get the UI value on the node, value is the node name or text or index of the tab item node. 
function pe_togglebuttons.GetUIValue(mcmlNode, pageInstName)
	
end

-- set the UI value on the node
function pe_togglebuttons.SetUIValue(mcmlNode, pageInstName, value)
	
end

