--[[
Title: code behind for page KeepWorkStackableItem.html
Author(s): yangguiyi
Date: 2020/7/21
Desc:  script/apps/Aries/Creator/Game/KeepWork/KeepWorkStackableItem.html
Use Lib:
-------------------------------------------------------
-------------------------------------------------------
]]
local KeepWorkStackableItemPage = {};
commonlib.setfield("MyCompany.Aries.Creator.Game.KeepWork.KeepWorkStackableItemPage", KeepWorkStackableItemPage);
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

function KeepWorkStackableItemPage.OnInit(data)
	page = document:GetPageCtrl();
	item_data = data

	-- 获取知识豆数量
	
    local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(bean_gsid)
	my_bean = copies or 0;

    local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(coin_gsid)
	my_coin = copies or 0;
	
	local rule = item_data.rule or {}
	local exchange_costs = rule.exchangeCosts or {}
	local gid = exchange_costs[1] and exchange_costs[1].id or 0
	is_cost_bean = bean_gid == gid
	
	local gsid = 10;
	local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(gsid)
	is_vip = copies and copies > 0
	is_need_vip = item_data.isVip

	buy_num = 1
end

function KeepWorkStackableItemPage.GetBuyDesc1()
	if is_need_vip and not is_vip then
		local desc = "VIP专享，你还不是VIP，是否要开通VIP？"
		return desc
	end

	local rule = item_data.rule or {}

	local exchange_costs = rule.exchangeCosts or {}
	local price = exchange_costs[1] and exchange_costs[1].amount or 0
	local result_price = price * buy_num
	local good_name = item_data.name

	local id = exchange_costs[1] and exchange_costs[1].id or 0
	local cost_data = KeepWorkItemManager.GetItemTemplateById(id) or {}
	local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(cost_data.gsId)
	local my_money = copies and copies or 0

	local cost_name = ""
	if cost_data and cost_data.name then
		cost_name = cost_data.name
	end

	local exchange_targets = rule.exchangeTargets or {}
	local target_num = exchange_targets[1] and exchange_targets[1].goods[1].amount or 0
	local result_target_num = target_num * buy_num

	
	
	local desc = string.format("需要%d个%s，你现在有%d个%s", result_price, cost_name, my_money, cost_name)
	
	return desc
end

function KeepWorkStackableItemPage.OnOK()
	if is_need_vip and not is_vip then
		ParaGlobal.ShellExecute("open", "explorer.exe", "https://keepwork.com/vip", "", 1); 
		_guihelper.MessageBox("开通VIP后点击【确定】，刷新VIP状态。", function()
			page:CloseWindow()
			KeepWorkItemManager.LoadItems()
		end)
		
		return
	end


	-- local my_money = is_cost_bean and my_bean or my_coin
	local rule = item_data.rule or {}

	local exchange_costs = rule.exchangeCosts or {}
	local price = exchange_costs[1] and exchange_costs[1].amount or 0
	local result_price = price * buy_num
	
	-- 判断是否不够钱
	local id = exchange_costs[1] and exchange_costs[1].id or 0
	local cost_data = KeepWorkItemManager.GetItemTemplateById(id) or {}
	local cost_name = cost_data.name or ""
	local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(cost_data.gsId)
	local my_money = copies and copies or 0
	
	if my_money < result_price then
		if cost_data.gsId == bean_gsid then
			KeepWorkStackableItemPage.openBeanNoEnoughView()
		elseif cost_data.gsId == coin_gsid then
			KeepWorkStackableItemPage.openCoinNoEnoughView()
		else
			local need_num = result_price - my_money
			_guihelper.MessageBox(string.format("您的%s不足，还需要%d个%s", cost_name, need_num, cost_name))
		end
		
		return
	end	

	print("买买买", item_data.id, buy_num)
	local gsid = item_data.id
    keepwork.mall.buy({
        productId = item_data.id,
        quantity = buy_num,
        platform = 1,
        headers = {
            ["Content-Type"] = 1,
            -- ["Authorization"] = " Bearer aa",
        }
	},function(err, msg, data)
		if err == 200 then
			_guihelper.MessageBox("购买成功!");
			KeepWorkItemManager.LoadItems()
			page:CloseWindow()
		elseif err == 500 then
			_guihelper.MessageBox("购买失败!");
			-- if is_cost_bean then
			-- 	KeepWorkStackableItemPage.openBeanNoEnoughView()
			-- else
			-- 	KeepWorkStackableItemPage.openCoinNoEnoughView()
			-- end

		end
		-- KeepWorkMallPage.HandleGoodsData(data)
    end)
end

function KeepWorkStackableItemPage.setBuyNum(num)
	buy_num = num or 1
end

function KeepWorkStackableItemPage.getBuyBtDesc()
	local desc = "马上购买"
	-- is_need_vip = true

	
	-- 如果需要vip 但自己并不是vip
	if is_need_vip and not is_vip then
		desc = "马上开通"
	end
	
	return desc
end

function KeepWorkStackableItemPage.openBeanNoEnoughView()

	local params = {}
	local seq = 1
	System.App.Commands.Call("File.MCMLWindowFrame", {
		-- TODO:  Add uid to url
		url = "script/apps/Aries/Creator/Game/KeepWork/KeepWorkBeanNoEnough.html", 
		name = "KeepWorkStackableItemPage.openBeanNoEnoughView", 
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		isShowTitleBar = false,
		-- isTopLevel = true,
		allowDrag = true,
		DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
		style = CommonCtrl.WindowFrame.ContainerStyle,
		zorder = 10,
		enable_esc_key = true,
		directPosition = true,
			align = "_ct",
			x = -466/2,
			y = -400/2,
			width = 466,
			height = 355,
	});
end

function KeepWorkStackableItemPage.openCoinNoEnoughView()
	local params = {}
	local seq = 1
	local url = System.localserver.UrlHelper.BuildURLQuery("script/apps/Aries/Creator/Game/KeepWork/KeepWorkCoinNoEnough.html", {});
	System.App.Commands.Call("File.MCMLWindowFrame", {
		-- TODO:  Add uid to url
		url = url, 
		name = "Aries.PurchaseItemWnd", 
		app_key = MyCompany.Aries.app.app_key, 
		isShowTitleBar = false,
		isTopLevel = true,
		allowDrag = true,
		DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
		style = CommonCtrl.WindowFrame.ContainerStyle,
		zorder = 10,
		enable_esc_key = true,
		directPosition = true,
			align = "_ct",
			x = -466/2,
			y = -400/2,
			width = 466,
			height = 355,
	});
end

function KeepWorkStackableItemPage.canChooseNums()
	local rule = item_data.rule or {}
	local exchange_targets = rule.exchangeTargets or {}
	local id = exchange_targets[1] and exchange_targets[1].goods[1].id or 0
	local cost_item_data = KeepWorkItemManager.GetItemTemplateById(id) or {}

	if cost_item_data.max and cost_item_data.max > 1 then
		return true
	end

	return false
end