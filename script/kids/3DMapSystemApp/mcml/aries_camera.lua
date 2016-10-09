--[[
Title: 
Author(s): Leio
Date: 2010/06/21
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/aries_camera.lua");
-------------------------------------------------------
]]
local mcml = Map3DSystem.mcml;
local pairs = pairs
local ipairs = ipairs
local tostring = tostring
local tonumber = tonumber
local type = type
local string_find = string.find;
local string_format = string.format;
local string_gsub = string.gsub;
local string_lower = string.lower
local string_match = string.match;

local table_getn = table.getn;
local mcml_controls = commonlib.gettable("Map3DSystem.mcml_controls");
local LOG = LOG;
local CommonCtrl = commonlib.gettable("CommonCtrl");
local commonlib = commonlib.gettable("commonlib");

NPL.load("(gl)script/ide/MotionEx/MotionLine.lua");
local MotionLine = commonlib.gettable("MotionEx.MotionLine");

if(not Map3DSystem.mcml_controls) then Map3DSystem.mcml_controls = {} end
--在大于4号位的时候可以应用style2
local function canStyle2(mcmlNode)
	if(mcmlNode and mcmlNode.caster_slotid and mcmlNode.caster_slotid > 4 and mcmlNode.attr and mcmlNode.attr.style2) then
		return true;
	end	
end
--获取style2
local function getStyle2(mcmlNode)
	if(not mcmlNode)then return end
	if(mcmlNode.style2)then
		return mcmlNode.style2;
	end
	if(mcmlNode.attr and mcmlNode.attr.style2) then
		local style2 = {};
		
		local name, value;
		for name, value in string.gfind(mcmlNode.attr.style2, "([%w%-]+)%s*:%s*([^;]*)[;]?") do
			name = string_lower(name);
			value = string_gsub(value, "%s*$", "");
			style2[name] = value;
		end
		mcmlNode.style2 = style2;
		return style2;
	end
end
local function clipValues(x,y,z,dx,dy,dz,cameraobjectdistance,cameraliftupangle,cameraroty,dcameraobjectdistance,dcameraliftupangle,dcameraroty)
	x = tonumber(x);
	y = tonumber(y);
	z = tonumber(z);

	dx = tonumber(dx) or 0;
	dy = tonumber(dy) or 0;
	dz = tonumber(dz) or 0;

	cameraobjectdistance = tonumber(cameraobjectdistance);
	cameraliftupangle = tonumber(cameraliftupangle);
	cameraroty = tonumber(cameraroty);

	dcameraobjectdistance = tonumber(dcameraobjectdistance) or 0;
	dcameraliftupangle = tonumber(dcameraliftupangle) or 0;
	dcameraroty = tonumber(dcameraroty) or 0;

	if( x )then x = x + dx or 0; end
	if( y )then y = y + dy or 0; end
	if( z )then z = z + dz or 0; end
	if( cameraobjectdistance )then cameraobjectdistance = cameraobjectdistance + dcameraobjectdistance; end
	if( cameraliftupangle )then cameraliftupangle = cameraliftupangle + dcameraliftupangle; end
	if( cameraroty )then cameraroty = cameraroty + dcameraroty; end

	return x,y,z,cameraobjectdistance,cameraliftupangle,cameraroty,dx,dy,dz,dcameraobjectdistance,dcameraliftupangle,dcameraroty;
end
--camera
local aries_camera = {};
Map3DSystem.mcml_controls.aries_camera = aries_camera;

function aries_camera.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local id =  mcmlNode:GetString("id");
	local nodes = {};
	local childnode;


	for childnode in mcmlNode:next() do
		childnode.start_facing = mcmlNode.start_facing;
		childnode.end_facing = mcmlNode.end_facing;
		childnode.start_point_pos = mcmlNode.start_point_pos;
		childnode.end_point_pos = mcmlNode.end_point_pos;
		childnode.ground_pos = mcmlNode.ground_pos;
		childnode.caster_slotid = mcmlNode.caster_slotid;
		childnode.target_slotids = mcmlNode.target_slotids;

		local node = Map3DSystem.mcml_controls.create(rootName, childnode, bindingContext, _parent, left, top, width, height, style, parentLayout);
		if(node)then
			if(node.frametype)then
				node.FrameType = node.frametype;
				node.frametype = nil;
			end
			if(node.cameraobjectdistance)then
				node.CameraObjectDistance = node.cameraobjectdistance;
				node.cameraobjectdistance = nil;
			end
			if(node.cameraliftupangle)then
				node.CameraLiftupAngle = node.cameraliftupangle;
				node.cameraliftupangle = nil;
			end
			if(node.cameraroty)then
				node.CameraRotY = node.cameraroty;
				node.cameraroty = nil;
			end
			if(node.CameraRotY)then
				----确保在0-2pi之间
				node.CameraRotY = math.mod(node.CameraRotY,2*math.pi);
				if(node.CameraRotY < 0)then
					node.CameraRotY = node.CameraRotY + 2*math.pi;
				end
				--node.CameraRotY = math.mod(node.CameraRotY,math.pi);
			end
			table.insert(nodes,node);
		end
	end
	return nodes;
