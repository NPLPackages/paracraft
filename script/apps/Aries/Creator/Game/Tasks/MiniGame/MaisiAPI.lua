--[[
Title: MaisiAPI
Author: 
Date: 2024-01-01
Desc: Maisi third-party platform API interface management
]]

local MaisiAPI = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Tasks.MiniGame.MaisiAPI"));

-- 内存存储
MaisiAPI.cache = {
    userInfo = nil,
    userDetail = nil,
    userCaps = nil,
    token = nil,
    lastUpdateTime = {
        userInfo = 0,
        userDetail = 0,
        userCaps = 0,
        token = 0
    },
    cacheTimeout = {
        userInfo = 10, -- 10秒缓存
        userDetail = 10, -- 10秒缓存
        userCaps = 604800, -- 1周缓存
        token = 3600 -- 1小时缓存
    }
};

-- API URLs
MaisiAPI.urls = {
    getUserCaps = "https://be.maseai.com/api/v1/open/getUserCaps",
    getUserInfo = "https://be.maseai.com/api/v1/open/getUserInfo",
    getUserDetail = "https://be.maseai.com/api/v1/user/info",
    getMaisiToken = "https://api.keepwork.com/core/v0/oauth/getMaisiToken"
};

function MaisiAPI:ctor()
end

-- 检查缓存是否有效
function MaisiAPI:IsCacheValid(cacheType)
    if not self.cache[cacheType] then
        return false
    end
    
    local currentTime = ParaGlobal.timeGetTime()
    local lastUpdate = self.cache.lastUpdateTime[cacheType] or 0
    local timeout = self.cache.cacheTimeout[cacheType] or 0
    
    return (currentTime - lastUpdate) < (timeout * 1000) -- 转换为毫秒
end

-- 更新缓存
function MaisiAPI:UpdateCache(cacheType, data)
    self.cache[cacheType] = data
    self.cache.lastUpdateTime[cacheType] = ParaGlobal.timeGetTime()
end

-- 清理指定类型的缓存
function MaisiAPI:ClearCache(cacheType)
    System.options.thirdpartytoken = nil
    System.options.clientId = nil
    if cacheType then
        self.cache[cacheType] = nil
        self.cache.lastUpdateTime[cacheType] = 0
        commonlib.echo("MaisiAPI: Cleared cache for " .. cacheType)
    else
        -- 清理所有缓存
        self.cache.userInfo = nil
        self.cache.userDetail = nil
        self.cache.userCaps = nil
        self.cache.token = nil
        for key, _ in pairs(self.cache.lastUpdateTime) do
            self.cache.lastUpdateTime[key] = 0
        end
        commonlib.echo("MaisiAPI: Cleared all cache")
    end
end

-- 强制刷新指定类型的数据
function MaisiAPI:ForceRefresh(cacheType, callback)
    self:ClearCache(cacheType)
    
    if cacheType == "userInfo" then
        self:LoadMaisiUserInfo(callback, true)
    elseif cacheType == "userDetail" then
        self:LoadMaisiUserDetail(callback, true)
    elseif cacheType == "userCaps" then
        self:LoadMaisiUserCaps(callback, true)
    elseif cacheType == "token" then
        self:GetMaisiToken(callback, true)
    else
        commonlib.echo("MaisiAPI: Unknown cache type for force refresh: " .. tostring(cacheType))
        if callback and type(callback) == "function" then
            callback(false)
        end
    end
end

-- 强制刷新所有数据
function MaisiAPI:ForceRefreshAll(callback)
    self:ClearCache()
    self:LoadMaisiGameInfo(callback)
end

-- 获取用户权限信息
function MaisiAPI:LoadMaisiUserCaps(callback, forceRefresh)
    if not System.options.thirdpartytoken or not System.options.clientId then
        commonlib.echo("MaisiAPI: Missing thirdpartytoken or clientId")
        if callback and type(callback) == 'function' then
            callback(nil)
        end
        return
    end
    -- 检查缓存
    if not forceRefresh and self:IsCacheValid("userCaps") then
        commonlib.echo("MaisiAPI: Using cached userCaps")
        if callback and type(callback) == "function" then
            callback(self.cache.userCaps)
        end
        return
    end
    
    local maisi_url = self.urls.getUserCaps
    System.os.GetUrl({
        cache_policy = "access plus 1 week",
        url = maisi_url,
        json = true,
        headers = {
            ["Authorization"] = "Bearer " .. (System.options.thirdpartytoken or ""),
        },
    }, function(err, msg, data)
        commonlib.echo("======MaisiAPI=====getUserCaps callback");
        if(err == 200 and data and data.code == 200) then
            local maisiData = data.data
            self:UpdateCache("userCaps", maisiData)
            if callback and type(callback) == "function" then
                callback(maisiData)
            end
        else
            commonlib.echo("MaisiAPI: Failed to load user caps, err=" .. tostring(err))
            if callback and type(callback) == 'function' then
                callback(nil)
            end
        end
    end);
end

