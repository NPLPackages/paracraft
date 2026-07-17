--[[
Title: mqtt page
Author: pbb
CreateDate: 2024.1.2
Desc: 
use the lib:
------------------------------------------------------------
local MqttMainPage = NPL.load('(gl)script/apps/Aries/Creator/Game/Mqtt/MqttMainPage.lua')
MqttMainPage.ShowPage()
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Mqtt/MqttManager.lua")
local MqttManager = commonlib.gettable("MyCompany.Aries.Creator.Game.MqttManager");
local MqttMainPage = NPL.export()
local page

MqttMainPage.mqttServerList = {}
function MqttMainPage.OnInit()
    page = document:GetPageCtrl()
end

function MqttMainPage.ShowPage()
    if GameLogic.GetFilters():apply_filters('is_signed_in') then
        MqttMainPage.ShowView()
        return
    end

    GameLogic.GetFilters():apply_filters('check_signed_in', L"请先登录", function(result)
        if result == true then
            commonlib.TimerManager.SetTimeout(function()
                MqttMainPage.ShowView()
            end, 1000)
        end
    end)
end

function MqttMainPage.ShowView()
    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Mqtt/MqttMainPage.html",
        name = "MqttMainPage.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = false,
        directPosition = true,
        cancelShowAnimation = true,
        align = "_fi",
        x = -view_width/2,
        y = -view_height/2,
        width = view_width,
        height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    MqttMainPage.mqttServerList = {}
    MqttMainPage.LoadProjectList()
end

function MqttMainPage.RefreshPage(delay)
    if page then
        page:Refresh(delay or 0)
    end
end

function MqttMainPage.LoadProjectList()
    MqttManager.getInstance():LoadProjectList(function(result,data)
        if result == true then
            if data and data.count and data.count > 0 then
                local mqttList = data.rows or {}
                MqttMainPage.mqttServerList = mqttList
                page:GetNode('mqtt_list'):SetAttribute('DataSource', mqttList)
            else
                MqttMainPage.mqttServerList = {}
                page:GetNode('mqtt_list'):SetAttribute('DataSource', {})
            end
            MqttMainPage.RefreshPage()  
            return
        end
        GameLogic.AddBBS(nil,L"暂无数据")
    end)
end

function MqttMainPage.OnClickAddProject()
    local MqttCreateProject = NPL.load('(gl)script/apps/Aries/Creator/Game/Mqtt/Dialog/MqttCreateProject.lua')
    MqttCreateProject.ShowPage()
end

function MqttMainPage.OnClickProjectDetail(index)
    local data = MqttMainPage.mqttServerList[index]
    if data then
        local MqttDetailPage = NPL.load('(gl)script/apps/Aries/Creator/Game/Mqtt/MqttDetailPage.lua')
        MqttDetailPage.ShowPage(data)
    end
end

function MqttMainPage.OnClickProjectDelete(index)
    local data = MqttMainPage.mqttServerList[index]
    if data then
        local MqttDeleteProject = NPL.load('(gl)script/apps/Aries/Creator/Game/Mqtt/Dialog/MqttDeleteProject.lua')
        MqttDeleteProject.ShowPage(data)
    end
end

function MqttMainPage.OnClickProjectUpdate(index)
    local data = MqttMainPage.mqttServerList[index]
    if data then
        local MqttUpdateProject = NPL.load('(gl)script/apps/Aries/Creator/Game/Mqtt/Dialog/MqttUpdateProject.lua')
        MqttUpdateProject.ShowPage(data)
    end
end





