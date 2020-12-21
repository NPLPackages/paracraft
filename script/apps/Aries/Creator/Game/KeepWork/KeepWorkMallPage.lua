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

commonlib.setfield("MyCompany.Aries.Creator.Game.KeepWork.KeepWorkMallPage", KeepWorkMallPage);
local page;
local level_to_index = {}
local menu_item_index = 0
local cur_classifyId = 0
local bean_gsid = 998;
local coin_gsid = 888
local menu_node_data = {}
KeepWorkMallPage.isOpen = false
KeepWorkMallPage.all_mod_list = {}

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
	page.OnClose = KeepWorkMallPage.CloseView
	page.OnCreate = KeepWorkMallPage.OnCreate

end

function KeepWorkMallPage.OnCreate()
	-- local TreeViewNode = page:GetNode("item_gridviewtreeview");
	-- if TreeViewNode then
	-- 	local uiobject = ParaUI.GetUIObject(TreeViewNode.control.name)
	-- 	local VScrollBar = uiobject:GetChild("VScrollBar")
	-- 	VScrollBar.visible = false
	-- 	-- KeepWorkMallPage.OnRefresh()
	-- 	TreeViewNode.control:RefreshUI()
	-- end	

	KeepWorkMallPage.RefreshBeanNum()
end

function KeepWorkMallPage.Show()
	if System.options.isCodepku then
		return
	end

    if(GameLogic.GetFilters():apply_filters('is_signed_in'))then
        KeepWorkMallPage.ShowView()
        return
	end
	GameLogic.GetFilters():apply_filters('is_signed_in', L"请先登录", function(result)
		if result == true then
			commonlib.TimerManager.SetTimeout(function()
				KeepWorkMallPage.ShowView()
			end, 500)
        end
	end)
end

