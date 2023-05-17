--[[
Title: UserPermission
Author(s):  ygy
CreateDate: 2022.02.14
ModifyDate: 2022.02.14
Desc: 
use the lib:
------------------------------------------------------------
local UserPermission = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/UserPermission.lua");
------------------------------------------------------------
]]

local UserPermission = NPL.export()
local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");

local CheckTypeToDesc = {
    click_code_block = "使用代码方块",
    click_cad_block = "使用CAD方块",
    click_movie_block = "使用电影方块",
    click_save_bmax = "使用Bmax功能",
}

local CheckTypeToPermission = {
    click_code_block = "vip_code_block",
    click_cad_block = "vip_cad_block",
    click_movie_block = "vip_movie_block",
    click_save_bmax = "vip_bmax_save",
}

-- 特殊身份
local SpecialSchoolRoleList = {
    ["vip_school_student"] = 1,
    ["jiangxi_SchoolCourses"] = 1,
}

local TimeRuleDateType = {
    everyday = 0,
    schoolday = 1,
    holiday = 2,
}

local UserRoleList = {}
local UserPermissionsList = {}
local VipSchoolLimit  ={}

-- 检测是否特殊身份 (vip, school_admin, school_teacher, school_student, org_school)
function UserPermission.IsSpecialIdentity()
    if System.options.channelId_431 then
        return false
    end
    local check_role_list = {
        "vip","school_admin","school_teacher","school_student","org_school"
    }

    for index, v in ipairs(check_role_list) do
        if UserPermission.GetRoleData(v) then
            return true
        end
    end

    if vip_school_student then
        -- body
    end

    return false
end

function UserPermission.GetPermissionData(check_type)
    local permission_type = CheckTypeToPermission[check_type] or check_type
    local permission_data = UserPermissionsList[permission_type]

    return permission_data
end

function UserPermission.CheckHasPermission(check_type)
    if (true) then return true end -- bugID 1003014 1003013 1003012 1003011

    if (System.options.channelId_431) then
        return true
    end

    local permission_data = UserPermission.GetPermissionData(check_type);

    if (not permission_data) then
        return false;
    end

    local time_rules = permission_data.timeRules;

    if (UserPermission.CheckTimeRules(time_rules)) then
        return true;
    end

    return false
end

-- 检查用户是否有特殊身份 vip学校学生 江西某学校等

function UserPermission.CheckIsSpecialSchool()
    if System.options.channelId_431 then
        return false
    end
    for key, value in pairs(SpecialSchoolRoleList) do
        if UserPermission.GetRoleData(key) then
            return true
        end
    end

    return false
end

function UserPermission.GetVipSchoolLimitTime()
    local time_rule = UserPermission.GetVipSchoolTimeRule()
    
    if time_rule.start_time_t and time_rule.end_time_t then
        return time_rule.start_time_t, time_rule.end_time_t
    end

    local start_hour,start_min = 7,30
    local end_hour,end_min = 18,30

    return {start_hour = start_hour,start_min = start_min}, {end_hour = end_hour,end_min = end_min}
end

-- 获取当前所属学校的时间规则
-- {
--     end_time_t={ end_hour=18, end_min=30 },
--     start_time_t={ start_hour=7, start_min=0 },
--     week_list={ 2, 3, 4, 5 } 
-- } 
function UserPermission.GetVipSchoolTimeRule()
    local time_rule = VipSchoolLimit.default

    local school_data = KeepWorkItemManager.GetSchool()
    local school_id = school_data and school_data.id or 0
    -- 加多一步 确保取到schooid
    if not school_id or school_id == 0 then
        local profile = KeepWorkItemManager.GetProfile()
        school_id = profile and profile.schoolId or 0
    end

    if school_id and school_id > 0 then
        local school_time_rule = VipSchoolLimit[school_id] or VipSchoolLimit[tostring(school_id)]
        if school_time_rule then
            time_rule = school_time_rule    
        end
    end
    
    return time_rule
end

-- 检测是否上课的日子(周几)
function UserPermission.IsInVipSchoolCourseDay()
    local time_rule = UserPermission.GetVipSchoolTimeRule()

    if not time_rule.week_list then
        if time_rule.start_hour then
            return true
        end
        return false
    end

    local cur_time_stamp = QuestAction.GetServerTime()
    local week_day = commonlib.timehelp.GetWeekDay(cur_time_stamp)
    for key, v in pairs(time_rule.week_list) do
        if week_day == v then
            return true
        end
    end
    return false
end

-- 检测是否在时间规则定义的时间内
function UserPermission.CheckIsInTimeRule(time_rule)
    if System.options.channelId_431 then
        return true
    end
    local start_time_t, end_time_t = UserPermission.GetTimeRuleStartEndTimeT(time_rule)
    if not start_time_t then
        return
    end

    local cur_time_stamp = QuestAction.GetServerTime()
    local start_hour,start_min = start_time_t.start_hour, start_time_t.start_min
    local end_hour,end_min = end_time_t.end_hour, end_time_t.end_min

    local today_weehours = commonlib.timehelp.GetWeeHoursTimeStamp(cur_time_stamp)
    local limit_time_stamp = today_weehours + start_hour * 60 * 60 + start_min * 60
    local limit_time_end_stamp = today_weehours + end_hour * 60 * 60 + end_min * 60
    if cur_time_stamp >= limit_time_stamp and cur_time_stamp <= limit_time_end_stamp then
        return true
    end

    return false
