--[[
Title: mqtt create project page
Author: pbb
CreateDate: 2024.1.2
Desc: 
use the lib:
------------------------------------------------------------
local MqttDeleteProject = NPL.load('(gl)script/apps/Aries/Creator/Game/Mqtt/Dialog/MqttDeleteProject.lua')
MqttDeleteProject.ShowPage()
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Mqtt/MqttManager.lua")
local MqttManager = commonlib.gettable("MyCompany.Aries.Creator.Game.MqttManager");
local MqttMainPage = NPL.load('(gl)script/apps/Aries/Creator/Game/Mqtt/MqttMainPage.lua')
local MqttDeleteProject = NPL.export()
local page
MqttDeleteProject.deleteData = nil
function MqttDeleteProject.OnInit()
    page = document:GetPageCtrl()
end

function MqttDeleteProject.ShowPage(data)
    MqttDeleteProject.deleteData = data
    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Mqtt/Dialog/MqttDeleteProject.html",
        name = "MqttDeleteProject.ShowPage", 
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

function MqttDeleteProject.OnClickDeleteProject()
    if not page or not MqttDeleteProject.deleteData then
        return 
    end
    page:CloseWindow()
    local id = MqttDeleteProject.deleteData.id or -1
    MqttDeleteProject.deleteData = nil
    MqttManager.getInstance():DeleteProject(id,function(success,data)
        -- echo(data,true)
        print("delete====================",success)
        if success then
            GameLogic.AddBBS(nil,L"删除成功")
            MqttMainPage.LoadProjectList()
        else
            GameLogic.AddBBS(nil,L"删除失败")
        end
    end)
end