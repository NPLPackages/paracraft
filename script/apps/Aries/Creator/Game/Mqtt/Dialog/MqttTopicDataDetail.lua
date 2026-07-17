--[[
Title: mqtt create project page
Author: pbb
CreateDate: 2024.1.2
Desc: 
use the lib:
------------------------------------------------------------
local MqttTopicDataDetail = NPL.load('(gl)script/apps/Aries/Creator/Game/Mqtt/Dialog/MqttTopicDataDetail.lua')
MqttTopicDataDetail.ShowPage()
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Mqtt/MqttManager.lua")
local MqttManager = commonlib.gettable("MyCompany.Aries.Creator.Game.MqttManager");
local MqttMainPage = NPL.load('(gl)script/apps/Aries/Creator/Game/Mqtt/MqttMainPage.lua')
local MqttTopicDataDetail = NPL.export()
local page
MqttTopicDataDetail.topicData = nil
function MqttTopicDataDetail.OnInit()
    page = document:GetPageCtrl()
end

function MqttTopicDataDetail.ShowPage(data)
    MqttTopicDataDetail.topicData = data
    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Mqtt/Dialog/MqttTopicDataDetail.html",
        name = "MqttTopicDataDetail.ShowPage", 
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