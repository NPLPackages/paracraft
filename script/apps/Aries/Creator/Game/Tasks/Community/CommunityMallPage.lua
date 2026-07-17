--[[
Title: CommunityMallPage
Author(s):  pbb
CreateDate: 2023.12.6
Desc:
Use Lib:
-------------------------------------------------------
local CommunityMallPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/CommunityMallPage.lua");
CommunityMallPage.Show();
--]]

--Lib
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
local MallUtils = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWorkMall/MallUtils.lua");
--Page
NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWorkMall/MallManager.lua");
local MallManager = commonlib.gettable("MyCompany.Aries.Game.KeepWorkMall.MallManager");
local CommunityMallPage = NPL.export()

local level_to_index = {}
local menu_item_index = 0
local menu_node_data = {}

CommunityMallPage.defaul_select_menu_item_index = 1

local menu_data_sources = {
    {
        children = {
            {
                createdAt = "2022-06-29T01:53:12.000Z",
                id = 43,
                name = "推荐",
                parentId = 42,
                platform = 1,
                sn = 2,
                tag = "",
                updatedAt = "2022-06-29T01:53:34.000Z" 
            },
            {
                createdAt = "2022-06-29T01:53:23.000Z",
                id = 44,
                name = "热门",
                parentId = 42,
                platform = 1,
                sn = 3,
                tag = "",
                updatedAt = "2022-06-29T01:53:34.000Z" 
            },
        },
        createdAt = "2022-06-29T01:52:49.000Z",
        id = 42,
        name = "推荐",
        parentId = 0,
        platform = 1,
        sn = 1,
        tag = "推荐",
        updatedAt = "2022-06-29T01:53:34.000Z" 
    },
    {
        createdAt = "2020-09-09T01:21:06.000Z",
        id = 3,
        name = "建筑",
        parentId = 0,
        platform = 1,
        sn = 4,
        tag = "",
        updatedAt = "2022-06-29T01:53:34.000Z" 
    },
    {
        createdAt = "2020-09-21T01:43:51.000Z",
        id = 4,
        name = "装饰",
        parentId = 0,
        platform = 1,
        sn = 5,
        tag = "",
        updatedAt = "2022-06-29T01:53:34.000Z" 
    },
    {
        createdAt = "2020-11-30T21:44:14.000Z",
        id = 13,
        name = "家具",
        parentId = 0,
        platform = 1,
        sn = 6,
        tag = "",
        updatedAt = "2022-06-29T01:53:34.000Z" 
    },
    {
        createdAt = "2020-11-30T21:44:22.000Z",
        id = 14,
        name = "电器",
        parentId = 0,
        platform = 1,
        sn = 7,
        tag = "",
        updatedAt = "2022-06-29T01:53:34.000Z" 
    },
};
local pageNum = 40;
CommunityMallPage.data_hits = {}
CommunityMallPage.data_count = 0

CommunityMallPage.sort_data = {
    {name=L"名称", value="namePinyin.keyword" ,sort_type=-1},
    {name=L"使用量", value="useCount" ,sort_type=-1},
    {name=L"更新时间", value="updatedAt" ,sort_type=-1}
}
CommunityMallPage.sort_select_index = -1
CommunityMallPage.sort_select_type = -1 --0,asc-》顺序；1，desc-》降序

CommunityMallPage.menu_data_sources = {}
CommunityMallPage.select_menu_data = nil

local http_env = HttpWrapper.GetDevVersion()
local page,isOnlyShow
CommunityMallPage.IsInited = false
function CommunityMallPage.OnInit(pageCtrl)
    page = pageCtrl or document:GetPageCtrl();
    if not CommunityMallPage.IsInited then
        CommunityMallPage.IsInited = true
        MallManager.getInstance():LoadMallMenuList(function(data)
            CommunityMallPage.curPage = 1
            level_to_index = {}
            menu_item_index = 0
            CommunityMallPage.select_menu_data = nil
            local level = 1
            CommunityMallPage.menu_data_sources = {}
            menu_node_data = {}

            CommunityMallPage.HandleMenuData(CommunityMallPage.menu_data_sources, data, level)
        end)
    end
