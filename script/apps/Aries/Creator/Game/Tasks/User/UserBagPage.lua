--[[
Title: UserBagPage
Author(s): 
Date: 2020/8/11
Desc:  
Use Lib:
-------------------------------------------------------
local UserBagPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/UserBagPage.lua");
UserBagPage.ShowPage();
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");

local UserBagPage = NPL.export()
local page
UserBagPage.Current_Item_DS = {};
UserBagPage.accepted_bags = { 4,};
function UserBagPage.OnInit()
    page = document:GetPageCtrl();
end
function UserBagPage.ShowPage()
    if(not KeepWorkItemManager.GetToken())then
		_guihelper.MessageBox(L"请先登录！");
		return
	end
    UserBagPage.Current_Item_DS = UserBagPage.FillData();
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/User/UserBagPage.html",
			name = "UserBagPage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = false,
			zorder = 100,
			--app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -600/2,
				y = -500/2,
				width = 600,
				height = 500,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

    KeepWorkItemManager.GetFilter():add_filter("LoadItems_Finished", function()
        UserBagPage.Refresh();
    end);
end
function UserBagPage.Refresh()
    if(page and page:IsVisible())then
        page:Refresh(0);
    end
end
function UserBagPage.CanFill(item)
    if(not item)then
        return
    end
    for k,bagId in ipairs(UserBagPage.accepted_bags) do
        if(item.bagId == bagId)then
            return true;         
        end
    end
end
function UserBagPage.FillData()
    local items = KeepWorkItemManager.items or {};
    local result = {};
    for k,v in ipairs(items) do
        if(UserBagPage.CanFill(v))then
            table.insert(result,v);
        end
    end
    return result;
end