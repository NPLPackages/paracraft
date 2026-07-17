--[[
Title: Android
Author(s): big
Date: 2025.8.14
Desc: Paracraft Android平台通信模块，用于Lua与JavaScript的双向通信
------------------------------------------------------------
local Android = NPL.load("(gl)script/apps/Aries/Creator/Game/Android/Android.lua");
Android:SendMsg("xxx", {key = "value"}, nil, nil, "native");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
NPL.load("(gl)script/ide/System/os/os.lua");
NPL.load("(gl)script/ide/System/Encoding/base64.lua");
NPL.load("(gl)script/ide/Json.lua");

local Android = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

function Android:ctor()
    self.m_msg_callback = {};
    self.m_msgid_callback = {};
    self.m_msgid = 0;
    self.m_loaded = false;

    self.m_onload_timer = commonlib.Timer:new({callbackFunc = function()
        self:SendMsg("load");
    end});

    self.m_onload_timer:Change(200, 200);
end

function Android:GetNextMsgId()
    self.m_msgid = self.m_msgid + 1;
    return self.m_msgid;
end

function Android:SendMsgToJava(msgname, msgdata, msgid, callback)
    if (msgid == nil) then msgid = self:GetNextMsgId() end
    if (type(callback) == "function") then self.m_msgid_callback[msgid] = callback end

    ParaEngine.GetAttributeObject():SetField("SendMsgToJava", commonlib.Json.Encode({
        target = target or "android",
        msgid = msgid,
        msgname = msgname,
        msgdata = msgdata,
    }));
end

-- target = native 发送给 android webview 中的 js
-- target = webview 发送给 android webview
-- target = external 发送给外部应用
-- 接受 target = native 消息 NPL.this(function() msg = msg or {}; print(msg) end, {filename="android"});
-- 接受 target = webview 消息 NPL.this(function() msg = msg or {}; print(msg) end, {filename="webview"});
-- 接受 target = external 消息 NPL.this(function() msg = msg or {}; print(msg) end, {filename="external"});
function Android:SendMsg(msgname, msgdata, msgid, callback, target)
    if (msgid == nil) then msgid = self:GetNextMsgId() end
    if (type(callback) == "function") then self.m_msgid_callback[msgid] = callback end

    -- 使用 ParaEngine 的 Android 特定属性来发送消息到 JavaScript
    ParaEngine.GetAttributeObject():SetField("SendMsgToJS", commonlib.Json.Encode({
        target = target or "android",
        msgid = msgid,
        msgname = msgname,
        msgdata = msgdata,
    }));
end

function Android:RecvMsg(msg)
    if (type(msg) ~= "table" or type(msg.msgname) ~= "string") then return end
    local msgid = msg.msgid;
    local msgname = msg.msgname;
    local msgdata = msg.msgdata;

    local msgid_callback = self.m_msgid_callback[msgid or 0];
    if (msgid_callback) then msgid_callback(msgdata) end

	if (msgname == "echo") then
        echo(msg, true)
    elseif (msgname == "echo_and_reply") then
        Android:SendMsg("echo", msgdata);
    elseif (msgname == "load") then
        if (not self.m_loaded) then 
            self.m_loaded = true;
            -- 加载AndroidCodeBlock
            local AndroidCodeBlock = NPL.load("(gl)script/apps/Aries/Creator/Game/Android/AndroidCodeBlock.lua");
            if (not AndroidCodeBlock) then print("==============================AndroidCodeBlock Load Failed!!!=====================================") end
            -- 响应消息
            self:SendMsg("load");
        end
        -- 取消定时器
        if (self.m_onload_timer) then
            self.m_onload_timer:Change();
            self.m_onload_timer = nil;
            print("Android Loaded!!! cancel timer");
        end
    elseif (msgname == "execute") then
        self:Execute(msgdata, msgid);
    elseif (msgname == "permission_request") then
        self:HandlePermissionRequest(msgdata, msgid);
    elseif (msgname == "file_access") then
        self:HandleFileAccess(msgdata, msgid);
    elseif (msgname == "camera_access") then
        self:HandleCameraAccess(msgdata, msgid);
    elseif (msgname == "microphone_access") then
        self:HandleMicrophoneAccess(msgdata, msgid);
    elseif (msgname == "storage_access") then
        self:HandleStorageAccess(msgdata, msgid);
    elseif (msgname == "network_status") then
        self:HandleNetworkStatus(msgdata, msgid);
    elseif (msgname == "device_info") then
        self:HandleDeviceInfo(msgdata, msgid);
    else
        self:EmitMsg(msgname, msgdata, msgid);
    end
end

function Android:GetMsgCallbacks(msgname)
    return self.m_msg_callback[msgname] or {};
end

function Android:OnMsg(msgname, callback)
    self.m_msg_callback[msgname] = self.m_msg_callback[msgname] or {};
    self.m_msg_callback[msgname][callback] = callback;
end

function Android:OffMsg(msgname, callback)
    self.m_msg_callback[msgname] = self.m_msg_callback[msgname] or {};
    if (not callback) then
        self.m_msg_callback[msgname] = {};
        return
    end
    self.m_msg_callback[msgname][callback] = nil;
end

function Android:OffAllMsg()
    self.m_msg_callback = {};
end

function Android:EmitMsg(msgname, msgdata, msgid)
    local callbacks = self:GetMsgCallbacks(msgname);
    for callback in pairs(callbacks) do
        callback(msgdata, msgid);
    end
end

function Android:ExtendEnv(env)
    env.output = "";
    env.print = function(...)
        for i = 1, select('#', ...) do      -->获取参数总数
            local arg = select(i, ...);     -->函数会返回多个值
            env.output = env.output .. tostring(arg) .. "    ";
        end  
        env.output = env.output .. "\n";
    end
end

-- Android 特有的权限请求处理
function Android:HandlePermissionRequest(msgdata, msgid)
    local permission = msgdata.permission;
    local granted = msgdata.granted;
    
    if permission == "CAMERA" then
        self:EmitMsg("camera_permission", {granted = granted}, msgid);
    elseif permission == "RECORD_AUDIO" then
        self:EmitMsg("microphone_permission", {granted = granted}, msgid);
    elseif permission == "WRITE_EXTERNAL_STORAGE" then
        self:EmitMsg("storage_permission", {granted = granted}, msgid);
    elseif permission == "READ_EXTERNAL_STORAGE" then
        self:EmitMsg("read_storage_permission", {granted = granted}, msgid);
    end
    
    self:SendMsg("permission_response", {
        permission = permission,
        granted = granted
    }, msgid);
end

-- 文件访问处理
function Android:HandleFileAccess(msgdata, msgid)
    local action = msgdata.action;
    local path = msgdata.path;
    local result = msgdata.result;
    
    if action == "read" then
        self:EmitMsg("file_read_result", {path = path, result = result}, msgid);
    elseif action == "write" then
        self:EmitMsg("file_write_result", {path = path, result = result}, msgid);
    elseif action == "delete" then
        self:EmitMsg("file_delete_result", {path = path, result = result}, msgid);
    end
end

-- 相机访问处理
function Android:HandleCameraAccess(msgdata, msgid)
    local action = msgdata.action;
    local result = msgdata.result;
    
    if action == "capture" then
        self:EmitMsg("camera_capture_result", {result = result}, msgid);
    elseif action == "preview" then
        self:EmitMsg("camera_preview_result", {result = result}, msgid);
    end
end

-- 麦克风访问处理
function Android:HandleMicrophoneAccess(msgdata, msgid)
    local action = msgdata.action;
    local result = msgdata.result;
    
    if action == "record" then
        self:EmitMsg("microphone_record_result", {result = result}, msgid);
    elseif action == "stop" then
        self:EmitMsg("microphone_stop_result", {result = result}, msgid);
    end
end

-- 存储访问处理
function Android:HandleStorageAccess(msgdata, msgid)
    local action = msgdata.action;
    local result = msgdata.result;
    
    if action == "available_space" then
        self:EmitMsg("storage_space_result", {result = result}, msgid);
    elseif action == "external_storage" then
        self:EmitMsg("external_storage_result", {result = result}, msgid);
    end
end

-- 网络状态处理
function Android:HandleNetworkStatus(msgdata, msgid)
    local connected = msgdata.connected;
    local type = msgdata.type; -- wifi, mobile, none
    
    self:EmitMsg("network_status_changed", {
        connected = connected,
        type = type
    }, msgid);
end

-- 设备信息处理
function Android:HandleDeviceInfo(msgdata, msgid)
    local info = msgdata.info;
    
    self:EmitMsg("device_info_result", {info = info}, msgid);
end

-- 请求权限
function Android:RequestPermission(permission, callback)
    self:SendMsg("request_permission", {permission = permission}, nil, callback, "native");
end

-- 获取设备信息
function Android:GetDeviceInfo(callback)
    self:SendMsg("get_device_info", {}, nil, callback, "native");
end

-- 获取网络状态
function Android:GetNetworkStatus(callback)
    self:SendMsg("get_network_status", {}, nil, callback, "native");
end

-- 文件操作
function Android:ReadFile(path, callback)
    self:SendMsg("read_file", {path = path}, nil, callback, "native");
end

function Android:WriteFile(path, content, callback)
    self:SendMsg("write_file", {path = path, content = content}, nil, callback, "native");
end

function Android:DeleteFile(path, callback)
    self:SendMsg("delete_file", {path = path}, nil, callback, "native");
end

-- 相机操作
function Android:CapturePhoto(callback)
    self:SendMsg("capture_photo", {}, nil, callback, "native");
end

function Android:StartCameraPreview(callback)
    self:SendMsg("start_camera_preview", {}, nil, callback, "native");
end

function Android:StopCameraPreview(callback)
    self:SendMsg("stop_camera_preview", {}, nil, callback, "native");
end

-- 麦克风操作
function Android:StartRecording(callback)
    self:SendMsg("start_recording", {}, nil, callback, "native");
end

function Android:StopRecording(callback)
    self:SendMsg("stop_recording", {}, nil, callback, "native");
end

function Android:ExecuteJava2Lua(javacode, callback)
    self:SendMsg("Java2Lua", javacode, nil, function(result)
        if (type(callback) ~= "function") then return end
        callback(not result.error, result.luacode);
    end);
end

function Android:Execute(msgdata, msgid)
    local code = msgdata.code;
    local code_func, errormsg = loadstring(code, msgdata.filename or "android");
    local env = msgdata.env or {};

    setmetatable(env, {__index = _G});
    self:ExtendEnv(env);

    if(not code_func or errormsg) then
        LOG.std(nil, "error", "Android:Execute loadstring", errormsg);
        print(code)
        return;
    end

    setfenv(code_func, env);
    
    local success, result = pcall(code_func)
    
    self:SendMsg("execute_reply", {
        success = success,
        result = result,
        output = env.output,
    }, msgid);
end

Android:InitSingleton();
print("=================================Paracraft Android Loaded====================================");

local function activate(msg)
    local message = msg.msg;
    if type(message) == "string" and message ~= "" then
        local message_data = commonlib.Json.Decode(message);
        if message_data then msg = message_data end
	end
	Android:RecvMsg(msg);
end

NPL.this(function()
    msg = msg or {};
    activate(msg);
end, {filename="android"});

NPL.this(function()
    msg = msg or {};
    activate(msg);
end);