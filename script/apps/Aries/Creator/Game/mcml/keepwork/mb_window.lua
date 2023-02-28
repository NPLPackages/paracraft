--[[
Title: 
Author(s): ygy
Date: 2022/11/3
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/keepwork/mb_window.lua");
local mb_window = commonlib.gettable("MyCompany.Aries.Game.mcml.mb_window");
-------------------------------------------------------
]]
local mb_window = commonlib.gettable("MyCompany.Aries.Game.mcml.mb_window");

function mb_window.render_callback(mcmlNode, rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)
	mb_window.create_default(rootName, mcmlNode, bindingContext, _parent, left, top, right, bottom, myLayout, css);
	return true, true, true; -- ignore_onclick, ignore_background, ignore_tooltip;
end

function mb_window.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout, css)
	return mcmlNode:DrawDisplayBlock(rootName, bindingContext, _parent, left, top, width, height, parentLayout, style, mb_window.render_callback);
end

function mb_window.create_default(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, parentLayout, css)
	local bg_color = mcmlNode:GetString("bg_color") or "default"; 

    local window_bg = "Texture/Aries/Creator/keepwork/Mobile/common/win_bg1_100x100_32bits.png;0 0 100 100:30 30 30 30";
    local close_bg = "Texture/Aries/Creator/keepwork/Mobile/common/win_bt1_40x46_32bits.png;0 0 40 46";
	local title_bg = "Texture/Aries/Creator/keepwork/Mobile/common/win_title1_473x80_32bits.png;0 0 473 80:275 30 172 20";
    if(bg_color == "gray")then
		window_bg = "Texture/Aries/Creator/keepwork/Mobile/common/win_bg2_96x96_32bits.png;0 0 96 96:30 30 30 30";
	elseif bg_color == "black" then
		window_bg = "Texture/Aries/Creator/keepwork/Mobile/common/win_bg3_96x96_32bits.png;0 0 96 96:30 30 30 30";
    end

	local title_bg_height = mcmlNode:GetNumber("title_bg_height") or 80
	local w = mcmlNode:GetNumber("width") or (width-left);
	local default_height = mcmlNode:GetNumber("height")
	local h = default_height or (height-top);
	local title = mcmlNode:GetAttribute("title_text") or mcmlNode:GetAttributeWithCode("title", nil, true);
	local icon = mcmlNode:GetAttributeWithCode("icon", nil, true)
	local iconWidth = mcmlNode:GetNumber("icon_width") or 128
	local iconHeight = mcmlNode:GetNumber("icon_height") or 64
	local iconPosx = mcmlNode:GetNumber("icon_x") or 5
	local iconPosy = mcmlNode:GetNumber("icon_y") or -22
	local help_type = mcmlNode:GetAttributeWithCode("help_type", nil, true)
	local parent_width, parent_height = w, h;

	if not mcmlNode:GetNumber("icon_width") then
		local iconWidthWithCode = mcmlNode:GetAttributeWithCode("icon_width")

		if iconWidthWithCode then
			iconWidth = iconWidthWithCode
		end
	end

	if not mcmlNode:GetNumber("icon_height") then
		local iconHeightWithCode = mcmlNode:GetAttributeWithCode("icon_height")

		if iconHeightWithCode then
			iconHeight = iconHeightWithCode
		end
	end

	if not mcmlNode:GetNumber("icon_x") then
		local iconPosxWithCode = mcmlNode:GetAttributeWithCode("icon_x")

		if iconPosxWithCode then
			iconPosx = iconPosxWithCode
		end
	end

	if not mcmlNode:GetNumber("icon_y") then
		local iconPosyWithCode = mcmlNode:GetAttributeWithCode("icon_y")

		if iconPosyWithCode then
			iconPosy = iconPosyWithCode
		end
	end
	
	local title_height = 38;
	
	local _this = ParaUI.CreateUIObject("container", "c", "_lt", left, top, w, h);
	_this.background = window_bg;
	_parent:AddChild(_this);
	_parent = _this;
	local _parent_window = _this;

	_this = ParaUI.CreateUIObject("container", "win_title_bg", "_lt", 2, 2, w - 4, title_bg_height);
	_this.background = title_bg;
	_parent:AddChild(_this);

	local is_create_icon = false
	 if(icon and icon ~= "" and not title)then
        _this = ParaUI.CreateUIObject("container", "icon", "_lt", iconPosx, iconPosy, iconWidth, iconHeight);
	    _this.background = icon;
	    _parent:AddChild(_this);
		is_create_icon = true
    end

	local title_top = (title_bg_height - title_height) * 0.5
	local font_size = title_bg_height + 10 <= 80 and 28 or 36
	_this = ParaUI.CreateUIObject("button", "window_title_text", "_lt", 20, title_top, w, title_height);
	_this.enabled = false;
	_this.text = title or "";
	_this.background = "";
	_this.font = string.format("System;%s;bold",font_size);
	_guihelper.SetUIFontFormat(_this, 36)
	_guihelper.SetButtonFontColor(_this, "#FFCC00", "#FFCC00");
	_parent:AddChild(_this);

	if help_type and help_type ~= "" then
		local help_icon_x = mcmlNode:GetNumber("help_icon_x") or iconWidth
		_this = ParaUI.CreateUIObject("button", "window_help_type", "_lt", help_icon_x, 5, 32, 32);	
		
		_this.background = "Texture/Aries/Creator/keepwork/Help/btn_32X32_32bits.png;0 0 32 32";
		_parent:AddChild(_this);

		_this:SetScript("onclick", function()
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Help/HelpPage.lua").Show(help_type);
		end);
	end

	local onclose = mcmlNode:GetString("onclose");
	local isHideClose = mcmlNode:GetAttributeWithCode("is_hide_close")

	if (onclose and onclose ~= "" and not isHideClose)then
		local btn_size = title_bg_height + 10 <= 80 and 30 or 40
		local btnName = mcmlNode:GetString("uiname_onclose") or "close_btn";
		local btn_top = title_bg_height + 10 <= 80 and 16 or 20
		_this = ParaUI.CreateUIObject("button", btnName, "_rt", -btn_size-20, btn_top, btn_size, btn_size + 6);	
		
		_this.background = close_bg;
		_parent:AddChild(_this);

		local tooltip = mcmlNode:GetAttributeWithCode("tooltip");
		_this.tooltip = tooltip;
		-- if(title_height>=32) then
		-- 	_this.enabled = false;
		-- 	_guihelper.SetUIColor(_this, "#ffffffff");
		-- 	_parent:AddChild(_this);
		-- 	-- the actual touchable area is 2 times bigger, to make it easier to click on some touch device. 
		-- 	_this = ParaUI.CreateUIObject("button", btnName, "_rt", -title_height*2, 0, title_height*2, title_height);
		-- 	_this.background = "";
		-- 	_parent:AddChild(_this);
		-- end

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