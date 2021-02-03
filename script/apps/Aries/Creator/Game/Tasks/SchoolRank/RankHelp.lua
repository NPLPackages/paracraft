--[[
    local RankHelp = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SchoolRank/RankHelp.lua");
    RankHelp.ShowView()
]]
local RankHelp = NPL.export()

local page 
function RankHelp.OnInit()
	page = document:GetPageCtrl();
end

function RankHelp.ShowView()
    local view_width = 740
	local view_height = 560
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/SchoolRank/RankHelp.html",
        name = "RankHelp.ShowView", 
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