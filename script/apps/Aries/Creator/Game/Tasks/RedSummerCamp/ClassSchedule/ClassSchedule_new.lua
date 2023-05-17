--[[
Title: 
Author(s): hyz
Date: 2022/8/4
Desc: 课表新UI
use the lib:
------------------------------------------------------------
local ClassSchedule_new = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/ClassSchedule/ClassSchedule_new.lua") 
ClassSchedule_new.ShowPage()
-------------------------------------------------------
]]
local RedSummerCampCourseScheduling = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCourseSchedulingV2.lua") 
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local ClassSimpleTip = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/ClassSchedule/ClassSimpleTip.lua") 
local RedSummerCampPPtPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtPage.lua");
local ClassSchedule_old = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/ClassSchedule/ClassSchedule.lua") 
local KeepworkService = NPL.load('(gl)Mod/WorldShare/service/KeepworkService.lua')

local ClassSchedule_new = NPL.export()


-- ClassSchedule_new.ds_years = {}
-- ClassSchedule_new.ds_months = {}
-- ClassSchedule_new.ds_classes = {}

local page
function ClassSchedule_new.OnInit()
    page = document:GetPageCtrl()
    page.OnClose = ClassSchedule_new.OnClosed;
    page.OnCreate = ClassSchedule_new.OnCreated;
end

function ClassSchedule_new.OnCreated()

end

function ClassSchedule_new.OnClosed()
    page = nil 
end

function ClassSchedule_new.ClosePage()
    if page then
        page:CloseWindow()
        page = nil 
    end
end

function ClassSchedule_new.ShowPage()
    RedSummerCampCourseScheduling.HideTip()

    ClassSchedule_new.isExpland_year = false --是否展开
    ClassSchedule_new.isExpland_month = false
    ClassSchedule_new.isExpland_class = false

    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/ClassSchedule/ClassSchedule_new.html",
        name = "ClassSchedule_new.ShowView", 
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
        x = 0,
        y = 0,
        width = 0,
        height = 0,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);

    RedSummerCampCourseScheduling.LoadClassList(function()
        local ds = RedSummerCampCourseScheduling.DS_classes()
        if KeepWorkItemManager.IsTeacher() then
            ClassSchedule_new.ds_classes = {}
            table.insert(ClassSchedule_new.ds_classes,{
                classId = 0,
                name = L"全部班级",
            })
            for i=1,#ds do
                table.insert(ClassSchedule_new.ds_classes,ds[i])
            end
        else
            ClassSchedule_new.ds_classes = ds
        end
        
        if ClassSchedule_new.curIdx_class==nil then
            ClassSchedule_new.curIdx_class = 1;
        end
        ClassSchedule_new.OnSelectListItem_class(ClassSchedule_new.curIdx_class)
    end)
end

ClassSchedule_new.isExpland_year = false
ClassSchedule_new.isExpland_month = false
ClassSchedule_new.isExpland_class = false
function ClassSchedule_new.OnClickExpand(_type,bool)
    if bool==false then
        ClassSchedule_new.isExpland_year = false
        ClassSchedule_new.isExpland_month = false
        ClassSchedule_new.isExpland_class = false
        if page then
            page:Refresh(0)
        end
        return
    end
    if _type=="year" then
        ClassSchedule_new.isExpland_year = not ClassSchedule_new.isExpland_year
        ClassSchedule_new.isExpland_month = false
        ClassSchedule_new.isExpland_class = false
    elseif _type=="month" then
        ClassSchedule_new.isExpland_month = not ClassSchedule_new.isExpland_month
        ClassSchedule_new.isExpland_year = false
        ClassSchedule_new.isExpland_class = false
    elseif _type=="class" then
        ClassSchedule_new.isExpland_class = not ClassSchedule_new.isExpland_class
        ClassSchedule_new.isExpland_year = false
        ClassSchedule_new.isExpland_month = false
    end
    
    if page then
        page:Refresh(0)
    end
