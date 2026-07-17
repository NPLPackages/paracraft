--[[
Title: Paracraft Copilot
Author(s): big
CreateDate: 2024.11.22
Desc: The ParacraftCopilot class provides intelligent assistance and automation within the CodeBlock. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Agent/ParacraftCopilot.lua");
local ParacraftCopilot = commonlib.gettable("MyCompany.Aries.Game.Agent.ParacraftCopilot");
ParacraftCopilot:Init();
-------------------------------------------------------
]]

local ParacraftCopilot = commonlib.gettable("MyCompany.Aries.Game.Agent.ParacraftCopilot");

function ParacraftCopilot:ctor()
end

function ParacraftCopilot:Init()
    -- show the copilot window
    self:ShowCopilotWindow();
end

function ParacraftCopilot:ShowCopilotWindow()
    if (self.isShowPage) then
        return
    end

    local params = {
        url = "script/apps/Aries/Creator/Game/Agent/ParacraftCopilot.html",
        name = "ParacraftCopilot.ShowCopilotWindow",
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        zorder = 1,
        allowDrag = true,
        bShow = true,
        directPosition = true,
        align = "_lt",
        x = 20,
        y = 20,
        width = 400,
        height = 800,
        cancelShowAnimation = true,
        bToggleShowHide = false,
        click_through = true,
    }
    System.App.Commands.Call("File.MCMLWindowFrame", params)
    self.isShowPage = true;
end

function ParacraftCopilot.RefreshAllMessages(toEnd)
    -- rewrite.
end;

function ParacraftCopilot.RefreshLastMessage()
    -- rewrite.
end;

function ParacraftCopilot.GetMessages()
    -- rewrite.
end;

function ParacraftCopilot.GetRoleName()
    -- rewrite.
end;

function ParacraftCopilot.AddArtifacts()
    -- rewrite.
end;
