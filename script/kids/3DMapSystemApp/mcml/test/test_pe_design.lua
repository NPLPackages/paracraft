--[[
Title: test all mcml design tags
Author(s): LiXizhi
Date: 2008/2/16
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/test/test_pe_design.lua");
test_pe_layoutflow()
test_pe_tabs()
%TESTCASE{"layout flow", func="test_pe_layoutflow"}%
%TESTCASE{"pe:* common tags", func="test_pe_tabs"}%
-------------------------------------------------------
]]
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/mcml.lua");

-- test passed by LiXizhi on 2008.2.16 
function test_pe_tabs()
	local file = ParaIO.open("script/kids/3DMapSystemApp/mcml/test/dlg_tabs.xml", "r")
	if(file:IsValid()) then
		local mcmlNode = ParaXML.LuaXML_ParseString(file:GetText())
		file:close();
		
		if(mcmlNode) then
			-- log(commonlib.serialize(mcmlNode));
			Map3DSystem.mcml.buildclass(mcmlNode);
			
			Map3DSystem.mcml_controls.create("test", mcmlNode, nil, _parent, 10, 10, 400, 400)
			
			--[[ create a dialog with tab pages. 
			_guihelper.ShowDialogBox("Test MCML renderer", nil, nil, 400, 400, 
				function(_parent)
					Map3DSystem.mcml_controls.create("me", mcmlNode, nil, _parent, 10, 10, 400, 400)
				end,
				function(dialogResult)
					if(dialogResult == _guihelper.DialogResult.OK) then
					end
					return true;
				end);
			--]]
		end		
	end		
end

-- test passed by LiXizhi on 2008.2.19
function test_pe_layoutflow()
local file = ParaIO.open("script/kids/3DMapSystemApp/mcml/test/dlg_layoutflow.xml", "r")
	if(file:IsValid()) then
		local mcmlNode = ParaXML.LuaXML_ParseString(file:GetText())
		file:close();
		if(mcmlNode) then
			Map3DSystem.mcml.buildclass(mcmlNode);
			Map3DSystem.mcml_controls.create("test", mcmlNode, nil, _parent, 10, 10, 400, 400)
		end
	end
end

function test_pe_dialog_onclick(dialogResult)
	if(dialogResult == _guihelper.DialogResult.OK) then
		_guihelper.MessageBox("u clicked ok");
	end
	return true;
end
-- @param onclick: the onclick script name or an URL to receive result using HTTP post. 
--  if it is a script name string, the script will be called with function(btnName, values, bindingContext), where btnName is name of button that is clicked and values is nil or a table collecting all name value pairs. 
function test_pe_editor_button_onclick(btnName, values, bindingContext)
	_guihelper.MessageBox(btnName.." clicked:\n"..commonlib.serialize(values));
end
