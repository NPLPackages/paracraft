--[[
Title: 
Author(s): Leio Zhang
Date: 2008/7/22
Desc: 
-- pe:storyboard

-- pe:doubleAnimationUsingKeyFrames
--2D object SurpportProperty = {"x","y","scaleX","scaleY","rotation","alpha"}
	-- pe:linearDoubleKeyFrame
	-- pe:discreteStringKeyFrame
	
-- pe:stringAnimationUsingKeyFrames
--2D object SurpportProperty = {"text","visible"}
	-- pe:discreteStringKeyFrame

pe:point3DAnimationUsingKeyFrames
-- 3D object SurpportProperty = {"SetPosition","CameraZoomSphere","CameraSetLookAtPos","CameraSetEyePos","CameraSetEyePosByAngle"}
	-- pe:linearPoint3DKeyFrame
	-- pe:discretePoint3DKeyFrame
	
-- pe:objectAnimationUsingKeyFrames
--2D and 3D object SurpportProperty = {"CreateMeshPhysicsObject","Create2DContainer","Create2DButton","Create2DText"}
	-- pe:discreteObjectKeyFrame
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_storyboard.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/Animation/Storyboard.lua");

if(not Map3DSystem.mcml_controls) then Map3DSystem.mcml_controls = {} end

-----------------------------------
-- pe:Storyboards control
-----------------------------------
local pe_storyboards = {};
Map3DSystem.mcml_controls.pe_storyboards = pe_storyboards;


function pe_storyboards.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	NPL.load("(gl)script/ide/Animation/StoryBoardPlayer.lua");
	local storyboard_player = CommonCtrl.Animation.StoryBoardPlayer:new();
	local name = mcmlNode:GetAttribute("name") or mcmlNode:GetAttribute("Name")
	if(name)then
		storyboard_player.name = name;
	end
	local childnode;
	for childnode in mcmlNode:next() do
		local left, top, width, height = parentLayout:GetPreferredRect();
		local storyboard = Map3DSystem.mcml_controls.create(rootName, childnode, bindingContext, _parent, left, top, width, height, style, parentLayout)
		if(storyboard) then
			storyboard_player:addStoryBoard(storyboard);
		end	
	end
	mcmlNode.storyboard_player = storyboard_player;

	return storyboard_player;
end

-----------------------------------
-- pe:Storyboard control
-----------------------------------
local pe_storyboard = {};
Map3DSystem.mcml_controls.pe_storyboard = pe_storyboard;


function pe_storyboard.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local storyboard = CommonCtrl.Animation.Storyboard:new();
	local storyboardManager = CommonCtrl.Animation.StoryboardManager:new();
	local name = mcmlNode:GetAttribute("name") or mcmlNode:GetAttribute("Name")
	if(name)then
		storyboard.name = name;
	end	
	local repeatCount = mcmlNode:GetAttribute("repeatCount") or mcmlNode:GetAttribute("RepeatCount")
	if(repeatCount) then
		storyboard.repeatCount = tonumber(repeatCount);
	end
	-- search any layers
	local childnode;
	for childnode in mcmlNode:next() do
		local left, top, width, height = parentLayout:GetPreferredRect();
		local animationKeyFrames_list = Map3DSystem.mcml_controls.create(rootName, childnode, bindingContext, _parent, left, top, width, height, style, parentLayout)
		if(table.getn(animationKeyFrames_list) >0) then
			local k,animationKeyFrames;
			for k,animationKeyFrames in ipairs(animationKeyFrames_list)do
				storyboardManager:AddChild(animationKeyFrames);
			end
		end	
	end
	storyboard:SetAnimatorManager(storyboardManager);
	mcmlNode.engine = storyboard;

	return storyboard;
end
-- play from beginning
function pe_storyboard.Play(mcmlNode, pageInstName)
	local engine = pe_storyboard.GetEngine(mcmlNode, pageInstName);
	if(not engine) then return ;end
	engine:doPlay();
end
-- pause group 
function pe_storyboard.Pause(mcmlNode, pageInstName)
	local engine = pe_storyboard.GetEngine(mcmlNode, pageInstName);
	if(not engine) then return ;end
	engine:doPause();
end
-- resume group 
function pe_storyboard.Resume(mcmlNode, pageInstName)
	local engine = pe_storyboard.GetEngine(mcmlNode, pageInstName);
	if(not engine) then return ;end
	engine:doResume();
end
-- stop group 
function pe_storyboard.Stop(mcmlNode, pageInstName)
	local engine = pe_storyboard.GetEngine(mcmlNode, pageInstName);
	if(not engine) then return ;end
	engine:doStop();
end
-- end group 
function pe_storyboard.End(mcmlNode, pageInstName)
	local engine = pe_storyboard.GetEngine(mcmlNode, pageInstName);
	if(not engine) then return ;end
	engine:doEnd();
end
-- preframe group 
function pe_storyboard.preframe(mcmlNode, pageInstName)
	local engine = pe_storyboard.GetEngine(mcmlNode, pageInstName);
	if(not engine) then return ;end
	engine:gotoAndStopPreFrame();
end
-- nextframe group 
function pe_storyboard.nextframe(mcmlNode, pageInstName)
	local engine = pe_storyboard.GetEngine(mcmlNode, pageInstName);
	if(not engine) then return ;end
	engine:gotoAndStopNextFrame();
end
-- pretime group 
function pe_storyboard.pretime(mcmlNode, pageInstName)
	local engine = pe_storyboard.GetEngine(mcmlNode, pageInstName);
	if(not engine) then return ;end
	engine:gotoAndStopPreTime();
end
-- nexttime group 
function pe_storyboard.nexttime(mcmlNode, pageInstName)
	local engine = pe_storyboard.GetEngine(mcmlNode, pageInstName);
	if(not engine) then return ;end
	engine:gotoAndStopNextTime();
end
-- speedpreframe group
function pe_storyboard.speedpreframe(mcmlNode, pageInstName,args)
	local engine = pe_storyboard.GetEngine(mcmlNode, pageInstName);
	if(not engine) then return ;end
	engine:speedPreFrame(args);
end
-- speednextframe group
function pe_storyboard.speednextframe(mcmlNode, pageInstName,args)
	local engine = pe_storyboard.GetEngine(mcmlNode, pageInstName);
	if(not engine) then return ;end
	engine:speedNextFrame(args);
end
-- speedpretime group
function pe_storyboard.speedpretime(mcmlNode, pageInstName,args)
	local engine = pe_storyboard.GetEngine(mcmlNode, pageInstName);
	if(not engine) then return ;end
	engine:speedPreTime(args);
end
-- speednexttime group
function pe_storyboard.speednexttime(mcmlNode, pageInstName,args)
	local engine = pe_storyboard.GetEngine(mcmlNode, pageInstName);
	if(not engine) then return ;end
	engine:speedNextTime(args);
end
function pe_storyboard.ReverseToMcml(mcmlNode, pageInstName)
	local engine = pe_storyboard.GetEngine(mcmlNode, pageInstName);
	if(not engine) then return ;end
	return engine:ReverseToMcml();
end
function pe_storyboard.GetEngine(mcmlNode, pageInstName)
	local engine = mcmlNode.engine;
	if(not engine or type(engine)~="table" )then
		commonlib.echo("pe_storyboard.GetEngine error: the value of engine is nil  or the type of engine is not table!");
	end
	return engine; 
end
----------------------------------------------------------------------
-- pe:doubleAnimationUsingKeyFrames control
----------------------------------------------------------------------
local pe_doubleAnimationUsingKeyFrames = {};
Map3DSystem.mcml_controls.pe_doubleAnimationUsingKeyFrames = pe_doubleAnimationUsingKeyFrames;


function pe_doubleAnimationUsingKeyFrames.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local keyFrames = {};	
	local TargetName = mcmlNode:GetAttribute("TargetName")
	local TargetProperty =  mcmlNode:GetAttribute("TargetProperty");
	local Duration =  mcmlNode:GetAttribute("Duration");	
	if(TargetName and TargetProperty) then
		local f_targetname,f_targetproperty;
		-- every target
		for f_targetname in string.gfind(TargetName, "([^%s;]+)") do
			--local pageCtrl = mcmlNode:GetPageCtrl();
			--local targetNode = pageCtrl:GetNode(f_targetname);
			targetNode = mcmlNode:SearchChildByAttribute("name", f_targetname)
			-- every target property
			for f_targetproperty in string.gfind(TargetProperty, "([^%s;]+)") do	
				if(targetNode) then
					-- bind it to control.
						local UICtrlName = targetNode:GetInstanceName(rootName);
					-- create a DoubleAnimationUsingKeyFrames
					local doubleAnimationUsingKeyFrames = CommonCtrl.Animation.DoubleAnimationUsingKeyFrames:new{
						TargetName = UICtrlName,
						TargetProperty = f_targetproperty,
						Duration = Duration,
					};
					local childnode;
					for childnode in mcmlNode:next() do
						local left, top, width, height = parentLayout:GetPreferredRect();
						local keyframe = Map3DSystem.mcml_controls.create(rootName, childnode, bindingContext, _parent, left, top, width, height, style, parentLayout)
						if(type(keyframe) == "table") then
							-- add child node
							doubleAnimationUsingKeyFrames:addKeyframe(keyframe)
						end	
					end
					table.insert(keyFrames,doubleAnimationUsingKeyFrames);
				end
			end
		end
	end	
	return keyFrames;
end
-----------------------------------
-- pe:linearDoubleKeyFrame control
-----------------------------------
local pe_linearDoubleKeyFrame = {};
Map3DSystem.mcml_controls.pe_linearDoubleKeyFrame = pe_linearDoubleKeyFrame;


function pe_linearDoubleKeyFrame.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local linearDoubleKeyFrame;
	
	local KeyTime = mcmlNode:GetAttribute("KeyTime")
	local Value =  mcmlNode:GetAttribute("Value");
	local SimpleEase =  mcmlNode:GetAttribute("SimpleEase");
	Value = tonumber(Value);
	SimpleEase = tonumber(SimpleEase);
	if(KeyTime and Value) then
		-- create a LinearDoubleKeyFrame
		linearDoubleKeyFrame = CommonCtrl.Animation.LinearDoubleKeyFrame:new{
			KeyTime = KeyTime,
			Value = Value,
			SimpleEase = SimpleEase,
		};
	end	
	return linearDoubleKeyFrame;
end
-----------------------------------
-- pe:discreteDoubleKeyFrame control
-----------------------------------
local pe_discreteDoubleKeyFrame = {};
Map3DSystem.mcml_controls.pe_discreteDoubleKeyFrame = pe_discreteDoubleKeyFrame;


function pe_discreteDoubleKeyFrame.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local discreteDoubleKeyFrame;
	
	local KeyTime = mcmlNode:GetAttribute("KeyTime")
	local Value =  mcmlNode:GetAttribute("Value");
	Value = tonumber(Value);
	if(KeyTime and Value) then
		-- create a DiscreteDoubleKeyFrame
		discreteDoubleKeyFrame = CommonCtrl.Animation.DiscreteDoubleKeyFrame:new{
			KeyTime = KeyTime,
			Value = Value,
		};
	end	
	return discreteDoubleKeyFrame;
end
----------------------------------------------------------------------
-- pe:stringAnimationUsingKeyFrames control
----------------------------------------------------------------------
local pe_stringAnimationUsingKeyFrames = {};
Map3DSystem.mcml_controls.pe_stringAnimationUsingKeyFrames = pe_stringAnimationUsingKeyFrames;


function pe_stringAnimationUsingKeyFrames.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local keyFrames = {};	
	local TargetName = mcmlNode:GetAttribute("TargetName")
	local TargetProperty =  mcmlNode:GetAttribute("TargetProperty");
	local Duration =  mcmlNode:GetAttribute("Duration");
	if(TargetName and TargetProperty) then
		local f_targetname,f_targetproperty;
		-- every target
		for f_targetname in string.gfind(TargetName, "([^%s;]+)") do
			--local pageCtrl = mcmlNode:GetPageCtrl();
			--local targetNode = pageCtrl:GetNode(f_targetname);
			targetNode = mcmlNode:SearchChildByAttribute("name", f_targetname)
			-- every target property
			for f_targetproperty in string.gfind(TargetProperty, "([^%s;]+)") do	
				if(targetNode) then
					-- bind it to control.
					local UICtrlName = targetNode:GetInstanceName(rootName);
					
					-- create a StringAnimationUsingKeyFrames
					local stringAnimationUsingKeyFrames = CommonCtrl.Animation.StringAnimationUsingKeyFrames:new{
						TargetName = UICtrlName,
						TargetProperty = f_targetproperty,
						Duration = Duration,
					};
					local name = mcmlNode[1]["name"]
					if(name =="pe:stringAnimationUsingKeyFrames_Value")then
					local temp_Value = mcmlNode[1][1]
						stringAnimationUsingKeyFrames = CommonCtrl.Animation.Reverse.LrcToMcml(temp_Value,stringAnimationUsingKeyFrames)
					else	
						local childnode;
						for childnode in mcmlNode:next() do
							local left, top, width, height = parentLayout:GetPreferredRect();
							local keyframe = Map3DSystem.mcml_controls.create(rootName, childnode, bindingContext, _parent, left, top, width, height, style, parentLayout)
							if(type(keyframe) == "table") then
								-- add child node
								stringAnimationUsingKeyFrames:addKeyframe(keyframe)
							end	
						end
					end
					table.insert(keyFrames,stringAnimationUsingKeyFrames);
				end
			end
		end
	end	
	return keyFrames;
end
-----------------------------------
-- pe:discreteStringKeyFrame control
-----------------------------------
local pe_discreteStringKeyFrame = {};
Map3DSystem.mcml_controls.pe_discreteStringKeyFrame = pe_discreteStringKeyFrame;


function pe_discreteStringKeyFrame.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local discreteStringKeyFrame;
	
	local KeyTime = mcmlNode:GetAttribute("KeyTime")
	local Value =  mcmlNode:GetAttribute("Value");
	if(KeyTime and Value) then
		-- create a LinearDoubleKeyFrame
		discreteStringKeyFrame = CommonCtrl.Animation.DiscreteStringKeyFrame:new{
			KeyTime = KeyTime,
			Value = Value,
		};
	end	
	return discreteStringKeyFrame;
end
----------------------------------------------------------------------
-- pe:point3DAnimationUsingKeyFrames control
----------------------------------------------------------------------
local pe_point3DAnimationUsingKeyFrames = {};
Map3DSystem.mcml_controls.pe_point3DAnimationUsingKeyFrames = pe_point3DAnimationUsingKeyFrames;


function pe_point3DAnimationUsingKeyFrames.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local keyFrames = {};	
	local TargetName = mcmlNode:GetAttribute("TargetName")
	local TargetProperty =  mcmlNode:GetAttribute("TargetProperty");
	local Duration =  mcmlNode:GetAttribute("Duration");	
	if(TargetName and TargetProperty) then
		local f_targetname,f_targetproperty;
		-- every target
		for f_targetname in string.gfind(TargetName, "([^%s;]+)") do
			--local pageCtrl = mcmlNode:GetPageCtrl();
			--local targetNode = pageCtrl:GetNode(f_targetname);
			-- every target property
			for f_targetproperty in string.gfind(TargetProperty, "([^%s;]+)") do	
				--if(targetNode) then
					-- bind it to control.
						--local UICtrlName = targetNode:GetInstanceName(rootName);
					-- create a Point3DAnimationUsingKeyFrames
					local point3DAnimationUsingKeyFrames = CommonCtrl.Animation.Point3DAnimationUsingKeyFrames:new{
						TargetName = f_targetname,
						TargetProperty = f_targetproperty,
						Duration = Duration,
					};
					local childnode;
					for childnode in mcmlNode:next() do
						local left, top, width, height = parentLayout:GetPreferredRect();
						local keyframe = Map3DSystem.mcml_controls.create(rootName, childnode, bindingContext, _parent, left, top, width, height, style, parentLayout)
						if(type(keyframe) == "table") then
							-- add child node
							point3DAnimationUsingKeyFrames:addKeyframe(keyframe)
						end	
					end
					table.insert(keyFrames,point3DAnimationUsingKeyFrames);
				--end
			end
		end
	end	
	return keyFrames;
end
-----------------------------------
-- pe:linearPoint3DKeyFrame control
-----------------------------------
local pe_linearPoint3DKeyFrame = {};
Map3DSystem.mcml_controls.pe_linearPoint3DKeyFrame = pe_linearPoint3DKeyFrame;


function pe_linearPoint3DKeyFrame.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local linearPoint3DKeyFrame;
	
	local KeyTime = mcmlNode:GetAttribute("KeyTime")
	local Value =  mcmlNode:GetAttribute("Value");
	local SimpleEase =  mcmlNode:GetAttribute("SimpleEase");
	SimpleEase = tonumber(SimpleEase);
	if(KeyTime and Value) then
		-- create a LinearPoint3DKeyFrame
		linearPoint3DKeyFrame = CommonCtrl.Animation.LinearPoint3DKeyFrame:new{
			KeyTime = KeyTime,
			SimpleEase = SimpleEase,
		};
		linearPoint3DKeyFrame:SetValue(Value);
	end	
	return linearPoint3DKeyFrame;
end
-----------------------------------
-- pe:discretePoint3DKeyFrame control
-----------------------------------
local pe_discretePoint3DKeyFrame = {};
Map3DSystem.mcml_controls.pe_discretePoint3DKeyFrame = pe_discretePoint3DKeyFrame;


function pe_discretePoint3DKeyFrame.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local discretePoint3DKeyFrame;
	
	local KeyTime = mcmlNode:GetAttribute("KeyTime")
	local Value =  mcmlNode:GetAttribute("Value");
	if(KeyTime and Value) then
		-- create a LinearPoint3DKeyFrame
		discretePoint3DKeyFrame = CommonCtrl.Animation.DiscretePoint3DKeyFrame:new{
			KeyTime = KeyTime,
		};
		discretePoint3DKeyFrame:SetValue(Value);
	end	
	return discretePoint3DKeyFrame;
end
----------------------------------------------------------------------
-- pe:objectAnimationUsingKeyFrames control
----------------------------------------------------------------------
local pe_objectAnimationUsingKeyFrames = {};
Map3DSystem.mcml_controls.pe_objectAnimationUsingKeyFrames = pe_objectAnimationUsingKeyFrames;


function pe_objectAnimationUsingKeyFrames.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local keyFrames = {};	
	local TargetName = mcmlNode:GetAttribute("TargetName")
	local TargetProperty =  mcmlNode:GetAttribute("TargetProperty");
	local Duration =  mcmlNode:GetAttribute("Duration");	
	if(TargetName and TargetProperty) then
		local f_targetname,f_targetproperty;
		-- every target
		for f_targetname in string.gfind(TargetName, "([^%s;]+)") do
			--local pageCtrl = mcmlNode:GetPageCtrl();
			--local targetNode = pageCtrl:GetNode(f_targetname);
			-- every target property
			for f_targetproperty in string.gfind(TargetProperty, "([^%s;]+)") do	
				--if(targetNode) then
					-- bind it to control.
					--local UICtrlName = targetNode:GetInstanceName(rootName);
					-- create a ObjectAnimationUsingKeyFrames
					local objectAnimationUsingKeyFrames = CommonCtrl.Animation.ObjectAnimationUsingKeyFrames:new{
						TargetName = f_targetname,
						TargetProperty = f_targetproperty,
						Duration = Duration,
					};
					local childnode;
					for childnode in mcmlNode:next() do
						local left, top, width, height = parentLayout:GetPreferredRect();
						local keyframe = Map3DSystem.mcml_controls.create(rootName, childnode, bindingContext, _parent, left, top, width, height, style, parentLayout)
						if(type(keyframe) == "table") then
							-- add child node
							objectAnimationUsingKeyFrames:addKeyframe(keyframe)
						end	
					end
					table.insert(keyFrames,objectAnimationUsingKeyFrames);
				--end
			end
		end
	end	
	return keyFrames;
end
-----------------------------------
-- pe:discreteObjectKeyFrame control
-----------------------------------
local pe_discreteObjectKeyFrame = {};
Map3DSystem.mcml_controls.pe_discreteObjectKeyFrame = pe_discreteObjectKeyFrame;


function pe_discreteObjectKeyFrame.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local discreteObjectKeyFrame;
	
	local KeyTime = mcmlNode:GetAttribute("KeyTime")
	local Value =  mcmlNode:GetAttribute("Value");
	if(not Value)then
		Value = mcmlNode[1];
	end
	if(Value)then
		-- because the type of value if table
		NPL.DoString("CommonCtrl.Animation.Util.value = "..Value);
	end
	Value = CommonCtrl.Animation.Util.value;
	CommonCtrl.Animation.Util.value = nil;
	if(KeyTime and Value) then
		-- create a LinearDoubleKeyFrame
		discreteObjectKeyFrame = CommonCtrl.Animation.DiscreteObjectKeyFrame:new{
			KeyTime = KeyTime,
			Value = Value,
		};
	end	
	return discreteObjectKeyFrame;
end
