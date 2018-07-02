--[[
Title: CodeHelpData
Author(s): LiXizhi
Date: 2018/6/7
Desc: add help data here
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeHelpData.lua");
local CodeHelpData = commonlib.gettable("MyCompany.Aries.Game.Code.CodeHelpData");
CodeHelpData.LoadParacraftCodeFunctions()
-------------------------------------------------------
]]
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local CodeHelpData = commonlib.gettable("MyCompany.Aries.Game.Code.CodeHelpData");

local all_cmds = {
-- Data
{
	type = "set", 
	message0 = L"设置全局变量%1为%2",
	arg0 = {
		{
			name = "key",
			type = "field_input",
			text = "test", 
		},
		{
			name = "value",
			type = "field_input",
			text = "hello", 
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = true,
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


{
	type = "registerCloneEvent", 
	message0 = L"当演员被复制时%1",
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
	message0 = L"复制角色%1",
	arg0 = {
		{
			name = "input",
			type = "field_input",
			text = "myself",
		},
	},
	category = "Data", color="#cc0000",
	helpUrl = "", 
	canRun = false,
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
	message0 = L"设置角色属性%1为%2",
	arg0 = {
		{
			name = "key",
			type = "field_input",
			text = "test", 
		},
		{
			name = "value",
			type = "field_input",
			text = "hello", 
		},
	},
	category = "Data", 
	color = "#cc0000",
	helpUrl = "", 
	canRun = false,
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
	message0 = L"获取角色属性%1",
	arg0 = {
		{
			name = "key",
			type = "field_input",
			text = "test", 
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

-- Looks
{
	type = "sayAndWait", 
	message0 = L"说 %1 持续 %2 秒",
	arg0 = {
		{
			name = "text",
			type = "field_input",
			text = L"hello!", 
		},
		{
			name = "duration",
			type = "field_number",
			text = 2, 
		},
	},
	category = "Looks", 
	helpUrl = "", 
	canRun = true,
	func_description = 'say("%s", %s)',
	ToNPL = function(self)
		return string.format('say("%s", %s)\n', self:getFieldValue('text'), self:getFieldAsString('duration'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
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
			type = "field_input",
			text = L"hello!", 
		},
	},
	category = "Looks", 
	helpUrl = "", 
	canRun = true,
	func_description = 'say("%s")',
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
			type = "field_input",
			text = L"Start Game!", 
		},
	},
	category = "Looks", 
	helpUrl = "", 
	canRun = true,
	func_description = 'tip("%s")',
	ToNPL = function(self)
		return string.format('tip("%s")\n', self:getFieldValue('text'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
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
			type = "field_number",
			text = 4, 
		},
	},
	category = "Looks", 
	helpUrl = "", 
	canRun = true,
	func_description = 'anim(%d)',
	ToNPL = function(self)
		return string.format('anim(%d)\n', self:getFieldValue('animId'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
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
			type = "field_number",
			text = 10, 
		},
		{
			name = "timeTo",
			type = "field_number",
			text = 1000, 
		},
	},
	category = "Looks", 
	helpUrl = "", 
	canRun = true,
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
			type = "field_number",
			text = 10, 
		},
		{
			name = "timeTo",
			type = "field_number",
			text = 1000, 
		},
	},
	category = "Looks", 
	helpUrl = "", 
	canRun = true,
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
			type = "field_number",
			text = 1, 
		},
	},
	category = "Looks", 
	helpUrl = "", 
	canRun = true,
	func_description = 'playSpeed(%d)',
	ToNPL = function(self)
		return string.format('playSpeed(%d)\n', self:getFieldValue('speed'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
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
			type = "field_number",
			text = 10, 
		},
	},
	category = "Looks", 
	helpUrl = "", 
	canRun = true,
	func_description = 'scale(%d)',
	ToNPL = function(self)
		return string.format('scale(%d)\n', self:getFieldValue('scaleDelta'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
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
			type = "field_number",
			text = 100, 
		},
	},
	category = "Looks", 
	helpUrl = "", 
	canRun = true,
	func_description = 'scaleTo(%d)',
	ToNPL = function(self)
		return string.format('scaleTo(%d)\n', self:getFieldValue('scale'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
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
	type = "focus", 
	message0 = L"观看此角色%1",
	arg0 = {
		{
			name = "name",
			type = "field_input",
			text = "myself", 
		},
	},
	category = "Looks", 
	color = "#cc0000",
	helpUrl = "", 
	canRun = true,
	func_description = 'focus("%s")',
	ToNPL = function(self)
		return string.format('focus("%s")\n', self:getFieldAsString('name'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
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
			type = "field_input",
			text = "12", 
		},
		{
			name = "pitch",
			type = "field_input",
			text = "45", 
		},
		{
			name = "facing",
			type = "field_input",
			text = "90", 
		},
	},
	category = "Looks", 
	color = "#cc0000",
	helpUrl = "", 
	canRun = true,
	func_description = 'camera(%s, %s, %s)',
	ToNPL = function(self)
		return string.format('camera(%s, %s, %s)\n', self:getFieldAsString('dist'), self:getFieldAsString('pitch'), self:getFieldAsString('facing'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
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
	examples = {{desc = L"", canRun = true, code = [[
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
	examples = {{desc = L"", canRun = true, code = [[
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
-- Motion
{
	type = "moveForward", 
	message0 = L"前进%1格 在%2秒内",
	arg0 = {
		{
			name = "dist",
			type = "field_number",
			text = 1, 
		},
		{
			name = "duration",
			type = "field_number",
			text = 0.5, 
		},
	},
	category = "Motion", 
	helpUrl = "", 
	canRun = true,
	func_description = 'moveForward(%d, %d)',
	ToNPL = function(self)
		return string.format('moveForward(%s, %s)\n', self:getFieldAsString('dist'), self:getFieldAsString('duration'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
turn(30);
for i=1, 20 do
    moveForward(0.05)
end
]]}},
},
{
	type = "turn", 
	message0 = L"旋转%1度",
	arg0 = {
		{
			name = "degree",
			type = "field_number",
			text = 15, 
		},
	},
	category = "Motion", 
	helpUrl = "", 
	canRun = true,
	func_description = 'turn(%d)',
	ToNPL = function(self)
		return string.format('turn(%s)\n', self:getFieldAsString('degree'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
turnTo(-60)
for i=1, 100 do
    turn(-3)
end
]]}},
},
{
	type = "turnTo", 
	message0 = L"旋转到%1方向",
	arg0 = {
		{
			name = "degree",
			type = "field_number",
			text = 90, 
		},
	},
	category = "Motion", 
	helpUrl = "", 
	canRun = true,
	func_description = 'turnTo(%d)',
	ToNPL = function(self)
		return string.format('turnTo(%s)\n', self:getFieldAsString('degree'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
turnTo(-60)
wait(1)
turnTo(0)
]]}},
},
{
	type = "turnToTarget", 
	message0 = L"转向%1",
	arg0 = {
		{
			name = "targetName",
			type = "field_input",
			text = "mouse-pointer", 
		},
	},
	category = "Motion", 
	helpUrl = "", 
	canRun = true,
	func_description = 'turnTo("%s")',
	ToNPL = function(self)
		return string.format('turnTo("%s")\n', self:getFieldAsString('targetName'));
	end,
	examples = {{desc = L"转向鼠标,主角,指定角色", canRun = true, code = [[
turnTo("mouse-pointer")
moveForward(1, 1)
turnTo("@p")
moveForward(1, 1)
turnTo("frog")
moveForward(1, 1)
]]}},
},
{
	type = "move", 
	message0 = L"位移%1 %2 %3 在%4秒内",
	arg0 = {
		{
			name = "x",
			type = "field_number",
			text = 1, 
		},
		{
			name = "y",
			type = "field_number",
			text = 0, 
		},
		{
			name = "z",
			type = "field_number",
			text = 0, 
		},
		{
			name = "duration",
			type = "field_number",
			text = 0.5, 
		},
	},
	category = "Motion", 
	helpUrl = "", 
	canRun = true,
	func_description = 'move(%s, %s, %s, %s)',
	ToNPL = function(self)
		return string.format('move(%s, %s, %s, %s)\n', self:getFieldAsString('x'), self:getFieldAsString('y'), self:getFieldAsString('z'), self:getFieldAsString('duration'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
turnTo(0)
move(0.5,1,0, 0.5)
move(1,-1,0, 0.5)
say("jump!", 1)
]]}},
},
{
	type = "moveTo", 
	message0 = L"瞬移到%1 %2 %3",
	arg0 = {
		{
			name = "x",
			type = "field_number",
			text = function()
				local x, y, z = EntityManager.GetPlayer():GetBlockPos();
				return x;
			end, 
		},
		{
			name = "y",
			type = "field_number",
			text = function()
				local x, y, z = EntityManager.GetPlayer():GetBlockPos();
				return y;
			end, 
		},
		{
			name = "z",
			type = "field_number",
			text = function()
				local x, y, z = EntityManager.GetPlayer():GetBlockPos();
				return z;
			end, 
		},
	},
	category = "Motion", 
	helpUrl = "", 
	canRun = true,
	isDynamicNPLCode = true,
	func_description = 'moveTo(%s, %s, %s)',
	ToNPL = function(self)
		return string.format('moveTo(%s, %s, %s)\n', self:getFieldAsString('x'), self:getFieldAsString('y'), self:getFieldAsString('z'));
	end,
	examples = {{desc = L"", canRun = false, code = [[
moveTo(19257,5,19174)
moveTo("mouse-pointer")
moveTo("@p")
moveTo("frog")
]]}},
},
{
	type = "moveToTarget", 
	message0 = L"瞬移到%1",
	arg0 = {
		{
			name = "targetName",
			type = "field_input",
			text = "mouse-pointer", 
		},
	},
	category = "Motion", 
	helpUrl = "", 
	canRun = true,
	func_description = 'moveTo("%s")',
	ToNPL = function(self)
		return string.format('moveTo("%s")\n', self:getFieldValue('targetName'));
	end,
	examples = {{desc = L"瞬移到主角，鼠标，指定角色", canRun = true, code = [[
say("current player", 1)
moveTo("@p")
say("mouse-pointer", 1)
moveTo("mouse-pointer")
say("the frog actor if any", 1)
moveTo("frog")
]]}},
},
{
	type = "walk", 
	message0 = L"行走%1 %2 %3持续%4秒",
	arg0 = {
		{
			name = "x",
			type = "field_number",
			text = 1, 
		},
		{
			name = "y",
			type = "field_number",
			text = 0,
		},
		{
			name = "z",
			type = "field_number",
			text = 0, 
		},
		{
			name = "duration",
			type = "field_number",
			text = 0.5, 
		},
	},
	category = "Motion", 
	helpUrl = "", 
	canRun = true,
	func_description = 'walk(%s, %s, %s, %s)',
	ToNPL = function(self)
		return string.format('walk(%s, %s, %s, %s)\n', self:getFieldAsString('x'), self:getFieldAsString('y'), self:getFieldAsString('z'), self:getFieldAsString('duration'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
walk(1,0) -- x,z
walk(0,1) -- x,z
walk(-1,0,-1) -- x,y,z
]]}},
},

{
	type = "walkForward", 
	message0 = L"向前走%1持续%2秒",
	arg0 = {
		{
			name = "dist",
			type = "field_number",
			text = 1, 
		},
		{
			name = "duration",
			type = "field_number",
			text = 0.5, 
		},
	},
	category = "Motion", 
	helpUrl = "", 
	canRun = true,
	func_description = 'walkForward(%s, %s)',
	ToNPL = function(self)
		return string.format('walkForward(%s, %s)\n', self:getFieldAsString('dist'), self:getFieldAsString('duration'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
turnTo(0)
walkForward(1)
turn(180)
walkForward(1, 0.5)
]]}},
},

{
	type = "velocity", 
	message0 = L"速度%1",
	arg0 = {
		{
			name = "cmd_text",
			type = "field_input",
			text = "~ 5 ~", 
		},
	},
	category = "Motion", 
	helpUrl = "", 
	canRun = true,
	func_description = 'velocity("%s")',
	ToNPL = function(self)
		return string.format('velocity("%s")\n', self:getFieldAsString('cmd_text'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
velocity("~ 10 ~")
wait(0.3)
velocity("add 2 ~ 2")
wait(2)
velocity("0 0 0")
]]}},
},

