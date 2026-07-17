--[[
Title: Plant Selection UI
Author(s): Copilot
Date: 2025/1/20
Desc: UI for selecting plants to grow
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/PlantSelection.lua");
local PlantSelection = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.PlantSelection");
PlantSelection.Show(function(plantName) 
    print(plantName)
end);
-------------------------------------------------------
]]
local PlantSelection = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.PlantSelection")

function PlantSelection.OnInit()
    -- self.page = document:GetPageCtrl();
end

function PlantSelection.Show(callback)
    PlantSelection.OnSelect = callback
    
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/PlantSelection.html",
        name = "PlantSelection",
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 1000,
        directPosition = true,
            align = "_ct",
            x = -300,
            y = -200,
            width = 600,
            height = 420,
    }
    System.App.Commands.Call("File.MCMLWindowFrame", params)
end

