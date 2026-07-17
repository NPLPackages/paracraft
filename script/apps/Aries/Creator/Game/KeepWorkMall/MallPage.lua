--[[
Title: MallPage
Author(s):  pbb
CreateDate: 2023.12.6
Desc:
Use Lib:
-------------------------------------------------------
local MallPage = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWorkMall/MallPage.lua");
MallPage.Show();
--]]

--Lib
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
local MallUtils = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWorkMall/MallUtils.lua");
local MallMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWorkMall/MallMainPage.lua");
--Page
NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWorkMall/MallManager.lua");
local MallManager = commonlib.gettable("MyCompany.Aries.Game.KeepWorkMall.MallManager");
local MallPage = NPL.export()

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
MallPage.data_hits = {}
MallPage.data_count = 0

MallPage.sort_data = {
    {name=L"名称", value="namePinyin.keyword" ,sort_type=-1},
    {name=L"使用量", value="useCount" ,sort_type=-1},
    {name=L"更新时间", value="updatedAt" ,sort_type=-1}
}
MallPage.sort_select_index = -1
MallPage.sort_select_type = -1 --0,asc-》顺序；1，desc-》降序

MallPage.menu_data_sources = {}
MallPage.menu_select_index = -1
MallPage.menu_select_children_index = -1

local http_env = HttpWrapper.GetDevVersion()
local page,isOnlyShow
MallPage.IsInited = false
function MallPage.OnInit(pageCtrl)
    page = pageCtrl or document:GetPageCtrl();
    if not MallPage.IsInited then
        MallPage.IsInited = true
        MallManager.getInstance():LoadMallMenuList(function(data)
            MallPage.menu_data_sources = data;
            MallPage.HandleMenuDataSource()
            local menuIndex = MallPage.GetCodeMenuIndex()
            MallPage.menu_select_index = -1
            MallPage.curPage = 1
            if menuIndex > 0 then
                MallPage.OnChangeMenu(menuIndex)
            else
                MallPage.OnChangeMenu(1)
            end
        end)
    end
end

function MallPage.GetCodeMenuIndex()
    if not MallMainPage.bFromCodeBlock then
        return -1
    end
    local index = -1
    if MallPage.menu_data_sources and next(MallPage.menu_data_sources) ~= nil then
        for i = 1,#MallPage.menu_data_sources do
            if MallPage.menu_data_sources[i].name == "代码" then
                index = i
                break
            end
        end
    end
    return index
end

function MallPage.InitData(bSearch)
    MallPage.sort_select_index = -1
    MallPage.sort_select_type = -1
    MallPage.dataLoaded = false
    MallPage.data_hits = {}
    if not bSearch then
        MallPage.SearchText = ""
        MallPage.data_count = 0
        MallPage.curPage = 1
        MallPage.lastLoadIndex = 0
    end
    -- print("InitData====================")
    -- print(commonlib.debugstack())
end

function MallPage.CloseView()
    page = nil;
    isOnlyShow = nil
    MallPage.InitData()
end

