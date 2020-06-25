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
EnterTextDialog.ShowPage("select buttons", function(result)
	echo(result);
end, nil, "buttons", {"button1", "button2", "button3", "button4"})
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
	return not EnterTextDialog.IsMultiLine() and not EnterTextDialog.IsSelectText() and not EnterTextDialog.IsButtons();
end

function EnterTextDialog.IsButtons()
	return EnterTextDialog.GetType() == "buttons";
end

-- @param default_text: default text to be displayed. 
-- @param type_: if true, it is multi-line text. otherwise it is nil|text|multiline|select|buttons.
-- @param options: only used when type is "select" or "buttons". 
-- when type_ is "select": it is {{value="0", text="zero"},{value="1"}}
-- when type_ is "buttons": it is {"text1", "text2", "text3"}, result is button Index 
-- @param showParams: nil or {align="_ct", x, y, width, height}
function EnterTextDialog.ShowPage(text, OnClose, default_text, type_, options, showParams)
	EnterTextDialog.result = nil;
	EnterTextDialog.text = text;
	if(type_ == true) then
		EnterTextDialog.SetType("multiline");
	else
		EnterTextDialog.SetType(type_);
	end
	if(options and EnterTextDialog.IsSelectText()) then
		for _, option in pairs(options) do
			option.selected = option.value == default_text;
		end
	end
	EnterTextDialog.options = options;
	showParams = showParams or {};
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
			align = showParams.align or "_ct",
			x = showParams.x or -200,
			y = showParams.y or -150,
			width = showParams.width or 400,
			height = showParams.height or 400,
	};
	params = GameLogic.GetFilters():apply_filters('EnterTextDialog.PageParams', params, showParams)
	
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	if(default_text) then
		if(EnterTextDialog.IsMultiLine()) then
			params._page:SetUIValue("text_multi", default_text);
		elseif(EnterTextDialog.IsSelectText()) then
			params._page:SetUIValue("text_select", default_text);
		else
			params._page:SetUIValue("text", default_text);
		end
	end
	params._page.OnClose = function()
		if(OnClose) then
			OnClose(EnterTextDialog.result);
		end
		page = nil;
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

-- TODO: not implemented
function EnterTextDialog.SelectAll()
	if(page) then
		local ctl = page:FindControl("text")
		if(ctl) then
			-- TODO: only mcml2 support text selection in textbox. 
		end
	end
end

function EnterTextDialog.GetButtonsDS()
	local ds = {};
	if(EnterTextDialog.options) then
		for _, text in ipairs(EnterTextDialog.options) do
			ds[#ds+1] = {text = text};
		end
	end
	return ds;
end

function EnterTextDialog.OnClose()
	if(page) then
		page:CloseWindow();
	end
end

function EnterTextDialog.OnClickButton(index)
	if(page) then
		EnterTextDialog.result = index;
		page:CloseWindow();
	end
end