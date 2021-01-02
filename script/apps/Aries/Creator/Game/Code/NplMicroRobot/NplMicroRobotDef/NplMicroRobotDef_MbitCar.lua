--[[
Title: NplMicroRobotDef_MbitCar
Author(s): leio
Date: 2020/12/15
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicroRobot/NplMicroRobotDef/NplMicroRobotDef_MbitCar.lua");
-------------------------------------------------------
]]
NPL.export({

{
	type = "mbit_小车类.RGB_Car_Big2", 
	message0 = L"小车RGB探照灯 选择车灯颜色 %1",
    arg0 = {
        {
			name = "op",
			type = "field_dropdown",
			options = {
				{ L"灭", "OFF" },
				{ L"红色", "Red" },
				{ L"绿色", "Green" },
				{ L"蓝色", "Blue" },
				{ L"白色", "White" },
				{ L"青色", "Cyan" },
				{ L"品红", "Pinkish" },
				{ L"黄色", "Yellow" },
			},
		},
	},
    previousStatement = true,
	nextStatement = true,
	category = "NplMicroRobot.MbitCar", 
	helpUrl = "", 
	canRun = false,
	funcName = "mbit_小车类.RGB_Car_Big2",
	func_description = 'mbit_小车类.RGB_Car_Big2(mbit_小车类.enColor.%s)',
	ToNPL = function(self)
		return "";
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "mbit_小车类.RGB_Car_Big", 
	message0 = L"小车RGB探照灯 红色 %1 绿色 %2 蓝色 %3",
    arg0 = {
        {
			name = "r_value",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0,
		},
        {
			name = "g_value",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0,
		},
        {
			name = "b_value",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0,
		},
	},
    previousStatement = true,
	nextStatement = true,
	category = "NplMicroRobot.MbitCar", 
	helpUrl = "", 
	canRun = false,
	funcName = "mbit_小车类.RGB_Car_Big",
	func_description = 'mbit_小车类.RGB_Car_Big(%s,%s,%s)',
	ToNPL = function(self)
		return "";
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},


{
	type = "mbit_传感器类.Ultrasonic", 
	message0 = L"超声波 发射管脚 %1 接收管脚 %2",
    arg0 = {
        {
			name = "op_1",
			type = "field_dropdown",
			options = {
				{ L"P0", "P0" },
				{ L"P1", "P1" },
				{ L"P2", "P2" },
				{ L"P3", "P3" },
				{ L"P4", "P4" },
				{ L"P5", "P5" },
				{ L"P6", "P6" },
				{ L"P7", "P7" },
				{ L"P8", "P8" },
				{ L"P9", "P9" },
				{ L"P10", "P10" },
				{ L"P11", "P11" },
				{ L"P12", "P12" },
				{ L"P13", "P13" },
				{ L"P14", "P14" },
				{ L"P15", "P15" },
				{ L"P16", "P16" },
			},
		},
        {
			name = "op_2",
			type = "field_dropdown",
			options = {
				{ L"P0", "P0" },
				{ L"P1", "P1" },
				{ L"P2", "P2" },
				{ L"P3", "P3" },
				{ L"P4", "P4" },
				{ L"P5", "P5" },
				{ L"P6", "P6" },
				{ L"P7", "P7" },
				{ L"P8", "P8" },
				{ L"P9", "P9" },
				{ L"P10", "P10" },
				{ L"P11", "P11" },
				{ L"P12", "P12" },
				{ L"P13", "P13" },
				{ L"P14", "P14" },
				{ L"P15", "P15" },
				{ L"P16", "P16" },
			},
		},
	},
    output = {type = "null",},
	category = "NplMicroRobot.MbitCar", 
	helpUrl = "", 
	canRun = false,
	funcName = "mbit_传感器类.Ultrasonic",
	func_description = 'mbit_传感器类.Ultrasonic(DigitalPin.%s, DigitalPin.%s)',
	ToNPL = function(self)
		return ""
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},


{
	type = "mbit_小车类.Ultrasonic_Car", 
	message0 = L"超声波返回(cm)",
    output = {type = "null",},
	category = "NplMicroRobot.MbitCar", 
	helpUrl = "", 
	canRun = false,
	funcName = "mbit_小车类.Ultrasonic_Car",
	func_description = 'mbit_小车类.Ultrasonic_Car()',
	ToNPL = function(self)
		return ""
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "mbit_小车类.Servo_Car", 
	message0 = L"小车舵机 编号%1 角度 %2",
    arg0 = {
        {
			name = "op",
			type = "field_dropdown",
			options = {
				{ L"S1", "S1" },
				{ L"S2", "S2" },
				{ L"S3", "S3" },
			},
		},
        {
			name = "value",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0,
		},
	},
    previousStatement = true,
	nextStatement = true,
	category = "NplMicroRobot.MbitCar", 
	helpUrl = "", 
	canRun = false,
	funcName = "mbit_小车类.Servo_Car",
	func_description = 'mbit_小车类.Servo_Car(mbit_小车类.enServo.%s, %s)',
	ToNPL = function(self)
		return "";
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "mbit_小车类.Avoid_Sensor", 
	message0 = L"壁障传感器 检测到 %1",
    arg0 = {
        {
			name = "op",
			type = "field_dropdown",
			options = {
				{ L"有障碍物", "OBSTACLE" },
				{ L"无障碍物", "NOOBSTACLE" },
			},
		},
	},
    output = {type = "null",},
	category = "NplMicroRobot.MbitCar", 
	helpUrl = "", 
	canRun = false,
	funcName = "mbit_小车类.Avoid_Sensor",
	func_description = 'mbit_小车类.Avoid_Sensor(mbit_小车类.enAvoidState.%s)',
	ToNPL = function(self)
		return "";
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "mbit_小车类.Line_Sensor", 
	message0 = L"巡线传感器 位置 %1 检测到 %2",
    arg0 = {
        {
			name = "op",
			type = "field_dropdown",
			options = {
				{ L"左边状态", "LeftState" },
				{ L"右边状态", "RightState" },
			},
		},
        {
			name = "op_2",
			type = "field_dropdown",
			options = {
				{ L"白线", "White" },
				{ L"黑线", "Black" },
			},
		},
	},
    output = {type = "null",},
	category = "NplMicroRobot.MbitCar", 
	helpUrl = "", 
	canRun = false,
	funcName = "mbit_小车类.Line_Sensor",
	func_description = 'mbit_小车类.Line_Sensor(mbit_小车类.enPos.%s, mbit_小车类.enLineState.%s)',
	ToNPL = function(self)
		return "";
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "mbit_小车类.CarCtrl", 
	message0 = L"小车控制 %1",
    arg0 = {
        {
			name = "op",
			type = "field_dropdown",
			options = {
				{ L"前行", "Car_Run" },
				{ L"后退", "Car_Back" },
				{ L"左转", "Car_Left" },
				{ L"右转", "Car_Right" },
				{ L"停止", "Car_Stop" },
				{ L"原地左旋", "Car_SpinLeft" },
				{ L"原地右旋", "Car_SpinRight" },
			},
		},

	},
    previousStatement = true,
	nextStatement = true,
	category = "NplMicroRobot.MbitCar", 
	helpUrl = "", 
	canRun = false,
	funcName = "mbit_小车类.CarCtrl",
	func_description = 'mbit_小车类.CarCtrl(mbit_小车类.CarState.%s)',
	ToNPL = function(self)
		return "";
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "mbit_小车类.CarCtrlSpeed", 
	message0 = L"小车控制 %1 速度 %2",
    arg0 = {
        {
			name = "op",
			type = "field_dropdown",
			options = {
				{ L"前行", "Car_Run" },
				{ L"后退", "Car_Back" },
				{ L"左转", "Car_Left" },
				{ L"右转", "Car_Right" },
				{ L"停止", "Car_Stop" },
				{ L"原地左旋", "Car_SpinLeft" },
				{ L"原地右旋", "Car_SpinRight" },
			},
		},
        {
			name = "value",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0,
		},
	},
    previousStatement = true,
	nextStatement = true,
	category = "NplMicroRobot.MbitCar", 
	helpUrl = "", 
	canRun = false,
	funcName = "mbit_小车类.CarCtrlSpeed",
	func_description = 'mbit_小车类.CarCtrlSpeed(mbit_小车类.CarState.%s, %s)',
	ToNPL = function(self)
		return "";
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "mbit_小车类.CarCtrlSpeed2", 
	message0 = L"小车控制 %1 左电机速度 %2 右电机速度 %3",
    arg0 = {
        {
			name = "op",
			type = "field_dropdown",
			options = {
				{ L"前行", "Car_Run" },
				{ L"后退", "Car_Back" },
				{ L"左转", "Car_Left" },
				{ L"右转", "Car_Right" },
				{ L"停止", "Car_Stop" },
				{ L"原地左旋", "Car_SpinLeft" },
				{ L"原地右旋", "Car_SpinRight" },
			},
		},
        {
			name = "left_value",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0,
		},
        {
			name = "right_value",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0,
		},
	},
    previousStatement = true,
	nextStatement = true,
	category = "NplMicroRobot.MbitCar", 
	helpUrl = "", 
	canRun = false,
	funcName = "mbit_小车类.CarCtrlSpeed2",
	func_description = 'mbit_小车类.CarCtrlSpeed2(mbit_小车类.CarState.%s, %s, %s)',
	ToNPL = function(self)
		return "";
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

})