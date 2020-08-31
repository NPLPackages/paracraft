--[[
Title: help function for Kp chat 
Author(s): leio
Date: 2020/8/13
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/KpChatHelper.lua");
local KpChatHelper = commonlib.gettable("MyCompany.Aries.Creator.ChatSystem.KpChatHelper");
-------------------------------------------------------
]]
local KpChatHelper = commonlib.gettable("MyCompany.Aries.Creator.ChatSystem.KpChatHelper");
function KpChatHelper.ShowUserInfo(username)
    if(not username)then
        return
    end
    local page = NPL.load("Mod/GeneralGameServerMod/App/ui/page.lua");
    if(page and page.ShowUserInfoPage)then
        page.ShowUserInfoPage({ username = username }); 
    end
end
