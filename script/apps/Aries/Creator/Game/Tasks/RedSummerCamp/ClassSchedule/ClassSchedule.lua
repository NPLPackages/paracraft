--[[
Title: 
Author(s): hyz
Date: 2022/6/15
Desc: 课表UI， RedSummerCampCourseSchedulingV2的子UI
use the lib:
------------------------------------------------------------
local ClassSchedule = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/ClassSchedule/ClassSchedule.lua") 

-------------------------------------------------------
]]
local RedSummerCampCourseScheduling = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCourseSchedulingV2.lua") 
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local ClassSimpleTip = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/ClassSchedule/ClassSimpleTip.lua") 
local RedSummerCampPPtPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtPage.lua");

local ClassSchedule = NPL.export()

local page;
function ClassSchedule.OnInit()
    page = document:GetPageCtrl();
    
end

local _weekDays = {
    L"星期一",
    L"星期二",
    L"星期三",
    L"星期四",
    L"星期五",
    L"星期六",
    L"星期日",
}

function ClassSchedule.clear()
    ClassSchedule.curClassId = nil --当前选中的班级id
    ClassSchedule.allSchedules = {}
    ClassSchedule.curSelectedWeek = os.time() --当前的选中的哪一周（一周中的任意一天）
    ClassSchedule.hasNotRequest = true
end

--登录进来后，请求当前课程表，如果有正在上的课，弹框提示
function ClassSchedule.CheckJumpToSchedule()
	local range = 10*60
    ClassSchedule.ReqNowSchedule(range,function(_courses)
        -- print("=========sssss 1")
        -- echo(_courses,true)
        local uid = KeepWorkItemManager.GetUID()
        -- print("xx-------uid",uid)
        if _courses and #_courses>0 then
            local now = os.time()
            local _isTeacher = KeepWorkItemManager.IsTeacher()
            local info
            local _type = 0 --0没有已到上课时间和即将到上课时间的课程，1即将到上课时间, 2已到上课时间，3已经开始上课了
            
            for k,v in pairs(_courses) do
                
                if v.startAt_stamp<now+range and v.endAt_stamp>now then
                    if _type<1 then
                        _type = 1
                        info = v
                    end
                end
                if v.startAt_stamp<now and v.endAt_stamp>now then
                    if _type<2 then
                        _type = 2
                        info = v
                    end
                end
                if v.status==3 then
                    if _isTeacher then 
                        if uid==v.realityUserId then
                            -- print("---------我是老师",v.realityUserId)
                            if _type<3 then
                                _type = 3 
                                info = v
                            end
                        end
                    else
                        if _type<3 then
                            _type = 3 
                            info = v
                        end
                    end
                end
            end
            print("-----------_type",_type,"_isTeacher",_isTeacher)
            
            if _isTeacher then 
                -- print("===========eeee")
                -- echo(info,true)
                if info then
                    local name = info.class.name.." "
                    for k,v in ipairs(info.sections) do
                        name = name..v.name
                        if k~=#info.sections then
                            name = name.." "
                        end
                    end
                    RedSummerCampCourseScheduling.LoadClassList(function()
                        local jumpUrl = ClassSchedule.GetJumpUrl_adjustSchedule(info.class.orgId)
                        if _type==2 then
                            local tip = string.format("%s-%s 《%s》%s，是否开始上课？",info.startAtStr,info.endAtStr,name,L"已到上课时间")
                            ClassSimpleTip.ShowIsClassTimeTip(tip,function()
                                ClassSchedule._realStartingCourse(info)
                            end,jumpUrl)
                        elseif _type==1 then
                            local tip = string.format("%s-%s 《%s》%s，是否开始上课？",info.startAtStr,info.endAtStr,name,L"即将到上课时间")
                            ClassSimpleTip.ShowIsClassTimeTip(tip,function()
                                ClassSchedule._realStartingCourse(info)
                            end,jumpUrl)
                        elseif _type==3 then
                            local tip = string.format(L"您有教学课程《%s》正在进行，是否立即进入课程页？",name or "")
                            ClassSchedule.SetCurCourse()
                            ClassSimpleTip.ShowIntoClassRoomGuide(tip,function()
                                ClassSchedule._doJump2PPT(info)
                            end)
                        end
                    end)
                end
            else
                RedSummerCampCourseScheduling.LoadClassList(function()
                    if _type==2 then --已到上课时间，是否进入课堂
                        local tip = string.format(L"你所在的班级《%s》已经到上课时间，快进入课堂准备上课吧！",info.class.name or "")
                        ClassSimpleTip.ShowIntoClassRoomGuide(tip,function()
                            ClassSchedule._doJump2PPT(info)
                        end)
                    elseif _type==3 then --已经开始上课，是否进入课堂
                        ClassSchedule.SetCurCourse()
                        local tip = string.format(L"你所在的班级《%s》已经开始上课，快进入课堂认真上课吧！",info.class.name or "")
                        ClassSimpleTip.ShowIntoClassRoomGuide(tip,function()
                            ClassSchedule._doJump2PPT(info)
                            ClassSchedule.Attendance(info.id)
                        end,true)
                    end
                end)
            end
        end
    end)
