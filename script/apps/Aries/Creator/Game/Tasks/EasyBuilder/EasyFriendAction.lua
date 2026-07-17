--[[
Title: EasyBuilder Friend Action Task
Author(s): LiXizhi
Date: 2025/10/09
Desc: Friend interaction system with level-based actions

Use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyFriendAction.lua");
local EasyFriendAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyFriendAction");
EasyFriendAction:ShowPage(GameLogic.EntityManager.GetPlayer())
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/EntityAnimation.lua");
local FriendActionManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/FriendActionManager.lua");
local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local EasyFriendAction = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyFriendAction"));

local page;
local baseAnimPath = "character/Animation/movietemplates/friend/"
-- Configuration: actions available per friend level
-- Each action has: name, animId, icon (optional), description
EasyFriendAction.friendLevelConfig = {
    [1] = {
        level_name = "陌生人",
        actions = {
            { name = "个人信息", animId = 161, noConfirm=true, funcName="OnClickViewProfile", description = "查看对方信息" },
            { name = "+ 好友", animId = 31, funcName="OnClickAddFriend", description = "礼貌地点头" },
            { name = "打招呼", animId = 0, animDuration=3000, animFile=baseAnimPath.."zoulujizhang.blocks.xml", description = "友好地打个招呼" },
            --{ name = "再见", animId = 35, smiley="$5", description = "挥手告别" },
            { name = "送食物", animId = 0, noConfirm=true, funcName="OnClickSendFood", description = "吃的东西" },
            { name = "跟随", animId = 0, customAnim="follow", description = "挥手" },
             { name = "请跟我", animId = 0, customAnim="followme", description = "挥手" },
        }
    },
    [2] = {
        level_name = "普通朋友",
        actions = {
            { name = "送礼", animId = 0, animDuration=3000, animFile=baseAnimPath.."songli.blocks.xml", description = "送礼", },
            { name = "鼓掌", animId = 145, smiley="$6", description = "为朋友鼓掌" },
            { name = "送小心心", animId = 0, animDuration=3000, animFile=baseAnimPath.."songxiaoxingxing.blocks.xml", description = "送小心心", },
        }
    },
    [3] = {
        level_name = "好朋友",
        actions = {
            { name = "双人舞", animId = 0, animDuration=3000, animFile=baseAnimPath.."tiaowu.blocks.xml", description = "一起跳舞" },
            { name = "一起跑步", animId = 0, animDuration=3000, animFile=baseAnimPath.."run.blocks.xml", description = "一起跑步" },
            { name = "讲故事", animId = 171, description = "给朋友讲故事" },
        }
    },
    [4] = {
        level_name = "亲密朋友",
        actions = {
            { name = "文本私聊", animId = 148, description = "打字" },
            { name = "放孔明灯", animId = 0, animDuration=3000, animFile=baseAnimPath.."fangtiandeng.blocks.xml", description = "放孔明灯" },
            { name = "屁股着火", animId = 0, animDuration=3000, animFile=baseAnimPath.."piguzhaohuo.blocks.xml", description = "屁股着火" },
        }
    },
    [5] = {
        level_name = "挚友",
        actions = {
            { name = "坐下聊天", animId = 72, description = "坐下来聊天" },
            { name = "坐着思考", animId = 78, description = "一起思考问题" },
            { name = "肩碰肩", animId = 0, animDuration=3000, animFile=baseAnimPath.."pengjian.blocks.xml", description = "肩碰肩" },
        }
    },
    [6] = {
        level_name = "知己",
        actions = {
            { name = "踏青", animId = 0, animDuration=3000, animFile=baseAnimPath.."chunyiangran.blocks.xml", description = "春意盎然" },
            { name = "平躺", animId = 100, description = "一起休息" },
            { name = "好buddy", animId = 0, animDuration=3000, animFile=baseAnimPath.."buddy.blocks.xml", description = "buddy" },
           
        }
    },
    [7] = {
        level_name = "灵魂伴侣",
        actions = {
            { name = "比心", animId = 0, animDuration=3000, animFile=baseAnimPath.."bixin.blocks.xml", description = "比心" },
            { name = "一起飞", animId = 38, description = "飞行" },
        }
    },
}

function EasyFriendAction.InitPage(Page)
    page = Page;
end

function EasyFriendAction:ShowPage(targetEntity)
    EasyFriendAction.targetEntity = targetEntity
    FriendActionManager.Init()
    if(not page) then
        local width, height = 380, 640;
        local params = {
                url = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyFriendAction.html", 
                name = "EasyFriendAction.ShowPage", 
                isShowTitleBar = false,
                DestroyOnClose = true,
                bToggleShowHide=false, 
                style = CommonCtrl.WindowFrame.ContainerStyle,
                enable_esc_key = false,
                allowDrag = false,
                click_through = true, 
                bShow = (bShow ~= false),
                directPosition = true,
                    align = "_rt",
                    x = -width-20,
                    y = 64,
                    width = width,
                    height = height,
            };
        System.App.Commands.Call("File.MCMLWindowFrame", params);
        if(params._page) then
            params._page.OnClose = function()
                page = nil;
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

function EasyFriendAction:CloseWindow()
    if(page) then
        page:CloseWindow();
    end
end

function EasyFriendAction:RefreshPage()
    if(page) then
        page:Refresh(0.01);
    end
end

-- Get current friend level
function EasyFriendAction.GetCurrentFriendLevel()
    if not EasyFriendAction.targetEntity then
        return 1
    end
    local username = EasyFriendAction.targetEntity.GetUserName and EasyFriendAction.targetEntity:GetUserName()
    if username then
        EasyFriendAction.currentFriendLevel = FriendActionManager.GetFriendLevel(username)
    end
    return EasyFriendAction.currentFriendLevel or 1;
end

-- Set friend level
function EasyFriendAction.SetFriendLevel(level)
    level = tonumber(level);
    if(level and level >= 1 and level <= 7) then
        EasyFriendAction.currentFriendLevel = level;
        if(page) then
            page:Refresh(0.01);
        end
    end
end

function EasyFriendAction.GetCurrentFriendLevelName()
    local level = EasyFriendAction.GetCurrentFriendLevel();
    local config = EasyFriendAction.friendLevelConfig[level];
    if(config) then
        return config.level_name;
    end
    return "";
end

-- Get all actions from all friend levels
function EasyFriendAction.GetAllLevelActions()
    -- Cache the actions_ds on first access
    if(not EasyFriendAction.cached_actions_ds) then
        local actions_ds = {};
        local index = 1;
        
        for level = 1, 7 do
            local config = EasyFriendAction.friendLevelConfig[level];
            if(config) then
                -- Add level header
                actions_ds[index] = {
                    data_type = "level_header",
                    index = index,
                    levelName = "等级 " .. level .. " - " .. config.level_name,
                    level = level,
                };
                index = index + 1;
                
                -- Add actions for this level
                for i, action in ipairs(config.actions) do
                    actions_ds[index] = {
                        data_type = "action",
                        index = index,
                        actionName = action.name,
                        animDuration = action.animDuration or 2000,
                        animFile = action.animFile,
                        animId = action.animId or "",
                        funcName = action.funcName or "",
                        description = action.description or "",
                        smiley = action.smiley or "",
                        customAnim = action.customAnim,
                        noConfirm = action.noConfirm,
                        level = level,
                    };
                    index = index + 1;
                end
            end
        end
        
        EasyFriendAction.cached_actions_ds = actions_ds;
    end
    
    return EasyFriendAction.cached_actions_ds;
end

function EasyFriendAction.GetAllActionCount()
    local count = 0;
    for level = 1, 7 do
        local config = EasyFriendAction.friendLevelConfig[level];
        if(config and config.actions) then
            count = count + #config.actions;
        end
    end
    return count;
end

-- Handle action click
function EasyFriendAction.OnClickAction(index)
    index = tonumber(index);
    if(not index) then return end
    
    -- Find the action in the all actions list
    local allActions = EasyFriendAction.GetAllLevelActions();
    local actionData = allActions[index];
    if(not actionData or actionData.data_type ~= "action") then return end
    
    if(actionData.level > EasyFriendAction.GetCurrentFriendLevel()) then
        GameLogic.AddBBS(nil, L"需要提升好友等级才能使用此动作");
        return
    end
     if not EasyFriendAction.targetEntity then
        GameLogic.AddBBS(nil, L"请先选择一个目标");
        return
    end
    if(actionData.funcName and actionData.funcName ~= "") then
        local func = EasyFriendAction[actionData.funcName];
        if(type(func) == "function") then
            func(EasyFriendAction.targetEntity);
        end
    end
    
    -- If noConfirm is true, execute action locally without network confirmation
    if(actionData.noConfirm) then
        EasyFriendAction.DoAction(actionData)
        EasyFriendAction.OnClickClose()
        return
    end
   
    local username = EasyFriendAction.targetEntity.GetUserName and EasyFriendAction.targetEntity:GetUserName() or "";
    if not username or username == "" then
        GameLogic.AddBBS(nil, L"目标用户不存在");
        return
    end
    local actionname = actionData.actionName;
    if actionname and actionname ~= "" then
        FriendActionManager.SendFriendAction(actionname,username)
    end
    EasyFriendAction.OnClickClose()
end

function EasyFriendAction.GetActionDataByName(name)
    local allActions = EasyFriendAction.GetAllLevelActions();
    for _, action in ipairs(allActions) do
        if(action.actionName == name) then
            return action;
        end
    end
    return nil;
end

function EasyFriendAction.DoAction(actionData)
    if(actionData.smiley and actionData.smiley ~= "") then
        local MiniGameSmileyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameSmileyPage.lua");
        MiniGameSmileyPage.DoSendSmileySymbol(actionData.smiley)
    end
    local animId = actionData.animId
    if(animId) then
        local entity = EntityManager:GetFocus();
        if(entity and entity.SetAnimation) then
            local animDuration = actionData.animDuration or 2000;
            if(EasyFriendAction.targetEntity and EasyFriendAction.targetEntity ~= entity and EasyFriendAction.targetEntity.SetAnimation) then
                local targetEntity = EasyFriendAction.targetEntity;
                -- Make entities face each other
                local x1, y1, z1 = entity:GetPosition();
                local x2, y2, z2 = targetEntity:GetPosition();
                local dx = x2 - x1;
                local dz = z2 - z1;
                local facing = math.atan2(dx, dz) - math.pi/2; 
                entity:SetFacing(facing);
                targetEntity:SetFacing(facing + math.pi);
                
                -- TODO: we may need to send a network message to the target entity to ask for comfirmation
                -- tricky: remove using SetAnimId, after you implement network event. 
                local animFunc = targetEntity.SetAnimId or targetEntity.SetAnimation;
                animFunc(targetEntity, animId)
                targetEntity:SetHeadRotation(0, 0);
                commonlib.TimerManager.SetTimeout(function()
                    animFunc(targetEntity, 0);
                end, animDuration);
            end
            

            entity:SetControlledExternally(true);
            entity:SetHeadRotation(0, 0);
            entity:SetAnimation(animId);
            
            -- Reset external control after 2 seconds
            commonlib.TimerManager.SetTimeout(function()
                if(entity) then
                    entity:SetAnimation(0);
                    entity:SetControlledExternally(false);
                end
            end, animDuration);
        end
        
    end
end

function EasyFriendAction.OnClickClose()
    EasyFriendAction:CloseWindow()
end

function EasyFriendAction.OnClickViewProfile(targetEntity)
    if(targetEntity and targetEntity.GetUserName) then
        local username = targetEntity:GetUserName();
        if(username and username ~= "") then
            GameLogic.ShowUserInfoPage(username);
        end
    end
end

function EasyFriendAction.OnClickAddFriend(targetEntity)
    if not targetEntity then
        return
    end
    if targetEntity.GetPlayerInfo then
        local playerInfo = targetEntity:GetPlayerInfo()
        local userInfo = playerInfo.userinfo
        local userId = userInfo.id
        if not userId or userId == "" then
            return
        end
        EasyFriendAction.SendFriendApply(userId)
        return
    end
    if(targetEntity.GetUserName) then
        local username = targetEntity:GetUserName();
        if(username and username ~= "") then
            local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
            KeepWorkItemManager.GetUserInfo({
                username = username,
                cache_policy = "access plus 100 days",
            },function(err,msg,data)
                if(err ~= 200)then
                    return
                end
                EasyFriendAction.SendFriendApply(data.id)
            end)
        end
    end
    
end

function EasyFriendAction.CheckIsFriend(friendId,callback)
	keepwork.friend.friendsList({
        headers = {
            ["x-per-page"] = 300,
            ["x-page"] = 1,
        }
	},function(err, msg, data)
		if err == 200 then
			data = data or {}
			for k,v in pairs(data) do
				if v.friendId == friendId then
					callback(true)
					return
				end
			end
			callback(false)
		end
	end)
end

function EasyFriendAction.SendFriendApply(userId)
    local my_userId = Mod.WorldShare.Store:Get("user/userId")
    if userId and my_userId == userId then
        GameLogic.AddBBS("statusBar", L"不能添加自己为好友", 5000, "0 255 0");
        return
    end
    EasyFriendAction.CheckIsFriend(userId,function(isFriend)
        if isFriend then
            GameLogic.AddBBS("statusBar", L"该用户已是您的好友", 5000, "0 255 0");
            return
        end
        keepwork.friend.applyFriend({
            friendId = userId,
            remark = "希望成为您的好友",
        },function(err, msg, data)
            if err == 200 then
                GameLogic.AddBBS("statusBar", L"已向对方发出好友请求，请耐心等待回复。", 5000, "0 255 0");
            end
        end)
    end)
end

function EasyFriendAction.OnClickSendFood()
    local MiniGameUserBag = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameUserBag.lua");
    MiniGameUserBag.ShowPage("food", nil, true)
end
