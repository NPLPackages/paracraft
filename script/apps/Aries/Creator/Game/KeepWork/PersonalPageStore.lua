--[[
Title: Personal Page Store (Refactored)
Author(s): pbb
Date: 2025/8/8
Desc: Store for personal page data management - refactored to match JavaScript patterns
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/PersonalPageStore.lua");
local PersonalPageStore = commonlib.gettable("MyCompany.Aries.Creator.Game.KeepWork.PersonalPageStore");
------------------------------------------------------------
]]

-- required libs
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
NPL.load("(gl)script/ide/System/Util/YamlConverter.lua");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local YamlConverter = commonlib.gettable("System.Util.YamlConverter");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon");
local KeepworkSiteService = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/KeepWorkSiteService.lua");

-- Sanitize world name to only contain valid characters (letters, numbers, underscore)
-- Converts non-alphanumeric characters to their base64-like representation
local function SanitizeWorldName(worldName)
    if not worldName or worldName == "" then
        return "unnamed"
    end
    
    local result = {}
    for i = 1, #worldName do
        local char = worldName:sub(i, i)
        local byte = string.byte(char)
        
        -- Keep alphanumeric characters and underscore as-is
        if (byte >= 48 and byte <= 57) or  -- 0-9
           (byte >= 65 and byte <= 90) or  -- A-Z
           (byte >= 97 and byte <= 122) or -- a-z
           char == "_" then
            table.insert(result, char)
        else
            -- Convert other characters to _[hex]_ format
            table.insert(result, string.format("_%02X_", byte))
        end
    end
    
    local sanitized = table.concat(result)
    return sanitized
end

-- Normalize page name: convert nil or "@world" to actual world-specific page name
local function NormalizePageName(pageName)
    -- If pageName is nil or "@world", replace with world-specific name
    if not pageName or pageName == "" or pageName == "@world" then
        -- Try to get project ID first
        local projectId = WorldCommon.GetWorldTag("kpProjectId")
        
        if projectId and projectId ~= "" then
            -- Use format: world_[projectId]
            return "world_" .. tostring(projectId)
        else
            -- Fallback to world name, sanitized
            local worldName = WorldCommon.GetWorldTag("name")
            if not worldName or worldName == "" then
                worldName = "unnamed"
            end
            
            -- Sanitize world name to ensure valid characters
            local sanitizedName = SanitizeWorldName(worldName)
            return "world_" .. sanitizedName
        end
    end
    
    return pageName
end

-- local utility functions
local diskPath = ParaIO.GetWritablePath().."Database/PersonalPageStore/"

local function isArray(t)
    if type(t) ~= "table" or t == nil then
        return false
    end
    -- 空表视为数组
    if next(t) == nil then
        return true
    end
    local count = 0
    for k, v in pairs(t) do
        if type(k) ~= "number" or k <= 0 or math.floor(k) ~= k then
            return false
        end
        count = count + 1
    end
    
    -- 检查是否有间隔（确保从1开始连续）
    for i = 1, count do
        if t[i] == nil then
            return false
        end
    end
    return true
end

local function isemptytable(t) 
    return t == nil or next(t) == nil 
end

local function isValidValue(value) 
    if value == nil then
        return false
    end
    if type(value) == "table" then
        return not isemptytable(value)
    elseif type(value) == "string" then
        return value ~= ""
    end
    return true
end

-- Path utility functions matching JavaScript implementation
local function GetValueByPath(obj, path)
    if not obj then
        return nil
    end
    if not path or path == "" then
        return obj
    end
    
    if not path:find("%.") then
        return obj[path]
    end
    
    local keys = commonlib.split(path, ".")
    local current = obj
    
    for _, key in ipairs(keys) do
        if current and type(current) == "table" and current[key] ~= nil then
            current = current[key]
        else
            return nil
        end
    end
    
    return current
end