function MallPage.Show()

    -- local ItemComponent = NPL.load('script/apps/Aries/Creator/Game/KeepWork/KeepWorkMallComponent/ItemComponent.lua');
    -- Map3DSystem.mcml_controls.RegisterUserControl('pe:keepwork_mall_item', ItemComponent)
    isOnlyShow = true
    MallManager.getInstance():LoadMallMenuList(function(data)
        MallPage.menu_data_sources = data;
        MallPage.HandleMenuDataSource()
        MallPage.menu_select_index = 1
        MallPage.curPage = 1
        local params = {
            url = "script/apps/Aries/Creator/Game/KeepWorkMall/MallPage.html",
            name = "MallPage.Show", 
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

function MallPage.HandleMenuDataSource()
    local dataSource = MallPage.menu_data_sources
    local search_menu_data_source = MallManager.getInstance():GetMallSearchHistory()
    -- echo(search_menu_data_source,true)
    -- print("search menudata ========================")
    if search_menu_data_source and search_menu_data_source.children and next(search_menu_data_source.children) ~= nil then
        if dataSource[#dataSource].id == 99999 then
            table.remove(dataSource)
        end
        table.insert(dataSource, search_menu_data_source)
    end
    MallPage.menu_data_sources = dataSource
end

function MallPage.RefreshPage()
    if page then
        page:Refresh(0)
    end
end

function MallPage.GetChildMenuData()
    local menuData = MallPage.menu_data_sources[MallPage.menu_select_index]
    if menuData and menuData.children then
        return menuData.children
    end
    return {}
end

function MallPage.IsHasChildMenu()
    return next(MallPage.GetChildMenuData()) ~= nil and true or false
end

function MallPage.IsChangeToSearchMenu(index)
    if index and index > 0 then
        return MallPage.menu_data_sources[index].id == 99999
    end
end

function MallPage.OnChangeMenu(name,bSearch)
    local index = tonumber(name)
    if index and index > 0 then
        if not bSearch then 
            
            MallPage.InitData()
            if MallPage.menu_select_index ~= index then
                MallPage.menu_select_index = index
                MallPage.menu_select_children_index = -1
            else
                if MallPage.menu_select_children_index ~= -1 then
                    MallPage.menu_select_children_index = -1
                end
            end
        else
            MallPage.menu_select_index = index
            MallPage.menu_select_children_index = -1
        end
        if MallPage.IsChangeToSearchMenu(index) then
            MallPage.OnChangeChildMenu(1,bSearch)
            return
        end
        MallPage.LoadMallList()
        MallPage.RefreshPage()
        MallPage.RefreshGridView(bSearch)
    end
end

function MallPage.RefreshGridView(bSearch)
    if bSearch then
        if page:GetNode("menu_gridview") and page:GetNode("menu_gridview"):GetChild("pe:treeview") then
           page:GetNode("menu_gridview"):GetChild("pe:treeview").control:ScrollToEnd()
        end
    end
    if MallPage.menu_select_index == 1 then
        if page:GetNode("menu_gridview") and page:GetNode("menu_gridview"):GetChild("pe:treeview") then
            page:GetNode("menu_gridview"):GetChild("pe:treeview").control.ClientY = 0
            page:GetNode("menu_gridview"):GetChild("pe:treeview").control:Update()
         end
    end
end

function MallPage.OnChangeChildMenu(name,bSearch)
    local index = tonumber(name)
    if index and index > 0  then
        MallPage.InitData(bSearch)
        if MallPage.menu_select_children_index ~= index then
            MallPage.menu_select_children_index = index
        else
            MallPage.menu_select_children_index = -1
        end
        if not bSearch then
            MallPage.LoadMallList()
        end
        MallPage.RefreshPage()
        MallPage.RefreshGridView(bSearch)
    end
end

function MallPage.InitSortData(index)
    if MallPage.sort_select_index ~= index then
        MallPage.sort_select_index = index
        MallPage.sort_select_type = 0
    else
        if MallPage.sort_select_type == 0 then
            MallPage.sort_select_type = 1
        else
            MallPage.sort_select_type = 0
        end
    end
    MallPage.data_count = 0
    MallPage.lastLoadIndex = 0
    MallPage.dataLoaded = false
    MallPage.curPage = 1
    MallPage.data_hits = {}
end

function MallPage.OnChangeSort(name)
    local index = tonumber(name)
    if index and index > 0 then
        MallPage.InitSortData(index)
        MallPage.LoadMallList()
        MallPage.RefreshPage()
    end
end

function MallPage.GetSortData()
    local isShort = MallPage.sort_select_index > 0 and MallPage.sort_select_type >= 0
    local sortType
    if isShort then
        sortType = MallPage.sort_select_type == 0 and "asc" or "desc"
    end

    local sortName
    if isShort then
        sortName = MallPage.sort_data[MallPage.sort_select_index].value or ""
    end
    return sortName, sortType
end

function MallPage.GetMenuData()
    local isLoadChild = MallPage.IsHasChildMenu() and MallPage.menu_select_children_index > 0
    
    local menuData = MallPage.menu_data_sources[MallPage.menu_select_index] or {}
    local menuId,menuName,menuType
    if isLoadChild then
        menuData = menuData.children[MallPage.menu_select_children_index] or {}
        menuId = menuData.id
        menuName = menuData.name
        menuType = menuData.type
    else
        menuId = menuData.id
        menuName = menuData.name        
    end
    return menuId,menuName,menuType,menuData
end

function MallPage.LoadMallListImp()
    local menuId,menuName,menuType,menuData = MallPage.GetMenuData()
    local sortName, sortType = MallPage.GetSortData()
    if not sortName then
        sortName = "useCount"
        sortType = "desc"
    end
    local dataNum = #MallPage.data_hits
    if menuType and menuType == "search" then
        local search_text = menuData.name
        MallPage.OnSearchGood(search_text,true)
        return
    end
    if menuId and menuId > 0 then
        if MallPage.data_count == 0 or dataNum < MallPage.data_count then
            MallManager.getInstance():LoadMallList(MallPage.curPage,menuId,sortName,sortType,function(data,key)
                if not data then
                    return
                end
                if MallPage.data_count == 0 then
                    MallPage.data_count= data.total
                end
                MallPage.dataLoaded = true
                if data and data.hits and next(data.hits) ~= nil then
                    for i,v in ipairs(data.hits) do
                        table.insert(MallPage.data_hits,v)
                    end
                    MallPage.HandleDataSources()
                    -- print("dddddddddddccccccccccccccccc",#MallPage.data_hits,key,dataNum,MallPage.data_count)
                else
                    -- print("MallPage aaaaaaaaaa=============",key,dataNum,MallPage.data_count,MallPage.curPage,menuName)
                    -- echo(data,true)
                    -- GameLogic.AddBBS(nil,L"没有更多的物品数据了")
                end
            end)
        else
            -- GameLogic.AddBBS(nil,L"没有更多的物品数据了")
        end
        
    end
end

function MallPage.LoadMallList()
    if MallPage.SearchText and MallPage.SearchText ~= "" then
        MallPage.OnSearchGood(MallPage.SearchText)
        return
    end
    MallPage.LoadMallListImp()
end

function MallPage.HandleDataSources()
    if not MallPage.data_hits or next(MallPage.data_hits) == nil then
        return
    end
    if MallPage.loadTimer then
        MallPage.loadTimer:Change()
        MallPage.loadTimer = nil
    end
    MallPage.loadFunc = nil
    MallPage.loadElseFunc = nil
    local count = 0
    for i,v in ipairs(MallPage.data_hits) do
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
            if not System.options.isCommunity then
                v.hasIcon = false
                v.icon = ""
            else
                v.icon = v.newIcon
                v.use_little_icon = true
            end
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
        local preNum = #MallPage.data_hits
        MallPage.data_hits = commonlib.filter(MallPage.data_hits, function (item)
            return item.isPublic == 1;
        end)

        local filterNum = #MallPage.data_hits
        local curTotal = MallPage.data_count or filterNum
        local maxDataNum = math.min(pageNum,curTotal)
        if filterNum < maxDataNum then
            MallPage.curPage = MallPage.curPage + 1
            MallPage.LoadMallList()
        end
    end

    local index = 1;
    local loadCount = 0;
    if not MallPage.loadFunc then
        MallPage.loadFunc = function (item_data)
            if index > #MallPage.data_hits then
                MallPage.FlushView(false);
                return;
            end
            index = index + 1;
            if item_data and item_data.needDownload then
                MallUtils.LoadLiveModelXml(item_data,function (data)
                    item_data.xmlInfo = data.xmlInfo
                    item_data.tooltip = data.tooltip
                    item_data.hasLoad = true
                    loadCount = loadCount + 1
                    if loadCount <= pageNum then
                        if MallPage.loadFunc then
                            MallPage.loadFunc(MallPage.data_hits[index])
                        end
                    else
                        MallPage.FlushView(false)
                        MallPage.loadTimer = commonlib.TimerManager.SetTimeout(function ()
                            MallPage.LoadElseModel(index + 1)
                        end, 1000)
                    end
                end)
            else
                if MallPage.loadFunc then
                    MallPage.loadFunc(MallPage.data_hits[index])
                end
            end
        end
    end
    MallPage.loadFunc(MallPage.data_hits[index]);
end

function MallPage.LoadElseModel(index)
    if not MallPage.loadElseFunc then
        MallPage.loadElseFunc = function (item_data)
            if index > #MallPage.data_hits then
                MallPage.FlushView(false)
                return
            end
            index = index + 1
            if item_data and item_data.needDownload then
                MallUtils.LoadLiveModelXml(item_data,function (data)
                    item_data.xmlInfo = data.xmlInfo
                    item_data.tooltip = data.tooltip
                    item_data.hasLoad = true
                    if MallPage.loadElseFunc then
                        MallPage.loadElseFunc(MallPage.data_hits[index])
                    end
                end)
            else
                if MallPage.loadElseFunc then
                    MallPage.loadElseFunc(MallPage.data_hits[index])
                end
            end
        end
    end
    MallPage.loadElseFunc(MallPage.data_hits[index])
end

function MallPage.LoadMore(index)
    if (not index or type(tonumber(index)) ~= "number" or not MallPage.data_hits) then
        return;
    end
    
    index = tonumber(index);
    local dataLength = #MallPage.data_hits;
    -- print("LoadMore==============",index,dataLength,MallPage.data_count,MallPage.curPage)
    if (index >= dataLength) then
        if MallPage.lastLoadIndex ~= index then
            MallPage.lastLoadIndex = index;
            MallPage.curPage = MallPage.curPage + 1
            MallPage.LoadMallList()
        end
    end
end

function MallPage.FlushView(only_refresh_grid)
    if only_refresh_grid then
        local gvw_name = "item_gridview";
        local node = page:GetNode(gvw_name);
        pe_gridview.DataBind(node, gvw_name, false);
    else
        MallPage.RefreshPage()
    end
end

function MallPage.OnMouseWheel()
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
    
    for key, item in ipairs(MallPage.data_hits) do
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

function MallPage:CheckIsCollected(item)
    if not item or type(item) ~= "table" then
        return false
    end
    local id = item.id
    if id and id > 0 then
        return MallManager.getInstance():CheckIsCollected(id)
    end

    return false
end

function MallPage.OnClickCollect(data)
    -- print("OnClickCollect-===============")
    -- echo(data,true)
    MallManager.getInstance():CollectMallGood(data and data.id,function(result)
        if not result then
            MallPage.RefreshPage()
        end
    end)
    MallPage.RefreshPage()
end

function MallPage.OnClickItem(item_data,callbackFunc)
    if not item_data then
        return
    end
    MallUtils.OnClickUseGood(item_data)
end

function MallPage.OnClickSearch(search_text)
    if not MallPage.SearchFunc then
        MallPage.SearchFunc = commonlib.debounce(function(search_text)
            MallPage.OnSearchGood(search_text)
        end,300)
    end
    MallPage.SearchFunc(search_text)
end

function MallPage.AddSearchMenu(search_text)
    MallManager.getInstance():AddMallSearchHistory(search_text)
    MallPage.HandleMenuDataSource()
    MallPage.menu_select_children_index = 1
    local menuIndex = #MallPage.menu_data_sources
    -- print("search==========",search_text,menuIndex)
    MallPage.OnChangeMenu(menuIndex,true)
end

function MallPage.OnSearchGood(search_text,bFromMenu)
    if (not MallPage.SearchText or MallPage.SearchText == "") and (not search_text or search_text == "") then
        return
    end
    local initFunc = nil
    initFunc = function() 
        MallPage.sort_select_index = -1
        MallPage.sort_select_type = -1
        MallPage.curPage = 1
        MallPage.data_count = 0
        MallPage.data_hits = {}
        -- print("initFuc================")
    end
    -- print("ddddddddddddddddddddddddd===============",MallPage.SearchText,search_text,MallPage.curPage)
    if MallPage.SearchText and MallPage.SearchText ~= "" and (not search_text or search_text == "") then
        initFunc()
        MallPage.SearchText = ""
        -- print("inideFunc===================")
        MallPage.OnChangeMenu(1)
        -- MallPage.LoadMallList()
        return
    end
    if MallPage.SearchText ~= search_text then
        MallPage.SearchText = search_text
        initFunc()
        if not bFromMenu then
            MallPage.AddSearchMenu(search_text)
        end
    end
    local dataNum = #MallPage.data_hits
    local sortName,sortOrder = MallPage.GetSortData()
    -- print(commonlib.debugstack())
    if MallPage.data_count == 0 or dataNum < MallPage.data_count or (sortName and sortName ~= "") then
        MallManager.getInstance():SearchMallList(MallPage.curPage,search_text,sortName,sortOrder,function(data,key)
            -- echo(data,true)
            if not data then
                return
            end
            MallPage.dataLoaded = true
            if data and data.hits and next(data.hits) ~= nil then
                if MallPage.data_count == 0 then
                    MallPage.data_count = data.total
                end
                for i,v in ipairs(data.hits) do
                    table.insert(MallPage.data_hits,v)
                end
                MallPage.HandleDataSources()
                -- print("aaaaaaaaaaaaaaaaaaaaa===============",MallPage.SearchText,search_text)
                -- print("mall search==============",#MallPage.data_hits,key,dataNum,MallPage.data_count,MallPage.curPage)
            else
                -- print("cccccccccccccccccccccccc===============",MallPage.SearchText,search_text)
                -- print("mall search==============",key,dataNum,MallPage.data_count,MallPage.curPage,menuName)
                -- GameLogic.AddBBS(nil,L"没有更多的物品数据了")
            end
        end)
    end
end

function MallPage.ClearSearch()
    MallPage.sort_select_index = -1
    MallPage.sort_select_type = -1
    MallPage.curPage = 1
    MallPage.data_count = 0
    MallPage.data_hits = {}
    MallPage.SearchText = ""
    MallPage.menu_select_children_index = -1
    MallPage.menu_select_index = -1
end


