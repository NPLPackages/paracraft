--[[
Title: 
Author(s): Leio
Date: 2010/06/21
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/test/test_aries_camera.lua");
test_camera()
-------------------------------------------------------
]]
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/mcml.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/aries_camera.lua");

function test_camera()
	local file = ParaIO.open("script/kids/3DMapSystemApp/mcml/test/test_aries_camera.xml", "r")
	if(file:IsValid()) then
		local mcmlNode = ParaXML.LuaXML_ParseString(file:GetText())
		file:close();
		
		if(mcmlNode) then
			mcmlNode = Map3DSystem.mcml.buildclass(mcmlNode);
			mcmlNode = mcmlNode[1];

			local facing = 0.6;
			local start_point_pos = { 246, 1.3, 261.5 };
			local end_point_pos = { 246, 1.3, 238 };
			local ground_pos = { 250.33, 2.77, 249.84 };
			mcmlNode.facing = facing;
			mcmlNode.start_point_pos = start_point_pos;
			mcmlNode.end_point_pos = end_point_pos;
			mcmlNode.ground_pos = ground_pos;
			commonlib.echo(mcmlNode.name,true); 
			local nodes = Map3DSystem.mcml_controls.aries_camera.create("test", mcmlNode, nil, _parent, 10, 10, 400, 400)
			commonlib.echo(nodes);
		end		
	end		
end