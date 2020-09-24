--[[
Title: UserComplainPage
Author(s): leio
Date: 2020/9/15
Desc:  
Use Lib:
-------------------------------------------------------
local UserComplainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/UserComplainPage.lua");
local input_msg = UserComplainPage.MakeProjectMsg(1001);
UserComplainPage.ShowPage(UserComplainPage.Types.PROJECT,input_msg);


local input_msg = UserComplainPage.MakeChatMsg(1,"test","aaaaaaaaaaaaa");
UserComplainPage.ShowPage(UserComplainPage.Types.CHAT,input_msg);
--]]

local UserComplainPage = NPL.export()
local page
UserComplainPage.radio_ds = {
    { label = L"假冒网站", key = 1, checked = true,},
    { label = L"传播病毒", key = 2, },
    { label = L"反动", key = 3, },
    { label = L"色情", key = 4, },
    { label = L"暴力", key = 5, },
    { label = L"其它", key = 0, },
}
UserComplainPage.Types = {
    PROJECT = "PROJECT",
    CHAT = "CHAT",
};
UserComplainPage.TypesValue = {
    PROJECT = 5,
    CHAT = 10,
};
UserComplainPage.output_msg = {};
function UserComplainPage.OnInit()
    page = document:GetPageCtrl();
end
function UserComplainPage.MakeProjectMsg(projectId)
    if(not projectId)then
        return
    end
    local title = string.format(L"项目ID:%s",tostring(projectId));
    local msg = {
        projectId = projectId,
        title = title,
    }
    return msg;
end
function UserComplainPage.MakeChatMsg(userId, username, content, timestamp)
    if(not userId or not username)then
        return
    end
    local title = string.format(L"%s(%s)(%s):%s",tostring(userId), username, timestamp or "", content or "");
    local msg = {
        userId = userId,
        username = username,
        content = content,
        title = title,
    }
    return msg;
end
function UserComplainPage.ShowPage(input_type, input_msg)
    UserComplainPage.output_msg = {
        input_type = input_type,
        input_msg = input_msg,
    };
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/User/UserComplainPage.html",
			name = "UserComplainPage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			zorder = 0,
			--app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -700/2,
				y = -510/2,
				width = 700,
				height = 510,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

end
