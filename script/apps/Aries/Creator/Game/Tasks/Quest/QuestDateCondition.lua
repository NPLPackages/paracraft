--[[
Title: QuestDateCondition
Author(s): leio
Date: 2021/1/11
use the lib:
------------------------------------------------------------
NOTE：
------------------------------------------------------------------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestDateCondition.lua");
local QuestDateCondition = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestDateCondition");
-------------------------------------------------------
]]
local QuestDateCondition = commonlib.inherit(nil,commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestDateCondition"))

QuestDateCondition.type= "QuestDateCondition";
function QuestDateCondition:ctor()
        self.values = {};
        self.strict = false;
        self.cur_time = nil;
        self.endtime = nil
        self.cur_time_stamp = 0
end
--[[
    value 支持多个日期多个时间段

    strict 是否强制 为true 则必须是在配置的date日期和配置的duration时段 才符合条件
                    false 则是date日期之后每天的duration时间段 才算是符合条件 这种情况若配置多个data 则以第一个data日期为开始日期
    endtime 结束时间 只要过了这个时间 就当这个任务已失效
        {   
            "type": "QuestDateCondition",
            "values" : [ 
                { "date": "2021-1-11", "duration": "10:00:00-12:00:00" },
                { "date": "2021-1-11", "duration": "14:00:00-16:00:00" },
                { "date": "2021-1-11", "duration": "20:00:00-22:00:00" },
            ],
            "strict": false,
            "endtime": 2021-01-12 11:28:21
        }
]]
function QuestDateCondition:Parse(config)
    if(not config)then
        return
    end
    self.values = commonlib.deepcopy(config.values or {})
    self.strict = config.strict;
    self.endtime = config.endtime
end
function QuestDateCondition:Refresh()
end
function QuestDateCondition:IsValid()
    -- check date by self.cur_time
    -- if self.cur_time == nil then
    --     return false
    -- end

    local cur_time_stamp = GameLogic.QuestAction.GetServerTime()

    -- 先判断结束时间
    if self.endtime and self.endtime ~= "" then
        local year, month, day, hour, min, sec = self.endtime:match("^(%d+)%D(%d+)%D(%d+)%D(%d+)%D(%d+)%D(%d+)") 
        if not year then
            return false
        end

        local endtime_stamp = QuestDateCondition.GetTimeStamp(year, month, day, hour, min, sec)
        if cur_time_stamp > endtime_stamp then
            return false
        end
    end

    if #self.values == 0 then
        return false
    end

    local cur_date_str = os.date("%Y-%m-%d",cur_time_stamp)
    local begain_data_str = cur_date_str
    if not self.strict then
        local year, month, day = self.values[1].date:match("^(%d+)%D(%d+)%D(%d+)")
        local begain_time_weehours_stamp = QuestDateCondition.GetTimeStamp(year, month, day)
        begain_data_str = cur_time_stamp > begain_time_weehours_stamp and cur_date_str or self.values[1].date
    end

    for i, v in ipairs(self.values) do
        local date = self.strict and v.date or begain_data_str

        local target_time_str = string.format("%s-%s", date, v.duration)
        local year, month, day, hour_begain, min_begain, sec_begain, hour_end, min_end, sec_end = target_time_str:match("^(%d+)%D(%d+)%D(%d+)%D(%d+)%D(%d+)%D(%d+)%D(%d+)%D(%d+)%D(%d+)") 

        local begain_time_stamp = QuestDateCondition.GetTimeStamp(year, month, day, hour_begain, min_begain, sec_begain)
        local end_time_stamp = QuestDateCondition.GetTimeStamp(year, month, day, hour_end, min_end, sec_end)
        if cur_time_stamp >= begain_time_stamp and cur_time_stamp <= end_time_stamp then
            return true
        end
    end
    return false
end

function QuestDateCondition.GetTimeStamp(year, month, day, hour, min, sec)
    year = year or 0
    month = month or 0
    day = day or 0
    hour = hour or 0
    min = min or 0
    sec = year or 0

    local time_stamp = os.time({day=tonumber(day), month=tonumber(month), year=tonumber(year), hour=tonumber(hour)})
    time_stamp = time_stamp + min * 60 + sec

    return time_stamp
end