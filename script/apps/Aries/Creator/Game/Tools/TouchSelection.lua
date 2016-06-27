--[[
Title: Touch selections
Author(s): LiXizhi
Date: 2014/9/30
Desc: manages all blocks being selected in the touch controller. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tools/TouchSelection.lua");
local TouchSelection = commonlib.gettable("MyCompany.Aries.Game.Tools.TouchSelection");
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tools/ToolTouchBase.lua");
NPL.load("(gl)script/ide/math/vector.lua");
NPL.load("(gl)script/ide/math/ShapeAABB.lua");
local ShapeAABB = commonlib.gettable("mathlib.ShapeAABB");
local vector3d = commonlib.gettable("mathlib.vector3d");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local TouchController = commonlib.gettable("MyCompany.Aries.Game.GUI.TouchController");
local TouchSelection = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Tools.TouchSelection"));
TouchSelection:Property("Name", "TouchSelection");

-- @param nCount: number of object selected. 
TouchSelection:Signal("SelectionChanged", function(nCount) end);
TouchSelection:Signal("SelectionDeleted", function() end);

function TouchSelection:ctor()
	-- array of blocks
	self.cur_selection = {}; 
	-- mapping from block index to true. 
	self.selection_map = {};
end

function TouchSelection:ClearAll()
	self.cur_selection = {};
	self.selection_map = {};
	self.px, self.py, self.pz = nil, nil, nil;

	self:NortifySelectionChange();
end

function TouchSelection:AddToSelection(x, y, z)
	local index = BlockEngine:GetSparseIndex(x, y, z);
	if(not self.selection_map[index]) then
		self.selection_map[index] = true;
		self.cur_selection[#(self.cur_selection)+1] = {x,y,z};
		return true;
	end
end

function TouchSelection:NortifySelectionChange()
	-- signal
	self:SelectionChanged(self:GetSelectionCount());
end

function TouchSelection:GetCurSelection()
	return self.cur_selection;
end

function TouchSelection:IsEmpty()
	return #(self.cur_selection) == 0;
end

function TouchSelection:GetSelectionCount()
	return #(self.cur_selection);
end


function TouchSelection:DeleteAllBlocks()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DestroyNearbyBlocksTask.lua");
	local task = MyCompany.Aries.Game.Tasks.DestroyNearbyBlocks:new({
		explode_time=200, 
		destroy_blocks = self.cur_selection,
	})
	task:Run();
	self:ClearAll();

	-- signal: 
	self:SelectionDeleted();
end

-- pick selected block to current player's hand if selection count is 1. 
function TouchSelection:TryPickSelection()
	if(self:GetSelectionCount() == 1) then
		if(GameLogic.GameMode:IsEditor()) then
			-- similar to alt + left click to get the block in hand without destroying it
			local block = self.cur_selection[1];
			local block_id = BlockEngine:GetBlockId(block[1], block[2], block[3]);
			if(block_id) then
				GameLogic.SetBlockInRightHand(block_id);
			end
		end
	end
end

-- @param dx, dy, dz: if nil, default to 0,1,0
function TouchSelection:ExtrudeSelection(dx, dy, dz)
	if(#(self.cur_selection) > 0) then
		if(not dx and not dy and not dz) then
			dx,dy,dz = 0, 1, 0;
		else
			dx,dy,dz = (dx or 0), (dy or 0), (dz or 0);
		end
		self.px, self.py, self.pz = (self.px or 0), (self.py or 0), (self.pz or 0);
		if( (dx~=0) or (dy~=0) or (dz~=0)) then
			local params = {blocks = self.cur_selection};

			-- tricky: only allow extruding one direction.
			if(self.px*dx <= 0) then
				self.px = 0
			end
			if(self.py*dy <= 0) then
				self.py = 0;
			end
			if(self.pz*dz <= 0) then
				self.pz = 0;
			end

			self.px = self.px + dx;
			params.dx = self.px;

			self.py = self.py + dy;
			params.dy = self.py;

			self.pz = self.pz + dz;
			params.dz = self.pz;

			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ExtrudeBlocksTask.lua");
			local task = MyCompany.Aries.Game.Tasks.ExtrudeBlocks:new(params)
			task:Run();
		end
	end
end

function TouchSelection:CopyTo(dx, dy, dz, bSolidOrWired)
	-- TODO:
end

-- slot: 
function TouchSelection:EditSelection()
	if(self:GetSelectionCount() == 1) then
		local curSelBlock = self:GetCurSelection()[1];
		if(curSelBlock) then
			local x, y, z = curSelBlock[1], curSelBlock[2], curSelBlock[3];
			local block_id = BlockEngine:GetBlockId(x,y,z);
			return GameLogic.GetPlayerController():OnClickBlock(block_id, x,y,z, "right", EntityManager.GetPlayer());
		end
	else
		-- TODO: group operation, such as copy, translate, rotation, etc. 
	end
end