--[[
Title: Emscripten
Author(s): wxa
Date: 2023.6.12
Desc: lua 与 js 通信
------------------------------------------------------------
local Emscripten = NPL.load("(gl)script/apps/Aries/Creator/Game/Emscripten/Emscripten.lua");
Emscripten:SendMsg("xxx", {key = "value"}, nil, nil, "external");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
NPL.load("(gl)script/ide/System/os/os.lua");
NPL.load("(gl)script/ide/System/Encoding/base64.lua");
NPL.load("(gl)script/ide/Json.lua");

local Emscripten = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

function Emscripten:ctor()
    self.m_msg_callback = {};
    self.m_msgid_callback = {};
    self.m_msgid = 0;
    self.m_loaded = false;

    self.m_onload_timer = commonlib.Timer:new({callbackFunc = function()
        self:SendMsg("load");
    end});

    self.m_onload_timer:Change(200, 200);
end

function Emscripten:GetNextMsgId()
    self.m_msgid = self.m_msgid + 1;
    return self.m_msgid;
end

-- target = emscripten 发送给 webparacraft
-- target = webview 发送给 webparacraft 内嵌的iframe
-- target = external 发送给 webparacraft 外层的window(内嵌iframe webparacraft的页面) Emscripten:SendMsg("xxx", {key = "value"}, nil, nil, "external")
-- 接受 target = emscripten 消息 NPL.this(function() msg = msg or {}; print(msg) end, {filename="emscripten"});
-- 接受 target = webview 消息 NPL.this(function() msg = msg or {}; print(msg) end, {filename="webview"});  网页版专用
-- 接受 target = external 消息 NPL.this(function() msg = msg or {}; print(msg) end, {filename="external"});
function Emscripten:SendMsg(msgname, msgdata, msgid, callback, target)
    if (msgid == nil) then msgid = self:GetNextMsgId() end
    if (type(callback) == "function") then self.m_msgid_callback[msgid] = callback end

    ParaEngine.GetAttributeObject():SetField("SendMsgToJS", commonlib.Json.Encode({
        target = target or "emscripten",
        msgid = msgid,
        msgname = msgname,
        -- msgdata = Encoding.base64(commonlib.Json.Encode(msgdata)),
        msgdata = msgdata,
    }));
end

function Emscripten:RecvMsg(msg)
    if (type(msg) ~= "table" or type(msg.msgname) ~= "string") then return end
    local msgid = msg.msgid;
    local msgname = msg.msgname;
    local msgdata = msg.msgdata;

    local msgid_callback = self.m_msgid_callback[msgid or 0];
    if (msgid_callback) then msgid_callback(msgdata) end

	if (msgname == "echo") then
        echo(msg, true)
    elseif (msgname == "echo_and_reply") then
        Emscripten:SendMsg("echo", msgdata);
    elseif (msgname == "load") then
        if (not self.m_loaded) then 
            self.m_loaded = true;
            -- 加载JsCodeBlock
            local JsCodeBlock = NPL.load("(gl)script/apps/Aries/Creator/Game/Emscripten/JsCodeBlock.lua");
            if (not JsCodeBlock) then print("==============================JsCodeBlock Load Failed!!!=====================================") end
            -- 响应消息
            self:SendMsg("load");
        end
        -- 取消定时器
        if (self.m_onload_timer) then
            self.m_onload_timer:Change();
            self.m_onload_timer = nil;
            print("Emscripten Loaded!!! cancel timer");
        end
    elseif (msgname == "execute") then
        self:Execute(msgdata, msgid);
    else
        self:EmitMsg(msgname, msgdata, msgid);
    end
end

function Emscripten:GetMsgCallbacks(msgname)
    return self.m_msg_callback[msgname] or {};
end

function Emscripten:OnMsg(msgname, callback)
    self.m_msg_callback[msgname] = self.m_msg_callback[msgname] or {};
    self.m_msg_callback[msgname][callback] = callback;
end

function Emscripten:OffMsg(msgname, callback)
    self.m_msg_callback[msgname] = self.m_msg_callback[msgname] or {};
    if (not callback) then
        self.m_msg_callback[msgname] = {};
        return
    end
    self.m_msg_callback[msgname][callback] = nil;
end

function Emscripten:OffAllMsg()
    self.m_msg_callback = {};
end

function Emscripten:EmitMsg(msgname, msgdata, msgid)
    local callbacks = self:GetMsgCallbacks(msgname);
    for callback in pairs(callbacks) do
        callback(msgdata, msgid);
    end
end


function Emscripten:ExtendEnv(env)
    env.output = "";
    env.print = function(...)
        for i = 1, select('#', ...) do      -->获取参数总数
            local arg = select(i, ...);     -->函数会返回多个值
            env.output = env.output .. tostring(arg) .. "    ";
        end  
        env.output = env.output .. "\n";
    end
end

function Emscripten:ExecutePy2Lua(pycode, callback)
    -- if (true) then return callback(true, pycode) end
    self:SendMsg("Py2Lua", pycode, nil, function(result)
        if (type(callback) ~= "function") then return end
        callback(not result.error, result.luacode);
    end);
end

function Emscripten:Execute(msgdata, msgid)
    local code = msgdata.code;
    local code_func, errormsg = loadstring(code, msgdata.filename or "emscripten");
    local env = msgdata.env or {};

    setmetatable(env, {__index = _G});
    self:ExtendEnv(env);

    if(not code_func or errormsg) then
        LOG.std(nil, "error", "Emscripten:Execute loadstring", errormsg);
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

Emscripten:InitSingleton();
print("=================================Paracraft Emscripten Loaded====================================");

local function activate(msg)
    local message = msg.msg;
    if type(message) == "string" and message ~= "" then
        local message_data = commonlib.Json.Decode(message);
        if message_data then msg = message_data end
	end
	Emscripten:RecvMsg(msg);
end

NPL.this(function()
    msg = msg or {};
    activate(msg);
end, {filename="emscripten"});

NPL.this(function()
    msg = msg or {};
    activate(msg);
end);
