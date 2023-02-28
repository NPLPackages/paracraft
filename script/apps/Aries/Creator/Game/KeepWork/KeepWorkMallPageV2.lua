--[[
Title: KeepWorkMallPage
Author(s): yangguiyi pbb
Date: 2020/7/14（2022.6.29）
Desc:
Use Lib:
-------------------------------------------------------
local KeepWorkMallPage = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/KeepWorkMallPageV2.lua");
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
local menu_item_index = 0
local cur_classifyId = nil
local bean_gsid = 998;
local coin_gsid = 888;

--cad
KeepWorkMallPage.modelTypes = {{name ="all"},{name ="x"}, {name ="bmax"}, {name ="stl"}, {name ="fbx"}, {name ="blocks"}, {name ="liveModel"}, {name = "cad"}}
KeepWorkMallPage.model_index = 1
KeepWorkMallPage.isExpland_modelType = false
--search
KeepWorkMallPage.search_keyworlds = ""

ENUM_OF_GSID = {
	-- 皮肤碎片
	FRAGMENT_GSID = 10006,
	BEAN_ID = 998,
}
local pageNum = 15 * 2
KeepWorkMallPage.isOpen = false
KeepWorkMallPage.all_mod_list = {}

KeepWorkMallPage.IsFromCadBlock = false
KeepWorkMallPage.menu_data_sources = {}
KeepWorkMallPage.menu_data_sources = {
	{
		children={
		  {
			createdAt="2022-06-29T01:53:12.000Z",
			id=43,
			name="推荐",
			parentId=42,
			platform=1,
			sn=2,
			tag="",
			updatedAt="2022-06-29T01:53:34.000Z" 
		  },
		  {
			createdAt="2022-06-29T01:53:23.000Z",
			id=44,
			name="热门",
			parentId=42,
			platform=1,
			sn=3,
			tag="",
			updatedAt="2022-06-29T01:53:34.000Z" 
		  },
		},
		createdAt="2022-06-29T01:52:49.000Z",
		id=42,
		name="推荐",
		parentId=0,
		platform=1,
		sn=1,
		tag="推荐",
		updatedAt="2022-06-29T01:53:34.000Z" 
	  },
	  {
		createdAt="2020-09-09T01:21:06.000Z",
		id=3,
		name="建筑",
		parentId=0,
		platform=1,
		sn=4,
		tag="",
		updatedAt="2022-06-29T01:53:34.000Z" 
	  },
	  {
		createdAt="2020-09-21T01:43:51.000Z",
		id=4,
		name="装饰",
		parentId=0,
		platform=1,
		sn=5,
		tag="",
		updatedAt="2022-06-29T01:53:34.000Z" 
	  },
	  {
		createdAt="2020-11-30T21:44:14.000Z",
		id=13,
		name="家具",
		parentId=0,
		platform=1,
		sn=6,
		tag="",
		updatedAt="2022-06-29T01:53:34.000Z" 
	  },
	  {
		createdAt="2020-11-30T21:44:22.000Z",
		id=14,
		name="电器",
		parentId=0,
		platform=1,
		sn=7,
		tag="",
		updatedAt="2022-06-29T01:53:34.000Z" 
	  },
}

KeepWorkMallPage.grid_data_sources = {
	{enabled=true, name="1_1",invented = true},{enabled=true, name="1_2",invented = true},{enabled=true, name="1_3",invented = true},{enabled=true, name="1_4",invented = true},{enabled=true, name="1_5",invented = true},{enabled=true, name="1_6",invented = true},
	{enabled=true, name="1_7",invented = true},{enabled=true, name="1_8",invented = true},{enabled=true, name="1_9",invented = true},{enabled=true, name="1_10",invented = true},{enabled=true, name="1_11",invented = true},{enabled=true, name="1_12",invented = true}
}

KeepWorkMallPage.cur_select_level = 1 --大的分类索引
KeepWorkMallPage.cur_select_type_index = 1 --大的分类下的子分类索引
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
	KeepWorkMallPage.RefreshBeanNum()
end

function KeepWorkMallPage.Show(bFromCadBlock)
	if System.options.isCodepku then
		return
	end

	KeepWorkMallPage.IsFromCadBlock = bFromCadBlock
	KeepWorkMallPage.model_index = 1
	if KeepWorkMallPage.IsFromCadBlock then
		KeepWorkMallPage.model_index = 8
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

function KeepWorkMallPage.ShowView()
	KeepWorkMallPage.isOpen = true
	keepwork.mall.menus.get({
		cache_policy,
		platform =  1,
	},function(err, msg, data)
		if err == 200 and data then
			KeepWorkMallPage.cur_select_level = 1
			KeepWorkMallPage.cur_select_type_index = 1
			KeepWorkMallPage.menu_data_sources = data

			local params = {
					url = "script/apps/Aries/Creator/Game/KeepWork/KeepWorkMallPageV2.html",
					name = "KeepWorkMallPage.Show", 
					isShowTitleBar = false,
					DestroyOnClose = true,
					style = CommonCtrl.WindowFrame.ContainerStyle,
					allowDrag = false,
					enable_esc_key = true,
					zorder = 0,
					directPosition = true,
					DesignResolutionWidth = 1280,
					DesignResolutionHeight = 720,
					cancelShowAnimation = true,
					isTopLevel = true,
					align = "_fi",
						x = 0,
						y = 0,
						width = 0,
						height = 0,
				};
			System.App.Commands.Call("File.MCMLWindowFrame", params);
			KeepWorkMallPage.GetPageDt()
			GameLogic.GetFilters():add_filter("OnInstallModel", function ()
				commonlib.TimerManager.SetTimeout(function()
					if KeepWorkMallPage.isOpen then
						KeepWorkMallPage.HandleDataSources()
						KeepWorkMallPage.FlushView(true)
					end
				end, 500)
			end);

			if(KeepWorkMallPage.show_callback)then
				KeepWorkMallPage.show_callback();
			end
		end
	end)
end

function KeepWorkMallPage.GetChildMenuData()
	local menuData = KeepWorkMallPage.menu_data_sources[KeepWorkMallPage.cur_select_level]
	if menuData and menuData.children then
		return menuData.children
	end
	return {}
end

function KeepWorkMallPage.GetPageDt()
	KeepWorkMallPage.cur_select_level = 1
	KeepWorkMallPage.cur_select_type_index = 1
	local good_id = KeepWorkMallPage.GetGoodId(KeepWorkMallPage.cur_select_level,KeepWorkMallPage.cur_select_type_index)
	if good_id and good_id > 0 then
		KeepWorkMallPage.GetGoodsData(good_id)
	end
end

function KeepWorkMallPage.GetGoodId(menu_index,child_menu_index)
	local menu_data = KeepWorkMallPage.menu_data_sources[menu_index]
	local good_id = menu_data.id
	if menu_data  then
		if menu_data.children and #menu_data.children > 0 then
			good_id = menu_data.children[child_menu_index].id 
		end
	end
	return good_id
end

function KeepWorkMallPage.OnChangeMenu(name)
	if not name then
		return 
	end
	loadElse = false
	KeepWorkMallPage.dataLoaded = false
	local index = tonumber(string.match(name,"[%d]+$"))
	local id = tonumber(string.match(name,"^[%d]+"))
	KeepWorkMallPage.cur_select_level = index
	KeepWorkMallPage.cur_select_type_index = 1
	KeepWorkMallPage.model_index = 1
	KeepWorkMallPage.search_keyworlds = ""
	-- KeepWorkMallPage.OnRefresh()	
	local good_id = KeepWorkMallPage.GetGoodId(KeepWorkMallPage.cur_select_level,KeepWorkMallPage.cur_select_type_index)
	if good_id and good_id > 0 then
		KeepWorkMallPage.GetGoodsData(good_id)
	end
end

function KeepWorkMallPage.OnChangeChildMenu(name)
	if not name then
		return 
	end
	loadElse = false
	KeepWorkMallPage.dataLoaded = false
	local index = tonumber(string.match(name,"[%d]+$"))
	local id = tonumber(string.match(name,"^[%d]+"))
	KeepWorkMallPage.cur_select_type_index = index
	local good_id = id
	KeepWorkMallPage.GetGoodsData(good_id)
end

function KeepWorkMallPage.IsSelectRec()
	local menu_data = KeepWorkMallPage.menu_data_sources[KeepWorkMallPage.cur_select_level]
	if menu_data and menu_data.name == "推荐" and KeepWorkMallPage.cur_select_level == 1 then
		if menu_data.children and menu_data.children[KeepWorkMallPage.cur_select_type_index] and string.find(menu_data.children[KeepWorkMallPage.cur_select_type_index].name,"推荐") then
			return true
		end
		if not menu_data.children then
			return true
		end
		return false
	end
	return false
end

function KeepWorkMallPage.OnRefresh()
    if(page)then
        page:Refresh(0);
		local search_ctrl = page:FindUIControl("search_text")
		if search_ctrl and KeepWorkMallPage.search_keyworlds and KeepWorkMallPage.search_keyworlds ~= ""then
			search_ctrl.text = KeepWorkMallPage.search_keyworlds
		end
    end
end

function KeepWorkMallPage.SearchProduct(keywords)
	local keywords = keywords or ""
	if keywords == "" then
		KeepWorkMallPage.search_keyworlds = ""
		KeepWorkMallPage.GetGoodsData(nil, keywords, true)
		return 
	end
	local modelType 
	if KeepWorkMallPage.model_index ~=1 then
		modelType = KeepWorkMallPage.GetSelectModelType()
	end
	-- print("keywords===========",keywords)
	local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
    local httpwrapper_version = HttpWrapper.GetDevVersion();
	if httpwrapper_version and (httpwrapper_version == "LOCAL" or httpwrapper_version == "STAGE" or httpwrapper_version == "ONLINE") then
		keepwork.mall.searchGoods({
			q=keywords,
			modelType = modelType,
			["per_page"] = 1000,
			["page"] = 1,
		},function(err,msg,data)
			-- echo(err)
			-- echo(data)
			if err == 200 and data and data.hits then
				KeepWorkMallPage.search_keyworlds = keywords
				KeepWorkMallPage.IsInsert = false
				KeepWorkMallPage.IsSearch = true
				KeepWorkMallPage.grid_data_sources = data.hits or {}
				KeepWorkMallPage.dataLoaded = true
				KeepWorkMallPage.cur_select_level = -1
				KeepWorkMallPage.cur_select_type_index = -1
				KeepWorkMallPage.HandleDataSources()
				KeepWorkMallPage.FlushView(true)
				KeepWorkMallPage.IsSearch = false
			end
		end)
		return 
	end
	KeepWorkMallPage.GetGoodsData(nil, keywords, true)
end

function KeepWorkMallPage.GetGoodsData(classifyId, keyword, only_refresh_grid,count)
	-- classifyId 类别id
	-- tag hot，latest 火热 最新
	-- keyword 按商品名称模糊匹配
	if classifyId then
		cur_classifyId = classifyId
	else
		classifyId = cur_classifyId
	end
	if not classifyId then
		return 
	end

	local modelType = KeepWorkMallPage.GetSelectModelType()
	if modelType == "all" then
		modelType = nil
	end
	local pageCount = 1000
	if count ~= nil then
		pageCount = count
	end
    keepwork.mall.goods.get({
        classifyId = classifyId,
        -- tag = tag,
        keyword = keyword,
        platform = 1,
		modelType = modelType,
		["x-per-page"] = pageCount,
		["x-page"] = 1,
	},function(err, msg, data)
		-- print("err===========",err,classifyId)
		if data and tonumber(data.count) > pageCount then
			KeepWorkMallPage.GetGoodsData(classifyId, keyword, only_refresh_grid,tonumber(data.count))
		else
			KeepWorkMallPage.IsInsert = false
			KeepWorkMallPage.grid_data_sources = data ~= nil and data.rows or {}
			KeepWorkMallPage.dataLoaded = true
			KeepWorkMallPage.HandleDataSources()
			KeepWorkMallPage.FlushView(only_refresh_grid)
		end
    end)
end

KeepWorkMallPage.IsSearch = false
function KeepWorkMallPage.IsSearchData()
	return KeepWorkMallPage.IsSearch
end

KeepWorkMallPage.IsInsert = false
function KeepWorkMallPage.FlushView(only_refresh_grid)
	if KeepWorkMallPage.IsSelectRec() and not KeepWorkMallPage.IsInsert 
		and KeepWorkMallPage.grid_data_sources and #KeepWorkMallPage.grid_data_sources > 0
		and not KeepWorkMallPage.IsSearchData() then
		--插入占位数据
		for i=1,5 do
			table.insert(KeepWorkMallPage.grid_data_sources,1,{baner=1,id=-1})
		end
		KeepWorkMallPage.IsInsert = true
	end
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
		if not v.empty and not v.baner then
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
			v.useCount = tonumber(v.useCount) or 0
			-- v.is_show_hot_tag = string.find(v.tags, "hot") and string.find(v.tags, "hot") > 0
			-- v.is_show_latest_tag = string.find(v.tags, "latest") and string.find(v.tags, "latest") > 0
			if string.find(v.tags, "hot") and string.find(v.tags, "hot") > 0 then
				v.is_show_hot_tag = true
			end
			v.is_show_latest_tag = false
			if string.find(v.tags, "latest") and string.find(v.tags, "latest") > 0 then
				v.is_show_latest_tag = true
			end
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
	end
	if System.options.isChannel_430 then
		KeepWorkMallPage.grid_data_sources = commonlib.filter(KeepWorkMallPage.grid_data_sources, function (item)
			return item.hasPermission
		end)
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
				if loadCount <= pageNum then
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
			-- KeepWorkMallPage.FlushView(false)
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

function KeepWorkMallPage.UseGood(goodId)
	keepwork.mall.useGood({
		router_params = {id = goodId}
	}, function(err, msg, data)
		if err ~= 200 then
			GameLogic.AddBBS(nil,"商品使用失败，错误码是"..err)
		end
	end);
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
		if fileType == "cad" then
			fileType = "blocks"
		end
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
			local command = string.format("/install -ext %s -reload %s -filename %s %s", fileType,needReload, "temp/onlinestore/"..filename,model_url)
			GameLogic.RunCommand(command)
		elseif model_url:match("character/") then         
			GameLogic.RunCommand(string.format("/take BlockModel {tooltip=%q}", model_url));  
			KeepWorkMallPage.HandleDataSources()
			KeepWorkMallPage.FlushView(true)
		end
		
		commonlib.TimerManager.SetTimeout(function()
			local uiname = "KeepWorkMallPageV2."..item_data.id..item_data.name
			local node = ParaUI.GetUIObject(uiname)
			local x, y
			if node and node:IsValid() then
				x,y = node:GetAbsPosition();
			end
			KeepWorkMallPage.model_index = 1
			KeepWorkMallPage.search_keyworlds = ""
			KeepWorkMallPage.Close()
			local good_id = item_data.id
			if good_id and good_id > 0 then
				KeepWorkMallPage.UseGood(good_id)
			end
			--
			if x and y then				
				local KeepWorkSingleItem = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/KeepWorkSingleItem.lua")
    			KeepWorkSingleItem.ShowNotification(item_data,{x=x,y=y})
			end
		end,200)
		return
	end
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
	loadElse = false
	KeepWorkMallPage.IsFromCadBlock = false
	KeepWorkMallPage.model_index = 1
	KeepWorkMallPage.search_keyworlds = ""
	KeepWorkMallPage.isExpland_modelType = false
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

function KeepWorkMallPage.OnChangeModelType(name)
	local index = tonumber(name)
	if index and index > 0 and index <= 8  then
		KeepWorkMallPage.model_index = index 
		local modelType = KeepWorkMallPage.GetSelectModelType()
		-- KeepWorkMallPage.OnRefresh()
		KeepWorkMallPage.onClick_modelType()
		if KeepWorkMallPage.search_keyworlds and KeepWorkMallPage.search_keyworlds ~= "" then
			KeepWorkMallPage.SearchProduct(KeepWorkMallPage.search_keyworlds)
			return
		end
		KeepWorkMallPage.GetGoodsData(nil, nil, false)
	end
end

function  KeepWorkMallPage.GetSelectModelType()
	return KeepWorkMallPage.modelTypes[KeepWorkMallPage.model_index].name
end

function KeepWorkMallPage.onClick_modelType()
	if KeepWorkMallPage.IsFromCadBlock then
		return 
	end
	KeepWorkMallPage.isExpland_modelType = not KeepWorkMallPage.isExpland_modelType
	KeepWorkMallPage.OnRefresh()
end

--#endregion
