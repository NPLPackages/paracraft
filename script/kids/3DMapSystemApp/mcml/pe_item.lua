--[[
Title: all controls for profile tag controls.
Author(s): WangTian
Date: 2009/2/10
Desc: pe:item

---++ pe:slot
Renders the slot item's icon in specific size (defined in style). It just turns into an img tag for the specified item's icon.

---+++ Attributes:
| *Required* | *Name* | *Type* | *Description* |
| required | bag | number | nil if doesn't belong to any |
| required | order | number | bag or shortcut position, nil if doesn't belong to any |
| | showmouseoverdetail | bool | show item details on mouse over |
| | height | number | image height in pixel |
| | width | number | image width in pixel |
| | allowmove | bool | can be moved to a new position |
| | allowshortcut | bool | can be shortcut to quicklaunch, e.g. main menu app items |
| | allowuse | bool | can be used if right clicked |
| | greyifnothave | bool | grey the item shortcut icon if the item don't exists in inventory |
| | showcharges | bool | show the item charges |
| | IsRightClickDisable | bool | disable right click or not, if this value donot exist, the default value is false (that means right click is enable)|
| | onclick | string | on click event, function(name,value) end, if onclick field is specified, the default click bahavior is then overwritten. If the function returns true, the default handler will be called,otherwise the default one is still called.  |
| | cursor | the mouse over cursor file |
| | type | nil or "count". If this is "count", it will only display count of self.gsid. This is convinient way to display item count which automatically update the page when item count changes.  |
| | gsid | only works when type is "count" |

---++ pe:item
Renders a global store item's icon in specific size (defined in style).
| *Required* | *Name* | *Type* | *Description* |
| required | gsid | guid | The ID of the item in global store |
| | allowuse | bool | can be used when clicked, use the item directly if the item exists in user inventory |
| | greyifnothave | bool | grey the item shortcut icon if the item don't exists in user inventory |
| tooltip_is_lock_position | default to false, where the tooltip position will change with the mouse position. it can be "true" to lock it and use tooltip offset |
| tooltip_offset_x, tooltip_offset_y | initial offset position. |
| tooltip | text or a mcml url. |
| is_container | boolean, if true, it will act exactly like a div tag, except that onclick and tooltip is like pe_item |
| isenabled | boolean, if false, onclick and tooltip are both disabled. |
| onclick | callback function. |
| isshortcut | boolean, true to create a short cut to gsid item of the current user. When there is 0 copies, onclick will purchase item, otherwise it will use the item. One can replace the use on_use_item callback. |
| on_use_item | only used when isshortcut is true. one can replace the user item callback function(gsid) end | 
| on_emptyclick_item | only used when isshortcut is true. one can replace the user click callback when the user has 0 copy of the given item. function(gsid) end |
| isdragable | set this to false, if one wants to disable dragging when isshortcut=true |
| tooltip_headerline | if true it will show the tooltip head line |
| bag | number: only search in the given bag |
| excludebag | number: search in all bags except this one. |
| isclickable | |


---++ pe:item-name
Renders the item's name like pe:name
string pattern such as [%s] to quote the item name in the square brackets

---++ pe:item-price
Renders the item's buy price like pe:name

---++ pe:slot-item
Renders the item's icon in specific size (defined in style). It just turns into an img tag for the specified item's icon.
The pe:slot-bag doesn't specify any item information. It will be automaticly synchronized with server using epolling mechanism.


shortcuts are stored in MCML profile of MyDesktop application
---++ pe:shortcut
Renders the item's shortcut in specific size (defined in style). It just turns into an img tag for the specified item's icon.
Usually pe:shortcut is not implicitly coded in MCML.

---++ pe:slot-shortcut
User can add item shortcuts into quicklaunch bar slots. Those items don't indicate any item ownership. The data is then stored in the 
MCML profile of MyDesktop application.

---+++ Examples

<verbatim>
<div style="float:left;margin:5px">
	Item 123:<br/>
    <pe:item guid="123"  linked="true"/><br/>
</div>
</verbatim>

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_item.lua");
-------------------------------------------------------
]]
local L = CommonCtrl.Locale("IDE");
NPL.load("(gl)script/ide/TooltipHelper.lua");

NPL.load("(gl)script/kids/3DMapSystemUI/Desktop/Cursor.lua");
local Cursor = commonlib.gettable("Map3DSystem.UI.Cursor");

local ItemManager = commonlib.gettable("Map3DSystem.Item.ItemManager");
--

----------------------------------------------------------------------
-- pe:slot: handles MCML tag <pe:slot>
-- Turns into an img tag for the specified item's icon.
----------------------------------------------------------------------
local pe_slot = commonlib.gettable("Map3DSystem.mcml_controls.pe_slot");

pe_slot.ContainingPageCtrls = {};

pe_slot.shortcut_ContainingPageCtrls = {};
pe_slot.shortcut_dragtarget_instances = {};

local shortcut_gsids = {};

-- is gsis in card or rune region
local function IsCardOrRune_gsid(gsid)
	if(gsid >= 22101 and gsid <= 22999) then
		return true;
	elseif(gsid >= 41101 and gsid <= 41999) then
		return true;
	elseif(gsid >= 42101 and gsid <= 42999) then
		return true;
	elseif(gsid >= 43101 and gsid <= 43999) then
		return true;
	elseif(gsid >= 44101 and gsid <= 44999) then
		return true;
	elseif(gsid >= 23101 and gsid <= 23999) then
		return true;
	end
	return false;
end
local function GetOutlineFromQualityAndSize(quality, size)
	local quality_background = "";
	if(System.options.version == "kids") then
		local base_bk = "Texture/Aries/Desktop/ItemOutline/outline_all_32bits.png";
		if(quality == 2) then
			--quality_background = "Texture/Aries/Desktop/ItemOutline/outline_blue_32bits.png: 7 7 7 7";
			quality_background = base_bk..";0 74 36 36: 7 7 7 7";
		elseif(quality == 1) then
			quality_background = base_bk..";0 0 36 36: 7 7 7 7";
			--quality_background = "Texture/Aries/Desktop/ItemOutline/outline_green_32bits.png: 7 7 7 7";
		elseif(quality == 3) then
			--quality_background = "Texture/Aries/Desktop/ItemOutline/outline_violet_32bits.png: 7 7 7 7";
			quality_background = base_bk..";0 37 36 36: 7 7 7 7";
		elseif(quality == 0) then
			--quality_background = "Texture/Aries/Desktop/ItemOutline/outline_white_32bits.png: 7 7 7 7";
			quality_background = base_bk..";37 74 36 36: 7 7 7 7";
		elseif(quality == 4) then
			--quality_background = "Texture/Aries/Desktop/ItemOutline/outline_orange_32bits.png: 7 7 7 7";
			quality_background = base_bk..";37 0 36 36: 7 7 7 7";
		end
	elseif(System.options.version == "teen") then
		if(size <= 32) then
			if(quality == 2) then
				quality_background = "Texture/Aries/Desktop/ItemOutline/outline_blue_small_32bits.png: 7 7 7 7";
			elseif(quality == 1) then
				quality_background = "Texture/Aries/Desktop/ItemOutline/outline_green_small_32bits.png: 7 7 7 7";
			elseif(quality == 3) then
				quality_background = "Texture/Aries/Desktop/ItemOutline/outline_violet_small_32bits.png: 7 7 7 7";
			elseif(quality == 0) then
				quality_background = "Texture/Aries/Desktop/ItemOutline/outline_white_small_32bits.png: 7 7 7 7";
			elseif(quality == 4) then
				quality_background = "Texture/Aries/Desktop/ItemOutline/outline_orange_small_32bits.png: 7 7 7 7";
			end
		else
			if(quality == 2) then
				quality_background = "Texture/Aries/Desktop/ItemOutline/outline_blue_32bits.png: 7 7 7 7";
			elseif(quality == 1) then
				quality_background = "Texture/Aries/Desktop/ItemOutline/outline_green_32bits.png: 7 7 7 7";
			elseif(quality == 3) then
				quality_background = "Texture/Aries/Desktop/ItemOutline/outline_violet_32bits.png: 7 7 7 7";
			elseif(quality == 0) then
				quality_background = "Texture/Aries/Desktop/ItemOutline/outline_white_32bits.png: 7 7 7 7";
			elseif(quality == 4) then
				quality_background = "Texture/Aries/Desktop/ItemOutline/outline_orange_32bits.png: 7 7 7 7";
			end
		end
	end
	return quality_background;
end

