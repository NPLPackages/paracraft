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

local Notice = NPL.export();
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
    page.OnClose = Notice.CloseView  
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
                    if Notice.GetTimeStamp(a.createdAt) < Notice.GetTimeStamp(b.createdAt) then
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
    --commonlib.echo(Notice.tblNoticeDt,true)
    --commonlib.echo(data,true)
end

function Notice.GetTimeStamp(strTime)
    strTime = strTime or "";
    local year, month, day, hour, min, sec = strTime:match("^(%d+)%D(%d+)%D(%d+)%D(%d+)%D(%d+)%D(%d+)"); 
    local time_stamp = os.time({day=tonumber(day), month=tonumber(month), year=tonumber(year), hour=tonumber(hour) + 8}); -- 这个时间是带时区的 要加8小时
    time_stamp = time_stamp + min * 60 + sec;
    return time_stamp;
end

function Notice.Show(nType)
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
                    zorder = -1,
                    app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
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
    if string.find(url, "http://") or string.find(url, "https://") or string.find(url, "ftp://") then
        isValid = true
    end
    return isValid
end

--点击公告图片，此处需要添加埋点事件
function Notice.OnImageBgClick(data)
    --(data,true)
    local name = data.name
    if string.find(name, "创造周末") and string.find(name, "创造周末") > 0 then
        local ActWeek = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ActWeek/ActWeek.lua")
        ActWeek.ShowView()
        return
    end

    local url = data.url;
    if(url and #url ~= 0 and Notice.IsValidUrl(url)) then 
        ParaGlobal.ShellExecute("open",url, "","", 1);
        GameLogic.GetFilters():apply_filters("user_behavior", 1 ,"click.promotion.announcement");
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
    local key = "Paracraft_Notice_Show";
    local value = "" ;
    local nowtime = os.time();
    if Notice.isSelectShowToday then
        value = string.format("1#%d",nowtime);
    else
        value = string.format("0#%d",nowtime) ;       
    end
    --保存数据的方式
    GameLogic.GetPlayerController():SaveRemoteData(key,value,true);
end

function Notice.CheckCanShow()
    local key = "Paracraft_Notice_Show"
    local value = GameLogic.GetPlayerController():LoadRemoteData(key,"true");
    if value == true or value =="true" then
        Notice.isSelectShowToday = false
        return true
    else
        local isSelect = tonumber(string.sub(value,1,1));
        local saveTime = os.date("%Y-%m-%d",tonumber(string.sub(value,3,-1)));
        local nowTime = os.date("%Y-%m-%d",tonumber(os.date()));
        if tostring(saveTime) ~= tostring(nowTime) then
            Notice.isSelectShowToday = false ;        
        else
            Notice.isSelectShowToday = (isSelect == 1 and true or false);
        end
        return not Notice.isSelectShowToday;
    end   
end