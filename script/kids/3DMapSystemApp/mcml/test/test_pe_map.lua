--[[
Title: test all mcml map tags
Author(s): WangTian
Date: 2008/3/24
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/test/test_pe_map.lua");
test_pe_map()
%TESTCASE{"test pe:map", func="test_pe_map"}%
-------------------------------------------------------
]]
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/mcml.lua");

-- TODO: test
function test_pe_map()
	
	local testString = [[
<pe:map /pe:map>
	]];
	local mcmlNode = ParaXML.LuaXML_ParseString(testString);
	
	if(mcmlNode) then
		-- log(commonlib.serialize(mcmlNode));
		Map3DSystem.mcml.buildclass(mcmlNode);
		
		Map3DSystem.mcml_controls.create("test", mcmlNode, nil, _parent, 10, 10, 400, 400);
		
		---- create a dialog with tab pages. 
		--_guihelper.ShowDialogBox("Test MCML renderer", nil, nil, 400, 400, 
			--function(_parent)
				--Map3DSystem.mcml_controls.create("me", mcmlNode, nil, _parent, 10, 10, 400, 400)
			--end,
			--function(dialogResult)
				--if(dialogResult == _guihelper.DialogResult.OK) then
				--end
				--return true;
			--end);
	end		
end