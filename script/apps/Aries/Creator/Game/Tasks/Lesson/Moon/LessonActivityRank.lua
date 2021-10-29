--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{pbb}
    time:2021-09-23 19:45:09
    use lib:
    local LessonActivityRank = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Lesson/Moon/LessonActivityRank.lua") 
    LessonActivityRank.ShowPage()
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestAction.lua");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
local LessonActivityRank = NPL.export()
LessonActivityRank.score = 0 --积分
LessonActivityRank.duration = 0 --登顶时长
LessonActivityRank.count = 0 --登顶次数
LessonActivityRank.miniduration_time = 0
LessonActivityRank.all_ranks = {}
LessonActivityRank.self_rank = {}
LessonActivityRank.cur_select = nil
LessonActivityRank.IsEmpty = true
LessonActivityRank.RankData = {
    -- {rank = 1, name = "我是超长的名字", score = 996, icon_type = "rise"},
    -- {rank = 2, name = "我是超长的名字2", score = 998, icon_type = "low"},
    -- {rank = 3, name = "我是超长的名字2", score = 998, icon_type = "none"},
    -- {rank = 4, name = "我是超长的名字2", score = 998, icon_type = "new"},
    -- {rank = 5, name = "我是超长的名字2", score = 998, icon_type = "new"},
}
local page = nil
function LessonActivityRank.OnInit()
    page = document:GetPageCtrl();
end

function LessonActivityRank.ClosePage()
    if page then
        page:CloseWindow()
        page = nil
    end
    LessonActivityRank.score = 0 --积分
    LessonActivityRank.duration = 0 --登顶时长
    LessonActivityRank.count = 0 --登顶次数
    LessonActivityRank.miniduration_time = 0
    LessonActivityRank.all_ranks = {}
    LessonActivityRank.self_rank = {}
    LessonActivityRank.cur_select = nil
    LessonActivityRank.IsEmpty = true
end

function LessonActivityRank.RefreshPage()
    if page then
        page:Refresh(0)
    end
end

function LessonActivityRank.ShowView()
    local view_width = 958
    local view_height = 585
    LessonActivityRank.IsEmpty = true
    LessonActivityRank.cur_select = "score"
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Lesson/Moon/LessonActivityRank.html",
        name = "LessonActivityRank.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 4,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key,
        directPosition = true,
        align = "_ct",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    LessonActivityRank.OnClickRank("exp")
end

function LessonActivityRank.GetRecudedNumberDesc(number)
    if number == nil then
        return
    end
    local num = tonumber(number)
    if num == nil then
        return number
    end

    if num < 10000 then
        return number
    end

    local int_num = math.floor(num/10000)
    local float_num = math.floor((num - int_num * 10000)/1000)
    return string.format("%s.%s万", int_num, float_num)
end

function LessonActivityRank.GetTimeStamp()
    return QuestAction.GetServerTime()
end

function LessonActivityRank.ShowPage()
    keepwork.moonrank.getrecord({},function(err, msg, data)
        if err == 200 then
            if data and data.record then
                LessonActivityRank.score = data.record.exp
                LessonActivityRank.duration = data.record.duration
                LessonActivityRank.count = data.record.count
                LessonActivityRank.miniduration_time = data.record.minDurationAt
            end
            LessonActivityRank.ShowView()
        else
            GameLogic.AddBBS(nil,"排行榜数据异常")
        end
    end)
end

function LessonActivityRank.UpdateRecord(time,score,count)
    local newTime = time or 0
    local addScore = score or 0
    local addCount = count or 0
    if (LessonActivityRank.duration > 0 and newTime < LessonActivityRank.duration) or LessonActivityRank.duration == 0 then
        LessonActivityRank.duration = newTime
        LessonActivityRank.miniduration_time = LessonActivityRank.GetTimeStamp()
    end
    LessonActivityRank.score = LessonActivityRank.score + addScore
    LessonActivityRank.count = LessonActivityRank.count + addCount

    keepwork.moonrank.updaterecord({
        duration = LessonActivityRank.duration,
        exp = LessonActivityRank.score,
        minDurationAt = LessonActivityRank.miniduration_time,
        count = LessonActivityRank.count
    },function(err, msg, data)
        if err == 200 then
            print("更新爬塔记录成功")
        end    
    end)
end

function LessonActivityRank.GetRankData(type,cb)
    local ranktype = type or "exp"
    local rankData = LessonActivityRank.GetCurRankData(ranktype)
    if rankData then
        LessonActivityRank.IsEmpty = false
        if cb then
            cb()
        end
        return
    end
    keepwork.moonrank.getrank({
        type =ranktype,
        limit =200,
    },function(err, msg, data)
        if err == 200 then
            LessonActivityRank.SetRankData(data,type)
            LessonActivityRank.IsEmpty = false
            if cb then
                cb()
            end
        end
    end)
end

function LessonActivityRank.SetRankData(data,type)
    if data and data.ranks and data.selfRank then
        local all_ranks = data.ranks
        LessonActivityRank.all_ranks = {}
        LessonActivityRank.all_ranks[type] = {}
        for i=1,#all_ranks do
            LessonActivityRank.all_ranks[type][i] = {}
            LessonActivityRank.all_ranks[type][i].rank = i
            LessonActivityRank.all_ranks[type][i].name = all_ranks[i].user.username
            LessonActivityRank.all_ranks[type][i].portrait = all_ranks[i].user.portrait
            LessonActivityRank.all_ranks[type][i].duration = all_ranks[i].duration
            LessonActivityRank.all_ranks[type][i].exp = all_ranks[i].exp
        end

        local selfRank = data.selfRank
        if selfRank then
            LessonActivityRank.self_rank[type] = {}
            LessonActivityRank.self_rank[type].rank = selfRank.rank
            LessonActivityRank.self_rank[type].duration = selfRank.duration
            LessonActivityRank.self_rank[type].exp = selfRank.exp
        end
        
    end
end

function LessonActivityRank.GetCurRankData(type)
    local ranktype = type or "exp"
    if LessonActivityRank.all_ranks[type] then
        return LessonActivityRank.all_ranks[type]
    end
end

function LessonActivityRank.GetViewData()
    return LessonActivityRank.all_ranks[LessonActivityRank.cur_select]
end

function LessonActivityRank.OnClickRank(name)
    if name and LessonActivityRank.cur_select == name then
        return 
    end
    LessonActivityRank.cur_select = name
    LessonActivityRank.GetRankData(LessonActivityRank.cur_select,function()
        LessonActivityRank.RankData = LessonActivityRank.GetViewData()
        LessonActivityRank.RefreshPage()
    end)
end