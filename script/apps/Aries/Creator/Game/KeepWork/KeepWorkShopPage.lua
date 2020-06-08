--[[
Title: KeepWorkShopPage
Author(s): leio
Date: 2020/4/24
Desc:  
Use Lib:
-------------------------------------------------------
local KeepWorkShopPage = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/KeepWorkShopPage.lua");
KeepWorkShopPage.Show()
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local KeepWorkShopPage = NPL.export();

KeepWorkShopPage.category_index = 2;
KeepWorkShopPage.Current_Item_DS = {};

KeepWorkShopPage.category = {
    {text=L"商城", name="shop",  },
    {text=L"背包", name="slot",  },
}

local page;


function KeepWorkShopPage.OnInit()
	page = document:GetPageCtrl();
	KeepWorkShopPage.OnChangeCategory(nil, false);
end

function KeepWorkShopPage.Show()
    local params = {
			url = "script/apps/Aries/Creator/Game/KeepWork/KeepWorkShopPage.html",
			name = "KeepWorkShopPage.Show", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			zorder = -1,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -800/2,
				y = -500/2,
				width = 800,
				height = 500,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function KeepWorkShopPage.OnChangeCategory(index, bRefreshPage)
    KeepWorkShopPage.category_index = index or KeepWorkShopPage.category_index;
    if(KeepWorkShopPage.category_index == 1)then
        KeepWorkShopPage.Current_Item_DS = KeepWorkItemManager.globalstore;
    else
        KeepWorkShopPage.Current_Item_DS = KeepWorkItemManager.items;
    end
    
	if(bRefreshPage~=false and page) then
		page:Refresh(0.01);
	end
end