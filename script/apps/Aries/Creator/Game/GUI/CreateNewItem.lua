--[[
Title: Create New Item
Author(s): LiXizhi
Date: 2015/12/25
Desc: create new items from given list of items
use the lib:
------------------------------------------------------------
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");

NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/CreateNewItem.lua");
local CreateNewItem = commonlib.gettable("MyCompany.Aries.Game.GUI.CreateNewItem");
CreateNewItem.ShowPage({
	ItemStack:new():Init(62,1),
	ItemStack:new():Init(101,1),
}, function(itemStack)
	echo(itemStack);
end)
-------------------------------------------------------
]]
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local CreateNewItem = commonlib.gettable("MyCompany.Aries.Game.GUI.CreateNewItem");

local page;
function CreateNewItem.OnInit()
	page = document:GetPageCtrl();
end

-- @param itemStackArray: array of item stacks
-- @param OnClose: function(result) end, where result is the itemStack selected or nil.
function CreateNewItem.ShowPage(itemStackArray, OnClose)
	CreateNewItem.result = nil;
	CreateNewItem.itemStackArray = itemStackArray;
	
	local Screen = commonlib.gettable("System.Windows.Screen");
	local x, y = ParaUI.GetMousePosition();
	x = math.min(x, Screen:GetWidth() - 200);
	y = math.min(y, Screen:GetHeight() - 200);

	local params = {
			url = "script/apps/Aries/Creator/Game/GUI/CreateNewItem.html", 
			name = "CreateNewItem.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			click_through = false, 
			enable_esc_key = true,
			bShow = true,
			isTopLevel = true,
			---app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_lt",
				x = x,
				y = y,
				width = 400,
				height = 400,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	
	params._page.OnClose = function()
		if(OnClose) then
			OnClose(CreateNewItem.result);
		end
	end
end


function CreateNewItem.OnOK()
	if(page) then
		CreateNewItem.result = nil;
		page:CloseWindow();
	end
end
