--[[
Title: mqtt create project page
Author: pbb
CreateDate: 2024.1.2
Desc: 
use the lib:
------------------------------------------------------------
local MqttCreateProject = NPL.load('(gl)script/apps/Aries/Creator/Game/Mqtt/Dialog/MqttCreateProject.lua')
MqttCreateProject.ShowPage()
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Mqtt/MqttManager.lua")
local MqttManager = commonlib.gettable("MyCompany.Aries.Creator.Game.MqttManager");
local MqttMainPage = NPL.load('(gl)script/apps/Aries/Creator/Game/Mqtt/MqttMainPage.lua')
local MqttCreateProject = NPL.export()
local page

function MqttCreateProject.OnInit()
    page = document:GetPageCtrl()
end

function MqttCreateProject.ShowPage()
    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Mqtt/Dialog/MqttCreateProject.html",
        name = "MqttCreateProject.ShowPage", 
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

function MqttCreateProject.OnClickAddProject()
    if not page then
        return 
    end
    local name = page:GetValue("text_mqtt_name_create")
    if not name or name == "" then
        GameLogic.AddBBS(nil,L"请输入正确的项目名称")
        return 
    end
    page:CloseWindow()
    MqttManager.getInstance():AddProject(name,function(success,data)
        -- echo(data,true)
        if success then
            GameLogic.AddBBS(nil,L"创建成功")
            MqttMainPage.LoadProjectList()
        else
            GameLogic.AddBBS(nil,L"创建失败")
        end
    end)
end