{
	type = "bounce", 
	message0 = L"反弹",
	arg0 = {},
	category = "Motion", 
	helpUrl = "", 
	canRun = true,
	func_description = 'bounce()',
	ToNPL = function(self)
		return 'bounce()';
	end,
	examples = {{desc = L"遇到方块反弹", canRun = true, code = [[
turnTo(45)
while(true) do
    moveForward(0.02)
    if(isTouching("block")) then
        bounce()
    end
end
]]}},
},

{
	type = "getX", 
	message0 = L"X坐标",
	arg0 = {},
	output = {type = "field_number",},
	category = "Motion", 
	helpUrl = "", 
	canRun = false,
	func_description = 'getX()',
	ToNPL = function(self)
		return 'getX()';
	end,
	examples = {{desc = L"", canRun = true, code = [[
while(true) do
    say(getX())
end
]]}},
},
{
	type = "getY", 
	message0 = L"Y坐标",
	arg0 = {},
	output = {type = "field_number",},
	category = "Motion", 
	helpUrl = "", 
	canRun = false,
	func_description = 'getY()',
	ToNPL = function(self)
		return 'getY()';
	end,
	examples = {{desc = L"", canRun = true, code = [[
while(true) do
    say(getY())
    if(getY()<3) then
        tip("Game Over!")
    end
end
]]}},
},
{
	type = "getZ", 
	message0 = L"Z坐标",
	arg0 = {},
	output = {type = "field_number",},
	category = "Motion", 
	helpUrl = "", 
	canRun = false,
	func_description = 'getZ()',
	ToNPL = function(self)
		return 'getZ()';
	end,
	examples = {{desc = L"", canRun = true, code = [[
while(true) do
    say(getZ())
end
]]}},
},
{
	type = "getPos", 
	message0 = L"角色xyz位置",
	arg0 = {},
	output = {type = "field_number",},
	category = "Motion", 
	helpUrl = "", 
	canRun = false,
	func_description = 'getPos()',
	ToNPL = function(self)
		return 'getPos()';
	end,
	examples = {{desc = L"", canRun = true, code = [[
local x, y, z = getPos()
setPos(x, y+0.5, z)
]]}},
},
{
	type = "setPos", 
	message0 = L"设置角色位置%1 %2 %3",
	arg0 = {
		{
			name = "x",
			type = "field_number",
			text = function()
				local x, y, z = EntityManager.GetPlayer():GetBlockPos();
				return x;
			end, 
		},
		{
			name = "y",
			type = "field_number",
			text = function()
				local x, y, z = EntityManager.GetPlayer():GetBlockPos();
				return y;
			end, 
		},
		{
			name = "z",
			type = "field_number",
			text = function()
				local x, y, z = EntityManager.GetPlayer():GetBlockPos();
				return z;
			end, 
		},
	},
	category = "Motion", 
	helpUrl = "", 
	canRun = true,
	func_description = 'setPos(%s, %s, %s)',
	ToNPL = function(self)
		return string.format('setPos(%s, %s, %s)\n', self:getFieldAsString('x'), self:getFieldAsString('y'), self:getFieldAsString('z'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
local x, y, z = getPos()
setPos(x, y+0.5, z)
]]}},
},
{
	type = "getFacing", 
	message0 = L"方向",
	arg0 = {},
	output = {type = "field_number",},
	category = "Motion", 
	helpUrl = "", 
	canRun = false,
	func_description = 'getFacing()',
	ToNPL = function(self)
		return 'getFacing()';
	end,
	examples = {{desc = L"", canRun = true, code = [[
while(true) do
    say(getFacing())
end
]]}},
},

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

