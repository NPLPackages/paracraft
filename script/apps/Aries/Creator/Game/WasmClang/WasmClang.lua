--[[
Title: WasmClang
Author(s): wxa
Date: 2023.5.31
Desc: compiling C/C++ using clang in wasm(llvm + clang)
------------------------------------------------------------
local WasmClang = NPL.load("(gl)script/apps/Aries/Creator/Game/WasmClang/WasmClang.lua");
function WasmClang:GetUrl()
    return "http://127.0.0.1:8088/npl/webparacraft/wasm-clang/index.local.html?platform=emscripten";
end

WasmClang:Start(function()
    -- compile and run c/c++ code after initializing wasm environment.
    WasmClang:CompileLinkRun([=[
        #include <stdio.h>
        int main() {
          printf("hello world");
          return 0;
        }
    ]=]);
end);
WasmClang:Connect("LogReceived", function(text)
    print(text);
end)
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/os/os.lua");
NPL.load("(gl)script/ide/System/Encoding/base64.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserPlugin.lua");
local Encoding = commonlib.gettable("System.Encoding");
local NplBrowserPlugin = commonlib.gettable("NplBrowser.NplBrowserPlugin");
local WasmClang = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

WasmClang:Signal("LogReceived");
-- _G.WasmClang = WasmClang;

function WasmClang:ctor()
    self.m_log_text = ""
    self.started = false;
    self.WasmClangStarted = false;
end

function WasmClang:GetUrl()
    if (self.m_url) then return self.m_url end
    local platform  = System.os.GetPlatform();
    platform = platform == "win32" and "windows" or platform;
    self.m_url = "https://webparacraft.keepwork.com/wasm-clang/index.html?platform=" .. platform;
    return self.m_url;
end

function WasmClang:GetID()
    return "WasmClang";
end

function WasmClang:GetFilename()
    return "WasmClang";
end

function WasmClang:ClearLog()
    self.m_log_text = "";
end

function WasmClang:IsWasmClangStarted()
    return self.WasmClangStarted;
end

function WasmClang:Start(callback)
    if (self.WasmClangStarted) then 
        if (callback) then callback() end
        return;
    end
    self.started = true;
    NplBrowserPlugin.Start({id = self:GetID(), url = self:GetUrl(), x = 0, y = 0, width = 0, height = 0});
    local timer = commonlib.Timer:new({callbackFunc = function(timer)
        if (self.WasmClangStarted) then 
            timer:Change();
            if (callback) then 
                callback() 
            end
        end
    end});
    timer:Change(200, 200);
end

function WasmClang:Stop()
end

function WasmClang:SendMsg(msg)
    NplBrowserPlugin.NPL_Activate(self:GetID(), self:GetFilename(), msg);
end

function WasmClang:CompileLinkRun(code, callback)
    self.m_compile_link_run_callback = callback;
    self:ClearLog();
    self:SendMsg({cmd = "CompileLinkRun", code = code});
end

function WasmClang:CompileLinkRunFinished()
    if (type(self.m_compile_link_run_callback) == "function") then
        self.m_compile_link_run_callback();
    end
end

function WasmClang:Log(text)
    self:LogReceived(text);

    self.m_log_text = (self.m_log_text or "") .. text;
end

function WasmClang:GetLogText()
    return self.m_log_text;
end

function WasmClang:Test()
    self:CompileLinkRun([[
        #include <stdio.h>
        int main() {
          printf("hello world");
          return 0;
        }
    ]]);
end

function WasmClang:OnMessage(msg)
	if (msg.cmd == "log") then
        self:Log(msg.text);
    elseif (msg.cmd == "WasmClangStarted") then
        self.WasmClangStarted = true;
        self:SendMsg({cmd = "WasmClangStarted"});
    elseif (msg.cmd == "CompileLinkRunFinished") then
        self:CompileLinkRunFinished();
	elseif (msg.cmd == "echo") then
        echo(msg, true)
    elseif (msg.cmd == "echo_and_reply") then
        echo(msg, true)
        msg.cmd = "echo";
        self:SendMsg(msg);
    end
end

WasmClang:InitSingleton();

NPL.this(function()
	local msg = NplBrowserPlugin.TranslateJsMessage(msg)
    WasmClang:OnMessage(msg);
end, {filename="WasmClang"});
