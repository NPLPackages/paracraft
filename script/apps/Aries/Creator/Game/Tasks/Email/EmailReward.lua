--[[
    author:pbb
    date:
    Desc:
    use lib:
    local EmailReward = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Email/EmailReward.lua" ) 
    EmailReward.ShowView()
]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
local EmailReward = NPL.export()
local page = nil
EmailReward.rewards = {}

local test = {{gsId=998,amount=42}}

function EmailReward.OnInit()
    page = document:GetPageCtrl();
end

function EmailReward.ShowView(rewards)
    EmailReward.rewards = rewards or test
    print("zzzzzzzzzzzzzzz===============")
    echo(EmailReward.rewards,true)
    local view_width = 440
    local view_height = 310
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Email/EmailReward.html",
        name = "EmailReward.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 4,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key,
        directPosition = true,
        align = "_ct",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    EmailReward.InitRewardUI()
end

function EmailReward.GetTotalNum()
    local num = #EmailReward.rewards or 0
    num = num > 12 and 12 or num
    return num
end

function EmailReward.GetRewardIcon(index)
    if EmailReward.rewards and EmailReward.rewards[index] then
        local gsId = EmailReward.rewards[index].gsId
        local icon = string.format("Texture/Aries/Creator/keepwork/items/item_%d_32bits.png;32 0 65 64",gsId)  
        if gsId > 80000 then
            local item = CustomCharItems:GetItemByGsid(tostring(gsId))
			if item then
				icon = item.icon
			end
        end
        return icon   
    end 
    return ""   
end
-- local EmailManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Email/EmailManager.lua");
-- function EmailReward.GetRewardName(index)
--     if EmailReward.rewards and EmailReward.rewards[index] then
--         local gsId = EmailReward.rewards[index].gsId
--         local iteminfo = EmailManager.GetItemInfo(gsId)
--         local name = ""
--         if iteminfo and type(iteminfo) == "table" then
--             name = iteminfo.name
--         end
--         return name
--     end  
--     return ""
-- end

function EmailReward.GetRewardNum(index)
    if EmailReward.rewards and EmailReward.rewards[index] then
        return EmailReward.rewards[index].amount
    end  
    return 0
end

function EmailReward.GetRewardTips(index)
    if EmailReward.rewards and EmailReward.rewards[index] then
        local gsId = EmailReward.rewards[index].gsId
        local itemTemplate = KeepWorkItemManager.GetItemTemplate(gsId);
        if itemTemplate then
            return itemTemplate.name
        end
    end  
end

function EmailReward.InitRewardUI()
    local parent_root = page:GetParentUIObject() 

    local num = EmailReward.GetTotalNum()
    local index = num / 5
    local startY = EmailReward.GetStartPosY(num)    
    for i =1,num do
        local startX = EmailReward.GetStartPosX(num,i)
        local posx = i<=5 and startX + 80 *(i-1) or startX + 80 *(i - 6)
        local posy = i<=5 and startY  or startY + 80
        local rewardBg = ParaUI.CreateUIObject("container", "rewardBg"..i, "_lt", posx , posy, 60, 60);
        rewardBg.background = "Texture/Aries/Creator/keepwork/Email/wupingdi_60X60_32bits.png;0 0 40 40:16 16 16 16"; 
        rewardBg.visible = true  
        parent_root:AddChild(rewardBg)

        local icon = ParaUI.CreateUIObject("container", "icon"..i, "_lt", 6, 0, 48, 48);
        local tooltip = EmailReward.GetRewardTips(i)
        icon.background = EmailReward.GetRewardIcon(i)
        icon.visible = true
        if tooltip then
            icon.tooltip=tooltip
        end  
        rewardBg:AddChild(icon)


        local rewardNumstr = ""
        if EmailReward.GetRewardNum(i) > 0 then
            rewardNumstr = tostring(EmailReward.GetRewardNum(i))
        end
        local iconnum = ParaUI.CreateUIObject("button", "iconnum"..i, "_lt", 18, 42, 40, 20);
        iconnum.zorder = 3
        iconnum.enabled = false;
        iconnum.text = rewardNumstr
        iconnum.background = "";
        iconnum.shadow = true
        iconnum:SetField("TextShadowQuality",8)
        iconnum.font = "System;12;bold";
        iconnum.visible = true
        _guihelper.SetButtonFontColor(iconnum, "#ffffff", "#ffffff");
        rewardBg:AddChild(iconnum);
    end
end

function EmailReward.GetStartPosX(num,index)
    local total_num = num  or 0
    if num <= 5 then
        total_num = num
    else
        if index <= 5 then
            total_num = 5
        else
            total_num = num - 5
        end
    end
    if total_num == 1 then
        return 188
    elseif total_num == 2 then
        return 150
    elseif total_num == 3 then
        return 110
    elseif total_num == 4 then
        return 66
    elseif total_num == 5 then
        return 32
    end
end

function EmailReward.GetStartPosY(num)
    if num <= 5 then
        return 100
    else
        return 70
    end
end