end

function ClassSchedule_new.getListItemName(_type,idx)
    local ds = ClassSchedule_new.getListData(_type)
    idx = tonumber(idx) or 1
    if _type=="year" then
        if ds[idx] and ds[idx].year then
            return ds[idx].year..""
        end
    elseif _type=="month" then
        if ds[idx] and ds[idx].month then
            return ds[idx].month..""
        end
    elseif _type=="class" then
        local info = ClassSchedule_new.ds_classes[idx]
        local str = info.name or ""
        if info.status==3 then
            str = str.."(已结业)"
        end
        return str
    end
    return ""
end


function ClassSchedule_new.getListData(_type)
    local ret
    if _type=="year" then
        if ClassSchedule_new.ds_years==nil then
            local curYear = tonumber(os.date("%Y"))
            ClassSchedule_new.ds_years = {}
            for i=curYear,2018,-1 do
                table.insert(ClassSchedule_new.ds_years,{
                    year = i
                })
            end
            ClassSchedule_new.curIdx_year = 1;
        end
        ret = ClassSchedule_new.ds_years
    elseif _type=="month" then
        if ClassSchedule_new.ds_months==nil then
            local curMonth = tonumber(os.date("%m"))
            ClassSchedule_new.ds_months = {}
            for i=1,12 do
                if i==curMonth then
                    ClassSchedule_new.curIdx_month = i;
                end
                table.insert(ClassSchedule_new.ds_months,{
                    month = i
                })
            end
        end
        ret = ClassSchedule_new.ds_months
    elseif _type=="class" then
        if ClassSchedule_new.ds_classes==nil then
            local ds = RedSummerCampCourseScheduling.DS_classes()
            if KeepWorkItemManager.IsTeacher() then
                ClassSchedule_new.ds_classes = {}
                table.insert(ClassSchedule_new.ds_classes,{
                    classId = 0,
                    name = L"全部班级",
                })
                for i=1,#ds do
                    table.insert(ClassSchedule_new.ds_classes,ds[i])
                end
            else
                ClassSchedule_new.ds_classes = ds
            end
            
            ClassSchedule_new.curIdx_class = 1;
        end
        -- print("ClassSchedule_new.ds_classes")
        -- echo(ClassSchedule_new.ds_classes,true)
        ret = ClassSchedule_new.ds_classes
    end
    -- echo(ret)
    return ret or {}
end

function ClassSchedule_new.OnSelectListItem_year(name)
    local idx = tonumber(name)
    local _type = "year"
    local ds = ClassSchedule_new.getListData(_type)
    local info = ds[idx]
    ClassSchedule_new.OnClickExpand(_type)

    ClassSchedule_new.curIdx_year = idx
    if page then
        page:Refresh(0)
    end
    ClassSchedule_new.UpdateCourseOfMonth()
end

function ClassSchedule_new.OnSelectListItem_month(name)
    local idx = tonumber(name)
    local _type = "month"
    local ds = ClassSchedule_new.getListData(_type)
    local info = ds[idx]
    ClassSchedule_new.OnClickExpand(_type)

    ClassSchedule_new.curIdx_month = idx
    if page then
        page:Refresh(0)
    end
    ClassSchedule_new.UpdateCourseOfMonth()
end

function ClassSchedule_new.OnSelectListItem_class(name)
    local idx = tonumber(name)
    local _type = "class"
    local ds = ClassSchedule_new.getListData(_type)
    if #ds==0 then
        return
    end
    local info = ds[idx]
    ClassSchedule_new.OnClickExpand(_type,false)

    ClassSchedule_new.curIdx_class = idx
    if page then
        page:Refresh(0)
    end
    ClassSchedule_new.UpdateCourseOfMonth()
    if info and info.classId~=0 then
        ClassSchedule_old.SetClassInfo(info)
    end
end

