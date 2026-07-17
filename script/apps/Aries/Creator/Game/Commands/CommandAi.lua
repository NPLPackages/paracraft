--[[
Title: Command Ai
Author(s): big, pbb, huangweiqiang
CreateDate: 2023.7.7
ModifyDate: 2025.3.6
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandAi.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.ai.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/AIChat.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/EasyAIChatTools.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local AIChat = commonlib.gettable("MyCompany.Aries.Game.Common.AIChat");
local EasyAIChatTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.EasyAIChatTools");

local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

local modelName = "keepwork-pro";
-- Module-level AIChat session for session continuity (+ prefix)
local aiChatSession = nil;

Commands["ask"] = {
    name="ask", 
    quick_ref="/ask [-model modelname] [-event eventName] [-knowledge knowledgeCodes] [-knowledgeUsername username] [-images imageUrls] [+] 这里输入问题", 
    desc=[[大模型默认为keepwork pro。 免费用户每天10次，会员用户几乎不限制。 
/ask -model ERNIE-4.0-8K -event AIResult 你叫什么名字？
/ask 你叫什么名字？ 启动一个新的session, 并提问
/ask {{role = "user",content="你的名字是alice"},{role = "assistant",content="好的"},{role = "user",content="你叫什么名字?"}}
/ask + 你的名字是papa 如果加号开始，表示继续前面的session. 继续提问。 
/ask -event AIResult 你叫什么名字？-- If event callback returns "abort" it will stop generating text
/ask -knowledge user/knowledge1,user/knowledge2 你叫什么名字？ --注意：多知识库使用英文,分隔
/ask -knowledgeUsername user
/ask -images image1,image2 这图片是什么？
/ask -needTool true 你叫什么名字？
]], 
    handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
        local option_name = "";
        local value;
        local options = {};
		while (option_name and cmd_text) do
			option_name, cmd_text = CmdParser.ParseOption(cmd_text);
			if(option_name == "model") then
				value, cmd_text = CmdParser.ParseString(cmd_text);
                options[option_name] = value;
            elseif(option_name == "event") then
                value, cmd_text = CmdParser.ParseString(cmd_text)
                options[option_name] = value;
            elseif(option_name == "knowledge") then
                value, cmd_text = CmdParser.ParseString(cmd_text)
                options[option_name] = value;
            elseif(option_name == "knowledgeUsername") then
                value, cmd_text = CmdParser.ParseString(cmd_text)
                options[option_name] = value;
            elseif(option_name == "images") then
                value, cmd_text = CmdParser.ParseString(cmd_text)
                options[option_name] = value;
            elseif(option_name == "needTool") then
                value, cmd_text = CmdParser.ParseString(cmd_text)
                options[option_name] = value == "true" or value == "1" or value == "True" or value == "TRUE";
            elseif(option_name == "noHistory") then
                value, cmd_text = CmdParser.ParseString(cmd_text)
                options[option_name] = value == "true" or value == "1" or value == "True" or value == "TRUE";
            elseif(option_name) then
                options[option_name] = true
            end
        end
        
        local word
        word, cmd_text = CmdParser.ParseFormated(cmd_text, "%+%s+");

        local isNewSession = true;
        if (word) then
            isNewSession = false;
        end

        word = cmd_text

        -- Create or reuse AIChat session
        local inputMessages;
        if (isNewSession) then
            if(cmd_text and cmd_text:match("^{.*}$")) then
                inputMessages = commonlib.LoadTableFromString(cmd_text)
            end
            -- Create new AIChat instance for new session
            aiChatSession = AIChat:new();
            aiChatSession:SetModel(options.model or modelName);
            aiChatSession:SetStream(true);
            aiChatSession:SetAutoHistory(not options.noHistory);
            
            -- Set knowledge base if specified
            if options.knowledge then
                aiChatSession:SetKnowledgeBase(options.knowledge);
            end
            if options.knowledgeUsername then
                aiChatSession:SetKnowledgeUsername(options.knowledgeUsername);
            end
            
            -- Register tools if needTool is enabled
            if options.needTool then
                EasyAIChatTools.RegisterMQTTTools(aiChatSession);
                EasyAIChatTools.RegisterPersonalPageTools(aiChatSession);
                -- TODO: Support custom tool registration via -tools option
                -- e.g., /ask -tools mqtt,personal_page,scheduler
            end
            
            -- If inputMessages provided, set history directly
            if inputMessages then
                aiChatSession:SetHistory(inputMessages);
                word = nil; -- Don't add additional user message
            end
        else
            -- Continue previous session
            if not aiChatSession then
                -- Fallback: create new session if no previous session exists
                aiChatSession = AIChat:new();
                aiChatSession:SetModel(options.model or modelName);
                aiChatSession:SetStream(true);
                aiChatSession:SetAutoHistory(not options.noHistory);
            end
            -- Update options for continued session
            if options.knowledge then
                aiChatSession:SetKnowledgeBase(options.knowledge);
            end
            if options.knowledgeUsername then
                aiChatSession:SetKnowledgeUsername(options.knowledgeUsername);
            end
            if options.needTool then
                EasyAIChatTools.RegisterMQTTTools(aiChatSession);
                EasyAIChatTools.RegisterPersonalPageTools(aiChatSession);
            end
        end

        local callbackFunc = {callback = false};
        
        -- AIChat callback adapter: converts AIChat callback signature to code block expected format
        -- AIChat: function(resultCode, delta, deltaThink, fullResult, fullThink)
        -- Code block expects: callbackFunc.callback(result, bSucceed)
        local function aiChatCallback(resultCode, delta, deltaThink, fullResult, fullThink)
            -- Streaming phase: resultCode is nil, delta/deltaThink contain new chunks
            if not resultCode then
                -- Fire event during streaming if -event option is specified
                if options.event and (delta or deltaThink) then
                    local streamResult = fullResult or "";
                    if fullThink and fullThink ~= "" and not streamResult:find("<think>") then
                        streamResult = string.format("<think>%s</think>", fullThink) .. streamResult;
                    end
                    local res = GameLogic.RunCommand(format("/sendevent %s %s", options.event, streamResult));
                    if res == "abort" then
                        aiChatSession:Abort();
                    end
                end
                return;
            end
            
            -- Completion phase: resultCode contains HTTP status
            local result = fullResult or "";
            local think = fullThink or "";
            local bSucceed = (resultCode == 200);
            
            -- Handle error cases
            if not bSucceed then
                if resultCode == 429 then
                    result = L"今天的免费对话次数用完了";
                elseif result == "" then
                    print("keepwork.ai.chat api return", resultCode);
                    result = L"哎呀,开小差了！";
                end
            end
            
            LOG.std(nil, "info", "CommandAsk.Complete", result);
            
            -- Call code block callback with adapted signature
            if callbackFunc.callback then
                local finalResult = result;
                if think and think ~= "" and not finalResult:find("<think>") then
                    finalResult = string.format("<think>%s</think>", think) .. finalResult;
                end
                callbackFunc.callback(finalResult, bSucceed);
                callbackFunc.callback = nil;
            end
            
            -- Fire final event if -event option is specified
            if options.event and result then
                local eventResult = result;
                if think and think ~= "" and not eventResult:find("<think>") then
                    eventResult = string.format("<think>%s</think>", think) .. eventResult;
                end
                local res = GameLogic.RunCommand(format("/sendevent %s %s", options.event, eventResult));
                if res == "abort" then
                    aiChatSession:Abort();
                end
            end
        end
        
        -- Call AIChat:Ask with the user input
        local askOptions = {};
        if options.images then
            askOptions.images = options.images;
        end
        
        aiChatSession:Ask(word, aiChatCallback, askOptions);
        
        return callbackFunc;
    end
};

Commands["capture"] = {
    name="capture", 
    quick_ref="/capture [none|hide|image|video|videoimage|webpage|sound|text|objectdetection|pose|handpose] [-width 400] [-height 300] [-url url] [-x 0 -y -0] [-duration 5] [-file temp/capture.png] [-event eventName]", 
    desc=[[capture image with computer's camera. we will use webview to capture the image.
ESC key to close the camera window, click the camera window to take image. 
@return file|filename: if start with "temp/" we will save to temp folder, otherwise we will save to world folder.
@return callback function(filename, bSucceed). 
/capture image -width 400 -height 300 -file temp/camera.jpg
/capture sound -file temp/capture.wav
-- Chinese audio to text for 5 seconds at most
/capture text -duration 5
-- immediately stop and save to file even duration time is not reached. 
/capture text stop
-- English audio to text
/capture text -language en -duration 3
-- capture audio to text in silent mode
/capture text -silent -language en -duration 3
/capture text -language en
/capture objectdetection start -event OnObjectDetect
/capture pose start -event OnPose
-- model [PoseNet|MoveNet|BlazePose] -runtime [mediapipe|tfjs] -maxPoses [number] -interval [number]
/capture pose start -model BlazePose -maxPoses 1 -event OnPose
/capture handpose start -event OnHandPose
-- play mp4 video, and capture via vidioimage sub-command later
/capture webpage -url https://url.mp4
-- when user clicked, an event is fired with msg:{filename}
/capture video -event OnVideoCaptured
-- capture current video image during pose, video, handpose, objectdetection, etc. 
/capture videoimage -format jpeg -filename test.jpg
/capture videoimage -format png -filename test.png
-- event msg is {width, height, data={r,g,b,a,...}}
/capture videoimage -format raw -event OnImageCaptured
/capture videoimage -format rgbstring -event OnImageCaptured
-- close camera capture window
/capture video stop
/capture none
/capture hide
]], 
    handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
        local subCmd, action;
        subCmd, cmd_text = CmdParser.ParseWord(cmd_text);
        subCmd = subCmd or "image"
        action, cmd_text = CmdParser.ParseWord(cmd_text);
        action = action or "start"

        local option_name = "";
        local value;
        local options = {};
		while (option_name and cmd_text) do
			option_name, cmd_text = CmdParser.ParseOption(cmd_text);
			if(option_name == "x" or option_name == "y" or option_name == "width" or option_name == "height" or option_name == "duration" or option_name == "scale" or option_name == "scale_x" or option_name == "scale_y") then
				value, cmd_text = CmdParser.ParseInt(cmd_text);
                options[option_name] = value;
			elseif(option_name == "file" or option_name == "filename") then
				value, cmd_text = CmdParser.ParseFilename(cmd_text);
                if(value) then
                    if(not value:match("^temp/") and not commonlib.Files.IsAbsolutePath(value)) then
                        value = GameLogic.GetWorldDirectory() .. value;
                    end
                    local fileExt = commonlib.Files.GetFileExtension(value)
                    if(not fileExt) then
                        if(subCmd == "image") then
                            value = value..".jpg"
                        else
                            value = value..".wav"
                        end
                    end
                    options[option_name] = value;
                end
            elseif(option_name == "language" or option_name == "event" or option_name == "model" or option_name == "maxPoses" or option_name == "interval" or option_name == "runtime" or option_name == "format") then
                value, cmd_text = CmdParser.ParseWord(cmd_text);
                options[option_name] = value;
            elseif (option_name == "camera_id" or option_name == "device_id") then
                value, cmd_text = CmdParser.ParseString(cmd_text);
                options[option_name] = value;
            elseif(option_name == "debug" or option_name == "offline" or option_name == "isolated" or option_name == "s" or option_name == "silent") then
                options[option_name] = true;
            elseif(option_name == "video_url" or option_name == "url" or option_name == "camera_url") then
                value, cmd_text = CmdParser.ParseUrl(cmd_text);
                options[option_name] = value;
            end
        end

        local callbackFunc = {callback = false};
        if(subCmd == "video" or subCmd == "image") then
            if (ParaEngine.GetAppCommandLineByParam("isAppleStore", nil)) then
                _guihelper.MessageBox(L"Mac App Store 版本的 Paracraft 暂不支持摄像头功能。");
                return;
            end

            local NPLJS = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NPLJS.lua");
            if(action == "stop") then
                if(options.event) then
                    local event = System.Core.Event:new():init(options.event)
                      GameLogic:event(event)
                end
                NPLJS:CloseCamera();
                return
            else
                if(subCmd == "image") then
                    GameLogic.AddBBS("capture", L"请打开摄像头，点击视频拍照，ESC键取消", 15000, "0 255 0");
                     -- push Esc state
	                System.PushState({name = "GetCameraImage", OnEscKey = function()
                        NPLJS:CloseCamera();
                    end});
                else
                    GameLogic.AddBBS("capture", L"请打开摄像头", 5000, "0 255 0");
                end
                NPLJS:GetCameraVideoImages({callback = function(bSucceed, filename) 
                    GameLogic.AddBBS("capture", nil);
                    LOG.std(nil, "info", "CommandCapture", "captured to %s: %s",  filename, tostring(bSucceed));
                    local filename = Files.GetRelativePath(filename)
                    if(options.event) then
                        local event = System.Core.Event:new():init(options.event)
  				        event.msg = {filename = filename, bSucceed = bSucceed};
  				        GameLogic:event(event)
                    end
                    if(subCmd == "image") then
                        NPLJS:CloseCamera();

                        if(callbackFunc.callback) then
                            filename = Files.GetRelativePath(filename)
                            callbackFunc.callback(filename, bSucceed);
                            callbackFunc.callback = nil;
                        end
                    end
                end, x = options.x, y = options.y, width = options.width, height = options.height, 
                filepath = options.file or options.filename, debug = options.debug, url = options.url, 
                scale = options.scale, scale_x = options.scale_x, scale_y = options.scale_y, isolated = options.isolated,
                camera_id = options.camera_id, device_id = options.device_id, offline = options.offline, camera_url = options.camera_url});
            end
            if(subCmd == "image") then
                return callbackFunc;
            end
        elseif (subCmd == "smartcar") then
            -- if(options.event) then
            --     local camera_id = options.camera_id;
            --     local event = System.Core.Event:new():init(options.event)
            --     options.callback = function(data) 
            --         if (camera_id and type(data) == "table" and camera_id ~= data.camera_id) then return end
            --         event.msg = data;
            --         GameLogic:event(event)
            --     end
            -- end
            -- local NPLJS = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NPLJS.lua");
            -- NPLJS:SmartCar(options);
        elseif (subCmd == "videoimage") then
            if(options.event) then
                local camera_id = options.camera_id;
                local event = System.Core.Event:new():init(options.event)
                options.callback = function(data) 
                    if (camera_id and type(data) == "table" and camera_id ~= data.camera_id) then return end
                    event.msg = data;
                    GameLogic:event(event)
                end
            end
            local NPLJS = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NPLJS.lua");
            NPLJS:GetCameraImageData(options);
        elseif(subCmd == "none") then
            local NPLJS = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NPLJS.lua");
            NPLJS:CloseCamera();
            GameLogic.AddBBS("capture", nil);
        elseif(subCmd == "hide") then
            local NPLJS = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NPLJS.lua");
            NPLJS:Hide();
        elseif(subCmd == "show") then
            local NPLJS = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NPLJS.lua");
            NPLJS:Show();
        elseif(subCmd == "text") then
            -- audio to text with external web service
             NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/SoundRecorder.lua");
            local SoundRecorder = commonlib.gettable("MyCompany.Aries.Game.Movie.SoundRecorder");
            -- make sure it is wav file.
            local filename = options.file or options.filename or "temp/audioToText.wav";
            if(action == "stop") then
                SoundRecorder.OnStopRecord();
                return
            else
                SoundRecorder.CaptureSound(filename, function(filename)
                    if(callbackFunc.callback) then
                        if(filename) then
                            local content = commonlib.Files.GetFileText(filename);
                            local langId; -- default to Chinese language
                            if(options.language == "en" or options.language == "enUS" or options.language == "English") then
                                langId = "1737" -- English language
                            end
                            keepwork.ai.audioEncode2Text({
                                    format = "wav",
                                    dev_pid = langId,
                                    speech = commonlib.Encoding.base64(content),
                                },
                            -- For unknown reason, sending multipart/form does not work. 
                            -- keepwork.ai.audio2Text(
                            --     {
                            --         -- {name="format", type="string", value="wav"},
                            --         {name="file", type="file", ["Content-Type"] = "audio/wav", filename="input.wav", value=content},
                            --     },
                                function(err, msg, data)
                                    local result, bSucceed;
                                    if (err ~= 200) then
                                        bSucceed = false;
                                        if(err == 429) then
                                            result = L"今天的免费次数用完了"
                                        elseif(err == 500) then
                                            result = ""
                                        elseif(err == 400) then
                                            local data = data or {};
                                            if data.message and data.message ~= "" then
                                                local err_code = data.code or 0;
                                                result = data.message..",错误码："..err_code;
                                            else
                                                result = L"服务器错误,code：400"
                                            end
                                        elseif(type(data) == "string") then
                                            result = data
                                        else
                                            -- TODO: for other err code
                                            result = "error code:"..err;
                                        end
                                    else
                                        result = data and data.data;
                                        bSucceed = true;
                                    end
                
                                    LOG.std(nil, "info", "CommandCapture soundtext", data);
                                    if(callbackFunc.callback) then
                                        callbackFunc.callback(result, bSucceed);
                                        callbackFunc.callback = nil;
                                    end
                                end
                            );
                        else
                            callbackFunc.callback();
                            callbackFunc.callback = nil;
                        end
                    end
                end, options.duration, options.silent)
            end
            return callbackFunc;

        elseif(subCmd == "sound") then
            NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/SoundRecorder.lua");
            local SoundRecorder = commonlib.gettable("MyCompany.Aries.Game.Movie.SoundRecorder");
            local filename = options.file or options.filename;
            SoundRecorder.CaptureSound(filename, function(filename)
                if(callbackFunc.callback) then
                    if(filename) then
                        filename = Files.GetRelativePath(filename)
                    end
                    callbackFunc.callback(filename, filename~=nil);
                    callbackFunc.callback = nil;
                end
            end, options.duration)
            return callbackFunc;

        elseif(subCmd == "objectdetection" or subCmd == "pose" or subCmd == "handpose") then
            -- TODO: audio to text with external web service
            -- https://ai-demos.cocorobo.cn/object-detection/index.html
            local NPLJS = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NPLJS.lua");
            if (action == "start") then
                GameLogic.AddBBS("capture", L"请打开摄像头，ESC键取消", 15000, "0 255 0");

                if(options.event) then
                    local event = System.Core.Event:new():init(options.event)
                    options.callback = function(data) 
                        event.msg = data;
  				        GameLogic:event(event)
                    end
                end
                if (subCmd == "objectdetection") then NPLJS:GetCameraObjectDetection(options) end 
                if (subCmd == "pose") then NPLJS:GetCameraPoseDetection(options) end
                if (subCmd == "handpose") then NPLJS:GetCameraHandPoseDetection(options) end
            else
                NPLJS:Close();
            end
        elseif (subCmd == "webpage") then
            local NPLJS = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NPLJS.lua");
            if (action == "start") then
                NPLJS:GetWebPageImage({callback = function() 
                    if(options.event) then
                        local event = System.Core.Event:new():init(options.event)
  				        event.msg = {};
  				        GameLogic:event(event)
                    end
                end, x = options.x, y = options.y, width = options.width, height = options.height, url = options.url, scale = options.scale, scale_x = options.scale_x, scale_y = options.scale_y, debug = options.debug})
            else
                NPLJS:Close();
            end
        end
    end
};