end

function UserPermission.GetTimeRuleStartEndTimeT(time_rule)
    if not time_rule then
        return
    end

    if not time_rule.startTime then
        time_rule.startTime = "0:0"
    end

    if not time_rule.endTime then
        time_rule.endTime = "23:59"
    end

    if time_rule.start_time_t == nil then
        local start_hour,start_min = string.match(time_rule.startTime, "(%d+):(%d+)");
        time_rule.start_time_t = {start_hour = tonumber(start_hour), start_min = tonumber(start_min)}
    end

    if time_rule.end_time_t == nil then
        local end_hour,end_min = string.match(time_rule.endTime, "(%d+):(%d+)");
        time_rule.end_time_t = {end_hour = tonumber(end_hour), end_min = tonumber(end_min)}
    end

    return time_rule.start_time_t, time_rule.end_time_t
end

-- 检测是否上课的时间
function UserPermission.IsInVipSchoolCourseTime()
    if System.options.channelId_431 then
        return true
    end
    local cur_time_stamp = QuestAction.GetServerTime()
    local start_time_t, end_time_t = UserPermission.GetVipSchoolLimitTime()
    local start_hour,start_min = start_time_t.start_hour, start_time_t.start_min
    local end_hour,end_min = end_time_t.end_hour, end_time_t.end_min

    local today_weehours = commonlib.timehelp.GetWeeHoursTimeStamp(cur_time_stamp)
    local limit_time_stamp = today_weehours + start_hour * 60 * 60 + start_min * 60
    local limit_time_end_stamp = today_weehours + end_hour * 60 * 60 + end_min * 60
    if cur_time_stamp >= limit_time_stamp and cur_time_stamp <= limit_time_end_stamp then
        return true
    end

    return false
end

function UserPermission.CheckCanEditBlock(check_type, callbackFunc)
	local function InvokeCallBack_()
		if (callbackFunc) then
			callbackFunc();
		end
	end

    -- if not System.options.isDevMode then
    --     if cb then
    --         cb()
    --     end
    --     return
    -- end

    if (System.options.channelId_431) then
        InvokeCallBack_();
        return;
    end

    -- 宏示教的情况允许
    if (GameLogic.Macros:IsPlaying()) then
        InvokeCallBack_();
        return;
    end

    -- 白名单世界
    local world_data = QuestAction.GetCurWorldData();

    if (world_data and (world_data.isFreeWorld or 0) ~= 0) then
		InvokeCallBack_();
        return;
    end

    -- 没登录的话 要求登录
	if (not GameLogic.GetFilters():apply_filters('is_signed_in')) then
		if (System.options.cmdline_world) then
			-- tricky: this will allow offline editing for local editing. 
			InvokeCallBack_();
			return;
		end

		GameLogic.GetFilters():apply_filters('check_signed_in', "请先登录");

		return;
	end

    if (GameLogic.IsVip()) then
        InvokeCallBack_();
        return;
    end

    -- "您所在的学校免费使用时段为周一到周五（9:00-18:00）"
    -- "可联系学校老师解锁该功能或开通"

    local has_permission = UserPermission.CheckHasPermission(check_type);

    if has_permission then
        InvokeCallBack_();
    else
        local permission_type = CheckTypeToPermission[check_type];
        local cache_policy = "access plus 20 second";

        keepwork.permissions.single({
			router_params = {
				featureNames = permission_type,
			},
            cache_policy = cache_policy,
        },function(err, msg, data)
            if err == 200 then
                for k, v in pairs(data) do
                    local key = v.name == v.enName and v.name or v.enName;
                    UserPermissionsList[key] = v;
                end

                if UserPermission.CheckHasPermission(check_type) then
                    InvokeCallBack_();
                else
                    local desc = CheckTypeToDesc[check_type];
                    local ContactTeacherAlert = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ContactTeacher/ContactTeacherAlert.lua");
                    ContactTeacherAlert.Show(check_type, desc);
                end
            end
        end) 
    end
    
    --return has_permission
end

--[[ 
    获取身份数据
    identity_name
        :vip                    vip用户
        :school_admin           管理员
        :school_teacher         机构教师
        :school_student         机构学员
        :org_school             430合作校
        :vip_school_student     一般合作校
]]--
function UserPermission.GetRoleData(identity_name)
    if not UserRoleList then
        return false
    end

    return UserRoleList[identity_name]
end

