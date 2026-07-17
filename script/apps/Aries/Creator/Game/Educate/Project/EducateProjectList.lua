--[[
    author:{pbb}
    time:2023-02-20 17:50:48
    uselib:
        local EducateProjectList = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Project/EducateProjectList.lua")
        EducateProjectList.ShowPage()
]]
local Opus = NPL.load("(gl)Mod/WorldShare/cellar/Opus/Opus.lua")
local EducateProjectList = NPL.export()
local page,page_root
function EducateProjectList.OnInit()
    page = document:GetPageCtrl()
end

function EducateProjectList.ShowPage()
    local isOffline = System.options.isOffline --智慧教育离线模式
    if isOffline then
        local OfflineEducateProjectList = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Offline/Project/EducateProjectList.lua")
        OfflineEducateProjectList.ShowPage()
        return
    end
    if GameLogic.GetFilters():apply_filters('is_signed_in') then
        EducateProjectList.ShowView()
        return
    end
    
    GameLogic.GetFilters():apply_filters('check_signed_in', L"请先登录", function(result)
        if result == true then
            commonlib.TimerManager.SetTimeout(function()
                EducateProjectList.ShowView()
            end, 1000)
        end
    end)
end

function EducateProjectList.ShowView()
    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Educate/Project/EducateProjectList.html",
        name = "EducateProjectList.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        zorder = 0,
        directPosition = true,
        cancelShowAnimation = true,
        DesignResolutionWidth = 1280,
		DesignResolutionHeight = 720,
        align = "_fi",
            x = view_width,
            y = view_height,
            width = -view_width/2,
            height = -view_height/2,
    };
    
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    commonlib.TimerManager.SetTimeout(function()
        EducateProjectList.ShowCreate()
    end,200)
    if(params._page ) then
		params._page.OnClose = function(bDestroy)
			EducateProjectList.CloseCreate()
            page = nil
		end
	end
end

function EducateProjectList.ShowCreate()
    if Opus and type(Opus.ShowCreate) == "function" then
        local width = 1132
        local height = 470
        local x = -530
        local y = -230
        Opus:ShowCreate(nil,width,height,x,y,true,1)
    end
end

function EducateProjectList.CloseCreate()
    Opus:CloseOpus()
end

function EducateProjectList.ClosePage()
    if page then
        page:CloseWindow()
    end
    EducateProjectList.CloseCreate()
end