end

--camera:track
local aries_camera_track = {};
Map3DSystem.mcml_controls.aries_camera_track = aries_camera_track;

function aries_camera_track.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local css = mcmlNode:GetStyle(Map3DSystem.mcml_controls.pe_html.css["camera:track"], style) or {};
	local duration,frametype,x,y,z,dx,dy,dz,cameraobjectdistance,cameraliftupangle,cameraroty,dcameraobjectdistance,dcameraliftupangle,dcameraroty = 
		(css["duration"] or 0),(css["frametype"] or "None"),
		(css["x"] or nil),(css["y"] or nil),(css["z"] or nil),
		(css["dx"] or 0),(css["dy"] or 0),(css["dz"] or 0),
		(css["cameraobjectdistance"] or nil),(css["cameraliftupangle"] or nil),(css["cameraroty"] or nil),
		(css["dcameraobjectdistance"] or 0),(css["dcameraliftupangle"] or 0),(css["dcameraroty"] or 0);
		
	duration = tonumber(duration);
	x,y,z,cameraobjectdistance,cameraliftupangle,cameraroty,dx,dy,dz,dcameraobjectdistance,dcameraliftupangle,dcameraroty = clipValues(x,y,z,dx,dy,dz,cameraobjectdistance,cameraliftupangle,cameraroty,dcameraobjectdistance,dcameraliftupangle,dcameraroty);
		
	local node = {
		duration = duration,
		frametype = frametype,
		x = x,
		y = y,
		z = z,
		cameraobjectdistance = cameraobjectdistance,
		cameraliftupangle = cameraliftupangle,
		cameraroty = cameraroty,
	};
	return node;
end

--camera:point
--相对一个观察点
local aries_camera_point = {};
Map3DSystem.mcml_controls.aries_camera_point = aries_camera_point;

function aries_camera_point.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local css;
	if(canStyle2(mcmlNode))then
		css = getStyle2(mcmlNode) or {};
	else
		css = mcmlNode:GetStyle() or {};
	end
	local duration,frametype,x,y,z,dx,dy,dz,cameraobjectdistance,cameraliftupangle,cameraroty,dcameraobjectdistance,dcameraliftupangle,dcameraroty = 
		(css["duration"] or 0),(css["frametype"] or "None"),
		(css["x"] or nil),(css["y"] or nil),(css["z"] or nil),
		(css["dx"] or 0),(css["dy"] or 0),(css["dz"] or 0),
		(css["cameraobjectdistance"] or nil),(css["cameraliftupangle"] or nil),(css["cameraroty"] or nil),
		(css["dcameraobjectdistance"] or 0),(css["dcameraliftupangle"] or 0),(css["dcameraroty"] or 0);
		
	duration = tonumber(duration);
	x,y,z,cameraobjectdistance,cameraliftupangle,cameraroty,dx,dy,dz,dcameraobjectdistance,dcameraliftupangle,dcameraroty = clipValues(x,y,z,dx,dy,dz,cameraobjectdistance,cameraliftupangle,cameraroty,dcameraobjectdistance,dcameraliftupangle,dcameraroty);
	
	--caster or target or ground	
	local point =  mcmlNode:GetString("point");

	local start_facing = mcmlNode.start_facing;
	local end_facing = mcmlNode.end_facing;
	local start_point_pos = mcmlNode.start_point_pos;
	local end_point_pos = mcmlNode.end_point_pos;
	local ground_pos = mcmlNode.ground_pos;
	local caster_slotid = mcmlNode.caster_slotid;
	
	if(not start_facing or not end_facing or not start_point_pos or not end_point_pos or not ground_pos)then return end

	local eye_pos;
	if(point == "caster")then
		eye_pos = start_point_pos;
	elseif(point == "target")then
		eye_pos = end_point_pos;
	elseif(point == "ground")then
		eye_pos = ground_pos;
	elseif(point == "ground2")then
		eye_pos = ground_pos;
		local is_pvp;
		NPL.load("(gl)script/apps/Aries/Scene/WorldManager.lua");
		local WorldManager = commonlib.gettable("MyCompany.Aries.WorldManager");
		local world_info = WorldManager:GetCurrentWorld();
		if(world_info and world_info.team_mode and world_info.team_mode == "random_pvp")then
			is_pvp = true;
		end
		if(SystemInfo.GetField("name") == "Taurus")then
			is_pvp = true;
		end
		if(is_pvp and caster_slotid and caster_slotid > 4)then
			cameraroty = cameraroty + 3.14
		end
	end
	if(not eye_pos)then return end

	local node = {
		duration = duration,
		frametype = frametype,
		x = eye_pos[1] + dx,
		y = eye_pos[2] + dy,
		z = eye_pos[3] + dz,
		cameraobjectdistance = cameraobjectdistance,
		cameraliftupangle = cameraliftupangle,
		cameraroty = cameraroty,
	};
	return node;
