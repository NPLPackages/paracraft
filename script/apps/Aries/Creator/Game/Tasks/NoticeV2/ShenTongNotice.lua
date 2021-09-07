--[[
    author:{pbb}
    time:2021-08-27 18:09:57
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/NoticeV2/ShenTongNotice.lua").ShowView();
]]

local ShenTongNotice = NPL.export()

local page = nil
ShenTongNotice.m_datas = {{}}
function ShenTongNotice.OnInit()
    page = document:GetPageCtrl();
end

function ShenTongNotice.ShowView()
    local view_width = 750
    local view_height = 520
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/NoticeV2/ShenTongNotice.html",
        name = "ShenTongNotice.ShowView", 
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