---- Renders the slot with or without item's icon in specific size(defined in style)
---- the pe:slot uses a refresh mechanism to update to the latest inventory data and link data
function pe_slot.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	-- insert into the pe_slot.ContainingPageCtrls table if the pagectrl contains pe:slot tag
	local pageCtrl = mcmlNode:GetPageCtrl();
	if(pageCtrl and pageCtrl.name) then
		pe_slot.ContainingPageCtrls[pageCtrl.name] = true;
	end

	local guid = tonumber(mcmlNode:GetAttributeWithCode("guid", nil, true));
	local bag = tonumber(mcmlNode:GetAttributeWithCode("bag"));
	local order = tonumber(mcmlNode:GetAttributeWithCode("order"));
	local position = tonumber(mcmlNode:GetAttributeWithCode("position"));
	local gsid = tonumber(mcmlNode:GetAttributeWithCode("gsid", nil, true));
	local nid = tonumber(mcmlNode:GetAttributeWithCode("nid") or Map3DSystem.App.profiles.ProfileManager.GetNID());
	local has_guid_attr = guid;

	local ItemManager = Map3DSystem.Item.ItemManager;
	local Player = MyCompany.Aries.Player;
	local item;
	if(nid == Map3DSystem.App.profiles.ProfileManager.GetNID()) then
		if(type(guid) == "number") then
			-- get item from guid
			item = ItemManager.GetItemByGUID(guid);
		elseif(type(bag) == "number") and (type(order) == "number") then
			-- get item from bag and order
			item = ItemManager.GetItemByBagAndOrder(bag, order);
		elseif(type(bag) == "number") and (type(position) == "number") then
			-- get item from bag and position
			item = ItemManager.GetItemByBagAndPosition(bag, position);
		elseif(gsid) then
			local bOwn, guid_, bag_, copies_ = ItemManager.IfOwnGSItem(gsid, bag);
			if(bOwn) then
				guid = guid_;
				item = ItemManager.GetItemByGUID(guid);
			end
		else
			log("error: must specify item instance guid or bag+order or bag+position for pe:slot tag\n");
			return;
		end
	else
		if(type(guid) == "number") then
			-- get item from guid
			item = ItemManager.GetOPCItemByGUID(nid, guid);
		elseif(type(bag) == "number") then
			if(type(order) == "number") then
				-- get item from bag and order
				item = ItemManager.GetOPCItemByBagAndOrder(nid, bag, order);
			elseif(type(position) == "number") then
				-- get item from bag and position
				item = ItemManager.GetOPCItemByBagAndPosition(nid, bag, position);
			elseif(type(gsid) == "number") then
				-- get item from bag and gsid
				item = ItemManager.GetOPCItemByBagAndGsid(nid, bag, gsid);
			else
				log("error: must specify item instance guid or bag+order or bag+position for pe:slot tag\n");
				return;
			end
		else
			log("error: must specify item instance guid or bag+order or bag+position for pe:slot tag\n");
			return;
		end
	end
	
	local slot_type = mcmlNode:GetString("type");
	if(slot_type == "count") then
		if(gsid or item) then
			local copies;

			-- we will only display the count of the given item. 
			if(gsid == 0 or gsid==-1) then
				local userinfo = Map3DSystem.App.profiles.ProfileManager.GetUserInfoInMemory();
				if(userinfo) then
					if(gsid == 0) then
						copies = userinfo["emoney"];
					elseif(gsid == -1) then
						copies = userinfo["pmoney"];
					end
				end
			elseif(not copies) then
				local gsItem = System.Item.ItemManager.GetGlobalStoreItemInMemory(gsid or item.gsid);
				if(gsItem) then
					if(item) then
						copies = item.copies;
					elseif(gsid) then
						local _;
						local bOwn, guid_, bag_, copies_ = ItemManager.IfOwnGSItem(gsid, bag);
						if(bOwn and copies_) then
							copies = copies_;
						end
					end
				elseif (gsid and gsid<0) then
					local _;
					local bOwn, guid_, bag_, copies_ = ItemManager.IfOwnGSItem(gsid);
					if(bOwn and copies_) then
						copies = copies_;
					end
				end
			end

			copies = copies or 0;
				
			local text = tostring(copies);
			local old_name = mcmlNode.name;
			mcmlNode.name = "pe:slot_count";
			mcmlNode:DrawDisplayBlock(rootName,bindingContext, _parent, left, top, width, height, parentLayout, style, 
				function(mcmlNode, rootName, bindingContext, _parent, left, top, width, height, myLayout, css)
					-- local left, top, width, height = myLayout:GetPreferredRect();
					Map3DSystem.mcml_controls.pe_text.create(rootName, text, bindingContext, _parent, left, top, width, height, 
						{display=css["display"], color = css.color, ["font-family"] = css["font-family"],  ["font-size"]=css["font-size"], ["font-weight"] = css["font-weight"], ["text-align"] = css["text-align"], ["text-shadow"] = css["text-shadow"], ["base-font-size"] = css["base-font-size"], ["line-height"]=css["line-height"]}, myLayout)
				end)
			mcmlNode.name = old_name;
		end
		return;
	end

	if(item == nil) then
		guid = 0;
	else
		guid = item.guid;
	end
	
	if(guid == 0) then
		-- add a single button text
		local left, top, width, height = parentLayout:GetPreferredRect();
		local css = mcmlNode:GetStyle(Map3DSystem.mcml_controls.pe_html.css["pe:item"]) or {};
		local margin_left, margin_top, margin_bottom, margin_right = 
				(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
				(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);
			
		local tmpWidth = mcmlNode:GetNumber("width") or css.width;
		if(tmpWidth) then
			if((left + tmpWidth+margin_left+margin_right)<width) then
				width = left + tmpWidth+margin_left+margin_right;
			else
				parentLayout:NewLine();
				left, top, width, height = parentLayout:GetPreferredRect();
				width = left + tmpWidth+margin_left+margin_right;
			end
		end
		local tmpHeight = mcmlNode:GetNumber("height") or css.height;
		if(tmpHeight) then
			height = top + tmpHeight+margin_top+margin_bottom;
		end
	
		parentLayout:AddObject(width-left, height-top);
		left = left + margin_left
		top = top + margin_top;
		width = width - margin_right;
		height = height - margin_bottom;
	
		-- invalid guid stands for empty slot
		local sShowSlotNameIfEmpty = mcmlNode:GetString("ShowSlotNameIfEmpty");
		if(sShowSlotNameIfEmpty) then
			local _this = ParaUI.CreateUIObject("button", "b", "_lt", left, top, width-left, height-top);
			_this.background = "";
			_this.zorder = mcmlNode:GetNumber("zorder") or 0;
		
			_parent:AddChild(_this);

			_this.enabled = false;
			_this.text = sShowSlotNameIfEmpty;
			if(css.color) then
				_guihelper.SetFontColor(_this, css.color);
			end
		end
		return;
	end
	
	gsid = item.gsid or gsid;
	local icon = mcmlNode:GetAttributeWithCode("icon");
	local name = mcmlNode:GetAttributeWithCode("name1");
	--NOTE by leio:add a bool value
	local ShowNumBg = mcmlNode:GetBool("ShowNumBg");
	local HideCnt = mcmlNode:GetBool("HideCnt");

	local name = mcmlNode:GetAttributeWithCode("name1");
	if(icon == nil) then
		--local bLocalVersion = true;
		--Map3DSystem.Item.ItemManager.GetGlobalStoreItem(gsid, "pe:slot_"..tostring(gsid), function(msg)
			--if(msg and msg.globalstoreitems and msg.globalstoreitems[1]) then
				--
				--local function AutoRefresh(newIcon, newName)
					--if(newIcon and newIcon ~= icon) then
						--icon = newIcon;
						--name = newName;
						---- only refresh if name is different from last
						--local pageCtrl = mcmlNode:GetPageCtrl();
						--if(pageCtrl) then
							---- needs to refresh for newly fetched version.
							--if(has_guid_attr) then
								--mcmlNode:SetAttribute("icon", newIcon)
								--mcmlNode:SetAttribute("name1", newName)
							--end
							--if(not bLocalVersion) then
								--
								--pageCtrl:Refresh();
							--end
						--end
					--end
				--end
				--local gsItem = ItemManager.GetGlobalStoreItemInMemory(gsid);
				--local gsItemIcon = gsItem.icon;
				--local gsItemName = gsItem.template.name;
				--
				--if(System.options.version == "teen") then
					--if(gsItem.template.class == 1) then
						--local gender = MyCompany.Aries.Player.GetGender(nid)
						--if(gender == "female") then
							--gsItemIcon = gsItem.icon_female or gsItemIcon;
						--end
					--end
				--end
				--
				--if(gsItemIcon == nil or gsItemIcon == "") then
					---- if no nickname is provided, use a question mark instead
					--gsItemIcon = "Texture/Aries/Quest/Question_Mark_32bits.png";
					--AutoRefresh(gsItemIcon, gsItemName);
				--else
					--AutoRefresh(gsItemIcon, gsItemName);
				--end
			--end	
		--end);
		--bLocalVersion = false;
		
		local gsItem = Map3DSystem.Item.ItemManager.GetGlobalStoreItemInMemory(gsid);
		if(gsItem) then
			icon = gsItem.icon;
			name = gsItem.template.name;
			-- icon with gender
			if(System.options.version == "teen") then
				if(gsItem.template.class == 1) then
					local gender = MyCompany.Aries.Player.GetGender(nid);
					if(gender == "female") then
						icon = gsItem.icon_female or icon;
					end
				end
			end
		else
			icon = "texture/alphadot.png";
		end
	end
	
	if(mcmlNode:GetBool("greyifnothave",false)) then
		local _,_,iconname = string.find(icon,"/([^/]*)%.png");
		local greyiconname = iconname.."_grey";
		icon = string.gsub(icon,iconname,greyiconname);
	end

	--local src = item.icon or "";
	local css = mcmlNode:GetStyle(Map3DSystem.mcml_controls.pe_html.css["pe:item"]) or {};
	
	local left, top, width, height = parentLayout:GetPreferredRect();
	local margin_left, margin_top, margin_bottom, margin_right = 
			(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
			(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);
			
	local tmpWidth = mcmlNode:GetNumber("width") or css.width;
	if(tmpWidth) then
		if((left + tmpWidth+margin_left+margin_right)<width) then
			width = left + tmpWidth+margin_left+margin_right;
		else
			parentLayout:NewLine();
			left, top, width, height = parentLayout:GetPreferredRect();
			width = left + tmpWidth+margin_left+margin_right;
		end
	end
	local tmpHeight = mcmlNode:GetNumber("height") or css.height;
	if(tmpHeight) then
		height = top + tmpHeight+margin_top+margin_bottom;
	end
	
	parentLayout:AddObject(width-left, height-top);
	left = left + margin_left
	top = top + margin_top;
	width = width - margin_right;
	height = height - margin_bottom;
	
	if(icon) then

		local _this = ParaUI.CreateUIObject("button", "b", "_lt", left, top, width-left, height-top);
		--_this.enabled = false;
		if(icon == "") then
			_this.background = css.background or "";
		else
			_this.background = icon;
			-- for card textures
			if(IsCardOrRune_gsid(gsid)) then
				if((width-left) == (height-top)) then
					-- tricky: for square pe:slot use the thumb texture as card
					local gsItem = System.Item.ItemManager.GetGlobalStoreItemInMemory(gsid);
					if(gsItem) then
						_this.background = gsItem.descfile;
					end
				end
			end
		end

		--_guihelper.SetUIColor(_this, css["background-color"] or "255 255 255");
		local animstyle = mcmlNode:GetNumber("animstyle") or if_else(System.options.version == "kids", 12, nil);
		
		if(animstyle) then
			_this.animstyle = animstyle;
		end
		
		_this.zorder = mcmlNode:GetNumber("zorder") or 0;

		local cursor_file = mcmlNode:GetAttributeWithCode("cursor");
		if(cursor_file and cursor_file~="") then
			_this.cursor = cursor_file;
		end

		_this.zorder = mcmlNode:GetNumber("zorder") or 0;
		
		_parent:AddChild(_this);
		
		local _clicktarget = _this;
		local isdragable = false; -- mcmlNode:GetBool("isdragable", true);
		if(System.options.version == "teen") then
			isdragable = mcmlNode:GetBool("isdragable", false);
		end
		if(isdragable) then
			local _drag = ParaUI.CreateUIObject("button", "mousedraglayer", "_lt", left, top, width-left, height-top);
			local background;
			if(icon == "") then
				background = css.background or "";
			else
				background = icon;
			end
			_drag.background = "";
			_drag.zorder = mcmlNode:GetNumber("zorder") or 0;
			_drag.candrag = true;
			_parent:AddChild(_drag);

			_drag.ondragbegin = string.format([[;Map3DSystem.mcml_controls.pe_slot.OnDragBegin(%d, %q, %d);]], _drag.id, background, gsid);
			_drag.ondragmove = string.format([[;Map3DSystem.mcml_controls.pe_slot.OnDragMove(%d, %q);]], _drag.id, background);
			_drag.ondragend = string.format([[;Map3DSystem.mcml_controls.pe_slot.OnDragEnd(%d, %q);]], _drag.id, background);

			_clicktarget = _drag;
		end

		local isclickable = mcmlNode:GetBool("isclickable",true);
		if(isclickable)then
			local param1 = mcmlNode:GetAttributeWithCode("param1");
			_clicktarget:SetScript("onclick", Map3DSystem.mcml_controls.pe_slot.OnClick, guid, mcmlNode);
		end
		if(item and type(item.IsClickable) == "function") then
			if(item:IsClickable() == false) then
				_this.animstyle = 0;
				_this.onclick = nil;
				_this.enabled = false;
			end
		end
		
		local showdebugdesc = mcmlNode:GetBool("showdebugdesc");
		if(showdebugdesc == true) then
			local gsItem = Map3DSystem.Item.ItemManager.GetGlobalStoreItemInMemory(gsid);
			if(gsItem) then
				local tooltip = tostring(name).."\n"..
						"bag="..item.bag.."\n"..
						"clientdata="..item.clientdata.."\n"..
						"copies="..item.copies.."\n"..
						"gsid="..item.gsid.."\n"..
						"guid="..item.guid.."\n"..
						"obtaintime="..item.obtaintime.."\n"..
						"order="..item.order.."\n"..
						"position="..item.position.."\n"..
						"serverdata="..commonlib.serialize_compact(item.serverdata).."\n";
				_clicktarget.tooltip = tooltip;
			end
			_clicktarget:SetScript("onclick", Map3DSystem.mcml_controls.pe_slot.OnClick, guid,mcmlNode, true);
		end
		
		local tooltip = mcmlNode:GetAttributeWithCode("tooltip");
		
		if(tooltip and tooltip ~= "")then
			-- if tooltip is explicitly provided
			local tooltip_page = string.match(tooltip or "", "page://(.+)");
			if(tooltip_page) then
				local is_lock_position, use_mouse_offset;
				if(mcmlNode:GetAttribute("tooltip_is_lock_position") == "true") then
					is_lock_position, use_mouse_offset = true, false
				end
				local tooltip_headerline = mcmlNode:GetAttributeWithCode("tooltip_headerline")
				if(tooltip_headerline) then
					tooltip_page = format("%s&hdr=%s", tooltip_page, tooltip_headerline);
				end
				CommonCtrl.TooltipHelper.BindObjTooltip(_clicktarget.id, tooltip_page, mcmlNode:GetNumber("tooltip_offset_x"), mcmlNode:GetNumber("tooltip_offset_y"),
					nil,nil,nil, nil, nil, nil, is_lock_position, use_mouse_offset);
			else
				_clicktarget.tooltip = tooltip;
			end
		else
			-- if no tooltip is explicitly provided, use the default one
			local tooltip = tostring(name);
			--tooltip = tostring(name);
			if(item and type(item.GetTooltip) == "function") then
				local tip = item:GetTooltip();
				if(tip) then
					tooltip = tip;
					if(System.options.version == "teen") then
						mcmlNode:SetAttribute("tooltip_offset_x", (width-left) - 0);
						mcmlNode:SetAttribute("tooltip_offset_y", 0);
						mcmlNode:SetAttribute("tooltip_is_lock_position", "true");
					end
				end
			end
			if(System.options.version == "teen") then
				local gsItem = System.Item.ItemManager.GetGlobalStoreItemInMemory(gsid);
				if(gsItem and gsItem.template.class == 18 and (gsItem.template.subclass == 1 or gsItem.template.subclass == 2)) then
					tooltip = "page://script/apps/Aries/Inventory/Cards/CardsTooltip.html?state=7&gsid="..gsid;
				else
					-- force teen version tooltip with all-in-one version
					tooltip = "page://script/apps/Aries/Desktop/GenericTooltip_InOne.html?gsid="..item.gsid.."&guid="..item.guid;
					if(nid ~= Map3DSystem.App.profiles.ProfileManager.GetNID()) then
						tooltip = tooltip.."&nid="..nid;
					end
				end
			else
				local gsItem = System.Item.ItemManager.GetGlobalStoreItemInMemory(gsid);
				if(gsItem and gsItem.template.class == 18 and (gsItem.template.subclass == 1 or gsItem.template.subclass == 2)) then
					tooltip = "page://script/apps/Aries/Inventory/Cards/CardsTooltip.html?state=7&gsid="..gsid;
				else
					-- force teen version tooltip with all-in-one version
					tooltip = "page://script/apps/Aries/Desktop/GenericTooltip_InOne.html?gsid="..item.gsid.."&guid="..item.guid;
					if(nid ~= Map3DSystem.App.profiles.ProfileManager.GetNID()) then
						tooltip = tooltip.."&nid="..nid;
					end
				end
			end
			-- if tooltip is explicitly provided
			local tooltip_page = string.match(tooltip or "", "page://(.+)");
			if(tooltip_page) then
				local is_lock_position, use_mouse_offset;
				if(mcmlNode:GetAttribute("tooltip_is_lock_position") == "true") then
					is_lock_position, use_mouse_offset = true, false
				end
				local tooltip_headerline = mcmlNode:GetAttributeWithCode("tooltip_headerline")
				if(tooltip_headerline) then
					tooltip_page = format("%s&hdr=%s", tooltip_page, tooltip_headerline);
				end
				CommonCtrl.TooltipHelper.BindObjTooltip(_clicktarget.id, tooltip_page, mcmlNode:GetNumber("tooltip_offset_x"), mcmlNode:GetNumber("tooltip_offset_y"),
					nil,nil,nil, nil, nil, nil, is_lock_position, use_mouse_offset);
			else
				_clicktarget.tooltip = tooltip;
			end
		end

		local bShowCount = true;
		local gsItem = System.Item.ItemManager.GetGlobalStoreItemInMemory(gsid);
		if(gsItem) then
			if((gsItem.template.maxcount == 1 and gsItem.template.inventorytype > 0) or gsItem.template.class == 1) then
				-- hide all item count that can be equiped in bag 0
				bShowCount = false;
			end
		end
		if(not HideCnt)then
			if(bShowCount) then
				--如果不显示数字背景
				if(not ShowNumBg)then
					-- show the item copies in on the item slot
					local _this = ParaUI.CreateUIObject("button", "count", "_lt", width - 48, height - 16, 48, 16);
					_this.background = "";
					_this.enabled = false;
					_this.zorder = (mcmlNode:GetNumber("zorder") or 0) + 1;
					_this.text = tostring(item.copies);
					_this.font = System.DefaultBoldFontString;
					_parent:AddChild(_this);
					-- DT_RIGHT
					_guihelper.SetUIFontFormat(_this, 2+256);
				else
					_this = ParaUI.CreateUIObject("button", "count", "_lt", width - 32 , height - 32, 32, 32);
					_this.background = "Texture/Aries/Quest/object_slot_32bits.png";
					_this.enabled = false;
					--_this.font = System.DefaultLargeBoldFontString;
					_guihelper.SetFontColor(_this, "255 255 255");
					_guihelper.SetUIColor(_this, "255 255 255");
					_this.zorder = (mcmlNode:GetNumber("zorder") or 0) + 1;
					_this.text = tostring(item.copies);
					_parent:AddChild(_this);
					_guihelper.SetUIFontFormat(_this, 1+256);
				end
			end
		end
		local isVIPItem = false;
		local gsItem = System.Item.ItemManager.GetGlobalStoreItemInMemory(gsid);
		if(gsItem) then
			if(gsItem.template.stats[180] == 1) then
				isVIPItem = true;
			end
		end
		local bHideVIPTag = mcmlNode:GetBool("HideVIPTag");
		if(isVIPItem and not bHideVIPTag) then
			-- show the item copies in on the item slot
			local _this = ParaUI.CreateUIObject("button", "VIPTag", "_lt", left, height - 32, 32, 32);
			_this.background = "Texture/Aries/Common/VIP_itemtag_32bits.png";
			_this.enabled = false;
			_this.zorder = (mcmlNode:GetNumber("zorder") or 0) + 1;
			_parent:AddChild(_this);
		end
		
		if(System.options.version == "teen") then
			local quality_background = "";
			local gsItem = Map3DSystem.Item.ItemManager.GetGlobalStoreItemInMemory(gsid);
			local bWithUnavailableMask = false;
			if(gsItem) then

				quality_background = GetOutlineFromQualityAndSize(gsItem.template.stats[221], math.min(width-left, height-top));

				-- show the item copies in on the item slot
				local _this = ParaUI.CreateUIObject("container", "quality_tag", "_lt", left, top, width-left, height-top);
				_this.background = quality_background;
				_this.enabled = false;
				_this.zorder = (mcmlNode:GetNumber("zorder") or 0) + 1;
				_parent:AddChild(_this);

				-- item with school limit
				local school_id = gsItem.template.stats[137] or gsItem.template.stats[169];
				if(school_id) then
					local myschool = "storm";
					local school = MyCompany.Aries.Combat.GetSchool();
					if(school) then
						myschool = school;
					end

					local item_school = "storm";
					if(school_id == 6) then
						item_school = "fire";
					elseif(school_id == 7) then
						item_school = "ice";
					elseif(school_id == 8) then
						item_school = "storm";
					elseif(school_id == 9) then
						item_school = "myth";
					elseif(school_id == 10) then
						item_school = "life";
					elseif(school_id == 11) then
						item_school = "death";
					elseif(school_id == 12) then
						item_school = "balance";
					end

					if(myschool ~= item_school) then
						bWithUnavailableMask = true;
					end
				end
			end

			if(gsItem) then
				-- 222 装备耐久度 
				if(gsItem.template.stats[222]) then
					if(item.GetDurability) then
						local dur = item:GetDurability();
						if(dur <= 0) then
							bWithUnavailableMask = true;
						end
					end
				end
			end

			if(bWithUnavailableMask == true) then
				-- show the item with red outline
				local _this = ParaUI.CreateUIObject("container", "school_not_match_tag", "_lt", left, top, width-left, height-top);
				_this.background = "Texture/Aries/Desktop/ItemOutline/outline_school_not_match_32bits.png: 7 7 7 7";
				_this.enabled = false;
				_this.zorder = (mcmlNode:GetNumber("zorder") or 0) + 1;
				_parent:AddChild(_this);
			end

		else
			if(IsCardOrRune_gsid(gsid)) then
				if((width-left) == (height-top)) then
					-- item quality mask
					local quality_background = "";
					local gsItem = Map3DSystem.Item.ItemManager.GetGlobalStoreItemInMemory(gsid);

					local _this;
					if(gsItem.template.stats[99] and gsItem.template.stats[99] == 1) then
					-- this is a gold or diamond card, draw an overlay. 
						quality_background = "Texture/Aries/Desktop/ItemOutline/gold_border_smaller_32bits.png: 12 12 12 12";
						_this = ParaUI.CreateUIObject("container", "quality_tag", "_lt", left-3, top-3, width-left+6, height-top+6);
					else
						quality_background = GetOutlineFromQualityAndSize(gsItem.template.stats[221] or 0, math.min(width-left, height-top));
						--if(not gsItem.template.stats[221] or gsItem.template.stats[221] == 0) then
							--quality_background = ""
						--end
						 _this = ParaUI.CreateUIObject("container", "quality_tag", "_lt", left-2, top-2, width-left+4, height-top+4);
					end
					-- show the item copies in on the item slot
					--local _this = ParaUI.CreateUIObject("container", "quality_tag", "_lt", left-3, top-3, width-left+6, height-top+6);
					_this.background = quality_background;
					_this.enabled = false;
					_this.zorder = (mcmlNode:GetNumber("zorder") or 0) + 1;
					_parent:AddChild(_this);
				end
			end
		end
	end
end

local drag_src_gsid = nil;
local drag_src_shortcut_id = nil;

local function GetGlobalDragContainer()
	local _slaveicon = ParaUI.GetUIObject("_g_pe_item_slaveicon")
	if(_slaveicon:IsValid() ~= true) then
		_slaveicon = ParaUI.CreateUIObject("container", "_g_pe_item_slaveicon", "_lt", -1000, -1000, 32, 32);
		_slaveicon.background = "texture/alphadot.png";
		_slaveicon.zorder = 1000;
		_slaveicon:AttachToRoot();
		--local _pointer = ParaUI.CreateUIObject("container", "pointer", "_lt", 0, 0, 16, 16);
		--_pointer.background = "Texture/Aries/Common/DragItemPointer_32bits.png";
		--_slaveicon:AddChild(_pointer);
	end
	return _slaveicon;
end

function pe_slot.OnDragBegin(id, background, gsid, from_shortcut_id)
	local _drag = ParaUI.GetUIObject(id);
	if(_drag and _drag:IsValid() == true) then
		if(from_shortcut_id) then
			_drag.background = "";
		end
		local _slaveicon = GetGlobalDragContainer();
		if(_slaveicon:IsValid() == true) then
			_slaveicon.background = background;
			_slaveicon.width = _drag.width;
			_slaveicon.height = _drag.height;
		end
		drag_src_gsid = gsid;
		drag_src_shortcut_id = from_shortcut_id;
	end
end

function pe_slot.OnDragMove(id, background)
	local _drag = ParaUI.GetUIObject(id);
	if(_drag and _drag:IsValid() == true) then
		--Cursor.LockCursor("none", true);
		local _slaveicon = GetGlobalDragContainer();
		if(_slaveicon:IsValid() == true) then
			local x, y = ParaUI.GetMousePosition();
			_slaveicon.translationx = x + 1000 - _slaveicon.width*0.5 + 1;
			_slaveicon.translationy = y + 1000 - _slaveicon.height + 1;
			_slaveicon:ApplyAnim();
		end
	end
end

function pe_slot.OnDragEnd(id, background, from_shortcut_id)
	local _drag = ParaUI.GetUIObject(id);
	if(_drag and _drag:IsValid() == true) then
		if(from_shortcut_id) then
			_drag.background = background;
		end
		-- Cursor.UnlockCursor("default", true);
		local _slaveicon = GetGlobalDragContainer();
		if(_slaveicon:IsValid() == true) then
			_slaveicon.translationx = 0;
			_slaveicon.translationy = 0;
			_slaveicon:ApplyAnim();
		end
		
		local m_x, m_y = ParaUI.GetMousePosition();
		local temp_removelist;
		local ui_id, id;
		for ui_id, id in pairs(pe_slot.shortcut_dragtarget_instances) do
			local _dragtarget = ParaUI.GetUIObject(ui_id);
			if(_dragtarget and _dragtarget:IsValid() == true) then
				local x, y, width, height = _dragtarget:GetAbsPosition();
				if((m_x >= x) and (m_x <= (x + width)) and (m_y >= y) and (m_y <= (y + height))) then
					-- mark gsid
					if(drag_src_shortcut_id ~= id) then
						pe_slot.Save_shortcut_gsids(id, drag_src_gsid);
						if(drag_src_shortcut_id) then
							-- drag from shortcut
							pe_slot.Save_shortcut_gsids(drag_src_shortcut_id, nil);
						end
					end
					-- refresh pe:shortcut page control
					pe_slot.RefreshShortcutContainingPageCtrls();
					-- reset drag source
					drag_src_gsid = nil;
					drag_src_shortcut_id = nil;
					return;
				end
			else
				temp_removelist = temp_removelist or {};
				temp_removelist[ui_id] = true;
			end
		end
		if(temp_removelist) then
			for ui_id, id in pairs(temp_removelist) do
				pe_slot.shortcut_dragtarget_instances[ui_id] = nil;
			end
		end
		-- no target found
		if(drag_src_shortcut_id) then
			-- drag from shortcut
			pe_slot.Save_shortcut_gsids(drag_src_shortcut_id, nil);
			-- refresh pe:shortcut page control
			pe_slot.RefreshShortcutContainingPageCtrls();
		end
		-- reset drag source
		drag_src_gsid = nil;
		drag_src_shortcut_id = nil;
	end
end

function pe_slot.Load_shortcut_gsids()
	shortcut_gsids = MyCompany.Aries.Player.LoadLocalData("shortcut_table");
	if(type(shortcut_gsids) ~= "table") then
		-- default value
		shortcut_gsids = {
			17155, -- 17155_HPPotion01
			nil, --17156, -- 17156_HPPotion02
			--17157, -- 17157_HPPotion03
			--17158, -- 17158_HPPotion04
			--17159, -- 17159_HPPotion05
			nil, --12001, -- 12001_ExpPowerPotion
			nil, --12012, -- 12012_CombatPills_DamageBoost
			nil,
			nil,
			nil,
			12017, -- 12017_ScrollBackToCity
			12016, -- 12016_TeleportStone
		};
	end
end

function pe_slot.Save_shortcut_gsids(id, gsid)
	shortcut_gsids[id] = gsid;
	MyCompany.Aries.Player.SaveLocalData("shortcut_table", shortcut_gsids);
end

function pe_slot.Get_shortcut_gsid(id)
	return shortcut_gsids[id]
end

function pe_slot.OnClickItemShortcut(index)
	local gsid = shortcut_gsids[index];

	if(gsid and gsid > 0) then
		-- use item by default
		local hasGSItem = Map3DSystem.Item.ItemManager.IfOwnGSItem;
		local bHas, guid = hasGSItem(gsid);
		if(bHas) then
			local item = Map3DSystem.Item.ItemManager.GetItemByGUID(guid);
			if(item and item.guid > 0) then
				item:OnClick("left");

				-- TODO: play click hint
			end
		end
	end
end

function pe_slot.OnClickUseItem(node)
	local mcmlNode = node.mcmlNode;
	if(not mcmlNode) then return end
	
	local onclick = mcmlNode:GetString("onclick");
	local guid = node.guid; -- tonumber(mcmlNode:GetAttributeWithCode("guid"));
	local result = true;
	if(onclick and onclick ~= "")then
		result = Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onclick, guid, mcmlNode, mouse_button)
	end
	if(result) then
		local item = Map3DSystem.Item.ItemManager.GetItemByGUID(guid);
		if(item and item.guid > 0) then
			item:OnClick("left");
		end
	end
end

function pe_slot.OnClickSell(node)
	local guid = node.guid;
	if(not guid) then return end
	local guid = tonumber(guid);
	if(guid) then
		NPL.load("(gl)script/apps/Aries/Desktop/ItemSellPanel.lua");
		MyCompany.Aries.Desktop.ItemSellPanel.OnClickSellItem(guid);
	end
end

function pe_slot.OnClickCancel(node)
end

function pe_slot.OnClickDestroy(node)
	local mcmlNode = node.mcmlNode;
	if(not mcmlNode) then return end
	local guid = node.guid; -- tonumber(mcmlNode:GetAttributeWithCode("guid"));
	local item = Map3DSystem.Item.ItemManager.GetItemByGUID(guid);

	if(item and item.guid > 0) then
		local item2 = Map3DSystem.Item.ItemManager.GetGlobalStoreItemInMemory(item.gsid);
		if(item2)then
			--commonlib.echo("!!:");
			--commonlib.echo(item2);
			-- destroy the item
			_guihelper.MessageBox("你确定要销毁 ".. item2.template.name .." 物品么？", function(result) 
				if(_guihelper.DialogResult.Yes == result) then
					Map3DSystem.Item.ItemManager.DestroyItem(guid, 1, function(msg)
						if(msg and msg.issuccess == true) then
							_guihelper.MessageBox("销毁成功!");
						end
					end);
				elseif(_guihelper.DialogResult.No == result) then
				end
			end, _guihelper.MessageBoxButtons.YesNo);
		end
	end
end

-- handle right click
function pe_slot.HandleRightClick(guid, mcmlNode)
	CommonCtrl.TooltipHelper.HideLast();
	if(not mcmlNode) then return end
	if(not guid) then return end
	-- if item is specied by bag and position, we will ignore right menu, since those item may be equipped ones.
	local guid = tonumber(guid);
	if(guid) then
		
		local ctl = CommonCtrl.GetControl("Aries_Slot_RightMenu");
		if(ctl == nil)then
			ctl = CommonCtrl.ContextMenu:new{
				name = "Aries_Slot_RightMenu",
				width = 100,
				height = 80, -- add menuitemHeight(30) with each new item
				DefaultNodeHeight = 24,
			};
			local node = ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "", Name = "Group", Type = "Group", NodeHeight = 0 });
			node:AddChild(CommonCtrl.TreeNode:new({Text = "使用", Name = "UseItem", Type = "Menuitem", onclick = pe_slot.OnClickUseItem, }));
			node:AddChild(CommonCtrl.TreeNode:new({Text = "出售", Name = "Recollect", Type = "Menuitem", onclick = pe_slot.OnClickSell, }));
			-- node:AddChild(CommonCtrl.TreeNode:new({Text = "销毁", Name = "Destroy", Type = "Menuitem", onclick = pe_slot.OnClickDestroy, }));
			node:AddChild(CommonCtrl.TreeNode:new({Text = "取消", Name = "Cancel", Type = "Menuitem", onclick = pe_slot.OnClickCancel, }));
		end
		local parentNode = ctl.RootNode:GetChild(1);
		local i;
		for i = 1, parentNode:GetChildCount() do
			local node = parentNode:GetChild(i);
			if(node) then
				node.mcmlNode = mcmlNode;
				node.guid = guid;
			end
		end

		local x, y = ParaUI.GetMousePosition();
		if(x and y)then
			ctl:Show(x, y);
		end
	end
