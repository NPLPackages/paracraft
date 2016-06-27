--[[
Title: slot 
Author(s):  LiXizhi
Company: ParaEngine
Date: 2014.1.2
Desc: represents a bag position in an inventory(ContainerView). 
EntityManager.GetPlayer():GetDragItem() contains the current itemStack that is being dragged. 
use the lib:
---++ pe:mc_slot
| *name* | *desc* |
| bagpos | slot_index in containerView |
| ContainerView | the ContainerView object. if not specified, it will be EntityManager.GetPlayer().inventoryView. which is curent player's inventory view. |
| DestInventory | the default dest inventory when shift+left key is pressed. we will automatically send all items in this slot to the dest inventory.  |
| onclick | onclick event |
| onclick_empty | when clicking on empty slot |
| edit_mode | if "editor_only", drag operation is only possible in editor mode. |
| css.background2 | mouse over bg |

------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/pe_mc_slot.lua");
local pe_mc_slot = commonlib.gettable("MyCompany.Aries.Game.mcml.pe_mc_slot");
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/block_types.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemStack.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/TouchSession.lua");
NPL.load("(gl)script/ide/System/Core/PainterContext.lua");
local PainterContext = commonlib.gettable("System.Core.PainterContext");
local TouchSession = commonlib.gettable("MyCompany.Aries.Game.Common.TouchSession")
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local drag_src_mcml_node = nil;

-- create class
local pe_mc_slot = commonlib.gettable("MyCompany.Aries.Game.mcml.pe_mc_slot");

pe_mc_slot.block_icon_instances = {};

function pe_mc_slot.render_callback(mcmlNode, rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)
	local contView = mcmlNode:GetAttributeWithCode("ContainerView", nil, true) or EntityManager.GetPlayer().inventoryView;
	local bagpos = mcmlNode:GetAttributeWithCode("bagpos", nil, true);

	if(bagpos and contView) then
		bagpos = tonumber(bagpos);
		mcmlNode.slot = contView:GetSlot(bagpos);
		mcmlNode.slot_index = bagpos;
	end
	
	if(not contView or not mcmlNode.slot) then
		LOG.std(nil, "warn", "pe_mc_slot", "no container view or slot defined. ")
		return;
	end
	mcmlNode.contView = contView;
	-- default destination container
	mcmlNode.destInventory = mcmlNode:GetAttributeWithCode("DestInventory", nil, true);

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
	_this.background = "";

	_parent:AddChild(_this);

	mcmlNode.uiobject_id = _this.id;
	pe_mc_slot.block_icon_instances[mcmlNode.uiobject_id] = mcmlNode;

	mcmlNode.block_id = nil;
	mcmlNode.block_count = nil;

	local tooltip = mcmlNode:GetAttributeWithCode("tooltip");

	-- if tooltip is explicitly provided
	local tooltip_page = string.match(tooltip or "", "page://(.+)");
	if(tooltip_page) then
		local is_lock_position, use_mouse_offset;
		if(mcmlNode:GetAttribute("tooltip_is_lock_position") == "true") then
			is_lock_position, use_mouse_offset = true, false
		end
		CommonCtrl.TooltipHelper.BindObjTooltip(_this.id, tooltip_page, mcmlNode:GetNumber("tooltip_offset_x"), mcmlNode:GetNumber("tooltip_offset_y"),
			nil,nil,nil, nil, nil, nil, is_lock_position, use_mouse_offset);
	elseif(tooltip) then
		_this.tooltip = tooltip;
	else
		local is_lock_position, use_mouse_offset;
		if(mcmlNode:GetAttribute("tooltip_is_lock_position") == "true") then
			is_lock_position, use_mouse_offset = true, false
		end
		CommonCtrl.TooltipHelper.BindObjTooltip(_this.id, function()
			if(mcmlNode.slot) then
				local itemStack = mcmlNode.slot:GetStack();
				if(itemStack) then
					local tooltip = itemStack:GetTooltip();
					return "script/apps/Aries/Creator/Game/mcml/item_tooltip.html?text="..tooltip;
				end
			end
		end, mcmlNode:GetNumber("tooltip_offset_x"), mcmlNode:GetNumber("tooltip_offset_y"),
		nil,nil,nil, nil, nil, nil, is_lock_position, use_mouse_offset);
	end

	pe_mc_slot.RefreshMcmlNode(mcmlNode, _this, css);

	return true, true, true; -- ignore_onclick, ignore_background, ignore_tooltip;
end

-- this is just a temparory tag for offline mode
function pe_mc_slot.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	return mcmlNode:DrawDisplayBlock(rootName, bindingContext, _parent, left, top, width, height, parentLayout, style, pe_mc_slot.render_callback);
end

-- refresh according to current slot
-- @param _this: the ParaUIObject. if nil, it will be retrieved from the mcmlNode. 
-- @return true if updated, and false if the control no longer exist
function pe_mc_slot.RefreshMcmlNode(mcmlNode, _this, css)
	_this = _this or mcmlNode:GetControl();
	if(not _this) then
		return false;
	end

	local itemStack = mcmlNode.slot:GetStack();
	
	local block_id, block_count, item;
	if(itemStack and itemStack.count > 0) then
		block_id, block_count = itemStack.id, itemStack.count;
		item = itemStack:GetItem();
	else
		block_id, block_count = 0, 0;
	end
	
	if(block_id ~= mcmlNode.block_id) then
		
		mcmlNode.block_id = block_id;
		mcmlNode.block_count = block_count;

		local isOwnerDraw;
		if(item and item:IsOwnerDrawIcon()) then
			isOwnerDraw = true;
			_this:SetField("OwnerDraw", true);
			_this:SetScript("ondraw", function(obj)
				if(mcmlNode.slot) then
					local itemStack = mcmlNode.slot:GetStack();
					if(itemStack) then
						local item = itemStack:GetItem()
						if(item) then
							item:DrawIcon(PainterContext, obj.width, obj.height, itemStack);
						end
					end
				end
			end);
		end
		if(not isOwnerDraw) then
			_this:SetField("OwnerDraw", false);
			local background;
			local text;
			if(itemStack and block_count and block_count>0) then
				background = itemStack:GetIcon();	
				text = itemStack:GetIconText();
			end
			mcmlNode.icon = background or "";
			_this.background = background or "";
			_this.text = text or "";
		end

		local ontouch = mcmlNode:GetString("ontouch");
		if(ontouch and ontouch ~= "")then
			_this:SetScript("ontouch", pe_mc_slot.OnTouchSlot, mcmlNode);
		end
		if(css and css.background2) then
			_guihelper.SetVistaStyleButton(_this, nil, css.background2);
		end
		_this:SetScript("onclick", pe_mc_slot.OnClickSlot, mcmlNode);
	else
		-- same block_id but different count. 
		if(block_count~=mcmlNode.block_count) then 
			mcmlNode.block_count = block_count;

			if(block_count>1) then
				_this.text = tostring(block_count);
			else
				_this.text = "";
			end
		end
	end
	return true;
end

-- whether in the dragging state. 
pe_mc_slot.is_dragging = false;

-- this simulate the dragging cursor
local function GetGlobalDragContainer()
	local _slaveicon = ParaUI.GetUIObject("_g_drag_cont")
	if(_slaveicon:IsValid() ~= true) then
		_slaveicon = ParaUI.CreateUIObject("button", "_g_drag_cont", "_lt", -1000, -1000, 32, 32);
		_slaveicon.background = "";
		_slaveicon.zorder = 1000;
		_slaveicon:GetAttributeObject():SetField("TextOffsetY", 8)
		_slaveicon:GetAttributeObject():SetField("TextShadowQuality", 8);
		_guihelper.SetFontColor(_slaveicon, "#ffffffff");
		_guihelper.SetUIColor(_slaveicon, "#ffffffff");
		_slaveicon.font = "System;12;bold";
		_guihelper.SetUIFontFormat(_slaveicon, 38);
		_slaveicon.shadow = true;
		_slaveicon:AttachToRoot();
	end
	return _slaveicon;
end

local function GetGlobalDragCanvas()
	local _canvas = ParaUI.GetUIObject("_g_GlobalDragCanvas")
	if(_canvas:IsValid() ~= true) then
		_canvas = ParaUI.CreateUIObject("container", "_g_GlobalDragCanvas", "_fi", 0,0,0,0);
		_canvas.background = "";
		_canvas.zorder = 1001;
		_canvas.visible = false;
		
		_canvas:SetScript("onmousedown", function()	
			if(not pe_mc_slot.isTouchDragging) then
				pe_mc_slot.OnClickDragCanvas();
			end
		end)
		_canvas:SetScript("onframemove", function()
			if(not pe_mc_slot.isTouchDragging) then
				pe_mc_slot.OnDragFrameMove();
			end
		end);
		_canvas:AttachToRoot();
	end
	return _canvas;
end

function pe_mc_slot.CanDragOrEditNode(mcmlNode)
	if(mcmlNode) then
		local edit_mode = mcmlNode:GetAttributeWithCode("edit_mode", false);
		if(edit_mode) then
			if(edit_mode == "editor_only" and not GameLogic.GameMode:IsUseCreatorBag()) then
				return false;
			else
				return true;
			end
		else
			return true;
		end
	end
end

-- obsoleted: this is done via C++, which is good enough to simulate all touch drag and click actions. 
function pe_mc_slot.OnTouchSlotMouseSim(mcmlNode)
	local touch = msg;
	local touchSession = TouchSession.GetTouchSession(touch);
	if(touch.type == "WM_POINTERDOWN") then
		touchSession.tag = -1;
		
	elseif(touch.type == "WM_POINTERUPDATE") then
		if(touchSession.tag == -1) then
			if(touchSession:GetMaxDragDistance() >= touchSession:GetFingerSize()) then
				-- not a click
				local IsScrollableOrHasMouseWheelRecursive = false; -- TODO: check if the touched GUIObject allow mouse wheel.
				if(IsScrollableOrHasMouseWheelRecursive) then
					-- simulate a mouse wheel event(disable mouse down/up/move), if the UI control below is scrollable. 
					touchSession.tag = 3;
				else
					-- dragging operation start here
					touchSession.tag = 4;
					local can_edit = pe_mc_slot.CanDragOrEditNode(mcmlNode);
					if(can_edit) then
						local count;
						local onclick = mcmlNode:GetAttributeWithCode("onclick");
						if(not onclick) then
							-- dragging here
							drag_src_mcml_node = nil;
							local itemStack = mcmlNode.contView:ClickSlot(mcmlNode.slot_index, "SlotToPlayer", count, EntityManager.GetPlayer());
							if(itemStack) then
								drag_src_mcml_node = mcmlNode;
								pe_mc_slot.isTouchDragging = true;
								pe_mc_slot.UpdateDraggingDisplay(mcmlNode);
							end
						end
					end
				end
			end
		end
		if(pe_mc_slot.isTouchDragging) then
			pe_mc_slot.OnDragFrameMove(touch.x, touch.y);
		end
	elseif(touch.type == "WM_POINTERUP") then
		local click_event;
		echo({touchSession.tag, pe_mc_slot.isTouchDragging, "up"})
		if(touchSession.tag == 1) then
			click_event = "left";
		elseif(touchSession.tag == 2) then
			click_event = "right";
		elseif(touchSession.tag == -1) then
			if(touchSession:GetHoverTime() < 300) then
				click_event = "left";
			else
				click_event = "right";
			end
		end
		if(click_event) then
			local can_edit = pe_mc_slot.CanDragOrEditNode(mcmlNode);
			if(can_edit) then
				local onclick = mcmlNode:GetAttributeWithCode("onclick");
				if(onclick) then
					-- if there is onclick event
					mouse_button = click_event;
					Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onclick, mcmlNode);
				else
					local itemStack = mcmlNode.slot:GetStack();
					if(itemStack) then
						-- both left and right click defaults to right click to use the item in game mode. 
						itemStack:OnItemRightClick(EntityManager.GetPlayer());
					end
				end
			else
				local itemStack = mcmlNode.slot:GetStack();
				if(itemStack) then
					-- both left and right click defaults to right click to use the item in game mode. 
					itemStack:OnItemRightClick(EntityManager.GetPlayer());
				end
			end
		end
		if(pe_mc_slot.isTouchDragging) then
			-- has to set this, since we will drop to 3d scene if no ui target is found. 
			ParaUI.SetMousePosition(touch.x, touch.y);
			pe_mc_slot.OnClickDragCanvas(touch.x, touch.y, "left");
			pe_mc_slot.isTouchDragging = false;
			local itemStack = EntityManager.GetPlayer():GetDragItem();
			if(itemStack) then
				-- still got the item in hand? destroy it. 
				EntityManager.GetPlayer():SetDragItem(nil);
				pe_mc_slot.UpdateDraggingDisplay(mcmlNode);
			end
		end
		touchSession.tag = nil;
	end
end

function pe_mc_slot.OnTouchSlot(ui_obj, mcmlNode)
	local ontouch = mcmlNode:GetString("ontouch");
	if(ontouch == "")then
		ontouch = nil;
	end
	local result;
	if(ontouch) then
		-- the callback function format is function(mcmlNode, touchEvent) end
		result = Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, ontouch, mcmlNode, msg);
		return;
	end
	-- obsoleted: this is done via C++
	-- pe_mc_slot.OnTouchSlotMouseSim(mcmlNode);