function KeepWorkMallPage.ShowView()
	KeepWorkMallPage.isOpen = true
	keepwork.mall.menus.get({
		cache_policy,
		platform =  1,
	},function(err, msg, data)
		if err == 200 and data then
			KeepWorkMallPage.cur_select_level = 1
			KeepWorkMallPage.cur_select_type_index = 1
			KeepWorkMallPage.menu_item_index = KeepWorkMallPage.defaul_select_menu_item_index
			
			level_to_index = {}
			menu_item_index = 0
		
			local level = 1
			KeepWorkMallPage.menu_data_sources = {}
			menu_node_data = {}
			KeepWorkMallPage.HandleMenuData(KeepWorkMallPage.menu_data_sources, data, level)
			local att = ParaEngine.GetAttributeObject();
			local oldsize = att:GetField("ScreenResolution", {1280,720});
	
			local standard_width = 1280
			local standard_height = 720
			
			local view_width = 996
			local view_height = 613
	
			local ratio = view_width/standard_width
	
			local params = {
					url = "script/apps/Aries/Creator/Game/KeepWork/KeepWorkMallPage.html",
					name = "KeepWorkMallPage.Show", 
					isShowTitleBar = false,
					DestroyOnClose = true,
					style = CommonCtrl.WindowFrame.ContainerStyle,
					allowDrag = true,
					enable_esc_key = true,
					zorder = 0,
					app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
					directPosition = true,
						align = "_ct",
						x = -view_width/2,
						y = -view_height/2,
						width = view_width,
						height = view_height,
				};
			System.App.Commands.Call("File.MCMLWindowFrame", params);
	
			GameLogic.GetFilters():add_filter("OnInstallModel", function ()
				commonlib.TimerManager.SetTimeout(function()
					if KeepWorkMallPage.isOpen then
						KeepWorkMallPage.HandleDataSources()
						KeepWorkMallPage.FlushView(true)
					end
				end, 500)
			end);
	
			KeepWorkMallPage.OnChangeTopBt(1);
			KeepWorkMallPage.ChangeMenuType(KeepWorkMallPage.cur_select_level, KeepWorkMallPage.cur_select_type_index);
	
			if(KeepWorkMallPage.show_callback)then
				KeepWorkMallPage.show_callback();
			end
		end
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
        page:Refresh(0.2);
    end
end
function KeepWorkMallPage.ChangeMenuType(level, index)
	KeepWorkItemManager.is_select_show_model = false
	KeepWorkMallPage.cur_select_level = level
	KeepWorkMallPage.cur_select_type_index = index
	KeepWorkMallPage.changeMenuNodeType(KeepWorkMallPage.menu_data_sources, level, index)
	KeepWorkMallPage.OnRefresh()
end

-- 切换到某个类别的时候会自动收起其他的展开的类别 确定是不能收起当前类别
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

-- 切换到某个类别的时候不会自动收起其他的展开的类别 但能收起当前类别
function KeepWorkMallPage.changeMenuNodeType(data, level, index)
	for k, v in pairs(menu_node_data) do
		if type(v) == "table" and v.name == "type" then
			if v.attr.level == level and v.attr.index == index then
				v.attr.expanded = not v.attr.expanded
			end
		end
    end
end

function KeepWorkMallPage.HandleMenuData(parent_t, data, level)
	if level_to_index[level] == nil then
		level_to_index[level] = 0
	end

	
	for k, v in pairs(data) do
		local temp_t = {}
		temp_t.name = v.children == nil and "item" or "type"
		
		temp_t.attr = {}
		-- 中间级别的样式处理
		-- if temp_t.name == "type" then
		-- 	temp_t.attr.isMidleMenu = level > 1
		-- end
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
			KeepWorkMallPage.cur_select_level = parent_t.attr and parent_t.attr.level or 1
			KeepWorkMallPage.cur_select_type_index = parent_t.attr and parent_t.attr.index or 1
			KeepWorkMallPage.GetGoodsData(temp_t.attr.server_data.id)
		end

		if temp_t.name == "type" then
			menu_node_data[#menu_node_data + 1] = temp_t
		end
	end	
end

local tagList = {
	[1] = nil,
	[2] = "latest",
	[3] = "hot",
}

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
		KeepWorkMallPage.grid_data_sources = data.rows
		KeepWorkMallPage.HandleDataSources()
		KeepWorkMallPage.FlushView(only_refresh_grid)
    end)
end

function KeepWorkMallPage.FlushView(only_refresh_grid)
	if only_refresh_grid then
		local gvw_name = "item_gridview";
		local node = page:GetNode(gvw_name);
		pe_gridview.DataBind(node, gvw_name, false);
	else
		KeepWorkMallPage.OnRefresh()
	end
end

function KeepWorkMallPage.HandleDataSources()
	if nil == KeepWorkMallPage.grid_data_sources then
		return
	end
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditModel/EditModelTask.lua");

	for k, v in pairs(KeepWorkMallPage.grid_data_sources) do
			
		v.goods_data = {}
		if v.rule and v.rule.exchangeTargets and v.rule.exchangeTargets[1] then
			local goods = v.rule.exchangeTargets[1].goods
			
			for index, value in ipairs(goods) do
				local goods_data = KeepWorkItemManager.GetItemTemplateById(goods[1].id) or {}
				v.goods_data[#v.goods_data + 1] = goods_data
			end
		end

		v.cost_name = ""
		v.cost = 0
		v.cost_desc = ""
		v.enabled = true
		v.is_show_hot_tag = string.find(v.tags, "hot") and string.find(v.tags, "hot") > 0
		v.is_show_latest_tag = string.find(v.tags, "latest") and string.find(v.tags, "latest") > 0
		v.isLink = v.purchaseUrl ~= nil and v.purchaseUrl ~= ""
		local modelUrl = v.goods_data[1] and v.goods_data[1].modelUrl or ""
		v.isModelProduct = #v.goods_data == 1 and modelUrl ~= ""
		-- 售完或者到达购买上限的情况下不允许购买
		v.buy_txt = "购买"
		if v.rule and v.rule.storage == 0 then
			v.buy_txt = "售完"
			v.enabled = false
			v.is_sell = true
		else
			v.enabled = KeepWorkMallPage.checkIsGetLimit(v)

			if v.isModelProduct then
				local good_data = v.goods_data[1]
				local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(good_data.gsId)
				local bag_nums = copies and copies or 0
				v.bag_nums = bag_nums
				if bag_nums > 0 then
					if GameLogic.IsReadOnly() then
						v.buy_txt = "已拥有"
						v.enabled = false
						v.is_has = true
					else
						v.buy_txt = "使用"
						v.enabled = true
						v.is_use = false
						v.can_use = true
						-- 如果有使用中的显示的需求
						-- local EditModelTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditModelTask");
						-- if EditModelTask and EditModelTask.GetModelFileInHand then
						-- 	local file = EditModelTask:GetModelFileInHand()
						-- 	if file == modelUrl or file == string.format("blocktemplates/%s.%s", good_data.name, good_data.fileType) then
						-- 		v.buy_txt = "已使用"
						-- 		v.enabled = false
						-- 		v.is_use = true
						-- 		v.can_use = false
						-- 	end
						-- end

					end

					--file ：blocktemplates/河马.bmax
					
				end
			end
		end
		
		
		if v.rule and v.rule.exchangeCosts and v.rule.exchangeCosts[1] then
			v.cost = v.rule.exchangeCosts[1].amount
			
			local cost_item_data = KeepWorkItemManager.GetItemTemplateById(v.rule.exchangeCosts[1].id) or {}
			v.cost_name = cost_item_data.name or ""

			if cost_item_data.gsId == bean_gsid then
				v.is_cost_bean = true
			elseif cost_item_data.gsId == coin_gsid then
				v.is_cost_coin = true
			end

			if v.is_cost_bean or v.is_cost_coin then
				v.cost_desc = v.cost
			else
				v.cost_desc = v.cost .. v.cost_name
			end
		elseif v.price then
			v.cost_desc = v.price
		end
	end

	table.sort(KeepWorkMallPage.grid_data_sources, function(a, b)
		return (a.id > b.id);
	end);
end

function KeepWorkMallPage.OnClickBuy(item_data)
	if item_data.isLink then
		ParaGlobal.ShellExecute("open", item_data.purchaseUrl, "", "", 1); 
		return
	end

	if item_data.enabled == false then
		return
	end

	if item_data.isModelProduct and item_data.bag_nums and item_data.bag_nums > 0 then
		if GameLogic.IsReadOnly() then
			return
		end
		local good_data = item_data.goods_data[1]
		local model_url = good_data.modelUrl or ""
		-- model_url = "character/CC/05effect/fire.x"   
		if model_url:match("^https?://") then
			local command = string.format("/install -ext %s -filename %s %s", good_data.fileType, good_data.name, model_url)
			GameLogic.RunCommand(command)
		elseif model_url:match("character/") then         
			GameLogic.RunCommand(string.format("/take BlockModel {tooltip=%q}", model_url));  
			KeepWorkMallPage.HandleDataSources()
			KeepWorkMallPage.FlushView(true)
		end
		
		return
	end

	local KeepWorkStackableItemPage = MyCompany.Aries.Creator.Game.KeepWork.KeepWorkStackableItemPage
	
	if KeepWorkStackableItemPage then
		KeepWorkStackableItemPage.closeView()
	end

	local KeepWorkStackableItem = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/KeepWorkStackableItem.lua");
	KeepWorkStackableItem.InitData(item_data)
	local params = {}
	local seq = 1
	local url = System.localserver.UrlHelper.BuildURLQuery("script/apps/Aries/Creator/Game/KeepWork/KeepWorkStackableItem.html", {});
	System.App.Commands.Call("File.MCMLWindowFrame", {
		-- TODO:  Add uid to url
		url = url, 
		name = "Aries.PurchaseItemWnd", 
		app_key = MyCompany.Aries.app.app_key, 
		isShowTitleBar = false,
		-- isTopLevel = true,
		click_through = false,
		bShow = true,
		allowDrag = true,
		DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
		style = CommonCtrl.WindowFrame.ContainerStyle,
		zorder = 10,
		enable_esc_key = true,
		directPosition = true,
			align = "_ct",
			x = -396/2,
			y = -274/2,
			width = 396,
			height = 274,
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
	if data.isLink then
		return true
	end

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

local top_bt_desc_list = {
	[1] = "全部类别",
	[2] = "最新类别",
	[3] = "热门类别"
}
function KeepWorkMallPage.getTopBtDesc()
	return top_bt_desc_list[KeepWorkMallPage.top_bt_index or 1] or ""
end

function KeepWorkMallPage.CloseView()
	KeepWorkMallPage.isOpen = false
end

function KeepWorkMallPage.Close()
	if page then
		page:CloseWindow();
		KeepWorkMallPage.CloseView()
	end
end

function KeepWorkMallPage.GetPageCtrl()
    return page;
end

-- 展示已购买的模型
function KeepWorkMallPage.ShowBuyModel()
    if nil == KeepWorkItemManager.globalstore then
        return nil
	end

	KeepWorkItemManager.is_select_show_model = true

	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditModel/EditModelTask.lua");
	local is_handle_list = #KeepWorkMallPage.all_mod_list > 0
	local list = is_handle_list and KeepWorkMallPage.all_mod_list or KeepWorkItemManager.globalstore
	KeepWorkMallPage.grid_data_sources = {}
    for k,v in pairs(list) do
		if v.fileType == "bmax" then
			if not is_handle_list then
				KeepWorkMallPage.all_mod_list[#KeepWorkMallPage.all_mod_list + 1] = v
			end
			
			local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(v.gsId)
			local bag_nums = copies and copies or 0
			if bag_nums > 0 then
				local data = {}
				data.isModelProduct = true
				-- 售完或者到达购买上限的情况下不允许购买
				data.icon = string.format("Texture/Aries/Creator/keepwork/items/item_%s_32bits.png", v.gsId)
				data.bag_nums = bag_nums
				data.name = v.name
				
				if GameLogic.IsReadOnly() then
					data.buy_txt = "已拥有"
					data.enabled = false
					data.is_has = true
				else
					data.buy_txt = "使用"
					data.enabled = true
					data.can_use = true
					-- 如果有使用中的显示的需求
					-- local EditModelTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditModelTask");
					-- if EditModelTask and EditModelTask.GetModelFileInHand then
					-- 	local file = EditModelTask:GetModelFileInHand()
					-- 	if file == string.format("blocktemplates/%s.%s", data.name, v.fileType) then
					-- 		data.buy_txt = "已使用"
					-- 		data.enabled = false
					-- 		data.is_use = true
					-- 		data.can_use = false
					-- 	end
					-- end
				end
	
				KeepWorkMallPage.grid_data_sources[#KeepWorkMallPage.grid_data_sources + 1] = data
			end
        end
	end

	KeepWorkMallPage.cur_select_level = 0
	KeepWorkMallPage.cur_select_type_index = 0
	KeepWorkMallPage.FlushView()
end

function KeepWorkMallPage.RefreshBeanNum()
	local TreeViewNode = page:GetNode("bean_label");

    local template = KeepWorkItemManager.GetItemTemplate(bean_gsid);
    local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(bean_gsid)
    copies = copies or 0;
	page:SetValue("bean_label", copies)
end