end
-- onclick inventory slot item
function pe_slot.OnClick(uiobj, guid, mcmlNode, isDebug,tooltipx,tooltipy)
	NPL.load("(gl)script/apps/Aries/Desktop/Dock/DockTip.lua");
	local DockTip = commonlib.gettable("MyCompany.Aries.Desktop.DockTip");

    local msg = { aries_type = "OnClickInventoryItem", guid = guid, wndName = "main"};
    CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", msg);
    
	if(not mcmlNode) then return end
	if(mouse_button == "right" and guid) then
		local item = ItemManager.GetItemByGUID(guid);
		if(item and System.options.version == "kids")then
			NPL.load("(gl)script/apps/Aries/CombatPet/CombatPetHelper.lua");
			local CombatPetHelper = commonlib.gettable("MyCompany.Aries.CombatPet.CombatPetHelper");
			--宠物口粮不显示 使用
			local provider = CombatPetHelper.GetClientProvider();
			if(provider and provider:IsFood(item.gsid))then
				return
			end
		end		
	end
	local onclick = mcmlNode:GetString("onclick");
	local disable_event = mcmlNode:GetBool("disable_event");
	local IsRightClickDisable = mcmlNode:GetBool("IsRightClickDisable", System.options.version~="teen");
	local result = true;
	if(onclick and onclick ~= "")then
		result = Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onclick, guid, mcmlNode, mouse_button)
	end
		
	if(result) then
		local item = Map3DSystem.Item.ItemManager.GetItemByGUID(guid);
		if(not disable_event and item and item.guid > 0) then
			if(ItemManager.GetEvents():DispatchEvent({type = "pe_slot_OnClick" , item = item, })) then
				return;
			end
		end

		if(mouse_button == "right" and (not IsRightClickDisable)) then
			pe_slot.HandleRightClick(guid, mcmlNode)
		else
			if(item and item.guid > 0) then
				item.from_ui_click = true;
				if(item.IsCombatApparel and item:IsCombatApparel()) then
					item:OnClick(mouse_button, nil, nil, true); -- true for bShowStatsDiff
				else
					if(DockTip.NeedShowBar(item.gsid))then
						DockTip.OnClick_Item_NeedShowBar(item.gsid)
					else
						item:OnClick(mouse_button);
					end
				end
				item.from_ui_click = nil;

				-- 切换背包自动装载原背包卡片
				if(mouse_button == "left") then
					local _gsid  = item.gsid;
					local ItemManager = System.Item.ItemManager;
					local _mItem = ItemManager.GetGlobalStoreItemInMemory(_gsid);
					local _inventorytype=_mItem.template.inventorytype;
					if (_inventorytype == 24) then -- 战斗背包
						local MyCardsManager = commonlib.gettable("MyCompany.Aries.Inventory.Cards.MyCardsManager");
						MyCardsManager.AutoCopyCardsFrmPreDeck(_gsid);
					end
				end
			end
		end
	end
