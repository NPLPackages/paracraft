--[[
Title: Tool Touch Base
Author(s): LiXizhi
Date: 2014/11/25
Desc: base class for touch based tools
use the lib:
Desc: there are basically 3 kinds of touch sessions. 
1. action touch: tap, tap and drag (it will perform default action on tapped blocks when touch up, as follows:)
	- if block has default action, it will trigger block action, such as a button or a door.
	- if block in hand has action, it will trigger block template action, such as open the book in hand. 
	- otherwise, it will create on the sides of all touched blocks using the block in hand. 
2. selection touch: tap (drag) and hover (it will add all tapped blocks to selected blocks)
3. gesture touch: when block selection is NOT empty, all action touch is gesture touch. 
	- tap: deselect all selected blocks
	- tap (special case): if there is only a single selected block, and we tap on it, it will trigger the block editor (right click)
	- tap and drag up (NOT IMPLEMENTED): extrude all selected blocks vertically up .
	- tap and drag down (NOT IMPLEMENTED): delete all selected blocks.
	- two fingers tap and drag (NOT IMPLEMENTED): clone selected blocked and move to new position. 
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tools/ToolTouchBase.lua");
local ToolTouchBase = commonlib.gettable("MyCompany.Aries.Game.Tools.ToolTouchBase");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/TouchButton.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/TouchSession.lua");
local TouchButton = commonlib.gettable("MyCompany.Aries.Game.Common.TouchButton")
local TouchSession = commonlib.gettable("MyCompany.Aries.Game.Common.TouchSession")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TouchController = commonlib.gettable("MyCompany.Aries.Game.GUI.TouchController");

local Tool = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Tools.ToolTouchBase"));
Tool:Property("Name", "ToolTouchBase");
-- whether to show touch track. 
Tool:Property("ShowTouchTrack", true);
-- whether to allow selecting multiple blocks. 
Tool:Property("AllowMultiSelection", false);
Tool:Property("Checkable", true, "IsCheckable");
Tool:Property("Enabled", true, "IsEnabled");
-- short cut key sequence 
Tool:Property("Shortcut", "");

Tool:Signal("StatusInfoChanged", function(strInfo)  end);

-- default to 10 pixels
Tool.default_finger_size = 10;

-- selection group index used to show the frame
Tool.groupindex_selection = 0;
Tool.groupindex_empty = 2;
Tool.groupindex_wrong = 3;
Tool.groupindex_hint_white = 4; -- when placeable but not matching hand block
Tool.groupindex_hint_green = 5; -- when placeable and match hand block
Tool.groupindex_hint_green_auto = 6; -- auto selected block


function Tool:ctor()
	-- all registered gestures
	self.gestures = {};
	-- current active gesture
	self.activeGesture = nil;
end

function Tool:OnSelect()
	-- GameLogic.GameMode:SetCurrentTool("touch_pen");
end

function Tool:OnDeselect()
	-- GameLogic.GameMode:SetCurrentTool(nil);
	self.last_select_entity = nil;
	self.activeGesture = nil;
end

-- public function: call this when touch event arrives.
-- @param tag: where the touch happens, such as "camera_pad", "move_pad", "touch_scene"
function Tool:OnTouchScene(touch, tag)
	local touch_session = self:GetTouchSession(touch);

	if(self:InterpreteTouchGestures(touch)) then
		-- if there is a gesture, we will ignore all other active touch sessions. 
		self:DisableAllTouchSessions();
		return;
	end

	if(touch_session:IsEnabled()) then
		if(touch.type == "WM_POINTERDOWN") then
			self:StartTick();
			self:handleTouchSessionDown(touch_session, touch);
		elseif(touch.type == "WM_POINTERUPDATE") then
			self:handleTouchSessionMove(touch_session, touch);
		elseif(touch.type == "WM_POINTERUP") then
			self:handleTouchSessionUp(touch_session, touch);
			self:CheckStopTick();
		end
	end
end

function Tool:DisableAllTouchSessions()
	self:ClearAllTouchData();
	local touch_sessions = TouchSession.GetAllSessions();
	local touch_session;
	for i = 1, #touch_sessions do
		touch_session = touch_sessions[i];
		touch_session:SetEnabled(false);
	end
end

function Tool:GetTouchSession(touch)
	return TouchSession.GetTouchSession(touch);
end


function Tool:RegisterGestureRecognizer(gesture)
	self.gestures[#(self.gestures)+1] = gesture;
end

-- return true if at least one gesture is recognized. 
-- @param touch: the most recent touch event
-- @return true if active gesture is recognized. 
function Tool:InterpreteTouchGestures(touch)
	-- process active gesture
	local activeGesture = self.activeGesture;
	if(activeGesture) then
		if(activeGesture:InterpreteTouchGesture(touch)) then
			return true;
		else
			self.activeGesture = nil;
		end
	end
	-- if no active gesture, iterate over all gestures until one is recognized. 
	local gestures = self.gestures;
	for _, gesture in ipairs(gestures) do
		if(gesture:InterpreteTouchGesture(touch)) then
			self.activeGesture = gesture;
			return true;
		end
	end
end

function Tool:StartTick()
	self:ChangeTimer(0,30)
end

function Tool:CheckStopTick()
	local touch_sessions = TouchSession.GetAllSessions();
	if(#touch_sessions == 0) then
		self:OnTick();
		self:KillTimer();
	end
end

function Tool:GetActiveTouchCount()
	return #(TouchSession.GetAllSessions());
end

function Tool:ClearAllTouchData()
	ParaTerrain.DeselectAllBlock(self.groupindex_hint_white);
	Game.SelectionManager:ClearPickingResult();
	-- this will make the mouse out of client area. Please note it must be smaller than -1000
	ParaUI.SetMousePosition(-1000, -1000);
end

function Tool:OnTick()
	local touch_sessions = TouchSession.GetAllSessions();
	if(#touch_sessions == 0) then
		self:ClearAllTouchData();
	end
end

function Tool:handleTouchSessionDown(touch_session, touch)
	touch_session.blocks = {};
	touch_session.is_blocks_selected = true;
	ParaUI.SetMousePosition(touch.x, touch.y);
	local result = GameLogic.GetSceneContext():CheckMousePick();
	if(result) then
		if(not result.block_id and result.entity and result.obj) then
			self.last_select_entity = result.entity;
			-- ParaSelection.AddObject(result.obj, 1);
			if(touch_session:GetBlockCount() == 0) then
				return;
			end
		else
			self.last_select_entity = nil;
			ParaSelection.ClearGroup(1);
		end

		if(result.blockX) then
			touch_session:AddBlock(result.blockX,result.blockY,result.blockZ,result.side);
			if(self:GetShowTouchTrack()) then
				local x,y,z = BlockEngine:GetBlockIndexBySide(result.blockX,result.blockY,result.blockZ,result.side);
				ParaTerrain.SelectBlock(x,y,z, true, self.groupindex_hint_white);
			end
		end
	end
end

-- virtual: return picking result.
function Tool:handleTouchSessionMove(touch_session, touch)
	ParaUI.SetMousePosition(touch.x, touch.y);
	local result = GameLogic.GetSceneContext():CheckMousePick();
	
	if(result) then
		if(not result.block_id and result.entity and result.obj) then
			self.last_select_entity = result.entity;
			-- ParaSelection.AddObject(result.obj, 1);
			if(touch_session:GetBlockCount() == 0) then
				return;
			end
		else
			self.last_select_entity = nil;
			ParaSelection.ClearGroup(1);
		end

		if(result.blockX) then
			if(self:GetAllowMultiSelection()) then
				touch_session:AddBlock(result.blockX,result.blockY,result.blockZ,result.side);
			elseif(not touch_session:HasBlock(result.blockX,result.blockY,result.blockZ)) then
				-- only the most recent block is selected. 
				if(touch_session:GetBlockCount() > 0) then
					touch_session:ClearAllBlocks();
				end
				touch_session:AddBlock(result.blockX,result.blockY,result.blockZ,result.side);
			end
			if(self:GetShowTouchTrack()) then
				local x,y,z = BlockEngine:GetBlockIndexBySide(result.blockX,result.blockY,result.blockZ,result.side);
				ParaTerrain.SelectBlock(x,y,z, true, self.groupindex_hint_white);
			end
		end
	end
	return result;
end

function Tool:handleTouchSessionUp(touch_session, touch)
	ParaUI.SetMousePosition(touch.x, touch.y);
	
	local touch_type = self:ComputeEndingTouchType(touch_session);
	if(touch_type == "touch_selection") then
		self:SetLastSelectionFinishTime(touch_session:GetLastTime());
	elseif(touch_type == "touch_gesture") then
		self:handleTouchUpGesture(touch_session, touch);
	elseif(touch_type == "touch_action") then
		self:handleTouchUpAction(touch_session, touch);
	elseif(touch_type == "touch_aabb_point") then
		self:handleTouchUpAABBSelectPoint(touch_session, touch);
	end
end

-- virtual function: decide what kind of touches: 
-- @return: basically three kinds "gesture", "action", and "selection"
function Tool:ComputeEndingTouchType(touch_session)
	return "touch_action";
end

-- virtual function:
function Tool:handleTouchUpActionEntity(touch_session, touch)
end

-- virtual function:
function Tool:handleTouchUpActionSingleBlock(touch_session, touch)
end

-- virtual function:
function Tool:handleTouchUpActionMultiBlocks(touch_session, touch)
end

-- virtual function: handle all kinds of touch actions
function Tool:handleTouchUpAction(touch_session, touch)
	local blocks = touch_session:GetBlocks();
	if(not blocks or #blocks <= 1) then
		local isClickProcessed;
		if(self.last_select_entity) then
			isClickProcessed = self:handleTouchUpActionEntity(touch_session, touch);
		end
		if(not isClickProcessed) then
			self:handleTouchUpActionSingleBlock(touch_session, touch);
		end
	else
		self:handleTouchUpActionMultiBlocks(touch_session, touch);
	end
end

-- set the last touch up time when a selection touch finished 
function Tool:SetLastSelectionFinishTime(time)
	self.lastSelectionFinishTime = time;
end

function Tool:GetLastSelectionFinishTime()
	return self.lastSelectionFinishTime or 0;
end



