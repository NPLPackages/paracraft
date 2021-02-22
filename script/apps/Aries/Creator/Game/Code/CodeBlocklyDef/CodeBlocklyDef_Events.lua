--[[
Title: CodeBlocklyDef_Events
Author(s): LiXizhi
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
	message0 = L"当演员被点击时",
	message1 = L"%1",
	arg1 = {
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
	funcName = "registerClickEvent",
	func_description = 'registerClickEvent(function()\\n%send)',
    ToPython = function(self)
		local input = self:getFieldAsString('input')
		if input == '' then
			input = 'pass'
		end
		return string.format('def registerClickEvent_func(msg):\n    %s\nregisterClickEvent(registerClickEvent_func)\n', input);
	end,
	ToNPL = function(self)
		return string.format('registerClickEvent(function()\n    %s\nend)\n', self:getFieldAsString('input'));
	end,
	examples = {{desc = "", canRun = true, code = [[
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
	type = "keyEventNames", 
	message0 = "%1",
	arg0 = {
		{
			name = "keyname",
			type = "field_dropdown",
			options = {
				{ L"空格", "space" },{ L"左", "left" },{ L"右", "right" },{ L"上", "up" },{ L"下", "down" }, { "ESC", "escape" },
				{"a","a"},{"b","b"},{"c","c"},{"d","d"},{"e","e"},{"f","f"},{"g","g"},{"h","h"},
				{"i","i"},{"j","j"},{"k","k"},{"l","l"},{"m","m"},{"n","n"},{"o","o"},{"p","p"},
				{"q","q"},{"r","r"},{"s","s"},{"t","t"},{"u","u"},{"v","v"},{"w","w"},{"x","x"},
				{"y","y"},{"z","z"},
				{"1","1"},{"2","2"},{"3","3"},{"4","4"},{"5","5"},{"6","6"},{"7","7"},{"8","8"},{"9","9"},{"0","0"},
				{"f1","f1"},{"f2","f2"},{"f3","f3"},{"f4","f4"},{"f5","f5"},{"f6","f6"},{"f7","f7"},{"f8","f8"},{"f9","f9"},{"f10","f10"},{"f11","f11"},{"f12","f12"},
				{ L"回车", "return" },{ "-", "minus" },{ "+", "equal" },{ "back", "back" },{ "tab", "tab" },
				{ "lctrl", "lcontrol" },{ "lshift", "lshift" },{ "lalt", "lmenu" },
				{"num0","numpad0"},{"num1","numpad1"},{"num2","numpad2"},{"num3","numpad3"},{"num4","numpad4"},{"num5","numpad5"},{"num6","numpad6"},{"num7","numpad7"},{"num8","numpad8"},{"num9","numpad9"},
				{L"鼠标滚轮","mouse_wheel"},{L"鼠标按钮","mouse_buttons"}
			},
		},
	},
	hide_in_toolbox = true,
	category = "Events", 
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
	type = "registerKeyPressedEvent", 
	message0 = L"当%1键按下时",
	message1 = L"%1",
	arg0 = {
		{
			name = "keyname",
			type = "input_value",
            shadow = { type = "keyEventNames", value = "space",},
		},
		
	},
    arg1 = {
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
	funcName = "registerKeyPressedEvent",
	func_description = 'registerKeyPressedEvent(%s, function(msg)\\n%send)',
    ToPython = function(self)
		local input = self:getFieldAsString('input')
		if input == '' then
			input = 'pass'
		end
		return string.format('def registerKeyPressedEvent_func(msg):\n    %s\nregisterKeyPressedEvent("%s", registerKeyPressedEvent_func)\n', input, self:getFieldAsString('keyname'));
	end,
	ToNPL = function(self)
		return string.format('registerKeyPressedEvent("%s", function(msg)\n    %s\nend)\n', self:getFieldAsString('keyname'), self:getFieldAsString('input'));
	end,
	examples = {
{desc = L"空格跳跃", canRun = true, code = [[
registerKeyPressedEvent("space",function()
    say("Jump!", 1)
    move(0,1,0, 0.5)
    move(0,-1,0, 0.5)
    walkForward(0)
end)
]]},
{desc = L"任意按键", canRun = true, code = [[
registerKeyPressedEvent("any", function(msg)
    run(function()
        say(msg.keyname)
    end)
    if(isKeyPressed("e")) then
        return true
    end
end)
]]},
{desc = L"鼠标按钮", canRun = true, code = [[
registerKeyPressedEvent("mouse_buttons",function(event)
    say("button:"..event:buttons())
end)
]]},
{desc = L"鼠标滚轮", canRun = true, code = [[
registerKeyPressedEvent("mouse_wheel",function(mouse_wheel)
    say("delta:"..mouse_wheel)
end)
]]},
},
},

{
	type = "registerBlockClickEvent", 
	message0 = L"当方块%1被点击时",
	message1 = L"%1",
	arg0 = {
		{
			name = "blockid",
			type = "input_value",
			shadow = { type = "text", value = "10",},
			text = "10", 
		},
	},
    arg1 = {
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
	funcName = "registerBlockClickEvent",
	func_description = 'registerBlockClickEvent(%s, function(msg)\\n%send)',
    ToPython = function(self)
		local input = self:getFieldAsString('input')
		if input == '' then
			input = 'pass'
		end
		return string.format('def registerBlockClickEvent_func(msg):\n    %s\nregisterBlockClickEvent("%s", registerBlockClickEvent_func)\n', input, self:getFieldAsString('blockid'));
	end,
	ToNPL = function(self)
		return string.format('registerBlockClickEvent("%s", function(msg)\n    %s\nend)\n', self:getFieldAsString('blockid'), self:getFieldAsString('input'));
	end,
	examples = {
{desc = L"任意方块被点击", canRun = true, code = [[
registerBlockClickEvent("any",function(msg)
    local blockid = msg.blockid;
    x, y, z, side = msg.x, msg.y, msg.z, msg.side
    say(blockid..":"..x..","..y..","..z..":"..side)
end)
]]},
{desc = L"某个方块被点击", canRun = true, code = [[
registerBlockClickEvent("10",function(msg)
    local blockid = msg.blockid;
    x, y, z, side = msg.x, msg.y, msg.z, msg.side
    tip("colorblock10:"..x..","..y..","..z..":"..side)
end)
]]},
},
},


{
	type = "registerTickEvent", 
	message0 = L"每%1帧执行",
	message1 = L"%1",
	arg0 = {
		{
			name = "ticks",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
            text = 1, 
		},
	},
    arg1 = {
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
	funcName = "registerTickEvent",
	func_description = 'registerTickEvent(%d, function(msg)\\n%send)',
    ToPython = function(self)
		local input = self:getFieldAsString('input')
		if input == '' then
			input = 'pass'
		end
		return string.format('def registerTickEvent_func(msg):\n    %s\nregisterTickEvent(%d, registerTickEvent_func)\n', input, self:getFieldValue('ticks'));
	end,
	ToNPL = function(self)
		return string.format('registerTickEvent(%d, function()\n    %s\nend)\n',  self:getFieldValue('ticks'), self:getFieldAsString('input'));
	end,
	examples = {
{desc = "", canRun = true, code = [[
i=1
registerTickEvent(1, function(msg)
    i = i + 1
    say(i)
end)
]]},
},
},

{
	type = "registerAnimationEvent", 
	message0 = L"当动画在%1帧时",
	message1 = L"%1",
	arg0 = {
		{
			name = "time",
			type = "input_value",
            shadow = { type = "math_number", value = 1000,},
			text = 1000, 
		},
		
	},
    arg1 = {
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
	funcName = "registerAnimationEvent",
	func_description = 'registerAnimationEvent(%d, function()\\n%send)',
    ToPython = function(self)
		local input = self:getFieldAsString('input')
		if input == '' then
			input = 'pass'
		end
		return string.format('def registerAnimationEvent_func(msg):\n    %s\nregisterAnimationEvent(%d, registerAnimationEvent_func)\n', input, self:getFieldValue('time'));
	end,
	ToNPL = function(self)
		return string.format('registerAnimationEvent(%d, function()\n    %s\nend)\n', self:getFieldValue('time'), self:getFieldAsString('input'));
	end,
	examples = {{desc = "", canRun = true, code = [[
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
	type = "msgTypes", 
	message0 = "%1",
	arg0 = {
		{
			name = "value",
			type = "field_input",
			text = "msg1",
		},
	},
	hide_in_toolbox = true,
	category = "Events", 
	output = {type = "null",},
	helpUrl = "", 
	canRun = false,
	func_description = '"%s"',
	colourSecondary = "#ffffff",
	ToNPL = function(self)
		return string.format("%q", self:getFieldAsString('value'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},


{
	type = "registerBroadcastEvent", 
	message0 = L"当收到%1消息时(%2)",
	message1 = "%1",
	arg0 = {
		{
			name = "msg",
			type = "input_value",
			shadow = { type = "msgTypes", value = "msg1",},
			text = "msg1", 
		},
		{
			name = "param1",
			type = "field_input",
			text = "msg", 
		},
	},
    arg1 = {
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
	funcName = "registerBroadcastEvent",
	func_description = 'registerBroadcastEvent(%s, function(%s)\\n%send)',
    ToPython = function(self)
		local input = self:getFieldAsString('input')
		if input == '' then
			input = 'pass'
		end
		return string.format('def registerBroadcastEvent_func(msg):\n    %s\nregisterBroadcastEvent("%s", registerBroadcastEvent_func)\n', input, self:getFieldValue('msg'));
	end,
	ToNPL = function(self)
		return string.format('registerBroadcastEvent("%s", function(msg)\n    %s\nend)\n', self:getFieldAsString('msg'), self:getFieldAsString('input'));
	end,
	examples = {{desc = "", canRun = true, code = [[
registerBroadcastEvent("jump", function(fromName)
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
			type = "input_value",
			shadow = { type = "msgTypes", value = "msg1",},
			text = "msg1", 
		},
	},
	category = "Events", 
	color="#00cc00",
	helpUrl = "", 
	canRun = false,
	hide_in_toolbox = true, -- deprecated, use broadcast2
	previousStatement = true,
	nextStatement = true,
	funcName = "broadcast",
	func_description = 'broadcast(%s)',
	ToNPL = function(self)
		return string.format('broadcast("%s")\n', self:getFieldAsString('msg'));
	end,
	examples = {{desc = "", canRun = true, code = [[
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
	type = "broadcast2", 
	message0 = L"广播消息%1(%2)",
	arg0 = {
		{
			name = "msg",
			type = "input_value",
			shadow = { type = "msgTypes", value = "msg1",},
			text = "msg1", 
		},
		{
			name = "params",
			type = "input_value",
			shadow = { type = "text", value = "",},
			text = "", 
		},
	},
	category = "Events", 
	color="#00cc00",
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "broadcast",
	func_description = 'broadcast(%s, %s)',
	ToNPL = function(self)
		return string.format('broadcast("%s", "%s")\n', self:getFieldAsString('msg'), self:getFieldAsString('params'));
	end,
	examples = {{desc = "", canRun = true, code = [[
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
			type = "input_value",
			shadow = { type = "msgTypes", value = "msg1",},
			text = "msg1", 
		},
	},
	category = "Events", 
	color="#00cc00",
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "broadcastAndWait",
	func_description = 'broadcastAndWait(%s)',
	ToNPL = function(self)
		return string.format('broadcastAndWait("%s")\n', self:getFieldAsString('msg'));
	end,
	examples = {{desc = "", canRun = true, code = [[
registerBroadcastEvent("hi", function(fromName)
    say("hi,"..tostring(fromName))
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
	type = "broadcastTo", 
	message0 = L"广播消息给%1,%2,%3",
	arg0 = {
		{
			name = "username",
			type = "input_value",
			shadow = { type = "text", value = "username",},
			text = "username", 
		},
		{
			name = "msg",
			type = "input_value",
			shadow = { type = "text", value = "title",},
			text = "title", 
		},
		{
			name = "params",
			type = "input_value",
			shadow = { type = "msgTable", value = "{}",},
			text = "{}", 
		},
	},
	category = "Events", 
	color="#00cc00",
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "broadcastTo",
	func_description = 'broadcastTo(%s, %s, %s)',
	ToNPL = function(self)
		return string.format('broadcastTo("%s", "%s", %s)\n', self:getFieldAsString('username'), self:getFieldAsString('msg'), self:getFieldAsString('params'));
	end,
	examples = {{desc = "", canRun = false, code = [[
registerBroadcastEvent("Hello", function(msg)
    tip(msg.text.." from "..(msg.from or ""))    
end)
setActorValue("name", "Alice")
broadcastTo("Alice", "Hello", {text="hello"})
]]},
},
},

{
	type = "registerStopEvent", 
	message0 = L"当代码方块停止时",
	message1 = L"%1",
	arg1 = {
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
	funcName = "registerStopEvent",
	func_description = 'registerStopEvent(function()\\n%send)',
	ToPython = function(self)
		local input = self:getFieldAsString('input')
		if input == '' then
			input = 'pass'
		end
		return string.format('def registerStopEvent_func(msg):\n    %s\nregisterStopEvent(registerStopEvent_func)\n', input);
	end,
	ToNPL = function(self)
		return string.format('registerStopEvent(function()\n    %s\nend)\n', self:getFieldAsString('input'));
	end,
	examples = {{desc = L"只能执行马上可返回的代码", canRun = true, code = [[
registerStopEvent(function()
    tip("stopped")
end)
]]}},
},

{
	type = "registerAgentEvent", 
	message0 = L"当收到%1智能消息时(%2)",
	message1 = "%1",
	arg0 = {
		{
			name = "msg",
			type = "input_value",
			shadow = { type = "agentEventTypes", value = "TryCreate",},
			text = "GetIcon", 
		},
		{
			name = "param1",
			type = "field_input",
			text = "msg", 
		},
	},
    arg1 = {
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
	funcName = "registerAgentEvent",
	func_description = 'registerAgentEvent(%s, function(%s)\\n%send)',
    ToPython = function(self)
		local input = self:getFieldAsString('input')
		if input == '' then
			input = 'pass'
		end
		return string.format('def registerAgentEvent_func(msg):\n    %s\nregisterAgentEvent("%s", registerAgentEvent_func)\n', input, self:getFieldValue('msg'));
	end,
	ToNPL = function(self)
		return string.format('registerAgentEvent("%s", function(msg)\n    %s\nend)\n', self:getFieldAsString('msg'), self:getFieldAsString('input'));
	end,
	examples = {{desc = "", canRun = false, code = [[
registerAgentEvent("TryCreate", function(msg)
    setBlock(msg.x, msg.y, msg.z, 62)
end)
registerAgentEvent("OnSelect", function(msg)
    tip("you selected agent item")
end)
registerAgentEvent("OnDeSelect", function(msg)
    tip("you de-selected agent item")
end)
registerAgentEvent("GetIcon", function()
    return "Texture/blocks/items/apple.png"
end)
registerAgentEvent("OnClickInHand", function(msg)
    tip("you clicked me!")
end)
]]}},
},

{
	type = "agentEventTypes", 
	message0 = "%1",
	arg0 = {
		{
			name = "value",
			type = "field_dropdown",
			options = {
				{ L"TryCreate", "TryCreate" },
				{ L"OnSelect", "OnSelect" },
				{ L"OnDeSelect", "OnDeSelect" },
				{ L"GetIcon", "GetIcon" },
				{ L"OnClickInHand", "OnClickInHand" },
			},
		},
	},
	hide_in_toolbox = true,
	category = "Events", 
	output = {type = "null",},
	helpUrl = "", 
	canRun = false,
	func_description = '"%s"',
	ToNPL = function(self)
		return self:getFieldAsString('value');
	end,
	examples = {{desc = "", canRun = false, code = [[
]]}},
},

{
	type = "networkEventTypes", 
	message0 = "%1",
	arg0 = {
		{
			name = "value",
			type = "field_dropdown",
			options = {
				{ L"ps_用户加入", "ps_user_joined" },
				{ L"ps_用户离开", "ps_user_left" },
				{ L"ps_服务器启动", "ps_server_started" },
				{ L"ps_服务器关闭", "ps_server_shutdown" },
				{ L"用户加入", "connect" },
			},
		},
	},
	hide_in_toolbox = true,
	category = "Events", 
	output = {type = "null",},
	helpUrl = "", 
	canRun = false,
	func_description = '"%s"',
	ToNPL = function(self)
		return self:getFieldAsString('value');
	end,
	examples = {{desc = "", canRun = false, code = [[
]]}},
},

{
	type = "registerNetworkEvent", 
	message0 = L"当收到网络消息%1(%2)时",
	message1 = "%1",
	arg0 = {
		{
			name = "msg",
			type = "input_value",
			shadow = { type = "networkEventTypes", value = "connect",},
			text = "connect", 
		},
		{
			name = "param1",
			type = "field_input",
			text = "msg", 
		},
	},
    arg1 = {
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
	funcName = "registerNetworkEvent",
	func_description = 'registerNetworkEvent(%s, function(%s)\\n%send)',
    ToPython = function(self)
		local input = self:getFieldAsString('input')
		if input == '' then
			input = 'pass'
		end
		return string.format('def registerNetworkEvent_func(msg):\n    %s\nregisterNetworkEvent("%s", registerNetworkEvent_func)\n', input, self:getFieldAsString('msg'));
	end,
	ToNPL = function(self)
		return string.format('registerNetworkEvent("%s", function(msg)\n    %s\nend)\n', self:getFieldAsString('msg'), self:getFieldAsString('input'));
	end,
	examples = {{desc = L"私服模式:", canRun = false, code = [[
registerNetworkEvent("ps_user_joined", function(msg)
    tip(format("user join: %s id:%d", msg.username, msg.entityId))
    wait(1)
    sendNetworkEvent(msg.username, "Hello", {text=msg.username})
    sendNetworkEvent(msg.entityId, "Hello", {text="welcome"})
end)
registerNetworkEvent("ps_user_left", function(msg)
    tip(format("user left: %s id:%d", msg.username, msg.entityId))
end)
registerNetworkEvent("ps_server_started", function(msg)
    tip(format("server start: %s id:%d", msg.username, msg.entityId))
end)
registerNetworkEvent("Hello", function(msg)
    tip(msg.from..":"..msg.text)
end)
]]},
{desc = L"大厅模式:", canRun = false, code = [[
registerNetworkEvent("updateScore", function(msg)
   _G[msg.userinfo.keepworkUsername] = msg.score;
   showVariable(msg.userinfo.keepworkUsername)
end)

registerNetworkEvent("connect", function(msg)
   broadcastNetworkEvent("updateScore", {score = 100})
end)

registerNetworkEvent("disconnect", function(msg)
   hideVariable(msg.userinfo.keepworkUsername)
end)

while(true) do
   broadcastNetworkEvent("updateScore", {score = 100})
   wait(1);
end
]]},

},
},

{
	type = "msgTable", 
	message0 = "%1",
	arg0 = {
		{
			name = "value",
			type = "field_input",
			text = "{}"
		},
	},
	hide_in_toolbox = true,
	category = "Events", 
	output = {type = "null",},
	colourSecondary = "#ffffff",
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
	type = "broadcastNetworkEvent", 
	message0 = L"广播网络消息%1(%2)",
	arg0 = {
		{
			name = "msg",
			type = "input_value",
			shadow = { type = "text", value = "msgname",},
			text = "msgname", 
		},
		{
			name = "params",
			type = "input_value",
			shadow = { type = "msgTable", value = "{}",},
			text = "{}", 
		},
	},
	category = "Events", 
	color="#00cc00",
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "broadcastNetworkEvent",
	func_description = 'broadcastNetworkEvent(%s, %s)',
	ToNPL = function(self)
		return string.format('broadcastNetworkEvent("%s", %s)\n', self:getFieldAsString('msg'), self:getFieldAsString('params'));
	end,
	examples = {{desc = L"私服模式:", canRun = false, code = [[
registerNetworkEvent("HelloText", function(msg)
    tip("HelloText: "..msg.text.." from: "..msg.from)
    if(GameLogic.isServer) then
        broadcastNetworkEvent("HelloText", {text=msg.text, from=msg.from}) 
    end
end)
if(GameLogic.isRemote) then
    for i=1, 2000 do
        sendNetworkEvent("admin",  "HelloText", {text=i}) 
        wait(1)
    end
end
]]},
{desc = L"大厅模式:", canRun = false, code = [[
hide()
becomeAgent("@p")

registerNetworkEvent("updatePlayerPos", function(msg)
   runForActor(msg.userinfo.keepworkUsername, function()
      moveTo(msg.x, msg.y, msg.z)
   end)
end)

registerCloneEvent(function(name)
    setActorValue("name", name)
end)

registerNetworkEvent("connect", function(msg)
    clone(nil, msg.userinfo.keepworkUsername)
end)

registerNetworkEvent("disconnect", function(msg)
   runForActor(msg.userinfo.keepworkUsername, function()
      delete();
   end)
end)

while(true) do
   broadcastNetworkEvent("updatePlayerPos", {x = getX(), y=getY(), z=getZ()})
   wait(0.2);
end
]]}},
},


{
	type = "sendNetworkEvent", 
	message0 = L"发送网络消息给%1,%2,%3",
	arg0 = {
		{
			name = "username",
			type = "input_value",
			shadow = { type = "text", value = "username",},
			text = "username", 
		},
		{
			name = "msg",
			type = "input_value",
			shadow = { type = "text", value = "title",},
			text = "title", 
		},
		{
			name = "params",
			type = "input_value",
			shadow = { type = "msgTable", value = "{}",},
			text = "{}", 
		},
	},
	category = "Events", 
	color="#00cc00",
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "sendNetworkEvent",
	func_description = 'sendNetworkEvent(%s, %s, %s)',
	ToNPL = function(self)
		return string.format('sendNetworkEvent("%s", "%s", %s)\n', self:getFieldAsString('username'), self:getFieldAsString('msg'), self:getFieldAsString('params'));
	end,
	examples = {{desc = L"私服模式:", canRun = false, code = [[
registerNetworkEvent("HelloText", function(msg)
    tip("HelloText: "..msg.text.." from: "..msg.from)
    if(GameLogic.isServer) then
        broadcastNetworkEvent("HelloText", {text=msg.text, from=msg.from}) 
    end
end)
if(GameLogic.isRemote) then
    for i=1, 2000 do
        sendNetworkEvent("admin",  "HelloText", {text=i}) 
        wait(1)
    end
end
]]},
{desc = L"大厅模式:"..L"发送消息给指定用户", canRun = false, code = [[
registerNetworkEvent("title", function(msg)
   tip(msg.userinfo.keepworkUsername)
   wait(1)
   tip(msg.a)
end)

sendNetworkEvent("username", "title", {a=1})
]]},

{desc = L"UDP模式:"..L"发送原始消息给指定地址(无需登录)", canRun = false, code = [[
-- __original is predefined name
registerNetworkEvent("__original", function(msg)
   log(msg.isUDP)
   log(msg.nid or msg.tid)
   log(msg.data)
end)

sendNetworkEvent(nid, nil, "binary \0 string")
-- given ip and port
sendNetworkEvent("\\\\192.168.0.1 8099", nil, "binary \0 string")
-- broadcast with subnet
sendNetworkEvent("\\\\192.168.0.255 8099", nil, "binary \0 string")
-- UDP broadcast
sendNetworkEvent("*8099", nil, "binary \0 string")
]]},
},
},


{
	type = "cmdExamples", 
	message0 = "%1",
	arg0 = {
		{
			name = "value",
			type = "field_dropdown",
			options = {
				{ L"/tip", "/tip" },
				{ L"改变时间[-1,1]", "/time"},
				{ L"加载世界:项目id", "/loadworld"},
				{ L"设置真实光影[1|2|3]", "/shader"},
				{ L"设置光源颜色[0,2] [0,2] [0,2]", "/light"},
				{ L"设置太阳颜色[0,2] [0,2] [0,2]", "/sun"},
				{ L"发送事件HelloEvent", "/sendevent HelloEvent {data=1}" },
				{ L"添加规则:Lever可放在Glowstone上", "/addrule Block CanPlace Lever Glowstone" },
				{ L"添加规则:Glowstone可被删除", "/addrule Block CanDestroy Glowstone true" },
				{ L"添加规则:人物自动爬坡", "/addrule Player AutoWalkupBlock false" },
				{ L"添加规则:人物可跳跃", "/addrule Player CanJump true" },
				{ L"添加规则:人物摄取距离为5米", "/addrule Player PickingDist 5" },
				{ L"添加规则:人物可在空中继续跳跃", "/addrule Player CanJumpInAir true" },
				{ L"添加规则:人物可飞行", "/addrule Player CanFly true" },
				{ L"添加规则:人物在水中可跳跃", "/addrule Player CanJumpInWater true" },
				{ L"添加规则:人物跳起的速度", "/addrule Player JumpUpSpeed 5" },
				{ L"添加规则:人物可跑步", "/addrule Player AllowRunning false" },
				{ L"设置最小人物出现距离", "/property -scene MinPopUpDistance 100"},
				{ L"设置最大人物多边形数目", "/property -scene MaxCharTriangles 500000"},
				{ L"禁用自动人物细节", "/lod off"},
				{ L"关闭自动等待", "/autowait false"},
				{ L"隐藏物品栏", "/hide quickselectbar"},
				{ L"显示物品栏", "/show quickselectbar"},
			},
		},
	},
	hide_in_toolbox = true,
	category = "Events", 
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
	type = "cmd", 	message0 = L"执行命令%1,%2",
	arg0 = {
		{
			name = "msg",
			type = "input_value",
            shadow = { type = "cmdExamples", value = "/tip hello",},
			text = "/tip hello", 
		},
		{
			name = "params",
			type = "input_value",
			shadow = { type = "text", value = "",},
			text = "\"\"",
		},
	},
	category = "Events", 
	color="#cc0000",
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "cmd",
	func_description = 'cmd(%s, %s)',
	ToNPL = function(self)
		return string.format('cmd("%s", %s)\n', self:getFieldAsString('msg'), self:getFieldAsString('params'));
	end,
	examples = {
	{desc = "", canRun = true, code = [[
cmd("/setblock ~0 ~0 ~1 62")
cmd("/cameradist 12")
cmd("/camerayaw 0")
cmd("/camerapitch 0.5")
cmd("/time", "0")
]]},
{desc = L"关闭自动等待", canRun = true, code = [[
set("count", 1)
showVariable("count")
cmd("/autowait false")
for i=1, 10000 do
    _G.count = count +1
end
say("it finished instantly with autowait false", 3)
cmd("/autowait true")
for i=1, 10000 do
    _G.count = count +1
end
]]}
},
},

};
function CodeBlocklyDef_Events.GetCmds()
	return cmds;
end
