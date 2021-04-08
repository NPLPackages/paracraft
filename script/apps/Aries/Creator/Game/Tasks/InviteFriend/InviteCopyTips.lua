--[[
    author:pbb
    date:
    Desc:
    use lib:
        local InviteCopyTips = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/InviteFriend/InviteCopyTips.lua")
        InviteCopyTips.ShowView()
]]
local InviteCopyTips = NPL.export()

local page = nil
InviteCopyTips.isShow = false
function InviteCopyTips.OnInit()
    page = document:GetPageCtrl();
end

function InviteCopyTips.ShowView()
    if InviteCopyTips.isShow then
        return 
    end
    local view_width = 350
    local view_height = 168
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/InviteFriend/InviteCopyTips.html",
        name = "InviteCopyTips.ShowView", 
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
    InviteCopyTips.isShow = true
end