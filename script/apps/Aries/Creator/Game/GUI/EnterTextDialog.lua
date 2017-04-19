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

-- @param type_: nil|text|multiline|select.  if nil, it is single line text, if "multiline" it is multiline text. 
function EnterTextDialog.SetType(type_)
	EnterTextDialog.type = type_;
end

function EnterTextDialog.GetType()
	return EnterTextDialog.type;
end

function EnterTextDialog.IsMultiLine()
	return EnterTextDialog.GetType() == "multiline";
end

function EnterTextDialog.IsSelectText()
	return EnterTextDialog.GetType() == "select";
end

function EnterTextDialog.IsSingleLine()
	return not EnterTextDialog.IsMultiLine() and not EnterTextDialog.IsSelectText();
end


-- @param default_text: default text to be displayed. 
-- @param type_: if true, it is multi-line text. otherwise it is nil|text|multiline|select.
-- @param options: only used when type is "select". such as {{value="0", text="zero"},{value="1"}}
function EnterTextDialog.ShowPage(text, OnClose, default_text, type_, options)
	EnterTextDialog.result = nil;
	EnterTextDialog.text = text;
	if(bIsMultiLine == true) then
		EnterTextDialog.SetType("multiline");
	else
		EnterTextDialog.SetType(type_);
	end
	if(options) then
		for _, option in pairs(options) do
			option.selected = option.value == default_text;
		end
	end
	EnterTextDialog.options = options;

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
		elseif(EnterTextDialog.IsSelectText()) then
			params._page:SetValue("text_select", default_text);
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

function EnterTextDialog.OnOK()
	if(page) then
		if(EnterTextDialog.IsMultiLine()) then
			EnterTextDialog.result = page:GetValue("text_multi");
		elseif(EnterTextDialog.IsSelectText()) then
			EnterTextDialog.result = page:GetValue("text_select");
		else
			EnterTextDialog.result = page:GetValue("text");
		end
		page:CloseWindow();
	end
end

function EnterTextDialog.GetText()
	return EnterTextDialog.text or L"请输入:";
end