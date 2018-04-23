--[[
Title: 
Author(s): Leio
Date: 2012/09/24
Desc: 
支持两种模式 full or lite
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/mcml/pe_aries_window.lua");
-------------------------------------------------------
]]
local pe_aries_window = commonlib.gettable("MyCompany.Aries.mcml_controls.pe_aries_window");

local lite_window_bg = "Texture/Aries/Common/Teen/control/window_none_title_icon_32bits.png;0 0 256 164:80 40 120 20";

local window_bg = "Texture/Aries/Common/Teen/control/big_window_bg_32bits.png:7 7 7 7";
local window_title_bg = "Texture/Aries/Common/Teen/control/window_none_ribbon_bg_32bits.png;0 0 220 70:113 29 102 32";--220 70
local window_title_highlight_bg = "Texture/Aries/Common/Teen/control/window_title_center_bg_32bits.png;0 0 425 38";--425 38
local window_ribbon_bg = "Texture/Aries/Common/Teen/control/window_title_ribbon_32bits.png;0 0 660 42";--660 42
local window_title_text = "";
local window_icon = "";
local help_btn_bg = "Texture/Aries/Common/Teen/control/help_32bits.png;0 0 20 20";
--local close_btn_bg = "Texture/Aries/Common/Teen/control/close_32bits.png;0 0 20 20";
local close_btn_bg = "Texture/Aries/Common/Teen/control/close_button2_32bits.png;0 0 30 20";
local help_disable_btn_bg = "Texture/Aries/Common/Teen/control/help_disable_32bits.png;0 0 20 20";

local mc_window_bg = "Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png;267 89 34 34:8 8 8 8";
local mc_close_btn_bg = "Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png;363 59 26 26:7 7 7 7";
local mc_line = "Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png;352 66 1 1";



function pe_aries_window.render_callback(mcmlNode, rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)
	local mode = mcmlNode:GetString("mode") or "full"; -- full or lite

	if(mode == "full")then
		pe_aries_window.create_full(rootName, mcmlNode, bindingContext, _parent, left, top, right, bottom, myLayout, css);
	elseif(mode == "thin" or mode == "mc")then
		pe_aries_window.create_thin_mc(rootName, mcmlNode, bindingContext, _parent, left, top, right, bottom, myLayout, css);
	else
		pe_aries_window.create_lite(rootName, mcmlNode, bindingContext, _parent, left, top, right, bottom, myLayout, css);
	end
	return true, true, true; -- ignore_onclick, ignore_background, ignore_tooltip;
end

function pe_aries_window.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout, css)
	return mcmlNode:DrawDisplayBlock(rootName, bindingContext, _parent, left, top, width, height, parentLayout, style, pe_aries_window.render_callback);
end
function pe_aries_window.SetTitle(mcmlNode, pageInstName, title)
	if(not title)then
		return
	end
	mcmlNode:SetAttribute("title_text",title);
end
function pe_aries_window.create_lite(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, parentLayout, css)
	if(System.options.mc) then
		pe_aries_window.create_thin_mc(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, parentLayout, css);
		return;
	end
	local isdeepbg = mcmlNode:GetBool("isdeepbg");
	local w = mcmlNode:GetNumber("width") or (width-left);
	

	local default_height = mcmlNode:GetNumber("height")
	local h = default_height or (height-top);
	local title = mcmlNode:GetAttribute("title_text") or mcmlNode:GetAttributeWithCode("title", nil, true);
	local icon = mcmlNode:GetString("icon") or ""; --32 32
	local background = mcmlNode:GetString("background") or "";
	
	local _this = ParaUI.CreateUIObject("container", "c", "_lt", left, top, w, h);
	_this.background = lite_window_bg;
	_parent:AddChild(_this);
	_parent = _this;
	local _parent_window = _this;

	
	_this = ParaUI.CreateUIObject("button", "window_title_text", "_mt", 0, 2, 20, 24);
	_this.enabled = false;
	_this.text = title;
	_this.background = "";
	_this.font = "System;14;bold";
	_guihelper.SetButtonFontColor(_this, "#ffffff", "#ffffff");
	-- _this:GetAttributeObject():SetField("TextOffsetY", -3);
	_this.shadow = true;
	_this:GetAttributeObject():SetField("TextShadowQuality", 8);
	_this:GetAttributeObject():SetField("TextShadowColor", _guihelper.ColorStr_TO_DWORD("#802a2e27"));
	_parent:AddChild(_this);

	
	local onhelp = mcmlNode:GetString("onhelp");
	local onclose = mcmlNode:GetString("onclose");

	if(onhelp and onhelp ~= "")then
		_this = ParaUI.CreateUIObject("button", "helpbtn", "_rt", - 54, 5, 20, 20);
		_parent:AddChild(_this);
		_this.background = help_btn_bg;
		_this:SetScript("onclick", function()
			Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onhelp, buttonName, mcmlNode)
		end);
	end

	if(onclose and onclose ~= "")then
		_this = ParaUI.CreateUIObject("button", "close_btn", "_rt", - 34, 5, 30, 20);
		_this.background = close_btn_bg;
		_parent:AddChild(_this);
		_this:SetScript("onclick", function()
			Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onclose, buttonName, mcmlNode)
		end);
	end

	local parent_width, parent_height = w - 14, h - 37;
	_this = ParaUI.CreateUIObject("container", "childnode", "_fi", 7, 30, 7, 7);
	if(isdeepbg)then
		_this.background="Texture/Aries/Common/Teen/control/border_bg1_32bits.png:3 3 3 3";
	else
		_this.background=background;
	end
	_parent:AddChild(_this);
	_parent = _this;

	local myLayout = parentLayout:new_child();
	myLayout:reset(0, 0, parent_width, parent_height);
	myLayout:ResetUsedSize();
	mcmlNode:DrawChildBlocks_Callback(rootName, bindingContext, _parent, 0, 0, parent_width, parent_height, myLayout, css);

	-- if height is not specified, we will use auto-sizing. 
	if(not default_height) then
		local used_width, used_height = myLayout:GetUsedSize();
		if(used_height < parent_height) then
			_parent_window.height = h - (parent_height-used_height);
		end
	end
