--[[
Title: EditBook Page
Author(s): LiXizhi
Date: 2014/1/21
Desc: # is used as the line seperator \r\n. Space key is replaced by _ character. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EditBookPage.lua");
local EditBookPage = commonlib.gettable("MyCompany.Aries.Game.GUI.EditBookPage");
EditBookPage.ShowPage(itemStack, OnClose);
-------------------------------------------------------
]]
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local EditBookPage = commonlib.gettable("MyCompany.Aries.Game.GUI.EditBookPage");

local curItemStack;
local page;

function EditBookPage.OnInit()
	page = document:GetPageCtrl();
end

function EditBookPage.GetItemID()
	return curItemStack.id;
end

function EditBookPage.GetItemStack()
	return curItemStack;
end

function EditBookPage.GetContent()
	local content = curItemStack:GetData();
	if(type(content) == "table") then
		return commonlib.Lua2XmlString(content);
	else
		return content;
	end
end

function EditBookPage.SetContent(content)
	curItemStack:SetData(content);
end

function EditBookPage.ShowPage(itemStack, OnClose)
	if(not itemStack) then
		return;
	end
	curItemStack = itemStack;
	
	local params;
	if(System.options.IsMobilePlatform) then
		params = {
			url = "script/apps/Aries/Creator/Game/GUI/EditBookPage.mobile.html", 
			name = "EditBookPage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			click_through = false, 
			enable_esc_key = true,
			bShow = true,
			zorder = -1,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -225,
				y = -220,
				width = 450,
				height = 440,
		};
	else
		params = {
			url = "script/apps/Aries/Creator/Game/GUI/EditBookPage.html", 
			name = "EditBookPage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			click_through = false, 
			enable_esc_key = true,
			bShow = true,
			zorder = -1,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -180,
				y = -200,
				width = 360,
				height = 400,
		};
	end
	
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	params._page.OnClose = OnClose;
end