-- 获取用户基本信息
function MaisiAPI:LoadMaisiUserInfo(callback, forceRefresh)
    if not System.options.thirdpartytoken or not System.options.clientId then
        commonlib.echo("MaisiAPI: Missing thirdpartytoken or clientId")
        if callback and type(callback) == 'function' then
            callback(nil)
        end
        return
    end
    
    -- 检查缓存
    if not forceRefresh and self:IsCacheValid("userInfo") then
        commonlib.echo("MaisiAPI: Using cached userInfo")
        if callback and type(callback) == "function" then
            callback(self.cache.userInfo)
        end
        return
    end
    
    local maisi_url = self.urls.getUserInfo
    System.os.GetUrl({
        cache_policy = "access plus 10 second",
        url = maisi_url,
        json = true,
        headers = {
            ["Authorization"] = "Bearer " .. System.options.thirdpartytoken,
        },
    }, function(err, msg, data)
        commonlib.echo("======MaisiAPI=====getUserInfo callback");
        -- commonlib.echo(data, true);
        if(err == 200 and data and data.code == 200) then
            local userInfo = data.data or {}
            self:UpdateCache("userInfo", userInfo)
            if callback and type(callback) == "function" then
                callback(userInfo)
            end
        else
            commonlib.echo("MaisiAPI: Failed to load user info, err=" .. tostring(err))
            if callback and type(callback) == "function" then
                callback(nil)
            end
        end
    end);
end

-- 获取用户详细信息
function MaisiAPI:LoadMaisiUserDetail(callback, forceRefresh)
    if not System.options.thirdpartytoken or not System.options.clientId then
        commonlib.echo("MaisiAPI: Missing thirdpartytoken or clientId")
        if callback and type(callback) == 'function' then
            callback(nil)
        end
        return
    end
    
    -- 检查缓存
    if not forceRefresh and self:IsCacheValid("userDetail") then
        commonlib.echo("MaisiAPI: Using cached userDetail")
        if callback and type(callback) == "function" then
            callback(self.cache.userDetail)
        end
        return
    end
    
    local maisi_url = self.urls.getUserDetail
    System.os.GetUrl({
        cache_policy = "access plus 10 second",
        url = maisi_url,
        json = true,
        headers = {
            ["Authorization"] = "Bearer " .. System.options.thirdpartytoken,
        },
    }, function(err, msg, data)
        commonlib.echo("======MaisiAPI=====getUserDetail callback");
        -- commonlib.echo(data, true);
        if(err == 200 and data and data.code == 200) then
            local userDetail = data.data
            self:UpdateCache("userDetail", userDetail)
            if callback and type(callback) == "function" then
                callback(userDetail)
            end
        else
            commonlib.echo("MaisiAPI: Failed to load user detail, err=" .. tostring(err))
            if callback and type(callback) == "function" then
                callback(nil)
            end
        end
    end);
end

-- 加载所有Maisi游戏信息
function MaisiAPI:LoadMaisiGameInfo(callback)
    self:LoadMaisiUserInfo(function(userInfo)
        self:LoadMaisiUserDetail(function(userDetail)
            self:LoadMaisiUserCaps(function(userCaps)
                if callback and type(callback) == "function" then
                    callback({
                        userInfo = userInfo,
                        userDetail = userDetail,
                        userCaps = userCaps
                    })
                end
            end)
        end)
    end)
end

-- 获取Maisi Token
function MaisiAPI:GetMaisiToken(callback, forceRefresh)
    -- 检查缓存
    if not forceRefresh and self:IsCacheValid("token") and System.options.thirdpartytoken then
        commonlib.echo("MaisiAPI: Using cached token")
        if callback and type(callback) == "function" then
            callback(true)
        end
        return
    end
    
    local input = {};
    input.json = true
    input.url = self.urls.getMaisiToken;
    input.method = "POST";
    input.form = {}
    local headers = input.headers or {};
    local keepworkToken = Mod.WorldShare.Store:Get("user/token")
    if not keepworkToken then
        commonlib.echo("MaisiAPI: Missing keepwork token")
        if callback and type(callback) == "function" then
            callback(false)
        end
        return
    end
    
    headers["Authorization"] = "Bearer " .. keepworkToken;
    input.headers = headers;
    
    System.os.GetUrl(input, function(err, msg, data)
        local getToken = false
        print("getMaisiToken====================")
        -- echo(data,true)
        if err == 200 and data then
            local tokens = data.token or {}
            local maisiToken = tokens.accessToken
            if maisiToken and type(maisiToken) == "string" then
                System.options.thirdpartytoken = maisiToken
                System.options.clientId = "maisi"
                self:UpdateCache("token", maisiToken)
                getToken = true
                commonlib.echo("MaisiAPI: Successfully obtained Maisi token")
            end
        else
            commonlib.echo("MaisiAPI: Failed to get Maisi token, err=" .. tostring(err))
        end
        
        if callback and type(callback) == "function" then
            callback(getToken)
        end
    end);
end

-- 获取缓存的数据
function MaisiAPI:GetCachedData(cacheType)
    if self:IsCacheValid(cacheType) then
        return self.cache[cacheType]
    end
    return nil
end

-- 获取所有缓存的数据
function MaisiAPI:GetAllCachedData()
    return {
        userInfo = self:GetCachedData("userInfo"),
        userDetail = self:GetCachedData("userDetail"),
        userCaps = self:GetCachedData("userCaps"),
        token = self:GetCachedData("token")
    }
end

-- 设置缓存超时时间
function MaisiAPI:SetCacheTimeout(cacheType, timeoutSeconds)
    if self.cache.cacheTimeout[cacheType] then
        self.cache.cacheTimeout[cacheType] = timeoutSeconds
        commonlib.echo("MaisiAPI: Set cache timeout for " .. cacheType .. " to " .. timeoutSeconds .. " seconds")
    else
        commonlib.echo("MaisiAPI: Unknown cache type: " .. tostring(cacheType))
    end
end

-- 初始化方法
function MaisiAPI:Init()
    commonlib.echo("MaisiAPI: Initialized")
end

-- 清理方法
function MaisiAPI:Cleanup()
    self:ClearCache()
    commonlib.echo("MaisiAPI: Cleaned up")
end

MaisiAPI:InitSingleton():Init()