--[[
小游戏数据存储管理类
负责处理用户游戏数据的本地存储、云端同步等功能
]]

NPL.load("(gl)script/ide/System/localserver/localserver.lua");
local LocalServer = commonlib.gettable("System.localserver");

-- 数据存储管理类
local MiniGameDataStore = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Tasks.MiniGame.MiniGameDataStore"));

-- 数据存储路径
MiniGameDataStore.DATA_PATH = "temp/minigame_data/";
MiniGameDataStore.USER_DATA_FILE = "user_progress.json";
MiniGameDataStore.GAME_STATS_FILE = "game_statistics.json";

-- 内存缓存
MiniGameDataStore.userData = nil;
MiniGameDataStore.gameStats = nil;
MiniGameDataStore.isInitialized = false;

-- 初始化数据存储
function MiniGameDataStore:Init()
    if self.isInitialized then
        return;
    end
    
    -- 确保数据目录存在
    ParaIO.CreateDirectory(self.DATA_PATH);
    
    -- 加载用户数据
    self:LoadUserData();
    
    -- 加载游戏统计数据
    self:LoadGameStats();
    
    self.isInitialized = true;
end

-- 加载用户数据
function MiniGameDataStore:LoadUserData()
    local filePath = self.DATA_PATH .. self.USER_DATA_FILE;
    
    if ParaIO.DoesFileExist(filePath) then
        local file = ParaIO.open(filePath, "r");
        if file:IsValid() then
            local content = file:GetText(0, -1);
            file:close();
            
            -- 解析JSON数据
            NPL.load("(gl)script/ide/Json.lua");
            local ok, data = pcall(commonlib.Json.Decode, content);
            if ok and data then
                self.userData = data;
            else
                self.userData = {};
            end
        else
            self.userData = {};
        end
    else
        self.userData = {};
    end
end

-- 保存用户数据
function MiniGameDataStore:SaveUserData()
    if not self.userData then
        return false;
    end
    
    local filePath = self.DATA_PATH .. self.USER_DATA_FILE;
    
    -- 编码为JSON
    NPL.load("(gl)script/ide/Json.lua");
    local jsonData = commonlib.Json.Encode(self.userData);
    
    if jsonData then
        local file = ParaIO.open(filePath, "w");
        if file:IsValid() then
            file:WriteString(jsonData);
            file:close();
            return true;
        end
    end
    
    return false;
end

-- 获取用户数据
function MiniGameDataStore:GetUserData(key)
    if not self.isInitialized then
        self:Init();
    end
    
    if key then
        return self.userData[key];
    else
        return self.userData;
    end
end

-- 设置用户数据
function MiniGameDataStore:SetUserData(key, value)
    if not self.isInitialized then
        self:Init();
    end
    
    if key then
        self.userData[key] = value;
        
        -- 自动保存
        self:SaveUserData();
        return true;
    end
    
    return false;
end

-- 删除用户数据
function MiniGameDataStore:RemoveUserData(key)
    if not self.isInitialized then
        self:Init();
    end
    
    if key and self.userData[key] then
        self.userData[key] = nil;
        
        -- 自动保存
        self:SaveUserData();
        return true;
    end
    
    return false;
end

-- 加载游戏统计数据
function MiniGameDataStore:LoadGameStats()
    local filePath = self.DATA_PATH .. self.GAME_STATS_FILE;
    
    if ParaIO.DoesFileExist(filePath) then
        local file = ParaIO.open(filePath, "r");
        if file:IsValid() then
            local content = file:GetText(0, -1);
            file:close();
            
            -- 解析JSON数据
            NPL.load("(gl)script/ide/Json.lua");
            local ok, data = pcall(commonlib.Json.Decode, content);
            if ok and data then
                self.gameStats = data;
            else
                self.gameStats = self:CreateDefaultGameStats();
            end
        else
            self.gameStats = self:CreateDefaultGameStats();
        end
    else
        self.gameStats = self:CreateDefaultGameStats();
    end
end

-- 创建默认游戏统计数据
function MiniGameDataStore:CreateDefaultGameStats()
    return {
        totalPlayTime = 0, -- 总游戏时间（秒）
        totalGamesPlayed = 0, -- 总游戏次数
        totalScore = 0, -- 总得分
        averageScore = 0, -- 平均得分
        bestScore = 0, -- 最高得分
        gamesWon = 0, -- 获胜次数
        gamesLost = 0, -- 失败次数
        winRate = 0, -- 胜率
        areaStats = {}, -- 各区域统计
        gameTypeStats = {}, -- 各游戏类型统计
        difficultyStats = {}, -- 各难度统计
        dailyStats = {}, -- 每日统计
        achievements = {}, -- 成就列表
        lastPlayTime = 0, -- 最后游戏时间
        createdTime = ParaGlobal.timeGetTime() -- 创建时间
    };