end

function ClassSchedule.GetJumpUrl_adjustSchedule(orgId,classId)
    local token = commonlib.getfield("System.User.keepworktoken")
    local KeepworkService = NPL.load('(gl)Mod/WorldShare/service/KeepworkService.lua')
    local urlbase = KeepworkService:GetKeepworkUrl()

    local orgUrl = nil
    local ds = RedSummerCampCourseScheduling.DS_classes()
    for k,v in ipairs(ds) do
        if v.org.id==orgId then
            orgUrl = v.org.orgUrl 
            break
        end
    end

    local method = '/s/myOrganization'
    if orgUrl then
        method = '/org/' .. orgUrl .. '/teacher/teach'
    end

    local url
    if classId then
        local idx = math.max(RedSummerCampPPtPage.GetLessonServerIndex() or 0,0)+1

        local packageId = RedSummerCampPPtPage.CourseConfigData and RedSummerCampPPtPage.CourseConfigData.id
        local sectionId = RedSummerCampPPtPage.CourseConfigData and RedSummerCampPPtPage.CourseConfigData.sectionAuths and RedSummerCampPPtPage.CourseConfigData.sectionAuths[idx] and RedSummerCampPPtPage.CourseConfigData.sectionAuths[idx].id
        local dateStr = os.date("%Y-%m-%d",os.time())
        local timeStr = os.date("%H:%M",os.time())

        url = format('%s/p?url=%s&token=%s&packages=%s&sections=%s&date=%s&class=%s&time=%s', urlbase, Mod.WorldShare.Utils.EncodeURIComponent(method), token or "",packageId or "",sectionId or "",Mod.WorldShare.Utils.EncodeURIComponent(dateStr),classId,Mod.WorldShare.Utils.EncodeURIComponent(timeStr))
    else
        url = format('%s/p?url=%s&token=%s', urlbase, Mod.WorldShare.Utils.EncodeURIComponent(method), token or "")
    end
    print("========jumpUrl",url)
    return url
end