end

--camera:empty
local aries_camera_empty = {};
Map3DSystem.mcml_controls.aries_camera_empty = aries_camera_empty;

function aries_camera_empty.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local css = mcmlNode:GetStyle() or {};
	local duration = (css["duration"] or 0)
	duration = tonumber(duration);
	local node = {
		duration = duration,
	};
	return node;
end
local aries_camera_dynamic = {};
Map3DSystem.mcml_controls.aries_camera_dynamic = aries_camera_dynamic;
--camera:dynamic
function aries_camera_dynamic.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local css = mcmlNode:GetStyle() or {};
	local duration,frametype,x,y,z,dx,dy,dz,cameraobjectdistance,cameraliftupangle,cameraroty,dcameraobjectdistance,dcameraliftupangle,dcameraroty = 
		(css["duration"] or 0),(css["frametype"] or "None"),
		(css["x"] or nil),(css["y"] or nil),(css["z"] or nil),
		(css["dx"] or 0),(css["dy"] or 0),(css["dz"] or 0),
		(css["cameraobjectdistance"] or nil),(css["cameraliftupangle"] or nil),(css["cameraroty"] or nil),
		(css["dcameraobjectdistance"] or 0),(css["dcameraliftupangle"] or 0),(css["dcameraroty"] or 0);
		
	duration = tonumber(duration);
	x,y,z,cameraobjectdistance,cameraliftupangle,cameraroty,dx,dy,dz,dcameraobjectdistance,dcameraliftupangle,dcameraroty = clipValues(x,y,z,dx,dy,dz,cameraobjectdistance,cameraliftupangle,cameraroty,dcameraobjectdistance,dcameraliftupangle,dcameraroty);
	
	local att = ParaCamera.GetAttributeObject();
	local x,y,z = ParaCamera.GetLookAtPos(); 
	local node = {
		duration = duration,
		frametype = frametype,
		x = x,
		y = y,
		z = z,
		cameraobjectdistance = att:GetField("CameraObjectDistance",5) + dcameraobjectdistance,
		cameraliftupangle = att:GetField("CameraLiftupAngle",0.4)  + dcameraliftupangle,
		cameraroty = att:GetField("CameraRotY",0) + dcameraroty,
	};
	return node;
