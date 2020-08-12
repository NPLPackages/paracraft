--[[
Title: KeepWorkMallPage
Author(s): yangguiyi
Date: 2020/7/14
Desc:  
Use Lib:
-------------------------------------------------------
local KeepWorkMallPage = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/KeepWorkMallPage.lua");
KeepWorkMallPage.Show();
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");

local KeepWorkMallPage = NPL.export();
local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");

local page;
local level_to_index = {}
local menu_item_index = 0
local cur_classifyId = 0
KeepWorkMallPage.menu_data_sources = {}
KeepWorkMallPage.menu_data_sources = {
	{
		name="type",attr={category="command",text="全部一级目录1",select_menu_item_index=1,index=1, expanded = true, level = 1},
		{
			name="type",attr={index=1,type_index=2,category="command",name="cmd",text="全部二级目录1", expanded = true, level = 2},
			{name="item",attr={menu_item_index=1,type_index=2,category="command",name="cmd",text="全部三级目录1",},},
			{name="item",attr={menu_item_index=2,type_index=2,category="command",name="actions",text="全部三级目录2",},},
		},
		{
			name="type",attr={index=2,type_index=2,category="command",name="cmd",text="全部二级目录2", level = 2},
			{name="item",attr={menu_item_index=3,type_index=2,category="command",name="cmd",text="全部三级目录3",},},
			{name="item",attr={menu_item_index=4,type_index=2,category="command",name="actions",text="全部三级目录4",},},
		},
	},
	{
		name="type",attr={category="shortcutkey",text="全部一级目录2",select_menu_item_index=1,index=2, level = 1},
		{name="item",attr={menu_item_index=5,type_index=3,category="shortcutkey",name="shortcutkey",text="全部二级目录3",},},
	},
}

KeepWorkMallPage.grid_data_sources = {
	{enabled=true, name="1_1"},{enabled=true, name="1_2"},{enabled=true, name="1_3"},{enabled=true, name="1_4"},{enabled=true, name="1_5"},{enabled=true, name="1_6"},
	{enabled=true, name="1_7"},{enabled=true, name="1_8"},{enabled=true, name="1_9"},{enabled=true, name="1_10"},{enabled=true, name="1_11"},{enabled=true, name="1_12"},
	{enabled=true, name="1_13"},{enabled=true, name="1_14"}
}

KeepWorkMallPage.cur_select_level = 1
KeepWorkMallPage.cur_select_type_index = 1
KeepWorkMallPage.top_bt_index = 1;

KeepWorkMallPage.defaul_select_menu_item_index = 1
KeepWorkMallPage.menu_item_index = KeepWorkMallPage.defaul_select_menu_item_index
function KeepWorkMallPage.OnInit()
	page = document:GetPageCtrl();
end

function KeepWorkMallPage.Show()
	local params = {
			url = "script/apps/Aries/Creator/Game/KeepWork/KeepWorkMallPage.html",
			name = "KeepWorkMallPage.Show", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			zorder = -1,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -650/2,
				y = -450/2,
				width = 650,
				height = 450,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	KeepWorkMallPage.OnChangeTopBt(1);

    keepwork.mall.menus.get({
        cache_policy,
        platform =  1,
    },function(err, msg, data)
		level_to_index = {}
		menu_item_index = 0
	
		local level = 1
		KeepWorkMallPage.menu_data_sources = {}
		KeepWorkMallPage.HandleMenuData(KeepWorkMallPage.menu_data_sources, data, level)
		KeepWorkMallPage.ChangeMenuType(KeepWorkMallPage.cur_select_level, KeepWorkMallPage.cur_select_type_index);
	end)
	

end
function KeepWorkMallPage.OnChangeTopBt(index)
	index = tonumber(index)
    KeepWorkMallPage.top_bt_index = index;
	-- KeepWorkMallPage.OnRefresh()
	KeepWorkMallPage.GetGoodsData()
end
function KeepWorkMallPage.ChangeMenuItem(attr)
	
	local menu_item_index = tonumber(attr.menu_item_index)
	KeepWorkMallPage.menu_item_index = menu_item_index;
	local server_item_data = attr.server_data
	KeepWorkMallPage.GetGoodsData(server_item_data.id)
end
function KeepWorkMallPage.OnRefresh()
    if(page)then
        page:Refresh(0.05);
    end
end
function KeepWorkMallPage.ChangeMenuType(level, index)
	KeepWorkMallPage.cur_select_level = level
	KeepWorkMallPage.cur_select_type_index = index
	KeepWorkMallPage.ExpandedNode(KeepWorkMallPage.menu_data_sources, level, index)
    KeepWorkMallPage.OnRefresh()
end

function KeepWorkMallPage.ExpandedNode(data, level, index)
	for k, v in pairs(data) do
		if type(v) == "table" and v.name == "type" then
			if v.attr.level == level and v.attr.index == index then
				for k2, v2 in pairs(data) do
					if type(v2) == "table" and v2.name == "type" then
						v2.attr.expanded = k2 == k
					end
				end
				return true
			else
				local find_result = KeepWorkMallPage.ExpandedNode(v, level, index)
				if (find_result) then
					for k2, v2 in pairs(data) do
						if type(v2) == "table" and v2.name == "type" then
							v2.attr.expanded = k2 == k
						end
					end
					return true
				end
			end
		end
    end

	return false
end

function KeepWorkMallPage.HandleMenuData(parent_t, data, level)
	if level_to_index[level] == nil then
		level_to_index[level] = 0
	end
	
	for k, v in pairs(data) do
		local temp_t = {}
		temp_t.name = v.children == nil and "item" or "type"
		temp_t.attr = {}
		temp_t.attr.server_data = v
		temp_t.attr.type_index = 1
		temp_t.attr.text = v.name
		temp_t.attr.level = level
		level_to_index[level] = level_to_index[level] + 1
		-- 有子节点 说明还需要展开
		if v.children then
			temp_t.attr.index = level_to_index[level]

			local next_level = level + 1
			KeepWorkMallPage.HandleMenuData(temp_t, v.children, next_level)			
		else
			menu_item_index = menu_item_index + 1
			temp_t.attr.menu_item_index = menu_item_index
		end

		parent_t[k] = temp_t

		-- 记录默认展示的索引
		if temp_t.attr.menu_item_index and temp_t.attr.menu_item_index == KeepWorkMallPage.defaul_select_menu_item_index then
			KeepWorkMallPage.cur_select_level = parent_t.attr.level
			KeepWorkMallPage.cur_select_type_index = parent_t.attr.index
			KeepWorkMallPage.GetGoodsData(temp_t.attr.server_data.id)
		end
	end	
end

local tagList = {
	[1] = nil,
	[2] = "latest",
	[3] = "hot",
}

-- {
--     bean=0,
--     coin=0,
--     createdAt="2020-07-21T08:50:28.000Z",
--     description="测试兑换10001",
--     icon="http://qiniu-public-dev.keepwork.com/admin5-6bb607b0-d172-11ea-a1c7-af49ce54d063",
--     id=12,
--     isVip=false,
--     method=0,
--     name="测试兑换10001",
--     rule={
--       createdAt="2020-06-04T08:18:35.000Z",
--       desc="测试兑换10001",
--       exId=10001,
--       exchangeCosts={ { amount=1, id=15 } },
--       exchangeTargets={
--         {
--           goods={
--             {
--               amount=1,
--               goods={
--                 bagId=8,
--                 beans=100000,
--                 canHandsel=true,
--                 canTrade=true,
--                 canUse=true,
--                 coins=100000,
--                 createdAt="2020-06-04T08:16:07.000Z",
--                 dayMax=100000,
--                 deleted=false,
--                 desc="测试物品10003",
--                 destoryAfterUse=true,
--                 expiredRules=1,
--                 expiredSeconds=0,
--                 gsId=10003,
--                 icon="none",
--                 id=16,
--                 max=100000,
--                 name="测试物品10003",
--                 stackable=true,
--                 typeId=8,
--                 updatedAt="2020-06-04T09:10:14.000Z",
--                 weekMax=100000 
--               },
--               id=16 
--             },
--             {
--               amount=1,
--               goods={
--                 bagId=9,
--                 beans=100000,
--                 canHandsel=true,
--                 canTrade=true,
--                 canUse=true,
--                 coins=100000,
--                 createdAt="2020-06-04T08:19:34.000Z",
--                 dayMax=100000,
--                 deleted=false,
--                 desc="测试物品10004",
--                 destoryAfterUse=true,
--                 expiredRules=1,
--                 expiredSeconds=0,
--                 gsId=10004,
--                 icon="none",
--                 id=17,
--                 max=100000,
--                 name="测试物品10004",
--                 stackable=true,
--                 typeId=8,
--                 updatedAt="2020-06-04T09:10:27.000Z",
--                 weekMax=100000 
--               },
--               id=17 
--             } 
--           },
--           probability=100 
--         } 
--       },
--       greedy=false,
--       icon="http://qiniu-public-dev.keepwork.com/admin5-6bb607b0-d172-11ea-a1c7-af49ce54d063",
--       id=27,
--       name="测试兑换10001",
--       preconditions={ { amount=6, id=12, op="gte" } },
--       storage=-1,
--       updatedAt="2020-07-29T08:06:41.000Z" 
--     },
--     ruleId=10001,
--     showAt=2,
--     sn=0,
--     status=1,
--     tags="latest,hot",
--     updatedAt="2020-08-10T05:20:00.000Z" 
--   },

function KeepWorkMallPage.GetGoodsData(classifyId, keyword, only_refresh_grid)
	-- classifyId 类别id
	-- tag hot，latest 火热 最新
	-- keyword 按商品名称模糊匹配
	if classifyId then
		cur_classifyId = classifyId
	else
		classifyId = cur_classifyId
	end
	

	local top_bt_index = KeepWorkMallPage.top_bt_index
	local tag = tagList[top_bt_index]
    keepwork.mall.goods.get({
        classifyId = classifyId,
        tag = tag,
        keyword = keyword,
        platform = 1,
        headers = {
            ["x-per-page"] = 1000,
            ["x-page"] = 1,
        }
    },function(err, msg, data)
		for k, v in pairs(data.rows) do
			v.cost_name = ""
			v.cost = 0
			v.cost_desc = ""
			v.tag_desc = ""
			v.enabled = true
			v.vip_desc = v.isVip and "vip" or ""

			-- 售完或者到达购买上限的情况下不允许购买
			v.buy_txt = "购买"
			if v.rule and v.rule.storage == 0 then
				v.buy_txt = "售完"
				v.enabled = false
			end

			v.enabled = KeepWorkMallPage.checkIsGetLimit(v)

			if v.tags == "latest" then
				v.tag_desc = "最新"
			elseif v.tags == "hot" then
				v.tag_desc = "热门"
			elseif v.tags == "latest,hot" or v.tags == "hot,latest" then
				v.tag_desc = "最新热门"
			end
			
			if v.rule and v.rule.exchangeCosts and v.rule.exchangeCosts[1] then
				v.cost = v.rule.exchangeCosts[1].amount

				local cost_item_data = KeepWorkItemManager.GetItemTemplateById(v.rule.exchangeCosts[1].id) or {}
				v.cost_name = cost_item_data.name or ""
				v.cost_desc = v.cost .. v.cost_name				
			end
			
		end

		KeepWorkMallPage.grid_data_sources = data.rows
		if only_refresh_grid then
			local gvw_name = "item_gridview";
			local node = page:GetNode(gvw_name);
			pe_gridview.DataBind(node, gvw_name, false);
		else
			KeepWorkMallPage.OnRefresh()
		end
		KeepWorkMallPage.OnRefresh()
    end)
end

function KeepWorkMallPage.OnClickBuy(item_data)
	item_data = commonlib.Json.Encode(item_data);
	local params = {}
	local seq = 1
	local url = System.localserver.UrlHelper.BuildURLQuery("script/apps/Aries/Creator/Game/KeepWork/KeepWorkStackableItem.html", {item_data = item_data});
	System.App.Commands.Call("File.MCMLWindowFrame", {
		-- TODO:  Add uid to url
		url = url, 
		name = "Aries.PurchaseItemWnd", 
		app_key = MyCompany.Aries.app.app_key, 
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

function KeepWorkMallPage.notEnoughBean()
	item_data = commonlib.Json.Encode(item_data);
	local params = {}
	local seq = 1
	local url = System.localserver.UrlHelper.BuildURLQuery("script/apps/Aries/Creator/Game/KeepWork/KeepWorkBeanNoEnough.html", {item_data = item_data});
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
-- 判断是否达到购买限制
-- 条件 
-- 1 背包数量已经等于或者大于要购买的物品的购买限制数量时 不允许购买
-- 2 背包数量还没达到限制的购买数量 但买了之后会超过限制数量 必须看是否允许贪婪 若允许 则可以购买 但后买后的数量依然不能超过限制数量
--   若不允许 则不允许购买
function KeepWorkMallPage.checkIsGetLimit(data)
	if nil == data.rule then
		return false
	end
	local exchange_targets = data.rule.exchangeTargets or {}
	local greedy = data.rule.greedy
	local target_list = exchange_targets[1].goods or {}
	for k, v in pairs(target_list) do
		local goods_data = KeepWorkItemManager.GetItemTemplateById(v.id) or {}
		local max = goods_data.max or 0
		
		local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(goods_data.gsId)
		local bag_nums = copies and copies or 0
		
		if bag_nums >= max then
			return false
		end

		if bag_nums + v.amount > max then
			-- 这种情况下要判断是否允许贪婪 不允许贪婪则不允许购买
			if greedy == false then
				return false
			end
		end
	end

	return true
end