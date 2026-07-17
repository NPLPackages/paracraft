--[[
Title: Compete mock user opus
Author(s): big
Date: 2025/07/30
Desc: 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Competition/CompeteMockUserOpus.lua")
local CompetitionMockUserOpus = commonlib.gettable("MyCompany.Aries.Game.Educate.Competete.MockUserOpus")
-------------------------------------------------------
]]

local CompetitionApi =  NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Competition/CompetitionApi.lua")

local CompetitionMockUserOpus = commonlib.gettable("MyCompany.Aries.Game.Educate.Competete.MockUserOpus")

-- Timer控制变量
local timer = nil
local currentIndex = 1
local isRunning = false
local isPaused = false
local isProcessing = false

local userData = {
    {id = 1, name = "User1", action = "action1"},
    {id = 2, name = "User2", action = "action2"},
    {id = 3, name = "User3", action = "action3"},
    -- 添加更多测试数据
}

-- 处理单个用户数据项
function CompetitionMockUserOpus.ProcessUserItem(item, callback)
    if not item then
        if callback then callback(false, "无效的数据项") end
        return
    end
    
    isProcessing = true
    
    -- 模拟异步处理过程
    LOG.std(nil, "info", "CompetitionMockUserOpus", "开始处理用户数据: %s", item.name or "未知用户")
    
    -- 这里可以调用实际的API或处理逻辑
    -- 例如: CompetitionApi.SomeMethod(item, function(success, msg) ... end)
    
    -- 模拟异步操作，2秒后完成
    commonlib.TimerManager.SetTimeout(function()
        isProcessing = false
        local success = math.random() > 0.2 -- 80%成功率
        local message = success and "处理成功" or "处理失败"
        
        LOG.std(nil, "info", "CompetitionMockUserOpus", "用户数据处理完成: %s, 结果: %s", item.name or "未知用户", message)
        
        if callback then
            callback(success, message)
        end
    end, 2000)
end

-- 执行下一个item
function CompetitionMockUserOpus.ProcessNext()
    if isPaused or isProcessing then
        return
    end
    
    if currentIndex > #userData then
        CompetitionMockUserOpus.Stop()
        LOG.std(nil, "info", "CompetitionMockUserOpus", "所有用户数据处理完成")
        return
    end
    
    local currentItem = userData[currentIndex]
    LOG.std(nil, "info", "CompetitionMockUserOpus", "处理第 %d/%d 个用户数据", currentIndex, #userData)
    
    CompetitionMockUserOpus.ProcessUserItem(currentItem, function(success, message)
        if isRunning and not isPaused then
            currentIndex = currentIndex + 1
            -- 处理完成后继续下一个
            CompetitionMockUserOpus.ProcessNext()
        end
    end)
end

-- 启动遍历
function CompetitionMockUserOpus.StartMock()
    if isRunning then
        LOG.std(nil, "warn", "CompetitionMockUserOpus", "Mock已经在运行中")
        return
    end
    
    if #userData == 0 then
        LOG.std(nil, "warn", "CompetitionMockUserOpus", "userData为空，无需处理")
        return
    end
    
    isRunning = true
    isPaused = false
    currentIndex = 1
    
    LOG.std(nil, "info", "CompetitionMockUserOpus", "开始Mock用户数据处理，共 %d 个用户", #userData)
    
    -- 创建定时器，每500ms检查一次是否可以处理下一个
    timer = commonlib.TimerManager.SetTimer(function()
        if isRunning and not isPaused then
            CompetitionMockUserOpus.ProcessNext()
        end
    end, 500, -1) -- -1表示无限循环
    
    -- 立即开始处理第一个
    CompetitionMockUserOpus.ProcessNext()
end

-- 暂停处理
function CompetitionMockUserOpus.Pause()
    if not isRunning then
        LOG.std(nil, "warn", "CompetitionMockUserOpus", "Mock未在运行，无法暂停")
        return
    end
    
    isPaused = true
    LOG.std(nil, "info", "CompetitionMockUserOpus", "Mock处理已暂停")
end

-- 恢复处理
function CompetitionMockUserOpus.Resume()
    if not isRunning then
        LOG.std(nil, "warn", "CompetitionMockUserOpus", "Mock未在运行，无法恢复")
        return
    end
    
    if not isPaused then
        LOG.std(nil, "warn", "CompetitionMockUserOpus", "Mock未暂停，无需恢复")
        return
    end
    
    isPaused = false
    LOG.std(nil, "info", "CompetitionMockUserOpus", "Mock处理已恢复")
end

-- 停止处理
function CompetitionMockUserOpus.Stop()
    if timer then
        commonlib.TimerManager.ClearTimer(timer)
        timer = nil
    end
    
    isRunning = false
    isPaused = false
    isProcessing = false
    
    LOG.std(nil, "info", "CompetitionMockUserOpus", "Mock处理已停止")
end

-- 获取当前状态
function CompetitionMockUserOpus.GetStatus()
    return {
        isRunning = isRunning,
        isPaused = isPaused,
        isProcessing = isProcessing,
        currentIndex = currentIndex,
        totalCount = #userData,
        progress = currentIndex > 0 and (currentIndex - 1) / #userData or 0
    }
end

-- 设置用户数据
function CompetitionMockUserOpus.SetUserData(data)
    if isRunning then
        LOG.std(nil, "warn", "CompetitionMockUserOpus", "Mock正在运行，无法设置新数据")
        return false
    end
    
    userData = data or {}
    currentIndex = 1
    LOG.std(nil, "info", "CompetitionMockUserOpus", "用户数据已更新，共 %d 个用户", #userData)
    return true
end

-- 测试函数
function CompetitionMockUserOpus.RunTest()
    LOG.std(nil, "info", "CompetitionMockUserOpus", "开始测试...")
    
    -- 设置测试数据
    local testData = {}
    for i = 1, 10 do
        table.insert(testData, {
            id = i,
            name = "TestUser" .. i,
            action = "test_action_" .. i
        })
    end
    
    CompetitionMockUserOpus.SetUserData(testData)
    CompetitionMockUserOpus.StartMock()
    
    -- 10秒后暂停
    commonlib.TimerManager.SetTimeout(function()
        LOG.std(nil, "info", "CompetitionMockUserOpus", "测试暂停...")
        CompetitionMockUserOpus.Pause()
        
        -- 5秒后恢复
        commonlib.TimerManager.SetTimeout(function()
            LOG.std(nil, "info", "CompetitionMockUserOpus", "测试恢复...")
            CompetitionMockUserOpus.Resume()
        end, 5000)
    end, 10000)
end

--[[
使用示例:

-- 启动Mock
CompetitionMockUserOpus.StartMock()

-- 暂停
CompetitionMockUserOpus.Pause()

-- 恢复
CompetitionMockUserOpus.Resume()

-- 停止
CompetitionMockUserOpus.Stop()

-- 获取状态
local status = CompetitionMockUserOpus.GetStatus()
print("Running:", status.isRunning, "Paused:", status.isPaused, "Progress:", status.progress)

-- 设置自定义数据
local myData = {
    {id = 1, name = "User1", data = "some data"},
    {id = 2, name = "User2", data = "other data"}
}
CompetitionMockUserOpus.SetUserData(myData)

-- 运行测试
CompetitionMockUserOpus.RunTest()
]]


