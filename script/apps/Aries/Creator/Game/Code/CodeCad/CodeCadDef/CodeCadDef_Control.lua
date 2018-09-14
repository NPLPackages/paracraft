--[[
Title: CodeCadDef_Control
Author(s): leio
Date: 2018/9/10
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeCad/CodeCadDef/CodeCadDef_Control.lua");
local CodeCadDef_Control = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCad.CodeCadDef_Control");
-------------------------------------------------------
]]
local CodeCadDef_Control = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCad.CodeCadDef_Control");
local cmds = {

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
	category = "Control", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'for i=1, %d do\\n%send',
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
	type = "repeat_until", 
	message0 = L"重复执行",
	message1 = L"%1",
	message2 = L"一直到%1",
	arg1 = {
		{
			name = "input",
			type = "input_statement",
		},
	},
    arg2 = {
		{
			name = "expression",
			type = "input_value",
		},
	},
	category = "Control", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	hide_in_toolbox = true,
	func_description = "repeat\\n%suntil(%s)",
	ToNPL = function(self)
		return string.format('repeat\n    %s\nuntil(%s)\n', self:getFieldAsString('input'), self:getFieldAsString('expression'));
	end,
	examples = {{desc = "", canRun = true, code = [[
repeat
    moveForward(0.01)
until(false)
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
	category = "Control", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'while(true) do\\n%send',
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
	type = "repeat_count_step", 
	message0 = L"循环:变量%1从%2到%3递增%4",
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
	category = "Control", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'for %s=%d, %d, %d do\\n%send',
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


{
	type = "forKeyValue", 
	message0 = L"每个%1,%2在%3",
	message1 = L"%1",
	arg0 = {
		{
			name = "key",
			type = "field_input",
			text = "key", 
		},
		{
			name = "value",
			type = "field_input",
			text = "value", 
		},
		{
			name = "data",
			type = "input_value",
			text = "data", 
		},
		
	},
    arg1 = {
		{
			name = "input",
			type = "input_statement",
			text = "", 
		},
    },
	category = "Control", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'for %s, %s in pairs(%s) do\\n%send',
	ToNPL = function(self)
		return string.format('for %s, %s in pairs(%s) do\n    %s\nend\n', self:getFieldAsString('key'), self:getFieldAsString('value'), self:getFieldAsString('data'), self:getFieldAsString('input'));
	end,
	examples = {{desc = "", canRun = true, code = [[
myData = {
    key1="value1", 
    key2="value2",
    key2="value2",
}
for k, v in pairs(myData) do
    say(v, 1);
end
]]}},
},

{
	type = "forIndexValue", 
	message0 = L"每个%1,%2在数组%3",
	message1 = L"%1",
	arg0 = {
		{
			name = "i",
			type = "field_input",
			text = "index", 
		},
		{
			name = "item",
			type = "field_input",
			text = "item", 
		},
		{
			name = "data",
			type = "input_value",
			text = "data", 
		},
		
	},
    arg1 = {
        {
			name = "input",
			type = "input_statement",
			text = "", 
		},
    },
	category = "Control", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'for %s, %s in ipairs(%s) do\\n%send',
	ToNPL = function(self)
		return string.format('for %s, %s in ipairs(%s) do\n    %s\nend\n', self:getFieldAsString('i'), self:getFieldAsString('item'), self:getFieldAsString('data'), self:getFieldAsString('input'));
	end,
	examples = {{desc = "", canRun = true, code = [[
myData = {
    {x=1, y=0, z=0, duration=0.5},
    {x=0, y=0, z=1, duration=0.5},
    {x=-1, y=0, z=-1, duration=1},
}
for i, item in ipairs(myData) do
    move(item.x, item.y, item.z, item.duration)
end
]]}},
},


};
function CodeCadDef_Control.GetCmds()
	return cmds;
end
