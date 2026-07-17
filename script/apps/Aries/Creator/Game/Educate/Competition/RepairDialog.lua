--[[
Title: RepairDialog
Author(s): pbb
Date: 2024/04/26
Desc:  
Use Lib:
-------------------------------------------------------
local RepairDialog = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Competition/RepairDialog.lua")
RepairDialog.ShowView("",function(result) end);
--]]

local RepairDialog = NPL.export()
RepairDialog.callback = nil
RepairDialog.msg = nil
local page = nil
function RepairDialog.OnInit()
    page = document:GetPageCtrl()
end

function RepairDialog.ShowView(msg, callback)
    if page then
        page:CloseWindow()
        page = nil
    end
    RepairDialog.callback = callback
    RepairDialog.msg = (msg and msg ~= "") and msg or L"确定“重新加载”后将会打开新的世界，当前的世界数据就会被删除，是否确认重新加载？"

    local view_width, view_height = 0, 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Educate/Competition/RepairDialog.html",
        name = "RepairDialog.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        zorder = 1,
        directPosition = true,
        align = "_fi",
        x = -view_width/2,
        y = -view_height/2,
        width = view_width,
        height = view_height,
        isTopLevel = true,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function RepairDialog.OnClose()
    if page then
        page:CloseWindow()
        page = nil
    end
end

function RepairDialog.OnBtnSure()
    if RepairDialog.callback and type(RepairDialog.callback) == "function" then
        print("repair dialog callback===============0")
        RepairDialog.callback(true)
    end
    RepairDialog.OnClose()
end

function RepairDialog.OnBtnCancel()
    if RepairDialog.callback and type(RepairDialog.callback) == "function" then
        print("repair dialog callback===============1")
        RepairDialog.callback(false)
    end
    RepairDialog.OnClose()
end