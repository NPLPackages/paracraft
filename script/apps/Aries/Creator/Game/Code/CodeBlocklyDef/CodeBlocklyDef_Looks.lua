--[[
Title: CodeBlocklyDef_Looks
Author(s): leio
Date: 2018/7/5
Desc: define blocks in category of Looks
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyDef/CodeBlocklyDef_Looks.lua");
local CodeBlocklyDef_Looks= commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyDef.CodeBlocklyDef_Looks");
-------------------------------------------------------
]]
local CodeBlocklyDef_Looks = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyDef.CodeBlocklyDef_Looks");
local cmds = {
-- Looks
{
	type = "sayAndWait", 
	message0 = L"说 %1 持续 %2 秒",
	arg0 = {
		{
			name = "text",
            type = "input_value",
            shadow = { type = "text", value = L"hello!",},
			text = L"hello!", 
		},
		{
			name = "duration",
			type = "input_value",
            shadow = { type = "math_number", value = 2,},
			text = 2, 
		},
	},
	category = "Looks", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	func_description = 'say(%s, %s)',
	ToNPL = function(self)
		return string.format('say("%s", %s)\n', self:getFieldValue('text'), self:getFieldAsString('duration'));
	end,
	examples = {{desc = "", canRun = true, code = [[
say("Jump!", 2)
move(0,1,0)
]]}},
},
{
	type = "say", 
	message0 = L"说 %1",
	arg0 = {
		{
			name = "text",
			type = "input_value",
            shadow = { type = "text", value = L"hello!",},
			text = L"hello!", 
		},
	},
	category = "Looks", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	func_description = 'say(%s)',
	ToNPL = function(self)
		return string.format('say("%s")\n', self:getFieldValue('text'));
	end,
	examples = {{desc = L"在人物头顶说些话", canRun = true, code = [[
say("Hello!")
wait(1)
say("")
]]}},
},
{
	type = "tip", 
	message0 = L"提示文字%1",
	arg0 = {
		{
			name = "text",
			type = "input_value",
            shadow = { type = "text", value = L"Start Game!",},
			text = L"Start Game!", 
		},
	},
	category = "Looks", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	func_description = 'tip(%s)',
	ToNPL = function(self)
		return string.format('tip("%s")\n', self:getFieldValue('text'));
	end,
	examples = {{desc = "", canRun = true, code = [[
tip("Start Game in 3!")
wait(1)
tip("Start Game in 2!")
wait(1)
tip("Start Game in 1!")
wait(1)
tip("")
]]}},
},
{
	type = "show", 
	message0 = L"显示",
	arg0 = {
	},
	category = "Looks", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	func_description = 'show()',
	ToNPL = function(self)
		return string.format('show()\n');
	end,
},
{
	type = "hide", 
	message0 = L"隐藏",
	arg0 = {
	},
	category = "Looks", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	func_description = 'hide()',
	ToNPL = function(self)
		return string.format('hide()\n');
	end,
},
{
	type = "anim", 
	message0 = L"播放动作编号 %1",
	arg0 = {
		{
			name = "animId",
			type = "input_value",
            shadow = { type = "math_number", value = 4,},
			text = 4, 
		},
	},
	category = "Looks", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	func_description = 'anim(%d)',
	ToNPL = function(self)
		return string.format('anim(%d)\n', self:getFieldValue('animId'));
	end,
	examples = {{desc = "", canRun = true, code = [[
anim(4)
move(-2,0,0,1)
anim(0)
]]},
{desc = L"常用动作编号", canRun = true, code = [[
-- 0: standing
-- 4: walking 
-- 5: running
-- check movie block for more ids
]]}
},
},
{
	type = "play", 
	message0 = L"播放从%1到%2毫秒",
	arg0 = {
		{
			name = "timeFrom",
			type = "input_value",
            shadow = { type = "math_number", value = 10,},
			text = 10, 
		},
		{
			name = "timeTo",
			type = "input_value",
            shadow = { type = "math_number", value = 1000,},
			text = 1000, 
		},
	},
	category = "Looks", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	func_description = 'play(%d, %d)',
	ToNPL = function(self)
		return string.format('play(%d, %d)\n', self:getFieldValue('timeFrom'), self:getFieldValue('timeTo'));
	end,
	examples = {{desc = L"播放电影方块中的角色动画", canRun = true, code = [[
play(10, 1000)
say("No looping", 1)
]]}},
},
{
	type = "playLoop", 
	message0 = L"循环播放从%1到%2毫秒",
	arg0 = {
		{
			name = "timeFrom",
			type = "input_value",
            shadow = { type = "math_number", value = 10,},
			text = 10, 
		},
		{
			name = "timeTo",
			type = "input_value",
            shadow = { type = "math_number", value = 1000,},
			text = 1000, 
		},
	},
	category = "Looks", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	func_description = 'playLoop(%d, %d)',
	ToNPL = function(self)
		return string.format('playLoop(%d, %d)\n', self:getFieldValue('timeFrom'), self:getFieldValue('timeTo'));
	end,
	examples = {{desc = L"播放电影方块中的角色动画", canRun = true, code = [[
playLoop(10, 1000)
say("Looping", 3)
stop()
]]}},
},
{
	type = "playSpeed", 
	message0 = L"播放速度%1",
	arg0 = {
		{
			name = "speed",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
	},
	category = "Looks", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	func_description = 'playSpeed(%d)',
	ToNPL = function(self)
		return string.format('playSpeed(%d)\n', self:getFieldValue('speed'));
	end,
	examples = {{desc = "", canRun = true, code = [[
playSpeed(4)
playLoop(0, 1000)
say("Looping", 3)
playSpeed(1)
stop()
]]}},
},
{
	type = "stop", 
	message0 = L"停止播放",
	arg0 = {
	},
	category = "Looks", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	func_description = 'stop()',
	ToNPL = function(self)
		return 'stop()\n';
	end,
	examples = {{desc = L"播放/暂停角色动画", canRun = true, code = [[
playLoop(10, 1000)
wait(2)
stop()
turn(15)
playLoop(10, 1000)
wait(2)
stop()
]]}},
},
{
	type = "scale", 
	message0 = L"放缩百分之%1",
	arg0 = {
		{
			name = "scaleDelta",
			type = "input_value",
            shadow = { type = "math_number", value = 10,},
			text = 10, 
		},
	},
	category = "Looks", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	func_description = 'scale(%d)',
	ToNPL = function(self)
		return string.format('scale(%d)\n', self:getFieldValue('scaleDelta'));
	end,
	examples = {{desc = "", canRun = true, code = [[
scale(50)
wait(1)
scale(-50)
]]}},
},
{
	type = "scaleTo", 
	message0 = L"放缩到百分之%1",
	arg0 = {
		{
			name = "scale",
			type = "input_value",
            shadow = { type = "math_number", value = 100,},
			text = 100, 
		},
	},
	category = "Looks", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	func_description = 'scaleTo(%d)',
	ToNPL = function(self)
		return string.format('scaleTo(%d)\n', self:getFieldValue('scale'));
	end,
	examples = {{desc = "", canRun = true, code = [[
for i=1, 20 do
    scale(10)
end
scaleTo(50)
wait(0.5)
scaleTo(200)
wait(0.5)
scaleTo(100)
]]}},
},
{
	type = "focus_list", 
	message0 = "%1",
	arg0 = {
		{
			name = "to",
			type = "field_dropdown",
			options = {
				{ L"此角色", "myself" },
				{ L"主角", "player" },
				{ L"某个角色名", "" },
			},
		},
		
	},
    hide_in_toolbox = true,
    output = {type = "null",},
	category = "Looks", 
	helpUrl = "", 
	canRun = false,
	func_description = '"%s"',
	ToNPL = function(self)
		return 'local key = "value"\n';
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "focus", 
	message0 = L"观看%1",
	arg0 = {
		{
			name = "name",
			type = "input_value",
            shadow = { type = "focus_list" },
			text = "myself",
		},
	},
	category = "Looks", 
	color = "#cc0000",
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	func_description = 'focus(%s)',
	ToNPL = function(self)
		return string.format('focus("%s")\n', self:getFieldAsString('name'));
	end,
	examples = {{desc = "", canRun = true, code = [[
focus()
moveForward(2,2)
focus("player")
]]}},
},

{
	type = "camera", 
	message0 = L"摄影机距离%1角度%2朝向%3",
	arg0 = {
		{
			name = "dist",
			type = "input_value",
            shadow = { type = "math_number", value = 12,},
			text = 12, 
		},
		{
			name = "pitch",
			type = "input_value",
            shadow = { type = "math_number", value = 45,},
			text = 45, 
		},
		{
			name = "facing",
			type = "input_value",
            shadow = { type = "math_number", value = 90,},
			text = 90, 
		},
	},
	category = "Looks", 
	color = "#cc0000",
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	func_description = 'camera(%s, %s, %s)',
	ToNPL = function(self)
		return string.format('camera(%s, %s, %s)\n', self:getFieldAsString('dist'), self:getFieldAsString('pitch'), self:getFieldAsString('facing'));
	end,
	examples = {{desc = "", canRun = true, code = [[
for i=1, 100 do
    camera(10+i*0.1, nil, nil)
    wait(0.05)
end
]]}},
},

{
	type = "getScale", 
	message0 = L"放缩尺寸",
	arg0 = {},
	output = {type = "field_number",},
	category = "Looks", 
	helpUrl = "", 
	canRun = false,
	func_description = 'getScale()',
	ToNPL = function(self)
		return 'getScale()';
	end,
	examples = {{desc = "", canRun = true, code = [[
while(true) do
    if(getScale() >= 200) then
        scaleTo(100)
    else
        scale(10)
    end
end
]]}},
},
{
	type = "getPlayTime", 
	message0 = L"动画时间",
	arg0 = {},
	output = {type = "field_number",},
	category = "Looks", 
	helpUrl = "", 
	canRun = false,
	func_description = 'getPlayTime()',
	ToNPL = function(self)
		return 'getPlayTime()';
	end,
	examples = {{desc = "", canRun = true, code = [[
playLoop(10, 2000)
while(true) do
    if(getPlayTime() > 1000) then
        say("hi")
    else
        say("")
    end
    wait(0.01);
end
]]}},
},
};
function CodeBlocklyDef_Looks.GetCmds()
	return cmds;
end