end

function CommunityMallPage.InitData(bSearch)
    CommunityMallPage.sort_select_index = -1
    CommunityMallPage.sort_select_type = -1
    CommunityMallPage.dataLoaded = false
    CommunityMallPage.data_hits = {}
    if not bSearch then
        CommunityMallPage.SearchText = ""
        CommunityMallPage.data_count = 0
        CommunityMallPage.curPage = 1
        CommunityMallPage.lastLoadIndex = 0
    end
    -- print("InitData====================")
    -- print(commonlib.debugstack())
end

function CommunityMallPage.CloseView()
    page = nil;
    isOnlyShow = nil
    CommunityMallPage.InitData()
end

function CommunityMallPage.Show()
    isOnlyShow = true
    MallManager.getInstance():LoadMallMenuList(function(data)
        -- print("CommunityMallPage.Show menu data==================")
        -- echo(data,true)
        CommunityMallPage.curPage = 1
        level_to_index = {}
        menu_item_index = 0
        CommunityMallPage.select_menu_data = nil
        local level = 1
        CommunityMallPage.menu_data_sources = {}
        menu_node_data = {}

        CommunityMallPage.HandleMenuData(CommunityMallPage.menu_data_sources, data, level)
        local params = {
            url = "script/apps/Aries/Creator/Game/Tasks/Community/CommunityMallPage.html",
            name = "CommunityMallPage.Show", 
            isShowTitleBar = false,
            DestroyOnClose = true,
            style = CommonCtrl.WindowFrame.ContainerStyle,
            allowDrag = false,
            enable_esc_key = true,
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
    end);
end

function CommunityMallPage.IsNodeSelected(data)
    if not data or type(data) ~= "table" then
        return false
    end
    local nodeData = CommunityMallPage.select_menu_data.attr
    if not nodeData then
        nodeData = CommunityMallPage.select_menu_data
    end
    if nodeData and nodeData.server_data and data.server_data and nodeData.server_data.id == data.server_data.id then
        return true
    end
    return false
end

function CommunityMallPage.ChangeMenuItem(attr)
	CommunityMallPage.ChangeToMenuByData(attr)
    CommunityMallPage.RefreshPage()
end

function CommunityMallPage.ChangeMenuType(level, index)
	CommunityMallPage.changeMenuNodeType(CommunityMallPage.menu_data_sources, level, index)
	CommunityMallPage.RefreshPage()
end

-- 切换到某个类别的时候不会自动收起其他的展开的类别 但能收起当前类别
function CommunityMallPage.changeMenuNodeType(data, level, index)
    local select_node = nil
	for k, v in pairs(menu_node_data) do
		if type(v) == "table" and v.name == "type" then
			if v.attr.level == level and v.attr.index == index then
				v.attr.expanded = not v.attr.expanded
                select_node = v
                break
			end
		end
    end
    CommunityMallPage.ChangeToMenuByData(select_node)
end

function CommunityMallPage.HandleMenuData(parent_t, data, level)
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
			CommunityMallPage.HandleMenuData(temp_t, v.children, next_level)			
		else
			menu_item_index = menu_item_index + 1
			temp_t.attr.menu_item_index = menu_item_index
		end

		parent_t[k] = temp_t

		-- 记录默认展示的索引
		if temp_t.attr.menu_item_index and temp_t.attr.menu_item_index == CommunityMallPage.defaul_select_menu_item_index then			
			--CommunityMallPage.GetGoodsData(temp_t.attr.server_data.id)
            CommunityMallPage.ChangeToMenuByData(temp_t)
		end

		if temp_t.name == "type" then
			menu_node_data[#menu_node_data + 1] = temp_t
		end
	end	
end

function CommunityMallPage.ChangeToMenuByData(data)
    print("ChangeToMenuByData============")
    -- echo(data,true)
    -- echo(CommunityMallPage.select_menu_data or {},true)
    CommunityMallPage.select_menu_data = data
    CommunityMallPage.InitData()
    CommunityMallPage.LoadMallList()
end

function CommunityMallPage.RefreshPage()
    if page then
        page:Refresh(0)
    end
end

function CommunityMallPage.RefreshGridView(bSearch)
    if bSearch then
        if page:GetNode("menu_gridview") and page:GetNode("menu_gridview"):GetChild("pe:treeview") then
           page:GetNode("menu_gridview"):GetChild("pe:treeview").control:ScrollToEnd()
        end
    end
    -- if then
    --     if page:GetNode("menu_gridview") and page:GetNode("menu_gridview"):GetChild("pe:treeview") then
    --         page:GetNode("menu_gridview"):GetChild("pe:treeview").control.ClientY = 0
    --         page:GetNode("menu_gridview"):GetChild("pe:treeview").control:Update()
    --      end
    -- end
end

function CommunityMallPage.InitSortData(index)
    if CommunityMallPage.sort_select_index ~= index then
        CommunityMallPage.sort_select_index = index
        CommunityMallPage.sort_select_type = 0
    else
        if CommunityMallPage.sort_select_type == 0 then
            CommunityMallPage.sort_select_type = 1
        else
            CommunityMallPage.sort_select_type = 0
        end
    end
    CommunityMallPage.data_count = 0
    CommunityMallPage.lastLoadIndex = 0
    CommunityMallPage.dataLoaded = false
    CommunityMallPage.curPage = 1
    CommunityMallPage.data_hits = {}
end

function CommunityMallPage.OnChangeSort(name)
    local index = tonumber(name)
    if index and index > 0 then
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.mall_page.click_sort_item", {index=index,useNoId=true},nil,true);
        CommunityMallPage.InitSortData(index)
        CommunityMallPage.LoadMallList()
        CommunityMallPage.RefreshPage()
    end
end

function CommunityMallPage.GetSortData()
    local isShort = CommunityMallPage.sort_select_index > 0 and CommunityMallPage.sort_select_type >= 0
    local sortType
    if isShort then
        sortType = CommunityMallPage.sort_select_type == 0 and "asc" or "desc"
    end

    local sortName
    if isShort then
        sortName = CommunityMallPage.sort_data[CommunityMallPage.sort_select_index].value or ""
    end
    return sortName, sortType
end



function CommunityMallPage.LoadMallListImp()
    local sortName, sortType = CommunityMallPage.GetSortData()
    if not sortName then
        sortName = "useCount"
        sortType = "desc"
    end
    local dataNum = #CommunityMallPage.data_hits
    -- if menuType and menuType == "search" then
    --     local search_text = menuData.name
    --     CommunityMallPage.OnSearchGood(search_text,true)
    --     return
    -- end
    local menuData = CommunityMallPage.select_menu_data.attr
    if not menuData then
        menuData = CommunityMallPage.select_menu_data
    end
    local menuId = menuData.server_data.id
    print("CommunityMallPage.LoadMallListImp menuId=========",menuId)
    if menuId and menuId > 0 then
        if CommunityMallPage.data_count == 0 or dataNum < CommunityMallPage.data_count then
            MallManager.getInstance():LoadMallList(CommunityMallPage.curPage,menuId,sortName,sortType,function(data,key)
                if not data then
                    return
                end
                if CommunityMallPage.data_count == 0 then
                    CommunityMallPage.data_count= data.total
                end
                CommunityMallPage.dataLoaded = true
                if data and data.hits and next(data.hits) ~= nil then
                    for i,v in ipairs(data.hits) do
                        table.insert(CommunityMallPage.data_hits,v)
                    end
                    CommunityMallPage.HandleDataSources()
                    -- print("dddddddddddccccccccccccccccc",#CommunityMallPage.data_hits,key,dataNum,CommunityMallPage.data_count)
                else
                    -- print("CommunityMallPage aaaaaaaaaa=============",key,dataNum,CommunityMallPage.data_count,CommunityMallPage.curPage,menuName)
                    -- echo(data,true)
                    -- GameLogic.AddBBS(nil,L"没有更多的物品数据了")
                end
            end)
        else
            -- GameLogic.AddBBS(nil,L"没有更多的物品数据了")
        end
        
    end
end

function CommunityMallPage.LoadMallList()
    if CommunityMallPage.SearchText and CommunityMallPage.SearchText ~= "" then
        CommunityMallPage.OnSearchGood(CommunityMallPage.SearchText)
        return
    end
    CommunityMallPage.LoadMallListImp()
end

function CommunityMallPage.HandleDataSources()
    if not CommunityMallPage.data_hits or next(CommunityMallPage.data_hits) == nil then
        return
    end
    local count = 0
    for i,v in ipairs(CommunityMallPage.data_hits) do
        v.name = commonlib.GetLimitLabel(v.name,20)
        v.useCount = tonumber(v.useCount) or 0

        v.isLink = v.method == 1  or (v.purchaseUrl ~= nil and v.purchaseUrl ~= "") --购买方式，0：内部购买；1：外部购买
        v.hasIcon = (v.icon ~= "" and v.icon ~= nil) or (v.newIcon ~= "" and v.newIcon ~= nil)

        local isShowIcon = http_env == "STAGE" and (v.modelType == "bmax" or v.modelType == "x") or v.modelType == "bmax"
        v.isLiveModel = v.modelType == "liveModel"
        v.hasPermission = MallUtils.CheckHasPermission(v)
        v.enabled = v.hasPermission
        v.vip_enabled = not v.hasPermission
        local modelUrl = v.modelUrl or ""
        local downloadUrl = v.modelUrl or ""
        v.isModelProduct = modelUrl ~= "" and modelUrl ~= nil
        if v.isModelProduct and v.hasIcon and isShowIcon then
            v.icon = v.newIcon
            v.use_little_icon = true
        else
            v.use_little_icon = false
        end
        if v.isModelProduct then
            v.modelType = (v.modelType and v.modelType~= "") and v.modelType or ""
        end

        v.needDownload = (downloadUrl~= nil and downloadUrl ~= "") and not downloadUrl:match("character/") and v.modelType ~= "blocks"
        if v.needDownload then
            count = count + 1
        end
    end

    if System.options.isHideVip then
        local preNum = #CommunityMallPage.data_hits
        CommunityMallPage.data_hits = commonlib.filter(CommunityMallPage.data_hits, function (item)
            return item.isPublic == 1;
        end)

        local filterNum = #CommunityMallPage.data_hits
        local curTotal = CommunityMallPage.data_count or filterNum
        local maxDataNum = math.min(pageNum,curTotal)
        if filterNum < maxDataNum then
            CommunityMallPage.curPage = CommunityMallPage.curPage + 1
            CommunityMallPage.LoadMallList()
        end
    end

    local index = 1;
    local loadCount = 0;
    local loadFunc = nil;
    loadFunc = function (item_data)
        if index > #CommunityMallPage.data_hits then
            CommunityMallPage.FlushView(false);
            return;
        end

        index = index + 1;
        if item_data.needDownload then
            MallUtils.LoadLiveModelXml(item_data,function (data)
                item_data.xmlInfo = data.xmlInfo
                item_data.tooltip = data.tooltip
                item_data.hasLoad = true
                loadCount = loadCount + 1
                if loadCount <= pageNum then
                    loadFunc(CommunityMallPage.data_hits[index])
                else
                    CommunityMallPage.FlushView(false)
                    commonlib.TimerManager.SetTimeout(function ()
                        CommunityMallPage.LoadElseModel(index + 1)
                    end, 1000)
                end
                
            end)
        else
            loadFunc(CommunityMallPage.data_hits[index])
        end
    end

    loadFunc(CommunityMallPage.data_hits[index]);
end

function CommunityMallPage.LoadElseModel(index)
    local loadFunc = nil
    loadFunc = function (item_data)
        if index > #CommunityMallPage.data_hits then
            CommunityMallPage.FlushView(false)
            return
        end
        index = index + 1
        if item_data.needDownload then
            MallUtils.LoadLiveModelXml(item_data,function (data)
                item_data.xmlInfo = data.xmlInfo
                item_data.tooltip = data.tooltip
                item_data.hasLoad = true
                loadFunc(CommunityMallPage.data_hits[index])
            end)
        else
            loadFunc(CommunityMallPage.data_hits[index])
        end
    end
    loadFunc(CommunityMallPage.data_hits[index])
end

function CommunityMallPage.LoadMore(index)
    if (not index or type(tonumber(index)) ~= "number" or not CommunityMallPage.data_hits) then
        return;
    end
    
    index = tonumber(index);
    local dataLength = #CommunityMallPage.data_hits;
    -- print("LoadMore==============",index,dataLength,CommunityMallPage.data_count,CommunityMallPage.curPage)
    if (index >= dataLength) then
        if CommunityMallPage.lastLoadIndex ~= index then
            CommunityMallPage.lastLoadIndex = index;
            CommunityMallPage.curPage = CommunityMallPage.curPage + 1
            CommunityMallPage.LoadMallList()
        end
    end
end

function CommunityMallPage.FlushView(only_refresh_grid)
    if only_refresh_grid then
        local gvw_name = "item_gridview";
        local node = page:GetNode(gvw_name);
        pe_gridview.DataBind(node, gvw_name, false);
    else
        CommunityMallPage.RefreshPage()
    end
end

function CommunityMallPage.OnMouseWheel()
    if (not page) then
        return;
    end

    local itemGrideViewNode = page:GetNode("item_gridview");
    local curLine = 0;

    if (itemGrideViewNode) then
        if (itemGrideViewNode:GetChild('pe:treeview') and
            itemGrideViewNode:GetChild('pe:treeview').control) then
            local control = itemGrideViewNode:GetChild('pe:treeview').control;

            if control then
                curLine = math.ceil(control.ClientY / 180);
            end
        end
    end

    local lineCount = 5;
    local startLine = curLine * lineCount - (lineCount - 1);
    local startIndex;
    local endIndex;

    if (startLine - 5) > 0 then
        startIndex = startLine - lineCount;
        endIndex = startIndex + (lineCount * 6 - 1);
    else
        startIndex = startLine
        endIndex = startIndex + (lineCount * 5 - 1);
    end
    
    for key, item in ipairs(CommunityMallPage.data_hits) do
        if (key < startIndex or key > endIndex) then
            if (item and item.icon and item.icon ~= "") then
                ParaAsset.LoadTexture('', item.icon, 1):UnloadAsset()
            end

            if (item and item.modelUrl and item.modelUrl ~= "") then
                ParaAsset.LoadTexture('', item.modelUrl, 1):UnloadAsset()
            end
            -- if (item and item.tooltip and item.tooltip ~= "") then
            --     ParaAsset.LoadParaX("", Files.GetTempPath()..item.tooltip):UnloadAsset();
            -- end
        end
    end
end

function CommunityMallPage:CheckIsCollected(item)
    if not item or type(item) ~= "table" then
        return false
    end
    local id = item.id
    if id and id > 0 then
        return MallManager.getInstance():CheckIsCollected(id)
    end

    return false
end

function CommunityMallPage.OnClickCollect(data)
    -- print("OnClickCollect-===============")
    -- echo(data,true)
    GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.mall_page.click_collect", {id=data and data.id or 0,useNoId=true},nil,true);
    MallManager.getInstance():CollectMallGood(data and data.id,function(result)
        if not result then
            CommunityMallPage.RefreshPage()
        end
    end)
    CommunityMallPage.RefreshPage()
end

function CommunityMallPage.OnClickItem(item_data,callbackFunc)
    if not item_data then
        return
    end
    MallUtils.OnClickUseGood(item_data)
end

function CommunityMallPage.OnClickSearch(search_text)
    if not CommunityMallPage.SearchFunc then
        CommunityMallPage.SearchFunc = commonlib.debounce(function(search_text)
            CommunityMallPage.OnSearchGood(search_text)
            GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.mall_page.click_search", {text=search_text,useNoId=true},nil,true);
        end,300)
    end
    CommunityMallPage.SearchFunc(search_text)
end

function CommunityMallPage.AddSearchMenu(search_text)
    
end

function CommunityMallPage.OnSearchGood(search_text,bFromMenu)
    if (not CommunityMallPage.SearchText or CommunityMallPage.SearchText == "") and (not search_text or search_text == "") then
        return
    end
    local initFunc = nil
    initFunc = function() 
        CommunityMallPage.sort_select_index = -1
        CommunityMallPage.sort_select_type = -1
        CommunityMallPage.curPage = 1
        CommunityMallPage.data_count = 0
        CommunityMallPage.data_hits = {}
        -- print("initFuc================")
    end
    -- print("ddddddddddddddddddddddddd===============",CommunityMallPage.SearchText,search_text,CommunityMallPage.curPage)
    if CommunityMallPage.SearchText and CommunityMallPage.SearchText ~= "" and (not search_text or search_text == "") then
        initFunc()
        CommunityMallPage.SearchText = ""
        -- print("inideFunc===================")
        CommunityMallPage.LoadMallList()
        return
    end
    if CommunityMallPage.SearchText ~= search_text then
        CommunityMallPage.SearchText = search_text
        initFunc()
        if not bFromMenu then
            CommunityMallPage.AddSearchMenu(search_text)
        end
    end
    local dataNum = #CommunityMallPage.data_hits
    local sortName,sortOrder = CommunityMallPage.GetSortData()
    -- print(commonlib.debugstack())
    if CommunityMallPage.data_count == 0 or dataNum < CommunityMallPage.data_count or (sortName and sortName ~= "") then
        MallManager.getInstance():SearchMallList(CommunityMallPage.curPage,search_text,sortName,sortOrder,function(data,key)
            -- echo(data,true)
            if not data then
                return
            end
            CommunityMallPage.dataLoaded = true
            if data and data.hits and next(data.hits) ~= nil then
                if CommunityMallPage.data_count == 0 then
                    CommunityMallPage.data_count = data.total
                end
                for i,v in ipairs(data.hits) do
                    table.insert(CommunityMallPage.data_hits,v)
                end
                CommunityMallPage.HandleDataSources()
                -- print("aaaaaaaaaaaaaaaaaaaaa===============",CommunityMallPage.SearchText,search_text)
                -- print("mall search==============",#CommunityMallPage.data_hits,key,dataNum,CommunityMallPage.data_count,CommunityMallPage.curPage)
            else
                -- print("cccccccccccccccccccccccc===============",CommunityMallPage.SearchText,search_text)
                -- print("mall search==============",key,dataNum,CommunityMallPage.data_count,CommunityMallPage.curPage,menuName)
                -- GameLogic.AddBBS(nil,L"没有更多的物品数据了")
            end
        end)
    end
end

function CommunityMallPage.ClearSearch()
    CommunityMallPage.sort_select_index = -1
    CommunityMallPage.sort_select_type = -1
    CommunityMallPage.curPage = 1
    CommunityMallPage.data_count = 0
    CommunityMallPage.data_hits = {}
    CommunityMallPage.SearchText = ""
end



