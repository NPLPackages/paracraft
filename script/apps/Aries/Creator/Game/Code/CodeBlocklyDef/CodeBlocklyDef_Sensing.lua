--[[
Title: CodeBlocklyDef_Sensing
Author(s): LiXizhi
Date: 2018/7/5
Desc: define blocks in category of Sensing
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyDef/CodeBlocklyDef_Sensing.lua");
local CodeBlocklyDef_Sensing= commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyDef.CodeBlocklyDef_Sensing");
-------------------------------------------------------
]]
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local CodeBlocklyDef_Sensing = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyDef.CodeBlocklyDef_Sensing");
local cmds = {
-- Sensing
{
	type = "isTouchingOptions", 
	message0 = "%1",
	arg0 = {
		{
			name = "value",
			type = "field_dropdown",
			options = {
				{ L"方块", "block" },
				{ L"附近玩家", "@a" },
				{ L"某个方块id", "62" },
				{ L"某个角色名", "" },
			},
		},
	},
	hide_in_toolbox = true,
	category = "Sensing", 
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
	type = "isTouching", 
	message0 = L"是否碰到%1",
	arg0 = {
		{
			name = "input",
			type = "input_value",
			shadow = { type = "text", typeOptions = "isTouchingOptions", value = "block",},
			text = "block",
		},
	},
	output = {type = "field_number",},
	category = "Sensing", 
	helpUrl = "", 
	canRun = false,
	funcName = "isTouching",
	func_description = 'isTouching(%s)',
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
]]},
{desc = "", canRun = true, code = [[
local boxActor = getActor("box")
if(isTouching(boxActor)) then
    say("touched")
end
]]}
},
},

