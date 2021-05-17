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
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/SoundManager.lua");
local SoundManager = commonlib.gettable("MyCompany.Aries.Game.Sound.SoundManager");

local EditMovieTextPage = commonlib.gettable("MyCompany.Aries.Game.Movie.EditMovieTextPage");

local default_narrator = -1
local page;
function EditMovieTextPage.OnInit()
	page = document:GetPageCtrl();
end

-- @param OnClose: function(values) end 
-- @param last_values: {text, ...}
function EditMovieTextPage.ShowPage(title, OnClose, last_values)
	EditMovieTextPage.result = last_values;
	EditMovieTextPage.title = title;
	default_narrator = -1
	
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
	return EditMovieTextPage.title or L"添加/编辑字幕";
end

function EditMovieTextPage.OnOK()
	SoundManager:StopPlayText()
	if(page) then
		local text = page:GetValue("text");
		if(text) then
			text = text:gsub("\r?\n", "#");
		end
		local fontSize = tonumber(page:GetValue("fontsize")) or 25;
		fontSize = math.min(math.max(fontSize, 8), 100);
		fontcolor = page:GetValue("fontcolor");
		bgcolor = page:GetValue("bgcolor");

		EditMovieTextPage.result = {
			text = text,
			fontsize = fontSize,
			fontcolor = fontcolor,
			textpos = page:GetValue("textpos"),
			textanim = page:GetValue("textanim"),
			bganim = page:GetValue("bganim"),
			textbg = page:GetValue("textbg"),
			voicenarrator = page:GetValue("voicenarrator"),
			bgcolor = bgcolor,
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
		if(values.textbg) then
			page:SetValue("textbg", values.textbg);
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
		if(values.voicenarrator) then
			page:SetValue("voicenarrator", values.voicenarrator);
			default_narrator = values.voicenarrator
			EditMovieTextPage.UpdateSoundDesc()
		end
		
	end
end

function EditMovieTextPage.OnClickSelcetNarrator(name, value)
	if value == default_narrator then
		return
	end

	if value >= 0 and not System.User.isVip and not GameLogic.Macros:IsPlaying() then
		page:SetValue("voicenarrator", default_narrator);
		GameLogic.IsVip("PlyText", true, function(result)
			if result then
				page:SetValue("voicenarrator", value);
			end
		end)
		return
	end
end

function EditMovieTextPage.OnListeningTest()
	local text = page:GetValue("text") or "";
	text = text:gsub("\r?\n", "#");

	if text == "" then
		page:SetValue("SoundDesc", "")
		GameLogic.AddBBS(nil, L"请先输入文字", 15000, "255 0 0");
		return
	end

	local voicenarrator = page:GetValue("voicenarrator", -1)
	voicenarrator = tonumber(voicenarrator)
	if not voicenarrator or voicenarrator < 0 then
		page:SetValue("SoundDesc", "")
		GameLogic.AddBBS(nil, L"请选择播音员", 15000, "255 0 0");
		return
	end

	local nTimeoutMS = 7
	local start_timestamp = os.time()
	SoundManager:PrepareText(text,  voicenarrator, function(file_path)
		if os.time() - start_timestamp > nTimeoutMS then
			GameLogic.AddBBS(nil, L"合成声音超时，请重新尝试", 15000, "255 0 0");
			return
		end
		
		SoundManager:StopPlayText()
		local channel = "playtext" .. voicenarrator
		SoundManager:SetPlayTextChannel(channel)
		SoundManager:PlaySound(channel, file_path)
		EditMovieTextPage.UpdateSoundDesc()
	end)
end

function EditMovieTextPage.OnTextChange()
	if not System.User.isVip then
		page:SetValue("voicenarrator", -1);
	end
end

function EditMovieTextPage.UpdateSoundDesc()
	local text = page:GetValue("text") or "";
	text = text:gsub("\r?\n", "#")

	if text == "" then
		page:SetValue("SoundDesc", "")
		return
	end

	local voicenarrator = page:GetValue("voicenarrator", -1)
	voicenarrator = tonumber(voicenarrator)
	if not voicenarrator or voicenarrator < 0 then
		page:SetValue("SoundDesc", "")
		return
	end

	local channel_name = "playtext" .. voicenarrator

	local md5_value = SoundManager:GetPlayTextMd5(text, voiceNarrator)
	local filename = md5_value .. ".mp3"
	local file_path = string.format("%s/%s/%s", SoundManager:GetPlayTextDiskFolder(), voicenarrator, filename)
	local duration = SoundManager:GetSoundDuration(channel_name, file_path)
	
	if duration and duration > 0 then
		page:SetValue("SoundDesc", string.format("时长%.1f秒", duration))
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
