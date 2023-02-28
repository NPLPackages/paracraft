--[[
    author:{pbb}
    time:2022-04-14 10:33:51
    use lib:
    local LessonDock = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/LessonDock.lua") 
    LessonDock.ShowView()
]]

local LessonDock = NPL.export()
LessonDock.IsShow = false
function LessonDock.ShowView(bShow)
   if bShow == true then
        GameLogic.DockManager:ShowAllDock()
        if not LessonDock.IsShow then
            GameLogic.DockManager:ShowDockByKey("E_DOCK_LESSON")
            LessonDock.IsShow = true
            GameLogic:Connect("WorldUnloaded", LessonDock, LessonDock.OnWorldUnload, "UniqueConnection");
        end
   else
        GameLogic.DockManager:HideAllDock()
   end
end

function LessonDock.OnWorldUnload()
    LessonDock.IsShow = false
    GameLogic.DockManager:ShowAllDock()
end