{
	type = "setName", 
	message0 = L"设置名字为%1",
	arg0 = {
		{
			name = "name",
			type = "input_value",
            shadow = { type = "text", value = "frog",},
			text = "frog",
		},
	},
	category = "Sensing", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'setActorValue("name", %s)',
	ToNPL = function(self)
		return string.format('setActorValue("name", "%s")\n', self:getFieldAsString('name'));
	end,
	examples = {{desc = L"复制的对象也可有不同的名字", canRun = true, code = [[
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
	type = "setPhysicsRaidus", 
	message0 = L"设置物理半径%1",
	arg0 = {
		{
			name = "radius",
			type = "input_value",
            shadow = { type = "math_number", value = 0.25,},
			text = 0.25,
		},
	},
	category = "Sensing", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	func_description = 'setActorValue("physicsRadius", %s)',
	ToNPL = function(self)
		return string.format('setActorValue("physicsRadius", %s)\n', self:getFieldAsString('radius'));
	end,
	examples = {{desc = "", canRun = true, code = [[
cmd("/show boundingbox")
setBlock(getX(), getY()+2, getZ(), 62)
setActorValue("physicsRadius", 0.5)
setActorValue("physicsHeight", 2)
move(0, 0.2, 0)
if(isTouching("block")) then
    say("touched!", 1)
end
setBlock(getX(), getY()+2, getZ(), 0)
wait(2)
move(0, -0.2, 0)
cmd("/hide boundingbox")
]]}},
},

{
	type = "setPhysicsHeight", 
	message0 = L"设置物理高度%1",
	arg0 = {
		{
			name = "height",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1,
		},
	},
	category = "Sensing", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	func_description = 'setActorValue("physicsHeight", %s)',
	ToNPL = function(self)
		return string.format('setActorValue("physicsHeight", %s)\n', self:getFieldAsString('height'));
	end,
	examples = {{desc = "", canRun = true, code = [[
cmd("/show boundingbox")
setBlock(getX(), getY()+2, getZ(), 62)
setActorValue("physicsRadius", 0.5)
setActorValue("physicsHeight", 2)
move(0, 0.2, 0)
if(isTouching("block")) then
    say("touched!", 1)
end
setBlock(getX(), getY()+2, getZ(), 0)
wait(2)
move(0, -0.2, 0)
cmd("/hide boundingbox")
]]}},
},

{
	type = "registerCollisionEvent", 
	message0 = L"当碰到%1时",
	message1 = L"%1",
	arg0 = {
		{
			name = "name",
			type = "input_value",
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
	category = "Sensing", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "registerCollisionEvent",
	func_description = 'registerCollisionEvent(%s, function(actor)\\n%send)',
	ToPython = function(self)
		local input = self:getFieldAsString('input')
		if input == '' then
			input = 'pass'
		end
		return string.format('def registerCollisionEvent_func(msg):\n    %s\nregisterCollisionEvent("%s", registerCollisionEvent_func)\n', input, self:getFieldAsString('name'));
	end,
	ToNPL = function(self)
		return string.format('registerCollisionEvent("%s", function(actor)\n%send)\n', self:getFieldAsString('name'), self:getFieldAsString('input'));
	end,
	examples = {
	{desc = L"某个角色", canRun = true, code = [[
broadcastCollision()
registerCollisionEvent("frog", function(actor)
    local data = actor:GetActorValue("some_data")
end)
]]},

{desc = L"任意角色", canRun = true, code = [[
broadcastCollision()
registerCollisionEvent("", function(actor)
    local data = actor:GetActorValue("some_data")
    if(data == 1) then
        say("collide with 1")
    end
end)
]]},

{desc = L"某个组Id", canRun = true, code = [[
broadcastCollision()
setActorValue("groupId", 3);
registerCollisionEvent(3, function(actor)
    say("collide with group 3")
end)
]]},
},
},

{
	type = "broadcastCollision", 
	message0 = L"广播碰撞消息",
	arg0 = {},
	category = "Sensing", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "broadcastCollision",
	func_description = 'broadcastCollision()',
	ToNPL = function(self)
		return 'broadcastCollision()\n';
	end,
	examples = {{desc = "", canRun = true, code = [[
broadcastCollision()
registerCollisionEvent("frog", function()
end)
]]}},
},

{
	type = "distanceTo", 
	message0 = L"到%1的距离",
	arg0 = {
		{
			name = "input",
			type = "input_value",
			shadow = { type = "targetNameType", value = "mouse-pointer",},
			text = "mouse-pointer",
		},
	},
	output = {type = "field_number",},
	category = "Sensing", 
	helpUrl = "", 
	canRun = false,
	funcName = "distanceTo",
	func_description = 'distanceTo(%s)',
	ToNPL = function(self)
		return string.format('distanceTo("%s")\n', self:getFieldAsString('input'));
	end,
	examples = {{desc = "", canRun = true, code = [[
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
]]},
{desc = "", canRun = true, code = [[
if(distanceTo(getActor("box")) < 3) then
    say("box")
end
]]}
},
},

{
	type = "calculatePushOut", 
	message0 = L"计算物理碰撞距离%1,%2,%3",
	arg0 = {
		{
			name = "dx",
			type = "input_value",
			shadow = { type = "math_number", value = 0,},
			text = 0,
		},
		{
			name = "dy",
			type = "input_value",
			shadow = { type = "math_number", value = 0,},
			text = 0,
		},
		{
			name = "dz",
			type = "input_value",
			shadow = { type = "math_number", value = 0,},
			text = 0,
		},
	},
	output = {type = "field_number",},
	category = "Sensing", 
	helpUrl = "", 
	canRun = false,
	funcName = "calculatePushOut",
	func_description = 'calculatePushOut(%s, %s, %s)',
	ToNPL = function(self)
		return string.format('calculatePushOut(%s, %s, %s)\n', self:getFieldAsString('dx'), self:getFieldAsString('dy'), self:getFieldAsString('dz'));
	end,
	examples = {{desc = L"保证不与刚体重叠", canRun = false, code = [[
while(true) do
   local dx, dy, dz = calculatePushOut()
   if(dx~=0 or dy~=0 or dz~=0) then
      move(dx, dy, dz, 0.1);
   end
   wait()
end
]]},
{desc = L"尝试移动一段距离", canRun = false, code = [[
for i=1, 100 do
   local dx, dy, dz = calculatePushOut(0.1, 0, 0)
   if(dx~=0 or dy~=0 or dz~=0) then
      move(dx, dy, dz, 0.1);
   end
   wait()
end
]]}
},
},


{
	type = "askAndWait", 
	message0 = L"提问%1并等待回答",
	message1 = L"选项%1",
	arg0 = {
		{
			name = "input",
			type = "input_value",
            shadow = { type = "text", value = L"你叫什么名字?",},
			text = L"你叫什么名字?",
		},
	},
	arg1 = {
		{
			name = "choices",
			type = "input_value",
            shadow = { type = "functionParams", value = "",},
			text = "",
		},
	},
	category = "Sensing", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "ask",
	func_description = 'ask(%s, %s)',
	ToPython = function(self)
		return string.format('result = ask("%s")\n', self:getFieldAsString('input'));
	end,
	ToNPL = function(self)
		return string.format('local result = ask("%s")\n', self:getFieldAsString('input'));
	end,
	examples = {{desc = "", canRun = true, code = [[
ask("what is your name")
say("hello "..tostring(answer), 2)

ask("select your choice", {"choice A", "choice B"})
if(answer == 1) then
    say("you choose A")
elseif(answer == 2) then
    say("you choose B")
end

]]},
{desc = "", canRun = true, code = [[
local name = ask("what is your name?")
say("hello "..tostring(name), 2)
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
	message0 = L"回答",
	arg0 = {},
	output = {type = "field_number",},
	category = "Sensing", 
	helpUrl = "", 
	canRun = false,
	funcName = "answer",
	func_description = 'get("answer")',
	ToNPL = function(self)
		return 'get("answer")';
	end,
	examples = {{desc = "", canRun = true, code = [[
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
	type = "isKeyPressedOptions", 
	message0 = "%1",
	arg0 = {
		{
			name = "value",
			type = "field_dropdown",
			options = {
				{ L"空格", "space" },{ L"左", "left" },{ L"右", "right" },{ L"上", "up" },{ L"下", "down" },{ "ESC", "escape" },
				{"a","a"},{"b","b"},{"c","c"},{"d","d"},{"e","e"},{"f","f"},{"g","g"},{"h","h"},
				{"i","i"},{"j","j"},{"k","k"},{"l","l"},{"m","m"},{"n","n"},{"o","o"},{"p","p"},
				{"q","q"},{"r","r"},{"s","s"},{"t","t"},{"u","u"},{"v","v"},{"w","w"},{"x","x"},
				{"y","y"},{"z","z"},
				{"1","1"},{"2","2"},{"3","3"},{"4","4"},{"5","5"},{"6","6"},{"7","7"},{"8","8"},{"9","9"},{"0","0"},
				{"f1","f1"},{"f2","f2"},{"f3","f3"},{"f4","f4"},{"f5","f5"},{"f6","f6"},{"f7","f7"},{"f8","f8"},{"f9","f9"},{"f10","f10"},{"f11","f11"},{"f12","f12"},
				{ L"回车", "return" },{ "-", "minus" },{ "+", "equal" },{ "back", "back" },{ "tab", "tab" },
				{ "lctrl", "lcontrol" },{ "lshift", "lshift" },{ "lalt", "lmenu" },
				{"num0","numpad0"},{"num1","numpad1"},{"num2","numpad2"},{"num3","numpad3"},{"num4","numpad4"},{"num5","numpad5"},{"num6","numpad6"},{"num7","numpad7"},{"num8","numpad8"},{"num9","numpad9"},
			},

		},
	},
	hide_in_toolbox = true,
	category = "Sensing", 
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
	type = "isKeyPressed", 
	message0 = L"%1键是否按下",
	arg0 = {
		{
			name = "input",
			type = "input_value",
			shadow = { type = "isKeyPressedOptions", value = "space",},
		},
	},
	output = {type = "field_number",},
	category = "Sensing", 
	helpUrl = "", 
	canRun = false,
	funcName = "isKeyPressed",
	func_description = 'isKeyPressed(%s)',
	ToNPL = function(self)
		return string.format('isKeyPressed("%s")', self:getFieldAsString('input'));
	end,
	examples = {{desc = "", canRun = true, code = [[
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
{desc = "", canRun = true, code = [[
say("press any key to continue!")
while(true) do
    if(isKeyPressed("any")) then
        say("you pressed a key!", 2)
    end
    wait()
end
]]},
{desc = L"按键列表", canRun = true, code = [[

-- numpad0,numpad1,...,numpad9

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
	funcName = "isMouseDown",
	func_description = 'isMouseDown()',
	ToNPL = function(self)
		return string.format('isMouseDown()');
	end,
	examples = {{desc = L"点击任意位置传送", canRun = true, code = [[
say("click anywhere")
while(true) do
    if(isMouseDown()) then
        moveTo("mouse-pointer")
        wait(0.3)
    elseif(isMouseDown(2)) then
        tip("right mouse button down")
        wait(0.3)
    end
end
]]}},
},

{
	type = "getMousePoint", 
	message0 = L"鼠标XY",
	arg0 = {
	},
	output = {type = "field_number",},
	category = "Sensing", 
	helpUrl = "", 
	canRun = false,
	funcName = "getMousePoint",
	func_description = 'getMousePoint()',
	ToPython = function(self)
		return string.format('x, y = getMousePoint()\n');
	end,
	ToNPL = function(self)
		return string.format('local x, y = getMousePoint()\n');
	end,
	examples = {{desc = "", canRun = true, code = [[
-- x in [-500, 500]
local x, y = getMousePoint()
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
	funcName = "mousePickBlock",
	func_description = 'mousePickBlock()',
	ToPython = function(self)
		return string.format('x, y, z, blockid = mousePickBlock()\n');
	end,
	ToNPL = function(self)
		return string.format('local x, y, z, blockid = mousePickBlock()\n');
	end,
	examples = {{desc = L"点击任意位置传送", canRun = true, code = [[
while(true) do
    local x, y, z, blockid, side = mousePickBlock();
    if(x) then
        say(format("%s %s %s :%d", x, y, z, blockid))
    end
end
]]}},
},
{
	type = "getBlock", 
	message0 = L"获取方块%1 %2 %3",
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
	output = {type = "field_number",},
	category = "Sensing", 
	helpUrl = "", 
	canRun = false,
	funcName = "getBlock",
	func_description = 'getBlock(%s, %s, %s)',
	ToNPL = function(self)
		return string.format('getBlock(%s, %s, %s)', self:getFieldAsString('x'), self:getFieldAsString('y'), self:getFieldAsString('z'));
	end,
	examples = {{desc = "", canRun = true, code = [[
local x,y,z = getPos();
local id = getBlock(x,y-1,z)
say("block below is "..id, 2)
]]},
{desc = L"获取方块的Data数据", canRun = true, code = [[
local x,y,z = getPos();
local id, data = getBlock(x,y-1,z)
]]},
{desc = L"获取方块的Entity数据", canRun = true, code = [[
local x,y,z = getPos();
local entity = getBlockEntity(x,y,z)
if(entity) then
    say(entity.class_name, 1)
    if(entity.class_name == "EntityBlockModel") then
        say(entity:GetModelFile())
    end
end
]]},
},
},

{
	type = "setBlock", 
	message0 = L"放置方块%1 %2 %3 %4",
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
		{
			name = "blockId",
			type = "input_value",
            shadow = { type = "math_number", value = 62,},
			text = "62", 
		},
	},
	category = "Sensing", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "setBlock",
	func_description = 'setBlock(%s, %s, %s, %s)',
	ToNPL = function(self)
		return string.format('setBlock(%s, %s, %s, %s)\n', self:getFieldAsString('x'), self:getFieldAsString('y'), self:getFieldAsString('z'), self:getFieldAsString('blockId'));
	end,
	examples = {{desc = "", canRun = true, code = [[
local x,y,z = getPos()
local id = getBlock(x,y+2,z)
setBlock(x,y+2,z, 62)
wait(1)
-- 0 to delete block
setBlock(x,y+2,z, 0)
setBlock(x,y+2,z, id)
-- with additional block data
local data = 0
setBlock(x,y+2,z, id, data)
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
	funcName = "getTimer",
	func_description = 'getTimer()',
	ToNPL = function(self)
		return string.format('getTimer()');
	end,
	examples = {{desc = "", canRun = true, code = [[
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
	previousStatement = true,
	nextStatement = true,
	funcName = "resetTimer",
	func_description = 'resetTimer()',
	ToNPL = function(self)
		return string.format('resetTimer()');
	end,
	examples = {{desc = "", canRun = true, code = [[
resetTimer()
while(getTimer()<2) do
    wait(0.5);
end
say("hi", 2)
]]}},
},

{
	type = "gameModeOptions", 
	message0 = "%1",
	arg0 = {
		{
			name = "value",
			type = "field_dropdown",
			options = {
				{ L"游戏模式", "game" },{ L"编辑模式", "edit" },
			},
		},
	},
	hide_in_toolbox = true,
	category = "Sensing", 
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
	type = "setMode", 
	message0 = L"设置模式%1",
	arg0 = {
		{
			name = "input",
			type = "input_value",
            shadow = { type = "gameModeOptions", value = "game",},
		},
	},
	category = "Sensing", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	func_description = 'cmd("/mode", %s)',
	ToNPL = function(self)
		return string.format('cmd("/mode", "%s")\n', self:getFieldAsString('input'));
	end,
	examples = {{desc = "", canRun = true, code = [[
if(GameLogic.GetGameMode() == "edit") then
    cmd("/mode", "game")
end
]]}},
},

{
	type = "getMode", 
	message0 = L"当前游戏模式",
	arg0 = {
	},
	output = {type = "null",},
	category = "Sensing", 
	helpUrl = "", 
	canRun = false,
	funcName = "GetGameMode",
	func_description = 'GameLogic.GetGameMode()',
	ToNPL = function(self)
		return string.format('GameLogic.GetGameMode()');
	end,
	examples = {{desc = L"防作弊密码锁", canRun = true, code = [[
if(GameLogic.GetGameMode() == "edit") then
    cmd("/mode", "game")
end
local hasPassword
while(not hasPassword) do
    if(GameLogic.GetGameMode() == "edit") then
        cmd("/mode", "game")
        run(function()
            ask("Enter password: 1234")
            if(answer == "1234") then
                hasPassword = true;
                cmd("/mode", "edit")
            end
        end)
    end
    wait(1)
end
]]}},
},

};
function CodeBlocklyDef_Sensing.GetCmds()
	return cmds;
end
