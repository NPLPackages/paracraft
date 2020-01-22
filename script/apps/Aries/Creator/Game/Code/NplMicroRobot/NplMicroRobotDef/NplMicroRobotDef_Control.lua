--[[
Title: NplMicroRobotDef_Control
Author(s): leio
Date: 2019/7/19
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicroRobot/NplMicroRobotDef/NplMicroRobotDef_Control.lua");
-------------------------------------------------------
]]
NPL.export({
{
	type = "microbit_pause", 
	message0 = L"等待 %1 毫秒",
	arg0 = {
        {
			name = "text",
            type = "input_value",
            shadow = { type = "math_number", value = 1000,},
			text = 1000, 
		},
	},
    
	category = "NplMicroRobot.Control", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'microbit_pause(%s)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "forever", 
	message0 = L"永远重复%1",
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
	category = "NplMicroRobot.Control", 
	helpUrl = "", 
	canRun = false,
	funcName = "while",
	previousStatement = true,
	nextStatement = true,
	func_description = 'while(true) do\\n%send',
	func_description_js = 'while(true){\\n%s}',
	ToNPL = function(self)
		return string.format('while(true) do\n    %s\nend\n', self:getFieldAsString('input'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "repeat_count", 
	message0 = L"循环:变量%1从%2到%3",
	message1 = L"%1",
	arg0 = {
		{
			name = "var",
			type = "field_variable",
			variable = "i",
			variableTypes = {""},
			text = "key",
		},
        {
			name = "start_index",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
        {
			name = "end_index",
			type = "input_value",
            shadow = { type = "math_number", value = 10,},
			text = 10, 
		},
        
	},
    arg1 = {
		{
			name = "input",
			type = "input_statement",
		},
	},
	category = "NplMicroRobot.Control", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "for",
	func_description = 'for %s=%d, %d do\\n%send',
    func_description_js_provider = [[
    var name = Blockly.JavaScript.variableDB_.getName(block.getFieldValue('var'), Blockly.Variables.NAME_TYPE) || 'i';
    var start_index = Blockly.JavaScript.valueToCode(block,'start_index', Blockly.JavaScript.ORDER_ATOMIC) || '""';
    var end_index = Blockly.JavaScript.valueToCode(block,'end_index', Blockly.JavaScript.ORDER_ATOMIC) || '""';
    var input_statement_input = Blockly.JavaScript.statementToCode(block, 'input') || '';
    return 'for(let %s = %d; %s <= %d; %s++){\n%s\n}\n'.format(name,start_index,name,end_index,name,input_statement_input);
    ]],
	ToNPL = function(self)
		return string.format('for %s=%d, %d do\n    %s\nend\n', self:getFieldValue('var'),self:getFieldValue('start_index'),self:getFieldValue('end_index'), self:getFieldAsString('input'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "control_if", 
	message0 = L"如果%1那么",
	message1 = L"%1",
	arg0 = {
		{
			name = "expression",
			type = "input_value",
		},
    },
    arg1 = {
		{
			name = "input_true",
			type = "input_statement",
			text = "", 
		},
	},
	category = "NplMicroRobot.Control", 
	helpUrl = "", 
	canRun = false,
	funcName = "if",
	previousStatement = true,
	nextStatement = true,
	func_description = 'if(%s) then\\n%send',
	func_description_js = 'if(%s){\\n%s}',
	ToNPL = function(self)
		return string.format('if(%s) then\n    %s\nend\n', self:getFieldAsString('expression'), self:getFieldAsString('input_true'));
	end,
	examples = {{desc = "", canRun = true, code = [[

]]}},
},

{
	type = "if_else", 
	message0 = L"如果%1那么",
	message1 = L"%1",
	message2 = L"否则",
	message3 = L"%1",
	arg0 = {
		{
			name = "expression",
			type = "input_value",
		},
    },
    arg1 = {
		{
			name = "input_true",
			type = "input_statement",
			text = "", 
		},
	},
    arg3 = {
		{
			name = "input_else",
			type = "input_statement",
			text = "", 
		},
	},
	category = "NplMicroRobot.Control", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'if(%s) then\\n%selse\\n%send',
	func_description_js = 'if(%s){\\n%s}else{\\n%s}',
	ToNPL = function(self)
		return string.format('if(%s) then\n    %s\nelse\n    %s\nend\n', self:getFieldAsString('expression'), self:getFieldAsString('input_true'), self:getFieldAsString('input_else'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},





})
