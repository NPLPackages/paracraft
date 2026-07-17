--[[
Title: micro python 
Author(s): LiXizhi
Date: 2023/8/2
Desc: output and more
use the lib:
-------------------------------------------------------
from mpython import *

p0 = MPythonPin(0, PinMode.ANALOG)

p0 = MPythonPin(0, PinMode.PWM)

import machine

p0 = MPythonPin(0, PinMode.IN, None)
p0.read_digital()

p0.write_digital(1)

p0.read_analog()

p0.write_analog(1023)
p0.write_analog(1023)
machine.time_pulse_us(Pin(Pin.P0), 1, timeout_us=1000000)
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/Color.lua");
local Color = commonlib.gettable("System.Core.Color");

NPL.export({

{
	type = "servo.write_angle", 
	message0 = L"设置舵机%1 角度%2",
	arg0 = {
		{
			name = "PIN",
			type = "field_dropdown",
			options = {
				{ L"P0", "0" },
				{ L"P1", "1" },
				{ L"P2", "2" },
				{ L"P5(button_A)", "5" },
				{ L"P6(buzzer)", "6" },
				{ L"P7(RGB)", "7" },
				{ L"P8", "8" },
				{ L"P9", "9" },
				{ L"P11(button_B)", "11" },
				{ L"P12", "12" },
				{ L"P13", "13" },
				{ L"P14", "14" },
				{ L"P15", "15" },
				{ L"P16", "16" },
				{ L"P19(SCL)", "19" },
				{ L"P20(SDA", "20" },
			  }
		},
		{
			name = "angle",
			type = "input_value",
            shadow = { type = "math_number", value = 90,},
			text = 90, 
		},
	},
	category = "output", 
	helpUrl = "", 
	canRun = false,
	funcName = "servo.write_angle",
	previousStatement = true,
	nextStatement = true,
	headerText = "from servo import Servo",
	func_description = 'servo_%s.write_angle(%s)',
	ToNPL = function(self)
		return string.format('servo_%s.write_angle(%s)\n', self:getFieldAsString('PIN'), self:getFieldAsString('angle'));
	end,
	ToMicroPython = function(self)
		self:GetBlockly():AddUniqueHeader(string.format('servo_%s = Servo(%s, min_us=500, max_us=2500, actuation_range=180)', self:getFieldAsString('PIN'), self:getFieldAsString('PIN')));
		return string.format('servo_%s.write_angle(%s)\n', self:getFieldAsString('PIN'), self:getFieldAsString('angle'));
	end,
	examples = {{desc = "", canRun = true, code = [[
from servo import Servo
servo_0 = Servo(0, min_us=500, max_us=2500, actuation_range=180)
servo_0.write_angle(90)
]]}},
},


{
	type = "rgb.fill", 
	message0 = L"设置%1RGB灯颜色为%2",
	arg0 = {
		{
			name = "src",
			type = "field_dropdown",
			options = {
				{ L"所有", ".fill" },
				{ L"#0", "[0] = " },
				{ L"#1", "[1] = " },
				{ L"#2", "[2] = " },
			}
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ff0000",},
			text = "#ff0000",
		},
	},
	category = "output", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\nimport time",
	func_description = 'rgb%s %s',
	ToNPL = function(self)
		local color = Color.ColorStrToValues(self:getFieldAsString('color'));
		local src = self:getFieldAsString('src')
		if(src == ".fill") then
			return string.format('rgb%s((%s,%s,%s))\nrgb.write()\ntime.sleep_ms(1)\n', src, color[1], color[2], color[3]);
		else
			return string.format('rgb%s[%s,%s,%s]\nrgb.write()\ntime.sleep_ms(1)\n', src, color[1], color[2], color[3]);
		end
	end,
	ToMicroPython = function(self)
		local color = Color.ColorStrToValues(self:getFieldAsString('color'));
		local src = self:getFieldAsString('src')
		local block_indent = self:GetIndent();
		if(src == ".fill") then
			return string.format('rgb%s((%s,%s,%s))\n%srgb.write()\n%stime.sleep_ms(1)\n', src, color[1], color[2], color[3], block_indent, block_indent);
		else
			return string.format('rgb%s[%s,%s,%s]\n%srgb.write()\n%stime.sleep_ms(1)\n', src, color[1], color[2], color[3], block_indent, block_indent);
		end
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},


{
	type = "rgb.fillRGB", 
	message0 = L"设置%1RGB灯颜色为R%2 G%3 B%4",
	arg0 = {
		{
			name = "src",
			type = "field_dropdown",
			options = {
				{ L"所有", ".fill" },
				{ L"#0", "[0] = " },
				{ L"#1", "[1] = " },
				{ L"#2", "[2] = " },
			}
		},
		{
			name = "r",
			type = "input_value",
            shadow = { type = "math_number", value = 255,},
			text = 255, 
		},
		{
			name = "g",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
		{
			name = "b",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
	},
	category = "output", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\nimport time",
	func_description = 'rgb%s (%s,%s,%s)',
	ToNPL = function(self)
		local color = {self:getFieldAsString('r'), self:getFieldAsString('g'), self:getFieldAsString('b')};
		local src = self:getFieldAsString('src')
		if(src == ".fill") then
			return string.format('rgb%s((int(%s),int(%s),int(%s)))\nrgb.write()\ntime.sleep_ms(1)\n', src, color[1], color[2], color[3]);
		else
			return string.format('rgb%s[int(%s),int(%s),int(%s)]\nrgb.write()\ntime.sleep_ms(1)\n', src, color[1], color[2], color[3]);
		end
	end,
	ToMicroPython = function(self)
		local color = {self:getFieldAsString('r'), self:getFieldAsString('g'), self:getFieldAsString('b')};
		local src = self:getFieldAsString('src')
		local block_indent = self:GetIndent();
		if(src == ".fill") then
			return string.format('rgb%s((int(%s),int(%s),int(%s)))\n%srgb.write()\n%stime.sleep_ms(1)\n', src, color[1], color[2], color[3], block_indent, block_indent);
		else
			return string.format('rgb%s[int(%s),int(%s),int(%s)]\n%srgb.write()\n%stime.sleep_ms(1)\n', src, color[1], color[2], color[3], block_indent, block_indent);
		end
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "rgb.close", 
	message0 = L"关闭%1RGB灯",
	arg0 = {
		{
			name = "src",
			type = "field_dropdown",
			options = {
				{ L"所有", ".fill" },
				{ L"#0", "[0] = " },
				{ L"#1", "[1] = " },
				{ L"#2", "[2] = " },
			}
		},
	},
	category = "output", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\nimport time",
	func_description = 'rgb%s close()',
	ToNPL = function(self)
		local color = {0,0,0};
		local src = self:getFieldAsString('src')
		if(src == ".fill") then
			return string.format('rgb%s((int(%s),int(%s),int(%s)))\nrgb.write()\ntime.sleep_ms(1)\n', src, color[1], color[2], color[3]);
		else
			return string.format('rgb%s(int(%s),int(%s),int(%s))\nrgb.write()\ntime.sleep_ms(1)\n', src, color[1], color[2], color[3]);
		end
	end,
	ToMicroPython = function(self)
		local color = {0,0,0};
		local src = self:getFieldAsString('src')
		local block_indent = self:GetIndent();
		if(src == ".fill") then
			return string.format('rgb%s((int(%s),int(%s),int(%s)))\n%srgb.write()\n%stime.sleep_ms(1)\n', src, color[1], color[2], color[3], block_indent, block_indent);
		else
			return string.format('rgb%s(int(%s),int(%s),int(%s))\n%srgb.write()\n%stime.sleep_ms(1)\n', src, color[1], color[2], color[3], block_indent, block_indent);
		end
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "music.play", 
	message0 = L"播放音乐%1",
	arg0 = {
		{
			name = "content",
			type = "input_value",
            shadow = { type = "text", value = "c4:1",},
			text = "c4:1", 
		},
	},
	category = "output", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\nimport music",
	func_description = 'music.play("%s")',
	ToNPL = function(self)
		return string.format('music.play("%s")\n', self:getFieldAsString('content'));
	end,
	ToMicroPython = function(self)
		return string.format('music.play(%s)\n', self:GetValueAsString('content'));
	end,
	examples = {{desc = "", canRun = false, code = [[
from mpython import *
import music
music.play("c4:1")
music.play(['c4:1', 'e', 'g', 'c5', 'e5', 'g4'])
]]}},
},

{
	type = "music.playPin", 
	message0 = L"播放%1 引脚%2",
	arg0 = {
		{
			name = "content",
			type = "input_value",
            shadow = { type = "text", value = "c4:1",},
			text = "c4:1", 
		},
		{
			name = "PIN",
			type = "field_dropdown",
			options = {
				{ L"P0", "0" },
				{ L"P1", "1" },
				{ L"P2", "2" },
				{ L"P5(button_A)", "5" },
				{ L"P6(buzzer)", "6" },
				{ L"P7(RGB)", "7" },
				{ L"P8", "8" },
				{ L"P9", "9" },
				{ L"P11(button_B)", "11" },
				{ L"P12", "12" },
				{ L"P13", "13" },
				{ L"P14", "14" },
				{ L"P15", "15" },
				{ L"P16", "16" },
				{ L"P19(SCL)", "19" },
				{ L"P20(SDA", "20" },
			}
		},
	},
	category = "output", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\nimport music",
	func_description = 'music.play("%s", pin=Pin.P%s)',
	ToNPL = function(self)
		return string.format('music.play("%s", pin=Pin.P%s)\n', self:getFieldAsString('content'), self:getFieldAsString('PIN'));
	end,
	ToMicroPython = function(self)
		return string.format('music.play(%s, pin=Pin.P%s)\n', self:GetValueAsString('content'), self:getFieldAsString('PIN'));
	end,
	examples = {{desc = "", canRun = false, code = [[
]]}},
},

{
	type = "Pin.write_digital", 
	message0 = L"设置引脚%1数字值%2",
	arg0 = {
		{
			name = "PIN",
			type = "field_dropdown",
			options = {
				{ L"P0", "0" },
				{ L"P1", "1" },
				{ L"P2", "2" },
				{ L"P5(button_A)", "5" },
				{ L"P6(buzzer)", "6" },
				{ L"P7(RGB)", "7" },
				{ L"P8", "8" },
				{ L"P9", "9" },
				{ L"P11(button_B)", "11" },
				{ L"P12", "12" },
				{ L"P13", "13" },
				{ L"P14", "14" },
				{ L"P15", "15" },
				{ L"P16", "16" },
				{ L"P19(SCL)", "19" },
				{ L"P20(SDA", "20" },
			}
		},
		{
			name = "value",
			type = "field_dropdown",
			options = {
				{ L"高", "1" },
				{ L"低", "0" },
			}
		},
	},
	category = "output", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *",
	func_description = 'p%s.write_digital(%s)',
	ToNPL = function(self)
		local pin = self:getFieldAsString('PIN');
		return string.format('p%s.write_digital(%s)\n', pin, self:getFieldAsString('value'));
	end,
	ToMicroPython = function(self)
		local pin = self:getFieldAsString('PIN');
		local analogIn = string.gsub("pXX = MPythonPin(XX, PinMode.OUT)\n", "XX", pin);
		self:GetBlockly():AddUniqueHeader(analogIn);
		return string.format('p%s.write_digital(%s)\n', pin, self:getFieldAsString('value'));
	end,
	examples = {{desc = "", canRun = false, code = [[
]]}},
},

{
	type = "Pin.write_analog", 
	message0 = L"设置引脚%1模拟值(PWM)%2",
	arg0 = {
		{
			name = "PIN",
			type = "field_dropdown",
			options = {
				{ L"P0", "0" },
				{ L"P1", "1" },
				{ L"P2", "2" },
				{ L"P5(button_A)", "5" },
				{ L"P6(buzzer)", "6" },
				{ L"P7(RGB)", "7" },
				{ L"P8", "8" },
				{ L"P9", "9" },
				{ L"P11(button_B)", "11" },
				{ L"P12", "12" },
				{ L"P13", "13" },
				{ L"P14", "14" },
				{ L"P15", "15" },
				{ L"P16", "16" },
				{ L"P19(SCL)", "19" },
				{ L"P20(SDA", "20" },
			}
		},
		{
			name = "pwm",
			type = "input_value",
            shadow = { type = "math_number", value = 1023,},
			text = 1023, 
		},
	},
	category = "output", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *",
	func_description = 'p%s.write_analog(%s)',
	ToNPL = function(self)
		local pin = self:getFieldAsString('PIN');
		return string.format('p%s.write_analog(%s)\n', pin, self:getFieldAsString('pwm'));
	end,
	ToMicroPython = function(self)
		local pin = self:getFieldAsString('PIN');
		local analogIn = string.gsub("pXX = MPythonPin(XX, PinMode.PWM)\n", "XX", pin);
		self:GetBlockly():AddUniqueHeader(analogIn);
		return string.format('p%s.write_analog(%s)\n', pin, self:getFieldAsString('pwm'));
	end,
	examples = {{desc = "", canRun = false, code = [[
from mpython import *
# such as controlling LED light
p0 = MPythonPin(0, PinMode.PWM)
p0.write_analog(1023)
]]}},
},

{
	type = "machine.Pin.Init.Out", 
	message0 = L"初始化%1为%2管脚#%3",
	arg0 = {
		{
			name = "name",
			type = "input_value",
            shadow = { type = "text", value = "pin0",},
			text = "pin0", 
		},
		{
			name = "mode",
			type = "field_dropdown",
			options = {
				{ L"数字输出", "PinOut" },
				{ L"PWM模拟输出", "PWM" },
				{ L"数字输入", "PinIn" },
				{ L"模拟输入", "ADC" },
			}
		},
		{
			name = "PIN",
			type = "input_value",
            shadow = { type = "math_number", value = 33,},
			text = 33, 
		},
	},
	output = {type = "null",},
	category = "output", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "import machine",
	func_description = '%s = machine.%s(%s)',
	ToNPL = function(self)
		local mode = self:getFieldAsString('mode')
		local name = self:getFieldAsString('name')
		local pin = self:getFieldAsString('PIN')
		local code;
		if(mode == "PinIn") then
			code = string.format('%s = machine.Pin(%s, machine.Pin.IN)\n', name, pin);
		elseif(mode == "PinOut") then
			code = string.format('%s = machine.Pin(%s, machine.Pin.OUT)\n', name, pin);
		elseif(mode == "ADC") then
			code = string.format('%s = machine.ADC(machine.Pin(%s))\n', name, pin);
		elseif(mode == "PWM") then
			code = string.format('%s = machine.PWM(machine.Pin(%s))\n', name, pin);
		end
		return code;
	end,
	ToMicroPython = function(self)
		local mode = self:getFieldAsString('mode')
		local name = self:getFieldAsString('name')
		local pin = self:getFieldAsString('PIN')
		local code;
		if(mode == "PinIn") then
			code = string.format('%s = machine.Pin(%s, machine.Pin.IN)\n', name, pin);
		elseif(mode == "PinOut") then
			code = string.format('%s = machine.Pin(%s, machine.Pin.OUT)\n', name, pin);
		elseif(mode == "ADC") then
			code = string.format('%s = machine.ADC(machine.Pin(%s))\n', name, pin);
		elseif(mode == "PWM") then
			code = string.format('%s = machine.PWM(machine.Pin(%s))\n', name, pin);
		end
		self:GetBlockly():AddUniqueHeader(code);
		return "";
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "machine.Pin.write_digital", 
	message0 = L"数字输出%1设为%2",
	arg0 = {
		{
			name = "name",
			type = "input_value",
            shadow = { type = "text", value = "pin0",},
			text = "pin0", 
		},
		{
			name = "value",
			type = "field_dropdown",
			options = {
				{ L"高", "1" },
				{ L"低", "0" },
			}
		},
	},
	category = "output", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "import machine",
	func_description = '%s.value(%s)',
	ToNPL = function(self)
		local name = self:getFieldAsString('name');
		return string.format('%s.value(%s)\n', name, self:getFieldAsString('value'));
	end,
	ToMicroPython = function(self)
		local name = self:getFieldAsString('name');
		return string.format('%s.value(%s)\n', name, self:getFieldAsString('value'));
	end,
	examples = {{desc = "", canRun = false, code = [[
]]}},
},

{
	type = "machine.Pin.Init.OutPWM", 
	message0 = L"初始化%1为PWM模拟输出 管脚#%2",
	arg0 = {
		{
			name = "name",
			type = "input_value",
            shadow = { type = "text", value = "pwm0",},
			text = "pwm0", 
		},
		{
			name = "PIN",
			type = "input_value",
            shadow = { type = "math_number", value = 33,},
			text = 33, 
		},
	},
	output = {type = "null",},
	category = "output", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "import machine",
	func_description = '%s = machine.PWM(machine.Pin(%s))',
	ToNPL = function(self)
		local mode = "PWM"
		local name = self:getFieldAsString('name')
		local pin = self:getFieldAsString('PIN')
		local code;
		if(mode == "PinIn") then
			code = string.format('%s = machine.Pin(%s, machine.Pin.IN)\n', name, pin);
		elseif(mode == "PinOut") then
			code = string.format('%s = machine.Pin(%s, machine.Pin.OUT)\n', name, pin);
		elseif(mode == "ADC") then
			code = string.format('%s = machine.ADC(machine.Pin(%s))\n', name, pin);
		elseif(mode == "PWM") then
			code = string.format('%s = machine.PWM(machine.Pin(%s))\n', name, pin);
		end
		return code;
	end,
	ToMicroPython = function(self)
		local mode = "PWM"
		local name = self:getFieldAsString('name')
		local pin = self:getFieldAsString('PIN')
		local code;
		if(mode == "PinIn") then
			code = string.format('%s = machine.Pin(%s, machine.Pin.IN)\n', name, pin);
		elseif(mode == "PinOut") then
			code = string.format('%s = machine.Pin(%s, machine.Pin.OUT)\n', name, pin);
		elseif(mode == "ADC") then
			code = string.format('%s = machine.ADC(machine.Pin(%s))\n', name, pin);
		elseif(mode == "PWM") then
			code = string.format('%s = machine.PWM(machine.Pin(%s))\n', name, pin);
		end
		self:GetBlockly():AddUniqueHeader(code);
		return "";
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "machine.Pin.write_pwm", 
	message0 = L"PWM模拟输出%1赋值为%2/%3",
	arg0 = {
		{
			name = "name",
			type = "input_value",
            shadow = { type = "text", value = "pwm0",},
			text = "pwm0", 
		},
		{
			name = "pwm",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
		{
			name = "precision",
			type = "field_dropdown",
			options = {
				{ "1023", "1023" },
				{ "65535", "65535" },
			},
			text = "65535", 
		},
	},
	category = "output", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "import machine",
	func_description = '%s.duty_u16(%s) -- %s',
	ToNPL = function(self)
		local name = self:getFieldAsString('name');
		local precision = self:getFieldAsString('precision');
		if(precision == "1023") then
			return string.format('%s.duty(%s)\n', name, self:getFieldAsString('pwm'));
		else
			return string.format('%s.duty_u16(%s)\n', name, self:getFieldAsString('pwm'));
		end
	end,
	ToMicroPython = function(self)
		local name = self:getFieldAsString('name');
		local precision = self:getFieldAsString('precision');
		if(precision == "1023") then
			return string.format('%s.duty(%s)\n', name, self:getFieldAsString('pwm'));
		else
			return string.format('%s.duty_u16(%s)\n', name, self:getFieldAsString('pwm'));
		end
	end,
	examples = {{desc = "", canRun = false, code = [[
]]}},
},

{
	type = "machine.Pin.write_pwm_freq", 
	message0 = L"PWM模拟输出%1频率设为%2",
	arg0 = {
		{
			name = "name",
			type = "input_value",
            shadow = { type = "text", value = "pwm0",},
			text = "pwm0", 
		},
		{
			name = "frequency",
			type = "input_value",
            shadow = { type = "math_number", value = 2000,},
			text = 2000, 
		},
	},
	category = "output", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "import machine",
	func_description = '%s.freq(%s)',
	ToNPL = function(self)
		local name = self:getFieldAsString('name');
		return string.format('%s.freq(%s)\n', name, self:getFieldAsString('frequency'));
	end,
	ToMicroPython = function(self)
		local name = self:getFieldAsString('name');
		return string.format('%s.freq(%s)\n', name, self:getFieldAsString('frequency'));
	end,
	examples = {{desc = "", canRun = false, code = [[
]]}},
},

{
	type = "parrot.set_speed", 
	message0 = L"扩展板打开%1电源 输出功率%2",
	arg0 = {
		{
			name = "motor",
			type = "field_dropdown",
			options = {
				{ L"M1", "1" },
				{ L"M2", "2" },
			}
		},
		{
			name = "power",
			type = "input_value",
            shadow = { type = "math_number", value = 60,},
			text = 60, 
		},
	},
	category = "output", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\nimport parrot",
	func_description = 'parrot.set_speed(parrot.MOTOR_%s, -%s)',
	ToNPL = function(self)
		return string.format('parrot.set_speed(parrot.MOTOR_%s, -(%s))\n', self:getFieldAsString('motor'), self:getFieldAsString('power'));
	end,
	ToMicroPython = function(self)
		return string.format('parrot.set_speed(parrot.MOTOR_%s, -(%s))\n', self:getFieldAsString('motor'), self:getFieldAsString('power'));
	end,
	examples = {{desc = "", canRun = false, code = [[
from mpython import *
import parrot
parrot.set_speed(parrot.MOTOR_1, -(60))
]]}},
},

{
	type = "parrot.led_off", 
	message0 = L"扩展板关闭%1电源",
	arg0 = {
		{
			name = "motor",
			type = "field_dropdown",
			options = {
				{ L"M1", "1" },
				{ L"M2", "2" },
			}
		},
	},
	category = "output", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\nimport parrot",
	func_description = 'parrot.led_off(parrot.MOTOR_%s)',
	ToNPL = function(self)
		return string.format('parrot.led_off(parrot.MOTOR_%s)\n', self:getFieldAsString('motor'), self:getFieldAsString('power'));
	end,
	ToMicroPython = function(self)
		return string.format('parrot.led_off(parrot.MOTOR_%s)\n', self:getFieldAsString('motor'), self:getFieldAsString('power'));
	end,
	examples = {{desc = "", canRun = false, code = [[
]]}},
},

{
	type = "neopixel.init", 
	message0 = L"灯带初始化 名称%1 引脚%2 数量 %3",
	arg0 = {
		{
			name = "name",
			type = "input_value",
            shadow = { type = "text", value = "my_rgb",},
			text = "my_rgb", 
		},
		{
			name = "PIN",
			type = "field_dropdown",
			options = {
				{ L"P7(RGB)", "7" },
				{ L"P8", "8" },
				{ L"P9", "9" },
				{ L"P11(button_B)", "11" },
				{ L"P12", "12" },
				{ L"P13", "13" },
				{ L"P14", "14" },
				{ L"P15", "15" },
				{ L"P16", "16" },
			}
		},
		{
			name = "count",
			type = "input_value",
            shadow = { type = "math_number", value = 5,},
			text = 5, 
		},
	},
	category = "output", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\nimport neopixel",
	func_description = '%s = neopixel.NeoPixel(Pin(Pin.P%s), n=%s, bpp=3, timing=1)',
	ToNPL = function(self)
		return string.format('%s = neopixel.NeoPixel(Pin(Pin.P%s), n=%s, bpp=3, timing=1)', 
			self:getFieldAsString('name'), self:getFieldAsString('PIN'), self:getFieldAsString('count'));
	end,
	ToMicroPython = function(self)
		self:GetBlockly():AddUniqueHeader(string.format('%s = neopixel.NeoPixel(Pin(Pin.P%s), n=%s, bpp=3, timing=1)', 
			self:getFieldAsString('name'), self:getFieldAsString('PIN'), self:getFieldAsString('count')));
		return "\n";
	end,
	examples = {{desc = "", canRun = false, code = [[
]]}},
},

{
	type = "neopixel.fill", 
	message0 = L"灯带 %1 %2号 颜色为%3",
	arg0 = {
		{
			name = "name",
			type = "input_value",
            shadow = { type = "text", value = "my_rgb",},
			text = "my_rgb", 
		},
		{
			name = "index",
			type = "input_value",
            shadow = { type = "math_number", value = -1,},
			text = -1, 
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ff0000",},
			text = "#ff0000",
		},
	},
	category = "output", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\nimport neopixel",
	func_description = '%s.fill(%s)',
	ToNPL = function(self)
		local color = Color.ColorStrToValues(self:getFieldAsString('color'));
		local index = tonumber(self:getFieldAsString('index'))
		if(index == -1) then
			return string.format('%s.fill((%s,%s,%s))\n', self:getFieldAsString('name'), color[1], color[2], color[3]);
		else
			return string.format('%s[%s] = (%s,%s,%s)\n', self:getFieldAsString('name'), index, color[1], color[2], color[3]);
		end
	end,
	ToMicroPython = function(self)
		local color = Color.ColorStrToValues(self:getFieldAsString('color'));
		local index = self:getFieldAsString('index')
		if(type(index) == "string" and index:match("^%-?%d+$")) then
			index = tonumber(index)
		end
		if(index == -1) then
			return string.format('%s.fill((%s,%s,%s))\n', self:getFieldAsString('name'), color[1], color[2], color[3]);
		else
			return string.format('%s[%s] = (%s,%s,%s)\n', self:getFieldAsString('name'), index, color[1], color[2], color[3]);
		end
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "neopixel.fillRGB", 
	message0 = L"灯带 %1 %2号 R%3 G %4 B %5",
	arg0 = {
		{
			name = "name",
			type = "input_value",
            shadow = { type = "text", value = "my_rgb",},
			text = "my_rgb", 
		},
		{
			name = "index",
			type = "input_value",
            shadow = { type = "math_number", value = -1,},
			text = -1, 
		},
		{
			name = "r",
			type = "input_value",
            shadow = { type = "math_number", value = 255,},
			text = 255, 
		},
		{
			name = "g",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
		{
			name = "b",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
	},
	category = "output", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\nimport neopixel",
	func_description = '%s.fill((%s, %s, %s))',
	ToNPL = function(self)
		local index = tonumber(self:getFieldAsString('index'))
		if(index == -1) then
			return string.format('%s.fill((%s,%s,%s))\n', self:getFieldAsString('name'), self:getFieldAsString('r'), self:getFieldAsString('g'), self:getFieldAsString('b'));
		else
			return string.format('%s[%s] = (%s,%s,%s)\n', self:getFieldAsString('name'), index, self:getFieldAsString('r'), self:getFieldAsString('g'), self:getFieldAsString('b'));
		end
	end,
	ToMicroPython = function(self)
		local index = self:getFieldAsString('index')
		if(type(index) == "string" and index:match("^%-?%d+$")) then
			index = tonumber(index)
		end
		if(index == -1) then
			return string.format('%s.fill((%s,%s,%s))\n', self:getFieldAsString('name'), self:getFieldAsString('r'), self:getFieldAsString('g'), self:getFieldAsString('b'));
		else
			return string.format('%s[%s] = (%s,%s,%s)\n', self:getFieldAsString('name'), index, self:getFieldAsString('r'), self:getFieldAsString('g'), self:getFieldAsString('b'));
		end
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "neopixel.write", 
	message0 = L"灯带 %1 设置生效",
	arg0 = {
		{
			name = "name",
			type = "input_value",
            shadow = { type = "text", value = "my_rgb",},
			text = "my_rgb", 
		},
	},
	category = "output", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\nimport neopixel",
	func_description = '%s.write()',
	ToNPL = function(self)
		return string.format('%s.write()\n', self:getFieldAsString('name'));
	end,
	ToMicroPython = function(self)
		return string.format('%s.write()\n', self:getFieldAsString('name'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "neopixel.close", 
	message0 = L"灯带 %1 关闭",
	arg0 = {
		{
			name = "name",
			type = "input_value",
            shadow = { type = "text", value = "my_rgb",},
			text = "my_rgb", 
		},
	},
	category = "output", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\nimport neopixel",
	func_description = '%s.fill((0,0,0))',
	ToNPL = function(self)
		return string.format('%s.fill((0,0,0))\n', self:getFieldAsString('name'));
	end,
	ToMicroPython = function(self)
		return string.format('%s.fill((0,0,0))\n', self:getFieldAsString('name'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

});