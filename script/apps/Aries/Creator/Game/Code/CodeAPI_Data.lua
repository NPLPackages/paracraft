--[[
Title: CodeAPI
Author(s): LiXizhi
Date: 2018/6/8
Desc: sandbox API environment
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeAPI_Data.lua");
-------------------------------------------------------
]]
NPL.PostLoad(function()
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeUI.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeGlobals.lua");
end)
local UdpSocket = NPL.load("(gl)script/ide/System/os/network/UdpSocket.lua");
local SerialPortConnector = commonlib.gettable("MyCompany.Aries.Game.Code.SerialPortConnector");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local CodeUI = commonlib.gettable("MyCompany.Aries.Game.Code.CodeUI");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local env_imp = commonlib.gettable("MyCompany.Aries.Game.Code.env_imp");


-- simple log any object, similar to echo. 
function env_imp:log(...)
	GameLogic.GetCodeGlobal():log(...);
end

-- similar to log, but without formatting support like %d in first parameter
function env_imp:print(...)
	GameLogic.GetCodeGlobal():print(...);
end

-- @param level: default to 5 
function env_imp:printStack(level)
	local stack = commonlib.debugstack(2, level or 5, 1)
	for line in stack:gmatch("([^\r\n]+)") do
		if(not line:match("C function") and not line:match("CodeCoroutine.lua")) then
			env_imp.echo(self, line);
		end
	end
end

function env_imp:echo(obj, ...)
	commonlib.echo(obj, ...);
	if(type(obj) == "string") then
		GameLogic.RunCommand("/echo "..obj:sub(1, 100))
	else
		GameLogic.RunCommand("/echo "..commonlib.serialize_in_length(obj, 100))
	end
	
end

-- get the entity associated with the actor, or get global entity by name
function env_imp:GetEntity(name)
    if(name and name~="") then
		return EntityManager.GetEntity(name);
    elseif(self.actor) then
		return self.actor:GetEntity();
	end
end

function env_imp:getActorEntityValue(name, key)
	local actor_entity = nil;
	if(not name or name == "myself") then
		actor_entity = self.actor and self.actor:GetEntity();
	elseif(name == "player") then
		actor_entity = EntityManager.GetPlayer();
	elseif(type(name) == "string") then
		local actor = GameLogic.GetCodeGlobal():GetActorByName(name);
		actor_entity = actor and actor:GetEntity();
	end
	if (not actor_entity) then return nil end
	if (key == "x" or key == "y" or key == "z") then
		local bx, by, bz = actor_entity:GetBlockPos();
		if (key == "x") then return bx end
		if (key == "y") then return by end 
		if (key == "z") then return bz end 
	end
	return nil;
end

function env_imp:getActorValue(name)
	if(self.actor) then
		return self.actor:GetActorValue(name)
	end
end

local actor_value_type = {
	["name"] = "string",
	["physicsRadius"] = "number",
	["physicsHeight"] = "number",
	["isBlocker"] = "boolean",
	["isLodEnabled"] = "boolean",
	["groupId"] = "number",
	["sentientRadius"] = "number",
	["x"] = "number",
	["y"] = "number",
	["z"] = "number",
	["time"] = "number",
	["facing"] = "number",
	["walkSpeed"] = "number",
	["pitch"] = "number",
	["roll"] = "number",
	-- ["color"] = "string",
	["opacity"] = "number",
	-- ["selectionEffect"] = "string or number",
	["isAgent"] = "boolean",
	["zorder"] = "number",
	["movieactor"] = "number",
	["playSpeed"] = "number",
	-- ["billboarded"] = "table",
	["shadowCaster"] = "boolean",
	["isServerEntity"] = "boolean",
	["dummy"] = "boolean",
	["gravity"] = "number",
	["velocity"] = "number",
	["addVelocity"] = "number",
	["surfaceDecay"] = "number",
	["airDecay"] = "number",
	["isRelativePlay"] = "boolean",
	["isIgnoreSkinAnim"] = "boolean",
	-- ["parent"] = "string",
	["parentOffset"] = "number",
	["parentRot"] = "number",
}

function env_imp:setActorValue(name, value, v2, v3)
	if (actor_value_type[name] == "number") then
		value = tonumber(value);
		if (value == nil) then return print("setActorValue 设置无效值:", value) end 
	end
	if(self.actor) then
		self.actor:SetActorValue(name, value, v2, v3)
	end
