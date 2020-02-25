--[[
Title: select skins
Author(s): LiXizhi
Date: 2020/2/21
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/SelectSkinPage.lua");
local SelectSkinPage = commonlib.gettable("MyCompany.Aries.Game.Movie.SelectSkinPage");
SelectSkinPage.ShowPage(function(value)
	if(type(value) == "table" and value.filename) then
		_guihelper.MessageBox(value.filename);
	end
end, {{filename="Texture/whitedot.png"}, {filename="Texture/alphadot.png"}})
-------------------------------------------------------
]]

local SelectSkinPage = commonlib.gettable("MyCompany.Aries.Game.Movie.SelectSkinPage");
SelectSkinPage.skins = {}

local page;
function SelectSkinPage.OnInit()
	page = document:GetPageCtrl();
end

function SelectSkinPage.GetTitle()
	return SelectSkinPage.title or "";
end

function SelectSkinPage.GetSkinDS(index)
	if(not index) then
		return #(SelectSkinPage.skins);
	else
		return SelectSkinPage.skins[index];
	end
end

-- @param OnOK: function(values) end 
-- @param skins: array of skins
-- @param title: custom title 
function SelectSkinPage.ShowPage(OnOK, skins, title)
	SelectSkinPage.result = nil;
	SelectSkinPage.title = title;
	SelectSkinPage.last_value = nil;
	SelectSkinPage.skins = skins or {};

	local params = {
		url = "script/apps/Aries/Creator/Game/Movie/SelectSkinPage.html", 
		name = "SelectSkinPage.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		bToggleShowHide=false, 
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = true,
		click_through = false, 
		enable_esc_key = true,
		bShow = true,
		isTopLevel = true,
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		directPosition = true,
			align = "_ct",
			x = -100,
			y = -160,
			width = 512,
			height = 400,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	params._page.OnClose = function()
		if(SelectSkinPage.result == "OK") then
			OnOK(SelectSkinPage.last_value);
		end
	end
end

function SelectSkinPage.OnClickItem(name)
	local index = tonumber(name);
	SelectSkinPage.last_value = SelectSkinPage.skins[index];
	SelectSkinPage.OnOK()
end

function SelectSkinPage.OnOK()
	if(page) then
		SelectSkinPage.result = "OK";
		page:CloseWindow();
	end
end

function SelectSkinPage.OnClose()
	page:CloseWindow();
end

