--[[
    author:pbb
    date:
    Desc:
    use lib:
    local VipCodeExchangeResult = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VipToolTip/VipCodeExchangeResult.lua") 
    VipCodeExchangeResult.ShowView()
]]
local VipCodeExchangeResult = NPL.export()

local page = nil
VipCodeExchangeResult.desc = ""
function VipCodeExchangeResult.OnInit()
    page = document:GetPageCtrl();
end

function VipCodeExchangeResult.ShowView(desc) 
    VipCodeExchangeResult.desc  = desc   
    local view_width = 400
    local view_height = 200
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/VipToolTip/VipCodeExchangeResult.html",
        name = "VipCodeExchangeResult.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        zorder = 5,
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
