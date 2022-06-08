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

NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerAssetFile.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerSkins.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
local PlayerSkins = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerSkins");
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");

commonlib.setfield("MyCompany.Aries.Creator.Game.KeepWork.KeepWorkMallPage", KeepWorkMallPage);
local page;
local level_to_index = {}
local menu_item_index = 0
local cur_classifyId = nil
local bean_gsid = 998;
local coin_gsid = 888;

ENUM_OF_GSID = {
	-- 皮肤碎片
	FRAGMENT_GSID = 10006,
	BEAN_ID = 998,
}

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
	{enabled=true, name="1_1",invented = true},{enabled=true, name="1_2",invented = true},{enabled=true, name="1_3",invented = true},{enabled=true, name="1_4",invented = true},{enabled=true, name="1_5",invented = true},{enabled=true, name="1_6",invented = true},
	{enabled=true, name="1_7",invented = true},{enabled=true, name="1_8",invented = true},{enabled=true, name="1_9",invented = true},{enabled=true, name="1_10",invented = true},{enabled=true, name="1_11",invented = true},{enabled=true, name="1_12",invented = true}
}

KeepWorkMallPage.cur_select_level = 1
KeepWorkMallPage.cur_select_type_index = 1
KeepWorkMallPage.top_bt_index = 1;

KeepWorkMallPage.defaul_select_menu_item_index = 1
KeepWorkMallPage.menu_item_index = KeepWorkMallPage.defaul_select_menu_item_index
local loadCount = 0
local needLoadCount = 0
local wholeScale = 0.75
local loadElse = true

KeepWorkMallPage.show_state = {
	sell = 1, 			--出售状态
	has = 2, 			-- 已拥有
	can_use = 3, 		-- 可使用
	vip_enabled = 4,	-- vip专属
	sell_out = 5,		-- 售完
}
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
	GameLogic.GetFilters():apply_filters('check_signed_in', L"请先登录", function(result)
		if result == true then
			commonlib.TimerManager.SetTimeout(function()
				KeepWorkMallPage.ShowView()
			end, 500)
        end
	end)
end

local insertAll = false
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
			if not insertAll then
				table.insert(data,1,{platform=1,tag="",sn=1,createdAt="2020-08-10T22:27:54.000Z",updatedAt="2022-04-13T03:07:35.000Z",id=nil,name="全部",parentId=0,})
				insertAll = true
			end
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
					-- app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key,
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
	
			-- KeepWorkMallPage.OnChangeTopBt(1);
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
	loadElse = false
	KeepWorkMallPage.dataLoaded = false
	local menu_item_index = tonumber(attr.menu_item_index)
	KeepWorkMallPage.menu_item_index = menu_item_index;
	local server_item_data = attr.server_data
	KeepWorkMallPage.GetGoodsData(server_item_data.id)
end

function KeepWorkMallPage.OnRefresh()
    if(page)then
        page:Refresh(0);
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