end

function pe_mc_slot.OnClickSlot(ui_obj, mcmlNode)
	local bIsDragClick, count;

	local can_edit = pe_mc_slot.CanDragOrEditNode(mcmlNode);

	if(can_edit) then
		if(mouse_button=="left") then
			local onclick = mcmlNode:GetAttributeWithCode("onclick");
			local shift_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LSHIFT) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RSHIFT);
			local ctrl_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LCONTROL) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RCONTROL);

			if(ctrl_pressed and GameLogic.GameMode:IsUseCreatorBag()) then
				-- ctrl+left click to clone the given slot item only in editor mode. 
				local itemStack = mcmlNode.slot:GetStack();
				if(itemStack) then
					bIsDragClick = true;
					count = itemStack.count;
					mcmlNode.slot:AddItem(itemStack:Copy());
				end
			elseif(shift_pressed) then
				if(mcmlNode.destInventory) then
					mcmlNode.contView:ShiftClickSlot(mcmlNode.slot_index, nil, mcmlNode.destInventory);
				else
					-- shift click to remove all.
					mcmlNode.slot:RemoveItem(nil);
				end
			elseif(onclick) then
				-- if there is onclick event
				Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onclick, mcmlNode);
			else
				local itemStack = mcmlNode.slot:GetStack();
				local onclick_empty = mcmlNode:GetAttributeWithCode("onclick_empty");
				if(onclick_empty and not itemStack) then
					Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onclick_empty, mcmlNode);
				else
					-- dragging operation: left click to take all 
					bIsDragClick = true;
					count = nil;
				end
			end
		elseif(mouse_button=="right") then
			local itemStack = mcmlNode.slot:GetStack();
			if(itemStack) then
				local newStack, hasHandled = itemStack:OnItemRightClick(EntityManager.GetPlayer());
				if(not hasHandled) then
					-- right click to take half. 
					bIsDragClick = true;
					count = math.floor(itemStack.count / 2);
					if(count <= 0) then
						count = nil;
					end
				end
			end
		end
		if(bIsDragClick) then
			drag_src_mcml_node = nil;
			local itemStack = mcmlNode.contView:ClickSlot(mcmlNode.slot_index, "SlotToPlayer", count, EntityManager.GetPlayer());
			if(itemStack) then
				drag_src_mcml_node = mcmlNode;
				pe_mc_slot.UpdateDraggingDisplay(mcmlNode);
			end
		end
	else
		local itemStack = mcmlNode.slot:GetStack();
		if(itemStack) then
			-- both left and right click defaults to right click to use the item in game mode. 
			itemStack:OnItemRightClick(EntityManager.GetPlayer());
		end
	end