function ClassSchedule_new.getDropListXml(_type,listWidth,maxItemNum)
    listWidth = listWidth or 116
    maxItemNum = maxItemNum or 5
    local ds = ClassSchedule_new.getListData(_type)
    local num = #ds
    local height = 26*math.min(num,maxItemNum)
    local gridStyle = string.format("margin:0px;width:${listWidth}px;height:%spx;",height)
    local listBgStyle = string.format("position: relative;margin-top: 32px;padding-top: 10px; margin-left: 0px; width: ${listWidth}px; height: %spx; background: url(Texture/Aries/Creator/keepwork/RedSummerCamp/classes/xialakuang_30x24_32bits.png#0 0 30 24:10 10 10 10);",height+20)
    local str = [[
        <div style="float:left;width: ${listWidth}px; height:44px;margin-top:0px;margin-left: 11px;" >
            <input zorder="3" type="button" value='<%= _guihelper.TrimUtf8TextByWidth("${curSelectText}", 110) %>' uiname="btn_drop_${_type}" onclick='onClick_${_type}' style="position: relative; text-offset-y:-2;text-offset-x:15;text-align:left; width: ${listWidth}px; height: 36px; font-size:16px; base-font-size:16px; font-weight:bold; background: url(Texture/Aries/Creator/keepwork/RedSummerCamp/courses/riqi_116x36_32bits.png#0 0 116 36);" />
            <pe:if condition='<%= ClassSchedule_new.isExpland_${_type} %>'>
                <div zorder="4" uiname="icon_unexpand" align="right" style="position: relative;float: left;margin-top: 14px; margin-right: 8px;width: 12px;height: 8px; background: url(Texture/Aries/Creator/keepwork/RedSummerCamp/courses/jiantou_shang_12x8_32bits.png#0 0 12 8);"></div>
            </pe:if>
            <pe:if condition='<%= not ClassSchedule_new.isExpland_${_type} %>'>
                <div zorder="4" uiname="icon_expand" align="right" style="position: relative;float: left;margin-top: 14px; margin-right: 8px;width: 12px;height: 8px; background: url(Texture/Aries/Creator/keepwork/RedSummerCamp/courses/jiantou_12x8_32bits.png#0 0 12 8);"></div>
            </pe:if>
            <pe:if condition='<%=ClassSchedule_new.isExpland_${_type}%>'>
            <pe:container zorder="2" uiname="list_bg_${_type}" style='${listBgStyle}'>
                <pe:gridview style='${gridStyle}' name="item_gridview" CellPadding="0" VerticalScrollBarStep="36" VerticalScrollBarOffsetX="8" AllowPaging="false" ItemsPerLine="1" DefaultNodeHeight = "26" 
                        DataSource='<%= ClassSchedule_new.getListData("${_type}") %>'>
                        <Columns>
                            <input 
                                type="button" 
                                class="listbutton_unselected" 
                                value='<%= ClassSchedule_new.getListItemName("${_type}",Eval("index")) %>' 
                                name='<%=Eval("index")%>'
                                onclick='ClassSchedule_new.OnSelectListItem_${_type}()'
                                style="text-offset-x:12;width:${listWidth}px;height:26px;text-align:left;color:#cccccc;font-size:14" 
                                MouseOver_BG="Texture/alphadot.png"
                            />
                        </Columns>
                        <EmptyDataTemplate>
                        </EmptyDataTemplate>
                    </pe:gridview>
            </pe:container>
                
                <pe:container zorder="1" onclick='onClick_${_type}' style="position:absolute;margin-top: -720px; margin-left: -1280px; width: 2560px;height: 1440px; background:url()"></pe:container>
            </pe:if>
        </div>
    ]]

    local titleStr = ""
    if _type=="year" then
        titleStr = ClassSchedule_new.getListItemName(_type,ClassSchedule_new.curIdx_year)..L"年"
    elseif _type=="month" then
        titleStr = ClassSchedule_new.getListItemName(_type,ClassSchedule_new.curIdx_month)..L"月"
    elseif _type=="class" then
        titleStr = ClassSchedule_new.getListItemName(_type,ClassSchedule_new.curIdx_class)
    end
    str = str:gsub("${curSelectText}",titleStr)
    str = str:gsub("${_type}",_type)
    str = str:gsub("${gridStyle}",gridStyle)
    str = str:gsub("${listBgStyle}",listBgStyle)
    str = str:gsub("${listWidth}",listWidth)
    -- echo(str,true)
    return str