end

-- 保存游戏统计数据
function MiniGameDataStore:SaveGameStats()
    if not self.gameStats then
        return false;
    end
    
    local filePath = self.DATA_PATH .. self.GAME_STATS_FILE;
    
    -- 编码为JSON
    NPL.load("(gl)script/ide/Json.lua");
    local jsonData = commonlib.Json.Encode(self.gameStats);
    
    if jsonData then
        local file = ParaIO.open(filePath, "w");
        if file:IsValid() then
            file:WriteString(jsonData);
            file:close();
            return true;
        end
    end
    
    return false;
end

-- 记录游戏结果
function MiniGameDataStore:RecordGameResult(gameData)
    if not self.isInitialized then
        self:Init();
    end
    
    if not gameData then
        return false;
    end
    
    local stats = self.gameStats;
    local currentTime = ParaGlobal.timeGetTime();
    
    -- 更新基础统计
    stats.totalGamesPlayed = stats.totalGamesPlayed + 1;
    stats.totalPlayTime = stats.totalPlayTime + (gameData.playTime or 0);
    stats.lastPlayTime = currentTime;
    
    -- 更新得分统计
    local score = gameData.score or 0;
    stats.totalScore = stats.totalScore + score;
    stats.averageScore = stats.totalScore / stats.totalGamesPlayed;
    
    if score > stats.bestScore then
        stats.bestScore = score;
    end
    
    -- 更新胜负统计
    if gameData.success then
        stats.gamesWon = stats.gamesWon + 1;
    else
        stats.gamesLost = stats.gamesLost + 1;
    end
    stats.winRate = (stats.gamesWon / stats.totalGamesPlayed) * 100;
    
    -- 更新区域统计
    if gameData.areaId then
        local areaId = tostring(gameData.areaId);
        if not stats.areaStats[areaId] then
            stats.areaStats[areaId] = {
                gamesPlayed = 0,
                gamesWon = 0,
                totalScore = 0,
                bestScore = 0,
                averageScore = 0
            };
        end
        
        local areaStat = stats.areaStats[areaId];
        areaStat.gamesPlayed = areaStat.gamesPlayed + 1;
        areaStat.totalScore = areaStat.totalScore + score;
        areaStat.averageScore = areaStat.totalScore / areaStat.gamesPlayed;
        
        if score > areaStat.bestScore then
            areaStat.bestScore = score;
        end
        
        if gameData.success then
            areaStat.gamesWon = areaStat.gamesWon + 1;
        end
    end
    
    -- 更新游戏类型统计
    if gameData.gameType then
        local gameType = gameData.gameType;
        if not stats.gameTypeStats[gameType] then
            stats.gameTypeStats[gameType] = {
                gamesPlayed = 0,
                gamesWon = 0,
                totalScore = 0,
                bestScore = 0
            };
        end
        
        local typeStat = stats.gameTypeStats[gameType];
        typeStat.gamesPlayed = typeStat.gamesPlayed + 1;
        typeStat.totalScore = typeStat.totalScore + score;
        
        if score > typeStat.bestScore then
            typeStat.bestScore = score;
        end
        
        if gameData.success then
            typeStat.gamesWon = typeStat.gamesWon + 1;
        end
    end
    
    -- 更新难度统计
    if gameData.difficulty then
        local difficulty = tostring(gameData.difficulty);
        if not stats.difficultyStats[difficulty] then
            stats.difficultyStats[difficulty] = {
                gamesPlayed = 0,
                gamesWon = 0,
                totalScore = 0,
                bestScore = 0
            };
        end
        
        local diffStat = stats.difficultyStats[difficulty];
        diffStat.gamesPlayed = diffStat.gamesPlayed + 1;
        diffStat.totalScore = diffStat.totalScore + score;
        
        if score > diffStat.bestScore then
            diffStat.bestScore = score;
        end
        
        if gameData.success then
            diffStat.gamesWon = diffStat.gamesWon + 1;
        end
    end
    
    -- 更新每日统计
    local dateKey = os.date("%Y-%m-%d", currentTime / 1000);
    if not stats.dailyStats[dateKey] then
        stats.dailyStats[dateKey] = {
            gamesPlayed = 0,
            gamesWon = 0,
            totalScore = 0,
            playTime = 0
        };
    end
    
    local dailyStat = stats.dailyStats[dateKey];
    dailyStat.gamesPlayed = dailyStat.gamesPlayed + 1;
    dailyStat.totalScore = dailyStat.totalScore + score;
    dailyStat.playTime = dailyStat.playTime + (gameData.playTime or 0);
    
    if gameData.success then
        dailyStat.gamesWon = dailyStat.gamesWon + 1;
    end
    
    -- 检查成就
    self:CheckAchievements(gameData);
    
    -- 保存数据
    self:SaveGameStats();
    
    return true;