end
local aries_camera_caster = {};
Map3DSystem.mcml_controls.aries_camera_caster = aries_camera_caster;
--camera:caster
function aries_camera_caster.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local css;
	if(canStyle2(mcmlNode))then
		css = getStyle2(mcmlNode) or {};
	else
		css = mcmlNode:GetStyle() or {};
	end
	local radius,angle,duration,frametype,x,y,z,dx,dy,dz,cameraobjectdistance,cameraliftupangle,cameraroty,dcameraobjectdistance,dcameraliftupangle,dcameraroty = 
		(css["radius"] or nil),(css["angle"] or nil),
		(css["duration"] or 0),(css["frametype"] or "None"),
		(css["x"] or nil),(css["y"] or nil),(css["z"] or nil),
		(css["dx"] or 0),(css["dy"] or 0),(css["dz"] or 0),
		(css["cameraobjectdistance"] or nil),(css["cameraliftupangle"] or nil),(css["cameraroty"] or nil),
		(css["dcameraobjectdistance"] or 0),(css["dcameraliftupangle"] or 0),(css["dcameraroty"] or 0);
		
	radius = tonumber(radius) or 4;
	angle = tonumber(angle) or 30;
	cameraobjectdistance = tonumber(cameraobjectdistance) or 2;
	cameraliftupangle = tonumber(cameraliftupangle) or -0.3;
	cameraroty = tonumber(cameraroty) or 0;

	duration = tonumber(duration);
	x,y,z,cameraobjectdistance,cameraliftupangle,cameraroty,dx,dy,dz,dcameraobjectdistance,dcameraliftupangle,dcameraroty = clipValues(x,y,z,dx,dy,dz,cameraobjectdistance,cameraliftupangle,cameraroty,dcameraobjectdistance,dcameraliftupangle,dcameraroty);

	local start_facing = mcmlNode.start_facing;
	local end_facing = mcmlNode.end_facing;
	local start_point_pos = mcmlNode.start_point_pos;
	local end_point_pos = mcmlNode.end_point_pos;
	local ground_pos = mcmlNode.ground_pos;

	if(not start_facing or not end_facing or not start_point_pos or not end_point_pos or not ground_pos)then return end
	local facing = start_facing;
	local center_x = start_point_pos[1];
	local center_y = start_point_pos[2];
	local center_z = start_point_pos[3];

	local rotation = 1.57 + facing + angle * 3.14 / 180;
	local eye_x = center_x + math.sin(rotation) * radius;
	local eye_y = center_y + 1;
	local eye_z = center_z + math.cos(rotation) * radius;

	local cameraroty = facing - 3.14 + angle * 3.14 / 180 + dcameraroty;
	local node = {
		duration = duration,
		frametype = frametype,

		x = eye_x + dx,
		y = eye_y + dy,
		z = eye_z + dz,
		cameraobjectdistance = cameraobjectdistance,
		cameraliftupangle = cameraliftupangle,
		cameraroty = cameraroty,
		
	};
	return node;
end
local aries_camera_target = {};
Map3DSystem.mcml_controls.aries_camera_target = aries_camera_target;
--camera:target
function aries_camera_target.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local css;
	if(canStyle2(mcmlNode))then
		css = getStyle2(mcmlNode) or {};
	else
		css = mcmlNode:GetStyle() or {};
	end
	local radius,angle,duration,frametype,x,y,z,dx,dy,dz,cameraobjectdistance,cameraliftupangle,cameraroty,dcameraobjectdistance,dcameraliftupangle,dcameraroty = 
		(css["radius"] or nil),(css["angle"] or nil),
		(css["duration"] or 0),(css["frametype"] or "None"),
		(css["x"] or nil),(css["y"] or nil),(css["z"] or nil),
		(css["dx"] or 0),(css["dy"] or 0),(css["dz"] or 0),
		(css["cameraobjectdistance"] or nil),(css["cameraliftupangle"] or nil),(css["cameraroty"] or nil),
		(css["dcameraobjectdistance"] or 0),(css["dcameraliftupangle"] or 0),(css["dcameraroty"] or 0);
	radius = tonumber(radius) or 4;
	angle = tonumber(angle) or 30;
	cameraobjectdistance = tonumber(cameraobjectdistance) or 2;
	cameraliftupangle = tonumber(cameraliftupangle) or -0.3;
	cameraroty = tonumber(cameraroty) or 0;

	duration = tonumber(duration);
	x,y,z,cameraobjectdistance,cameraliftupangle,cameraroty,dx,dy,dz,dcameraobjectdistance,dcameraliftupangle,dcameraroty = clipValues(x,y,z,dx,dy,dz,cameraobjectdistance,cameraliftupangle,cameraroty,dcameraobjectdistance,dcameraliftupangle,dcameraroty);
	local start_facing = mcmlNode.start_facing;
	local end_facing = mcmlNode.end_facing;
	local start_point_pos = mcmlNode.start_point_pos;
	local end_point_pos = mcmlNode.end_point_pos;
	local ground_pos = mcmlNode.ground_pos;

	if(not start_facing or not end_facing or not start_point_pos or not end_point_pos or not ground_pos)then return end
	local facing = end_facing;

	local center_x = end_point_pos[1];
	local center_y = end_point_pos[2];
	local center_z = end_point_pos[3];

	local rotation = 1.57 + facing - angle * 3.14 / 180;
	local eye_x = center_x + math.sin(rotation) * radius;
	local eye_y = center_y + 1;
	local eye_z = center_z + math.cos(rotation) * radius;


	--local cameraroty = facing + 3.14 - angle * 3.14 / 180 + dcameraroty;
	local cameraroty = facing - 3.14 - angle * 3.14 / 180 + dcameraroty;
	local node = {
		duration = duration,
		frametype = frametype,

		x = eye_x + dx,
		y = eye_y + dy,
		z = eye_z + dz,
		cameraobjectdistance = cameraobjectdistance,
		cameraliftupangle = cameraliftupangle,
		cameraroty = cameraroty,
		
	};
	return node;
