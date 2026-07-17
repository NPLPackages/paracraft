--[[
Title: mqtt create project page
Author: pbb
CreateDate: 2024.1.2
Desc: 
use the lib:
------------------------------------------------------------
local MqttCreateTopic = NPL.load('(gl)script/apps/Aries/Creator/Game/Mqtt/Dialog/MqttCreateTopic.lua')
MqttCreateTopic.ShowPage()
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Mqtt/MqttManager.lua")
local MqttManager = commonlib.gettable("MyCompany.Aries.Creator.Game.MqttManager");
local MqttMainPage = NPL.load('(gl)script/apps/Aries/Creator/Game/Mqtt/MqttMainPage.lua')
local MqttDetailPage = NPL.load('(gl)script/apps/Aries/Creator/Game/Mqtt/MqttDetailPage.lua')
local MqttCreateTopic = NPL.export()
local page

MqttCreateTopic.iotProjectId = nil
function MqttCreateTopic.OnInit()
    page = document:GetPageCtrl()
end

function MqttCreateTopic.ShowPage(iotProjectId)
    MqttCreateTopic.iotProjectId = iotProjectId
    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Mqtt/Dialog/MqttCreateTopic.html",
        name = "MqttCreateTopic.ShowPage", 
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
end

function MqttCreateTopic.OnClickAddTopic()
    if not page or not MqttCreateTopic.iotProjectId then
        return 
    end
    local desc = page:GetValue("text_mqtt_desc_create") or ""
    page:CloseWindow()
    MqttManager.getInstance():AddTopic(MqttCreateTopic.iotProjectId,desc,function(success,data)
        -- echo(data,true)
        if success then
            GameLogic.AddBBS(nil,L"创建成功")
            MqttMainPage.LoadProjectList()
            MqttDetailPage.LoadTopicList(true)
        else
            GameLogic.AddBBS(nil,L"创建失败")
        end
        MqttCreateTopic.iotProjectId = nil
    end)
end