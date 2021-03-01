--[[
Title: code behind for page TableGetItem.html
Author(s): yangguiyi
Date: 2020/7/21
Desc:  script/apps/Aries/Creator/Game/Tasks/TurnTable/TableGetItem.html
Use Lib:
-------------------------------------------------------
local TableGetItem = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TurnTable/TableGetItem.lua");
TableGetItem.Show();
-------------------------------------------------------
]]
local TurnTable = NPL.export();
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");

local page;
local item_data
local item_name;
local buy_num = 1
local is_vip = false
local is_need_vip = true
local my_bean, my_coin

local bean_gsid = 998;
local coin_gsid = 888
local bean_gid = 10
local is_cost_bean = true
local DockTipPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockTipPage.lua");

function TableGetItem.OnInit(data)
	page = document:GetPageCtrl();

	item_data = data
end

function TableGetItem.IsShowModelDesc()
	return item_data.isModelProduct
end

function TableGetItem.Show(data)
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/TurnTable/TableGetItem.html",
        name = "TableGetItem.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = -1,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,
        
        align = "_ct",
        x = -700/2,
        y = -662/2,
        width = 700,
        height = 662,
    };
    print("bbbbbbbbbbbbbbbbbbbbbbb")
    System.App.Commands.Call("File.MCMLWindowFrame", params);

end

function TableGetItem.OnOK()
	local exchange_result = item_data.exchangeResult or {}
	local gain_list = exchange_result.gainList or {}

	-- local DockTipPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockTipPage.lua");
	for key, value in pairs(gain_list) do
		local item = value or {}
		local goods_info = item.goodsInfo
		local gsid = goods_info.gsId or 0
	
		local amount = item.amount
		local isModel = goods_info.modelUrl ~= nil and goods_info.modelUrl ~= ""
		if not isModel then
			DockTipPage.GetInstance():PushGsid(gsid,amount);
		end
		
	end

end

function TableGetItem.OpenCrteate()
	page:CloseWindow();
	if(mouse_button == "right") then
		last_page_ctrl = GameLogic.GetFilters():apply_filters('show_console_page')
	else
		-- the new version
		last_page_ctrl = GameLogic.GetFilters():apply_filters('show_create_page')
	end
end

function TableGetItem.OpenHome()
	page:CloseWindow();
	GameLogic.RunCommand("/loadworld home");
end