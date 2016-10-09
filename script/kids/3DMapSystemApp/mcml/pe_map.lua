--[[
Title: all controls for user related tags controls.
Author(s): Clayman, WangTian
Date: 2008/3/24
Desc: 
Revised: 2008/11/24
NOTE by WangTian: all previous Map3DSystem map tags are all DEPRECATED 
		only minimap is supported
Revised: 2009/4/10
NOTE by WangTian: all map related tags are redesigned to mark-in-map style

---+ Description
pe:map is a 2D canvas on MCML page that contains one or many pe:marks. Avatar position is shown as an arrow according to the current character 
facing in world scene. Avatar arrow is on top of almost everything shown in the pe:map region, including the map background itself, 
pe:mark, pushed pe:mark tooltip. Only normal pe:mark tooltip is over the avatar arrow which is only displayed on mouse over pe:mark.
Each pe:mark can mark a building or any map spot that require instant teleport. App command can be called if specified when the pe:mark invokes 
application specific functions. Non-map-related child tags are all discarded.

---++ pe:map tag
| *Property*		| *Descriptions*				 |
| type				| "2D" or "3D" (3D type is not implemented) |
| name				| unique local map instance name |
| background		| map background url |
| title				| map title name |
| width				| width in pixel like "100px" |
| height			| height in pixel like "100px" |
| RefPos1			| reference position 1 on both Map(in pixel) and Scene(in world coordinate, only x, z) e.g. "(102, 342), (20894, 18061)"|
| RefPos2			| reference position 2 on both Map(in pixel) and Scene(in world coordinate, only x, z) e.g. "(23.53, 92.94), (19687.31, 17508.432)"|
| AvatarArrow_bg	| avatar arrow background url |
| AvatarArrow_size	| avatar arrow ui object size |
| isShownAvatar		| is avatar arrow shown |
| isFixedFacing		| is avatar arrow facing fixed |

---++ pe:mark tag
| *Property*		| *Descriptions*				 |
| type				| "2D" or "3D" (3D type is not implemented) |
| background		| mark background url |
| highlight_bg		| highlight background, if not specified, use the background property |
| pressed_bg		| pressed background, if not specified, use the highlight_bg or background property |
| tooltip			| mouse over tooltip |
| commandname		| app command name that called when the pe:mark is pressed |
| MapPosition		| coordinate of mark on map(in pixel) "x, y, width, height" e.g. "42, 69, 32, 32" |
| worldpath			| teleport target world path, if not specified, use the current world |
| AvatarPosition	| coordinate of mark teleport position on scene(in world coordinate) "x, y, z"  e.g. "19687.31, 12.54, 17508.432" |
| CameraPosition	| camera setting of the teleport position "CameraObjectDistance, CameraLiftupAngle, CameraRotY"  e.g. "50, 1.2, 1.57" |
| portal_gsid		| if portal_gsid is empty, then this point can teleport. if portal_gsid isnot empty, judge if has the gsid_item or not. if has, can teleport, if not cannot teleport |
| portal_background	| if portal_gsid isnot empty and can teleport, use this portal_background url to replace background |
| portal_highlight_bg|if portal_gsid isnot empty and can teleport, use this portal_highlight_bg to replace highlight_bg |
| portal_pressed_bg	| if portal_gsid isnot empty and can teleport, use this portal_pressed_bg to replace pressed_bg |
| clickable			| true or false, if clickable is empty then use true as default value.


use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_map.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/timer.lua");
local bDebugMap = false;
----------------------------------------------------------------------
-- pe_map: handles MCML tag <pe:map>
----------------------------------------------------------------------
local pe_map = commonlib.gettable("Map3DSystem.mcml_controls.pe_map");

pe_map.LocalMaps = {};

-- animation file that played before and after the teleport process
pe_map.PreTeleportAnimation = "character/particles/summonNew.x";
pe_map.PostTeleportAnimation = "character/particles/LevelUp.x";

-- pe:map is a 2D canvas on MCML page that contains one or many pe:marks. Avatar position is shown as an arrow according to the current character 
--		facing in world scene. Avatar arrow is on top of almost everything shown in the pe:map region, including the map background itself, 
--		pe:mark, pushed pe:mark tooltip. Only normal pe:mark tooltip is over the avatar arrow which is only displayed on mouse over pe:mark.
--		Each pe:mark can mark a building or any map spot that require instant teleport. App command can be called if specified when the pe:mark invokes 
--		application specific functions.
-- NOTE: pe:map always discards non-map-related child tag
function pe_map.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local background = mcmlNode:GetAttributeWithCode("background") or "";
	local foreground = mcmlNode:GetAttributeWithCode("foreground") or "";
	
	local left, top, width, height = parentLayout:GetPreferredRect();
	local css = mcmlNode:GetStyle(Map3DSystem.mcml_controls.pe_html.css["pe:map"]) or {};
	local margin_left, margin_top, margin_bottom, margin_right = 
			(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
			(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	
			
	local tmpWidth = mcmlNode:GetNumber("width") or css.width
	if(tmpWidth) then
		if((left + tmpWidth+margin_left+margin_right)<width) then
			width = left + tmpWidth+margin_left+margin_right;
		else
			parentLayout:NewLine();
			left, top, width, height = parentLayout:GetPreferredRect();
			width = left + tmpWidth+margin_left+margin_right;
		end
	end
	local tmpHeight = mcmlNode:GetNumber("height") or css.height
	if(tmpHeight) then
		height = top + tmpHeight+margin_top+margin_bottom
	end
	
	if(css.position ~= "relative") then
		parentLayout:AddObject(width-left, height-top);
	end
	
	left = left + margin_left
	top = top + margin_top;
	width = width - margin_right;
	height = height - margin_bottom;
	
	local instName = mcmlNode:GetAttribute("name");
	
	if(instName ==  nil) then
		log("error: nil name for pe:map canvas\n")
		return;
	end
	
	local RefPos1 = mcmlNode:GetAttributeWithCode("RefPos1") or "";
	local RefPos2 = mcmlNode:GetAttributeWithCode("RefPos2") or "";
	local AvatarArrow_bg = mcmlNode:GetAttributeWithCode("AvatarArrow_bg") or "";
	local AvatarArrow_size = mcmlNode:GetNumber("AvatarArrow_size") or 15;
	local isShownAvatar = not (mcmlNode:GetAttribute("isShownAvatar") == "false");

	local isFixedFacing = mcmlNode:GetBool("isFixedFacing") or false;
	local worldname = mcmlNode:GetString("worldname") or "";
	
	-- don't show avatar position if in other world
	local worldDir = ParaWorld.GetWorldDirectory();
	if(worldDir ~= "worlds/MyWorlds/"..worldname.."/") then
		isShownAvatar = false;
	end
	
	if(RefPos1 == "" or RefPos2 == "") then
		log("error: 2 map reference positions must be specified in pe:map\n");
		return;
	end
	
	local RefPos1 = string.gsub(RefPos1, " ", "");
	local RefPos2 = string.gsub(RefPos2, " ", "");
	local mapX1, mapY1, avatarX1, avatarZ1 = string.match(RefPos1, "%(([%-%.%d]+),([%-%.%d]+)%),%(([%-%.%d]+),([%-%.%d]+)%)");
	local mapX2, mapY2, avatarX2, avatarZ2 = string.match(RefPos2, "%(([%-%.%d]+),([%-%.%d]+)%),%(([%-%.%d]+),([%-%.%d]+)%)");
	
	mapX1 = tonumber(mapX1);
	mapY1 = tonumber(mapY1);
	avatarX1 = tonumber(avatarX1);
	avatarZ1 = tonumber(avatarZ1);
	mapX2 = tonumber(mapX2);
	mapY2 = tonumber(mapY2);
	avatarX2 = tonumber(avatarX2);
	avatarZ2 = tonumber(avatarZ2);
	
	-- calculate the corner of the map
	local scaleX = (avatarX2 - avatarX1) / (mapX2 - mapX1);
	local scaleY = (avatarZ2 - avatarZ1) / (mapY2 - mapY1);
	local lefttopX = avatarX1 - mapX1 * scaleX;
	local lefttopZ = avatarZ1 - mapY1 * scaleY;
	local rightbottomX = avatarX2 + (width - mapX2) * scaleX;
	local rightbottomZ = avatarZ2 + (height - mapY2) * scaleY;
	
	local mapParams = {
		width = width, 
		height = height, 
		lefttopX = lefttopX, 
		lefttopZ = lefttopZ, 
		rightbottomX = rightbottomX, 
		rightbottomZ = rightbottomZ, 
		isShownAvatar = isShownAvatar, 
		isFixedFacing = isFixedFacing, 
		anchors = {},
	};
	
	if(isShownAvatar) then
		pe_map.LocalMaps[instName] = mapParams;
	end
	
	local _mapCanvas = ParaUI.CreateUIObject("container", instName, "_lt", left, top, width-left, height-top);
	--_mapCanvas.enabled = false;
	if(background == "") then
		_mapCanvas.background = css.background or "";
	else
		-- tricky: this allows dynamic images to update itself, _mapCanvas.background only handles static images with fixed size.
		_mapCanvas.background = background;
	end
	local fastrender = mcmlNode:GetBool("fastrender");
	if(fastrender == nil) then
		fastrender = true;
	end
	_mapCanvas.fastrender = fastrender;
	_guihelper.SetUIColor(_mapCanvas, css["background-color"] or "255 255 255");
	
	_parent:AddChild(_mapCanvas);
	
	if(string.find(background, "http://")) then
		-- TODO: garbage collect HTTP textures after it is no longer used?
	end
	
	-- render mark nodes
	local function render_node(childnode)
		if(type(childnode) ~= "table") then
			return true;
		end
		if(childnode.name == "pe:mark") then
			-- attach the pe:mark to pe:map canvas
			local background = childnode:GetAttributeWithCode("background") or "";
			local highlight_bg = childnode:GetAttributeWithCode("highlight_bg") or background;
			local pressed_bg = childnode:GetAttributeWithCode("pressed_bg") or highlight_bg;
			local tooltip = childnode:GetAttributeWithCode("tooltip") or "";
			local commandname = childnode:GetAttributeWithCode("commandname") or "";
			local MapPosition = childnode:GetAttributeWithCode("MapPosition") or "";
			local worldpath = childnode:GetAttributeWithCode("worldpath") or "";
			local AvatarPosition = childnode:GetAttributeWithCode("AvatarPosition") or "";
			local CameraPosition = childnode:GetAttributeWithCode("CameraPosition") or "";
			local portal_gsid = childnode:GetAttributeWithCode("portal_gsid") or "";
			local portal_background = childnode:GetAttributeWithCode("portal_background") or "";
			local portal_highlight_bg = childnode:GetAttributeWithCode("portal_highlight_bg") or portal_background;
			local portal_pressed_bg = childnode:GetAttributeWithCode("portal_pressed_bg") or portal_highlight_bg;
			local clickable = childnode:GetAttributeWithCode("clickable") or "";

			if(MapPosition == "") then
				log("error: map position must be specified in pe:mark: \n");
				commonlib.echo(childnode);
				return false;
			end
			
			local MapPosition = string.gsub(MapPosition, " ", "");
			local mapX, mapY, mapWidth, mapHeight = string.match(MapPosition, "([%-%.%d]+),([%-%.%d]+),([%-%.%d]+),([%-%.%d]+)");
			mapX = tonumber(mapX);
			mapY = tonumber(mapY);
			mapWidth = tonumber(mapWidth);
			mapHeight = tonumber(mapHeight);
			
			if(AvatarPosition == "" or CameraPosition == "") then
				-- this is a pure mark that doesn't relate with any click behavior
				local _mark = ParaUI.CreateUIObject("container", "mark", "_lt", mapX, mapY, mapWidth, mapHeight);
				--local background = childnode:GetAttributeWithCode("background") or "";
				_mark.background = background;
				--local animstyle = childnode:GetNumber("animstyle") or 0;
				--_mark.animstyle = animstyle;
				_mapCanvas:AddChild(_mark);
				if(childnode:GetBool("enabled") == false) then
					_mark.enabled = false;
				end
				-- show the childnode in MCML tag in the mark container
				local myLayout = Map3DSystem.mcml_controls.layout:new();
				myLayout:reset(0, 0, mapWidth, mapHeight);
				local childchildnode;
				for childchildnode in childnode:next() do
					Map3DSystem.mcml_controls.create("MarkChild", childchildnode, nil, _mark, 0, 0, mapWidth, mapHeight, nil, myLayout);
				end
			else
				-- this is a place teleport mark
				local AvatarPosition = string.gsub(AvatarPosition, " ", "");
				local CameraPosition = string.gsub(CameraPosition, " ", "");
				local sceneX, sceneY, sceneZ = string.match(AvatarPosition, "([%-%.%d]+),([%-%.%d]+),([%-%.%d]+)");
				sceneX = tonumber(sceneX);
				sceneY = tonumber(sceneY);
				sceneZ = tonumber(sceneZ);
				local CameraObjectDistance, CameraLiftupAngle, CameraRotY = string.match(CameraPosition, "([%-%.%d]+),([%-%.%d]+),([%-%.%d]+)");
				CameraObjectDistance = tonumber(CameraObjectDistance);
				CameraLiftupAngle = tonumber(CameraLiftupAngle);
				CameraRotY = tonumber(CameraRotY);
				
				-- mark button
				local _markCont = ParaUI.CreateUIObject("container", "markcont", "_lt", mapX, mapY, mapWidth, mapHeight);
				_markCont.background = "";
				_mapCanvas:AddChild(_markCont);
				
				local _mark = ParaUI.CreateUIObject("button", "mark", "_lt", 0, 0, mapWidth, mapHeight);
				local tooltip_page = string.match(tooltip or "", "page://(.+)");
				if(tooltip_page) then
					CommonCtrl.TooltipHelper.BindObjTooltip(_mark.id, tooltip_page);
				else
					_mark.tooltip = tooltip;
				end
				
				-- if portal_gsid is empty, then this point can teleport. if portal_gsid isnot empty, judge if has the gsid_item or not.
				clickable = string.lower(clickable);
				if (portal_gsid == "" )then
					if (clickable == "" or clickable == "true") then
						_mark:SetScript("onclick", pe_map.TeleportToPos, mcmlNode, sceneX, sceneY, sceneZ, CameraObjectDistance, CameraLiftupAngle, CameraRotY, worldname);
					end
				else
					local ItemManager = System.Item.ItemManager;
					local hasGSItem = ItemManager.IfOwnGSItem;
					portal_gsid = tonumber(portal_gsid);
					local CanTeleport = hasGSItem(portal_gsid);
					if (CanTeleport) then	
						background = portal_background;
						highlight_bg = portal_highlight_bg;
						pressed_bg = portal_pressed_bg;				
						if (clickable == "" or clickable == "true") then
							_mark:SetScript("onclick", pe_map.TeleportToPos, mcmlNode, sceneX, sceneY, sceneZ, CameraObjectDistance, CameraLiftupAngle, CameraRotY, worldname);
						end
					end
				end				

				--log("++++++++++++++map++++"..portal_gsid.."|"..background.."\n");
				--local background = childnode:GetAttributeWithCode("background") or "";
				--local highlight_bg = childnode:GetAttributeWithCode("highlight_bg") or background;
				--local pressed_bg = childnode:GetAttributeWithCode("pressed_bg") or highlight_bg;
				if(background == highlight_bg and highlight_bg == pressed_bg) then
					-- the same background for 3 background status
					_mark.background = background;
				else
					-- 3 background status
					_guihelper.SetVistaStyleButton3(_mark, background, highlight_bg, background, pressed_bg);
				end
				if(childnode:GetBool("alwaysmouseover")) then
					_mark:GetAttributeObject():SetField("AlwaysMouseOver", true);
				end

				_markCont:AddChild(_mark);
			end
		elseif(childnode.name == "pe:map-anchor") then
			local AvatarPosition = childnode:GetAttributeWithCode("AvatarPosition") or "";
			local sceneX, sceneZ = string.match(AvatarPosition, "([%-%.%d]+), ([%-%.%d]+)");
			sceneX = tonumber(sceneX);
			sceneZ = tonumber(sceneZ);
			local MapCoord = childnode:GetAttributeWithCode("MapCoord") or "";
			local coordX, coordY = string.match(MapCoord, "([%-%.%d]+), ([%-%.%d]+)");
			coordX = tonumber(coordX);
			coordY = tonumber(coordY);
			table.insert(mapParams.anchors, {
				scenePos = {sceneX, sceneZ}, -- scene position
				mapPos = {coordX, coordY}, -- map position
			});
			
			if(bDebugMap) then
				-- marker effect
				local params = {
					asset_file = "character/v5/temp/Effect/Moonfire_Impact_Base.x",
					start_position = {sceneX, 3, sceneZ},
					duration_time = 8000000,
					force_name = "mapanchor"..#(mapParams.anchors),
					begin_callback = function() 
					end,
					end_callback = function()
					end,
				};
				local EffectManager = MyCompany.Aries.EffectManager;
				EffectManager.CreateEffect(params);
				
				-- debug marker to show the anchors
				local _mark = ParaUI.CreateUIObject("button", "fafefew", "_lt", coordX - 16, coordY - 16, 32, 32);
				_mark.background = "texture/aries/cursor/fire.tga";
				_mark.text = #(mapParams.anchors).."";
				_mapCanvas:AddChild(_mark);
			end
		else
			local left, top, width, height = parentLayout:GetPreferredRect();
			Map3DSystem.mcml_controls.create(rootName, childnode, bindingContext, _parent, left, top, width, height, nil, parentLayout)

			local childnode_;
			for childnode_ in childnode:next() do
				if(type(childnode_) == "table") then
					render_node(childnode_);
				end
			end
		end
		return true;
	end

	-- add all child pe:mark nodes
	local childnode;
	for childnode in mcmlNode:next() do
		if(not render_node(childnode)) then
			break;
		end
	end
	
	if(foreground and foreground ~= "") then
		local _mapForeground = ParaUI.CreateUIObject("container", "foreground", "_lt", left, top, width-left, height-top);
		_mapForeground.background = mcmlNode:GetAbsoluteURL(foreground);
		_guihelper.SetUIColor(_mapForeground, css["background-color"] or "255 255 255");
		_mapForeground.enabled = false;
		_parent:AddChild(_mapForeground);
	end
	
	-- update the arrow according to player position
	if(isShownAvatar) then
		-- update the avatar arrow
		local _avatarArrow = ParaUI.CreateUIObject("container", "AvatarArrow", "_lt", 
				-AvatarArrow_size/2, -AvatarArrow_size/2, AvatarArrow_size, AvatarArrow_size);
		_avatarArrow.enabled = false;
		_avatarArrow.visible = false;
		_avatarArrow.zorder = 100; --  stay above the pe:marks and push layer
		_avatarArrow.background = AvatarArrow_bg;
		_mapCanvas:AddChild(_avatarArrow);

		pe_map.RegisterPeMapUpdateAvatarTimer();
	end
end

function pe_map.AppendTooltipForUIObj(id, page, force_offset_x, force_offset_y)
	-- start the timer if not created before
	if(not pe_map.update_tooltip_timer) then
		pe_map.update_tooltip_timer = commonlib.Timer:new({callbackFunc = function()
			local x, y = ParaUI.GetMousePosition();
			local temp = ParaUI.GetUIObjectAtPoint(x, y);
			if(temp and temp:IsValid() == true) then
				local x, y, _, __ = temp:GetAbsPosition();
				local params = pe_map.tooltip_page_pairs[temp.id];
				if(params and params.page and params.force_offset_x and params.force_offset_y) then
					pe_map.RefreshToolTipPage(params.page, x + params.force_offset_x, y + params.force_offset_y);
				elseif(params and params.page) then
					pe_map.RefreshToolTipPage(params.page);
				else
					pe_map.RefreshToolTipPage(nil);
				end
			else
				pe_map.RefreshToolTipPage(nil);
			end
		end});
	end
	pe_map.update_tooltip_timer:Change(0, 200);
	pe_map.tooltip_page_pairs = pe_map.tooltip_page_pairs or {};
	pe_map.tooltip_page_pairs[id] = {};
	pe_map.tooltip_page_pairs[id].page = page;
	pe_map.tooltip_page_pairs[id].force_offset_x = force_offset_x;
	pe_map.tooltip_page_pairs[id].force_offset_y = force_offset_y;
end

local offset_tooltip = 5000;
local last_tooltip_page = nil;
function pe_map.RefreshToolTipPage(page, force_position_x, force_position_y)
	local _tooltip_cont = ParaUI.GetUIObject("MCML_tooltip_page_cont");
	if(_tooltip_cont:IsValid() == false) then
		_tooltip_cont = ParaUI.CreateUIObject("container", "MCML_tooltip_page_cont", "_lt", offset_tooltip, offset_tooltip, 1000, 1000);
		_tooltip_cont.background = "";
		_tooltip_cont.enabled = false;
		_tooltip_cont.zorder = 10000;
		_tooltip_cont:AttachToRoot();
	end
	local used_width, used_height;
	if(page and not last_tooltip_page) then
		pe_map.page_tooltip = System.mcml.PageCtrl:new({url = page});
		pe_map.page_tooltip:Create("MCML_tooltip_page", _tooltip_cont, "_fi", 0, 0, 0, 0);
		used_width, used_height = pe_map.page_tooltip:GetUsedSize();
	elseif(page and page ~= last_tooltip_page) then
		_tooltip_cont:RemoveAll();
		pe_map.page_tooltip = System.mcml.PageCtrl:new({url = page});
		pe_map.page_tooltip:Create("MCML_tooltip_page", _tooltip_cont, "_fi", 0, 0, 0, 0);
		used_width, used_height = pe_map.page_tooltip:GetUsedSize();
	elseif(not page and last_tooltip_page) then
		_tooltip_cont:RemoveAll();
	else
		--if(pe_map.page_tooltip) then
			--used_width, used_height = pe_map.page_tooltip:GetUsedSize();
		--end
		return
	end
	if(page) then
		local x, y = ParaUI.GetMousePosition();
		local left = (force_position_x or x);
		local top =  (force_position_y or (y + 36));
		
		-- added by LiXizhi: 2010.9.30, so that the tip is always in screen.
		if(used_width and used_height) then
			local _, _, resWidth, resHeight = ParaUI.GetUIObject("root"):GetAbsPosition();

			local x,y = left, top;
	
			if((x + used_width) > resWidth) then
				x = resWidth - used_width;
			end
			if(x<0) then x = 0 end
			
			if((y + used_height) > resHeight) then
				y = resHeight - used_height;
			end
			if(y<0) then y = 0 end
			left = x;
			top = y;
		end
		_tooltip_cont.translationx = left - offset_tooltip;
		_tooltip_cont.translationy = top - offset_tooltip;

		_tooltip_cont:ApplyAnim();
	else
		local x, y = ParaUI.GetMousePosition();
		_tooltip_cont.translationx = 0;
		_tooltip_cont.translationy = 0;
		_tooltip_cont:ApplyAnim();
	end
	
	last_tooltip_page = page;
end

-- teleport to position
-- @param sceneX, sceneY, sceneZ: scene position in world coordinates
-- @param CameraObjectDistance, CameraLiftupAngle, CameraRotY: camera setting
-- @param worldname: world name specified. 
function pe_map.TeleportToPos(ui_obj, mcmlNode, sceneX, sceneY, sceneZ, CameraObjectDistance, CameraLiftupAngle, CameraRotY, worldname)
	
	local onclick = mcmlNode:GetString("OnTeleport");
	if(onclick and onclick ~= "")then
		Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onclick, mcmlNode);
	end
	
	-- call hook for Aries OnPurchaseItem
	if(Map3DSystem.SystemInfo.GetField("name") == "Aries") then
		local msg = { aries_type = "OnMapTeleport", 
			position = {sceneX, sceneY, sceneZ}, 
			camera = {CameraObjectDistance, CameraLiftupAngle, CameraRotY}, 
			worldname = worldname,
			bCheckBagWeight = true,
			wndName = "map", 
		};
		CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", msg);
	else
		ParaScene.GetPlayer():SetPosition(sceneX, sceneY, sceneZ);
		ParaScene.GetPlayer():SnapToTerrainSurface(0);
		ParaScene.GetPlayer():SetFacing(CameraRotY);
		local att = ParaCamera.GetAttributeObject();
		att:SetField("CameraObjectDistance", CameraObjectDistance);
		att:SetField("CameraLiftupAngle", CameraLiftupAngle);
		att:SetField("CameraRotY", CameraRotY);
	end
	
end

-- register the avatar update timer
function pe_map.RegisterPeMapUpdateAvatarTimer()
	NPL.load("(gl)script/ide/timer.lua");
	pe_map.timer = pe_map.timer or commonlib.Timer:new({callbackFunc = pe_map.UpdateAvatarPos});
	pe_map.timer:Change(200, 200);
end

local function isInTriangle(xa, ya, xb, yb, xc, yc, xd, yd)
	--¦xd  yd  1 ¦   ¦xd  yd  1 ¦   ¦xd  yd  1 ¦   ¦xa  ya  1 ¦ 
	--¦xa  ya  1 ¦ + ¦xa  ya  1 ¦ + ¦xb  yb  1 ¦ = ¦xb  yb  1 ¦ 
	--¦xb  yb  1 ¦   ¦xc  yc  1 ¦   ¦xc  yc  1 ¦   ¦xc  yc  1 ¦ 
	if ((xd * ya + xa * yb + xb * yd - xa * yd - xb * ya - xd * yb +
		xd * ya + xa * yc + yd * xc - xc * ya - xa * yd - xd * yc +
		xd * yb + xb * yc + xc * yd - xc * yb - xb * yd - xd * yc) - 
		(xa * yb + xb * yc + xc * ya - xc * yb - xb * ya - xa * yc) < 1) then
		return true;
	end
	return false;
end
				
local function distanceP2P(ax, ay, bx, by)
	local len_sq = (ax - bx)*(ax - bx) + (ay - by)*(ay - by);
	if(len_sq>0.001) then
		return math.sqrt(len_sq);
	else
		return 0;
	end
end
				
local function distanceP2Segment(px, py, ax, ay, bx, by)
	-- p to a-->b segment
	local l = distanceP2P(ax, ay, bx, by);
	if(l < 1) then -- a == b
		return 0;
	end
	local r = ((ay - py)*(ay - by) - (ax - px)*(bx - ax)) / (l * l);
	if(r > 1) then -- perpendicular projection of P is on the forward extention of AB
		return math.min(distanceP2P(px, py, bx, by), distanceP2P(px, py, ax, ay));
	elseif(r < 0) then  -- perpendicular projection of P is on the backward extention of AB
		return math.min(distanceP2P(px, py, bx, by), distanceP2P(px, py, ax, ay));
	else
		local s = ((ay - py)*(bx - ax) - (ax - px)*(by - ay))/(l * l);
		return math.abs(s * l);
	end
end

-- Note 2009.6.1: this is removed. pe_map will be deprecated or refactored to be used at a later time. 
-- the following code is not thread-safe to even load the file, so removed from IDE.
-- pe_map.RegisterPeMapUpdateAvatarTimer();
function pe_map.UpdateAvatarPos()
	local instName, mapParams;
	for instName, mapParams in pairs(pe_map.LocalMaps) do
		if(mapParams.isShownAvatar) then
			local _canvas = ParaUI.GetUIObject(instName);
			if(_canvas:IsValid() == true) then
				local _avatarArrow = _canvas:GetChild("AvatarArrow");
			
				local x, y, z = ParaScene.GetPlayer():GetPosition();
				local width = mapParams.width;
				local height = mapParams.height;
				local lefttopX = mapParams.lefttopX;
				local lefttopZ = mapParams.lefttopZ;
				local rightbottomX = mapParams.rightbottomX;
				local rightbottomZ = mapParams.rightbottomZ;
				local isShownAvatar = mapParams.isShownAvatar;
				local isFixedFacing = mapParams.isFixedFacing;
				
				local centerX = (lefttopX + rightbottomX) / 2;
				local centerZ = (lefttopZ + rightbottomZ) / 2;
				
				-- 20071.033203125, -0.79140192270279, 20039.06640625
				centerX = 20071.033203125;
				centerZ = 20039.06640625;
				
				local minDistSq = 100000;
				
				local marksPosAndDistSq = {};
				local i, anchor;
				if(#(mapParams.anchors)<3) then
					return;
				end
				for i, anchor in ipairs(mapParams.anchors) do
					
					local t_x = anchor.mapPos[1] - (anchor.mapPos[1] - width/2) * (anchor.scenePos[1] - x) / (anchor.scenePos[1] - centerX);
					local t_y = anchor.mapPos[2] - (anchor.mapPos[2] - height/2) * (anchor.scenePos[2] - z) / (anchor.scenePos[2] - centerZ);
					
					local DistSq = (anchor.scenePos[1] - x) * (anchor.scenePos[1] - x) + (anchor.scenePos[2] - z) * (anchor.scenePos[2] - z);
					
					table.insert(marksPosAndDistSq, {
						t_x = t_x, 
						t_y = t_y, 
						index = i,
						DistSq = DistSq,
						dist = math.sqrt(DistSq),
					});
				end
				
				table.sort(marksPosAndDistSq, function(a, b)
					return (a.DistSq < b.DistSq);
				end);
				
				local anchor1 = mapParams.anchors[marksPosAndDistSq[1].index];
				local anchor2 = mapParams.anchors[marksPosAndDistSq[2].index];
				local anchor3 = mapParams.anchors[marksPosAndDistSq[3].index];
				
				if(bDebugMap) then
					local _current1 = _canvas:GetChild("current1");
					if(not _current1 or _current1:IsValid() == false) then
						-- debug marker to show the anchors
						_current1 = ParaUI.CreateUIObject("button", "current1", "_lt", - 16, - 16, 32, 32);
						_current1.background = "texture/aries/andy/Red_32bits.png";
						_canvas:AddChild(_current1);
					end
					_current1.translationx = anchor1.mapPos[1];
					_current1.translationy = anchor1.mapPos[2];
					
					local _current2 = _canvas:GetChild("current2");
					if(not _current2 or _current2:IsValid() == false) then
						-- debug marker to show the anchors
						_current2 = ParaUI.CreateUIObject("button", "current2", "_lt", - 16, - 16, 32, 32);
						_current2.background = "texture/aries/andy/Red_32bits.png";
						_canvas:AddChild(_current2);
					end
					_current2.translationx = anchor2.mapPos[1];
					_current2.translationy = anchor2.mapPos[2];
					
					local _current3 = _canvas:GetChild("current3");
					if(not _current3 or _current3:IsValid() == false) then
						-- debug marker to show the anchors
						_current3 = ParaUI.CreateUIObject("button", "current3", "_lt", - 16, - 16, 32, 32);
						_current3.background = "texture/aries/andy/Green_32bits.png";
						_canvas:AddChild(_current3);
					end
					_current3.translationx = anchor3.mapPos[1];
					_current3.translationy = anchor3.mapPos[2];
					
					_current1.background = "texture/aries/andy/106.png";
					_current2.background = "texture/aries/andy/107.png";
					_current3.background = "texture/aries/andy/108.png";
				end
				
				local d12 = distanceP2Segment(x, z, anchor1.scenePos[1], anchor1.scenePos[2], anchor2.scenePos[1], anchor2.scenePos[2]);
				local d23 = distanceP2Segment(x, z, anchor1.scenePos[1], anchor1.scenePos[2], anchor2.scenePos[1], anchor2.scenePos[2]);
				local d31 = distanceP2Segment(x, z, anchor1.scenePos[1], anchor1.scenePos[2], anchor2.scenePos[1], anchor2.scenePos[2]);
				
				if((anchor1.mapPos[1] - anchor2.mapPos[1]) * (anchor1.scenePos[1] - anchor2.scenePos[1]) < 0) then
					d12 = 1000;
				end
				if((anchor2.mapPos[1] - anchor3.mapPos[1]) * (anchor2.scenePos[1] - anchor3.scenePos[1]) < 0) then
					d23 = 1000;
				end
				if((anchor3.mapPos[1] - anchor1.mapPos[1]) * (anchor3.scenePos[1] - anchor1.scenePos[1]) < 0) then
					d31 = 1000;
				end
				local dmin = math.min(d12, d23, d31);
				
				if(d12 == dmin) then
					if(bDebugMap) then
						commonlib.ShowDebugString("x", "d12")
					end
					translationx = anchor1.mapPos[1] + (anchor2.mapPos[1] - anchor1.mapPos[1]) * (x - anchor1.scenePos[1]) / (anchor2.scenePos[1] - anchor1.scenePos[1]);
				elseif(d23 == dmin) then
					if(bDebugMap) then
						commonlib.ShowDebugString("x", "d23")
					end
					translationx = anchor2.mapPos[1] + (anchor3.mapPos[1] - anchor2.mapPos[1]) * (x - anchor2.scenePos[1]) / (anchor3.scenePos[1] - anchor2.scenePos[1]);
				elseif(d31 == dmin) then
					if(bDebugMap) then
						commonlib.ShowDebugString("x", "d31")
					end
					translationx = anchor3.mapPos[1] + (anchor1.mapPos[1] - anchor3.mapPos[1]) * (x - anchor3.scenePos[1]) / (anchor1.scenePos[1] - anchor3.scenePos[1]);
				end
				
				local d12 = distanceP2Segment(x, z, anchor1.scenePos[1], anchor1.scenePos[2], anchor2.scenePos[1], anchor2.scenePos[2]);
				local d23 = distanceP2Segment(x, z, anchor1.scenePos[1], anchor1.scenePos[2], anchor2.scenePos[1], anchor2.scenePos[2]);
				local d31 = distanceP2Segment(x, z, anchor1.scenePos[1], anchor1.scenePos[2], anchor2.scenePos[1], anchor2.scenePos[2]);
				
				if((anchor1.mapPos[2] - anchor2.mapPos[2]) * (anchor1.scenePos[2] - anchor2.scenePos[2]) > 0) then
					d12 = 1000;
				end
				if((anchor2.mapPos[2] - anchor3.mapPos[2]) * (anchor2.scenePos[2] - anchor3.scenePos[2]) > 0) then
					d23 = 1000;
				end
				if((anchor3.mapPos[2] - anchor1.mapPos[2]) * (anchor3.scenePos[2] - anchor1.scenePos[2]) > 0) then
					d31 = 1000;
				end
				local dmin = math.min(d12, d23, d31);
				
				if(d12 == dmin) then
					if(bDebugMap) then
						commonlib.ShowDebugString("y", "d12")
					end
					translationy = anchor1.mapPos[2] + (anchor2.mapPos[2] - anchor1.mapPos[2]) * (z - anchor1.scenePos[2]) / (anchor2.scenePos[2] - anchor1.scenePos[2]);
				elseif(d23 == dmin) then
					if(bDebugMap) then
						commonlib.ShowDebugString("y", "d23")
					end
					translationy = anchor2.mapPos[2] + (anchor3.mapPos[2] - anchor2.mapPos[2]) * (z - anchor2.scenePos[2]) / (anchor3.scenePos[2] - anchor2.scenePos[2]);
				elseif(d31 == dmin) then
					if(bDebugMap) then
						commonlib.ShowDebugString("y", "d31")
					end
					translationy = anchor3.mapPos[2] + (anchor1.mapPos[2] - anchor3.mapPos[2]) * (z - anchor3.scenePos[2]) / (anchor1.scenePos[2] - anchor3.scenePos[2]);
				end
				_avatarArrow.translationx = translationx;
				_avatarArrow.translationy = translationy;
				
				-- show the avatar arrow
				_avatarArrow.visible = true;
				
				-- rotate the avatar arrow if not fixed
				if(isFixedFacing == true) then
					_avatarArrow.rotation = 0;
				else
					local angle = ParaScene.GetPlayer():GetFacing();
					angle = angle + math.pi/2;
					_avatarArrow.rotation = angle;
				end
			end
		end
	end
end


-- get the MCML value on the node
function pe_map.GetValue(mcmlNode)
	return mcmlNode:GetAttribute("value") or mcmlNode:GetInnerText();
end

-- set the MCML value on the node
function pe_map.SetValue(mcmlNode, value)
	if(type(value) == "string") then
		mcmlNode:SetInnerText(value)
	else
		mcmlNode:SetInnerText(nil);
	end	
end

-- get the UI value on the node
function pe_map.GetUIValue(mcmlNode, pageInstName)
	local ctl = mcmlNode:GetControl(pageInstName);
	if(ctl) then
		return ctl.text;
	end
end

-- set the UI value on the node
function pe_map.SetUIValue(mcmlNode, pageInstName, value)
	local ctl = mcmlNode:GetControl(pageInstName);
	if(ctl) then
		if(value) then
			local text = tostring(value);
			--resize control
			local textWidth = _guihelper.GetTextWidth(text) + 6
			ctl.width = textWidth;
			ctl.text = text;
		else
			ctl.text = "";
		end	
	end
end

-- zoom to a location on the map. 
-- @param x: in normalized world coordinate
-- @param y:
-- @param mode: "2D" or "3D", defaults to "2D"
function pe_map.ZoomToXY(mcmlNode, pageInstName, x, y, mode,zoom)
	local map = CommonCtrl.GetControl("mb_map");
	if(map == nil)then
		return
	end
	
	if(mode == "3D")then
		mode = Map3DApp.WorldMap.DisplayState.D3;
	else
		mode = Map3DApp.WorldMap.DisplayState.D2;
	end
	
	map:SetDisplayState(mode);
	map:SetZoomValue(zoom);
	map:SetViewPosition(x,y);
end


----------------------------------------------------------------------
-- pe_land: handles MCML tag <pe:land>
----------------------------------------------------------------------
--[[
local pe_land = {};
Map3DSystem.mcml_controls.pe_land = pe_land;

-- display land tile info
function pe_land.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	-- calculate size
	parentLayout:NewLine();
	local left, top, width, height = parentLayout:GetPreferredRect();
	local css = mcmlNode:GetStyle(Map3DSystem.mcml_controls.pe_html.css["pe:map"]) or {};
	local padding_left, padding_top, padding_bottom, padding_right = 
		(css["padding-left"] or css["padding"] or 0),(css["padding-top"] or css["padding"] or 0),
		(css["padding-bottom"] or css["padding"] or 0),(css["padding-right"] or css["padding"] or 0);
	local margin_left, margin_top, margin_bottom, margin_right = 
			(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
			(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	
	if(css.width) then
		if((left + css.width) < width) then
			width = left + css.width + margin_left  + margin_right
		end
	end
	if(css.height) then
		if((top + css.height) < height) then
			height = top + css.height + margin_top  + margin_bottom
		end
	end
	parentLayout:AddObject(width - left, height - top);
	parentLayout:NewLine();
	
	-- get tag attributes
	left = left + margin_left
	top = top + margin_top;
	width = width - margin_right;
	height = height - margin_bottom;
	
	local instName;
	if(mcmlNode:GetAttribute("name") or mcmlNode:GetAttribute("id")) then
		instName = mcmlNode:GetInstanceName(rootName);
	end	
	
	local _this = ParaUI.CreateUIObject("button", "pe_land", "_lt", left, top, width - left, height - top);
	_this.text = "购买"
	_parent:AddChild(_this);
	
end
-]]

----------------------------------------------------------------------
-- pe_mapmark: handles MCML tag <pe:mapmark>
----------------------------------------------------------------------


----------------------------------------------------------------------
-- pe_minimap: handles MCML tag <pe:minimap>
----------------------------------------------------------------------
local pe_minimap = {};
Map3DSystem.mcml_controls.pe_minimap = pe_minimap;

-- minimap uses the same mini scene graph as the main map application.
-- NOTE: if there are many such tags scattered on screen as well as the main map control,
--		they all chop a certain rectangle from the same main map mini scene graph
-- NOTE2: pe:map always discards non-map-related child tag
-- TODO: track focus in future
function pe_minimap.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	-- calculate size
	parentLayout:NewLine();
	local left, top, width, height = parentLayout:GetPreferredRect();
	local css = mcmlNode:GetStyle(Map3DSystem.mcml_controls.pe_html.css["pe:minimap"]) or {};
	local padding_left, padding_top, padding_bottom, padding_right = 
		(css["padding-left"] or css["padding"] or 0),(css["padding-top"] or css["padding"] or 0),
		(css["padding-bottom"] or css["padding"] or 0),(css["padding-right"] or css["padding"] or 0);
	local margin_left, margin_top, margin_bottom, margin_right = 
			(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
			(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	
	if(css.width) then
		if((left + css.width) < width) then
			width = left + css.width + margin_left  + margin_right
		end
	end
	if(css.height) then
		if((top + css.height) < height) then
			height = top + css.height + margin_top  + margin_bottom
		end
	end
	parentLayout:AddObject(width - left, height - top);
	parentLayout:NewLine();
	
	left = left + margin_left
	top = top + margin_top;
	width = width - margin_right;
	height = height - margin_bottom;
	
	--create map container
	local _minimap = ParaUI.CreateUIObject("container", "pe_minimap", "_lt", left, top, width - left, height - top);
	_parent:AddChild(_minimap);
	
	NPL.load("(gl)script/kids/3DMapSystemUI/MiniMap/MiniMapWnd.lua");
	Map3DSystem.UI.MiniMapWnd.Show(true, _minimap);
	
	do return end
	
	-- get tag attributes
	--get map center position
	local x = mcmlNode:GetNumber("x",0.5);
	local y = mcmlNode:GetNumber("y",0.5);

	--get display mode:3D or 2D
	local mode = mcmlNode:GetAttribute("mode","2D");
	if(mode == "3D")then
		mode = Map3DApp.WorldMap.DisplayState.D3;
	else
		mode = Map3DApp.WorldMap.DisplayState.D2;
	end
	
	--get zoom value
	local zoom = mcmlNode:GetNumber("zoom",0)
	--allow drag map?
	local allowDrag = mcmlNode:GetBool("canmove",false);
	--get display text	
	local value = mcmlNode:GetString("value") or mcmlNode:GetInnerText();
	
	--show map
	--we use the same map name as used in main map window
	--so,there is only one map instance
	local map = CommonCtrl.GetControl("mb_minimap");
	if(map == nil)then
		map = Map3DApp.WorldMap.Map:new{
			name = "mb_minimap";
		};
	end
	map:SetParentWnd(_minimap);
	map:SetEnable(allowDrag);
	map:Show(true);
	map:SetDisplayState(mode);
	map:SetZoomValue(zoom);
	map:SetViewPosition(x,y);
	
	local instName;
	if(mcmlNode:GetAttribute("name") or mcmlNode:GetAttribute("id")) then
		instName = mcmlNode:GetInstanceName(rootName);
	end	
	
	--render 2D mark 
	if(mode == Map3DApp.WorldMap.DisplayState.D2)then
		local _left =  (width - left)/2 - 16;
		local _top = (height - top)/2 - 16;
		local _this = ParaUI.CreateUIObject("container","s","_lt",0,0,32,32);
		_this.translationx = (width - left)/2 - 16;
		_this.translationy = (height - top)/2 - 32;
		_this.background = "Texture/worldMap/mark_5.png";
		_minimap:AddChild(_this);
		
		if(value) then
			local textWidth = _guihelper.GetTextWidth(value) + 6;
			local _this = ParaUI.CreateUIObject("button", instName or "s", "_lt", left, top, textWidth, 20);
			_this.background = "Texture/3DMapSystem/Startup/EasyFrame.png:2 2 2 2";
			_this.text = value;
			_this.translationx = (width - left)/2 - textWidth/2 + 15;
			_this.translationy = (height - top)/2-55;
			_parent:AddChild(_this);
		end	
	elseif(mode == Map3DApp.WorldMap.DisplayState.D3)then
		--TODO: render 3D mark
	end

	
	-- add all child MCML nodes
	--local childnode;
	--for childnode in mcmlNode:next() do
		--pe_minimap.showMapNode(mcmlNode, childnode, bindingContext);
	--end
end