--[[
Title: edit movie text
Author(s): LiXizhi
Date: 2014/5/12
Desc: edit movie text page
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/EditMovieTextPage.lua");
local EditMovieTextPage = commonlib.gettable("MyCompany.Aries.Game.Movie.EditMovieTextPage");
EditMovieTextPage.ShowPage(nil, function(values)
	echo(values);
end, {text="1", fontsize="30", bganim="fadein"})
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/KeyFrameCtrl.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieUISound.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");
local MovieClip = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClip");
local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");

local EditMovieTextPage = commonlib.gettable("MyCompany.Aries.Game.Movie.EditMovieTextPage");

local page;
function EditMovieTextPage.OnInit()
	page = document:GetPageCtrl();
end

-- @param OnClose: function(values) end 
-- @param last_values: {text, ...}
function EditMovieTextPage.ShowPage(title, OnClose, last_values)
	EditMovieTextPage.result = last_values;
	EditMovieTextPage.title = title;
	
	local params = {
			url = "script/apps/Aries/Creator/Game/Movie/EditMovieTextPage.html", 
			name = "EditMovieTextPage.ShowPage", 
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
				x = -320,
				y = -250,
				width = 640,
				height = 300,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	EditMovieTextPage.UpdateUIFromValue(last_values);
	
	params._page.OnClose = function()
		if(OnClose) then
			OnClose(EditMovieTextPage.result);
		end
	end
end

function EditMovieTextPage.GetTitle()
	return EditMovieTextPage.title or "添加/编辑字幕";
end

function EditMovieTextPage.OnOK()
	if(page) then
		local text = page:GetValue("text");
		if(text) then
			text = text:gsub("\r?\n", "#");
		end
		EditMovieTextPage.result = {
			text = text,
			fontsize = tonumber(page:GetValue("fontsize")),
			fontcolor = page:GetValue("fontcolor"),
			textpos = page:GetValue("textpos"),
			textanim = page:GetValue("textanim"),
			bganim = page:GetValue("bganim"),
			bgcolor = page:GetValue("bgcolor"),
		};
		page:CloseWindow();
	end
end

function EditMovieTextPage.UpdateUIFromValue(values)
	if(page and values) then
		if(values.text) then
			page:SetValue("text", values.text:gsub("#", "\r\n"));
		end
		if(values.fontsize) then
			page:SetValue("fontsize", tostring(values.fontsize));
		end
		if(values.fontcolor) then
			page:SetValue("fontcolor", values.fontcolor);
		end
		if(values.textpos) then
			page:SetValue("textpos", values.textpos);
		end
		if(values.textanim) then
			page:SetValue("textanim", values.textanim);
		end
		if(values.bganim) then
			page:SetValue("bganim", values.bganim);
		end
		if(values.bgcolor) then
			page:SetValue("bgcolor", values.bgcolor);
		end
	end
end

function EditMovieTextPage.OnReset()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/ActorGUIText.lua");
	local actor = commonlib.gettable("MyCompany.Aries.Game.Movie.ActorGUIText");
	EditMovieTextPage.UpdateUIFromValue(actor.default_values);
end

function EditMovieTextPage.OnClose()
	page:CloseWindow();
end
