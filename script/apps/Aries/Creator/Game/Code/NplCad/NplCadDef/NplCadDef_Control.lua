--[[
Title: NplCadDef_Control
Author(s): leio
Date: 2018/9/10
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplCad/NplCadDef/NplCadDef_Control.lua");
local NplCadDef_Control = commonlib.gettable("MyCompany.Aries.Game.Code.NplCad.NplCadDef_Control");
-------------------------------------------------------
]]
local NplCadDef_Control = commonlib.gettable("MyCompany.Aries.Game.Code.NplCad.NplCadDef_Control");
local cmds = {
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
	category = "Control", 
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
	category = "Control", 
	helpUrl = "", 
	canRun = false,
	funcName = "if",
	previousStatement = true,
	nextStatement = true,
	func_description = 'if(%s) then\\n%send',
	ToPython = function(self)
		local input = self:getFieldAsString('input_true')
		if input == '' then
			input = 'pass'
		end
		return string.format('if %s:\n    %s\n', self:getFieldAsString('expression'), input);
	end,
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
	category = "Control", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'if(%s) then\\n%selse\\n%send',
	ToPython = function(self)
		local input_true = self:getFieldAsString('input_true')
		local input_else = self:getFieldAsString('input_else')
		if input_true == '' then
			input_true = 'pass'
		end
		if input_else == '' then
			input_else = 'pass'
		end
		return string.format('if %s:\n    %s\nelse:\n    %s\n', self:getFieldAsString('expression'), input_true, input_else);
	end,
	ToNPL = function(self)
		return string.format('if(%s) then\n    %s\nelse\n    %s\nend\n', self:getFieldAsString('expression'), self:getFieldAsString('input_true'), self:getFieldAsString('input_else'));
	end,
	examples = {{desc = "", canRun = true, code = [[
while(true) do
    if(distanceTo("mouse-pointer")<3) then
        say("mouse-pointer")
    else
        say("")
    end
    wait(0.01)
end
]]}},
},

};
function NplCadDef_Control.GetCmds()
	return cmds;
end
