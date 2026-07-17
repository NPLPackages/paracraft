--[[
-- 存档点管理器：占用、自动加载、距离释放、本地加载限制
    uselib:
    local CheckPointManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CheckPointManager.lua");
    CheckPointManager.Init()
]]
local EasyCheckPoint = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyCheckPoint.lua");
local EasyMyCheckPoint = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyMyCheckPoint.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyEditableWorld.lua");
local EasyEditableWorld = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyEditableWorld");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");

local CheckPointManager = NPL.export()

CheckPointManager.occupiedBySubtag = CheckPointManager.occupiedBySubtag or {}
CheckPointManager.occupiedByModelId = CheckPointManager.occupiedByModelId or {}
CheckPointManager.occupiedByUser = CheckPointManager.occupiedByUser or {}
CheckPointManager.myOccupied = CheckPointManager.myOccupied or {}
CheckPointManager.releaseSchedule = CheckPointManager.releaseSchedule or {}
CheckPointManager.distanceTimer = CheckPointManager.distanceTimer or nil
CheckPointManager.isInitialized = CheckPointManager.isInitialized or false

function CheckPointManager.Init()
    if CheckPointManager.isInitialized then return end
    CheckPointManager.isInitialized = true

    GameLogic.GetFilters():remove_filter("OnGGSLogout",  CheckPointManager.OnGGSLogout);
    GameLogic.GetFilters():add_filter("OnGGSLogout",  CheckPointManager.OnGGSLogout);

    GameLogic.GetFilters():remove_filter("OnGGSUpdateEditWorldInfo",  CheckPointManager.OnGGSUpdateEditWorldInfo);
    GameLogic.GetFilters():add_filter("OnGGSUpdateEditWorldInfo",  CheckPointManager.OnGGSUpdateEditWorldInfo);

    GameLogic.GetFilters():remove_filter("EasyEditableWorldSlotFilenameChanged",  CheckPointManager.WorldSlotChanged);
    GameLogic.GetFilters():add_filter("EasyEditableWorldSlotFilenameChanged", CheckPointManager.WorldSlotChanged);
end

function CheckPointManager.OnGGSDisConnected()
    CheckPointManager.ClearOccupied()
end

function CheckPointManager.OnWorldUnload()
    CheckPointManager.ClearOccupied()
    CheckPointManager.ClearDownloadHistory()
end

function CheckPointManager.ClearOccupied()
    CheckPointManager.occupiedBySubtag = {}
    CheckPointManager.occupiedByModelId = {}
    CheckPointManager.myOccupied = nil
    CheckPointManager.releaseSchedule = {}
    CheckPointManager.occupiedByUser = {}
end

function CheckPointManager.OnGGSUpdateEditWorldInfo(editableWorld)
    LOG.std(nil, "info", "CheckPointManager", "OnGGSUpdateEditWorldInfo editableWorld:%s", commonlib.serialize(editableWorld))
    local username = editableWorld.username or ""
    local editableWorld = editableWorld.editableWorld
    local subTag,modelId = editableWorld:match("([^;]+);([^;]+)")
    modelId = tonumber(modelId)
    if not subTag or not modelId then
        return
    end
    if modelId <=0 then
        local occupiedData = CheckPointManager.occupiedByUser[username]
        CheckPointManager.RemoveOccupiedData(occupiedData)
        return
    end
    CheckPointManager.GetModelDataById(modelId,subTag,function(data)
        if not data or not data.id then
            return
        end
        local occupiedData = {
            subTag = subTag,
            worldName = currentTag,
            username = username,
            model = data,
            isOccupied = true,
        }

        CheckPointManager.AddOccupiedData(occupiedData)
        -- EasyCheckPoint.DownloadModel(data)
    end)
    return editableWorld
end

function CheckPointManager.RemoveOccupiedData(occupiedData)
    if not occupiedData or not occupiedData.model or not occupiedData.model.id then
        return
    end
    local username = occupiedData.username or ""
    if not username or username == "" then
        return
    end
    local modelId = occupiedData.model.id
    CheckPointManager.occupiedByUser[username] = nil
    local subTag = occupiedData.subTag
    print("CheckPointManager.RemoveOccupiedData, subTag:", subTag, "username:", username, "modelId:", modelId)
    if subTag and subTag ~= "" then
        local occupiedDatas = CheckPointManager.occupiedBySubtag[subTag]
        if occupiedDatas then
            for i, data in ipairs(occupiedDatas) do
                if data.username == username then
                    table.remove(occupiedDatas, i)
                    CheckPointManager.occupiedByModelId[modelId] = nil
                    break
                end
            end
        end
    end
end

function CheckPointManager.AddOccupiedData(occupiedData)
    if not occupiedData or not occupiedData.model or not occupiedData.model.id then
        return
    end
    local username = occupiedData.username or ""
    if not username or username == "" then
        return
    end
    local occupiedUserData = CheckPointManager.occupiedByUser[username]
    if occupiedUserData and occupiedUserData.model and occupiedUserData.model.id then
        CheckPointManager.RemoveOccupiedData(occupiedUserData)
    end
    local modelId = occupiedData.model.id
    local subTag = occupiedData.subTag
    if modelId and modelId > 0 and subTag and subTag ~= "" then
        if not CheckPointManager.occupiedBySubtag[subTag] then
            CheckPointManager.occupiedBySubtag[subTag] = {}
        end
        table.insert(CheckPointManager.occupiedBySubtag[subTag], occupiedData)
        CheckPointManager.occupiedByModelId[modelId] = occupiedData
        CheckPointManager.occupiedByUser[username] = occupiedData
    end