end

function pe_aries_window.create_full(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, parentLayout, css)
	if(System.options.mc) then
		pe_aries_window.mc_create_full(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, parentLayout, css);
		return;
	end
	
	local w = mcmlNode:GetNumber("width") or (width-left);
	local default_height = mcmlNode:GetNumber("height")
	local h = default_height or (height-top);
	local title = mcmlNode:GetAttribute("title_text") or mcmlNode:GetAttributeWithCode("title", nil, true);
	local icon = mcmlNode:GetString("icon") or ""; --32 32
	local parent_width, parent_height = w, h;
	local _this = ParaUI.CreateUIObject("container", "c", "_lt", left, top, w, h);
	_this.background = window_bg;
	_parent:AddChild(_this);
	_parent = _this;
	local _parent_window = _this;

	_this = ParaUI.CreateUIObject("container", "window_title_bg", "_lt", -12, -17, w + 15, 70);
	_this.background = window_title_bg;
	_parent:AddChild(_this);
	_this = ParaUI.CreateUIObject("container", "window_title_highlight_bg", "_lt", (w - 425)/2, -10, 425, 38);
	_this.background = window_title_highlight_bg;
	_parent:AddChild(_this);
	_this = ParaUI.CreateUIObject("container", "window_ribbon_bg", "_lt", (w - 660)/2, -7, 660, 42);
	_this.background = window_ribbon_bg;
	_parent:AddChild(_this);
	_this = ParaUI.CreateUIObject("button", "window_title_text", "_lt", 0, 0, w, 32);
	_this.text = title;
	_this.enabled = false;
	_this.background = "";
	_this.font = "System;14;bold";
	_guihelper.SetButtonFontColor(_this, "#ffffff", "#ffffff");
	_this:GetAttributeObject():SetField("TextOffsetY", -6);
	_this.shadow = true;
	_this:GetAttributeObject():SetField("TextShadowQuality", 8);
	_this:GetAttributeObject():SetField("TextShadowColor", _guihelper.ColorStr_TO_DWORD("#802a2e27"));
	_parent:AddChild(_this);

	_this = ParaUI.CreateUIObject("container", "icon", "_lt", -10, -16, 64, 64);
	_this.background = icon;
	_parent:AddChild(_this);
	
	local onclose = mcmlNode:GetString("onclose");
	local onhelp = mcmlNode:GetString("onhelp");
	--if(onclose or onhelp) then
		--_this = ParaUI.CreateUIObject("button", "help_btn_bg", "_lt", w - 44, 5, 20, 20);
		--_parent:AddChild(_this);
	--
		--if(onhelp and onhelp ~= "")then
			--_this.background = help_btn_bg;
			--_this:SetScript("onclick", function()
				--Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onhelp, buttonName, mcmlNode)
			--end);
		--else
			--_this.enabled = false;
			--_this.background = help_disable_btn_bg;
			--_guihelper.SetUIColor(_this, "#ffffffff");
		--end
	--end

	
	if(onhelp and onhelp ~= "")then
		_this = ParaUI.CreateUIObject("button", "help_btn_bg", "_lt", w - 54, 5, 20, 20);
		_parent:AddChild(_this);
		_this.background = help_btn_bg;
		_this:SetScript("onclick", function()
			Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onhelp, buttonName, mcmlNode)
		end);
	end

	if(onclose and onclose ~= "")then
		_this = ParaUI.CreateUIObject("button", "close_btn_bg", "_lt", w - 34, 5, 30, 20);
		_this.background = close_btn_bg;
		_parent:AddChild(_this);
		_this:SetScript("onclick", function()
			Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onclose, buttonName, mcmlNode)
		end);
	end

	local myLayout = parentLayout:new_child();
	myLayout:reset(0, 0, parent_width, parent_height);
	myLayout:ResetUsedSize();
	mcmlNode:DrawChildBlocks_Callback(rootName, bindingContext, _parent, 0, 0, parent_width, parent_height, myLayout, css);

	-- if height is not specified, we will use auto-sizing. 
	if(not default_height) then
		local used_width, used_height = myLayout:GetUsedSize();
		if(used_height < parent_height) then
			_parent_window.height = h - (parent_height-used_height);
		end
	end
