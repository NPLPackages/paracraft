--[[
Title: CodeBlocklyDef_Events
Author(s): leio
Date: 2018/7/5
Desc: define blocks in category of Events
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyDef/CodeBlocklyDef_Events.lua");
local CodeBlocklyDef_Events= commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyDef.CodeBlocklyDef_Events");
-------------------------------------------------------
]]
local CodeBlocklyDef_Events = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyDef.CodeBlocklyDef_Events");
local cmds = {
-- Events
{
	type = "registerClickEvent", 
	message0 = L"当演员被点击时%1",
	arg0 = {
		{
			name = "input",
			type = "input_statement",
			text = "",
		},
	},
	category = "Events", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'registerClickEvent(function()\\n%send)',
	ToNPL = function(self)
		return string.format('registerClickEvent(function()\n%send)\n', self:getFieldAsString('input'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
registerClickEvent(function()
    for i=1, 20 do
        scale(10)
    end
    for i=1, 20 do
        scale(-10)
    end
end)
]]}},
},

{
	type = "registerKeyPressedEvent", 
	message0 = L"当%1键按下时%2",
	arg0 = {
		{
			name = "keyname",
			type = "field_input",
			text = "space", 
		},
		{
			name = "input",
			type = "input_statement",
			text = "",
		},
	},
	category = "Events", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'registerKeyPressedEvent("%s", function()\\n%send)',
	ToNPL = function(self)
		return string.format('registerKeyPressedEvent("%s", function()\n%send)\n', self:getFieldAsString('keyname'), self:getFieldAsString('input'));
	end,
	examples = {{desc = L"空格跳跃", canRun = true, code = [[
registerKeyPressedEvent("space",function()
    say("Jump!", 1)
    move(0,1,0, 0.5)
    move(0,-1,0, 0.5)
    walkForward(0)
end)
]]}},
},

{
	type = "registerAnimationEvent", 
	message0 = L"当动画在%1帧时%2",
	arg0 = {
		{
			name = "time",
			type = "field_number",
			text = 1000, 
		},
		{
			name = "input",
			type = "input_statement",
			text = "",
		},
	},
	category = "Events", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'registerAnimationEvent(%d, function()\\n%send)',
	ToNPL = function(self)
		return string.format('registerAnimationEvent(%d, function()\n%send)\n', self:getFieldValue('time'), self:getFieldAsString('input'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
registerAnimationEvent(10, function()
    say("anim started", 3)
end)
registerAnimationEvent(1000, function()
    say("anim stopped", 1)
end)
registerClickEvent(function()
    play(10, 1000)
end);
say("click me!")
]]}},
},

{
	type = "registerBroadcastEvent", 
	message0 = L"当收到%1消息时%2",
	arg0 = {
		{
			name = "msg",
			type = "field_input",
			text = "message0", 
		},
		{
			name = "input",
			type = "input_statement",
			text = "",
		},
	},
	category = "Events", 
	color="#00cc00",
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'registerBroadcastEvent("%s", function()\\n%send)',
	ToNPL = function(self)
		return string.format('registerBroadcastEvent("%s", function()\n%send)\n', self:getFieldAsString('msg'), self:getFieldAsString('input'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
registerBroadcastEvent("jump", function()
    move(0,1,0)
    wait(1)
    move(0,-1,0)
end)
registerClickEvent(function()
    broadcastAndWait("jump")
    say("That was fun!", 2)
end)
say("click to jump!")
]]}},
},

{
	type = "broadcast", 
	message0 = L"广播%1消息",
	arg0 = {
		{
			name = "msg",
			type = "field_input",
			text = "message0", 
		},
	},
	category = "Events", 
	color="#00cc00",
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'broadcast("%s")',
	ToNPL = function(self)
		return string.format('broadcast("%s")\n', self:getFieldAsString('msg'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
registerBroadcastEvent("hello", function(msg)
    say("hello"..msg)
    move(0,1,0, 0.5)
    move(0,-1,0, 0.5)
    say("bye")
end)
for i=1, 2 do
    broadcast("hello", i)
    wait(0.5)
end
]]}},
},

{
	type = "broadcastAndWait", 
	message0 = L"广播%1消息并等待返回",
	arg0 = {
		{
			name = "msg",
			type = "field_input",
			text = "message0", 
		},
	},
	category = "Events", 
	color="#00cc00",
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'broadcastAndWait("%s")',
	ToNPL = function(self)
		return string.format('broadcastAndWait("%s")\n', self:getFieldAsString('msg'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
registerBroadcastEvent("hi", function()
    say("hi")
    wait(1)
    say("bye")
    wait(1)
end)
for i=1, 2 do
    broadcastAndWait("hi")
end
]]}},
},

{
	type = "cmd", 
	message0 = L"执行命令%1",
	arg0 = {
		{
			name = "msg",
			type = "field_input",
			text = "/tip hello", 
		},
	},
	category = "Events", 
	color="#cc0000",
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'cmd("%s")',
	ToNPL = function(self)
		return string.format('cmd("%s")\n', self:getFieldAsString('msg'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
cmd("/setblock ~0 ~0 ~1 62")
cmd("/cameradist 12")
cmd("/camerayaw 0")
cmd("/camerapitch 0.5")
]]}},
},

};
function CodeBlocklyDef_Events.GetCmds()
	return cmds;
end