end

function CheckPointManager.GetServerTime()
    local servertime = GameLogic.GetFilters():apply_filters('service.session.get_current_server_time')
    return servertime or os.time()
end

function CheckPointManager.WorldSlotChanged(filename, displayName)
    if not filename or filename == "" then
        local model =  CheckPointManager.myOccupied and CheckPointManager.myOccupied.model
        if model and model.subtag and model.subtag ~= "" then --解除占用
           CheckPointManager.RemoveOccupiedData(CheckPointManager.myOccupied)
           CheckPointManager.myOccupied = nil
        end
        return filename, displayName
    end
    local basename = filename:match("([^/\\]+)$") or filename
    local clean = basename:gsub("%.autosave$", "")
    local slot, subtag = clean:match("^(%d+)%.([^.]+)%.blocks%.xml$")
    if slot and subtag and  subtag ~= "" then
        EasyMyCheckPoint.CheckRemoteModelExist(slot, subtag, function(exist, model)
            if exist and model then
                local player = GameLogic.GetPlayer()
                if player then
                    local username = Mod.WorldShare.Store:Get('user/username')
                    local currentTag = EasyEditableWorld.GetCurrentTag()
                    local serverData = commonlib.deepcopy(model)
                    -- serverData.filename = nil
                    -- serverData.local_filesize = nil
                    -- serverData.serverSlotIndex = nil
                    local occupiedData = {
                        subTag = subtag,
                        worldName = currentTag,
                        username = username,
                        model = serverData,
                        isOccupied = true,
                        isMine = true,
                    }
                    local curEditableWorld = player:GetEditableWorld() or ""
                    local worldStr = occupiedData.subTag..";"..serverData.id
                    if curEditableWorld and curEditableWorld ~= worldStr then
                        player:SetEditableWorld(worldStr)
                        CheckPointManager.AddOccupiedData(occupiedData)
                        CheckPointManager.myOccupied = occupiedData
                        GameLogic.GetFilters():apply_filters("update_editable_world", {editableWorld = worldStr})
                    end
                end
            else
                CheckPointManager.RemoveOccupiedData(CheckPointManager.myOccupied)
                CheckPointManager.myOccupied = nil
            end
        end)
    end
    return filename, displayName
end

function CheckPointManager.GetOccupiedDataByModelId(modelId)
    return CheckPointManager.occupiedByModelId[modelId]
end

function CheckPointManager.GetOccupiedDataBySubtag(subtag)
    return CheckPointManager.occupiedBySubtag[subtag]
end

-- 监听登出，设置30秒后释放该用户的占用
function CheckPointManager.OnGGSLogout(username)
    LOG.std(nil, "info", "CheckPointManager", "OnGGSLogout username:%s", username)
    local occupiedData = CheckPointManager.occupiedByUser[username]
    if occupiedData then
        CheckPointManager.RemoveOccupiedData(occupiedData)
    end
    return username
end

function CheckPointManager.GetModelDataById(modelId,subTag,callback)
    local currentTag = EasyEditableWorld.GetCurrentTag()
    if not currentTag or currentTag == "" or not subTag or subTag == "" then
        GameLogic.AddBBS(nil, L"当前未打开任何世界", 2000, "255 0 0")
        return
    end
    if not modelId or modelId <= 0 then
        return
    end
    keepwork.mall.getModelsByTagWithSubtag({
        tag = currentTag,
        subtag = subTag,
        ids = string.format("[%d]", modelId),
    },function(err,msg,data)
        if err  ~= 200 or not data then
            if callback and type(callback) == "function" then
                callback()
            end
            return
        end
        local model = data.rows and data.rows[1]
        if callback and type(callback) == "function" then
            callback(model)
        end
    end)
end

function CheckPointManager.AddDownLoadHistory(model)
    if not model or not model.id then
        return
    end
    CheckPointManager.downloadHistory = CheckPointManager.downloadHistory or {}
    for _,v in pairs(CheckPointManager.downloadHistory) do
        if v.subtag == model.subtag then
            CheckPointManager.downloadHistory[v.id] = nil
        end
    end
    CheckPointManager.downloadHistory[model.id] = model
end

function CheckPointManager.RemoveDownloadHistory(model)
    if not model or not model.id then
        return
    end
    CheckPointManager.downloadHistory = CheckPointManager.downloadHistory or {}
    CheckPointManager.downloadHistory[model.id] = nil
end

function CheckPointManager.ClearDownloadHistory()
    CheckPointManager.downloadHistory = {}
end

function CheckPointManager.GetDownloadHistory(modelId)
    if not modelId or modelId <= 0 then
        return nil
    end
    CheckPointManager.downloadHistory = CheckPointManager.downloadHistory or {}
    return CheckPointManager.downloadHistory[modelId]
end

function CheckPointManager.UpdateDownloadHistory()
    CheckPointManager.downloadHistory = CheckPointManager.downloadHistory or {}
    local newMap = {}
    for _,v in pairs(CheckPointManager.downloadHistory) do
        local subtag = v.subtag
        local isLoaded = GameLogic.EditableWorld:GetTemplateFileAtSubTag(subtag)
        if isLoaded and isLoaded ~= "" then
            newMap[v.id] = v
        end
    end
    CheckPointManager.downloadHistory = newMap
end