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
	examples = {{desc = "", canRun = true, code = [[
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
	type = "waitUntil", 
	message0 = L"等待直到%1",
	arg0 = {
		{
			name = "expression",
			type = "input_value",
            shadow = { type = "boolean"},
		},
	},
	category = "Control", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	hide_in_toolbox = false,
	func_description = "repeat wait(0.01) until(%s)",
	ToNPL = function(self)
		return string.format('repeat wait(0.01) until(%s)\n', self:getFieldAsString('expression'));
	end,
	examples = {{desc = L"每帧检测一次", canRun = true, code = [[
say("press space key to continue")
repeat wait(0.01) until(isKeyPressed("space"))
say("started")
]]},
{desc = L"输入为某个变量或表达式", canRun = false, code = [[
repeat wait(0.01) until(gamestate == "gameStarted")
repeat wait(0.01) until(current_level == 1)
]]},
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
	type = "wait_until", 
	message0 = L"等待直到%1为真",
	arg0 = {
		{
			name = "expression",
			type = "input_value",
			shadow = { type = "expression_compare", },
			text = "status == \"start\""
		},
    },
	category = "Control", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'repeat wait() until(%s)',
	ToNPL = function(self)
		return string.format('repeat wait() until(%s)\n', self:getFieldAsString('expression'));
	end,
	examples = {{desc = "", canRun = true, code = [[
status = "gameStarted"
repeat wait() until(status == "gameStarted")
say("game started")
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
	examples = {{desc = "", canRun = true, code = [[
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
	type = "runForActor", 
	message0 = L"执行角色%1代码",
	message1 = L"%1",
	arg0 = {
		{
			name = "actor",
			type = "input_value",
            shadow = { type = "text", value = "myself",},
			text = "myself", 
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
	color="#00cc00",
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'runForActor(%s, function()\\n%send)',
	ToNPL = function(self)
		return string.format('runForActor("%s", function()\n    %s\nend)\n', self:getFieldAsString('actor'), self:getFieldAsString('input'));
	end,
	examples = {
	{desc = "", canRun = true, code = [[
runForActor("myself", function()
	say("hello", 1)
end)
say("world", 1)
]]},
{desc = "", canRun = true, code = [[
local actor = getActor("myself")
local x, y, z = runForActor(actor, function()
    return getPos();
end)
say(x..y..z, 1)
]]},
},
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
	examples = {{desc = "", canRun = true, code = [[
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
	examples = {{desc = "", canRun = true, code = [[
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
			type = "input_value",
			options = {
				{ L"当前玩家", "@p" },
				{ L"某个角色名", "" },
			},
			shadow = { type = "text", value = "@p",},
			text = "@p",
		},
	},
	category = "Control", 
	helpUrl = "", 
	color = "#cc0000",
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'becomeAgent(%s)',
	ToNPL = function(self)
		return string.format('becomeAgent("%s")\n', self:getFieldAsString('name'));
	end,
	examples = {{desc = L"成为当前角色的化身", canRun = true, code = [[
becomeAgent("@p")
]]}},
},

{
	type = "setOutput", 
	message0 = L"设置方块输出%1",
	arg0 = {
		{
			name = "result",
			type = "input_value",
            shadow = { type = "math_number", value = 15,},
			text = 15, 
		},
	},
	category = "Control", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'setOutput(%s)',
	ToNPL = function(self)
		return string.format('setOutput(%s)\n', self:getFieldAsString('result'));
	end,
	examples = {{desc = "", canRun = true, code = [[
setOutput(15)
wait(2)
setOutput(0)
]]}},
},

};
function CodeBlocklyDef_Control.GetCmds()
	return cmds;
end
