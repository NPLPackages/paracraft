--[[
Title: 
Author(s): pbb
Date: 2021/9/17
Desc: 
use the lib:
------------------------------------------------------------
local RedSummerCampCourseScheduling = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCourseScheduling.lua") 
RedSummerCampCourseScheduling.ShowView()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestAction.lua");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
local strPath = ';NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCourseScheduling.lua")'
local RedSummerCampCourseScheduling = NPL.export()
local beginYear,endYear
local Ydata
local page,page_root
local curYear,curMonth
local curSelectLesson = ""
local gsid = 40007
local save_key = "cource_scheduling"
RedSummerCampCourseScheduling.curLearnHistroy = {}
RedSummerCampCourseScheduling.lessonCnf = {
    {
        key="ppt_L1",
        name="机构课L1",
        icon= "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/i1_94X94_32bits.png#0 0 94 94",
        num = "24节",
    },
    {
        key ="ppt_S1",
        name="社团课S1",
        icon= "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/i5_94X94_32bits.png#0 0 94 94",
        num = "16节",
    },
    {
        key ="ppt_X1",
        name="校园课X1",
        icon= "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/i3_94X94_32bits.png#0 0 94 94",
        num = "16节",
    },
	{
         key ="ppt_Z1",
         name="试听课Z1",
         icon= "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/i4_94X94_32bits.png#0 0 94 94",
		 num = "3节",
    }
}
-- true to enable lessons for the current users
local auths = {ppt_L1 = false, ppt_S1 = false, ppt_X1 = false, ppt_Z1 = true}

local lessonKeys = {"LP_CommunityCourses","LP_SchoolCourses","LP_OrgCourses"}
function RedSummerCampCourseScheduling.OnInit()
    page = document:GetPageCtrl();
    if page then
        page_root = page:GetParentUIObject()
    end
end

function RedSummerCampCourseScheduling.AuthLesson(callback)
    local times = 0
    for i,v in ipairs(lessonKeys) do
        keepwork.permissions.check({
            featureName = v
        },function(err, msg, data)
            if err == 200 then
                local curKey = lessonKeys[i]
                if curKey == "LP_CommunityCourses" then
                    auths.ppt_S1 = data.data or false
                end
                if curKey == "LP_SchoolCourses" then
                    auths.ppt_X1 = data.data or false
                end
                if curKey == "LP_OrgCourses" then
                    auths.ppt_L1 = data.data or false
                end

                times = times + 1

                if times == #lessonKeys then
                    if callback then
                        callback()
                    end
                end
            end
        end) 
    end
end

function RedSummerCampCourseScheduling.ShowView()
    RedSummerCampCourseScheduling.InitPageData()
    RedSummerCampCourseScheduling.ShowPage()
    RedSummerCampCourseScheduling.AuthLesson(function()
        RedSummerCampCourseScheduling.InitPageData()
        RedSummerCampCourseScheduling.RefreshPage()
    end)
end

function RedSummerCampCourseScheduling.ShowPage()
    local view_width = 740
    local view_height = 560
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCourseScheduling.html",
        name = "RedSummerCampCourseScheduling.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = false,
        zorder = 0,
        -- app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key,
        directPosition = true,
        align = "_fi",
            x = 0,
            y = 0,
            width = 0,
            height = 0,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    RedSummerCampCourseScheduling.InitCalendar()
end

function RedSummerCampCourseScheduling.RefreshPage()
    if page then
        page:Refresh(0)
        RedSummerCampCourseScheduling.InitCalendar()
    end
end

function RedSummerCampCourseScheduling.InitPageData()
    beginYear = 2000
    endYear = tonumber(os.date("%Y", os.time()) ) or 2022
    Ydata = {}
    curYear = tonumber(os.date("%Y",os.time()))
    curMonth = tonumber(os.date("%m", os.time()))
    local userId = GameLogic.GetFilters():apply_filters('store_get', 'user/userId');
    save_key = userId.."cource_scheduling"
    RedSummerCampCourseScheduling.GetLessonHistroy()
end

function RedSummerCampCourseScheduling.GetDateStr()
    return string.format("%d年%02d月",curYear or 2021,curMonth or 9)
end

function RedSummerCampCourseScheduling.OnClickNextMonth()
    if curYear >= endYear and curMonth == 12 then
        return
    end
    curMonth = curMonth + 1
    if curMonth > 12 then
        curMonth = 1
        curYear =  curYear + 1
    end
    RedSummerCampCourseScheduling.RefreshPage()
end

function RedSummerCampCourseScheduling.OnClickPreMonth()
    if curYear <= beginYear and curMonth == 1 then
        return
    end
    curMonth = curMonth - 1
    if curMonth < 1 then
        curMonth = 12
        curYear =  curYear - 1
    end
    RedSummerCampCourseScheduling.RefreshPage()
end

local startX = 34
local startY = 74
local dis_X = 83
function RedSummerCampCourseScheduling.InitCalendar()
    local parentNode = ParaUI.GetUIObject("left_container")
    if parentNode and parentNode:IsValid() then
        --print(parentNode.x,parentNode.y)
        local weekStr = {"日","一","二","三","四","五","六"}
        for i=1,7 do
            local x = startX + (i-1) * dis_X
            local y = startY 
            local textWeek = ParaUI.CreateUIObject("button", "textWeek", "_lt", x, y, 60, 60);
            textWeek.enabled = false;
            textWeek.text = ""..weekStr[i];
            textWeek.background = "";
            textWeek.font = "System;26;norm";
            _guihelper.SetButtonFontColor(textWeek, "#000000", "#0000000");
            parentNode:AddChild(textWeek);
        end

        local zsData = RedSummerCampCourseScheduling.getCurDatedata(curYear,curMonth)
        for i,data in pairs(zsData) do
            local index = i%7
            index = index == 0 and 7 or index
            local indey = math.modf(i/7) 
            indey = index == 7 and  indey - 1 or indey
            local x = startX + 6 + (index-1) * dis_X
            local y = startY + 46 + indey * 60
            local textCalendar = ParaUI.CreateUIObject("button", "textCalendar", "_lt", x, y, 50, 50);
            textCalendar.enabled = RedSummerCampCourseScheduling.GetDayBack(data) ~= "";
            textCalendar.text = ""..data.d;
            textCalendar.background = RedSummerCampCourseScheduling.GetDayBack(data);
            textCalendar.font = "System;26;norm";
            local colorStr = data.isQs and "#d2d0d0" or "#212122"
            _guihelper.SetButtonFontColor(textCalendar, colorStr, colorStr);
            parentNode:AddChild(textCalendar);
            local tooltip = RedSummerCampCourseScheduling.GetToolTip(i)
            if(tooltip and tooltip ~= "")then
                CommonCtrl.TooltipHelper.BindObjTooltip(textCalendar.id, tooltip, 1, 1,400,215,10, true, true, true, true, true, false, nil, nil, nil, true, nil);
            end
        end
    end
end

function RedSummerCampCourseScheduling.GetDayBack(data)
    if data then
        if RedSummerCampCourseScheduling.IsCurDay(data) then
            return "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/4_32bits.png;0 0 32 32:14 14 14 14"
        end

        if RedSummerCampCourseScheduling.GetDayHistroy(data) ~= nil then
            return "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/3_32bits.png;0 0 32 32:14 14 14 14"
        end
    end
    return ""
end

function RedSummerCampCourseScheduling.IsCurDay(data)
    if data then
        if curYear == tonumber(os.date("%Y",os.time())) 
            and curMonth == tonumber(os.date("%m", os.time())) 
            and not data.isQs
            and data.d == tonumber(os.date("%d", os.time())) then
            return true
        end
    end
    return false
end

function RedSummerCampCourseScheduling.GetDayHistroy(data)
    if data and not data.isQs then
        local time_stamp = os.time({year = curYear, month = curMonth, day = data.d, hour=0, min=0, sec=0})
        -- print(string.format("%d年%d月%02d日",curYear,curMonth,data.d),time_stamp,type(time_stamp))
        local clientData = KeepWorkItemManager.GetClientData(gsid) or {};
        -- echo(clientData)
        if clientData[tostring(time_stamp)] ~= nil then
            return clientData[tostring(time_stamp)]
        end
    end
end

function RedSummerCampCourseScheduling.SetDayHistroy(lessonKey,learnContent, pptIndex)
    local server_time = QuestAction.GetServerTime()
    local year = tonumber(os.date("%Y", server_time))	
	local month = tonumber(os.date("%m", server_time))
	local day = tonumber(os.date("%d", server_time))
    local dateStamp = os.time({year = year, month = month, day = day, hour=0, min=0, sec=0})
    local lessonKey = lessonKey or curSelectLesson

    local clientData = KeepWorkItemManager.GetClientData(gsid) or {};
    clientData[tostring(dateStamp)] = {key = lessonKey ,content = learnContent or "", pptIndex = pptIndex or 1}
    -- print("setData=============")
    -- echo(clientData)
    KeepWorkItemManager.SetClientData(gsid, clientData, function()
        print("save success")
    end,function (err, msg, data)
        echo(err)
        echo(msg)
        echo(data)
    end);
end

local tempDt = {
    [1632240000] = {
        key="ppt_S1",
        content = "社团课S1系列第1节 \r\n 知识点：人物向前移动 \r\n MoveForward()命令"
    }
}

function RedSummerCampCourseScheduling.GetHistroyByIndex(index)
    local curIndex = index or 1
    local zsData = RedSummerCampCourseScheduling.getCurDatedata(curYear,curMonth)
    local dataHistroy = RedSummerCampCourseScheduling.GetDayHistroy(zsData[curIndex])
    if dataHistroy then
        return dataHistroy
    end
    
end

function RedSummerCampCourseScheduling.GetToolTip(index)
    local dataHistroy = RedSummerCampCourseScheduling.GetHistroyByIndex(index)
    if dataHistroy then
        return "script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCourseSchedulingTip.html?index="..index;
    end
    return ""
end

    -- 绘制月份的详细信息 
function RedSummerCampCourseScheduling.getCurDatedata(year,month)
    -- 日历单页显示42个日期数据 
    -- 初始42个日期数据进行标记 z=周几  d=日期初始为0
    RedSummerCampCourseScheduling.InitData()
    local zsData = {}
    local _s = {0,1,2,3,4,5,6}
    for i=1,42 do
        local index = i%7
        zsData[i] = {z = _s[index == 0 and 7 or index],d = 0}
    end
    -- echo(zsData)
    --[[
        记录第一次插入数据的位置-1  ,记录最后插入位置+1
        可以通过该参数，进行填补日期
    ]]
    local jlFristIndex,jlFinalIndex = -1,-1
    -- echo(Ydata,true)
    -- 把该年月的日期相应的插入到对应的位置中
    for i,ds in pairs( Ydata[year].ms[month] ) do
            -- 该参数为了避免 zsData的日期数据重复的插入
            -- 从2开始为了保证可以存在上个月分的日期显示
            local statIndex = 2 
            -- 根据周的数据依次记录日期数据 
            for j,d in pairs(ds) do
                for k=statIndex,#zsData do
                    local t2 =  k%7
                    if tonumber(zsData[k].z) == tonumber(d.z) then
                        if jlFristIndex == -1 then
                            jlFristIndex = k - 1
                        end
                        -- 修改日期
                        zsData[k].d = d.d
                        statIndex = statIndex + 1
                        jlFinalIndex = k  + 1
                        break
                    end
                end
            end
    end


    -- jlFristIndex,jlFinalIndex 填补缺省日期  对一月份特殊处理
    if month == 1 then
        if jlFinalIndex ~= -1 then
            local d = 1
            for j=jlFinalIndex,#zsData do
                zsData[j].d = d
                zsData[j].isQs = true
                d = d + 1
            end
        end


        if jlFristIndex ~= -1 then
            local index = 31
            for i=jlFristIndex,1,-1 do
                zsData[i].d = index
                zsData[i].isQs = true
                index = index - 1
            end
        end


    else
        if jlFinalIndex ~= -1 then
            local d = 1
            for j=jlFinalIndex,#zsData do
                zsData[j].d = d
                zsData[j].isQs = true
                d = d + 1
            end
        end


        if jlFristIndex ~= -1 then
            local ds = Ydata[year].ms[month-1].ds
            local index = #ds
            for i=jlFristIndex,1,-1 do
                zsData[i].d = ds[index].d
                zsData[i].isQs = true
                index = index - 1
            end
        end
    end


    -- zsData 就是 按照 0日、1、2、3、4、5、6对应排列的日期数据 可以进行绘制
    return zsData
end

function RedSummerCampCourseScheduling.InitData()
    -- 获取需要的年份的数据
    -- 获取年 月 日 周
    Ydata = {}
    for i = beginYear,endYear do
        local vo = {}
        vo.y = i
        vo.ms = {}
        for j=2,13 do
            -- 获取该月份的天数  month参数是要填写下月个月份的 天数是0的话就是求得上个月的最后一天，所以month应该+1
            local tianshu = os.date("%d", os.time({year=i,month=j,day=0}) )
            vo.ms[j-1] = {}
            vo.ms[j-1].ds = {}
            -- 插入天数数据
            for k=1,tianshu do
                vo.ms[j-1].ds[k] = {}
                -- 日期
                vo.ms[j-1].ds[k].d =  k
                -- 得到该日期是周几
                local t = os.time({year=i,month=j-1,day=k})
                vo.ms[j-1].ds[k].z = os.date("*t",t).wday -1
            end
        end
        Ydata[i] = vo
    end
end


function RedSummerCampCourseScheduling.IsHaveHistroy()
    return #RedSummerCampCourseScheduling.curLearnHistroy > 0
end

function RedSummerCampCourseScheduling.GetLessonHistroy()
    local keys = GameLogic.GetPlayerController():LoadRemoteData(save_key,{});
    RedSummerCampCourseScheduling.curLearnHistroy = {}
    for i=1,#keys do
        local key = keys[i]
        local temp = RedSummerCampCourseScheduling.GetLessonByKey(key)
        local canlearn = RedSummerCampCourseScheduling.CheckCanLearn(key)
        if temp and canlearn then
            table.insert(RedSummerCampCourseScheduling.curLearnHistroy, temp)
        end
    end
    return RedSummerCampCourseScheduling.curLearnHistroy
end

function RedSummerCampCourseScheduling.GetLessonByKey(key)
    for i=1,#RedSummerCampCourseScheduling.lessonCnf do
        if RedSummerCampCourseScheduling.lessonCnf[i].key == key  then
            return RedSummerCampCourseScheduling.lessonCnf[i]
        end
    end
end

function RedSummerCampCourseScheduling.SaveLessonHistroy()
    local keys = GameLogic.GetPlayerController():LoadRemoteData(save_key,{});
    if keys then
        local num = #keys
        if num == 0 then
            keys[1] = curSelectLesson
        else
            if keys[1] ~= curSelectLesson then
                local temp = keys[1]
                keys[1] = curSelectLesson
                keys[2] = temp
            end
        end
    end
    -- echo(keys)
    GameLogic.GetPlayerController():SaveRemoteData(save_key,keys,true);
end

function RedSummerCampCourseScheduling.CheckCanLearn(name)
    local isCanlearn = auths[name]
    if name == "ppt_X1"  then
        return isCanlearn or System.User.isVipSchool
    end
    return isCanlearn
end

function RedSummerCampCourseScheduling.OnClickLesson(name)
    if not RedSummerCampCourseScheduling.CheckCanLearn(name) then
        -- GameLogic.AddBBS(nil,"该课程为会员和机构会员学习课程")
        local strTip = "你暂时没有该课程访问权限，请联系客服"
        _guihelper.MessageBox(strTip)
        return
    end
    curSelectLesson = name
    RedSummerCampCourseScheduling.SaveLessonHistroy()
    RedSummerCampCourseScheduling.GetLessonHistroy()
    -- RedSummerCampCourseScheduling.SetDayHistroy("ppt_S1","社团课S1系列第1节 \r\n 知识点：人物向前移动 \r\n MoveForward()命令")
    RedSummerCampCourseScheduling.RefreshPage()

    local RedSummerCampPPtPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtPage.lua");
    RedSummerCampPPtPage.Show(curSelectLesson);
    -- print("RedSummerCampCourseScheduling name============",name)
end

function RedSummerCampCourseScheduling.ClosePage()
    if page then
        page:CloseWindow();
        page = nil
    end
end