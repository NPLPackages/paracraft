--[[
Title: Serial Port Connector
Author(s): LiXizhi
Date: 2023/7/29
Desc: singleton class for serial port connector

micropython on ESP32 REPL(read-eval-print-loop) mode. 
  CTRL-A '\001'       -- on a blank line, enter raw REPL mode
  CTRL-B '\002'       -- on a blank line, enter normal REPL mode
  CTRL-C '\003'       -- interrupt a running program
  CTRL-D '\004'       -- on a blank line, do a soft reset of the board
  CTRL-E '\005'       -- on a blank line, enter paste mode

please note, if we receive a line that begins with "/" we will run it as a command,
such as "/tip hello" or "/sendevent hello msg", these provide simply two way communications between hardware and paracraft. 

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/SerialPort/SerialPortConnector.lua");
local SerialPortConnector = commonlib.gettable("MyCompany.Aries.Game.Code.SerialPortConnector");
SerialPortConnector.Show()
SerialPortConnector.Close()
SerialPortConnector.Send("help()\r\n")
SerialPortConnector.Send('\004') -- send ctrl + D : soft reboot
SerialPortConnector.SetRunMicroPythonMainCode('print("hello")')
SerialPortConnector.RunPythonCodeREPL('print("hello")')

-- sample of virtual port
local VirtualSerialPort = inherit()
function VirtualSerialPort:ctor()
    entity = GetEntity();
    self.name = entity:GetName();
end
function VirtualSerialPort:open()
    return true;
end
function VirtualSerialPort:isOpen()
    return true;
end
function VirtualSerialPort:GetFilename()
    return self.name;
end
function VirtualSerialPort:GetFullname()
    return self:GetFilename()
end
function VirtualSerialPort:Connect(name, callback) 
    self[name] = callback
end
function VirtualSerialPort:send(data)
    -- TODO: 
end
function VirtualSerialPort:OnReceive(data) 
    if(self.dataReceived) then
        self.dataReceived(data, self)
    end
    -- process line by line
    local remaining = (self.lineBuffer or "")..data;
    while (remaining) do
        local line, remaining2 = remaining:match("^([^\r\n]*)[\r\n]+(.*)$")
        if(line) then
            if(self.lineReceived) then
                self.lineReceived(line, self);
            end
            remaining = remaining2;
        else
            break;
        end
    end
    self.lineBuffer = remaining;
end
function VirtualSerialPort:close()
end
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/SerialPort/SerialPortConnector.lua");
local SerialPortConnector = commonlib.gettable("MyCompany.Aries.Game.Code.SerialPortConnector");
local virtalPort = VirtualSerialPort:new()
SerialPortConnector.AddVirtualPort(virtalPort:GetFilename(), virtalPort)
registerStopEvent(function()
    SerialPortConnector.RemoveVirtualPort(virtalPort:GetFilename())
end)
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/os/Serial.lua");
NPL.load("(gl)script/ide/System/os/BlueTooth.lua");
local Serial = commonlib.gettable("System.os.Serial");
local BlueTooth = commonlib.gettable("System.os.BlueTooth");
local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
local SerialPortConnector = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Code.SerialPortConnector"));
SerialPortConnector:Signal("dataReceived", function(data) end)
SerialPortConnector:Signal("lineReceived", function(line) end)

SerialPortConnector.driverUrl = "https://keepwork.com/official/open/download/serialportdriver";

local page;
local currentPort;
local currentBLEPortName;
local allPorts;
local virtualPorts;
local platform = System.os.GetPlatform();

function SerialPortConnector:ctor()
    allPorts = commonlib.ArrayMap:new();
    virtualPorts = {}; -- {name, port} map
end

function SerialPortConnector.Init()
    page = document:GetPageCtrl();
end

function SerialPortConnector.Show()
    if (page and page:IsVisible()) then
        return;
    end
    
    local width, height = 230, 32;
    local params = {
        url = "script/apps/Aries/Creator/Game/Code/SerialPort/SerialPortConnector.html", 
        name = "SerialPortConnector.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        bToggleShowHide = false, 
        style = CommonCtrl.WindowFrame.ContainerStyle,
        zorder = 2,
        allowDrag = true,
        click_through = false, 
        enable_esc_key = false,
        bShow = true,
        ---app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,
        align = "_ctt",
        x = -width,
        y = 10,
        width = width,
        height = height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);

    SerialPortConnector.StartTimer();
    params._page.OnClose = function()
        page = nil;
        SerialPortConnector.mytimer:Change();
    end
end

function SerialPortConnector.SetConnectMode()
    SerialPortConnector.mode = "connect";
    SerialPortConnector.RefreshPage()
end

function SerialPortConnector.RefreshPage()
    if (page) then
        page:Refresh(0.01);
    end
end

function SerialPortConnector.Close()
    if (page) then
        page:CloseWindow();
    end
end

function SerialPortConnector.StartTimer()
    SerialPortConnector.mytimer = SerialPortConnector.mytimer or commonlib.Timer:new({callbackFunc = SerialPortConnector.OnTick})
    SerialPortConnector.mytimer:Change(200, 200);
end

function SerialPortConnector.OnTick(timer)
end

local portNames = {}
local portNamesDS = {{value="", text=L"自动", selected=true}};

function SerialPortConnector.GetPortNames()
    return portNames;
end

function SerialPortConnector.GetPortNameDS()
    return portNamesDS;
end

function SerialPortConnector.GetCurrentPortName()
    if (currentPort) then
        return currentPort:GetFullname();
    end
    return "";
end

function SerialPortConnector.GetCurrentFilename()
    if (platform == "ios" or currentBLEPortName == L"蓝牙") then
        return L"蓝牙";
    else
        if (currentPort) then
            return currentPort:GetFilename();
        end
    end
    return "";
end

function SerialPortConnector.GetActivePorts()
    return allPorts;
end

function SerialPortConnector.GetActivePortCount()
    return allPorts:size();
end

function SerialPortConnector.UpdatePortList()
    local portNames = SerialPortConnector.GetPortNames();
    portNamesDS = {{value="", text=L"自动"}}; -- {{value="COM1"}, {value="COM2"}};
    for _, name in ipairs(portNames) do
        portNamesDS[#portNamesDS+1] = {value=name};
    end
    local selectedPortName = SerialPortConnector.GetCurrentPortName() or "";
    for _, option in ipairs(portNamesDS) do
        option.selected = selectedPortName == option.value;
    end
    if(platform == "win32") then
        portNamesDS[#portNamesDS+1] = {value="installDriver", text=L"安装驱动"};
    end
end

-- this function is slow, call it sparingly
function SerialPortConnector.FetchPortNames()
    if (platform == "ios") then
        portNames = { L"蓝牙" };
    else
        portNames = Serial:GetPortNames() or {};
        for name, _ in pairs(virtualPorts) do
            portNames[#portNames + 1] = name;
        end

        if (platform == "android" or platform == "win32") then
            portNames[#portNames + 1] = L"蓝牙";
        end
    end

    return portNames;
end

function SerialPortConnector.SearchPortNames()
    local portNames = SerialPortConnector.FetchPortNames();

    SerialPortConnector.UpdatePortList();
    if(#portNames == 0) then
        GameLogic.AddBBS("SerialPortConnector", L"没有找到串口设备，请链接设备", 6000, "0 255 0");
    end
    SerialPortConnector.RefreshPage();
end

function SerialPortConnector.IsConnected()
    if (platform == "ios" or currentBLEPortName == L"蓝牙") then
        if (SerialPortConnector.mode == "connected") then
            return true;
        else
            return false;
        end
    else
        return currentPort ~= nil and currentPort:isOpen();
    end
end

function SerialPortConnector.GetCurrentPort()
    return currentPort;
end

function SerialPortConnector.Disconnect()
    if (platform == "ios" or currentBLEPortName == L"蓝牙") then
        BlueTooth:disconnectBlueTooth();
        currentBLEPortName = nil;
    else
        if (currentPort) then
            currentPort:close();
            SerialPortConnector.RemovePort(currentPort);
            SerialPortConnector.SearchPortNames();
        end
    end
end

function SerialPortConnector.DisconnectAll()
    if (platform == "ios" or currentBLEPortName == L"蓝牙") then
		BlueTooth:disconnectBlueTooth();
		currentBLEPortName = nil;
	else
        local hasClosedPort;
		while(true) do
            local count = SerialPortConnector.GetActivePortCount()
            if(count > 0) then
    		    local port = allPorts:at(count)
			    if(port) then
				    port:close();
				    SerialPortConnector.RemovePort(port);
                    hasClosedPort = true;
                else
                    break;
			    end
            else
                break;
            end
		end
        if(hasClosedPort) then
            SerialPortConnector.SearchPortNames();
        end
	end
end

function SerialPortConnector.InstallDriver()
	ParaGlobal.ShellExecute("open", SerialPortConnector.driverUrl, "", "", 1);
end

function SerialPortConnector.OnSelectPort(name, value)
    if(value == "installDriver") then
        SerialPortConnector.InstallDriver()
        if(page) then
            page:SetValue(name, "");
        end
        return;
    end
end

function SerialPortConnector.AddPort(port, index)
    SerialPortConnector.SetCurrentPort(port);
    allPorts:add(port:GetFullname(), port, index);
    return allPorts:getIndex(port:GetFullname());
end

function SerialPortConnector.RemovePort(port)
    allPorts:remove(port:GetFullname());
    if (currentPort == port) then
        currentPort = allPorts:first();
    end
end

function SerialPortConnector.SetCurrentPort(port)
    currentPort = port;
end

-- @param portName: if "" or nil, we will try to select a non-virtual port.
-- if it is an unconnected virtual port name, we will automatically connect and then select it. 
-- in other conditions, we will just select if there is an existing connected port with the same name. 
-- @param isVirtualPortOnly: true we will connect to the first virtual port and select it.
function SerialPortConnector.SetCurrentPortByName(portName, isVirtualPortOnly)
    if (not portName or portName == "") then
        for name, port in allPorts:pairs() do
            if (not virtualPorts[portName]) then
                portName = name;
                break
            end
        end
        if(isVirtualPortOnly) then
            -- set portName to first item in virtualPorts
            for name, port in pairs(virtualPorts) do
			    portName = name;
			    break
		    end
        end
    end
    if(isVirtualPortOnly and (not portName or not virtualPorts[portName])) then
        -- for virtual port, always use one even if name does not match. 
        for name, port in pairs(virtualPorts) do
			portName = name;
            break;
		end
    end
    
    if (allPorts:contains(portName)) then
        local curPort = allPorts:get(portName);
        if (currentPort ~= curPort) then
            SerialPortConnector.SetCurrentPort(curPort)
            SerialPortConnector.mode = "connected";
            SerialPortConnector.RefreshPage();
        elseif (SerialPortConnector.mode ~= "connected") then
            SerialPortConnector.mode = "connected";
            SerialPortConnector.RefreshPage();
        end
        return true;
    elseif (portName and virtualPorts[portName]) then
        SerialPortConnector.Connect(isVirtualPortOnly)
        if(allPorts:contains(portName)) then
            return SerialPortConnector.SetCurrentPortByName(portName)
        end
    end
end

-- open virtual or physical port. 
-- @return the port object
function SerialPortConnector.OpenPort(portName)
    local file = virtualPorts[portName];
    if(file) then
        if(file.open and file:open()) then
            return file;
        else
            LOG.std(nil, "system", "SerialPortConnector", "failed to open virtual port: %s", portName);
            return
        end
    else
        file = Serial:OpenPort(portName)
    end
    return file;
end

function SerialPortConnector.OnSetBlueStatus()
    SerialPortConnector.mode = "connected";
    SerialPortConnector.RefreshPage();
end

-- @param isVirtualPortOnly: true we will not connect to real port.
function SerialPortConnector.Connect(isVirtualPortOnly)
    if (SerialPortConnector.GetCurrentPortName() ~= "") then
        local portName = page and page:GetUIValue("portName") or "";
        if ((not portName or portName == "") or allPorts:contains(portName)) then
            local port = allPorts:get(portName)
            if (port) then
                SerialPortConnector.SetCurrentPort(port)
                SerialPortConnector.mode = "connected";
                SerialPortConnector.RefreshPage();
                return true;
            end
        end
    end
    
    local portName = page and page:GetUIValue("portName") or "";

    if (platform == "ios" or portName == L"蓝牙") then
        if (platform == "win32") then
            BlueTooth:init(function()
                BlueTooth:setDeviceName("paracraft_ble");
                BlueTooth:setupBluetoothDelegate();
                BlueTooth:reconnectBlueTooth();
                GameLogic.AddBBS("SerialPortConnector", L"正在连接蓝牙设备...", 5000, "0 0 255");
                currentBLEPortName = portName;
                BlueTooth:Connect("setBlueStatus", SerialPortConnector, SerialPortConnector.OnSetBlueStatus, "UniqueConnection")
            end);
        else
            BlueTooth:init();
            BlueTooth:setDeviceName("paracraft_ble");
            BlueTooth:setupBluetoothDelegate();
            BlueTooth:reconnectBlueTooth();
            GameLogic.AddBBS("SerialPortConnector", L"正在连接蓝牙设备...", 5000, "0 0 255");
            currentBLEPortName = portName;
            BlueTooth:Connect("setBlueStatus", SerialPortConnector, SerialPortConnector.OnSetBlueStatus, "UniqueConnection")
        end
        
        return;
    end

    if (portName and portName ~= "") then
        local file = SerialPortConnector.OpenPort(portName)
        if (file) then
            SerialPortConnector.AddPort(file)
            file:Connect("dataReceived", SerialPortConnector.OnDataReceived)
            file:Connect("lineReceived", SerialPortConnector.OnLineReceived)
        end
    else
        local ports = SerialPortConnector.FetchPortNames()
        if (ports) then
            local firstPort;
            for _, name in ipairs(ports) do
                if(not isVirtualPortOnly or virtualPorts[name]) then
                    local file = SerialPortConnector.OpenPort(name)
                    if (file) then
                        firstPort = firstPort or file;
                        SerialPortConnector.AddPort(file)
                        file:Connect("dataReceived", SerialPortConnector.OnDataReceived)
                        file:Connect("lineReceived", SerialPortConnector.OnLineReceived)
                    end
                end
                -- try connect to all available ports
                -- break;
            end
            SerialPortConnector.SetCurrentPort(firstPort)
        end
    end
    if (currentPort) then
        -- Connected:
        SerialPortConnector.UpdatePortList()
        SerialPortConnector.mode = "connected";
        SerialPortConnector.RefreshPage();
        return true;
    else
        GameLogic.AddBBS("SerialPortConnector", L"无法连接串口", 5000, "255 0 0");
    end
    
end

function SerialPortConnector.onBeforeClickDropDownButton()
    SerialPortConnector.FetchPortNames();
    SerialPortConnector.UpdatePortList();
end

function SerialPortConnector.OnDataReceived(data)
    -- echo("data:" .. data)
    SerialPortConnector:dataReceived(data)
end

function SerialPortConnector.OnLineReceived(line)
    if(line:match("^>?O?K???>?raw REPL; CTRL%-B to exit")) then
		-- ignore raw REPL prefix
    elseif(line:match("^>?O?K???>?>?%s?/%w+")) then
        -- escape ">>> " and ">OK>" for raw and normal REPL prefix
        line = line:gsub("^[^/]+", "")
        GameLogic.RunCommand(line);
    else
        SerialPortConnector:lineReceived(line)
        if(#line > 100) then
            line = line:sub(1, 100) .. "...";
        end
        GameLogic.GetCodeGlobal():print(line);
    end
end

function SerialPortConnector.SwitchBLEMode()
    local port;
    
    if (not CodeBlockWindow or not CodeBlockWindow.IsVisible) then
        return;
    end

    if (not CodeBlockWindow.IsVisible() and preferredPortNameOrIndex and preferredPortNameOrIndex ~= "") then
        port = SerialPortConnector.GetPort(preferredPortNameOrIndex)
    end

    port = port or SerialPortConnector.GetPort();

    if (port and SerialPortConnector.IsConnected()) then
        local filename = "main.py"
        local template = [[
from mpython import *
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
]]

        code = string.format(template, code);
        code = code:gsub("\\", "\\\\")
        code = code:gsub("\r", "\\r")
        code = code:gsub("\n", "\\n")
        code = code:gsub("\"", "\\\"")
        local result = string.format("\003\005f = open('%s','w')\r\nf.write(\"%s\")\r\nf.close()\r\n\004", filename, code)
        LOG.std(nil, "info", "SerialPortConnector", "upload file: %s", filename);
        port:send(result)
    
        if(filename == "main.py") then
            port:send('\004') -- soft reboot to run main.py
        end
    end
end

function SerialPortConnector.BLEExec(code)
    if (not SerialPortConnector.IsConnected() or not code) then
        return;
    end

    code = code:gsub("\\", "\\\\")
    code = code:gsub("\r", "\\r")
    code = code:gsub("\n", "\\n")
    code = code:gsub("\"", "\\\"")

    BlueTooth:writeToCharacteristic(BlueTooth.serUUID, BlueTooth.chaUUID, code);
end

function SerialPortConnector.SetRunArduinoMainCode(code, filename, preferredPortNameOrIndex)
    local port;
    if (not CodeBlockWindow.IsVisible() and preferredPortNameOrIndex and preferredPortNameOrIndex ~= "") then
        port = SerialPortConnector.GetPort(preferredPortNameOrIndex)
    end
    port = port or SerialPortConnector.GetPort();

    if (port and SerialPortConnector.IsConnected() and code) then
        if (not filename or not filename:match("%.ino$")) then
            filename = "main.ino"
        end
        -- Ctrl+C to interrupt, Ctrl+E to enter paste mode, paste code, and Ctrl+D to exit
        code = code:gsub("\\", "\\\\")
        code = code:gsub("\r", "\\r")
        code = code:gsub("\n", "\\n")
        code = code:gsub("\"", "\\\"")
        local result = string.format("\003\005f = open('%s','w')\r\nf.write(\"%s\")\r\nf.close()\r\n\004", filename, code)
        port:send(result)
        if(filename == "main.ino") then
            port:send('\004') -- soft reboot to run main.ino
        end
        return true
    end
end

-- we will write the code to given file. 
-- @param filename: if filename does not end with .py, we will write to main.py by default.
-- @param code: code string
function SerialPortConnector.SetRunMicroPythonMainCode(code, filename, preferredPortNameOrIndex)
    if (platform == "ios" or currentBLEPortName == L"蓝牙") then
        if (SerialPortConnector.IsConnected() and code) then
            if (not filename or not filename:match("%.py$")) then
                filename = "main.py"
            end

            local template = [[
from mpython import *
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
%s

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
]]
            code = string.format(template, code);

            if (System.os.GetPlatform() == "win32") then
                code = code:gsub("\\", "\\\\\\");
                code = code:gsub("\r", "\\\\r");
                code = code:gsub("\n", "\\\\n");
                code = code:gsub("\"", "\\\\\"");
            else
                code = code:gsub("\\", "\\\\");
                code = code:gsub("\r", "\\r");
                code = code:gsub("\n", "\\n");
                code = code:gsub("\"", "\\\"");
            end

            local result = string.format("f = open('%s','w')\r\nf.write(\"%s\")\r\nf.close()\r\nmachine.reset()", filename, code);
            BlueTooth:writeToCharacteristic(BlueTooth.serUUID, BlueTooth.chaUUID, result, true);

            GameLogic.AddBBS(nil, "正在执行中，请稍候...", 10000, "47 247 110");

            if (platform == "ios") then
                SerialPortConnector.mode = nil;
                SerialPortConnector.RefreshPage();
                
                commonlib.TimerManager.SetTimeout(function()
                    SerialPortConnector.Connect();
                end, 15000)
            elseif (platform == "win32") then
                BlueTooth.isWin32Connected = false;
                BlueTooth.isFoundDevice = false;

                SerialPortConnector.mode = nil;
                SerialPortConnector.RefreshPage();
                
                commonlib.TimerManager.SetTimeout(function()
                    SerialPortConnector.Connect();
                end, 15000)
            end
        end
    else
        local port;
        if (not CodeBlockWindow.IsVisible() and preferredPortNameOrIndex and preferredPortNameOrIndex ~= "") then
            port = SerialPortConnector.GetPort(preferredPortNameOrIndex)
        end
        port = port or SerialPortConnector.GetPort();

        if (port and SerialPortConnector.IsConnected() and code) then
            if (not filename or not filename:match("%.py$")) then
                filename = "main.py"
            end
            code = code:gsub("\\", "\\\\")
            code = code:gsub("\r", "\\r")
            code = code:gsub("\n", "\\n")
            code = code:gsub("\"", "\\\"")
            -- Ctrl+C twice to interrupt any running program
            port:send("\r\003")
            ParaEngine.Sleep(0.1)
            port:send("\003")
            ParaEngine.Sleep(0.1)
            -- Ctrl+E to enter paste mode, paste code, and Ctrl+D to exit
            local result = string.format("\005f = open('%s','w')\r\nf.write(\"%s\")\r\nf.close()\r\n\004", filename, code)
            port:send(result)
            LOG.std(nil, "info", "SerialPortConnector", "upload file: %s size:%d", filename, #result);
            if(filename == "main.py") then
                port:send('\004') -- soft reboot to run main.py
            end
            return true
        end
    end
end

-- @param nIndexOrName: if nil, use current port; if number, use the port at index; if string, use the port with given name
function SerialPortConnector.GetPort(nIndexOrName)
    if(not nIndexOrName) then
        return SerialPortConnector.GetCurrentPort()
    elseif(type(nIndexOrName) == "number") then
        return allPorts:at(nIndexOrName);
    elseif(type(nIndexOrName) == "string") then
        return allPorts:get(nIndexOrName);
    end
end

-- execute python code in REPL mode
-- @param nIndexOrName: if nil, use current port; if number, use the port at index; if -1, send to all ports
function SerialPortConnector.RunPythonCodeREPL(code, nIndexOrName)
    local count = SerialPortConnector.GetActivePortCount()
    if(code and count > 0) then
        -- normalize line endings
        code = code:gsub("\r\n", "\n")
        code = code:gsub("\n", "\r\n")
        -- Ctrl+A to enter raw mode, paste code, and Ctrl+D to exit
        local result = string.format("\001%s\r\n\004", code)
        
        if(nIndexOrName ~= -1 or count <=1) then
            local port = SerialPortConnector.GetPort(nIndexOrName)
            if(port and port:isOpen()) then
                port:send(result)
                return true
            end
        else
            for i = 1, count do
                local port = allPorts:at(i)
                if(port and port:isOpen()) then
                    port:send(result)
                end
            end
        end
    end
end

-- send raw command like "help()\r\n", "\004" Ctrl+D soft reboot. 
-- @param nIndexOrName: if nil, use current port; if number, use the port at index; if -1, send to all ports
function SerialPortConnector.Send(cmd, nIndexOrName)
    if (platform == "ios" or currentBLEPortName == L"蓝牙") then
    else
        local count = SerialPortConnector.GetActivePortCount()
        if(cmd and count > 0) then
            if(nIndexOrName ~= -1 or count <=1) then
                local port = SerialPortConnector.GetPort(nIndexOrName)
                if(port and port:isOpen()) then
                    port:send(cmd)
                    return true
                end
            else
                for i = 1, count do
                    local port = allPorts:at(i)
                    if(port and port:isOpen()) then
                        port:send(cmd)
                    end
                end
            end
        end
    end
end

-- add a virtual serial port which may be implemented in code block or scripts
-- @param name: unique name of the virtual port
-- @param port: the port object which has the same interface as System.os.SerialPort
function SerialPortConnector.AddVirtualPort(name, port)
    virtualPorts[name] = port;
end

function SerialPortConnector.RemoveVirtualPort(name)
    local port = virtualPorts[name]
    if(port) then
        virtualPorts[name] = nil;
        SerialPortConnector.RemovePort(port)
        SerialPortConnector.SearchPortNames()
    end
end

function SerialPortConnector.ClearVirtualPorts()
    virtualPorts[name] = {};
end

function SerialPortConnector.HasVirtualPort(name)
    return name and virtualPorts[name] ~= nil
end

SerialPortConnector:InitSingleton();