--[[
Title: mqtt create project page
Author: pbb
CreateDate: 2024.1.2
name: 
use the lib:
------------------------------------------------------------
local MqttCreateDevice = NPL.load('(gl)script/apps/Aries/Creator/Game/Mqtt/Dialog/MqttCreateDevice.lua')
MqttCreateDevice.ShowPage()
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Mqtt/MqttManager.lua")
local MqttManager = commonlib.gettable("MyCompany.Aries.Creator.Game.MqttManager");
local MqttMainPage = NPL.load('(gl)script/apps/Aries/Creator/Game/Mqtt/MqttMainPage.lua')
local MqttDetailPage = NPL.load('(gl)script/apps/Aries/Creator/Game/Mqtt/MqttDetailPage.lua')
local MqttCreateDevice = NPL.export()
local page
MqttCreateDevice.iotProjectId = nil
function MqttCreateDevice.OnInit()
    page = document:GetPageCtrl()
end

function MqttCreateDevice.ShowPage(iotProjectId)
    MqttCreateDevice.iotProjectId = iotProjectId
    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Mqtt/Dialog/MqttCreateDevice.html",
        name = "MqttCreateDevice.ShowPage", 
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

function MqttCreateDevice.OnClickAddDevice()
    if not page or not MqttCreateDevice.iotProjectId then
        return 
    end
    local name = page:GetValue("text_mqtt_name_create")
    if not name or name == "" then
        GameLogic.AddBBS(nil,L"请输入正确的设备名称")
        return 
    end
    page:CloseWindow()
    MqttManager.getInstance():AddDevice(MqttCreateDevice.iotProjectId,name,function(success,data)
        -- echo(data,true)
        if success then
            GameLogic.AddBBS(nil,L"创建成功")
            MqttMainPage.LoadProjectList()
            MqttDetailPage.LoadDeviceList(true)
        else
            GameLogic.AddBBS(nil,L"创建失败")
        end
    end)
end