end

------------------------------------------------------------
-- All dragging operations are deprecated in Aries project
--
---- slot item drag begin, it will translate into OnDrag*** function calls to each slot object
--function pe_slot.OnDragBegin(type, bagid, position)
--function pe_slot.OnDragMove(type, bagid, position)
--function pe_slot.OnDragEnd(type, bagid, position)
------------------------------------------------------------

-- refresh all page ctrls that contains pe:slot tag
function pe_slot.RefreshContainingPageCtrls()
	local invalid_ctrls;
	local name, _;
	for name, _ in pairs(pe_slot.ContainingPageCtrls) do
		local pageCtrl = CommonCtrl.GetControl(name);
		if(pageCtrl and pageCtrl.Refresh and ParaUI.GetUIObject(name):IsValid()) then
			pageCtrl:Refresh(0.01);
		else
			invalid_ctrls = invalid_ctrls or {};
			invalid_ctrls[name] = true;
		end
	end
	if(invalid_ctrls) then
		for name, _ in pairs(invalid_ctrls) do
			pe_slot.ContainingPageCtrls[name] = nil;
		end
	end

	-- refresh shortcut by default
	pe_slot.RefreshShortcutContainingPageCtrls();
end

-- refresh all page ctrls that contains pe:item-shortcut tag
function pe_slot.RefreshShortcutContainingPageCtrls()
	local invalid_ctrls;
	local name, _;
	for name, _ in pairs(pe_slot.shortcut_ContainingPageCtrls) do
		local pageCtrl = CommonCtrl.GetControl(name);
		if(pageCtrl and pageCtrl.Refresh and ParaUI.GetUIObject(name):IsValid()) then
			-- NOTE: this is an immediate refresh
			pageCtrl:Refresh(0.01);
		else
			invalid_ctrls = invalid_ctrls or {};
			invalid_ctrls[name] = true;
		end
	end
	if(invalid_ctrls) then
		for name, _ in pairs(invalid_ctrls) do
			pe_slot.shortcut_ContainingPageCtrls[name] = nil;
		end
	end
	CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", { action_type = "post_pe_slot_PageRefresh", wndName = "main",});
end

-- get the MCML value on the node
function pe_slot.GetValue(mcmlNode)
	return mcmlNode:GetAttribute("guid");
end

-- set the MCML value on the node
function pe_slot.SetValue(mcmlNode, value)
	mcmlNode:SetAttribute("guid", value);
	mcmlNode:SetAttribute("icon", nil);
	if(value) then
		local icon;
		local item = Map3DSystem.Item.ItemManager.GetItemByGUID(tonumber(value));
		if(item and item.gsid) then
			local gsItem = Map3DSystem.Item.ItemManager.GetGlobalStoreItemInMemory(item.gsid);
			if(gsItem) then
				icon = gsItem.icon;
				if(System.options.version == "teen") then
					if(gsItem.template.class == 1) then
						local gender = MyCompany.Aries.Player.GetGender();
						if(gender == "female") then
							icon = gsItem.icon_female or icon;
						end
					end
				end
			else
				icon = "texture/alphadot.png";
			end
			mcmlNode:SetAttribute("icon", icon);
		end
	end
end

----------------------------------------------------------------------
-- pe:item: handles MCML tag <pe:item>
-- Turns into an img for the specified item's icon.
----------------------------------------------------------------------
local pe_item = {};
Map3DSystem.mcml_controls.pe_item = pe_item;

--private function: 
function pe_item.add_tooltip_and_click(mcmlNode, _this, gsid, _clicktarget)
	if(mcmlNode:GetString("isenabled") == "false") then
		return 
	end
	_clicktarget = _clicktarget or _this;

	local isclickable = mcmlNode:GetBool("isclickable", true);
	local onclick = mcmlNode:GetString("onclick") or "";
		
	if(isclickable == true) then
		if(onclick ~= "") then
			local animstyle = mcmlNode:GetNumber("animstyle");
			if(animstyle and animstyle>0) then
				_this.animstyle = animstyle;
			end
			local param1 = mcmlNode:GetAttributeWithCode("param1");
			_this:SetScript("onclick", Map3DSystem.mcml_controls.pe_item.OnGeneralClick, mcmlNode, gsid, onclick, if_else(param1 and tonumber(param1), tonumber(param1), param1));
		else
			local animstyle = mcmlNode:GetNumber("animstyle", 12);
			if(animstyle and animstyle>0) then
				_this.animstyle = animstyle;
			end
			_clicktarget:SetScript("onclick", function()
				local isShortCut = mcmlNode:GetBool("isshortcut", false);
				local isskipviptest = mcmlNode:GetBool("isskipviptest");
				if(isShortCut) then
					pe_item.OnClickGSItem_shortcut(gsid, isskipviptest, mcmlNode);
				else
					pe_item.OnClickGSItem(gsid, isskipviptest);
				end
			end)
		end
	end
	
	local tooltip = "page://script/apps/Aries/Desktop/GenericTooltip_InOne.html?gsid="..gsid;
	-- force using a given serverdata, in case, the item is not in local cache. 
	local serverdata = mcmlNode:GetAttributeWithCode("serverdata")
	if(serverdata and type(serverdata) == "string") then
		tooltip = format("%s&serverdata=%s", tooltip, serverdata);
	end

	tooltip = mcmlNode:GetAttributeWithCode("tooltip") or tooltip;
	if(tooltip and tooltip ~= "")then
		-- if tooltip is explicitly provided
		local tooltip_page = string.match(tooltip or "", "page://(.+)");
		if(tooltip_page) then
			local is_lock_position, use_mouse_offset;
			if(mcmlNode:GetAttribute("tooltip_is_lock_position") == "true") then
				is_lock_position, use_mouse_offset = true, false
			end
			local tooltip_headerline = mcmlNode:GetAttributeWithCode("tooltip_headerline")
			if(tooltip_headerline and tooltip_headerline~="") then
				tooltip_page = format("%s&hdr=%s", tooltip_page, tooltip_headerline);
			end
			CommonCtrl.TooltipHelper.BindObjTooltip(_clicktarget.id, tooltip_page, mcmlNode:GetNumber("tooltip_offset_x"), mcmlNode:GetNumber("tooltip_offset_y"),
				nil,nil,nil, nil, nil, nil, is_lock_position, use_mouse_offset, nil, tonumber(mcmlNode:GetAttributeWithCode("tooltip_absolute_x")), tonumber(mcmlNode:GetAttributeWithCode("tooltip_absolute_y")), mcmlNode:GetAttributeWithCode("target_parent_name"));
		else
			_clicktarget.tooltip = tooltip;
		end
	end
	local showdefaulttooltip = mcmlNode:GetBool("showdefaulttooltip");
	if(System.options.version == "teen") then
		showdefaulttooltip = mcmlNode:GetBool("showdefaulttooltip");

		-- NOTE: 2011/9/15: why default showdefaulttooltip? debug purporse?
		--showdefaulttooltip = mcmlNode:GetBool("showdefaulttooltip", true);
	end
	if(showdefaulttooltip == true and System.options.version == "kids") then
		local gsItem = Map3DSystem.Item.ItemManager.GetGlobalStoreItemInMemory(gsid);
		if(gsItem) then
			--_clicktarget.tooltip = gsItem.gsid.."\n"..gsItem.template.name;
			_clicktarget.tooltip = "";
			local tooltip_page = "script/apps/Aries/Desktop/ApparelTooltip.html?gsid="..gsItem.gsid
			local tooltip_headerline = mcmlNode:GetAttributeWithCode("tooltip_headerline")
			if(tooltip_headerline) then
				tooltip_page = format("%s&hdr=%s", tooltip_page, tooltip_headerline);
			end
			CommonCtrl.TooltipHelper.BindObjTooltip(_clicktarget.id, tooltip_page, mcmlNode:GetNumber("tooltip_offset_x"), mcmlNode:GetNumber("tooltip_offset_y"));
		end
	end
	local showdebugdesc = mcmlNode:GetBool("showdebugdesc");
	if(showdebugdesc == true) then
		local gsItem = Map3DSystem.Item.ItemManager.GetGlobalStoreItemInMemory(gsid);
		if(gsItem) then
			--_clicktarget.tooltip = gsItem.gsid.."\n"..gsItem.template.name;
			_clicktarget.tooltip = "";
			CommonCtrl.TooltipHelper.BindObjTooltip(_clicktarget.id, "script/apps/Aries/Desktop/ApparelTooltip.html?gsid="..gsItem.gsid, mcmlNode:GetNumber("tooltip_offset_x"), mcmlNode:GetNumber("tooltip_offset_y"));
		end
	end	
	
	-- force card tooltip with no explict tooltip
	local gsItem = System.Item.ItemManager.GetGlobalStoreItemInMemory(gsid);
	if(gsItem and gsItem.template.class == 18 and (gsItem.template.subclass == 1 or gsItem.template.subclass == 2)) then
		if(mcmlNode:GetAttributeWithCode("tooltip") == nil) then
			local tooltip = "script/apps/Aries/Inventory/Cards/CardsTooltip.html?state=7&gsid="..gsid;
			local bSkipRequireLevelInTooltip = mcmlNode:GetBool("bSkipRequireLevelInTooltip");
			if(bSkipRequireLevelInTooltip == true) then
				tooltip = tooltip.."&bSkipRequireLevelInTooltip=true";
			end
			CommonCtrl.TooltipHelper.BindObjTooltip(_clicktarget.id, tooltip, mcmlNode:GetNumber("tooltip_offset_x"), mcmlNode:GetNumber("tooltip_offset_y"));
		end
	end
