
--[[
Title: JsCodeBlock
Author(s): wxa
Date: 2023.6.12
Desc: Js CodeBlock 接口函数
------------------------------------------------------------
local JsCodeBlock = NPL.load("(gl)script/apps/Aries/Creator/Game/Emscripten/JsCodeBlock.lua");
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.ai.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/TextToWorld/TextToWorld.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/TextToWorld/TextCodeBlock.lua");
local TextCodeBlock = commonlib.gettable("MyCompany.Aries.Game.Code.TextToWorld.TextCodeBlock")
local TextToWorld = commonlib.gettable("MyCompany.Aries.Game.Code.TextToWorld.TextToWorld");
local Emscripten = NPL.load("(gl)script/apps/Aries/Creator/Game/Emscripten/Emscripten.lua");

local JsCodeBlock = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

function JsCodeBlock:ctor()
    self.m_text_world = TextToWorld:new();
    self.m_index_callback_map = {};
    self.m_loading = false;
    self.m_loaded = false;
    self.m_world_name = "";
    self.m_text_world:Connect("codeblockFinished", function(codeblock, textOutput)
        self:ExecuteCodeBlockCodeCallback(codeblock, textOutput);
    end);
end

function JsCodeBlock:LoadTextWorld(option, callback)
    local world_name = option.worldName or "CodeLabTextWorld";
    local pid = option.pid or 0;
    local reload = option.reload or (self.m_world_name ~= world_name);
    if (self.m_loading) then return callback({state = "loading"}) end
    if (self.m_loaded and not reload) then return callback({state = "loaded"}) end
    
    self.m_loading = true;
    self.m_loaded = false;
    self.m_world_name = world_name;
    self.m_text_world.prepareWorldName = self.m_world_name;
    self.m_text_world:ResetWorld(function()
        self.m_loading = false;
        self.m_loaded = true;
        callback({state = "loaded"});
    end, pid ~= 0 and pid or nil);
end

function JsCodeBlock:GetCodeBlockText(option)
    local code = option.code or "";
    local language = option.language or "codeblock";
    local title = option.title;
    local actor = option.actor and "true" or "false";
    local pid = option.pid or 0;
    local name = option.name;
    local text = code;

    language = language == "codeblock" and "npl" or language;
    text = "-- actor: " .. actor .. "\n" .. text;
    if (pid ~= 0) then text = "-- projectId: " .. pid .. "\n" .. text end
    if (name and name ~= "") then text = "-- name: " .. name .. "\n" .. text end
    if (title) then text = "-- title: " .. title .. "\n" .. text end
    if (language) then text = "-- language: " .. language .. "\n" .. text end

    return text;
end

function JsCodeBlock:ExecuteCodeBlockCode(option, callback)
    local index = option.index or 1;
    local language = option.language or "codeblock";

    if (language == "clang") then
        self:ExecuteClangCode(option.code or "", callback);
    elseif (language == "AI") then
        self:ExecuteAICode(option.messages or {}, option.modelName or "", callback);
    else
        local text = self:GetCodeBlockText(option);
        self.m_index_callback_map[index] = callback;
        self.m_text_world:RunString(text, index);
    end
end

function JsCodeBlock:ExecuteAICode(messages, modelName, callback)
    keepwork.ai.chat(
        {
            messages = messages,
            model = modelName
        },
        function(err, msg, data)
            if (not data or not data.result) then
                LOG.std(nil, "info", "JsCodeBlock:ExecuteAICode", data);
                return;
            end

            if (callback and type(callback) == "function") then
                callback(data);
            end
        end
    );
end

function JsCodeBlock:ExecuteClangCode(code, callback)
    local WasmClang = NPL.load("(gl)script/apps/Aries/Creator/Game/WasmClang/WasmClang.lua");
    WasmClang:Start(function()
        WasmClang:CompileLinkRun(code, function()
            if (type(callback) == "function") then
                callback({output = WasmClang:GetLogText()});
            end
        end)
    end)
end

function JsCodeBlock:ExecuteCodeBlockCodeCallback(codeblock, textOutput)
    local index = codeblock:GetIndex();
    local callback = self.m_index_callback_map[index];

    if (codeblock:GetLanguage() == "commands") then
        textOutput = "done";
    end
    
    if (callback) then callback({output = textOutput}) end
    self.m_index_callback_map[index] = nil;
end

function JsCodeBlock:GoToCodeBlock(option)
    local text = self:GetCodeBlockText(option);
    local index = option.index or 1;

    local block = TextCodeBlock:new():Init(self, index);
    block:SetType("codeblock"); -- assume it is codeblock
    block:SetParentTitle(nil);

    for line in text:gmatch("[^\r\n]+") do
        block:AddLine(line)
    end

    block:CreateSceneBlocks();
    block:GotoThisBlock();
end

function JsCodeBlock:LoadGoogleBlocklyConfig(option, callback)
    local text = self:GetCodeBlockText(option);
    local index = option.index or 1;
    local google_blockly_workspace = option.google_blockly_workspace;

    local block = TextCodeBlock:new():Init(self, index);
    block:SetType("codeblock"); 
    block:SetParentTitle(nil);

    for line in text:gmatch("[^\r\n]+") do
        block:AddLine(line)
    end

    local GoogleNplBlockly = NPL.load("script/ide/System/UI/Blockly/GoogleNplBlockly.lua");
    local code_entity = block:CreateSceneBlocks();
    local google_blockly = GoogleNplBlockly:LoadEntityGoogleBlockly(code_entity, google_blockly_workspace);
    if (type(callback) == "function") then
        callback(google_blockly);
    end
end

JsCodeBlock:InitSingleton();

Emscripten:OnMsg("LoadTextWorld", function(msgdata, msgid)
    msgdata = type(msgdata) ~= "table" and {} or msgdata;
    JsCodeBlock:LoadTextWorld(msgdata, function(reply_data)
        Emscripten:SendMsg("LoadTextWorldReply", reply_data, msgid);
    end);
end);

Emscripten:OnMsg("ExecuteCodeBlockCode", function(msgdata, msgid)
    msgdata = type(msgdata) ~= "table" and {} or msgdata;
    JsCodeBlock:ExecuteCodeBlockCode(msgdata, function(reply_data)
        LOG.std(nil, "info", "JsCodeBlock" ,"ExecuteCodeBlockCodeReply reply_data is %s", tostring(reply_data));
        Emscripten:SendMsg("ExecuteCodeBlockCodeReply", reply_data, msgid);
    end);
end);

Emscripten:OnMsg("GoToCodeBlock", function(msgdata, msgid)
    msgdata = type(msgdata) ~= "table" and {} or msgdata;
    JsCodeBlock:GoToCodeBlock(msgdata);
end);

Emscripten:OnMsg("LoadGoogleBlocklyConfig", function(msgdata, msgid)
    msgdata = type(msgdata) ~= "table" and {} or msgdata;
    JsCodeBlock:LoadGoogleBlocklyConfig(msgdata, function(reply_data)
        Emscripten:SendMsg("LoadNplToGoogleBlocklyConfigReply", reply_data, msgid);
    end);
end);

print("==============================JsCodeBlock Loaded====================================");