end

-- call this to update the dragging icon and count display according to current drag status. 
function pe_mc_slot.UpdateDraggingDisplay(mcmlNode)
	local itemStack = EntityManager.GetPlayer():GetDragItem();
	if(itemStack) then
		-- update icon and count
		local iconSize;
		if(mcmlNode) then
			local srcObj = mcmlNode:GetControl();
			if(srcObj) then
				iconSize = srcObj.width;
			end
		end

		local _slaveicon = GetGlobalDragContainer();
		if(_slaveicon:IsValid()) then
			local _canvas = GetGlobalDragCanvas();
			_canvas.visible = true;
			_slaveicon.background = itemStack:GetIcon() or "";
			if(iconSize) then
				_slaveicon.width = iconSize;
				_slaveicon.height = iconSize;
			end

			_slaveicon.text = itemStack:GetIconText();
		end
	else
		-- make invisible
		local _slaveicon = GetGlobalDragContainer();
		if(_slaveicon:IsValid()) then
			_slaveicon.translationx = 0;
			_slaveicon.translationy = 0;
			_slaveicon:ApplyAnim();
			_slaveicon:SetScript("onframemove", nil);
		end
		GetGlobalDragCanvas().visible = false;
	end
end

-- called every frame move to translate UI to current mouse cursor. 
-- @param x, y: if nil, the current mouse position is used. 
function pe_mc_slot.OnDragFrameMove(x, y)
	if(EntityManager.GetPlayer():GetDragItem()) then
		local _slaveicon = GetGlobalDragContainer();
		if(_slaveicon:IsValid()) then
			if(not x or not y) then
				x, y = ParaUI.GetMousePosition();
			end
			_slaveicon.translationx = x + 1000 - _slaveicon.width*0.5 + 1;
			_slaveicon.translationy = y + 1000 - _slaveicon.height + 1;
			_slaveicon.colormask = "255 255 255 200";
			_slaveicon:ApplyAnim();
		end
	end