end

function pe_aries_window.create_thin_mc(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, parentLayout, css)
	--local isdeepbg = mcmlNode:GetBool("isdeepbg");
	local w = mcmlNode:GetNumber("width") or (width-left);
	local default_height = mcmlNode:GetNumber("height")
	local h = default_height or (height-top);
	local title = mcmlNode:GetAttribute("title_text") or mcmlNode:GetAttributeWithCode("title", nil, true);
	local icon = mcmlNode:GetString("icon") or ""; --32 32
	local background = mcmlNode:GetString("background") or "";
	
	local title_height = mcmlNode:GetNumber("title_height") or 28;
	
	local _this = ParaUI.CreateUIObject("container", "c", "_lt", left, top, w, h);
	_this.background = mc_window_bg;
	_parent:AddChild(_this);
	_parent = _this;
	local _parent_window = _this;

	
	_this = ParaUI.CreateUIObject("button", "window_title_text", "_lt", 10, 1, w, title_height);
	_this.enabled = false;
	_this.text = title;
	_this.background = "";
	if(title_height >= 32) then
		_this.font = "System;20;bold";
	else
		_this.font = "System;14;bold";
	end
	_guihelper.SetUIFontFormat(_this, 36)
	_guihelper.SetButtonFontColor(_this, "#FCFCFC", "#FCFCFC");
	_parent:AddChild(_this);
	
	local onclose = mcmlNode:GetString("onclose");

	if(onclose and onclose ~= "")then
		local btn_size = title_height-2;
		if(title_height>=32) then
			_this = ParaUI.CreateUIObject("button", "close_btn", "_rt", -btn_size-10, 1, btn_size, btn_size);	
		else
			_this = ParaUI.CreateUIObject("button", "close_btn", "_rt", -btn_size-1, 1, btn_size, btn_size);	
		end
		
		_this.background = mc_close_btn_bg;
		_parent:AddChild(_this);

		if(title_height>=32) then
			_this.enabled = false;
			_guihelper.SetUIColor(_this, "#ffffffff");
			_parent:AddChild(_this);
			-- the actual touchable area is 2 times bigger, to make it easier to click on some touch device. 
			_this = ParaUI.CreateUIObject("button", "close_btn", "_rt", -title_height*2, 0, title_height*2, title_height);
			_this.background = "";
			_parent:AddChild(_this);
		end

		_this:SetScript("onclick", function()
			Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onclose, buttonName, mcmlNode)
		end);
	end

	_this = ParaUI.CreateUIObject("container", "mc_panel_line", "_lt", 1, title_height, w-2, 1);
	_this.background = mc_line;
	_parent:AddChild(_this);
	local parent_width, parent_height = w - 2, h - title_height + 4;
	_this = ParaUI.CreateUIObject("container", "childnode", "_fi", 5, title_height, 7, 7);
	_this.background=background;
	_parent:AddChild(_this);
	_parent = _this;

	local myLayout = parentLayout:new_child();
	myLayout:reset(0, 0, parent_width, parent_height);
	myLayout:ResetUsedSize();
	mcmlNode:DrawChildBlocks_Callback(rootName, bindingContext, _parent, 0, 0, parent_width, parent_height, myLayout, css);

	-- if height is not specified, we will use auto-sizing. 
	if(not default_height) then
		local used_width, used_height = myLayout:GetUsedSize();
		if(used_height < parent_height) then
			_parent_window.height = h - (parent_height-used_height);
		end
	end
end

function pe_aries_window.mc_create_full(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, parentLayout, css)

end