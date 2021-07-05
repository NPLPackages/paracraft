--[[
    author:pbb
    date:
    Desc:
    use lib:
    local SummerCampNotice = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampNotice.lua") 
    SummerCampNotice.ShowView()
]]
local SummerCampNotice = NPL.export()
SummerCampNotice.strImgPath = "Texture/Aries/Creator/keepwork/SummerCamp/"
local strPath = ';NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampNotice.lua")'
local SummerCampMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampMainPage.lua") 
local parent_root
SummerCampNotice.tblNoticeDt = {
    {   icon="img_notice2_232X225_32bits.png#0 0 232 225",
        gift_icon="img_item1_200X80_32bits.png#0 0 200 80",        
    },
    {   icon="img_notice3_232X225_32bits.png#0 0 232 225",
        gift_icon="img_item2_200X80_32bits.png#0 0 200 80",        
    },
    {   icon="img_notice4_232X225_32bits.png#0 0 232 225",
        gift_icon="img_item3_200X80_32bits.png#0 0 200 80",        
    },
    {   icon="img_notice5_232X225_32bits.png#0 0 232 225",
        gift_icon="img_item4_200X80_32bits.png#0 0 200 80",        
    }
}
SummerCampNotice.m_nSelectAdIndex = 1
SummerCampNotice.tbAdsDt = {
    {
        icon = "img_noticegg1_493X243_32bits.png#0 0 493 243",
        name = "zhengcheng",
    },
    {
        icon = "img_noticegg2_493X243_32bits.png#0 0 493 243",
        name = "lesson",
    },
    {
        icon = "img_noticegg3_493X243_32bits.png#0 0 493 243",
        name = "xinguan",
    },    
    {
        icon = "img_noticegg4_493X243_32bits.png#0 0 493 243",
        name = "camp",
    },
    {
        icon = "img_noticegg5_493X243_32bits.png#0 0 493 243",
        name = "hero",
    },

}


local NoticeTimeId = 100890
local isFirstIn = false
local page = nil
function SummerCampNotice.OnInit()
    page = document:GetPageCtrl();
    parent_root  = page:GetParentUIObject() 
    page.OnCreate = SummerCampNotice.OnCreate 
end

function SummerCampNotice.ShowView()
    if SummerCampMainPage then
        SummerCampMainPage.ShowView()
        return
    end
    
    local view_width = 980
    local view_height = 560
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampNotice.html",
        name = "SummerCampNotice.ShowView", 
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
    NPL.SetTimer(NoticeTimeId, 15, ';NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampNotice.lua").Timer()');
    SummerCampNotice.RefreshPage()
end

function SummerCampNotice.Timer()
    if isFirstIn then
        isFirstIn = true
        return
    end
    local num = #SummerCampNotice.tbAdsDt
    SummerCampNotice.m_nSelectAdIndex = SummerCampNotice.m_nSelectAdIndex + 1
    if SummerCampNotice.m_nSelectAdIndex > num then
        SummerCampNotice.m_nSelectAdIndex = 1
    end
    SummerCampNotice.RefreshPage()
end

function SummerCampNotice.OnClosePage()
    if page then
        page:CloseWindow()
        SummerCampNotice.m_nSelectAdIndex = 1
        NPL.KillTimer(NoticeTimeId);
    end
end

local isCanClickPre = true
function SummerCampNotice.OnClickPreAds()
    if not isCanClickPre then
        return
    end
    -- commonlib.TimerManager.SetTimeout(function() 
    --     isCanClickPre = true
    -- end, 500);
    -- isCanClickPre = false
    local num = #SummerCampNotice.tbAdsDt
    SummerCampNotice.m_nSelectAdIndex = SummerCampNotice.m_nSelectAdIndex - 1
    if SummerCampNotice.m_nSelectAdIndex < 1 then
        SummerCampNotice.m_nSelectAdIndex = num
    end
    SummerCampNotice.RefreshPage()
end
local isCanClickNext = true
function SummerCampNotice.OnClickNextAds()
    if not isCanClickNext then
        return
    end
    -- commonlib.TimerManager.SetTimeout(function() 
    --     isCanClickNext = true
    -- end, 500);
    -- isCanClickNext = false
    local num = #SummerCampNotice.tbAdsDt
    SummerCampNotice.m_nSelectAdIndex = SummerCampNotice.m_nSelectAdIndex + 1
    if SummerCampNotice.m_nSelectAdIndex > num then
        SummerCampNotice.m_nSelectAdIndex = 1
    end
    SummerCampNotice.RefreshPage()
end

function SummerCampNotice.IsInSummerCampWorld()    
    local world_id = SummerCampNoticeIntro.GetSummerWorldId()
	local project_id = WorldCommon.GetWorldTag("kpProjectId");
	if project_id == world_id then
		return true
	end
	return false
end

function SummerCampNotice.GetSummerWorldId()
    local id_list = {
        ONLINE = 70351,
        RELEASE = 20669,
    }
    local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
    local httpwrapper_version = HttpWrapper.GetDevVersion();
    local world_id = id_list[httpwrapper_version]
    return world_id
end

function SummerCampNotice.OnClickAds(name)
    
    if name == "zhengcheng" then --征程
        SummerCampNotice.OnClosePage()
        GameLogic.QuestAction.OpenSummerVipView()
        return 
    end
    if name == "lesson" then  --名师公开课
        GameLogic.RunCommand("/open https://keepwork.com/official/tips/xu.ni-wx/dinghuistudio")
        return
    end

    if name == "xinguan" then --新冠
        GameLogic.GetCodeGlobal():BroadcastTextEvent("openUI", {name = "taskMain"}, function()
            SummerCampNotice.OnClosePage()
        end);
        return
    end

    if name == "camp" then --国家赛事集训营
        return
    end

    if name == "hero" then --盖世英雄
        SummerCampNotice.OnClosePage()
        GameLogic.RunCommand("/goto 18907,12,19188")
        return
    end
end

function SummerCampNotice.OnClickDot(name)
    local index = tonumber(name)
    if SummerCampNotice.m_nSelectAdIndex == index then
        return 
    end
    SummerCampNotice.m_nSelectAdIndex = index
    SummerCampNotice.RefreshPage()
end

function SummerCampNotice.RefreshPage()
    if page then
        page:Refresh(0)
    end    
end

function SummerCampNotice.GetCurAdsBgStyle()
    local curAds = SummerCampNotice.tbAdsDt[SummerCampNotice.m_nSelectAdIndex]
    return string.format("<div onclick='OnClickAds' name='%s' style='margin-left:44px; margin-top:-134px; width: 493px;height: 243px;background: url(%s%s);'></div>",curAds.name,SummerCampNotice.strImgPath,curAds.icon)
end

function SummerCampNotice.OnClickBottom(name)
    if not name then
        return
    end
    SummerCampNotice.OnClosePage()
    local index = tonumber(string.sub(name,7,-1))
    local SummerCampNoticeIntro = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampNoticeIntro.lua") 
    SummerCampNoticeIntro.ShowView(index)
end

function SummerCampNotice.OnMouseEnter(index)
    local name = "bottomsel"..index
    local pNode = ParaUI.GetUIObject(name)
    if pNode then
        pNode.visible = true
    end
end

function SummerCampNotice.OnMouseLeave(index)
    local name = "bottomsel"..index
    local pNode = ParaUI.GetUIObject(name)
    if pNode then
        pNode.visible = false
    end
end

function SummerCampNotice.OnCreate()
    for i=1,4 do 
        local pNode = ParaUI.GetUIObject("bottomsel"..i)
        pNode.visible = false
    end
end