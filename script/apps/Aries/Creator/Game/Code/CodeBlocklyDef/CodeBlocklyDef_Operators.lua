--[[
Title: CodeBlocklyDef_Operators
Author(s): leio
Date: 2018/7/5
Desc: define blocks in category of Operators
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyDef/CodeBlocklyDef_Operators.lua");
local CodeBlocklyDef_Operators= commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyDef.CodeBlocklyDef_Operators");
-------------------------------------------------------
]]
local CodeBlocklyDef_Operators = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyDef.CodeBlocklyDef_Operators");
local cmds = {
-- Operators
{
	type = "getString", 
	message0 = "\"%1\"",
	arg0 = {
		{
			name = "left",
			type = "field_input",
			text = "string",
		},
	},
	output = {type = "field_number",},
	category = "Operators", 
	helpUrl = "", 
	canRun = false,
	func_description = '"%s"',
	ToNPL = function(self)
		return string.format('"%s"', self:getFieldAsString('left'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
]]}},
},
{
	type = "getBoolean", 
	message0 = L"%1",
	arg0 = {
		{
			name = "value",
			type = "field_dropdown",
			options = {
				{ "true", "true" },
				{ "false", "false" }
			  }
		},
	},
	output = {type = "field_number",},
	category = "Operators", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s',
	ToNPL = function(self)
		return self:getFieldAsString("value");
	end,
	examples = {{desc = L"", canRun = true, code = [[
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
	category = "Operators", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s',
	ToNPL = function(self)
		return string.format('%s', self:getFieldAsString('left'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
]]}},
},

{
	type = "addition", 
	message0 = L"%1 + %2 %3",
	arg0 = {
		{
			name = "left",
			type = "input_value",
		},
		{
			name = "dummy",
			type = "input_dummy",
		},
		{
			name = "right",
			type = "input_value",
		},
	},
	output = {type = "field_number",},
	category = "Operators", 
	helpUrl = "", 
	canRun = false,
	func_description = '((%s) + (%s))',
	ToNPL = function(self)
		return string.format('(%s) + (%s)', self:getFieldAsString('left'), self:getFieldAsString('right'));
	end,
	examples = {{desc = L"数字的加减乘除", canRun = true, code = [[
say("1+1=?")
wait(1)
say(1+1)
]]}},
},

{
	type = "random", 
	message0 = L"随机选择从%1到%2",
	arg0 = {
		{
			name = "from",
			type = "field_number",
			text = "1",
		},
		{
			name = "to",
			type = "field_number",
			text = "10",
		},
	},
	output = {type = "field_number",},
	category = "Operators", 
	helpUrl = "", 
	canRun = false,
	func_description = 'math.random(%s,%s)',
	ToNPL = function(self)
		return string.format('math.random(%s,%s)', self:getFieldAsString('from'), self:getFieldAsString('to'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
while(true) do
    say(math.random(1,100))
    wait(0.5)
end
]]}},
},

{
	type = "equal", 
	message0 = L"%1 == %2 %3",
	arg0 = {
		{
			name = "left",
			type = "input_value",
		},
		{
			name = "dummy",
			type = "input_dummy",
		},
		{
			name = "right",
			type = "input_value",
		},
	},
	output = {type = "field_number",},
	category = "Operators", 
	helpUrl = "", 
	canRun = false,
	func_description = '((%s) == (%s))',
	ToNPL = function(self)
		return string.format('(%s) == (%s)', self:getFieldAsString('left'), self:getFieldAsString('right'));
	end,
	examples = {{desc = L"比较两个数值", canRun = true, code = [[
while(true) do
    a = math.random(0,10)
    if(a==0) then
        say(a)
    elseif(a<=3) then
        say(a.."<=3")
    elseif(a>6) then
        say(a..">6")
    else
        say("3<"..a.."<=6")
    end
    wait(2)
end
]]}},
},

{
	type = "and", 
	message0 = L"%1 与 %2 %3",
	arg0 = {
		{
			name = "left",
			type = "input_value",
		},
		{
			name = "dummy",
			type = "input_dummy",
		},
		{
			name = "right",
			type = "input_value",
		},
	},
	output = {type = "field_number",},
	category = "Operators", 
	helpUrl = "", 
	canRun = false,
	func_description = '((%s) and (%s))',
	ToNPL = function(self)
		return string.format('(%s) and (%s)', self:getFieldAsString('left'), self:getFieldAsString('right'));
	end,
	examples = {{desc = L"同时满足条件", canRun = true, code = [[
while(true) do
    a = math.random(0,10)
    if(3<a and a<=6) then
        say("3<"..a.."<=6")
    else
        say(a)
    end
    wait(2)
end
]]}},
},

