--[[
Title: CodeBlocklyDef_Control
Author(s): leio
Date: 2018/7/5
Desc: define blocks in category of Control
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyDef/CodeBlocklyDef_Control.lua");
local CodeBlocklyDef_Control= commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyDef.CodeBlocklyDef_Control");
-------------------------------------------------------
]]
local CodeBlocklyDef_Control = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyDef.CodeBlocklyDef_Control");
local cmds = {
-- Control
{
	type = "wait", 
	message0 = L"等待%1秒",
	arg0 = {
		{
			name = "time",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
	},
	category = "Control", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'wait(%s)',
	ToNPL = function(self)
		return string.format('wait(%s)\n', self:getFieldAsString('time'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
say("hi")
wait(1)
say("bye", 1)
]]},
{desc = L"等待下一个时钟周期", canRun = true, code = [[
while(true) do
    if(isKeyPressed("space")) then
        say("space is pressed", 1)
    end
    wait()
end
]]}
},
},

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
	examples = {{desc = L"", canRun = true, code = [[
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
	func_description = "repeat\\n%suntil(%s)",
	ToNPL = function(self)
		return string.format('repeat\n    %s\nuntil(%s)\n', self:getFieldAsString('input'), self:getFieldAsString('expression'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
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
	examples = {{desc = L"", canRun = true, code = [[
while(true) do
    moveForward(0.01)
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
	examples = {{desc = L"", canRun = true, code = [[

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
	examples = {{desc = L"", canRun = true, code = [[
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
			type = "field_input",
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
	examples = {{desc = L"", canRun = true, code = [[
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
			type = "field_input",
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
	examples = {{desc = L"", canRun = true, code = [[
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

{
	type = "run", 
	message0 = L"并行执行",
	message1 = L"%1",
	arg1 = {
		{
			name = "input",
			type = "input_statement",
			text = "",
		},
	},
	category = "Control", 
	color="#00cc00",
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'run(function()\\n%send)',
	ToNPL = function(self)
		return string.format('run(function()\n    %s\nend)\n', self:getFieldAsString('input'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
run(function()
    say("follow mouse pointer!")
    while(true) do
        if(distanceTo("mouse-pointer") < 7) then
            turnTo("mouse-pointer");
        elseif(distanceTo("@p") > 14) then
            moveTo("@p")
        end
    end
end)
run(function()
    while(true) do
        moveForward(0.02)
    end
end)
]]}},
},

{
	type = "exit", 
	message0 = L"结束程序",
	arg0 = {
	},
	category = "Control", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	func_description = 'exit()',
	ToNPL = function(self)
		return string.format('exit()\n');
	end,
	examples = {{desc = L"", canRun = true, code = [[
say("Press X key to exit")
registerKeyPressedEvent("x", function()
    exit()
end)
]]}},
},

{
	type = "restart", 
	message0 = L"重新开始",
	arg0 = {
	},
	category = "Control", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	func_description = 'restart()',
	ToNPL = function(self)
		return string.format('restart()\n');
	end,
	examples = {{desc = L"", canRun = true, code = [[
say("Press X key to restart")
registerKeyPressedEvent("x", function()
    restart()
end)
]]}},
},

{
	type = "becomeAgent", 
	message0 = L"成为%1的化身",
	arg0 = {
		{
			name = "name",
			type = "field_variable",
			text = "@p", 
			variable = "@p",
			variableTypes = {"actorNames"},
		},
	},
	category = "Control", 
	helpUrl = "", 
	color = "#cc0000",
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'becomeAgent("%s")',
	ToNPL = function(self)
		return string.format('becomeAgent("%s")\n', self:getFieldAsString('name'));
	end,
	examples = {{desc = L"成为当前角色的化身", canRun = true, code = [[
becomeAgent("@p")
]]}},
},

};
function CodeBlocklyDef_Control.GetCmds()
	return cmds;
end
