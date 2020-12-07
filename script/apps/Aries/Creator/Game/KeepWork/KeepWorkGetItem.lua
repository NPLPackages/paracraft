--[[
Title: code behind for page KeepWorkGetItem.html
Author(s): yangguiyi
Date: 2020/7/21
Desc:  script/apps/Aries/Creator/Game/KeepWork/KeepWorkGetItem.html
Use Lib:
-------------------------------------------------------
local KeepWorkGetItem = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/KeepWorkGetItem.lua");
KeepWorkGetItem.openBeanNoEnoughView();
-------------------------------------------------------
]]
local KeepWorkGetItem = {};
commonlib.setfield("MyCompany.Aries.Creator.Game.KeepWork.KeepWorkGetItem", KeepWorkGetItem);
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

function KeepWorkGetItem.OnInit(data)
	page = document:GetPageCtrl();

	item_data = data
end

function KeepWorkGetItem.IsShowModelDesc()
	return item_data.isModelProduct
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
-- 	} 
--   }

function KeepWorkGetItem.OnOK()
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

function KeepWorkGetItem.OpenCrteate()
	page:CloseWindow();
	if(mouse_button == "right") then
		-- the new version
		last_page_ctrl = GameLogic.GetFilters():apply_filters('show_create_page')
	else
		last_page_ctrl = GameLogic.GetFilters():apply_filters('show_console_page')
	end
end

function KeepWorkGetItem.OpenHome()
	page:CloseWindow();
	GameLogic.RunCommand("/loadworld home");
end