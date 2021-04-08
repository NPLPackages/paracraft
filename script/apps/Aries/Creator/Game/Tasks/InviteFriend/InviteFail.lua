--[[
    author:pbb
    date:
    Desc:
    use lib:
        local InviteFail = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/InviteFriend/InviteFail.lua")
        InviteFail.ShowView()
]]
local InviteFail = NPL.export()

local page = nil
InviteFail.errcode = nil
function InviteFail.OnInit()
    page = document:GetPageCtrl();
end

function InviteFail.ShowView(errcode)
    InviteFail.errcode = errcode
    local view_width = 350
    local view_height = 168
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/InviteFriend/InviteFail.html",
        name = "InviteFail.ShowView", 
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