end
local aries_camera_ground = {};
Map3DSystem.mcml_controls.aries_camera_ground = aries_camera_ground;
--camera:ground
function aries_camera_ground.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local css;
	if(canStyle2(mcmlNode))then
		css = getStyle2(mcmlNode) or {};
	else
		css = mcmlNode:GetStyle() or {};
	end
	local radius,angle,duration,frametype,x,y,z,dx,dy,dz,cameraobjectdistance,cameraliftupangle,cameraroty,dcameraobjectdistance,dcameraliftupangle,dcameraroty = 
		(css["radius"] or nil),(css["angle"] or nil),
		(css["duration"] or 0),(css["frametype"] or "None"),
		(css["x"] or nil),(css["y"] or nil),(css["z"] or nil),
		(css["dx"] or 0),(css["dy"] or 0),(css["dz"] or 0),
		(css["cameraobjectdistance"] or nil),(css["cameraliftupangle"] or nil),(css["cameraroty"] or nil),
		(css["dcameraobjectdistance"] or 0),(css["dcameraliftupangle"] or 0),(css["dcameraroty"] or 0);
	radius = tonumber(radius) or 0;
	angle = tonumber(angle) or 0;
	cameraobjectdistance = tonumber(cameraobjectdistance) or 0;
	cameraliftupangle = tonumber(cameraliftupangle) or 0;
	cameraroty = tonumber(cameraroty) or 0;

	duration = tonumber(duration);
	x,y,z,cameraobjectdistance,cameraliftupangle,cameraroty,dx,dy,dz,dcameraobjectdistance,dcameraliftupangle,dcameraroty = clipValues(x,y,z,dx,dy,dz,cameraobjectdistance,cameraliftupangle,cameraroty,dcameraobjectdistance,dcameraliftupangle,dcameraroty);
	local start_facing = mcmlNode.start_facing;
	local end_facing = mcmlNode.end_facing;
	local start_point_pos = mcmlNode.start_point_pos;
	local end_point_pos = mcmlNode.end_point_pos;
	local ground_pos = mcmlNode.ground_pos;

	if(not start_facing or not end_facing or not start_point_pos or not end_point_pos or not ground_pos)then return end
	local facing = 0;

	local center_x = ground_pos[1];
	local center_y = ground_pos[2];
	local center_z = ground_pos[3];

	local rotation = 1.57 + facing - angle * 3.14 / 180;
	local eye_x = center_x + math.sin(rotation) * radius;
	local eye_y = center_y;
	local eye_z = center_z + math.cos(rotation) * radius;


	local cameraroty = facing - 3.14 - angle * 3.14 / 180 + dcameraroty;
	local node = {
		duration = duration,
		frametype = frametype,

		x = eye_x + dx,
		y = eye_y + dy,
		z = eye_z + dz,
		cameraobjectdistance = cameraobjectdistance,
		cameraliftupangle = cameraliftupangle,
		cameraroty = cameraroty,
		
	};
	return node;
end
local aries_camera_follow = {};
Map3DSystem.mcml_controls.aries_camera_follow = aries_camera_follow;
--camera:follow
function aries_camera_follow.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local css;
	if(canStyle2(mcmlNode))then
		css = getStyle2(mcmlNode) or {};
	else
		css = mcmlNode:GetStyle() or {};
	end
	local duration,frametype,x,y,z,dx,dy,dz,cameraobjectdistance,cameraliftupangle,cameraroty,dcameraobjectdistance,dcameraliftupangle,dcameraroty = 
		(css["duration"] or 0),(css["frametype"] or "None"),
		(css["x"] or nil),(css["y"] or nil),(css["z"] or nil),
		(css["dx"] or 0),(css["dy"] or 0),(css["dz"] or 0),
		(css["cameraobjectdistance"] or nil),(css["cameraliftupangle"] or nil),(css["cameraroty"] or nil),
		(css["dcameraobjectdistance"] or 0),(css["dcameraliftupangle"] or 0),(css["dcameraroty"] or 0);
		
	duration = tonumber(duration);
	x,y,z,cameraobjectdistance,cameraliftupangle,cameraroty,dx,dy,dz,dcameraobjectdistance,dcameraliftupangle,dcameraroty = clipValues(x,y,z,dx,dy,dz,cameraobjectdistance,cameraliftupangle,cameraroty,dcameraobjectdistance,dcameraliftupangle,dcameraroty);

	local target =  mcmlNode:GetString("target");
	local node = {
		duration = duration,
		frametype = frametype,
		FollowTarget = target,
		AllowFollow = true,
		cameraobjectdistance = cameraobjectdistance,
		cameraliftupangle = cameraliftupangle,
		cameraroty = cameraroty,
	};
	return node;
