--[[
Title: Notice
Author(s): pbb
Date: 2021/01/18
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/NoticeV2/Notice.lua").Show();
--]]
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local DockPopupControl = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockPopupControl.lua")
local Notice = NPL.export();

local httpwrapper_version = HttpWrapper.GetDevVersion();
local campIds = {
    ONLINE = 41570,
    RELEASE = 1471,
}

local page

local SAVE_DATA_KEY = "Paracraft_Notice_ShowV2"

Notice.isSelectShowToday = true;
Notice.nSelectIndex = 1;
Notice.tblNoticeDt = {};
Notice.nDataNum = 0
Notice.servertime = 0
Notice.isCanClickNext = true
Notice.mainData = {}
Notice.rendData = {}

function Notice.OnInit()
    page = document:GetPageCtrl(); 
end

function Notice.GetPageCtrl()
    return page
end

--处理获得的数据
function Notice.GetPageData(data)
    --print("Notice.GetPageData====================")
    if data and type(data) == "table" then
        local tblSize = #data;
        if tblSize > 1 then
            table.sort(data,function(a,b)
                if a.priority < b.priority then
                    return true;
                elseif a.priority == b.priority then
                    if commonlib.timehelp.GetTimeStampByDateTime(a.createdAt) < commonlib.timehelp.GetTimeStampByDateTime(b.createdAt) then
                        return true;
                    end
                    return false;
                else
                    return false;
                end
            end)           
        end
    end


    local isSelectMain = false
    Notice.nDataNum = 0
    Notice.tblNoticeDt = {};
    for k , v in pairs(data) do
        if not isSelectMain then
            Notice.mainData.id = v.id;
            Notice.mainData.cover = v.cover or "";
            Notice.mainData.url = v.url or "";
            Notice.mainData.name = v.name
            Notice.mainData.index = k
            isSelectMain = true
        else
            local temp = {};
            temp.id = v.id;
            temp.cover = v.cover;
            temp.url = v.url or "";
            temp.name = v.name
            temp.index = k
            table.insert(Notice.tblNoticeDt,temp);
        end        
    end
    Notice.nDataNum = #Notice.tblNoticeDt
    for i = Notice.nSelectIndex,Notice.nSelectIndex + 3 do 
        Notice.rendData[i] = Notice.tblNoticeDt[i]
    end
    -- commonlib.echo(Notice.tblNoticeDt,true)
    -- commonlib.echo(data,true)
end

function Notice.Show(nType,zorder)
    Notice.LoadLocalData()
    keepwork.notic.announcements({
    },function(info_err, info_msg, info_data)
        if info_err == 200 then
            --commonlib.echo(info_data,true)            
            Notice.GetPageData(info_data); 
            if Notice.nDataNum > 0 then
                local viewwidth = 1080
                local viewheight = 660
                local params = {
                    url = "script/apps/Aries/Creator/Game/Tasks/NoticeV2/Notice.html",
                    name = "Notice.Show", 
                    isShowTitleBar = false,
                    DestroyOnClose = true,
                    style = CommonCtrl.WindowFrame.ContainerStyle,
                    allowDrag = true,
                    enable_esc_key = true,
                    zorder = zorder or -1,
                    -- app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
                    directPosition = true,                
                    align = "_ct",
                    x = -viewwidth/2,
                    y = -viewheight/2,
                    width = viewwidth,
                    height = viewheight,
                };                
                System.App.Commands.Call("File.MCMLWindowFrame", params)               
            else
                if nType == 1 then --点击活动按钮进入的
                    _guihelper.MessageBox("目前暂无公告及活动哦");
                end
            end            
        else
            _guihelper.MessageBox("活动或者公告数据异常，请重试或者联系客服~");
        end
    end) 

end

function Notice.CloseView()
    -- body
    Notice.nSelectIndex = 1;
    Notice.tblNoticeDt = {};
    Notice.rendData = {}  
    Notice.isCanClickNext = true
    Notice.nDataNum = 0
    Notice.servertime = 0
    Notice.mainData = {}
    Notice.SaveLocalData()
    DockPopupControl.StopPopup()
    if page then
        page:CloseWindow()
        page = nil
    end
end


function Notice.OnImageClick(data)
    --print("OnImageClick==========================")    
    Notice.OnImageBgClick(data)
end

function Notice.OnMainImageClick()
    --print("OnMainImageClick================")
    Notice.OnImageBgClick(Notice.mainData)
end

function Notice.RefreshPage()
    if not page then
        return
    end
    page:Refresh(0)
end

function Notice.getCover(index)    
    return Notice.tblNoticeDt[index].cover