end

function env_imp:showVariable(name, title, color, fontSize)
	if(type(name) == "string") then
		if(color == "") then
			color = nil;
		end
		if(title == "") then
			title = nil;
		end
		if(fontSize == "") then
			fontSize = nil
		end
		if(fontSize) then
			fontSize = tonumber(fontSize)
			if(fontSize) then
				fontSize = math.max(math.min(40, fontSize), 6);
			end
		end
		local item = CodeUI:ShowGlobalData(name, title, color, fontSize);
		if(item) then
			item:TrackCodeBlock(self.codeblock)
		end
	end
end

-- file is included by running it right at the place of including within the containing codeblock. The logics is similar to c++ include.
-- @param filename: include a file relative to current world directory
-- if the filename is a lib name, we will also search for ./lib/filename/filename.lua or system lib folder for the lib. System lib folder is ..Game/Code/lib/filename/filename.lua folder.
function env_imp:include(filename)
	if(self.codeblock) then
		return self.codeblock:IncludeFile(filename)
	end
end

-- importing a library is the alternative way of placing code blocks in the scene. 
-- A library is a group of code blocks in the form of files. These files are usually organized in a folder with the same name of the library. 
-- for example, when import("abc"), we will load all files in ./lib/abc/*.* as code blocks. These code blocks are loaded only once in a given world, 
-- but can be imported multiple times. When the last code block that is importing a library is stopped, the imported libary will be unloaded. 
-- This also makes debugging a library easy by just restarting the code block that referenced it. 
-- When importing a lib, we will first search in the current world directory's ./lib folder for a given library, and then in system library folder, which is ..Game/Code/lib folder.
-- The advantage of using library is for making the scene cleaner than placing code blocks.
-- @param libName: import a library by name. loading all files in  "./lib/[libName]/*.*" folder.
function env_imp:import(libName)
	if(self.codeblock) then
		local library = self.codeblock:ImportCodeLibrary(libName)
		if(not library or library:IsEmpty()) then
			env_imp.exit(self);
		end
	end
end

-- private: This function is faster than getActor(), only used internally. 
function env_imp:GetActor()
	return self.actor;
end

-- get actor by name
-- @param name: nil or "myself" means current actor, or any actor name, if"@p" it means current player
function env_imp:getActor(name)
	if(not name or name == "myself") then
		return self.actor;
	elseif(name == "@p") then
		return GameLogic.GetCodeGlobal():GetPlayerActor();
	else
		return GameLogic.GetCodeGlobal():GetActorByName(name);
	end
end

function env_imp:string_length(var, str)
	if (type(var) == "table") then return #var end 
	if (type(var) == "string") then return ParaMisc.GetUnicodeCharNum(var) end 
	if(type(str) ~= "string") then
		return 0
	end
	return ParaMisc.GetUnicodeCharNum(str);
end

function env_imp:string_char(str, index)
	if not str or str == "" or not index then
		return ""
	end
	local len = ParaMisc.GetUnicodeCharNum(str);
	if (index < 1 or index > len) then return "" end
	return ParaMisc.UniSubString(str, index, index); 
end

function env_imp:string_contain(str, substr)
	if(str and substr) then
		local pos = string.find(str, substr, 1, true);
		return pos and true or false;
	end
end

function env_imp:List_GetIndexByItem(list, item)
    if (type(list) ~= "table") then
        return nil
    end
    for index, val in ipairs(list) do
        if (val == item) then
            return index
        end
    end
    return nil;
end

function env_imp:List_IsExistItem(list, item)
    if (type(list) ~= "table") then
        return false
    end
    for index, val in ipairs(list) do
        if (val == item) then
            return true
        end
    end
    return false;
end

function env_imp:List_Insert(list, index, item)
    if (type(list) ~= "table") then
        return nil
    end
    if (index ~= nil and item == nil) then
        item, index = index, #list + 1
    end
    return table.insert(list, index, item);
end

function env_imp:List_Remove(list, index)
    if (type(list) ~= "table") then
        return nil
    end
    return table.remove(list, index);
end

function env_imp:List_Length(list)
    if (type(list) ~= "table") then
        return 0
    end
    return #(list);
end

-- get url synchronously or async according to whether callbackFunc is nil. 
-- @param url_params: {url=string, options={}, form={}, headers={}, json=true}, see also System.os.GetUrl(). 
-- @param callbackFunc: function(data, errCode, msg) end. if nil, this function is synchronous, if not this function is async. 
-- @return data, errCode, msg: data can be nil or msg if no json object. The second parameter is always http code, the third is HTML message. 
function env_imp:getUrl(url_params, callbackFunc)
	if(not callbackFunc) then
		local err_, msg_, data_
		System.os.GetUrl(url_params, self.co:MakeCallbackFunc(function(err, msg, data)
			err_, msg_, data_ = err, msg, data
			env_imp.resume(self, err, msg, data);
		end))
		env_imp.yield(self)
		if(data_) then
			return data_, err_, msg_;
		elseif(err_ == 200) then
			return msg_, err_, msg_;
		else
			return nil, err_, msg_;	
		end
	else
		System.os.GetUrl(url_params, self.co:MakeCallbackFuncAsyncRun(function(err, msg, data)
			if(not data and err == 200) then
				data = msg;
			end
			callbackFunc(data, err, msg)
		end))
	end
end

-- @param params: {server="mqtt.keepwork.com", port="", user, password, clientid, keepalive=60}
function env_imp:emscripten_mqtt_connect(params)
	local hostname = params.uri or params.server or "mqtt.keepwork.com";
	params.uri = "ws://" .. hostname;
	if(params.port) then params.uri = params.uri..":"..params.port end
	if (hostname == "mqtt.keepwork.com") then
		params.url = "wss://mqtt.keepwork.com:8084/mqtt";
	else
		params.url = params.url or params.uri;
	end
	params.username = params.user or params.username;
	params.clientId = params.clientid or params.id;
	params.clean = params.clean~=false;
	params.keepalive = params.keepalive or params.keep_alive;

	local mqttClient = GameLogic.GetCodeGlobal():GetGlobal("mqtt")
	if(mqttClient) then
		mqttClient:Close()
		GameLogic.GetCodeGlobal():SetGlobal("mqtt", nil)
	end

	NPL.load("(gl)script/apps/Aries/Creator/Game/Emscripten/EmscriptenMQTT.lua");
	local EmscriptenMQTT = commonlib.gettable("MyCompany.Aries.Game.GameLogic.EmscriptenMQTT")
	mqttClient = EmscriptenMQTT:new();
	GameLogic.GetCodeGlobal():SetGlobal("mqtt", mqttClient);

	if(self.codeblock) then
		self.codeblock:Connect("beforeStopped", function()
			local mqttClient = GameLogic.GetCodeGlobal():GetGlobal("mqtt")
			if(mqttClient) then
				mqttClient:Close()
				GameLogic.GetCodeGlobal():SetGlobal("mqtt", nil)
			end
		end)
	end

	local is_yield = true;
	mqttClient:Connect(params, self.co:MakeCallbackFunc(function(bConnected)
		if (is_yield) then
			env_imp.resume(self, bConnected)
			is_yield = false;
		end
	end), function(msg)
		if(msg.topic and msg.payload) then
			GameLogic.GetCodeGlobal():BroadcastTextEvent("__mqtt__"..msg.topic, msg.payload);
		end
	end)
	env_imp.yield(self)
end

-- @param topic: topic to publish to
-- @param payload: any string data
function env_imp:emscripten_mqtt_publish(topic, payload)
	local mqttClient = GameLogic.GetCodeGlobal():GetGlobal("mqtt")
	if(mqttClient) then
		return mqttClient:Publish({topic=topic, payload=payload})
	end
end

-- @param topic: topic to subscribe
-- @param qos: level of subscription, default to 0
function env_imp:emscripten_mqtt_subscribe(topic, callbackFunc, qos)
	env_imp.registerBroadcastEvent(self, "__mqtt__"..topic, callbackFunc)
	local mqttClient = GameLogic.GetCodeGlobal():GetGlobal("mqtt")
	if(mqttClient) then
		mqttClient:Subscribe({topic=topic, qos = qos or 1})
	end
end

-- @param params: {server="mqtt.keepwork.com", port="", user, password, clientid, keepalive=60}
function env_imp:mqtt_connect(params)
	if (System.os.IsEmscripten()) then return env_imp.emscripten_mqtt_connect(self, params) end

	-- do some parameter translation
	params.uri = params.uri or params.server or "mqtt.keepwork.com";
	if(params.port) then
		params.uri = params.uri..":"..params.port;
	end
	params.username = params.user or params.username;
	params.id = params.clientid or params.id;
	params.clean = params.clean~=false;
	params.keep_alive = params.keepalive or params.keep_alive;

	NPL.load("(gl)script/ide/System/os/network/MQTT/mqtt.lua");
	local mqtt = commonlib.gettable("System.os.network.mqtt");

	local mqttClient = GameLogic.GetCodeGlobal():GetGlobal("mqtt")
	if(mqttClient) then
		mqttClient:close_connection()
		GameLogic.GetCodeGlobal():SetGlobal("mqtt", nil)
	end
	-- create MQTT client
	local mqttClient = mqtt:new():Init(params)
	GameLogic.GetCodeGlobal():SetGlobal("mqtt", mqttClient)

	if(self.codeblock) then
		self.codeblock:Connect("beforeStopped", function()
			local mqttClient = GameLogic.GetCodeGlobal():GetGlobal("mqtt")
			if(mqttClient) then
				GameLogic.GetFilters():apply_filters("beforeMqttClosed", mqttClient);
				mqttClient:close_connection()
				GameLogic.GetCodeGlobal():SetGlobal("mqtt", nil)
			end
		end)
	end

	mqttClient:on({
		connect = function(connack)
			if connack.rc ~= 0 then
				GameLogic.AddBBS("mqtt", "连接到MQTT服务器失败:"..connack:reason_string(), 5000, "255 0 0")
				print("connection to broker failed:", connack:reason_string(), connack)
				return
			end
			GameLogic.GetFilters():apply_filters("mqttConnected", connack,mqttClient);
		end,
		message = function(msg)
			-- assert(mqttClient:acknowledge(msg))
			if(msg.topic and msg.payload) then
				GameLogic.GetCodeGlobal():BroadcastTextEvent("__mqtt__"..msg.topic, msg.payload);
			end
		end,
		error = function(err)
			LOG.std(nil,"info","CodeAPI_Data",err)
		end,
		close = function(result)
			GameLogic.GetFilters():apply_filters("mqttClosed", result,mqttClient);
		end
	})
	mqttClient:start(self.co:MakeCallbackFunc(function(bConnected)
		env_imp.resume(self, bConnected)
	end))
	local bConnected = env_imp.yield(self)
	return bConnected;
end

-- @param topic: topic to publish to
-- @param payload: any string data
function env_imp:mqtt_publish(topic, payload)
	if type(payload) ~= "string" then
		payload = tostring(payload)
	end
	if (System.os.IsEmscripten()) then return env_imp.emscripten_mqtt_publish(self, topic, payload) end

	local mqttClient = GameLogic.GetCodeGlobal():GetGlobal("mqtt")
	if(mqttClient) then
		return mqttClient:publish({topic=topic, payload=payload})
	end
end

-- @param topic: topic to subscribe
-- @param qos: level of subscription, default to 0
function env_imp:mqtt_subscribe(topic, callbackFunc, qos)
	if (System.os.IsEmscripten()) then return env_imp.emscripten_mqtt_subscribe(self, topic, callbackFunc, qos) end

	env_imp.registerBroadcastEvent(self, "__mqtt__"..topic, callbackFunc)

	local mqttClient = GameLogic.GetCodeGlobal():GetGlobal("mqtt")
	if(mqttClient) then
		local subscribe_args = {
			topic=topic, 
			qos = qos or 1, 
			callback=self.co:MakeCallbackFunc(function()
				env_imp.resume(self)
			end)
		}
		mqttClient:subscribe(subscribe_args)
		GameLogic.GetFilters():apply_filters("mqttSubscribed", subscribe_args,mqttClient);
		env_imp.yield(self)
		return true;
	end
end

-- serialport_send(data)
-- serialport_send(data, dataType) 
-- serialport_send(portIndex, data, dataType) 
-- @param portIndex: it can be a number or data. if -1 means all ports.
-- @param data: text or binary data to send.
-- @param dataType: if nil it is raw data. if "code" data is python code
function env_imp:serialport_send(portIndex, data, dataType)
	if(not SerialPortConnector.Send) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Code/SerialPort/SerialPortConnector.lua");
	end
	SerialPortConnector.Show();
	if(type(portIndex) ~= "number") then
		data, dataType = portIndex, data;
		portIndex = nil;
	end

	if( dataType == "code") then
		SerialPortConnector.RunPythonCodeREPL(data, portIndex)
	else
		SerialPortConnector.Send(data, portIndex)
	end
end

function env_imp:udp_open(port)
	UdpSocket:Open(port);
end

function env_imp:udp_send(data, ip, port)
	UdpSocket:Send(ip, port, data);
end

function env_imp:udp_broadcast(data)
	UdpSocket:Broadcast(data);
end

function env_imp:udp_recv(callback)
	env_imp.registerBroadcastEvent(self, "__udp__", callback)
	UdpSocket:Recv(function(data)
		GameLogic.GetCodeGlobal():BroadcastTextEvent("__udp__", data);
	end);
end

--personnal page store
function env_imp:loadPersonalPageData(pageName, key, callbackFunc)
	if type(pageName) ~= "string" or pageName == "" then
		 print("invalid pageName")
		return 
	end
	if not GameLogic.PersonalPageStore then
		print("PersonalPageStore is loaded failed")
		return
	end
	if not callbackFunc or type(callbackFunc) ~= "function" then
		local data_ = nil
		GameLogic.PersonalPageStore:LoadKeys(pageName, key, self.co:MakeCallbackFunc(function(data)
			data_ = data
			env_imp.resume(self, data);
		end))
		env_imp.yield(self)
		return data_;
	else
		GameLogic.PersonalPageStore:LoadKeys(pageName, key, self.co:MakeCallbackFuncAsyncRun(function(data)
			callbackFunc(data)
		end))
	end
end

function env_imp:deletePersonalPageData(pageName, key, bFlush)
	if type(pageName) ~= "string" or pageName == "" then
		print("invalid pageName")
		return
	end
	if not GameLogic.PersonalPageStore then
		print("PersonalPageStore is loaded failed")
		return
	end
	GameLogic.PersonalPageStore:DeleteKeys(pageName, key, bFlush)

end

function env_imp:savePersonalPageData(pageName, key, value, bFlush)
	if type(pageName) ~= "string" or pageName == "" then
		print("invalid pageName")
	   return 
   end
   if not GameLogic.PersonalPageStore then
	   print("PersonalPageStore is loaded failed")
	   return
   end
   GameLogic.PersonalPageStore:SaveKeys(pageName, key, value, bFlush)
end

-- Save personal page data as time series
-- @param pageName: string - Page name
-- @param keyValues: table - Array of {key="time", value=20250806, type="unique"} objects
-- @param maxKeyCount: number - Maximum number of items to keep in arrays (default: 10)
-- @param callbackFunc: function - Optional callback function
function env_imp:savePersonalPageDataTimeSeries(pageName, keyValues, maxKeyCount, callbackFunc, bFlush)
	if type(pageName) ~= "string" or pageName == "" then
		print("invalid pageName")
		return
	end
	if not GameLogic.PersonalPageStore then
		print("PersonalPageStore is loaded failed")
		return
	end
	if type(keyValues) ~= "table" then
		print("invalid keyValues, should be table")
		return
	end
	
	maxKeyCount = maxKeyCount or 10
	
	if not callbackFunc or type(callbackFunc) ~= "function" then
		-- Synchronous call
		local result = nil
		GameLogic.PersonalPageStore:SavePageDataTimeSeries(pageName, keyValues, maxKeyCount, self.co:MakeCallbackFunc(function(success)
			result = success
			env_imp.resume(self, success)
		end), bFlush)
		env_imp.yield(self)
		return result
	else
		-- Asynchronous call
		GameLogic.PersonalPageStore:SavePageDataTimeSeries(pageName, keyValues, maxKeyCount, self.co:MakeCallbackFuncAsyncRun(function(success)
			callbackFunc(success)
		end), bFlush)
	end
end

function env_imp:saveDataToFile(filepath, content)
	local basePath = ParaIO.GetWritablePath()
	content = tostring(content)
	if filepath and filepath ~= "" then
		filepath = basePath..filepath
		local openFileMode = "w+"
		if not ParaIO.DoesFileExist(filepath) then
			ParaIO.CreateDirectory(filepath)
		else
			openFileMode = "a+"
		end
		local file = ParaIO.open(filepath, openFileMode)
		if file then
			file:WriteString(content .. "\n")
			file:close()
		end
	end
end