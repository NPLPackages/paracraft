--[[
Title: EasyBuilder AI Chat
Author(s): LiXizhi
Date: 2025/11/22
Desc: In-game 1v1 chat with character using LLM

Use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyAIChat.lua");
local EasyAIChat = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyAIChat");
EasyAIChat:ShowPage(targetEntity)
EasyAIChat:CloseWindow()
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/SceneContextManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.ai.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/AIChat.lua");

local AIChat = commonlib.gettable("MyCompany.Aries.Game.Common.AIChat");
local SceneContextManager = commonlib.gettable("System.Core.SceneContextManager");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local EasyAIChat = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyAIChat"));

local page;

-- Custom chat config for Say method
local customChatConfig = {background="Texture/Aries/HeadOn/head_speak_bg_32bits.png;0 0 128 64:24 20 64 41",min_width=88,min_height=64, text_color="#333333",
    padding = 14,
    padding_bottom = 36,
    max_width = 230,
    height = 200,
    fontSize = 16,
}

-- Chat history for the current conversation
EasyAIChat.targetEntity = nil
EasyAIChat.isWaitingForResponse = false
EasyAIChat.currentAIChat = nil
EasyAIChat.model = "keepwork-pro" -- Default model
EasyAIChat.characterConfig = nil
EasyAIChat.showChatLog = false
EasyAIChat.chatLogScrollOffset = 0 -- Number of messages to skip from the end (0 = show latest)
EasyAIChat.showQuickReplies = false

-- Default character configuration
local DEFAULT_CHARACTER_CONFIG = {
    character = {
        name = "数字人",
        age = 8,
        role = "游戏角色",
        description = "你喜欢和用户交流",
        chat_background = nil,
    },
    objective = {
        description = nil,
    },
    initial = {
        message = nil,
    },
    quick_replies = {
        "你好！",
    },
    system_prompt = [[你是一个AI游戏角色。你喜欢和用户交流，。假设用户是7-14岁的孩子，每次用1-2句话回答用户
]],
}

function EasyAIChat.InitPage(Page)
    page = Page;
    EasyAIChat.chatLogScrollOffset = 0
end

function EasyAIChat.GetDisplayName()
    if(EasyAIChat.targetEntity and EasyAIChat.targetEntity.GetDisplayName) then
        local name = EasyAIChat.targetEntity:GetDisplayName() or "";
        name = name:gsub(".*/", "");
        name = name:gsub(":%d%d%d%d.*$", "");
        return name;
    end
    return "";
end

-- Get character config from entity's GetAICharConfig
function EasyAIChat.GetCharacterConfig()
    if not EasyAIChat.targetEntity then
        return nil
    end
    
    local config = nil
    
    -- Try to get AI character config from entity
    if EasyAIChat.targetEntity.GetAICharConfig then
        config = EasyAIChat.targetEntity:GetAICharConfig()
    end
    
    -- If no config from entity, use default config
    if not config then
        config = commonlib.copy(DEFAULT_CHARACTER_CONFIG)
    else
        -- Merge with defaults for any missing fields
        if not config.character then
            config.character = commonlib.copy(DEFAULT_CHARACTER_CONFIG.character)
        end
        if not config.objective then
            config.objective = commonlib.copy(DEFAULT_CHARACTER_CONFIG.objective)
        end
        if not config.initial then
            config.initial = commonlib.copy(DEFAULT_CHARACTER_CONFIG.initial)
        end
        if not config.quick_replies then
            config.quick_replies = commonlib.copy(DEFAULT_CHARACTER_CONFIG.quick_replies)
        end
        -- Use default system_prompt if empty or not specified
        if not config.system_prompt or config.system_prompt == "" then
            config.system_prompt = DEFAULT_CHARACTER_CONFIG.system_prompt
        end
    end
    
    return config
end

-- Helper function to show initial message if available and chat history is empty
function EasyAIChat.ShowInitialMessage()
    if not EasyAIChat.targetEntity or not EasyAIChat.targetEntity.chatHistory then
        return
    end
    
    -- Only show if chat history is empty and initial.message exists
    if #EasyAIChat.targetEntity.chatHistory == 0 and 
       EasyAIChat.characterConfig and EasyAIChat.characterConfig.initial and 
       EasyAIChat.characterConfig.initial.message and 
       EasyAIChat.characterConfig.initial.message ~= "" then
        
        local initialMessage = EasyAIChat.characterConfig.initial.message
        
        -- Add to chat history
        table.insert(EasyAIChat.targetEntity.chatHistory, {
            role = "assistant",
            text = initialMessage,
        })
        
        -- Make entity say the initial message
        if EasyAIChat.targetEntity.Say then
            EasyAIChat.targetEntity:Say(initialMessage, 10, true, customChatConfig)
        end
    end
end

function EasyAIChat:ShowPage(targetEntity)
    if EasyAIChat.targetEntity ~= targetEntity then
        -- Reset chat log display when switching characters
        EasyAIChat.chatLogScrollOffset = 0
        -- disconnect previous beforeDestroyed listener if any
        if EasyAIChat.targetEntity then
            EasyAIChat.targetEntity:Disconnect("beforeDestroyed", EasyAIChat, EasyAIChat.OnEntityDestroyed);
        end
    end
    
    EasyAIChat.targetEntity = targetEntity
    EasyAIChat.isWaitingForResponse = false
    
    -- Initialize chatHistory on entity if it doesn't exist
    if targetEntity and not targetEntity.chatHistory then
        targetEntity.chatHistory = {}
    end
    
    -- Load character config from StaticTag
    if targetEntity then
        EasyAIChat.characterConfig = EasyAIChat.GetCharacterConfig()
        
        -- Add initial message if chat history is empty and initial.message exists
        EasyAIChat.ShowInitialMessage()
    else
        EasyAIChat.characterConfig = nil
    end
    
    local bShow = targetEntity ~= nil
    
    if(bShow) then
        commonlib.TimerManager.SetTimeout(function()
            SceneContextManager:Connect("mousePressed", EasyAIChat, EasyAIChat.OnSceneClicked, "UniqueConnection");
        end, 100);
    end
    
    -- connect to beforeDestroyed signal to close page when entity is destroyed
    if targetEntity then
        targetEntity:Connect("beforeDestroyed", EasyAIChat, EasyAIChat.OnEntityDestroyed, "UniqueConnection");
    end
    
    if(not page) then
        local width, height = 600, 180;
        local params = {
            url = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyAIChat.html", 
            name = "EasyAIChat.ShowPage", 
            isShowTitleBar = false,
            DestroyOnClose = true,
            bToggleShowHide=false, 
            style = CommonCtrl.WindowFrame.ContainerStyle,
            enable_esc_key = true,
            allowDrag = false,
            click_through = true, 
            bShow = (bShow ~= false),
            zorder = 2,
            directPosition = true,
            align = "_ctb",
            x = 0,
            y = 0,
            width = width,
            height = height,
        };
        System.App.Commands.Call("File.MCMLWindowFrame", params);
        if(params._page) then
            params._page.OnClose = function()
                -- disconnect beforeDestroyed listener if any
                local ent = EasyAIChat.targetEntity
                if ent then
                    ent:Disconnect("beforeDestroyed", EasyAIChat, EasyAIChat.OnEntityDestroyed);
                end
                
                if EasyAIChat.currentAIChat then
                    EasyAIChat.currentAIChat:Abort()
                    EasyAIChat.currentAIChat = nil
                end
                
                EasyAIChat.targetEntity = nil
                EasyAIChat.isWaitingForResponse = false
                page = nil;
                SceneContextManager:Disconnect("mousePressed", EasyAIChat, EasyAIChat.OnSceneClicked);
            end
        end
    else
        if(bShow == false) then
            page:CloseWindow();
        else
            page:Refresh(0.1);
        end
    end
end

function EasyAIChat:OnSceneClicked(event)
    -- Don't close on scene click for chat window
    -- User might want to keep chatting while moving around
end

-- Handler for entity beforeDestroyed signal. Closes the window when entity is destroyed.
function EasyAIChat:OnEntityDestroyed()
    EasyAIChat:CloseWindow()
end

function EasyAIChat:CloseWindow()
    if EasyAIChat.currentAIChat then
        EasyAIChat.currentAIChat:Abort()
        EasyAIChat.currentAIChat = nil
    end
    if(page) then
        page:CloseWindow();
    end
    EasyAIChat.showQuickReplies = false
end

function EasyAIChat:RefreshPage()
    if(page) then
        page:Refresh(0.01);
    end
end

function EasyAIChat.OnClickClose()
    EasyAIChat:CloseWindow()
end

function EasyAIChat.HasQuickReplies()
    if EasyAIChat.characterConfig and EasyAIChat.characterConfig.quick_replies then
        return #EasyAIChat.characterConfig.quick_replies > 0
    end
    return false
end

function EasyAIChat.IsShowQuickReplies()
    return EasyAIChat.showQuickReplies
end

function EasyAIChat.OnToggleShowQuickReplies()
    EasyAIChat.showQuickReplies = not EasyAIChat.showQuickReplies
    EasyAIChat:RefreshPage()
end

function EasyAIChat.GetQuickReplies()
    if EasyAIChat.characterConfig and EasyAIChat.characterConfig.quick_replies then
        local result = {}
        for _, reply in ipairs(EasyAIChat.characterConfig.quick_replies) do
            table.insert(result, reply)
        end
        return result
    end
    return {}
end

function EasyAIChat.OnClickQuickReply(index)
    index = tonumber(index)
    local quickReplies = EasyAIChat.GetQuickReplies()
    if not quickReplies or not quickReplies[index] then
        return
    end
    local reply = quickReplies[index].text
    if not reply or reply == "" then
        return
    end
    
    -- Close the quick replies popup
    EasyAIChat.showQuickReplies = false
    EasyAIChat:RefreshPage()
    
    -- auto-send with the reply text
    EasyAIChat.SendText(reply)
end

function EasyAIChat.GetChatHistory()
    return {}
end

function EasyAIChat.IsWaitingForResponse()
    return EasyAIChat.isWaitingForResponse
end

function EasyAIChat.IsShowChatLog()
    return EasyAIChat.showChatLog
end

function EasyAIChat.OnToggleShowChatLog()
    EasyAIChat.showChatLog = not EasyAIChat.showChatLog
    if EasyAIChat.showChatLog then
        -- Reset scroll to show latest messages
        EasyAIChat.chatLogScrollOffset = 0
    end
    EasyAIChat:RefreshPage()
end

function EasyAIChat.OnScrollChatLogUp()
    if not EasyAIChat.targetEntity or not EasyAIChat.targetEntity.chatHistory then
        return
    end
    local totalMessages = #EasyAIChat.targetEntity.chatHistory
    local maxOffset = math.max(0, totalMessages - 5)
    if EasyAIChat.chatLogScrollOffset < maxOffset then
        EasyAIChat.chatLogScrollOffset = EasyAIChat.chatLogScrollOffset + 1
        EasyAIChat:RefreshPage()
    end
end

function EasyAIChat.OnScrollChatLogDown()
    if EasyAIChat.chatLogScrollOffset > 0 then
        EasyAIChat.chatLogScrollOffset = EasyAIChat.chatLogScrollOffset - 1
        EasyAIChat:RefreshPage()
    end
end

function EasyAIChat.GetTotalMessagesCount()
    if not EasyAIChat.targetEntity or not EasyAIChat.targetEntity.chatHistory then
        return 0
    end
    return #EasyAIChat.targetEntity.chatHistory
end

function EasyAIChat.GetVisibleChatHistory()
    local history = {}
    if not EasyAIChat.targetEntity or not EasyAIChat.targetEntity.chatHistory then
        return history
    end
    
    local totalMessages = #EasyAIChat.targetEntity.chatHistory
    
    if totalMessages == 0 then
        return history
    end
    
    -- Filter out tool messages and prepare display list
    local displayList = {}
    for i = 1, totalMessages do
        local msg = EasyAIChat.targetEntity.chatHistory[i]
        if msg.role == "user" or msg.role == "assistant" then
            table.insert(displayList, msg)
        end
    end
    
    local totalDisplay = #displayList
    if totalDisplay == 0 then
        return history
    end

    -- Calculate the range of messages to show (5 messages)
    local endIndex = totalDisplay - EasyAIChat.chatLogScrollOffset
    local startIndex = math.max(1, endIndex - 4) -- Show 5 messages
    
    for i = startIndex, endIndex do
        local msg = displayList[i]
        if(msg.text and #msg.text > 300) then
            msg = commonlib.copy(msg)
            msg.text = string.sub(msg.text, 1, 300).."...";
        end
        table.insert(history, msg)
    end
    
    return history
end

function EasyAIChat.CanScrollUp()
    if not EasyAIChat.targetEntity or not EasyAIChat.targetEntity.chatHistory then
        return false
    end
    local totalMessages = #EasyAIChat.targetEntity.chatHistory
    local maxOffset = math.max(0, totalMessages - 5)
    return EasyAIChat.chatLogScrollOffset < maxOffset
end

function EasyAIChat.CanScrollDown()
    return EasyAIChat.chatLogScrollOffset > 0
end

-- Send text directly to the AI
function EasyAIChat.SendText(text)
    if not text or text == "" then
        return
    end
    
    if EasyAIChat.isWaitingForResponse then
        GameLogic.AddBBS(nil, L"请等待回复...", 2000)
        return
    end
    
    if not EasyAIChat.targetEntity then
        GameLogic.AddBBS(nil, L"角色已不存在", 2000)
        EasyAIChat:CloseWindow()
        return
    end
    
    -- Initialize chatHistory if needed
    if not EasyAIChat.targetEntity.chatHistory then
        EasyAIChat.targetEntity.chatHistory = {}
    end
    
    -- Add user message to history
    table.insert(EasyAIChat.targetEntity.chatHistory, {
        role = "user",
        text = text,
    })
    
    -- Check if the entity's copilot can handle this message
    if EasyAIChat.targetEntity.copilot and EasyAIChat.targetEntity.copilot.OnChatMessage then
        local handled, replyText = EasyAIChat.targetEntity.copilot:OnChatMessage(text)
        if handled then
            -- Copilot handled the message, add reply to history if provided
            if replyText and replyText ~= "" then
                table.insert(EasyAIChat.targetEntity.chatHistory, {
                    role = "assistant",
                    text = replyText,
                })
            end
            -- Close the window and let copilot take over
            EasyAIChat:CloseWindow()
            return
        end
    end
    
    -- Set waiting state
    EasyAIChat.isWaitingForResponse = true
    EasyAIChat:RefreshPage()
    
    -- Call LLM API to get response
    EasyAIChat:HandleLLMResponse(text)
end

function EasyAIChat.OnClickSend(name)
    local inputText;
    if(page) then
        inputText = page:GetUIValue("chatInput");
    end
    if not inputText or inputText == "" then
        return
    end
    
    -- Clear input field
    if page then
        local inputNode = page:GetNode("chatInput")
        if inputNode then
            inputNode:SetAttribute("value", "")
        end
    end
    
    EasyAIChat.SendText(inputText)
end

function EasyAIChat:HandleLLMResponse(userInput)
    if not EasyAIChat.targetEntity or not EasyAIChat.targetEntity.chatHistory then
        return
    end

    if EasyAIChat.currentAIChat then
        EasyAIChat.currentAIChat:Abort()
    end

    local aiChat = AIChat:new();
    EasyAIChat.currentAIChat = aiChat;
    if EasyAIChat.needOfficialTools then
        aiChat:RegisterEasyTools();
    end

    -- Check if target entity's copilot has tools
    if EasyAIChat.targetEntity and EasyAIChat.targetEntity.copilot and EasyAIChat.targetEntity.copilot.GetTools then
        local tools = EasyAIChat.targetEntity.copilot:GetTools()
        if tools and #tools > 0 then
            -- Deep copy tools to avoid potential issues with C++ bindings modifying the table
            local toolsCopy = commonlib.deepcopy(tools)
            aiChat:SetTools(toolsCopy)
            
            -- Register callbacks for each tool
            for _, tool in ipairs(toolsCopy) do
                local toolName = tool["function"].name
                aiChat:RegisterToolCallback(toolName, function(args, callback)
                    if EasyAIChat.targetEntity and EasyAIChat.targetEntity.copilot and EasyAIChat.targetEntity.copilot.HandleToolCall then
                         local result = EasyAIChat.targetEntity.copilot:HandleToolCall(toolName, args, callback)
                         if callback then
                            if result ~= nil then
                                callback(result)
                            end
                         else
                            return result or "Tool executed"
                         end
                         return
                    end
                    if callback then
                        callback("Tool execution failed: Copilot not found")
                        return
                    end
                    return "Tool execution failed: Copilot not found"
                end)
            end
        end
    end

    aiChat:SetModel(EasyAIChat.model);
    aiChat:SetStream(true);
    -- Enable auto_history to ensure AIChat records tool interactions internally
    -- This is crucial for Sync logic to retrieve the full context (Tool Calls/Results)
    aiChat:SetAutoHistory(true);

    -- Add system prompt from character config if available
    if EasyAIChat.characterConfig and EasyAIChat.characterConfig.system_prompt then
        aiChat:SetSystemPrompt(EasyAIChat.characterConfig.system_prompt);
    end
    
    -- Limit chat history to last 15 messages to avoid context window issues
    local maxHistory = 15
    local totalMsgs = #EasyAIChat.targetEntity.chatHistory
    local startIdx = math.max(1, totalMsgs - maxHistory + 1)
    
    for i = startIdx, totalMsgs do
        local msg = EasyAIChat.targetEntity.chatHistory[i]
        -- Support tool roles and extra fields
        if msg.role == "user" or msg.role == "assistant" or msg.role == "tool" then
             aiChat:AddMessage(msg.role, msg.text or msg.content, msg.tool_calls, msg.tool_call_id);
        end
    end

    -- Add placeholder for assistant response
    local assistantMsg = {
        role = "assistant",
        text = "",
        isStreaming = true
    }
    table.insert(EasyAIChat.targetEntity.chatHistory, assistantMsg)

    local lastSayTime = 0;
    local lastSayLength = 0;

    aiChat:Ask(nil, function(resultCode, delta, deltaThink, fullResult, fullThink)
        if not page then return end
        
        local result = fullResult or ""
        local think = fullThink or ""
        local bSucceed = false;

        if(not resultCode) then
            -- Streaming update
            local displayText = result
            if think and think ~= "" then
                displayText = string.format("<think>%s</think>\n%s", think, result)
            end
            assistantMsg.text = displayText
            
            local curTime = commonlib.TimerManager.GetCurrentTime();
            if((curTime - lastSayTime) > 1000) then
                 if(string.len(result) > lastSayLength) then
                    if(EasyAIChat.targetEntity and EasyAIChat.targetEntity.Say) then
                        EasyAIChat.targetEntity:Say(result, 10, true, customChatConfig);
                    end
                    lastSayTime = curTime;
                    lastSayLength = string.len(result);
                 end
            end
        else
            -- Finished or Error
            EasyAIChat.isWaitingForResponse = false
            assistantMsg.isStreaming = false
            
            if (resultCode ~= 200) then
                bSucceed = false;
                if(resultCode == 429) then
                    result = L"今天的免费对话次数用完了"
                elseif(type(result) == "string" and result ~= "") then
                    -- result is already set to fullResult
                else
                    result = L"哎呀,开小差了！"
                end
                assistantMsg.text = result
            else
                bSucceed = true;
                local displayText = result
                if think and think ~= "" and not result:find("<think>") then
                    displayText = string.format("<think>%s</think>\n%s", think, result)
                end
                
                -- Log the completed chat result
                LOG.std(nil, "info", "EasyAIChat", "chat completed - result: %s, think: %s", result, think or "");
                
                -- Sync back full history from AIChat to preserve tool call context
                -- This ensures the next request includes the tool calls that happened in this turn
                if aiChat and aiChat.GetHistory then
                    local newHistory = aiChat:GetHistory()
                    local convertedHistory = {}
                    for _, m in ipairs(newHistory) do
                        local newM = commonlib.copy(m)
                        -- Ensure compatibility with EasyAIChat which uses 'text' field
                        if not newM.text and newM.content then
                            newM.text = newM.content
                        end
                        table.insert(convertedHistory, newM)
                    end
                    EasyAIChat.targetEntity.chatHistory = convertedHistory
                    
                    -- Update assistantMsg ref for speech (it might be the last message now)
                    if #convertedHistory > 0 then
                        local lastMsg = convertedHistory[#convertedHistory]
                        if lastMsg.role == "assistant" then
                            assistantMsg.text = lastMsg.text
                        end
                    end
                else
                    assistantMsg.text = displayText
                end
            end
            
            EasyAIChat:RefreshPage()
            
            -- Speak the result
            if bSucceed and EasyAIChat.targetEntity and EasyAIChat.targetEntity.Say then
                EasyAIChat.targetEntity:Say(result, 10, true, customChatConfig)
            end
        end
    end)
end

function EasyAIChat.OnClickClearChatLog()
    if EasyAIChat.targetEntity then
        EasyAIChat.targetEntity.chatHistory = {}
        
        -- Add initial message if it exists
        EasyAIChat.ShowInitialMessage()
    end
    EasyAIChat.chatLogScrollOffset = 0
    EasyAIChat:RefreshPage()
end
