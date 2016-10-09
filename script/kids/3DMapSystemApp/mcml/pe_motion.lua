--[[
Title: A MCML tags wrapping functions of IDE/motion lib.
Author(s): LiXizhi, Leio
Date: 2008/5/4
Desc: pe:animgroup, pe:animlayer, pe:animator
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_motion.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/Motion/AnimatorEngine.lua");
if(not Map3DSystem.mcml_controls) then Map3DSystem.mcml_controls = {} end

-----------------------------------
-- pe:animgroup control
-----------------------------------
local pe_animgroup = {};
Map3DSystem.mcml_controls.pe_animgroup = pe_animgroup;

-- it contains a group of pe:animlayer
function pe_animgroup.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local engine = CommonCtrl.Motion.AnimatorEngine:new();
	local animatorManager = CommonCtrl.Motion.AnimatorManager:new();
	-- search any layers
	local childnode;
	for childnode in mcmlNode:next() do
		local left, top, width, height = parentLayout:GetPreferredRect();
		local layerManager = Map3DSystem.mcml_controls.create(rootName, childnode, bindingContext, _parent, left, top, width, height, style, parentLayout)
		if(type(layerManager) == "table") then
			animatorManager:AddChild(layerManager);
		end	
	end
	engine:SetAnimatorManager(animatorManager);
	mcmlNode.engine = engine;
end

-- play from beginning
function pe_animgroup.Play(mcmlNode, pageInstName)
	local engine = pe_animgroup.GetEngine(mcmlNode, pageInstName);
	if(not engine) then return ;end
	engine:doPlay();
end
-- pause group 
function pe_animgroup.Pause(mcmlNode, pageInstName)
	local engine = pe_animgroup.GetEngine(mcmlNode, pageInstName);
	if(not engine) then return ;end
	engine:doPause();
end
-- resume group 
function pe_animgroup.Resume(mcmlNode, pageInstName)
	local engine = pe_animgroup.GetEngine(mcmlNode, pageInstName);
	if(not engine) then return ;end
	engine:doResume();
end
-- stop group 
function pe_animgroup.Stop(mcmlNode, pageInstName)
	local engine = pe_animgroup.GetEngine(mcmlNode, pageInstName);
	if(not engine) then return ;end
	engine:doStop();
end

function pe_animgroup.GetEngine(mcmlNode, pageInstName)
	local engine = mcmlNode.engine;
	if(not engine or type(engine)~="table" )then
		commlib.echo("pe_animgroup.GetEngine error: the value of engine is nil  or the type of engine is not table!");
	end
	return engine;
end

-----------------------------------
-- pe:animlayer control
-----------------------------------
local pe_animlayer = {};
Map3DSystem.mcml_controls.pe_animlayer = pe_animlayer;

-- a layer contains a group of pe:animator. 
function pe_animlayer.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local layerManager = CommonCtrl.Motion.LayerManager:new();
	-- search any tab items
	local childnode;
	for childnode in mcmlNode:next() do
		local left, top, width, height = parentLayout:GetPreferredRect();
		local animator = Map3DSystem.mcml_controls.create(rootName, childnode, bindingContext, _parent, left, top, width, height, style, parentLayout);
		if(type(animator) == "table") then
			layerManager:AddChild(animator);
		end	
	end
	return layerManager;
end

-----------------------------------
-- pe:animator control
-----------------------------------
local pe_animator = {};
Map3DSystem.mcml_controls.pe_animator = pe_animator;

-- it binds to another mcml control
function pe_animator.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local animator;
	-- target control name that this animator is bound to.
	local target = mcmlNode:GetAttribute("for") or mcmlNode:GetAttribute("target");
	-- XAML animation file that this animator uses.
	local src = mcmlNode:GetAttribute("src");
	
	if(src and target) then
		src = mcmlNode:GetAbsoluteURL(src);
		
		-- create animator
		local pageCtrl = mcmlNode:GetPageCtrl();
		if(pageCtrl) then
			local targetNode = pageCtrl:GetNode(target);
			if(targetNode) then
				-- bind it to control.
				local UICtrlName = targetNode:GetInstanceName(rootName);
				animator = CommonCtrl.Motion.Animator:new();
				animator:Init(src, UICtrlName);
			end	
		end	
	end	
	return animator;
end