--请求当前时间的课表
function ClassSchedule.ReqNowSchedule(range,callback)
    local _courses = ClassSchedule._getNowSchedule(range)
    if #_courses>0 then
        -- print("------一招就找到了")
        callback(_courses)
        return 
    end
    
    keepwork.schedule.currentSchedule({
        roleId = KeepWorkItemManager.IsTeacher() and 2 or nil,
        headers = {
            ["x-per-page"] = 200,
            ["x-page"] = 1,
        },
    },function(err,msg,data)
        -- print("----当前课表返回 err",err)
        if err~=200 then
            if callback then
                callback(nil)
            end
            return
        end
        
        -- echo(data,true)
        local data = data.data;
        local count = data and data.count
        if count==nil then
            if callback then
                callback(nil)
            end
            return
        end
        local rows = data.rows;
        for k,v in ipairs(rows) do
            v = ClassSchedule._insertOneSchedule(v)
            
            table.insert(_courses,v)
        end
        -- echo(_courses,true)
        local ret = ClassSchedule._getNowSchedule(range)
        -- print("---------在这里找到的",#ret)
        if callback then
            callback(ret)
        end
    end)
end

--[[
    ClassSchedule.allSchedules:
    {
        [classId] = {
            [weekDate] = [ --weekDate: 本周周一的日期 如：2022-06-20
                {
                    weekday = 1, --星期几
                    date = "2022.06.20",
                    courses = [ --这一天的日期
                        {
                            schoolId = 0,
                            classId = 0,
                            startAt = "2022-05-30T14:48:44.000Z",
                            endAt = "2022-05-30T14:48:44.000Z",
                            status = 0, --上课状态: 0.未上课, 1.已上课, 2.缺课, 3.正在上课
                            schoolId = 0,
                            course = {
                                id = 0,
                                name = "S1社团课"
                            }，
                            sections = [
                                {id=0,name="第一章"},
                                {id=0,name="第二章"},
                            ],
                            class = {
                                name = "向日葵班"
                            },

                            realityStartAt = "2022-05-30T14:48:44.000Z",
                            realityEndAt = "2022-05-30T14:48:44.000Z",
                            students = [
                                {status=0,userId=0}
                            ]
                        },
                        
                    ]
                }
            ]
        }
        
    }
]]

ClassSchedule.curClassId = nil --当前选中的班级id
ClassSchedule.allSchedules = {}
ClassSchedule.curSelectedWeek = os.time() --当前的选中的哪一周（一周中的任意一天）

--根据时间戳，获取那一天所在的周的周一的时间戳
function ClassSchedule.GetMondayOfStamp(stamp,formatStr)
    if #(tostring(stamp))==13 then
        stamp = math.floor(stamp/1000)
    end
    local day = commonlib.timehelp.GetWeekDay(stamp)
    local ret = stamp - (day-1)*24*3600
    if formatStr then
        ret = os.date(formatStr,ret)
    end
    return ret
end

--刷新课表UI
function ClassSchedule.RefreshScheduleUI()
    -- if page then
    --     page:Refresh(0)
    -- end
    RedSummerCampCourseScheduling.RefreshPage()
end

--获取当前选中的周的某一天的课表
function ClassSchedule._getScheduleOfDay(day)
    local week_data = ClassSchedule._findScheduleOfWeek()
    if not week_data then
        return
    end
    return week_data[day]
end

--获取当前这一时刻的课表安排
function ClassSchedule._getNowSchedule(range)
    range = range or 0 --误差范围
    local _courses = {}
    local now = os.time()
    local all = ClassSchedule.allSchedules or {}
    for classId,class_data in pairs(all) do
        for mondayDate,week_data in pairs(class_data) do
            for day, day_data in pairs(week_data) do 
                for k,v in pairs(day_data.courses) do
                    if v.v==3 or (v.startAt_stamp<now+range and v.endAt_stamp>now) then
                        table.insert(_courses,v)
                    end
                end
            end
        end
    end
    --print("-------ssss _courses",#_courses)
    return _courses
end

ClassSchedule.hasNotRequest = true
--直接获取一周的课表数据
function ClassSchedule._findScheduleOfWeek(weekStamp)
    if ClassSchedule.hasNotRequest then
        ClassSchedule.hasNotRequest = false
        ClassSchedule.ReqScheduleOfWeek()
        return
    end
    local classId = ClassSchedule.curClassId
    if weekStamp==nil then
        if ClassSchedule.curSelectedWeek == nil then
            ClassSchedule.curSelectedWeek = os.time()
        end
        weekStamp = ClassSchedule.curSelectedWeek
    end

    local mondayStr = ClassSchedule.GetMondayOfStamp(weekStamp,"%Y-%m-%d")
    -- print("--------mondayStr",mondayStr)
    local class_data = ClassSchedule.allSchedules[classId]

    if class_data==nil then 
        return
    end 
    week_data = class_data[mondayStr]
    -- GameLogic.AddBBS("12","杀死 3")
    -- print("=========aaaaaweek_data",ClassSchedule.curClassId,mondayStr)
    -- echo(week_data,true)
    return week_data
end

--插入一条课表数据
function ClassSchedule._insertOneSchedule(v)
    ClassSchedule.allSchedules = ClassSchedule.allSchedules or {}
    local class_data = ClassSchedule.allSchedules[v.classId]
    if not class_data then
        class_data = {}
        ClassSchedule.allSchedules[v.classId] = class_data
    end
    v.startAt_stamp = commonlib.timehelp.GetTimeStampByDateTime(v.startAt)
    v.endAt_stamp = commonlib.timehelp.GetTimeStampByDateTime(v.endAt)
    local mondayDate = ClassSchedule.GetMondayOfStamp(v.startAt_stamp,"%Y-%m-%d") --上课时间所在周的周一日期
    local week_data = class_data[mondayDate]
    if not week_data then
        week_data = {}
        class_data[mondayDate] = week_data
    end
    
    v.date = os.date("%Y.%m.%d",v.startAt_stamp)
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
    
    local day_data = week_data[v.weekday]
    if not day_data then
        day_data = {}
        week_data[v.weekday] = day_data
        day_data.weekday = v.weekday
        day_data.weekDayStr = _weekDays[v.weekday]
        day_data.date = v.date
    end
    local courses = day_data.courses
    if not courses then
        courses = {}
        day_data.courses = courses
    end
    
    local ret = nil --是否已經存在了
    for k,obj in pairs(courses) do
        if obj.startAt==v.startAt and obj.endAt==v.endAt then
            ret = obj 
            break
        end
    end
    if ret then --已经有了，刷新值就行
        for k,xx in pairs(v) do
            ret[k] = xx
        end
    else
        ret = v
        table.insert(courses,ret)
    end

    return ret
end

--[[
    获取一周的课表
    weekStamp:一周中的任意一天的时间戳，没有就是当前周
]]
function ClassSchedule.ReqScheduleOfWeek(weekStamp,callback,bForce)
    ClassSchedule.allSchedules = ClassSchedule.allSchedules or {}
    
    if weekStamp==nil then
        if ClassSchedule.curSelectedWeek == nil then
            ClassSchedule.curSelectedWeek = os.time()
        end
        weekStamp = ClassSchedule.curSelectedWeek
    end
    -- print("---------weekStamp",weekStamp)
    -- print("-----ReqScheduleOfWeek ClassSchedule.curClassId",ClassSchedule.curClassId)

    local ret = ClassSchedule._findScheduleOfWeek(weekStamp)
    if not bForce and ret then
        if callback then
            callback(ret)
        end
        -- print("------有了",#ret)echo(ret)
        return 
    end
    
    keepwork.schedule.searchSchedule({
        roleId = KeepWorkItemManager.IsTeacher() and 2 or nil,
        classId = ClassSchedule.curClassId,
        date = weekStamp,
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
        local rows = data.rows;
        for k,v in ipairs(rows) do
            ClassSchedule._insertOneSchedule(v)
        end
        
        local week_data = ClassSchedule._findScheduleOfWeek(weekStamp)
        -- print("=========dddddddd",week_data==nil)
        -- echo(ClassSchedule.allSchedules,true)
        ClassSchedule.SetCurCourse()
        if count>0 then
            ClassSchedule.RefreshScheduleUI()
        end
        if callback then
            callback(week_data)
        end
    end)
end


--一周中，所有的课，按顺序排列，有哪几节课
--任意一对 (开始时间-结束时间)算一节课
function ClassSchedule.GetAllCourseTime()
    local tab = {}
    local num = 2
    for i=1,7 do 
        local day_data = ClassSchedule._getScheduleOfDay(i)
        if day_data then
            for k,v in pairs(day_data.courses) do
                local courseTimeStr = v.startAtStr.."-"..v.endAtStr
                tab[courseTimeStr] = {v.startAtStr, v.endAtStr}
            end
        end
    end
    
    local ret = {}
    for k,v in pairs(tab) do
        table.insert(ret,v)
    end

    --按照开始时间排序
    table.sort(ret,function(a,b)
        local startA = string.gsub(a[1],"[^%d]+","")
        local startB = string.gsub(b[1],"[^%d]+","")
        local endA = string.gsub(a[2],"[^%d]+","")
        local endB = string.gsub(b[2],"[^%d]+","")
        if startA==startB then
            return endA<endB
        else
            return startA<startB
        end
    end)
    return ret;
end

function ClassSchedule.GetCourseOfDay(day)
    local ret = {}

    local times = ClassSchedule.GetAllCourseTime()
    
    local day_data = ClassSchedule._getScheduleOfDay(day)
    if day_data then
        for i=1,#times do
            local t = times[i]
            local startAtStr,endAtStr = t[1],t[2]

            local info = ""
            for k,v in pairs(day_data.courses) do
                if v.startAtStr==startAtStr and v.endAtStr==endAtStr then
                    info = v
                    break
                end
            end
            
            ret[i] = info
        end
        
    end
    -- if day==2 then
    --     print("----------sssss day",day)
    --     echo(ret)
    -- end
    return ret
end

--设置班级信息
function ClassSchedule.SetClassInfo(classInfo)
    
    ClassSchedule.classInfo = classInfo
    ClassSchedule.curClassId = classInfo.classId or classInfo.id
    -- print("班级",classInfo.classId,ClassSchedule.curClassId)
    -- print("-----------aaaffgtyyyy 1",ClassSchedule.curClassId)
    -- echo(classInfo,true)
    ClassSchedule.ReqScheduleOfWeek(nil,nil)

end

--学生进行签到
function ClassSchedule.CheckSignIn()

end

--获取日期范围描述
function ClassSchedule.GetCurDateDesc()
    if ClassSchedule.curSelectedWeek == nil then
        ClassSchedule.curSelectedWeek = os.time()
    end
    
    if #(tostring(ClassSchedule.curSelectedWeek))==13 then
        ClassSchedule.curSelectedWeek = math.floor(ClassSchedule.curSelectedWeek/1000)
    end

    local stamp = ClassSchedule.curSelectedWeek
    local day = commonlib.timehelp.GetWeekDay(stamp)
    local monday = stamp - (day-1)*24*3600
    local sunday = monday + 6*24*3600
    
    local str = os.date(L"%Y.%m.%d",monday) .. " - " .. os.date(L"%Y.%m.%d",sunday)

    return str
end

function ClassSchedule.on_pre_week()
    if ClassSchedule.curSelectedWeek == nil then
        ClassSchedule.curSelectedWeek = os.time()
    end
    local temp = ClassSchedule.curSelectedWeek - 7*24*3600
    ClassSchedule.ReqScheduleOfWeek(temp,function(week_data)
        if not week_data then
            GameLogic.AddBBS(nil,L"往前没有排课了")
        else
            ClassSchedule.curSelectedWeek = temp 
            ClassSchedule.RefreshScheduleUI()
        end
    end)
end

function ClassSchedule.on_next_week()
    if ClassSchedule.curSelectedWeek == nil then
        ClassSchedule.curSelectedWeek = os.time()
    end
    local temp = ClassSchedule.curSelectedWeek + 7*24*3600
    ClassSchedule.ReqScheduleOfWeek(temp,function(week_data)
        if not week_data then
            GameLogic.AddBBS(nil,L"往后没有排课了")
        else
            ClassSchedule.curSelectedWeek = temp
            ClassSchedule.RefreshScheduleUI()
        end
    end)
end

--当前正在进行的课程
ClassSchedule._curCourse = nil 

--是否正在上课
function ClassSchedule.IsInClassNow()
    if ClassSchedule._curCourse then 
        return true 
    end
    
    return nil
end

function ClassSchedule.SetCurCourse(_course)
    if _course then
        ClassSchedule._curCourse = _course
    elseif ClassSchedule._curCourse==nil then
        local all = ClassSchedule.allSchedules or {}
        for classId,class_data in pairs(all) do
            for mondayDate,week_data in pairs(class_data) do
                for day, day_data in pairs(week_data) do 
                    for k,v in pairs(day_data.courses) do
                        if v.status==3 then --3表示正在上课
                            ClassSchedule._curCourse = v 
                            return v
                        end
                    end
                end
            end
        end
    end
end

--老师点击"开始上课"
function ClassSchedule.StartClass(callback)
    ClassSchedule.ReqNowSchedule(nil,function(_courses)
        _courses = _courses or {}
        local _schedules = {}
        for k,v in pairs(_courses) do
            _schedules[v.classId] = v
        end
        -- print("==========_sourse")
        -- echo(_courses)
        local ds = RedSummerCampCourseScheduling.DS_classes()
        ClassSimpleTip.ShowChooseClass(ds,function(index)
            local cls_info = ds[index]
            -- print("=============cls_info")
            -- echo(cls_info,true)
            if cls_info then --上课
                local obj = _schedules[cls_info.classId]
                -- print("上课 obj 返回")echo(obj)
                if obj==nil then
                    -- GameLogic.AddBBS(nil,L"当前没有排课")
                    ClassSimpleTip.ShowJumpTo_adjustSchedule(ClassSchedule.GetJumpUrl_adjustSchedule(cls_info.orgId,cls_info.classId))
                    return
                end
                if obj.status==3 then
                    GameLogic.AddBBS(nil,L"该班级正在上课中，请选择其他班级")
                    return
                end
                ClassSchedule._realStartingCourse(obj,callback)
            end
        end)
    end)
    
end

function ClassSchedule._realStartingCourse(_course,callback)
    ClassSchedule._doJump2PPT(_course)
    keepwork.schedule.startCourse({
        id = _course.id
    },function(err,msg,data)
        --print("-------开始上课返回 err",err,"_course.id",_course.id)
        if err==200 then
            _course.status = 3
            ClassSchedule.SetCurCourse(_course)
            GameLogic.GetFilters():apply_filters("starting_class");
            if callback then
                callback()
            end
            GameLogic.AddBBS(nil,L"进入课堂模式，开始上课")
            ClassSchedule.RefreshScheduleUI()
        else
            -- echo(data)
            GameLogic.AddBBS(nil,data.message,nil,"255 0 0")
        end
    end)
end

--老师点击"下课"
function ClassSchedule.EndClass(callback)
    local _course = ClassSchedule._curCourse
    if _course==nil then
        GameLogic.GetFilters():apply_filters("ending_class");
        return
    end
    ClassSimpleTip.ShowAfterClassConfirmTip(function()
        keepwork.schedule.endCourse({
            id = _course.id
        },function(err,msg,data)
            -- print("-------下课返回 err",err)
            if err==200 then
                _course.status = 1
                ClassSchedule._curCourse = nil 
                GameLogic.GetFilters():apply_filters("ending_class");
                if callback then
                    callback(data)
                end
                GameLogic.AddBBS(nil,L"已退出课堂模式，本次课程结束")
                ClassSchedule.RefreshScheduleUI()
            end
        end)
    end)
end

--处理推送
--[[
    {
        action = "schedule_start"|"schedule_start",
        orgId: 0,
        classId: 0,
        scheduleId: 0,
    }
]]
function ClassSchedule.OnSocketPush(obj)
    local _isTeacher = KeepWorkItemManager.IsTeacher()
    local info = nil;
    ClassSchedule.ReqScheduleOfWeek(nil,function(week_data)
        -- print("---------回调来")
        local _course = ClassSchedule._findCourseByScheduleId(obj.scheduleId)
        if _course==nil then
            print("找不到课程")
            echo(obj)
            return
        end
        -- echo(obj)
        if obj.action=="schedule_start_pre" then --上课前10分钟和上课前各推送一次，推给老师
            local name = _course.class.name.." "
            for k,v in ipairs(_course.sections) do
                name = name..v.name
                if k~=#_course.sections then
                    name = name.." "
                end
            end
            local _type = 0 --0没有已到上课时间和即将到上课时间的课程，1即将到上课时间, 2已到上课时间，3已经开始上课了
            do
                local v = _course
                local now = os.time()
                local range = 10*60
                if v.startAt_stamp<now+range and v.endAt_stamp>now then
                    _type = 1
                    info = v
                end
                if v.startAt_stamp<now and v.endAt_stamp>now then
                    _type = 2
                    info = v
                end
                if v.status==3 then
                    _type = 3 
                    info = v
                end
            end
            print("---------obj.action",obj.action)
            local jumpUrl = ClassSchedule.GetJumpUrl_adjustSchedule(_course.class.orgId)
            print("----jumpUrl2",jumpUrl)
            if _type==2 then
                local tip = string.format("%s-%s 《%s》%s，是否开始上课？",_course.startAtStr,_course.endAtStr,name,L"已到上课时间")
                ClassSimpleTip.ShowIsClassTimeTip(tip,function()
                    ClassSchedule._realStartingCourse(_course)
                end,jumpUrl)
            elseif _type==1 then
                local tip = string.format("%s-%s 《%s》%s，是否开始上课？",_course.startAtStr,_course.endAtStr,name,L"即将到上课时间")
                ClassSimpleTip.ShowIsClassTimeTip(tip,function()
                    ClassSchedule._realStartingCourse(_course)
                end,jumpUrl)
            end
        elseif obj.action=="schedule_start" then --老师点击了上课，推给学生
            if not _isTeacher then
                _course.status = 3
                ClassSchedule.RefreshScheduleUI()
                if RedSummerCampPPtPage.IsVisible() then
                    GameLogic.AddBBS(nil,L"进入课堂模式，开始上课")
                    ClassSchedule.Attendance(_course.id)
                    return
                end
                local tip = string.format(L"你所在的班级《%s》已经开始上课，快进入课堂认真上课吧！",_course.class.name or "")
                ClassSimpleTip.ShowIntoClassRoomGuide(tip,function()
                    ClassSchedule._doJump2PPT(_course)
                    ClassSchedule.Attendance(_course.id)
                end,true)
            end
        elseif obj.action=="schedule_finish" then --老师点击了下课，推给学生
            -- print("--------下课了")
            if not _isTeacher then
                ClassSchedule._curCourse = nil
                _course.status = 1
                ClassSchedule.RefreshScheduleUI()
                GameLogic.AddBBS(nil,L"已退出课堂模式，本次课程结束")
            end
        end
    end,true)
end

function ClassSchedule._doJump2PPT(_course)
    if true then
        local ClassSchedule_new = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/ClassSchedule/ClassSchedule_new.lua") 
        ClassSchedule_new._doJump2PPT(_course)
        return
    end
    if _course==nil then
        return
    end
    ClassSchedule.classInfo = _course.class
    ClassSchedule.curClassId = _course.class.classId or _course.class.id
    if not RedSummerCampCourseScheduling.IsVisible() then
        RedSummerCampCourseScheduling.ShowView()
        RedSummerCampCourseScheduling.curClassName = _course.class.name
        RedSummerCampCourseScheduling.SetScheduleVisible(true)
    end
    -- if not RedSummerCampPPtPage.IsVisible() then
        --进入PPT页面
        RedSummerCampCourseScheduling.ShowPPTPageById(_course.courseId,_course.sections[1].index)
    -- end
end

function ClassSchedule._findCourseByScheduleId(scheduleId)
    -- print("----------scheduleId",scheduleId)
    if scheduleId==nil then
        return
    end
    
    local all = ClassSchedule.allSchedules or {}
    for classId,class_data in pairs(all) do
        for mondayDate,week_data in pairs(class_data) do
            for day, day_data in pairs(week_data) do 
                for k,v in pairs(day_data.courses) do
                    -- print("-------v.id",v.id)
                    if v.id==scheduleId then
                        -- print("---------去掉转")
                        -- echo(v,true)
                        return v
                    end
                end
            end
        end
    end
end

function ClassSchedule.OnClickCourse(name,mcmlNode)
    local scheduleId = tonumber(name)
    if scheduleId==nil then
        return
    end
    local _course = ClassSchedule._findCourseByScheduleId(scheduleId)
    if _course then
        -- echo(_course)
        ClassSchedule._doJump2PPT(_course)
    end
end

--学生打卡考勤
function ClassSchedule.Attendance(scheduleId)
    keepwork.schedule.attendance({
        id = scheduleId
    },function(err,msg,data)
        print("-----考勤结果 err",err)
        echo(data)
        if err==200 then
            -- GameLogic.AddBBS(1,L"考勤成功")
        else
            echo(msg)
        end
    end)
end