function KeepWorkMallPage.GetGoodsData(classifyId, keyword, only_refresh_grid,count)
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
	local menuItemIndex = tonumber(KeepWorkMallPage.menu_item_index)
	if menuItemIndex == 1  then
		classifyId  = nil
	end
	local pageCount = 1000
	if count ~= nil then
		pageCount = count
	end
    keepwork.mall.goods.get({
        classifyId = classifyId,
        tag = tag,
        keyword = keyword,
        platform = 1,
		["x-per-page"] = pageCount,
		["x-page"] = 1,
	},function(err, msg, data)
		if tonumber(data.count) > pageCount then
			KeepWorkMallPage.GetGoodsData(classifyId, keyword, only_refresh_grid,tonumber(data.count))
		else
			KeepWorkMallPage.grid_data_sources = data.rows
			KeepWorkMallPage.dataLoaded = true
			KeepWorkMallPage.HandleDataSources()
			KeepWorkMallPage.FlushView(only_refresh_grid)
		end
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
	-- System.User.isVip = true
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditModel/EditModelTask.lua");
	-- 换装背包id
    local bagId, bagNo = 0, 1007;
    for _, bag in ipairs(KeepWorkItemManager.bags) do
        if (bagNo == bag.bagNo) then 
            bagId = bag.id;
            break;
        end
    end
	local count = 0
	for k, v in pairs(KeepWorkMallPage.grid_data_sources) do
		v.name = commonlib.GetLimitLabel(v.name,20)
		v.goods_data = {}
		if v.rule and v.rule.exchangeTargets and v.rule.exchangeTargets[1] then
			local goods = v.rule.exchangeTargets[1].goods			
			for index, value in ipairs(goods) do
				
				local goods_data = KeepWorkMallPage.GetItemTemplate(goods[1]) or {}
				v.goods_data[#v.goods_data + 1] = goods_data
			end
		end

		v.cost_name = ""
		v.cost = 0
		v.cost_desc = ""
		v.enabled = true
		v.is_show_hot_tag = string.find(v.tags, "hot") and string.find(v.tags, "hot") > 0
		v.is_show_latest_tag = string.find(v.tags, "latest") and string.find(v.tags, "latest") > 0
		v.isLink = v.method == 1  or (v.purchaseUrl ~= nil and v.purchaseUrl ~= "") --购买方式，0：内部购买；1：外部购买
		local modelUrl = v.goods_data[1] and v.goods_data[1].modelUrl or ""
		v.isModelProduct = #v.goods_data == 1 and modelUrl ~= ""
		local downloadUrl =  (modelUrl ~= nil and modelUrl ~= "") and modelUrl or v.modelUrl
		v.vip_enabled = false
		-- 售完或者到达购买上限的情况下不允许购买
		v.hasIcon = v.icon ~= "" and v.icon ~= nil
		v.buy_txt = "购买"
		v.show_state = KeepWorkMallPage.show_state.sell
		v.isLiveModel = v.modelType == "liveModel"
		v.hasPermission = KeepWorkItemManager.CheckHasPermission(v)
		if v.rule and v.rule.storage == 0 then
			v.buy_txt = "售完"
			v.enabled = false
			v.is_sell = true
			v.show_state = KeepWorkMallPage.show_state.sell_out
		else
			v.enabled = KeepWorkMallPage.checkIsGetLimit(v) or v.hasPermission
			if v.hasPermission then
				v.buy_txt = "使用"
				v.enabled = true
				v.is_use = false
				if v.isLink then
					v.can_use = false
				else
					v.can_use = true
				end
				v.show_state = KeepWorkMallPage.show_state.can_use
			else
				v.vip_enabled = true
				v.enabled = false
				v.show_state = KeepWorkMallPage.show_state.vip_enabled
			end
			if v.isModelProduct then
				local good_data = v.goods_data[1]
				local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(good_data.gsId)
				local bag_nums = copies and copies or 0
				
				if good_data.extra and good_data.extra.vip_enabled == true then
					v.vip_enabled = true
					v.enabled = false
					v.show_state = KeepWorkMallPage.show_state.vip_enabled
				end

				if good_data.extra and good_data.extra.icon_size ~= nil then
					v.use_little_icon = true
				end

				-- 如果是vip专属 再判断下是不是vip 如果是vip 那么就直接已拥有的显示
				if v.vip_enabled and System.User.isVip or v.vip_enabled == false then
					bag_nums = 1
				end

				if not good_data.fileType and v.modelType then
					good_data.fileType = v.modelType
				end
				v.modelType = (v.modelType and v.modelType~= "") and v.modelType or good_data.fileType

				v.isLiveModel = good_data.fileType == "liveModel"

				v.bag_nums = bag_nums
				v.is_use_in_player = good_data.bagId == bagId
				if bag_nums > 0 then
					if good_data.bagId == bagId then
						v.buy_txt = "已拥有"
						v.enabled = false
						v.is_has = true
						v.can_use = false
						v.show_state = KeepWorkMallPage.show_state.has
					else
						if GameLogic.GameMode:IsEditor() then
							v.buy_txt = "使用"
							v.enabled = true
							v.is_use = false
							v.can_use = true
							v.show_state = KeepWorkMallPage.show_state.can_use
						else
							v.buy_txt = "已拥有"
							v.enabled = false
							v.is_has = true
							v.can_use = false
							v.show_state = KeepWorkMallPage.show_state.has
						end
					end

					--file ：blocktemplates/河马.bmax
					
				end
			end
		end
		
		
		if v.rule and v.rule.exchangeCosts and v.rule.exchangeCosts[1] then
			v.cost = v.rule.exchangeCosts[1].amount
			
			local cost_item_data = KeepWorkMallPage.GetItemTemplate(v.rule.exchangeCosts[1]) or {}
			v.cost_name = cost_item_data.name or ""

			if cost_item_data.gsId == ENUM_OF_GSID.FRAGMENT_GSID then
				v.is_cost_fragment = true;
			elseif cost_item_data.gsId == bean_gsid then
				v.is_cost_bean = true
			elseif cost_item_data.gsId == coin_gsid then
				v.is_cost_coin = true
			end

			if v.is_cost_bean or v.is_cost_coin or v.is_cost_fragment then
				v.cost_desc = v.cost
			else
				v.cost_desc = v.cost .. v.cost_name
			end
		elseif v.price then
			v.cost_desc = v.price
		end
		

		v.needDownload = (downloadUrl~= nil and downloadUrl ~= "") and not downloadUrl:match("character/") and v.modelType ~= "blocks"
		if v.needDownload then
			count = count + 1
		end
	end

	-- table.sort(KeepWorkMallPage.grid_data_sources, function(a, b)
	-- 	return (a.id > b.id);
	-- end);

	local index = 1
	loadCount = 0
	local loadFunc = nil
	loadFunc = function (item_data)
		if index > #KeepWorkMallPage.grid_data_sources then
			KeepWorkMallPage.FlushView(false)
			return
		end
		index = index + 1
		if item_data.needDownload then
			KeepWorkMallPage.LoadLiveModelXml(item_data,function (data)
				item_data.xmlInfo = data.xmlInfo
				item_data.tooltip = data.tooltip
				item_data.hasLoad = true
				loadCount = loadCount + 1
				if loadCount <= 12 then
					loadFunc(KeepWorkMallPage.grid_data_sources[index])
				else
					KeepWorkMallPage.FlushView(false)
					commonlib.TimerManager.SetTimeout(function ()
						KeepWorkMallPage.LoadElseModel(index)
					end, 1000)
				end
			end)
		else
			loadFunc(KeepWorkMallPage.grid_data_sources[index])
		end
	end
	loadFunc(KeepWorkMallPage.grid_data_sources[index])
end

function KeepWorkMallPage.LoadElseModel(index)
	local loadFunc = nil
	loadFunc = function (item_data)
		if index > #KeepWorkMallPage.grid_data_sources then
			return
		end
		index = index + 1
		if item_data.needDownload then
			KeepWorkMallPage.LoadLiveModelXml(item_data,function (data)
				item_data.xmlInfo = data.xmlInfo
				item_data.tooltip = data.tooltip
				item_data.hasLoad = true
				loadFunc(KeepWorkMallPage.grid_data_sources[index])
			end)
		else
			loadFunc(KeepWorkMallPage.grid_data_sources[index])
		end
	end
	loadFunc(KeepWorkMallPage.grid_data_sources[index])
end

function KeepWorkMallPage.OnClickBuy(item_data)
	if not item_data.invented then
		local name = string.format("click.resource.%s",item_data.name)
		GameLogic.GetFilters():apply_filters("user_behavior", 1, name, {useNoId=true});
	end
	if item_data.isLink then
		ParaGlobal.ShellExecute("open", item_data.purchaseUrl, "", "", 1); 
		return
	end

	if item_data.is_use_in_player and item_data.bag_nums > 0 then
        local page = NPL.load("Mod/GeneralGameServerMod/App/ui/page.lua");
        page.ShowUserInfoPage({ username = System.User.keepworkUsername, });
		return
	end

	if item_data.enabled == false then
		if item_data.vip_enabled and not item_data.is_has then
			GameLogic.IsVip("VipGoods", true, function(result)
				if result then
					if (KeepWorkItemManager.IsVip()) then
						local KeepWorkMallPage = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/KeepWorkMallPage.lua");
						KeepWorkMallPage.HandleDataSources()
						KeepWorkMallPage.FlushView()
					end
				end
			end)

			-- System.User.isVip = true
			-- if (KeepWorkItemManager.IsVip()) then
			-- 	local KeepWorkMallPage = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/KeepWorkMallPage.lua");
			-- 	KeepWorkMallPage.HandleDataSources()
			-- 	KeepWorkMallPage.FlushView()
			-- end
		end
		return
	end

	if (item_data.isModelProduct and item_data.bag_nums and item_data.bag_nums > 0) or item_data.vip_enabled == false then
		if not GameLogic.GameMode:IsEditor() then
			return
		end
		local good_data = item_data.goods_data[1]
		local model_url = good_data and good_data.modelUrl or item_data.modelUrl
		local name = good_data and good_data.name or item_data.name
		local fileType = good_data and good_data.fileType or item_data.modelType
		local filename =  good_data and good_data.desc or item_data.name
		-- model_url = "character/CC/05effect/fire.x"
		if model_url:match("^https?://") then
			NPL.load("(gl)script/apps/Aries/Desktop/GameMemoryProtector.lua");
			local GameMemoryProtector = commonlib.gettable("MyCompany.Aries.Desktop.GameMemoryProtector");
			local downloadList = GameLogic.GetPlayerController():LoadLocalData("mall_download_list",{})
			local needReload = false
			local md5 = GameMemoryProtector.hash_func_md5(item_data)
			if downloadList[name] ~= md5 then
				downloadList[name] = md5
				GameLogic.GetPlayerController():SaveLocalData("mall_download_list",downloadList)
				needReload = true
			end
			local command = string.format("/install -ext %s -reload %s -filename %s %s", fileType,needReload, "onlinestore/"..filename,model_url)
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
		-- app_key = MyCompany.Aries.app.app_key, 
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
		-- app_key = MyCompany.Aries.app.app_key, 
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
		local goods_data = KeepWorkMallPage.GetItemTemplate(v) or {}
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
	insertAll = false
	loadElse = false
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

function KeepWorkMallPage.RefreshBeanNum()
	local TreeViewNode = page:GetNode("bean_label");

    local template = KeepWorkItemManager.GetItemTemplate(bean_gsid);
    local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(bean_gsid)
    copies = copies or 0;
	page:SetValue("bean_label", copies)
end

function KeepWorkMallPage.GetItemTemplate(item)
	if item.gsId then
		return KeepWorkItemManager.GetItemTemplate(item.gsId)
	end

	if item.id then
		return KeepWorkItemManager.GetItemTemplateById(item.id)
	end
end

local needFilterList = {"character/CC/artwar/furnitures/motianlun.x"}
function KeepWorkMallPage.IsInFilterList(filename)
	for key, value in pairs(needFilterList) do
		if tostring(filename) ==value then
			return true
		end
	end
	return false
end

function KeepWorkMallPage.IsSpecialModel(item_data)
	local good_data = item_data and item_data.goods_data and item_data.goods_data[1]
	local model_url = good_data and good_data.modelUrl or (item_data and item_data.modelUrl)
	return KeepWorkMallPage.IsInFilterList(model_url)
end

function KeepWorkMallPage.CanUseCanvas3dIcon(item_data)
	return not item_data.hasIcon or (not item_data.hasIcon and item_data.isLiveModel) or item_data.isLiveModel
end

function KeepWorkMallPage.GetIcon(item_data)
	if not KeepWorkMallPage.dataLoaded then
		return nil
	end
	if item_data.isLiveModel then
		return nil
	else
		local good_data = item_data and item_data.goods_data and item_data.goods_data[1]
		local model_url = good_data and good_data.modelUrl or (item_data and item_data.modelUrl)
		local filename = ""
		if model_url and model_url:match("^https?://") then
			filename = item_data.tooltip
		elseif model_url and model_url:match("character/") then
			filename = model_url
		else
			return nil
		end
		local filepath = PlayerAssetFile:GetValidAssetByString(filename)
		if not filepath and filename then
			filepath = Files.GetTempPath()..filename
		end
	
		local ReplaceableTextures, CCSInfoStr, CustomGeosets;
	
		local skin = nil
		if skin then
			CustomGeosets = skin
		elseif(PlayerAssetFile:IsCustomModel(filepath)) then
			CCSInfoStr = PlayerAssetFile:GetDefaultCCSString()
		elseif(PlayerSkins:CheckModelHasSkin(filepath)) then
			-- TODO:  hard code worker skin here
			ReplaceableTextures = {[2] = PlayerSkins:GetSkinByID(12)};
		end
		return {
			AssetFile = filepath, IsCharacter=true, x=0, y=0, z=0,
			ReplaceableTextures=ReplaceableTextures, CCSInfoStr=CCSInfoStr, CustomGeosets = CustomGeosets
		}
	end
end

--#region 新版商城 20220506

function KeepWorkMallPage.LoadModelFile(item_data,index)
end

function KeepWorkMallPage.LoadLiveModelXml(item_data,cb)
	if item_data.needDownload then
		local good_data = item_data.goods_data[1]
		local model_url = good_data and good_data.modelUrl or (item_data and item_data.modelUrl)
		local name = good_data and good_data.desc or (item_data and item_data.name)
		if not item_data.isLiveModeland and not item_data.modelType then
			return
		end
		local filename = item_data.isLiveModel and "onlinestore/"..name..".blocks.xml" or  "onlinestore/"..name.."."..item_data.modelType
		if model_url:match("^https?://") then
			KeepWorkMallPage.LoadBlocksXmlToLocal(filename,model_url,function (data)
				if data.xmlInfo then
					data.xmlInfo.wholeScale = wholeScale
				end
				cb(data)
			end,item_data.isLiveModel)
		end
	end
end

function KeepWorkMallPage.LoadBlocksXmlToLocal(filename,url,cb,isLiveModel)
	local dest = ""
	if not filename:match("^onlinestore/") then
		dest = Files.WorldPathToFullPath(commonlib.Encoding.Utf8ToDefault(filename))
	else
		dest = Files.GetTempPath()..commonlib.Encoding.Utf8ToDefault(filename)
	end
	local func = function ()
		if isLiveModel then
			KeepWorkMallPage.ParseXml(dest,cb)
		else
			cb({tooltip = commonlib.Encoding.Utf8ToDefault(filename)})
		end
	end
	if(ParaIO.DoesFileExist(dest, true)) then
		func()
	else
		NPL.load("(gl)script/ide/System/localserver/factory.lua");
		local cache_policy = System.localserver.CachePolicy:new("access plus 1 year");
		local ls = System.localserver.CreateStore();
		if(not ls) then
			log("error: failed creating local server resource store \n")
			return
		end
		ls:GetFile(cache_policy, url, function(entry)
			if(entry and entry.entry and entry.entry.url and entry.payload and entry.payload.cached_filepath) then
				ParaIO.CreateDirectory(dest);
				if(ParaIO.CopyFile(entry.payload.cached_filepath, dest, true)) then
					Files.NotifyNetworkFileChange(dest)
					func()
				else
					LOG.std(nil, "warn", "CommandInstall", "failed to copy from %s to %s", entry.payload.cached_filepath, dest);
				end
			end
		end)
	end

end

function KeepWorkMallPage.ParseXml(path,cb)
	local xmlRoot = ParaXML.LuaXML_ParseFile(path);
	if xmlRoot then
		local root_node = commonlib.XPath.selectNode(xmlRoot, "/pe:blocktemplate");
		if(root_node and root_node[1]) then
			local node = commonlib.XPath.selectNode(root_node, "/references");
			if(node) then
				for _, fileNode in ipairs(node) do
					local filename = fileNode.attr.filename
					local filepath = GameLogic.GetWorldDirectory()..commonlib.Encoding.Utf8ToDefault(filename);
					if(not ParaIO.DoesFileExist(filepath, true)) then
						local text = fileNode[1];
						NPL.load("(gl)script/ide/System/Encoding/base64.lua");
						text = System.Encoding.unbase64(text)
						ParaIO.CreateDirectory(filepath)
						local file = ParaIO.open(filepath, "w")
						if(file:IsValid()) then
							file:WriteString(text, #text);
							file:close();
						else
							LOG.std(nil, "warn", "BlockTemplate", "failed to write file to: %s", filepath);
						end
					else
						LOG.std(nil, "warn", "BlockTemplate", "load template ignored existing world file: %s", filename);
					end
				end
			end
			local node = commonlib.XPath.selectNode(root_node, "/pe:entities");
			if(node) then
				local entities = NPL.LoadTableFromString(node[1])
				local liveEntities = commonlib.copy(entities)
				if(entities and #entities > 0) then
					for _, entity in ipairs(entities) do
						if entity.attr.linkTo == nil then
							local _xmlInfo = entity
							local xmlInfo = KeepWorkMallPage.GetXmlNodeWithAllLinkedInfo(_xmlInfo,liveEntities)
							cb({xmlInfo = xmlInfo})
							break
						end
					end
				end
			end
		end
	end
end

function KeepWorkMallPage.GetXmlNodeWithAllLinkedInfo(_xmlInfo,entities)
	local getXmlInfo
	getXmlInfo = function (xmlInfo)
		xmlInfo.linkList = {}
		for key, entity in pairs(entities) do
			if entity.attr.linkTo == xmlInfo.attr.name then
				getXmlInfo(entity)
				local result =  commonlib.split(entity.attr.linkTo,"::")
				table.insert(xmlInfo.linkList,{
					mountIdx = nil, --如果是插件点上的点，记录是本节点的哪个插件点
					xmlInfo = entity,
					linkInfo = {
						boneName = result[2],
						pos = nil,
						rot = nil,
					},
					nodeInfo = { --记录相对与本节点的位移
						x = (entity.attr.x - xmlInfo.attr.x)*wholeScale,
						y = (entity.attr.y - xmlInfo.attr.y)*wholeScale,
						z = (entity.attr.z - xmlInfo.attr.z)*wholeScale,
					}
				})
			end
		end
	end
	getXmlInfo(_xmlInfo)
	return _xmlInfo
end

function KeepWorkItemManager.CheckHasPermission(item_data)
	if item_data.isPublic == 1 then
		return true
	else
		local UserPermission = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/UserPermission.lua");
		local enabled = UserPermission.CheckUserPermission("onlinestore")
		return enabled ~= nil and enabled or false
	end
end

--#endregion