end

-- 检查成就
function MiniGameDataStore:CheckAchievements(gameData)
    local stats = self.gameStats;
    local achievements = stats.achievements;
    
    -- 定义成就列表
    local achievementList = {
        {id = "first_win", name = "初次胜利", desc = "完成第一个游戏", condition = function() return stats.gamesWon >= 1 end},
        {id = "win_10", name = "小有成就", desc = "获胜10次", condition = function() return stats.gamesWon >= 10 end},
        {id = "win_50", name = "游戏达人", desc = "获胜50次", condition = function() return stats.gamesWon >= 50 end},
        {id = "win_100", name = "游戏大师", desc = "获胜100次", condition = function() return stats.gamesWon >= 100 end},
        {id = "high_score_1000", name = "高分选手", desc = "单局得分超过1000", condition = function() return stats.bestScore >= 1000 end},
        {id = "play_time_1h", name = "专注训练", desc = "累计游戏时间1小时", condition = function() return stats.totalPlayTime >= 3600 end},
        {id = "perfect_area", name = "区域专家", desc = "完成所有区域", condition = function() return self:IsAllAreasCompleted() end},
        {id = "daily_player", name = "每日训练", desc = "连续7天进行训练", condition = function() return self:GetConsecutiveDays() >= 7 end}
    };
    
    -- 检查每个成就
    for _, achievement in ipairs(achievementList) do
        if not achievements[achievement.id] and achievement.condition() then
            achievements[achievement.id] = {
                name = achievement.name,
                desc = achievement.desc,
                unlockedTime = ParaGlobal.timeGetTime()
            };
            
            -- 显示成就解锁消息
            self:ShowAchievementUnlocked(achievement);
        end
    end
end

-- 显示成就解锁消息
function MiniGameDataStore:ShowAchievementUnlocked(achievement)
    local message = string.format("🏆 成就解锁！\n\n%s\n%s", achievement.name, achievement.desc);
    _guihelper.MessageBox(message);
end

-- 检查是否所有区域都已完成
function MiniGameDataStore:IsAllAreasCompleted()
    local progressData = self:GetUserData("brain_map_progress");
    if progressData and progressData.completedAreas then
        return #progressData.completedAreas >= 6; -- 6个主要区域
    end
    return false;
end

-- 获取连续游戏天数
function MiniGameDataStore:GetConsecutiveDays()
    local dailyStats = self.gameStats.dailyStats;
    local currentTime = ParaGlobal.timeGetTime();
    local consecutiveDays = 0;
    
    -- 从今天开始往前检查
    for i = 0, 30 do -- 最多检查30天
        local checkDate = os.date("%Y-%m-%d", (currentTime - i * 24 * 3600 * 1000) / 1000);
        if dailyStats[checkDate] and dailyStats[checkDate].gamesPlayed > 0 then
            consecutiveDays = consecutiveDays + 1;
        else
            break;
        end
    end
    
    return consecutiveDays;
end

-- 获取游戏统计数据
function MiniGameDataStore:GetGameStats()
    if not self.isInitialized then
        self:Init();
    end
    
    return self.gameStats;
end

-- 重置所有数据
function MiniGameDataStore:ResetAllData()
    self.userData = {};
    self.gameStats = self:CreateDefaultGameStats();
    
    self:SaveUserData();
    self:SaveGameStats();
    
    return true;
end

-- 导出数据
function MiniGameDataStore:ExportData()
    local exportData = {
        userData = self.userData,
        gameStats = self.gameStats,
        exportTime = ParaGlobal.timeGetTime(),
        version = "1.0"
    };
    
    NPL.load("(gl)script/ide/Json.lua");
    return commonlib.Json.Encode(exportData);
end

-- 导入数据
function MiniGameDataStore:ImportData(jsonData)
    if not jsonData then
        return false;
    end
    
    NPL.load("(gl)script/ide/Json.lua");
    local ok, data = pcall(commonlib.Json.Decode, jsonData);
    
    if ok and data and data.userData and data.gameStats then
        self.userData = data.userData;
        self.gameStats = data.gameStats;
        
        self:SaveUserData();
        self:SaveGameStats();
        
        return true;
    end
    
    return false;
end