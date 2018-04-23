--[[
Title: all controls for Aries specific tags
Author(s): WangTian
Date: 2009/10/17
Desc: all aries specific tags

--+++ aries:miniscenecameramodifier 
| *property* | *desc* |
| IsRotateModel | true to rotate model instead of camera. default to false. |

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/mcml/pe_aries2.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Friends/Main.lua");
NPL.load("(gl)script/apps/Aries/Chat/FamilyChatWnd.lua");
		
----------------------------------------------------------------------
-- aries:onlinestatus: handles MCML tag <aries:onlinestatus>
-- it renders the img of the user online status
----------------------------------------------------------------------
local aries_onlinestatus = commonlib.gettable("MyCompany.Aries.mcml_controls.aries_onlinestatus")

local online_bg = "Texture/Aries/Friends/FriendsWnd_BuddyIcon_Online_32bits.png;0 0 32 26";
local offline_bg = "Texture/Aries/Friends/FriendsWnd_BuddyIcon_Offline_32bits.png;0 0 32 26";

-- aries_userinfo is just a wrapper of button control with user field value as text
function aries_onlinestatus.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local nid = mcmlNode:GetAttributeWithCode("nid");
	nid = tonumber(nid);
	if(not nid) then
		log("error: must specify nid in mcml tag aries:onlinestatus \n")
		return;
	end
	
	local isOnline;
	if(MyCompany.Aries.Friends.IsFriendInMemory(nid)) then
		-- if nid is friend of user use jabber online status
		isOnline = MyCompany.Aries.Friends.IsUserOnlineInMemory(nid);
	else
		-- if nid is not friend of user use family online status
		isOnline = MyCompany.Aries.Chat.FamilyChatWnd.IsFamilyMemberOnline(nid);
	end
	
	local online_img = mcmlNode:GetAttributeWithCode("online_bg") or online_bg;
	local offline_img = mcmlNode:GetAttributeWithCode("offline_bg") or offline_bg;
	
	local src = "";
	if(isOnline) then
		src = online_img;
	else
		src = offline_img;
	end
	
	mcmlNode:SetAttribute("src", src);
	-- create as an <img> tag
	Map3DSystem.mcml_controls.pe_img.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
end


----------------------------------------------------------------------
-- aries:miniscenecameramodifier: handles MCML tag <aries:miniscenecameramodifier>
----------------------------------------------------------------------
local aries_miniscenecameramodifier = commonlib.gettable("MyCompany.Aries.mcml_controls.aries_miniscenecameramodifier");

-- aries_miniscenecameramodifier is just a wrapper of button control
function aries_miniscenecameramodifier.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local miniscenename = mcmlNode:GetAttributeWithCode("miniscenename");
	if(not miniscenename) then
		log("error: must specify miniscenename in mcml tag aries:miniscenecameramodifier \n")
		return;
	end
	local type = mcmlNode:GetAttributeWithCode("type");
	if(not miniscenename) then
		log("error: must specify type in mcml tag aries:miniscenecameramodifier \n")
		return;
	end
	
	---- create as an <img> tag
	--Map3DSystem.mcml_controls.pe_editor_button.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
	
	local src = mcmlNode:GetAttributeWithCode("src") or "";
	
	local left, top, width, height = parentLayout:GetPreferredRect();
	local css = mcmlNode:GetStyle(Map3DSystem.mcml_controls.pe_html.css["img"]) or {};
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
			
	local tmpWidth = tonumber(mcmlNode:GetAttributeWithCode("width")) or css.width
	if(tmpWidth) then
		if((left + tmpWidth+margin_left+margin_right)<width) then
			width = left + tmpWidth+margin_left+margin_right;
		else
			parentLayout:NewLine();
			left, top, width, height = parentLayout:GetPreferredRect();
			width = left + tmpWidth+margin_left+margin_right;
		end
	end
	local tmpHeight = tonumber(mcmlNode:GetAttributeWithCode("height")) or css.height
	if(tmpHeight) then
		height = top + tmpHeight+margin_top+margin_bottom
	end
			
	if(bUseSpace) then
		parentLayout:AddObject(width-left, height-top);
	end
	
	left = left + margin_left
	top = top + margin_top;
	width = width - margin_right;
	height = height - margin_bottom;
	
	local instName;
	if(mcmlNode:GetAttribute("name") or mcmlNode:GetAttribute("id")) then
		instName = mcmlNode:GetInstanceName(rootName);
	end	
	
	local _this = ParaUI.CreateUIObject("button",instName or "b","_lt", left, top, width-left, height-top);
	--_this.enabled = false;
	if(src == "") then
		_this.background = css.background or "";
	else
		_this.background = src;
	end
	
	local normal_bg = mcmlNode:GetAttributeWithCode("Normal_BG");
	local mouseover_bg = mcmlNode:GetAttributeWithCode("MouseOver_BG");
	local pressed_bg = mcmlNode:GetAttributeWithCode("Pressed_BG");
	if(normal_bg and mouseover_bg and pressed_bg) then
		_guihelper.SetVistaStyleButton3(_this, normal_bg, mouseover_bg, nil, pressed_bg);
	end
	
	local animstyle = mcmlNode:GetAttributeWithCode("animstyle", nil, true);
	if(animstyle) then
		_this.animstyle = tonumber(animstyle);
	end
	local tooltip = mcmlNode:GetAttributeWithCode("tooltip");
	if(tooltip) then
		_this.tooltip = tooltip;
	end
	if(mcmlNode:GetNumber("zorder")) then
		_this.zorder = mcmlNode:GetNumber("zorder");
	end
	local enabled = mcmlNode:GetBool("enabled");
	if(enabled == false) then
		_this.enabled = false;
	end
	if(mcmlNode:GetBool("alwaysmouseover")) then
		_this:GetAttributeObject():SetField("AlwaysMouseOver", true);
	end
	
	_parent:AddChild(_this);
	
	local IsRotateModel = mcmlNode:GetBool("IsRotateModel");

	if(type == "rotateleft") then
		_this.onclick = string.format(";MyCompany.Aries.mcml_controls.aries_miniscenecameramodifier.RotateLeft(%q, %s);", miniscenename, tostring(not IsRotateModel));
		_this:SetScript("onframemove",
			function(_obj, miniscenename)
				if(_obj and _obj:IsValid() == true) then
					local isPressed = _obj:GetAttributeObject():GetField("IsPressed", false);
					if(isPressed == true) then
						aries_miniscenecameramodifier.RotateLeft(miniscenename, not IsRotateModel);
					end
				end
			end, miniscenename);
		--local onclick = "Map3DSystem.mcml_controls.aries_miniscenecameramodifier.RotateLeft();";
		--mcmlNode:SetAttribute("onclick", onclick);
		--mcmlNode:SetAttribute("param1", miniscenename);
	elseif(type == "rotateright") then
		_this.onclick = string.format(";MyCompany.Aries.mcml_controls.aries_miniscenecameramodifier.RotateRight(%q, %s);", miniscenename, tostring(not IsRotateModel));
		_this:SetScript("onframemove",
			function(_obj, miniscenename)
				if(_obj and _obj:IsValid() == true) then
					local isPressed = _obj:GetAttributeObject():GetField("IsPressed", false);
					if(isPressed == true) then
						aries_miniscenecameramodifier.RotateRight(miniscenename, not IsRotateModel);
					end
				end
			end, miniscenename);
		--local onclick = "Map3DSystem.mcml_controls.aries_miniscenecameramodifier.RotateRight();";
		--mcmlNode:SetAttribute("onclick", onclick);
		--mcmlNode:SetAttribute("param1", miniscenename);
	end
end

-- set the camera of the miniscene if any. 
-- @param facing: facing value in rad. 
-- @param bIsDelta: if true, facing will be addictive. 
function aries_miniscenecameramodifier.SetCameraRotY(miniscenegraphname, facing, bIsDelta)
	if(facing and miniscenegraphname) then
		local scene = ParaScene.GetMiniSceneGraph(miniscenegraphname);
		if(scene:IsValid()) then
			local fRotY, fLiftupAngle, fCameraObjectDist = scene:CameraGetEyePosByAngle();
			scene:CameraSetEyePosByAngle(if_else(bIsDelta, fRotY + facing, facing), fLiftupAngle, fCameraObjectDist);
			
			if(not scene:IsCameraEnabled()) then
				CommonCtrl.Canvas3D.AdoptMiniSceneCamera(scene);
			end
		end
	end	
end

-- set the facing of the current model if any. This function can be used to rotate the model. 
-- @param facing: facing value in rad. 
-- @param bIsDelta: if true, facing will be addictive. 
function aries_miniscenecameramodifier.SetModelFacing(miniscenegraphname, facing, bIsDelta)
	if(facing and miniscenegraphname) then
		local scene = ParaScene.GetMiniSceneGraph(miniscenegraphname);
		local obj = scene:GetObject(miniscenegraphname);
		if(obj:IsValid()) then
			if(bIsDelta) then
				obj:SetFacing(obj:GetFacing()+facing);
			else
				obj:SetFacing(facing);
			end
		end
	end	
end

function aries_miniscenecameramodifier.RotateLeft(miniscenegraphname, bIsCamera)
	if(bIsCamera) then
		aries_miniscenecameramodifier.SetCameraRotY(miniscenegraphname, -0.05, true)
	else
		aries_miniscenecameramodifier.SetModelFacing(miniscenegraphname, 0.05, true)
	end
end

function aries_miniscenecameramodifier.RotateRight(miniscenegraphname, bIsCamera)
	if(bIsCamera) then
		aries_miniscenecameramodifier.SetCameraRotY(miniscenegraphname, 0.05, true)
	else
		aries_miniscenecameramodifier.SetModelFacing(miniscenegraphname, -0.05, true)
	end
end


----------------------------------------------------------------------
-- aries:questobjectivestatus: handles MCML tag <aries:questobjectivestatus>
-- Turns into an img for the specified item's icon.
----------------------------------------------------------------------
local aries_questobjectivestatus = commonlib.gettable("MyCompany.Aries.mcml_controls.aries_questobjectivestatus");

-- Renders the item's icon in specific size(defined in style)
function aries_questobjectivestatus.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	
	local gsids = tostring(mcmlNode:GetAttributeWithCode("gsids"));
	local conjunction = mcmlNode:GetAttributeWithCode("conjunction");
	
	local on_tooltip = mcmlNode:GetAttributeWithCode("on_tooltip");
	local off_tooltip = mcmlNode:GetAttributeWithCode("off_tooltip");
	
	local on_bg = mcmlNode:GetAttributeWithCode("on_bg");
	local off_bg = mcmlNode:GetAttributeWithCode("off_bg");
	
	local force_status = mcmlNode:GetAttributeWithCode("force_status");
	
	local ItemManager = Map3DSystem.Item.ItemManager;
	local hasGSItem = ItemManager.IfOwnGSItem;
	local equipGSItem = ItemManager.IfEquipGSItem;
	
	local status;
	if(force_status) then
		status = force_status;
	else
		-- check quest status according to gsid existence
		if(conjunction == "and") then
			status = "on";
			local gsid;
			for gsid in string.gfind(gsids, "([^,]+)") do
				gsid = tonumber(gsid);
				if(not hasGSItem(gsid)) then
					status = "off";
					break;
				end
			end
		elseif(conjunction == "or" or conjunction == nil) then
			status = "off";
			local gsid;
			for gsid in string.gfind(gsids, "([^,]+)") do
				gsid = tonumber(gsid);
				if(hasGSItem(gsid)) then
					status = "on";
					break;
				end
			end
		end
	end
	
	if(status == "on") then
		mcmlNode:SetAttribute("src", on_bg);
	elseif(status == "off") then
		mcmlNode:SetAttribute("src", off_bg);
	end
	
	local animstyle = mcmlNode:GetAttributeWithCode("animstyle");
	if(not animstyle) then
		-- default animstyle
		mcmlNode:SetAttribute("animstyle", 21);
	end
	
	if(status == "on" and on_tooltip) then
		mcmlNode:SetAttribute("tooltip", on_tooltip);
	elseif(status == "off" and off_tooltip) then
		mcmlNode:SetAttribute("tooltip", off_tooltip);
	end
	
	-- create as an <img> tag
	Map3DSystem.mcml_controls.pe_img.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
end

local aries_userhead = commonlib.gettable("MyCompany.Aries.mcml_controls.aries_userhead")

local boy_bg = "Texture/Aries/Common/Teen/Team/boy_32bits.png";
local girl_bg = "Texture/Aries/Common/Teen/Team/girl_32bits.png";

function aries_userhead.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local nid = mcmlNode:GetAttributeWithCode("nid");
	local object = mcmlNode:GetString("object") or "";
	local src = boy_bg;
	nid = tonumber(nid);
	if(object == "npc")then
	else
		if(not nid) then
			return;
		end
		local boy_bg = mcmlNode:GetAttributeWithCode("boy_bg") or boy_bg;
		local girl_bg = mcmlNode:GetAttributeWithCode("girl_bg") or girl_bg;
		local Player = commonlib.gettable("MyCompany.Aries.Player");
		local gender = Player.GetGender(nid)
		 if(gender == "male")then
			src = boy_bg;
		else
			src = girl_bg;
		end
	end
	mcmlNode:SetAttribute("src", src);
	-- create as an <img> tag
	Map3DSystem.mcml_controls.pe_img.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
end
