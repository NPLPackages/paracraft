--[[
Title: Location tracker for 3D navigation
Author(s): LiXizhi
Date: 2010/10/14
Desc: 
---++ pe:locationtracker
pe:locationtracker is like the GPS which is a UI indicator about the direction and distance between the current player position and a target position. 
<verbatim>
	<pe:locationtracker dest="{255,0,0}" style="width:32px;height:32px;margin:10px;">
		<pe:label name="distance" style="color:#808080;text-align:center;margin-top:10px" />
	</pe:locationtracker>
	<pe:locationtracker dest="{255,0},{0,255},{20000,20000}" style="width:64px;height:64px;margin:10px;">
		<pe:label name="distance" style="color:#000000;font-weight:bold;text-align:center;width:64px;height:16px;margin-top:48px;" />
	</pe:locationtracker>
</verbatim>

| *property* | *desc*|
| source_name | the soruce character name. if nil or "", it is the current player  | 
| coordinate | "camera", "global". default to "global". use which coordinate system | 
-- | use_camera_facing | true or false. default to "true". if false, we will use facing of the camera. | 
| dest_name | the destination character name. if nil or "", in which case dest_x, dest_y, dest_z will be used as destination point | 
| dest| 3d position or array of dest positions. if it is 3d vector, the y component is ignored. | 
| dist_mode | "min_dist" or "min_angle". if there is multiple destination, this decides which distance is shown. if "min_dist" the closest targets is shown; if "min_angle", the target that the player is facing to is shown. default to "min_angle". |
| reach_dist | if we are within this distance, we will show "-" or  "reach_text", default to 2 |
| reach_text | the text to when we have reached a given target.  |
| worldname | The world name that the location belongs to. If the world name is different from the current game world's name, we will direct the user to the nearest portal NPC. | 

---++ pe:arrowpointer
an animated arrow or container with 8 directions
| *property* | *desc*|
| name | must be a unique name. duplicated name will delete previous arrow. | 
| direction | a value from 1 to 9. pointer direction, using the num pad as the direction | 
| animfile | default to "script/UIAnimation/CommonIcon.lua.table", others can be "script/UIAnimation/CommonBounce.lua.table" |
<verbatim>
 <pe:arrowpointer name="tip" direction="2" style="width:32px;height:32px;" />

 <pe:arrowpointer name="tip" direction="2" style="width:128px;height:25px;background:url(Texture/alphadot.png)" >
	<div>abc</div>
 </pe:arrowpointer>
</verbatim>

If one wants to show the distance to the closest target according to current player facing, then one can creat a child node whose name is "distance"
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/mcml/pe_locationtracker.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/math/vector.lua");
local math_abs = math.abs;
local vector3d = commonlib.gettable("mathlib.vector3d");

-----------------------------------
-- pe:locationtracker control
-----------------------------------
local pe_locationtracker = commonlib.gettable("MyCompany.Aries.mcml_controls.pe_locationtracker");

function pe_locationtracker.render_callback(mcmlNode, rootName, bindingContext, _parent, left, top, width, height, myLayout, css)
	-- create the background container
	local _this=ParaUI.CreateUIObject("container","b","_lt", left, top, width-left, height-top);
	_this.background = css.background or "";
	_parent:AddChild(_this);
	mcmlNode.uiobject_id = _this.id;

	-- read dest array 
	local dest_array = mcmlNode:GetAttributeWithCode("dest");
	if(type(dest_array) == "string") then
		dest_array = NPL.LoadTableFromString("{"..dest_array.."}");
	end
	if(type(dest_array) == "table") then
		local i, dest 
		for i, dest in ipairs(dest_array) do
			if(not dest[3]) then
				dest[2], dest[3] = 0, dest[2];
			else
				dest[2] = 0;
			end
			dest = vector3d:new(dest);
			LOG.info(dest:length2());
		end
		mcmlNode.dest_array = dest_array;
	end
	
	local dist_mode = mcmlNode:GetBool("dist_mode");
	local reach_dist = mcmlNode:GetNumber("reach_dist") or 2;
	local reach_text = mcmlNode:GetString("reach_text") or "--";
	local coordinate = mcmlNode:GetBool("coordinate");
	
	local srcBtn = ParaUI.CreateUIObject("button","src","_fi", 0,0,0,0);
	srcBtn.background = mcmlNode:GetString("arrow_bg") or "Texture/Aries/MapHelp/tracker/src_arrow.png";
	_this:AddChild(srcBtn);

	if(dest_array) then
		local i, dest
		for i, dest in ipairs(dest_array) do
			local destBtn = ParaUI.CreateUIObject("button", tostring(i), "_fi", 0,0,0,0);
			destBtn.background = mcmlNode:GetString("dest_bg") or "Texture/Aries/MapHelp/tracker/tracker_target.png";
			_this:AddChild(destBtn);
		end
	end
	-- for inner nodes
	mcmlNode:DrawChildBlocks_Callback(rootName, bindingContext, _parent, left, top, width, height, myLayout, css)

	-- create timer and update content
	mcmlNode.timer = mcmlNode.timer or commonlib.Timer:new({callbackFunc = function(timer)
		local parentCtl = ParaUI.GetUIObject(mcmlNode.uiobject_id);
		if(not parentCtl:IsValid()) then
			timer:Change();
			return;
		end
		if (parentCtl) then
			local src_name = mcmlNode:GetString("source_name");
			local src_pos, src_facing;
			if(not src_name or src_name == "") then
				local player = ParaScene.GetPlayer();
				src_pos = vector3d:new(player:GetPosition());
				src_pos.y = 0;
				src_facing = player:GetFacing();
			else
				local player = ParaScene.GetObject(src_name);
				src_pos = vector3d:new(player:GetPosition());
				src_pos.y = 0;
				src_facing = player:GetFacing();
			end
			local camera_facing = ParaCamera.GetAttributeObject():GetField("CameraRotY", 0);
			
			src_facing = src_facing or 0;
			if(src_facing) then
				if(coordinate == "camera") then
					parentCtl:GetChild("src").rotation = src_facing - camera_facing;
				else
					parentCtl:GetChild("src").rotation = src_facing;
				end
			end
			if(mcmlNode.dest_array and src_pos) then
				local near_dist;
				local near_angle;
				local i, dest
				for i, dest in ipairs(mcmlNode.dest_array) do
					local distance = src_pos:dist(dest);
					local relativePos = dest - src_pos;
					local angle = vector3d.unit_x:angle(relativePos);
					if(relativePos[3]>0) then
						angle = - angle;
					end

					-- update rotation for each target
					local destBtn = parentCtl:GetChild(tostring(i));
					if(coordinate == "camera") then
						destBtn.rotation = angle - camera_facing;
					else
						destBtn.rotation = angle;
					end
					-- we can display distance either for closest distance or closest angle
					if(dist_mode == "min_dist") then
						if(not near_dist or distance<near_dist) then
							near_angle = math_abs(angle-src_facing);
							near_dist = distance;
						end
					else
						if(not near_angle or math_abs(angle-src_facing)<near_angle) then
							near_angle = math_abs(angle-src_facing);
							near_dist = distance;
						end
					end
				end
				if(near_dist) then
					-- update distance display
					local labelNode = mcmlNode:GetChildWithAttribute("name", "distance");
					if(labelNode) then
						if(reach_dist < near_dist) then
							labelNode:SetUIValue(rootName, format("%d", near_dist));
						else
							labelNode:SetUIValue(rootName, reach_text);
						end
					end
				end
			end
		end
	end});
	mcmlNode.timer:Change(0,100);

	return true, true, true; -- ignore_onclick, ignore_background, ignore_tooltip;
end

function pe_locationtracker.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	return mcmlNode:DrawDisplayBlock(rootName, bindingContext, _parent, left, top, width, height, parentLayout, style, pe_locationtracker.render_callback);
end

-----------------------------------
-- pe:arrowpointer control
-----------------------------------
NPL.load("(gl)script/apps/Aries/Desktop/GUIHelper/ArrowPointer.lua");
local ArrowPointer = commonlib.gettable("MyCompany.Aries.Desktop.GUIHelper.ArrowPointer");	
local pe_arrowpointer = commonlib.gettable("MyCompany.Aries.mcml_controls.pe_arrowpointer");

function pe_arrowpointer.render_callback(mcmlNode, rootName, bindingContext, _parent, left, top, width, height, myLayout, css)
	local direction = mcmlNode:GetString("direction", "2");	
	local direction_ = tonumber(direction);
	if(direction_) then
		direction = direction_;
	end
	local on_create_callback;
	if(mcmlNode:GetChildCount() > 0) then
		on_create_callback = function(_arrow_cont, id)
			local child_layout = myLayout:new_child();
			local width, height = child_layout:GetPreferredSize();
			mcmlNode:DrawChildBlocks_Callback(rootName, bindingContext, _arrow_cont, 0, 0, width, height, child_layout, css)
		end
	end
	ArrowPointer.ShowArrow(mcmlNode:GetAttribute("name") or "pe_arrowpointer", direction, "_lt", left, top, width-left, height-top, css.background, _parent, on_create_callback,mcmlNode:GetString("animfile"))
	return true, true, true; -- ignore_onclick, ignore_background, ignore_tooltip;
end

function pe_arrowpointer.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	return mcmlNode:DrawDisplayBlock(rootName, bindingContext, _parent, left, top, width, height, parentLayout, style, pe_arrowpointer.render_callback);
end