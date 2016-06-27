--[[
Title: Simple Shapes Commands
Author(s): LiXizhi
Date: 2013/2/9
Desc: create simple shapes by commands
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandShapes.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/SlashCommand/SlashCommand.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CmdParser.lua");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");

Commands["box"] = {
	name="box", 
	quick_ref="/box dx dy dz", 
	desc=[[create a box
@param dx dy dz: the size of the box.
e.g.
/box 3 1 5   --create a box 3*1*5 sized
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateSimpleShapeTask.lua");
		
		local dx,dy,dz;
		dx, cmd_text = CmdParser.ParseInt(cmd_text);
		dy, cmd_text = CmdParser.ParseInt(cmd_text);
		dz, cmd_text = CmdParser.ParseInt(cmd_text);
		if(dx and dy and dz) then
			local task = MyCompany.Aries.Game.Tasks.CreateSimpleShape:new({shape="box", dx=dx, dy=dy, dz=dz})
			task:Run();
		end
	end,
};

Commands["ring"] = {
	name="ring", 
	quick_ref="/ring [x|y|z] radius [thickness]", 
	desc=[[create a ring
@param x|y|z: default to "y" axis
e.g.
/ring 10 2
/ring x 10 2
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		if(not GameLogic.is_started) then
			return 
		end
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateSimpleShapeTask.lua");
		local plane, radius, thickness = cmd_text:match("(%a*)%s*(%d+)%s*(%d*)");
		radius = tonumber(radius or 10);
		if(thickness) then
			thickness = tonumber(thickness);
		end
		if(plane and plane == "") then
			plane = "y";
		end
		local task = MyCompany.Aries.Game.Tasks.CreateSimpleShape:new({shape="ring", radius=radius, thickness=thickness, plane = plane})
		task:Run();
	end,
};

Commands["circle"] = {
	name="circle", 
	quick_ref="/circle [x|y|z] radius", 
	desc=[[create a circle using current block
@param x|y|z: default to "y" axis
e.g.
/circle 4
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		if(not GameLogic.is_started) then
			return 
		end
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateSimpleShapeTask.lua");
		local plane, radius = cmd_text:match("(%a*)%s*(%d+)");
		radius = tonumber(radius or 10);
		if(plane and plane == "") then
			plane = "y";
		end
		local task = MyCompany.Aries.Game.Tasks.CreateSimpleShape:new({shape="circle", radius=radius, plane = plane})
		task:Run();
	end,
};

Commands["sphere"] = {
	name="sphere", 
	quick_ref="/sphere radius [beSolid]", 
	desc=[[create a sphere
@param beSolid: default to true. 
e.g.
/sphere 4
/sphere 4 false
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		if(not GameLogic.is_started) then
			return 
		end
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateSimpleShapeTask.lua");
		local radius, beSolid = cmd_text:match("(%d+)%s*(%a*)");
		radius = tonumber(radius or 10);
		if(beSolid and beSolid == "true") then
			beSolid = true;
		else
			beSolid = false;
		end
		local task = MyCompany.Aries.Game.Tasks.CreateSimpleShape:new({shape="sphere", radius=radius, beSolid=beSolid})
		task:Run();
	end,
};

Commands["ellipsoid"] = {
	name="ellipsoid", 
	quick_ref="/ellipsoid radiusX radiusY radiusZ [beSolid]", 
	desc=[[create ellipsoid 
@param beSolid: default to true. 
e.g.
/ellipsoid 3 4 5
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		if(not GameLogic.is_started) then
			return 
		end
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateSimpleShapeTask.lua");
		local radiusX, radiusY, radiusZ, beSolid = cmd_text:match("(%d+)%s*(%d+)%s*(%d+)%s*(%a*)");
		radiusX = tonumber(radiusX or 10);
		radiusY = tonumber(radiusY or 10);
		radiusZ = tonumber(radiusZ or 10);
		if(beSolid and beSolid == "true") then
			beSolid = true;
		else
			beSolid = false;
		end
		local task = MyCompany.Aries.Game.Tasks.CreateSimpleShape:new({shape="ellipsoid", radiusX=radiusX, radiusY=radiusY, radiusZ=radiusZ, beSolid=beSolid})
		task:Run();
	end,
};

