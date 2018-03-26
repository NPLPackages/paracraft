--[[
Title: block edges or corners
Author(s): LiXizhi
Date: 2017/12/25
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/PatternBlockEdge.lua");
local PatternBlockEdge = commonlib.gettable("MyCompany.Aries.Game.Memory.PatternBlockEdge");
-------------------------------------------------------
]]
local i=0;
local function AutoEnum()
	i = i + 1;
	return i;
end

local PatternBlockEdge = commonlib.createtable("MyCompany.Aries.Game.Memory.PatternBlockEdge", {
	-- two faces whose normals point inwards forms inner edge
	edge_in_top_front = AutoEnum(),
	edge_in_top_left = AutoEnum(),
	edge_in_top_right = AutoEnum(),
	edge_in_top_back = AutoEnum(),
	edge_in_left_front = AutoEnum(),
	edge_in_left_back = AutoEnum(),
	edge_in_right_front = AutoEnum(),
	edge_in_right_back = AutoEnum(),
	edge_in_bottom_front = AutoEnum(),
	edge_in_bottom_left = AutoEnum(),
	edge_in_bottom_right = AutoEnum(),
	edge_in_bottom_back = AutoEnum(),

	-- two faces whose normals point outwards forms outer edge
	edge_out_top_front = AutoEnum(),
	edge_out_top_left = AutoEnum(),
	edge_out_top_right = AutoEnum(),
	edge_out_top_back = AutoEnum(),
	edge_out_left_front = AutoEnum(),
	edge_out_left_back = AutoEnum(),
	edge_out_right_front = AutoEnum(),
	edge_out_right_back = AutoEnum(),
	edge_out_bottom_front = AutoEnum(),
	edge_out_bottom_left = AutoEnum(),
	edge_out_bottom_right = AutoEnum(),
	edge_out_bottom_back = AutoEnum(),


	-- three faces whose normals point inwards forms inner corner
	corner_in_xyz	= AutoEnum(),
	corner_in_xyNz	= AutoEnum(),
	corner_in_xNyz	= AutoEnum(),
	corner_in_xNyNz	= AutoEnum(),
	corner_in_Nxyz	= AutoEnum(),
	corner_in_NxyNz	= AutoEnum(),
	corner_in_NxNyz	= AutoEnum(),
	corner_in_NxNyNz  = AutoEnum(),

	-- two faces whose normals point outwards forms outer corner
	corner_out_xyz	= AutoEnum(),
	corner_out_xyNz	= AutoEnum(),
	corner_out_xNyz	= AutoEnum(),
	corner_out_xNyNz	= AutoEnum(),
	corner_out_Nxyz	= AutoEnum(),
	corner_out_NxyNz	= AutoEnum(),
	corner_out_NxNyz	= AutoEnum(),
	corner_out_NxNyNz  = AutoEnum(),

	-- standard faces
	face_left = AutoEnum(),
	face_right = AutoEnum(),
	face_front = AutoEnum(),
	face_back = AutoEnum(),
	face_top = AutoEnum(),
	face_botom = AutoEnum(),
});