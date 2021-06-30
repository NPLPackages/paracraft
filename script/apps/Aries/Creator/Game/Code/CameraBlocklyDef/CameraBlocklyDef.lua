--[[
Title: Camera Block 
Author(s): chenjinxian
Date: 
Desc: 
use the lib:
-------------------------------------------------------
-------------------------------------------------------
]]
NPL.export({
-----------------------
{
	type = "camera_use", 
	message0 = "使用【%1号】摄影机",
	arg0 = {
		{
			name = "cameraId",
			type = "field_dropdown",
			options = {
				{ "1", "#1" },
				{ "2", "#2" },
				{ "3", "#3" },
				{ "4", "#4" },
			},
			text = "1",
		},
	},
	category = "Camera", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "camera.use",
	func_description = 'camera.use("%s")',
	ToNPL = function(self)
		return string.format('camera.use("%s")\n', self:getFieldValue('cameraId'));
	end,
	examples = {{desc = "使用指定的摄影机", canRun = false, code = [[
]]}},
},

{
	type = "setPosition", 
	message0 = L"设置摄影机位置%1%2%3",
	arg0 = {
		{
			name = "x",
			type = "input_value",
			shadow = { type = "math_number", value = 19200,},
			text = 19200, 
		},
		{
			name = "y",
			type = "input_value",
			shadow = { type = "math_number", value = 5,},
			text = 5, 
		},
		{
			name = "z",
			type = "input_value",
			shadow = { type = "math_number", value = 19200,},
			text = 19200, 
		},
	},
	category = "Motion", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "camera.setPosition",
	func_description = 'camera.setPosition(%d, %d, %d)',
	ToNPL = function(self)
		return string.format('camera.setPosition(%s, %s, %s)\n', self:getFieldAsString('x'), self:getFieldAsString('y'), self:getFieldAsString('z'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "moveForward", 
	message0 = L"摄影机前进%1格 在%2秒内",
	arg0 = {
		{
			name = "dist",
			type = "input_value",
			shadow = { type = "math_number", value = 10,},
			text = 10, 
		},
		{
			name = "duration",
			type = "input_value",
			shadow = { type = "math_number", value = 5,},
			text = 5, 
		},
	},
	category = "Motion", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "camera.moveForward",
	func_description = 'camera.moveForward(%d, %d)',
	ToNPL = function(self)
		return string.format('camera.moveForward(%s, %s)\n', self:getFieldAsString('dist'), self:getFieldAsString('duration'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "moveHorizontal", 
	message0 = L"摄影机平移%1格 在%2秒内",
	arg0 = {
		{
			name = "dist",
			type = "input_value",
			shadow = { type = "math_number", value = 10,},
			text = 10, 
		},
		{
			name = "duration",
			type = "input_value",
			shadow = { type = "math_number", value = 5,},
			text = 5, 
		},
	},
	category = "Motion", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "camera.moveHorizontal",
	func_description = 'camera.moveHorizontal(%d, %d)',
	ToNPL = function(self)
		return string.format('camera.moveHorizontal(%s, %s)\n', self:getFieldAsString('dist'), self:getFieldAsString('duration'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "moveVertical", 
	message0 = L"摄影机上移%1格 在%2秒内",
	arg0 = {
		{
			name = "dist",
			type = "input_value",
			shadow = { type = "math_number", value = 10,},
			text = 10, 
		},
		{
			name = "duration",
			type = "input_value",
			shadow = { type = "math_number", value = 5,},
			text = 5, 
		},
	},
	category = "Motion", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "camera.moveVertical",
	func_description = 'camera.moveVertical(%d, %d)',
	ToNPL = function(self)
		return string.format('camera.moveVertical(%s, %s)\n', self:getFieldAsString('dist'), self:getFieldAsString('duration'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "rotateYaw", 
	message0 = L"摄影机左右旋转%1格 在%2秒内",
	arg0 = {
		{
			name = "degree",
			type = "input_value",
			shadow = { type = "math_number", value = 30,},
			text = 30, 
		},
		{
			name = "duration",
			type = "input_value",
			shadow = { type = "math_number", value = 10,},
			text = 10, 
		},
	},
	category = "Motion", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "camera.rotateYaw",
	func_description = 'camera.rotateYaw(%d, %d)',
	ToNPL = function(self)
		return string.format('camera.rotateYaw(%s, %s)\n', self:getFieldAsString('degree'), self:getFieldAsString('duration'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "rotatePitch", 
	message0 = L"摄影机上下旋转%1格 在%2秒内",
	arg0 = {
		{
			name = "degree",
			type = "input_value",
			shadow = { type = "math_number", value = 30,},
			text = 30, 
		},
		{
			name = "duration",
			type = "input_value",
			shadow = { type = "math_number", value = 10,},
			text = 10, 
		},
	},
	category = "Motion", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "camera.rotatePitch",
	func_description = 'camera.rotatePitch(%d, %d)',
	ToNPL = function(self)
		return string.format('camera.rotatePitch(%s, %s)\n', self:getFieldAsString('degree'), self:getFieldAsString('duration'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "rotateRoll", 
	message0 = L"摄影机摆动旋转%1格 在%2秒内",
	arg0 = {
		{
			name = "degree",
			type = "input_value",
			shadow = { type = "math_number", value = 30,},
			text = 30, 
		},
		{
			name = "duration",
			type = "input_value",
			shadow = { type = "math_number", value = 10,},
			text = 10, 
		},
	},
	category = "Motion", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "camera.rotateRoll",
	func_description = 'camera.rotateRoll(%d, %d)',
	ToNPL = function(self)
		return string.format('camera.rotateRoll(%s, %s)\n', self:getFieldAsString('degree'), self:getFieldAsString('duration'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "circle", 
	message0 = L"摄影机环绕%1度，半径%2格，在%2秒内",
	arg0 = {
		{
			name = "degree",
			type = "input_value",
			shadow = { type = "math_number", value = 60,},
			text = 60, 
		},
		{
			name = "radius",
			type = "input_value",
			shadow = { type = "math_number", value = 20,},
			text = 20, 
		},
		{
			name = "duration",
			type = "input_value",
			shadow = { type = "math_number", value = 10,},
			text = 10, 
		},
	},
	category = "Motion", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "camera.circle",
	func_description = 'camera.circle(%d, %d, %d)',
	ToNPL = function(self)
		return string.format('camera.circle(%s, %s, %s)\n', self:getFieldAsString('degree'), self:getFieldAsString('radius'), self:getFieldAsString('duration'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},



});