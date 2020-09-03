--[[
Title: CodeBlocklyDef_Motion
Author(s): LiXizhi
Date: 2018/7/5
Desc: define blocks in category of Motion
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyDef/CodeBlocklyDef_Motion.lua");
local CodeBlocklyDef_Motion= commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyDef.CodeBlocklyDef_Motion");
-------------------------------------------------------
]]
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local CodeBlocklyDef_Motion = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyDef.CodeBlocklyDef_Motion");
local cmds = {
-- Motion
{
	type = "moveForward", 
	message0 = L"前进%1格 在%2秒内",
	arg0 = {
		{
			name = "dist",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
            text = 1, 
		},
		{
			name = "duration",
			type = "input_value",
            shadow = { type = "math_number", value = 0.5,},
            text = 0.5, 
		},
	},
	category = "Motion", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "moveForward",
	func_description = 'moveForward(%d, %d)',
	ToNPL = function(self)
		return string.format('moveForward(%s, %s)\n', self:getFieldAsString('dist'), self:getFieldAsString('duration'));
	end,
	examples = {{desc = "", canRun = true, code = [[
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
			type = "input_value",
            shadow = { type = "math_number", value = 15,},
            text = 15, 
		},
	},
	category = "Motion", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "turn",
	func_description = 'turn(%d)',
	ToNPL = function(self)
		return string.format('turn(%s)\n', self:getFieldAsString('degree'));
	end,
	examples = {{desc = "", canRun = true, code = [[
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
			type = "input_value",
            shadow = { type = "math_number", value = 90,},
            text = 90, 
		},
	},
	category = "Motion", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "turnTo",
	func_description = 'turnTo(%d)',
	ToNPL = function(self)
		return string.format('turnTo(%s)\n', self:getFieldAsString('degree'));
	end,
	examples = {{desc = "", canRun = true, code = [[
turnTo(-60)
wait(1)
turnTo(0)
]]},
{desc = L"三轴旋转", canRun = true, code = [[
turnTo(0, 0, 45)
wait(1)
turnTo(0, 45, 0)
wait(1)
turnTo(0, nil, 45)
]]},
{desc = "", canRun = true, code = [[
while(true) do
    setActorValue("pitch", getActorValue("pitch")+2)
    say(getActorValue("pitch"))
    wait()
end
]]},
{desc = "", canRun = true, code = [[
while(true) do
    turnTo(nil, nil, getActorValue("roll")+2)
    wait()
end
]]},
},
},

{
	type = "targetNameType", 
	message0 = "%1",
	arg0 = {
		{
			name = "value",
			type = "field_dropdown",
			options = {
				{ L"鼠标", "mouse-pointer" },
				{ L"摄影机", "camera" },
				{ L"最近的玩家", "@p" },
				{ L"某个角色名", "" },
			},
		},
	},
	hide_in_toolbox = true,
	category = "Motion", 
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
	type = "turnToTarget", 
	message0 = L"转向%1",
	arg0 = {
		{
			name = "targetName",
			type = "input_value",
			shadow = { type = "targetNameType", value = "mouse-pointer",},
			text = "mouse-pointer",
		},
	},
	category = "Motion", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "turnTo",
	func_description = 'turnTo(%s)',
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
]]},
{desc = L"面向摄影机", canRun = true, code = [[
while(true) do
    turnTo("camera")
    wait(0.01)
end
]]},
{desc = L"面向摄影机", canRun = true, code = [[
-- camera yaw and pitch
while(true) do
    turnTo("camera", "camera")
    wait(0.01)
end
]]}
},
},
{
	type = "move", 
	message0 = L"位移%1 %2 %3 在%4秒内",
	arg0 = {
		{
			name = "x",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
            text = 1, 
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
		{
			name = "duration",
			type = "input_value",
            shadow = { type = "math_number", value = 0.5,},
            text = 0.5, 
		},
	},
	category = "Motion", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "move",
	func_description = 'move(%s, %s, %s, %s)',
	ToNPL = function(self)
		return string.format('move(%s, %s, %s, %s)\n', self:getFieldAsString('x'), self:getFieldAsString('y'), self:getFieldAsString('z'), self:getFieldAsString('duration'));
	end,
	examples = {{desc = "", canRun = true, code = [[
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
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = function()
				local x, y, z = EntityManager.GetPlayer():GetBlockPos();
				return x;
			end, 
		},
		{
			name = "y",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = function()
				local x, y, z = EntityManager.GetPlayer():GetBlockPos();
				return y;
			end, 
		},
		{
			name = "z",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
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
	previousStatement = true,
	nextStatement = true,
	funcName = "moveTo",
	func_description = 'moveTo(%s, %s, %s)',
	ToNPL = function(self)
		return string.format('moveTo(%s, %s, %s)\n', self:getFieldAsString('x'), self:getFieldAsString('y'), self:getFieldAsString('z'));
	end,
	examples = {{desc = "", canRun = false, code = [[
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
			type = "input_value",
			shadow = { type = "targetNameType", value = "mouse-pointer",},
			text = "mouse-pointer",
		},
	},
	category = "Motion", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "moveTo",
	func_description = 'moveTo(%s)',
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
]]},
{desc = L"瞬移到角色的某个骨骼", canRun = false, code = [[
-- block position
moveTo("myActorName")
-- float position
moveTo("myActorName::")
-- bone position
moveTo("myActorName::bone_name")
]]}
},
},
{
	type = "walk", 
	message0 = L"行走%1 %2 %3持续%4秒",
	arg0 = {
		{
			name = "x",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
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
		{
			name = "duration",
			type = "input_value",
            shadow = { type = "math_number", value = -1,},
			text = -1, 
		},
	},
	category = "Motion", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "walk",
	func_description = 'walk(%s, %s, %s, %s)',
	ToNPL = function(self)
		return string.format('walk(%s, %s, %s, %s)\n', self:getFieldAsString('x'), self:getFieldAsString('y'), self:getFieldAsString('z'), self:getFieldAsString('duration'));
	end,
	examples = {{desc = "", canRun = true, code = [[
walk(1,0) -- x,z
walk(0,1) -- x,z
walk(-1,0,-1) -- x,y,z
walk(0,0,0,-1) -- walk and stop
]]},
{desc = L"精准行走模式", canRun = true, code = [[
walk(0.1, 0, 0, 0.1, true)
walk(0,0,0) -- stop
]]}
},
},

{
	type = "walkForward", 
	message0 = L"向前走%1持续%2秒",
	arg0 = {
		{
			name = "dist",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
		{
			name = "duration",
			type = "input_value",
            shadow = { type = "math_number", value = 0.5,},
			text = 0.5, 
		},
	},
	category = "Motion", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "walkForward",
	func_description = 'walkForward(%s, %s)',
	ToNPL = function(self)
		return string.format('walkForward(%s, %s)\n', self:getFieldAsString('dist'), self:getFieldAsString('duration'));
	end,
	examples = {{desc = "", canRun = true, code = [[
turnTo(0)
walkForward(1)
turn(180)
walkForward(1, 0.5)
]]},
{desc = L"恢复默认物理仿真", canRun = true, code = [[
play(0,1000, true)
moveForward(1, 0.5)
walkForward(0)
]]},
{desc = L"精准行走模式", canRun = true, code = [[
walkForward(0.1, 0.1, true)
]]}
},
},

{
	type = "attachTo", 
	message0 = L"固定到%1的骨骼%2上",
	arg0 = {
		{
			name = "targetName",
			type = "input_value",
			shadow = { type = "text", value = L"父角色",},
			text = L"父角色",
		},
		{
			name = "boneName",
			type = "input_value",
			shadow = { type = "text", value = "",},
			text = "",
		},
	},
	category = "Motion", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "attachTo",
	func_description = 'attachTo(%s,%s)',
	ToNPL = function(self)
		return string.format('attachTo("%s","%s")\n', self:getFieldValue('targetName'), self:getFieldValue('boneName'));
	end,
	examples = {{desc = "", canRun = false, code = [[
attachTo("parent", "R_Hand")
-- with position offset
attachTo("parent", "R_Hand", {0,1,1})
-- with offset and rotation {roll, pitch, roll}
attachTo("parent", "R_Hand", {0,1,1}, {0, 0, 1.57})
-- without parent bone's rotation
attachTo("parent", "R_Hand", nil, nil, false)
-- detach
attachTo(nil)
-- properties
parent = getActorValue("parent")
setActorValue("parentOffset", "0, 2, 0")
setActorValue("parentRot", {0, 3.14, 0})
]]},
},
},

{
	type = "velocity", 
	message0 = L"速度%1",
	arg0 = {
		{
			name = "cmd_text",
            type = "input_value",
            shadow = { type = "text", value = "~ 5 ~",},

			text = "~ 5 ~", 
		},
	},
	category = "Motion", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	-- hide_in_toolbox = true, -- deprecated, use SetActorValue("velocity") instead
	nextStatement = true,
	funcName = "velocity",
	func_description = 'velocity(%s)',
	ToNPL = function(self)
		return string.format('velocity("%s")\n', self:getFieldAsString('cmd_text'));
	end,
	examples = {{desc = "", canRun = true, code = [[
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
	previousStatement = true,
	nextStatement = true,
	funcName = "bounce",
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
	funcName = "getX",
	func_description = 'getX()',
	ToNPL = function(self)
		return 'getX()';
	end,
	examples = {{desc = "", canRun = true, code = [[
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
	funcName = "getY",
	func_description = 'getY()',
	ToNPL = function(self)
		return 'getY()';
	end,
	examples = {{desc = "", canRun = true, code = [[
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
	funcName = "getZ",
	func_description = 'getZ()',
	ToNPL = function(self)
		return 'getZ()';
	end,
	examples = {{desc = "", canRun = true, code = [[
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
	funcName = "getPos",
	func_description = 'getPos()',
	ToNPL = function(self)
		return 'getPos()';
	end,
	examples = {{desc = "", canRun = true, code = [[
local x, y, z = getPos()
setPos(x, y+0.5, z)
]]},
{desc = "", canRun = true, code = [[
local x, y, z = getPos("actorName")
setPos(x, y+0.5, z)
]]}
},
},
{
	type = "setPos", 
	message0 = L"设置角色位置%1 %2 %3",
	arg0 = {
		{
			name = "x",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = function()
				local x, y, z = EntityManager.GetPlayer():GetBlockPos();
				return x;
			end, 
		},
		{
			name = "y",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = function()
				local x, y, z = EntityManager.GetPlayer():GetBlockPos();
				return y;
			end, 
		},
		{
			name = "z",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = function()
				local x, y, z = EntityManager.GetPlayer():GetBlockPos();
				return z;
			end, 
		},
	},
	category = "Motion", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "setPos",
	func_description = 'setPos(%s, %s, %s)',
	ToNPL = function(self)
		return string.format('setPos(%s, %s, %s)\n', self:getFieldAsString('x'), self:getFieldAsString('y'), self:getFieldAsString('z'));
	end,
	examples = {{desc = "", canRun = true, code = [[
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
	funcName = "getFacing",
	func_description = 'getFacing()',
	ToNPL = function(self)
		return 'getFacing()';
	end,
	examples = {{desc = "", canRun = true, code = [[
while(true) do
    say(getFacing())
end
]]},
{desc = "", canRun = true, code = [[
say(getFacing("someActorName"))
]]}
},
},

};
function CodeBlocklyDef_Motion.GetCmds()
	return cmds;
end
