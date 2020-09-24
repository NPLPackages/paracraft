--[[
Title: code behind for page KeepWorkStackableItem.html
Author(s): yangguiyi
Date: 2020/7/21
Desc:  script/apps/Aries/Creator/Game/KeepWork/KeepWorkStackableItem.html
Use Lib:
-------------------------------------------------------
local KeepWorkStackableItem = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/KeepWorkStackableItem.lua");
KeepWorkStackableItem.openBeanNoEnoughView();
-------------------------------------------------------
]]
local KeepWorkStackableItemPage = {};
commonlib.setfield("MyCompany.Aries.Creator.Game.KeepWork.KeepWorkStackableItemPage", KeepWorkStackableItemPage);
local KeepWorkMallPage = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/KeepWorkMallPage.lua");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
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
local requestOrderTimes = 0
local requestOrderMaxTimes = 10
local orderId = 0

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

	
	
	local desc = string.format("需要%d个%s，你现在有%d个%s,确定要购买吗?", result_price, cost_name, my_money, cost_name)
	
	return desc
end

-- {
-- 	exchangeResult={
-- 	  costList={
-- 		{
-- 		  amount=2,
-- 		  goodsInfo={
-- 			bagId=4,
-- 			beans=1,
-- 			canHandsel=false,
-- 			canTrade=false,
-- 			canUse=false,
-- 			coins=1,
-- 			createdAt="2020-06-01T07:31:06.000Z",
-- 			dayMax=500,
-- 			deleted=false,
-- 			desc="通过活动与任务获得的兑换物。上限500，每天最多可获得50。",
-- 			destoryAfterUse=false,
-- 			expiredRules=1,
-- 			expiredSeconds=0,
-- 			gsId=998,
-- 			icon="0",
-- 			id=10,
-- 			max=2500,
-- 			name="知识豆",
-- 			showAt=1,
-- 			stackable=true,
-- 			typeId=7,
-- 			updatedAt="2020-08-11T06:52:19.000Z",
-- 			weekMax=2500 
-- 		  } 
-- 		} 
-- 	  },
-- 	  gainList={
-- 		{
-- 		  amount=1,
-- 		  goodsInfo={
-- 			bagId=4,
-- 			beans=20,
-- 			canHandsel=false,
-- 			canTrade=false,
-- 			canUse=true,
-- 			coins=98,
-- 			createdAt="2020-06-01T07:48:30.000Z",
-- 			dayMax=9999999999,
-- 			deleted=false,
-- 			desc="用于在世界频道中广播，每条消息消耗1个。",
-- 			destoryAfterUse=true,
-- 			expiredRules=1,
-- 			expiredSeconds=0,
-- 			gsId=10001,
-- 			icon="0",
-- 			id=12,
-- 			max=9999999999,
-- 			name="世界喇叭",
-- 			showAt=1,
-- 			stackable=true,
-- 			typeId=8,
-- 			updatedAt="2020-06-01T08:28:43.000Z",
-- 			weekMax=9999999999 
-- 		  } 
-- 		} 
-- 	  } 
-- 	},
-- 	mOrder={
-- 	  bean=0,
-- 	  coin=0,
-- 	  createdAt="2020-08-12T07:14:25.228Z",
-- 	  id=38,
-- 	  mProductId=1,
-- 	  mProductName="大力丸商品",
-- 	  platform=1,
-- 	  quantity=1,
-- 	  ruleId=100000,
-- 	  state=3,
-- 	  stateLog={ completedAt="2020-08-12T07:14:25.228Z" },
-- 	  updatedAt="2020-08-12T07:14:25.228Z",
-- 	  userId=623 
-- 	} ,
--	icon=""
--   }