-- Control
{
	type = "wait", 
	message0 = L"等待%1秒",
	arg0 = {
		{
			name = "time",
			type = "field_number",
			text = 1, 
		},
	},
	category = "Control", 
	helpUrl = "", 
	canRun = false,
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
	message0 = L"重复%1次%2",
	arg0 = {
		{
			name = "times",
			type = "field_number",
			text = 10, 
		},
		{
			name = "input",
			type = "input_statement",
			text = "", 
		},
	},
	category = "Control", 
	helpUrl = "", 
	canRun = false,
	func_description = 'for i=1, %d do\\n%send',
	ToNPL = function(self)
		return string.format('for i=1, %d do\n%send\n', self:getFieldValue('times'), self:getFieldAsString('input'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
for i=1, 10 do
    moveForward(0.1)
end
]]}},
},

{
	type = "forever", 
	message0 = L"永远重复%1",
	arg0 = {
		{
			name = "input",
			type = "input_statement",
			text = "", 
		},
	},
	category = "Control", 
	helpUrl = "", 
	canRun = false,
	func_description = 'while(true) do\\n%send',
	ToNPL = function(self)
		return string.format('while(true) do\n%send\n', self:getFieldAsString('input'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
while(true) do
    moveForward(0.01)
end
]]}},
},

