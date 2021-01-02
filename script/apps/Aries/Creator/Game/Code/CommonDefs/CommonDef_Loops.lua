--[[
Title: CommonDef_Loops
Author(s): leio
Date: 2020/12/14
Desc: 
use the lib:
-------------------------------------------------------
local CommonDef_Loops = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CommonDefs/CommonDef_Loops.lua");
-------------------------------------------------------
]]
NPL.export({
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
	category = "Loops", 
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
	category = "Loops", 
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
    return 'for(var %s = %d; %s <= %d; %s++){\n%s\n}'.format(name,start_index,name,end_index,name,input_statement_input);
    ]],
	ToNPL = function(self)
		return string.format('for %s=%d, %d do\n    %s\nend\n', self:getFieldValue('var'),self:getFieldValue('start_index'),self:getFieldValue('end_index'), self:getFieldAsString('input'));
	end,
	examples = {{desc = "", canRun = true, code = [[
for i=1, 10, 1 do
    moveForward(i)
end
]]}},
},




})