-- 获取用户角色信息
function UserPermission.LoadUserRoles()
    keepwork.user.roles({},function(err, msg, data)
        if(err ~= 200)then
            return
        end
        if(data and #data > 0)then
            UserRoleList = {}
            for key, v in pairs(data) do
                UserRoleList[v.name] = v

                if v.name == "vip_school_student" then
                    local SetIsVipSchool = Mod.WorldShare.Store:Action('user/SetIsVipSchool')
                    if SetIsVipSchool then
                        SetIsVipSchool(true)
                    end
                end
            end
        end
    end)

    UserPermissionsList = {}
    -- 获取是否有权限
    keepwork.permissions.all({
    },function(err, msg, data)
        if err == 200 then
            -- print("keepwork.permissions.all>>>>>>>>>>>>>>>>>")
            -- echo(data, true)
            for k, v in pairs(data) do
                local key = v.name == v.enName and v.name or v.enName
                UserPermissionsList[key] = v
            end
            GameLogic.GetFilters():apply_filters("on_permission_load");
        end
    end) 

    local requery_data = {}
    if System.options.isDevMode then
        local server_time = QuestAction.GetServerTime()
        local year = tonumber(os.date("%Y", server_time))	
        local month = tonumber(os.date("%m", server_time))
        local day = tonumber(os.date("%d", server_time))
        
        requery_data.date = string.format("%d-%d-%d", year, month, day)
        -- requery_data.date ="2022-01-01"
    end
    keepwork.date.isholiday(requery_data,function(err, msg, data)
        -- print("keepwork.date.isholiday>>>>>>>>>>>>>>>>>")
        -- echo(data, true)
        if err == 200 then
            UserPermission.IsTodayHoliday = data.isHoliday
        end
    end)
    UserPermission.InitVipSchoolLimit()
end

-- 处理校本课权限相关
-- VipSchoolLimit = {
--     ["10999"]={
--       end_time_t={ end_hour=20, end_min=0 },
--       start_time_t={ start_hour=9, start_min=0 },
--       week_list={ 1, 2, 3, 4, 5 } 
--     },
--     default={
--       end_time_t={ end_hour=18, end_min=30 },
--       start_time_t={ start_hour=7, start_min=0 },
--       week_list={ 2, 3, 4, 5 } 
--     } 
--   }
function UserPermission.InitVipSchoolLimit()
    -- 配置的物品id
    local gsid = 12001
    local item = KeepWorkItemManager.GetItemTemplate(gsid) or {}

    local extra = item.extra

    if not extra.default then
        extra.default = { endTime="18:30", startTime="07:00", week="1_2_3_4_5"}
    end

    -- test
    -- extra.default = { endTime="18:30", startTime="07:00", week="2_3_4_5"}

    for k, time_rule in pairs(extra) do
        if time_rule.startTime and time_rule.endTime then
            local result = {}
            local start_hour,start_min = string.match(time_rule.startTime, "(%d+):(%d+)");
            local end_hour,end_min = string.match(time_rule.endTime, "(%d+):(%d+)");
            result = {
                start_time_t = {start_hour = tonumber(start_hour), start_min = tonumber(start_min)},
                end_time_t = {end_hour = tonumber(end_hour), end_min = tonumber(end_min)},
            }
    
            if time_rule.week then
                local week_list = commonlib.split(time_rule.week, "_")
                result.week_list = week_list
                for i, v in ipairs(result.week_list) do
                    result.week_list[i] = tonumber(v)
                end
            end
    
            VipSchoolLimit[k] = result
        end
    end
end

-- 获取用户角色信息
function UserPermission.ClearUserRoles()
    UserRoleList = {}
    UserPermissionsList = {}
end
-- 检测用户是否有某个权限
function UserPermission.CheckUserPermission(permission)
    if permission and UserPermissionsList[permission] then
        return true
    end
end

function UserPermission.GetUserPermissionsList()
    return UserPermissionsList
end

function UserPermission.GetTimeRuleDateTypeDesc(time_rule)
    if time_rule.dateType == TimeRuleDateType.everyday then
       return L"每天"
    end

    if time_rule.dateType == TimeRuleDateType.schoolday then
        return L"上学日"
    end

    if time_rule.dateType == TimeRuleDateType.holiday then
        return L"节假日"
    end


    return ""
end

function UserPermission.CheckTimeRules(time_rules)
    if not time_rules or #time_rules == 0 then
        return true
    end
    if #time_rules == 1 and time_rules[1].dateType == nil then
        return true
    end
    
    for key, time_rule in pairs(time_rules) do
    -- dateType 0 每天 1上学日 2节假日
        if time_rule.dateType == nil or time_rule.dateType == "" then
            time_rule.dateType = 0
        end
        
        time_rule.startTime = time_rule.startTime or "0:0"
        time_rule.endTime = time_rule.endTime or "23:59"


        -- return UserPermission.CheckIsInTimeRule(time_rule)
        if time_rule.dateType == TimeRuleDateType.everyday then
            if UserPermission.CheckIsInTimeRule(time_rule) then
                return true
            end
        end

        if time_rule.dateType == TimeRuleDateType.schoolday and not UserPermission.IsTodayHoliday then
            if UserPermission.CheckIsInTimeRule(time_rule) then
                return true
            end
        end

        if time_rule.dateType == TimeRuleDateType.holiday and UserPermission.IsTodayHoliday then
            if UserPermission.CheckIsInTimeRule(time_rule) then
                return true
            end
        end
    end
end