{
	type = "if_else", 
	message0 = L"如果%1那么%2否则%3",
	arg0 = {
		{
			name = "expression",
			type = "input_expression",
			text = "", 
		},
		{
			name = "input_true",
			type = "input_statement",
			text = "", 
		},
		{
			name = "input_else",
			type = "input_statement",
			text = "", 
		},
	},
	category = "Control", 
	helpUrl = "", 
	canRun = false,
	func_description = 'if(%s) then\\n%selse\\n%send',
	ToNPL = function(self)
		return string.format('if(%s) then\n%selse\n%send\n', self:getFieldAsString('expression'), self:getFieldAsString('input_true'), self:getFieldAsString('input_else'));
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
	message0 = L"每个%1,%2在%3%4",
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
		{
			name = "input",
			type = "input_statement",
			text = "", 
		},
	},
	category = "Control", 
	helpUrl = "", 
	canRun = false,
	func_description = 'for %s, %s in pairs(%s) do\\n%send',
	ToNPL = function(self)
		return string.format('for %s, %s in pairs(%s) do\n%send\n', self:getFieldAsString('key'), self:getFieldAsString('value'), self:getFieldAsString('data'), self:getFieldAsString('input'));
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
	message0 = L"每个%1,%2在数组%3%4",
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
		{
			name = "input",
			type = "input_statement",
			text = "", 
		},
	},
	category = "Control", 
	helpUrl = "", 
	canRun = false,
	func_description = 'for %s, %s in ipairs(%s) do\\n%send',
	ToNPL = function(self)
		return string.format('for %s, %s in ipairs(%s) do\n%send\n', self:getFieldAsString('i'), self:getFieldAsString('item'), self:getFieldAsString('data'), self:getFieldAsString('input'));
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
	message0 = L"并行执行%1",
	arg0 = {
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
	func_description = 'run(function()\\n%send)',
	ToNPL = function(self)
		return string.format('run(function()\n%send)\n', self:getFieldAsString('input'));
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

-- Sensing
{
	type = "isTouching", 
	message0 = L"是否碰到%1",
	arg0 = {
		{
			name = "input",
			type = "field_input",
			text = "block",
		},
	},
	output = {type = "field_number",},
	category = "Sensing", 
	helpUrl = "", 
	canRun = false,
	func_description = 'isTouching("%s")',
	ToNPL = function(self)
		return string.format('isTouching("%s")\n', self:getFieldAsString('input'));
	end,
	examples = {{desc = L"是否和方块与人物有接触", canRun = true, code = [[
turnTo(45)
while(true) do
    moveForward(0.1)
    if(isTouching(62)) then
        say("grass block!", 1)
    elseif(isTouching("block")) then
        bounce()
    elseif(isTouching("box")) then
        bounce()
    end
end
]]}},
},

{
	type = "distanceTo", 
	message0 = L"到%1的距离",
	arg0 = {
		{
			name = "input",
			type = "field_input",
			text = "mouse-pointer",
		},
	},
	output = {type = "field_number",},
	category = "Sensing", 
	helpUrl = "", 
	canRun = false,
	func_description = 'distanceTo("%s")',
	ToNPL = function(self)
		return string.format('distanceTo("%s")\n', self:getFieldAsString('input'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
while(true) do
    if(distanceTo("mouse-pointer") < 3) then
        say("mouse-pointer")
    elseif(distanceTo("@p") < 10) then
        say("player")
    elseif(distanceTo("@p") > 10) then
        say("nothing")
    end
    wait(0.01)
end
]]}},
},