function KeepWorkStackableItemPage.OnOK()
	if is_need_vip and not is_vip then
		--[[
		ParaGlobal.ShellExecute("open", "explorer.exe", "https://keepwork.com/vip", "", 1); 
		_guihelper.MessageBox("开通VIP后点击【确定】，刷新VIP状态。", function()
			page:CloseWindow()
			KeepWorkItemManager.LoadItems()
		end)
		]]
		page:CloseWindow()
		GameLogic.GetFilters():apply_filters("VipNotice", true);

		
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
	local is_not_enough = my_money < result_price
	-- is_not_enough = true
	-- cost_data.gsId = 998
	-- cost_data.gsId = 888

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
			-- 订单状态：0：进行中, 1： 购买成功，2: 购买失败
			orderId = data.id
			if data.state == 0 then
				_guihelper.MessageBoxClass.CheckShowCallback = KeepWorkStackableItemPage.openMessageBox
				_guihelper.MessageBox("订单请求中，请稍等...", KeepWorkStackableItemPage.openMessageBox, _guihelper.MessageBoxButtons.OK);

				HttpWrapper.Create("keepwork.mall.orderResule", "%MAIN%/core/v0/mall/mOrders/" .. orderId, "GET", false)
				requestOrderTimes = 0
				commonlib.TimerManager.SetTimeout(function()
					KeepWorkStackableItemPage.requestOrderResult()
				end, 500)
			elseif data.state == 1 then
				data.icon = item_data.icon
				-- GameLogic.AddBBS("statusBar", L"购买成功!", 5000, "0 255 0");
				KeepWorkStackableItemPage.openGetItemView(data)
				KeepWorkItemManager.LoadItems(nil, function ()
					if KeepWorkMallPage.isOpen then
						KeepWorkMallPage.GetGoodsData()
					end
					
				end)

				page:CloseWindow()
			else

				if is_not_enough then
					if cost_data.gsId == bean_gsid then
						page:CloseWindow()
						KeepWorkStackableItemPage.openBeanNoEnoughView()
					elseif cost_data.gsId == coin_gsid then
						page:CloseWindow()
						KeepWorkStackableItemPage.openCoinNoEnoughView()
					else
						local need_num = result_price - my_money
						_guihelper.MessageBox(string.format("您的%s不足，还需要%d个%s", cost_name, need_num, cost_name))
					end
				else
					GameLogic.AddBBS("statusBar", L"购买失败!", 5000, "0 255 0");
				end	
			end

		elseif err == 500 then
			_guihelper.MessageBox("购买失败!");
		else
			if is_not_enough then
				if cost_data.gsId == bean_gsid then
					page:CloseWindow()
					KeepWorkStackableItemPage.openBeanNoEnoughView()
				elseif cost_data.gsId == coin_gsid then
					page:CloseWindow()
					KeepWorkStackableItemPage.openCoinNoEnoughView()
				else
					local need_num = result_price - my_money
					_guihelper.MessageBox(string.format("您的%s不足，还需要%d个%s", cost_name, need_num, cost_name))
				end
			else
				GameLogic.AddBBS("statusBar", L"购买失败!", 5000, "0 255 0");
			end	
		end
    end)
end

function KeepWorkStackableItemPage.openMessageBox()
	commonlib.TimerManager.SetTimeout(function()
		_guihelper.MessageBoxClass.CheckShowCallback = KeepWorkStackableItemPage.openMessageBox
	end, 1)
	
	_guihelper.MessageBox("订单请求中，请稍后...", KeepWorkStackableItemPage.openMessageBox, _guihelper.MessageBoxButtons.OK);
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
			x = -400/2,
			y = -216/2,
			width = 400,
			height = 216,
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
			x = -400/2,
			y = -216/2,
			width = 400,
			height = 216,
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

function KeepWorkStackableItemPage.getGoodName()
	return item_data and item_data.name or ""
end

function KeepWorkStackableItemPage.openGetItemView(data)
	-- data.icon = "Texture/Aries/Creator/keepwork/items/item_10001_32bits.png"
	data = commonlib.Json.Encode(data);
	local url = System.localserver.UrlHelper.BuildURLQuery("script/apps/Aries/Creator/Game/KeepWork/KeepWorkGetItem.html", {item_data = data});
	System.App.Commands.Call("File.MCMLWindowFrame", {
		-- TODO:  Add uid to url
		url = url, 
		name = "keepWork.GetItem", 
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
			x = -400/2,
			y = -304/2,
			width = 400,
			height = 304,
	});
end

function KeepWorkStackableItemPage.closeView()
	page:CloseWindow()
end

function KeepWorkStackableItemPage.requestOrderResult()
	requestOrderTimes = requestOrderTimes + 1
	if requestOrderTimes > requestOrderMaxTimes then
		-- 关闭弹窗
		_guihelper.CloseMessageBox()
		_guihelper.MessageBoxClass.CheckShowCallback = nil
		-- 确保不会因为延时出现时间差的问题
		commonlib.TimerManager.SetTimeout(function()
			_guihelper.MessageBoxClass.CheckShowCallback = nil
		end, 10)

		GameLogic.AddBBS("statusBar", L"购买失败!请稍后重试", 5000, "0 255 0");
		return
	end
	GameLogic.AddBBS("statusBar", L"订单请求中，请稍等...", 5000, "0 255 0");
	
	
	KeepworkService:GetToken()
    keepwork.mall.orderResule({
        headers = {
			["Authorization"] = format("Bearer %s", token),
        }
	},function(err, msg, data)
		if err == 200 then
			if data.state == 0 then
				commonlib.TimerManager.SetTimeout(function()
					KeepWorkStackableItemPage.requestOrderResult()
				end, 500)
			elseif data.state == 1 then
				-- 关闭弹窗
				GameLogic.AddBBS("statusBar", L"订单请求成功", 5000, "0 255 0");
				_guihelper.CloseMessageBox()
				_guihelper.MessageBoxClass.CheckShowCallback = nil
				-- 确保不会因为延时出现时间差的问题
				commonlib.TimerManager.SetTimeout(function()
					_guihelper.MessageBoxClass.CheckShowCallback = nil
				end, 10)

				data.icon = item_data.icon
				data.isModelProduct = item_data.isModelProduct
				-- GameLogic.AddBBS("statusBar", L"购买成功!", 5000, "0 255 0");
				KeepWorkStackableItemPage.openGetItemView(data)
				KeepWorkItemManager.LoadItems()
				page:CloseWindow()
			else
				GameLogic.AddBBS("statusBar", L"购买失败!", 5000, "0 255 0");
			end
		
		end
	end)
end