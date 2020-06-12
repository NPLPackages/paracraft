--[[
Title: CodeBlocklyDef_Looks
Author(s): LiXizhi
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
	funcName = "say",
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
	funcName = "say",
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
	funcName = "tip",
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
	funcName = "show",
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
	funcName = "hide",
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
	funcName = "anim",
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
	funcName = "play",
	func_description = 'play(%s, %s)',
	ToNPL = function(self)
		return string.format('play(%d, %d)\n', self:getFieldValue('timeFrom'), self:getFieldValue('timeTo'));
	end,
	examples = {{desc = L"播放电影方块中的角色动画", canRun = true, code = [[
play(10, 1000)
say("No looping", 1)
]]}},
},
{
	type = "playAndWait", 
	message0 = L"播放并等待从%1到%2毫秒",
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
	funcName = "playAndWait",
	func_description = 'playAndWait(%s, %s)',
	ToNPL = function(self)
		return string.format('playAndWait(%d, %d)\n', self:getFieldValue('timeFrom'), self:getFieldValue('timeTo'));
	end,
	examples = {{desc = L"播放电影方块中的角色动画", canRun = true, code = [[
playAndWait(10, 1000)
say("finished")
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
	funcName = "playLoop",
	func_description = 'playLoop(%s, %s)',
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
	type = "playBone", 
	message0 = L"骨骼%1从%2到%3并循环%4",
	arg0 = {
		{
			name = "boneName",
			type = "input_value",
            shadow = { type = "text", value = "Root",},
			text = "Root", 
		},
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
		{
			name = "isLooping",
			type = "field_dropdown",
			options = {
				{ "true", "true" },
				{ "false", "false" },
			},
			text = "true", 
		},
	},
	category = "Looks", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "playBone",
	func_description = 'playBone(%s, %s, %s, %s)',
	ToNPL = function(self)
		return string.format('playBone("%s", %d, %d, %s)\n', self:getFieldValue('boneName'),  self:getFieldValue('timeFrom'), self:getFieldValue('timeTo'), self:getFieldValue('isLooping'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
playBone("Neck", 2000)
-- regular expression supported
playBone(".*UpperArm", 5000, 7000)
playBone(".*Forearm", 5000, 7000)
play(0, 4000)
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
	funcName = "playSpeed",
	func_description = 'playSpeed(%d)',
	ToNPL = function(self)
		return string.format('playSpeed(%d)\n', self:getFieldValue('speed'));
	end,
	examples = {{desc = "", canRun = true, code = [[
playSpeed(4)
playLoop(0, 1000)
say("Looping", 3)
setActorValue("playSpeed", 1)
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
	funcName = "stop",
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
	funcName = "scale",
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
	funcName = "scaleTo",
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
	funcName = "focus",
	func_description = 'focus(%s)',
	ToNPL = function(self)
		return string.format('focus("%s")\n', self:getFieldAsString('name'));
	end,
	examples = {{desc = "", canRun = true, code = [[
focus()
moveForward(2,2)
focus("player")
]]},
{desc = "", canRun = true, code = [[
focus("someName")
focus(getActor("someName2"))
]]}
},
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
	funcName = "camera",
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
	funcName = "getScale",
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
	funcName = "getPlayTime",
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

{
	type = "setMovie", 
	message0 = L"设置电影频道%1为:%2,%3,%4",
	arg0 = {
		{
			name = "name",
			type = "input_value",
            shadow = { type = "text", value = "myself",},
			text = "myself", 
		},
		{
			name = "x",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
		{
			name = "y",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
		{
			name = "z",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
	},
	category = "Looks", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "setMovie",
	func_description = 'setMovie(%s, %s, %s, %s)',
	ToNPL = function(self)
		return string.format('setMovie("%s", %s, %s, %s)\n', self:getFieldAsString('name'), self:getFieldAsString('x'), self:getFieldAsString('y'), self:getFieldAsString('z'));
	end,
	examples = {{desc = L"不传参数代表与代码方块相邻的电影方块", canRun = true, code = [[
hide()
setMovie("main")
playMovie("main", 0, -1);
]]},

{desc = L"myself代表当前代码方块的名字", canRun = true, code = [[
setMovie("myself")
playMovie("myself", 0, -1);
]]},

{desc = L"指定电影方块的坐标", canRun = true, code = [[
local x, y, z = codeblock:GetBlockPos();
setMovie("main", x, y, z+1)
playMovie("main", 0, -1);
]]},

},
},

{
	type = "isMatchMovie", 
	message0 = L"是否匹配电影%1",
	arg0 = {
		{
			name = "name",
			type = "input_value",
            shadow = { type = "text", value = "myself",},
			text = "myself", 
		},
	},
	category = "Looks", 
	helpUrl = "", 
	canRun = true,
	output = {type = "null",},
	funcName = "isMatchMovie",
	func_description = 'isMatchMovie(%s)',
	ToNPL = function(self)
		return string.format('isMatchMovie("%s")\n', self:getFieldAsString('name'));
	end,
	examples = {{desc = L"myself代表当前代码方块的名字", canRun = true, code = [[
if(isMatchMovie("myself")) then
	playMatchedMovie("myself")
end
]]}},
},

{
	type = "playMatchedMovie", 
	message0 = L"播放匹配的电影%1,%2",
	arg0 = {
		{
			name = "name",
			type = "input_value",
            shadow = { type = "text", value = "myself",},
			text = "myself", 
		},
		{
			name = "waitForFinish",
			type = "field_dropdown",
			options = {
				{ L"并等待", "true" },
				{ L"不等待", "false" },
			},
		},
	},

	category = "Looks", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "playMatchedMovie",
	func_description = 'playMatchedMovie(%s, %s)',
	ToNPL = function(self)
		return string.format('playMatchedMovie("%s", %s)\n', self:getFieldAsString('name'), self:getFieldAsString('waitForFinish'));
	end,
	examples = {{desc = L"myself代表当前代码方块的名字", canRun = true, code = [[
if(isMatchMovie("myself")) then
	playMatchedMovie("myself")
end
]]}},
},

{
	type = "playMovie", 
	message0 = L"播放电影频道%1从%2到%3毫秒",
	arg0 = {
		{
			name = "name",
			type = "input_value",
            shadow = { type = "text", value = "myself",},
			text = "myself", 
		},
		{
			name = "timeFrom",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
		{
			name = "timeTo",
			type = "input_value",
            shadow = { type = "math_number", value = -1,},
			text = -1, 
		},
	},
	category = "Looks", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "playMovie",
	func_description = 'playMovie(%s, %s, %s)',
	ToNPL = function(self)
		return string.format('playMovie("%s", %d, %d)\n', self:getFieldAsString('name'), self:getFieldValue('timeFrom'), self:getFieldValue('timeTo'));
	end,
	examples = {{desc = L"播放与代码方块相邻的电影方块", canRun = true, code = [[
hide()
-- -1 means end of movie
playMovie("myself", 0, -1);
stopMovie("myself");
]]}},
},

{
	type = "playMovieLoop", 
	message0 = L"循环播放电影频道%1从%2到%3毫秒",
	arg0 = {
		{
			name = "name",
			type = "input_value",
            shadow = { type = "text", value = "myself",},
			text = "myself", 
		},
		{
			name = "timeFrom",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
		{
			name = "timeTo",
			type = "input_value",
            shadow = { type = "math_number", value = -1,},
			text = -1, 
		},
	},
	category = "Looks", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "playMovie",
	func_description = 'playMovie(%s, %s, %s, true)',
	ToNPL = function(self)
		return string.format('playMovie("%s", %d, %d, true)\n', self:getFieldAsString('name'), self:getFieldValue('timeFrom'), self:getFieldValue('timeTo'));
	end,
	examples = {{desc = L"播放与代码方块相邻的电影方块", canRun = true, code = [[
hide()
playMovie("myself", 0, 1000, true);
]]}},
},

{
	type = "stopMovie", 
	message0 = L"停止播放电影频道%1",
	arg0 = {
		{
			name = "name",
			type = "input_value",
            shadow = { type = "text", value = "myself",},
			text = "myself", 
		},
	},
	category = "Looks", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "stopMovie",
	func_description = 'stopMovie(%s)',
	ToNPL = function(self)
		return string.format('stopMovie("%s")\n', self:getFieldAsString('name'));
	end,
	examples = {{desc = "", canRun = true, code = [[
playMovie("myself", 0, -1);
stopMovie();
]]}},
},

{
	type = "setMovieProperty", 
	message0 = L"设置电影频道%1的属性%2为%3",
	arg0 = {
		{
			name = "name",
			type = "input_value",
            shadow = { type = "text", value = "myself",},
			text = "myself", 
		},
		{
			name = "key",
			type = "field_dropdown",
			options = {
				{ L"播放速度", "Speed" },
				{ L"重用角色", "ReuseActor" },
				{ L"使用摄影机", "UseCamera" },
			},
		},
		{
			name = "value",
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
	funcName = "setMovieProperty",
	func_description = 'setMovieProperty(%s, "%s", %s)',
	ToNPL = function(self)
		return string.format('setMovieProperty("%s", "%s", %s)\n', self:getFieldAsString('name'), self:getFieldAsString('key'), self:getFieldAsString('value'));
	end,
	examples = {{desc = "", canRun = true, code = [[
setMovieProperty("myself", "Speed", 2);
playMovie("myself", 0, -1);
stopMovie();
]]}},
},

{
	type = "window", 
	message0 = L"窗口%1,%2,%3,%4,%5,%6",
	arg0 = {
		{
			name = "mcmlCode",
			type = "input_value",
            shadow = { type = "text", value = "html",},
			text = "html", 
		},
		{
			name = "alignment",
			type = "field_dropdown",
			options = {
				{ L"左上", "_lt" },
				{ L"左下", "_lb" },
				{ L"居中", "_ct" },
				{ L"居中上", "_ctt" },
				{ L"居中下", "_ctb" },
				{ L"居中左", "_ctl" },
				{ L"居中右", "_ctr" },
				{ L"右上", "_rt" },
				{ L"右下", "_rb" },
				{ L"中间上", "_mt" },
				{ L"中间左", "_ml" },
				{ L"中间右", "_mr" },
				{ L"中间下", "_mb" },
				{ L"全屏", "_fi" },
				{ L"人物头顶", "headon" },
				{ L"人物头顶".."3D", "headon3D" },
			},
			text = "_lt", 
		},
		{
			name = "left",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0,
		},
		{
			name = "top",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0,
		},
		{
			name = "width",
			type = "input_value",
            shadow = { type = "math_number", value = 300,},
			text = 300,
		},
		{
			name = "height",
			type = "input_value",
            shadow = { type = "math_number", value = 100,},
			text = 100,
		},
	},
	category = "Looks", 
	helpUrl = "https://github.com/tatfook/CodeBlockDemos/wiki/Window", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "window",
	func_description = 'window(%s, "%s", %s, %s, %s, %s)',
	ToPython = function(self)
		return string.format('window("""%s""","%s", %s, %s, %s, %s)\n', self:getFieldAsString('mcmlCode'), 
			self:getFieldAsString('alignment'), self:getFieldAsString('left'), self:getFieldAsString('top'), self:getFieldAsString('width'), self:getFieldAsString('height'));
	end,
	ToNPL = function(self)
		return string.format('window([[\n%s\n]],"%s", %s, %s, %s, %s)\n', self:getFieldAsString('mcmlCode'), 
			self:getFieldAsString('alignment'), self:getFieldAsString('left'), self:getFieldAsString('top'), self:getFieldAsString('width'), self:getFieldAsString('height'));
	end,
	examples = {{desc = L"绘图板", canRun = false, code = [=[
wnd = window([[<div>draw something</div>]], "_lt",200,20,300,300);
local ctx = wnd:getContext();
ctx.strokeStyle = "#ff0000"
ctx.lineWidth = 2
ctx.font="System;20;"
ctx:fillText("left click and drag", 10, 30)
ctx.fillStyle = "#80808080"
ctx:fillRect(0,0,ctx:getWidth(),ctx:getHeight())
wnd:registerEvent("onmousedown", function(event)
    ctx:strokeRect(event:pos():x(), event:pos():y(), 1, 1)
    ctx:beginPath()
    ctx:moveTo(event:pos():x(), event:pos():y())
end)
wnd:registerEvent("onmousemove", function(event)
    if(event:LeftButton()) then
        ctx:lineTo(event:pos():x(), event:pos():y())
        ctx:stroke()
        ctx:beginPath()
        ctx:moveTo(event:pos():x(), event:pos():y())
    end
end)
wnd:registerEvent("onmouseup", function(event)
    if(event:button() == "right") then
        wnd:CloseWindow()
    end
end)
]=]},
{desc = "MCML UI", canRun = false, code = [=[
test = {key="hello world"}

function OnClickTest2()
    test.key = document:GetPageCtrl():GetValue("myName")
    cmd("/tip clicked2!"..test.key)
end

function GetTitle()
    return "Enter text:"
end

window([[ 
<script>
function OnClose()
    cmd("/tip clicked!"..Page:GetValue("myName"))
    Page:CloseWindow()
end
</script>
<div style="margin:10px"> 
    <%=GetTitle()%> 
    <input name="myName"  type="text" style="width:90px" value='<%=test.key%>'/> 
    <input type="button" onclick="OnClickTest2" value="click me"/> 
    <input type="button" onclick="OnClose" value="close" style="margin-left:5px"/> 
</div> 
]], "_lt", 10, 10, 300, 100)
]=]},
{desc = "Context2d API", canRun = false, code = [=[
local wnd = window([[<div>draw something</div>]], "_lt",200,20,300,300);
local ctx = wnd:getContext();
ctx.globalAlpha = 0.5
ctx:clearRect()
ctx.fillStyle = "#80808080"
ctx:fillRect(0, 0, ctx.width, ctx.height)
ctx.lineWidth = 2
ctx.font="System;20;"
ctx:save()
ctx:translate(50, 10)
ctx:rotate(-0.2)
ctx:drawImage("preview.jpg", 70, 60, 64, 32)
ctx:strokeText("left click and drag", 10, 30)
ctx:restore()
ctx.strokeStyle = "#ff0000"
ctx:moveTo(0,0)
ctx:lineTo(80,80)
ctx:lineTo(0,80)
ctx:stroke()
ctx:beginPath()
ctx:arc(100, 100, 40, 0, 1.4, true)
ctx:lineTo(190, 120)
ctx:closePath()
ctx:stroke()
ctx.fillStyle = "blue"
ctx:fill()
]=]}
},
},

};
function CodeBlocklyDef_Looks.GetCmds()
	return cmds;
end