end


-- @param m_x, m_y: mouse x, y position. 
-- @return the mcmlNode or nil if not found
function pe_mc_slot.GetNodeByMousePosition(m_x, m_y)
	if(not m_x) then
		m_x, m_y = ParaUI.GetMousePosition();
	end

	local candidateNode, candidatePath;
	local temp_removelist;
	for ui_id, mcmlNode in pairs(pe_mc_slot.block_icon_instances) do
		local _dragtarget = ParaUI.GetUIObject(ui_id);
		if(_dragtarget and _dragtarget:IsValid()) then
			local border = 6; -- using a border size of 6
			local x, y, width, height = _dragtarget:GetAbsPosition();
			if((m_x >= (x-border)) and (m_x <= (x + width + border)) and (m_y >= (y-border)) and (m_y <= (y + height+border))) then
				-- mark gsid

				-- ensure that the node is 95% visible in its parent container(just in case of a scrollable container)
				if(_dragtarget:GetField("VisibleRecursive", false) and not _guihelper.IsUIObjectClipped(_dragtarget, 0.2)) then
					local path = 0;
					local parent = _dragtarget;
					while parent and parent:IsValid() do
						local index = parent:GetField("index", 0);
						if(index>=0) then
							path = index + path / 100;
							parent = parent.parent;
						else
							break;
						end
					end
					-- compare with last candidates. 
					if(not candidatePath or candidatePath < path) then
						candidateNode = mcmlNode;
						candidatePath = path;
					end
				end
			end
		else
			temp_removelist = temp_removelist or {};
			temp_removelist[ui_id] = true;
		end
	end
	if(temp_removelist) then
		for ui_id, mcmlNode in pairs(temp_removelist) do
			pe_mc_slot.block_icon_instances[ui_id] = nil;
		end
	end
	return candidateNode;