{
	type = "askAndWait", 
	message0 = L"提问%1并等待回答",
	arg0 = {
		{
			name = "input",
			type = "field_input",
			text = L"你叫什么名字?",
		},
	},
	category = "Sensing", 
	helpUrl = "", 
	canRun = true,
	func_description = 'ask("%s")',
	ToNPL = function(self)
		return string.format('ask("%s")\n', self:getFieldAsString('input'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
ask("what is your name")
say("hello "..tostring(answer), 2)

ask("select your choice", {"choice A", "choice B"})
if(answer == 1) then
    say("you choose A")
elseif(answer == 2) then
    say("you choose B")
end
]]},
{desc = L"关闭对话框", canRun = true, code = [[
run(function()
   wait(3)
   ask()
end)
ask("Please answer in 3 seconds")
say("hello "..tostring(answer), 2)
]]}
},
},

{
	type = "answer", 
	message0 = L"提问的结果",
	arg0 = {},
	output = {type = "field_number",},
	category = "Sensing", 
	helpUrl = "", 
	canRun = false,
	func_description = 'get("answer")',
	ToNPL = function(self)
		return 'get("answer")';
	end,
	examples = {{desc = L"", canRun = true, code = [[
say("<div style='color:#ff0000'>Like A or B?</div>html are supported")
ask("type A or B")
if(answer == "A") then
   say("A is good", 2)
elseif(answer == "B") then
   say("B is fine", 2)
else
   say("i do not understand you", 2)
end
]]}},
},

{
	type = "isKeyPressed", 
	message0 = L"%1键是否按下",
	arg0 = {
		{
			name = "input",
			type = "field_input",
			text = "space",
		},
	},
	output = {type = "field_number",},
	category = "Sensing", 
	helpUrl = "", 
	canRun = false,
	func_description = 'isKeyPressed("%s")',
	ToNPL = function(self)
		return string.format('isKeyPressed("%s")\n', self:getFieldAsString('input'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
say("press left/right key to move me!")
while(true) do
    if(isKeyPressed("left")) then
        move(0, 0.1)
        say("")
    elseif(isKeyPressed("right")) then
        move(0, -0.1)
        say("")
    end
    wait()
end
]]},
{desc = L"", canRun = true, code = [[
say("press any key to continue!")
while(true) do
    if(isKeyPressed("any")) then
        say("you pressed a key!", 2)
    end
    wait()
end
]]},
{desc = L"按键列表", canRun = true, code = [[
-- a,b,c,...z
-- 1,2,3,...9,0
-- f1,f2,...,f12,escape
-- space,left,right,up,down
-- numpad0,numpad1,...,numpad9
-- return,minus,equals,back,tab,
-- lcontrol,lshift,lmenu
]]}
},
},

