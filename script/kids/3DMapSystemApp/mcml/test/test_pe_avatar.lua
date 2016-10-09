--[[
Title: test all mcml avatar tags
Author(s): WangTian
Date: 2008/3/16
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/test/test_pe_avatar.lua");
test_pe_avatar()
%TESTCASE{"test pe:avatar", func="test_pe_avatar"}%
-------------------------------------------------------
]]
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/mcml.lua");

-- TODO: test
function test_pe_avatar()
	
	local testString = [[
<pe:avatar uid = "6ea1ce24-bdf7-4893-a053-eb5fd2a74281" /pe:avatar>
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