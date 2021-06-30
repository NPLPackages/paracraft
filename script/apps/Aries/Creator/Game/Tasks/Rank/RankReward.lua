--[[
Title: RankReward
Author(s): yangguiyi
Date: 2021/2/2
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Rank/RankReward.lua").Show();
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local RankReward = NPL.export();

local server_time = 0
local page
local modele_bag_id = 0
RankReward.RewardData = {
    {name="第1名"},
    {name="第2名"},
    {name="第3名"},
    {name="第4-10名"},
    {name="第11-50名"},
    {name="第51-200名"},
}
function RankReward.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = RankReward.CloseView
end

function RankReward.Show(begain_id)
    -- begain_id = 31000
    RankReward.BegainId = begain_id
    RankReward.ShowView()
end

function RankReward.ShowView()
    if page and page:IsVisible() then
        return
    end

    local bagNo = 1007;
    for _, bag in ipairs(KeepWorkItemManager.bags) do
        if (bagNo == bag.bagNo) then 
            modele_bag_id = bag.id;
            break;
        end
    end

    RankReward.HandleData()
    
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Rank/RankReward.html",
        name = "RankReward.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 0,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,
        
        align = "_ct",
        x = -679/2,
        y = -434/2,
        width = 679,
        height = 434,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function RankReward.FreshView()
    local parent  = page:GetParentUIObject()
end

function RankReward.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
    RankReward.FreshView()
end

function RankReward.CloseView()
    RankReward.ClearData()
end

function RankReward.ClearData()
end

function RankReward.HandleData()
    local exid = RankReward.BegainId or 0
    for i, v in ipairs(RankReward.RewardData) do
        v.goods_data = {}
        local exchange_data = KeepWorkItemManager.GetExtendedCostTemplate(exid)
        
        if exchange_data and exchange_data.exchangeTargets and exchange_data.exchangeTargets[1] then
            -- for i2, v2 in ipairs(exchange_data.exchangeTargets[1].goods) do
            --     v.goods_data[#v.goods_data + 1] = v2
            -- end
            v.goods_data = exchange_data.exchangeTargets[1].goods
        end
        exid = exid + 1
    end
end

function RankReward.IsRoleModel(item_data)
	if item_data and item_data.bagId == modele_bag_id then
		return true
	end

	return false
end