end

function ClassSchedule_new.getCurSelectCls()
    local ds = ClassSchedule_new.getListData("class")
    local cls_info = ds[ClassSchedule_new.curIdx_class]
    return cls_info
end

function ClassSchedule_new.OnClick_addClassOrManageCourse()
    local _isTeacher = KeepWorkItemManager.IsTeacher()
    if _isTeacher then
        local url;
        local ds = ClassSchedule_new.getListData("class")
        local cls_info = ClassSchedule_new.getCurSelectCls()
        -- if cls_info==nil then
        --     cls_info = ds[1]
        -- end
        -- if cls_info.classId==0 then
        --     cls_info = ds[2]
        -- end

        if cls_info then
            echo(cls_info,true)
            local url = ClassSchedule_old.GetJumpUrl_adjustSchedule(cls_info.orgId,cls_info.classId)
            GameLogic.RunCommand("/open "..url)
        else
            local url = ClassSchedule_old.GetJumpUrl_adjustSchedule(nil,nil)
            GameLogic.RunCommand("/open "..url)
        end
    else
        local view_width = 0
        local view_height = 0
        local params = {
            url = "script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampAddClassByInviteCode.html",
            name = "ClassSchedule_new.RedSummerCampAddClassByInviteCode", 
            isShowTitleBar = false,
            DestroyOnClose = true,
            style = CommonCtrl.WindowFrame.ContainerStyle,
            allowDrag = false,
            enable_esc_key = false,
            directPosition = true,
            cancelShowAnimation = true,
            DesignResolutionWidth = 1280,
            DesignResolutionHeight = 720,
            align = "_fi",
                x = -view_width/2,
                y = -view_height/2,
                width = view_width,
                height = view_height,
        };
        System.App.Commands.Call("File.MCMLWindowFrame", params);
    end
end

--当前年份当前月份的所有日期数据列表
--返回周数据的数组，数组每项包含一周的数据
function ClassSchedule_new.GetDate_ds()
    local cls_info = ClassSchedule_new.getCurSelectCls()
    local class_id
    if cls_info==nil then
        class_id = 0;--没有课程但是有日期数据，兼容一下
    else
        class_id = cls_info.classId
    end

    ClassSchedule_new.getListData("year")
    ClassSchedule_new.curIdx_year = ClassSchedule_new.curIdx_year or 1
    local year = tonumber(ClassSchedule_new.getListItemName("year",ClassSchedule_new.curIdx_year))
    local month = tonumber(ClassSchedule_new.getListItemName("month",ClassSchedule_new.curIdx_month))

    local month_ds = ClassSchedule_new.GetDaysOfMonth(year,month,class_id)
    
    local daynum = #month_ds
    if month_ds.weeks==nil then
        month_ds.weeks = {}
        local _week = {}
        for i=1,daynum do
            local obj = month_ds[i]
            table.insert(_week,obj)
            if obj.weekDay==7 then
                table.insert(month_ds.weeks,_week)
                _week = {}
            end
        end
    end
    -- print("========month_ds")
    -- echo(month_ds,true)
    
    -- echo(month_ds.weeks,true)
    return month_ds
end