end

-- only used for container typed pe_item. 
function pe_item.container_render_callback(mcmlNode, rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)
	-- inner nodes
	mcmlNode:DrawChildBlocks_Callback(rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)

	local gsid = tonumber(mcmlNode:GetAttributeWithCode("gsid", nil, true));
	if(type(gsid) == "number" and gsid~=0) then
		-- for tooltip
		local _this=ParaUI.CreateUIObject("button","b","_lt", left, top, right-left, bottom-top);
		_this.background = if_else(css and css.background, css.background, "");
		_parent:AddChild(_this);	
		pe_item.add_tooltip_and_click(mcmlNode, _this, gsid);
	end

	return true, true, true; -- ignore_onclick, ignore_background, ignore_tooltip;
end

-- Renders the item's icon in specific size(defined in style)
function pe_item.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local gsid = tonumber(mcmlNode:GetAttributeWithCode("gsid", nil, true));
	if(type(gsid) ~= "number") then
		log("error: must specify global store id for pe:item tag\n");
		return;
	end
	
	-- for container only tab, we will only enable clicking and tooltip
	if(mcmlNode:GetAttribute("is_container")) then
		return mcmlNode:DrawDisplayBlock(rootName, bindingContext, _parent, left, top, width, height, parentLayout, style, pe_item.container_render_callback);
	end

	if(gsid and gsid<=0) then
		
		-- add a single button text
		local left, top, width, height = parentLayout:GetPreferredRect();
		local css = mcmlNode:GetStyle(Map3DSystem.mcml_controls.pe_html.css["pe:item"]) or {};
		local margin_left, margin_top, margin_bottom, margin_right = 
				(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
				(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);
			
		local tmpWidth = mcmlNode:GetNumber("width") or css.width;
		if(tmpWidth) then
			if((left + tmpWidth+margin_left+margin_right)<width) then
				width = left + tmpWidth+margin_left+margin_right;
			else
				parentLayout:NewLine();
				left, top, width, height = parentLayout:GetPreferredRect();
				width = left + tmpWidth+margin_left+margin_right;
			end
		end
		local tmpHeight = mcmlNode:GetNumber("height") or css.height;
		if(tmpHeight) then
			height = top + tmpHeight+margin_top+margin_bottom;
		end
	
		parentLayout:AddObject(width-left, height-top);
		left = left + margin_left
		top = top + margin_top;
		width = width - margin_right;
		height = height - margin_bottom;

		local isShortCut = mcmlNode:GetBool("isshortcut", false);
		if(isShortCut) then
			-- gsid = 0 stands for empty item
			-- this mcml node is created via pe:item-shortcut
			-- create a drag target effect
			local shortcut_id = mcmlNode:GetNumber("shortcut_id");
			if(shortcut_id) then
				local _dragtarget_name = "dragtarget_effect_"..shortcut_id;
				local _dragtarget = ParaUI.CreateUIObject("button", _dragtarget_name, "_lt", left, top, width-left, height-top);
				--_dragtarget.background = ;
				_dragtarget.zorder = mcmlNode:GetNumber("zorder") or 0;
				_guihelper.SetVistaStyleButton3(_dragtarget, 
						"", 
						"Texture/Aries/Inventory/SlotHighLight_32bits.png", 
						"", 
						"Texture/Aries/Inventory/SlotHighLight_32bits.png");
				--_dragtarget:GetAttributeObject():SetField("AlwaysMouseOver", true);
				_parent:AddChild(_dragtarget);
				pe_slot.shortcut_dragtarget_instances[_dragtarget.id] = shortcut_id;
			end
		else
			if(System.options.version ~= "kids") then
				local _this = ParaUI.CreateUIObject("button", "b", "_lt", left, top, width-left, height-top);
				local background = "";
				if(gsid == 0) then
					--  奇豆emoney
					background = "Texture/Aries/Common/ThemeTeen/others/silver_coin_32bits.png"
					_this.tooltip="银币(绑定)"
				elseif(gsid == -1) then
					--  奇豆pmoney
					background = "Texture/Aries/Common/ThemeTeen/others/silver_coin_32bits.png"
					_this.tooltip="银币"
				end
				_this.background = background;
				_parent:AddChild(_this);
			end
		end
		return;
	end

	local Player = MyCompany.Aries.Player;
	
	local css = mcmlNode:GetStyle(Map3DSystem.mcml_controls.pe_html.css["pe:item"]);
	local icon = mcmlNode:GetAttributeWithCode("icon") or css.background;
	if(icon == nil) then
		--local bLocalVersion = true;
		--Map3DSystem.Item.ItemManager.GetGlobalStoreItem(gsid, "pe:item_"..tostring(gsid), function(msg)
			--if(msg and msg.globalstoreitems and msg.globalstoreitems[1]) then
				--
				--local function AutoRefresh(newIcon)
					--if(newIcon and newIcon ~= icon) then
						---- only refresh if name is different from last
						--icon = newIcon;
						--local pageCtrl = mcmlNode:GetPageCtrl();
						--if(pageCtrl) then
							---- needs to refresh for newly fetched version.
							--mcmlNode:SetAttribute("icon", icon)
							--if(not bLocalVersion) then
								--pageCtrl:Refresh();
							--end
						--end
					--end
				--end
				--
				--local gsItem = ItemManager.GetGlobalStoreItemInMemory(gsid);
				--local gsItemIcon = gsItem.icon;
				--
				--if(System.options.version == "teen") then
					--if(gsItem.template.class == 1) then
						--local gender = MyCompany.Aries.Player.GetGender(nid)
						--if(gender == "female") then
							--gsItemIcon = gsItem.icon_female or gsItemIcon;
						--end
					--end
				--end
--
				--if(gsItemIcon == nil or gsItemIcon == "") then
					---- if no nickname is provided, use a question mark instead
					--gsItemIcon = "Texture/Aries/Quest/Question_Mark_32bits.png";
					--AutoRefresh(gsItemIcon);
				--else
					--AutoRefresh(gsItemIcon);
				--end
			--end	
		--end);
		--bLocalVersion = false;

		local gsItem = Map3DSystem.Item.ItemManager.GetGlobalStoreItemInMemory(gsid);
		if(gsItem) then
			icon = gsItem.icon;
			-- icon with gender
			if(System.options.version == "teen") then
				if(gsItem.template.class == 1) then
					local gender = MyCompany.Aries.Player.GetGender(nid);
					if(gender == "female") then
						icon = gsItem.icon_female or icon;
					end
				end
			end
		else
			icon = "texture/alphadot.png";
		end
	end

	if(mcmlNode:GetBool("greyifnothave",false)) then
		local _,_,iconname = string.find(icon,"/([^/]*)%.png");
		local greyiconname = iconname.."_grey";
		icon = string.gsub(icon,iconname,greyiconname);
	end
	
	local isShortCut = mcmlNode:GetBool("isshortcut", false);
	if(isShortCut) then
		-- tricky: to force update the shortcut icon with updated gsid otherwise the icon is out of date
		if(gsid > 0) then
			local gsItem = System.Item.ItemManager.GetGlobalStoreItemInMemory(gsid);
			if(gsItem) then
				icon = gsItem.icon;
				mcmlNode:SetAttribute("icon", icon);
			end
		else
			icon = gsItem.icon;
			mcmlNode:SetAttribute("icon", "");
		end

		-- insert into the pe_slot.shortcut_ContainingPageCtrls table if the pagectrl contains pe:item-shortcut tag
		local pageCtrl = mcmlNode:GetPageCtrl();
		if(pageCtrl and pageCtrl.name) then
			pe_slot.shortcut_ContainingPageCtrls[pageCtrl.name] = true;
		end
	end
	
	--local src = item.icon or "";
	
	local left, top, width, height = parentLayout:GetPreferredRect();
	local css = mcmlNode:GetStyle(Map3DSystem.mcml_controls.pe_html.css["pe:item"]) or {};
	local margin_left, margin_top, margin_bottom, margin_right = 
			(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
			(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);
	
	local bUseSpace;
	if(css.position == "absolute") then
		-- absolute positioning in parent
		left = (css.left or 0);
		top = (css.top or 0);
	elseif(css.position == "relative") then
		-- relative positioning in next render position. 
		left = left + (css.left or 0);
		top = top + (css.top or 0);
	else
		left = left + (css.left or 0);
		top = top + (css.top or 0);
		bUseSpace = true;	
	end
			
	local tmpWidth = mcmlNode:GetNumber("width") or css.width;
	if(tmpWidth) then
		if((left + tmpWidth+margin_left+margin_right)<width) then
			width = left + tmpWidth+margin_left+margin_right;
		else
			parentLayout:NewLine();
			left, top, width, height = parentLayout:GetPreferredRect();
			width = left + tmpWidth+margin_left+margin_right;
		end
	end
	local tmpHeight = mcmlNode:GetNumber("height") or css.height;
	if(tmpHeight) then
		height = top + tmpHeight+margin_top+margin_bottom;
	end
	
	if(bUseSpace) then
		parentLayout:AddObject(width-left, height-top);
	end
		
	left = left + margin_left
	top = top + margin_top;
	width = width - margin_right;
	height = height - margin_bottom;
	
	if(icon) then
		local isShortCut = mcmlNode:GetBool("isshortcut", false);
		if(isShortCut) then
			-- this mcml node is created via pe:item-shortcut
			-- create a drag target effect
			local shortcut_id = mcmlNode:GetNumber("shortcut_id");
			if(shortcut_id) then
				local _dragtarget_name = "dragtarget_effect_"..shortcut_id;
				local _dragtarget = ParaUI.CreateUIObject("button", _dragtarget_name, "_lt", left, top, width-left, height-top);
				_dragtarget.background = "Texture/Aries/Inventory/SlotHighLight_32bits.png";
				_dragtarget.zorder = mcmlNode:GetNumber("zorder") or 0;
			
				_dragtarget:GetAttributeObject():SetField("AlwaysMouseOver", true);
				_parent:AddChild(_dragtarget);
				pe_slot.shortcut_dragtarget_instances[_dragtarget.id] = shortcut_id;
			end
		end

		local _this;
		local isclickable = mcmlNode:GetBool("isclickable",true);
		if(isclickable == false) then
			_this = ParaUI.CreateUIObject("button", "b", "_lt", left, top, width-left, height-top);
			css["background-color"] = css["background-color"] or "#ffffffff"
		else
			_this = ParaUI.CreateUIObject("button", "b", "_lt", left, top, width-left, height-top);
		end

		--_this.enabled = false;
		if(icon == "") then
			_this.background = css.background or "";
		else
			-- tricky: this allows dynamic images to update itself, _this.background only handles static images with fixed size.
			_this.background = icon;
			-- for card textures
			if(IsCardOrRune_gsid(gsid)) then
				if((width-left) == (height-top)) then
					-- tricky: for square pe:item use the thumb texture as card
					local gsItem = System.Item.ItemManager.GetGlobalStoreItemInMemory(gsid);
					if(gsItem) then
						_this.background = gsItem.descfile;
					end
				end
			end
		end
		if(css["background-color"]) then
			_guihelper.SetUIColor(_this, css["background-color"]);
		end	
		--_guihelper.SetUIColor(_this, css["background-color"] or "255 255 255");
		
		_parent:AddChild(_this);
		
		local _clicktarget = _this;
		local isdragable = mcmlNode:GetBool("isdragable", false);
		
		local isShortCut = mcmlNode:GetBool("isshortcut", false);
		if(isdragable) then
			local _drag = ParaUI.CreateUIObject("button", "mousedraglayer", "_lt", left, top, width-left, height-top);
			local background = _this.background;
			if(isShortCut) then
				-- this mcml node is created via pe:item-shortcut
				_drag.background = background;
				_this.background = "";
			else
				_drag.background = "";
			end
			_drag.zorder = mcmlNode:GetNumber("zorder") or 0;
			_drag.candrag = true;
			_parent:AddChild(_drag);

			local shortcut_id = nil;
			
			if(isShortCut) then
				shortcut_id = mcmlNode:GetNumber("shortcut_id");
			end

			_drag.ondragbegin = string.format([[;Map3DSystem.mcml_controls.pe_slot.OnDragBegin(%d, %q, %d, %s);]], _drag.id, background, gsid, tostring(shortcut_id));
			_drag.ondragmove = string.format([[;Map3DSystem.mcml_controls.pe_slot.OnDragMove(%d, %q);]], _drag.id, background);
			_drag.ondragend = string.format([[;Map3DSystem.mcml_controls.pe_slot.OnDragEnd(%d, %q, %s);]], _drag.id, background, tostring(shortcut_id));

			_clicktarget = _drag;
		end

		-- tooltip and clik implementation
		pe_item.add_tooltip_and_click(mcmlNode, _this, gsid, _clicktarget);

		--NOTE by leio:add a bool value
		local ShowNumBg = mcmlNode:GetBool("ShowNumBg");
		if(ShowNumBg)then
			_this = ParaUI.CreateUIObject("button", "count", "_lt", width - 32 , height - 32, 32, 32);
			_this.background = "Texture/Aries/Quest/object_slot_32bits.png";
			_this.enabled = false;
			--_this.font = System.DefaultLargeBoldFontString;
			_guihelper.SetFontColor(_this, "255 255 255");
			_guihelper.SetUIColor(_this, "255 255 255");
			_this.zorder = (mcmlNode:GetNumber("zorder") or 0) + 1;
			_this.text = "0";
			_parent:AddChild(_this);
		end
		
		-- NOTE: used in the UnitStatusTip.html
		local ShowCount = mcmlNode:GetNumber("ShowCount") or mcmlNode:GetAttributeWithCode("ShowCount");
		if(ShowCount) then
			-- show the item copies in on the item slot
			local _this = ParaUI.CreateUIObject("button", "count", "_lt", width - 48, height - 16, 48, 16);
			_this.background = "";
			_this.enabled = false;
			_this.zorder = (mcmlNode:GetNumber("zorder") or 0) + 1;
			_this.text = tostring(ShowCount);
			_this.font = System.DefaultBoldFontString;
			_parent:AddChild(_this);
			-- DT_RIGHT
			_guihelper.SetUIFontFormat(_this, 2);
		end

		-- draw the card mask
		local gsItem = Map3DSystem.Item.ItemManager.GetGlobalStoreItemInMemory(gsid);
		local isFateCard;
		if(gsItem and gsItem.template.stats[528]) then
			isFateCard = true;
		else
			isFateCard = false;
		end
		if(IsCardOrRune_gsid(gsid) or isFateCard) then
			if((width-left) ~= (height-top)) then
				-- show tooltip for non-square pe:item tag
				if(System.options.version == "teen") then
					local bFromInCombatDeck = mcmlNode:GetBool("bFromInCombatDeck");
					pe_item.DrawCardMask_teen(gsid, _this, nil, bFromInCombatDeck);
				else
					pe_item.DrawCardMask(gsid, _this);
				end
			end
		end
		
		if(isShortCut) then
			local gsItem = Map3DSystem.Item.ItemManager.GetGlobalStoreItemInMemory(gsid);
			if(gsItem and gsItem.template.maxcount > 1) then
				-- use item by default
				local hasGSItem = Map3DSystem.Item.ItemManager.IfOwnGSItem;

				local bag = mcmlNode:GetNumber("bag");
				local excludebag = mcmlNode:GetNumber("excludebag");
				local bHas, guid, _, copies = hasGSItem(gsid, bag, excludebag);

				copies = copies or 0;

				-- show default item copies in on the item slot
				local _this = ParaUI.CreateUIObject("button", "count", "_lt", width - 48, height - 16, 48, 16);
				_this.background = "";
				_this.enabled = false;
				_this.shadow = true;
				_this.scalingx = 0.95;
				_this.scalingy = 0.95;
				_this.zorder = (mcmlNode:GetNumber("zorder") or 0) + 1;
				_this.text = tostring(copies);
				_this.font = System.DefaultBoldFontString;
				_parent:AddChild(_this);
				-- DT_RIGHT
				_guihelper.SetUIFontFormat(_this, 2);
			end
		end

		if(System.options.version == "teen") then
			-- show a grey layer mask for empty shortcut items
			if(isShortCut) then
				local hasGSItem = Map3DSystem.Item.ItemManager.IfOwnGSItem;
				local bag = mcmlNode:GetNumber("bag");
				local excludebag = mcmlNode:GetNumber("excludebag");
				local bHas, guid, _, copies = hasGSItem(gsid, bag, excludebag);

				copies = copies or 0;
				if(copies == 0) then
					-- show the item copies in on the item slot
					local _this = ParaUI.CreateUIObject("container", "quality_tag", "_lt", left, top, width-left, height-top);
					_this.background = "Texture/Aries/Desktop/ItemOutline/greymask_empty_32bits.png: 7 7 7 7";
					_this.enabled = false;
					_this.zorder = (mcmlNode:GetNumber("zorder") or 0);
					_parent:AddChild(_this);
				end
			end
			-- item quality mask
			local quality_background = "";
			local gsItem = Map3DSystem.Item.ItemManager.GetGlobalStoreItemInMemory(gsid);
			if(gsItem) then

				quality_background = GetOutlineFromQualityAndSize(gsItem.template.stats[221], math.min(width-left, height-top));

				if((width-left) == (height-top)) then
					if(gsItem.template.class == 18 and gsItem.template.stats[221] == 0) then
						-- don't draw card quality for white cards and runes
					else
						-- show the pe_item quality tag in square pe:item
						local _this = ParaUI.CreateUIObject("container", "quality_tag", "_lt", left, top, width-left, height-top);
						_this.background = quality_background;
						_this.enabled = false;
						_this.zorder = (mcmlNode:GetNumber("zorder") or 0) + 1;
						_parent:AddChild(_this);
					end
				end
			
				-- item with school limit
				local school_id = gsItem.template.stats[137] or gsItem.template.stats[169];
				if(school_id) then
					local myschool = "storm";
					local school = MyCompany.Aries.Combat.GetSchool();
					if(school) then
						myschool = school;
					end

					local item_school = "storm";
					if(school_id == 6) then
						item_school = "fire";
					elseif(school_id == 7) then
						item_school = "ice";
					elseif(school_id == 8) then
						item_school = "storm";
					elseif(school_id == 9) then
						item_school = "myth";
					elseif(school_id == 10) then
						item_school = "life";
					elseif(school_id == 11) then
						item_school = "death";
					elseif(school_id == 12) then
						item_school = "balance";
					end

					if(myschool ~= item_school) then
						-- show the item with red outline
						local _this = ParaUI.CreateUIObject("container", "school_not_match_tag", "_lt", left, top, width-left, height-top);
						_this.background = "Texture/Aries/Desktop/ItemOutline/outline_school_not_match_32bits.png: 7 7 7 7";
						_this.enabled = false;
						_this.zorder = (mcmlNode:GetNumber("zorder") or 0) + 1;
						_parent:AddChild(_this);
					end
				end
			end
		else
			if(IsCardOrRune_gsid(gsid)) then
				if((width-left) == (height-top)) then
					-- item quality mask
					local quality_background = "";
					local gsItem = Map3DSystem.Item.ItemManager.GetGlobalStoreItemInMemory(gsid);
					local _this;
					if(gsItem.template.stats[99] and gsItem.template.stats[99] == 1) then
					-- this is a gold or diamond card, draw an overlay. 
						quality_background = "Texture/Aries/Desktop/ItemOutline/gold_border_smaller_32bits.png: 12 12 12 12";
						_this = ParaUI.CreateUIObject("container", "quality_tag", "_lt", left-3, top-3, width-left+6, height-top+6);
					else
						quality_background = GetOutlineFromQualityAndSize(gsItem.template.stats[221] or 0, math.min(width-left, height-top));
						--if(not gsItem.template.stats[221] or gsItem.template.stats[221] == 0) then
							--quality_background = ""
						--end
						 _this = ParaUI.CreateUIObject("container", "quality_tag", "_lt", left-2, top-2, width-left+4, height-top+4);
					end
					-- show the item copies in on the item slot
					--local _this = ParaUI.CreateUIObject("container", "quality_tag", "_lt", left-1, top-1, width-left+2, height-top+2);
					_this.background = quality_background;
					_this.enabled = false;
					_this.zorder = (mcmlNode:GetNumber("zorder") or 0) + 1;
					_parent:AddChild(_this);
				end
			end
		end
		local zorder = mcmlNode:GetNumber("zorder");
		if(zorder and not isShortCut and not isdragable) then
			_this.zorder = zorder;
		end
	end
end

pe_item.CardDescTest_str = nil;

-- @param gsid:
-- @param _this: the parent container inside which to draw the canvas
-- @param bFillParent: if true, we will use _this as the direct parent. Otherwise we will create an internall container with the same size, but one will lose the auto scaling property.
function pe_item.DrawCardMask(gsid, _this, bFillParent)
	if(gsid and _this) then
		local x = _this.x;
		local y = _this.y;
		local width = _this.width;
		local height = _this.height;
		
		-- abs position in case of non "_lt" alignment, e.x. card picker display
		local this_x, this_y = _this:GetAbsPosition();
		local parent_x, parent_y = _this.parent:GetAbsPosition();

		local x = this_x - parent_x;
		local y = this_y - parent_y;

		local gsItem = System.Item.ItemManager.GetGlobalStoreItemInMemory(gsid);
		if(gsItem.template.class == 3 and gsItem.template.subclass == 9) then
			-- 0 0 186 256
			local scaling = width / 186;

			local _card_canvas;
			if(bFillParent) then 
				_card_canvas = ParaUI.CreateUIObject("container", "card_canvas", "_fi", 0,0,0,0);
				_this:AddChild(_card_canvas);
			else
				_card_canvas = ParaUI.CreateUIObject("container", "card_canvas", "_lt", x, y, 186, 256);
				_this.parent:AddChild(_card_canvas);
			end

			_card_canvas.enabled = false;
			_card_canvas.background = "";
			
			local des = ParaUI.CreateUIObject("text", "desc", "_lt", 24, 185, 147, 115);
			des:GetFont("text").format = 256; -- no clip
			--des.font = if_else(scaling<0.7, "System;15;norm", "System;14;norm");
			des.font = "System;14;norm";
			des.text = pe_item.CardDescTest_str or gsItem.template.description;
			_card_canvas:AddChild(des);

		
			if(not bFillParent) then
				_card_canvas.x = x - (186 - width) / 2;
				_card_canvas.y = y - (256 - height) / 2;

				_card_canvas.scalingx = scaling;
				_card_canvas.scalingy = height / 256;
				_card_canvas:ApplyAnim();
			end
			return;
		end
		if(gsItem) then
			-- 0 0 151 230
			local scaling = width / 151;

			local _card_canvas;
			if(bFillParent) then 
				_card_canvas = ParaUI.CreateUIObject("container", "card_canvas", "_fi", 0,0,0,0);
				_this:AddChild(_card_canvas);
			else
				_card_canvas = ParaUI.CreateUIObject("container", "card_canvas", "_lt", x, y, 151, 230);
				_this.parent:AddChild(_card_canvas);
			end

			_card_canvas.enabled = false;
			_card_canvas.background = "";

			local _pips = ParaUI.CreateUIObject("text", "pips", "_lt", 120, 5, 30, 28);
			_pips:GetFont("text").format = 1+256; -- center and no clip
			_pips.font = "System;14;norm";
			local pip_text = tostring(gsItem.template.stats[134] or 0);
			if(gsItem.template.stats[134] == 114) then
				pip_text = "X";
			end
			_pips.text = pip_text;
			_card_canvas:AddChild(_pips);
			-- show card cooldown rounds in kids version also  2015.4.3 lipeng
			local _pips = ParaUI.CreateUIObject("text", "cooldown", "_lt", 7, 115, 32, 32);
			_pips:GetFont("text").format = 1+256; -- center and no clip
			_pips.font = "System;12;norm";
			_pips.shadow = true;
			_pips.text = tostring(gsItem.template.stats[186] or 0);

			if(System.options.version == "teen") then
				-- show card cooldown rounds in teen version
				_pips.text = tostring(gsItem.template.stats[186] or 0);
			end

			_card_canvas:AddChild(_pips);
			
			local _pips = ParaUI.CreateUIObject("text", "desc", "_lt", if_else(scaling<0.7, 16, 18), 142, 114, 115);
			_pips:GetFont("text").format = 256; -- no clip
			_pips.font = if_else(scaling<0.7, "System;15;norm", "System;14;norm");
			_pips.text = pe_item.CardDescTest_str or gsItem.template.description;
			_card_canvas:AddChild(_pips);

			local card_type = gsItem.template.stats[99];
			if(card_type and card_type~=0) then
				-- this is a gold or diamond card, draw an overlay. 
				if(card_type == 1) then
					local overlay_;
					if(bFillParent) then
						overlay_ = ParaUI.CreateUIObject("button", "overlay", "_fi", -8, -5, -11, -11);
					else
						overlay_ = ParaUI.CreateUIObject("button", "overlay", "_lt", -8, -5, _card_canvas.width+11, _card_canvas.height+11);
					end
					overlay_.background = "Texture/Aries/Desktop/ItemOutline/gold_border_32bits.png: 22 22 22 22";
					_guihelper.SetUIColor(overlay_, "255 255 255 255");
					_card_canvas:AddChild(overlay_);
				end
			end

			local _quality = ParaUI.CreateUIObject("container", "quality", "_lt", 0, 222, 148, 9);
			_quality.enabled = false;
			_card_canvas:AddChild(_quality);
			local base_quality_bk = "Texture/Aries/Combat/CardComponents/quality_all_32bits.png"
			if((not gsItem.template.stats[221]) or gsItem.template.stats[221] == 0) then
				_quality.background = base_quality_bk..";0 0 148 9"
			elseif(gsItem.template.stats[221] == 1) then
				--_quality.background = "Texture/Aries/Combat/CardComponents/quality_green_32bits.png";
				_quality.background = base_quality_bk..";0 11 148 9"
			elseif(gsItem.template.stats[221] == 2) then
				--_quality.background = "Texture/Aries/Combat/CardComponents/quality_blue_32bits.png";
				_quality.background = base_quality_bk..";0 33 148 9"
			elseif(gsItem.template.stats[221] == 3) then
				--_quality.background = "Texture/Aries/Combat/CardComponents/quality_purple_32bits.png";
				_quality.background = base_quality_bk..";0 22 148 9"
			elseif(gsItem.template.stats[221] == 4) then
				--_quality.background = "Texture/Aries/Combat/CardComponents/quality_orange_32bits.png";
				_quality.background = base_quality_bk..";0 44 148 9"
			end

			if(not bFillParent) then
				_card_canvas.x = x - (151 - width) / 2;
				_card_canvas.y = y - (230 - height) / 2;

				_card_canvas.scalingx = scaling;
				_card_canvas.scalingy = height / 230;
				_card_canvas:ApplyAnim();
			end
		end
	end
end

-- @param gsid:
-- @param _this: the parent container inside which to draw the canvas
-- @param bFillParent: if true, we will use _this as the direct parent. Otherwise we will create an internall container with the same size, but one will lose the auto scaling property.
-- @param bFromInCombatDeck: if true, this card is from incombat my card deck
function pe_item.DrawCardMask_teen(gsid, _this, bFillParent, bFromInCombatDeck)
	if(gsid and _this) then
		local x = _this.x;
		local y = _this.y;
		local width = _this.width;
		local height = _this.height;
		
		-- abs position in case of non "_lt" alignment, e.x. card picker display
		local this_x, this_y = _this:GetAbsPosition();
		local parent_x, parent_y = _this.parent:GetAbsPosition();

		local x = this_x - parent_x;
		local y = this_y - parent_y;

		-- 0 0 151 230
		local gsItem = System.Item.ItemManager.GetGlobalStoreItemInMemory(gsid);
		if(gsItem) then
			local scaling = width / 151;

			local _card_canvas;
			if(bFillParent) then 
				_card_canvas = ParaUI.CreateUIObject("container", "card_canvas", "_fi", 0,0,0,0);
				_this:AddChild(_card_canvas);
			else
				_card_canvas = ParaUI.CreateUIObject("container", "card_canvas", "_lt", x, y, 151, 230);
				_this.parent:AddChild(_card_canvas);
			end

			_card_canvas.enabled = false;
			_card_canvas.background = "";

			local _pips = ParaUI.CreateUIObject("container", "pips", "_lt", -1, 0, 32, 32);
			local pip_text = tostring(gsItem.template.stats[134] or 0);
			if(gsItem.template.stats[134] == 114) then
				pip_text = "X";
			end
			if(bFromInCombatDeck) then
				local school = MyCompany.Aries.Combat.GetSchoolGSID();
				if(not MyCompany.Aries.Combat.IsSameSchoolGSIDAndShortID(school, gsItem.template.stats[136]) and gsItem.template.stats[136] ~= 12) then
					if(gsItem.template.stats[134] ~= 114) then
						-- not X pip card
						pip_text = tostring((gsItem.template.stats[134] or 0) * 2);
					end
				end
			end
			_pips.background = "Texture/Aries/Combat/CardComponents/pipcost_"..pip_text.."_32bits.png";
			_card_canvas:AddChild(_pips);
			
			local school = MyCompany.Aries.Combat.GetSchoolGSID();
			if(gsItem.template.stats[134] ~= 114) then
				-- skip double pip cost tag for incombat deck
				if(not bFromInCombatDeck) then
					-- skip x pips cards
					if(not MyCompany.Aries.Combat.IsSameSchoolGSIDAndShortID(school, gsItem.template.stats[136]) and gsItem.template.stats[136] ~= 12) then
						local _double_cost_tag = ParaUI.CreateUIObject("container", "double_cost_tag", "_lt", 19, 14, 16, 16);
						_double_cost_tag.background = "Texture/Aries/Combat/CardComponents/double_cost_tag_32bits.png";
						_card_canvas:AddChild(_double_cost_tag);
					end
				end
			end
			
			if(gsItem.template.class == 18 and gsItem.template.subclass == 2) then
				local _rune_tag = ParaUI.CreateUIObject("container", "rune_tag", "_lt", 90, 166, 64, 64);
				_rune_tag.background = "Texture/Aries/Combat/CardComponents/rune_tag_new_32bits.png";
				_rune_tag.zorder = 100;
				_card_canvas:AddChild(_rune_tag);
			end
			
			local locale = System.options.locale;
			if(locale == "zhCN" or locale == "zhTW") then
				local _name = ParaUI.CreateUIObject("text", "name", "_lt", 0, 4, 155, 28);
				_name:GetFont("text").format = 1+256; -- center and no clip
				_name.font = "System;18;bold";
				_name.shadow = true;
				_guihelper.SetFontColor(_name, "255 255 255");
				_name:GetAttributeObject():SetField("TextShadowQuality", 8);
				_name:GetAttributeObject():SetField("TextShadowColor", _guihelper.ColorStr_TO_DWORD("#a02a2e27"));
				_name.text = gsItem.template.name;
				_card_canvas:AddChild(_name);
			else
				
				local _name = ParaUI.CreateUIObject("button", "name", "_lt", 30, -1, 95, 34);
				--_name.background = "texture/alphadot.png";
				_name.background = "";
				--_name:GetFont("text").format = 1+256; -- center and no clip
				_name:GetFont("text").format = 1 + 4 + 16 + 256;
				_name.font = "System;14;bold";
				_name.shadow = true;
				--_name.enabled = false;
				_guihelper.SetFontColor(_name, "255 255 255");
				_name:GetAttributeObject():SetField("TextShadowQuality", 8);
				_name:GetAttributeObject():SetField("TextShadowColor", _guihelper.ColorStr_TO_DWORD("#a02a2e27"));
				_name.text = gsItem.template.name; -- "เป็นมอนสเตอร์ด่านจำลอง"; --
				_card_canvas:AddChild(_name);
			end

			local _cooldown = ParaUI.CreateUIObject("text", "cooldown", "_lt", 14, 141, 32, 32);
			_cooldown:GetFont("text").format = 1+256; -- center and no clip
			_cooldown.font = "System;12;norm";
			_cooldown.shadow = true;
			_guihelper.SetFontColor(_cooldown, "200 255 255 255");
			_cooldown:GetAttributeObject():SetField("TextShadowQuality", 8);
			_cooldown:GetAttributeObject():SetField("TextShadowColor", _guihelper.ColorStr_TO_DWORD("#a02a2e27"));
			_cooldown.text = tostring(gsItem.template.stats[186] or 0);
			_card_canvas:AddChild(_cooldown);
			
			local _cardtype = ParaUI.CreateUIObject("container", "cardtype", "_lt", 80, 143, 64, 16);
			local assetkey_lower = string.lower(gsItem.assetkey);

			if(string.find(assetkey_lower, "fire_singleattackwithdot_level2")) then
				_cardtype.background = "Texture/Aries/Combat/CardComponents/cardtype_singleattack_32bits.png";
			elseif(string.find(assetkey_lower, "ice_singleattackwithdot_level5")) then
				_cardtype.background = "Texture/Aries/Combat/CardComponents/cardtype_singleattack_32bits.png";
			elseif(string.find(assetkey_lower, "shield")) then
				_cardtype.background = "Texture/Aries/Combat/CardComponents/cardtype_shield_32bits.png";
			elseif(string.find(assetkey_lower, "healblade")) then
				_cardtype.background = "Texture/Aries/Combat/CardComponents/cardtype_healblade_32bits.png";
			elseif(string.find(assetkey_lower, "blade")) then
				_cardtype.background = "Texture/Aries/Combat/CardComponents/cardtype_blade_32bits.png";
			elseif(string.find(assetkey_lower, "areaattack")) then
				_cardtype.background = "Texture/Aries/Combat/CardComponents/cardtype_areaattack_32bits.png";
			elseif(string.find(assetkey_lower, "areaheal")) then
				_cardtype.background = "Texture/Aries/Combat/CardComponents/cardtype_areaheal_32bits.png";
			elseif(string.find(assetkey_lower, "single") and string.find(assetkey_lower, "withdot")) then
				_cardtype.background = "Texture/Aries/Combat/CardComponents/cardtype_dotattack_32bits.png";
			elseif(string.find(assetkey_lower, "single") and string.find(assetkey_lower, "withhot")) then
				_cardtype.background = "Texture/Aries/Combat/CardComponents/cardtype_hotheal_32bits.png";
			elseif(string.find(assetkey_lower, "dotattack")) then
				_cardtype.background = "Texture/Aries/Combat/CardComponents/cardtype_dotattack_32bits.png";
			elseif(string.find(assetkey_lower, "globalaura")) then
				_cardtype.background = "Texture/Aries/Combat/CardComponents/cardtype_globalaura_32bits.png";
			elseif(string.find(assetkey_lower, "singleattack")) then
				_cardtype.background = "Texture/Aries/Combat/CardComponents/cardtype_singleattack_32bits.png";
			elseif(string.find(assetkey_lower, "singleheal")) then
				_cardtype.background = "Texture/Aries/Combat/CardComponents/cardtype_singleheal_32bits.png";
			else
				_cardtype.background = "Texture/Aries/Combat/CardComponents/cardtype_misc_32bits.png";
			end
			_card_canvas:AddChild(_cardtype);
			
			local _quality = ParaUI.CreateUIObject("container", "quality", "_lt", 0, 218, 256, 16);
			_quality.enabled = false;
			_card_canvas:AddChild(_quality);
			
			if(gsItem.template.stats[221] == 0) then
				_quality.background = "Texture/Aries/Combat/CardComponents/quality_white_32bits.png";
			elseif(gsItem.template.stats[221] == 1) then
				_quality.background = "Texture/Aries/Combat/CardComponents/quality_green_32bits.png";
			elseif(gsItem.template.stats[221] == 2) then
				_quality.background = "Texture/Aries/Combat/CardComponents/quality_blue_32bits.png";
			elseif(gsItem.template.stats[221] == 3) then
				_quality.background = "Texture/Aries/Combat/CardComponents/quality_purple_32bits.png";
			elseif(gsItem.template.stats[221] == 4) then
				_quality.background = "Texture/Aries/Combat/CardComponents/quality_orange_32bits.png";
			else
				_quality.background = "Texture/Aries/Combat/CardComponents/quality_white_32bits.png";
			end

			local description = gsItem.template.description;

			local Combat = MyCompany.Aries.Combat;
			local Card = MyCompany.Aries.Combat_Server.Card;

			local cardkey = Combat.Get_cardkey_from_gsid(gsid) or Combat.Get_rune_cardkey_from_gsid(gsid);
			if(cardkey) then
				local cardTemplate = Card.GetCardTemplate(cardkey);
				if(cardTemplate and cardTemplate.params) then
					if(cardTemplate.type == "Absorb_Adv") then
						local base_absorb_pts = cardTemplate.params.base_absorb_pts or 0;
						local scale_absorb_pts = cardTemplate.params.scale_absorb_pts or 1;
						local boost_absolute = Combat.GetStats(cardTemplate.spell_school, "damage_absolute_base") or 0;
						local total_absorb_pts = math.ceil(base_absorb_pts + scale_absorb_pts * boost_absolute);
						
						description = string.gsub(description, "@absorb@", tostring(total_absorb_pts));
					end
				end
			end
			
			local locale = System.options.locale;
			if(locale == "zhCN" or locale == "zhTW") then
				local _desc = ParaUI.CreateUIObject("text", "desc", "_lt", 8, 159, 134, 115);
				_desc:GetFont("text").format = 256; -- no clip
				_desc.font = "System;12;norm";
				_desc.text = pe_item.CardDescTest_str or description;
				_card_canvas:AddChild(_desc);
			else
				description = pe_item.CardDescTest_str or string.gsub(description, "\n", "");
				local _desc = ParaUI.CreateUIObject("button", "desc", "_lt", 8, 159, 138, 115);
				--_desc.background = "texture/alphadot.png";
				_desc.background = "";
				_desc.font = "System;12;norm";
				_desc.text = description;
				_guihelper.SetButtonTextColor(_desc, "0 0 0");
				_desc.enabled = false;
				--_desc:GetFont("text").format = 256; -- no clip
				--_desc:GetFont("text").format = 0 + 16 + 256;
				_guihelper.SetUIFontFormat(_desc, 0 + 16 + 256);
				_card_canvas:AddChild(_desc);
			end

			local card_type = gsItem.template.stats[99];
			if(card_type and card_type~=0) then
				-- this is a gold or diamond card, draw an overlay. 
				if(card_type == 1) then
					local overlay_;
					if(bFillParent) then
						overlay_ = ParaUI.CreateUIObject("button", "overlay", "_fi", -8, -5, -11, -11);
					else
						overlay_ = ParaUI.CreateUIObject("button", "overlay", "_lt", -8, -5, _card_canvas.width+11, _card_canvas.height+11);
					end
					overlay_.background = "Texture/Aries/Desktop/ItemOutline/gold_border_32bits.png: 22 22 22 22";
					_guihelper.SetUIColor(overlay_, "255 255 255 255");
					_card_canvas:AddChild(overlay_);
				end
			end
			if(not bFillParent) then
				_card_canvas.x = x - (151 - width) / 2;
				_card_canvas.y = y - (230 - height) / 2;

				_card_canvas.scalingx = scaling;
				_card_canvas.scalingy = height / 230;
				_card_canvas:ApplyAnim();
			end
		end
	end
end

function pe_item.OnGeneralClick(uiobj, mcmlNode, gsid, callback, ...)
	Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, callback, gsid, mcmlNode, ...)
end

-- on click the global store item
function pe_item.OnClickGSItem(gsid, isskipviptest,callback)
	-- purchase item by default
	
	local isVIPItem = false;
	local gsItem = System.Item.ItemManager.GetGlobalStoreItemInMemory(gsid);
	if(gsItem) then
		if(gsItem.template.stats[180] == 1) then
			isVIPItem = true;
		end
	end
	if(not isskipviptest) then
		local VIP = commonlib.gettable("MyCompany.Aries.VIP");
		if(isVIPItem and not VIP.IsVIPAndActivated()) then
			--_guihelper.MessageBox([[<div style="margin-left:14px;margin-top:16px;">你的魔法星能量值为0，还不能购买这件装备。快用能量石给魔法星补充能量再来购买吧！</div>]]);
		
			NPL.load("(gl)script/apps/Aries/Desktop/GUIHelper/CustomMessageBox.lua");
			_guihelper.Custom_MessageBox("你的魔法星能量值为0，还不能购买这件装备。快用能量石给魔法星补充能量再来购买吧！",function(result)
				if(result == _guihelper.DialogResult.Yes)then
					--NPL.load("(gl)script/apps/Aries/VIP/PurChaseEnergyStone.lua");
					--local PurchaseEnergyStone = commonlib.gettable("MyCompany.Aries.Inventory.PurChaseEnergyStone");
					--PurchaseEnergyStone.Show();
					local command = System.App.Commands.GetCommand("Profile.Aries.PurchaseItemWnd");
					if(command) then
						command:Call({gsid = 998,callback=callback});
					end                    
				end
			end,_guihelper.MessageBoxButtons.YesNo,{yes = "Texture/Aries/Common/GotMagicStone_32bits.png; 0 0 153 49", no = "Texture/Aries/Common/Later_32bits.png; 0 0 153 49"});

			return;
		end
	end
	
	local command = System.App.Commands.GetCommand("Profile.Aries.PurchaseItemWnd");
	if(command) then
		command:Call({gsid = gsid,callback=callback});
	end
	
	--_guihelper.MessageBox("你确定要购买 #"..tostring(gsid).." 物品么？", function(result) 
		--if(_guihelper.DialogResult.Yes == result) then
			--Map3DSystem.Item.ItemManager.PurchaseItem(gsid, 1, function(msg)
				--if(msg) then
					--log("+++++++Purchase item return: #"..tostring(gsid).." +++++++\n")
					--commonlib.echo(msg);
				--end
			--end);
		--elseif(_guihelper.DialogResult.No == result) then
			---- doing nothing if the user cancel the add as friend
		--end
	--end, _guihelper.MessageBoxButtons.YesNo);
end

function pe_item.OnClickGSItem_shortcut(gsid, isskipviptest, mcmlNode)
	-- use item by default
	local hasGSItem = Map3DSystem.Item.ItemManager.IfOwnGSItem;

	local bag = mcmlNode:GetNumber("bag");
	local excludebag = mcmlNode:GetNumber("excludebag");
	local bHas, guid, _, copies = hasGSItem(gsid, bag, excludebag);

	if(bHas) then
		local item = Map3DSystem.Item.ItemManager.GetItemByGUID(guid);
		if(item and item.guid > 0) then
			local on_use_item = mcmlNode:GetAttributeWithCode("on_use_item");
			if(on_use_item) then
				Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, on_use_item, gsid, mcmlNode);
			else
				item:OnClick("left");
			end
		end
	else
		local on_emptyclick_item = mcmlNode:GetAttributeWithCode("on_emptyclick_item");
		if(on_emptyclick_item) then
			Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, on_emptyclick_item, gsid, mcmlNode);
		else
			pe_item.OnClickGSItem(gsid, isskipviptest);
		end
	end
