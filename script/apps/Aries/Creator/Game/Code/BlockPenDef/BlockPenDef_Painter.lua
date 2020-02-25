--[[
Title: Block Pen
Author(s): LiXizhi
Date: 2020/2/16
Desc: 
use the lib:
-------------------------------------------------------
-------------------------------------------------------
]]
NPL.export({
-----------------------
{
	type = "setPenSpeed", 
	message0 = "绘图速度 %1",
	arg0 = {
		{
			name = "speed",
			type = "input_value",
			shadow = { type = "math_number", value = 2,},
			text = 2, 
		},
	},
	category = "canvas", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'setPenSpeed(%s)',
	ToNPL = function(self)
		return string.format('setPenSpeed(%s)\n', self:getFieldValue('speed'));
	end,
	examples = {{desc = "", canRun = false, code = [[
]]}},
},
-----------------------
{
	type = "createCanvas", 
	message0 = "创建绘图板%1, %2x%3, %4",
	arg0 = {
		{
			name = "mode",
			type = "field_dropdown",
			options = {
				{ "xy", "xy" },
				{ "xz", "xz" },
			},
		},
		{
			name = "width",
			type = "input_value",
			shadow = { type = "math_number", value = 200,},
			text = 200, 
		},
		{
			name = "height",
			type = "input_value",
			shadow = { type = "math_number", value = 200,},
			text = 200, 
		},
		{
			name = "blockId",
			type = "field_dropdown",
			options = {
				{ "不变", "-1" },
				{ "彩色方块", "10" },
				{ "空气", "0" },
			},
			text = "10",
		},
	},
	category = "canvas", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'createCanvas("%s", %s, %s, %s)',
	ToNPL = function(self)
		return string.format('createCanvas("%s", %s, %s, %s)\n', self:getFieldValue('mode'), self:getFieldValue('width'), self:getFieldValue('height'), self:getFieldValue('blockId'));
	end,
	examples = {{desc = "在当前角色位置创建画板", canRun = false, code = [[
createCanvas("xz", 200, 200, -1)
for i=1, 4 do
    drawLine("forward", 5)    
    turnPen("right", 90) 
end
createCanvas("xy", 200, 200, -1)
setPenColor(0x00ff00)
for i=1, 4 do
    drawLine("forward", 5)    
    turnPen("right", 90) 
end
]]}},
},
-----------------------
{
	type = "resetPen", 
	message0 = "重置画笔",
	arg0 = {
	},
	category = "canvas", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'resetPen()',
	ToNPL = function(self)
		return string.format('resetPen()\n');
	end,
	examples = {{desc = "", canRun = false, code = [[
]]}},
},
-----------------------
{
	type = "drawLine", 
	message0 = "%1 %2格",
	arg0 = {
		{
			name = "style",
			type = "field_dropdown",
			options = {
				{ "向前画", "forward" },
				{ "向后画", "backward" },
			},
		},
		{
			name = "value",
			type = "input_value",
			shadow = { type = "math_number", value = 5,},
			text = 5, 
		},
	},
	category = "painter", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'drawLine("%s", %s)',
	ToNPL = function(self)
		return string.format('drawLine("%s", %s)\n', self:getFieldValue('style'), self:getFieldValue('value'));
	end,
	examples = {{desc = "正方形", canRun = false, code = [[
for i=1, 4 do
    drawLine("forward", 5)    
    turnPen("right", 90) 
end
]]}},
},
-----------------------
{
	type = "turnPen", 
	message0 = "%1 %2度",
	arg0 = {
		{
			name = "style",
			type = "field_dropdown",
			options = {
				{ "左转", "left" },
				{ "右转", "right" },
			},
		},
		{
			name = "value",
			type = "input_value",
			shadow = { type = "math_number", value = 90,},
			text = 90, 
		},
	},
	category = "painter", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'turnPen("%s", %s)',
	ToNPL = function(self)
		return string.format('turnPen("%s", %s)\n', self:getFieldValue('style'), self:getFieldValue('value'));
	end,
	examples = {{desc = "五角星", canRun = false, code = [[
for i=1, 5 do
    drawLine("forward", 16)
    turnPen("right", 144)  
end
]]}},
},
-----------------------
{
	type = "turnPenTo", 
	message0 = "旋转到 %1",
	arg0 = {
		{
			name = "value",
			type = "input_value",
			shadow = { type = "math_number", value = 90,},
			text = 90, 
		},
	},
	category = "painter", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'turnPenTo(%s)',
	ToNPL = function(self)
		return string.format('turnPenTo(%s)\n', self:getFieldValue('value'));
	end,
	examples = {{desc = "", canRun = false, code = [[
]]}},
},
-----------------------
{
	type = "penColorList", 
	message0 = "%1",
	arg0 = {
		{
			name = "value",
			type = "field_dropdown",
			options = {
				{ "红", "0xff0000" },
				{ "绿", "0x00ff00" },
				{ "兰", "0x0000ff" },
				{ "黑", "0x000000" },
				{ "黄", "0xffff00" },
				{ "紫", "0xff00ff" },
				{ "随机", "math.random(0, 0xffffff)" },
			},
		},
	},
	output = {type = "null",},
	hide_in_toolbox = true,
	category = "painter", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s',
	ToNPL = function(self)
		return string.format('%s', self:getFieldAsString('value'));
	end,
	examples = {{desc = "", canRun = false, code = [[
]]}},
},
{
	type = "setPenColor", 
	message0 = "画笔颜色 %1",
	arg0 = {
		{
			name = "value",
			type = "input_value",
            shadow = { type = "penColorList"},
		},
	},
	category = "painter", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'setPenColor(%s)',
	ToNPL = function(self)
		return string.format('setPenColor(%s)\n', self:getFieldValue('value'));
	end,
	examples = {{desc = "", canRun = false, code = [[
]]}},
},
{
	type = "setPenBlockId", 
	message0 = "画笔方块id %1",
	arg0 = {
		{
			name = "value",
			type = "input_value",
            shadow = { type = "math_number", value=10},
			text = 10;
		},
	},
	category = "painter", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'setPenBlockId(%s)',
	ToNPL = function(self)
		return string.format('setPenBlockId(%s)\n', self:getFieldValue('value'));
	end,
	examples = {{desc = "", canRun = false, code = [[
]]}},
},
-----------------------
{
	type = "jumpTo", 
	message0 = "跳到%1, %2",
	arg0 = {
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
	},
	category = "painter", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'jumpTo(%s, %s)',
	ToNPL = function(self)
		return string.format('jumpTo(%s, %s)\n', self:getFieldValue('x'), self:getFieldValue('y'));
	end,
	examples = {{desc = L"射线", canRun = false, code = [[
for i=1, 6 do
    setPenColor(math.random(0, 0xffffff))
    jumpTo(0, 0)
    drawLine("forward", 5)
    turnPen("left", 60)
end 
]]}},
},
-----------------------
{
	type = "drawBlock", 
	message0 = "画点%1, %2",
	arg0 = {
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
	},
	category = "painter", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'drawBlock(%s, %s)',
	ToNPL = function(self)
		return string.format('drawBlock(%s, %s)\n', self:getFieldValue('x'), self:getFieldValue('y'));
	end,
	examples = {{desc = "", canRun = false, code = [[
]]}},
},
-----------------------
{
	type = "repeat", 
	message0 = L"重复%1次",
	message1 = L"%1",
	arg0 = {
		{
			name = "times",
			type = "input_value",
            shadow = { type = "math_number", value = 4,},
			text = 4, 
		},
	},
    arg1 = {
		{
			name = "input",
			type = "input_statement",
		},
	},
	category = "painter", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'for i=1, %d do\\n%send',
	ToNPL = function(self)
		return string.format('for i=1, %d do\n    %s\nend\n', self:getFieldValue('times'), self:getFieldAsString('input'));
	end,
	examples = {{desc = "", canRun = false, code = [[
]]}},
},
});