--[[
Title: Block transform
Author(s): LiXizhi
Date: 2013/3/25
Desc: block transform
use the lib:
------------------------------------------------------------
-------------------------------------------------------
]]
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");

local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");



Commands["translate"] = {
	name="translate", 
	quick_ref="/translate from_x from_y from_z (dx dy dz) to offset_x offset_y offset_z", 
	desc=[[/translate from_x from_y from_z (dx dy dz) to offset_x offset_y offset_z
translate blocks e.g.
/translate ~ ~-1 ~ (1 1 1) to 0 3 0
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local from_x, from_y, from_z, from_dx, from_dy, from_dz;
		local offset_x, offset_y, offset_z;

		local options;
		options, cmd_text = CmdParser.ParseOptions(cmd_text);

		from_x, from_y, from_z, cmd_text = CmdParser.ParsePos(cmd_text, fromEntity);

		if(from_x) then
			from_dx, from_dy, from_dz, cmd_text = CmdParser.ParsePosInBrackets(cmd_text);
			local to, cmd_text = CmdParser.ParseText(cmd_text, "to");
			if(to) then
				offset_x, cmd_text = CmdParser.ParseInt(cmd_text);
				if(offset_x) then
					NPL.load("(gl)script/ide/math/vector.lua");
					local vector3d = commonlib.gettable("mathlib.vector3d");
					NPL.load("(gl)script/ide/math/ShapeAABB.lua");
					local ShapeAABB = commonlib.gettable("mathlib.ShapeAABB");

					offset_y, cmd_text = CmdParser.ParseInt(cmd_text);
					offset_z, cmd_text = CmdParser.ParseInt(cmd_text);
					offset_y = offset_y or 0;
					offset_z = offset_z or 0;

					local aabb = ShapeAABB:new();
					if(not from_dx) then
						from_dx, from_dy, from_dz = 0, 0, 0;
					end
					aabb:SetPointAABB(vector3d:new({from_x, from_y, from_z}));
					aabb:Extend(vector3d:new({from_x+from_dx, from_y+from_dy, from_z+from_dz}));

					NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TransformBlocksTask.lua");
					local task = MyCompany.Aries.Game.Tasks.TransformBlocks:new({
						dx = offset_x, dy=offset_y, dz=offset_z, 
						blocks = BlockEngine:GetAllBlocksInfoInAABB(aabb),
						aabb=aabb,
					})
					task:Run();
				end
			end
		end
		
	end,
};

--
Commands["rotate"] = {
	name="rotate", 
	quick_ref="/rotate [x|y|z] from_x from_y from_z (dx dy dz) angle [to pivot_x pivot_y pivot_z]", 
	desc=[[ rotate a region of blocks along a given axis
/rotate [x|y|z] from_x from_y from_z (dx dy dz) angle [to pivot_x pivot_y pivot_z]
/rotate x ~ ~ ~ (3 2 3) 1.57 to ~4 ~ ~
/rotate y ~ ~ ~ (3 2 3) 1.57
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local from_x, from_y, from_z, from_dx, from_dy, from_dz;
		local pivot_x, pivot_y, pivot_z, rotate_axis, angle;

		rotate_axis, cmd_text = CmdParser.ParseWord(cmd_text);
		rotate_axis = rotate_axis or "y"

		from_x, from_y, from_z, cmd_text = CmdParser.ParsePos(cmd_text, fromEntity);

		if(from_x) then
			from_dx, from_dy, from_dz, cmd_text = CmdParser.ParsePosInBrackets(cmd_text);
			angle, cmd_text = CmdParser.ParseInt(cmd_text);
			local to, cmd_text = CmdParser.ParseText(cmd_text, "to");
			if(to) then
				pivot_x, pivot_y, pivot_z, cmd_text = CmdParser.ParsePos(cmd_text, fromEntity);
			end

			NPL.load("(gl)script/ide/math/vector.lua");
			local vector3d = commonlib.gettable("mathlib.vector3d");
			NPL.load("(gl)script/ide/math/ShapeAABB.lua");
			local ShapeAABB = commonlib.gettable("mathlib.ShapeAABB");

			if(angle and from_dx) then
				local aabb = ShapeAABB:new();
				if(not from_dx) then
					from_dx, from_dy, from_dz = 0, 0, 0;
				end
				aabb:SetPointAABB(vector3d:new({from_x, from_y, from_z}));
				aabb:Extend(vector3d:new({from_x+from_dx, from_y+from_dy, from_z+from_dz}));

				NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TransformBlocksTask.lua");
				local task = MyCompany.Aries.Game.Tasks.TransformBlocks:new({
					rot_x = if_else(rotate_axis=="x", angle, nil),
					rot_y = if_else(rotate_axis=="y", angle, nil),
					rot_z = if_else(rotate_axis=="z", angle, nil),
					pivot_x = pivot_x, pivot_y = pivot_y, pivot_z = pivot_z,
					blocks = BlockEngine:GetAllBlocksInfoInAABB(aabb),
					aabb = aabb,
				})
				task:Run();
			end
		end
	end,
};

Commands["offsetworld"] = {
	name="offsetworld", 
	quick_ref="/offsetworld offsetY", 
	desc=[[Offset the entire world vertically to make room for very low or high blocks. 
This is a very time comsuming job and should be used with care. It will search disk for all blocks.
/offsetworld 2    : move all world blocks upwards by 2 blocks. 
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local offsetY;
		offsetY, cmd_text = CmdParser.ParseInt(cmd_text);
		if(offsetY) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/OffsetWorldTask.lua");
			local task = MyCompany.Aries.Game.Tasks.OffsetWorldTask:new():Init(offsetY)
			task:Run();
		end
	end,
};

Commands["touchworld"] = {
	name = "touchworld";
	quick_ref = "/touchworld";
	desc = "Set all regions as modified. You can then save the world";
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/OffsetWorldTask.lua");
		local WorldFileProvider = commonlib.gettable("MyCompany.Aries.Game.World.WorldFileProvider");
		local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
		
		local fileprovider = WorldFileProvider:new():Init();
		local coords = fileprovider:GetAllRegionCoords();
		
		local blockWorld = GameLogic.GetBlockWorld()
		
		for _, coord in ipairs(coords) do
			ParaBlockWorld.LoadRegion(blockWorld, coord.WorldX, coord.WorldY, coord.WorldZ);
			EntityManager.GetRegionContainer(coord.WorldX,coord.WorldZ);
		end
		
		local worldAtt = ParaBlockWorld.GetBlockAttributeObject(blockWorld);
		local count = worldAtt:GetChildCount();

		for i = 0, count - 1 do
			local regionAtt = worldAtt:GetChildAt(i);
			regionAtt:SetField("IsModified", true);
		end
		
	end
}