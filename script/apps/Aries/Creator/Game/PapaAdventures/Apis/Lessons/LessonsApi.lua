--[[
Title: Papa Adventures Lessons Base API
Author(s):  big
Date:  2023.3.26
Place: Foshan
use the lib:
------------------------------------------------------------
local LessonsBaseApi = NPL.load("(gl)script/apps/Aries/Creator/Game/PapaAdventures/Apis/Lessons/BaseApi.lua");
------------------------------------------------------------
]]

local BaseRequestApi = NPL.load("(gl)Mod/WorldShare/api/BaseRequestApi.lua");

local LessonsApi = NPL.export();

local marketingRequest = BaseRequestApi:CreateRequest(BaseRequestApi.apis.marketing);

function LessonsApi:GetLessonDetail(id, success, error)
    marketingRequest:Get("/lessons/" .. id, nil, nil, success, error);
end

function LessonsApi:GetLessonSections(id, success, error)
    marketingRequest:Get("/sections/" .. id, nil, nil, success, error);
end

function LessonsApi:ScheduleUsers(scheduleId, report,projectId,success, error)
    local params = {
        scheduleId = scheduleId,
        status = 1,
        projectId = projectId,
        extra = {
            report = report,
        }
    };

    marketingRequest:Post("/scheduleUsers", params, nil, success, error);
end