function ClassSchedule_new.GetDaysOfMonth(year,month,class_id)
    if not class_id or not year or not month then
        return {}
    end
    if ClassSchedule_new.course_ds==nil then
        ClassSchedule_new.course_ds = {}
    end
    if ClassSchedule_new.course_ds[class_id]==nil then
        ClassSchedule_new.course_ds[class_id] = {}
    end 
    if ClassSchedule_new.course_ds[class_id][year]==nil then
        ClassSchedule_new.course_ds[class_id][year] = {}
    end
    local month_ds
    if ClassSchedule_new.course_ds[class_id][year][month]==nil then
        ClassSchedule_new.course_ds[class_id][year][month] = {}
        month_ds = ClassSchedule_new.course_ds[class_id][year][month]
        local y,m,d,weekDay;
        for i=0,31 do
            y,m,d = commonlib.timehelp.get_next_date(year,month,1,i)
            if m~=month then
                break
            end
            weekDay = commonlib.timehelp.get_day_of_week(y,m,d)
            -- print("========y,m,d",y,m,d,"weekDay",weekDay)
            month_ds[i+1] = {
                day = d,
                weekDay = weekDay,
                month = month,
                year = year,
            }
        end
        if month_ds[1].weekDay>1 then
            local weekDay = month_ds[1].weekDay
            for i=1,weekDay-1 do
                table.insert(month_ds,1,{
                    weekDay = weekDay-i,
                    empty = true,
                })
            end
        end
        if month_ds[#month_ds].weekDay<7 then
            local weekDay = month_ds[#month_ds].weekDay
            for i = 1,7-weekDay do
                table.insert(month_ds,{
                    weekDay = i+weekDay,
                    empty = true,
                })
            end
        end
        -- echo(month_ds,true)
    else
        month_ds = ClassSchedule_new.course_ds[class_id][year][month]
    end
    return month_ds
end

function ClassSchedule_new.getWeekDay_ds(weekIdx)
    weekIdx = tonumber(weekIdx)
    local weeks = ClassSchedule_new.GetDate_ds().weeks
    local days = weeks[weekIdx]
    return days
end

--一个表格项，即一天的数据
function ClassSchedule_new.GetDayXml(weekIdx,dayIdx,height)
    dayIdx = tonumber(dayIdx)
    local days = ClassSchedule_new.getWeekDay_ds(weekIdx)
    local obj = days[dayIdx]
    local str = [[
        <div width="161" height="${height}" style="float:left;">
            <div style="margin-top: 3px;margin-right: 0px;font-size: 15px;base-font-size: 15px;text-align:center">${date_str}</div>
            ${all_class_course}
        </div>
    ]]
    str = str:gsub("${height}",height)
    local date_str = ""
    if obj.day then
        date_str = string.format("%d-%02d-%02d",obj.year,obj.month,obj.day)
    end
    str = str:gsub("${date_str}",date_str)

    local _isTeacher = KeepWorkItemManager.IsTeacher()

    local all_class_course = ""
    local tooltipStr = ""
    if obj.courses then
        -- echo(obj.courses,true)
        tooltipStr = ""
        for i=1,#obj.courses do
            local cou = obj.courses[i]
            local class_name = ""
            for k,v in pairs(ClassSchedule_new.ds_classes) do
                if v.classId==cou.classId then
                    class_name = v.name;
                    break
                end
            end
            local arr = {cou.course.name}
            for k,v in ipairs(cou.sections) do
                arr[#arr+1] = v.name
            end
            local course_name = table.concat(arr," ")
            local course_name_crop = _guihelper.TrimUtf8TextByWidth(course_name,136,"System;12")
            if course_name_crop~=course_name then
                course_name_crop = course_name_crop.."..."
            end
            local timeStr = cou.startAtStr.."-"..cou.endAtStr
            tooltipStr = class_name.."\n"..course_name.."\n"..timeStr.."\n"
            -- print("class_name",class_name)
            -- print("course_name_crop",course_name_crop)
            -- print("timeStr",timeStr)
            local text_color = "#ff0000"
            local _status = cou.status
            
            if not _isTeacher then --学生
                if cou.studentStatus==1 then --已考勤
                elseif cou.studentStatus==0 then --缺勤
                    _status = 2
                end
            else --老师
            end
            local isTimeNow = false
            local now = os.time()
            if cou.startAt_stamp<now and cou.endAt_stamp>now then
                isTimeNow = true
            end
            if _status==0 then --待上课
                text_color = "#000000"
            elseif _status==1 then --已上课
                text_color = "#3A8806"
            elseif _status==2 then --缺课
                text_color = "#DB2B2B"
            elseif _status==3 then --正在教学
                text_color = "#FF8A00"
            end
            local xml = [[
            <div width="161" name="${corrseId}" onclick="ClassSchedule_new.OnCourseClick" tooltip="${tooltipStr}">
                <div style="margin-top: -2px;color:${text_color};font-weight:bold;margin-left: 5px;font-size: 12px;base-font-size: 12px;">${class_name}</div>
                <div style="margin-left: 5px;color:${text_color};font-size: 12px;base-font-size: 12px;">${course_name_crop}</div>
                <div style="margin-left: 5px;color:${text_color};font-size: 12px;base-font-size: 12px;">${timeStr}</div>
            </div>
            ]]
            xml = xml:gsub("${class_name}",class_name)
            xml = xml:gsub("${course_name_crop}",course_name_crop)
            xml = xml:gsub("${timeStr}",timeStr)
            xml = xml:gsub("${text_color}",text_color)
            xml = xml:gsub("${corrseId}",cou.id)

            tooltipStr = tooltipStr:gsub("\""," ")
            xml = xml:gsub("${tooltipStr}",tooltipStr)

            all_class_course = all_class_course..xml
        end
        tooltipStr = tooltipStr.."\n"
    end

    str = str:gsub("${all_class_course}",all_class_course)
    
    return str
end

function ClassSchedule_new.OnCourseClick(name,xmlNode)
    -- ClassSchedule_old.OnClickCourse(name,xmlNode)
    local scheduleId = tonumber(name)
    if scheduleId==nil then
        return
    end
    local _course = ClassSchedule_old._findCourseByScheduleId(scheduleId)
    if _course then
        -- echo(_course)
        ClassSchedule_new._doJump2PPT(_course)
    end
end

function ClassSchedule_new._doJump2PPT(_course)
    if _course==nil then
        return
    end
    ClassSchedule_old.classInfo = _course.class
    ClassSchedule_old.curClassId = _course.class.classId or _course.class.id
    --进入PPT页面
    if _course.sections and _course.sections[1] then
        RedSummerCampCourseScheduling.ShowPPTPageById(_course.courseId,_course.sections[1].index)
    end
end

--横向的一周的表格
function ClassSchedule_new.GetXmlofWeek(weekIdx)
    weekIdx = tonumber(weekIdx)
    local days = ClassSchedule_new.getWeekDay_ds(weekIdx)
    local height = 133;
    for k,v in pairs(days) do
        if v.courses then
            local len = #v.courses
            height = math.max(height,len*56+16+5)
            -- print("---------len",len,height)
        end
    end
    local str = [[
        <div width="1130" height="${height}" style="background: url(Texture/Aries/Creator/keepwork/RedSummerCamp/courses/kebiao_1130x133_32bits.png#0 0 1130 133:20 20 20 20);">
            <pe:repeat name="weekdayInfo" DataSource="<%= ClassSchedule_new.getWeekDay_ds(${weekIdx}) %>">
                <pe:repeatitem>
                    <%= ClassSchedule_new.GetDayXml(${weekIdx},Eval("index"),${height}) %>
                </pe:repeatitem>
            </pe:repeat>
        </div>
    ]]
    str = str:gsub("${weekIdx}",weekIdx)
    str = str:gsub("${height}",height)
    return str
end

--更新当前月份的课程数据
function ClassSchedule_new.UpdateCourseOfMonth(callback)
    local month_ds = ClassSchedule_new.GetDate_ds()
    local startDate,endDate;
    local hasRequested = false
    for i=1,#month_ds do
        local obj = month_ds[i]
        if obj.courses~=nil then
            hasRequested = true
        end
        if startDate==nil then
            if not month_ds[i].empty then
                startDate = string.format("%d-%02d-%02d",obj.year,obj.month,obj.day)
            end
        elseif endDate==nil then
            if month_ds[i].empty then
                -- echo(month_ds[i-1])
                endDate = string.format("%d-%02d-%02d",month_ds[i-1].year,month_ds[i-1].month,month_ds[i-1].day)
                break
            elseif i==#month_ds then
                endDate = string.format("%d-%02d-%02d",obj.year,obj.month,obj.day)
            end
        end
    end

    -- print("开始",startDate)
    -- print("结束",endDate)

    if hasRequested then
        ClassSchedule_new.RefreshUI()
        return
    end

    local cls_info = ClassSchedule_new.getCurSelectCls()
    local class_id
    if cls_info==nil then
        class_id = 0;--全部班级
    else
        class_id = cls_info.classId
    end

    local weeks_of_month = ClassSchedule_new.GetDate_ds().weeks;

    keepwork.schedule.searchSchedule({
        roleId = KeepWorkItemManager.IsTeacher() and 2 or nil,
        classId = class_id,
        startAt = startDate,
        endAt = endDate,
        -- headers = {
            ["x-per-page"] = 200,
            ["x-page"] = 1,
        -- },
    },function(err,msg,data)
        -- print("-------searchSchedule返回",err)
        -- echo(data,true)
        if err~=200 then
            return
        end
        --TODO
        local data = data.data;
        local count = data and data.count
        if count==nil then
            if callback then
                callback(nil)
            end
            return
        end
        local y,m,d;
            local rows = data.rows;
            local obj = nil --一天的数据
            for k,v in ipairs(rows) do
                v.startAt_stamp = commonlib.timehelp.GetTimeStampByDateTime(v.startAt)
                v.endAt_stamp = commonlib.timehelp.GetTimeStampByDateTime(v.endAt)
    
                v.date = os.date("%Y-%m-%d",v.startAt_stamp)
                v.weekday = commonlib.timehelp.GetWeekDay(v.startAt_stamp)
                v.startAtStr = os.date("%H:%M",v.startAt_stamp)
                v.endAtStr = os.date("%H:%M",v.endAt_stamp)
                if v.status==1 then --已经上课了
                    local uid = KeepWorkItemManager.GetUID()
                    local students = v.students or {}
                    for k,obj in pairs(students) do
                        if obj.userId==uid then
                            v.studentStatus = obj.status --课堂状态:0,1
                            -- print("--------找到学生",v.status)
                        end
                    end
                end
                ClassSchedule_old._insertOneSchedule(v)
    
                y,m,d = commonlib.timehelp.GetYearMonthDayFromStr(v.date)
                
                for k,day in ipairs(month_ds) do
                    if day.year==y and day.month==m and day.day==d then --找到当天的数据，往里面补充课程数据
                        obj = day;
                        break
                    end
                end
                if obj then
                    obj.courses = obj.courses or {}
                    local contain
                    for _,o in ipairs(obj.courses) do
                        if o.startAt==v.startAt and o.endAt==v.endAt then --已经有了
                            contain = o
                            break
                        end
                    end
                    if contain then
                        for k,xx in pairs(v) do
                            contain[k] = xx
                        end
                    else
                        table.insert(obj.courses,v)
                    end
                end
            end
        -- echo(month_ds,true)
        ClassSchedule_new.RefreshUI()
        if callback then
            callback(nil)
        end
    end)
end

function ClassSchedule_new.OnAddedClass(classInfo)
    if not page then
        return
    end
    ClassSchedule_new.UpdateCourseOfMonth()
end

function ClassSchedule_new.RefreshUI()
    if page then
        page:Refresh(0)
    end
end