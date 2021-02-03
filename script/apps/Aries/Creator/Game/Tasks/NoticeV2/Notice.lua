--[[
Title: Notice
Author(s): pbb
Date: 2021/01/18
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/NoticeV2/Notice.lua").Show();
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

local NoticeTimeId = 2001
local Notice = NPL.export();
Notice.isSelectShowToday = true;
Notice.nSelectIndex = 1;
Notice.tblNoticeDt = {};
Notice.nDataNum = 0
Notice.servertime = 0
Notice.isCanClickNext = true
Notice.mainData = {}
Notice.rendData = {}

local exids = {
    sign1=11001,
    sign2=11001,
    sign3=11002,
    sign4=11002,
    sign5=11003,
    sign6=11003,
    sign7=11004
}
Notice.signData ={}
Notice.signTime = 0;-- 上一次签到时间
Notice.signNum = 0; --连续签到天数

local minSignTimeDis = 24 * 60 * 60 --间隔一天
local maxSignTimeDis = 48 * 60 * 60 --间隔两天

Notice.gsid = 40004

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
    local addNum = Notice.GetAddNum(Notice.nDataNum) --数据不足，先补充无用数据
    for i = 1,addNum do
        local temp = {}
        temp.id = 10001 + i;
        temp.cover = "";
        temp.url = "";
        temp.name = "temp"
        temp.index = Notice.nDataNum + i
        table.insert(Notice.tblNoticeDt,temp);
    end

    Notice.nDataNum = #Notice.tblNoticeDt
    for i = Notice.nSelectIndex,Notice.nSelectIndex + 3 do 
        Notice.rendData[i] = Notice.tblNoticeDt[i]
    end
    --commonlib.echo(Notice.tblNoticeDt,true)
    --commonlib.echo(data,true)
end

function Notice.GetAddNum(num)
    if num <= 4 then
        return 4 - num
    elseif num > 4 and num <= 8 then
        return 8 - num
    elseif num > 8 and num <= 12 then
        return 12 - num
    else
        return 16 - num
    end
end

function Notice.InitSignConfig()
    local icons = {"1_138X138_32bits","1_138X138_32bits","2_138X138_32bits","2_138X138_32bits","3_138X138_32bits","4_138X138_32bits","5_194X138_32bits"}
    local dayicons = {"d1_75X35_32bits","d2_75X35_32bits","d3_75X35_32bits","d4_75X35_32bits","d5_75X35_32bits","d6_75X35_32bits","d7_75X35_32bits"}
    Notice.signData  = {}
    for i=1,7 do
        local temp = {}
        temp.name = string.format("sign%d",i)
        temp.index = i
        temp.icon = string.format("width: 128px;height: 128px;background: url(Texture/Aries/Creator/keepwork/Noticev2/%s.png#0 0 138 138);",icons[i])
        temp.dayicon = string.format("margin-top: -128px; margin-left: -10px;width: 75px;height: 35px; background: url(Texture/Aries/Creator/keepwork/Noticev2/%s.png#0 0 75 35);",dayicons[i])
        if i == 7 then
            temp.icon = string.format("width: 194px;height: 128px;background: url(Texture/Aries/Creator/keepwork/Noticev2/%s.png#0 0 194 138);",icons[i])
            temp.dayicon = string.format("margin-top: -128px; margin-left: -10px;width: 106px;height: 35px; background: url(Texture/Aries/Creator/keepwork/Noticev2/%s.png#0 0 106 35);",dayicons[i])
        end
        Notice.signData[#Notice.signData + 1] = temp
    end
end

function Notice.GetTimeStamp(strTime)
    strTime = strTime or "";
    local year, month, day, hour, min, sec = strTime:match("^(%d+)%D(%d+)%D(%d+)%D(%d+)%D(%d+)%D(%d+)"); 
    local time_stamp = os.time({day=tonumber(day), month=tonumber(month), year=tonumber(year), hour=tonumber(hour) + 8}); -- 这个时间是带时区的 要加8小时
    time_stamp = time_stamp + min * 60 + sec;
    return time_stamp;
end

function Notice.GetServerTime(callback)
    keepwork.user.server_time({}, function(err, msg, data)
        if err ~= 200 then
            print("获取服务器时间失败！")
            return 
        end
        -- print("notice================================",err)
        -- commonlib.echo(data,true)
        local server_time = Notice.GetTimeStamp(data.now)
        local year = os.date("%Y", server_time)	
        local month = os.date("%m", server_time)
        local day = os.date("%d", server_time)
        local day_time_stamp = os.time({year = year, month = month, day = day, hour=0, minute=0, second=0})  
        Notice.servertime = day_time_stamp  
        Notice.InitSignConfig()
        Notice.InitSignData()    
        if callback then
            callback()
        end        
    end)
end

function Notice.CheckCanSign(index)
    local curTime = Notice.servertime
    local signTime = Notice.signTime
    if index == Notice.signNum + 1 then
        local isCanSign = ((curTime - signTime ) >= minSignTimeDis and (curTime - signTime ) < maxSignTimeDis) or  signTime == 0
        if isCanSign then
            return true
        end        
        return false
    else
        return false
    end  
end

function Notice.IsHaveSign(index)
    if index <= Notice.signNum then
        return true
    end
    return false
end

function Notice.InitSignData()
    local clientData = KeepWorkItemManager.GetClientData(Notice.gsid) or {}
    Notice.signTime = clientData.signTime or 0
    Notice.signNum = clientData.signNum or 0
    print("初始化数据")
    commonlib.echo(clientData,true)    
    local timeDis = Notice.servertime - Notice.signTime
    local isSignDisc = (timeDis >= maxSignTimeDis and Notice.signNum > 0) --七日签到连续签到断开
    local isNewState = (timeDis >= minSignTimeDis and timeDis < maxSignTimeDis and Notice.signNum >= 7) --七日签到的新一轮
    if isSignDisc or isNewState then 
        Notice.signNum = 0
        Notice.signTime = 0        
        clientData.signNum = Notice.signNum
        clientData.signTime = Notice.signTime
        print("连续签到断开或者开始下一轮签到")
        KeepWorkItemManager.SetClientData(Notice.gsid, clientData, function()
            print("连续签到断开")
        end); 
    end    
    print("sign data is isSignDisc,isNewState,Notice.servertime,Notice.signTime,Notice.signNum,timeDis",isSignDisc,isNewState,Notice.servertime,Notice.signTime,Notice.signNum,timeDis)    
end

function Notice.ClickSign(id)
    local index = tonumber(string.sub(id,5,-1))
    if Notice.CheckCanSign(index) then 
        local exid = exids[id]
        --print("duihuan===============",exid)
        KeepWorkItemManager.DoExtendedCost(exid, function()        
            Notice.signTime = Notice.servertime
            Notice.signNum = Notice.signNum + 1
            local clientData = KeepWorkItemManager.GetClientData(Notice.gsid) or {}
            clientData.signNum = Notice.signNum
            clientData.signTime = Notice.signTime
            KeepWorkItemManager.SetClientData(Notice.gsid, clientData, function()
                _guihelper.MessageBox("签到成功~")
                Notice.RefreshPage()
            end);
        end,function() 
            GameLogic.AddBBS(nil, L"签到失败!", 3000, "0 255 0");
        end);         
    else
        print("不可签到")
    end
end

function Notice.Show(nType)
    keepwork.notic.announcements({
    },function(info_err, info_msg, info_data)
        if info_err == 200 then
            --commonlib.echo(info_data,true)            
            Notice.GetPageData(info_data); 
            if Notice.nDataNum > 0 then
                Notice.GetServerTime(function()
                    local viewwidth = 1080
                    local viewheight = 720
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
                end)                
            else
                if nType == 1 then --点击活动按钮进入的
                    _guihelper.MessageBox("目前暂无公告及活动哦");
                    -- GameLogic.AddBBS(nil,"目前暂无公告及活动哦",3000,"255,0,0")
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