--[[
    author:{pbb}
    time:2023-02-09 17:50:48
    uselib:
        local EducateProject = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Project/EducateProject.lua")
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
    EducateProject.GetUserWorldUsedSize()
end

function EducateProject.CloseCreate()
    Opus:CloseOpus()
end

function EducateProject.GetUserWorldUsedSize()
    keepwork.world.gettotalsize({},function(err,msg,data)
        if err == 200 and data then
            if System.options.isDevMode then
                print("err=========",err)
                echo(data,true)
            end
            local totalSize = tonumber(data.total) or 0 --总容量
            local surplus = tonumber(data.surplus) or 0 --剩余容量
            surplus = math.max(surplus,0)
            local use = tonumber(data.use) or 0 --使用容量
            if surplus then
                local objText = ParaUI.GetUIObject("project_memui")
                if objText:IsValid() then
                    objText.text = "剩余存档空间："..(math.floor((surplus/1024/1024)*10)/10).."MB"
                end
            end
        else
            local EducateMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/EducateMainPage.lua")
            EducateMainPage.LoginOutByErrToken(err)
        end
    end)
end

