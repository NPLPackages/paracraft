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
    if(id == "checkin")then
        ParacraftLearningRoomDailyPage.DoCheckin();
    elseif(id == "island")then
        ParacraftLearningRoomDailyPage.OnLearningLand();
    elseif(id == "vip")then
        ParacraftLearningRoomDailyPage.OnVIP();
    elseif(id == "school")then
        DockPage.OnClick_school_menu();
    else
        _guihelper.MessageBox(id);
    end
end

function DockPage.OnClick_school_menu()
	local ctl = CommonCtrl.GetControl("OnClick_school_menu");
	if(ctl == nil)then
		ctl = CommonCtrl.ContextMenu:new{
			name = "OnClick_school_menu",
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
			node:AddChild(CommonCtrl.TreeNode:new({Text = "菜单1", Name = "ExitGame", Type = "Menuitem", onclick = DockPage.OnClick_Menuitem, }));
			node:AddChild(CommonCtrl.TreeNode:new({Text = "菜单2", Name = "ExitGame", Type = "Menuitem", onclick = DockPage.OnClick_Menuitem, }));
			node:AddChild(CommonCtrl.TreeNode:new({Text = "菜单3", Name = "ExitGame", Type = "Menuitem", onclick = DockPage.OnClick_Menuitem, }));
			node:AddChild(CommonCtrl.TreeNode:new({Text = "菜单4", Name = "ExitGame", Type = "Menuitem", onclick = DockPage.OnClick_Menuitem, }));
			node:AddChild(CommonCtrl.TreeNode:new({Text = "菜单5", Name = "ExitGame", Type = "Menuitem", onclick = DockPage.OnClick_Menuitem, }));
			node:AddChild(CommonCtrl.TreeNode:new({Text = "菜单6", Name = "ExitGame", Type = "Menuitem", onclick = DockPage.OnClick_Menuitem, }));
	end
	
	local x,y,width, height = _guihelper.GetLastUIObjectPos();
	ctl:Show(x-105, y-ctl.height);
end
function DockPage.OnClick_Menuitem(key)
    echo("=======key");
    echo(key);
end
