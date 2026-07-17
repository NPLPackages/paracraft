--[[
    -- 存档点逻辑
    --uselib:
        local EasyCheckPoint = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyCheckPoint.lua");
        EasyCheckPoint.ShowPage(checkPoint, entity)
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/KeepWork.lua");
local KeepWork = commonlib.gettable("MyCompany.Aries.Game.GameLogic.KeepWork")
NPL.load("(gl)script/ide/System/Util/YamlConverter.lua");
local YamlConverter = commonlib.gettable("System.Util.YamlConverter");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyEditableWorld.lua");
local EasyMyCheckPoint = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyMyCheckPoint.lua");
local CheckPointManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CheckPointManager.lua");
local EasyEditableWorld = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyEditableWorld");

local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local EasyCheckPoint = NPL.export()

local curInstance;
local page;

local curPage = 1
local perPage = 50
local personalPageName = "modelWorld"
-- Always a top level task
EasyCheckPoint.is_top_level = true;
EasyCheckPoint.current_sort = {} 
local sortConfigs = {
    {name="updatedAt",desc="更新时间"},
    {name="downloads",desc="下载数"},
    {name="likes",desc="收藏数"},
}
-- asc desc
function EasyCheckPoint.OnInit()
    page = document:GetPageCtrl();
end

function EasyCheckPoint.ShowPage(checkPoint, entity)
    EasyCheckPoint.checkPoint = checkPoint
    EasyCheckPoint.entity = entity
    if not EasyCheckPoint.checkPoint then
        GameLogic.AddBBS(nil, "请先选择存档点")
        return
    end
    CheckPointManager.UpdateDownloadHistory()
    EasyCheckPoint.LoadRecommendData(function()
        EasyCheckPoint.LoadPersonalDatas(function()
            EasyCheckPoint.ShowView(checkPoint, entity)
        end)
    end)
end

function EasyCheckPoint.ShowView(checkPoint, entity)
    EasyCheckPoint.current_sort = {}
    EasyCheckPoint.ResetPagination()
    local width, height = 900, 630;
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyCheckPoint.html", 
        name = "EasyCheckPoint.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        bToggleShowHide=false, 
        style = CommonCtrl.WindowFrame.ContainerStyle,
        enable_esc_key = false,
        allowDrag = false,
        click_through = true, 
        directPosition = true,
        align = "_ct",
        x = -width/2,
        y = -height/2,
        width = width,
        height = height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    EasyCheckPoint.LoadModels()
    if(params._page) then
        params._page.OnClose = function()
            page = nil;
        end
    end
end

function EasyCheckPoint.CloseWindow()
    if(page) then
        page:CloseWindow();
    end
end

function EasyCheckPoint.RefreshPage()
    if(page) then
        page:Refresh(0.01);
    end
end


-- 我的存档
function EasyCheckPoint.OnClickMine()
    EasyCheckPoint.CloseWindow()
    EasyMyCheckPoint.ShowEditableWorld(EasyCheckPoint.checkPoint, EasyCheckPoint.entity)
end

-- 入驻
function EasyCheckPoint.OnClickOccupy()

end

-- 修改存档点信息
function EasyCheckPoint.OnClickUpdate()
    local checkPoint = EasyCheckPoint.checkPoint
    local entity = EasyCheckPoint.entity
    if checkPoint then
        EasyCheckPoint.CloseWindow()
        
        local EasyEditCheckPoint = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyEditCheckPoint.lua");
        EasyEditCheckPoint.ShowPage(checkPoint, entity)
    end
end

function EasyCheckPoint.OnClickSort(name)
    local index = tonumber(name)
    if not index then return end
    local sortConfig = sortConfigs[index]
    if not sortConfig then return end

    local sort = EasyCheckPoint.current_sort
    local sortName = sortConfig and sortConfig.name
    if not sortName then return end
    
    if sort.name == sortName then
        sort.order = sort.order == "asc" and "desc" or "asc"
    else
        sort.name = sortName
        sort.order = "desc"  -- 默认降序
    end
    EasyCheckPoint.OnSortChange(sort)
end

function EasyCheckPoint.OnSortChange(sort)
    EasyCheckPoint.current_sort = sort
    -- 排序切换时重置分页
    EasyCheckPoint.ResetPagination()
    EasyCheckPoint.LoadModels()
end

-- 重置分页参数
function EasyCheckPoint.ResetPagination()
    curPage = 1
    EasyCheckPoint.models = {}
    EasyCheckPoint.showModels = {}
    EasyCheckPoint.isLoading = false
    EasyCheckPoint.totalCount = nil
end

function EasyCheckPoint.LoadModels()
    local x_order
    local sort = EasyCheckPoint.current_sort
    if sort.name and sort.order then
        x_order = sort.name .. "-" .. sort.order
    end
    local subTag = EasyCheckPoint.checkPoint
    local currentTag = EasyEditableWorld.GetCurrentTag()
    -- 设置加载状态
    EasyCheckPoint.isLoading = true
    local params = {
        tag = currentTag,
        subtag = subTag,
        ["x-order"] = x_order,
        ["x-page"] = curPage,
        ["x-per-page"] = perPage,
    }

    GameLogic.AddBBS("loadmodel", L"正在加载存档数据...")
    keepwork.mall.getModelsByTagWithSubtag(params,function(err,msg,data)
        GameLogic.AddBBS("loadmodel", nil)
        EasyCheckPoint.isLoading = false
        if err ~= 200 or not data or not data.rows then
            GameLogic.AddBBS(nil, L"加载数据失败，请重试")
            return
        end
        local models = data.rows or {}
        for _, model in ipairs(models) do
            model.isLiked = EasyCheckPoint.likedMap[model.id]
            model.isDownloaded = EasyCheckPoint.downloadedMap[model.id]
            model.isRecommend = EasyCheckPoint.recommendMap[model.id] ~= nil
        end
        LOG.std(nil, "info", "EasyCheckPoint.LoadModels", models)

        -- 初始化models数组（如果不存在）
        if not EasyCheckPoint.models then
            EasyCheckPoint.models = {}
        end
        
        -- 如果是第一页，重置数据；否则追加数据
        if curPage == 1 then
            EasyCheckPoint.models = models
        else
            -- 追加新数据到现有数据
            for _, model in ipairs(models) do
                table.insert(EasyCheckPoint.models, model)
            end
        end
        EasyCheckPoint.HandleDataByPlaceholder()
        -- 更新总数据信息
        if data.count then
            EasyCheckPoint.totalCount = data.count
        end

        EasyCheckPoint.RefreshPage()
    end)
end

function EasyCheckPoint.LoadMore(index)
    if not index or type(tonumber(index)) ~= "number" or not EasyCheckPoint.models or EasyCheckPoint.isLoading then
        return
    end
    index = tonumber(index)
    local dataLength = #EasyCheckPoint.models
    -- 检查是否已达到最大页数（如果有总数信息）
    if index >= dataLength and index < EasyCheckPoint.totalCount  then
        curPage = curPage + 1
        EasyCheckPoint.LoadModels()
    end
end

-- 刷新数据
function EasyCheckPoint.OnClickRefresh()
    curPage = 1
    EasyCheckPoint.models = {}
    EasyCheckPoint.totalCount = nil
    EasyCheckPoint.LoadModels()
end

-- 格式化数字显示
function EasyCheckPoint.FormatNumber(num)
    if not num or num == 0 then
        return "0"
    end
    
    if num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    else
        return tostring(num)
    end
end

-- 格式化文件大小
function EasyCheckPoint.FormatFileSize(size)
    if not size or size == 0 then
        return ""
    end
    
    local units = {"B", "KB", "MB", "GB"}
    local unitIndex = 1
    local fileSize = tonumber(size) or 0
    
    while fileSize >= 1024 and unitIndex < #units do
        fileSize = fileSize / 1024
        unitIndex = unitIndex + 1
    end
    
    if unitIndex == 1 then
        return string.format("%d %s", fileSize, units[unitIndex])
    else
        return string.format("%.1f %s", fileSize, units[unitIndex])
    end
end

-- 编辑存档点属性
function EasyCheckPoint.OnClickEdit()
    local checkPoint = EasyCheckPoint.checkPoint
    local entity = EasyCheckPoint.entity
    
    if not checkPoint and not entity then
        GameLogic.AddBBS(nil, L"请先选择一个存档点")
        return
    end
    
    -- 加载编辑页面
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyEditCheckPoint.lua")
    local EasyEditCheckPoint = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.EasyEditCheckPoint")
    if EasyEditCheckPoint and EasyEditCheckPoint.ShowPage then
        EasyEditCheckPoint.ShowPage(checkPoint, entity)
    end
end

-- 获取排序选项数据源
function EasyCheckPoint.GetSortOptions()
    return sortConfigs
end

-- 获取排序显示文本
function EasyCheckPoint.GetSortDisplayText(sortIndex)
    if not sortIndex or not tonumber(sortIndex) then return "" end
    sortIndex = tonumber(sortIndex)
    local sortOption = sortConfigs[sortIndex]
    if not sortOption then return "" end
    
    local current_sort = EasyCheckPoint.current_sort or {name = "updatedAt", order = "desc"}
    local text = sortOption.desc or sortOption.name or ""
    
    -- 如果是当前排序字段，添加排序方向指示
    if current_sort.name == sortOption.name then
        if current_sort.order == "desc" then
            text = text .. " ↓"
        else
            text = text .. " ↑"
        end
    end
    
    return text
 end

 -- 获取存档数据源（用于网格视图）
 function EasyCheckPoint.GetModelsDataSource()
     return EasyCheckPoint.models or {}
 end

function EasyCheckPoint.GetStoreUtil()
    if not EasyCheckPoint.PersonalPageStore then
        NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/PersonalPageStore.lua");
        EasyCheckPoint.PersonalPageStore = commonlib.gettable("MyCompany.Aries.Creator.Game.KeepWork.PersonalPageStore");
    end
    return EasyCheckPoint.PersonalPageStore
end

function EasyCheckPoint.LoadPersonalDatas(callback)
    local storeUtil = EasyCheckPoint.GetStoreUtil()
    storeUtil:LoadPageData(personalPageName, nil, function(data)
        local localData = commonlib.deepcopy(data) or {}
        EasyCheckPoint.likehistory = localData.liked or {}
        EasyCheckPoint.downloaded = localData.downloaded or {}
        EasyCheckPoint.likedMap = EasyCheckPoint.likedMap or {}
        for _, model in ipairs(EasyCheckPoint.likehistory) do
            EasyCheckPoint.likedMap[model.id] = true
        end
        EasyCheckPoint.downloadedMap = EasyCheckPoint.downloadedMap or {}
        for _, model in ipairs(EasyCheckPoint.downloaded) do
            EasyCheckPoint.downloadedMap[model.id] = true
        end
        if callback then
            callback()
        end
    end)
end

function EasyCheckPoint.DeletePersonalData(modelId)
    if not modelId or modelId <= 0 then
        return
    end
    EasyCheckPoint.LoadPersonalDatas(function()
        for i, model in ipairs(EasyCheckPoint.likehistory) do
            if model.id == modelId then
                table.remove(EasyCheckPoint.likehistory, i)
                break
            end
        end
        EasyCheckPoint.SavePersonalDatas("liked")
        EasyCheckPoint.likedMap[modelId] = nil
        for i, model in ipairs(EasyCheckPoint.downloaded) do
            if model.id == modelId then
                table.remove(EasyCheckPoint.downloaded, i)
                break
            end
        end
        EasyCheckPoint.downloadedMap[modelId] = nil
        EasyCheckPoint.SavePersonalDatas("downloaded")
    end)
end

function EasyCheckPoint.SavePersonalDatas(key)
    local storeUtil = EasyCheckPoint.GetStoreUtil()
    if key == "liked" then
        storeUtil:SavePageData(personalPageName, "liked", EasyCheckPoint.likehistory)
    elseif key == "downloaded" then
        storeUtil:SavePageData(personalPageName, "downloaded", EasyCheckPoint.downloaded)
    end
end

function EasyCheckPoint.OnClickLiked(index)
    if not EasyCheckPoint.models[index] then
        return
    end
    if not EasyCheckPoint.LikeFuncImp then
        EasyCheckPoint.LikeFuncImp = commonlib.debounce(function(index)
            EasyCheckPoint.OnClickLikedImp(index)
        end, 200)
    end
    EasyCheckPoint.LikeFuncImp(index)
end

function EasyCheckPoint.OnClickLikedImp(index)
    local model = EasyCheckPoint.models[index]
    if not model or model.isLiked then
        return
    end
    model.likedAt = os.date("%Y-%m-%d %H:%M:%S")
    table.insert(EasyCheckPoint.likehistory, model)
    EasyCheckPoint.likedMap[model.id] = true
    EasyCheckPoint.SavePersonalDatas("liked")
    keepwork.mall.increaseLikeCount({
        router_params = {id = model.id},
    },function(err,msg,data)
        if err == 200 then
            model.likes = model.likes + 1
            model.isLiked = true
            EasyCheckPoint.RefreshPage()
        end
    end)
end

-- 执行存档下载
function EasyCheckPoint.DownloadModel(model)
    if not model or not model.id then
        LOG.std(nil, "error", "EasyCheckPoint.DownloadModel", "存档数据无效")
        return
    end
    local modelUrl = model.modelUrl or ""
    if modelUrl == "" then
        LOG.std(nil, "error", "EasyCheckPoint.DownloadModel", "存档模型URL无效")
        return
    end

    local subTag = model.subtag or ""
    local userId = Mod.WorldShare.Store:Get('user/userId') or ""
    local isMine = model and userId == model.userId
    
    GameLogic.AddBBS("download", L"正在下载存档，请稍候...")
    EasyMyCheckPoint.DownLoadFile(modelUrl,dest,nil,function(filepath)
        if filepath and filepath ~= "" then
            GameLogic.AddBBS("download", nil)

            NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyEditableWorld.lua");
            local EasyEditableWorld = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyEditableWorld");
            EasyEditableWorld.LoadExternalFile(filepath, subTag, isMine)
        else
            GameLogic.AddBBS("download", L"下载文件失败")
        end
    end)
end

function EasyCheckPoint.OnClickDownloaded(index)
    if not EasyCheckPoint.models[index] then
        GameLogic.AddBBS(nil, L"未找到存档数据")
        return
    end
    if not EasyCheckPoint.DownloadFuncImp then
        EasyCheckPoint.DownloadFuncImp = commonlib.debounce(function(index)
            EasyCheckPoint.OnClickDownloadedImp(index)
        end, 200)
    end
    EasyCheckPoint.DownloadFuncImp(index)
end

function EasyCheckPoint.OnClickDownloadedImp(index)
    EasyCheckPoint.CloseWindow()
    local model = EasyCheckPoint.models[index]
    EasyCheckPoint.DownLoadModelImp(model)
end

function EasyCheckPoint.LoadMineModel(model)
    
end

function EasyCheckPoint.DownLoadModelImp(model)
    EasyCheckPoint.DownloadModel(model)
    CheckPointManager.AddDownLoadHistory(model)
    keepwork.mall.increaseDownloadCount({
        router_params = {id = model.id},
    },function(err,msg,data)
        if err == 200 then
            model.downloads = model.downloads + 1
            model.isDownloaded = true
            if not EasyCheckPoint.downloadedMap[model.id] then
                model.downloadedAt = os.date("%Y-%m-%d %H:%M:%S")
                EasyCheckPoint.downloadedMap[model.id] = true
                table.insert(EasyCheckPoint.downloaded, model)
            else
                for i, item in pairs(EasyCheckPoint.downloaded) do
                    if item.id == model.id then
                        item.downloads = model.downloads
                        item.downloadedAt = model.downloadedAt
                        break
                    end
                end
            end
            EasyCheckPoint.SavePersonalDatas("downloaded")
            EasyCheckPoint.RefreshPage()
        end
    end)
end

function EasyCheckPoint.OnClickRemoveDownloaded(index)
    if not EasyCheckPoint.models[index] then
        GameLogic.AddBBS(nil, L"未找到存档数据")
        return
    end
    EasyCheckPoint.CloseWindow()
    local model = EasyCheckPoint.models[index]
    CheckPointManager.RemoveDownloadHistory(model)
    local subtag = model.subtag or ""
    if subtag and subtag ~= "" then
        GameLogic.EditableWorld:RemoveReadonlyBlockTemplateBySubTag(subtag)
    end
end

function EasyCheckPoint.LoadRecommendData(callback)
    EasyCheckPoint.recommendMap = EasyCheckPoint.recommendMap or {}
    local recommendModels = EasyCheckPoint.entity:GetStaticTag("recommendModels")
    if not recommendModels or recommendModels == "" then
        if callback then
            callback()
        end
        return
    end
    local isWebConfig = recommendModels:find("^https?://")
    if isWebConfig then
        KeepWork.GetRawFile(recommendModels, function(err, msg, data)
           if data and data ~= "" then
                local recommendModels = YamlConverter.YAMLToLua(data) or {}
                local currentSubTag = EasyCheckPoint.checkPoint
                if currentSubTag and currentSubTag ~= "" then
                    local subModels = recommendModels[currentSubTag] or {}
                    for _, model in ipairs(subModels) do
                        EasyCheckPoint.recommendMap[model.id] = model
                    end
                end
           end
           if callback then
                callback()
           end
        end)
    else
        local recommendModels = commonlib.LoadTableFromString(recommendModels) or {}
        for _, model in ipairs(recommendModels) do
            EasyCheckPoint.recommendMap[model.id] = model
        end
        if callback then
            callback()
        end
    end
end

function EasyCheckPoint.GetActionName()
    local subTag = EasyCheckPoint.checkPoint
    local actionName = GameLogic.EditableWorld:GetActionNameFromSubtag(subTag)
    return actionName or subTag
end

function EasyCheckPoint.LoadPlaceHolder()
    local subTag = EasyCheckPoint.checkPoint
    local occupiedData = CheckPointManager.GetOccupiedDataBySubtag(subTag)
    local placeholderData = {}
    local hasMine = false
    if occupiedData and #occupiedData > 0 then
        for _, item in ipairs(occupiedData) do
            local model = item.model
            local isMine = item.isMine
            if model then
                local data = commonlib.copy(model)
                data.occupiedUser = item.username
                data.isOccupied = true
                data.isPlaceholder = true
                if isMine then
                    data.isMine = isMine
                    table.insert(placeholderData, 1, data)
                    hasMine = true
                else
                    table.insert(placeholderData, data)
                end
            end
        end
    end
    if not hasMine then
        table.insert(placeholderData, 1, {
            isPlaceholder = true,
            value = subTag,
        })
    end
    return placeholderData
end
function EasyCheckPoint.HandleDataByPlaceholder()
    local placeholders = EasyCheckPoint.LoadPlaceHolder()
    local models = placeholders
    local serverModels = commonlib.deepcopy(EasyCheckPoint.models)
    for _, model in ipairs(serverModels) do
        table.insert(models, model)
    end
    EasyCheckPoint.showModels = models
end

function EasyCheckPoint.OnClickSearch()
    if not page then
        return 
    end
    local searchText = page:GetValue("checkpoint") or ""
    local modelId = tonumber(searchText)
    if not modelId or modelId <= 0 then
        GameLogic.AddBBS(nil, L"请输入正确的存档ID")
        return
    end
    local currentTag = EasyEditableWorld.GetCurrentTag()
    local params = {
        tag = currentTag,
        ids = string.format("[%d]", modelId),
    }
    GameLogic.AddBBS("loadmodel", L"正在加载存档数据...")
    keepwork.mall.getModelsByTagWithSubtag(params,function(err,msg,data)
        GameLogic.AddBBS("loadmodel", nil)
        if err ~= 200 or not data or not data.rows or #data.rows == 0 then
            GameLogic.AddBBS(nil, L"这个ID不存在或不属于这个世界")
            return
        end
        local model = data.rows[1]
        local msgTip = string.format(L"是否要加载ID：%d(#%s)的存档，作者ID：%d？", model.id, model.subtag or "", model.userId)
        _guihelper.MessageBox(msgTip, function(res)
            if(res and res == _guihelper.DialogResult.Yes) then
                EasyCheckPoint.CloseWindow()
                EasyCheckPoint.DownLoadModelImp(model)
            end
        end, _guihelper.MessageBoxButtons.YesNo)
    end)
end

function EasyCheckPoint.IsModelDataLoaded(modelId)
    return CheckPointManager.GetDownloadHistory(modelId) ~= nil
end

 