--[[
Title: NplMicrobitDef_Control
Author(s): leio
Date: 2018/9/10
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicrobit/NplMicrobitDef/NplMicrobitDef_Control.lua");
local NplMicrobitDef_Control = commonlib.gettable("MyCompany.Aries.Game.Code.NplMicrobit.NplMicrobitDef_Control");
-------------------------------------------------------
]]
local NplMicrobitDef_Control = commonlib.gettable("MyCompany.Aries.Game.Code.NplMicrobit.NplMicrobitDef_Control");
local cmds = {
{
	type = "basic_forever", 
	message0 = L"永远执行",
	message1 = L"%1",
    arg1 = {
		{
			name = "input",
			type = "input_statement",
		},
	},
	category = "Control", 
	helpUrl = "", 
	canRun = false,
	nextStatement = true,
	func_description = 'forever(function(){\\n%s\\n})',
	func_description_js = 'basic.forever(function(){\\n%s\\n})',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[

]]}},
},

{
	type = "basic_pause", 
	message0 = L"暂停 %1 毫秒",
    arg0 = {
		{
			name = "time",
			type = "input_value",
            shadow = { type = "math_number", value = 100,},
			text = 100, 
		},
	},
	category = "Control", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'pause(%s)',
	func_description_js = 'basic.pause(%s)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[

]]}},
},

};
function NplMicrobitDef_Control.GetCmds()
	return cmds;
end
