--[[
Title: ContactTeacherAlert
Author(s): yangguiyi
Date: 2021/2/2
Desc:  
Use Lib:
-------------------------------------------------------
local ContactTeacherAlert = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ContactTeacher/ContactTeacherAlert.lua")
ContactTeacherAlert.Show();
--]]
local ContactTeacherAlert = NPL.export();
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local UserPermission = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/UserPermission.lua");
local server_time = 0
local page
function ContactTeacherAlert.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = ContactTeacherAlert.OnClosePage
end

function ContactTeacherAlert.Show(vip_remind_key, vip_remind_desc)
    if GameLogic.GetFilters():apply_filters('check_unavailable_before_open_vip')==true then
		return
	end
    ContactTeacherAlert.vip_remind_key = vip_remind_key
    ContactTeacherAlert.vip_remind_desc = vip_remind_desc
    ContactTeacherAlert.ShowView()
end

function ContactTeacherAlert.ClosePage()
   if page then
       page:CloseWindow()
       page = nil
   end
end

function ContactTeacherAlert.ShowView()
    if page and page:IsVisible() then
        return
    end
    ContactTeacherAlert.HandleData()

    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/ContactTeacher/ContactTeacherAlert.html",
        name = "ContactTeacherAlert.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 0,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,
        
        align = "_ct",
        x = -478/2,
        y = -266/2,
        width = 478,
        height = 266,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function ContactTeacherAlert.FreshView()
    local parent  = page:GetParentUIObject()
end

function ContactTeacherAlert.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
    ContactTeacherAlert.FreshView()
end

function ContactTeacherAlert.OnClosePage()
    ContactTeacherAlert.ClearData()
end

function ContactTeacherAlert.ClearData()
end

function ContactTeacherAlert.HandleData()
end

function ContactTeacherAlert.OnClickContactTeacher()
    local isVerified = GameLogic.GetFilters():apply_filters('store_get', 'user/isVerified');
    local hasJoinedSchool = GameLogic.GetFilters():apply_filters('store_get', 'user/hasJoinedSchool');
    if not isVerified or not hasJoinedSchool then
		GameLogic.GetFilters():apply_filters('cellar.certificate.show_certificate_notice_page', function()
			KeepWorkItemManager.LoadProfile(false, function()
			end)
		end)

        return
    end

    ContactTeacherAlert.ClosePage()
    local ContactTeacherPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ContactTeacher/ContactTeacherPage.lua")
    ContactTeacherPage.Show(ContactTeacherAlert.vip_remind_key, ContactTeacherAlert.vip_remind_desc);
end

function ContactTeacherAlert.OnClickBuyVip()
    ContactTeacherAlert.ClosePage()
    local VipPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/VipPage.lua");
    VipPage.ShowPage(ContactTeacherAlert.vip_remind_key, ContactTeacherAlert.vip_remind_desc);
end

function ContactTeacherAlert.GetVipLimitTimeDesc()
    local function get_num_str(number)
        if number >= 10 then
            return number
        end
    
        return "0" .. number
    end

    local permission_data = UserPermission.GetPermissionData(ContactTeacherAlert.vip_remind_key)
    if permission_data and permission_data.timeRules and permission_data.timeRules[1] then
        local time_rule = permission_data.timeRules[1]
        local start_time_t, end_time_t = UserPermission.GetTimeRuleStartEndTimeT(time_rule)
        if not start_time_t then
            return ""
        end

        local start_hour,start_min = get_num_str(start_time_t.start_hour), get_num_str(start_time_t.start_min)
        local end_hour,end_min = get_num_str(end_time_t.end_hour), get_num_str(end_time_t.end_min)
    
        local date_desc = UserPermission.GetTimeRuleDateTypeDesc(time_rule)
        -- local week_desc = ContactTeacherAlert.GetVipLimitWeekDesc()
        local desc = string.format("您所在的学校免费使用时段为%s（%s:%s-%s:%s）", date_desc, start_hour, start_min, end_hour, end_min)
        return desc
    end

    return ""
end

function ContactTeacherAlert.GetVipLimitWeekDesc()
    local time_rule = UserPermission.GetVipSchoolTimeRule()
    local week_desc = ""
    local week_list = time_rule.week_list
    if week_list then
        -- 先判断是否连续
        local is_continued = week_list[#week_list] == week_list[1] + #week_list - 1
        if is_continued then
            local start_day_desc = commonlib.NumberToString(week_list[1])
            local end_day_desc = commonlib.NumberToString(week_list[#week_list])
            week_desc = string.format("周%s到周%s", start_day_desc, end_day_desc)
            return week_desc
        end

        week_desc = "周"
        for i, v in ipairs(week_list) do
            week_desc = week_desc .. commonlib.NumberToString(v)

            if i ~= #week_list then
                week_desc = week_desc .. "、"
            end
        end
    end
    
    return week_desc
end

function ContactTeacherAlert.HasTimeRule()
    local permission_data = UserPermission.GetPermissionData(ContactTeacherAlert.vip_remind_key)
    return permission_data and permission_data.timeRules and permission_data.timeRules[1] and permission_data.timeRules[1].dateType ~= nil
end