end
local aries_camera_abcenter = {};
Map3DSystem.mcml_controls.aries_camera_abcenter = aries_camera_abcenter;
--camera:abcenter
function aries_camera_abcenter.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local css;
	if(canStyle2(mcmlNode))then
		css = getStyle2(mcmlNode) or {};
	else
		css = mcmlNode:GetStyle() or {};
	end
	local radius,angle,duration,frametype,x,y,z,dx,dy,dz,cameraobjectdistance,cameraliftupangle,cameraroty,dcameraobjectdistance,dcameraliftupangle,dcameraroty = 
		(css["radius"] or nil),(css["angle"] or nil),
		(css["duration"] or 0),(css["frametype"] or "None"),
		(css["x"] or nil),(css["y"] or nil),(css["z"] or nil),
		(css["dx"] or 0),(css["dy"] or 0),(css["dz"] or 0),
		(css["cameraobjectdistance"] or nil),(css["cameraliftupangle"] or nil),(css["cameraroty"] or nil),
		(css["dcameraobjectdistance"] or 0),(css["dcameraliftupangle"] or 0),(css["dcameraroty"] or 0);
	radius = tonumber(radius) or 0;
	angle = tonumber(angle) or 0;
	cameraobjectdistance = tonumber(cameraobjectdistance) or 0;
	cameraliftupangle = tonumber(cameraliftupangle) or 0;
	cameraroty = tonumber(cameraroty) or 0;

	duration = tonumber(duration);
	x,y,z,cameraobjectdistance,cameraliftupangle,cameraroty,dx,dy,dz,dcameraobjectdistance,dcameraliftupangle,dcameraroty = clipValues(x,y,z,dx,dy,dz,cameraobjectdistance,cameraliftupangle,cameraroty,dcameraobjectdistance,dcameraliftupangle,dcameraroty);
	local start_facing = mcmlNode.start_facing;
	local end_facing = mcmlNode.end_facing;
	local start_point_pos = mcmlNode.start_point_pos;
	local end_point_pos = mcmlNode.end_point_pos;
	local ground_pos = mcmlNode.ground_pos;

	if(not start_facing or not end_facing or not start_point_pos or not end_point_pos or not ground_pos)then return end
	local facing = 0;

	local center_x = ground_pos[1];
	local center_y = ground_pos[2];
	local center_z = ground_pos[3];

	local eye_x = start_point_pos[1] + (end_point_pos[1] - start_point_pos[1]) / 2;
	local eye_y = start_point_pos[2] + (end_point_pos[2] - start_point_pos[2]) / 2;
	local eye_z = start_point_pos[3] + (end_point_pos[3] - start_point_pos[3]) / 2;
	facing = math.atan2((end_point_pos[1] - start_point_pos[1]), (end_point_pos[3] - start_point_pos[3])) - math.pi/2;

	cameraroty = facing + dcameraroty;
	local node = {
		duration = duration,
		frametype = frametype,

		x = eye_x + dx,
		y = eye_y + dy,
		z = eye_z + dz,
		cameraobjectdistance = cameraobjectdistance,
		cameraliftupangle = cameraliftupangle,
		cameraroty = cameraroty,
		
	};
	return node;
