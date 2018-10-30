--[[
Title: CodeBlocklyDef_Motion
Author(s): leio
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
	func_description = 'turnTo(%d)',
	ToNPL = function(self)
		return string.format('turnTo(%s)\n', self:getFieldAsString('degree'));
	end,
	examples = {{desc = "", canRun = true, code = [[
turnTo(-60)
wait(1)
turnTo(0)
]]}},
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
]]}},
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
]]}},
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
            shadow = { type = "math_number", value = 0.5,},
			text = 0.5, 
		},
	},
	category = "Motion", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	func_description = 'walk(%s, %s, %s, %s)',
	ToNPL = function(self)
		return string.format('walk(%s, %s, %s, %s)\n', self:getFieldAsString('x'), self:getFieldAsString('y'), self:getFieldAsString('z'), self:getFieldAsString('duration'));
	end,
	examples = {{desc = "", canRun = true, code = [[
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
	func_description = 'walkForward(%s, %s)',
	ToNPL = function(self)
		return string.format('walkForward(%s, %s)\n', self:getFieldAsString('dist'), self:getFieldAsString('duration'));
	end,
	examples = {{desc = "", canRun = true, code = [[
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
            type = "input_value",
            shadow = { type = "text", value = "~ 5 ~",},

			text = "~ 5 ~", 
		},
	},
	category = "Motion", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
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
	func_description = 'getPos()',
	ToNPL = function(self)
		return 'getPos()';
	end,
	examples = {{desc = "", canRun = true, code = [[
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
	func_description = 'getFacing()',
	ToNPL = function(self)
		return 'getFacing()';
	end,
	examples = {{desc = "", canRun = true, code = [[
while(true) do
    say(getFacing())
end
]]}},
},

};
function CodeBlocklyDef_Motion.GetCmds()
	return cmds;
end
