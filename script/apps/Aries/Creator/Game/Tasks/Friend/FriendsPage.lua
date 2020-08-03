--[[
Title: FriendsPage
Author(s): 
Date: 2020/7/3
Desc:  
Use Lib:
-------------------------------------------------------
local FriendsPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendsPage.lua");
FriendsPage.Show();
--]]
local FriendsPage = NPL.export();


local page;


FriendsPage.data_sources = {
    {
        { label = "1", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", nid = "10086"},
--        { label = "1"},
--        { label = "1"},
--        { label = "1"},
--        { label = "1"},
--        { label = "1"},
--        { label = "1"},
--        { label = "1"},
--        { label = "1"},
    },
    {
        { label = "2"},
        { label = "2"},
        { label = "2"},
        { label = "2"},
        { label = "2"},
        { label = "2"},
        { label = "2"},
        { label = "2"},
        { label = "2"},
        { label = "2"},
        { label = "2"},
        { label = "2"},
        { label = "2"},
    },
    {
        { label = "3"},
        { label = "3"},
        { label = "3"},
        { label = "3"},
        { label = "3"},
        { label = "3"},
        { label = "3"},
        { label = "3"},
        { label = "3"},
        { label = "3"},
        { label = "3"},
        { label = "3"},
        { label = "3"},
        { label = "3"},
        { label = "3"},
        { label = "3"},
        { label = "3"},
    },
    {
        { label = "4"},
        { label = "4"},
        { label = "4"},
        { label = "4"},
        { label = "4"},
        { label = "4"},
        { label = "4"},
        { label = "4"},
        { label = "4"},
        { label = "4"},
        { label = "4"},
        { label = "4"},
        { label = "4"},
        { label = "4"},
        { label = "4"},
        { label = "4"},
        { label = "4"},
        { label = "4"},
    },
}
FriendsPage.Current_Item_DS = {};
FriendsPage.index = 1;
function FriendsPage.OnInit()
	page = document:GetPageCtrl();
end

function FriendsPage.Show()
    local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/Friend/FriendsPage.html",
			name = "FriendsPage.Show", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			zorder = -1,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_lt",
				x = 10,
				y = 10/2,
				width = 300,
				height = 500,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
    FriendsPage.OnChange(1);
end
function FriendsPage.OnChange(index)
	index = tonumber(index)
    FriendsPage.index = index;
    FriendsPage.Current_Item_DS = FriendsPage.data_sources[index] or {}
    FriendsPage.OnRefresh()
end
function FriendsPage.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
end
function FriendsPage.ClickItem(index)
	commonlib.echo("aaaaaaaaaa")
end
