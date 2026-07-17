--[[
Title: educate Competition mainpage funcions
Author(s): pbb
Date: 2023/6/9
Desc: 
Use Lib:
-------------------------------------------------------
local CompetitionCreatePaper = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Competition/CompetitionCreatePaper.lua")
CompetitionCreatePaper.ShowPage()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Competition/CompetitionManager.lua")
local CompetitionManager = commonlib.gettable("MyCompany.Aries.Game.Educate.Competete.Manager")
local CompetitionUtils =  NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Competition/CompetitionUtils.lua")
local CompetitionCreatePaper = NPL.export()
CompetitionCreatePaper.projectList = nil
local page 
function CompetitionCreatePaper.OnInit()
    page = document:GetPageCtrl()
end

function CompetitionCreatePaper.ShowPage()
    -- CompetitionManager:CheckInValidCompete(function()
        CompetitionCreatePaper.ShowView()
    -- end)
end

function CompetitionCreatePaper.ShowView()
    print("CompetitionCreatePaper.ShowView=============")
    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Educate/Competition/CompetitionCreatePaper.html",
        name = "CompetitionCreatePaper.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = false,
        zorder = -10,
        click_through = true,
        directPosition = true,
        cancelShowAnimation = true,
        -- DesignResolutionWidth = 1280,
		-- DesignResolutionHeight = 720,
        align = "_fi",
            width = view_width,
            height = view_height,
            x = -view_width/2,
            y = -view_height/2,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    GameLogic.RunCommand("/hide dock")
    CompetitionCreatePaper.UpdateSurplusTime()
end

function CompetitionCreatePaper.UpdateSurplusTime()
    CompetitionCreatePaper.surplus_timer = CompetitionCreatePaper.surplus_timer or commonlib.Timer:new({callbackFunc = function(timer)
        CompetitionCreatePaper.compete_time = CompetitionManager:GetSurplusTime()
        local timestr = CompetitionUtils.GetTimeFormatStr(CompetitionCreatePaper.compete_time)
        local surplus_time_str
        if CompetitionCreatePaper.compete_time and CompetitionCreatePaper.compete_time > 0 then
            local baseTimeStr = "答卷剩余时间为："
            if CompetitionManager:IsCompeteTimeConfig() then
                baseTimeStr = "创作题剩余作答时间为："
            end
            surplus_time_str = baseTimeStr..(timestr or 0)
        else
            surplus_time_str = "答题时间已结束"
        end
        if page then
            page:SetUIValue("name_supurs_time",surplus_time_str or "")
        end
    end});
    CompetitionCreatePaper.surplus_timer:Change(0, 1000);
end

function CompetitionCreatePaper.ClosePage()
    if page then
        page:CloseWindow()
        page = nil
    end
    if CompetitionCreatePaper.surplus_timer then
        CompetitionCreatePaper.surplus_timer:Change()
        CompetitionCreatePaper.surplus_timer = nil
    end
end

function CompetitionCreatePaper.OnSubmitProject()
    if not CompetitionCreatePaper.is_submiting then
        if not CompetitionCreatePaper.SubmitWorld then
            CompetitionCreatePaper.SubmitWorld = commonlib.debounce(function()
                CompetitionManager:SetIsSubmitScore(true)
                CompetitionManager:SubmitWorld()
            end, 300)
        end
        CompetitionCreatePaper.SubmitWorld() 
    end
    
end

function CompetitionCreatePaper.CheckIsSubmitWorld()
    local compete_data = CompetitionManager:GetCompeteData()
    return compete_data and compete_data.type ~= "loadworld"
end
