--[[
Title: educate Competition mainpage funcions
Author(s): pbb
Date: 2023/6/9
Desc: 
Use Lib:
-------------------------------------------------------
local CompetitionMain = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Competition/CompetitionMain.lua")
CompetitionMain.ShowPage()
-------------------------------------------------------
]]
local CompetitionUtils =  NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Competition/CompetitionUtils.lua")
local CompetitionApi =  NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Competition/CompetitionApi.lua")
local CompetitionMain = NPL.export()
CompetitionMain.compete_data = nil
local compete_main_data = {}
local page ,page_root
function CompetitionMain.OnInit()
    page = document:GetPageCtrl()
    page_root = page:GetParentUIObject()
    CompetitionMain.GetCompeteData(function()
        CompetitionMain.UpdateTimer()
        CompetitionMain.RefreshPage()
    end)
end

function CompetitionMain.DelayCheck() --超时校验

end 

function CompetitionMain.RefreshPage()
    if page then
        local oldPosY
        if page:GetNode("user_race") and page:GetNode("user_race").control then
            oldPosY = page:GetNode("user_race").control.ClientY
        end
        page:Refresh(0)

        if oldPosY then
            page:GetNode("user_race").control.ClientY = oldPosY
            page:GetNode("user_race").control:Update()
        end
    end
end

function CompetitionMain.GetCompeteData(callback)
    CompetitionApi.GetMineRaceList({
    },function(err,msg,data)
        if err == 200 then
            local recData = data.rows or {}
            echo(recData,true)
            print("我的赛事数据是============")
            CompetitionMain.HandleCompeteData(recData)
            if callback then
                callback()
            end
        else
            if err == 401 then
                GameLogic.GetFilters():apply_filters("EducateLogout", nil ,function()
                    CompetitionMain.GetCompeteData(callback)
                end)
            end
            local str = err == 401 and "获取赛事数据失败，请重新登录" or L"获取赛事数据失败，code===="..err
            GameLogic.AddBBS(nil,str)
        end
    end)
end

function CompetitionMain.ShowPage()
    CompetitionMain.GetCompeteData(function()
        CompetitionMain.ShowView()
    end)
end

