--[[
Title: EasyBuilder AI Configuration
Author(s): LiXizhi
Date: 2025/11/23
Desc: Configuration page for AI character settings

Use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyAIConfig.lua");
local EasyAIConfig = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyAIConfig");
EasyAIConfig:ShowPage(targetEntity)
-------------------------------------------------------
]]
local EasyAIConfig = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyAIConfig"));
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");

local page;
EasyAIConfig.targetEntity = nil
EasyAIConfig.config = nil

-- Default character configuration (same as in EasyAIChat.lua)
local DEFAULT_CHARACTER_CONFIG = {
    character = {
        name = "数字人",
        age = 8,
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

function EasyAIConfig.InitPage(Page)
    page = Page;
end

function EasyAIConfig:ShowPage(targetEntity)
    EasyAIConfig.targetEntity = targetEntity
    
    if not targetEntity then
        return
    end
    
    -- Load existing config or use default
    if targetEntity.GetAICharConfig then
        EasyAIConfig.config = commonlib.copy(targetEntity:GetAICharConfig())
    end
    
    if not EasyAIConfig.config then
        EasyAIConfig.config = commonlib.copy(DEFAULT_CHARACTER_CONFIG)
    else
        -- Ensure structure exists
        if not EasyAIConfig.config.character then
            EasyAIConfig.config.character = commonlib.copy(DEFAULT_CHARACTER_CONFIG.character)
        end
        if not EasyAIConfig.config.initial then
            EasyAIConfig.config.initial = commonlib.copy(DEFAULT_CHARACTER_CONFIG.initial)
        end
        if not EasyAIConfig.config.quick_replies then
            EasyAIConfig.config.quick_replies = commonlib.copy(DEFAULT_CHARACTER_CONFIG.quick_replies)
        end
        if not EasyAIConfig.config.system_prompt then
            EasyAIConfig.config.system_prompt = DEFAULT_CHARACTER_CONFIG.system_prompt
        end
    end
    
    -- Load name from entity's display name if available
    if targetEntity.GetDisplayName then
        local displayName = targetEntity:GetDisplayName()
        if displayName and displayName ~= "" then
            EasyAIConfig.config.character.name = displayName
        end
    end
    
    local width, height = 500, 600;
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyAIConfig.html", 
        name = "EasyAIConfig.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        bToggleShowHide=false, 
        style = CommonCtrl.WindowFrame.ContainerStyle,
        enable_esc_key = true,
        allowDrag = true,
        click_through = false, 
        zorder = 2,
        directPosition = true,
        align = "_ct",
        x = -width/2,
        y = -height/2,
        width = width,
        height = height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function EasyAIConfig.CloseWindow()
    if(page) then
        page:CloseWindow();
    end
end

function EasyAIConfig.GetConfig()
    return EasyAIConfig.config
end

function EasyAIConfig.GetQuickRepliesText()
    if EasyAIConfig.config and EasyAIConfig.config.quick_replies then
        return table.concat(EasyAIConfig.config.quick_replies, "\n")
    end
    return ""
end

function EasyAIConfig.OnClickSave()
    if not page or not EasyAIConfig.targetEntity then
        return
    end
    
    -- Update config from UI
    EasyAIConfig.config.character.name = page:GetUIValue("name")
    EasyAIConfig.config.system_prompt = page:GetUIValue("system_prompt")
    EasyAIConfig.config.initial.message = page:GetUIValue("initial_message")
    
    -- Parse quick replies
    local quickRepliesText = page:GetUIValue("quick_replies")
    local quickReplies = {}
    for line in string.gmatch(quickRepliesText, "[^\r\n]+") do
        if line and line ~= "" then
            table.insert(quickReplies, line)
        end
    end
    EasyAIConfig.config.quick_replies = quickReplies
    
    -- Set display name on entity
    if EasyAIConfig.targetEntity.SetDisplayName then
        EasyAIConfig.targetEntity:SetDisplayName(EasyAIConfig.config.character.name)
    end
    
    -- Save to entity
    if EasyAIConfig.targetEntity.SetAICharConfig then
        EasyAIConfig.targetEntity:SetAICharConfig(EasyAIConfig.config)
        GameLogic.AddBBS(nil, L"配置已保存", 2000)
    end
    
    EasyAIConfig.CloseWindow()
end