{
	type = "isMouseDown", 
	message0 = L"鼠标是否按下",
	arg0 = {
	},
	output = {type = "field_number",},
	category = "Sensing", 
	helpUrl = "", 
	canRun = false,
	func_description = 'isMouseDown()',
	ToNPL = function(self)
		return string.format('isMouseDown()\n');
	end,
	examples = {{desc = L"点击任意位置传送", canRun = true, code = [[
say("click anywhere")
while(true) do
    if(isMouseDown()) then
        moveTo("mouse-pointer")
        wait(0.3)
    end
end
]]}},
},

{
	type = "mousePickBlock", 
	message0 = L"鼠标选取",
	arg0 = {
	},
	output = {type = "field_number",},
	category = "Sensing", 
	helpUrl = "", 
	canRun = false,
	func_description = 'mousePickBlock()',
	ToNPL = function(self)
		return string.format('mousePickBlock()\n');
	end,
	examples = {{desc = L"点击任意位置传送", canRun = true, code = [[
while(true) do
    local x, y, z, blockid = mousePickBlock();
    if(x) then
        say(format("%s %s %s :%d", x, y, z, blockid))
    end
end
]]}},
},
{
	type = "getBlock", 
	message0 = L"获取方块id%1 %2 %3",
	arg0 = {
		{
			name = "x",
			type = "field_number",
			text = function()
				local x, y, z = EntityManager.GetPlayer():GetBlockPos();
				return x;
			end, 
		},
		{
			name = "y",
			type = "field_number",
			text = function()
				local x, y, z = EntityManager.GetPlayer():GetBlockPos();
				return y;
			end, 
		},
		{
			name = "z",
			type = "field_number",
			text = function()
				local x, y, z = EntityManager.GetPlayer():GetBlockPos();
				return z;
			end, 
		},
	},
	output = {type = "field_number",},
	category = "Sensing", 
	helpUrl = "", 
	canRun = false,
	func_description = 'getBlock(%s, %s, %s)',
	ToNPL = function(self)
		return string.format('getBlock(%s, %s, %s)\n', self:getFieldAsString('x'), self:getFieldAsString('y'), self:getFieldAsString('z'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
local x,y,z = getPos();
local id = getBlock(x,y-1,z)
say("block below is "..id, 2)
]]}},
},

{
	type = "setBlock", 
	message0 = L"放置方块%1 %2 %3 %4",
	arg0 = {
		{
			name = "x",
			type = "field_number",
			text = function()
				local x, y, z = EntityManager.GetPlayer():GetBlockPos();
				return x;
			end, 
		},
		{
			name = "y",
			type = "field_number",
			text = function()
				local x, y, z = EntityManager.GetPlayer():GetBlockPos();
				return y;
			end, 
		},
		{
			name = "z",
			type = "field_number",
			text = function()
				local x, y, z = EntityManager.GetPlayer():GetBlockPos();
				return z;
			end, 
		},
		{
			name = "blockId",
			type = "field_number",
			text = "62", 
		},
	},
	category = "Sensing", 
	helpUrl = "", 
	canRun = false,
	func_description = 'setBlock(%s, %s, %s, %s)',
	ToNPL = function(self)
		return string.format('setBlock(%s, %s, %s, %s)\n', self:getFieldAsString('x'), self:getFieldAsString('y'), self:getFieldAsString('z'), self:getFieldAsString('blockId'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
local x,y,z = getPos()
local id = getBlock(x,y+2,z)
setBlock(x,y+2,z, 62)
wait(1)
-- 0 to delete block
setBlock(x,y+2,z, 0)
setBlock(x,y+2,z, id)
]]}},
},

{
	type = "timer", 
	message0 = L"计时器",
	arg0 = {
	},
	output = {type = "field_number",},
	category = "Sensing", 
	helpUrl = "", 
	canRun = false,
	func_description = 'getTimer()',
	ToNPL = function(self)
		return string.format('getTimer()');
	end,
	examples = {{desc = L"", canRun = true, code = [[
resetTimer()
while(getTimer()<5) do
    moveForward(0.02)
end
]]}},
},

{
	type = "resetTimer", 
	message0 = L"重置计时器",
	arg0 = {
	},
	category = "Sensing", 
	helpUrl = "", 
	canRun = true,
	func_description = 'resetTimer()',
	ToNPL = function(self)
		return string.format('resetTimer()');
	end,
	examples = {{desc = L"", canRun = true, code = [[
resetTimer()
while(getTimer()<2) do
    wait(0.5);
end
say("hi", 2)
]]}},
},

{
	type = "mode", 
	message0 = L"设置为游戏模式",
	arg0 = {
	},
	category = "Sensing", 
	helpUrl = "", 
	canRun = true,
	func_description = 'cmd("/mode game")',
	ToNPL = function(self)
		return string.format('cmd("/mode game")\n');
	end,
},

