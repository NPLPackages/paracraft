--[[
Title: EditCommand Page
Author(s): LiXizhi
Date: 2014/2/21
Desc: # is used as the line seperator \r\n. Space key is replaced by _ character. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EditCommandPage.lua");
local EditCommandPage = commonlib.gettable("MyCompany.Aries.Game.GUI.EditCommandPage");
EditCommandPage.ShowPage(itemStack, OnClose);
-------------------------------------------------------
]]
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local EditCommandPage = commonlib.gettable("MyCompany.Aries.Game.GUI.EditCommandPage");

local curItemStack;
local page;

function EditCommandPage.OnInit()
	page = document:GetPageCtrl();
end

function EditCommandPage.GetItemID()
	return curItemStack.id;
end

function EditCommandPage.GetItemStack()
	return curItemStack;
end

function EditCommandPage.GetCode()
	local content = curItemStack:GetData();
	if(type(content) == "table") then
		return commonlib.Lua2XmlString(content);
	else
		return content;
	end
end

function EditCommandPage.SetCode(code)
	curItemStack:SetData(code);
end

function EditCommandPage.ShowPage(itemStack, OnClose)
	if(not itemStack) then
		return;
	end
	curItemStack = itemStack;
	local params = {
			url = "script/apps/Aries/Creator/Game/GUI/EditCommandPage.html", 
			name = "EditCommandPage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			bShow = true,
			click_through = false, 
			zorder = -1,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -180,
				y = -200,
				width = 360,
				height = 400,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	params._page.OnClose = OnClose;
end
