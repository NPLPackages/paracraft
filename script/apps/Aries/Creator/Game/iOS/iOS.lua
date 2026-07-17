--[[
Title: iOS
Author(s): big
Date: 2025.8.19
Desc: Paracraft iOS平台通信模块，用于Lua与JavaScript的双向通信
------------------------------------------------------------
local iOS = NPL.load("(gl)script/apps/Aries/Creator/Game/iOS/iOS.lua");
iOS:SendMsg("xxx", {key = "value"}, nil, nil, "native");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
NPL.load("(gl)script/ide/System/os/os.lua");
NPL.load("(gl)script/ide/System/Encoding/base64.lua");
NPL.load("(gl)script/ide/Json.lua");

local iOS = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

function iOS:ctor()
    self.m_msg_callback = {};
    self.m_msgid_callback = {};
    self.m_msgid = 0;
    self.m_loaded = false;

    self.m_onload_timer = commonlib.Timer:new({callbackFunc = function()
        self:SendMsg("load");
    end});

    self.m_onload_timer:Change(200, 200);
end

function iOS:GetNextMsgId()
    self.m_msgid = self.m_msgid + 1;
    return self.m_msgid;
end

function iOS:SendMsgToObjectiveC(msgname, msgdata, msgid, callback)
    if (msgid == nil) then msgid = self:GetNextMsgId() end
    if (type(callback) == "function") then self.m_msgid_callback[msgid] = callback end

    ParaEngine.GetAttributeObject():SetField("SendMsgToObjectiveC", commonlib.Json.Encode({
        target = target or "ios",
        msgid = msgid,
        msgname = msgname,
        msgdata = msgdata,
    }));
end

-- target = native 发送给 iOS webview 中的 js
-- target = webview 发送给 iOS webview
-- target = external 发送给外部应用
-- 接受 target = native 消息 NPL.this(function() msg = msg or {}; print(msg) end, {filename="ios"});
-- 接受 target = webview 消息 NPL.this(function() msg = msg or {}; print(msg) end, {filename="webview"});
-- 接受 target = external 消息 NPL.this(function() msg = msg or {}; print(msg) end, {filename="external"});
function iOS:SendMsg(msgname, msgdata, msgid, callback, target)
    if (msgid == nil) then msgid = self:GetNextMsgId() end
    if (type(callback) == "function") then self.m_msgid_callback[msgid] = callback end

    -- 使用 ParaEngine 的 iOS 特定属性来发送消息到 JavaScript
    ParaEngine.GetAttributeObject():SetField("SendMsgToJS", commonlib.Json.Encode({
        target = target or "ios",
        msgid = msgid,
        msgname = msgname,
        msgdata = msgdata,
    }));
end

function iOS:RecvMsg(msg)
    if (type(msg) ~= "table" or type(msg.msgname) ~= "string") then return end
    local msgid = msg.msgid;
    local msgname = msg.msgname;
    local msgdata = msg.msgdata;

    local msgid_callback = self.m_msgid_callback[msgid or 0];
    if (msgid_callback) then msgid_callback(msgdata) end

	if (msgname == "echo") then
        echo(msg, true)
    elseif (msgname == "echo_and_reply") then
        iOS:SendMsg("echo", msgdata);
    elseif (msgname == "load") then
        if (not self.m_loaded) then 
            self.m_loaded = true;
            -- 加载iOSCodeBlock
            local iOSCodeBlock = NPL.load("(gl)script/apps/Aries/Creator/Game/iOS/iOSCodeBlock.lua");
            if (not iOSCodeBlock) then print("==============================iOSCodeBlock Load Failed!!!=====================================") end
            -- 响应消息
            self:SendMsg("load");
        end
        -- 取消定时器
        if (self.m_onload_timer) then
            self.m_onload_timer:Change();
            self.m_onload_timer = nil;
            print("iOS Loaded!!! cancel timer");
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
    elseif (msgname == "app_lifecycle") then
        self:HandleAppLifecycle(msgdata, msgid);
    elseif (msgname == "push_notification") then
        self:HandlePushNotification(msgdata, msgid);
    elseif (msgname == "touch_id_face_id") then
        self:HandleBiometricAuth(msgdata, msgid);
    else
        self:EmitMsg(msgname, msgdata, msgid);
    end
end

function iOS:GetMsgCallbacks(msgname)
    return self.m_msg_callback[msgname] or {};
end

function iOS:OnMsg(msgname, callback)
    self.m_msg_callback[msgname] = self.m_msg_callback[msgname] or {};
    self.m_msg_callback[msgname][callback] = callback;
end

function iOS:OffMsg(msgname, callback)
    self.m_msg_callback[msgname] = self.m_msg_callback[msgname] or {};
    if (not callback) then
        self.m_msg_callback[msgname] = {};
        return
    end
    self.m_msg_callback[msgname][callback] = nil;
end

function iOS:OffAllMsg()
    self.m_msg_callback = {};
end

function iOS:EmitMsg(msgname, msgdata, msgid)
    local callbacks = self:GetMsgCallbacks(msgname);
    for callback in pairs(callbacks) do
        callback(msgdata, msgid);
    end
end

function iOS:ExtendEnv(env)
    env.output = "";
    env.print = function(...)
        for i = 1, select('#', ...) do      -->获取参数总数
            local arg = select(i, ...);     -->函数会返回多个值
            env.output = env.output .. tostring(arg) .. "    ";
        end  
        env.output = env.output .. "\n";
    end
end

-- iOS 特有的权限请求处理
function iOS:HandlePermissionRequest(msgdata, msgid)
    local permission = msgdata.permission;
    local granted = msgdata.granted;
    
    if permission == "NSCameraUsageDescription" then
        self:EmitMsg("camera_permission", {granted = granted}, msgid);
    elseif permission == "NSMicrophoneUsageDescription" then
        self:EmitMsg("microphone_permission", {granted = granted}, msgid);
    elseif permission == "NSPhotoLibraryUsageDescription" then
        self:EmitMsg("photo_library_permission", {granted = granted}, msgid);
    elseif permission == "NSLocationWhenInUseUsageDescription" then
        self:EmitMsg("location_permission", {granted = granted}, msgid);
    elseif permission == "NSLocationAlwaysAndWhenInUseUsageDescription" then
        self:EmitMsg("location_always_permission", {granted = granted}, msgid);
    elseif permission == "NSContactsUsageDescription" then
        self:EmitMsg("contacts_permission", {granted = granted}, msgid);
    elseif permission == "NSCalendarsUsageDescription" then
        self:EmitMsg("calendar_permission", {granted = granted}, msgid);
    end
    
    self:SendMsg("permission_response", {
        permission = permission,
        granted = granted
    }, msgid);
end

-- 文件访问处理
function iOS:HandleFileAccess(msgdata, msgid)
    local action = msgdata.action;
    local path = msgdata.path;
    local result = msgdata.result;
    
    if action == "read" then
        self:EmitMsg("file_read_result", {path = path, result = result}, msgid);
    elseif action == "write" then
        self:EmitMsg("file_write_result", {path = path, result = result}, msgid);
    elseif action == "delete" then
        self:EmitMsg("file_delete_result", {path = path, result = result}, msgid);
    elseif action == "document_picker" then
        self:EmitMsg("document_picker_result", {result = result}, msgid);
    end
end

-- 相机访问处理
function iOS:HandleCameraAccess(msgdata, msgid)
    local action = msgdata.action;
    local result = msgdata.result;
    
    if action == "capture" then
        self:EmitMsg("camera_capture_result", {result = result}, msgid);
    elseif action == "preview" then
        self:EmitMsg("camera_preview_result", {result = result}, msgid);
    elseif action == "image_picker" then
        self:EmitMsg("image_picker_result", {result = result}, msgid);
    end
end

-- 麦克风访问处理
function iOS:HandleMicrophoneAccess(msgdata, msgid)
    local action = msgdata.action;
    local result = msgdata.result;
    
    if action == "record" then
        self:EmitMsg("microphone_record_result", {result = result}, msgid);
    elseif action == "stop" then
        self:EmitMsg("microphone_stop_result", {result = result}, msgid);
    elseif action == "speech_recognition" then
        self:EmitMsg("speech_recognition_result", {result = result}, msgid);
    end
end

-- 存储访问处理
function iOS:HandleStorageAccess(msgdata, msgid)
    local action = msgdata.action;
    local result = msgdata.result;
    
    if action == "available_space" then
        self:EmitMsg("storage_space_result", {result = result}, msgid);
    elseif action == "icloud_storage" then
        self:EmitMsg("icloud_storage_result", {result = result}, msgid);
    elseif action == "documents_directory" then
        self:EmitMsg("documents_directory_result", {result = result}, msgid);
    end
end

-- 网络状态处理
function iOS:HandleNetworkStatus(msgdata, msgid)
    local connected = msgdata.connected;
    local type = msgdata.type; -- wifi, cellular, none
    local reachability = msgdata.reachability; -- iOS 特有的网络可达性
    
    self:EmitMsg("network_status_changed", {
        connected = connected,
        type = type,
        reachability = reachability
    }, msgid);
end

-- 设备信息处理
function iOS:HandleDeviceInfo(msgdata, msgid)
    local info = msgdata.info;
    
    self:EmitMsg("device_info_result", {info = info}, msgid);
end

-- App 生命周期处理 (iOS 特有)
function iOS:HandleAppLifecycle(msgdata, msgid)
    local state = msgdata.state; -- active, inactive, background, foreground
    
    self:EmitMsg("app_lifecycle_changed", {state = state}, msgid);
end

-- 推送通知处理 (iOS 特有)
function iOS:HandlePushNotification(msgdata, msgid)
    local action = msgdata.action;
    local result = msgdata.result;
    
    if action == "register" then
        self:EmitMsg("push_notification_registered", {result = result}, msgid);
    elseif action == "receive" then
        self:EmitMsg("push_notification_received", {result = result}, msgid);
    end
end

-- 生物识别认证处理 (iOS 特有)
function iOS:HandleBiometricAuth(msgdata, msgid)
    local action = msgdata.action;
    local result = msgdata.result;
    local type = msgdata.type; -- touchid, faceid
    
    if action == "authenticate" then
        self:EmitMsg("biometric_auth_result", {
            result = result,
            type = type
        }, msgid);
    elseif action == "available" then
        self:EmitMsg("biometric_available_result", {
            result = result,
            type = type
        }, msgid);
    end
end

-- 请求权限
function iOS:RequestPermission(permission, callback)
    self:SendMsg("request_permission", {permission = permission}, nil, callback, "native");
end

-- 获取设备信息
function iOS:GetDeviceInfo(callback)
    self:SendMsg("get_device_info", {}, nil, callback, "native");
end

-- 获取网络状态
function iOS:GetNetworkStatus(callback)
    self:SendMsg("get_network_status", {}, nil, callback, "native");
end

-- 文件操作
function iOS:ReadFile(path, callback)
    self:SendMsg("read_file", {path = path}, nil, callback, "native");
end

function iOS:WriteFile(path, content, callback)
    self:SendMsg("write_file", {path = path, content = content}, nil, callback, "native");
end

function iOS:DeleteFile(path, callback)
    self:SendMsg("delete_file", {path = path}, nil, callback, "native");
end

-- 文档选择器 (iOS 特有)
function iOS:ShowDocumentPicker(callback)
    self:SendMsg("show_document_picker", {}, nil, callback, "native");
end

-- 相机操作
function iOS:CapturePhoto(callback)
    self:SendMsg("capture_photo", {}, nil, callback, "native");
end

function iOS:StartCameraPreview(callback)
    self:SendMsg("start_camera_preview", {}, nil, callback, "native");
end

function iOS:StopCameraPreview(callback)
    self:SendMsg("stop_camera_preview", {}, nil, callback, "native");
end

-- 图片选择器 (iOS 特有)
function iOS:ShowImagePicker(callback)
    self:SendMsg("show_image_picker", {}, nil, callback, "native");
end

-- 麦克风操作
function iOS:StartRecording(callback)
    self:SendMsg("start_recording", {}, nil, callback, "native");
end

function iOS:StopRecording(callback)
    self:SendMsg("stop_recording", {}, nil, callback, "native");
end

-- 语音识别 (iOS 特有)
function iOS:StartSpeechRecognition(callback)
    self:SendMsg("start_speech_recognition", {}, nil, callback, "native");
end

function iOS:StopSpeechRecognition(callback)
    self:SendMsg("stop_speech_recognition", {}, nil, callback, "native");
end

-- 生物识别认证 (iOS 特有)
function iOS:AuthenticateWithBiometrics(reason, callback)
    self:SendMsg("authenticate_biometrics", {reason = reason}, nil, callback, "native");
end

function iOS:CheckBiometricAvailability(callback)
    self:SendMsg("check_biometric_availability", {}, nil, callback, "native");
end

-- 推送通知 (iOS 特有)
function iOS:RegisterForPushNotifications(callback)
    self:SendMsg("register_push_notifications", {}, nil, callback, "native");
end

-- App Store 评分 (iOS 特有)
function iOS:RequestAppStoreReview(callback)
    self:SendMsg("request_app_store_review", {}, nil, callback, "native");
end

-- 分享内容 (iOS 特有)
function iOS:ShareContent(content, callback)
    self:SendMsg("share_content", {content = content}, nil, callback, "native");
end

-- 震动反馈 (iOS 特有)
function iOS:TriggerHapticFeedback(type, callback)
    -- type: light, medium, heavy, selection, impact, notification
    self:SendMsg("trigger_haptic_feedback", {type = type}, nil, callback, "native");
end

-- 获取 App 版本信息
function iOS:GetAppVersion(callback)
    self:SendMsg("get_app_version", {}, nil, callback, "native");
end

-- 获取电池信息
function iOS:GetBatteryInfo(callback)
    self:SendMsg("get_battery_info", {}, nil, callback, "native");
end

-- 设置状态栏样式
function iOS:SetStatusBarStyle(style, callback)
    -- style: default, lightContent, darkContent
    self:SendMsg("set_status_bar_style", {style = style}, nil, callback, "native");
end

function iOS:ExecuteObjectiveC2Lua(objccode, callback)
    self:SendMsg("ObjectiveC2Lua", objccode, nil, function(result)
        if (type(callback) ~= "function") then return end
        callback(not result.error, result.luacode);
    end);
end

function iOS:Execute(msgdata, msgid)
    local code = msgdata.code;
    local code_func, errormsg = loadstring(code, msgdata.filename or "ios");
    local env = msgdata.env or {};

    setmetatable(env, {__index = _G});
    self:ExtendEnv(env);

    if(not code_func or errormsg) then
        LOG.std(nil, "error", "iOS:Execute loadstring", errormsg);
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

iOS:InitSingleton();
print("=================================Paracraft iOS Loaded====================================");

local function activate(msg)
    local message = msg.msg;
    if type(message) == "string" and message ~= "" then
        local message_data = commonlib.Json.Decode(message);
        if message_data then msg = message_data end
	end
	iOS:RecvMsg(msg);
end

NPL.this(function()
    msg = msg or {};
    activate(msg);
end, {filename="ios"});

NPL.this(function()
    msg = msg or {};
    activate(msg);
end);