{
	type = "or", 
	message0 = L"%1 或 %2 %3",
	arg0 = {
		{
			name = "left",
			type = "input_value",
		},
		{
			name = "dummy",
			type = "input_dummy",
		},
		{
			name = "right",
			type = "input_value",
		},
	},
	output = {type = "field_number",},
	category = "Operators", 
	helpUrl = "", 
	canRun = false,
	func_description = '((%s) or (%s))',
	ToNPL = function(self)
		return string.format('(%s) or (%s)', self:getFieldAsString('left'), self:getFieldAsString('right'));
	end,
	examples = {{desc = L"左边或右边满足条件", canRun = true, code = [[
while(true) do
    a = math.random(0,10)
    if(a<=3 or a>6) then
        say(a)
    else
        say("3<"..a.."<=6")
    end
    wait(2)
end
]]}},
},

{
	type = "not", 
	message0 = L"不满足%1 %2",
	arg0 = {
		{
			name = "left",
			type = "input_value",
		},
		{
			name = "dummy",
			type = "input_dummy",
		},
	},
	output = {type = "field_number",},
	category = "Operators", 
	helpUrl = "", 
	canRun = false,
	func_description = '(not %s)',
	ToNPL = function(self)
		return string.format('(not %s)', self:getFieldAsString('left'));
	end,
	examples = {{desc = L"是否不为真", canRun = true, code = [[
while(true) do
    a = math.random(0,10)
    if((not (3<=a)) or (not (a>6))) then
        say("3<"..a.."<=6")
    else
        say(a)
    end
    wait(2)
end
]]}},
},

{
	type = "join", 
	message0 = L"连接字符串%1和%2",
	arg0 = {
		{
			name = "left",
			type = "field_input",
			text = "hello",
		},
		{
			name = "right",
			type = "field_input",
			text = "world",
		},
	},
	output = {type = "field_number",},
	category = "Operators", 
	helpUrl = "", 
	canRun = false,
	func_description = '("%s".."%s")',
	ToNPL = function(self)
		return string.format('("%s".."%s")', self:getFieldAsString('left'), self:getFieldAsString('right'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
say("hello ".."world".."!!!")
]]}},
},

{
	type = "lengthOf", 
	message0 = L"字符串%1的长度",
	arg0 = {
		{
			name = "left",
			type = "field_input",
			text = "hello",
		},
	},
	output = {type = "field_number",},
	category = "Operators", 
	helpUrl = "", 
	canRun = false,
	func_description = '(#"%s")',
	ToNPL = function(self)
		return string.format('(#"%s")', self:getFieldAsString('left'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
say("length of hello is "..(#"hello"));
]]}},
},

{
	type = "mod", 
	message0 = L"%1模%2",
	arg0 = {
		{
			name = "left",
			type = "field_number",
			text = "66",
		},
		{
			name = "right",
			type = "field_number",
			text = "10",
		},
	},
	output = {type = "field_number",},
	category = "Operators", 
	helpUrl = "", 
	canRun = false,
	func_description = '(%s%%s)',
	ToNPL = function(self)
		return string.format('(%s%%%s)', self:getFieldAsString('left'), self:getFieldAsString('right'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
say("66%10=="..(66%10))
]]}},
},

{
	type = "round", 
	message0 = L"四舍五入取整%1",
	arg0 = {
		{
			name = "left",
			type = "field_number",
			text = 5.5,
		},
	},
	output = {type = "field_number",},
	category = "Operators", 
	helpUrl = "", 
	canRun = false,
	func_description = 'math.floor(%s+0.5)',
	ToNPL = function(self)
		return string.format('math.floor(%s+0.5)', self:getFieldAsString('left'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
while(true) do
    a = math.random(0,10) / 10
    b = math.floor(a+0.5)
    say(a.."=>"..b)
    wait(2)
end
]]}},
},

{
	type = "math.sqrt", 
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
			type = "field_number",
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
	examples = {{desc = L"", canRun = true, code = [[
say("math.sqrt(9)=="..math.sqrt(9), 1)
say("math.cos(1)=="..math.cos(1), 1)
say("math.abs(-1)=="..math.abs(1), 1)
]]}},
},
};
function CodeBlocklyDef_Operators.GetCmds()
	return cmds;
end
