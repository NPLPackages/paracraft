--[[
    author:pbb
    date:
    Desc:
    use lib:
        local InviteSuccess = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/InviteFriend/InviteSuccess.lua")
        InviteSuccess.ShowView()
]]
local InviteSuccess = NPL.export()

local page = nil
function InviteSuccess.OnInit()
    page = document:GetPageCtrl();
end

function InviteSuccess.ShowView()
    local view_width = 414
    local view_height = 274
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/InviteFriend/InviteSuccess.html",
        name = "InviteSuccess.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 4,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key,
        directPosition = true,
        align = "_ct",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end