end

-- this function is only used by application. 
function pe_item.on_handle_click_shortcut(gsid, mcmlNode)
	local disable_event = mcmlNode:GetBool("disable_event");
	local IsRightClickDisable = mcmlNode:GetBool("IsRightClickDisable", System.options.version~="teen");

	local bHas, guid, _, copies = ItemManager.IfOwnGSItem(gsid);
	
	if(bHas) then
    	local item = Map3DSystem.Item.ItemManager.GetItemByGUID(guid);
		if(item and item.guid > 0 and item.OnClick) then
			if(not disable_event) then
				if(ItemManager.GetEvents():DispatchEvent({type = "pe_slot_OnClick" , item = item, })) then
					return;
				end
			end
			if(mouse_button == "right" and (not IsRightClickDisable)) then
				pe_slot.HandleRightClick(guid, mcmlNode)
			else
				if(item and item.guid > 0) then
					item.from_ui_click = true;
					if(item.IsCombatApparel and item:IsCombatApparel()) then
						item:OnClick(mouse_button, nil, nil, true); -- true for bShowStatsDiff
					else
						if(DockTip.NeedShowBar(item.gsid))then
							DockTip.OnClick_Item_NeedShowBar(item.gsid)
						else
							item:OnClick(mouse_button);
						end
					end
					item.from_ui_click = nil;
				end
			end
		end
    end
