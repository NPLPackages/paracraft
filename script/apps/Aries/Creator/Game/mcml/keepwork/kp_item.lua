--[[
Title: mcml tag for keepwork item
Author(s): leio
Date: 2020/4/24
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/keepwork/kp_item.lua");
local kp_item = commonlib.gettable("MyCompany.Aries.Game.mcml.kp_item");
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");

local kp_item = commonlib.gettable("MyCompany.Aries.Game.mcml.kp_item");
function kp_item.render_callback(mcmlNode, rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)
	local _this = ParaUI.CreateUIObject("button", "b", "_lt", left, top, right-left, bottom-top);
	_guihelper.SetUIColor(_this, "#ffffffff");
	local animstyle = mcmlNode:GetNumber("animstyle");
	if(animstyle) then
		_this.animstyle = animstyle;
	end
	_this.zorder = mcmlNode:GetNumber("zorder") or 0;
	_this:GetAttributeObject():SetField("TextOffsetY", 8)
	_this:GetAttributeObject():SetField("TextShadowQuality", 8);
	_guihelper.SetFontColor(_this, "#ffffffff");
	_guihelper.SetUIColor(_this, "#ffffffff");
	_this.font = "System;12;bold";
	_guihelper.SetUIFontFormat(_this, 38);
	_this.shadow = true;

	_parent:AddChild(_this);

	mcmlNode.uiobject_id = _this.id;

	local gsid;

	gsid = mcmlNode:GetAttributeWithCode("gsid", nil, true);

	local itemTemplate = KeepWorkItemManager.GetItemTemplate(gsid);
	local background;

	_this.background = background or "";

	_this:GetAttributeObject():SetField("TextOffsetY", 8)
	_this:GetAttributeObject():SetField("TextShadowQuality", 8);
	_guihelper.SetFontColor(_this, "#ffffffff");
	_guihelper.SetUIColor(_this, "#ffffffff");
	_this.font = "System;12;bold";
	_guihelper.SetUIFontFormat(_this, 38);
	_this.shadow = true;
	_this.text = tostring(gsid);
	
	local isclickable = mcmlNode:GetBool("isclickable",true);
	if(isclickable)then
		_this:SetScript("onclick", kp_item.OnClick, bagpos, mcmlNode);

		local tooltip = mcmlNode:GetAttributeWithCode("tooltip");

		if(not tooltip and itemTemplate) then
            tooltip = commonlib.serialize(itemTemplate, true)
		end
		-- if tooltip is explicitly provided
		local tooltip_page = string.match(tooltip or "", "page://(.+)");
		if(tooltip_page) then
			local is_lock_position, use_mouse_offset;
			if(mcmlNode:GetAttribute("tooltip_is_lock_position") == "true") then
				is_lock_position, use_mouse_offset = true, false
			end
			CommonCtrl.TooltipHelper.BindObjTooltip(_this.id, tooltip_page, mcmlNode:GetNumber("tooltip_offset_x"), mcmlNode:GetNumber("tooltip_offset_y"),
				nil,nil,nil, nil, nil, nil, is_lock_position, use_mouse_offset);
		else
			local tooltip2 = mcmlNode:GetAttributeWithCode("tooltip2");
			if(tooltip2) then
				tooltip = format("%s\n%s", tooltip or "", tooltip2)
			end
			_this.tooltip = tooltip;
		end
	end
	return true, true, true; -- ignore_onclick, ignore_background, ignore_tooltip;
end


-- this is just a temparory tag for offline mode
function kp_item.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	return mcmlNode:DrawDisplayBlock(rootName, bindingContext, _parent, left, top, width, height, parentLayout, style, kp_item.render_callback);
end

function kp_item.OnClick(ui_obj, bagpos, mcmlNode)
	local onclick = mcmlNode:GetAttributeWithCode("onclick");
	if(onclick) then
		-- if there is onclick event
		Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onclick, mcmlNode.bag_pos_ or mcmlNode.block_id, mcmlNode);
	end
end