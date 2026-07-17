--[[
    author:{pbb}
    time:2023-02-09 17:50:48
    uselib:
        local EducateProject = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Offline/Project/EducateProject.lua")
        EducateProject.ShowCreate()
        EducateProject.ShowPage()
]]
local Opus = NPL.load("(gl)Mod/WorldShare/cellar/Opus/Opus.lua")
local EducateProject = NPL.export()
local page,page_root
function EducateProject.OnInit()
    page = document:GetPageCtrl()
    if page then
        EducateProject.ShowCreate()
    end

end

function EducateProject.ShowCreate()
    if Opus and type(Opus.ShowCreate) == "function" then
        local width = 1132
        local height = 470
        local x = -510
        local y = -220
        Opus:ShowCreate(nil,width,height,x,y,true,-1)
    end
end

function EducateProject.CloseCreate()
    Opus:CloseOpus()
end

