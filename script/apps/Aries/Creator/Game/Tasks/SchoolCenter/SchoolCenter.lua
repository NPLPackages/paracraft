--[[
Title: SchoolCenter
Author(s): yangguiyi
Date: 2021/6/2
Desc:  
Use Lib:
-------------------------------------------------------
local SchoolCenter = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SchoolCenter/SchoolCenter.lua")
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local SchoolCenter = NPL.export();

SchoolCenter.ReportList = {
    ["create.world.block"] = 0,
    ["create.world.code"] = 0,
    ["create.world.animation"] = 0,
}

function SchoolCenter.OnInt()
    GameLogic.GetFilters():add_filter("SchoolCenter.AddEvent", SchoolCenter.AddReportEvent);
    -- GameLogic.GetFilters():apply_filters("SchoolCenter.AddEvent", "create.world.block");
end

function SchoolCenter.AddReportEvent(action, num)
    num = num or 1
    if SchoolCenter.ReportList[action] == nil then
        return
    end

    SchoolCenter.ReportList[action] = SchoolCenter.ReportList[action] + num

    if SchoolCenter.Timer == nil then
		SchoolCenter.Timer = commonlib.Timer:new({callbackFunc = function(timer)
            SchoolCenter.ReportAllEvent()
		end})
		SchoolCenter.Timer:Change(0, 1000 * 1200);
    end
end

function SchoolCenter.ReportAllEvent()
    if not GameLogic.GetFilters():apply_filters('is_signed_in') then
        return
    end
    
    for k, v in pairs(SchoolCenter.ReportList) do
        if v and v > 0 then
            SchoolCenter.ReportEvent(k, v)
        end
    end
end

function SchoolCenter.ReportEvent(action, count)
    local profile = KeepWorkItemManager.GetProfile()
    local data = {
        userId = profile.id,
        count = count,
        beginAt = "",
        traceId = "",
    }
    keepwork.burieddata.sendSingleBuriedData({
        category 	= 'behavior',
        action 		= action,
        data 		= data
    },function(err, msg, data)
        -- print("oooooooooooooooooooooooooooo", err)
        -- echo(data, true)
        if err == 200 then
            SchoolCenter.ReportList[action] = SchoolCenter.ReportList[action] - count
        end
    end)
end

function SchoolCenter.OpenPage(show_callback)
    if not GameLogic.GetFilters():apply_filters('is_signed_in') then
        GameLogic.AddBBS(nil, L"请先登录", 3000, "255 0 0")
        return
    end

    local KeepworkServiceSchoolAndOrg = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/SchoolAndOrg.lua")
    KeepworkServiceSchoolAndOrg:GetUserAllSchools(function(data, err)
        -- if not data or not data.id then
        --     GameLogic.AddBBS(nil, L"请先加入学校", 3000, "255 0 0")
        --     return
        -- end
        keepwork.user.roles_in_campus({},function(err2, msg2, data2)
            if err2 == 200 then
                if data2.isTeacher then
                    page = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SchoolCenter/TeacherPage.lua")
            
                else
                    page = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SchoolCenter/StudentPage.lua")
                end
            
                page.show_callback = show_callback
                page.Show(data.id);
            end
        end)


    end)


end