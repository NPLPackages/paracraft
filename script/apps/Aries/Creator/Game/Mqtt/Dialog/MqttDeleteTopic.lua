--[[
Title: mqtt create project page
Author: pbb
CreateDate: 2024.1.2
Desc: 
use the lib:
------------------------------------------------------------
local MqttDeleteTopic = NPL.load('(gl)script/apps/Aries/Creator/Game/Mqtt/Dialog/MqttDeleteTopic.lua')
MqttDeleteTopic.ShowPage()
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Mqtt/MqttManager.lua")
local MqttManager = commonlib.gettable("MyCompany.Aries.Creator.Game.MqttManager");
local MqttMainPage = NPL.load('(gl)script/apps/Aries/Creator/Game/Mqtt/MqttMainPage.lua')
local MqttDetailPage = NPL.load('(gl)script/apps/Aries/Creator/Game/Mqtt/MqttDetailPage.lua')
local MqttDeleteTopic = NPL.export()
local page
MqttDeleteTopic.deleteData = nil
function MqttDeleteTopic.OnInit()
    page = document:GetPageCtrl()
end

function MqttDeleteTopic.ShowPage(data)
    MqttDeleteTopic.deleteData = data
    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Mqtt/Dialog/MqttDeleteTopic.html",
        name = "MqttDeleteTopic.ShowPage", 
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

function MqttDeleteTopic.OnClickDeleteTopic()
    if not page or not MqttDeleteTopic.deleteData then
        return 
    end
    page:CloseWindow()
    local id = MqttDeleteTopic.deleteData.id or -1
    MqttDeleteTopic.deleteData = nil
    MqttManager.getInstance():DeleteTopic(id,function(success,data)
        -- echo(data,true)
        print("delete====================",success)
        if success then
            GameLogic.AddBBS(nil,L"删除成功")
            MqttMainPage.LoadProjectList()
            MqttDetailPage.LoadTopicList(true)
        else
            GameLogic.AddBBS(nil,L"删除失败")
        end
    end)
end