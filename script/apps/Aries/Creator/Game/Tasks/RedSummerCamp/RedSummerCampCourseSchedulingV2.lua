--[[
Title: 
Author(s): pbb
Date: 2021/9/17
Desc: 
use the lib:
------------------------------------------------------------
local RedSummerCampCourseScheduling = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCourseSchedulingV2.lua") 
RedSummerCampCourseScheduling.ShowView()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestAction.lua");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
local RedSummerCampPPtPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtPage.lua");
local ClassSchedule = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/ClassSchedule/ClassSchedule.lua",true) 
local RedSummerCampCourseScheduling = NPL.export()
local beginYear,endYear
local Ydata
local page,page_root
local curYear,curMonth
local curSelectLesson = ""
local gsid = 40007
local my_course_id = 999
local all_course_id= 998
local show_num= 10
local default_classes = {
    {
        name="我的课包",
        sn = 100,
        id = my_course_id,
    },
    {
        name="全部",
        sn = 99,
        id = all_course_id,
    },
}
RedSummerCampCourseScheduling.curLearnHistroy = {}
RedSummerCampCourseScheduling.lessonCnf = {}
RedSummerCampCourseScheduling.my_lessonCnf = {}
RedSummerCampCourseScheduling.show_lesson_list ={}
RedSummerCampCourseScheduling.auths = {}
function RedSummerCampCourseScheduling.OnInit()
    page = document:GetPageCtrl()
    if page then
        page_root = page:GetParentUIObject()
    end
end

function RedSummerCampCourseScheduling.SetControlVisible(name, v)
    if not name or name=="" then
        return
    end
    if page and page:IsVisible() then
        local control = page:FindControl(name)
        if control and control:IsValid() then
            control.visible = v ~= nil and v  or false
        end
    end
end

function RedSummerCampCourseScheduling.AuthLessonV2(callback)
    RedSummerCampCourseScheduling.LoadUserRoles(function()
        keepwork.courses.userCourses({},function(err, msg, data)
            RedSummerCampCourseScheduling.lessonCnf = {}
            RedSummerCampCourseScheduling.my_lessonCnf = {}
            RedSummerCampCourseScheduling.auths = {}
            if err == 200 then
                local isHaveErrData = false
                for k,v in pairs(data) do
                    if v and v.code and v.code ~= "" then
                        RedSummerCampCourseScheduling.my_lessonCnf[#RedSummerCampCourseScheduling.my_lessonCnf + 1] = v
                        RedSummerCampCourseScheduling.auths[v.code] = true
                    else
                        isHaveErrData = true
                    end
                end

                if isHaveErrData then
                    RedSummerCampCourseScheduling.ReprotErrorData("coursesuserCourses",data)
                end

                table.sort(RedSummerCampCourseScheduling.my_lessonCnf,function(a,b)
                    return a.sn > b.sn
                end)
                RedSummerCampCourseScheduling.LoadLessonCnfV2(callback)
            else
                LOG.std(nil, "info", "RedSummerCampCourseScheduling.AuthLessonV2", data);
                LOG.std(nil, "info", "RedSummerCampCourseScheduling.AuthLessonV2", err);
                RedSummerCampCourseScheduling.LoginOutByErrToken(err)
                if err and err == 0 then
                    RedSummerCampCourseScheduling.LoadLessonData()
                end
            end
        end)
    end)
end



function RedSummerCampCourseScheduling.LoadLessonCnfV2(callback)
    keepwork.courses.query({},function(err, msg, data)
        RedSummerCampCourseScheduling.lessonCnf = {}
        if err == 200 then
            if not data or not data.count then
                RedSummerCampCourseScheduling.ReprotErrorData("coursesquery",data)
            end
            if data and data.count and data.count > 0 then
                for k,v in pairs(data.rows) do
                    if v then
                        v.auth=false
                        if RedSummerCampCourseScheduling.auths[v.code] then
                            v.auth = RedSummerCampCourseScheduling.auths[v.code]
                            RedSummerCampCourseScheduling.lessonCnf[#RedSummerCampCourseScheduling.lessonCnf + 1] = v
                        else
                            if v.displayRules == 0 then
                                v.auth = true
                                RedSummerCampCourseScheduling.my_lessonCnf[#RedSummerCampCourseScheduling.my_lessonCnf + 1] = v
                                RedSummerCampCourseScheduling.lessonCnf[#RedSummerCampCourseScheduling.lessonCnf + 1] = v
                                RedSummerCampCourseScheduling.auths[v.code] = true
                                
                            elseif v.displayRules == 1 then
                                v.auth = false
                                RedSummerCampCourseScheduling.lessonCnf[#RedSummerCampCourseScheduling.lessonCnf + 1] = v
                                RedSummerCampCourseScheduling.auths[v.code] = false
                            end
                        end
                    end
                end
            end
            if callback then
                callback()
            end
        else
            LOG.std(nil, "info", "RedSummerCampCourseScheduling.LoadLessonCnfV2", data);
            LOG.std(nil, "info", "RedSummerCampCourseScheduling.LoadLessonCnfV2", err);
            RedSummerCampCourseScheduling.LoginOutByErrToken(err)
        end
    end)
end

function RedSummerCampCourseScheduling.SortLessonByAuth()
    if RedSummerCampCourseScheduling.lessonCnf and #RedSummerCampCourseScheduling.lessonCnf > 0 then
        if RedSummerCampCourseScheduling.lessonCnf[1].sn then
            table.sort(RedSummerCampCourseScheduling.lessonCnf,function(a,b)
                return a.sn > b.sn
            end)
        end
        local temp1 = {}
        local temp2 = {}
        for k,v in pairs(RedSummerCampCourseScheduling.lessonCnf) do
            if RedSummerCampCourseScheduling.auths[v.code] then
                temp1[#temp1 + 1] = v
            else
                temp2[#temp2 + 1] = v
            end
        end
        RedSummerCampCourseScheduling.lessonCnf = {}
        RedSummerCampCourseScheduling.lessonCnf = temp1
        for k,v in pairs(temp2) do
            RedSummerCampCourseScheduling.lessonCnf[#RedSummerCampCourseScheduling.lessonCnf + 1] = v
        end
    end
end

function RedSummerCampCourseScheduling.LoadPageData() 
    RedSummerCampCourseScheduling.AuthLessonV2(function()
        RedSummerCampCourseScheduling.SortLessonByAuth()
        RedSummerCampCourseScheduling.LoadLessonClasses()
    end)
end

function RedSummerCampCourseScheduling.LoadLessonClasses()
    keepwork.courses.course_class({
        ["x-per-page"] = 200,
        ["x-page"] = 1,
    },function (err ,msg, data)
        RedSummerCampCourseScheduling.m_select_index = 1
        RedSummerCampCourseScheduling.lesson_classes = {}
        RedSummerCampCourseScheduling.lesson_classes = commonlib.copy(default_classes)
        RedSummerCampCourseScheduling.show_lesson_classes = {}
        RedSummerCampCourseScheduling.other_lesson_classes = {}
        RedSummerCampCourseScheduling.show_lesson_list = {}
        if err == 200 then
            if not data or not data.count then
                RedSummerCampCourseScheduling.ReprotErrorData("coursescourse_class",data)
            end
            if data and data.count and data.count > 0 then
                for i,v in ipairs(data.rows) do
                    RedSummerCampCourseScheduling.lesson_classes[#RedSummerCampCourseScheduling.lesson_classes + 1] = v
                end
                table.sort( RedSummerCampCourseScheduling.lesson_classes, function (a,b)
                    return a.sn > b.sn
                end)
                for i,v in ipairs(RedSummerCampCourseScheduling.lesson_classes) do
                    if v.id == my_course_id then
                        v.courses = commonlib.copy(RedSummerCampCourseScheduling.my_lessonCnf)
                    end
                    if v.id == all_course_id then
                        v.courses = commonlib.copy(RedSummerCampCourseScheduling.lessonCnf)
                    end
                    if i <= show_num then
                        RedSummerCampCourseScheduling.show_lesson_classes[#RedSummerCampCourseScheduling.show_lesson_classes + 1] = v
                    else
                        RedSummerCampCourseScheduling.other_lesson_classes[#RedSummerCampCourseScheduling.other_lesson_classes + 1] = v
                    end
                end
            end
            RedSummerCampCourseScheduling.show_lesson_list = commonlib.copy(RedSummerCampCourseScheduling.my_lessonCnf)
            
            RedSummerCampCourseScheduling.RefreshPage()
        else
            LOG.std(nil, "info", "RedSummerCampCourseScheduling.LoadLessonClasses", data);
            LOG.std(nil, "info", "RedSummerCampCourseScheduling.LoadLessonClasses", err);
            RedSummerCampCourseScheduling.LoginOutByErrToken(err)
        end
    end)
    
end

function RedSummerCampCourseScheduling.ShowView()
    local function show()
        RedSummerCampCourseScheduling.InitPageData()
        RedSummerCampCourseScheduling.ShowPage()
    end
    if GameLogic.GetFilters():apply_filters('is_signed_in') then
        show()
        return
    end

    GameLogic.GetFilters():apply_filters('check_signed_in', L"请先登录", function(result)
        if result == true then
            commonlib.TimerManager.SetTimeout(function()
                show()
            end, 1000)
        end
    end)
    
end

function RedSummerCampCourseScheduling.ExchangeLessonSuc()
    if page and page:IsVisible() then
        RedSummerCampCourseScheduling.LoadPageData()
    end
end

function RedSummerCampCourseScheduling.ShowPage()
    local view_width = 740
    local view_height = 560
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCourseSchedulingV2.html",
        name = "RedSummerCampCourseScheduling.ShowView", 
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
    if(params._page ) then
		params._page.OnClose = function(bDestroy)
			RedSummerCampCourseScheduling.HideTip()
		end
	end

    RedSummerCampCourseScheduling.InitOtherLessonBg()
    RedSummerCampCourseScheduling.LoadPageData()
	-- 上报
	GameLogic.GetFilters():apply_filters('user_behavior', 1, 'crsp.courselist.visit', {useNoId = true})
    RedSummerCampCourseScheduling._isExpland = false
    RedSummerCampCourseScheduling.LoadClassList()
    if not RedSummerCampCourseScheduling.IsBindEvent then
        GameLogic.GetFilters():add_filter("KeyPressEvent",function(callbackVal, event)
            if event.keyname == "DIK_ESCAPE" then
                if RedSummerCampCourseScheduling.IsOpen() then
                    RedSummerCampCourseScheduling.ClosePage()
                    event:accept()
                end
            end
            return callbackVal, event
        end)
        RedSummerCampCourseScheduling.IsBindEvent = true
    end
    
end

function RedSummerCampCourseScheduling.RefreshPage()
    if page then
        RedSummerCampCourseScheduling.UpdateMyLessonAfterLearn()
        page:Refresh(0)
        RedSummerCampCourseScheduling.InitOtherLessonBg()
    end
end

function RedSummerCampCourseScheduling.InitOtherLessonBg()
    local uiObj = ParaUI.GetUIObject("otherBg")
    if uiObj and uiObj:IsValid() then
        uiObj.visible = false
        uiObj:SetScript("onmouseleave",function()
            uiObj.visible = false
        end)
    end    
end

function RedSummerCampCourseScheduling.OnClickCourseOtherClass(name)
    local changeIndex = -1
    for i,v in ipairs(RedSummerCampCourseScheduling.other_lesson_classes) do
        if v.id == tonumber(name) then
            changeIndex = i
            break
        end
    end
    local destIndex = 3
    if changeIndex > 0 and RedSummerCampCourseScheduling.show_lesson_classes[destIndex] ~= nil then
        local temp = RedSummerCampCourseScheduling.show_lesson_classes[destIndex]
        RedSummerCampCourseScheduling.show_lesson_classes[destIndex] = RedSummerCampCourseScheduling.other_lesson_classes[changeIndex]
        RedSummerCampCourseScheduling.other_lesson_classes[changeIndex] = temp
        local id = RedSummerCampCourseScheduling.show_lesson_classes[destIndex].id
        RedSummerCampCourseScheduling.OnClickCourseClass(tostring(id))
    end

end

function RedSummerCampCourseScheduling.OnClickCourseClass(name)
    local lessonId = -1
    local lessonIndex = -1
    for i,v in ipairs(RedSummerCampCourseScheduling.show_lesson_classes) do
        if v.id == tonumber(name) then
            lessonId = v.id
            RedSummerCampCourseScheduling.m_select_index = i
            break
        end
    end
    --首先求得该数据在总数据的位置
    for i,v in ipairs(RedSummerCampCourseScheduling.lesson_classes) do
        if lessonId == v.id then
            lessonIndex = i
            break
        end
    end
    if lessonIndex <= 0 or lessonId <= 0 then --数据不合理
        return 
    end
    local curIndex = RedSummerCampCourseScheduling.m_select_index
    -- 请求课程列表项下的具体内容
    if lessonId == my_course_id or lessonId == all_course_id then --我的课包 和 全部课包
        RedSummerCampCourseScheduling.show_lesson_list = RedSummerCampCourseScheduling.show_lesson_classes[curIndex].courses or {}
        
        RedSummerCampCourseScheduling.RefreshPage() 
        RedSummerCampCourseScheduling.SaveLessonData()
    else
        RedSummerCampCourseScheduling.show_lesson_list = {}
        local courses = RedSummerCampCourseScheduling.show_lesson_classes[curIndex].courses
        if courses and #courses > 0 then
            RedSummerCampCourseScheduling.show_lesson_list = courses
            
            RedSummerCampCourseScheduling.RefreshPage() 
        else
            keepwork.courses.query_courses({
                router_params = {
                    courseClassifyId = lessonId,
                },
                headers = {
                    ["x-per-page"] = 200,
                    ["x-page"] = 1,
                }
            },function(err,msg,data)
                if err == 200 then
                    if data and data.count > 0 then
                        local temp1 = {}
                        local temp2 = {}
                        for k,v in pairs(data.rows) do
                            if RedSummerCampCourseScheduling.auths[v.code] then
                                temp1[#temp1 + 1] = v
                            else
                                temp2[#temp2 + 1] = v
                            end
                        end
                        for k,v in pairs(temp2) do
                            temp1[#temp1 + 1] = v
                        end
                        RedSummerCampCourseScheduling.show_lesson_list = temp1
                        RedSummerCampCourseScheduling.show_lesson_classes[curIndex].courses = temp1
                        RedSummerCampCourseScheduling.lesson_classes[lessonIndex].courses = temp1
                        
                        RedSummerCampCourseScheduling.SaveLessonData()
                    end
                else
                    LOG.std(nil, "info", "RedSummerCampCourseScheduling.OnClickCourseClass", data);
                    LOG.std(nil, "info", "RedSummerCampCourseScheduling.OnClickCourseClass", err);
                    RedSummerCampCourseScheduling.LoginOutByErrToken(err)
                end
                RedSummerCampCourseScheduling.RefreshPage() 
            end)
        end
    end
end

function RedSummerCampCourseScheduling.LoginOutByErrToken(err)
    local err = err or 0
    local str = "请求数据失败，错误码是"..err
    if err == 401 then
        str = str .. "，请退出重新登陆"
    elseif err == 0 then
        str = "你的网络质量差"
    end

    local RedSummerCampMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampMainPage.lua");
    local RedSummerCampSchoolMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampSchoolMainPage.lua");
    
    GameLogic.AddBBS(nil,str)
    commonlib.TimerManager.SetTimeout(function()
        if err and err == 401 then
            GameLogic.GetFilters():apply_filters('logout', nil, function()
                GameLogic.GetFilters():apply_filters("OnKeepWorkLogout", true);
                RedSummerCampPPtPage.ClosePPtAllPage()
                RedSummerCampSchoolMainPage.Close()
                RedSummerCampMainPage.Close()
                local is_enter_world = GameLogic.GetFilters():apply_filters('store_get', 'world/isEnterWorld');
                if (is_enter_world) then
                    local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop")
                    local platform = System.os.GetPlatform()
        
                    if platform == 'win32' or platform == 'mac' then
                        Desktop.ForceExit(false)
                    elseif platform ~= 'win32' then
                        Desktop.ForceExit(true)
                    end
                else
                    MyCompany.Aries.Game.MainLogin:next_step({IsLoginModeSelected = false})
                end
            end);            
            RedSummerCampPPtPage.PPtCacheData = {}
        end
    end, 2000)
end

local SAVE_LESSON_KEY = "CourseScheduling_Save"
function RedSummerCampCourseScheduling.SaveLessonData()
    if RedSummerCampCourseScheduling.lesson_classes and #RedSummerCampCourseScheduling.lesson_classes > 0 then
        GameLogic.GetPlayerController():SaveLocalData(SAVE_LESSON_KEY, RedSummerCampCourseScheduling.lesson_classes, true);
    end
end


--加载离线配置
function RedSummerCampCourseScheduling.LoadLessonData()
    local data = GameLogic.GetPlayerController():LoadLocalData(SAVE_LESSON_KEY,nil,true);
    if data and #data > 0 then
        RedSummerCampCourseScheduling.m_select_index = 1
        RedSummerCampCourseScheduling.lesson_classes = data
        RedSummerCampCourseScheduling.show_lesson_classes = {}
        RedSummerCampCourseScheduling.other_lesson_classes = {}
        RedSummerCampCourseScheduling.show_lesson_list = {}
        table.sort( RedSummerCampCourseScheduling.lesson_classes, function (a,b)
            return a.sn > b.sn
        end)
        for i,v in ipairs(RedSummerCampCourseScheduling.lesson_classes) do
            if v.id == my_course_id then
                RedSummerCampCourseScheduling.my_lessonCnf= commonlib.copy(v.courses)
            end
            if v.id == all_course_id then
                RedSummerCampCourseScheduling.lessonCnf= commonlib.copy(v.courses)
            end
            if i <= show_num then
                RedSummerCampCourseScheduling.show_lesson_classes[#RedSummerCampCourseScheduling.show_lesson_classes + 1] = v
            else
                RedSummerCampCourseScheduling.other_lesson_classes[#RedSummerCampCourseScheduling.other_lesson_classes + 1] = v
            end
        end

        --处理数据
        RedSummerCampCourseScheduling.auths = {} 
        -- for k,v in pairs(RedSummerCampCourseScheduling.lessonCnf) do
        --     if v.displayRules == 0 then
        --         RedSummerCampCourseScheduling.my_lessonCnf[#RedSummerCampCourseScheduling.my_lessonCnf + 1] = v
        --         RedSummerCampCourseScheduling.auths[v.code] = true
        --     end
        -- end
        
        if RedSummerCampCourseScheduling.my_lessonCnf then
            for i,v in ipairs(RedSummerCampCourseScheduling.my_lessonCnf) do
                RedSummerCampCourseScheduling.auths[v.code] = true
            end
        end
        if RedSummerCampCourseScheduling.m_select_index == 1 then
            for k,v in pairs(RedSummerCampCourseScheduling.my_lessonCnf) do
                RedSummerCampCourseScheduling.show_lesson_list[#RedSummerCampCourseScheduling.show_lesson_list + 1] = v
            end
        end
        
        RedSummerCampCourseScheduling.RefreshPage()
    end
end

function RedSummerCampCourseScheduling.InitPageData()
    local timeStamp = QuestAction.GetServerTime()
    curYear = tonumber(os.date("%Y",timeStamp))
    endYear = curYear
    beginYear = curYear
    Ydata = {}
    curMonth = tonumber(os.date("%m", timeStamp))
end

function RedSummerCampCourseScheduling.GetSaveKey()
    local userId = GameLogic.GetFilters():apply_filters('store_get', 'user/userId') or "";
    local save_key = userId.."cource_scheduling"
    return save_key
end

function RedSummerCampCourseScheduling.GetDateStr()
    return string.format("%d年%02d月",curYear or 2021,curMonth or 9)
end

function RedSummerCampCourseScheduling.OnClickNextMonth()
    curMonth = curMonth + 1
    if curMonth > 12 then
        curMonth = 1
        curYear =  curYear + 1
        endYear = curYear
        beginYear = curYear
        Ydata = {}
    end
    RedSummerCampCourseScheduling.RefreshPage()
end

function RedSummerCampCourseScheduling.OnClickPreMonth()
    curMonth = curMonth - 1
    if curMonth < 1 then
        curMonth = 12
        curYear =  curYear - 1
        endYear = curYear
        beginYear = curYear
        Ydata = {}
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
        if curYear < beginYear then
            return 
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
        local server_time = QuestAction.GetServerTime()
        if curYear == tonumber(os.date("%Y",server_time)) 
            and curMonth == tonumber(os.date("%m", server_time)) 
            and not data.isQs
            and data.d == tonumber(os.date("%d", server_time)) then
            return true
        end
    end
    return false
end

function RedSummerCampCourseScheduling.GetTodayHistroy()
    local server_time = QuestAction.GetServerTime()
    local year = tonumber(os.date("%Y",server_time))
    local month = tonumber(os.date("%m", server_time))
    local day = tonumber(os.date("%d", server_time))
    local time_stamp = os.time({year = year, month = month, day = day, hour=0, min=0, sec=0})
    local clientData = KeepWorkItemManager.GetClientData(gsid) or {};
    if clientData[tostring(time_stamp)] ~= nil then
        return clientData[tostring(time_stamp)]
    end
end

function RedSummerCampCourseScheduling.GetDayHistroy(data)
    if data and not data.isQs then
        local time_stamp = os.time({year = curYear, month = curMonth, day = data.d, hour=0, min=0, sec=0})
        local clientData = KeepWorkItemManager.GetClientData(gsid) or {};
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
    KeepWorkItemManager.SetClientData(gsid, clientData, function()
        print("save success")
    end,function (err, msg, data)
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
    if not Ydata[year] or not Ydata[year].ms[month] then
        return {}
    end
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
            local tianshu = os.date("%d",os.time({year=i,month=j,day=0}))
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

function RedSummerCampCourseScheduling.CheckCanLearn(name)
    local isCanlearn = RedSummerCampCourseScheduling.auths[name]
    return isCanlearn
end

function RedSummerCampCourseScheduling.OnClickLesson(name)
    -- if not RedSummerCampCourseScheduling.CheckCanLearn(name) then
    --     local strTip = "你暂时没有该课程的访问权限，请联系客服或使用对应的激活码。"
    --     _guihelper.MessageBox(strTip,nil,_guihelper.MessageBoxButtons.OK_CustomLabel,nil,"script/apps/Aries/Creator/Game/GUI/DefaultMessageBox.lesson.html")
    --     return
    -- end
    curSelectLesson = name
    local course_data = RedSummerCampCourseScheduling.GetCouseDataByName(curSelectLesson) 
    RedSummerCampCourseScheduling.HideTip()
    if course_data then
        RedSummerCampCourseScheduling.ShowPageByCourseData(course_data)
    else
        RedSummerCampCourseScheduling.SaveLessonHistroy()
        RedSummerCampPPtPage.Show(curSelectLesson)
    end
    RedSummerCampCourseScheduling.RefreshPage()
end

function RedSummerCampCourseScheduling.getTimeStampByString(timeStr)
    local patt = "(%d+)%D(%d+)%D(%d+)%s+(%d+)%D(%d+)"
    local y,m,d,h,min = string.match(timeStr,patt)
    local time_stamp = os.time({year = tonumber(y), month = tonumber(m), day = tonumber(d), hour=tonumber(h), min=tonumber(min), sec=0})
    return time_stamp
end

local function OpenPPTByLessonAuth(config,courseData,pptIndex,server_index)
    if config then
        local server_time_stamp = QuestAction.GetServerTime()
        local sectionAuths = {}
        local num = #config
        for i=1,num do
            local timeStamp = tonumber(RedSummerCampCourseScheduling.getTimeStampByString(config[i].time))
            if timeStamp and timeStamp <= tonumber(server_time_stamp) then
                local server_index = config[i].index - 2
                sectionAuths[#sectionAuths + 1] = {courseId = courseData.id,index = server_index,ppt_index = config[i].index}
            end
        end
        sectionAuths.lessonCfg = config
        courseData.sectionAuths = sectionAuths
    end
    local course_auth = courseData.auth
    local section_auth = false
    if System.options.isDevMode then
		print("index===========",pptIndex,server_index,server_time_stamp)
        echo(courseData.sectionAuths)
        echo(config)
	end
    
    if courseData.sectionAuths then
        for k,v in pairs(courseData.sectionAuths) do
            if (server_index and v.index == server_index) or  (pptIndex and v.ppt_index == pptIndex) then
                section_auth = true
                break
            end
        end
    end
    RedSummerCampCourseScheduling.HideTip()
    if not course_auth then
        local strTip =  L"你暂时没有该课程的访问权限，请联系客服或使用对应的激活码。" 
        _guihelper.MessageBox(strTip,nil,_guihelper.MessageBoxButtons.OK_CustomLabel,nil,"script/apps/Aries/Creator/Game/GUI/DefaultMessageBox.lesson.html")
        return 
    end
    if not section_auth and pptIndex and pptIndex > 1 then
        local strTip = L"课程暂未解锁，请先学习已经解锁的内容吧！"
        _guihelper.MessageBox(strTip,nil,_guihelper.MessageBoxButtons.OK_CustomLabel,nil,"script/apps/Aries/Creator/Game/GUI/DefaultMessageBox.lesson.html")
        RedSummerCampPPtPage.Show(courseData,1)
        return 
    end
    RedSummerCampPPtPage.Show(courseData,pptIndex,nil, server_index)
    
end

function RedSummerCampCourseScheduling.ShowCoursePageWhenTutorial(courseData,pptIndex,is_show_exit_bt, server_index)
    local EmailManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Email/EmailManager.lua");
    local courseConfig = EmailManager.FindCourseDataByCode(courseData.code)
    if type(courseConfig) == "table" then
        local extraCfg = EmailManager.GetExtraConfig()
        local courseConfig = EmailManager.FindCourseDataByCode(courseData.code)
        if courseConfig then
            OpenPPTByLessonAuth(courseConfig.course_data,courseData,pptIndex,server_index)
            return
        end
        if extraCfg then
            local tutorial_config = extraCfg.tutorial_config
            if tutorial_config then
                local lessonCfg = tutorial_config[courseData.code]
                OpenPPTByLessonAuth(lessonCfg,courseData,pptIndex,server_index)
            end
        else
            keepwork.good.good_info({
				router_params = {
					gsId = 12002,
				}
			},function(err, msg, data)
				if err == 200 then
					extraCfg = data.data.extra  
					EmailManager.SetExtraConfig(extraCfg)
                    local tutorial_config = extraCfg.tutorial_config
                    if tutorial_config then
                        local lessonCfg = tutorial_config[courseData.code]
                        OpenPPTByLessonAuth(lessonCfg,courseData,pptIndex,server_index)
                    end
				end
			end) 
        end
        return
    end
end

-- { { courseId=68, id=6078, index=0, name="课前准备课" } },
function RedSummerCampCourseScheduling.ShowPageByCourseData(courseData,pptIndex,is_show_exit_bt, server_index)
    if not GameLogic.GetFilters():apply_filters('is_signed_in') then
        return
    end
    if not courseData or type(courseData) ~= "table" then
        return 
    end
    curSelectLesson = courseData.code
    RedSummerCampCourseScheduling.SaveLessonHistroy()
    local EmailManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Email/EmailManager.lua");
    local courseConfig = EmailManager.FindCourseDataByCode(courseData.code)
    courseData.timeRules = RedSummerCampCourseScheduling.GetTimeRuleByName(courseData.code)
    courseData.sectionAuths = nil
    if type(courseConfig) == "table" and type(courseConfig.course_data) == "table" and #courseConfig.course_data > 0 then
        RedSummerCampCourseScheduling.ShowCoursePageWhenTutorial(courseData,pptIndex,is_show_exit_bt, server_index)
        return
    end
    RedSummerCampCourseScheduling.OpenNormalCourse(courseData,pptIndex,is_show_exit_bt, server_index)
end

function RedSummerCampCourseScheduling.OpenNormalCourse(courseData,pptIndex,is_show_exit_bt, server_index)
    keepwork.courses.getCourseSectionAuths({
        courseId = courseData.id
    },function(err, msg, data)
        -- print("err=============",err)
        -- echo(data,true)
        if err == 200 then
            courseData.sectionAuths = (data and data.data and #data.data > 0) and data.data or {}
        end
        -- echo(courseData.sectionAuths,true)
        if server_index then
            local course_auth = courseData.auth
            local section_auth = false

            if courseData.sectionAuths then
                for k,v in pairs(courseData.sectionAuths) do
                    if v.index == server_index then
                        section_auth = true
                        break
                    end
                end
            end
            if not course_auth then
                local strTip =  L"你暂时没有该课程的访问权限，请联系客服或使用对应的激活码。" 
                _guihelper.MessageBox(strTip,nil,_guihelper.MessageBoxButtons.OK_CustomLabel,nil,"script/apps/Aries/Creator/Game/GUI/DefaultMessageBox.lesson.html")
                return 
            end
            if not section_auth then
                local strTip = L"课程暂未解锁，请先学习已经解锁的内容吧！"
                _guihelper.MessageBox(strTip,nil,_guihelper.MessageBoxButtons.OK_CustomLabel,nil,"script/apps/Aries/Creator/Game/GUI/DefaultMessageBox.lesson.html")
                return 
            end
        end
        -- print("server_index=======",server_index)
        -- echo(courseData,true)
        RedSummerCampCourseScheduling.HideTip()
        RedSummerCampPPtPage.Show(courseData,pptIndex,is_show_exit_bt, server_index)
    end)
end

function RedSummerCampCourseScheduling.ShowPPTPage(code,index,is_show_exit_bt,serverIndex)
    if not code then
        return 
    end
    RedSummerCampCourseScheduling.AuthLessonV2(function()
        local course_data = RedSummerCampCourseScheduling.GetCouseDataByName(code)
        local data = course_data ~= nil and course_data or code			
        RedSummerCampCourseScheduling.ShowPageByCourseData(data,index,is_show_exit_bt,serverIndex)
    end)
end

function RedSummerCampCourseScheduling.ShowPPTPageById(courseId,serverIndex)
    if not courseId then
        return 
    end
    RedSummerCampCourseScheduling.AuthLessonV2(function()
        local course_data = RedSummerCampCourseScheduling.GetCouseDataById(courseId)
        RedSummerCampCourseScheduling.ShowPageByCourseData(course_data,nil,nil,serverIndex)
    end)
end

function RedSummerCampCourseScheduling.GetTimeRuleByName(name)
    if RedSummerCampCourseScheduling.my_lessonCnf then
        for k,v in pairs(RedSummerCampCourseScheduling.my_lessonCnf) do
            if v.code == name then
                return v.timeRules
            end
        end
    end
end

function RedSummerCampCourseScheduling.GetCouseDataByName(ppt_name)
    for i=1,#RedSummerCampCourseScheduling.lessonCnf do
        if RedSummerCampCourseScheduling.lessonCnf[i].code == ppt_name  then
            return RedSummerCampCourseScheduling.lessonCnf[i]
        end
    end
end

function RedSummerCampCourseScheduling.GetCouseDataById(id)
    for i=1,#RedSummerCampCourseScheduling.lessonCnf do
        if RedSummerCampCourseScheduling.lessonCnf[i].id == id  then
            return RedSummerCampCourseScheduling.lessonCnf[i]
        end
    end
end

function RedSummerCampCourseScheduling.SaveLessonHistroy()
    local keys = GameLogic.GetPlayerController():LoadRemoteData(RedSummerCampCourseScheduling.GetSaveKey(),{})
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
    GameLogic.GetPlayerController():SaveRemoteData(RedSummerCampCourseScheduling.GetSaveKey(),keys,true);
end

function RedSummerCampCourseScheduling.IsLearn(key)
    if RedSummerCampCourseScheduling.m_select_index ~= 1 then
        return false
    end
    local keys = GameLogic.GetPlayerController():LoadRemoteData(RedSummerCampCourseScheduling.GetSaveKey(),{});
    if keys and #keys > 0 then
        for i=1,#keys do
            if keys[i] == key then
                return true
            end
        end
    end
    return false
end

local function GetMyLessonClass()
    RedSummerCampCourseScheduling.show_lesson_classes = commonlib.filter(RedSummerCampCourseScheduling.show_lesson_classes,function(tab)
        return tab and tab.sn == 100
    end)
end

function RedSummerCampCourseScheduling.UpdateMyLessonAfterLearn()
    if System.options.isChannel_430 then
        GetMyLessonClass()
    end
    local keys = GameLogic.GetPlayerController():LoadRemoteData(RedSummerCampCourseScheduling.GetSaveKey(),{});
    local startIndex = 1
    local learnNum = RedSummerCampCourseScheduling.my_lessonCnf and #RedSummerCampCourseScheduling.my_lessonCnf or 0
    if keys and #keys > 0 and learnNum > 0 then
        for i=1,#keys do
            local tempKey = keys[i]
            for index,v in ipairs(RedSummerCampCourseScheduling.my_lessonCnf) do
                if v.code == tempKey and i ~= index then
                    local temp = RedSummerCampCourseScheduling.my_lessonCnf[index] 
                    RedSummerCampCourseScheduling.my_lessonCnf[index]   = RedSummerCampCourseScheduling.my_lessonCnf[i]
                    RedSummerCampCourseScheduling.my_lessonCnf[i] = temp
                    break
                end
            end
        end
        if RedSummerCampCourseScheduling.show_lesson_classes and RedSummerCampCourseScheduling.show_lesson_classes[1] then
            RedSummerCampCourseScheduling.show_lesson_classes[1].courses = commonlib.copy(RedSummerCampCourseScheduling.my_lessonCnf)
            if RedSummerCampCourseScheduling.m_select_index == 1 then
                RedSummerCampCourseScheduling.show_lesson_list = commonlib.copy(RedSummerCampCourseScheduling.my_lessonCnf)
            end
        end
    end
    
    if System.options.isChannel_430 then
        RedSummerCampCourseScheduling.show_lesson_list = commonlib.filter(RedSummerCampCourseScheduling.show_lesson_list, function (class)
            return RedSummerCampCourseScheduling.CheckCanLearn(class.code)
        end)
	end

    --[[reservation_experiencer
        3D_tiyanke_user
        tsyyz_test_user]]
    --根据pptcode做课程隔离
    local isHaveTutorial = false
    local courses = {
        -- ["yyz_course"] = true,
        -- ["prepare_course"] = true,
        -- ["3D_tiyanke"]=true,
        -- ["tsyyz_test"] = true
    }
    local EmailManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Email/EmailManager.lua");
    local courseEvalution =  EmailManager.GetCourseValidationCfg()
    local courseConfig = courseEvalution and courseEvalution.course_config or {}
    local num =  #courseConfig
    local role = {}

    for i = 1,num do
        local curRoleCourse = courseConfig[i] or {}
        for j = 1,#curRoleCourse do
            if not courses[curRoleCourse[j].course_name] then
                courses[curRoleCourse[j].course_name] = true
            end
            role[#role + 1] = curRoleCourse[j].role_name
        end
    end
    local tempCourse = {}
    for k,v in pairs(RedSummerCampCourseScheduling.my_lessonCnf) do
        if courses[v.code] then
            tempCourse[#tempCourse + 1] = v
        end
    end
    -- echo(role)
    -- echo(RedSummerCampCourseScheduling.UserRoleList,true)
    RedSummerCampCourseScheduling.UserRoleList = RedSummerCampCourseScheduling.UserRoleList or {}
    local data =RedSummerCampCourseScheduling.UserRoleList["7_days_experience"] or RedSummerCampCourseScheduling.UserRoleList["tsyyz_test_user"]
    for i = 1,#role do
        data = data or RedSummerCampCourseScheduling.UserRoleList[role[i]]
    end
    isHaveTutorial = data ~= nil and System.options.channelId_tutorial
    if isHaveTutorial then
        -- echo(RedSummerCampCourseScheduling.show_lesson_classes,true)
        -- print("dddddddddddddddddd")
        -- echo(RedSummerCampCourseScheduling.my_lessonCnf,true)
        GetMyLessonClass()
        RedSummerCampCourseScheduling.m_select_index = 1
        RedSummerCampCourseScheduling.show_lesson_list = {}
        for i,v in ipairs(tempCourse) do
            RedSummerCampCourseScheduling.show_lesson_list[#RedSummerCampCourseScheduling.show_lesson_list + 1] = v
        end
        if System.options.isDevMode then
            print("dddddddddddddddddd")
            echo(RedSummerCampCourseScheduling.show_lesson_list,true)
        end
        return 
    end
    if not isHaveTutorial and System.options.channelId_tutorial then
        GetMyLessonClass()
        RedSummerCampCourseScheduling.m_select_index = 1
        RedSummerCampCourseScheduling.show_lesson_list = {}
    end
end

function RedSummerCampCourseScheduling.LoadUserRoles(callbackFunc)
    local function open()
        RedSummerCampCourseScheduling.UserRoleList = {}
        local timeStamp = QuestAction.GetServerTime()
        keepwork.user.roles({},function(err, msg, data)
            if(err == 200 and data and #data > 0)then
                for key, v in pairs(data) do
                    if v and v.userRoles then
                        if v.userRoles.deadline then
                            local deadLine = commonlib.timehelp.GetTimeStampByDateTime(v.userRoles.deadline)
                            if timeStamp < deadLine then
                                RedSummerCampCourseScheduling.UserRoleList[v.name] = v
                            end
                        else
                            RedSummerCampCourseScheduling.UserRoleList[v.name] = v
                        end
                    end
                end
            end
            if type(callbackFunc) == "function" then
                callbackFunc()
            end
        end)
    end

    local EmailManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Email/EmailManager.lua");
    local extra = EmailManager.GetExtraConfig()
    if not extra then
        local Email = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Email/Email.lua");
        keepwork.good.good_info({
            router_params = {
                gsId = 12002,
            }
        },function(err, msg, data)
            if err == 200 then
                Email.SetGoodInfo(data,function()
                    open()
                end)
            end
        end)  
        return
    end
    open()
end 

function RedSummerCampCourseScheduling.SearchLesson(searchKey)
    if searchKey and searchKey ~= "" then
        RedSummerCampCourseScheduling.m_strSearchKey = searchKey
    else
        RedSummerCampCourseScheduling.m_strSearchKey = nil
    end
    if RedSummerCampCourseScheduling.m_strSearchKey and RedSummerCampCourseScheduling.m_strSearchKey ~= "" then
        local temp = {}
        if #RedSummerCampCourseScheduling.show_lesson_list > 0 then
            for k,v in pairs(RedSummerCampCourseScheduling.show_lesson_list) do
                if RedSummerCampCourseScheduling.CheckFind(v.name,RedSummerCampCourseScheduling.m_strSearchKey) then
                    temp[#temp + 1] = v
                end
            end
        end
        if temp and #temp > 0 and page then
            -- echo(temp,true)
            page:CallMethod("lessonppt","SetDataSource", temp)
            page:CallMethod("lessonppt","DataBind")
            return 
        end
    end
    page:CallMethod("lessonppt","SetDataSource", RedSummerCampCourseScheduling.show_lesson_list)
    page:CallMethod("lessonppt","DataBind")
end

function RedSummerCampCourseScheduling.CheckFind(str1,str2)
    return string.find(str1,str2) or string.find(str1,string.lower(str2)) or string.find(str1,string.upper(str2))
end

function RedSummerCampCourseScheduling.ClosePage()
    if page then
        page:CloseWindow();
        page = nil
    end
    RedSummerCampCourseScheduling.HideTip()
end

function RedSummerCampCourseScheduling.IsVisible()
	return page~=nil
end


function RedSummerCampCourseScheduling.ShowCourseReferencePage()
    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCourseRefrencePage.html",
        name = "RedSummerCampCourseScheduling.ShowCourseReferencePage", 
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

function RedSummerCampCourseScheduling.ShowCourseHelpPage()
    local RedSummerCampCourseSchedulingHelp = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCourseSchedulingHelp.lua") 
    RedSummerCampCourseSchedulingHelp.ShowView()
end


-------------------------------------------
------------CourseSchedulingTip------------
-------------------------------------------
local containerName = "courseschedulingtip_container"
local container
local CourseSchedulingTip = {}
function CourseSchedulingTip.ShowTip(data)
    if not data then
        return
    end
    local tip = data ~= nil and  data.description or ""
    if not tip or tip == "" then
        return 
    end
    local page = "script/apps/Aries/Creator/Game/Tasks/Quest/QuestAiCourseToolTip.html?s="..tip
    if not container or not container:IsValid() then
        container = ParaUI.CreateUIObject("container", containerName, "_lt", 0, 0, 300, 500);
        container.background = "";
        container:GetAttributeObject():SetField("ClickThrough", true);
        container.zorder = 50001;
        container:AttachToRoot()
    end
    container:RemoveAll()
    container.visible = true;
    local page_tooltip = System.mcml.PageCtrl:new({url = page})
    page_tooltip.click_through = true
    page_tooltip:Create("_CourseMCMLPage_", container, "_fi", 0, 0, 0, 0);
    CourseSchedulingTip.UpdateTip()
end

function CourseSchedulingTip.UpdateTip()
    CourseSchedulingTip.tooltip_timer = CourseSchedulingTip.tooltip_timer or  commonlib.Timer:new({callbackFunc = function(timer)
		if container and container.visible and container:IsValid() then
            local x, y = ParaUI.GetMousePosition();
            container.x = x + 24
            container.y = y + 24
        end
	end});
	CourseSchedulingTip.tooltip_timer:Change(0,100);
end

function CourseSchedulingTip.HideTip()
    if container and container:IsValid() then
        container.visible = false
    end
    if CourseSchedulingTip.tooltip_timer then
        CourseSchedulingTip.tooltip_timer:Change()
    end
end

function RedSummerCampCourseScheduling.ShowTip(data)
    CourseSchedulingTip.ShowTip(data)
    if RedSummerCampCourseScheduling.delay_timer then
        RedSummerCampCourseScheduling.delay_timer:Change()
    end
    RedSummerCampCourseScheduling.delay_timer = commonlib.TimerManager.SetTimeout(function ()
        RedSummerCampCourseScheduling.HideTip()
    end,5000)
end

function RedSummerCampCourseScheduling.HideTip()
    CourseSchedulingTip.HideTip()
end

function RedSummerCampCourseScheduling.IsOpen()
	return page and page:IsVisible()
end

function RedSummerCampCourseScheduling.DS_classes()
    RedSummerCampCourseScheduling.classees_ds = RedSummerCampCourseScheduling.classees_ds or {}
    return RedSummerCampCourseScheduling.classees_ds
end

function RedSummerCampCourseScheduling.LoadClassList(callback)
    local ds = RedSummerCampCourseScheduling.DS_classes()
    if #ds>0 then
        if callback then
            callback(RedSummerCampCourseScheduling.classees_ds)
        end
        return
    end
    local _isTeacher = KeepWorkItemManager.IsTeacher()
    keepwork.userclass.getclasses({
        roleId = _isTeacher and 2 or nil
    },function(err,msg,data)
        if err~=200 then
            if callback then
                callback({})
            end
            return
        end
        -- print("1111111err") echo(err)
        -- print("msg") echo(msg)
        -- print("data") echo(data,true)
        if data and type(data.data)=="table" then
            RedSummerCampCourseScheduling.classees_ds = data.data
            if page then
                page:Refresh(0)
            end
            if callback then
                callback(RedSummerCampCourseScheduling.classees_ds)
            end
        end
    end)

    GameLogic.GetFilters():add_filter("on_start_login", function()
        RedSummerCampCourseScheduling.classees_ds = {}
        ClassSchedule.clear()
    end);
end

--是否有未结业班级
--orgType: 1.试用 2.正式 3.受代理管辖的机构 4.学校
function RedSummerCampCourseScheduling.CheckHasUnGraduationClasses(callback,orgType)
    orgType = orgType or 4
    RedSummerCampCourseScheduling.LoadClassList(function(ds)
        for k,v in pairs(ds) do
            if v.status==1 and (v.org==nil or v.org.type==orgType) then
                callback(true)
                return;
            end
        end
        callback(false)
    end)    
end

function RedSummerCampCourseScheduling.GetClassName(index)
    local info = RedSummerCampCourseScheduling.classees_ds[index]
    local str = info.name or ""
    if info.status==3 then
        str = str.."(已结业)"
    end
    return str
end

function RedSummerCampCourseScheduling.OnToggleClasses(name, value)

end

RedSummerCampCourseScheduling._isExpland = false --是否展开
function RedSummerCampCourseScheduling.OnClickExpandAllClass()
    RedSummerCampCourseScheduling._isExpland = not RedSummerCampCourseScheduling._isExpland
    if RedSummerCampCourseScheduling._isExpland then
    else
    end
    if page then
        page:Refresh(0)
    end
end

function RedSummerCampCourseScheduling.OnClickSelectClass(name)
    local idx = tonumber(name)
    local info = RedSummerCampCourseScheduling.classees_ds[idx]
    RedSummerCampCourseScheduling.curClassName = info.name
    ClassSchedule.SetClassInfo(info)

    RedSummerCampCourseScheduling.OnClickExpandAllClass()
    RedSummerCampCourseScheduling.SetScheduleVisible(true)
end

function RedSummerCampCourseScheduling.SetScheduleVisible(bool)
    RedSummerCampCourseScheduling.isShowSchedule = bool
    if not bool then
        RedSummerCampCourseScheduling.curClassName = nil
    end
    if not page then
        return
    end
    local schedule_contentframe = ParaUI.GetUIObject("schedule_contentframe")
    if schedule_contentframe.visible ~= bool then
        page:Refresh(0)
    end
end

function RedSummerCampCourseScheduling.OnClickAddClass()
    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampAddClassByInviteCode.html",
        name = "RedSummerCampCourseScheduling.RedSummerCampAddClassByInviteCode", 
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

function RedSummerCampCourseScheduling.OnCommitAddClass(_page,code,callback)
    keepwork.userclass.joinclass({
        code = code
    },function(err, msg, data)
        if err==400 then
            if(type(data) == "string") then
                data = commonlib.Json.Decode(data) or data;
            end
            if data and data.message then
                GameLogic.AddBBS(nil,data.message,nil,"255 0 0")
            else
                GameLogic.AddBBS(nil,L"加入班级失败",nil,"255 0 0")
            end

            if _page then
                _page:CloseWindow()
            end
            return
        end
        -- print("",commonlib.debugstack())
        if data.data then
            if data.data.orgId then
                GameLogic.AddBBS(nil,L"加入班级成功")
            end
            local classInfo = data.data.classInfo
            if classInfo then
                classInfo.classId = classInfo.classId or classInfo.id
                table.insert(RedSummerCampCourseScheduling.classees_ds,classInfo)
                -- print("班级：")
                -- echo(RedSummerCampCourseScheduling.classees_ds)
                if page then
                    page:Refresh(0)
                end
            else
                RedSummerCampCourseScheduling.LoadClassList()
            end
            print("--------加入成功")
            -- echo(classInfo)
            ClassSchedule.SetClassInfo(classInfo)
            if callback then
                callback(classInfo)
            end
        end

        if _page then
            _page:CloseWindow()
        end
    end)
end

function RedSummerCampCourseScheduling.ReprotErrorData(key,data)
    -- 上报
    NPL.load("(gl)script/apps/Aries/Creator/Game/Common/ParacraftDebug.lua");
    local ParacraftDebug = commonlib.gettable("MyCompany.Aries.Game.Common.ParacraftDebug");
    ParacraftDebug:SendErrorLog("DevDebugLog", {
        desc = "lesson data err"..(key or ""),
        errorMessage = commonlib.serialize_compact({data = data}) or "",
        debugTag = "RedSummerCampCourseScheduling",
        stackInfo = commonlib.debugstack(),
    })
end