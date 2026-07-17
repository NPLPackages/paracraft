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
    
    -- Mounted folder system (readonly fallback layers)
    self.mountedLocalDir = nil       -- string: local disk absolute path (trailing /)
    self.mountedRemoteFolder = nil   -- table: { username, workspace, remoteStorePath }
    
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
    self.mountedLocalDir = nil
    self.mountedRemoteFolder = nil
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
    -- Ensure the parent directory exists (not the file itself)
    local parentDir = filepath:match("^(.*[/\\])")
    if parentDir and not ParaIO.DoesFileExist(parentDir) then
        ParaIO.CreateDirectory(parentDir)
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
            -- Dedup: only add if not already in the deleted list
            local alreadyInList = false
            for _, dk in ipairs(self.personalPageDataDeleted[pageName]) do
                if dk == key then alreadyInList = true; break end
            end
            if not alreadyInList then
                table.insert(self.personalPageDataDeleted[pageName], key)
            end
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

        if bFlush then
            -- Save to disk immediately so the version is bumped before remote sync,
            -- matching the JavaScript fix for stale-metadata race.
            self:SaveToDisk(pageName)
            self.pendingDiskPages[pageName] = nil
            self:BatchSyncToRemote(true)
        else
            self:DebouncedDiskSave()
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
        
        -- Also remove from base data so LoadPageData won't return stale value
        if existsInOriginal then
            DeleteValueByPath(self.personalPageData[pageName], key)
        end
        
        self.pendingDiskPages[pageName] = true
        self.pendingSync[pageName] = true

        if bFlush then
            self:SaveToDisk(pageName)
            self.pendingDiskPages[pageName] = nil
            self:BatchSyncToRemote(true)
        else
            self:DebouncedDiskSave()
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
                local pageData = YamlConverter.YAMLToLua(content, {useFrontMatter=true})
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
-- @param pageName: string - Page name
-- @param forceRefresh: boolean - Force reload from remote
-- @param callback: function - Callback after merge
-- @param bUseCache: boolean (optional) - Use cached remote response. Default: auto per page name.
function PersonalPageStore:CheckMergeRemoteData(pageName, forceRefresh, callback, bUseCache)
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
    if bUseCache == nil then
        bUseCache = pageName == "game_activity_candybox"
    end
    KeepworkSiteService:GetMarkdownByFullPath(remotePath, function(remoteDataContent)
        -- 增强异常处理：即使远程获取失败也要继续执行回调
        local success = false
        
        if remoteDataContent and remoteDataContent ~= "" then
            local remoteData = YamlConverter.YAMLToLua(remoteDataContent, {useFrontMatter=true})
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
            -- Allow retry on next access since remote was empty (might be transient)
            self.pageStatus[pageName]._remoteVersionChecked = false
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
    if hasUpdate or hasDeleted or not existingMetadata or not existingMetadata.version then
        local newMetadata = self:GenerateVersion(mergedData)
        self:SetMetadata(mergedData, newMetadata)
    end
    
    local yamlContent = YamlConverter.LuaToYAML(mergedData, {useFrontMatter=true})
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
        
        local yamlContent = YamlConverter.LuaToYAML(syncData, {useFrontMatter=true})
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

--------------------------------------------------------------------------------
-- Mounted Folder System
-- Readonly fallback layers for file operations.
-- Fallback order: workspace → local mount → remote mount.
--------------------------------------------------------------------------------

-- Mount a local disk directory as readonly fallback.
-- Files in this directory can be read but not written.
-- @param dirPath: string|nil - Absolute path to local directory. nil/empty to unmount.
function PersonalPageStore:MountLocalFolder(dirPath)
    if not dirPath or dirPath == "" then
        self.mountedLocalDir = nil
        LOG.std(nil, "info", "PersonalPageStore", "Unmounted local folder")
        return
    end
    dirPath = string.gsub(dirPath, "\\", "/")
    if not string.match(dirPath, "/$") then
        dirPath = dirPath .. "/"
    end
    self.mountedLocalDir = dirPath
    LOG.std(nil, "info", "PersonalPageStore", "Mounted local folder: %s", dirPath)
end

-- Mount a remote Keepwork folder as readonly fallback.
-- Path format: "username/site/workspace" or "username/workspace" (site defaults to self.remoteStorePath).
-- @param path: string|nil - Remote path. nil/empty to unmount.
function PersonalPageStore:MountRemoteFolder(path)
    if not path or path == "" then
        self.mountedRemoteFolder = nil
        LOG.std(nil, "info", "PersonalPageStore", "Unmounted remote folder")
        return
    end
    path = string.gsub(path, "^/+", "")
    path = string.gsub(path, "/+$", "")
    local parts = {}
    for segment in string.gmatch(path, "[^/]+") do
        table.insert(parts, segment)
    end
    if #parts < 2 then
        LOG.std(nil, "warn", "PersonalPageStore", "MountRemoteFolder: path requires at least username/workspace, got '%s'", path)
        return
    end
    local username = parts[1]
    local workspace = parts[#parts]
    local remoteStorePath = self.remoteStorePath
    if #parts > 2 then
        remoteStorePath = table.concat(parts, "/", 2, #parts - 1)
    end
    self.mountedRemoteFolder = {
        username = username,
        workspace = workspace,
        remoteStorePath = remoteStorePath,
    }
    LOG.std(nil, "info", "PersonalPageStore", "Mounted remote folder: %s/%s/%s", username, remoteStorePath, workspace)
end

-- Unmount all mounted folders.
function PersonalPageStore:UnmountFolder()
    if self.mountedLocalDir then
        LOG.std(nil, "info", "PersonalPageStore", "Unmounted local folder: %s", self.mountedLocalDir)
        self.mountedLocalDir = nil
    end
    if self.mountedRemoteFolder then
        LOG.std(nil, "info", "PersonalPageStore", "Unmounted remote folder")
        self.mountedRemoteFolder = nil
    end
end

-- Build the full remote page path for a file inside the mounted remote folder.
-- @param pageName: string - Page name (relative, no extension)
-- @return string|nil - Full path like "username/storePath/workspace/pageName"
function PersonalPageStore:_GetMountedRemotePagePath(pageName)
    local m = self.mountedRemoteFolder
    if not m then return nil end
    return string.format("%s/%s/%s/%s", m.username, m.remoteStorePath, m.workspace, pageName)
end

-- Get remote tree params for the mounted remote folder.
-- @return table|nil - { sitePath, folderBase } or nil
function PersonalPageStore:_GetMountedRemoteTreeParams()
    local m = self.mountedRemoteFolder
    if not m then return nil end
    local storePathParts = {}
    for segment in string.gmatch(m.remoteStorePath, "[^/]+") do
        table.insert(storePathParts, segment)
    end
    local siteName = storePathParts[1] or m.remoteStorePath
    local storeSubPath = table.concat(storePathParts, "/", 2)
    local sitePath = m.username .. "/" .. siteName
    local folderBase = (storeSubPath ~= "") and (storeSubPath .. "/" .. m.workspace) or m.workspace
    return { sitePath = sitePath, folderBase = folderBase }
end

-- Read file content from the mounted local directory (readonly).
-- Handles pageName → disk path mapping with extension probing.
-- @param relPath: string - Relative path (may or may not have extension)
-- @return string|nil - File content or nil if not found
function PersonalPageStore:_ReadMountedLocalFile(relPath)
    if not self.mountedLocalDir then return nil end
    if not relPath or relPath == "" then return nil end
    relPath = string.gsub(relPath, "\\", "/")
    -- Path traversal prevention
    if string.find(relPath, "%.%.") then return nil end
    relPath = string.gsub(relPath, "^/+", "")

    -- Helper to try reading a single absolute path
    local function tryRead(absPath)
        local file = ParaIO.open(absPath, "r")
        if file:IsValid() then
            local content = file:GetText(0, -1)
            file:close()
            return content
        else
            file:close()
            return nil
        end
    end

    -- If relPath already has an extension, try directly
    if string.find(relPath, "%.[^/%.]+$") then
        return tryRead(self.mountedLocalDir .. relPath)
    end

    -- Otherwise probe extensions in priority order
    local tryExts = {".md", ".lua", ".txt", ".json", ".xml", ".log", ""}
    for _, ext in ipairs(tryExts) do
        local content = tryRead(self.mountedLocalDir .. relPath .. ext)
        if content then return content end
    end
    return nil
end

-- Read file content from the mounted remote folder (readonly, async).
-- @param pageName: string - Page name (relative, no extension)
-- @param callback: function(content) - Returns content string or nil
function PersonalPageStore:_ReadMountedRemoteFile(pageName, callback)
    if not self.mountedRemoteFolder then
        if callback then callback(nil) end
        return
    end
    local m = self.mountedRemoteFolder
    -- Build path relative to the site: storePath/workspace/pageName
    local sitePath = table.concat({m.remoteStorePath, m.workspace, pageName}, "/")
    KeepworkSiteService:GetMarkdownByFullPath(sitePath, function(remoteContent)
        if remoteContent and remoteContent ~= "" then
            local pageData = YamlConverter.YAMLToLua(remoteContent, {useFrontMatter=true})
            if pageData and type(pageData) == "table" and pageData.content ~= nil then
                if callback then callback(pageData.content) end
                return
            end
            -- Fallback: treat raw content as plain markdown (no YAML frontmatter)
            if callback then callback(remoteContent) end
            return
        end
        if callback then callback(nil) end
    end, true, m.username)
end

-- List files in the mounted local directory.
-- @param subDir: string|nil - Subdirectory relative to mount root
-- @return table - Array of {name, filesize} entries
function PersonalPageStore:_ListMountedLocalDir(subDir)
    if not self.mountedLocalDir then return {} end
    local dir = self.mountedLocalDir
    if subDir and subDir ~= "" then
        local normSub = string.gsub(subDir, "\\", "/")
        if string.find(normSub, "%.%.") then return {} end
        normSub = string.gsub(normSub, "^/+", "")
        if not string.match(normSub, "/$") then normSub = normSub .. "/" end
        dir = dir .. normSub
    end

    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/FileTools.lua")
    local FileTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.FileTools")

    NPL.load("(gl)script/ide/Files.lua")
    -- List subdirectories ("*." pattern matches entries without extension, i.e. directories)
    local dirEntries = commonlib.Files.Find({}, dir, 0, 500)
    -- List allowed-extension files
    local fileEntries = commonlib.Files.Find({}, dir, 0, 500, function(item)
        local ext = commonlib.Files.GetFileExtension(item.filename)
        if ext then
            return FileTools.ALLOWED_EXTENSIONS["." .. ext]
        end
    end)

    local files = {}
    if dirEntries then
        for _, item in ipairs(dirEntries) do
            if item.filename ~= "." and item.filename ~= ".." then
                table.insert(files, { name = item.filename .. "/", filesize = 0 })
            end
        end
    end
    if fileEntries then
        for _, item in ipairs(fileEntries) do
            table.insert(files, { name = item.filename, filesize = item.filesize })
        end
    end
    return files
end

-- List files in the mounted remote folder (async).
-- @param subDir: string|nil - Subdirectory relative to mount workspace
-- @param callback: function(files) - Array of {name, filesize} entries
function PersonalPageStore:_ListMountedRemoteDir(subDir, callback)
    if not self.mountedRemoteFolder then
        if callback then callback({}) end
        return
    end
    local params = self:_GetMountedRemoteTreeParams()
    if not params then
        if callback then callback({}) end
        return
    end

    local folderPath = params.sitePath .. "/" .. params.folderBase
    if subDir and subDir ~= "" then
        subDir = string.gsub(subDir, "\\", "/")
        subDir = string.gsub(subDir, "^/+", "")
        subDir = string.gsub(subDir, "/+$", "")
        folderPath = folderPath .. "/" .. subDir
    end

    local repoPath = Mod.WorldShare.Utils.EncodeURIComponent(params.sitePath)
    repoPath = string.gsub(repoPath, "%%", "%%%%")
    local encodedFolder = Mod.WorldShare.Utils.EncodeURIComponent(folderPath)
    encodedFolder = string.gsub(encodedFolder, "%%", "%%%%")

    keepwork.site.tree({router_params = {
        repoPath = repoPath,
        folderPath = encodedFolder,
        recursive = false,
    }}, function(err, msg, data)
        local files = {}
        if err == 200 and data then
            if type(data) == "table" then
                for _, entry in ipairs(data) do
                    local name = entry.name or ""
                    local isFolder = entry.isTree == true
                    if isFolder then
                        if name ~= "" then
                            table.insert(files, { name = name .. "/", filesize = 0 })
                        end
                    else
                        if not string.match(name, "%.md$") then
                            name = name .. ".md"
                        end
                        if name ~= "" then
                            table.insert(files, { name = name, filesize = entry.size or 0 })
                        end
                    end
                end
            end
        end
        if callback then callback(files) end
    end)
end

-- Build a ReadFile result table from raw content, optionally extracting a line range.
-- @param content: string - Full file content
-- @param startLine: number|nil - 1-based start line
-- @param endLine: number|nil - 1-based end line
-- @param pageName: string - For error messages
-- @return table - {success, content, totalLines, startLine, endLine}
function PersonalPageStore:_BuildLineRangeResult(content, startLine, endLine, pageName)
    if not content then
        return {success = false, error = string.format("File '%s' is empty", pageName or "")}
    end
    -- Count lines
    local totalLines = 1
    local pos = 1
    while true do
        local found = string.find(content, "\n", pos, true)
        if not found then break end
        totalLines = totalLines + 1
        pos = found + 1
    end
    if not startLine and not endLine then
        return {success = true, content = content, totalLines = totalLines}
    end
    local sl = math.max(1, startLine or 1)
    local el = math.min(totalLines, endLine or totalLines)
    local lines = {}
    local lineNum = 0
    for line in (content .. "\n"):gmatch("([^\n]*)\n") do
        lineNum = lineNum + 1
        if lineNum >= sl and lineNum <= el then
            table.insert(lines, line)
        end
        if lineNum > el then break end
    end
    return {
        success = true,
        content = table.concat(lines, "\n"),
        totalLines = totalLines,
        startLine = sl,
        endLine = el,
    }
end

-- Search content string for query matches, returning a GrepSearch-compatible result.
-- @param query: string - Search query
-- @param content: string - File content to search
-- @param filePath: string - File path for result entries
-- @param isPattern: boolean - Whether query is a Lua pattern
-- @param maxResults: number - Max matches to return
-- @return table - {success, matches, totalMatches, truncated}
function PersonalPageStore:_GrepContent(query, content, filePath, isPattern, maxResults)
    maxResults = maxResults or 50
    local lowerQuery = not isPattern and string.lower(query) or nil
    local matches = {}
    local totalMatches = 0
    local lineNum = 0
    for line in (content .. "\n"):gmatch("([^\n]*)\n") do
        lineNum = lineNum + 1
        local found = false
        local matchText = nil
        if isPattern then
            local ok, result = pcall(string.find, line, query)
            if ok and result then
                found = true
                local ok2, captured = pcall(string.match, line, query)
                matchText = (ok2 and captured) or nil
            end
        else
            if string.find(string.lower(line), lowerQuery, 1, true) then
                found = true
            end
        end
        if found then
            totalMatches = totalMatches + 1
            if #matches < maxResults then
                table.insert(matches, {
                    file = filePath,
                    lineNumber = lineNum,
                    line = line,
                    matchText = matchText,
                })
            end
        end
    end
    return {
        success = true,
        matches = matches,
        totalMatches = totalMatches,
        truncated = totalMatches > maxResults,
    }
end

-- Copy content to workspace and apply string replacement.
-- @param pageName: string - Target page name
-- @param content: string - Original content from mount layer
-- @param oldString: string - Text to find
-- @param newString: string - Replacement text
-- @param callback: function(result)
function PersonalPageStore:_CopyOnWriteReplace(pageName, content, oldString, newString, callback)
    -- Verify oldString appears exactly once
    local count = 0
    local searchStart = 1
    local foundPos = nil
    while true do
        local pos = string.find(content, oldString, searchStart, true)
        if not pos then break end
        count = count + 1
        foundPos = pos
        searchStart = pos + 1
    end
    if count == 0 then
        if callback then callback({success = false, error = "oldString not found in file", matchCount = 0}) end
        return
    end
    if count > 1 then
        if callback then callback({success = false, error = string.format("oldString found %d times (must be exactly 1)", count), matchCount = count}) end
        return
    end
    -- Apply replacement (use plain find+concat to avoid pattern interpretation)
    local newContent = string.sub(content, 1, foundPos - 1) .. newString .. string.sub(content, foundPos + #oldString)
    -- Write to workspace via CreateFile
    local ft = self:_getFileTools()
    ft:CreateFile(pageName, newContent, function(createResult)
        if createResult and createResult.success then
            if callback then callback({success = true, matchCount = 1}) end
        else
            if callback then callback({success = false, error = "Failed to write copy-on-write result: " .. (createResult and createResult.error or "unknown")}) end
        end
    end)
end

--------------------------------------------------------------------------------
-- File Operations API
-- Provides file-style CRUD on PersonalPageStore pages (content stored under "content" key).
-- Internally delegates to FileTools in remote mode for consistent implementation.
-- These methods match the JS PersonalPageStore file ops API so both sides
-- present the same capability surface to AI Copilot tools.
--------------------------------------------------------------------------------

-- Lazy-create a FileTools instance in remote mode, scoped to the current workspace.
-- @return FileTools instance
function PersonalPageStore:_getFileTools()
    if not self._fileToolsInstance then
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/FileTools.lua");
        local FileTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.FileTools");
        self._fileToolsInstance = FileTools:new();
    end
    -- Re-sync workspace setting each call (cheap, and keeps it up to date)
    local wsName = self._fileOpsWorkspace or ""
    self._fileToolsInstance:SetWorkSpace(wsName, true)
    return self._fileToolsInstance
end

-- Set the workspace scope for file operations.
-- @param wsName: string - Workspace name (e.g. "papa"). Empty string or nil means root.
function PersonalPageStore:SetFileOpsWorkspace(wsName)
    self._fileOpsWorkspace = wsName or ""
end

-- Check that file operations are scoped to a workspace (safety guard).
-- @param callerName: string - Name of the calling method (for logging)
-- @return boolean - true if scoped, false otherwise
function PersonalPageStore:IsFileOpScoped(callerName)
    if not self._fileOpsWorkspace or self._fileOpsWorkspace == "" then
        LOG.std(nil, "warn", "PersonalPageStore", "%s: no workspace set, call SetFileOpsWorkspace first", callerName or "fileOp")
        return false
    end
    return true
end

-- Read file content by line range.
-- File content is stored under the "content" key of the page.
-- @param pageName: string - Page name / file path (relative to workspace)
-- @param startLine: number (optional) - 1-based start line
-- @param endLine: number (optional) - 1-based end line (inclusive)
-- @param callback: function(result) - result = {success, content, totalLines, startLine, endLine, error}
function PersonalPageStore:ReadFile(pageName, startLine, endLine, callback)
    if not self:IsFileOpScoped("ReadFile") then
        if callback then callback({success = false, error = "No workspace set"}) end
        return
    end
    local ft = self:_getFileTools()
    local self_ = self
    ft:ReadFile(pageName, startLine, endLine, function(result)
        -- Layer 1: workspace found it
        if result and result.success then
            if callback then callback(result) end
            return
        end

        local relPath = pageName or ""

        -- Layer 2: local mount fallback
        local localContent = self_:_ReadMountedLocalFile(relPath)
        if localContent then
            local lineResult = self_:_BuildLineRangeResult(localContent, startLine, endLine, pageName)
            if callback then callback(lineResult) end
            return
        end

        -- Layer 3: remote mount fallback
        self_:_ReadMountedRemoteFile(relPath, function(remoteContent)
            if remoteContent then
                local lineResult = self_:_BuildLineRangeResult(remoteContent, startLine, endLine, pageName)
                if callback then callback(lineResult) end
                return
            end
            -- All layers failed
            if callback then
                callback({success = false, error = string.format(
                    "File '%s' not found in workspace, local mount, or remote mount", pageName)})
            end
        end)
    end)
end

-- Replace exactly one occurrence of oldString with newString in a file's content.
-- @param pageName: string - Page name / file path
-- @param oldString: string - Exact text to find
-- @param newString: string - Replacement text
-- @param callback: function(result) - result = {success, error, matchCount}
function PersonalPageStore:ReplaceStringInFile(pageName, oldString, newString, callback)
    if not self:IsFileOpScoped("ReplaceStringInFile") then
        if callback then callback({success = false, error = "No workspace set"}) end
        return
    end
    local ft = self:_getFileTools()
    local self_ = self
    ft:ReplaceStringInFile(pageName, oldString, newString, function(result)
        -- If workspace had the file (success or error other than "not exist"), return
        if result and result.success then
            if callback then callback(result) end
            return
        end
        -- Check if the error is "file not found" (needs copy-on-write from mount)
        local errMsg = result and result.error or ""
        if not string.find(errMsg, "does not exist", 1, true) then
            -- Error is not "not found" (e.g. multiple matches), pass through
            if callback then callback(result) end
            return
        end

        -- File not in workspace: try reading from mount layers, then CoW
        local relPath = pageName or ""
        local localContent = self_:_ReadMountedLocalFile(relPath)
        if localContent then
            self_:_CopyOnWriteReplace(pageName, localContent, oldString, newString, callback)
            return
        end

        self_:_ReadMountedRemoteFile(relPath, function(remoteContent)
            if remoteContent then
                self_:_CopyOnWriteReplace(pageName, remoteContent, oldString, newString, callback)
                return
            end
            if callback then
                callback({success = false, error = string.format(
                    "File '%s' not found in workspace, local mount, or remote mount", pageName)})
            end
        end)
    end)
end

-- Search for a pattern in files.
-- Supports single-file search (filePath = specific file) and global/directory search
-- (filePath = nil or ends with "/"). Global search scans cached files and mounted folders.
-- @param query: string - Search pattern (plain text or Lua pattern)
-- @param filePath: string (optional) - Specific file to search, nil for global search
-- @param isPattern: boolean (optional) - If true, treat query as Lua pattern
-- @param maxResults: number (optional) - Max matches (default 50)
-- @param callback: function(result) - result = {success, matches, totalMatches, truncated, error}
function PersonalPageStore:GrepSearch(query, filePath, isPattern, maxResults, callback)
    if not self:IsFileOpScoped("GrepSearch") then
        if callback then callback({success = false, error = "No workspace set"}) end
        return
    end
    local ft = self:_getFileTools()
    local self_ = self
    ft:GrepSearch(query, filePath, isPattern, maxResults, function(result)
        -- Single-file search: if workspace found it, return; otherwise try mount layers
        if filePath and not string.match(filePath, "/$") then
            if result and result.success then
                if callback then callback(result) end
                return
            end
            local relPath = filePath
            local localContent = self_:_ReadMountedLocalFile(relPath)
            if localContent then
                local grepResult = self_:_GrepContent(query, localContent, filePath, isPattern, maxResults)
                if callback then callback(grepResult) end
                return
            end
            self_:_ReadMountedRemoteFile(relPath, function(remoteContent)
                if remoteContent then
                    local grepResult = self_:_GrepContent(query, remoteContent, filePath, isPattern, maxResults)
                    if callback then callback(grepResult) end
                    return
                end
                if callback then
                    callback({success = false, error = string.format(
                        "File '%s' not found in workspace, local mount, or remote mount", filePath)})
                end
            end)
            return
        end

        -- Directory or global search: merge workspace results with mounted file results
        local wsMatches = {}
        local wsSeen = {}  -- track files already matched in workspace
        local totalMatches = 0
        if result and result.success and result.matches then
            for _, m in ipairs(result.matches) do
                table.insert(wsMatches, m)
                if m.file then wsSeen[m.file] = true end
            end
            totalMatches = result.totalMatches or #result.matches
        end

        -- Search mounted local files that are not already in workspace
        local localFiles = self_:_ListMountedLocalDir(filePath)
        for _, f in ipairs(localFiles) do
            local isDir = string.sub(f.name, -1) == "/"
            if not isDir and not wsSeen[f.name] then
                local content = self_:_ReadMountedLocalFile(f.name)
                if content then
                    local grepResult = self_:_GrepContent(query, content, f.name, isPattern, maxResults)
                    if grepResult and grepResult.matches then
                        for _, m in ipairs(grepResult.matches) do
                            table.insert(wsMatches, m)
                        end
                        totalMatches = totalMatches + (grepResult.totalMatches or 0)
                    end
                    wsSeen[f.name] = true
                end
            end
        end

        -- Search mounted remote files that are not already in workspace
        local function finishWithMounted(mountMatches, mountTotal)
            for _, m in ipairs(mountMatches) do
                table.insert(wsMatches, m)
            end
            totalMatches = totalMatches + mountTotal
            if callback then
                callback({
                    success = #wsMatches > 0,
                    matches = wsMatches,
                    totalMatches = totalMatches,
                    truncated = totalMatches > maxResults,
                })
            end
        end

        -- Collect from mounted remote: list all files, then grep each
        if not self_.mountedRemoteFolder then
            finishWithMounted({}, 0)
            return
        end
        self_:_ListMountedRemoteDir(filePath, function(remoteFiles)
            if not remoteFiles or #remoteFiles == 0 then
                finishWithMounted({}, 0)
                return
            end
            local mountMatches = {}
            local mountTotal = 0
            local pending = 0
            for _, f in ipairs(remoteFiles) do
                local isDir = string.sub(f.name, -1) == "/"
                if not isDir and not wsSeen[f.name] then
                    pending = pending + 1
                end
            end
            if pending == 0 then
                finishWithMounted({}, 0)
                return
            end
            local done = 0
            for _, f in ipairs(remoteFiles) do
                local isDir = string.sub(f.name, -1) == "/"
                if not isDir and not wsSeen[f.name] then
                    self_:_ReadMountedRemoteFile(f.name, function(content)
                        done = done + 1
                        if content then
                            local grepResult = self_:_GrepContent(query, content, f.name, isPattern, maxResults)
                            if grepResult and grepResult.matches then
                                for _, m in ipairs(grepResult.matches) do
                                    table.insert(mountMatches, m)
                                end
                                mountTotal = mountTotal + (grepResult.totalMatches or 0)
                            end
                        end
                        if done >= pending then
                            finishWithMounted(mountMatches, mountTotal)
                        end
                    end)
                end
            end
        end)
    end)
end

-- Create or overwrite a file.
-- @param pageName: string - Page name / file path
-- @param content: string - File content
-- @param callback: function(result) - result = {success, error}
function PersonalPageStore:CreateFile(pageName, content, callback)
    if not self:IsFileOpScoped("CreateFile") then
        if callback then callback({success = false, error = "No workspace set"}) end
        return
    end
    local ft = self:_getFileTools()
    ft:CreateFile(pageName, content, callback)
end

-- List files in the workspace directory.
-- In remote mode, scans local PersonalPageStore cache directory.
-- @param subDir: string (optional) - Subdirectory to list
-- @param callback: function(result) - result = {success, files = [{name, filesize}], error}
function PersonalPageStore:ListDir(subDir, callback)
    if not self:IsFileOpScoped("ListDir") then
        if callback then callback({success = false, error = "No workspace set"}) end
        return
    end
    local ft = self:_getFileTools()
    local self_ = self
    ft:ListFiles(subDir, function(result)
        local files = {}
        local seen = {}
        -- Layer 1: workspace files
        if result and result.success and result.files then
            for _, f in ipairs(result.files) do
                table.insert(files, f)
                seen[f.name] = true
            end
        end

        -- Layer 2: local mount files (sync)
        local localFiles = self_:_ListMountedLocalDir(subDir)
        for _, f in ipairs(localFiles) do
            if not seen[f.name] then
                table.insert(files, f)
                seen[f.name] = true
            end
        end

        -- Layer 3: remote mount files (async)
        self_:_ListMountedRemoteDir(subDir, function(remoteFiles)
            for _, f in ipairs(remoteFiles) do
                if not seen[f.name] then
                    table.insert(files, f)
                    seen[f.name] = true
                end
            end
            if callback then
                callback({success = true, files = files})
            end
        end)
    end)
end

-- List all pages (convenience wrapper over ListDir).
-- @param callback: function(result) - result = {success, files, error}
function PersonalPageStore:ListPages(callback)
    self:ListDir(nil, callback)
end

-- Check if a path is absolute (starts with / and contains site path segments).
-- @param pageName: string
-- @return boolean
function PersonalPageStore:IsAbsolutePath(pageName)
    if not pageName then return false end
    return string.sub(pageName, 1, 1) == "/"
end

-- Convert glob pattern to Lua pattern.
-- Supports: * (any non-slash chars), ** (any chars including slash), ? (single char)
-- @param glob: string - Glob pattern
-- @return string - Lua pattern
function PersonalPageStore:GlobToPattern(glob)
    if not glob or glob == "" then return ".*" end
    -- Escape Lua magic characters except * and ?
    local pattern = glob:gsub("([%.%+%-%^%$%(%)%%])", "%%%1")
    -- ** → match anything including /
    pattern = pattern:gsub("%*%*", "{{GLOBSTAR}}")
    -- * → match non-slash characters
    pattern = pattern:gsub("%*", "[^/]*")
    -- ? → match single character
    pattern = pattern:gsub("%?", ".")
    pattern = pattern:gsub("{{GLOBSTAR}}", ".*")
    return "^" .. pattern .. "$"
end

-- Read a file by absolute path (bypasses workspace scoping).
-- @param absolutePath: string - Full page path (e.g. "/username/sitename/path")
-- @param bUseCache: boolean (optional) - Whether to use cache (default true)
-- @param callback: function(content) - Returns raw content string or nil
function PersonalPageStore:ReadAbsoluteFile(absolutePath, bUseCache, callback)
    if not absolutePath or absolutePath == "" then
        if callback then callback(nil) end
        return
    end
    -- Strip leading slash
    local cleanPath = absolutePath:gsub("^/+", "")
    if bUseCache == nil then bUseCache = true end
    
    -- Parse full path: username/sitename/rest... → extract username, pass rest to KeepworkSiteService
    local parts = {}
    for segment in string.gmatch(cleanPath, "[^/]+") do
        table.insert(parts, segment)
    end
    if #parts < 2 then
        if callback then callback(nil) end
        return
    end
    local username = parts[1]
    -- Path without username: sitename/rest...
    local sitePath = table.concat(parts, "/", 2)

    KeepworkSiteService:GetMarkdownByFullPath(sitePath, function(remoteContent)
        if remoteContent and remoteContent ~= "" then
            local pageData = YamlConverter.YAMLToLua(remoteContent, {useFrontMatter=true})
            if pageData and type(pageData) == "table" and pageData.content ~= nil then
                if callback then callback(pageData.content) end
                return
            end
            -- Fallback: treat raw content as plain markdown (no YAML frontmatter)
            if callback then callback(remoteContent) end
            return
        end
        if callback then callback(nil) end
    end, bUseCache, username)
end

-- Get remote tree parameters for API calls.
-- @return table - {sitePath, folderBase}
function PersonalPageStore:GetRemoteTreeParams()
    local username = Mod.WorldShare.Store:Get('user/username')
    username = (username and username ~= "") and username or "anonymous"
    local siteName = "edunotes"
    local sitePath = username .. "/" .. siteName
    local wsPrefix = self._fileOpsWorkspace or ""
    local folderBase = "store"
    if wsPrefix ~= "" then
        folderBase = folderBase .. "/" .. wsPrefix
    end
    return {sitePath = sitePath, folderBase = folderBase}
end

-- Fetch the remote file tree from the Keepwork API.
-- Uses keepwork.site.tree() directly (same pattern as KeepworkSiteService:CreateFolder).
-- @param callback: function(treeData) - Array of tree nodes or nil on failure
function PersonalPageStore:FetchRemoteTree(callback)
    if self:IsUseLocal() then
        if callback then callback(nil) end
        return
    end
    local params = self:GetRemoteTreeParams()
    local repoPath = Mod.WorldShare.Utils.EncodeURIComponent(params.sitePath)
    repoPath = string.gsub(repoPath, "%%", "%%%%")
    local fullFolderPath = params.sitePath .. "/" .. params.folderBase
    local folderPath = Mod.WorldShare.Utils.EncodeURIComponent(fullFolderPath)
    folderPath = string.gsub(folderPath, "%%", "%%%%")
    keepwork.site.tree({router_params = { repoPath = repoPath, folderPath = folderPath, recursive = true }}, function(err, msg, data)
        if err ~= 200 then
            LOG.std(nil, "warn", "PersonalPageStore", "FetchRemoteTree err: %s", tostring(err))
            if callback then callback(nil) end
            return
        end
        if callback then callback(data) end
    end)
end

PersonalPageStore:InitSingleton()
