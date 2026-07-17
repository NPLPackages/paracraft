--[[
Title: micro python
Author(s): LiXizhi
Date: 2023/8/2
Desc: 
use the lib:
-------------------------------------------------------
import network
my_wifi = wifi()
my_wifi.connectWiFi("TP-LINK_BFAA", "86571207tc")
-------------------------------------------------------
]]
MicroPython = NPL.load("./MicroPython.lua");
local function trimString(strText)
	if not strText or strText == "" then
		return ""
	end
	return strText:gsub("^%s+", ""):gsub("%s+$", ""):gsub("[\r\n]+", "")
end

local function filterString(strText)
	if not strText or strText == "" then
		return ""
	end
	return strText:gsub("[\r\n]+", "")
end

NPL.export({

{
	type = "cmdExamples", 
	message0 = "%1",
	arg0 = {
		{
			name = "value",
			type = "field_dropdown",
			options = {
				{ L"/tip", "tip" },
				{ L"发送事件", "sendevent" },
				{ L"改变时间[-1,1]", "time"},
				{ L"加载世界:项目id", "loadworld"},
			},
		},
	},
	hide_in_toolbox = true,
	category = "wifi", 
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
	type = "paracraft.runCmd", 
	message0 = L"向主机发命令%1 内容%2",
	arg0 = {
		{
			name = "cmdName",
			type = "input_value",
			shadow = { type = "text", value = "sendevent",},
            -- shadow = { type = "cmdExamples", value = "sendevent",},
			text = "sendevent", 
		},
		{
			name = "cmdParams",
			type = "input_value",
            shadow = { type = "text", value = "hello msg",},
			text = "hello msg", 
		},
	},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "",
	func_description = 'print("/%s %s")',
	ToNPL = function(self)
		local cmdName = self:getFieldAsString('cmdName')
		cmdName = cmdName:gsub("^/", "");
		return string.format('print("/%s %s")\n', cmdName, self:getFieldAsString('cmdParams'));
	end,
	ToMicroPython = function(self)
		local cmdName = self:GetValueAsString('cmdName')
		cmdName = cmdName:gsub("^([\"'])/", "%1");
		return string.format('print("/"+str(%s)+" "+str(%s))\n', cmdName, self:GetValueAsString('cmdParams'));
	end,
	examples = {{desc = "", canRun = false, code = [[
print("/tip hello")
print("/sendevent hello {'msg'}")
]]}},
},


{
	type = "network.wifi", 
	message0 = L"连接Wi-Fi 名称 %1 密码 %2",
	arg0 = {
		{
			name = "username",
			type = "input_value",
            shadow = { type = "text", value = "username",},
			text = "username", 
		},
		{
			name = "password",
			type = "input_value",
            shadow = { type = "text", value = "password",},
			text = "password", 
		},
	},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	funcName = "network.wifi",
	previousStatement = true,
	nextStatement = true,
	headerText = "import network\nimport time",
	func_description = 'my_wifi.connectWiFi(%s, %s)',
	ToNPL = function(self)
		local username, password = self:getFieldAsString('username'), self:getFieldAsString('password')
		username = trimString(username);
		password = trimString(password);
		local code = format("wifi = network.WLAN(network.STA_IF)\nwifi.active(True)\nwifi.connect('%s', '%s')\n", username, password)
		return code;
	end,
	ToMicroPython = function(self)
		self:GetBlockly():AddUniqueHeader("wifi = network.WLAN(network.STA_IF)", 2);
		local username, password = self:GetValueAsString('username'), self:GetValueAsString('password')
		username = trimString(username);
		password = trimString(password);
		local block_indent = self:GetIndent();
		-- wait 500ms for 20 iterations, timeout is 10 seconds. 
		local waitTillConnected = format("[time.sleep_ms(500) for _ in range(20) if not wifi.isconnected()]; print(%s + ': wifi connected') if wifi.isconnected() else print('Wifi failed to connect:' + %s); print(wifi.ifconfig()) if wifi.isconnected() else None", username, username)
		local code = format("if wifi.isconnected(): wifi.disconnect(); time.sleep(0.5) \n%swifi.active(True)\n%swifi.connect(%s, %s)\n%s%s\n", block_indent, block_indent, username, password, block_indent, waitTillConnected)
		return code;
	end,
	examples = {{desc = "", canRun = true, code = [[
import network
wifi = network.WLAN(network.STA_IF)
wifi.active(True)
wifi.connect('PLK123', '123456plk')

if wifi.isconnected():
    oled.fill(0)
    oled.DispChar(str('connected'), 0, 0, 1)
    oled.show()
]]}},
},

{
	type = "network.wifi.isconnected", 
	message0 = L"已连接到Wi-fi",
	arg0 = {
	},
	output = {type = "null",},
	category = "wifi", 
	helpUrl = "", 
	funcName = "wifi.isconnected",
	canRun = false,
	headerText = "import network",
	func_description = 'wifi.isconnected()',
	ToNPL = function(self)
		return "wifi.isconnected()";
	end,
	ToMicroPython = function(self)
		self:GetBlockly():AddUniqueHeader("wifi = network.WLAN(network.STA_IF)", 2);
		return "wifi.isconnected()";
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "network.wifi_AP", 
	message0 = L"开启WiFi热点AP 名称 %1 密码 %2 信道 %3",
	arg0 = {
		{
			name = "username",
			type = "input_value",
            shadow = { type = "text", value = "myWifi",},
			text = "myWifi", 
		},
		{
			name = "password",
			type = "input_value",
            shadow = { type = "text", value = "",},
			text = "", 
		},
		{
			name = "channel",
			type = "input_value",
            shadow = { type = "math_number", value = 11,},
			text = 11, 
		},
	},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	funcName = "network.wifi",
	previousStatement = true,
	nextStatement = true,
	headerText = "import network",
	func_description = 'my_wifi.enable_APWiFi(%s, %s, %s)',
	ToNPL = function(self)
		local username, password = self:getFieldAsString('username'), self:getFieldAsString('password')
		local authmode = password ~= "" and 4 or 0;
		local channel = self:getFieldAsString('channel')
		local code = format("wlan = network.WLAN(network.AP_IF)\nwlan.active(True)\nwlan.config(essid='%s', password='%s', authmode=%d, channel=%s)\n", username, password, authmode, channel)
		return code;
	end,
	ToMicroPython = function(self)
		self:GetBlockly():AddUniqueHeader("wlan = network.WLAN(network.AP_IF)", 2);
		local username, password = self:getFieldAsString('username'), self:getFieldAsString('password')
		local authmode = password ~= "" and 4 or 0;
		local channel = self:getFieldAsString('channel')
		local block_indent = self:GetIndent();
		local code = format("wlan.active(True)\n%swlan.config(essid='%s', password='%s', authmode=%d, channel=%s)\n", block_indent, username, password, authmode, channel)
		return code;
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "network.udp_socket_open", 
	message0 = L"开启UDP 侦听端口%1",
	arg0 = {
		{
			name = "port",
			type = "input_value",
            shadow = { type = "math_number", value = 8099,},
			text = 8099, 
		},
	},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	funcName = "network.udp_socket_open",
	previousStatement = true,
	nextStatement = true,
	headerText = "import network\nimport usocket",
	func_description = 'socket_udp.bind(("0.0.0.0", %s))',
	ToNPL = function(self)
		return string.format('socket_udp.bind(("0.0.0.0", %s))\n', self:getFieldAsString('port'));
	end,
	ToMicroPython = function(self)
		self:GetBlockly():AddUniqueHeader("socket_udp = usocket.socket(usocket.AF_INET, usocket.SOCK_DGRAM)", 4);
		return string.format('socket_udp.bind(("0.0.0.0", %s))\n', self:getFieldAsString('port'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "network.udp_socket_send", 
	message0 = L"UDP 发送消息 %1 到 %2 端口 %3",
	arg0 = {
		{
			name = "data",
			type = "input_value",
            shadow = { type = "text", value = "hello",},
			text = "hello", 
		},
		{
			name = "ip",
			type = "input_value",
            shadow = { type = "text", value = "255.255.255.255",},
			text = "255.255.255.255", 
		},
		{
			name = "port",
			type = "input_value",
            shadow = { type = "math_number", value = 8099,},
			text = 8099, 
		},
	},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	funcName = "network.udp_socket_send",
	previousStatement = true,
	nextStatement = true,
	headerText = "import network\nimport usocket",
	func_description = 'socket_udp.sendto(bytes(%s, "utf-8"), (%s, %s))',
	ToNPL = function(self)
		return string.format('socket_udp.sendto(bytes("%s", "utf-8"), ("%s", %s))\n', self:getFieldAsString('data'), self:getFieldAsString('ip'), self:getFieldAsString('port'));
	end,
	ToMicroPython = function(self)
		self:GetBlockly():AddUniqueHeader("socket_udp = usocket.socket(usocket.AF_INET, usocket.SOCK_DGRAM)", 4);
		local block_indent = self:GetIndent();
		return string.format('try: socket_udp.sendto(bytes(%s, "utf-8"), (%s, %s))\n%sexcept: pass\n', self:GetValueAsString('data'), self:GetValueAsString('ip'), self:getFieldAsString('port'), block_indent);
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "network.udp_socket_broadcast", 
	message0 = L"UDP 广播消息 %1 到端口 %2",
	arg0 = {
		{
			name = "data",
			type = "input_value",
            shadow = { type = "text", value = "hello",},
			text = "hello", 
		},
		{
			name = "port",
			type = "input_value",
            shadow = { type = "math_number", value = 8099,},
			text = 8099, 
		},
	},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	funcName = "network.udp_socket_broadcast",
	previousStatement = true,
	nextStatement = true,
	headerText = "import network\nimport usocket",
	func_description = 'socket_udp.sendto(bytes(%s, "utf-8"), ("255.255.255.255", %s))',
	ToNPL = function(self)
		return string.format('socket_udp.sendto(bytes("%s", "utf-8"), ("%s", %s))\n', self:getFieldAsString('data'), "255.255.255.255", self:getFieldAsString('port'));
	end,
	ToMicroPython = function(self)
		self:GetBlockly():AddUniqueHeader("socket_udp = usocket.socket(usocket.AF_INET, usocket.SOCK_DGRAM)", 4);
		local block_indent = self:GetIndent();
		return string.format('try: socket_udp.sendto(bytes(%s, "utf-8"), ("%s", %s))\n%sexcept: pass\n', self:GetValueAsString('data'), "255.255.255.255", self:getFieldAsString('port'), block_indent);
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "mqtt.udp_socket_receive", 
	message0 = L"当从UDP 接受到消息%1时",
	message1 = L"%1",
	arg0 = {
		{
			name = "msg",
			type = "field_variable",
            text = "msg", 
		},
	},
	arg1 = {
		{
			name = "input",
			type = "input_statement",
			text = "pass",
		},
	},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	funcName = "mqtt.udp_socket_receive",
	previousStatement = true,
	nextStatement = true,
	headerText = "import usocket\nimport _thread",
	func_description = 'mqtt.subscribe(%s)\n    %s',
	ToNPL = function(self)
		return string.format([[
def udp_recv("%s"):
    pass

def thread_udp():
    while True:
        try:
            _msg = socket_udp.recv(1024)
            if _msg: udp_recv(_msg.decode("UTF-8", "ignore"))
        except: pass

_thread.start_new_thread(thread_udp, ())
		]], self:getFieldAsString('msg'))
	end,
	ToMicroPython = function(self)
		self:GetBlockly():AddUniqueHeader([[
def thread_udp():
    while True:
        try:
            _msg = socket_udp.recv(1024)
            if _msg: udp_recv(_msg.decode("UTF-8", "ignore"))
        except: pass

_thread.start_new_thread(thread_udp, ())
]], 6);
		local block_indent = self:GetIndent();
		self:SetIndent("") -- tricky: since we are moving the code to header, so we need to remove the indent
		local input = self:getFieldAsString('input');
		
		local global_vars = MicroPython:GetGlobalVarsDefString(self, {[self:getFieldAsString('msg')] = true})
		local cbCode = string.format("def udp_recv(%s):\n%s%s\n", self:getFieldAsString('msg'), global_vars, input);
		self:SetIndent(block_indent)
		self:GetBlockly():AddUniqueHeader(cbCode, 5);

		return "";
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},


{
	type = "mqtt", 
	message0 = L"MQTT client_id %1 %2 服务器 %3 端口 %4",
	message1 = L"用户名 %1 密码 %2",
	message2 = L"keepalive %1",
	arg0 = {
		{
			name = "client_id",
			type = "input_value",
            shadow = { type = "text", value = "",},
			text = "", 
		},
		{
			OnClick="mqtt_config",
			name="add",
			text="Texture/Aries/Creator/keepwork/ggs/blockly/plus_13x13_32bits.png#0 0 13 13",
			type="field_image" 
		},
		{
			name = "server",
			type = "input_value",
            shadow = { type = "text", value = "mqtt.keepwork.com",},
			text = "mqtt.keepwork.com", 
		},
		{
			name = "port",
			type = "input_value",
            shadow = { type = "math_number", value = 18883,},
			text = 18883, 
		},
	},
	arg1 = {
		{
			name = "username",
			type = "input_value",
            shadow = { type = "text", value = "",},
			text = "", 
		},
		{
			name = "password",
			type = "input_value",
            shadow = { type = "text", value = "", isPassWord = true},
			text = "", 
			isPassWord = true,
		},
	},
	arg2 = {
		{
			name = "keepalive",
			type = "input_value",
            shadow = { type = "math_number", value = 30,},
			text = 30, 
		},
	},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	funcName = "MQTTClient",
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\nfrom umqtt.simple import MQTTClient",
	func_description = 'mqtt = MQTTClient(%s, %s, %s, %s, %s, %s)',
	ToNPL = function(self)
		local username = self:getFieldAsString('username')
		local password = self:getFieldAsString('password')
		username = trimString(username);
		password = trimString(password);
		return string.format('mqtt = MQTTClient("%s", "%s", %s, "%s", "%s", %s)\n', self:getFieldAsString('client_id'), 
			self:getFieldAsString('server'), self:getFieldAsString('port'),username, password,
			self:getFieldAsString('keepalive'));
	end,
	ToMicroPython = function(self)
		local username = self:GetValueAsString('username')
		local password = self:GetValueAsString('password')
		username = trimString(username);
		password = trimString(password);
		return string.format('mqtt = MQTTClient(%s, %s, %s, %s, %s, %s)\n', self:GetValueAsString('client_id'), 
			self:GetValueAsString('server'), self:getFieldAsString('port'),
			username, password,self:getFieldAsString('keepalive'));
	end,
	examples = {{desc = "", canRun = true, code = [[
from umqtt.simple import MQTTClient
mqtt = MQTTClient('mpy', 'mqtt.keepwork.com', 18883, 'liuqi672', '86571207tc', 30)
try:
    mqtt.connect()
    print('Connected')
except:
    print('Disconnected')
]]}},
},

{
	type = "mqtt_paracraft", 
	message0 = L"帕拉卡MQTT client_id %1  用户名 %2 密码 %3",
	arg0 = {
		{
			name = "client_id",
			type = "input_value",
            shadow = { type = "text", value = "",},
			text = "", 
		},
		{
			name = "username",
			type = "input_value",
            shadow = { type = "text", value = System.User.username or "",},
			text = System.User.username or "", 
		},
		{
			name = "password",
			type = "input_value",
            shadow = { type = "text", value = "", isPassWord = true},
			text = "", 
			isPassWord = true,
		},
	},
	category = "wifi", 
	helpUrl = "", 
	canRun = false, 
	hide_in_toolbox = true,
	funcName = "MQTTClient_paracraft",
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\nfrom umqtt.simple import MQTTClient",
	func_description = 'mqtt = MQTTClient(%s, "iot.keepwork.com", "1883", %s, %s, 30)',
	ToNPL = function(self)
		return string.format('mqtt = MQTTClient("%s", "iot.keepwork.com", 1883, "%s", "%s", 30)\n', 
			self:getFieldAsString('client_id'), self:getFieldAsString('username'), 
			self:getFieldAsString('password'));
	end,
	ToMicroPython = function(self)
		local username = self:GetValueAsString('username')
		local password = self:GetValueAsString('password')
		username = trimString(username);
		password = trimString(password);
		return string.format('mqtt = MQTTClient(%s, "iot.keepwork.com", 1883, %s, %s, 30)\n', 
			self:GetValueAsString('client_id'),username, password);
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "MQTT.connect", 
	message0 = L"连接MQTT",
	arg0 = {
	},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\nfrom umqtt.simple import MQTTClient\nfrom machine import Timer\nimport time",
	func_description = 'mqtt.connect()',
	ToNPL = function(self)
		return string.format("try:\n    mqtt.connect()\n    print('MQTT Connected')\nexcept:\n    print('MQTT Disconnected')\ndef timerMqtt_tick(_):\n    mqtt.ping()\ntimerMqtt = Timer(99)\ntimerMqtt.init(period=20000, mode=Timer.PERIODIC, callback=timerMqtt_tick)\n");
	end,
	ToMicroPython = function(self)
		local block_indent = self:GetIndent();
		local block_indent2 = block_indent .. self:GetBlockly().Const.Indent
		local id = self:GetBlockly():GetNextId();
		return string.format("try:\n%smqtt.connect()\n%sprint('MQTT Connected')\n%sexcept:\n%sprint('MQTT Disconnected')\n%sdef timerMqtt_tick(_):\n%smqtt.ping()\n%stimerMqtt = Timer(99)\n%stimerMqtt.init(period=20000, mode=Timer.PERIODIC, callback=timerMqtt_tick)\n", 
			block_indent2, block_indent2, block_indent, block_indent2, block_indent, block_indent2, block_indent, block_indent);
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},


{
	type = "mqtt.subscribe", 
	message0 = L"当从主题 %1 %2 接受到消息时",
	message1 = L"%1",
	arg0 = {
		{
			name = "topic",
			type = "input_value",
            shadow = { type = "text", value = (System.User.username or "").."/name",},
			text = (System.User.username or "").."/name", 
		},
		{
			OnClick="mqtt_config",
			name="add",
			text="Texture/Aries/Creator/keepwork/ggs/blockly/plus_13x13_32bits.png#0 0 13 13",
			type="field_image" 
		},
	},
	arg1 = {
			{
				name = "input",
				type = "input_statement",
				text = "pass",
			},
		},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	funcName = "mqtt.subscribe",
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\nfrom umqtt.simple import MQTTClient",
	func_description = 'mqtt.subscribe(%s)\n    %s',
	ToNPL = function(self)
		local precode = "def mqtt_callback(topic, msg):\n    try:\n        topic = topic.decode('utf-8', 'ignore')\n        _msg = msg.decode('utf-8', 'ignore')\n        eval('mqtt_topic_' + str(topic) + '(\"' + _msg + '\")')\n    except: print((topic, msg))\nmqtt.set_callback(mqtt_callback)\n"
		local input = self:getFieldAsString('input');
		if(input == "") then
			input = "pass"
		end
		local cbCode = string.format("def mqtt_topic_%s(_msg):\n    %s\n", self:getFieldAsString('topic'), input);
		return string.format('%s\n%s\nmqtt.subscribe("%s")\n', precode, cbCode, self:getFieldAsString('topic'));
	end,
	ToMicroPython = function(self)
		local hexFunc  =  'def str2name(str):\n    return "".join([c if (c.isalpha() or c.isdigit() or c==\'_\') else "_%x" % ord(c) for c in str])\n';
		self:GetBlockly():AddUniqueHeader(hexFunc );
		local precode = "def mqtt_callback(topic, msg):\n    try:\n        topic = topic.decode('utf-8', 'ignore')\n        _msg = msg.decode('utf-8', 'ignore')\n        eval('mqtt_topic_' + str2name(topic) + \"('\" + _msg + \"')\")\n    except: print((topic, msg))\n"
		self:GetBlockly():AddUniqueHeader(precode);
		local block_indent = self:GetIndent();
		self:SetIndent("") -- tricky: since we are moving the code to header, so we need to remove the indent
		local input = self:getFieldAsString('input');
		
		local global_vars = MicroPython:GetGlobalVarsDefString(self)

		local cbCode = string.format("def mqtt_topic_%s(_msg):\n%s%s\n", commonlib.Encoding.toValidParamName(self:getFieldAsString('topic')), global_vars, input);
		self:SetIndent(block_indent)

		self:GetBlockly():AddUniqueHeader(cbCode);
		return string.format('mqtt.set_callback(mqtt_callback)\nmqtt.subscribe(%s)\n', self:GetValueAsString('topic'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},


{
	type = "mqtt.msg", 
	message0 = L"从MQTT接收到的消息",
	arg0 = {
	},
	output = {type = "null",},
	category = "wifi", 
	helpUrl = "", 
	funcName = "mqtt.msg",
	canRun = false,
	headerText = "",
	func_description = '_msg',
	ToNPL = function(self)
		return "_msg";
	end,
	ToMicroPython = function(self)
		return "_msg";
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "mqtt.check_msg", 
	message0 = L"等待主题消息以%1模式",
	arg0 = {
		{
			name = "mode",
			type = "field_dropdown",
			options = {
				{ L"非阻塞", "check_msg()" },
				{ L"阻塞", "wait_msg()" },
			}
		},
	},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\nfrom umqtt.simple import MQTTClient",
	func_description = 'mqtt.%s',
	ToNPL = function(self)
		return string.format("mqtt.%s\n", self:getFieldAsString('mode'));
	end,
	ToMicroPython = function(self)
		return string.format("mqtt.%s\n", self:getFieldAsString('mode'));
	end,
	examples = {{desc = "", canRun = true, code = [[
for i in range(1, 10):
    mqtt.publish('test', str(i))
    time.sleep(1)
    mqtt.check_msg()
]]}},
},

{
	type = "mqtt.publish", 
	message0 = L"发布到主题 %1 %2 内容 %3",
	arg0 = {
		{
			name = "topic",
			type = "input_value",
            shadow = { type = "text", value = (System.User.username or "").."/name",},
			text = (System.User.username or "").."/name", 
		},
		{
			OnClick="mqtt_config",
			name="add",
			text="Texture/Aries/Creator/keepwork/ggs/blockly/plus_13x13_32bits.png#0 0 13 13",
			type="field_image" 
		},
		{
			name = "data",
			type = "input_value",
            shadow = { type = "text", value = "",},
			text = "", 
		},
	},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\nfrom umqtt.simple import MQTTClient",
	func_description = 'mqtt.publish(%s, %s)',
	ToNPL = function(self)
		local topic = self:getFieldAsString('topic');
		topic = filterString(topic);
		return string.format('try:\n   mqtt.publish("%s", "%s")\n except:\n   print("MQTT msg name: %s Published Failed")\n', topic, self:getFieldAsString('data'), topic);
	end,
	ToMicroPython = function(self)
		local block_indent = self:GetIndent();
		local block_indent2 = block_indent .. self:GetBlockly().Const.Indent
		local topic = self:GetValueAsString('topic');
		topic = filterString(topic);
		return string.format('try:\n%smqtt.publish(%s, %s)\n%sprint("MQTT Published Success")\n%sexcept:\n%sprint("MQTT msg name: %s Published Failed")\n',block_indent2, topic, self:GetValueAsString('data'),block_indent2, block_indent,block_indent2,topic);
	end,
	examples = {{desc = "", canRun = false, code = [[
]]}},
},


{
	type = "i2c.Init", 
	message0 = L"初始化%1 SCL%2 SDA%3 速率%4",
	arg0 = {
		{
			name = "name",
			type = "field_dropdown",
			options = {
				{ L"i2c_1", "i2c_1" },
				{ L"i2c_2", "i2c_2" },
			}
		},
		{
			name = "SCL",
			type = "input_value",
			shadow = { type = "text", value = "P13",},
			text = "P13",
		},
		{
			name = "SDA",
			type = "input_value",
			shadow = { type = "text", value = "P14",},
			text = "P14",
		},
		{
			name = "Frequency",
			type = "input_value",
			shadow = { type = "text", value = "400000",},
			text = "400000",
		},
	},
	output = {type = "null",},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "",
	func_description = '%s = I2C(scl=Pin(Pin.%s), sda=Pin(Pin.%s), freq=%s)',
	ToNPL = function(self)
		local scl = self:getFieldAsString('SCL')
		if(scl and scl:match("^P%d")) then
			local headerText = "from mpython import *\n"
			return string.format('%s%s = I2C(scl=Pin(Pin.%s), sda=Pin(Pin.%s), freq=%s)\n', headerText,
				self:getFieldAsString('name'),self:getFieldAsString('SCL'),self:getFieldAsString('SDA'),self:getFieldAsString('Frequency'));
		else
			local headerText = "import machine\n"
			return string.format('%s%s = machine.I2C(scl=machine.Pin(%s), sda=machine.Pin(%s), freq=%s)\n', headerText,
				self:getFieldAsString('name'),self:getFieldAsString('SCL'),self:getFieldAsString('SDA'),self:getFieldAsString('Frequency'));
		end
	end,
	ToMicroPython = function(self)
		local scl = self:getFieldAsString('SCL')
		local code;
		-- tricky: if a number is used, we will use machine.I2C
		if(scl and scl:match("^P%d")) then
			self:GetBlockly():AddUniqueHeader("from mpython import *");
			code = string.format('%s = I2C(scl=Pin(Pin.%s), sda=Pin(Pin.%s), freq=%s)\n', 
				self:getFieldAsString('name'),self:getFieldAsString('SCL'),self:getFieldAsString('SDA'),self:getFieldAsString('Frequency'));
		else
			self:GetBlockly():AddUniqueHeader("import machine");
			code = string.format('%s = machine.I2C(scl=machine.Pin(%s), sda=machine.Pin(%s), freq=%s)\n', 
				self:getFieldAsString('name'),self:getFieldAsString('SCL'),self:getFieldAsString('SDA'),self:getFieldAsString('Frequency'));
		end
		self:GetBlockly():AddUniqueHeader(code);
		return "";
	end,
	examples = {{desc = "", canRun = true, code = [[
from mpython import *
i2c_1 = I2C(scl=Pin(Pin.P13), sda=Pin(Pin.P14), freq=400000)
i2c_1.writeto(1, (bytearray([2, 80, 0,80,0])), True)

import machine
i2c_2 = machine.SoftI2C(scl = machine.Pin(22), sda = machine.Pin(21), freq = 100000)
i2c_2.readfrom(0, 0)
i2c_2.writeto(0, 0)
]]}},
},

{
	type = "i2c.writeto", 
	message0 = L"%1 设备地址 %2 写入数据bytearray[%3] 停止位%4",
	arg0 = {
		{
			name = "name",
			type = "field_dropdown",
			options = {
				{ L"i2c", "i2c" },
				{ L"i2c_1", "i2c_1" },
				{ L"i2c_2", "i2c_2" },
			}
		},
		{
			name = "address",
			type = "input_value",
            shadow = { type = "math_number", value = 38,},
			text = 1, 
		},
		{
			name = "data",
			type = "input_value",
            shadow = { type = "text", value = "",},
			text = "2, 80,0,80,0", 
		},
		{
			name = "endingBit",
			type = "field_dropdown",
			options = {
				{ L"真", "True" },
				{ L"假", "False" },
			  }
		},
	},
	output = {type = "null",},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\n",
	func_description = '%s.writeto(%s, bytearray([%s])), %s)',
	ToNPL = function(self)
		return string.format('%s.writeto(%s, (bytearray([%s])), %s)\n', 
			self:getFieldAsString('name'),self:getFieldAsString('address'),self:getFieldAsString('data'),self:getFieldAsString('endingBit'));
	end,
	ToMicroPython = function(self)
		local name = self:getFieldAsString('name');
		if(name == "i2c") then
			self:GetBlockly():AddUniqueHeader("from mpython import *");
		end
		return string.format('%s.writeto(%s, (bytearray([%s])), %s)\n', 
			name,self:getFieldAsString('address'),self:getFieldAsString('data'),self:getFieldAsString('endingBit'));
	end,
	examples = {{desc = "", canRun = true, code = [[
from mpython import *
i2c_1 = I2C(scl=Pin(Pin.P13), sda=Pin(Pin.P14), freq=400000)
i2c_1.writeto(1, (bytearray([2, 80, 0,80,0])), True)
]]}},
},

{
	type = "i2c.readfrom", 
	message0 = L"%1 设备地址 %2 读取字节数%3 停止位%4",
	arg0 = {
		{
			name = "name",
			type = "field_dropdown",
			options = {
				{ L"i2c", "i2c" },
				{ L"i2c_1", "i2c_1" },
				{ L"i2c_2", "i2c_2" },
			}
		},
		{
			name = "address",
			type = "input_value",
            shadow = { type = "math_number", value = 38,},
			text = 1, 
		},
		{
			name = "byteCount",
			type = "input_value",
            shadow = { type = "math_number", value = 38,},
			text = 1, 
		},
		{
			name = "endingBit",
			type = "field_dropdown",
			options = {
				{ L"真", "True" },
				{ L"假", "False" },
			  }
		},
	},
	output = {type = "null",},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	headerText = "",
	func_description = '%s.readfrom(%s, %s, %s)',
	ToNPL = function(self)
		return string.format('%s.readfrom(%s, %s, %s)\n', 
			self:getFieldAsString('name'),self:getFieldAsString('address'),self:getFieldAsString('byteCount'),self:getFieldAsString('endingBit'));
	end,
	ToMicroPython = function(self)
		local name = self:getFieldAsString('name');
		if(name == "i2c") then
			self:GetBlockly():AddUniqueHeader("from mpython import *");
		end
		return string.format('%s.readfrom(%s, %s, %s)\n', 
			name,self:getFieldAsString('address'),self:getFieldAsString('byteCount'),self:getFieldAsString('endingBit'));
	end,
	examples = {{desc = "", canRun = true, code = [[
from mpython import *
i2c_1 = I2C(scl=Pin(Pin.P13), sda=Pin(Pin.P14), freq=400000)
A = i2c_1.readfrom(1, 1, True)
]]}},
},

{
	type = "i2c.motor", 
	message0 = L"设置马达速度 M1 %1 M2 %2",
	arg0 = {
		{
			name = "M1",
			type = "input_value",
            shadow = { type = "math_number", value = 70,},
			text = 70, 
		},
		{
			name = "M2",
			type = "input_value",
            shadow = { type = "math_number", value = -70,},
			text = -70, 
		},
	},
	output = {type = "null",},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	funcName = "i2c.motor",
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\n",
	func_description = 'i2c.writeto(1, (bytearray([2, %s, 0, %s,0])), True)',
	ToNPL = function(self)
		return string.format('i2c.writeto(1, (bytearray([2, %s, 0, %s,0])), True)\n', 
			self:getFieldAsString('M1'),self:getFieldAsString('M2'));
	end,
	ToMicroPython = function(self)
		self:GetBlockly():AddUniqueHeader("i2c_1 = I2C(scl=Pin(Pin.P13), sda=Pin(Pin.P14), freq=400000)\n");
		local m1, m2 = self:getFieldAsString('M1'), self:getFieldAsString('M2');
		return string.format('i2c.writeto(1, (bytearray([2, round(%s/100*255) if (%s)>0 else 0, 0 if (%s)>0 else -round(%s/100*255), round(%s/100*255) if (%s)>0 else 0, 0 if (%s)>0 else -round(%s/100*255)])), True)\n', m1,m1,m1, m1, m2, m2, m2, m2);
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},


{
	type = "i2c.readSensorbyte", 
	message0 = L"读取巡线小车的值",
	arg0 = {
	},
	output = {type = "null",},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	headerText = "from mpython import *\nimport struct\n",
	func_description = 'i2c.readfrom(1, 1, True)',
	ToNPL = function(self)
		return "i2c.readfrom(1, 1, True)";
	end,
	ToMicroPython = function(self)
		self:GetBlockly():AddUniqueHeader("i2c_1 = I2C(scl=Pin(Pin.P13), sda=Pin(Pin.P14), freq=400000)\n");
		return 'struct.unpack("<b", i2c.readfrom(1, 1, True))[0]';
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},


{
	type = "hcsr04.init", 
	message0 = L"初始化声波传感器%1 trigger %2 echo %3",
	arg0 = {
		{
			name = "name",
			type = "input_value",
            shadow = { type = "text", value = "hcsr04"},
			text = "hcsr04", 
		},
		{
			name = "trigger_pin",
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
			},
			text = "0",
		},
		{
			name = "echo_pin",
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
			},
			text = "1",
		},
	},
	output = {type = "null",},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	funcName = "hcsr04.init",
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\nfrom hcsr04 import HCSR04\n",
	func_description = '%s = HCSR04(trigger_pin=Pin.P%s, echo_pin=Pin.P%s)',
	ToNPL = function(self)
		return string.format('%s = HCSR04(trigger_pin=Pin.P%s, echo_pin=Pin.P%s)\n', 
			self:getFieldAsString('name'),self:getFieldAsString('trigger_pin'),self:getFieldAsString('echo_pin'));
	end,
	ToMicroPython = function(self)
		local precode = string.format('%s = HCSR04(trigger_pin=Pin.P%s, echo_pin=Pin.P%s)\n', 
			self:getFieldAsString('name'),self:getFieldAsString('trigger_pin'),self:getFieldAsString('echo_pin'));
		self:GetBlockly():AddUniqueHeader(precode);
		return "";
	end,
	examples = {{desc = "", canRun = true, code = [[
from hcsr04 import HCSR04
from mpython import *
hcsr04 = HCSR04(trigger_pin=Pin.P16, echo_pin=Pin.P15)
A = None
A = hcsr04.distance_mm()
]]}},
},

{
	type = "hcsr04.distance", 
	message0 = L"%1 hcsr04超声波距离 单位%2",
	arg0 = {
		{
			name = "name",
			type = "input_value",
            shadow = { type = "text", value = "hcsr04"},
			text = "hcsr04", 
		},
		{
			name = "unit",
			type = "field_dropdown",
			options = {
				{ L"毫米", "mm" },
				{ L"厘米", "cm" },
			},
		},
	},
	output = {type = "null",},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	headerText = "from mpython import *\nfrom hcsr04 import HCSR04\n",
	func_description = '%s.distance_%s()',
	ToNPL = function(self)
		return string.format('%s.distance_%s()', self:getFieldAsString('name'),self:getFieldAsString('unit'));
	end,
	ToMicroPython = function(self)
		return string.format('%s.distance_%s()', self:getFieldAsString('name'),self:getFieldAsString('unit'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},


{
	type = "IRRecever", 
	message0 = L"当从红外接收端 %1 收到消息时",
	message1 = L"%1",
	arg0 = {
		{
			name = "pin",
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
			},
			text = "8",
		},
	},
	arg1 = {
			{
				name = "input",
				type = "input_statement",
				text = "pass",
			},
		},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	funcName = "IRRecever",
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\nfrom ir_remote import IRReceiver",
	func_description = 'receiver = IRReceiver(Pin.P%s) %s',
	ToNPL = function(self)
		local input = self:getFieldAsString('input');
		if(input == "") then
			input = "pass"
		end
		return string.format('receiver = IRReceiver(Pin.P%s)\nreceiver.daemon()\ndef remote_callback(_address, _command):\n    %s\nreceiver.set_callback(remote_callback)\n', 
			self:getFieldAsString('pin'), input);
	end,
	ToMicroPython = function(self)
		local precode = format("receiver = IRReceiver(Pin.P%s)\nreceiver.daemon()\n", self:getFieldAsString('pin'))
		self:GetBlockly():AddUniqueHeader(precode);
		local block_indent = self:GetIndent();
		self:SetIndent("") -- tricky: since we are moving the code to header, so we need to remove the indent
		local input = self:getFieldAsString('input');
		
		local global_vars = MicroPython:GetGlobalVarsDefString(self)

		local cbCode = string.format("def remote_callback(_address, _command):\n%s%s\nreceiver.set_callback(remote_callback)\n", 
			global_vars, input);
		self:SetIndent(block_indent)
		self:GetBlockly():AddUniqueHeader(cbCode);
		return "";
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "IRReceiver._command", 
	message0 = L"红外接收的数据",
	arg0 = {
	},
	output = {type = "null",},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	headerText = "from mpython import *\n",
	func_description = '_command',
	ToNPL = function(self)
		return "_command";
	end,
	ToMicroPython = function(self)
		return '_command';
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "IRReceiver.send", 
	message0 = L"红外发送 %1 地址 %2 命令%3",
	arg0 = {
		{
			name = "pin",
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
			},
			text = "8",
		},
		{
			name = "address",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
		{
			name = "command",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
		
	},
	output = {type = "null",},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\nfrom ir_remote import IRTransmit",
	func_description = 'ir = IRTransmit(Pin.P%s)\nir.send(%s, %s)\n',
	ToNPL = function(self)
		return string.format('ir = IRTransmit(Pin.P%s)\nir.send(%s, %s)\n', 
			self:getFieldAsString('pin'),self:getFieldAsString('address'),self:getFieldAsString('command'));
	end,
	ToMicroPython = function(self)
		self:GetBlockly():AddUniqueHeader(string.format('ir = IRTransmit(Pin.P%s)\n', self:getFieldAsString('pin')));
		return string.format('ir.send(%s, %s)\n', 
			self:getFieldAsString('address'),self:getFieldAsString('command'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "radio.on", 
	message0 = L"无线广播 %1",
	arg0 = {
		{
			name = "mode",
			type = "field_dropdown",
			options = {
				{ L"打开", "on()" },
				{ L"关闭", "off()" },
			}
		},
	},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "import radio",
	func_description = 'radio.%s',
	ToNPL = function(self)
		return string.format("radio.%s\n", self:getFieldAsString('mode'));
	end,
	ToMicroPython = function(self)
		return string.format("radio.%s\n", self:getFieldAsString('mode'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "radio.channel", 
	message0 = L"无线广播的频道设置为%1",
	arg0 = {
		{
			name = "channel",
			type = "input_value",
            shadow = { type = "math_number", value = 13,},
			text = 13, 
		},
	},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "import radio",
	func_description = 'radio.config(channel=%s)',
	ToNPL = function(self)
		return string.format("radio.config(channel=%s)\n", self:getFieldAsString('channel'));
	end,
	ToMicroPython = function(self)
		return string.format("radio.config(channel=%s)\n", self:getFieldAsString('channel'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "radio.send", 
	message0 = L"无线广播 发送 %1",
	arg0 = {
		{
			name = "msg",
			type = "input_value",
            shadow = { type = "text", value = "msg"},
			text = "msg", 
		},
	},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "import radio",
	func_description = 'radio.send("%s")',
	ToNPL = function(self)
		return string.format("radio.send('%s')\n", self:getFieldAsString('msg'));
	end,
	ToMicroPython = function(self)
		return string.format("radio.send(%s)\n", self:GetValueAsString('msg'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},


{
	type = "radio.receive", 
	message0 = L"当收到无线广播消息时",
	message1 = L"%1",
	arg0 = {
	},
	arg1 = {
			{
				name = "input",
				type = "input_statement",
				text = "pass",
			},
		},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	funcName = "radio.receive",
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\nfrom machine import Timer\nimport radio",
	func_description = 'def radio_recv(_radiomsg):\n    %s',
	ToNPL = function(self)
		local input = self:getFieldAsString('input');
		if(input == "") then
			input = "pass"
		end
		return string.format('def radio_recv(_radiomsg):\n    %s\n', input);
	end,
	ToMicroPython = function(self)
		local hexFunc  =  'def str2name(str):\n    return "".join([c if (c.isalpha() or c.isdigit() or c==\'_\') else "_%x" % ord(c) for c in str])\n';
		self:GetBlockly():AddUniqueHeader(hexFunc);

		local block_indent = self:GetIndent();
		self:SetIndent("") -- tricky: since we are moving the code to header, so we need to remove the indent
		local input = self:getFieldAsString('input');
		
		local global_vars = MicroPython:GetGlobalVarsDefString(self)
		local cbCode = string.format("def radio_recv(_radiomsg):\n%s%s\n", global_vars, input);
		self:SetIndent(block_indent)
		self:GetBlockly():AddUniqueHeader(cbCode);

		local precode = [[_radio_msg_list = []
def radio_callback(_msg):
    global _radio_msg_list
    try: radio_recv(_msg)
    except: pass
    if _msg in _radio_msg_list:
        eval('radio_recv_' + str2name(_msg) + '()')

tim13 = Timer(13)

def timer13_tick(_):
    _msg = radio.receive()
    if not _msg: return
    radio_callback(_msg)

tim13.init(period=20, mode=Timer.PERIODIC, callback=timer13_tick)]]
		self:GetBlockly():AddUniqueHeader(precode);

		return "";
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "radio.radiomsg", 
	message0 = L"收到的无线广播消息",
	arg0 = {
	},
	output = {type = "null",},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	headerText = "",
	func_description = '_radiomsg',
	ToNPL = function(self)
		return "_radiomsg";
	end,
	ToMicroPython = function(self)
		return "_radiomsg";
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "radio.receiveGivenMsg", 
	message0 = L"当收到特定无线广播消息%1时",
	message1 = L"%1",
	arg0 = {
		{
			name = "msg",
			type = "input_value",
            shadow = { type = "text", value = "on"},
			text = "on", 
		},
	},
	arg1 = {
			{
				name = "input",
				type = "input_statement",
				text = "pass",
			},
		},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	funcName = "radio.receiveGivenMsg",
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\nfrom machine import Timer\nimport radio",
	func_description = 'def radio_recv_%s():\n    %s',
	ToNPL = function(self)
		local input = self:getFieldAsString('input');
		if(input == "") then
			input = "pass"
		end
		return string.format('def radio_recv_%s():\n    %s\n', commonlib.Encoding.toValidParamName(self:getFieldAsString('msg')), input);
	end,
	ToMicroPython = function(self)
		local hexFunc  =  'def str2name(str):\n    return "".join([c if (c.isalpha() or c.isdigit() or c==\'_\') else "_%x" % ord(c) for c in str])\n';
		self:GetBlockly():AddUniqueHeader(hexFunc);

		local block_indent = self:GetIndent();
		self:SetIndent("") -- tricky: since we are moving the code to header, so we need to remove the indent
		local input = self:getFieldAsString('input');
	
		local precode = [[_radio_msg_list = []
def radio_callback(_msg):
    global _radio_msg_list
    try: radio_recv(_msg)
    except: pass
    if _msg in _radio_msg_list:
        eval('radio_recv_' + str2name(_msg) + '()')

tim13 = Timer(13)

def timer13_tick(_):
    _msg = radio.receive()
    if not _msg: return
    radio_callback(_msg)

tim13.init(period=20, mode=Timer.PERIODIC, callback=timer13_tick)]]
		self:GetBlockly():AddUniqueHeader(precode);

		local global_vars = MicroPython:GetGlobalVarsDefString(self)
		return string.format('_radio_msg_list.append(%s)\ndef radio_recv_%s():\n%s%s\n', self:GetValueAsString('msg'), commonlib.Encoding.toValidParamName(self:getFieldAsString('msg')), global_vars, input);
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "bluetooth.peripheral.register_event", 
	message0 = L"当收到BLE %1 消息时(%2)",
	message1 = L"%1",
	arg0 = {
		{
			name = "name",
			type = "input_value",
			text = "name",
		},
		{
			name = "params",
			type = "input_value",
			text = "params",
		}
	},
	arg1 = {
		{
			name = "input",
			type = "input_statement",
			text = "",
		}
	},
	category = "wifi",
	helpUrl = "",
	canRun = false,
	funcName = "bluetooth.peripheral",
	previousStatement = true,
	nextStatement = true,
	headerText = [[import binascii
from mpython_ble.gatts import Profile
from mpython_ble.services import Service
from mpython_ble.application import Peripheral
from mpython_ble import UUID
from mpython_ble.characteristics import Characteristic
import ujson
]],
	func_description = "",
	ToNPL = function(self)
		return ''
	end,
	ToMicroPython = function(self)
		self:GetBlockly():AddUniqueHeader("bleEventCallbacks={}");
		self:GetBlockly():AddUniqueHeader("def _ble_peripheral_connection_callback(_1, _2, _3):\n    pass\n");
		self:GetBlockly():AddUniqueHeader("def _ble_peripheral_write_callback(_1, _2, _3):\n    pass\n");

		self:GetBlockly():AddUniqueHeader("peripheral_ble_display_name='paracraft_ble'", 0);
		self:GetBlockly():AddUniqueHeader("peripheral_ble_serviceid=UUID(0x181A)", 0);
		self:GetBlockly():AddUniqueHeader("peripheral_ble_chars={\"charName\":\"_c1\", \"charUUID\":\"0x2A6E\", \"properties\":\"rwn\"}", 1);

		self:GetBlockly():AddUniqueHeader([[_ble_service = Service(peripheral_ble_serviceid)
if peripheral_ble_chars:
	exec(peripheral_ble_chars['charName'] + "=Characteristic(UUID(" + peripheral_ble_chars['charUUID'] + "), properties='" + peripheral_ble_chars['properties'] + "')" )
	eval("_ble_service.add_characteristics(" + peripheral_ble_chars['charName'] + ")")
]], 2);

		local code = [[
_ble_profile = Profile()
_ble_profile.add_services(_ble_service)

_ble_peripheral = Peripheral(name=bytes(peripheral_ble_display_name, 'utf-8'), profile=_ble_profile)
_ble_peripheral.connection_callback(_ble_peripheral_connection_callback)
_ble_peripheral.write_callback(_ble_peripheral_write_callback)
]];
		self:GetBlockly():AddUniqueHeader(code, 6);
		self:GetBlockly():AddUniqueHeader("_ble_peripheral.advertise(True)\n", 7);

		local input = self:getFieldAsString('input');
		if (input:gsub("%s", "") == "") then
			input = "	pass"
		end

		local eventName = self:getFieldAsString('name');
		local paramsName = self:getFieldAsString('params');

		local block_indent = self:GetIndent();
		self:SetIndent("") -- tricky: since we are moving the code to header, so we need to remove the indent
		local global_vars = MicroPython:GetGlobalVarsDefString(self, {[paramsName] = true})
		local dataFormat = [[
def __func__(__params__):
__globals__
__content__

bleEventCallbacks['__func__'] = __func__
]];
		dataFormat = dataFormat:gsub("__func__", eventName);
		dataFormat = dataFormat:gsub("__globals__", global_vars);
		dataFormat = dataFormat:gsub("__params__", paramsName);
		dataFormat = dataFormat:gsub("__content__", input);
		self:GetBlockly():AddUniqueHeader(dataFormat, 4);
		self:SetIndent(block_indent)

		local peripheralWriteCallback = [[def _ble_peripheral_write_callback(_conn_handle, _attr_handle, _data):
	handleData = _data.decode('utf-8')
	separator_index = handleData.find('|')
	global receiveEventName, receiveData

	if separator_index != -1:
		receiveEventName = handleData[:separator_index]
		data_str = handleData[separator_index + 1:]

		try:
			receiveData = ujson.loads(data_str)
		except ValueError as e:
			receiveData = None

	if receiveEventName in bleEventCallbacks:
		bleEventCallbacks[receiveEventName](receiveData)
]];

		self:GetBlockly():AddUniqueHeader(peripheralWriteCallback, 4);
	end,
	examples = {{desc = "", canRun = true, code = [[]]}},
},

{
	type = "bluetooth.send_event",
	message0 = L"发送消息到BLE设备 事件名 %1 数据 %2",
	arg0 = {
		{
			name = "event_name",
			type = "input_value",
			text = "name",
		},
		{
			name = "data",
			type = "input_value",
			text = "{}",
		},
	},
	category = "wifi",
	helpUrl = "",
	canRun = false,
	funcName = "bluetooth.attribute",
	previousStatement = true,
	nextStatement = true,
	headerText = [[import binascii
from mpython_ble.gatts import Profile
from mpython_ble.services import Service
from mpython_ble.application import Peripheral
from mpython_ble import UUID
from mpython_ble.characteristics import Characteristic
import ujson
]],
	func_description = "",
	ToNPL = function(self)
		return ""
	end,
	ToMicroPython = function(self)
		self:GetBlockly():AddUniqueHeader("def _ble_peripheral_connection_callback(_1, _2, _3):\n    pass\n");
		self:GetBlockly():AddUniqueHeader("def _ble_peripheral_write_callback(_1, _2, _3):\n    pass\n");

		self:GetBlockly():AddUniqueHeader("peripheral_ble_display_name='paracraft_ble'", 0);
		self:GetBlockly():AddUniqueHeader("peripheral_ble_serviceid=UUID(0x181A)", 0);
		self:GetBlockly():AddUniqueHeader("peripheral_ble_chars={\"charName\":\"_c1\", \"charUUID\":\"0x2A6E\", \"properties\":\"rwn\"}", 1);

		self:GetBlockly():AddUniqueHeader([[_ble_service = Service(peripheral_ble_serviceid)
if peripheral_ble_chars:
	exec(peripheral_ble_chars['charName'] + "=Characteristic(UUID(" + peripheral_ble_chars['charUUID'] + "), properties='" + peripheral_ble_chars['properties'] + "')" )
	eval("_ble_service.add_characteristics(" + peripheral_ble_chars['charName'] + ")")
]], 2);

		local code = [[
_ble_profile = Profile()
_ble_profile.add_services(_ble_service)

_ble_peripheral = Peripheral(name=bytes(peripheral_ble_display_name, 'utf-8'), profile=_ble_profile)
_ble_peripheral.connection_callback(_ble_peripheral_connection_callback)
_ble_peripheral.write_callback(_ble_peripheral_write_callback)
]];
		self:GetBlockly():AddUniqueHeader(code, 6);
		self:GetBlockly():AddUniqueHeader("_ble_peripheral.advertise(True)\n", 7);

		local sendEventCode = "";
		local eventName = self:getFieldAsString("event_name");
		local data = self:GetValueAsString("data");

		-- Using pattern matching to check the beginning and end.
		local start_quote = data:match("^['\"]");
		local end_quote = data:match("['\"]$");
		
		if start_quote and end_quote and start_quote == end_quote then
			data = data:sub(2, -2);
			sendEventCode = [[
eval("_ble_peripheral.attrubute_write(" + peripheral_ble_chars['charName'] +".value_handle, bytes(%s, 'utf8'), notify=True)")
]];
			sendEventCode = string.format(sendEventCode, string.format("'%s|%s'", eventName, data));
		else
			local block_indent = self:GetIndent();

			sendEventCode = [[global curParams
__block_indent__curParams = %s
__block_indent__eval("_ble_peripheral.attrubute_write(" + peripheral_ble_chars['charName'] +".value_handle, bytes(%s, 'utf8'), notify=True)")
]];
			sendEventCode = sendEventCode:gsub("__block_indent__", block_indent);
			sendEventCode = string.format(sendEventCode, data, string.format("'%s|' + curParams", eventName));
		end

		return sendEventCode;
	end,
	examples = {{desc = "", canRun = true, code = [[]]}},
},

{
	type = "bluetooth.peripheral", 
	message0 = L"构建BLE外围设备对象 显示名称:%1 Service UUID:%2",
	message1 = L"%1",
	arg0 = {
		{
			name = "name",
			type = "input_value",
			text = "paracraft_ble", 
		},
		{
			name = "service_uuid",
			type = "input_value",
			text = "0x181A",
		}
	},
	arg1 = {
		{
			name = "characteristic",
			type = "input_statement",
			text = "",
		}
	},
	category = "wifi",
	helpUrl = "",
	canRun = false,
	funcName = "bluetooth.peripheral",
	previousStatement = true,
	nextStatement = true,
	headerText = [[from mpython_ble.gatts import Profile
from mpython_ble.services import Service
from mpython_ble.application import Peripheral
from mpython_ble import UUID
from mpython_ble.characteristics import Characteristic]],
	func_description = "",
	ToNPL = function(self)
		return ''
	end,
	ToMicroPython = function(self)
		self:GetBlockly():AddUniqueHeader("bleEventCallbacks={}");
		self:GetBlockly():AddUniqueHeader("def _ble_peripheral_connection_callback(_1, _2, _3):\n    pass\n");
		self:GetBlockly():AddUniqueHeader("def _ble_peripheral_write_callback(_1, _2, _3):\n    pass\n");

		self:GetBlockly():AddUniqueHeader(format("peripheral_ble_display_name='%s'", self:getFieldAsString('name')), 1);
		self:GetBlockly():AddUniqueHeader(format("peripheral_ble_serviceid=UUID(%s)", self:getFieldAsString('service_uuid')), 1);
		self:GetBlockly():AddUniqueHeader("peripheral_ble_chars=None", 1);
		self:getFieldAsString('characteristic');

		self:GetBlockly():AddUniqueHeader([[_ble_service = Service(peripheral_ble_serviceid)
if peripheral_ble_chars:
	exec(peripheral_ble_chars['charName'] + "=Characteristic(UUID(" + peripheral_ble_chars['charUUID'] + "), properties='" + peripheral_ble_chars['properties'] + "')" )
	eval("_ble_service.add_characteristics(" + peripheral_ble_chars['charName'] + ")")
]], 2);

		local code = [[
_ble_profile = Profile()
_ble_profile.add_services(_ble_service)

_ble_peripheral = Peripheral(name=bytes(peripheral_ble_display_name, 'utf-8'), profile=_ble_profile)
_ble_peripheral.connection_callback(_ble_peripheral_connection_callback)
_ble_peripheral.write_callback(_ble_peripheral_write_callback)
]];
		self:GetBlockly():AddUniqueHeader(code, 6);

		return "";
	end,
	examples = {{desc = "", canRun = true, code = [[]]}},
},

{
	type = "bluetooth.characteristic", 
	message0 = L"定义BLE属性:%1 Characteristic UUID: %2 Read: %3 Write: %4 Notify: %5",
	arg0 = {
		{
			name = "properties_name",
			type = "input_value",
            shadow = { type = "text", value = "on"},
			text = "_c1", 
		},
		{
			name = "service_uuid",
			type = "input_value",
            shadow = { type = "text", value = "on"},
			text = "0x2A6E",
		},
		{
			name = "read",
			type = "field_dropdown",
			text = "True",
            options = {
				{ L"否",  ""},
				{ L"是", "True" },
			}
		},
		{
			name = "write",
			type = "field_dropdown",
			text = "True",
            options = {
				{ L"否",  ""},
				{ L"是", "True" },
			}
		},
		{
			name = "notify",
			type = "field_dropdown",
			text = "True",
            options = {
				{ L"否",  ""},
				{ L"是", "True" },
			}
		},
	},
	category = "wifi",
	helpUrl = "",
	canRun = false,
	hide_in_toolbox = true,
	funcName = "bluetooth.characteristic",
	previousStatement = true,
	nextStatement = true,
	headerText = [[from mpython_ble import UUID
from mpython_ble.characteristics import Characteristic]],
	func_description = "",
	ToNPL = function(self)
		return '';
	end,
	ToMicroPython = function(self)
		local properties_name = self:getFieldAsString('properties_name');
		local service_uuid = self:getFieldAsString("service_uuid");
		local properties = "";

		if (self:getFieldAsString("read") == "True") then
			properties = properties .. "r";
		end

		if (self:getFieldAsString("write") == "True") then
			properties = properties .. "w";
		end

		if (self:getFieldAsString("notify") == "True") then
			properties = properties .. "n";
		end

		local code = "peripheral_ble_chars={\"charName\":\"%s\", \"charUUID\":\"%s\", \"properties\":\"%s\"}";

		self:GetBlockly():AddUniqueHeader(string.format(code, properties_name, service_uuid, properties), 2);

		return "";
	end,
	examples = {{desc = "", canRun = true, code = [[]]}},
},

{
	type = "bluetooth.advertise", 
	message0 = L"BLE外围设备%1",
	arg0 = {
		{
			name = "advertise",
			type = "field_dropdown",
			text = "True",
            options = {
				{ L"停止广播",  ""},
				{ L"开始广播", "True" },
			}
		},
	},
	category = "wifi",
	helpUrl = "",
	canRun = false,
	hide_in_toolbox = true,
	funcName = "radio.advertise",
	previousStatement = true,
	nextStatement = true,
	headerText = "",
	func_description = "",
	ToNPL = function(self)
		return ""
	end,
	ToMicroPython = function(self)
		local advertise = self:getFieldAsString('advertise');
		local code;

		if (advertise == "True") then
			code = "_ble_peripheral.advertise(True)\n";
		else
			code = "_ble_peripheral.advertise(False)\n";
		end

		self:GetBlockly():AddUniqueHeader(code, 7);
	end,
	examples = {{desc = "", canRun = true, code = [[]]}},
},

{
	type = "bluetooth.peripherial_write_callback", 
	message0 = L"当BLE设备的属性值被改写时 连接句柄:%1 被写属性句柄:%2 写入的数据:%3",
	message1 = L"%1",
	arg0 = {
		{
			name = "connection_handle",
			type = "input_value",
			text = "_conn_handle",
		},
		{
			name = "attritube_handle",
			type = "input_value",
			text = "_attr_handle",
		},
		{
			name = "data",
			type = "input_value",
			text = "_data",
		}
	},
	arg1 = {
		{
			name = "input",
			type = "input_statement",
			text = "",
		}
	},
	category = "wifi",
	helpUrl = "",
	canRun = false,
	funcName = "bluetooth.peripherial_write_callback",
	hide_in_toolbox = true,
	previousStatement = false,
	nextStatement = true,
	headerText = "import binascii",
	func_description = "",
	ToNPL = function(self)
		return ""
	end,
	ToMicroPython = function(self)
		-- get block type.
		local field = self:GetInputField("input");
		local input_block = field:IsInput() and field:GetInputBlock();
		local block_type = '';

		if (input_block) then
			block_type = input_block:GetType();
		end

		local code;

		if (block_type == "bluetooth.message_read_format") then
			code = [[def _ble_peripheral_write_callback(__conn_handle__, __attr_handle__, __data__):
	handleData = __data__.decode('utf-8')
	separator_index = handleData.find('|')
	global receiveEventName, receiveData

	if separator_index != -1:
		receiveEventName = handleData[:separator_index]
		data_str = handleData[separator_index + 1:]

		try:
			receiveData = ujson.loads(data_str)
		except ValueError as e:
			receiveData = None

	if receiveEventName in bleEventCallbacks:
		bleEventCallbacks[receiveEventName](receiveData)
]];

			code = code:gsub("__conn_handle__", self:getFieldAsString('connection_handle'));
			code = code:gsub("__attr_handle__", self:getFieldAsString('attritube_handle'));
			code = code:gsub("__data__", self:getFieldAsString('data'));

			self:GetValueAsString('input');
		else
			code = [[def _ble_peripheral_write_callback(__conn_handle__, __attr_handle__, __data__):
%s
]]

			code = code:gsub("__conn_handle__", self:getFieldAsString('connection_handle'));
			code = code:gsub("__attr_handle__", self:getFieldAsString('attritube_handle'));
			code = code:gsub("__data__", self:getFieldAsString('data'));

			local input = self:GetValueAsString('input');

			if (input:gsub("%s", "") == "") then
				input = "	pass"
			end

			code = string.format(code, input);
		end
	
		self:GetBlockly():AddUniqueHeader(code, 5);
	end,
	examples = {{desc = "", canRun = true, code = [[]]}},
},

{
	type = "bluetooth.write_attribute", 
	message0 = L"写BLE设备的属性%1 值%2 Notify%3",
	arg0 = {
		{
			name = "properties_name",
			type = "input_value",
			text = "_c1",
		},
		{
			name = "message",
			type = "input_value",
			text = "abc",
		},
		{
			name = "notify",
			type = "field_dropdown",
			text = "True",
            options = {
				{ L"假",  "False"},
				{ L"真", "True" },
			}
		},
	},
	category = "wifi",
	helpUrl = "",
	canRun = false,
	hide_in_toolbox = true,
	funcName = "bluetooth.write_attribute",
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython_ble.application import Peripheral",
	func_description = "",
	ToNPL = function(self)
		return ""
	end,
	ToMicroPython = function(self)
		local code = "_ble_peripheral.attrubute_write(%s.value_handle, bytes(%s, 'utf-8'), notify=%s)";

		code = string.format(
			code,
			self:getFieldAsString('properties_name'),
			self:getFieldAsString('message'),
			self:getFieldAsString('notify')
		);

		return code;
	end,
	examples = {{desc = "", canRun = true, code = [[]]}},
},

{
	type = "bluetooth.message_format", 
	message0 = L"事件名:%1 数据:%2",
	arg0 = {
		{
			name = "event_name",
			type = "field_input",
			text = "eventName",
		},
		{
			name = "data",
			type = "input_value",
			text = "{}",
		},
	},
	output = { type = "null", },
	category = "wifi",
	helpUrl = "",
	canRun = false,
	hide_in_toolbox = true,
	func_description = "",
	ToNPL = function(self)
		return ""
	end,
	ToMicroPython = function(self)
		local eventName = self:getFieldAsString("event_name");
		local data = self:GetValueAsString("data");

		-- Using pattern matching to check the beginning and end.
		local start_quote = data:match("^['\"]");
		local end_quote = data:match("['\"]$");
		
		if start_quote and end_quote and start_quote == end_quote then
			data = data:sub(2, -2);
			data = string.format("'%s|%s'", eventName, data);
		else
			data = string.format("'%s|' + %s", eventName, data);
		end

		return data;
	end,
	examples = {{desc = "", canRun = true, code = [[]]}},
},

{
	type = "bluetooth.message_read_format", 
	message0 = L"解析事件(%1)和数据(%2)",
	message1 = L"%1",
	arg0 = {
		{
			name = "event_name",
			type = "field_input",
			text = "name",
		},
		{
			name = "params_name",
			type = "field_input",
			text = "params"
		}
	},
	arg1 = {
		{
			name = "block_data",
			type = "input_statement",
			text = "",
		}
	},
	category = "wifi",
	helpUrl = "",
	canRun = false,
	hide_in_toolbox = true,
	funcName = "bluetooth.message_read_format",
	previousStatement = true,
	nextStatement = true,
	headerText = "import ujson",
	func_description = "",
	ToNPL = function(self)
		return ''
	end,
	ToMicroPython = function(self)
		local input = self:getFieldAsString('block_data');
		if (input:gsub("%s", "") == "") then
			input = "		pass"
		end

		local eventName = self:getFieldAsString('event_name');
		local paramsName = self:getFieldAsString('params_name');

		local dataFormat = [[
def __func__(__params__):
	if True:
__content__

bleEventCallbacks['__func__'] = __func__
]];

		dataFormat = dataFormat:gsub("__func__", eventName);
		dataFormat = dataFormat:gsub("__params__", paramsName);
		dataFormat = dataFormat:gsub("__content__", input);

		self:GetBlockly():AddUniqueHeader(dataFormat, 5);
	end,
	examples = {{desc = "", canRun = true, code = [[]]}},
},

{
	type = "bluetooth.enable_burning", 
	message0 = L"开启BLE烧录",
	category = "wifi",
	helpUrl = "",
	canRun = false,
	hide_in_toolbox = true,
	funcName = "bluetooth.enable_burning",
	previousStatement = true,
	nextStatement = true,
	headerText = "",
	func_description = "",
	ToNPL = function(self)
		return ''
	end,
	ToMicroPython = function(self)
		return [[from mpython import *
from mpython_ble.gatts import Profile
from mpython_ble.services import Service
from mpython_ble.application import Peripheral
from mpython_ble import UUID
from mpython_ble.characteristics import Characteristic

import binascii

def _ble_peripheral_connection_callback(_1, _2, _3):
	pass
def _ble_peripheral_write_callback(_1, _2, _3):
	pass

def _ble_peripheral_connection_callback(_conn_handle, _addr_type, _addr):
	_addr = binascii.hexlify(_addr).decode('UTF-8','ignore')
	print(_addr)
	print('ble connected')

receive_data = bytearray(b"")
def _ble_peripheral_write_callback(_conn_handle, _attr_handle, _data):
	global receive_data
	if _data.decode('utf-8') == "start":
		receive_data = bytearray(b"")
		return
	elif _data.decode('utf-8') == "end":
		print(receive_data)
		exec(receive_data)
		return

	receive_data = receive_data + bytearray(_data)
	print(_data)

oled.DispChar(str('name: paracraft_ble'), 0, 0, 1)
oled.show()

_ble_service = Service(UUID(0x181A))
if True:
	_c1 = Characteristic(UUID(0x2A6E), properties='rwn')
	_ble_service.add_characteristics(_c1)

_ble_profile = Profile()
_ble_profile.add_services(_ble_service)

_ble_peripheral = Peripheral(name=bytes('paracraft_ble', 'utf-8'), profile=_ble_profile)
_ble_peripheral.connection_callback(_ble_peripheral_connection_callback)
_ble_peripheral.write_callback(_ble_peripheral_write_callback)
_ble_peripheral.advertise(True)
]];
	end,
	examples = {{desc = "", canRun = true, code = [[]]}},
},

{
	type = "bluetooth.create_hid", 
	message0 = L"构建BLE HID %1 对象 显示名称 %2 电池电量 %3",
	arg0 = {
		{
			name = "device",
			type = "field_dropdown",
			text = "mouse",
            options = {
				{ L"鼠标", "mouse"},
				{ L"键盘", "keyboard" },
				{ L"遥控", "remote_control" },
			}
		},
		{
			name = "display_name",
			type = "input_value",
			shadow = { type = "text", value = "paracraft_hid" },
			text = "paracraft_hid",
		},
		{
			name = "battery_level",
			type = "input_value",
			shadow = { type = "math_number", value = 100,},
			text = 100, 
		},
	},
	category = "wifi",
	helpUrl = "",
	canRun = false,
	hide_in_toolbox = true,
	funcName = "bluetooth.create_hid",
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython_ble.application import HID\nfrom mpython_ble.hidcode import Mouse",
	func_description = "",
	ToNPL = function(self)
		return ''
	end,
	ToMicroPython = function(self)
		local code = [[def _ble_hid_connect_callback(_1, _2, _3):pass
_ble_hid = HID(name=bytes('%s', 'utf-8'), battery_level=%s)
_ble_hid.hid_device.connection_callback(_ble_hid_connect_callback)
]]
		local displayName = self:getFieldAsString("display_name");
		local batteryLevel = self:getFieldAsString("battery_level");

		code = string.format(code, displayName, batteryLevel);

		return code;
	end,
	examples = {{ desc = "", canRun = true, code = [[]] }},
},

{
	type = "bluetooth.hid.advertise",
	message0 = L"BLE HID设备 %1",
	arg0 = {
		{
			name = "advertise",
			type = "field_dropdown",
			text = "True",
            options = {
				{ L"开始广播", "True"},
				{ L"停止广播", "False" },
			}
		},
	},
	category = "wifi",
	helpUrl = "",
	canRun = false,
	funcName = "bluetooth.hid.advertise",
	previousStatement = true,
	nextStatement = true,
	hide_in_toolbox = true,
	headerText = "from mpython_ble.application import HID",
	func_description = "",
	ToNPL = function(self)
		return ''
	end,
	ToMicroPython = function(self)
		local advertise = self:getFieldAsString("advertise");
		local code = "_ble_hid.advertise(%s)\n";

		code = string.format(code, advertise);

		return code;
	end,
	examples = {{ desc = "", canRun = true, code = [[]] }},
},

{
	type = "bluetooth.hid.connect_callback", 
	message0 = L"当BLE HID设备 连接时",
	message1 = "%1",
	arg1 = {
		{
			name = "block_data",
			type = "input_statement",
			text = "",
		}
	},
	category = "wifi",
	helpUrl = "",
	canRun = false,
	hide_in_toolbox = true,
	funcName = "bluetooth.hid.connect_callback",
	previousStatement = false,
	nextStatement = true,
	headerText = "",
	func_description = "",
	ToNPL = function(self)
		return ''
	end,
	ToMicroPython = function(self)
		local blockData = self:getFieldAsString("block_data");
		local code = [[def _ble_hid_connect_callback(_1, _2, _3):
%s
]];
		if (not blockData or string.gsub(blockData, " ", "") == "") then
			code = string.format(code, "	pass");
		else
			code = string.format(code, blockData);
		end

		return code;
	end,
	examples = {{ desc = "", canRun = true, code = [[]] }},
},

{
	type = "bluetooth.hid.disconnect", 
	message0 = L"BLE HID设备 断开连接",
	category = "wifi",
	helpUrl = "",
	canRun = false,
	funcName = "bluetooth.hid.disconnect",
	previousStatement = true,
	nextStatement = true,
	hide_in_toolbox = true,
	headerText = "from mpython_ble.application import HID\n",
	func_description = "",
	ToNPL = function(self)
		return ''
	end,
	ToMicroPython = function(self)
		return "_ble_hid.disconnect()\n";
	end,
	examples = {{ desc = "", canRun = true, code = [[]] }},
},

{
	type = "bluetooth.hid.battery", 
	message0 = L"BLE HID设备 电池电量",
	category = "wifi",
	helpUrl = "",
	canRun = false,
	hide_in_toolbox = true,
	funcName = "bluetooth.hid.battery",
	previousStatement = false,
	nextStatement = false,
	headerText = "from mpython_ble.application import HID\n",
	func_description = "",
	ToNPL = function(self)
		return ''
	end,
	ToMicroPython = function(self)
		return "_ble_hid.battery_level";
	end,
	examples = {{ desc = "", canRun = true, code = [[]] }},
},

{
	type = "bluetooth.hid.mouse_key", 
	message0 = L"鼠标键 %1",
	arg0 = {
		{
			name = "mouse_key",
			type = "field_dropdown",
			text = "left",
            options = {
				{ L"LEFT", "Mouse.LEFT"},
				{ L"RIGHT", "Mouse.RIGHT" },
				{ L"MIDDLE", "Mouse.MIDDLE" },
			}
		},
	},
	category = "wifi",
	helpUrl = "",
	hide_in_toolbox = true,
	output = {type = "null",},
	canRun = false,
	funcName = "bluetooth.hid.mouse_key",
	previousStatement = false,
	nextStatement = false,
	headerText = "from mpython_ble.application import HID\nfrom mpython_ble.hidcode import Mouse\n",
	func_description = "",
	ToNPL = function(self)
		return ''
	end,
	ToMicroPython = function(self)
		return self:getFieldAsString("mouse_key");
	end,
	examples = {{ desc = "", canRun = true, code = [[]] }},
},

{
	type = "bluetooth.hid.mouse_click", 
	message0 = L"BLE HID 鼠标 点击按键 %1",
	arg0 = {
		{
			name = "mouse_click",
			type = "input_value",
			shadow = { type = "text", value = "LEFT"},
			text = "LEFT",
		},
	},
	category = "wifi",
	helpUrl = "",
	canRun = false,
	hide_in_toolbox = true,
	funcName = "bluetooth.hid.mouse_click",
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython_ble.application import HID\nfrom mpython_ble.hidcode import Mouse\n",
	func_description = "",
	ToNPL = function(self)
		return ''
	end,
	ToMicroPython = function(self)
		local mouseClick = self:getFieldAsString("mouse_click");
		
		if mouseClick == "LEFT" then
			mouseClick = "Mouse.LEFT";
		elseif mouseClick == "RIGHT" then
			mouseClick = "Mouse.RIGHT";
		elseif mouseClick == "MIDDLE" then
			mouseClick = "Mouse.MIDDLE";
		else
			mouseClick = mouseClick or "Mouse.LEFT";
		end

		return string.format("_ble_hid.mouse_click(%s)\n", mouseClick);
	end,
	examples = {{ desc = "", canRun = true, code = [[]] }},
},

{
	type = "bluetooth.hid.mouse_press", 
	message0 = L"BLE HID 鼠标 长按按键 %1",
	arg0 = {
		{
			name = "mouse_press",
			type = "input_value",
			shadow = { type = "text", value = "LEFT"},
			text = "LEFT",
		},
	},
	category = "wifi",
	helpUrl = "",
	hide_in_toolbox = true,
	canRun = false,
	funcName = "bluetooth.hid.mouse_press",
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython_ble.application import HID\nfrom mpython_ble.hidcode import Mouse\n",
	func_description = "",
	ToNPL = function(self)
		return ''
	end,
	ToMicroPython = function(self)
		local mouseClick = self:getFieldAsString("mouse_press");
		
		if mouseClick == "LEFT" then
			mouseClick = "Mouse.LEFT";
		elseif mouseClick == "RIGHT" then
			mouseClick = "Mouse.RIGHT";
		elseif mouseClick == "MIDDLE" then
			mouseClick = "Mouse.MIDDLE";
		else
			mouseClick = mouseClick or "Mouse.LEFT";
		end

		return string.format("_ble_hid.mouse_press(%s)\n", mouseClick);
	end,
	examples = {{ desc = "", canRun = true, code = [[]] }},
},

{
	type = "bluetooth.hid.mouse_release", 
	message0 = L"BLE HID 鼠标 释放按键 %1",
	arg0 = {
		{
			name = "mouse_release",
			type = "input_value",
			shadow = { type = "text", value = "LEFT"},
			text = "LEFT",
		},
	},
	category = "wifi",
	helpUrl = "",
	hide_in_toolbox = true,
	canRun = false,
	funcName = "bluetooth.hid.mouse_release",
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython_ble.application import HID\nfrom mpython_ble.hidcode import Mouse\n",
	func_description = "",
	ToNPL = function(self)
		return ''
	end,
	ToMicroPython = function(self)
		local mouseClick = self:getFieldAsString("mouse_release");
		
		if mouseClick == "LEFT" then
			mouseClick = "Mouse.LEFT";
		elseif mouseClick == "RIGHT" then
			mouseClick = "Mouse.RIGHT";
		elseif mouseClick == "MIDDLE" then
			mouseClick = "Mouse.MIDDLE";
		else
			mouseClick = mouseClick or "Mouse.LEFT";
		end

		return string.format("_ble_hid.mouse_release(%s)\n", mouseClick);
	end,
	examples = {{ desc = "", canRun = true, code = [[]] }},
},

{
	type = "bluetooth.hid.mouse_release_all", 
	message0 = L"BLE HID 鼠标 释放所有按键",
	arg0 = {
		{
			name = "mouse_release_all",
			type = "input_value",
			shadow = { type = "text", value = "LEFT"},
			text = "LEFT",
		},
	},
	category = "wifi",
	helpUrl = "",
	hide_in_toolbox = true,
	canRun = false,
	funcName = "bluetooth.hid.mouse_release_all",
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython_ble.application import HID\n",
	func_description = "",
	ToNPL = function(self)
		return ''
	end,
	ToMicroPython = function(self)
		return "_ble_hid.mouse_release_all()\n";
	end,
	examples = {{ desc = "", canRun = true, code = [[]] }},
},

{
	type = "bluetooth.hid.mouse_move", 
	message0 = L"BLE HID 鼠标 光标移动 X轴移动量 %1 Y轴移动量 %2 滚轮 %3",
	arg0 = {
		{
			name = "position_x",
			type = "input_value",
			shadow = { type = "math_number", value = "0"},
			text = "0",
		},
		{
			name = "position_y",
			type = "input_value",
			shadow = { type = "math_number", value = "0"},
			text = "0",
		},
		{
			name = "mouse_move",
			type = "input_value",
			shadow = { type = "math_number", value = "0"},
			text = "0",
		},
	},
	category = "wifi",
	helpUrl = "",
	canRun = false,
	hide_in_toolbox = true,
	funcName = "bluetooth.hid.mouse_move",
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython_ble.application import HID\n",
	func_description = "",
	ToNPL = function(self)
		return ''
	end,
	ToMicroPython = function(self)
		local x = self:getFieldAsString("position_x");
		local y = self:getFieldAsString("position_y");
		local move = self:getFieldAsString("mouse_move");
		local code = "_ble_hid.mouse_move(x = %s, y = %s, wheel = %s)\n"

		return string.format(code, x, y, move);
	end,
	examples = {{ desc = "", canRun = true, code = [[]] }},
},

{
	type = "bluetooth.hid.keyboard_key", 
	message0 = L"键盘按键 %1",
	arg0 = {
		{
			name = "keyboard_key",
			type = "field_dropdown",
			text = "space",
            options = {
				{ L"Space", "SPACE"},
				{ L"Enter", "ENTER" },
				{ L"↑", "UP_ARROW" },
				{ L"↓", "DOWN_ARROW" },
				{ L"←", "LEFT_ARROW" },
				{ L"→", "RIGHT_ARROW" },
				{ L"1", "ONE" }, { L"2", "TWO" }, { L"3", "THREE" }, { L"4", "FOUR" }, { L"5", "FIVE" },
				{ L"6", "SIX" }, { L"7", "SEVEN" }, { L"8", "EIGHT" }, { L"9", "NINE" }, { L"0", "ZERO" },
				{ L"A", "A" }, { L"B", "B" }, { L"C", "C" }, { L"D", "D" }, { L"E", "E" },
				{ L"F", "F" }, { L"G", "G" }, { L"H", "H" }, { L"I", "I" }, { L"J", "J" },
				{ L"K", "K" }, { L"L", "L" }, { L"M", "M" }, { L"N", "N" }, { L"O", "O" },
				{ L"P", "P" }, { L"Q", "Q" }, { L"R", "R" }, { L"S", "S" }, { L"T", "T" },
				{ L"U", "U" }, { L"V", "V" }, { L"W", "W" }, { L"X", "X" }, { L"Y", "Y" },
				{ L"Z", "Z" },
				{ L"Esc", "ESCAPE" },
				{ L"Backspace", "BACKSPACE" },
				{ L"Tab", "TAB" },
				{ L"Ctrl", "CONTROL" },
				{ L"Alt", "ALT" },
				{ L"Shift", "SHIFT" },
				{ L"CapsLock", "CAPS_LOCK" },
				{ L"PgUp", "PAGE_UP" },
				{ L"PgDown", "PAGE_DOWN" },
				{ L"F1", "F1" }, { L"F2", "F2" }, { L"F3", "F3" }, { L"F4", "F4" }, { L"F5", "F5" }, { L"F6", "F6" },
				{ L"F7", "F7" }, { L"F8", "F8" }, { L"F9", "F9" }, { L"F10", "F10" }, { L"F11", "F11" }, { L"F12", "F12" },
			}
		},
	},
	category = "wifi",
	helpUrl = "",
	output = {type = "null",},
	canRun = false,
	funcName = "bluetooth.hid.keyboard_key",
	previousStatement = false,
	hide_in_toolbox = true,
	nextStatement = false,
	headerText = "from mpython_ble.application import HID\nfrom mpython_ble.hidcode import KeyboardCode\n",
	func_description = "",
	ToNPL = function(self)
		return ''
	end,
	ToMicroPython = function(self)
		local key = self:getFieldAsString("keyboard_key");
		
		return string.format("KeyboardCode.%s", key);
	end,
	examples = {{ desc = "", canRun = true, code = [[]] }},
},

{
	type = "bluetooth.hid.keyboard_send", 
	message0 = L"BLE HID 键盘 按下按键 %1",
	arg0 = {
		{
			name = "keyboard_send",
			type = "input_value",
			shadow = { type = "text", value = "Space" },
			text = "Space",
		},
	},
	category = "wifi",
	helpUrl = "",
	canRun = false,
	funcName = "bluetooth.hid.keyboard_send",
	previousStatement = true,
	hide_in_toolbox = true,
	nextStatement = true,
	headerText = "from mpython_ble.application import HID\nfrom mpython_ble.hidcode import KeyboardCode\n",
	func_description = "",
	ToNPL = function(self)
		return ''
	end,
	ToMicroPython = function(self)
		local key = self:getFieldAsString("keyboard_send");

		if (key == "Space") then
			key = "KeyboardCode.SPACE";
		end

		local code = "_ble_hid.keyboard_send(%s)\n";

		return string.format(code, key);
	end,
	examples = {{ desc = "", canRun = true, code = [[]] }},
},

{
	type = "bluetooth.hid.keyboard_send_simultaneously", 
	message0 = L"BLE HID 键盘 同时按下按键 %1 %2 %3",
	arg0 = {
		{
			name = "key1",
			type = "input_value",
			shadow = { type = "text", value = "Ctrl" },
			text = "Ctrl",
		},
		{
			name = "key2",
			type = "input_value",
			shadow = { type = "text", value = "C" },
			text = "C",
		},
		{
			name = "key3",
			type = "input_value",
			shadow = { type = "text", value = "" },
			text = "",
		},
	},
	category = "wifi",
	helpUrl = "",
	canRun = false,
	funcName = "bluetooth.hid.keyboard_send_simultaneously",
	previousStatement = true,
	hide_in_toolbox = true,
	nextStatement = true,
	headerText = "from mpython_ble.application import HID\nfrom mpython_ble.hidcode import KeyboardCode\n",
	func_description = "",
	ToNPL = function(self)
		return ''
	end,
	ToMicroPython = function(self)
		local key1 = self:getFieldAsString("key1");
		local key2 = self:getFieldAsString("key2");
		local key3 = self:getFieldAsString("key3");

		if (key1 == "Ctrl") then
			key1 = "KeyboardCode.CONTROL";
		end

		if (key2 == "C") then
			key2 = "KeyboardCode.C";
		end

		local allKeyStr = ""

		if (key1 and key1 ~= "") then
			allKeyStr = allKeyStr .. key1; 
		end

		if (key2 and key2 ~= "") then
			allKeyStr = allKeyStr .. ", " .. key2;
		end

		if (key3 and key3 ~= "") then
			allKeyStr = allKeyStr .. ", " .. key3;
		end

		local code = "_ble_hid.keyboard_send(%s)\n";

		return string.format(code, allKeyStr);
	end,
	examples = {{ desc = "", canRun = true, code = [[]] }},
},

{
	type = "bluetooth.hid.keyboard_press", 
	message0 = L"BLE HID 键盘 长按按键 %1",
	arg0 = {
		{
			name = "keyboard_press",
			type = "input_value",
			shadow = { type = "text", value = "Space" },
			text = "Space",
		},
	},
	category = "wifi",
	helpUrl = "",
	hide_in_toolbox = true,
	canRun = false,
	funcName = "bluetooth.hid.keyboard_press",
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython_ble.application import HID\nfrom mpython_ble.hidcode import KeyboardCode\n",
	func_description = "",
	ToNPL = function(self)
		return ''
	end,
	ToMicroPython = function(self)
		local keyboardPress = self:getFieldAsString("keyboard_press");

		if (keyboardPress == "Space") then
			keyboardPress = "KeyboardCode.SPACE";
		end

		local code = "_ble_hid.keyboard_press(%s)";

		return string.format(code, keyboardPress);
	end,
	examples = {{ desc = "", canRun = true, code = [[]] }},
},

{
	type = "bluetooth.hid.keyboard_release",
	message0 = L"BLE HID 键盘 释放按键 %1",
	arg0 = {
		{
			name = "keyboard_release",
			type = "input_value",
			shadow = { type = "text", value = "Space" },
			text = "Space",
		},
	},
	category = "wifi",
	helpUrl = "",
	canRun = false,
	hide_in_toolbox = true,
	funcName = "bluetooth.hid.keyboard_release",
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython_ble.application import HID\nfrom mpython_ble.hidcode import KeyboardCode\n",
	func_description = "",
	ToNPL = function(self)
		return ''
	end,
	ToMicroPython = function(self)
		local keyboardRelease = self:getFieldAsString("keyboard_release");

		if (keyboardRelease == "Space") then
			keyboardRelease = "KeyboardCode.SPACE";
		end

		local code = "_ble_hid.keyboard_release(%s)";

		return string.format(code, keyboardRelease);
	end,
	examples = {{ desc = "", canRun = true, code = [[]] }},
},

{
	type = "bluetooth.hid.keyboard_release_all",
	message0 = L"BLE HID 键盘 释放所有按键",
	category = "wifi",
	helpUrl = "",
	canRun = false,
	hide_in_toolbox = true,
	funcName = "bluetooth.hid.keyboard_release_all",
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython_ble.application import HID\n",
	func_description = "",
	ToNPL = function(self)
		return ''
	end,
	ToMicroPython = function(self)
		return "_ble_hid.keyboard_release_all()";
	end,
	examples = {{ desc = "", canRun = true, code = [[]] }},
},

{
	type = "bluetooth.hid.consumer_key",
	message0 = L"遥控器按键 %1",
	arg0 = {
		{
			name = "consumer_key",
			type = "field_dropdown",
			text = "POWER",
            options = {
				{ L"POWER", "POWER"}, { L"CHANNEL_UP", "CHANNEL_UP"}, { L"CHANNEL_DOWN", "CHANNEL_DOWN"},
				{ L"RECORD", "RECORD" }, { L"FAST_FORWARD", "FAST_FORWARD"}, { L"REWIND", "REWIND" },
				{ L"SCAN_NEXT_TRACK", "SCAN_NEXT_TRACK" }, { L"SCAN_PREVIOUS_TRACK", "SCAN_PREVIOUS_TRACK" },
				{ L"STOP", "STOP" }, { L"EJECT", "EJECT" }, { L"PLAY_PAUSE", "PLAY_PAUSE" },
				{ L"MUTE", "MUTE" }, { L"VOLUME_DECREMENT", "VOLUME_DECREMENT" }, { L"VOLUMENT_INCREMENT", "VOLUMENT_INCREMENT" }
			}
		}
	},
	category = "wifi",
	helpUrl = "",
	hide_in_toolbox = true,
	output = {type = "null",},
	canRun = false,
	funcName = "bluetooth.hid.remote_control_key",
	previousStatement = false,
	nextStatement = false,
	headerText = "from mpython_ble.hidcode import ConsumerCode\n",
	func_description = "",
	ToNPL = function(self)
		return ''
	end,
	ToMicroPython = function(self)
		local consumerKey = self:getFieldAsString("consumer_key") or "";

		return string.format("ConsumerCode.%s", consumerKey);
	end,
	examples = {{ desc = "", canRun = true, code = [[]] }},
},

{
	type = "bluetooth.hid.consumer_send", 
	message0 = L"BLE HID 遥控器点击 %1",
	arg0 = {
		{
			name = "consumer_send",
			type = "input_value",
			shadow = { type = "text", value = "POWER" },
			text = "POWER",
		},
	},
	category = "wifi",
	helpUrl = "",
	canRun = false,
	hide_in_toolbox = true,
	funcName = "bluetooth.hid.consumer_send",
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython_ble.application import HID\nfrom mpython_ble.hidcode import ConsumerCode\n",
	func_description = "",
	ToNPL = function(self)
		return ''
	end,
	ToMicroPython = function(self)
		local key = self:getFieldAsString("consumer_send");

		if (key == "POWER") then
			key = "ConsumerCode.POWER";
		end

		local code = "_ble_hid.keyboard_send(%s)\n";

		return string.format(code, key);
	end,
	examples = {{ desc = "", canRun = true, code = [[]] }},
},

});