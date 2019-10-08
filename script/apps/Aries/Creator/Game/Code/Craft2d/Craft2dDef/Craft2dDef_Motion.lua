--[[
Title: Craft2dDef_Motion
Author(s): leio
Date: 2019/10/4
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/Craft2d/Craft2dDef/Craft2dDef_Motion.lua");
local Craft2dDef_Motion = commonlib.gettable("MyCompany.Aries.Game.Code.Craft2d.Craft2dDef_Motion");
-------------------------------------------------------
]]
local Craft2dDef_Motion = commonlib.gettable("MyCompany.Aries.Game.Code.Craft2d.Craft2dDef_Motion");
local cmds = {

{
	type = "craft2d.left", 
	message0 = L"向左移动一步",
    
	category = "Craft2d.Motion", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description_js = 'codeOrgAPI.moveDirection(null, target, 3)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "craft2d.right", 
	message0 = L"向右移动一步",
    
	category = "Craft2d.Motion", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description_js = 'codeOrgAPI.moveDirection(null, target, 1)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "craft2d.up", 
	message0 = L"向上移动一步",
    
	category = "Craft2d.Motion", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description_js = 'codeOrgAPI.moveDirection(null, target, 0)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "craft2d.down", 
	message0 = L"向下移动一步",
    
	category = "Craft2d.Motion", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description_js = 'codeOrgAPI.moveDirection(null, target, 2)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

};
function Craft2dDef_Motion.GetCmds()
	return cmds;
end
