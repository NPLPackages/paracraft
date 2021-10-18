--[[
    author:pbb
    date:
    Desc:
    use lib:
    local CreateReward = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateReward/CreateReward.lua") 
    CreateReward.ShowView()
]]
local CreateRewardManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateReward/CreateRewardManager.lua") 
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local CreateReward = NPL.export()

local giftState = {
	can_not_get = 0,		--未能领取
	can_get = 1,			--可领取
	has_get = 2,			--已领取
}

local page = nil
local parent_root = nil
local strPath = ';NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateReward/CreateReward.lua")'
function CreateReward.OnInit()
    page = document:GetPageCtrl();
    parent_root  = page:GetParentUIObject()
    page.OnCreate = CreateReward.OnCreate()    
end

function CreateReward.ShowView()
    local view_width = 700
    local view_height = 450
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/CreateReward/CreateReward.html",
        name = "CreateReward.ShowView", 
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
    CreateReward.AddGiftItems()
end

function CreateReward.GetCreateTime()
    return CreateRewardManager.m_nCreateTotalTime
end

function CreateReward.RefreshPage()
    if page then
        page:Refresh(0)
        CreateReward.AddGiftItems()
    end
end

function CreateReward.OnCreate()
    --CreateReward.AddGiftItems()
end

function CreateReward.AddGiftItems()
    local startPos = {{44,52},{150,52},{294,52},{596,52}}
    local dotPos = {{60,119},{166,119},{314,119},{610,119}}
    local statePos = {{80,90},{186,90},{334,90},{630,90}}
    local times = {5,15,30,60}
    local get_index = CreateRewardManager.CheckGetIndex()
    local stateList = CreateRewardManager.GetGiftStateList()
      
    for i=1,4 do
        local normal = "Texture/Aries/Creator/keepwork/CreateReward/liwu2_55X56_32bits.png;0 0 55 56";
        local select = "Texture/Aries/Creator/keepwork/CreateReward/liwu1_55X56_32bits.png;0 0 55 56"; 
        local select_sp = "Texture/Aries/Creator/keepwork/CreateReward/liwu3_86X70_32bits.png;0 0 86 70"; 
        local gift_bg = normal
        local size = {55, 56}
        if i <= get_index then
            gift_bg = select
            if i == 4 then
                gift_bg = select_sp
                size = {76,62}
                startPos[i] = {588,48}
            end                
        end
        local gift_btn = ParaUI.CreateUIObject("button", "gift"..i, "_lt", startPos[i][1], startPos[i][2], size[1], size[2]);
        gift_btn.visible = true
        gift_btn.onclick = string.format([[%s.OnGiftClick(%d);]],strPath,i)
        gift_btn.background = gift_bg
        parent_root:AddChild(gift_btn);  
        
        local dotImg = ParaUI.CreateUIObject("container", "dot"..i, "_lt", dotPos[i][1], dotPos[i][2], 24, 24);
        dotImg:GetAttributeObject():SetField("ClickThrough", true);
        dotImg.background = "Texture/Aries/Creator/keepwork/CreateReward/yuan2_24X24_32bits.png;0 0 24 24"
        if i <= get_index then
            dotImg.background = "Texture/Aries/Creator/keepwork/CreateReward/yuan_24X24_32bits.png;0 0 24 24"
        end
        parent_root:AddChild(dotImg);  

        local txtTime = ParaUI.CreateUIObject("text", "times", "_lt", dotPos[i][1] - 14, 150, 80, 20);
        txtTime.background = nil;
        txtTime.text = times[i].."分钟";
        txtTime.font = "Tahoma;14;bold";
        parent_root:AddChild(txtTime)
        local default_state = i <= get_index and giftState.can_get or giftState.can_not_get  
        if default_state == giftState.can_get and stateList[i] == giftState.has_get then
            local getImg = ParaUI.CreateUIObject("container", "state"..i, "_lt", statePos[i][1], statePos[i][2], 22, 22);
            getImg:GetAttributeObject():SetField("ClickThrough", true);
            getImg.zorder = 2
            getImg.background = "Texture/Aries/Creator/keepwork/CreateReward/dagou_22X22_32bits.png;0 0 22 22"
            parent_root:AddChild(getImg); 
        end
    end
    CreateReward.ShowGiftItems()
end

function CreateReward.ShowGiftItems()
    local startX = 210 
    local startY = 310
    local icons = {"wuping_douzi_36X33_32bits.png;0 0 36 32","dianzan_32X32_32bits.png;0 0 32 32","pifu_64X64_32bits.png;0 0 64 64"}
    local tooltips = {"知识豆","作品推荐数","皮肤碎片"}
    for i = 1,3 do
        local giftImg = ParaUI.CreateUIObject("container", "giftbg"..i, "_lt", startX + (i-1)*90, startY, 60, 60);
        giftImg:GetAttributeObject():SetField("ClickThrough", true);
        giftImg.background = "Texture/Aries/Creator/keepwork/CreateReward/wupingdi_60X60_32bits.png;0 0 40 40:19 19 19 19"        
        parent_root:AddChild(giftImg);  


        local giftItem = ParaUI.CreateUIObject("container", "giftitem"..i, "_lt", 10, 10, 44, 44);
        giftItem.background = string.format("Texture/Aries/Creator/keepwork/CreateReward/%s",icons[i])
        giftItem.tooltip = tooltips[i]
        giftImg:AddChild(giftItem)
    end
end

function CreateReward.OnGiftClick(index)
    local get_index = CreateRewardManager.CheckGetIndex()
    if index > get_index then
        GameLogic.AddBBS(nil,"在创造区创造精彩的作品，奖励才会累加的更快哟")
        return 
    end

    local stateList = CreateRewardManager.GetGiftStateList()
    local default_state = index <= get_index and giftState.can_get or giftState.can_not_get
    local isGetGift = stateList[index] and stateList[index] or default_state
    if isGetGift ~= giftState.can_get then
        GameLogic.AddBBS(nil,"当前奖励已领取")
        return
    end

    local gifts = {
        {{exid = 30040 ,name ="知识豆",num = 20}},
        {{exid = 30051 ,name ="知识豆",num = 30}},
        {{exid=30042,name="知识豆",num = 50},{exid=30043,name="点赞",num = 30}},
        {{exid=30044,name="知识豆",num = 80},{exid=30045,name="点赞",num = 50},{exid=30046,name="皮肤碎片",num = 1}}
    }
    local r = math.random(0, 1000);
    local giftConfig = nil
    if index < 3 then
        giftConfig = gifts[index][1]
    elseif index == 3 then
        if r <=500 then
            giftConfig = gifts[index][1]
        else
            giftConfig = gifts[index][2]
        end
    elseif index == 4 then
        if r <=200 then
            giftConfig = gifts[index][1]
        elseif r <=600 then
            giftConfig = gifts[index][2]
        else
            giftConfig = gifts[index][3]
        end
    end 
    if giftConfig ~= nil then
        KeepWorkItemManager.DoExtendedCost(giftConfig.exid,function()
            local showConfig = {}
            if giftConfig.exid == 30043 or giftConfig.exid == 30045 then
                showConfig.gsId = 10005
            elseif giftConfig.exid == 30046 then
                showConfig.gsId = 10006
            else
                showConfig.gsId = 998
            end
            CreateRewardManager.SetGiftState(index,giftState.has_get)
            showConfig.num = giftConfig.num
            CreateReward.RefreshPage()
            local GetRewardResult = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateReward/GetRewardResult.lua") 
            GetRewardResult.ShowView(showConfig)
        end)
    end
end