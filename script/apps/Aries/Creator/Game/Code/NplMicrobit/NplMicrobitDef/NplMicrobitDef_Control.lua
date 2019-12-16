--[[
Title: NplMicrobitDef_Control
Author(s): leio
Date: 2019/7/19
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicrobit/NplMicrobitDef/NplMicrobitDef_Control.lua");
-------------------------------------------------------
]]
NPL.export({


{
	type = "repeat", 
	message0 = L"重复%1次",
	message1 = L"%1",
	arg0 = {
		{
			name = "times",
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
	category = "NplMicrobit.Control", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'for i=1, %d do\\n%send',
	ToPython = function(self)
		local input = self:getFieldAsString('input')
		if input == '' then
			input = 'pass'
		end
		return string.format('for i in range(%d):\n    %s\n', self:getFieldValue('times'), input);
	end,
	ToNPL = function(self)
		return string.format('for i=1, %d do\n    %s\nend\n', self:getFieldValue('times'), self:getFieldAsString('input'));
	end,
	examples = {{desc = "", canRun = true, code = [[
for i=1, 10 do
    moveForward(0.1)
end
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
	category = "NplMicrobit.Control", 
	helpUrl = "", 
	canRun = false,
	funcName = "while",
	previousStatement = true,
	nextStatement = true,
	func_description = 'while(true) do\\n%send',
	ToPython = function(self)
		local input = self:getFieldAsString('input')
		if input == '' then
			input = 'pass'
		end
		return string.format('while True:\n    %s\n', input);
	end,
	ToNPL = function(self)
		return string.format('while(true) do\n    %s\nend\n', self:getFieldAsString('input'));
	end,
	examples = {{desc = "", canRun = true, code = [[
while(true) do
    moveForward(0.01)
end
]]}},
},
{
	type = "repeat_count", 
	message0 = L"循环:变量%1从%2到%3",
	message1 = L"%1",
	arg0 = {
		{
			name = "var",
			type = "field_input",
			text = "i",
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
	category = "NplMicrobit.Control", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "for",
	func_description = 'for %s=%d, %d do\\n%send',
	ToPython = function(self)
		local input = self:getFieldAsString('input')
		if input == '' then
			input = 'pass'
		end
		return string.format('for %s in range(%d, %d):\n    %s\n', self:getFieldValue('var'),self:getFieldValue('start_index'),self:getFieldValue('end_index'), input);
	end,
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
	type = "repeat_count_step", 
	message0 = L"循环:变量%1从%2到%3递增%4",
	message1 = L"%1",
	arg0 = {
		{
			name = "var",
			type = "field_input",
			text = "i",
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
        {
			name = "step",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
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
	func_description = 'for %s=%d, %d, %d do\\n%send',
	ToPython = function(self)
		local input = self:getFieldAsString('input')
		if input == '' then
			input = 'pass'
		end
		return string.format('for %s in range(%d, %d, %d):\n    %s\n', self:getFieldValue('var'),self:getFieldValue('start_index'),self:getFieldValue('end_index'), self:getFieldValue('step'), input);
	end,
	ToNPL = function(self)
		return string.format('for %s=%d, %d, %d do\n    %s\nend\n', self:getFieldValue('var'),self:getFieldValue('start_index'),self:getFieldValue('end_index'), self:getFieldValue('step'), self:getFieldAsString('input'));
	end,
	examples = {{desc = "", canRun = true, code = [[
for i=1, 10, 1 do
    moveForward(i + 1)
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
	category = "NplMicrobit.Control", 
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
	category = "NplMicrobit.Control", 
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


})
