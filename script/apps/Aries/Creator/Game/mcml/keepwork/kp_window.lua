--[[
Title: 
Author(s): Leio
Date: 2020/8/25
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/keepwork/kp_window.lua");
local kp_window = commonlib.gettable("MyCompany.Aries.Game.mcml.kp_window");
-------------------------------------------------------
]]
local kp_window = commonlib.gettable("MyCompany.Aries.Game.mcml.kp_window");

function kp_window.render_callback(mcmlNode, rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)
	kp_window.create_default(rootName, mcmlNode, bindingContext, _parent, left, top, right, bottom, myLayout, css);
	return true, true, true; -- ignore_onclick, ignore_background, ignore_tooltip;
end

function kp_window.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout, css)
	return mcmlNode:DrawDisplayBlock(rootName, bindingContext, _parent, left, top, width, height, parentLayout, style, kp_window.render_callback);
end

function kp_window.create_default(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, parentLayout, css)
	local mode = mcmlNode:GetString("mode") or "default";  -- "default" or "lite"

    local window_bg = "Texture/Aries/Creator/keepwork/Window/dakuang_32bits.png;0 0 440 93:378 43 33 44";
    local close_bg = "Texture/Aries/Creator/keepwork/Window/guanbi_32bits.png;0 0 22 22";
    if(mode == "lite")then
        window_bg = "Texture/Aries/Creator/keepwork/Window/dakuang2_32bits.png;0 0 64 69:26 44 24 22";
    end

	local w = mcmlNode:GetNumber("width") or (width-left);
	local default_height = mcmlNode:GetNumber("height")
	local h = default_height or (height-top);
	local title = mcmlNode:GetAttribute("title_text") or mcmlNode:GetAttributeWithCode("title", nil, true);
	local icon = mcmlNode:GetAttributeWithCode("icon", nil, true)
	local iconWidth = mcmlNode:GetNumber("icon_width") or 128
	local iconHeight = mcmlNode:GetNumber("icon_height") or 64
	local parent_width, parent_height = w, h;
	
	local title_height = 28;
	
	local _this = ParaUI.CreateUIObject("container", "c", "_lt", left, top, w, h);
	_this.background = window_bg;
	_parent:AddChild(_this);
	_parent = _this;
	local _parent_window = _this;

	 if(icon and icon ~= "" and not title)then
        _this = ParaUI.CreateUIObject("container", "icon", "_lt", 5, -22, iconWidth, iconHeight);
	    _this.background = icon;
	    _parent:AddChild(_this);
    end

	_this = ParaUI.CreateUIObject("button", "window_title_text", "_lt", 10, 5, w, title_height);
	_this.enabled = false;
	_this.text = title or "";
	_this.background = "";
	_this.font = "System;14;bold";
	_guihelper.SetUIFontFormat(_this, 36)
	_guihelper.SetButtonFontColor(_this, "#FCFCFC", "#FCFCFC");
	_parent:AddChild(_this);

	local onclose = mcmlNode:GetString("onclose");

	if(onclose and onclose ~= "")then
		local btn_size = 22
		local btnName = mcmlNode:GetString("uiname_onclose") or "close_btn";
		_this = ParaUI.CreateUIObject("button", btnName, "_rt", -btn_size-15, 10, btn_size, btn_size);	
		
		_this.background = close_bg;
		_parent:AddChild(_this);

		local tooltip = mcmlNode:GetAttributeWithCode("tooltip");
		_this.tooltip = tooltip;
		if(title_height>=32) then
			_this.enabled = false;
			_guihelper.SetUIColor(_this, "#ffffffff");
			_parent:AddChild(_this);
			-- the actual touchable area is 2 times bigger, to make it easier to click on some touch device. 
			_this = ParaUI.CreateUIObject("button", btnName, "_rt", -title_height*2, 0, title_height*2, title_height);
			_this.background = "";
			_parent:AddChild(_this);
		end

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