--[[
Title: NplMicrobitDef_Looks
Author(s): leio
Date: 2019/11/29
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicrobit/NplMicrobitDef/NplMicrobitDef_Looks.lua");
-------------------------------------------------------
]]
NPL.export({

{
	type = "microbit_display_show", 
	message0 = L"显示 %1",
	arg0 = {
        {
			name = "text",
            type = "field_matrix",
		},
	},
    
	category = "NplMicrobit.Looks", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'microbit_display_show("%s")',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "microbit_display_scroll", 
	message0 = L"显示 %1",
	arg0 = {
        {
			name = "text",
            type = "input_value",
            shadow = { type = "text", value = L"hello",},
			text = L"hello", 
		},
	},
    
	category = "NplMicrobit.Looks", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'microbit_display_scroll(%s)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "microbit_display_clear", 
	message0 = L"清除显示",
	arg0 = {
	},
    
	category = "NplMicrobit.Looks", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'microbit_display_clear()',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

})