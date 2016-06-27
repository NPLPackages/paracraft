--[[
Title: player avatar display
Author(s):  LiXizhi
Company: ParaEngine
Date: 2013.10.14
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/pe_mc_player.lua");
------------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
-- create class
local pe_mc_player = commonlib.gettable("MyCompany.Aries.Game.mcml.pe_mc_player");

function pe_mc_player.render_callback(mcmlNode, rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)
	-- get user nid
	local nid = mcmlNode:GetAttributeWithCode("nid",nil,true);
	nid = tonumber(nid) or 0;

	local IsActiveRendering = mcmlNode:GetBool("IsActiveRendering")
	if(IsActiveRendering == nil) then
		IsActiveRendering = true
	end
	
	local IsInteractive = mcmlNode:GetBool("IsInteractive")
	if(IsInteractive == nil) then
		IsInteractive = true;
	end
	
	local autoRotateSpeed = mcmlNode:GetNumber("autoRotateSpeed")
	if(autoRotateSpeed == nil) then
		autoRotateSpeed = 0;
	end

	local miniSceneName = mcmlNode:GetAttributeWithCode("miniscenegraphname") or "pe:player"..ParaGlobal.GenerateUniqueID();

	local instName = mcmlNode:GetInstanceName(rootName);
	NPL.load("(gl)script/ide/Canvas3D.lua");
	local ctl = CommonCtrl.Canvas3D:new{
		name = instName.."_mcplayer",
		alignment = "_lt",
		left = left,
		top = top,
		width = right - left,
		height = bottom - top,
		background = mcmlNode:GetString("background") or css.background,
		parent = _parent,
		IsActiveRendering = IsActiveRendering,
		miniscenegraphname = miniSceneName,
		DefaultRotY = mcmlNode:GetNumber("DefaultRotY") or 0,
		RenderTargetSize = mcmlNode:GetNumber("RenderTargetSize") or 256,
		IsInteractive = IsInteractive,
		autoRotateSpeed = autoRotateSpeed,
		DefaultCameraObjectDist = mcmlNode:GetNumber("DefaultCameraObjectDist") or 7,
		DefaultLiftupAngle = mcmlNode:GetNumber("DefaultLiftupAngle") or 0.25,
		LookAtHeight = mcmlNode:GetNumber("LookAtHeight") or 1.5,
		FrameMoveCallback = function(ctl)
			pe_mc_player.OnFrameMove(ctl, mcmlNode);
		end,
	};
	mcmlNode.Canvas3D_ctl = ctl;
	ctl:Show(true);

	local obj_params = ObjEditor.GetObjectParams(ParaScene.GetPlayer());

	NPL.load("(gl)script/apps/Aries/Creator/Game/PlayerController.lua");
	
	if(not obj_params.AssetFile or obj_params.AssetFile == "") then
		obj_params = {
			IsCharacter = true, 
			AssetFile = MyCompany.Aries.Game.PlayerController:GetMainAssetPath(),
			x = 0, y=0, z=0, facing=0,
			Attribute = 128,
		};
	end
	obj_params.name = "mc_player";
	local skin;
	local player = EntityManager.GetFocus();
	if(player and player.GetSkin) then
		skin = player:GetSkin();
	else
		skin = MyCompany.Aries.Game.PlayerController:GetSkinTexture();
	end
	obj_params.ReplaceableTextures = {[2] = skin };
	obj_params.facing = 1.57;
	-- MESH_USE_LIGHT = 0x1<<7: use block ambient and diffuse lighting for this model. 
	obj_params.Attribute = 128;

	mcmlNode.obj_params = obj_params;

	ctl:ShowModel(obj_params);
	pe_mc_player.OnFrameMove(ctl, mcmlNode);
end

-- on frame move: facing the mouse cursor
function pe_mc_player.OnFrameMove(ctl, mcmlNode)
	local mouse_x, mouse_y = ParaUI.GetMousePosition();
	local _parent = ctl:GetContainer();
	if(_parent and _parent:IsValid()) then
		local x, y, width, height = _parent:GetAbsPosition();
		local dx = mouse_x - (x + width/2); 
		local dy = mouse_y - (y + height/2);
		local player = ctl:GetObject();
		if(player) then
			local HeadUpdownAngle = 0;
			local HeadTurningAngle = 0;
			local facing = 1.57;
			-- max pixel
			local len = dx^2 + dy^2; 
			if(len > 0) then
				len = math.sqrt(len);
				HeadUpdownAngle = -dy/len*0.7;
				HeadTurningAngle = -dx/len;
			end
			player:SetFacing(facing);
			player:SetField("HeadUpdownAngle", HeadUpdownAngle);
			player:SetField("HeadTurningAngle", HeadTurningAngle);
		end
	end
end

-- this is just a temparory tag for offline mode
function pe_mc_player.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	return mcmlNode:DrawDisplayBlock(rootName, bindingContext, _parent, left, top, width, height, parentLayout, style, pe_mc_player.render_callback);
end