function CompetitionMain.HandleCompeteData(data)
    CompetitionMain.compete_data = {}
    
    local curTime = CompetitionUtils.GetServerTime()
    if data and #data > 0 then
        local num = #data
        for i = 1,num do
            local competeData = data[i].compete
            local icon = competeData.icon
            local enrolmentId = data[i].id
            local status = data[i].status
            local temp = {}
            temp.icon = icon
            temp.competeId = competeData.id
            temp.startTime = competeData.startAt
            temp.endTime = competeData.endAt
            temp.name = competeData.name
            temp.sponsor = competeData.sponsor
            temp.status = status
            temp.applyStartAt = competeData.applyStartAt
            temp.applyEndAt = competeData.applyEndAt
            temp.compete_status = competeData.status
            
            local _,startTime,endTime = CompetitionUtils.GetTimeFormat(temp.startTime,temp.endTime)
            temp.isWaitStart = curTime < startTime
            temp.isMain = true
            temp.link = competeData.link
            temp.intro = commonlib.GetLimitLabel(competeData.intro, 240)
            temp.isShowExtra = commonlib.GetUnicodeCharNum(competeData.intro) > 240
            CompetitionMain.compete_data[#CompetitionMain.compete_data + 1] = commonlib.copy(temp)
            local papers = competeData.competeContents or {}
            local paperNum = #papers
            if paperNum > 0 then
                for j=1,paperNum do
                    temp = {}
                    local answerSheetRecord = papers[j].answerSheetRecord or {}
                    temp.icon = icon
                    temp.competeId = competeData.id
                    temp.paperId = papers[j].competePaper.id
                    temp.startTime = papers[j].answerStartAt
                    temp.endTime = papers[j].answerEndAt
                    temp.applyStartAt = competeData.applyStartAt
                    temp.applyEndAt = competeData.applyEndAt
                    temp.compete_status = answerSheetRecord.status or 0
                    temp.status = papers[j].status or status
                    local _,startTime,endTime = CompetitionUtils.GetTimeFormat(temp.startTime,temp.endTime)
                    temp.name = papers[j].competePaper.name
                    temp.competeContentId = papers[j].competePaper.competeContentId
                    temp.isMain = false
                    temp.isWaitStart = curTime < startTime
                    -- --如果外层大赛再开考时间内，试卷未到答题时间，则修改状态为不能进去
                    -- if status == 3 and curTime < startTime then 
                    --     temp.status = 0
                    -- end
                    temp.enrolmentId = enrolmentId
                    temp.sponsor = competeData.sponsor
                    temp.countDown = papers[j].countDown
                    CompetitionMain.compete_data[#CompetitionMain.compete_data + 1] = commonlib.copy(temp)
                end
            end
        end

        -- echo(CompetitionMain.compete_data,true)
    end
end

function CompetitionMain.ShowView()
    print("CompetitionMain.ShowView=============")
    local view_width = 1130
    local view_height = 600
    local params = {
        url = "script/apps/Aries/Creator/Game/Educate/Competition/CompetitionMain.html",
        name = "CompetitionMain.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        zorder = 10,
        directPosition = true,
        cancelShowAnimation = true,
        align = "_ct",
            width = view_width,
            height = view_height,
            x = -view_width/2,
            y = -view_height/2,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function CompetitionMain.ClosePage()
    if page then
        page:CloseWindow()
        page = nil
    end
end


function CompetitionMain.OnClickSubmit(index)
    local index = tonumber(index)
    local competeData = CompetitionMain.compete_data[index]
    if competeData and competeData.status == 6 then
        CompetitionMain.OpenResult(competeData.competeId)
        return
    end

    if competeData and competeData.paperId then
        local CompeteSelectPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Competition/CompeteSelectPage.lua")
        CompeteSelectPage.ShowView(competeData.paperId,competeData);
    end
end

function CompetitionMain.OpenResult(competeId)
    if competeId and competeId > 0 then
        local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
        local token = commonlib.getfield("System.User.keepworktoken") or ""
        local baseurl = "https://cp.palaka.cn/"
        local url = ""
        local http_env = HttpWrapper.GetDevVersion()
        if http_env == "LOCAL" or http_env == "STAGE" then
            baseurl = "http://cp-dev.kp-para.cn/"
        elseif http_env == "RELEASE" then
            baseurl = "http://cp-rls.kp-para.cn/"
        else
            baseurl = "https://cp.palaka.cn/"
        end
        url= baseurl.."?token="..token.."&redirect=/certificat/"..competeId
        local platform = System.os.GetPlatform()
        if platform == "win32" or platform == "emscripten" then
            GameLogic.RunCommand("/open "..url)
            return
        end
        GameLogic.RunCommand("/open -e "..url)
    end
end


function CompetitionMain.OnClickExtra(index)
    if index and index > 0 then
        local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
        local competeData = CompetitionMain.compete_data[index]
        if competeData and competeData.link then
            local token = commonlib.getfield("System.User.keepworktoken") or ""
            local baseurl = "https://cp.palaka.cn/"
            local url = ""
            local http_env = HttpWrapper.GetDevVersion()
            if http_env == "LOCAL" or http_env == "STAGE" then
                baseurl = "http://cp-dev.kp-para.cn/"
            elseif http_env == "RELEASE" then
                baseurl = "http://cp-rls.kp-para.cn/"
            else
                baseurl = "https://cp.palaka.cn/"
            end
            url= baseurl.."?token="..token.."&redirect="..competeData.link
            local platform = System.os.GetPlatform()
            if platform == "win32" or platform == "emscripten" then
                GameLogic.RunCommand("/open "..url)
                return
            end
            GameLogic.RunCommand("/open -e "..url)
        end 
    end
end

function CompetitionMain.UpdateTimer()
    CompetitionMain.updateTimer = CompetitionMain.updateTimer or commonlib.Timer:new({callbackFunc = function(timer)
        if CompetitionMain.compete_data and page then
            local num = #CompetitionMain.compete_data
            for i=1,num do
                local data = CompetitionMain.compete_data[i]
                if data.isWaitStart then
                    local curTime = CompetitionUtils.GetServerTime()
                    local _,startTime,endTime = CompetitionUtils.GetTimeFormat(data.startTime,data.endTime)
                    if curTime >= startTime then
                        GameLogic.AddBBS(nil,L"比赛已经开始，请点击进入按钮，开始这场比赛")
                        CompetitionMain.GetCompeteData(function()
                            CompetitionMain.RefreshPage()
                            timer:Change()
                        end)
                        break
                    end
                end
            end
        end
    end})
    CompetitionMain.updateTimer:Change(1000, 5000)
end

function CompetitionMain.ClearTimer()
    if CompetitionMain.updateTimer then
        CompetitionMain.updateTimer:Change()
        CompetitionMain.updateTimer = nil
    end
end
