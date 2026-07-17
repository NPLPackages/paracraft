--[[
Title: mqtt create project page
Author: pbb
CreateDate: 2024.1.2
Desc: 
use the lib:
------------------------------------------------------------
local MqttUpdateProject = NPL.load('(gl)script/apps/Aries/Creator/Game/Mqtt/Dialog/MqttUpdateProject.lua')
MqttUpdateProject.ShowPage(data)
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Mqtt/MqttManager.lua")
local MqttManager = commonlib.gettable("MyCompany.Aries.Creator.Game.MqttManager");
local MqttMainPage = NPL.load('(gl)script/apps/Aries/Creator/Game/Mqtt/MqttMainPage.lua')
local MqttUpdateProject = NPL.export()
local page
MqttUpdateProject.editProjectData = nil
function MqttUpdateProject.OnInit()
    page = document:GetPageCtrl()
end

function MqttUpdateProject.ShowPage(data)
    MqttUpdateProject.editProjectData = data
    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Mqtt/Dialog/MqttUpdateProject.html",
        name = "MqttUpdateProject.ShowPage", 
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

function MqttUpdateProject.OnClickUpdateProject()
    if not page or not MqttUpdateProject.editProjectData then
        return 
    end
    local name = page:GetValue("text_mqtt_name_update")
    if not name or name == "" then
        GameLogic.AddBBS(nil,L"请输入正确的项目名称")
        return 
    end
    if name == MqttUpdateProject.editProjectData.name then
        page:CloseWindow()
        return 
    end
    local id = MqttUpdateProject.editProjectData.id or -1
    page:CloseWindow()
    MqttManager.getInstance():UpdateProject(id,name,function(success,data)
        -- echo(data,true)
        if success then
            GameLogic.AddBBS(nil,L"修改成功")
            MqttMainPage.LoadProjectList()
        else
            GameLogic.AddBBS(nil,L"修改失败")
        end
    end)
end