{
	type = "modeEdit", 
	message0 = L"设置为编辑模式",
	arg0 = {
	},
	category = "Sensing", 
	helpUrl = "", 
	canRun = true,
	func_description = 'cmd("/mode edit")',
	ToNPL = function(self)
		return string.format('cmd("/mode edit")\n');
	end,
},

-- Sound
{
	type = "playNote", 
	message0 = L"播放音符%1持续%2节拍",
	arg0 = {
		{
			name = "note",
			type = "field_input",
			text = "7",
		},
		{
			name = "beat",
			type = "field_number",
			text = 0.25,
		},
	},
	category = "Sound", 
	helpUrl = "", 
	canRun = true,
	func_description = 'playNote("%s", %s)',
	ToNPL = function(self)
		return string.format('playNote("%s", %s)\n', self:getFieldAsString('note'), self:getFieldAsString('beat'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
while (true) do
    playNote("1", 0.5)
    playNote("2", 0.5)
    playNote("3", 0.5)
end
]]}},
},

{
	type = "playMusic", 
	message0 = L"播放背景音乐%1",
	arg0 = {
		{
			name = "filename",
			type = "field_input",
			text = "1",
		},
	},
	category = "Sound", 
	helpUrl = "", 
	canRun = true,
	func_description = 'playMusic("%s")',
	ToNPL = function(self)
		return string.format('playMusic("%s")\n', self:getFieldAsString('filename'));
	end,
	examples = {{desc = L"播放音乐后停止", canRun = true, code = [[
playMusic("2")
wait(5)
playMusic()
]]}},
},

{
	type = "playSound", 
	message0 = L"播放MP3音乐%1",
	arg0 = {
		{
			name = "filename",
			type = "field_input",
			text = "break",
		},
	},
	category = "Sound", 
	helpUrl = "", 
	canRun = true,
	func_description = 'playSound("%s")',
	ToNPL = function(self)
		return string.format('playSound("%s")\n', self:getFieldAsString('filename'));
	end,
	examples = {{desc = L"播放音乐后停止", canRun = true, code = [[
playSound("break")
wait(1)
playSound("click")
]]}},
},

-- Operators
{
	type = "addition", 
	message0 = L"%1+%2",
	arg0 = {
		{
			name = "left",
			type = "input_expression",
			text = "",
		},
		{
			name = "right",
			type = "input_expression",
			text = "",
		},
	},
	output = {type = "field_number",},
	category = "Operators", 
	helpUrl = "", 
	canRun = false,
	func_description = '(%s) + (%s)',
	ToNPL = function(self)
		return string.format('(%s) + (%s)', self:getFieldAsString('left'), self:getFieldAsString('right'));
	end,
	examples = {{desc = L"数字的加减乘除", canRun = true, code = [[
say("1+1=?")
wait(1)
say(1+1)
]]}},
},

{
	type = "random", 
	message0 = L"随机选择从%1到%2",
	arg0 = {
		{
			name = "from",
			type = "field_number",
			text = "1",
		},
		{
			name = "to",
			type = "field_number",
			text = "10",
		},
	},
	output = {type = "field_number",},
	category = "Operators", 
	helpUrl = "", 
	canRun = false,
	func_description = 'math.random(%s,%s)',
	ToNPL = function(self)
		return string.format('math.random(%s,%s)', self:getFieldAsString('from'), self:getFieldAsString('to'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
while(true) do
    say(math.random(1,100))
    wait(0.5)
end
]]}},
},

{
	type = "equal", 
	message0 = L"%1==%2",
	arg0 = {
		{
			name = "left",
			type = "input_expression",
			text = "",
		},
		{
			name = "right",
			type = "input_expression",
			text = "",
		},
	},
	output = {type = "field_number",},
	category = "Operators", 
	helpUrl = "", 
	canRun = false,
	func_description = '(%s) == (%s)',
	ToNPL = function(self)
		return string.format('(%s) == (%s)', self:getFieldAsString('left'), self:getFieldAsString('right'));
	end,
	examples = {{desc = L"比较两个数值", canRun = true, code = [[
while(true) do
    a = math.random(0,10)
    if(a==0) then
        say(a)
    elseif(a<=3) then
        say(a.."<=3")
    elseif(a>6) then
        say(a..">6")
    else
        say("3<"..a.."<=6")
    end
    wait(2)
end
]]}},
},