end
local aries_camera_abgcenter = {};
Map3DSystem.mcml_controls.aries_camera_abgcenter = aries_camera_abgcenter;
--camera:abgcenter
function aries_camera_abgcenter.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local css;
	if(canStyle2(mcmlNode))then
		css = getStyle2(mcmlNode) or {};
	else
		css = mcmlNode:GetStyle() or {};
	end
	local radius,angle,duration,frametype,x,y,z,dx,dy,dz,cameraobjectdistance,cameraliftupangle,cameraroty,dcameraobjectdistance,dcameraliftupangle,dcameraroty = 
		(css["radius"] or nil),(css["angle"] or nil),
		(css["duration"] or 0),(css["frametype"] or "None"),
		(css["x"] or nil),(css["y"] or nil),(css["z"] or nil),
		(css["dx"] or 0),(css["dy"] or 0),(css["dz"] or 0),
		(css["cameraobjectdistance"] or nil),(css["cameraliftupangle"] or nil),(css["cameraroty"] or nil),
		(css["dcameraobjectdistance"] or 0),(css["dcameraliftupangle"] or 0),(css["dcameraroty"] or 0);
	radius = tonumber(radius) or 0;
	angle = tonumber(angle) or 0;
	cameraobjectdistance = tonumber(cameraobjectdistance) or 0;
	cameraliftupangle = tonumber(cameraliftupangle) or 0;
	cameraroty = tonumber(cameraroty) or 0;

	duration = tonumber(duration);
	x,y,z,cameraobjectdistance,cameraliftupangle,cameraroty,dx,dy,dz,dcameraobjectdistance,dcameraliftupangle,dcameraroty = clipValues(x,y,z,dx,dy,dz,cameraobjectdistance,cameraliftupangle,cameraroty,dcameraobjectdistance,dcameraliftupangle,dcameraroty);
	local start_facing = mcmlNode.start_facing;
	local end_facing = mcmlNode.end_facing;
	local start_point_pos = mcmlNode.start_point_pos;
	local end_point_pos = mcmlNode.end_point_pos;
	local ground_pos = mcmlNode.ground_pos;

	if(not start_facing or not end_facing or not start_point_pos or not end_point_pos or not ground_pos)then return end
	local facing = 0;

	local center_x = ground_pos[1];
	local center_y = ground_pos[2];
	local center_z = ground_pos[3];

	local eye_x = start_point_pos[1] + (end_point_pos[1] - start_point_pos[1]) / 2;
	local eye_y = start_point_pos[2] + (end_point_pos[2] - start_point_pos[2]) / 2;
	local eye_z = start_point_pos[3] + (end_point_pos[3] - start_point_pos[3]) / 2;
	facing = math.atan2((end_point_pos[1] - start_point_pos[1]), (end_point_pos[3] - start_point_pos[3])) - math.pi/2;
	cameraroty = facing + dcameraroty;
	local node = {
		duration = duration,
		frametype = frametype,

		x = center_x + dx,
		y = center_y + dy,
		z = center_z + dz,
		cameraobjectdistance = cameraobjectdistance,
		cameraliftupangle = cameraliftupangle,
		cameraroty = cameraroty,
		
	};
	return node;
end
local aries_camera_agcenter = {};
Map3DSystem.mcml_controls.aries_camera_agcenter = aries_camera_agcenter;
--camera:agcenter
function aries_camera_agcenter.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local css;
	if(canStyle2(mcmlNode))then
		css = getStyle2(mcmlNode) or {};
	else
		css = mcmlNode:GetStyle() or {};
	end
	local radius,angle,duration,frametype,x,y,z,dx,dy,dz,cameraobjectdistance,cameraliftupangle,cameraroty,dcameraobjectdistance,dcameraliftupangle,dcameraroty = 
		(css["radius"] or nil),(css["angle"] or nil),
		(css["duration"] or 0),(css["frametype"] or "None"),
		(css["x"] or nil),(css["y"] or nil),(css["z"] or nil),
		(css["dx"] or 0),(css["dy"] or 0),(css["dz"] or 0),
		(css["cameraobjectdistance"] or nil),(css["cameraliftupangle"] or nil),(css["cameraroty"] or nil),
		(css["dcameraobjectdistance"] or 0),(css["dcameraliftupangle"] or 0),(css["dcameraroty"] or 0);
	radius = tonumber(radius) or 0;
	angle = tonumber(angle) or 0;
	cameraobjectdistance = tonumber(cameraobjectdistance) or 0;
	cameraliftupangle = tonumber(cameraliftupangle) or 0;
	cameraroty = tonumber(cameraroty) or 0;

	duration = tonumber(duration);
	x,y,z,cameraobjectdistance,cameraliftupangle,cameraroty,dx,dy,dz,dcameraobjectdistance,dcameraliftupangle,dcameraroty = clipValues(x,y,z,dx,dy,dz,cameraobjectdistance,cameraliftupangle,cameraroty,dcameraobjectdistance,dcameraliftupangle,dcameraroty);
	local start_facing = mcmlNode.start_facing;
	local end_facing = mcmlNode.end_facing;
	local start_point_pos = mcmlNode.start_point_pos;
	local end_point_pos = mcmlNode.end_point_pos;
	local ground_pos = mcmlNode.ground_pos;

	if(not start_facing or not end_facing or not start_point_pos or not end_point_pos or not ground_pos)then return end
	local facing = 0;

	local center_x = ground_pos[1];
	local center_y = ground_pos[2];
	local center_z = ground_pos[3];

	local eye_x = start_point_pos[1] + (ground_pos[1] - start_point_pos[1]) / 2;
	local eye_y = start_point_pos[2] + (ground_pos[2] - start_point_pos[2]) / 2;
	local eye_z = start_point_pos[3] + (ground_pos[3] - start_point_pos[3]) / 2;
	facing = math.atan2((ground_pos[1] - start_point_pos[1]), (ground_pos[3] - start_point_pos[3])) - math.pi/2;

	cameraroty = facing + dcameraroty;
	local node = {
		duration = duration,
		frametype = frametype,

		x = eye_x + dx,
		y = eye_y + dy,
		z = eye_z + dz,
		cameraobjectdistance = cameraobjectdistance,
		cameraliftupangle = cameraliftupangle,
		cameraroty = cameraroty,
		
	};
	return node;
