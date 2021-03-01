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
local UserComplainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/UserComplainPage.lua");
local KpChatChannel = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/KpChatChannel.lua");
function KpChatHelper.ShowMenu(str_username_chatid)
    if(not str_username_chatid)then
        return
    end
	local username, chatid = string.match(str_username_chatid,"(.+)_(.+)");
    if(mouse_button == "left") then
        KpChatHelper.ShowUserInfo(username);
	elseif(mouse_button == "right") then
        KpChatHelper.OnShowContextMenu(username, chatid);
	end
end
function KpChatHelper.OnShowContextMenu(username, chatid)
	
	local ctl = CommonCtrl.GetControl("kp_chat_window_username_ContextMenu");
	if(ctl==nil)then
		NPL.load("(gl)script/ide/ContextMenu.lua");
		ctl = CommonCtrl.ContextMenu:new{
			name = "kp_chat_window_username_ContextMenu",
			width = 120,
			height = 160,
			DefaultNodeHeight = 24,
			
		};
		local node = ctl.RootNode;
		node = ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "pe:name", Name = "pe:name", Type = "Group", NodeHeight = 0 });
		
		node:AddChild(CommonCtrl.TreeNode:new({Text = L"个人信息", Type = "Menuitem", onclick = function()
            KpChatHelper.ShowUserInfo(ctl.username);
			end, Icon = nil,}));
		node:AddChild(CommonCtrl.TreeNode:new({Text = L"举报违规", Type = "Menuitem", onclick = function()
            KpChatHelper.ShowComplainPage(ctl.chatid);
		    end, }));
	end	
    ctl.username = username;
    ctl.chatid = chatid;
	ctl:Show();
end
function KpChatHelper.ShowUserInfo(username)
    if(not username)then
        return
    end
    local page = NPL.load("Mod/GeneralGameServerMod/App/ui/page.lua");
    if(page and page.ShowUserInfoPage)then
        page.ShowUserInfoPage({ username = username }); 
    end
end
function KpChatHelper.ShowComplainPage(id)
    if(not id)then
        return
    end
    local msg = KpChatChannel.GetTempChatContent(id)
    if(msg)then
        local input_msg = UserComplainPage.MakeChatMsg(msg.kp_from_id,msg.kp_username,msg.words,msg.timestamp);
        UserComplainPage.ShowPage(UserComplainPage.Types.CHAT,input_msg);
    end
end

function KpChatHelper.ToWorld(id)
    local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")
    CommandManager:RunCommand(string.format('/loadworld -force -s %s', id))
end