{
	type = "and", 
	message0 = L"%1 与 %2",
	arg0 = {
		{
			name = "left",
			type = "input_expression",
			text = "",
		},
		{
			name = "right",
			type = "input_expression",
			text = "",
		},
	},
	output = {type = "field_number",},
	category = "Operators", 
	helpUrl = "", 
	canRun = false,
	func_description = '(%s) and (%s)',
	ToNPL = function(self)
		return string.format('(%s) and (%s)', self:getFieldAsString('left'), self:getFieldAsString('right'));
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
	type = "or", 
	message0 = L"%1 或 %2",
	arg0 = {
		{
			name = "left",
			type = "input_expression",
			text = "",
		},
		{
			name = "right",
			type = "input_expression",
			text = "",
		},
	},
	output = {type = "field_number",},
	category = "Operators", 
	helpUrl = "", 
	canRun = false,
	func_description = '(%s) or (%s)',
	ToNPL = function(self)
		return string.format('(%s) or (%s)', self:getFieldAsString('left'), self:getFieldAsString('right'));
	end,
	examples = {{desc = L"左边或右边满足条件", canRun = true, code = [[
while(true) do
    a = math.random(0,10)
    if(a<=3 or a>6) then
        say(a)
    else
        say("3<"..a.."<=6")
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
			type = "input_expression",
			text = "",
		},
	},
	output = {type = "field_number",},
	category = "Operators", 
	helpUrl = "", 
	canRun = false,
	func_description = '(not %s)',
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
	message0 = L"连接字符串%1和%2",
	arg0 = {
		{
			name = "left",
			type = "field_input",
			text = "hello",
		},
		{
			name = "right",
			type = "field_input",
			text = "world",
		},
	},
	output = {type = "field_number",},
	category = "Operators", 
	helpUrl = "", 
	canRun = false,
	func_description = '("%s".."%s")',
	ToNPL = function(self)
		return string.format('("%s".."%s")', self:getFieldAsString('left'), self:getFieldAsString('right'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
say("hello ".."world".."!!!")
]]}},
},

{
	type = "lengthOf", 
	message0 = L"字符串%1的长度",
	arg0 = {
		{
			name = "left",
			type = "field_input",
			text = "hello",
		},
	},
	output = {type = "field_number",},
	category = "Operators", 
	helpUrl = "", 
	canRun = false,
	func_description = '(#"%s")',
	ToNPL = function(self)
		return string.format('(#"%s")', self:getFieldAsString('left'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
say("length of hello is "..(#"hello"));
]]}},
},

{
	type = "mod", 
	message0 = L"%1模%2",
	arg0 = {
		{
			name = "left",
			type = "field_number",
			text = "66",
		},
		{
			name = "right",
			type = "field_number",
			text = "10",
		},
	},
	output = {type = "field_number",},
	category = "Operators", 
	helpUrl = "", 
	canRun = false,
	func_description = '(%s%%s)',
	ToNPL = function(self)
		return string.format('(%s%%%s)', self:getFieldAsString('left'), self:getFieldAsString('right'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
say("66%10=="..(66%10))
]]}},
},

{
	type = "round", 
	message0 = L"四舍五入取整%1",
	arg0 = {
		{
			name = "left",
			type = "field_number",
			text = 5.5,
		},
	},
	output = {type = "field_number",},
	category = "Operators", 
	helpUrl = "", 
	canRun = false,
	func_description = 'math.floor(%s+0.5)',
	ToNPL = function(self)
		return string.format('math.floor(%s+0.5)', self:getFieldAsString('left'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
while(true) do
    a = math.random(0,10) / 10
    b = math.floor(a+0.5)
    say(a.."=>"..b)
    wait(2)
end
]]}},
},

{
	type = "math.sqrt", 
	message0 = L"开根号%1",
	arg0 = {
		{
			name = "left",
			type = "field_number",
			text = 9,
		},
	},
	output = {type = "field_number",},
	category = "Operators", 
	helpUrl = "", 
	canRun = false,
	func_description = 'math.sqrt(%s)',
	ToNPL = function(self)
		return string.format('math.sqrt(%s)', self:getFieldAsString('left'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
say("math.sqrt(9)=="..math.sqrt(9), 1)
say("math.cos(1)=="..math.cos(1), 1)
say("math.abs(-1)=="..math.abs(1), 1)
]]}},
},
-- end of code items
}

-- all shared extended examples. 
local all_examples = {
{
	desc = L"点击我打招呼", 
	references = {"say", "sayAndWait", "turn", "play"}, 
	canRun = false,
	code = [[
say("Click Me!", 2)
registerClickEvent(function()
    turn(15)
    play(0,1000)
    say("hi!")
end)
]]},
{
	desc = L"显示/隐藏角色", 
	references = {"show", "hide",}, 
	canRun = true,
	code = [[
hide()
wait(1)
show()
]]},
}


function CodeHelpData.LoadParacraftCodeFunctions()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeHelpWindow.lua");
	local CodeHelpWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeHelpWindow");
	CodeHelpWindow.AddCodeHelpItems(all_cmds);
	CodeHelpWindow.AddCodeExamples(all_examples);
end
function CodeHelpData.GetAllCmds()
	return all_cmds;
end