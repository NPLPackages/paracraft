--[[
Title: item template
Author(s):  LiXizhi
Company: ParaEngine
Date: 2013.10.14
Desc: 
| name  | desc |
| block_id | name or id |
| tooltip2 | second line of the tooltip |
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/pe_mc_block.lua");
local pe_mc_block = commonlib.gettable("MyCompany.Aries.Game.mcml.pe_mc_block");
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/block_types.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemStack.lua");
local pe_mc_slot = commonlib.gettable("MyCompany.Aries.Game.mcml.pe_mc_slot");
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local drag_src_mcml_node = nil;
-- create class
local pe_mc_block = commonlib.gettable("MyCompany.Aries.Game.mcml.pe_mc_block");


function pe_mc_block.render_callback(mcmlNode, rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)
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

	local inventory = mcmlNode:GetAttributeWithCode("inventory", nil, true);
	if(not inventory) then
		inventory = EntityManager.GetPlayer().inventory;
	end
	mcmlNode.inventory = inventory;

	local block_id;
	local block_count;
	local bagpos = mcmlNode:GetAttributeWithCode("bagpos", nil, true);
	if(bagpos) then
		bagpos = tonumber(bagpos);
		mcmlNode.bag_pos_ = bagpos;
		
		block_id, block_count = inventory:GetItemByBagPos(bagpos);
		mcmlNode.item_stack = inventory:GetItem(bagpos);
	else
		block_id = mcmlNode:GetAttributeWithCode("block_id", nil, true);
		if(type(block_id) == "string") then
			if(block_id:match("^%d+$")) then
				block_id = tonumber(block_id);
			else
				local names = commonlib.gettable("MyCompany.Aries.Game.block_types.names")
				block_id = names[block_id];
			end
		end
		mcmlNode.item_stack = ItemStack:new():Init(block_id);
	end
	
	mcmlNode.block_id = block_id;
	mcmlNode.block_count = block_count or 0;

	local background;
	if(block_id) then
		local block_item = ItemClient.GetItem(block_id);
		if(block_item) then
			background = block_item:GetIcon():gsub("#", ";");	
		end
	end
	_this.background = background or "";

	_this:GetAttributeObject():SetField("TextOffsetY", 8)
	_this:GetAttributeObject():SetField("TextShadowQuality", 8);
	_guihelper.SetFontColor(_this, "#ffffffff");
	_guihelper.SetUIColor(_this, "#ffffffff");
	_this.font = "System;12;bold";
	_guihelper.SetUIFontFormat(_this, 38);
	_this.shadow = true;
	if(block_count and block_count>1) then
		_this.text = tostring(block_count);
	end
	
	local isclickable = mcmlNode:GetBool("isclickable",true);
	if(isclickable)then
		_this:SetScript("onclick", pe_mc_block.OnClick, bagpos, mcmlNode);

		local tooltip = mcmlNode:GetAttributeWithCode("tooltip");

		if(not tooltip and block_id) then
			local block_item = ItemClient.GetItem(block_id);
			if(block_item) then
				tooltip = block_item:GetTooltip();
			end
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

-- get block icon
function pe_mc_block.GetIcon(block_id)	
	if(block_id) then
		local block_item = ItemClient.GetItem(block_id);
		if(block_item) then
			return (block_item:GetIcon() or ""):gsub("#", ";");
		end
	end
	return "";
end

-- this is just a temparory tag for offline mode
function pe_mc_block.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	return mcmlNode:DrawDisplayBlock(rootName, bindingContext, _parent, left, top, width, height, parentLayout, style, pe_mc_block.render_callback);
end

function pe_mc_block.OnClick(ui_obj, bagpos, mcmlNode)
	local onclick = mcmlNode:GetAttributeWithCode("onclick");
	if(onclick) then
		-- if there is onclick event
		Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onclick, mcmlNode.bag_pos_ or mcmlNode.block_id, mcmlNode);
	end
end
