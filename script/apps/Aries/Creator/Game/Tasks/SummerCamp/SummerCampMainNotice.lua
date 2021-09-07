--[[
    author:yangguiyi
    date:
    Desc:
    use lib:
    local SummerCampMainNotice = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampMainNotice.lua") 
    SummerCampMainNotice.ShowView()
]]
local SummerCampMainNotice = NPL.export()
SummerCampMainNotice.strImgPath = "Texture/Aries/Creator/keepwork/SummerCamp/"
local strPath = ';NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampMainNotice.lua")'
local SummerCampMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampMainPage.lua") 
local parent_root
SummerCampMainNotice.tblNoticeDt = {
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
SummerCampMainNotice.m_nSelectAdIndex = 1
SummerCampMainNotice.tbAdsDt = {
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
function SummerCampMainNotice.OnInit()
    page = document:GetPageCtrl();
    parent_root  = page:GetParentUIObject() 
    page.OnCreate = SummerCampMainNotice.OnCreate 
end

function SummerCampMainNotice.ShowView(parent)
    local view_width = 1035
    local view_height = 623

    page = Map3DSystem.mcml.PageCtrl:new({ 
        url = "script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampMainNotice.html" ,
        click_through = false,
    } );
    SummerCampMainNotice._root = page:Create("SummerCampMainNotice.ShowView", parent, "_lt", 0, 0, view_width, view_height)

    SummerCampMainNotice.RefreshPage()
    return page
end

function SummerCampMainNotice.Timer()
    if isFirstIn then
        isFirstIn = true
        return
    end
    local num = #SummerCampMainNotice.tbAdsDt
    SummerCampMainNotice.m_nSelectAdIndex = SummerCampMainNotice.m_nSelectAdIndex + 1
    if SummerCampMainNotice.m_nSelectAdIndex > num then
        SummerCampMainNotice.m_nSelectAdIndex = 1
    end
    SummerCampMainNotice.RefreshPage()
end

function SummerCampMainNotice.OnClosePage()
    SummerCampMainNotice.m_nSelectAdIndex = 1
    NPL.KillTimer(NoticeTimeId);
    SummerCampMainPage.CloseView()
end

local isCanClickPre = true
function SummerCampMainNotice.OnClickPreAds()
    if not isCanClickPre then
        return
    end
    -- commonlib.TimerManager.SetTimeout(function() 
    --     isCanClickPre = true
    -- end, 500);
    -- isCanClickPre = false
    local num = #SummerCampMainNotice.tbAdsDt
    SummerCampMainNotice.m_nSelectAdIndex = SummerCampMainNotice.m_nSelectAdIndex - 1
    if SummerCampMainNotice.m_nSelectAdIndex < 1 then
        SummerCampMainNotice.m_nSelectAdIndex = num
    end
    SummerCampMainNotice.RefreshPage()
end
local isCanClickNext = true
function SummerCampMainNotice.OnClickNextAds()
    if not isCanClickNext then
        return
    end
    -- commonlib.TimerManager.SetTimeout(function() 
    --     isCanClickNext = true
    -- end, 500);
    -- isCanClickNext = false
    local num = #SummerCampMainNotice.tbAdsDt
    SummerCampMainNotice.m_nSelectAdIndex = SummerCampMainNotice.m_nSelectAdIndex + 1
    if SummerCampMainNotice.m_nSelectAdIndex > num then
        SummerCampMainNotice.m_nSelectAdIndex = 1
    end
    SummerCampMainNotice.RefreshPage()
end

function SummerCampMainNotice.IsInSummerCampWorld()    
    local world_id = SummerCampNoticeIntro.GetSummerWorldId()
	local project_id = WorldCommon.GetWorldTag("kpProjectId");
	if project_id == world_id then
		return true
	end
	return false
end

function SummerCampMainNotice.GetSummerWorldId()
    local id_list = {
        ONLINE = 70351,
        RELEASE = 20669,
    }
    local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
    local httpwrapper_version = HttpWrapper.GetDevVersion();
    local world_id = id_list[httpwrapper_version]
    return world_id
end

function SummerCampMainNotice.OnClickAds(name)
    
    if name == "zhengcheng" then --征程
        SummerCampMainNotice.OnClosePage()
        GameLogic.QuestAction.OpenSummerVipView()
        return 
    end
    if name == "lesson" then  --名师公开课
        GameLogic.RunCommand("/open https://keepwork.com/official/tips/xu.ni-wx/dinghuistudio")
        return
    end

    if name == "xinguan" then --新冠
        GameLogic.GetCodeGlobal():BroadcastTextEvent("openUI", {name = "taskMain"}, function()
            SummerCampMainNotice.OnClosePage()
        end);
        return
    end

    if name == "camp" then --国家赛事集训营
        return
    end

    if name == "hero" then --盖世英雄
        SummerCampMainNotice.OnClosePage()
        GameLogic.RunCommand("/goto 18907,12,19188")
        return
    end
end

function SummerCampMainNotice.OnClickDot(name)
    local index = tonumber(name)
    if SummerCampMainNotice.m_nSelectAdIndex == index then
        return 
    end
    SummerCampMainNotice.m_nSelectAdIndex = index
    SummerCampMainNotice.RefreshPage()
end

function SummerCampMainNotice.RefreshPage()
    if page then
        page:Refresh(0)
    end    
end

function SummerCampMainNotice.GetCurAdsBgStyle()
    local curAds = SummerCampMainNotice.tbAdsDt[SummerCampMainNotice.m_nSelectAdIndex]
    return string.format("<div onclick='OnClickAds' name='%s' style='position: relative;margin-left:0px; margin-top:0px; width: 493px;height: 243px;background: url(%s%s);'></div>",curAds.name,SummerCampMainNotice.strImgPath,curAds.icon)
end

function SummerCampMainNotice.OnClickBottom(name)
    if not name then
        return
    end
    SummerCampMainNotice.OnClosePage()
    local index = tonumber(string.sub(name,7,-1))
    local SummerCampNoticeIntro = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampNoticeIntro.lua") 
    SummerCampNoticeIntro.ShowView(index)
end

function SummerCampMainNotice.OnMouseEnter(index)
    local name = "bottomsel"..index
    local pNode = ParaUI.GetUIObject(name)
    if pNode then
        pNode.visible = true
    end
end

function SummerCampMainNotice.OnMouseLeave(index)
    local name = "bottomsel"..index
    local pNode = ParaUI.GetUIObject(name)
    if pNode then
        pNode.visible = false
    end
end

function SummerCampMainNotice.OnCreate()
    for i=1,4 do 
        local pNode = ParaUI.GetUIObject("bottomsel"..i)
        pNode.visible = false
    end
end