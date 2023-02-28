--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{pbb}
    time:2022-10-20 14:11:24
]]

local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros");
Macros.IsMouseTrackMode = false
local record_data = {}
local play_data = {}

function Macros.InitMouseTrack()
    record_data = {}
    play_data = {}
    Macros.IsMouseTrackMode = false
end

function Macros.BeginMouseTrack() 
    Macros.IsMouseTrackMode = true
    record_data = {}
    play_data = {}
    commonlib.TimerManager.SetTimeout(function()  
        if Macros:IsRecording() then
            Macros.ClearCapslockData(true)
        end
    end, 1)
end

function Macros.EndMouseTrack() 
    Macros.IsMouseTrackMode = false
    commonlib.TimerManager.SetTimeout(function()  
        if Macros:IsRecording() then
            Macros.ClearCapslockData()
        end
    end, 1)
    if Macros:IsPlaying() then
        Macros.PlayMouseTrack()
    end
end

function Macros.GenerRecordMacros()
    -- echo(record_data,true)
    if Macros:IsRecording() then
        for i,v in ipairs(record_data) do
            Macros:AddMacro("mouseTrack", v.x, v.y, v.duration)
            -- Macros:AddMacro("Idle", v.duration)
        end
    end
    record_data = {}
end

function Macros.mouseTrack(x,y, duration)
    Macros.AddMouseTrack(x,y,duration)
end

function Macros.RecordMouseTrack(x,y,duration)
    if not Macros.IsMouseTrack() then
        return 
    end
    local isPosRecord,index = false,-1
    for i=1,#record_data do
        if record_data[i].x == x and record_data[i].y == y then
            isPosRecord = true
            index = i
            break
        end
    end
    if isPosRecord then
        local data = record_data[index]
        if data then
            data.duration = data.duration + duration or 0
        end
        record_data[index] = data
    else
        record_data[#record_data + 1] = {x=x,y=y,duration=duration}
    end
end

function Macros.AddMouseTrack(x,y,duration)
    play_data[#play_data + 1] = {x=x,y=y,duration=duration}
end

function Macros.PlayMouseTrack()
    -- print("dddddddddddddddd")
    if play_data and #play_data > 0 then
        local midDuration = 30
        local dataNum = #play_data 
        local total_time = 0
        for i=1,dataNum do
            total_time = total_time + play_data[i].duration
        end
        midDuration = math.floor(total_time / dataNum + 0.5)

        for i=1,dataNum do
            if play_data[i].duration - midDuration > 1000 then
                play_data[i].isUse = true
            end
        end

        local results = Macros.SmoothPoint(play_data)
        echo(results)
        Macros:Pause();

        -- local LessonDraw = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Lesson/LessonDraw.lua") 
        -- LessonDraw.ShowView(results)

        Macros:Resume()
    end
end

function Macros.SmoothPoint(pointDts,smootNum)
    if not pointDts or #pointDts <= 2 then
        return pointDts
    end
    local index = 1
    local startPos = pointDts[1]
    local endPos = pointDts[#pointDts]
    local startDataNum = #pointDts
    local smootNum = startDataNum
    local step = 1/smootNum
    local result = pointDts
    while index < smootNum do
        local temp = {}
        local num = #result
        temp[#temp + 1] = startPos
        for i,v in ipairs(result) do
            if i <= num - 1 then
                if result[i].isUse then
                    temp[#temp + 1] = result[i]
                end
                if result[i].x ~= result[i + 1].x and result[i].y ~= result[i + 1].y and (math.abs(result[i].x-result[i + 1].x) > 5 or math.abs(result[i].y-result[i + 1].y) > 5) then
                    local newX = math.floor((result[i].x + result[i + 1].x)*0.5)
                    local newY = math.floor((result[i].y + result[i + 1].y)*0.5)
                    temp[#temp + 1] = {x=newX,y=newY}
                else
                    if not result[i].isUse then
                        temp[#temp + 1] = result[i]
                    end
                end
            end
        end
        temp[#temp + 1] = endPos
        result = temp
        index = index + 1
    end
    return result
end

function Macros.IsMouseTrack()
    return Macros.IsMouseTrackMode
end

function Macros.ClearCapslockData(bBegin)
    local keyIndex = -1
    for i=#Macros.macros,1,-1 do
        local name = Macros.macros[i].name
        local params = Macros.macros[i].params
        if name == "KeyPress" and params == "\"DIK_CAPSLOCK\"" then
            keyIndex = i
            break
        end
    end
    if keyIndex > 0 then
        table.remove(Macros.macros,keyIndex)
        local preIndex = keyIndex - 1
        local name = Macros.macros[preIndex].name
        local params = Macros.macros[preIndex].params
        if name == "KeyPressTrigger" and params == "\"DIK_CAPSLOCK\"" then
            table.remove(Macros.macros,preIndex)
        end

        if bBegin then
            local macro = Macros.macros[keyIndex]
            if macro and macro.name == "BeginMouseTrack" then
                local premacro = Macros.macros[keyIndex - 1]
                local premacro1 = Macros.macros[keyIndex - 2]
                if premacro and premacro1 and (premacro.name == premacro1.name) and premacro.name=="Idle" then
                    table.remove(Macros.macros,keyIndex - 1)
                end
            end
        end
    end
end
