--[[
    Author: <pbb>
    Date: 2024/05/15
    Description: This script is used to create a community user birth date page.
    useLib:
        local UserBirthDate = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/Setting/UserBirthDate.lua")
        UserBirthDate.Show()
]]
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')

local UserBirthDate = NPL.export()
UserBirthDate.curYear = 2000
UserBirthDate.curMonth = 1
UserBirthDate.curDay = 1
local page
function UserBirthDate.OnInit()
    page = document:GetPageCtrl()
    page.OnCreate = UserBirthDate.OnCreate
end

function UserBirthDate.Show(bForceEdit)
    if (GameLogic.GetFilters():apply_filters('is_signed_in')) then
        UserBirthDate.ShowPage(bForceEdit)
        return;
    end

    GameLogic.GetFilters():apply_filters('check_signed_in', L"请先登录", function(result)
        if (result == true) then
            commonlib.TimerManager.SetTimeout(function()
                UserBirthDate.ShowPage(bForceEdit)
            end, 500)
        end
    end)
end

function UserBirthDate.OnCreate()
    if page then
		page:SetValue("days", tostring(UserBirthDate.curDay));
        page:SetValue("months", tostring(UserBirthDate.curMonth));
        page:SetValue("years", tostring(UserBirthDate.curYear));
	end
end

function UserBirthDate.RefreshPage()
    if page then
        page:Refresh(0.02)
    end
end

function UserBirthDate.ShowPage(bForceEdit)
    UserBirthDate.profile = nil
    KeepworkServiceSession:Profile(function(response)
        if not response then
            return
        end
        local userinfo = response.info
        if userinfo and userinfo.birthdate and userinfo.birthdate ~= '' and not bForceEdit then --如果设置了生日的不需要弹出
            return 
        end
        UserBirthDate.profile = response
        
        UserBirthDate.curYear = 2000
        UserBirthDate.curMonth = 1
        UserBirthDate.curDay = 1
        local params = {
            url = "script/apps/Aries/Creator/Game/Tasks/Community/Setting/UserBirthDate.html", 
            name = "UserBirthDate.ShowPage", 
            isShowTitleBar = false,
            DestroyOnClose = true,
            style = CommonCtrl.WindowFrame.ContainerStyle,
            allowDrag = false,
            zorder = 10,
            click_through = true,
            cancelShowAnimation = true,
            directPosition = true,
                align = "_fi",
                x = 0,
                y = 0,
                width = 0,
                height = 0,
        }
    
        System.App.Commands.Call("File.MCMLWindowFrame", params);
    end)
end

function UserBirthDate.OnClose()
    UserBirthDate.curYear = tonumber(os.date("%Y"))
    UserBirthDate.curMonth = tonumber(os.date("%m"))
    UserBirthDate.curDay = tonumber(os.date("%d"))
    if page then
        page:CloseWindow()
        page = nil
    end
end

function UserBirthDate.GetDays()
    local year = UserBirthDate.curYear
    local month = UserBirthDate.curMonth
    local days = {31,28,31,30,31,30,31,31,30,31,30,31}
    local dayNum = days[month]
    -- 处理闰年的情况，闰年2月有29天
    if month == 2 and ((year % 4 == 0 and year % 100 ~= 0) or year % 400 == 0) then
        dayNum = 29
    end
    local tempDays = {}
    for i = 1, dayNum do
        table.insert(tempDays, {text= tostring(i), value=tostring(i)})
    end
    return tempDays
end

function  UserBirthDate.OnSelectYear(name,value)
    local year = tonumber(value)
    if year then
        UserBirthDate.curYear = year
        UserBirthDate.RefreshPage()
    end
end

function  UserBirthDate.OnSelectMonth(name,value)
    local month = tonumber(value)
    if month then
        UserBirthDate.curMonth = month
        UserBirthDate.RefreshPage()
    end
end

function UserBirthDate.OnSelectDay(name,value)
    local day = tonumber(value)
    if day then
        UserBirthDate.curDay = day
        UserBirthDate.RefreshPage()
    end
end

function UserBirthDate.GetCurYear()
    return UserBirthDate.curYear
end

function UserBirthDate.GetCurMonth()
    return UserBirthDate.curMonth
end

function UserBirthDate.GetCurDay()
    return UserBirthDate.curDay
end

function UserBirthDate.SetBirthDate()
    if not UserBirthDate.profile then
        return
    end
    local year = UserBirthDate.curYear
    local month = UserBirthDate.curMonth
    local day = UserBirthDate.curDay
    local birthdate = year .. '-' .. month .. '-' .. day

    local info = UserBirthDate.profile.info or {}
    local user_id = UserBirthDate.profile.id or 0
    info.birthdate = birthdate --更新生日信息，当前服务端有bug，不会更新修改时间
    keepwork.user.setinfo({
        router_params = {id = user_id},
        info = info
    },function(err,msg,data)
        if err == 200 then
            UserBirthDate.OnClose()
            GameLogic.AddBBS("UserBirthDate",L"生日设置成功",3000,"0 255 0")
        else
            GameLogic.AddBBS("UserBirthDate",L"生日设置失败,请重试",3000,"255 0 0")
        end
    end)
end

