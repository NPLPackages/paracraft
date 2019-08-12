--[[
Title: NplMicrobitDef_Control
Author(s): leio
Date: 2019/7/19
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
	type = "microbit.start", 
	message0 = L"启动%1",
	message1 = L"%1",
    arg0 = {
		{
			name = "label_dummy",
			type = "input_dummy",
		},
	},
	arg1 = {
		{
			name = "input",
			type = "input_statement",
		},
	},
	category = "NplMicrobit.Control", 
	helpUrl = "", 
	canRun = false,
	nextStatement = true,
	func_description_py = 'while True:\\n%s',
	ToNPL = function(self)
		return "";
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "microbit.button.is_pressed", 
	message0 = L"当 %1 按钮按下",
	message1 = L"%1",
    arg0 = {
		{
			name = "buttons",
			type = "field_dropdown",
			options = {
				{ L"A", "button_a" },
				{ L"B", "button_b" },
			},
		},
	},
	arg1 = {
		{
			name = "input",
			type = "input_statement",
		},
	},
	category = "NplMicrobit.Control", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description_py = 'if microbit.%s.is_pressed():\\n%s',
	ToNPL = function(self)
		return "";
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "microbit.display.show", 
	message0 = L"显示 %1",
	arg0 = {
        {
			name = "text",
            type = "field_matrix",
		},
	},
    
	category = "NplMicrobit.Control", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description_py = 'microbit.display.show(GetImage("%s"))',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "microbit.display.scroll", 
	message0 = L"显示 %1",
	arg0 = {
        {
			name = "text",
            type = "input_value",
            shadow = { type = "text", value = L"hello",},
			text = L"hello", 
		},
	},
    
	category = "NplMicrobit.Control", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description_py = 'microbit.display.scroll(%s)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "microbit.display.clear", 
	message0 = L"清除显示",
	arg0 = {
	},
    
	category = "NplMicrobit.Control", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description_py = 'microbit.display.clear()',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "microbit.sleep", 
	message0 = L"休眠 %1 毫秒",
	arg0 = {
        
        {
			name = "time",
			type = "input_value",
            shadow = { type = "math_number", value = 1000,},
			text = 1000, 
		},
        
	},
    
	category = "NplMicrobit.Control", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description_py = 'microbit.sleep(%d)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

};
function NplMicrobitDef_Control.GetCmds()
	return cmds;
end
