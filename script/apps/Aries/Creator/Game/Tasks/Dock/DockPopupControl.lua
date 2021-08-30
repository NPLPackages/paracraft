--[[
Title: DockPopupControl
Author(s): pbb
Date: 2021/4/7
Desc:  
Use Lib:
-------------------------------------------------------
local DockPopupControl = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockPopupControl.lua").StartPopup();
--]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandManager.lua");
local KeepWorkItemManager = NPL.load('(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua')
local Notice = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/NoticeV2/Notice.lua")
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local DockPopupControl = NPL.export()--commonlib.gettable("MyCompany.Aries.Game.Tasks.Dock.DockPopupControl");

DockPopupControl.popup_index = 1
DockPopupControl.max_popup_index = 3
DockPopupControl.popup_num = 0
DockPopupControl.isShow = false

function DockPopupControl.StartPopup(bCommand)
    if not GameLogic.GetFilters():apply_filters('is_signed_in') or bCommand then
        return
    end
    if DockPopupControl.isShow then
        return 
    end
    if DockPopupControl.IsInSummerCampWorld() then
        return 
    end
    DockPopupControl.isShow = true
    DockPopupControl.popup_num = 0
    DockPopupControl.popup_index =1
    if DockPopupControl.popup_index == 1 then
        DockPopupControl.ShowRealNameCertificate()
    end
end

function DockPopupControl.GotoNextPopup()
    if not GameLogic.GetFilters():apply_filters('is_signed_in') then
        return
    end
	
--	local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");
--	if(MovieManager:HasActiveCameraPlaying()) then
--		return
--	end

    DockPopupControl.popup_index = DockPopupControl.popup_index + 1
    if DockPopupControl.popup_index == 2 then
        DockPopupControl.ShowHomeWorkTip()
    elseif DockPopupControl.popup_index == 3 then
        DockPopupControl.ShowGuide()
    elseif DockPopupControl.popup_index == 4 then
        DockPopupControl.ShowNotice()
    end
end

function DockPopupControl.StopPopup()
    DockPopupControl.popup_num = 0
    DockPopupControl.popup_index =1
end

function DockPopupControl.IsInSummerCampWorld()
    local id_list = {
        ONLINE = 70351,
        RELEASE = 20669,
    }
    local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
    local httpwrapper_version = HttpWrapper.GetDevVersion();
    local world_id = id_list[httpwrapper_version]
	local project_id = WorldCommon.GetWorldTag("kpProjectId");
	if project_id == world_id 
        or project_id == 72966 
        or project_id == 73104
        or project_id == 72945
        or project_id == 79969 then
		return true
	end

	return false
end

function DockPopupControl.SetIsInSummerCampWorld(isIn)
    DockPopupControl.bInSummerCampWorld = isIn
end

function DockPopupControl.ShowNotice()
    DockPopupControl.popup_num = DockPopupControl.popup_num + 1
    -- if ((System.User.isVipSchool or System.User.isVip)) then
    --     if not DockPopupControl.IsInSummerCampWorld() then
    --         local SummerCampNotice = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampNotice.lua") 
    --         SummerCampNotice.ShowView()
    --     end        
    -- else
    --     if Notice.CheckCanShow() then
    --         Notice.Show(0)
    --     end  
    -- end  
    if Notice.CheckCanShow() then
        Notice.Show(0)
    end  
end

function DockPopupControl.ShowRealNameCertificate()
    if not GameLogic.GetFilters():apply_filters('service.session.is_real_name') then
        DockPopupControl.popup_num = DockPopupControl.popup_num + 1
        DockPopupControl.GotoNextPopup()
    else
        DockPopupControl.GotoNextPopup()
    end
end

function DockPopupControl.ShowHomeWorkTip()    
	-- local HomeWorkTip = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/HomeWork/HomeWorkTip.lua") 
    -- HomeWorkTip.Show()
    DockPopupControl.GotoNextPopup()
end

function DockPopupControl.GetBeginnerWorldId()
    local httpwrapper_version = HttpWrapper.GetDevVersion();
    if httpwrapper_version == 'ONLINE' then
        return 29477
    elseif httpwrapper_version == 'RELEASE' then
        return 1376
    else
        return 0
    end
end

function DockPopupControl.GetGuideWorldId()
    local httpwrapper_version = HttpWrapper.GetDevVersion();
    if httpwrapper_version == 'ONLINE' then
        return 40499
    elseif httpwrapper_version == 'RELEASE' then
        return 1457
    else
        return 0
    end
end

function DockPopupControl.ShowGuide()
    local where = GameLogic.GetFilters():apply_filters('service.session.get_user_where')
    if DockPopupControl.popup_num ==2 or where == "SCHOOL" then
        DockPopupControl.GotoNextPopup()
        return 
    end

    if not KeepWorkItemManager.HasGSItem(60001) then
        DockPopupControl.popup_num = DockPopupControl.popup_num + 1
        DockPopupControl.GotoNextPopup()

        return
    end

    if not KeepWorkItemManager.HasGSItem(60007) then
        DockPopupControl.popup_num = DockPopupControl.popup_num + 1
        _guihelper.MessageBox(
            L"是否参观3D校园？",
            function(res)
                if res and res == _guihelper.DialogResult.OK then
                    CommandManager:RunCommand('/loadworld -s -force ' .. DockPopupControl.GetGuideWorldId())
                end

                if res and res == _guihelper.DialogResult.Cancel then
                    DockPopupControl.GotoNextPopup()
                end
            end,
            _guihelper.MessageBoxButtons.OKCancel_CustomLabel
        )

        return
    end
    DockPopupControl.GotoNextPopup()
end

function DockPopupControl.CloseAllPage()
    
end

-- function DockPopupControl.InsertPopup(name)

-- end

-- function DockPopupControl.UpdatePopup()

-- end

-- function DockPopupControl.DeletePopup(name)

-- end
