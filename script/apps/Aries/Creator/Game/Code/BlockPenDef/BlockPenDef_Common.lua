--[[
Title: Block Pen
Author(s): LiXizhi
Date: 2020/2/16
Desc: 
use the lib:
-------------------------------------------------------
-------------------------------------------------------
]]
NPL.export({
-- Operators
{
	type = "math_op", 
	message0 = L"%1 %2 %3",
	arg0 = {
		{
			name = "left",
			type = "input_value",
            shadow = { type = "math_number", },
		},
		{
			name = "op",
			type = "field_dropdown",
			options = {
				{ "+", "+" },{ "-", "-" },{ "*", "*" },{ "/", "/" },
			},
		},
		{
			name = "right",
			type = "input_value",
            shadow = { type = "math_number", },
		},
	},
	output = {type = "field_number",},
	category = "Operators", 
	helpUrl = "", 
	canRun = false,
	func_description = '((%s) %s (%s))',
	ToNPL = function(self)
		return string.format('(%s) %s (%s)', self:getFieldAsString('left'), self:getFieldAsString('op'), self:getFieldAsString('right'));
	end,
	examples = {{desc = L"数字的加减乘除", canRun = true, code = [[
say("1+1=?")
wait(1)
say(1+1)
]]}},
},

{
	type = "math_op_compare_number", 
	message0 = L"%1 %2 %3",
	arg0 = {
		{
			name = "left",
			type = "input_value",
            shadow = { type = "math_number", },
		},
		{
			name = "op",
			type = "field_dropdown",
			options = {
				{ ">", ">" },{ "<", "<" },{ ">=", ">=" },{ "<=", "<=" },{ "==", "==" },{ "!=", "!=" },
			},
		},
		{
			name = "right",
			type = "input_value",
            shadow = { type = "math_number", },
		},
	},
	output = {type = "field_number",},
	category = "Operators", 
	helpUrl = "", 
	canRun = false,
	func_description = '((%s) %s (%s))',
	ToNPL = function(self)
		return string.format('(%s) %s (%s)', self:getFieldAsString('left'), self:getFieldAsString('op'), self:getFieldAsString('right'));
	end,
	examples = {{desc = "", canRun = true, code = [[
if(3>1) then
   say("3>1 == true")
end
]]}},
},

{
	type = "math_op_compare", 
	message0 = L"%1 %2 %3",
	arg0 = {
		{
			name = "left",
			type = "input_value",
            shadow = { type = "text", value = "",},
		},
		{
			name = "op",
			type = "field_dropdown",
			options = {
				{ "==", "==" },{ "!=", "!=" },
			},
		},
		{
			name = "right",
			type = "input_value",
            shadow = { type = "math_number",},
		},
	},
	output = {type = "field_number",},
	category = "Operators", 
	helpUrl = "", 
	canRun = false,
	func_description = '((%s) %s (%s))',
	ToNPL = function(self)
		return string.format('(%s) %s (%s)', self:getFieldAsString('left'), self:getFieldAsString('op'), self:getFieldAsString('right'));
	end,
	examples = {{desc = "", canRun = true, code = [[
if("1" == "1") then
   say("equal")
end
]]}},
},

{
	type = "math_oneop", 
	message0 = L"%1%2",
	arg0 = {
		{
			name = "name",
			type = "field_dropdown",
			options = {
				{ L"开根号", "sqrt" },
				{ "sin", "sin"},
				{ "cos", "cos"},
				{ L"绝对值", "abs"},
				{ "asin", "asin"},
				{ "acos", "acos"},
				{ L"向上取整", "ceil"},
				{ L"向下取整", "floor"},
				{ "tab", "tan"},
				{ "atan", "atan"},
				{ "sin", "exp"},
				{ "log10", "log10"},
				{ "exp", "exp"},
			},
		},
		{
			name = "left",
			type = "input_value",
            shadow = { type = "math_number", value = 9,},
			text = 9,
		},
	},
	output = {type = "field_number",},
	category = "Operators", 
	helpUrl = "", 
	canRun = false,
	func_description = 'math.%s(%s)',
	ToNPL = function(self)
		return string.format('math.%s(%s)', self:getFieldAsString('name'), self:getFieldAsString('left'));
	end,
	examples = {{desc = "", canRun = true, code = [[
say("math.sqrt(9)=="..math.sqrt(9), 1)
say("math.cos(1)=="..math.cos(1), 1)
say("math.abs(-1)=="..math.abs(1), 1)
]]}},
},

-- Data
{
	type = "getLocalVariable", 
	message0 = L"变量%1",
	arg0 = {
		{
			name = "var",
			type = "field_input",
			text = "score",
		},
	},
	output = {type = "null",},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s',
	ToNPL = function(self)
		return self:getFieldAsString('var');
	end,
	examples = {{desc = "", canRun = true, code = [[
local key = "value"
say(key, 1)
]]}},
},


{
	type = "assign", 
	message0 = L"%1赋值为%2",
	arg0 = {
		{
			name = "left",
			type = "input_value",
			shadow = { type = "getLocalVariable", value = "score",},
			text = "score",
		},
		{
			name = "right",
			type = "input_value",
			shadow = { type = "math_number", value = 1,},
			text = 1,
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = '%s = %s',
	ToNPL = function(self)
		return 'key = "value"\n';
	end,
	examples = {{desc = "", canRun = true, code = [[
text = "hello"
say(text, 1)
]]}},
},

{
	type = "getNumber", 
	message0 = L"%1",
	arg0 = {
		{
			name = "left",
			type = "field_number",
			text = "0",
		},
	},
	output = {type = "field_number",},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s',
	ToNPL = function(self)
		return string.format('%s', self:getFieldAsString('left'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},
{
	type = "getColor", 
	message0 = "%1",
	arg0 = {
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ff0000",},
			text = "#ff0000",
		},
	},
	output = {type = "null",},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s',
	ToNPL = function(self)
		return string.format('"%s"', self:getFieldAsString('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},
{
	type = "newFunction", 
	message0 = L"新函数(%1)",
	message1 = L"%1",
	arg0 = {
		{
			name = "param",
			type = "field_input",
			text = "param", 
		},
	},
    arg1 = {
        {
			name = "input",
			type = "input_statement",
			text = "", 
		},
    },
	output = {type = "field_number",},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = 'function(%s)\\n%send',
	ToNPL = function(self)
		return string.format('function(%s)\n    %s\nend\n', self:getFieldAsString('param'), self:getFieldAsString('input'));
	end,
	examples = {{desc = "", canRun = true, code = [[
local thinkText = function(text)
	say(text.."...")
end
thinkText("Let me think");
]]}},
},

{
	type = "callFunction", 
	message0 = L"调用函数%1(%2)",
	arg0 = {
		{
			name = "name",
			type = "field_input",
			text = "log",
		},
		{
			name = "param",
			type = "input_value",
			shadow = { type = "text", value = "param",},
			text = "param",
		},
	},
	previousStatement = true,
	nextStatement = true,
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s(%s)',
	ToNPL = function(self)
		return string.format('%s("%s")\n', self:getFieldAsString('name'), self:getFieldAsString('param'));
	end,
	examples = {{desc = "", canRun = true, code = [[
local thinkText = function(text)
	say(text.."...")
end
thinkText("Let me think");
]]}},
},


{
	type = "expression_compare", 
	message0 = L"%1 %2 %3",
	arg0 = {
		{
			name = "left",
-- TODO: nested shadow blocks are not supported
--			type = "input_value",
--          shadow = { type = "getLocalVariable", value = "status",},
			type = "field_input",
			text = "status",
		},
		{
			name = "op",
			type = "field_dropdown",
			options = {
				{ "==", "==" },{ "!=", "!=" },
			},
		},
		{
			name = "right",
-- TODO: nested shadow blocks are not supported
--			type = "input_value",
--          shadow = { type = "text", value = "start",},
			type = "field_input",
			text = "\"start\"",
		},
	},
	hide_in_toolbox = true,
	output = {type = "field_number",},
	category = "Control", 
	helpUrl = "", 
	canRun = false,
	func_description = '((%s) %s (%s))',
	ToNPL = function(self)
		return string.format('(%s) %s (%s)', self:getFieldAsString('left'), self:getFieldAsString('op'), self:getFieldAsString('right'));
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
	category = "Control", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'for %s=%d, %d do\\n%send',
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
	previousStatement = true,
	nextStatement = true,
	func_description = 'if(%s) then\\n%send',
	ToNPL = function(self)
		return string.format('if(%s) then\n    %s\nend\n', self:getFieldAsString('expression'), self:getFieldAsString('input_true'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},
});