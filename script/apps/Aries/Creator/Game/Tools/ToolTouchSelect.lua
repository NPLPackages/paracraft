--[[
Title: touch tool
Author(s): LiXizhi
Date: 2014/11/25
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tools/ToolTouchSelect.lua");
local ToolTouchSelect = commonlib.gettable("MyCompany.Aries.Game.Tools.ToolTouchSelect");
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tools/ToolTouchBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tools/TouchSelection.lua");
NPL.load("(gl)script/ide/math/ShapeAABB.lua");
NPL.load("(gl)script/ide/math/vector.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/TouchSession.lua");
local TouchSession = commonlib.gettable("MyCompany.Aries.Game.Common.TouchSession")
local vector3d = commonlib.gettable("mathlib.vector3d");
local ShapeAABB = commonlib.gettable("mathlib.ShapeAABB");
local TouchSelection = commonlib.gettable("MyCompany.Aries.Game.Tools.TouchSelection");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Tool = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Tools.ToolTouchBase"), commonlib.gettable("MyCompany.Aries.Game.Tools.ToolTouchSelect"));

Tool:Property("Name", "ToolTouchSelect");
-- whether to show touch track. 
Tool:Property("ShowTouchTrack", true);
-- whether to allow selecting multiple blocks. 
Tool:Property("AllowMultiSelection", true);

-- ms seconds for block selection
Tool.select_hover_time = 500;

function Tool:ctor()
	self.selection_aabb = ShapeAABB:new();
	self.selection_aabb:SetInvalid();
	self.Connect(TouchSelection, TouchSelection.SelectionDeleted, self, self.ClearSelectionAABB);
end

function Tool:OnSelect()
	Tool._super.OnSelect(self);
	self:ClearSelectionAABB();
end

function Tool:OnDeselect()
	Tool._super.OnDeselect(self);
	self:ClearSelectionAABB();
end

-- virtual function: handle all kinds of touch actions
function Tool:handleTouchUpAction(touch_session, touch)
	self:SelectBlocks(touch_session);
end

function Tool:SelectBlocks(touch_session)
	local blocks = touch_session:GetBlocks();
	if(blocks and #blocks >= 1) then
		for i, b in ipairs(blocks) do
			TouchSelection:AddToSelection(b[1], b[2], b[3]);
		end
		TouchSelection:NortifySelectionChange();
	end
end

function Tool:OnTick()
	local touch_sessions = TouchSession.GetAllSessions();
	if(#touch_sessions == 0) then
		self:ClearAllTouchData();
	end
	local touch_session;
	for i = 1, #touch_sessions do
		touch_session = touch_sessions[i];
		if(touch_session:IsEnabled() and not touch_session:GetField("selected") and touch_session:GetHoverTime() > self.select_hover_time) then
			self:SelectSessionBlocks(touch_session);
		end
	end
end

function Tool:SelectSessionBlocks(touch_session)
	local blocks = touch_session:GetBlocks();
	if(blocks and #blocks >0) then
		touch_session:SetField("selected", true);
		LOG.std(nil, "debug", "Tool", "a new batch of blocks are selected.");
		for _, block in ipairs(blocks) do
			ParaTerrain.SelectBlock(block[1],block[2],block[3], true, self.groupindex_selection);
			TouchSelection:AddToSelection(block[1],block[2],block[3]);
		end
		TouchSelection:NortifySelectionChange();
	end
end

function Tool:handleTouchSessionMove(touch_session, touch)
	local result = Tool._super.handleTouchSessionMove(self, touch_session, touch);
	if(result and result.blockX) then
		if(touch_session:GetField("selected")) then
			-- once selected, all following touch move are all regarded as selection touch. 
			ParaTerrain.SelectBlock(result.blockX,result.blockY,result.blockZ, true, self.groupindex_selection);
			TouchSelection:AddToSelection(result.blockX,result.blockY,result.blockZ);
			TouchSelection:NortifySelectionChange();
		end	
	end
end

function Tool:UpdateAABBToSelection()
	local aabb = self:GetSelectionAABB();
	local min = aabb:GetMin();
	local max = aabb:GetMax();
	for y = min[2], max[2] do
		for z = min[3], max[3] do
			for x = min[1], max[1] do
				local block_id = ParaTerrain.GetBlockTemplateByIdx(x,y,z);
				if(block_id > 0) then
					ParaTerrain.SelectBlock(x, y, z, true, self.groupindex_selection);
					TouchSelection:AddToSelection(x, y, z);
				end
			end
		end
	end
	TouchSelection:NortifySelectionChange();
end

-- current selection aabb
function Tool:AddPointToAABB(x, y, z)
	if(x and y and z) then
		if(not self.selection_aabb:IsValid()) then
			self.selection_aabb:SetPointAABB(vector3d:new({x, y, z}));
		else
			self.selection_aabb:Extend(x, y, z);
		end
	end
end

-- get selection
function Tool:GetSelectionAABB()
	return self.selection_aabb;
end

-- selection aabb is cleared when ctrl button is not being pressed. 
function Tool:ClearSelectionAABB()
	self.selection_aabb:SetInvalid();
end

function Tool:handleTouchUpAABBSelectPoint(touch_session, touch)
	if(GameLogic.GameMode:IsEditor()) then
		local blocks = touch_session:GetBlocks();
		if(blocks and #blocks >= 1) then
			for _, block in ipairs(blocks) do
				self:AddPointToAABB(block[1], block[2], block[3]);
			end
			
			self:UpdateAABBToSelection();
		end
	end
end

-- virtual function: decide what kind of touches: 
-- @return: basically three kinds "gesture", "action", and "selection"
function Tool:ComputeEndingTouchType(touch_session)
	if(touch_session:GetField("selected")) then
		return "touch_selection";
	else
		return "touch_aabb_point";
	end
end