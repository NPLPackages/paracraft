--[[
Title: mqtt create project page
Author: pbb
CreateDate: 2024.1.2
Desc: 
use the lib:
------------------------------------------------------------
local MqttClearTopic = NPL.load('(gl)script/apps/Aries/Creator/Game/Mqtt/Dialog/MqttClearTopic.lua')
MqttClearTopic.ShowPage()
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Mqtt/MqttManager.lua")
local MqttManager = commonlib.gettable("MyCompany.Aries.Creator.Game.MqttManager");
local MqttMainPage = NPL.load('(gl)script/apps/Aries/Creator/Game/Mqtt/MqttMainPage.lua')
local MqttClearTopic = NPL.export()
local page
MqttClearTopic.clearData = nil
function MqttClearTopic.OnInit()
    page = document:GetPageCtrl()
end

function MqttClearTopic.ShowPage(data)
    MqttClearTopic.clearData = data
    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Mqtt/Dialog/MqttClearTopic.html",
        name = "MqttClearTopic.ShowPage", 
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

function MqttClearTopic.OnClickTopicClear()
    if not page or not MqttClearTopic.clearData then
        return 
    end
    page:CloseWindow()
    local id = MqttClearTopic.clearData.id or -1
    MqttClearTopic.clearData = nil
    MqttManager.getInstance():ClearTopic(id,function(success,data)
        -- echo(data,true)
        print("clear topic ====================",success)
        if success then
            GameLogic.AddBBS(nil,L"清空成功")
            MqttMainPage.LoadProjectList()
        else
            GameLogic.AddBBS(nil,L"清空失败")
        end
    end)
end