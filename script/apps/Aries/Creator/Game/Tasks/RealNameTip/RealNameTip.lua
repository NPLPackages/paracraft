--[[
    author:pbb
    date:
    Desc:
    use lib:
    local RealNameTip = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RealNameTip/RealNameTip.lua") 
    RealNameTip.ShowView()
]]
local RealNameTip = NPL.export()

local page = nil
local callback
function RealNameTip.OnInit()
    page = document:GetPageCtrl();
end

function RealNameTip.ShowView(callback)
    callback = callback
    local view_width = 910
    local view_height = 630
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/RealNameTip/RealNameTip.html",
        name = "RealNameTip.ShowView", 
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
    GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.macro.task", { from = "macrosave",  name = "web-save",});
end

function RealNameTip.CloseView()
    if page then
        page:CloseWindow()
    end
end

function RealNameTip.ClickShowRealGift()
    RealNameTip.CloseView()
    GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.macro.task", { from = "macrosave",  name = "homework-award",});
    GameLogic.GetFilters():apply_filters(
        'show_certificate',
        function(result)
            if (result) then
                GameLogic.AddBBS(nil,"实名成功了，请重新点击保存")
            end
        end
    );
end