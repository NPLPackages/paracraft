--[[
Title: CodeBlocklyDef_Data
Author(s): leio
Date: 2018/7/5
Desc: define blocks in category of Data
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyDef/CodeBlocklyDef_Data.lua");
local CodeBlocklyDef_Data= commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyDef.CodeBlocklyDef_Data");
-------------------------------------------------------
]]
local CodeBlocklyDef_Data = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyDef.CodeBlocklyDef_Data");
local cmds = {
-- Data
{
	type = "setLocalVariable", 
	message0 = L"设置局部变量%1为%2",
	arg0 = {
		{
			name = "var",
			type = "field_variable",
			variable = "item",
			variableTypes = {""},
			text = "key",
		},
		{
			name = "value",
			type = "input_value",
			text = "value",
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'local %s = %s',
	ToNPL = function(self)
		return 'local key = "value"\n';
	end,
	examples = {{desc = L"", canRun = true, code = [[
local key = "value"
say(key, 1)
]]}},
},
{
	type = "getLocalVariable", 
	message0 = L"获取局部变量%1",
	arg0 = {
		{
			name = "var",
			type = "field_variable",
			variable = "item",
			variableTypes = {""},
			text = "key",
		},
	},
	output = {type = "null",},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s',
	ToNPL = function(self)
		return "key";
	end,
	examples = {{desc = L"", canRun = true, code = [[
local key = "value"
say(key, 1)
]]}},
},

{
	type = "set", 
	message0 = L"设置全局变量%1为%2",
	arg0 = {
		{
			name = "key",
			type = "field_input",
			text = "score", 
		},
		{
			name = "value",
			type = "field_input",
			text = "1", 
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	func_description = 'set("%s", "%s")',
	ToNPL = function(self)
		return string.format('set("%s", "%s")\n', self:getFieldAsString('key'), self:getFieldAsString('value'));
	end,
	examples = {{desc = L"也可以用_G.a", canRun = true, code = [[
_G.a = _G.a or 1
while(true) do
    _G.a = a + 1
    set("a", get("a") + 1)
    say(a)
end
]]}},
},

{
	type = "showVariable", 
	message0 = L"显示全局变量%1",
	arg0 = {
		{
			name = "name",
			type = "field_input",
			text = "score", 
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	func_description = 'showVariable("%s")',
	ToNPL = function(self)
		return string.format('showVariable("%s")\n', self:getFieldAsString('name'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
_G.score = 1
_G.msg = "hello"
showVariable("score", "Your Score")
showVariable("msg", "", "#ff0000")
while(true) do
   _G.score = _G.score + 1
   wait(0.01)
end
]]}},
},

{
	type = "hideVariable", 
	message0 = L"隐藏全局变量%1",
	arg0 = {
		{
			name = "name",
			type = "field_input",
			text = "score", 
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	func_description = 'hideVariable("%s")',
	ToNPL = function(self)
		return string.format('hideVariable("%s")\n', self:getFieldAsString('name'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
_G.score = 1
showVariable("score")
wait(1);
hideVariable("score")
]]}},
},
{
	type = "registerCloneEvent", 
	message0 = L"当角色被复制时%1",
	arg0 = {
		{
			name = "input",
			type = "input_statement",
			text = "",
		},
	},
	category = "Data", color="#cc0000",
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'registerCloneEvent(function()\\n%send)',
	ToNPL = function(self)
		return string.format('registerCloneEvent(function()\n%send)\n', self:getFieldAsString('input'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
registerCloneEvent(function(msg)
    move(msg or 1, 0, 0, 0.5)
    wait(1)
    delete()
end)
clone()
clone("myself", 2)
clone("myself", 3)
]]}},
},

{
	type = "clone", 
	message0 = L"复制%1",
	arg0 = {
		{
			name = "input",
			type = "field_dropdown",
			options = {
				{ L"此角色", "myself" },
				{ L"某个角色", "" },
			},
		},
	},
	category = "Data", color="#cc0000",
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'clone("%s")',
	ToNPL = function(self)
		return string.format('clone("%s")\n', self:getFieldAsString('input'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
registerClickEvent(function()
    move(1,0,0, 0.5)
end)
clone()
clone()
say("click")
]]}},
},

{
	type = "delete", 
	message0 = L"删除角色", color="#cc0000",
	arg0 = {
	},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = "delete()",
	ToNPL = function(self)
		return string.format('delete()\n');
	end,
	examples = {{desc = L"", canRun = true, code = [[
move(1,0)
say("Default actor will be deleted!", 1)
delete()
registerCloneEvent(function()
    say("This clone will be deleted!", 1)
    delete()
end)
for i=1, 100 do
    clone()
    wait(2)
end
]]}},
},

{
	type = "setActorValue", 
	message0 = L"设置角色的%1为%2",
	arg0 = {
		{
			name = "key",
			type = "field_dropdown",
			options = {
				{ L"名字", "name" },
				{ L"物理半径", "physicsRadius" },
				{ L"物理高度", "physicsHeight" },
				{ L"任意变量", "" },
			},
		},
		{
			name = "value",
			type = "field_input",
			text = "actor1", 
		},
	},
	category = "Data", 
	color = "#cc0000",
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'setActorValue("%s", "%s")',
	ToNPL = function(self)
		return string.format('setActorValue("%s", "%s")\n', self:getFieldAsString('key'), self:getFieldAsString('value'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
registerCloneEvent(function(name)
    setActorValue("name", name)
    moveForward(1);
end)
registerClickEvent(function()
    local myname = getActorValue("name")
    say("my name is "..myname)
end)
setActorValue("name", "Default")
clone("myself", "Cloned")
say("click us!")
]]}},
},

{
	type = "getActorValue", 
	message0 = L"获取角色的%1",
	arg0 = {
		{
			name = "key",
			type = "field_dropdown",
			options = {
				{ L"名字", "name" },
				{ L"物理半径", "physicsRadius" },
				{ L"物理高度", "physicsHeight" },
				{ L"任意变量", "" },
			},
		},
	},
	category = "Data", 
	output = {type = "field_number",},
	helpUrl = "", 
	canRun = false,
	func_description = 'getActorValue("%s")',
	ToNPL = function(self)
		return string.format('getActorValue("%s")', self:getFieldAsString('key'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
registerCloneEvent(function(msg)
    setActorValue("name", msg.name)
    moveForward(msg.dist);
end)
registerClickEvent(function()
    local myname = getActorValue("name")
    say("my name is "..myname)
end)
setActorValue("name", "Default")
clone("myself", {name = "clone1", dist=1})
clone(nil, {name = "clone2", dist=2})
say("click us!")
]]}},
},


{
	type = "log", 
	message0 = L"输出日志%1",
	arg0 = {
		{
			name = "obj",
			type = "field_input",
			text = "hello", 
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	func_description = 'log("%s")',
	ToNPL = function(self)
		return string.format('log("%s")\n', self:getFieldAsString('obj'));
	end,
	examples = {{desc = L"查看log.txt或F11看日志", canRun = true, code = [[
log(123)
log("hello")
something = {any="object"}
log(something)
]]}},
},

{
	type = "echo", 
	message0 = L"输出到聊天框%1",
	arg0 = {
		{
			name = "obj",
			type = "field_input",
			text = "hello", 
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	func_description = 'echo("%s")',
	ToNPL = function(self)
		return string.format('echo("%s")\n', self:getFieldAsString('obj'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
echo(123)
echo("hello")
something = {any="object"}
echo(something)
]]}},
},

};
function CodeBlocklyDef_Data.GetCmds()
	return cmds;
end
