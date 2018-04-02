--[[
Title: Pattern generator for blocks
Author(s): LiXizhi
Date: 2017/12/25
Desc: generate patterns from a given set of attention blocks and a viewpoint and direction.
because attention blocks are mostly static, we will also save edge information into attention blocks.
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/PatternGenBlocks.lua");
local PatternGenBlocks = commonlib.gettable("MyCompany.Aries.Game.Memory.PatternGenBlocks");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/Pattern.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/PatternBlockEdge.lua");
local PatternBlockEdge = commonlib.gettable("MyCompany.Aries.Game.Memory.PatternBlockEdge");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local Pattern = commonlib.gettable("MyCompany.Aries.Game.Memory.Pattern");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");

local PatternGenBlocks = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Memory.PatternGenBlocks"));
PatternGenBlocks:Property("Name", "PatternGenBlocks");

-- how many patterns to generate for per block. 
PatternGenBlocks:Property({"compression_rate", 0.1});
-- max block range from current eye position to get pattern recognition attention.
PatternGenBlocks:Property({"maxRadius", 10});

function PatternGenBlocks:ctor()
end


local function GetOffsetBySideAndView(view_direction, side1, side2)
	if(not side2) then
		return Direction.GetOffsetBySideAndView(side1, view_direction);
	else
		local dx, dy, dz = Direction.GetOffsetBySideAndView(side1, view_direction);
		local dx2, dy2, dz2 = Direction.GetOffsetBySideAndView(side2, view_direction);
		return dx+dx2, dy+dy2, dz+dz2;
	end
end

local neighborBlocks = {};

local function ComputeBlockEdge(block, blocks, view_direction)
	if(block.view_direction == view_direction and block.edges) then
		return;
	elseif(block.view_direction ~= view_direction and block.edges) then
		table.clear(block.edges);
	end
	block.edges = block.edges or {};
	local edges = block.edges;
	
	local dx, dy, dz;
	local x,y,z = block.bx, block.by, block.bz;
	for side = 0, 5 do
		local dx, dy, dz = GetOffsetBySideAndView(view_direction, side);
		neighborBlocks[side] = blocks[BlockEngine:GetSparseIndex(x+dx, y+dy, z+dz)];
	end
	local edge;
	if(not neighborBlocks[5]) then
		edges[#edges+1] = PatternBlockEdge.face_top;

		if(not neighborBlocks[0]) then
			edges[#edges+1] = PatternBlockEdge.edge_out_top_left;
		elseif(not neighborBlocks[1]) then
			edges[#edges+1] = PatternBlockEdge.edge_out_top_right;
		elseif(not neighborBlocks[2]) then
			edges[#edges+1] = PatternBlockEdge.edge_out_top_front;
		elseif(not neighborBlocks[3]) then
			edges[#edges+1] = PatternBlockEdge.edge_out_top_back;
		end

		dx, dy, dz = GetOffsetBySideAndView(view_direction, 0, 5);
		block = blocks[BlockEngine:GetSparseIndex(x+dx, y+dy, z+dz)];
		if(block) then
			edges[#edges+1] = PatternBlockEdge.edge_in_top_right;
		end

		dx, dy, dz = GetOffsetBySideAndView(view_direction, 1, 5);
		block = blocks[BlockEngine:GetSparseIndex(x+dx, y+dy, z+dz)];
		if(block) then
			edges[#edges+1] = PatternBlockEdge.edge_in_top_left;
		end

		dx, dy, dz = GetOffsetBySideAndView(view_direction, 2, 5);
		block = blocks[BlockEngine:GetSparseIndex(x+dx, y+dy, z+dz)];
		if(block) then
			edges[#edges+1] = PatternBlockEdge.edge_in_top_back;
		end

		dx, dy, dz = GetOffsetBySideAndView(view_direction, 3, 5);
		block = blocks[BlockEngine:GetSparseIndex(x+dx, y+dy, z+dz)];
		if(block) then
			edges[#edges+1] = PatternBlockEdge.edge_in_top_front;
		end
	end
	if(not neighborBlocks[4]) then
		edges[#edges+1] = PatternBlockEdge.face_bottom;
		if(not neighborBlocks[0]) then
			edges[#edges+1] = PatternBlockEdge.edge_out_bottom_left;
		elseif(not neighborBlocks[1]) then
			edges[#edges+1] = PatternBlockEdge.edge_out_bottom__right;
		elseif(not neighborBlocks[2]) then
			edges[#edges+1] = PatternBlockEdge.edge_out_bottom__front;
		elseif(not neighborBlocks[3]) then
			edges[#edges+1] = PatternBlockEdge.edge_out_bottom__back;
		end

		dx, dy, dz = GetOffsetBySideAndView(view_direction, 0, 4);
		block = blocks[BlockEngine:GetSparseIndex(x+dx, y+dy, z+dz)];
		if(block) then
			edges[#edges+1] = PatternBlockEdge.edge_in_bottom_right;
		end

		dx, dy, dz = GetOffsetBySideAndView(view_direction, 1, 4);
		block = blocks[BlockEngine:GetSparseIndex(x+dx, y+dy, z+dz)];
		if(block) then
			edges[#edges+1] = PatternBlockEdge.edge_in_bottom_left;
		end

		dx, dy, dz = GetOffsetBySideAndView(view_direction, 2, 4);
		block = blocks[BlockEngine:GetSparseIndex(x+dx, y+dy, z+dz)];
		if(block) then
			edges[#edges+1] = PatternBlockEdge.edge_in_bottom_back;
		end

		dx, dy, dz = GetOffsetBySideAndView(view_direction, 3, 4);
		block = blocks[BlockEngine:GetSparseIndex(x+dx, y+dy, z+dz)];
		if(block) then
			edges[#edges+1] = PatternBlockEdge.edge_in_bottom_front;
		end
	end
	if(not neighborBlocks[0]) then
		if(not neighborBlocks[2]) then
			edges[#edges+1] = PatternBlockEdge.edge_out_left_front;
		elseif(not neighborBlocks[3]) then
			edges[#edges+1] = PatternBlockEdge.edge_out_left_back;
		end

		dx, dy, dz = GetOffsetBySideAndView(view_direction, 0, 3);
		block = blocks[BlockEngine:GetSparseIndex(x+dx, y+dy, z+dz)];
		if(block) then
			edges[#edges+1] = PatternBlockEdge.edge_in_left_front;
		end

		dx, dy, dz = GetOffsetBySideAndView(view_direction, 0, 2);
		block = blocks[BlockEngine:GetSparseIndex(x+dx, y+dy, z+dz)];
		if(block) then
			edges[#edges+1] = PatternBlockEdge.edge_in_left_back;
		end
	end
	if(not neighborBlocks[1]) then
		if(not neighborBlocks[2]) then
			edges[#edges+1] = PatternBlockEdge.edge_out_right_front;
		elseif(not neighborBlocks[3]) then
			edges[#edges+1] = PatternBlockEdge.edge_out_right_back;
		end

		dx, dy, dz = GetOffsetBySideAndView(view_direction, 1, 3);
		block = blocks[BlockEngine:GetSparseIndex(x+dx, y+dy, z+dz)];
		if(block) then
			edges[#edges+1] = PatternBlockEdge.edge_in_right_front;
		end

		dx, dy, dz = GetOffsetBySideAndView(view_direction, 1, 2);
		block = blocks[BlockEngine:GetSparseIndex(x+dx, y+dy, z+dz)];
		if(block) then
			edges[#edges+1] = PatternBlockEdge.edge_in_right_back;
		end
	end
end

-- generate raw pattern near the given viewpoint. 
-- @param blocks: attentioned blocks map
-- @param view_direction: 0 is x:-1 	1 is x:+1 	2 is z:-1	3 is z:+1
-- @param cx,cy,cz: current view position, this could be the player or eye position. 
-- @param maxRadius: max block range from current eye position to get pattern recognition attention. default to 10. 
function PatternGenBlocks:Generate(blocks, cx,cy,cz, view_direction, maxRadius)
	local index = BlockEngine:GetSparseIndex(cx,cy,cz)
	
	maxRadius = maxRadius or self.maxRadius;
	local radiusSq = maxRadius * maxRadius;

	for index, block in pairs(blocks) do
		local x,y,z = block.bx, block.by, block.bz;
		-- ignore the negative half space of view direction.
		if( (view_direction == 0 and (x-cx) <= 0) or (view_direction == 1 and (x-cx) >= 0) or 
			(view_direction == 2 and (z-cz) <= 0) or (view_direction == 3 and (z-cz) >= 0)) then
			-- make sure we are only processing a small region around the current view(eye or player) pos.
			local distSq = (x-cx)^2 + (y-cy)^2 + (z-cz)^2;
			if(  distSq < radiusSq ) then
				ComputeBlockEdge(block, blocks, view_direction);
			end
		end
	end
end


-- generate all edges to the attention blocks
function PatternGenBlocks:GenerateEdges(blocks)
end