local function SetValueByPath(obj, path, value)
    if not obj then 
        return false 
    end

    if not path or path == "" then
        if type(value) == "table" and value ~= nil then
            -- Merge object if path is empty
            for k, v in pairs(value) do
                obj[k] = v
            end
            return true
        end
        return false -- Cannot set value without a path
    end
    
    if not path:find("%.") then
        if type(obj[path]) == "table" and type(value) == "table" and not isArray(obj[path]) and not isArray(value) then
            for k, v in pairs(value) do
                obj[path][k] = v
            end
        else
            -- 其他情况直接替换（包括数组）
            obj[path] = value
        end
        return true
    end
    
    local keys = commonlib.split(path, ".")
    local current = obj
    
    for i = 1, #keys - 1 do
        local key = keys[i]
        if not current[key] or type(current[key]) ~= "table" then
            current[key] = {}
        end
        current = current[key]
    end
    
    local finalKey = keys[#keys]
    if type(current[finalKey]) == "table" and type(value) == "table" and not isArray(value) then
        for k, v in pairs(value) do
            current[finalKey][k] = v
        end
    else
        current[finalKey] = value
    end
    return true
end

local function DeleteValueByPath(obj, path)
    if not obj or not path or path == "" then
        return false
    end
    
    if not path:find("%.") then
        if obj[path] ~= nil then
            obj[path] = nil
            return true
        end
        return false
    end
    
    local keys = commonlib.split(path, ".")
    local current = obj
    
    -- Navigate to parent of target key
    for i = 1, #keys - 1 do
        local key = keys[i]
        if not current[key] or type(current[key]) ~= "table" then
            return false -- Path doesn't exist
        end
        current = current[key]
    end
    
    -- Delete the final key
    local finalKey = keys[#keys]
    if current[finalKey] ~= nil then
        current[finalKey] = nil
        return true
    end
    
    return false
end

-- Main PersonalPageStore class
local PersonalPageStore = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Creator.Game.KeepWork.PersonalPageStore"))

-- Configuration constants matching JavaScript
local remoteSyncInterval = 5000 -- 5 seconds in milliseconds

function PersonalPageStore:ctor()
    self.personalPageData = {}
    self.personalPageDataUpdated = {}
    self.personalPageDataDeleted = {} -- Track deleted keys for each page
    self.pageStatus = {} -- Track page loading status like JavaScript
    self.pendingDiskPages = {} -- Pages pending disk save (using table as set)
    self.pendingSync = {} -- Pages pending remote sync (using table as set)
    self.isSyncing = false
    
    -- Configuration
    self.remoteSyncInterval = remoteSyncInterval
    self.remoteStorePath = "edunotes/store"
    
    -- Initialize timers
    self:CheckInitSyncTimers()
end

-- Initialize sync timers matching JavaScript pattern
function PersonalPageStore:CheckInitSyncTimers()
    if not self.gitSyncTimer then
        self.gitSyncTimer = commonlib.Timer:new({
            callbackFunc = function()
                self:BatchSyncToRemote()
            end
        })
        self.gitSyncTimer:Change(self.remoteSyncInterval, self.remoteSyncInterval)
    end
end

-- Cleanup method matching JavaScript destroy()
function PersonalPageStore:Destroy()
    if self.gitSyncTimer then
        self.gitSyncTimer:Change()
        self.gitSyncTimer = nil
    end
    if self.diskSaveTimer then
        self.diskSaveTimer:Change()
        self.diskSaveTimer = nil
    end
end

-- Reset method
function PersonalPageStore:Reset()
    self:BatchSyncToRemote()
    self.personalPageData = {}
    self.personalPageDataUpdated = {}
    self.personalPageDataDeleted = {}
    self.pageStatus = {}
    self.pendingDiskPages = {}
    self.pendingSync = {}
    self.isSyncing = false
end



-- Value comparison with deep equality check
function PersonalPageStore:IsValueEqual(v1, v2)
    if type(v1) ~= type(v2) then
        return false
    end
    
    if type(v1) == "table" and v1 ~= nil and v2 ~= nil then
        -- Handle arrays specifically
        local isArray1 = isArray(v1)
        local isArray2 = isArray(v2)
        
        if isArray1 and isArray2 then
            -- Arrays must have same length
            if #v1 ~= #v2 then
                return false
            end
            
            -- Arrays must have same values in same order
            for i = 1, #v1 do
                if not self:IsValueEqual(v1[i], v2[i]) then
                    return false
                end
            end
            return true
        end
        
        -- One is array, the other is not
        if isArray1 or isArray2 then
            return false
        end
        
        -- Handle regular tables
        local keys1 = {}
        local keys2 = {}
        for k, _ in pairs(v1) do table.insert(keys1, k) end
        for k, _ in pairs(v2) do table.insert(keys2, k) end
        
        if #keys1 ~= #keys2 then
            return false
        end
        
        for _, key in ipairs(keys1) do
            if not self:IsValueEqual(v1[key], v2[key]) then
                return false
            end
        end
        return true
    end
    
    return v1 == v2
end

-- Deep merge data
function PersonalPageStore:MergeData(target, source)
    if not source or type(source) ~= "table" then
        return target
    end
    
    -- 如果source是数组，直接替换target
    if isArray(source) then
        return commonlib.deepcopy(source)
    end
    
    for key, value in pairs(source) do
        if type(value) == "table" and value ~= nil then 
            if isArray(value) then
                -- 如果是数组，直接整体替换
                target[key] = commonlib.deepcopy(value)
            elseif type(target[key]) == "table" and target[key] ~= nil then
                -- 如果都是普通table，递归合并
                self:MergeData(target[key], value)
            else
                -- 其他情况，直接赋值
                target[key] = value
            end
        else
            target[key] = value
        end
    end
    return target
end

-- Get local storage path
function PersonalPageStore:GetLocalPagePath(pageName)
    local username = Mod.WorldShare.Store:Get('user/username')
    username = (username and username ~= "") and username or "anonymous"
    local userPath = diskPath..username.."/"
    local filepath = userPath..pageName..".md"
    if not ParaIO.DoesFileExist(filepath) then
        ParaIO.CreateDirectory(filepath)
    end
    return filepath
end

-- Get remote page path
function PersonalPageStore:GetRemotePagePath(pageName)
    local  siteName = "edunotes"
    local  sitePath = "edunotes/store/"
    local  filename = pageName.. ".md"
    local fullPath = format("%s%s", sitePath, filename)
    return fullPath, siteName
end

-- Check if using local mode
function PersonalPageStore:IsUseLocal()
    local isSigned = GameLogic.GetFilters():apply_filters('is_signed_in')
    return not isSigned
end

-- Get metadata with compatibility (优先使用_metadata，兼容旧的metadata)
function PersonalPageStore:GetMetadata(data)
    if not data or type(data) ~= "table" then
        return {}
    end
    return data._metadata or data.metadata or {}
end

-- Set metadata with compatibility (新数据使用_metadata，旧数据保持metadata不变)
function PersonalPageStore:SetMetadata(data, metadata)
    if not data or type(data) ~= "table" then
        return false
    end
    -- 新数据使用_metadata
    data._metadata = metadata
    
    return true
end

-- Generate version metadata
function PersonalPageStore:GenerateVersion(localData, remoteData)
    localData = localData or {}
    remoteData = remoteData or {}
    
    local localMetadata = self:GetMetadata(localData)
    local remoteMetadata = self:GetMetadata(remoteData)
    
    if remoteMetadata.version and localMetadata.version and 
       remoteMetadata.version > localMetadata.version then
        return {
            version = (remoteMetadata.version or 0) + 1,
            created_at = remoteMetadata.created_at or os.date("%Y-%m-%d-%H:%M:%S"),
            updated_at = os.date("%Y-%m-%d-%H:%M:%S")
        }
    end
    
    return {
        version = (localMetadata.version or 0) + 1,
        created_at = localMetadata.created_at or os.date("%Y-%m-%d-%H:%M:%S"),
        updated_at = os.date("%Y-%m-%d-%H:%M:%S")
    }
end

-- Save page data (main save method)
function PersonalPageStore:SavePageData(pageName, key, value, bFlush)
    pageName = NormalizePageName(pageName)
    self:CheckLoadData(pageName, function()
        self.personalPageData[pageName] = self.personalPageData[pageName] or {}
        self.personalPageDataUpdated[pageName] = self.personalPageDataUpdated[pageName] or {}
        local originalValue = GetValueByPath(self.personalPageDataUpdated[pageName], key)
        if originalValue == nil then
            originalValue = GetValueByPath(self.personalPageData[pageName], key)
        end
        
        -- Check if data actually changed
        if self:IsValueEqual(originalValue, value) then
            LOG.std(nil, "info", "PersonalPageStore", "Value unchanged, skipping save")
            return
        end
        if key and key ~= "" and key ~= "metadata" and key ~= "_metadata" and value == nil then
            self.personalPageDataDeleted[pageName] = self.personalPageDataDeleted[pageName] or {}
            table.insert(self.personalPageDataDeleted[pageName], key)
        else
            SetValueByPath(self.personalPageDataUpdated[pageName], key, value)
            -- 如果之前标记为删除，现在设置了新值，需要从删除列表中移除
            if self.personalPageDataDeleted[pageName] then
                for i = #self.personalPageDataDeleted[pageName], 1, -1 do
                    if self.personalPageDataDeleted[pageName][i] == key then
                        table.remove(self.personalPageDataDeleted[pageName], i)
                        break
                    end
                end
            end
        end

        self.pendingDiskPages[pageName] = true
        self.pendingSync[pageName] = true
        self:DebouncedDiskSave()
        if bFlush then
            self:BatchSyncToRemote(true)
        else
            self:CheckInitSyncTimers()
        end
    end)
end

-- Delete page data (explicit delete method)
function PersonalPageStore:DeletePageData(pageName, key, bFlush)
    pageName = NormalizePageName(pageName)
    if not key or key == "" or key == "metadata" or key == "_metadata" then
        LOG.std(nil, "warn", "PersonalPageStore", "Cannot delete empty key or metadata")
        return false
    end
    self:CheckLoadData(pageName, function()
        self.personalPageData[pageName] = self.personalPageData[pageName] or {}
        self.personalPageDataUpdated[pageName] = self.personalPageDataUpdated[pageName] or {}
        self.personalPageDataDeleted[pageName] = self.personalPageDataDeleted[pageName] or {}
        
        -- Check if key exists in current data
        local existsInOriginal = GetValueByPath(self.personalPageData[pageName], key) ~= nil
        local existsInUpdated = GetValueByPath(self.personalPageDataUpdated[pageName], key) ~= nil
        
        if not existsInOriginal and not existsInUpdated then
            LOG.std(nil, "info", "PersonalPageStore", "Key does not exist, nothing to delete: %s", key)
            return false
        end
        
        -- Add to deleted keys list if not already there
        local alreadyDeleted = false
        for _, deletedKey in ipairs(self.personalPageDataDeleted[pageName]) do
            if deletedKey == key then
                alreadyDeleted = true
                break
            end
        end
        
        if not alreadyDeleted then
            table.insert(self.personalPageDataDeleted[pageName], key)
        end
        
        -- Remove from updated data if exists
        if existsInUpdated then
            DeleteValueByPath(self.personalPageDataUpdated[pageName], key)
        end
        
        self.pendingDiskPages[pageName] = true
        self.pendingSync[pageName] = true
        self:DebouncedDiskSave()
        if bFlush then
            self:BatchSyncToRemote(true)
        else
            self:CheckInitSyncTimers()
        end
        LOG.std(nil, "info", "PersonalPageStore", "Marked key for deletion: %s", key)
    end)
    return true
end

-- Load page data with version checking
-- @param pageName: string - Page name
-- @param key: string - Data key (supports dot notation)
-- @param callback: function - Callback function
-- @param forceRemote: boolean - If true, skip local data and force load from remote only
function PersonalPageStore:LoadPageData(pageName, key, callback, forceRemote)
    pageName = NormalizePageName(pageName)
    
    -- If forceRemote is true, clear local cache and load from remote only
    if forceRemote then
        -- Clear local cached data for this page to ensure remote data takes priority
        self.personalPageData[pageName] = {}
        self.personalPageDataUpdated[pageName] = {}
        -- Reset both load status flags to force reload
        self.pageStatus[pageName] = self.pageStatus[pageName] or {}
        self.pageStatus[pageName]._localVersionChecked = true  -- Mark as checked but data is cleared
        self.pageStatus[pageName]._remoteVersionChecked = false
        
        -- Directly load from remote, skip disk loading
        self:CheckMergeRemoteData(pageName, true, function()
            -- Get the value from remote-loaded data
            local originalValue = GetValueByPath(self.personalPageData[pageName], key)
            local originalResult = originalValue and isValidValue(originalValue) and originalValue or nil
            local result = commonlib.deepcopy(originalResult)
            if callback and type(callback) == "function" then
                callback(result)
            end
            return result
        end)
        return
    end
    
    self:CheckLoadData(pageName, function()
        if not self.personalPageData[pageName] then
            self.personalPageData[pageName] = {}
        end
        if not self.personalPageDataUpdated[pageName] then
            self.personalPageDataUpdated[pageName] = {}
        end
        -- Check if we have updated data first (highest priority)
        -- use copy to avoid modify original data
        local updatedValue = GetValueByPath(self.personalPageDataUpdated[pageName], key)
        local updateResult = commonlib.deepcopy(updatedValue)
        if updateResult and isValidValue(updateResult) then
            if callback and type(callback) == "function" then
                callback(updateResult)
            end
            return updateResult
        end
        
        -- Get the original value 
        local originalValue = GetValueByPath(self.personalPageData[pageName], key)
        local originalResult = originalValue and isValidValue(originalValue) and originalValue or nil
        local result = commonlib.deepcopy(originalResult)
        if callback and type(callback) == "function" then
            callback(result)
        end
        return result
    end)
end

function PersonalPageStore:RefreshPageData(pageName)
   pageName = NormalizePageName(pageName)
   self.personalPageData[pageName] = {}
   self.personalPageDataUpdated[pageName] = {}
   self.personalPageDataDeleted[pageName] = {}
   self.pageStatus[pageName] = {}
end

function PersonalPageStore:RefreshLoadStatus(pageName)
    pageName = NormalizePageName(pageName)
    self.pageStatus[pageName] = self.pageStatus[pageName] or {}
    self.pageStatus[pageName]._localVersionChecked = false
    self.pageStatus[pageName]._remoteVersionChecked = false
end

-- Check and load data with version management
function PersonalPageStore:CheckLoadData(pageName, callback)
    pageName = NormalizePageName(pageName)
    self.pageStatus[pageName] = self.pageStatus[pageName] or {}
    
    local loadFromDisk = function()
        if not self.pageStatus[pageName]._localVersionChecked then
            self:CheckLoadPageFromDisk(pageName, false, function()
                if not self.pageStatus[pageName]._remoteVersionChecked then
                    self:CheckMergeRemoteData(pageName, false, callback)
                else
                    if callback then callback() end
                end
            end)
        else
            if not self.pageStatus[pageName]._remoteVersionChecked then
                self:CheckMergeRemoteData(pageName, false, callback)
            else
                if callback then callback() end
            end
        end
    end
    
    loadFromDisk()
end

-- Load page from disk
function PersonalPageStore:CheckLoadPageFromDisk(pageName, forceRefresh, callback)
    pageName = NormalizePageName(pageName)
    self.pageStatus[pageName] = self.pageStatus[pageName] or {}
    
    local localVersionChecked = self.pageStatus[pageName]._localVersionChecked
    
    if not localVersionChecked or forceRefresh then
        self.pageStatus[pageName]._localVersionChecked = true
        
        -- Initialize page data if needed
        if not self.personalPageData[pageName] then
            self.personalPageData[pageName] = {}
        end
        
        local localPath = self:GetLocalPagePath(pageName)
        local file = ParaIO.open(localPath, "r")
        if file and file:IsValid() then
            local content = file:GetText(0, -1)
            file:close()
            if content and content ~= "" then
                -- Parse YAML data
                local pageData = YamlConverter.YAMLToLua(content)
                if pageData then
                    self:MergeData(self.personalPageData[pageName], pageData)
                    local metadata = self:GetMetadata(pageData)
                    LOG.std(nil, "info", "PersonalPageStore", "load page data %s version: %s from disk", pageName, metadata and metadata.version or "unknown")
                end
            end
        end
    end
    
    if callback then callback() end
end

-- Check and merge remote data
function PersonalPageStore:CheckMergeRemoteData(pageName, forceRefresh, callback)
    pageName = NormalizePageName(pageName)
    -- Check if we already have loaded remote data for this page
    self.pageStatus[pageName] = self.pageStatus[pageName] or {}

    if self.pageStatus[pageName]._remoteVersionChecked and not forceRefresh then
        if callback then callback() end
        return
    end
    
    self.pageStatus[pageName]._remoteVersionChecked = true
    
    if self:IsUseLocal() then
        if callback then callback() end
        return
    end
    
    local localMetadata = self:GetMetadata(self.personalPageData[pageName] or {})
    local remotePath = self:GetRemotePagePath(pageName)
    local bUseCache = pageName == "game_activity_candybox"
    KeepworkSiteService:GetMarkdownByFullPath(remotePath, function(remoteDataContent)
        -- 增强异常处理：即使远程获取失败也要继续执行回调
        local success = false
        
        if remoteDataContent and remoteDataContent ~= "" then
            local remoteData = YamlConverter.YAMLToLua(remoteDataContent)
            if remoteData and type(remoteData) == "table" then
                -- Compare versions to determine which data to use
                local remoteMetadata = self:GetMetadata(remoteData)
                local localVersion = localMetadata.version or 0
                local remoteVersion = remoteMetadata.version or 0
                
                if remoteVersion > localVersion then
                    -- Remote is newer - use remote data
                    LOG.std(nil, "info", "PersonalPageStore", "Using remote data (v%s) over local (v%s) for page: %s", remoteVersion, localVersion, pageName)
                    
                    local wasEmpty = isemptytable(self.personalPageData[pageName])
                    if wasEmpty then
                        self.personalPageData[pageName] = remoteData
                    else
                        -- Merge remote data
                        for k, v in pairs(remoteData) do
                            if k ~= "metadata" and (not self.personalPageData[pageName][k] or self.personalPageData[pageName][k] ~= v) then
                                -- Only update if we don't have pending updates for this key
                                local hasPendingUpdate = GetValueByPath(self.personalPageDataUpdated[pageName], k)
                                if not hasPendingUpdate then
                                    SetValueByPath(self.personalPageData[pageName], k, v)
                                end
                            end
                        end
                        -- Always update metadata using SetMetadata method
                        self:SetMetadata(self.personalPageData[pageName], remoteMetadata)
                    end
                    
                    -- Force save updated data to disk
                    self:SaveToDisk(pageName, true)
                    success = true
                else
                    LOG.std(nil, "info", "PersonalPageStore", "Local data (v%s) is newer or equal to remote (v%s) for page: %s", localVersion, remoteVersion, pageName)
                    success = true
                end
            else
                LOG.std(nil, "error", "PersonalPageStore", "Failed to parse remote YAML data for page: %s", pageName)
            end
        else
            LOG.std(nil, "info", "PersonalPageStore", "Remote page not found or empty for: %s, using local data", pageName)
        end
        
        -- 无论远程获取是否成功，都要执行回调以确保本地数据处理逻辑继续
        if callback then callback() end
    end, bUseCache)
end

-- Save to disk
function PersonalPageStore:SaveToDisk(pageName, forceSave, callback)
    pageName = NormalizePageName(pageName)
    local localPath = self:GetLocalPagePath(pageName)
    if not localPath then 
        if callback then callback(false) end
        return false 
    end

    local hasUpdate = self.personalPageDataUpdated[pageName] and next(self.personalPageDataUpdated[pageName]) ~= nil
    local hasDeleted = self.personalPageDataDeleted[pageName] and #self.personalPageDataDeleted[pageName] > 0
    if not forceSave and not hasUpdate and not hasDeleted then
        -- No updated or deleted data, don't save
        if callback then callback(false) end
        return false
    end

    self.personalPageData[pageName] = self.personalPageData[pageName] or {}
    local mergedData = commonlib.deepcopy(self.personalPageData[pageName])
    
    if hasUpdate then
        self:MergeData(mergedData, self.personalPageDataUpdated[pageName] or {})
    end
    
    -- Process deleted keys
    if hasDeleted then
        for _, deletedKey in ipairs(self.personalPageDataDeleted[pageName]) do
            DeleteValueByPath(mergedData, deletedKey)
            LOG.std(nil, "info", "PersonalPageStore", "Deleted key from disk save: %s", deletedKey)
        end
    end
    
    local existingMetadata = self:GetMetadata(mergedData)
    if hasUpdate or not existingMetadata or not existingMetadata.version then
        local newMetadata = self:GenerateVersion(mergedData)
        self:SetMetadata(mergedData, newMetadata)
    end
    
    local yamlContent = YamlConverter.LuaToYAML(mergedData)
    local file = ParaIO.open(localPath, "w")
    if file then
        file:WriteString(yamlContent)
        file:close()
        
        local metadata = self:GetMetadata(mergedData)
        LOG.std(nil, "info", "PersonalPageStore", "page %s data saved to disk with version %s and filepath %s", pageName, metadata and metadata.version or "unknown", localPath)
        -- Update memory and clear pending updates
        self.personalPageData[pageName] = mergedData
        if self:IsUseLocal() then
            self.personalPageDataUpdated[pageName] = {}
            self.personalPageDataDeleted[pageName] = {}
        end
        if callback then callback(true) end
        return true
    end
    
    if callback then callback(false) end
    return false
end

-- Debounced disk save
function PersonalPageStore:DebouncedDiskSave()
    if not self.diskSaveTimer then
        self.diskSaveTimer = commonlib.Timer:new({
            callbackFunc = function()
                self:BatchSaveToDisk()
                self.diskSaveTimer = nil
            end
        })
    end
    self.diskSaveTimer:Change(500, nil) -- 500ms delay, single shot
end

-- Batch save to disk
function PersonalPageStore:BatchSaveToDisk()
    local pageCount = 0
    
    for pageName, _ in pairs(self.pendingDiskPages) do
        if self:SaveToDisk(pageName, false) then
            pageCount = pageCount + 1
        end
    end
    
    self.pendingDiskPages = {}
    GameLogic.FlushDiskIO()
    return pageCount
end

-- Sync to remote
function PersonalPageStore:SyncToGit(pageName, callback)
    pageName = NormalizePageName(pageName)
    if self:IsUseLocal() then
        if callback then callback(true) end
        return true
    end
    self:CheckMergeRemoteData(pageName, true, function()
        if not self.pendingSync[pageName] then
            LOG.std(nil, "info", "PersonalPageStore", "No pending updates for page: %s, clearing sync status", pageName)
            if callback then callback(true) end
            return true
        end
        local remotePath = self:GetRemotePagePath(pageName)
        
        -- Create a copy of current data for syncing
        local syncData = commonlib.deepcopy(self.personalPageData[pageName] or {})
        
        -- merge updated page data 
        self:MergeData(syncData, self.personalPageDataUpdated[pageName] or {})
        
        -- Process deleted keys
        if self.personalPageDataDeleted[pageName] and #self.personalPageDataDeleted[pageName] > 0 then
            for _, deletedKey in ipairs(self.personalPageDataDeleted[pageName]) do
                DeleteValueByPath(syncData, deletedKey)
                LOG.std(nil, "info", "PersonalPageStore", "Deleted key from remote sync: %s", deletedKey)
            end
        end
        
        local yamlContent = YamlConverter.LuaToYAML(syncData)
        local bUseCache = pageName == "game_activity_candybox"
        KeepworkSiteService:EditMarkdownByFullPath(remotePath, yamlContent, function(success)
            self.pendingSync[pageName] = nil
            if success then
                -- Update local data with synced data and clear pending changes
                self.personalPageData[pageName] = syncData
                self.personalPageDataUpdated[pageName] = {}
                self.personalPageDataDeleted[pageName] = {}
                local metadata = self:GetMetadata(syncData or {})
                LOG.std(nil, "info", "PersonalPageStore", "successfully sync %s version %s to Git", pageName, metadata and metadata.version or "unknown")
                if callback then callback(true) end
            else
                LOG.std(nil, "error", "PersonalPageStore", "failed to sync %s to Git", pageName)
                if callback then callback(false) end
            end
        end, bUseCache)
    end)
end

-- Batch sync to remote
function PersonalPageStore:BatchSyncToRemote(forceSync)
    -- Avoid duplicate syncing
    if self.isSyncing and not forceSync then
        return 0
    end
    
    -- First ensure all data is saved to disk
    self:BatchSaveToDisk()

    -- Check if there are pages pending sync
    local hasPendingSync = next(self.pendingSync) ~= nil
    
    if not hasPendingSync then
        return 0
    end

    self.isSyncing = true
    local syncCount = 0
    local totalPages = 0
    
    for pageName, _ in pairs(self.pendingSync) do
        totalPages = totalPages + 1
    end
    
    local completedPages = 0
    
    for pageName, _ in pairs(self.pendingSync) do
        self:SyncToGit(pageName, function(success)
            if success then
                syncCount = syncCount + 1
            end
            completedPages = completedPages + 1
            
            -- Check if all pages completed
            if completedPages >= totalPages then
                self.isSyncing = false
            end
        end)
    end
    
    return syncCount
end

-- Save page data as time series with key-value operations
-- @param pageName: string - Page name
-- @param keyValues: table - Array of {key="time", value=20250806, type="unique"} objects
-- @param maxKeyCount: number - Maximum number of items to keep in arrays (default: 10)
-- keyValues format: {{key="time", value=20250806, type="unique"}, {key="age", value=8, type="replace"}, {key="totalScore", value=10, type="addictive"}, {key="accuracy", value=90, type="mean"}}
-- The saved page data are always arrays of maxKeyCount items at most. The newly added keys are inserted at the beginning of the array.
-- When there is a unique key and it has same value of the front item, all (other) values will update the front item according to value type parameter.
-- The value type can be "unique", "replace", "addictive" or "mean".
-- The default value type is "replace", which will simply let the new value to replace old value at the front item.
-- If type is "addictive", the new value will be added to the front item, and the front item will be updated to the sum of all values.
-- If type is "mean", the new value will be added to the front item, and the front item will be updated to the mean of all values.
function PersonalPageStore:SavePageDataTimeSeries(pageName, keyValues, maxKeyCount, callback)
    pageName = NormalizePageName(pageName)
    maxKeyCount = maxKeyCount or 10
    
    -- Find the unique key if any
    local uniqueKey = nil
    for _, kv in ipairs(keyValues) do
        if kv.type == "unique" then
            uniqueKey = kv
            break
        end
    end
    
    local isReplaceOperation = false
    
    local processKeyValues = function()
        if uniqueKey then
            self:LoadPageData(pageName, uniqueKey.key, function(oldValue)
                -- Check if oldValue is array and compare with first element
                local compareValue = oldValue
                if type(oldValue) == "table" and #oldValue > 0 then
                    compareValue = oldValue[1]
                end
                
                if uniqueKey.value == compareValue then
                    isReplaceOperation = true
                    
                    local processedCount = 0
                    local totalCount = #keyValues
                    
                    for _, kv in ipairs(keyValues) do
                        self:LoadPageData(pageName, kv.key, function(values)
                            values = (not values or type(values) ~= "table") and {} or values
                            
                            -- Ensure it's an array by creating a copy (equivalent to Array.from(values))
                            local valuesArray = {}
                            if type(values) == "table" and #values > 0 then
                                for i = 1, #values do
                                    valuesArray[i] = values[i]
                                end
                            end
                            
                            -- Update the front item with the new value (same logic as JS)
                            if kv.type == "addictive" then
                                -- Add to the front item
                                if #valuesArray > 0 then
                                    valuesArray[1] = (valuesArray[1] or 0) + kv.value
                                else
                                    -- Use push equivalent (table.insert at end)
                                    table.insert(valuesArray, kv.value)
                                end
                            elseif kv.type == "mean" then
                                -- Calculate mean and update front item
                                if #valuesArray > 0 then
                                    valuesArray[1] = ((valuesArray[1] or 0) + kv.value) / 2
                                else
                                    -- Use push equivalent (table.insert at end)
                                    table.insert(valuesArray, kv.value)
                                end
                            else
                                -- Default replace operation (must handle empty array case)
                                if #valuesArray > 0 then
                                    valuesArray[1] = kv.value
                                else
                                    -- If array is empty, we need to add the value first
                                    table.insert(valuesArray, kv.value)
                                end
                            end
                            
                            kv.values = valuesArray
                            processedCount = processedCount + 1
                            
                            if processedCount >= totalCount then
                                self:FinalizeTimeSeries(pageName, keyValues, maxKeyCount, callback)
                            end
                        end)
                    end
                else
                    -- Process normal time series (append to front)
                    self:ProcessNormalTimeSeries(pageName, keyValues, maxKeyCount, callback)
                end
            end)
        else
            self:ProcessNormalTimeSeries(pageName, keyValues, maxKeyCount, callback)
        end
    end
    processKeyValues()
end

-- Process normal time series (append to front) - matches JS logic exactly
function PersonalPageStore:ProcessNormalTimeSeries(pageName, keyValues, maxKeyCount, callback)
    local processedCount = 0
    local totalCount = #keyValues
    
    for _, kv in ipairs(keyValues) do
        self:LoadPageData(pageName, kv.key, function(values)
            values = (not values or type(values) ~= "table") and {} or values
            
            -- Ensure it's an array by creating a copy (equivalent to Array.from(values))
            local valuesArray = {}
            if type(values) == "table" and #values > 0 then
                for i = 1, #values do
                    valuesArray[i] = values[i]
                end
            end
            
            -- Insert new value at the front (equivalent to values.unshift(kv.value) in JS)
            -- This is the key difference: JS always uses unshift for non-replace operations
            table.insert(valuesArray, 1, kv.value)
            
            kv.values = valuesArray
            
            processedCount = processedCount + 1
            if processedCount >= totalCount then
                self:FinalizeTimeSeries(pageName, keyValues, maxKeyCount, callback)
            end
        end)
    end
end

-- Finalize time series processing
function PersonalPageStore:FinalizeTimeSeries(pageName, keyValues, maxKeyCount, callback)
    -- Trim kv.values to maximum of maxKeyCount
    for _, kv in ipairs(keyValues) do
        if kv.values and type(kv.values) == "table" and #kv.values > maxKeyCount then
            local trimmedValues = {}
            for i = 1, maxKeyCount do
                trimmedValues[i] = kv.values[i]
            end
            kv.values = trimmedValues
        end
    end
    
    -- Save all keyValues
    local savedCount = 0
    local totalCount = #keyValues
    for _, kv in ipairs(keyValues) do
        self:SavePageData(pageName, kv.key, kv.values)
        savedCount = savedCount + 1
        
        if savedCount >= totalCount and callback then
            callback(true)
        end
    end
    
    if totalCount == 0 and callback then
        callback(false)
    end
end

-- Utility methods for multi-key operations (keeping from original)
function PersonalPageStore:SaveMultiKeysPageData(pageName, keysValueMap, bFlush)
    pageName = NormalizePageName(pageName)
    if not keysValueMap or type(keysValueMap) ~= "table" then
        return
    end
    
    -- Initialize page data if needed
    self.personalPageData[pageName] = self.personalPageData[pageName] or {}
    self.personalPageDataUpdated[pageName] = self.personalPageDataUpdated[pageName] or {}
    
    local hasChanges = false
    -- Check all key-value pairs for changes
    for key, value in pairs(keysValueMap) do
        local originalValue = GetValueByPath(self.personalPageData[pageName], key)
        
        if not self:IsValueEqual(originalValue, value) then
            SetValueByPath(self.personalPageDataUpdated[pageName], key, value)
            hasChanges = true
        end
    end
    if hasChanges then
        self.pendingDiskPages[pageName] = true
        self.pendingSync[pageName] = true
        self:DebouncedDiskSave()
        if bFlush then
            self:BatchSyncToRemote(true)
        else
            self:CheckInitSyncTimers()
        end
    end
end

function PersonalPageStore:LoadMultiKeysPageData(pageName, keys, callback)
    pageName = NormalizePageName(pageName)
    if not keys or type(keys) ~= "table" or #keys == 0 then
        if callback then callback({}) end
        return
    end
    
    self:CheckLoadData(pageName, function()
        local result = {}
        
        for _, key in ipairs(keys) do
            local updatedValue = GetValueByPath(self.personalPageDataUpdated[pageName], key)
            if updatedValue and isValidValue(updatedValue) then
                result[key] = updatedValue
            else
                local originalValue = GetValueByPath(self.personalPageData[pageName], key)
                if originalValue and isValidValue(originalValue) then
                    result[key] = originalValue
                end
            end
        end
        
        if callback then callback(result) end
    end)
end

-- Convenience methods
function PersonalPageStore:SaveKeys(pageName, keyOrMap, valueOrNil, bFlush)
    if type(keyOrMap) == "table" and valueOrNil == nil then
        self:SaveMultiKeysPageData(pageName, keyOrMap, bFlush)
    else
        self:SavePageData(pageName, keyOrMap, valueOrNil, bFlush)
    end
end

function PersonalPageStore:LoadKeys(pageName, keys, callback)
    if type(keys) == "table" then
        self:LoadMultiKeysPageData(pageName, keys, callback)
    else
        self:LoadPageData(pageName, keys, callback)
    end
end

-- Delete multiple keys from page data
function PersonalPageStore:DeleteMultiKeysPageData(pageName, keys, bFlush)
    pageName = NormalizePageName(pageName)
    if not keys or type(keys) ~= "table" or #keys == 0 then
        LOG.std(nil, "warn", "PersonalPageStore", "personalPageStore:deleteMultiKeys invalid keys: %s", tostring(keys))
        return 0
    end
    
    self:CheckLoadData(pageName, function()
        self.personalPageData[pageName] = self.personalPageData[pageName] or {}
        self.personalPageDataUpdated[pageName] = self.personalPageDataUpdated[pageName] or {}
        self.personalPageDataDeleted[pageName] = self.personalPageDataDeleted[pageName] or {}
        
        local deletedCount = 0
        for _, key in ipairs(keys) do
            -- Validate key
            if key and key ~= "" and key ~= "metadata" and key ~= "_metadata" then
                -- Check if key exists
                local exists = GetValueByPath(self.personalPageDataUpdated[pageName], key) ~= nil or
                              GetValueByPath(self.personalPageData[pageName], key) ~= nil
                
                if exists then
                    -- Add to deleted keys if not already present
                    local found = false
                    for _, deletedKey in ipairs(self.personalPageDataDeleted[pageName]) do
                        if deletedKey == key then
                            found = true
                            break
                        end
                    end
                    if not found then
                        table.insert(self.personalPageDataDeleted[pageName], key)
                    end
                    
                    -- Remove from updated data structures
                    DeleteValueByPath(self.personalPageDataUpdated[pageName], key)
                    DeleteValueByPath(self.personalPageData[pageName], key)
                    
                    deletedCount = deletedCount + 1
                    LOG.std(nil, "info", "PersonalPageStore", "personalPageStore:delete %s %s", pageName, key)
                else
                    LOG.std(nil, "info", "PersonalPageStore", "personalPageStore:delete key not found: %s", key)
                end
            else
                LOG.std(nil, "warn", "PersonalPageStore", "personalPageStore:delete invalid key: %s", tostring(key))
            end
        end
        
        if deletedCount > 0 then
            self.pendingDiskPages[pageName] = true
            self.pendingSync[pageName] = true
            self:DebouncedDiskSave()
            if bFlush then
                self:BatchSyncToRemote(true)
            else
                self:CheckInitSyncTimers()
            end
            LOG.std(nil, "info", "PersonalPageStore", "Marked key for deletion: %s", key)
        end
    end)
end

-- Delete keys (convenience method)
function PersonalPageStore:DeleteKeys(pageName, keys, bFlush)
    if type(keys) == "table" then
        self:DeleteMultiKeysPageData(pageName, keys, bFlush)
    else
        self:DeletePageData(pageName, keys, bFlush)
    end
end

-- Load page data as number, returns first value if array
-- @param pageName: string - Page name
-- @param key: string - Data key (supports dot notation)
-- @param callback: function - Callback function
-- @returns number|nil - Number value or nil if not found
function PersonalPageStore:LoadPageDataAsNumber(pageName, key, callback)
    pageName = NormalizePageName(pageName)
    self:LoadPageData(pageName, key, function(value)
        -- If value is array return its first value
        if type(value) == "table" and #value > 0 then
            value = value[1]
        end
        
        local result = (type(value) == "number") and value or nil
        
        if callback and type(callback) == "function" then
            callback(result)
        end
        
        return result
    end)
end

-- Clear data methods
function PersonalPageStore:ClearLocalDisk(pageName)
    pageName = NormalizePageName(pageName)
    local localPath = self:GetLocalPagePath(pageName)
    if not localPath then
        return false
    end

    -- Remove file
    if ParaIO.DoesFileExist(localPath) then
        ParaIO.DeleteFile(localPath)
    end
    
    -- Clear in-memory data
    if self.personalPageData[pageName] then
        self.personalPageData[pageName] = nil
    end
    if self.personalPageDataUpdated[pageName] then
        self.personalPageDataUpdated[pageName] = nil
    end
    
    -- Remove from pending operations
    self.pendingDiskPages[pageName] = nil
    
    LOG.std(nil, "info", "PersonalPageStore", "Successfully cleared local disk data for page: %s", pageName)
    return true
end

function PersonalPageStore:ClearRemotePage(pageName, callback)
    pageName = NormalizePageName(pageName)
    if self:IsUseLocal() then
        if callback then callback(true) end
        return true
    end

    local remotePath = self:GetRemotePagePath(pageName)
    KeepworkSiteService:DeleteMarkdownByFullPath(remotePath, function(success)
        if success then
            -- Remove from pending sync since the remote file no longer exists
            self.pendingSync[pageName] = nil
            LOG.std(nil, "info", "PersonalPageStore", "Successfully cleared remote page: %s", pageName)
        else
            LOG.std(nil, "error", "PersonalPageStore", "Error clearing remote page %s", pageName)
        end
        if callback then callback(success) end
    end)
end

function PersonalPageStore:ClearPageData(pageName, callback)
    self:ClearLocalDisk(pageName)
    self:ClearRemotePage(pageName, callback)
end

PersonalPageStore:InitSingleton()
