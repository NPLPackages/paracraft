--[[
Title: mcml tag for keepwork item
Author(s): leio
Date: 2020/4/24
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/keepwork/kp_slot.lua");
local kp_slot = commonlib.gettable("MyCompany.Aries.Game.mcml.kp_slot");
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local kp_slot = commonlib.gettable("MyCompany.Aries.Game.mcml.kp_slot");
function kp_slot.render_callback(mcmlNode, rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)
    local width = right-left;
    local height = bottom-top;
	local _this = ParaUI.CreateUIObject("button", "b", "_lt", left, top, width, height);
	_guihelper.SetUIColor(_this, "#ffffffff");
	local animstyle = mcmlNode:GetNumber("animstyle");
	if(animstyle) then
		_this.animstyle = animstyle;
	end
	_parent:AddChild(_this);

	mcmlNode.uiobject_id = _this.id;

	local guid;
    local copies = 0;
	guid = mcmlNode:GetAttributeWithCode("guid", nil, true);
    local item = KeepWorkItemManager.GetItem(guid);
	local itemTemplate;
    local gsid = item.gsId;
    if(item)then
	    itemTemplate = KeepWorkItemManager.GetItemTemplate(item.gsId);
        copies = item.copies;
    end
	local background;
    if(itemTemplate and itemTemplate.icon)then
        background = itemTemplate.icon;
    end
    if(not background or background == "" or background == "0")then
        background = string.format("Texture/Aries/Creator/keepwork/items/item_%d_32bits.png",gsid);
    end
	_this.background = background;

	_this:GetAttributeObject():SetField("TextOffsetY", height/2 - 8)
	_this:GetAttributeObject():SetField("TextShadowQuality", 8);
	_guihelper.SetFontColor(_this, "#ffffffff");
	_guihelper.SetUIColor(_this, "#ffffffff");
	_this.font = "System;12;bold";
	_guihelper.SetUIFontFormat(_this, 38);
	_this.shadow = true;
	_this.text = tostring(copies);
	
	kp_slot.add_tooltip_and_click(mcmlNode, _this, guid)
	return true, true, true; -- ignore_onclick, ignore_background, ignore_tooltip;
end


-- this is just a temparory tag for offline mode
function kp_slot.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	return mcmlNode:DrawDisplayBlock(rootName, bindingContext, _parent, left, top, width, height, parentLayout, style, kp_slot.render_callback);
end

function kp_slot.OnClick(ui_obj, mcmlNode, guid)
	local onclick = mcmlNode:GetAttributeWithCode("onclick");
	if(onclick) then
		-- if there is onclick event
		Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onclick, guid, mcmlNode);
	end
end
function kp_slot.add_tooltip_and_click(mcmlNode, _this, guid)
    if(not guid)then
        return
    end
    local isclickable = mcmlNode:GetBool("isclickable",true);
	if(isclickable)then
		_this:SetScript("onclick", kp_slot.OnClick, mcmlNode, guid);

		local tooltip = mcmlNode:GetAttributeWithCode("tooltip");
		local tooltip_page = string.format("script/apps/Aries/Creator/Game/mcml/keepwork/KpSlotToolTip.html?guid=%s",tostring(guid));
		if(tooltip_page) then
			local is_lock_position, use_mouse_offset;
			if(mcmlNode:GetAttribute("tooltip_is_lock_position") == "true") then
				is_lock_position, use_mouse_offset = true, false
			end
			CommonCtrl.TooltipHelper.BindObjTooltip(_this.id, tooltip_page, mcmlNode:GetNumber("tooltip_offset_x"), mcmlNode:GetNumber("tooltip_offset_y"),
				nil,nil,nil, nil, nil, nil, is_lock_position, use_mouse_offset);
		else
			_this.tooltip = tooltip;
		end
	end
end