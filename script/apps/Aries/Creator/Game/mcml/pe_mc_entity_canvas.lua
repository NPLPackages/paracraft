--[[
Title: entity canvas 
Author(s):  LiXizhi
Company: ParaEngine
Date: 2014.1.7
Desc: 
use the lib:
---++ pe:mc_entity_canvas
| *name* | *desc* |
| entity | default to current player. It should be valid entity object.  |

------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/pe_mc_entity_canvas.lua");
local pe_mc_entity_canvas = commonlib.gettable("MyCompany.Aries.Game.mcml.pe_mc_entity_canvas");
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/block_types.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemStack.lua");
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

-- create class
local pe_mc_entity_canvas = commonlib.gettable("MyCompany.Aries.Game.mcml.pe_mc_entity_canvas");

pe_mc_entity_canvas.block_icon_instances = {};

function pe_mc_entity_canvas.render_callback(mcmlNode, rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)
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

	local miniSceneName = mcmlNode:GetAttributeWithCode("miniscenegraphname") or "pe_mc_entity_canvas";

	local entity = mcmlNode:GetAttributeWithCode("entity", nil, true) or EntityManager.GetPlayer();
	mcmlNode.entity = entity;

	local obj_params = mcmlNode.entity:GetPortaitObjectParams(true);

	local instName = mcmlNode:GetInstanceName(rootName);
	NPL.load("(gl)script/ide/Canvas3D.lua");
	local ctl = CommonCtrl.Canvas3D:new{
		name = instName.."_mc_entity",
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
	};

	-- if human, we will enable face tracking mouse position.
	local bIsHumanChar;
	if(obj_params.AssetFile and obj_params.AssetFile:match("^character/CC/01char/")) then
		bIsHumanChar = true;
	end
	if(bIsHumanChar) then
		ctl.FrameMoveCallback = function(ctl)
			pe_mc_entity_canvas.OnFrameMove(ctl, mcmlNode);
		end
	end

	ctl:Show(true);

	obj_params.name = "mc_entity";
	ctl:ShowModel(obj_params);
	if(bIsHumanChar) then
		pe_mc_entity_canvas.OnFrameMove(ctl, mcmlNode);
	end
end

-- on frame move: facing the mouse cursor
function pe_mc_entity_canvas.OnFrameMove(ctl, mcmlNode)
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
function pe_mc_entity_canvas.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	return mcmlNode:DrawDisplayBlock(rootName, bindingContext, _parent, left, top, width, height, parentLayout, style, pe_mc_entity_canvas.render_callback);
end
