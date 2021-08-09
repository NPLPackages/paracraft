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
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "Camera.use",
	func_description = 'Camera.use("%s")',
	ToNPL = function(self)
		return string.format('Camera.use("%s")\n', self:getFieldValue('cameraId'));
	end,
	examples = {{desc = "使用指定的摄影机", canRun = true, code = [[
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
	category = "Camera", 
	helpUrl = "", 
	canRun = true,
	hide_in_toolbox = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "Camera.setPosition",
	func_description = 'Camera.setPosition(%d, %d, %d)',
	ToNPL = function(self)
		return string.format('Camera.setPosition(%s, %s, %s)\n', self:getFieldAsString('x'), self:getFieldAsString('y'), self:getFieldAsString('z'));
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
	category = "Camera", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "Camera.moveForward",
	func_description = 'Camera.moveForward(%d, %d)',
	ToNPL = function(self)
		return string.format('Camera.moveForward(%s, %s)\n', self:getFieldAsString('dist'), self:getFieldAsString('duration'));
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
	category = "Camera", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "Camera.moveHorizontal",
	func_description = 'Camera.moveHorizontal(%d, %d)',
	ToNPL = function(self)
		return string.format('Camera.moveHorizontal(%s, %s)\n', self:getFieldAsString('dist'), self:getFieldAsString('duration'));
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
	category = "Camera", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "Camera.moveVertical",
	func_description = 'Camera.moveVertical(%d, %d)',
	ToNPL = function(self)
		return string.format('Camera.moveVertical(%s, %s)\n', self:getFieldAsString('dist'), self:getFieldAsString('duration'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "rotateYaw", 
	message0 = L"摄影机左右旋转%1度 在%2秒内",
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
	category = "Camera", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "Camera.rotateYaw",
	func_description = 'Camera.rotateYaw(%d, %d)',
	ToNPL = function(self)
		return string.format('Camera.rotateYaw(%s, %s)\n', self:getFieldAsString('degree'), self:getFieldAsString('duration'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "rotatePitch", 
	message0 = L"摄影机上下旋转%1度 在%2秒内",
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
	category = "Camera", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "Camera.rotatePitch",
	func_description = 'Camera.rotatePitch(%d, %d)',
	ToNPL = function(self)
		return string.format('Camera.rotatePitch(%s, %s)\n', self:getFieldAsString('degree'), self:getFieldAsString('duration'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "rotateRoll", 
	message0 = L"摄影机摆动旋转%1度 在%2秒内",
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
	category = "Camera", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "Camera.rotateRoll",
	func_description = 'Camera.rotateRoll(%d, %d)',
	ToNPL = function(self)
		return string.format('Camera.rotateRoll(%s, %s)\n', self:getFieldAsString('degree'), self:getFieldAsString('duration'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "circle", 
	message0 = L"摄影机环绕%1度，在%2秒内，延长半径%3格",
	arg0 = {
		{
			name = "degree",
			type = "input_value",
			shadow = { type = "math_number", value = 60,},
			text = 60, 
		},
		{
			name = "duration",
			type = "input_value",
			shadow = { type = "math_number", value = 10,},
			text = 10, 
		},
		{
			name = "radius",
			type = "input_value",
			shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
	},
	category = "Camera", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "Camera.circle",
	func_description = 'Camera.circle(%d, %d, %d)',
	ToNPL = function(self)
		return string.format('Camera.circle(%s, %s, %s)\n', self:getFieldAsString('degree'), self:getFieldAsString('duration'), self:getFieldAsString('radius'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "camera_play", 
	message0 = L"播放动画%1到%2毫秒",
	arg0 = {
		{
			name = "bengin_time",
			type = "input_value",
			shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
		{
			name = "end_time",
			type = "input_value",
			shadow = { type = "math_number", value = 1000,},
			text = 1000, 
		},
	},
	category = "Camera", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "Camera.play",
	func_description = 'Camera.play(%d, %d)',
	ToNPL = function(self)
		return string.format('Camera.play(%s, %s)\n', self:getFieldAsString('bengin_time'), self:getFieldAsString('end_time'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "camera_wait", 
	message0 = L"等待%1秒",
	arg0 = {
		{
			name = "time",
			type = "input_value",
			shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
	},
	category = "Camera",
	helpUrl = "", 
	canRun = true,
	funcName = "Camera.wait",
	previousStatement = true,
	nextStatement = true,
	func_description = 'Camera.wait(%s)',
	ToNPL = function(self)
		return string.format('Camera.wait(%s)\n', self:getFieldAsString('time'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},



});