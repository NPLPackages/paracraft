--[[
    author: pbb
    date: 2025-04-25
    description: 用户称号管理逻辑
    uselib:
     local UserTitleManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/UserTitleManager.lua")
     UserTitleManager.RegisterGameEvent()
]]

local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local AIGC_GSID = 40004
local UserTitleManager = NPL.export()

local TitleTypes = {
    starOfPerfAtt = {firstAchiveNum = 200, achiveDay = 30, remainDay = 30 ,title = "全勤之星"},
    mathKnight = {firstAchiveNum = 200, leveledAchiveNum = 200, maxLevel = 99 ,title = "数学骑士"},
    greatScholar = {firstAchiveNum = 200, leveledAchiveNum = 200, maxLevel = 99 ,title = "大文豪"},
    englishPioneer = {firstAchiveNum = 200, leveledAchiveNum = 200, maxLevel = 99 ,title = "英语先锋"},
}


function UserTitleManager.Init()
    
end

function UserTitleManager.GetTitleInfo(titleType)
    return TitleTypes[titleType]
end

function UserTitleManager.GetAchiveData(titleType,callback)
    local clientData = KeepWorkItemManager.GetClientData(AIGC_GSID) or {}
    local achiveData = clientData[titleType]
    return achiveData
end

function UserTitleManager.SetAchiveData(titleType,achiveData)
    if not achiveData or next(achiveData) == nil then
        return
    end
    local clientData = KeepWorkItemManager.GetClientData(AIGC_GSID) or {}
    clientData[titleType] = achiveData
    KeepWorkItemManager.SetClientData(AIGC_GSID,clientData,function()
        GameLogic.AddBBS(nil,L"设置数据成功",nil,3000)
    end,function(err,msg,data)
        GameLogic.AddBBS(nil,L"设置数据失败",nil,3000)
        LOG.std(nil, "info", "UserTitleManager", "SetAchiveData failed: %s", tostring(err) or "")
    end)
end

--签到逻辑、
local signKey = "starOfPerfAtt"
function UserTitleManager.FinishTodaySign()
    local titleInfo = UserTitleManager.GetTitleInfo(signKey)
    local achiveData = UserTitleManager.GetAchiveData(signKey) or {}
    local time_stamp = GameLogic.GetFilters():apply_filters('service.session.get_current_server_time') or os.time()
    local year,month,day = os.date("%Y",time_stamp),os.date("%m",time_stamp),os.date("%d",time_stamp)
    local signDateTime = os.time({year=year,month=month,day=day,hour=0,min=0,sec=0})
    local daySeconds = 24 * 60 * 60
    if achiveData.lastSignTime and achiveData.lastSignTime == signDateTime then
        print("今天已经签到过了！")
        return
    end
     if not achiveData.startSignTime or achiveData.startSignTime == 0 then
        achiveData.startSignTime = signDateTime
        achiveData.signDays = 1
    else
        local diffDays = (signDateTime - achiveData.lastSignTime) / daySeconds
        if diffDays == 1 then
            achiveData.signDays = achiveData.signDays + 1
        else
            achiveData.signDays = 1
        end
    end
    achiveData.lastSignTime = signDateTime

    local exchangeBeanNum = 0
    if achiveData.signDays == titleInfo.achiveDay and not achiveData.isGetTitle then
        achiveData.isGetTitle = true
        achiveData.getTitleTime = signDateTime
        print("获得称号：" .. titleInfo.title)
        -- 获取知识豆
        exchangeBeanNum = exchangeBeanNum + titleInfo.firstAchiveNum
    end

    if achiveData.getTitleTime 
        and achiveData.getTitleTime > 0 
        and (achiveData.lastSignTime - achiveData.getTitleTime) >= titleInfo.remainDay * daySeconds then
        if achiveData.signDays < titleInfo.achiveDay then 
            achiveData.isGetTitle = false
            achiveData.getTitleTime = 0
        end
    end

    exchangeBeanNum = exchangeBeanNum + 20 
    if achiveData.isGetTitle then
        exchangeBeanNum = exchangeBeanNum + 20
    end
    -- 兑换知识豆
    UserTitleManager.ExchangeBean(exchangeBeanNum)
    -- 保存更新后的成就数据
    UserTitleManager.SetAchiveData(signKey, achiveData)
end

function UserTitleManager.FinishGame(game_key,data)
    UserTitleManager.FinishTodaySign()
    if game_key == "math" then
        UserTitleManager.FinishMathGame()
    elseif game_key == "chinese" then
        UserTitleManager.FinishChineseGame()
    elseif game_key == "english" then
        UserTitleManager.FinishEnglishGame()
    end
end

function UserTitleManager.ExchangeBean(exchangeBeanNum) --统计获得多少知识豆
    -- 兑换知识豆
    
end

function UserTitleManager.UpdateGameData(key)
    local titleInfo = UserTitleManager.GetTitleInfo(key)
    local achiveData = UserTitleManager.GetAchiveData(key) or {}
    local numOfGame = achiveData.numOfGame or 0
    numOfGame = numOfGame + 1
    local exchangeNum = 0
    if numOfGame >= titleInfo.firstAchiveNum and not achiveData.isGetTitle  then --首次
        achiveData.isGetTitle = true
        achiveData.curLevel = 1
        print("获得称号：" .. titleInfo.title)
        exchangeNum = exchangeNum + titleInfo.firstAchiveNum
    end
    if achiveData.curLevel and achiveData.curLevel > 1 
        and numOfGame - (titleInfo.firstAchiveNum + (achiveData.curLevel - 1) * titleInfo.leveledAchiveNum) >= titleInfo.leveledAchiveNum 
        and achiveData.curLevel < titleInfo.maxLevel then --升级
        achiveData.curLevel = achiveData.curLevel + 1
        print("称号等级提升：" .. achiveData.curLevel)
        exchangeNum = exchangeNum + titleInfo.leveledAchiveNum
    end
    achiveData.numOfGame = numOfGame
    UserTitleManager.ExchangeBean(exchangeNum)
    UserTitleManager.SetAchiveData(key, achiveData)
end

--数学游戏
local mathKey = "mathKnight"
function UserTitleManager.FinishMathGame()
    UserTitleManager.UpdateGameData(mathKey)
end

--语文游戏
local chineseKey = "greatScholar"
function UserTitleManager.FinishChineseGame()
    UserTitleManager.UpdateGameData(chineseKey)
end

--英语游戏
local englishKey = "englishPioneer"
function UserTitleManager.FinishEnglishGame()
    UserTitleManager.UpdateGameData(englishKey)
end

--活跃度
function UserTitleManager.UserTitleActive() --这个需要后端数据存储提供接口
    -- local achiveData = UserTitleManager.GetAchiveData(signKey)

end

-- 注册数据
function UserTitleManager.RegisterGameEvent()
    local codeGlobal = GameLogic.GetCodeGlobal()
    if codeGlobal then
        codeGlobal:RegisterTextEvent("finishMath", function(args,msg)
            local msg = msg.msg
            UserTitleManager.FinishGame("math",msg)
        end)
        codeGlobal:RegisterTextEvent("finishChinese", function(args,msg)
            local msg = msg.msg
            UserTitleManager.FinishGame("chinese",msg)
        end)
        codeGlobal:RegisterTextEvent("finishEnglish", function(args,msg)
            local msg = msg.msg
            UserTitleManager.FinishGame("english",msg)
        end)
    end
end

--[[
broadcast("finishMath", {xxxxxx})
broadcast("finishChinese", {xxxxxx})
broadcast("finishEnglish", {xxxxxx})
]]