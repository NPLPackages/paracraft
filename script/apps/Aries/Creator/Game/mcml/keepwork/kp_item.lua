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
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")

local kp_item = commonlib.gettable("MyCompany.Aries.Game.mcml.kp_item");
local icon_config = {
	[82004] = "Texture/Aries/Creator/keepwork/Avatar/icons/83164_alloy_silver_helmet_32bits.png",
	[82005] = "Texture/Aries/Creator/keepwork/Avatar/icons/83165_alloy_green_helmet_32bits.png",
	[82006] = "Texture/Aries/Creator/keepwork/Avatar/icons/83166_alloy_red_helmet_32bits.png",
	
	[83001] = "Texture/Aries/Creator/keepwork/Avatar/icons/84056_alloy_silver_armor_32bits.png",
	[83002] = "Texture/Aries/Creator/keepwork/Avatar/icons/84057_alloy_green_armor_32bits.png",
	[83003] = "Texture/Aries/Creator/keepwork/Avatar/icons/84058_alloy_red_armor_32bits.png",

	[84002] = "Texture/Aries/Creator/keepwork/Avatar/icons/85075_alloy_silver_guards_32bits.png",
	[84003] = "Texture/Aries/Creator/keepwork/Avatar/icons/85076_alloy_green_guards_32bits.png",
	[84004] = "Texture/Aries/Creator/keepwork/Avatar/icons/85077_alloy_red_guards_32bits.png",

	[86000] = "Texture/Aries/Creator/keepwork/Avatar/icons/87188_alloy_silver_shield_32bits.png",
	[86001] = "Texture/Aries/Creator/keepwork/Avatar/icons/87189_alloy_green_shield_32bits.png",
	[86002] = "Texture/Aries/Creator/keepwork/Avatar/icons/87190_alloy_red_shield_32bits.png",
}

function kp_item.render_callback(mcmlNode, rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)
	local _this = ParaUI.CreateUIObject("button", "b", "_lt", left, top, right-left, bottom-top);
	_guihelper.SetUIColor(_this, "#ffffffff");
	local animstyle = mcmlNode:GetNumber("animstyle");
	if(animstyle) then
		_this.animstyle = animstyle;
	end
	_this.zorder = mcmlNode:GetNumber("zorder") or 0;
	_parent:AddChild(_this);

	mcmlNode.uiobject_id = _this.id;

	local gsid;

	gsid = mcmlNode:GetAttributeWithCode("gsid", nil, true);

	local itemTemplate = KeepWorkItemManager.GetItemTemplate(gsid);
	local background;
    if(itemTemplate and itemTemplate.icon)then
        background = itemTemplate.icon;
    end

	if background == "1" then
		local item = CustomCharItems:GetItemByGsid(tostring(gsid))
		if item then
			background = item.icon
		elseif icon_config[gsid] then
			LOG.std(nil, "debug", "kp_item", "%s item can not find", gsid);
			background = icon_config[gsid]
		end

    end

    if(not background or background == "" or background == "0")then
        background = string.format("Texture/Aries/Creator/keepwork/items/item_%d_32bits.png",gsid);
    end

	_this.background = background;

	
	
    kp_item.add_tooltip_and_click(mcmlNode, _this, gsid)
	
	return true, true, true; -- ignore_onclick, ignore_background, ignore_tooltip;
end


-- this is just a temparory tag for offline mode
function kp_item.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	return mcmlNode:DrawDisplayBlock(rootName, bindingContext, _parent, left, top, width, height, parentLayout, style, kp_item.render_callback);
end

function kp_item.OnClick(ui_obj, mcmlNode, gsid)
	local onclick = mcmlNode:GetAttributeWithCode("onclick");
	if(onclick) then
		-- if there is onclick event
		Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onclick, gsid, mcmlNode);
	end
end
function kp_item.add_tooltip_and_click(mcmlNode, _this, gsid)
    if(not gsid)then
        return
    end
    local itemTemplate = KeepWorkItemManager.GetItemTemplate(gsid);
    if(not itemTemplate)then
        return
    end
    local isclickable = mcmlNode:GetBool("isclickable",true);
	if(isclickable)then
		_this:SetScript("onclick", kp_item.OnClick, mcmlNode, gsid);

		local tooltip = mcmlNode:GetAttributeWithCode("tooltip");

		local tooltip_page = string.format("script/apps/Aries/Creator/Game/mcml/keepwork/KpItemToolTip.html?gsid=%s",tostring(gsid));
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