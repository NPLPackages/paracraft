--[[
Title: mqtt create project page
Author: pbb
CreateDate: 2024.1.2
Desc: 
use the lib:
------------------------------------------------------------
local MqttUpdateTopic = NPL.load('(gl)script/apps/Aries/Creator/Game/Mqtt/Dialog/MqttUpdateTopic.lua')
MqttUpdateTopic.ShowPage(data)
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Mqtt/MqttManager.lua")
local MqttManager = commonlib.gettable("MyCompany.Aries.Creator.Game.MqttManager");
local MqttDetailPage = NPL.load('(gl)script/apps/Aries/Creator/Game/Mqtt/MqttDetailPage.lua')
local MqttUpdateTopic = NPL.export()
local page
MqttUpdateTopic.editTopicData = nil
function MqttUpdateTopic.OnInit()
    page = document:GetPageCtrl()
end

function MqttUpdateTopic.ShowPage(data)
    MqttUpdateTopic.editTopicData = data
    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Mqtt/Dialog/MqttUpdateTopic.html",
        name = "MqttUpdateTopic.ShowPage", 
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

function MqttUpdateTopic.OnClickUpdateTopic()
    if not page or not MqttUpdateTopic.editTopicData then
        return 
    end
    local desc = page:GetValue("text_mqtt_desc_update")
    if not desc or desc == "" then
        GameLogic.AddBBS(nil,L"请输入正确的主题备注")
        return 
    end
    if desc == MqttUpdateTopic.editTopicData.desc then
        page:CloseWindow()
        return 
    end
    page:CloseWindow()
    local topicId = MqttUpdateTopic.editTopicData.id 
    MqttManager.getInstance():UpdateTopic(topicId,desc,function(success,data)
        if success then
            GameLogic.AddBBS(nil,L"修改成功")
            MqttDetailPage.LoadTopicList(true)
        else
            GameLogic.AddBBS(nil,L"修改失败")
        end
    end)
end