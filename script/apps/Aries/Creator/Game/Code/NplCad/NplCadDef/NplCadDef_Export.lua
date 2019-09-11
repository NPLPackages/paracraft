--[[
Title: NplCadDef_Export
Author(s): leio
Date: 2019/9/5
Desc: a set of commands to bind joints and meshes
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplCad/NplCadDef/NplCadDef_Export.lua");
local NplCadDef_Export = commonlib.gettable("MyCompany.Aries.Game.Code.NplCad.NplCadDef_Export");
-------------------------------------------------------
]]
local NplCadDef_Export = commonlib.gettable("MyCompany.Aries.Game.Code.NplCad.NplCadDef_Export");
local cmds = {

{
	type = "exportFile", 
	message0 = L"导出 %1",
    arg0 = {
        
        {
			name = "value",
			type = "field_dropdown",
			options = {
				{ L"stl", "'stl'" },
				{ L"gltf", "'gltf'" },
			},
		},
	},
	category = "Export", 
	helpUrl = "", 
	canRun = false,
	func_description = 'exportFile(%s)',
	ToNPL = function(self)
        return string.format('exportFile(%s)', 
            self:getFieldValue('value')
            );
	end,
	examples = {{desc = "", canRun = true, code = [[
cube("union",1,'#ff0000')
exportFile('gltf')
    ]]}},
}
};
function NplCadDef_Export.GetCmds()
	return cmds;
end
