--[[
Title: Notice
Author(s): yangguiyi & pengbb
Date: 2020/11/23
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Notice/Notice.lua").Show();
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local NoticeTimeId = 2001
local Notice = NPL.export();
Notice.isSelectShowToday = true;
Notice.nSelectIndex = 1;
Notice.tblNoticeDt = {};
Notice.isFirstIn = true
Notice.nDataNum = 0
Notice.isCanClickNext = true



function Notice.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = Notice.CloseView 
         
end

--处理获得的数据
function Notice.GetPageData(data)
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

    Notice.tblNoticeDt = {};
    for k , v in pairs(data) do
        local temp = {};
        temp.id = v.id;
        temp.cover = v.cover;
        temp.url = v.url or "";
        temp.name = v.name
        temp.index = k
        table.insert(Notice.tblNoticeDt,temp);
    end
    Notice.nDataNum = #Notice.tblNoticeDt
    commonlib.echo(Notice.tblNoticeDt,true)
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
            Notice.GetPageData(info_data); 
            if Notice.nDataNum > 0 then
                local viewwidth = 1024
                local viewheight = 512
                local params = {
                    url = "script/apps/Aries/Creator/Game/Tasks/Notice/Notice.html",
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
                NPL.SetTimer(NoticeTimeId, 5.0, ";RegisterTime();"); --注册定时器
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

function RegisterTime()
    local clickindex = Notice.nSelectIndex  
    clickindex = Notice.isFirstIn and clickindex or clickindex + 1; --首次进来会调用定时器，导致直接刷新到了下一个活动页面，加一个首次判断
    if clickindex > Notice.nDataNum then
        clickindex= 1;
    end
    Notice.OnClick(string.format("button_%d",clickindex));
    Notice.isFirstIn = false
end

function Notice.CloseView()
    -- body
    Notice.nSelectIndex = 1;
    Notice.tblNoticeDt = {};
    Notice.isFirstIn = true
    Notice.isCanClickNext = true
    NPL.KillTimer(NoticeTimeId);
    Notice.SaveLocalData()
end


function Notice.OnClick(id)
    local index = tonumber(string.sub(id,8,-1));
    Notice.nSelectIndex = index;
    Notice.RefreshPage();    
end

function Notice.RefreshPage()
    if not page then
        return
    end
    page:Refresh(0)
end

function Notice.RenderButton(index)
    local strSelBg = "Texture/Aries/Creator/keepwork/Notice/dian2_10X10_32bits.png#2 2 10 10";
    local strNorBg = "Texture/Aries/Creator/keepwork/Notice/dian2_8X8_32bits.png#0 0 8 8";
    local nodeBg = index == Notice.nSelectIndex and strSelBg or strNorBg;
    local strName = string.format("button_%d",index);
    local s = string.format([[<input type="button" name='%s' onclick="OnClick" style="width:8px;height:8px;background:url(%s)"/>]],strName,nodeBg);
    if index == Notice.nSelectIndex then
        s = string.format([[<input type="button" name='%s' onclick="OnClick" style="width:10px;height:10px;background:url(%s)"/>]],strName,nodeBg);
    end
    return s
end

--预留修改的地方，用来根据数据动态修改gridvirew元素的位置和空格
function Notice.RenderGridView() 

end

function Notice.getCover(index)
    return Notice.tblNoticeDt[index].cover
end

--点击公告图片，此处需要添加埋点事件
function Notice.OnImageBgClick()
    local name = Notice.tblNoticeDt[Notice.nSelectIndex].name
    if name == "双旦活动" or name == "帮爷爷找帽子" then
        local ActRedhatExchange = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ActRedhat/ActRedhatExchange.lua")
        ActRedhatExchange.ShowView()
		GameLogic.GetFilters():apply_filters("user_behavior", 1 ,"click.promotion.announcement");
        return 
    end

    if string.find(name, "创造周末") and string.find(name, "创造周末") > 0 then
        local ActWeek = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ActWeek/ActWeek.lua")
        ActWeek.ShowView()
        return
    end

    local url = Notice.tblNoticeDt[Notice.nSelectIndex].url;
    if(url and #url ~= 0) then
        ParaGlobal.ShellExecute("open", "iexplore.exe", url, "", 1);
        GameLogic.GetFilters():apply_filters("user_behavior", 1 ,"click.promotion.announcement");
    else
        return 
    end
    keepwork.notic.announcements({
        router_params = {
            id = Notice.tblNoticeDt[Notice.nSelectIndex].id,
        }
    },function(err, msg, data)
        if err ~= 200 then
            print("请求失败~~~~~~~~~~~")
        end
    end)
end

--点击下一页或者上一页
function Notice.OnClickNextPage(page)
    if Notice.isCanClickNext then
        local curPage = Notice.nSelectIndex;
        curPage = curPage + page
        if curPage > Notice.nDataNum then
            curPage = 1
        end
        if curPage < 1 then
            curPage = Notice.nDataNum
        end
        Notice.OnClick(string.format("button_%d",curPage))
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