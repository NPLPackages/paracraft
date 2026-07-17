--[[
Title: EasyMyCheckPoint - My Checkpoint Management
Author(s): GitHub Copilot
Date: 2025/01/26
Desc: Easy checkpoint management tool that provides:
- Display saved worlds with subtag support
- Load/Save functionality for subtag-specific archives
- Restore functionality for deleted/overwritten archives

Use the lib:
------------------------------------------------------------
local EasyMyCheckPoint = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyMyCheckPoint.lua");
EasyMyCheckPoint.ShowEditableWorld(subTag)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/World/EditableWorld.lua");
local EditableWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.EditableWorld");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyEditableWorld.lua");
local EasyEditableWorld = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyEditableWorld");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local EasyMyCheckPoint = NPL.export()

local function getDataKey(subtag, slotIndex)
    if not subtag or not slotIndex then
        return ""
    end
    local currentTag = EasyEditableWorld.GetCurrentTag()
    return currentTag .. "_" .. subtag .. "_" .. slotIndex
end

function EasyMyCheckPoint.ClearRemoteModel()
    EasyMyCheckPoint.remoteModels = {}
end

function EasyMyCheckPoint.GetRemoteModelBySlotIndex(slotIndex, subTag)
    local remoteDatas = EasyMyCheckPoint.remoteModels or {}
    local userId = Mod.WorldShare.Store:Get('user/userId')
    if(not userId) then
        return
    end
    local dataKey = getDataKey(subTag, slotIndex)
    return remoteDatas[dataKey]
end

function EasyMyCheckPoint.CheckRemoteModelExist(slotIndex, subTag, callback)
    local remoteDatas = EasyMyCheckPoint.remoteModels or {}
    local userId = Mod.WorldShare.Store:Get('user/userId')
    if(not userId) then
        if callback and type(callback) == "function" then
            callback(false, L"用户未登录")
        end
        return
    end
    local dataKey = getDataKey(subTag, slotIndex)
    local model = remoteDatas[dataKey]
    if model then
        if callback and type(callback) == "function" then
            callback(true, model)
        end
    else
        EasyMyCheckPoint.LoadRemoteData(subTag,function(success)
            if success then
                remoteDatas = EasyMyCheckPoint.remoteModels or {}
                dataKey = getDataKey(subTag, slotIndex)
                model = remoteDatas[dataKey]
                if model then
                    if callback and type(callback) == "function" then
                        callback(true, model)
                    end
                else
                    if callback and type(callback) == "function" then
                        callback(false, L"远程数据不存在")
                    end
                end
            else
                if callback and type(callback) == "function" then
                    callback(false, L"加载远程数据失败")
                end
            end
        end)
    end
end

function EasyMyCheckPoint.ShowEditableWorld(subTag,entity)
    EasyMyCheckPoint.subTag = subTag
    EasyEditableWorld.entity = entity
    GameLogic.AddBBS("loadmymodel", L"正在加载存档数据...")
    EasyMyCheckPoint.LoadRemoteData(subTag,function(success)
        GameLogic.AddBBS("loadmymodel", nil)
        if(success) then
            EasyEditableWorld:new({
                operation="Save", 
                subTag = subTag, 
                worldName = nil, slotIndex = nil}):Run();
        else
            GameLogic.AddBBS(nil, L"加载远程数据失败")
        end
    end)
end

function EasyMyCheckPoint.RefreshEditableWorld(subTag, callback)
    if not subTag or subTag == "" or EasyMyCheckPoint.subTag == subTag then
        if callback and type(callback) == "function" then
            callback()
        end
        return 
    end
    EasyMyCheckPoint.subTag = subTag
    GameLogic.AddBBS("loadmymodel", L"正在加载存档数据...")
    EasyMyCheckPoint.LoadRemoteData(subTag,function(success)
        GameLogic.AddBBS("loadmymodel", nil)
        if not success then
            GameLogic.AddBBS(nil, L"加载远程数据失败")
            return
        end
        if callback and type(callback) == "function" then
            callback()
        end
    end)
end

function EasyMyCheckPoint.LoadRemoteData(subTag,callback)
    GameLogic.CheckSignedIn(L"请先登录",function(result)
        if result then
            local userId = Mod.WorldShare.Store:Get('user/userId')
            if not userId then
                GameLogic.AddBBS("status", L"用户不存在", 3000, "255 0 0");
                return
            end
            local EasyHomeBuilder = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyHomeBuilder.lua")
            EasyHomeBuilder.CheckMyHomeExist(function(bExist, numberOfHomes)
                local currentTag = EasyEditableWorld.GetCurrentTag()
                keepwork.mall.getModelsByTagWithSubtag({
                    tag = currentTag,
                    subtag = subTag,
                    userId = userId,
                    ["x-page"] = 1,
                    ["x-per-page"] = 200,
                },function(err,msg,data)
                    if err  ~= 200 or not data then
                        if callback and type(callback) == "function" then
                            callback(false);
                        end
                        return
                    else
                        EasyMyCheckPoint.HandleRemoteData(data)
                        if callback and type(callback) == "function" then
                            callback(true);
                        end
                    end
                end)
            end)
        else
            GameLogic.AddBBS("status", L"登录失败", 3000, "255 0 0");
        end
    end)
end

function EasyMyCheckPoint.HandleRemoteData(data,bUpload)
    if not data then
        return
    end
    local EasyHomeBuilder = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyHomeBuilder.lua")
    EasyMyCheckPoint.remoteModels = EasyMyCheckPoint.remoteModels or {}
    if bUpload then
        local isFind = false
        local dataKey = getDataKey(data.subtag, data.serverSlotIndex)
        local model = EasyMyCheckPoint.remoteModels[dataKey]
        if model then
            isFind = true
            local oldModel = EasyMyCheckPoint.remoteModels[dataKey]
            commonlib.partialcopy(oldModel,data)
            EasyMyCheckPoint.remoteModels[dataKey] = oldModel
        end
        if not isFind then
            local filename, local_filesize, serverSlotIndex = EasyMyCheckPoint.CheckLocalFileExist(data)
            if not filename or not local_filesize or not serverSlotIndex then
                LOG.std(nil, "info", "EasyMyCheckPoint", "CheckLocalFileExist, not found: %s", data.name)
                return
            end
            data.filename = filename
            data.local_filesize = local_filesize
            data.serverSlotIndex = serverSlotIndex
            data.isMineHome = EasyHomeBuilder.CheckServerHomeExist(data.id)
            dataKey = getDataKey(data.subtag, data.serverSlotIndex)
            EasyMyCheckPoint.remoteModels[dataKey] = data
        end
    else

        if data.rows and #data.rows > 0 then
            for _,model in ipairs(data.rows) do
                local filename, local_filesize, serverSlotIndex = EasyMyCheckPoint.CheckLocalFileExist(model)
                if filename and local_filesize and serverSlotIndex then
                    model.filename = filename
                    model.local_filesize = local_filesize
                    model.serverSlotIndex = serverSlotIndex
                    model.isMineHome = EasyHomeBuilder.CheckServerHomeExist(model.id)
                    local dataKey = getDataKey(model.subtag, model.serverSlotIndex)
                    EasyMyCheckPoint.remoteModels[dataKey] = model
                else
                    LOG.std(nil, "info", "EasyMyCheckPoint", "CheckLocalFileExist, not found: %s", model.name)
                end
            end
        end
    end
end

function EasyMyCheckPoint.RefreshHomeData()
    local EasyHomeBuilder = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyHomeBuilder.lua")
    EasyMyCheckPoint.remoteModels = EasyMyCheckPoint.remoteModels or {}
    for _,model in pairs(EasyMyCheckPoint.remoteModels) do
        model.isMineHome = EasyHomeBuilder.CheckServerHomeExist(model.id)
    end
end

function EasyMyCheckPoint.CheckLocalFileExist(data)
    if not data then
        return 
    end
    local name = data.name
    local slot = string.match(name,"_(%d+)$")
    if slot and tonumber(slot) > 0 then
        local slotIndex = tonumber(slot)
        local subTag = data.subtag
        local editableWorld = GameLogic.CreateGetEditableWorld();
        local filename = editableWorld and editableWorld:GetSlotFilename(slotIndex, nil, subTag)
        if filename and ParaIO.DoesFileExist(filename) then
            LOG.std(nil, "info", "EasyMyCheckPoint", "CheckLocalFileExist, filename: %s", filename)
            local local_filesize = ParaIO.GetFileSize(filename);
            return filename, local_filesize , slotIndex
        else
            LOG.std(nil, "info", "EasyMyCheckPoint", "CheckLocalFileExist, filename not exist: %s", filename)
            ParaIO.CreateDirectory(filename);
            local file = ParaIO.open(filename, "w");
            if file then
                file:WriteString("");
                file:close();
            end
            
            return filename, 0, slotIndex
        end
    end
end

local function formatRemoteUrl(url)
    if not url or url == "" then
        return ""
    end
    local isFindParams = url:find("?")
    if isFindParams then
        url = url:sub(1,isFindParams-1)
    end
    return url
end

function EasyMyCheckPoint.GetSubEntity(subTag)
    if EasyMyCheckPoint.entity then
        return EasyMyCheckPoint.entity
    end
    if not subTag or subTag == "" then
        return nil
    end
    local entity = GameLogic.EntityManager.FindFirstEntity(function(entity) 
        return entity.class_name == "LiveModel" and entity.GetStaticTag and entity:GetStaticTag("subtag") == subTag
    end)
    EasyMyCheckPoint.entity = entity
    return EasyMyCheckPoint.entity
end

function EasyMyCheckPoint.CheckSaveDistance()
    local subEntity = EasyMyCheckPoint.GetSubEntity(EasyMyCheckPoint.subTag)
    if not subEntity then
        return true
    end
    local bx,by,bz = subEntity:GetBlockPos()
    local cx,cy,cz = GameLogic.EntityManager.GetFocus():GetBlockPos()
    local distance = math.sqrt((bx-cx)^2 + (bz-cz)^2)
    print("distance===============:",distance,bx,by,bz,"pplayer=============",cx,cy,cz)
    return distance < 100
end

function EasyMyCheckPoint.UploadToServer(filename, worldData, callback)
    if not EasyMyCheckPoint.CheckSaveDistance() then
        GameLogic.AddBBS(nil, L"当前位置距离存档点超过100格，请先移动到存档点附近", 2000, "255 0 0")
        return
    end
    if not filename then
        return
    end
     NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWorkMall/MallManager.lua");
    local MallManager = commonlib.gettable("MyCompany.Aries.Game.KeepWorkMall.MallManager");
    MallManager.getInstance():UpLoadFile(filename,function(url,size)
        local url = formatRemoteUrl(url)
        if url and url ~= "" then
            EasyMyCheckPoint.CreateOrUpdateServer(worldData, url, size, callback)
        end
    end,maxWorldSize,"easy_my_editable_world")
end

function EasyMyCheckPoint.CreateOrUpdateServer(worldData, url, size, callback)
    if not worldData or not worldData.slotIndex then
        return
    end
    local userId = Mod.WorldShare.Store:Get('user/userId')
    local slotIndex = worldData.slotIndex
    local currentTag = EasyEditableWorld.GetCurrentTag()
    local modelId = worldData.id
    local oldModelUrl = worldData.modelUrl
    local isUpdate = modelId and tonumber(modelId) > 0
    local newModelName = userId .. "_" .. currentTag .. "_" .. worldData.subTag .. "_" .. slotIndex
    local params = {
        name = isUpdate and worldData.name or newModelName,
        tag = currentTag,
        subtag = worldData.subTag,
        desc = worldData.desc,
        modelUrl = url,
        size = size,
        modelType = 'blocks',
    }
    if isUpdate then
        params.id = modelId
    end

    local function updateModel()
        LOG.std(nil, "info", "EasyMyCheckPoint.UpdateModel", params)
        keepwork.mall.createOrUpdateModel(params,function(err,msg,data)
            if err  ~= 200 or not data then
                LOG.std(nil, "warn", "EasyMyCheckPoint.UpdateModel", "failed, err: %s", tostring(err))
                GameLogic.AddBBS("status", L"上传失败", 3000, "255 0 0");
                return
            end
            LOG.std(nil, "info", "EasyMyCheckPoint.UpdateModel", "success")    
            
            local responseData
            local index = data[1]
            if type(index) == "number" and index > 0 then
                local modelData = data[2]
                modelData = modelData[1]
                responseData = modelData
            else
                responseData = data
            end
            EasyMyCheckPoint.HandleRemoteData(responseData,true)
            if callback and type(callback) == "function" then
                callback(true)
            end
        end)
    end

    if isUpdate then
        EasyMyCheckPoint.DeleteQiNiuModel(oldModelUrl,function()
            updateModel()
        end)
    else
        updateModel()
    end
end

function EasyMyCheckPoint.LoadRemoteModel(modelData,callback)
    local modelUrl = modelData and modelData.modelUrl
    local filename = modelData and modelData.filename
    if modelUrl and modelUrl ~= "" and filename and filename ~= "" then
        EasyMyCheckPoint.DownLoadFile(modelUrl,filename,nil,function(filepath)
            if filepath and filepath ~= "" then
                if callback and type(callback) == "function" then
                    callback(true)
                end
            else
                if callback and type(callback) == "function" then
                    callback(false)
                end
            end
        end)
    else
        if callback and type(callback) == "function" then
            callback(false)
        end
    end
end

function EasyMyCheckPoint.DownLoadFile(url,dest,cache_policy,callback)
    if not url or url == "" then
        if callback and type(callback) == "function" then
            callback()
        end
        return
    end
    if not dest or dest == "" then
        dest = ParaIO.GetWritablePath().. "temp/editableworlds_downloads/" .. url:match("[^/]+$")
    end
    if not cache_policy then
        cache_policy = System.localserver.CachePolicy:new("access plus 1 day");
    end
    NPL.load("(gl)script/ide/System/localserver/factory.lua");
    local ls = System.localserver.CreateStore();
    if(not ls) then
        return
    end
    ls:GetFile(cache_policy, url, function(entry)
        if(entry and entry.entry and entry.entry.url and entry.payload and entry.payload.cached_filepath) then
            if callback and type(callback) == "function" then
                ParaIO.CreateDirectory(dest);
                if(ParaIO.CopyFile(entry.payload.cached_filepath, dest, true)) then
                    LOG.std(nil, "info", "EasyMyCheckPoint", "success to copy from %s to %s", entry.payload.cached_filepath, dest);
                    callback(dest)
                else
                    LOG.std(nil, "warn", "EasyMyCheckPoint", "failed to copy from %s to %s", entry.payload.cached_filepath, dest);
                    callback()
                end
            end
        end
    end)
end

function EasyMyCheckPoint.DeleteQiNiuModel(modelUrl,callback)
    if not modelUrl or modelUrl == "" then
        return
    end
    local baseurl = "https://qiniu-public.keepwork.com/"
    local key = modelUrl:sub(#baseurl+1)
    keepwork.mall.deleteQiniuFile({
        key = key,
    },function(err,msg,data)
        if callback and type(callback) == "function" then
            callback()
        end
        if err  ~= 200 then
            LOG.std(nil, "warn", "EasyMyCheckPoint", "failed to delete qiniu file, err: %s, msg: %s", err, msg);
            return
        end
        LOG.std(nil, "info", "EasyMyCheckPoint", "success to delete qiniu file, key: %s", key);
    end)
end

function EasyMyCheckPoint.DeleteModelBySubTag(slotIndex, subTag)
    if not slotIndex or slotIndex <= 0 then
        return
    end
    if not subTag or subTag == "" then
        return
    end
    local model = EasyMyCheckPoint.GetRemoteModelBySlotIndex(slotIndex,subTag)
    if not model or not model.id or model.id <= 0 then
        return
    end
    for key,v in pairs(EasyMyCheckPoint.remoteModels) do
        if v.id == model.id then
            EasyMyCheckPoint.remoteModels[key] = nil
            break
        end
    end
    local modelUrl = model.modelUrl
    local modelId = model.id
    EasyMyCheckPoint.DeleteQiNiuModel(modelUrl,function()
        EasyMyCheckPoint.DeleteRemoteModel(modelId,function()
            local EasyCheckPoint = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyCheckPoint.lua");
            EasyCheckPoint.DeletePersonalData(modelId)
            local EasyHomeBuilder = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyHomeBuilder.lua")
            EasyHomeBuilder.DeleteMyHome(modelId)
        end)
    end)
end

function EasyMyCheckPoint.DeleteRemoteModel(modelId,callback)
    if not modelId or modelId <= 0 then
        return
    end
    keepwork.mall.deleteModel({
        router_params = {id = modelId},
    },function(err,msg,data)
        if callback and type(callback) == "function" then
            callback()
        end
        if err  ~= 200 then
            LOG.std(nil, "warn", "EasyMyCheckPoint", "failed to delete model, err: %s, msg: %s", err, msg);
            return
        end
        LOG.std(nil, "info", "EasyMyCheckPoint", "success to delete model, id: %s", modelId);
    end)
end
