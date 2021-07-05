--[[
    author:pbb
    date:
    Desc:
    use lib:
    local SummerCampNoticeIntro = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampNoticeIntro.lua") 
    SummerCampNoticeIntro.ShowView(1)
]]
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local SummerCampNoticeIntro = NPL.export()
SummerCampNoticeIntro.strImgPath = "Texture/Aries/Creator/keepwork/SummerCamp/"

SummerCampNoticeIntro.n_curIndex = nil

local page = nil
function SummerCampNoticeIntro.OnInit()
    page = document:GetPageCtrl();
end

function SummerCampNoticeIntro.IsInSummerCampWorld()    
    local world_id = SummerCampNoticeIntro.GetSummerWorldId()
	local project_id = WorldCommon.GetWorldTag("kpProjectId");
	if project_id == world_id then
		return true
	end
	return false
end

function SummerCampNoticeIntro.GetSummerWorldId()
    local id_list = {
        ONLINE = 70351,
        RELEASE = 20669,
    }
    local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
    local httpwrapper_version = HttpWrapper.GetDevVersion();
    local world_id = id_list[httpwrapper_version]
    return world_id
end

function SummerCampNoticeIntro.OnClickGo()
    if not SummerCampNoticeIntro.IsInSummerCampWorld() then
        if page then
            page:CloseWindow()
        end
        GameLogic.RunCommand(string.format("/loadworld -force -s %d", SummerCampNoticeIntro.GetSummerWorldId()));
        return
    end
    if page then
        page:CloseWindow()
    end
    if SummerCampNoticeIntro.n_curIndex == 1 then
        --[[当用户点击【立即前往】的按钮时，如果用户不在夏令营的世界中，则首先拉起世界。随后打开【梦回摇篮】护照的面板（YJ出）]]
        GameLogic.GetCodeGlobal():BroadcastTextEvent("openRemainOriginalUI", {name = "mainPage"}, function()
           
        end);
    elseif SummerCampNoticeIntro.n_curIndex == 2 then
        --[[当用户点击【立即前往】的按钮时，如果用户不在夏令营的世界中，则首先拉起世界。随后打开【重走长征路】护照的面板（YJ出）并传送到指定坐标（YJ出）]]
        --GameLogic.AddBBS(nil,"敬请期待~")
        GameLogic.GetCodeGlobal():BroadcastTextEvent("openLongMarchUI", {name = "mainPage"});
    elseif SummerCampNoticeIntro.n_curIndex == 3 then
        --[[当用户点击【立即前往】的按钮时，如果用户不在夏令营的世界中，则首先拉起世界。将用户扔进2in1学习的世界（杜提供）。]]
        GameLogic.RunCommand(string.format("/goto %d %d %d", 18876,13,19189)); --18876,12,19189
    elseif SummerCampNoticeIntro.n_curIndex == 4 then
        --[[当用户点击【立即前往】的按钮时，如果用户不在夏令营的世界中，则首先拉起世界。如果用户已经完成了开营仪式，则打开【祝福编辑面板】。（面板见《闪闪红星》策划案）]]
        local SummerCampSignShowView = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampSignShowView.lua") 
        SummerCampSignShowView.ShowView()
    end
end

function SummerCampNoticeIntro.ShowView(index)
    SummerCampNoticeIntro.n_curIndex = index
    local view_width = 830
    local view_height = 560
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampNoticeIntro.html",
        name = "SummerCampNoticeIntro.ShowView", 
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


function SummerCampNoticeIntro.OnClosePage()
    if page then
        page:CloseWindow()
        local SummerCampNotice = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampNotice.lua") 
        SummerCampNotice.ShowView()
    end
end

function SummerCampNoticeIntro.RefreshPage()
    if page then
        page:Refresh(0.01)
    end
end