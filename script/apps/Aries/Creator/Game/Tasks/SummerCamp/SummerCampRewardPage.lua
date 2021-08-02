--[[
author:yangguiyi
date:
Desc:
use lib:
local SummerCampRewardPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampRewardPage.lua") 
SummerCampRewardPage.ShowView()
]]
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local httpwrapper_version = HttpWrapper.GetDevVersion();
local SummerCampRewardPage = NPL.export()

local page = nil

SummerCampRewardPage.ItemData = {
    {gsid = 70010, item_bg="Texture/Aries/Creator/keepwork/SummerCamp/item_1_237x451_32bits.png#0 0 237 451"},
    {gsid = 70011, item_bg="Texture/Aries/Creator/keepwork/SummerCamp/item_2_237x451_32bits.png#0 0 237 451"},
    {gsid = 70012, item_bg="Texture/Aries/Creator/keepwork/SummerCamp/item_3_237x451_32bits.png#0 0 237 451"},
    {gsid = 70009, item_bg="Texture/Aries/Creator/keepwork/SummerCamp/item_4_237x451_32bits.png#0 0 237 451"},
}

SummerCampRewardPage.RewardData = { {exid=60055},{exid=60056},{exid=60057},{exid=60058} }

function SummerCampRewardPage.OnInit()
    page = document:GetPageCtrl();
    page.OnCreate = SummerCampRewardPage.OnCreate
end

function SummerCampRewardPage.ShowView(parent)
    SummerCampRewardPage.InitData()
    local view_width = 1035
    local view_height = 623

    page = Map3DSystem.mcml.PageCtrl:new({ 
        url = "script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampRewardPage.html" ,
        click_through = false,
    } );
    SummerCampRewardPage._root = page:Create("SummerCampRewardPage.ShowView", parent, "_lt", 0, 0, view_width, view_height)

    return page
end

function SummerCampRewardPage.CloseView()
    -- body
end

function SummerCampRewardPage.InitData()
    for key, v in pairs(SummerCampRewardPage.ItemData) do
        v.has_get = QuestAction.CheckSummerTaskFinish(v.gsid)
        v.state_icon = SummerCampRewardPage.GetStateIcon(v.has_get)
    end

    for index, v in ipairs(SummerCampRewardPage.RewardData) do
        v.icon = QuestAction.GetGiftIcon(index)
        v.reward_icon = string.format("Texture/Aries/Creator/keepwork/SummerCamp/reward_%s_112x78_32bits.png#0 0 112 78", index)
        v.reward_icon_uiname = "summer_reward_icon_" .. index
    end
end

function SummerCampRewardPage.GetStateIcon(has_get)
    if has_get then
        return "Texture/Aries/Creator/keepwork/SummerCamp/bt_yida_125x60_32bits.png#0 0 125 60"
    end

    return "Texture/Aries/Creator/keepwork/SummerCamp/bt_weida_125x60_32bits.png#0 0 125 60"
end

function QuestAction.GetGiftIcon(index)
    local has_get = QuestAction.GetSummerRewardHasGet(index)
    if has_get then
        return string.format("Texture/Aries/Creator/keepwork/SummerCamp/gift_%s_2_128x128_32bits.png#0 0 128 128", index)
    end

    local certificate_num = QuestAction.GetCertificateNum()
    if certificate_num >= index then
        return string.format("Texture/Aries/Creator/keepwork/SummerCamp/gift_%s_1_128x128_32bits.png#0 0 128 128", index)
    end

    return string.format("Texture/Aries/Creator/keepwork/SummerCamp/gift_%s_0_128x128_32bits.png#0 0 128 128", index)
end

function SummerCampRewardPage.OnCreate()
    for index, v in ipairs(SummerCampRewardPage.RewardData) do
        local ui_object = ParaUI.GetUIObject(v.reward_icon_uiname);
        ui_object.visible = false
    end
end

function SummerCampRewardPage.OnMouseEnter(index)
    local ui_object = ParaUI.GetUIObject("summer_reward_icon_" .. index);
    ui_object.visible = true
end

function SummerCampRewardPage.OnMouseLeave(index)
    local ui_object = ParaUI.GetUIObject("summer_reward_icon_" .. index);
    ui_object.visible = false
end

function SummerCampRewardPage.OnClickGetReward(index)
    local has_get = QuestAction.GetSummerRewardHasGet(index)
    if has_get then
        GameLogic.AddBBS("summer_reward", L"您已领取", 5000, "255 0 0");
        return
    end


    local certificate_num = QuestAction.GetCertificateNum()
    if certificate_num < index then
        GameLogic.AddBBS("summer_reward", L"尚未达成", 5000, "255 0 0");
        return
    end
    
    local reward_data = SummerCampRewardPage.RewardData[index]
    KeepWorkItemManager.DoExtendedCost(reward_data.exid, function()
        QuestAction.SetSummerRewardGet(index, function()
            GameLogic.AddBBS("summer_reward", L"领取成功", 5000, "0 255 0");
            SummerCampRewardPage.InitData()
            page:Refresh(0)

            if index == #SummerCampRewardPage.RewardData then
                local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua");
                Page.ShowUserInfoPage({AvatarDefaulIndex = "right_hand_equipment"});
            end
        end)
    end) 
end