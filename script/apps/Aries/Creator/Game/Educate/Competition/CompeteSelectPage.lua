--[[
Title: CompeteSelectPage
Author(s): pbb
Date: 2023/09/06
Desc:  
Use Lib:
-------------------------------------------------------
local CompeteSelectPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Competition/CompeteSelectPage.lua")
CompeteSelectPage.ShowView();
--]]
local CompetitionApi =  NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Competition/CompetitionApi.lua")
local CompetitionUtils =  NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Competition/CompetitionUtils.lua")
local CompeteSelectPage = NPL.export();

CompeteSelectPage.isNeedGotoEdu = false
CompeteSelectPage.compete_data = nil
local server_time = 0
local page
function CompeteSelectPage.OnInit()
    page = document:GetPageCtrl();
end

function CompeteSelectPage.ShowView(paperId,compete_data)
    if page and page:IsVisible() then
        return
    end
    if not paperId or not compete_data then
        return
    end

    CompeteSelectPage.compete_data = compete_data
    
    CompeteSelectPage.isNeedGotoEdu = false
    CompetitionApi.GetRacePaperList({
        router_params = {
            id = paperId,
        }
    },function(err,msg,data)
        if err == 200 then
            if data and data.submittedPapers then
                GameLogic.AddBBS(nil,"你已经提交试卷了，不可查看试卷内容")
                return
            end
            CompeteSelectPage.HandleData(data)
            CompeteSelectPage.ShowPage()
        else
            if err == 401 then
                GameLogic.GetFilters():apply_filters("EducateLogout", nil ,function()
                    CompeteSelectPage.ShowView(paperId,compete_data)
                end)
            end
            local str = err == 401 and "获取试卷信息失败，请重新登录" or L"获取试卷信息失败，code===="..err
            GameLogic.AddBBS(nil,str)
        end
    end)
    return

    
end

function CompeteSelectPage.ShowPage()
    local params = {
        url = "script/apps/Aries/Creator/Game/Educate/Competition/CompeteSelectPage.html",
        name = "CompeteSelectPage.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 1,
        directPosition = true,
        withBgMask=true,
        align = "_ct",
        x = -640/2,
        y = -393/2,
        width = 640,
        height = 393,
        isTopLevel = true,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end


function CompeteSelectPage.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
end

function CompeteSelectPage.CloseView()
    if page then
        page:CloseWindow()
        page = nil
    end
end


function CompeteSelectPage.OpenWebUrl()
    local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
    local token = commonlib.getfield("System.User.keepworktoken")
    local baseurl = "http://edu-dev.kp-para.cn/login?"
    local url = ""
    local http_env = HttpWrapper.GetDevVersion()
    if http_env == "LOCAL" or http_env == "STAGE" then
        baseurl = "http://edu-dev.kp-para.cn/login?"
    elseif http_env == "RELEASE" then
        baseurl = "http://edu-rls.kp-para.cn/login?"
    else
        baseurl = "http://edu.palaka.cn/login?"
    end
    url = baseurl.."token="..token.."&type=PC"
    local platform = System.os.GetPlatform()
    if platform == "win32" or platform == "emscripten" then
        GameLogic.RunCommand("/open "..url)
        return
    end
    GameLogic.RunCommand("/open -e "..url)

end

function CompeteSelectPage.HandleData(data)
    CompeteSelectPage.ServerData = data
    CompeteSelectPage.CompetiesData={}
    
    if data and data.questionGroups and #data.questionGroups > 0 then
        for k,v in pairs(data.questionGroups) do
            if v.type == 5 or v.type == 6 then
                local competeQuestions = v.competeQuestions or {}
                for _,competeQuestion in pairs(competeQuestions) do
                    if v.type == 6 then
                        CompeteSelectPage.CompetiesData[#CompeteSelectPage.CompetiesData + 1] = competeQuestion --进入世界
                    elseif v.type == 5 then
                        if competeQuestion.creativeType == 3 then
                            CompeteSelectPage.CompetiesData[#CompeteSelectPage.CompetiesData + 1] = competeQuestion --fork世界创造
                        else
                            CompeteSelectPage.isNeedGotoEdu = true --进入智慧教育平台
                        end
                    end
                end
            else
                CompeteSelectPage.isNeedGotoEdu = true --进入智慧教育平台
            end
        end
    end
end

-- type:loadworld 加载世界  forkworld fork世界 createworld 创建世界
function CompeteSelectPage.GetLoadType(data)
    if not data then
        return "createworld"
    end
    if data.type == 5 and data.creativeType == 3 then
        return "forkworld"
    end
    if data.type == 6 then
        return "loadworld"
    end
end

function CompeteSelectPage.OnOpen(index)
    index = index and tonumber(index) or 1
    if CompeteSelectPage.CompetiesData and CompeteSelectPage.CompetiesData[index] then
        CompeteSelectPage.CloseView()
        local select_data = CompeteSelectPage.CompetiesData[index]
        local clientData = CompeteSelectPage.compete_data or {}
        local userId = GameLogic.GetFilters():apply_filters('store_get', 'user/userId');
        local client_compete_data = {
            action="edu_compete_submited",
            competeContentId = clientData.competeContentId,
            competeId = clientData.competeId,
            competePaperId = clientData.paperId,
            competeQuestionId = select_data.id,
            countDown = clientData.countDown,
            enrolmentId = clientData.enrolmentId,
            projectId = select_data.projectId,
            type = CompeteSelectPage.GetLoadType(select_data),
            userId = userId,
        }
        NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Competition/CompetitionManager.lua")
        local CompetitionManager = commonlib.gettable("MyCompany.Aries.Game.Educate.Competete.Manager")
        CompetitionManager:SetCompeteData(client_compete_data)
    end
end