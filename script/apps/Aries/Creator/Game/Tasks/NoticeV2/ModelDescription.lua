--[[
    author:{pbb}
    time:2022-02-25 10:02:28
    use lib:
        local ModelDescription = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/NoticeV2/ModelDescription.lua") 
        ModelDescription.ShowView()
]]

local ModelDescription = NPL.export()

local page = nil
function ModelDescription.OnInit()
    page = document:GetPageCtrl();
end

function ModelDescription.ShowView()
    local view_width = 448
    local view_height = 356
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/NoticeV2/ModelDescription.html",
        name = "ModelDescription.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 100,
        directPosition = true,
        align = "_ct",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end