end

-- get the MCML value on the node
function pe_item.GetValue(mcmlNode)
	return mcmlNode:GetAttribute("gsid");
end

-- set the MCML value on the node
function pe_item.SetValue(mcmlNode, value)
	mcmlNode:SetAttribute("gsid", value);
	mcmlNode:SetAttribute("icon", nil);
	if(value) then
		local icon;
		local gsItem = Map3DSystem.Item.ItemManager.GetGlobalStoreItemInMemory(tonumber(value));
		if(gsItem) then
			icon = gsItem.icon;
			-- icon with gender
			if(System.options.version == "teen") then
				if(gsItem.template.class == 1) then
					local gender = MyCompany.Aries.Player.GetGender();
					if(gender == "female") then
						icon = gsItem.icon_female or icon;
					end
				end
			end
		else
			icon = "texture/alphadot.png";
		end
		mcmlNode:SetAttribute("icon", icon);
	end
end


----------------------------------------------------------------------
-- pe:item-shortcut: handles MCML tag <pe:item-shortcut>
----------------------------------------------------------------------
local pe_item_shortcut = {};
Map3DSystem.mcml_controls.pe_item_shortcut = pe_item_shortcut;
-- a mapping from button name to mcml node instance.
pe_item_shortcut.button_instances = {};

