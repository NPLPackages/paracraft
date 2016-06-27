--[[
Title: Enter Text Dialog
Author(s): LiXizhi
Date: 2014/3/17
Desc: Display a dialog with text that let user to enter some input text. 
This is usually used by the /set -p name=prompt_msg command
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
EnterTextDialog.ShowPage("Please enter text", function(result)
	echo(result);
end)
-------------------------------------------------------
]]
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");

local page;
function EnterTextDialog.OnInit()
	page = document:GetPageCtrl();
end

-- @param default_text: default text to be displayed. 
function EnterTextDialog.ShowPage(text, OnClose, default_text, bIsMultiLine)
	EnterTextDialog.result = nil;
	EnterTextDialog.text = text;
	EnterTextDialog.bIsMultiLine = bIsMultiLine;

	local params = {
			url = "script/apps/Aries/Creator/Game/GUI/EnterTextDialog.html", 
			name = "EnterTextDialog.ShowPage", 
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
				align = "_ct",
				x = -200,
				y = -150,
				width = 400,
				height = 400,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	if(default_text) then
		if(EnterTextDialog.IsMultiLine()) then
			params._page:SetUIValue("text_multi", default_text);
		else
			params._page:SetUIValue("text", default_text);
		end
	end
	params._page.OnClose = function()
		if(OnClose) then
			OnClose(EnterTextDialog.result);
		end
	end
end

function EnterTextDialog.IsMultiLine()
	return EnterTextDialog.bIsMultiLine == true;
end

function EnterTextDialog.OnOK()
	if(page) then
		if(EnterTextDialog.IsMultiLine()) then
			EnterTextDialog.result = page:GetValue("text_multi");
		else
			EnterTextDialog.result = page:GetValue("text");
		end
		page:CloseWindow();
	end
end

function EnterTextDialog.GetText()
	return EnterTextDialog.text or L"请输入:";
end