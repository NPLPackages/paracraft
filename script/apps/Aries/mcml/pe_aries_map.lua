--[[
Title: the map tag used in aries
Author(s): LiXizhi
Date: 2011/5/17
Desc: 
---++ pe:aries_map
usually one can create multiple maps with different stuffs on it for the same map. 
<verbatim>
	<pe:aries_map dest="{255,0,0}" style="width:32px;height:32px;margin:10px;">
		<pe:texture_grid render_target_type="texture" >
            <pe:textureassemble name="tex" DataSource='<%=DS_Func_tex %>' />
        </pe:texture_grid>
	</pe:aries_map>
</verbatim>
| *property* | *desc*|
| name | string, this should be enabled. |
| update_interval | in milliseconds. such as updating every 1000ms. |
| flip_vertical | whether to flip all points vertically. this is usually true for 3D avatar because the y axis direction is different in 3D than in 2d. |
| mask_texture | mask_texture |
| point_ui_radius | point_ui_radius |
| active_rendering | active_rendering |
| show_player | boolean | 
| use_player_camera_facing | boolean if true, player will use camera facing. this only works when show_player is true.  | 
| show_team | boolean | 
| show_friends | boolean |
| show_npc | boolean |
| show_opc | boolean |
| hide_names | boolean ; whether to show names for team, opc, etc. |
| ClipCircle | string of "center_x, center_y, radius" like "20000,20000,500" or a table like {center_x=0, center_y=0, radius=100} |
| zorder | if specified a parent container of the same zorder will be created in its place. otherwise it will create on the default container. |
| center_on_player | boolean to center view on player | 
| map_boundary | string of "left, top, right, bottom" or a table like {left=0, ...}, if the ClipCircle is bigger than the map_boundary, then the map_boundary will be centered, regardless of center_on_player is true or false. if not specified, it means infinitly large. | 
| onmouseup | a function of function(mcmlNode, pos_x, pos_y) end, where pos_x and pos_y are logical coordinates in the map  |
| render_target_type in pe:texture_grid |  "texture" or "container", either one.  |
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/mcml/pe_aries_map.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/Display2D/viewport2d.lua");
NPL.load("(gl)script/apps/Aries/Team/TeamClientLogics.lua");
NPL.load("(gl)script/apps/GameServer/GSL.lua");
NPL.load("(gl)script/apps/Aries/Combat/Battlefield/BattlefieldClient.lua");
local BattlefieldClient = commonlib.gettable("MyCompany.Aries.Battle.BattlefieldClient");
local TeamClientLogics = commonlib.gettable("MyCompany.Aries.Team.TeamClientLogics");
local GSL_client = commonlib.gettable("Map3DSystem.GSL_client");
local viewport2d = commonlib.gettable("CommonCtrl.Display2D.viewport2d");
local Combat = commonlib.gettable("MyCompany.Aries.Combat");
-----------------------------------
-- pe:aries_map control
-----------------------------------
local pe_aries_map = commonlib.gettable("MyCompany.Aries.mcml_controls.pe_aries_map");


-- create view port 
function pe_aries_map.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	return mcmlNode:DrawDisplayBlock(rootName, bindingContext, _parent, left, top, width, height, parentLayout, style, pe_aries_map.render_callback);
end

-- call the render callback
function pe_aries_map.render_callback(mcmlNode, rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)
	local pageCtrl = mcmlNode:GetPageCtrl();
	local my_view = mcmlNode.my_view or viewport2d:new({
		name = mcmlNode:GetString("name"),
		flip_vertical = mcmlNode:GetBool("flip_vertical"),
	});
	mcmlNode.my_view = my_view;

	my_view:clear();
	local point_ui_radius = mcmlNode:GetNumber("point_ui_radius");
	if(point_ui_radius) then
		my_view:set_point_ui_radius(point_ui_radius);
	end

	local my_tex = my_view:get_texture_grid();
	
	local mask_texture = mcmlNode:GetString("mask_texture")
	local is_active_rendering = mcmlNode:GetBool("active_rendering");
	my_tex:set_active_rendering(is_active_rendering);
	
	if(mask_texture) then
		my_tex:set_mask_texture(mask_texture)
	end
	my_tex:clear();

	-- add child nodes
	local childnode;
	for childnode in mcmlNode:next() do
		if(type(childnode) == "table") then
			if(childnode.name=="pe:texture_grid") then
				my_tex.render_target_type = childnode:GetString("render_target_type") or "texture";
				-- static texture here
				local subnode;
				for subnode in childnode:next() do
					if(type(subnode) == "table" and subnode.name=="pe:texture") then
						local tmp = {left=subnode:GetNumber("left"),top=subnode:GetNumber("top"), right=subnode:GetNumber("right"), bottom=subnode:GetNumber("bottom"), background=subnode:GetString("filename")};
						my_tex:add(subnode:GetAttribute("name"), tmp);
					elseif(type(subnode) == "table" and subnode.name=="pe:textureassemble")then
						local DataSource = subnode:GetAttributeWithCode("DataSource");
						local subname = subnode:GetString("name") or "";
						if(DataSource == nil)then
							log("error: DataSource must be specified in pe:textureassemble: \n");
							commonlib.echo(subnode);
							return false;
						end

						subnode.datasource = DataSource;
						local count;
						if(type(subnode.datasource)=="function")then
							count = subnode.datasource() or 0;
						elseif(type(subnode.datasource)=="table")then
							count = #(subnode.datasource);
						end
						
						local i;

						if( count and count > 0 )then
							for i = 1,count do
								local row;
								if(type(subnode.datasource) == "function")then
									row = subnode.datasource(i);
								elseif(type(subnode.datasource) == "table")then
									row = subnode.datasource[i];									
								end

								if(row and type(row) == "table")then
									my_tex:add( subname .. i, row);
								end
							end
						end
					end
				end
			end
		end
	end

	----------------------------------
	local update_interval = mcmlNode:GetNumber("update_interval");

	local zorder = mcmlNode:GetNumber("zorder");
	local onmouseup = mcmlNode:GetAttributeWithCode("onmouseup");

	if(zorder or onmouseup) then
		local _this = ParaUI.CreateUIObject("container", "c", "_lt", left, top, right-left,bottom-top);
		_this.background = ""
		if(zorder) then
			_this.zorder = zorder;
		end
		_parent:AddChild(_this);
		_parent = _this;
		left, top, right, bottom = 0, 0, right-left, bottom-top;
		
		if(onmouseup) then
			_this:SetScript("onmouseup", function(obj)
				local x, y, _, _ = obj:GetAbsPosition();
				local location_x, location_y = my_view:GetPosByUIPoint(mouse_x - x, mouse_y - y, right, bottom);
				Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onmouseup, mcmlNode, location_x, location_y);
			end)
		else
			_this:GetAttributeObject():SetField("ClickThrough", true);
		end
	end

	local params = {
		left=left, top=top, right=right, bottom=bottom,
		show_player = mcmlNode:GetBool("show_player"),
		show_camera = mcmlNode:GetBool("show_camera"),
		show_team = mcmlNode:GetBool("show_team"),
		show_friends = mcmlNode:GetBool("show_friends"),
		show_npc = mcmlNode:GetBool("show_npc"),
		show_opc = mcmlNode:GetBool("show_opc"),
		hide_names = mcmlNode:GetBool("hide_names"),
		use_player_camera_facing = mcmlNode:GetBool("use_player_camera_facing"),
	}
	mcmlNode.my_view.params = params;
	params.parent_id =  _parent.id;

	if(update_interval) then
		
		mcmlNode.my_timer = mcmlNode.my_timer or commonlib.Timer:new({callbackFunc = function(timer)
			pe_aries_map.UpdateView(mcmlNode);
		end})
		mcmlNode.my_timer:Change(update_interval, update_interval);
	end

	-- clipping rect
	local ClipRect = mcmlNode:GetAttributeWithCode("ClipRect", nil, true);

	if(ClipRect and type(ClipRect) == "string")then
		local _centerx, _centery, _width, _height = string.match(ClipRect, "([%-%.%d]+),([%-%.%d]+),([%-%.%d]+),([%-%.%d]+)");
		_width = tonumber(_width);
		_height = tonumber(_height);
		_centerx = tonumber(_centerx);
		_centery = tonumber(_centery);

		my_view:clip_rect( _centerx, _centery, _width, _height );
	end

	local ClipCircle = mcmlNode:GetAttributeWithCode("ClipCircle", nil, true);
	if(ClipCircle)then
		local _centerx, _centery, _radius;
		if(type(ClipCircle) == "string") then
			_centerx, _centery, _radius = string.match(ClipCircle, "([%-%.%d]+),([%-%.%d]+),([%-%.%d]+)");
			_radius = tonumber(_radius);
			_centerx = tonumber(_centerx);
			_centery = tonumber(_centery);
		elseif(type(ClipCircle) == "table")then
			_radius = tonumber(ClipCircle.radius);
			_centerx = tonumber(ClipCircle.center_x);
			_centery = tonumber(ClipCircle.center_y);
		end
		my_view:clip_circle( _centerx, _centery, _radius );
	end	

	local MapBoundary = mcmlNode:GetAttributeWithCode("map_boundary", nil, true);
	
	if(MapBoundary) then
		if(type(MapBoundary) == "string") then
			local _left, _top, _right, _bottom = string.match(MapBoundary, "([%-%.%d]+),([%-%.%d]+),([%-%.%d]+),([%-%.%d]+)");
			my_view.map_boundary = {left=_left, top=_top, right=_right, bottom=_bottom};
		elseif(type(MapBoundary) == "table")then
			my_view.map_boundary = MapBoundary;
		end
	end

	-- populate with data
	pe_aries_map.UpdateView(mcmlNode);
	
	return true, false, true; -- ignore_onclick, ignore_background, ignore_tooltip;
end

-- text color for each school node
local school_text_color_map = {
	life = "#00cc00",
	fire = "#ff3300",
	death = "#333333",
	ice = "#3399ff",
	storm = "#ffcc00",
	default="#000000",
}
-- default font of the map text
local default_font = "System;11;norm";

-- draw node handler
-- @param ui_obj: the parent container
local function draw_mark_handler(obj, ui_obj)
	ui_obj.background = obj.background or "";
	ui_obj.rotation = obj.rotation or 0;
	ui_obj.zorder = obj.zorder or 0;
	local tooltip = obj.tooltip or "";
	if(tooltip ~= "") then
		if(ui_obj.tooltip ~= tooltip) then
			if(ui_obj.tooltip =="") then
				ui_obj:GetAttributeObject():SetField("ClickThrough", false);
			end
			ui_obj.tooltip = tooltip;
		end
	else
		if(ui_obj.tooltip~="") then
			ui_obj.tooltip = "";
			ui_obj:GetAttributeObject():SetField("ClickThrough", true);
		end
	end

	local text_ui = ui_obj:GetChild("text");
	if(not text_ui:IsValid()) then
		if(obj.text and obj.text ~= "") then
			text_ui = ParaUI.CreateUIObject("text", "text", "_lt", 0, obj.height or 32, 200, 22);
			ui_obj:AddChild(text_ui);
			text_ui.font = default_font;
			text_ui.shadow = true;
			_guihelper.SetFontColor(text_ui, school_text_color_map[obj.school] or school_text_color_map.default)
			text_ui.text = obj.text or "";
		end
	else
		text_ui.y = obj.height or 32;
		text_ui.text = obj.text or "";
	end
end

-- add agent to viewport
-- @param my_view: target viewport to add to. 
-- @param nid: nid or agent. need to be string
-- @param bg_size: node background image size
-- @param text: if text should be displayed below the icon. if "" it will be ignored.  if nil, it will be filled with user nick name if nid is specified. 
-- @param tooltip: if tooltip should be displayed when mouse over the icon. if "" it will be ignored.  if nil, it will be filled with user nick name if nid is specified. 
-- @param click_through: true to enable click_through. 
-- @return true if changed
local function AddAgentToViewport(my_view, nid, text, background, bg_size, tooltip, zorder, click_through)
	local agent;

	if(type(nid) == "table") then
		agent = nid;
		nid = agent.nid;
	else
		agent = GSL_client:FindAgent(nid);
	end
	
	local nid_number = tonumber(nid);
	local width, height = bg_size, bg_size;
	local school = Combat.GetSchool(if_else(System.User.nid==nid_number, nil, nid_number));
	if(not background and school) then
		background = format("Texture/Aries/WorldMaps/common/%s_arrow_32bits.png", school);
		width, height = 32, 32;
	end
		
	if(not text or not tooltip) then
		local agent_text;
		local user_info = Map3DSystem.App.profiles.ProfileManager.GetUserInfoInMemory(nid_number);
		if(user_info) then
			agent_text = user_info.nickname;
		else
			agent_text = nid;
		end
		text = text or agent_text;
		tooltip = tooltip or agent_text;
	end

	local bChanged;
	if(agent) then
		local x,z  = agent.x, agent.z;
		if (x and z) then
			local mark = my_view:get(nid);
			if(mark) then
				mark.marked = nil; -- unmark it. 
				if(mark.x ~= x or mark.y ~= z) then
					mark.x = x;
					mark.y = z;
					bChanged = true;
				end
				if(agent.facing and mark.rotation ~= (agent.facing + 1.57)) then
					mark.rotation = agent.facing + 1.57;
					bChanged = true;
				end
				if(mark.background ~= background) then
					mark.background = background;
					bChanged = true;
				end
				if(mark.tooltip ~= tooltip) then
					mark.tooltip = tooltip;
					bChanged = true;
				end
				if(mark.text ~= text) then
					mark.text = text;
					bChanged = true;
				end
				if(mark.width ~= width or mark.height ~= height) then
					mark.width = width;
					mark.height = height;
					bChanged = true;
				end
				if(mark.zorder ~= zorder) then
					mark.zorder = zorder;
					bChanged = true;
				end
			else
				my_view:add(nid, {
					ui_type = "container",
					x=x,
					y=z, 
					text = text,
					tooltip = tooltip,
					zorder = zorder,
					width = width,
					height = height,
					school = school,
					draw = draw_mark_handler,
					background = background,
					click_through = click_through,
					});
				bChanged = true;
			end
		end
	end
	return bChanged;
end

-- add or update a named point to view port
-- @param name: the point name string
-- @param point: {x,y,text,rotation, tooltip, school, width, height, background,zorder }
local function AddPointToViewport(my_view, name, point)
	local bChanged;
	local mark = my_view:get(name);
	if(mark) then
		mark.marked = nil; -- unmark it. 
		if(mark.x ~= point.x or mark.y ~= point.y) then
			mark.x = point.x;
			mark.y = point.y;
			bChanged = true;
		end
		if(mark.rotation ~= point.rotation and point.rotation) then
			mark.rotation = point.rotation;
			bChanged = true;
		end
		if(mark.background ~= point.background) then
			mark.background = point.background;
			bChanged = true;
		end
		if(mark.tooltip ~= point.tooltip) then
			mark.tooltip = point.tooltip;
			bChanged = true;
		end
		if(mark.text ~= point.text) then
			mark.text = point.text;
			bChanged = true;
		end
		if(mark.zorder ~= point.zorder) then
			mark.zorder = point.zorder;
			bChanged = true;
		end
		if(mark.width ~= point.width or mark.height ~= point.height) then
			mark.width = point.width;
			mark.height = point.height;
			bChanged = true;
		end
	else
		my_view:add(name, {
			ui_type = "container",
			x=point.x,
			y=point.y, 
			text = point.tooltip,
			width = point.width,
			height = point.height,
			draw = draw_mark_handler,
			text = point.text,
			zorder = point.zorder,
			school = point.school or "default", 
			background = point.background});
		bChanged = true;
	end
	return bChanged;
end

-- use this function to zoom in/out
-- @param radius: the new radius
-- @param bRefreshImmediate: true to refresh immediately. 
function pe_aries_map.SetClipRadius(mcmlNode, pageInstName, radius, bRefreshImmediate)
	local my_view = mcmlNode.my_view;
	if(my_view and radius and my_view.radius ~= radius) then
		my_view.radius = radius;
		my_view.changed = true;
		if(bRefreshImmediate) then
			pe_aries_map.UpdateView(mcmlNode);
		end
	end
end

-- use this function to zoom in/out
function pe_aries_map.GetClipRadius(mcmlNode, pageInstName)
	local my_view = mcmlNode.my_view;
	if(my_view) then
		return my_view.radius;
	end
end

pe_aries_map.default_player_icon = pe_aries_map.default_player_icon or "Texture/Aries/WorldMaps/common/maparrow_32bits.png"
pe_aries_map.default_camera_icon = pe_aries_map.default_camera_icon or "Texture/Aries/WorldMaps/common/camera_arrow.png"

-- called every second(etc) to update the canvas. 
function pe_aries_map.UpdateView(mcmlNode)
	local my_view = mcmlNode.my_view;
	if(not my_view or not my_view.params) then return end
	local params = my_view.params;
	
	local _parent = ParaUI.GetUIObject(params.parent_id);
	if(not _parent:IsValid()) then
		mcmlNode.my_timer:Change();
		return;
	elseif(not _parent:GetAttributeObject():GetField("VisibleRecursive",true)) then
		return;
	end
	local changed = my_view.changed;
	my_view:mark_all();
	-- for current player
	if(params.show_player) then
		local cur_player = my_view.cur_player;
		if(not cur_player) then
			cur_player = {nid = tostring(System.User.nid)};
			my_view.cur_player = cur_player;
		end
		local player = ParaScene.GetPlayer();
		cur_player.x, cur_player.y, cur_player.z = player:GetPosition();
		if(params.use_player_camera_facing) then
			cur_player.facing = ParaCamera.GetAttributeObject():GetField("CameraRotY", 0);
		else
			cur_player.facing = player:GetFacing();
		end
		
		changed = AddAgentToViewport(my_view, cur_player, "", pe_aries_map.default_player_icon, 32, "") or changed;
		if(changed and mcmlNode:GetBool("center_on_player") and my_view.cur_player) then
			my_view:clip_circle( my_view.cur_player.x, my_view.cur_player.z, my_view.radius);
		end
	end
	-- for current camera
	if(params.show_camera) then
		local cur_camera = my_view.cur_camera;
		if(not cur_camera) then
			cur_camera = {nid = "camera"};
			my_view.cur_camera = cur_camera;
		end
		local player = ParaScene.GetPlayer();
		cur_camera.x, cur_camera.y, cur_camera.z = player:GetPosition();
		cur_camera.facing = ParaCamera.GetAttributeObject():GetField("CameraRotY", 0);
		
		changed = AddAgentToViewport(my_view, cur_camera, "", pe_aries_map.default_camera_icon, 128, "") or changed;

		if(changed and mcmlNode:GetBool("center_on_camera") and my_view.cur_camera) then
			my_view:clip_circle( my_view.cur_camera.x, my_view.cur_camera.z, my_view.radius);
		end
	end
	
	local default_agent_tooltip;
	if(params.hide_names) then
		default_agent_tooltip = ""
	end

	-- for other player agent
	if(params.show_opc) then
		local my_side = BattlefieldClient:GetMySide();
		local nid, agent;
		local zorder = 2;
		for nid, agent in System.GSL_client:EachAgent() do
			if(nid~=System.GSL_client.agent and agent:has_avatar()) then
				if(my_side) then
					local agent_side = BattlefieldClient:GetPlayerSide(nid);
					if(agent_side) then
						if(agent_side == my_side) then
							changed = AddAgentToViewport(my_view, nid, "", "Texture/Aries/Desktop/CombatCharacterFrame/card/green.png",12, nil, zorder) or changed;
						else
							changed = AddAgentToViewport(my_view, nid, "", "Texture/Aries/Desktop/CombatCharacterFrame/card/red.png",12, nil, zorder) or changed;
						end
					end
				else
					changed = AddAgentToViewport(my_view, nid, "", "Texture/Aries/Login/Login/teen/loading_green_32bits.png",12, nil, zorder) or changed;
				end
			end
		end
	end

	-- for team members: this will override the opc display. 
	if(params.show_team) then
		local jc = TeamClientLogics:GetJC();
		if(jc) then
			local team = jc:GetTeam();
				
			local item = team:first();
			while (item) do
				changed = AddAgentToViewport(my_view, tostring(item.nid), default_agent_tooltip, nil, nil, "", nil) or changed;
				item = team:next(item);
			end
		end
	end

	-- custom points
	if(params.points) then
		local name, point
		for name, point in pairs(params.points) do
			changed = AddPointToViewport(my_view, name, point) or changed;
		end
	end


	if(my_view.map_boundary) then
		my_view:center_if_in_boundary(my_view.map_boundary);
	end

	-- TODO: for friends, etc. 
	if(params.show_friends) then
		-- TODO
	end
	my_view:remove_all_marked();

	if(changed) then
		my_view.changed = nil;
		my_view:draw(_parent, params.left, params.top, params.right, params.bottom);
	end
end

-- public method: one need to refresh the page or manually call "UpdateView" for points to take effect. 
-- pe_aries_map.UpdateView(mcmlNode);
-- @param mark_name: the point name string
-- @param mark_params: {x,y,text,rotation, tooltip, school, width, height, background,zorder}. if nil, it will clear the given point. 
-- @param bRefreshImmediate: true to refresh immediately. 
function pe_aries_map.ShowPoint(mcmlNode,instName, mark_name,mark_params, bRefreshImmediate)
	if(not mcmlNode or not mcmlNode.my_view or not mark_name)then return end
	local my_view = mcmlNode.my_view;
	if(not my_view or not my_view.params) then return end

	local params = my_view.params;
	params.points = params.points or {};
	params.points[mark_name] = mark_params;
	if(bRefreshImmediate) then
		pe_aries_map.UpdateView(mcmlNode);
	end
end

-- public method: get map point by name
-- return the point table with the given name. {x,y,text,rotation, tooltip, school, width, height, background,zorder}. if nil, it means not found. 
function pe_aries_map.GetPoint(mcmlNode,instName, mark_name)
	if(not mcmlNode or not mcmlNode.my_view or not mark_name or not mark_params)then return end
	local my_view = mcmlNode.my_view;
	if(not my_view or not my_view.params) then return end

	local params = my_view.params;
	if(params) then
		return params.points[mark_name];
	end
end

-- public method: clear all custom points
function pe_aries_map.ClearPoints(mcmlNode,instName, bRefreshImmediate)
	local my_view = mcmlNode.my_view;
	if(not my_view or not my_view.params) then return end

	local params = my_view.params;
	if(params) then
		params.points = nil;
		if(bRefreshImmediate) then
			pe_aries_map.UpdateView(mcmlNode);
		end
	end
end