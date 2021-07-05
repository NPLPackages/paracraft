--[[
    author:pbb
    date:
    Desc:
    use lib:
    local SummerCampIntro = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampIntro.lua") 
    SummerCampIntro.ShowView()
]]
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local httpwrapper_version = HttpWrapper.GetDevVersion();
local SummerCampIntro = NPL.export()

local page = nil
function SummerCampIntro.OnInit()
    page = document:GetPageCtrl();
end

function SummerCampIntro.ShowView()
    local view_width = 920
    local view_height = 690
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampIntro.html",
        name = "SummerCampIntro.ShowView", 
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

function SummerCampIntro.GotoSummerWorld()
    -- if not GameLogic.GetFilters():apply_filters('service.session.is_real_name') then
    --     _guihelper.MessageBox("亲爱的同学，夏令营活动需要实名才能参与，快去实名吧。", nil, nil,nil,nil,nil,nil,{ ok = L"确定"});
    --             _guihelper.MsgBoxClick_CallBack = function(res)
    --                 if(res == _guihelper.DialogResult.OK) then
    --                     GameLogic.GetFilters():apply_filters(
    --                     'show_certificate',
    --                     function(result)
    --                         if (result) then
    --                             local DockPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockPage.lua");
    --                             DockPage.RefreshPage(0.01)
    --                             GameLogic.QuestAction.AchieveTask("40006_1", 1, true)
    --                         end
    --                     end)
    --                 end
    --             end     
    --     return
    -- end
    if httpwrapper_version == "ONLINE" then
        GameLogic.RunCommand(string.format("/loadworld -force -s %d", 70351));
    end
end