--[[
author:yangguiyi
date:
Desc:
use lib:
local SummerCampSignShowView = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampSignShowView.lua") 
SummerCampSignShowView.ShowView()
]]

local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local httpwrapper_version = HttpWrapper.GetDevVersion();
local SummerCampSignShowView = NPL.export()

local page = nil
function SummerCampSignShowView.OnInit()
    page = document:GetPageCtrl();
    page.OnCreate = SummerCampSignShowView.OnCreate
    page.OnClose = SummerCampSignShowView.CloseView
end

function SummerCampSignShowView.ShowView()
    keepwork.sign_wall.get_my_greeting({}, function(err, message, data)
        -- print("vzzzzzzzzzzzzzzzzzzzzzzzzzzzz", err)
        -- echo(data, true)
        if err == 200 then
            SummerCampSignShowView.greeting_data = data.greeting
            SummerCampSignShowView.InitData()
            local view_width = 572
            local view_height = 445
            local params = {
                url = "script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampSignShowView.html",
                name = "SummerCampSignShowView.ShowView", 
                isShowTitleBar = false,
                DestroyOnClose = true,
                style = CommonCtrl.WindowFrame.ContainerStyle,
                allowDrag = true,
                enable_esc_key = true,
                zorder = 0,
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
    end)

end

function SummerCampSignShowView.OnCreate()

end

function SummerCampSignShowView.CloseView()
    -- body
end

function SummerCampSignShowView.InitData()

end

function SummerCampSignShowView.GetDesc()
    if SummerCampSignShowView.greeting_data then
        return SummerCampSignShowView.greeting_data.content
    end

    return ""
end

function SummerCampSignShowView.OpenSignView()
    page:CloseWindow()
    SummerCampSignShowView.CloseView()

    local SummerCampSignView = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampSignView.lua") 
    SummerCampSignView.ShowView()
end