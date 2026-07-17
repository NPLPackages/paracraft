--[[
Title: mqtt page
Author: pbb
CreateDate: 2024.1.2
Desc: 
use the lib:
------------------------------------------------------------
local MqttTopicDetailPage = NPL.load('(gl)script/apps/Aries/Creator/Game/Mqtt/MqttTopicDetailPage.lua')
MqttTopicDetailPage.ShowPage(project,data)
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Mqtt/MqttManager.lua")
local MqttManager = commonlib.gettable("MyCompany.Aries.Creator.Game.MqttManager");
local MqttTopicDetailPage = NPL.export()
local page

MqttTopicDetailPage.mqttProjectData = nil
MqttTopicDetailPage.mqttTopicData = nil
MqttTopicDetailPage.mqttTopicDataList = {}
MqttTopicDetailPage.mqttShowTopicDataList = {}

MqttTopicDetailPage.cur_year = os.date("%Y");
MqttTopicDetailPage.cur_month = os.date("%m");
MqttTopicDetailPage.cur_year1 = os.date("%Y");
MqttTopicDetailPage.cur_month1 = os.date("%m");
MqttTopicDetailPage.mIsShowCalendar = false
MqttTopicDetailPage.mIsShowCalendar1 = false

--search
MqttTopicDetailPage.search_timeStart = ""
MqttTopicDetailPage.search_timeEnd = ""
MqttTopicDetailPage.search_device_name = ""
MqttTopicDetailPage.search_device_data = ""

function MqttTopicDetailPage.OnInit()
    page = document:GetPageCtrl()
end

function MqttTopicDetailPage.ShowPage(project,data)
    if not data then
        return
    end
    MqttTopicDetailPage.OnClose()
    MqttTopicDetailPage.mqttTopicData = data
    MqttTopicDetailPage.mqttProjectData = project
    MqttTopicDetailPage.ShowView()
end

function MqttTopicDetailPage.ShowView()
    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Mqtt/MqttTopicDetailPage.html",
        name = "MqttTopicDetailPage.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        directPosition = true,
        cancelShowAnimation = true,
        align = "_fi",
        x = -view_width/2,
        y = -view_height/2,
        width = view_width,
        height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    params._page.OnClose = function()
        MqttTopicDetailPage.OnClose()
    end
    MqttTopicDetailPage.LoadTopicDataList()
end

function MqttTopicDetailPage.OnClose()
    MqttTopicDetailPage.search_timeStart = ""
    MqttTopicDetailPage.search_timeEnd = ""
    MqttTopicDetailPage.search_device_name = ""
    MqttTopicDetailPage.search_device_data = ""
    MqttTopicDetailPage.mqttTopicDataList = {}
    MqttTopicDetailPage.mqttShowTopicDataList = {}

    MqttTopicDetailPage.mqttProjectData = nil
    MqttTopicDetailPage.mqttTopicData = nil

    MqttTopicDetailPage.cur_year = os.date("%Y");
    MqttTopicDetailPage.cur_month = os.date("%m");
    MqttTopicDetailPage.cur_year1 = os.date("%Y");
    MqttTopicDetailPage.cur_month1 = os.date("%m");
    MqttTopicDetailPage.mIsShowCalendar = false
    MqttTopicDetailPage.mIsShowCalendar1 = false
end

function MqttTopicDetailPage.RefreshPage()
    if page then
        page:Refresh(0)
    end
    MqttTopicDetailPage.UpdateDetailUI()
end

function MqttTopicDetailPage.UpdateDetailUI()
    local calendarStart = ParaUI.GetUIObject("calendar_container_start")
    local calendarEnd = ParaUI.GetUIObject("calendar_container_end")
    if calendarStart and calendarStart:IsValid() and calendarEnd and calendarEnd:IsValid() then
        calendarStart.visible = MqttTopicDetailPage.mIsShowCalendar
        calendarEnd.visible = MqttTopicDetailPage.mIsShowCalendar1
    end
    if MqttTopicDetailPage.search_timeStart ~= "" then
        page:SetValue("text_mqtt_time_start",MqttTopicDetailPage.search_timeStart) 
    end
    if MqttTopicDetailPage.search_timeEnd ~= "" then
        page:SetValue("text_mqtt_time_end",MqttTopicDetailPage.search_timeEnd) 
    end
    if MqttTopicDetailPage.search_device_name ~= "" then
        page:SetValue("text_mqtt_device",MqttTopicDetailPage.search_device_name) 
    end
    if MqttTopicDetailPage.search_device_data ~= "" then
        page:SetValue("text_mqtt_device_data",MqttTopicDetailPage.search_device_data) 
    end
end

function MqttTopicDetailPage.LoadTopicDataList(bRefresh)
    if not MqttTopicDetailPage.mqttTopicData then
        return
    end
    if bRefresh == true then
        MqttTopicDetailPage.mqttTopicDataList = {}
        MqttTopicDetailPage.mqttShowTopicDataList = {}
    end
    local topicId = MqttTopicDetailPage.mqttTopicData.id

    MqttManager.getInstance():LoadTopicDataList(topicId,function(result,data)
        if result == true then
            -- echo(data,true)
            print("topic data list load success==========")
            -- if data and data.count and data.count > 0 then
            local mqttList = data or {}
            for k,v in ipairs(mqttList) do
                local temp = {}
                temp.clientid = v.clientid
                temp.createAt = v.createdAt
                --temp.publishAt = v.publishAt:gsub("T"," "):gsub(".000Z","")
                temp.publishTime = commonlib.timehelp.GetTimeStampByDateTime(v.publishAt)
                temp.publishAt = os.date("%Y-%m-%d %H:%M:%S",temp.publishTime)
                temp.deviceName = v.device and v.device.desc
                -- local jsonStr = commonlib.Json.Decode(v.payload)
                -- if jsonStr then
                --     temp.msg = commonlib.serialize_compact(jsonStr)
                -- else
                --     temp.msg = v.payload
                -- end
                temp.msg = v.payload
                
                table.insert(MqttTopicDetailPage.mqttTopicDataList,temp)
            end
            -- echo(MqttTopicDetailPage.mqttTopicDataList,true)
            MqttTopicDetailPage.mqttShowTopicDataList = MqttTopicDetailPage.mqttTopicDataList
            MqttTopicDetailPage.RefreshPage()
            return
        end
        GameLogic.AddBBS(nil,L"暂无数据")
    end)
end

function MqttTopicDetailPage.OnClickShowCalendar(name)
    if name == "calendar1" or name == "calendar2" then
        MqttTopicDetailPage.mIsShowCalendar1 = false
        MqttTopicDetailPage.mIsShowCalendar = not MqttTopicDetailPage.mIsShowCalendar
    elseif name == "calendar3" or name == "calendar4" then
        MqttTopicDetailPage.mIsShowCalendar = false
        MqttTopicDetailPage.mIsShowCalendar1 = not MqttTopicDetailPage.mIsShowCalendar1
    end
    MqttTopicDetailPage.RefreshPage()
end

function MqttTopicDetailPage.OnClickDay(name)
    MqttTopicDetailPage.OnClickShowCalendar("calendar3")
    if page then
        page:SetValue("text_mqtt_time_start", name)
        MqttTopicDetailPage.search_timeStart = name
    end
end

function MqttTopicDetailPage.OnClickDay1(name)
    --MqttTopicDetailPage.OnClickShowCalendar("calendar1")
    MqttTopicDetailPage.mIsShowCalendar1 = false
    MqttTopicDetailPage.mIsShowCalendar = false
    MqttTopicDetailPage.RefreshPage()
    
    
    if page then
        local timeStart = page:GetValue("text_mqtt_time_start") or ""
        local year,month,day = commonlib.timehelp.GetYearMonthDayFromStr(timeStart)
        local year1,month1,day1 = commonlib.timehelp.GetYearMonthDayFromStr(name)
        local start_time = os.time({year=year,month=month,day=day})
        local end_time = os.time({year=year1,month=month1,day=day1})
        if  start_time >= end_time then
            name = year.."-"..month.."-"..day
        end
        MqttTopicDetailPage.search_timeEnd = name
        page:SetValue("text_mqtt_time_end", name)
    end
end

function MqttTopicDetailPage.CheckValidTime(startTime,endTime)
    if startTime and endTime and startTime ~= "" and endTime ~= "" then
        local year,month,day = commonlib.timehelp.GetYearMonthDayFromStr(startTime)
        local start_time = os.time({year=year,month=month,day=day})
        year,month,day = commonlib.timehelp.GetYearMonthDayFromStr(endTime)
        local end_time = os.time({year=year,month=month,day=day})
        if start_time > end_time then
            GameLogic.AddBBS(nil,L"开始时间不能大于结束时间")
            return false
        end
        return true,start_time,end_time
    end
    return false
end

function MqttTopicDetailPage.OnClickSearch()
    if not page then
        return
    end
    MqttTopicDetailPage.search_timeStart = page:GetValue("text_mqtt_time_start") or ""
    MqttTopicDetailPage.search_timeEnd = page:GetValue("text_mqtt_time_end") or ""
    MqttTopicDetailPage.search_device_name = page:GetValue("text_mqtt_device") or ""
    MqttTopicDetailPage.search_device_data = page:GetValue("text_mqtt_device_data") or ""
    local bTimeValid,timeStart,timeEnd = MqttTopicDetailPage.CheckValidTime(MqttTopicDetailPage.search_timeStart,MqttTopicDetailPage.search_timeEnd)
    if bTimeValid then
        MqttTopicDetailPage.mqttShowTopicDataList = commonlib.filter(MqttTopicDetailPage.mqttTopicDataList, function (item)
            local isFilterTime = false
            if timeStart < timeEnd then
                isFilterTime = item.publishTime >= timeStart and item.publishTime <= timeEnd
            else
                isFilterTime = item.publishTime >= timeStart
            end
            return  isFilterTime
        end)
    else
        MqttTopicDetailPage.mqttShowTopicDataList = MqttTopicDetailPage.mqttTopicDataList
    end

    if MqttTopicDetailPage.search_device_name ~= "" then
        MqttTopicDetailPage.mqttShowTopicDataList = commonlib.filter(MqttTopicDetailPage.mqttShowTopicDataList, function (item)
            return item.deviceName:find(MqttTopicDetailPage.search_device_name);
        end)
    end

    if MqttTopicDetailPage.search_device_data ~= "" then
        MqttTopicDetailPage.mqttShowTopicDataList = commonlib.filter(MqttTopicDetailPage.mqttShowTopicDataList, function (item)
            return item.msg:find(MqttTopicDetailPage.search_device_data);
        end)
    end

    MqttTopicDetailPage.RefreshPage()
end

function MqttTopicDetailPage.ClearData()
    if page then
        page:SetValue("text_mqtt_device_data", "")
        page:SetValue("text_mqtt_device", "")
        page:SetValue("text_mqtt_time_start", "")
        page:SetValue("text_mqtt_time_end", "")
    end
    MqttTopicDetailPage.search_timeStart = ""
    MqttTopicDetailPage.search_timeEnd = ""
    MqttTopicDetailPage.search_device_name = ""
    MqttTopicDetailPage.search_device_data = ""
    MqttTopicDetailPage.cur_year = os.date("%Y");
    MqttTopicDetailPage.cur_month = os.date("%m");
    MqttTopicDetailPage.cur_year1 = os.date("%Y");
    MqttTopicDetailPage.cur_month1 = os.date("%m");
end


function MqttTopicDetailPage.OnClickClearSearch()
    -- text_mqtt_device_data text_mqtt_device text_mqtt_time_start text_mqtt_time_end
    MqttTopicDetailPage.ClearData()
    MqttTopicDetailPage.mqttShowTopicDataList = MqttTopicDetailPage.mqttTopicDataList
    MqttTopicDetailPage.RefreshPage()
    
end

function MqttTopicDetailPage.OnClickDetail(topicData)
    if topicData then
        local MqttTopicDataDetail = NPL.load('(gl)script/apps/Aries/Creator/Game/Mqtt/Dialog/MqttTopicDataDetail.lua')
        MqttTopicDataDetail.ShowPage(topicData)
    end
end

function MqttTopicDetailPage.OnClickRefresh()
    MqttTopicDetailPage.ClearData()
    MqttTopicDetailPage.LoadTopicDataList(true)
end