end

function Notice.IsValidUrl(url)
    local isValid = false
    local str_url = url or ""
    if string.find(str_url, "http://") or string.find(str_url, "https://") or string.find(str_url, "ftp://") then
        isValid = true
    end
    return isValid
end

--点击公告图片，此处需要添加埋点事件
function Notice.OnImageBgClick(data)
    --(data,true)
    
    local name = data.name 
    -- if string.find(name, "神通杯") and string.find(name, "神通杯") > 0 then
    --     Notice.CloseView()
    --     NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/NoticeV2/ShenTongNotice.lua").ShowView();
    --     GameLogic.GetFilters():apply_filters("user_behavior", 1 ,"click.promotion.announcement", { from='board1', fromName = 'shentong' });
    --     return
    -- end  
    if string.find(name, "冬令营") and string.find(name, "冬令营") > 0 then
        Notice.CloseView()
        GameLogic.RunCommand(string.format("/loadworld -s -auto %s", 132939))
        --GameLogic.AddBBS(nil,"敬请期待~~~~~")
        return
    end  
     
    if string.find(name, "推荐课") and string.find(name, "推荐课") > 0 then
        Notice.CloseView()
        GameLogic.GetFilters():apply_filters("user_behavior", 1 ,"click.promotion.announcement", { from='board2', fromName = 'reccource' });
        local RedSummerCampRecCoursePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampRecCoursePage.lua");
        RedSummerCampRecCoursePage.Show();
        return
    end
    
    if string.find(name, "结伴学习") and string.find(name, "结伴学习") > 0 then
        Notice.CloseView()
        local InviteFriend = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/InviteFriend/InviteFriend.lua")
        InviteFriend.ShowView()
        GameLogic.GetFilters():apply_filters("user_behavior", 1 ,"click.promotion.announcement", { from='board4', fromName = 'invite_friend' });
        return
    end  

    -- if string.find(name, "资源库") and string.find(name, "资源库") > 0 then
    --     Notice.CloseView()
    --     local KeepWorkMallPage = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/KeepWorkMallPage.lua");
    --     KeepWorkMallPage.Show();
    --     GameLogic.GetFilters():apply_filters("user_behavior", 1 ,"click.promotion.announcement", { from='board4', fromName = 'sf_res' });
    --     return
    -- end   
    if string.find(name, "换装系统") and string.find(name, "换装系统") > 0 then
        Notice.CloseView()
        GameLogic.GetFilters():apply_filters("user_behavior", 1 ,"click.promotion.announcement", { from='board3', fromName = 'character' });
        local page = NPL.load("Mod/GeneralGameServerMod/App/ui/page.lua");
        last_page_ctrl = page.ShowUserInfoPage({username = System.User.keepworkUsername});
        return
    end
    -- if string.find(name, "老师的礼物") and string.find(name, "老师的礼物") > 0 then
    --     Notice.CloseView()
    --     local ActTeacher = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ActTeacher/ActTeacher.lua") 
    --     ActTeacher.ShowView()
    --     GameLogic.GetFilters():apply_filters("user_behavior", 1 ,"click.promotion.announcement", { from='board4', fromName = 'act_teacher' });
    --     return
    -- end   
    
    if string.find(name, "人工智能") and string.find(name, "人工智能") > 0 then
        Notice.CloseView()
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestAllCourse.lua").Show();
        GameLogic.GetFilters():apply_filters("user_behavior", 1 ,"click.promotion.announcement", { from='board5', fromName = 'AI_class' });
        return
    end

    -- if string.find(name, "夏令营") and string.find(name, "夏令营") > 0 then
    --     Notice.CloseView()
    --     local SummerCampIntro = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampIntro.lua") 
    --     SummerCampIntro.ShowView()
    --     GameLogic.GetFilters():apply_filters("user_behavior", 1 ,"click.promotion.announcement", { from='board1', fromName = 'summercamp' });
    --     return
    -- end  
    -- if string.find(name, "端午") and string.find(name, "端午") > 0 then
    --     Notice.CloseView()
    --     GameLogic.GetFilters():apply_filters("user_behavior", 1 ,"click.promotion.announcement", { from='board2', fromName = 'actdragon' });
    --     local ActDragonBoatFestival = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ActDragonBoatFestival/ActDragonBoatFestival.lua");
    --     ActDragonBoatFestival:Init();
    --     return
    -- end
    -- if string.find(name, "探索界面") and string.find(name, "探索界面") > 0 then
    --     Notice.CloseView()
    --     GameLogic.GetFilters():apply_filters('show_offical_worlds_page')
    --     GameLogic.GetFilters():apply_filters("user_behavior", 1 ,"click.promotion.announcement", { from='board3', fromName = 'explore' });
    --     return
    -- end
    -- if string.find(name, "排行榜") and string.find(name, "排行榜") > 0 then
    --     Notice.CloseView()
    --     GameLogic.GetFilters():apply_filters("user_behavior", 1 ,"click.promotion.announcement", { from='board2', fromName = 'rank' });
    --     local RankPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Rank/Rank.lua")
    --     RankPage.Show();
    --     return
    -- end
    -- if string.find(name, "新皮肤") and string.find(name, "新皮肤") > 0 then
    --     Notice.CloseView()
    --     GameLogic.GetFilters():apply_filters("user_behavior", 1 ,"click.promotion.announcement", { from='board3', fromName = 'character' });
    --     local page = NPL.load("Mod/GeneralGameServerMod/App/ui/page.lua");
    --     last_page_ctrl = page.ShowUserInfoPage({username = System.User.keepworkUsername});
    --     return
    -- end

    -- if string.find(name, "五一活动") and string.find(name, "五一活动") > 0 then
    --     Notice.CloseView()
    --     NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Act51Ask/Act51AskRule.lua").Show()
    --     GameLogic.GetFilters():apply_filters("user_behavior", 1 ,"click.promotion.announcement", { from='board1', fromName = '51_activity' });
    --     return
    -- end
    -- if string.find(name, "换装系统") and string.find(name, "换装系统") > 0 then
    --     Notice.CloseView()
    --     local page = NPL.load("Mod/GeneralGameServerMod/App/ui/page.lua");
    --     last_page_ctrl = page.ShowUserInfoPage({username = System.User.keepworkUsername});
    --     GameLogic.GetFilters():apply_filters("user_behavior", 1 ,"click.promotion.announcement", { from='board5', fromName = 'clothes_sys' });
    --     return
    -- end
    

    local url = data.url;
    if(url and #url ~= 0 and Notice.IsValidUrl(url)) then 
        ParaGlobal.ShellExecute("open",url, "","", 1);
        GameLogic.GetFilters():apply_filters("user_behavior", 1 ,"click.promotion.announcement" ,{ from='board6', fromName = 'act_url_'..url});
    else
        return 
    end    
end

--点击下一页或者上一页
function Notice.OnClickNextPage(page)
    if Notice.isCanClickNext then
        local curPage = Notice.nSelectIndex;
        curPage = curPage + page
        if curPage > Notice.nDataNum - 3 or curPage < 1 then
            return
        end   
        Notice.rendData = {}      
        Notice.nSelectIndex = curPage
        local index = 1
        for i = Notice.nSelectIndex,Notice.nSelectIndex + 3 do 
            Notice.rendData[index] = Notice.tblNoticeDt[i]
            index = index + 1
        end
        --print("重新渲染")
        --echo(Notice.rendData,true)
        Notice.RefreshPage()
        Notice.isCanClickNext = false
        commonlib.TimerManager.SetTimeout(function()
			Notice.isCanClickNext = true
		end, 500);
    end    
end

--保存数据
function Notice.SaveLocalData()
    local nowtime = os.time()
    local data = {}
    data.IsAutoOpen = not Notice.isSelectShowToday
    data.CurSetTime = nowtime
    --保存数据的方式
    GameLogic.GetPlayerController():SaveRemoteData(SAVE_DATA_KEY,data);
end

function Notice.CheckCanShow()
    local data = GameLogic.GetPlayerController():LoadRemoteData(SAVE_DATA_KEY,nil);
    if not data or type(data) ~= "table" then
        return true
    else
        local saveTime = os.date("%Y-%m-%d",data.CurSetTime or os.time())
        local nowTime = os.date("%Y-%m-%d",tonumber(os.time()))
        if tostring(saveTime) ~= tostring(nowTime) then
            return true
        end
        return data.IsAutoOpen
    end   
end

function Notice.LoadLocalData()
    local data = GameLogic.GetPlayerController():LoadRemoteData(SAVE_DATA_KEY,nil);
    if not data or type(data) ~= "table" then
        Notice.isSelectShowToday = false
    else
        local saveTime = os.date("%Y-%m-%d",data.CurSetTime or os.time())
        local nowTime = os.date("%Y-%m-%d",tonumber(os.time()))
        if tostring(saveTime) ~= tostring(nowTime) then
            Notice.isSelectShowToday = false        
        else
            Notice.isSelectShowToday = not data.IsAutoOpen 
        end
    end   
end