end

-- user clicks on the fullscreen click drag canvas, we will find a valid target
-- @param m_x, m_y: if nil,the current mouse position is used. 
function pe_mc_slot.OnClickDragCanvas(m_x, m_y, m_button)
	local drag_item = EntityManager.GetPlayer():GetDragItem()
	if(drag_item) then
		local mouse_button = m_button or mouse_button;
		if(mouse_button == "left") then
			local mcmlNode = pe_mc_slot.GetNodeByMousePosition(m_x, m_y);
			
			if(mcmlNode) then
				if(not pe_mc_slot.CanDragOrEditNode(mcmlNode)) then
					return;
				end
				if(mcmlNode == drag_src_mcml_node) then
					if(mcmlNode.slot:HasStack()) then
						mcmlNode.contView:ClickSlot(mcmlNode.slot_index, "SlotToPlayer", 1, EntityManager.GetPlayer());
					else
						mcmlNode.contView:ClickSlot(mcmlNode.slot_index, "PlayerToSlot", nil, EntityManager.GetPlayer());
					end
				else
					mcmlNode.contView:ClickSlot(mcmlNode.slot_index, "PlayerToSlot", nil, EntityManager.GetPlayer());
				end
			else
				if(not m_x or not m_y) then
					m_x, m_y = ParaUI.GetMousePosition();
				end
				local _canvas = GetGlobalDragCanvas();
				local isVisibleBefore = _canvas.visible;
				if(isVisibleBefore) then
					_canvas.visible = false;
				end
				local temp = ParaUI.GetUIObjectAtPoint(m_x, m_y);
				if(not temp:IsValid()) then
					-- drop to 3d scene. 
					GameLogic.GetPlayerController():DropItemTo3DScene();
				else
					if(pe_mc_slot.isTouchDragging) then
						-- has to cancel dragging, so emulate a cancel right click here. 
						if(drag_src_mcml_node) then
							drag_src_mcml_node.contView:ClickSlot(drag_src_mcml_node.slot_index, "PlayerToSlot", 1, EntityManager.GetPlayer());
						end
					end
				end
			end
		elseif(mouse_button == "right") then
			if(drag_src_mcml_node) then
				drag_src_mcml_node.contView:ClickSlot(drag_src_mcml_node.slot_index, "PlayerToSlot", 1, EntityManager.GetPlayer());
			end
		end
	end
	pe_mc_slot.UpdateDraggingDisplay();
end

-- @param inventory: only refresh slots referencing given inventory. if nil, it will refresh all.
function pe_mc_slot.RefreshBlockIcons(inventory)
	local temp_removelist;

	local ui_id, mcmlNode;
	for ui_id, mcmlNode in pairs(pe_mc_slot.block_icon_instances) do
		if((not inventory or inventory == mcmlNode.slot.inventory) and not pe_mc_slot.RefreshMcmlNode(mcmlNode)) then
			temp_removelist = temp_removelist or {};
			temp_removelist[ui_id] = true;
		end
	end
	if(temp_removelist) then
		for ui_id, mcmlNode in pairs(temp_removelist) do
			pe_mc_slot.block_icon_instances[ui_id] = nil;
		end
	end
end