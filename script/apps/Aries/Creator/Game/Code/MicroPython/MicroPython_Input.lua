--[[
Title: micro python
Author(s): LiXizhi
Date: 2023/8/2
Desc: 
use the lib:
-------------------------------------------------------
from mpython import *

def on_button_a_pressed(_):
    pass
button_a.event_pressed = on_button_a_pressed

def on_button_a_released(_):
    pass
button_a.event_released = on_button_a_released
-------------------------------------------------------
]]
MicroPython = NPL.load("./MicroPython.lua");

NPL.export({

{
	type = "button_a.event_pressed", 
	message0 = L"当按键%1被%2时",
	message1 = L"%1",
	arg0 = {
		{
			name = "button",
			type = "field_dropdown",
			options = {
				{ L"A", "a" },
				{ L"B", "b" },
				{ L"C", "c" },
			}
		},
		{
			name = "eventType",
			type = "field_dropdown",
			options = {
				{ L"按下", "pressed" },
				{ L"松开", "released" },
			}
		},
	},
    arg1 = {
        {
			name = "input",
			type = "input_statement",
			text = "pass",
		},
    },
	category = "input", 
	helpUrl = "", 
	canRun = false,
	funcName = "button_a.event_pressed",
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *",
	func_description = 'def on_button_%s_%s(_):\\n    %s',
    ToNPL = function(self)
		local input = self:getFieldAsString('input')
		if input == '' then
			input = 'pass'
		end
		return string.format('def on_button_%s_%s(_):\n    %s\nbutton_%s.event_%s = on_button_%s_%s\n', 
			self:getFieldAsString('button'), self:getFieldAsString('eventType'), input, 
			self:getFieldAsString('button'), self:getFieldAsString('eventType'), 
			self:getFieldAsString('button'), self:getFieldAsString('eventType'));
	end,
	ToMicroPython = function(self)
		local input = self:getFieldAsString('input')
		local block_indent = self:GetIndent();
		if input == '' then
			input = 'pass'
		end

		local global_vars = MicroPython:GetGlobalVarsDefString(self)

		return string.format('def on_button_%s_%s(_):\n%s%s\n%sbutton_%s.event_%s = on_button_%s_%s\n', 
			self:getFieldAsString('button'), self:getFieldAsString('eventType'), global_vars, input, block_indent,
			self:getFieldAsString('button'), self:getFieldAsString('eventType'), 
			self:getFieldAsString('button'), self:getFieldAsString('eventType'));
	end,
	examples = {{desc = "", canRun = true, code = [[
from mpython import *
def on_button_a_pressed(_):
    oled.fill(0)
    oled.DispChar('AA', 0, 0, 1)
    oled.show()

button_a.event_pressed = on_button_a_pressed
]]}},
},


{
	type = "button_a.is_pressed", 
	message0 = L"按键 %1 %2",
	arg0 = {
		{
			name = "button",
			type = "field_dropdown",
			options = {
				{ L"A", "a" },
				{ L"B", "b" },
			}
		},
		{
			name = "eventType",
			type = "field_dropdown",
			options = {
				{ L"已经按下", "is_pressed()" },
				{ L"曾经按下", "was_pressed()" },
				{ L"按下过的次数", "get_presses()" },
			}
		},
	},
	output = {type = "null",},
	category = "input", 
	helpUrl = "", 
	canRun = false,
	headerText = "from mpython import *",
	func_description = 'button_%s.%s',
	ToNPL = function(self)
		return string.format('button_%s.%s', self:getFieldAsString('button'), self:getFieldAsString('eventType'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "touch_button.event", 
	message0 = L"当触摸键%1被%2时",
	message1 = L"%1",
	arg0 = {
		{
			name = "button",
			type = "field_dropdown",
			options = {
				{ L"P", "p" },
				{ L"Y", "y" },
				{ L"T", "t" },
				{ L"H", "h" },
				{ L"O", "o" },
				{ L"N", "n" },
			}
		},
		{
			name = "eventType",
			type = "field_dropdown",
			options = {
				{ L"触摸", "pressed" },
				{ L"释放", "released" },
			}
		},
	},
    arg1 = {
        {
			name = "input",
			type = "input_statement",
			text = "pass",
		},
    },
	category = "input", 
	helpUrl = "", 
	canRun = false,
	funcName = "touch_button.event",
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *",
	func_description = 'def on_touchpad_%s_%s(_):\\n    %s',
    ToNPL = function(self)
		local input = self:getFieldAsString('input')
		if input == '' then
			input = 'pass'
		end
		return string.format('def on_touchpad_%s_%s(_):\n    %s\ntouchpad_%s.event_%s = on_touchpad_%s_%s\n', 
			self:getFieldAsString('button'), self:getFieldAsString('eventType'), input, 
			self:getFieldAsString('button'), self:getFieldAsString('eventType'), 
			self:getFieldAsString('button'), self:getFieldAsString('eventType'));
	end,
	ToMicroPython = function(self)
		local input = self:getFieldAsString('input')
		local block_indent = self:GetIndent();
		if input == '' then
			input = 'pass'
		end

		local global_vars = MicroPython:GetGlobalVarsDefString(self)

		return string.format('def on_touchpad_%s_%s(_):\n%s%s\n%stouchpad_%s.event_%s = on_touchpad_%s_%s\n', 
			self:getFieldAsString('button'), self:getFieldAsString('eventType'), global_vars, input, block_indent,
			self:getFieldAsString('button'), self:getFieldAsString('eventType'), 
			self:getFieldAsString('button'), self:getFieldAsString('eventType'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "sound.read", 
	message0 = L"声音值",
	arg0 = {
	},
	output = {type = "null",},
	category = "input", 
	helpUrl = "", 
	canRun = false,
	headerText = "from mpython import *",
	func_description = 'sound.read()',
	ToNPL = function(self)
		return 'sound.read()';
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "light.read", 
	message0 = L"光线值",
	arg0 = {
	},
	output = {type = "null",},
	category = "input", 
	helpUrl = "", 
	canRun = false,
	headerText = "from mpython import *",
	func_description = 'light.read()',
	ToNPL = function(self)
		return 'light.read()';
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "PIN.read_digital", 
	message0 = L"引脚%1数字值",
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
	},
	output = {type = "null",},
	category = "input", 
	helpUrl = "", 
	canRun = false,
	headerText = "from mpython import *\n",
	func_description = 'p%s.read_digital()',
	ToNPL = function(self)
		return string.format('p%s.read_digital()', self:getFieldAsString('PIN'));
	end,
	ToMicroPython = function(self)
		local pin = self:getFieldAsString('PIN');
		local analogIn = string.gsub("pXX = MPythonPin(XX, PinMode.IN)\n", "XX", pin);
		self:GetBlockly():AddUniqueHeader(analogIn);
		return string.format('p%s.read_digital()', pin);
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "PIN.read_analog", 
	message0 = L"引脚%1模拟值",
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
	},
	output = {type = "null",},
	category = "input", 
	helpUrl = "", 
	canRun = false,
	headerText = "from mpython import *\n",
	func_description = 'p%s.read_analog()',
	ToNPL = function(self)
		return string.format('p%s.read_analog()', self:getFieldAsString('PIN'));
	end,
	ToMicroPython = function(self)
		local pin = self:getFieldAsString('PIN');
		local analogIn = string.gsub("pXX = MPythonPin(XX, PinMode.ANALOG)\n", "XX", pin);
		self:GetBlockly():AddUniqueHeader(analogIn);
		return string.format('p%s.read_analog()', pin);
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "machine.Pin.Init.In", 
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
				{ L"数字输入", "PinIn" },
				{ L"模拟输入", "ADC" },
				{ L"数字输出", "PinOut" },
				{ L"PWM模拟输出", "PWM" },
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
	category = "input", 
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
	type = "machine.PIN.read_digital", 
	message0 = L"获取数字输入%1的值",
	arg0 = {
		{
			name = "PIN",
			type = "input_value",
            shadow = { type = "text", value = "pin0",},
			text = "pin0", 
		},
	},
	output = {type = "null",},
	category = "input", 
	helpUrl = "", 
	canRun = false,
	headerText = "import machine",
	func_description = '%s.value()',
	ToNPL = function(self)
		return string.format('%s.value()', self:getFieldAsString('PIN'));
	end,
	ToMicroPython = function(self)
		return string.format('%s.value()', self:getFieldAsString('PIN'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "machine.PIN.read_analog", 
	message0 = L"获取模拟输入%1的值",
	arg0 = {
		{
			name = "PIN",
			type = "input_value",
            shadow = { type = "text", value = "pin0",},
			text = "pin0", 
		},
	},
	output = {type = "null",},
	category = "input", 
	helpUrl = "", 
	canRun = false,
	headerText = "import machine",
	func_description = '%s.read_u16()',
	ToNPL = function(self)
		return string.format('%s.read_u16()', self:getFieldAsString('PIN'));
	end,
	ToMicroPython = function(self)
		return string.format('%s.read_u16()', self:getFieldAsString('PIN'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "Soil_Humidity", 
	message0 = L"土壤湿度(V2.0) %1",
	arg0 = {
		{
			name = "PIN",
			type = "field_dropdown",
			options = {
				{ L"P0", "0" },
				{ L"P1", "1" },
				{ L"P2", "2" },
				{ L"P3(EXT)", "3" },
			}
		},
	},
	output = {type = "null",},
	category = "input", 
	helpUrl = "", 
	canRun = false,
	headerText = "from mpython import *\nimport math",
	func_description = 'p%s_Soil_Humidity()',
	ToNPL = function(self)
		return string.format('p%s_Soil_Humidity()', self:getFieldAsString('PIN'));
	end,
	ToMicroPython = function(self)
		local pin = self:getFieldAsString('PIN');
		local analogIn = string.gsub("pXX = MPythonPin(XX, PinMode.ANALOG)\n", "XX", pin);
		self:GetBlockly():AddUniqueHeader(analogIn);
		local precode = string.gsub("def pXX_Soil_Humidity():\n    global pXX_soil_humidity\n    pXX_soil_humidity = pXX.read_analog()\n    if pXX_soil_humidity > 2700:\n        pXX_soil_humidity = 2700\n        return numberMap(pXX_soil_humidity,1500,2700,100,0)\n    elif pXX_soil_humidity < 1500:\n        pXX_soil_humidity = 1500\n        return numberMap(pXX_soil_humidity,1500,2700,100,0)\n    else:\n        return numberMap(pXX_soil_humidity,1500,2700,100,0)\n\n",
			"XX", pin);
		self:GetBlockly():AddUniqueHeader(precode);

		return string.format('p%s_Soil_Humidity()', pin);
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},


{
	type = "DHT11.measure", 
	message0 = L"DHT11 %1 %2",
	arg0 = {
		{
			name = "PIN",
			type = "field_dropdown",
			options = {
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
			},
			text = "13",
		},
		{
			name = "mode",
			type = "field_dropdown",
			options = {
				{ L"温度", "temperature()" },
				{ L"湿度", "humidity()" },
			}
		},
	},
	output = {type = "null",},
	category = "input", 
	helpUrl = "", 
	canRun = false,
	headerText = "from mpython import *\nimport dht\nfrom machine import Timer",
	func_description = 'dht11%s.%s',
	ToNPL = function(self)
		return string.format('dht11.%s', self:getFieldAsString('mode'));
	end,
	ToMicroPython = function(self)
		local pin = self:getFieldAsString('PIN');
		local precode = string.gsub("dht11 = dht.DHT11(Pin(Pin.PXX))\n", "XX", pin);
		self:GetBlockly():AddUniqueHeader(precode);
		local measureCode = string.gsub('timerDHT = Timer(701)\ndef timerDHT_tick(_):\n    try: dht11.measure()\n    except: pass\ntimerDHT.init(period=1000, mode=Timer.PERIODIC, callback=timerDHT_tick)\n\n',
			"XX", pin);
		self:GetBlockly():AddUniqueHeader(measureCode);

		return string.format('dht11.%s', self:getFieldAsString('mode'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},


{
	type = "Env.measure", 
	message0 = L"%1 %2",
	arg0 = {
		{
			name = "Device",
			type = "field_dropdown",
			options = {
				{ L"BME280", "BME280" },
			},
			text = "BME280",
		},
		{
			name = "mode",
			type = "field_dropdown",
			options = {
				{ L"温度", "temperature()" },
				{ L"湿度", "humidity()" },
				{ L"气压", "pressure()" },
			}
		},
	},
	output = {type = "null",},
	category = "input", 
	helpUrl = "", 
	canRun = false,
	headerText = "from mpython import *\n",
	func_description = '%s.%s',
	ToNPL = function(self)
		return string.format('bme280.%s', self:getFieldAsString('mode'));
	end,
	ToMicroPython = function(self)
		local Device = self:getFieldAsString('Device');
		if(Device == "BME280") then
			self:GetBlockly():AddUniqueHeader("bme280=BME280()\n");
			return string.format('bme280.%s', self:getFieldAsString('mode'));
		end
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},


{
	type = "chip.onshake", 
	message0 = L"当数控板%1时",
	message1 = L"%1",
	arg0 = {
		{
			name = "eventType",
			type = "field_dropdown",
			options = {
				{ L"被摇晃", "on_shaked" },
				{ L"被抛起", "on_thrown" },
				{ L"向前倾斜", "on_tilt_forward" },
				{ L"向后倾斜", "on_tilt_back" },
				{ L"向左倾斜", "on_tilt_right" },
				{ L"向右倾斜", "on_tilt_left" },
				{ L"平放", "on_tilt_none" },
			}
		},
	},
    arg1 = {
        {
			name = "input",
			type = "input_statement",
			text = "pass",
		},
    },
	category = "input", 
	helpUrl = "", 
	canRun = false,
	funcName = "chip.onshake",
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\nfrom machine import Timer",
	func_description = 'def %s():\\n    %s',
    ToNPL = function(self)
		return string.format('def %s():\\n    %s\n', 
			self:getFieldAsString('eventType'), self:getFieldAsString('input'));
	end,
	ToMicroPython = function(self)
		local input = self:getFieldAsString('input')
		local block_indent = self:GetIndent();
		if input == '' then
			input = 'pass'
		end
		local precode = [[
_is_shaked = _is_thrown = False
_last_x = _last_y = _last_z = _count_shaked = _count_thrown = 0
def on_shaked():pass
def on_thrown():pass

_dir = ''
def on_tilt_forward():pass
def on_tilt_back():pass
def on_tilt_right():pass
def on_tilt_left():pass
def on_tilt_none():pass

timerAccelerometer = Timer(11)
def timerAccelerometerTick(_):
    global _dir, _is_shaked, _is_thrown, _last_x, _last_y, _last_z, _count_shaked, _count_thrown
    if _is_shaked:
        _count_shaked += 1
        if _count_shaked == 5: _count_shaked = 0
    if _is_thrown:
        _count_thrown += 1
        if _count_thrown == 10: _count_thrown = 0
        if _count_thrown > 0: return
    x=accelerometer.get_x(); y=accelerometer.get_y(); z=accelerometer.get_z()
    _is_thrown = (x * x + y * y + z * z < 0.25)
    if _is_thrown: on_thrown();return
    if _last_x == 0 and _last_y == 0 and _last_z == 0:
        _last_x = x; _last_y = y; _last_z = z; return
    diff_x = x - _last_x; diff_y = y - _last_y; diff_z = z - _last_z
    _last_x = x; _last_y = y; _last_z = z
    if _count_shaked > 0: return
    _is_shaked = (diff_x * diff_x + diff_y * diff_y + diff_z * diff_z > 1)
    if _is_shaked: on_shaked()
	if x < -0.3:
        if 'F' != _dir:_dir = 'F';on_tilt_forward()
    elif x > 0.3:
        if 'B' != _dir:_dir = 'B';on_tilt_back()
    elif y < -0.3:
        if 'R' != _dir:_dir = 'R';on_tilt_right()
    elif y > 0.3:
        if 'L' != _dir:_dir = 'L';on_tilt_left()
    else:
        if '' != _dir:_dir = '';on_tilt_none()
timerAccelerometer.init(period=150, mode=Timer.PERIODIC, callback=timerAccelerometerTick)
]]
		self:GetBlockly():AddUniqueHeader(precode);

		local global_vars = MicroPython:GetGlobalVarsDefString(self)

		return string.format('def %s():\n%s%s\n', 
			self:getFieldAsString('eventType'), global_vars, input);
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "accelerometor.get", 
	message0 = L"%1轴加速度",
	arg0 = {
		{
			name = "axis",
			type = "field_dropdown",
			options = {
				{ L"X", "x" },
				{ L"Y", "y" },
				{ L"Z", "z" },
			}
		},
	},
	output = {type = "null",},
	category = "input", 
	helpUrl = "", 
	canRun = false,
	headerText = "from mpython import *",
	func_description = 'accelerometer.get_%s()',
	ToNPL = function(self)
		return string.format('accelerometer.get_%s()', self:getFieldAsString('axis'));
	end,
	ToMicroPython = function(self)
		return string.format('accelerometer.get_%s()', self:getFieldAsString('axis'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "gyroscope.get", 
	message0 = L"%1轴角速度",
	arg0 = {
		{
			name = "axis",
			type = "field_dropdown",
			options = {
				{ L"X", "x" },
				{ L"Y", "y" },
				{ L"Z", "z" },
			}
		},
	},
	output = {type = "null",},
	category = "input", 
	helpUrl = "", 
	canRun = false,
	headerText = "from mpython import *",
	func_description = 'gyroscope.get_%s()',
	ToNPL = function(self)
		return string.format('gyroscope.get_%s()', self:getFieldAsString('axis'));
	end,
	ToMicroPython = function(self)
		return string.format('gyroscope.get_%s()', self:getFieldAsString('axis'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "tiltAngle.get", 
	message0 = L"%1轴倾斜角",
	arg0 = {
		{
			name = "axis",
			type = "field_dropdown",
			options = {
				{ L"X", "'X'" },
				{ L"Y", "'Y'" },
				{ L"Z", "'Z'" },
			}
		},
	},
	output = {type = "null",},
	category = "input", 
	helpUrl = "", 
	canRun = false,
	headerText = "from mpython import *",
	func_description = 'get_tilt_angle(%s)',
	ToNPL = function(self)
		return string.format('get_tilt_angle(%s)', self:getFieldAsString('axis'));
	end,
	ToMicroPython = function(self)
		self:GetBlockly():AddUniqueHeader([[
def get_tilt_angle(_axis):
    _Ax = accelerometer.get_x()
    _Ay = accelerometer.get_y()
    _Az = accelerometer.get_z()
    if 'X' == _axis:
        _T = math.sqrt(_Ay ** 2 + _Az ** 2)
        if _Az < 0: return math.degrees(math.atan2(_Ax , _T))
        else: return 180 - math.degrees(math.atan2(_Ax , _T))
    elif 'Y' == _axis:
        _T = math.sqrt(_Ax ** 2 + _Az ** 2)
        if _Az < 0: return math.degrees(math.atan2(_Ay , _T))
        else: return 180 - math.degrees(math.atan2(_Ay , _T))
    elif 'Z' == _axis:
        _T = math.sqrt(_Ax ** 2 + _Ay ** 2)
        if (_Ax + _Ay) < 0: return 180 - math.degrees(math.atan2(_T , _Az))
        else: return math.degrees(math.atan2(_T , _Az)) - 180
    return 0
]]);
		return string.format('get_tilt_angle(%s)', self:getFieldAsString('axis'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},


{
	type = "machine.reset", 
	message0 = L"复位",
	arg0 = {
	},
	category = "input", 
	helpUrl = "", 
	canRun = false,
	funcName = "machine.reset",
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\nimport machine",
	func_description = 'machine.reset()',
    ToNPL = function(self)
		return 'machine.reset()\n';
	end,
	ToMicroPython = function(self)
		return 'machine.reset()\n';
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

});