end
local aries_camera_bgcenter = {};
Map3DSystem.mcml_controls.aries_camera_bgcenter = aries_camera_bgcenter;
--camera:agcenter
function aries_camera_bgcenter.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local css;
	if(canStyle2(mcmlNode))then
		css = getStyle2(mcmlNode) or {};
	else
		css = mcmlNode:GetStyle() or {};
	end
	local radius,angle,duration,frametype,x,y,z,dx,dy,dz,cameraobjectdistance,cameraliftupangle,cameraroty,dcameraobjectdistance,dcameraliftupangle,dcameraroty = 
		(css["radius"] or nil),(css["angle"] or nil),
		(css["duration"] or 0),(css["frametype"] or "None"),
		(css["x"] or nil),(css["y"] or nil),(css["z"] or nil),
		(css["dx"] or 0),(css["dy"] or 0),(css["dz"] or 0),
		(css["cameraobjectdistance"] or nil),(css["cameraliftupangle"] or nil),(css["cameraroty"] or nil),
		(css["dcameraobjectdistance"] or 0),(css["dcameraliftupangle"] or 0),(css["dcameraroty"] or 0);
	radius = tonumber(radius) or 0;
	angle = tonumber(angle) or 0;
	cameraobjectdistance = tonumber(cameraobjectdistance) or 0;
	cameraliftupangle = tonumber(cameraliftupangle) or 0;
	cameraroty = tonumber(cameraroty) or 0;

	duration = tonumber(duration);
	x,y,z,cameraobjectdistance,cameraliftupangle,cameraroty,dx,dy,dz,dcameraobjectdistance,dcameraliftupangle,dcameraroty = clipValues(x,y,z,dx,dy,dz,cameraobjectdistance,cameraliftupangle,cameraroty,dcameraobjectdistance,dcameraliftupangle,dcameraroty);
	local start_facing = mcmlNode.start_facing;
	local end_facing = mcmlNode.end_facing;
	local start_point_pos = mcmlNode.start_point_pos;
	local end_point_pos = mcmlNode.end_point_pos;
	local ground_pos = mcmlNode.ground_pos;

	if(not start_facing or not end_facing or not start_point_pos or not end_point_pos or not ground_pos)then return end
	local facing = 0;

	local center_x = ground_pos[1];
	local center_y = ground_pos[2];
	local center_z = ground_pos[3];

	local eye_x = end_point_pos[1] + (ground_pos[1] - end_point_pos[1]) / 2;
	local eye_y = end_point_pos[2] + (ground_pos[2] - end_point_pos[2]) / 2;
	local eye_z = end_point_pos[3] + (ground_pos[3] - end_point_pos[3]) / 2;
	facing = math.atan2((ground_pos[1] - end_point_pos[1]), (ground_pos[3] - end_point_pos[3])) - math.pi/2;

	cameraroty = facing + dcameraroty;
	local node = {
		duration = duration,
		frametype = frametype,

		x = eye_x + dx,
		y = eye_y + dy,
		z = eye_z + dz,
		cameraobjectdistance = cameraobjectdistance,
		cameraliftupangle = cameraliftupangle,
		cameraroty = cameraroty,
		
	};
	return node;
end