-- Renders the item's icon in specific size(defined in style)
function pe_item_shortcut.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	--local gsid = tonumber(mcmlNode:GetAttributeWithCode("gsid"));
	--if(type(gsid) ~= "number") then
		--log("error: must specify global store id for pe:item-shortcut tag\n");
		--return;
	--end

	local shortcut_id = tonumber(mcmlNode:GetAttributeWithCode("shortcut_id"));
	if(type(shortcut_id) ~= "number") then
		log("error: must specify shortcut id for pe:item-shortcut tag\n");
		return;
	end

	local gsid = mcmlNode:GetAttributeWithCode("gsid") or shortcut_gsids[shortcut_id] or 0;
	mcmlNode:SetAttribute("gsid", gsid);
	
	local isdragable = mcmlNode:GetBool("isdragable", true);
	
	-- insert into the pe_slot.shortcut_ContainingPageCtrls table if the pagectrl contains pe:item-shortcut tag
	local pageCtrl = mcmlNode:GetPageCtrl();
	if(pageCtrl and pageCtrl.name) then
		pe_slot.shortcut_ContainingPageCtrls[pageCtrl.name] = true;
	end

	if(gsid == 0) then
		-- gsid = 0 stands for empty item
		mcmlNode:SetAttribute("guid", 0);
		if(shortcut_id) then
			mcmlNode:SetAttribute("isshortcut", true);
			mcmlNode:SetAttribute("shortcut_id", shortcut_id);
		end
		--mcmlNode:SetAttribute("isdragable", false);
		pe_item.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
		return;
	end

	local ItemManager = Map3DSystem.Item.ItemManager;
	local Player = MyCompany.Aries.Player;
	
	local css = mcmlNode:GetStyle(Map3DSystem.mcml_controls.pe_html.css["pe:item"]);
	local icon = mcmlNode:GetAttributeWithCode("icon") or css.background;

	local gsItem = ItemManager.GetGlobalStoreItemInMemory(gsid);
	if(not gsItem) then
		log("error: invalid gsid: "..tostring(gsid).." for pe:item-shortcut tag\n");
		return;
	end

	local hasGSItem = ItemManager.IfOwnGSItem;

	local bHas, guid = hasGSItem(gsid);
	if(bHas) then
		local item = ItemManager.GetItemByGUID(guid);
		if(item and item.guid > 0) then
			mcmlNode:SetAttribute("guid", item.guid);
			if(shortcut_id) then
				mcmlNode:SetAttribute("isshortcut", true);
				mcmlNode:SetAttribute("shortcut_id", shortcut_id);
			end
			mcmlNode:SetAttribute("tooltip", "page://script/apps/Aries/Desktop/GenericTooltip_InOne.html?gsid="..item.gsid.."&guid="..item.guid);
			
			mcmlNode:SetAttribute("isdragable", isdragable);
			pe_item.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
		end
	else
		-- empty item
		mcmlNode:SetAttribute("guid", 0);
		if(shortcut_id) then
			mcmlNode:SetAttribute("isshortcut", true);
			mcmlNode:SetAttribute("shortcut_id", shortcut_id);
		end
		if(gsid) then
			mcmlNode:SetAttribute("tooltip", "page://script/apps/Aries/Desktop/GenericTooltip_InOne.html?gsid="..gsid);
		end
		mcmlNode:SetAttribute("isdragable", isdragable);
		pe_item.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
	end
end