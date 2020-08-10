--[[
Title: DockPage
Author(s): leio
Date: 2020/8/3
Desc:  
Use Lib:
-------------------------------------------------------
local DockPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockPage.lua");
DockPage.Show();
DockPage.Hide();
--]]
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ParacraftLearningRoomDailyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParacraftLearningRoom/ParacraftLearningRoomDailyPage.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/PageCtrl.lua");
local DockPage = NPL.export();

DockPage.is_show = true;
DockPage.top_line_1 = {
    { label = L"", },
    { label = L"", },
    { label = L"", },
    { label = L"", },
    { label = L"", },
    { label = L"大赛", id = "competition", enabled = true, },
}
DockPage.top_line_2 = {
    { label = L"", },
    { label = L"", },
    { label = L"", },
    { label = L"", },
    { label = L"签到", id = "checkin", enabled2 = true, },
    { label = L"知识岛", id = "island", enabled2 = true, },
}

function DockPage.Show()
    if(not DockPage._root)then
        DockPage.page = Map3DSystem.mcml.PageCtrl:new({ 
            url = "script/apps/Aries/Creator/Game/Tasks/Dock/DockPage.html" ,
            click_through = true,
        } );
        DockPage._root = DockPage.page:Create("DockPage.Show_instance", nil, "_fi", 0, 0, 0, 0)
    end
    DockPage._root.visible = true;
    DockPage.is_show = true;
end
function DockPage.Hide()
    DockPage.is_show = false;
    if(DockPage._root)then
        DockPage._root.visible = false;
    end
end
function DockPage.IsShow()
    return DockPage.is_show;
end
function DockPage.OnClick(id)
    if(id == "character")then
        local UserInfoPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/UserInfoPage.lua");
        UserInfoPage.ShowPage();
    elseif(id == "work")then
        
        GameLogic.RunCommand("/menu file.loadworld");
    elseif(id == "explore")then
        local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")
        UserConsole.OnClickOfficialWorlds();
    elseif(id == "study")then
        local StudyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/StudyPage.lua");
        StudyPage.ShowPage();
    elseif(id == "school")then
        local MySchool = NPL.load("(gl)Mod/WorldShare/cellar/MySchool/MySchool.lua")
        MySchool:Show();
    elseif(id == "system")then
        DockPage.OnClick_system_menu();
    elseif(id == "vip")then
        ParacraftLearningRoomDailyPage.OnVIP();
    elseif(id == "mall")then
        local KeepWorkMallPage = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/KeepWorkMallPage.lua");
        KeepWorkMallPage.Show();
    elseif(id == "competition")then
	    ParaGlobal.ShellExecute("open", "explorer.exe", "https://keepwork.com/cp/home", "", 1); 
    elseif(id == "checkin")then
        ParacraftLearningRoomDailyPage.DoCheckin();
    elseif(id == "island")then
        ParacraftLearningRoomDailyPage.OnLearningLand();

        
    else
        _guihelper.MessageBox(id);
    end
end

function DockPage.OnClick_system_menu()
	local ctl = CommonCtrl.GetControl("OnClick_system_menu");
	if(ctl == nil)then
		ctl = CommonCtrl.ContextMenu:new{
			name = "OnClick_system_menu",
			width = 160,
			height = 160, -- add menuitemHeight(30) with each new item
            AutoPositionMode = "_lt",
			style = CommonCtrl.ContextMenu.DefaultStyle,
		};
		local node = ctl.RootNode;
		local subNode;
		node = ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "", Name = "name", Type="Title", NodeHeight = 0 });
		node = ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "", Name = "titleseparator", Type="separator", NodeHeight = 0 });
		node = ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "Quickwords", Name = "actions", Type = "Group", NodeHeight = 0 });
			node:AddChild(CommonCtrl.TreeNode:new({Text = L"架设私服", Name = "ExitGame", Type = "Menuitem", onclick = DockPage.OnClick_Menuitem_server, }));
			node:AddChild(CommonCtrl.TreeNode:new({Text = "插件管理", Name = "ExitGame", Type = "Menuitem", onclick = DockPage.OnClick_Menuitem_plugin, }));
			node:AddChild(CommonCtrl.TreeNode:new({Text = "联系客服", Name = "ExitGame", Type = "Menuitem", onclick = DockPage.OnClick_Menuitem_service, }));
			node:AddChild(CommonCtrl.TreeNode:new({Text = "系统设置", Name = "ExitGame", Type = "Menuitem", onclick = DockPage.OnClick_Menuitem_system, }));
			node:AddChild(CommonCtrl.TreeNode:new({Text = "退出", Name = "ExitGame", Type = "Menuitem", onclick = DockPage.OnClick_Menuitem_exit, }));
	end
	
	local x,y,width, height = _guihelper.GetLastUIObjectPos();
	ctl:Show(x-105, y-ctl.height);
end
function DockPage.OnClick_Menuitem_server()
    NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ServerPage.lua");
    local ServerPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.ServerPage");
    ServerPage.ShowPage();
end
function DockPage.OnClick_Menuitem_plugin()
    NPL.load("(gl)script/apps/Aries/Creator/Game/Login/SelectModulePage.lua");
    local SelectModulePage = commonlib.gettable("MyCompany.Aries.Game.MainLogin.SelectModulePage")
    SelectModulePage.ShowPage()
end
function DockPage.OnClick_Menuitem_service()
	ParaGlobal.ShellExecute("open", "explorer.exe", "https://keepwork.com/official/docs/FAQ/questions", "", 1); 
end
function DockPage.OnClick_Menuitem_system()
    GameLogic.RunCommand("/menu file.settings");
end
function DockPage.OnClick_Menuitem_exit()
    GameLogic.RunCommand("/menu file.exit");
end
