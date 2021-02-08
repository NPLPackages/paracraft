--[[
Title: CodeBlocklyDef_Data
Author(s): LiXizhi
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
	type = "getLocalVariable1", 
	message0 = L"%1",
	arg0 = {
		{
			name = "var",
			type = "field_variable",
			variable = L"变量名",
			variableTypes = {""},
			text = L"变量名",
		},
	},
	output = {type = "null",},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s',
	hide_in_codewindow = true,
	ToNPL = function(self)
		return self:getFieldAsString('var');
	end,
	examples = {{desc = "", canRun = true, code = [[
local key = "value"
say(key, 1)
]]}},
},

{
	type = "getLocalVariable", 
	message0 = L"%1",
	arg0 = {
		{
			name = "var",
			type = "field_input",
			text = L"变量名",
		},
	},
	output = {type = "null",},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s',
    colourSecondary = "#ffffff",
	ToNPL = function(self)
		return self:getFieldAsString('var');
	end,
	examples = {{desc = "", canRun = true, code = [[
local key = "value"
say(key, 1)
]]}},
},
{
	type = "assign1", 
	message0 = L"%1赋值为%2",
	arg0 = {
		{
			name = "left",
			type = "input_value",
			shadow = { type = "getLocalVariable1", value = L"变量名",},
			text = L"变量名",
		},
		{
			name = "right",
			type = "input_value",
			shadow = { type = "functionParams", value = "1",},
			text = "1",
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	hide_in_codewindow = true,
	previousStatement = true,
	nextStatement = true,
	func_description = '%s = %s',
	ToNPL = function(self)
		return string.format('%s = %s\n', self:getFieldAsString('left'), self:getFieldAsString('right'));
	end,
	examples = {{desc = "", canRun = true, code = [[
text = "hello"
say(text, 1)
]]}},
},

{
	type = "assign", 
	message0 = L"%1赋值为%2",
	arg0 = {
		{
			name = "left",
			type = "input_value",
			shadow = { type = "getLocalVariable", value = L"变量名",},
			text = L"变量名",
		},
		{
			name = "right",
			type = "input_value",
			shadow = { type = "functionParams", value = "1",},
			text = "1",
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = '%s = %s',
	ToNPL = function(self)
		return string.format('%s = %s\n', self:getFieldAsString('left'), self:getFieldAsString('right'));
	end,
	examples = {{desc = "", canRun = true, code = [[
text = "hello"
say(text, 1)
]]}},
},


{
	type = "set", 
	message0 = L"全局%1赋值为%2",
	arg0 = {
		{
			name = "key",
			type = "input_value",
			shadow = { type = "text", value = L"变量名",},
			text = L"变量名", 
		},
		{
			name = "value",
			type = "input_value",
            shadow = { type = "functionParams", value = "1",},
			text = "1", 
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "set",
	func_description = 'set(%s, %s)',
	ToNPL = function(self)
		return string.format('set("%s", %s)\n', self:getFieldAsString('key'), self:getFieldAsString('value'));
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
	type = "createLocalVariable", 
	message0 = L"新建本地%1为%2",
	arg0 = {
		{
			name = "var",
			type = "field_input",
			text = L"变量名",
		},
		{
			name = "value",
			type = "input_value",
			shadow = { type = "functionParams", value = "0",},
			text = "0",
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "local",
	func_description = 'local %s = %s',
	ToPython = function(self)
		return string.format('%s = %s\n', self:getFieldAsString('var'), self:getFieldAsString('value'));
	end,
	ToNPL = function(self)
		return string.format('local %s = %s\n', self:getFieldAsString('var'), self:getFieldAsString('value'));
	end,
	examples = {{desc = "", canRun = true, code = [[
local key = "value"
say(key, 1)
]]}},
},


{
	type = "registerCloneEvent", 
	message0 = L"当角色被克隆时(%1)",
	message1 = L"%1",
	arg0 = {
		{
			name = "param",
			type = "field_input",
			shadow = { type = "text", value = "name",},
			text = "name", 
		},
	},
	arg1 = {
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
	funcName = "registerCloneEvent",
	func_description = 'registerCloneEvent(function(%s)\\n%send)',
    ToPython = function(self)
		local input = self:getFieldAsString('input')
		if input == '' then
			input = 'pass'
		end
		return string.format('def registerCloneEvent_func(msg):\n    %s\nregisterCloneEvent("%s", registerCloneEvent_func)\n', input, self:getFieldAsString('param'));
	end,
	ToNPL = function(self)
		return string.format('registerCloneEvent(function(%s)\n    %s\nend)\n', self:getFieldAsString('param'), self:getFieldAsString('input'));
	end,
	examples = {{desc = "", canRun = true, code = [[
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
	type = "actorNames", 
	message0 = "%1",
	arg0 = {
		{
			name = "value",
			type = "field_dropdown",
			options = {
				{ L"此角色", "myself" },
				{ L"某个角色", "" },
			},
		},
	},
	hide_in_toolbox = true,
	category = "Data", 
	output = {type = "null",},
	helpUrl = "", 
	canRun = false,
	func_description = '%s',
	ToNPL = function(self)
		return self:getFieldAsString('value');
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "clone", 
	message0 = L"克隆%1(%2)",
	arg0 = {
		{
			name = "input",
			type = "input_value",
			shadow = { type = "text", value = "myself",},
			text = "\"myself\"",
		},
		{
			name = "params",
			type = "input_value",
			shadow = { type = "text", value = "",},
			text = "", 
		},
	},
	category = "Data", color="#cc0000",
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "clone",
	func_description = 'clone(%s, %s)',
	ToNPL = function(self)
		return string.format('clone(%s)\n', self:getFieldAsString('input'));
	end,
	examples = {{desc = "", canRun = true, code = [[
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
	message0 = L"删除此克隆角色", color="#cc0000",
	arg0 = {
	},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "delete",
	func_description = "delete()",
	ToNPL = function(self)
		return string.format('delete()\n');
	end,
	examples = {{desc = "", canRun = true, code = [[
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
	type = "actorProperties", 
	message0 = "%1",
	arg0 = {
		{
			name = "value",
			type = "field_dropdown",
			options = {
				{ L"名字", "name" },
				{ L"物理半径", "physicsRadius" },
				{ L"物理高度", "physicsHeight" },
				{ L"是否有物理", "isBlocker" },
				{ L"组Id", "groupId" },
				{ L"感知半径", "sentientRadius" },
				{ "x", "x" },
				{ "y", "y" },
				{ "z", "z" },
				{ L"时间", "time" },
				{ L"朝向", "facing" },
				{ L"行走速度", "walkSpeed" },
				{ L"俯仰角度", "pitch" },
				{ L"翻滾角度", "roll" },
				{ L"颜色", "color" },
				{ L"透明度", "opacity" },
				{ L"选中特效", "selectionEffect" },
				{ L"文字", "text" },
				{ L"是否为化身", "isAgent" },
				{ L"模型文件", "assetfile" },
				{ L"绘图代码", "rendercode" },
				{ L"Z排序", "zorder" },
				{ L"电影方块的位置", "movieblockpos" },
				{ L"电影角色", "movieactor" },
				{ L"电影播放速度", "playSpeed" },
				{ L"广告牌效果", "billboarded" },
				{ L"是否投影", "shadowCaster" },
				{ L"是否联机同步", "isServerEntity" },

				{ L"禁用物理仿真", "dummy" },
				{ L"重力加速度", "gravity" },
				{ L"速度", "velocity" },
				{ L"增加速度", "addVelocity" },
				{ L"摩擦系数", "surfaceDecay" },
				{ L"空气阻力", "airDecay" },
				
				{ L"父角色", "parent" },
				{ L"父角色位移", "parentOffset" },
				{ L"父角色旋转", "parentRot" },

				{ L"初始化参数", "initParams" },
				{ L"自定义数据", "userData" },
			},
		},
	},
	hide_in_toolbox = true,
	category = "Data", 
	output = {type = "null",},
	helpUrl = "", 
	canRun = false,
	func_description = '"%s"',
	ToNPL = function(self)
		return self:getFieldAsString('value');
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},


{
	type = "setActorValue", 
	message0 = L"设置角色的%1为%2",
	arg0 = {
		{
			name = "key",
			type = "input_value",
			shadow = { type = "actorProperties", value = "name",},
			text = "name", 
		},
		{
			name = "value",
			type = "input_value",
            shadow = { type = "text", value = "",},
			text = "", 
		},
	},
	category = "Data", 
	color = "#cc0000",
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "setActorValue",
	func_description = 'setActorValue(%s, %s)',
	ToNPL = function(self)
		return string.format('setActorValue("%s", "%s")\n', self:getFieldAsString('key'), self:getFieldAsString('value'));
	end,
	examples = {{desc = "", canRun = true, code = [[
registerCloneEvent(function(name)
    setActorValue("name", name)
    moveForward(1);
end)
registerClickEvent(function()
    local myname = getActorValue("name")
    say("my name is "..myname)
end)
setActorValue("name", "Default")
setActorValue("color", "#ff0000")
clone("myself", "Cloned")
say("click us!")
]]},
{desc = L"改变角色的电影方块", canRun = true, code = [[
local pos = getActorValue("movieblockpos")
pos[3] = pos[3] + 1
setActorValue("movieblockpos", pos)
]]},



{desc = L"改变电影角色", canRun = true, code = [[
setActorValue("movieactor", 1)
setActorValue("movieactor", "name1")
]]},

{desc = L"电影方块广告牌效果", canRun = true, code = [[
local yaw, roll, pitch = getActorValue("billboarded")
setActorValue("billboarded", {yaw = true, roll = true, pitch = pitch});
setActorValue("billboarded", {yaw = true});
]]},

{desc = L"选中特效", canRun = true, code = [[
-- -1 disable. 0 unlit, 1 yellow border
setActorValue("selectionEffect", -1)
]]},


{desc = L"多角色初始化参数", canRun = true, code = [[
registerCloneEvent(function(name)
    local params = getActorValue("initParams")
    echo(params)
    say(params.userData)
end)
]]},


},
},

{
	type = "getActorValue", 
	message0 = L"获取角色的%1",
	arg0 = {
		{
			name = "key",
			type = "input_value",
			shadow = { type = "actorProperties", value = "name",},
			text = "name", 
		},
	},
	category = "Data", 
	output = {type = "field_variable",},
	helpUrl = "", 
	canRun = false,
	funcName = "getActorValue",
	func_description = 'getActorValue(%s)',
	ToNPL = function(self)
		return string.format('getActorValue("%s")', self:getFieldAsString('key'));
	end,
	examples = {{desc = "", canRun = true, code = [[
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
	type = "getActor", 
	message0 = L"获取角色对象%1", 
	arg0 = {
		{
			name = "actorName",
			type = "input_value",
            shadow = { type = "text", value = "myself",},
			text = "myself", 
		},
	},
	output = {type = "field_variable",},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	funcName = "getActor",
	func_description = 'getActor(%s)',
	ToNPL = function(self)
		return string.format('getActor("%s")\n', self:getFieldAsString('actorName'));
	end,
	examples = {
	{desc = L"", canRun = true, code = [[
local actor = getActor("myself")
runForActor(actor, function()
	say("hello", 1)
end)
]]},
	{desc = L"", canRun = true, code = [[
local actor = getActor("name1")
local data = actor:GetActorValue("some_data")
]]},
},
},

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
	output = {type = "null",},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = '"%s"',
	ToNPL = function(self)
		return string.format('"%s"', self:getFieldAsString('left'));
	end,
	examples = {{desc = "", canRun = true, code = [[
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
				{ L"真", "true" },
				{ L"假", "false" },
				{ L"无效", "nil" },
			  }
		},
	},
	output = {type = "field_number",},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s',
	ToPython = function(self)
		local value = self:getFieldAsString("value")
		if value == 'true' then
			value = 'True'
		elseif value == 'false' then
			value = 'False'
		elseif value == 'nil' then
			value = 'None'
		end
		return value;
	end,
	ToNPL = function(self)
		return self:getFieldAsString("value");
	end,
	examples = {{desc = "", canRun = true, code = [[
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
	type = "newEmptyTable", 
	message0 = L"{%1%2%3}",
	arg0 = {
        {
			name = "start_dummy",
			type = "input_dummy",
		},
        {
			name = "end_dummy",
			type = "input_dummy",
		},
        {
            name = "btn",
            type = "field_button",
            content = {
                src = "png/plus-2x.png"
            },
            width = 16,
            height = 16,
            callback = "FIELD_BUTTON_CALLBACK_append_mcml_attr"
        },
	},
	output = {type = "field_number",},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description_lua_provider = [[
        var attrs = Blockly.Extensions.readTextFromMcmlAttrs(block, "Lua", ",");
        if (attrs) {
            return ["{%s}".format(attrs), Blockly.Lua.ORDER_ATOMIC];
        }else{
            return ["{}", Blockly.Lua.ORDER_ATOMIC];
        }
    ]],
	ToNPL = function(self)
		return "{}";
	end,
	examples = {{desc = "", canRun = true, code = [[
local t = {}
t[1] = "hello"
t["age"] = 10;
log(t)
]]}},
},
{
	type = "getTableValue", 
	message0 = L"%1中的%2",
	arg0 = {
		{
			name = "table",
			type = "input_value",
			shadow = { type = "functionParams", value = "_G",},
			text = "_G", 
		},
		{
			name = "key",
			type = "input_value",
			shadow = { type = "text", value = "key",},
			text = "key", 
		},
	},
	output = {type = "field_number",},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s[%s]',
	ToNPL = function(self)
		return string.format('%s["%s"]', self:getFieldAsString('table'), self:getFieldAsString('key'));
	end,
	examples = {{desc = "", canRun = true, code = [[
local t = {}
t[1] = "hello"
t["age"] = 10;
log(t)
]]}},
},

{
	type = "getArrayValue", 
	message0 = L"%1的第%2项",
	arg0 = {
		{
			name = "table",
			type = "input_value",
			shadow = { type = "functionParams", value = "_G",},
			text = "_G", 
		},
		{
			name = "key",
			type = "input_value",
			shadow = { type = "math_number", value = "1",},
			text = 1, 
		},
	},
	output = {type = "field_number",},
	category = "Data", 
	helpUrl = "", 
	hide_in_codewindow = true,
	canRun = false,
	func_description = '%s[%s]',
	ToNPL = function(self)
		return string.format('%s[%s]', self:getFieldAsString('table'), self:getFieldAsString('key'));
	end,
	examples = {{desc = "", canRun = true, code = [[
local t = {}
t[1] = "hello"
t["age"] = 10;
log(t)
]]}},
},

{
	type = "newFunction", 
	message0 = L"函数(%1)",
	message1 = L"%1",
	arg0 = {
		{
			name = "param",
			type = "field_input",
			text = "", 
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
    ToPython = function(self)
		local input = self:getFieldAsString('input')
		if input == '' then
			input = 'pass'
		end
		return string.format('def func(%s):\n    %s\n', self:getFieldAsString('param'), input);
	end,
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
	type = "defineFunction", 
	message0 = L"定义函数%1(%2)",
	message1 = L"%1",
	arg0 = {
		{
			name = "name",
			type = "field_input",
			text = "", 
		},
		{
			name = "param",
			type = "field_input",
			text = "", 
		},
	},
    arg1 = {
        {
			name = "input",
			type = "input_statement",
			text = "", 
		},
    },
	previousStatement = true,
	nextStatement = true,
	hide_in_codewindow = true,
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = 'function %s(%s)\\n%send',
    ToPython = function(self)
		local input = self:getFieldAsString('input')
		if input == '' then
			input = 'pass'
		end
		return string.format('def %s(%s):\n    %s\n', self:getFieldAsString('name'), self:getFieldAsString('param'), input);
	end,
	ToNPL = function(self)
		return string.format('function %s(%s)\n    %s\nend\n', self:getFieldAsString('name'), self:getFieldAsString('param'), self:getFieldAsString('input'));
	end,
	examples = {{desc = "", canRun = true, code = [[
function thinkText(text)
	say(text.."...")
end
thinkText("Let me think");
]]}},
},

{
	type = "functionParams", 
	message0 = "%1",
	arg0 = {
		{
			name = "value",
			type = "field_input",
			text = ""
		},
	},
	hide_in_toolbox = true,
	category = "Data", 
	output = {type = "null",},
	helpUrl = "", 
	canRun = false,
	func_description = '%s',
    colourSecondary = "#ffffff",
	ToNPL = function(self)
		return self:getFieldAsString('value');
	end,
	examples = {{desc = "", canRun = true, code = [[
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
			shadow = { type = "functionParams", value = "param",},
			text = "",
		},
	},
	previousStatement = true,
	nextStatement = true,
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s(%s)',
	ToNPL = function(self)
		return string.format('%s(%s)\n', self:getFieldAsString('name'), self:getFieldAsString('param'));
	end,
	examples = {{desc = "", canRun = true, code = [[
local thinkText = function(text)
	say(text.."...")
end
thinkText("Let me think");
]]}},
},

{
	type = "callFunctionWithReturn", 
	message0 = L"调用函数并返回%1(%2)",
	arg0 = {
		{
			name = "name",
			type = "field_input",
			text = "log",
		},
		{
			name = "param",
			type = "input_value",
			shadow = { type = "functionParams", value = "param",},
			text = "",
		},
	},
	output = {type = "null",},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s(%s)',
	ToNPL = function(self)
		return string.format('%s(%s)\n', self:getFieldAsString('name'), self:getFieldAsString('param'));
	end,
	examples = {{desc = "", canRun = true, code = [[
local getHello = function()
	return "hello world"
end
say(getHello())
]]}},
},


{
	type = "showVariable", 
	message0 = L"显示变量%1,%2,%3,%4",
	arg0 = {
		{
			name = "name",
			type = "field_input",
			text = "score", 
		},
		{
			name = "title",
			type = "field_input",
			text = "", 
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#0000ff",},
			text = "#0000ff",
		},
		{
			name = "fontSize",
			type = "input_value",
            shadow = { type = "math_number", value = "14",},
			text = "14",
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "showVariable",
	func_description = 'showVariable("%s", "%s", %s, %s)',
	ToNPL = function(self)
		return string.format('showVariable("%s", "%s", "%s", %s)\n', self:getFieldAsString('name'), self:getFieldAsString('title'), self:getFieldAsString('color'), self:getFieldAsString('fontSize'));
	end,
	examples = {{desc = "", canRun = true, code = [[
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
	funcName = "hideVariable",
	func_description = 'hideVariable("%s")',
	ToNPL = function(self)
		return string.format('hideVariable("%s")\n', self:getFieldAsString('name'));
	end,
	examples = {{desc = "", canRun = true, code = [[
_G.score = 1
showVariable("score")
wait(1);
hideVariable("score")
]]}},
},


{
	type = "log", 
	message0 = L"输出日志%1",
	arg0 = {
		{
			name = "obj",
			type = "input_value",
            shadow = { type = "text", value = "hello",},
			text = "hello", 
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "log",
	func_description = 'log(%s)',
	ToNPL = function(self)
		return string.format('log("%s")\n', self:getFieldAsString('obj'));
	end,
	examples = {{desc = L"查看log.txt或F11看日志", canRun = true, code = [[
log(123)
log("hello")
log({any="object"})
log("hello %s %d", "world", 1)
]]}},
},

{
	type = "echo", 
	message0 = L"输出到聊天框%1",
	arg0 = {
		{
			name = "obj",
			type = "input_value",
            shadow = { type = "text", value = "hello",},
			text = "hello", 
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "echo",
	func_description = 'echo(%s)',
	ToNPL = function(self)
		return string.format('echo("%s")\n', self:getFieldAsString('obj'));
	end,
	examples = {{desc = "", canRun = true, code = [[
echo(123)
echo("hello")
something = {any="object"}
echo(something)
]]}},
},

{
	type = "include", 
	message0 = L"引用文件%1", color="#cc0000",
	arg0 = {
		{
			name = "filename",
			type = "input_value",
            shadow = { type = "text", value = "hello.npl",},
			text = "hello.npl", 
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "include",
	func_description = 'include(%s)',
	ToNPL = function(self)
		return string.format('include("%s")\n', self:getFieldAsString('filename'));
	end,
	examples = {{desc = L"文件需要放到当前世界目录下", canRun = true, code = [[
-- _G.hello = function say("hello") end
include("hello.npl")
hello()
]]}},
},


{
	type = "gettable", 
	message0 = L"获取全局表%1", 
	arg0 = {
		{
			name = "tableName",
			type = "input_value",
            shadow = { type = "text", value = "scores",},
			text = "scores", 
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	output = {type = "field_variable",},
	funcName = "gettable",
	func_description = 'gettable(%s)',
	ToNPL = function(self)
		return string.format('gettable("%s")\n', self:getFieldAsString('tableName'));
	end,
	examples = {{desc = "", canRun = true, code = [[
some_data = gettable("some_data")
some_data.b = "b"
say(some_data.b)
]]}},
},

{
	type = "inherit", 
	message0 = L"继承表%1,新表%2",
	arg0 = {
		{
			name = "baseClass",
			type = "input_value",
            shadow = { type = "text", value = "baseTable",},
			text = "baseTable", 
		},
		{
			name = "newClass",
			type = "input_value",
            shadow = { type = "text", value = "newTable",},
			text = "newTable", 
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	output = {type = "field_variable",},
	funcName = "inherit",
	func_description = 'inherit(%s, %s)',
	ToNPL = function(self)
		return string.format('inherit("%s", "%s")\n', self:getFieldAsString('baseClass'), self:getFieldAsString('newClass'));
	end,
	examples = {{desc = "", canRun = true, code = [[
MyClassA = inherit(nil, "MyClassA");
function MyClassA:ctor()
end
function MyClassA:print(text)
    say("ClassA", 2)
end

MyClassB = inherit("MyClassA", "MyClassB");
function MyClassB:ctor()
end
function MyClassB:print()
    say("ClassB", 2)
end

-- class B inherits class A
MyClassB = gettable("MyClassB")
local b = MyClassB:new()
b:print()
b._super.print(b)
]]},
{desc = "", canRun = true, code = [[
MyClassA = inherit(nil, gettable("MyClassA"));
function MyClassA:ctor()
end
function MyClassA:print(text)
    say("ClassA", 2)
end
local a = MyClassA:new()
a:print()
]]}
},
},


{
	type = "saveUserData", 
	message0 = L"保存用户数据%1为%2",
	arg0 = {
		{
			name = "name",
			type = "input_value",
			shadow = { type = "text", value = "name",},
			text = "name", 
		},
		{
			name = "value",
			type = "input_value",
            shadow = { type = "functionParams", value = "",},
			text = "value", 
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "saveUserData",
	func_description = 'saveUserData(%s, %s)',
	ToNPL = function(self)
		return string.format('saveUserData("%s", "%s")\n', self:getFieldAsString('name'), self:getFieldAsString('value'));
	end,
	examples = {{desc = L"存储本地世界的用户数据", canRun = true, code = [[
saveUserData("score", 1)
saveUserData("user", {a=1})
local score = loadUserData("score", 0)
assert(score == 1)
]]}},
},

{
	type = "loadUserData", 
	message0 = L"加载用户数据%1默认值%2",
	arg0 = {
		{
			name = "name",
			type = "input_value",
			shadow = { type = "text", value = "name",},
			text = "name", 
		},
		{
			name = "defaultvalue",
			type = "input_value",
            shadow = { type = "functionParams", value = "",},
			text = "", 
		},
	},
	category = "Data", 
	output = {type = "field_variable",},
	helpUrl = "", 
	canRun = false,
	funcName = "loadUserData",
	func_description = 'loadUserData(%s, %s)',
	ToNPL = function(self)
		return string.format('loadUserData("%s", "%s")', self:getFieldAsString('name'), self:getFieldAsString('defaultvalue'));
	end,
	examples = {{desc = "", canRun = true, code = [[
saveUserData("score", 1)
local score = loadUserData("score", 0)
assert(score == 1)
]]}},
},



{
	type = "saveWorldData", 
	message0 = L"保存世界数据%1为%2",
	arg0 = {
		{
			name = "name",
			type = "input_value",
			shadow = { type = "text", value = "name",},
			text = "name", 
		},
		{
			name = "value",
			type = "input_value",
            shadow = { type = "functionParams", value = "",},
			text = "value", 
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "saveWorldData",
	func_description = 'saveWorldData(%s, %s)',
	ToNPL = function(self)
		return string.format('saveWorldData("%s", "%s")\n', self:getFieldAsString('name'), self:getFieldAsString('value'));
	end,
	examples = {{desc = L"常用于开发关卡编辑器", canRun = true, code = [[
-- only saved to disk when Ctrl+S, otherwise memory only
saveWorldData("maxLevel", 1)
local maxLevel = loadWorldData("maxLevel")
assert(maxLevel == 1)
]]},
{desc = L"从指定的文件加载", canRun = true, code = [[
saveWorldData("monsterCount", 1, "level1")
local monsterCount = loadWorldData("monsterCount", 0, "level1")
assert(monsterCount == 1)
]]},
},

},

{
	type = "loadWorldData", 
	message0 = L"加载世界数据%1默认值%2",
	arg0 = {
		{
			name = "name",
			type = "input_value",
			shadow = { type = "text", value = "name",},
			text = "name", 
		},
		{
			name = "defaultvalue",
			type = "input_value",
            shadow = { type = "functionParams", value = "",},
			text = "", 
		},
	},
	category = "Data", 
	output = {type = "field_variable",},
	helpUrl = "", 
	canRun = false,
	func_description = 'loadWorldData(%s, %s)',
	ToNPL = function(self)
		return string.format('loadWorldData("%s", "%s")', self:getFieldAsString('name'), self:getFieldAsString('defaultvalue'));
	end,
	examples = {{desc = L"常用于开发关卡编辑器", canRun = true, code = [[
-- only saved to disk when Ctrl+S, otherwise memory only
saveWorldData("maxLevel", 1)
local maxLevel = loadWorldData("maxLevel")
assert(maxLevel == 1)
]]},
{desc = L"从指定的文件加载", canRun = true, code = [[
saveWorldData("monsterCount", 1, "level1")
local monsterCount = loadWorldData("monsterCount", 0, "level1")
assert(monsterCount == 1)
]]},
},
},


{
	type = "code_block", 
	message0 = L"代码%1",
	message1 = L"%1",
    arg0 = {
		{
			name = "label_dummy",
			type = "input_dummy",
			text = "",
		},
	},
	arg1 = {
		{
			name = "codes",
			type = "field_input",
			text = "",
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = '%s',
	ToNPL = function(self)
		return string.format('%s\n', self:getFieldAsString('codes'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
]]}},
},
{
	type = "code_comment", 
	message0 = L"注释 %1",
	arg0 = {
		{
			name = "value",
			type = "field_input",
			text = "",
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = '-- %s',
	func_description_js = '// %s',
    ToPython = function(self)
		return string.format('# %s\n', self:getFieldAsString('value'));
	end,
	ToNPL = function(self)
		return string.format('-- %s', self:getFieldAsString('value'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
]]}},
},
{
	type = "code_comment_full", 
	message0 = L"注释全部 %1",
	message1 = "%1",
	message2 = "%1",
    arg0 = {
		{
			name = "label_dummy",
			type = "input_dummy",
			text = "",
		},
	},
	arg1 = {
		{
			name = "input",
			type = "input_statement",
			text = "", 
		},
	},
    arg2 = {
		{
			name = "label_dummy",
			type = "input_dummy",
			text = "",
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = '--[[\\n%s\\n]]',
	func_description_js = '/**\\n%s\\n*/',
    ToPython = function(self)
		return string.format('"""\n%s\n"""', self:getFieldAsString('input'));
	end,
	ToNPL = function(self)
		return string.format('--[[\n%s\n]]', self:getFieldAsString('input'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
]]}},
},

};
function CodeBlocklyDef_Data.GetCmds()
	return cmds;
end
