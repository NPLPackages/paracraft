--[[
Title: NplMicroRobotDef_Operators
Author(s): leio
Date: 2019/11/29
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicroRobot/NplMicroRobotDef/NplMicroRobotDef_Operators.lua");
-------------------------------------------------------
]]
NPL.export({

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
				{ "+", "+" },{ "-", "-" },{ "*", "*" },{ "/", "/" },{ "^", "^" },
			},
		},
		{
			name = "right",
			type = "input_value",
            shadow = { type = "math_number", },
		},
	},
	output = {type = "field_number",},
	category = "NplMicroRobot.Operators", 
	helpUrl = "", 
	canRun = false,
	func_description = '((%s) %s (%s))',
	ToNPL = function(self)
		return string.format('(%s) %s (%s)', self:getFieldAsString('left'), self:getFieldAsString('op'), self:getFieldAsString('right'));
	end,
	examples = {{desc = L"数字的加减乘除", canRun = true, code = [[
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
				{ ">", ">" },{ "<", "<" },{ ">=", ">=" },{ "<=", "<=" },{ "==", "==" },{ "~=", "~=" },
			},
		},
		{
			name = "right",
			type = "input_value",
            shadow = { type = "math_number", },
		},
	},
	output = {type = "field_number",},
	category = "NplMicroRobot.Operators", 
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
            --shadow = { type = "text", value = "",},
			shadow = { type = "functionParams", value = "1",},
		},
		{
			name = "op",
			type = "field_dropdown",
			options = {
				{ "==", "==" },{ "~=", "~=" },
			},
		},
		{
			name = "right",
			type = "input_value",
            -- shadow = { type = "text", value = "",},
			shadow = { type = "functionParams", value = "1",},
		},
	},
	output = {type = "field_number",},
	category = "NplMicroRobot.Operators", 
	helpUrl = "", 
	canRun = false,
	func_description = '((%s) %s (%s))',
	ToPython = function(self)
		local op = self:getFieldAsString('op')
		if op == '~=' then
			op = '!='
		end
		return string.format('(%s) %s (%s)', self:getFieldAsString('left'), op, self:getFieldAsString('right'));
	end,
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
	type = "random", 
	message0 = L"随机选择从%1到%2",
	arg0 = {
		{
			name = "from",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = "1",
		},
		{
			name = "to",
			type = "input_value",
            shadow = { type = "math_number", value = 10,},
			text = "10",
		},
	},
	output = {type = "field_number",},
	category = "NplMicroRobot.Operators", 
	helpUrl = "", 
	canRun = false,
	funcName = "random",
	func_description = 'math.random(%s,%s)',
	ToNPL = function(self)
		return string.format('math.random(%s,%s)', self:getFieldAsString('from'), self:getFieldAsString('to'));
	end,
	examples = {{desc = "", canRun = true, code = [[
while(true) do
    say(math.random(1,100))
    wait(0.5)
end
]]}},
},



{
	type = "math_compared", 
	message0 = L"%1 %2 %3",
	arg0 = {
		{
			name = "left",
			type = "input_value",
		},
		{
			name = "op",
			type = "field_dropdown",
			options = {
				{ L"并且", "and" },{ L"或", "or" },
			},
		},
		{
			name = "right",
			type = "input_value",
		},
	},
	output = {type = "field_number",},
	category = "NplMicroRobot.Operators", 
	helpUrl = "", 
	canRun = false,
	func_description = '((%s) %s (%s))',
	ToNPL = function(self)
		return string.format('(%s) %s (%s)', self:getFieldAsString('left'), self:getFieldAsString('op'),self:getFieldAsString('right'));
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
	type = "not", 
	message0 = L"不满足%1",
	arg0 = {
		{
			name = "left",
			type = "input_value",
		},
	},
	output = {type = "field_number",},
	category = "NplMicroRobot.Operators", 
	helpUrl = "", 
	canRun = false,
	funcName = "not",
	func_description = '(not %s)',
	func_description_js = '(!%s)',
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
	message0 = L"连接%1和%2",
	arg0 = {
		{
			name = "left",
			type = "input_value",
            shadow = { type = "text", value = "hello",},
			text = "hello",
		},
		{
			name = "right",
			type = "input_value",
            shadow = { type = "text", value = "world",},
			text = "world",
		},
	},
	output = {type = "field_number",},
	category = "NplMicroRobot.Operators", 
	helpUrl = "", 
	canRun = false,
	func_description = '(%s..%s)',
	func_description_js = '(%s+%s)',
	ToPython = function(self)
		return string.format('("%s" + "%s")', self:getFieldAsString('left'), self:getFieldAsString('right'));
	end,
	ToNPL = function(self)
		return string.format('("%s".."%s")', self:getFieldAsString('left'), self:getFieldAsString('right'));
	end,
	examples = {{desc = "", canRun = true, code = [[
say("hello ".."world".."!!!")
]]}},
},

{
	type = "lengthOf", 
	message0 = L"字符串%1的长度",
	arg0 = {
		{
			name = "left",
			type = "input_value",
            shadow = { type = "text", value = "hello",},
			text = "hello",
		},
	},
	output = {type = "field_number",},
	category = "NplMicroRobot.Operators", 
	helpUrl = "", 
	canRun = false,
	func_description = '(#%s)',
	ToPython = function(self)
		return string.format('len("%s")', self:getFieldAsString('left'));
	end,
	ToNPL = function(self)
		return string.format('(#"%s")', self:getFieldAsString('left'));
	end,
	examples = {{desc = "", canRun = true, code = [[
say("length of hello is "..(#"hello"));
]]}},
},

{
	type = "mod", 
	message0 = L"%1除以%2的余数",
	arg0 = {
		{
			name = "left",
			type = "input_value",
            shadow = { type = "math_number", value = 66,},
			text = "66",
		},
		{
			name = "right",
			type = "input_value",
            shadow = { type = "math_number", value = 10,},
			text = "10",
		},
	},
	output = {type = "field_number",},
	category = "NplMicroRobot.Operators", 
	helpUrl = "", 
	canRun = false,
	func_description = '(%s%%s)',
	ToNPL = function(self)
		return string.format('(%s%%%s)', self:getFieldAsString('left'), self:getFieldAsString('right'));
	end,
	examples = {{desc = "", canRun = true, code = [[
say("66%10=="..(66%10))
]]}},
},

{
	type = "round", 
	message0 = L"四舍五入取整%1",
	arg0 = {
		{
			name = "left",
			type = "input_value",
            shadow = { type = "math_number", value = 5.5,},
			text = 5.5,
		},
	},
	output = {type = "field_number",},
	category = "NplMicroRobot.Operators", 
	helpUrl = "", 
	canRun = false,
	funcName = "floor",
	func_description = 'math.floor(%s+0.5)',
	func_description_js = 'Math.floor(%s+0.5)',
	ToPython = function(self)
		return string.format('round(%s)', self:getFieldAsString('left'));
	end,
	ToNPL = function(self)
		return string.format('math.floor(%s+0.5)', self:getFieldAsString('left'));
	end,
	examples = {{desc = "", canRun = true, code = [[
while(true) do
    a = math.random(0,10) / 10
    b = math.floor(a+0.5)
    say(a.."=>"..b)
    wait(2)
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
				{ L"转成数字", "tonumber"},
				{ L"转成字符串", "tostring"},
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
	category = "NplMicroRobot.Operators", 
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

})