--[[
Title: actor text
Author(s): LiXizhi
Date: 2014/4/10
Desc: for movie subscript text. This actually a helper class for ActorCommands.
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/ActorGUIText.lua");
local actor = commonlib.gettable("MyCompany.Aries.Game.Movie.ActorGUIText");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/Actor.lua");
NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/SoundManager.lua");
local SoundManager = commonlib.gettable("MyCompany.Aries.Game.Sound.SoundManager");
local Screen = commonlib.gettable("System.Windows.Screen");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Actor = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Movie.Actor"), commonlib.gettable("MyCompany.Aries.Game.Movie.ActorGUIText"));

-- default text values. 
local default_values = {
	text = "", 
	fontsize = 25,
	fontcolor = "#ffffff",
	textpos = "bottom",
	bganim = "",
	textanim = "",
	textbg = nil,
	bgcolor = "",
	voicenarrator = -1,
}
Actor.default_values = default_values;

-- we will scale text if screen is big
Actor.MaxScreenWidth = 1440;
Actor.MaxScreenHeight = 960;
Actor.MinScreenWidth = 1280;
Actor.MinScreenHeight = 720;
Actor.defaultTextScaling = 1.2

-- in ms seconds. 
local fadein_time = 1000;
local fadeout_time = 1000;

function Actor:ctor()
end

function Actor:Init(itemStack, movieclipEntity, movieclip)
	if(not Actor._super.Init(self, itemStack, movieclipEntity, movieclip)) then
		return;
	end
	local timeseries = self.TimeSeries;
	timeseries:CreateVariableIfNotExist("text", "Discrete");
	self:PrePlayText()
	return self;
end

function Actor:IsKeyFrameOnly()
	return true;
end

-- @return true if recording. 
function Actor:SetRecording(isRecording)
	-- disable recording. 
	return false;
end

local curTextOrder = 0;
local text_actors = {};

function Actor:GetCurrentTextOrder()
	return curTextOrder;
end

function Actor:SetCurrentTextOrder(order)
	curTextOrder = order;
end

-- this actor can only write text on order that is equal to self:GetCurrentTextOrder().
function Actor:GetTextOrder()
	if(not self.textOrder) then
		self:SetCurrentTextOrder(self:GetCurrentTextOrder() + 1);
		self.textOrder = self:GetCurrentTextOrder();
		text_actors[self.textOrder] = true;
	end
	return self.textOrder;
end

-- remove GUI text
function Actor:OnRemove()
	text_actors[self:GetTextOrder()] = nil;
	if(self:GetTextOrder() == self:GetCurrentTextOrder()) then
		self:SetCurrentTextOrder(1);
		for i = self:GetTextOrder() - 1, 1, -1 do
			if(text_actors[i]) then
				self:SetCurrentTextOrder(i);
				break;
			end
		end
	
		if(self.uiobject_id) then
			local obj = self:GetTextObj(false);
			if(obj) then
				ParaUI.Destroy(obj.parent.id);
			end
			-- ParaUI.Destroy(self.uiobject_id);
		end
	end
	self.uiobject_id = nil;
end

-- add movie text at the current time. 
-- @param values: text or a table of {text, ...}
function Actor:AddKeyFrameOfText(values)
	if(type(values) ~= "table") then
		values = {text=values or ""};
	else
		-- do not save default values. 
		if(values.fontsize == default_values.fontsize) then
			values.fontsize = nil;
		end
		if(values.fontcolor == default_values.fontcolor) then
			values.fontcolor = nil;
		end
		if(values.textpos == default_values.textpos) then
			values.textpos = nil;
		end
		if(values.bganim == default_values.bganim) then
			values.bganim = nil;
		end
		if(values.textanim == default_values.textanim) then
			values.textanim = nil;
		end
		if(values.textbg == "") then
			values.textbg = nil;
		end
		if(values.bgcolor == default_values.bgcolor) then
			values.bgcolor = nil;
		end
		if(values.voicenarrator == default_values.voicenarrator) then
			values.voicenarrator = nil;
		end
	end
	self:AddKeyFrameByName("text", nil, values);
end

function Actor:CreateKeyFromUI(keyname, callbackFunc)
	local curTime = self:GetTime();
	local h,m,s = commonlib.timehelp.SecondsToHMS(curTime/1000);
	local strTime = string.format("%.2d:%.2d", m,math.floor(s));
	local title = format(L"起始时间%s, 请输入字幕文字:", strTime);
	local old_value = self:GetValue("text", curTime);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/EditMovieTextPage.lua");
	local EditMovieTextPage = commonlib.gettable("MyCompany.Aries.Game.Movie.EditMovieTextPage");
	EditMovieTextPage.ShowPage(title, function(result)
		if(result and not commonlib.partialcompare(old_value,result)) then
			self:AddKeyFrameOfText(result);
			self:FrameMovePlaying(0);
			if(callbackFunc) then
				callbackFunc(true);
			end
		end
	end, old_value);
end

function Actor:GetValue(name, time)
	local values = Actor._super.GetValue(self, name, time);
	if(values and type(values) ~= "table") then
		default_values.text = values;
		values = default_values;
	end
	return values;
end

-- static function:
-- once locked any calls to update the text will do nothing
function Actor:Lock()
	Actor.isLocked = true;
end

-- static function:
function Actor:Unlock()
	Actor.isLocked = false;
end

function Actor:Islocked()
	return Actor.isLocked;
end

function Actor.OnScreenSizeChange()
	local _parent = ParaUI.GetUIObject("MovieGUIRoot");
	local viewport = ViewportManager:GetSceneViewport();
	local margin_right = math.floor(viewport:GetMarginRight() / Screen:GetUIScaling()[1]);
	local margin_bottom = math.floor(viewport:GetMarginBottom() / Screen:GetUIScaling()[2])
	_parent.height = margin_bottom;
	_parent.width = margin_right;

	local width = Screen:GetWidth() - margin_right;
	local height = Screen:GetHeight() - margin_bottom;

	Actor.textScaling = width / math.max(math.min(width, Actor.MaxScreenWidth), Actor.MinScreenWidth);
	local textCtrl = _parent:GetChild("text")
	textCtrl.scalingx = Actor.textScaling * Actor.defaultTextScaling;
	textCtrl.scalingy = Actor.textScaling * Actor.defaultTextScaling;
	if(Actor.textpos ~= "center") then
		textCtrl:Reposition("_mb", 0, 45 * (Actor.textScaling or 1), 0, 50 * (Actor.textScaling or 1));
	end
end

-- return the text gui object or nil. 
function Actor:GetTextObj(bCreateIfNotExist)
	if(self.uiobject_id) then
		local _this = ParaUI.GetUIObject(self.uiobject_id);
		if(_this:IsValid()) then
			return _this;
		end
	end
	if(bCreateIfNotExist) then
		local _parent = ParaUI.GetUIObject("MovieGUIRoot");
		if(not _parent:IsValid()) then
			_parent = ParaUI.CreateUIObject("container", "MovieGUIRoot", "_fi", 0, 0, 0, 0);
			_parent.background = ""
			_parent.enabled = false;
			_parent.zorder = -3;
			_parent:AttachToRoot();
			
			local viewport = ViewportManager:GetSceneViewport();
			viewport:Connect("sizeChanged", Actor, Actor.OnScreenSizeChange, "UniqueConnection");
			
			local _this = ParaUI.CreateUIObject("button", "text", "_mb", 0, 45, 0, 50);
			_this.background = "";
			_this.font = "System;20;bold";
			_guihelper.SetFontColor(_this, "#ffffffff");
			-- no clipping and vertical centered
			_guihelper.SetUIFontFormat(_this, 256+4+1);
			_this.shadow = true;
			_this.enabled = false;
			_parent:AddChild(_this);
			self.uiobject_id = _this.id;
			Actor.OnScreenSizeChange()
			return _this;
		else
			local _this = _parent:GetChild("text");
			self.uiobject_id = _this.id;
			return _this;
		end
	end
end

local image_path = {
	["grey"] = "Texture/alphadot.png",
	["white"] = "Texture/whitedot.png",
	["black"] = "Texture/bg_black.png",
}

-- @param filename: relative to world directory or "grey" or ""
function Actor:GetTextImagePathByName(filename)
	if(filename and filename~="") then
		return image_path[filename] or Files.GetWorldFilePath(filename) or filename;
	else
		return "";
	end
end

-- update UI text with given values. 
function Actor:UpdateTextUI(text, fontsize, fontcolor, textpos, textbg, bgalpha, textalpha, bgcolor, voicenarrator)
	local obj = self:GetTextObj(true);
	if(not obj) then
		return
	end
	local bg_obj = obj.parent;

	if(text and text~="" ) then
		local play_text = GameLogic:GetText(text)
		if voicenarrator and voicenarrator >= 0 then
			if obj.text ~= play_text or not obj.visible or self.voicenarrator ~= voicenarrator then
				SoundManager:PlayText(play_text, voicenarrator)
			end
			self.voicenarrator = voicenarrator
		end

		obj.visible = true;
		obj.text = play_text;
		_guihelper.SetFontColor(obj, fontcolor or default_values.fontcolor);
		
		if(textalpha and textalpha~=1) then
			obj.colormask = format("255 255 255 %d", math.floor(textalpha*255));
		else
			obj.colormask = "255 255 255 255";
		end
	else
		obj.visible = false;
	end
	
	Actor.textpos = textpos;
	if(textpos == "center") then
		obj:Reposition("_ct", -480, -100, 960, 200);
	else
		obj:Reposition("_mb", 0, 45 * (Actor.textScaling or 1), 0, 50 * (Actor.textScaling or 1));
	end

	if(fontsize and fontsize~=default_values.fontsize) then
		obj.font = format("System;%d;bold", fontsize);
	else
		obj.font = format("System;%d;bold", default_values.fontsize);
	end

	if(textbg and textbg~="") then
		obj.background = self:GetTextImagePathByName(textbg);
	else
		obj.background = "";
	end

	if(bgcolor and bgcolor~="") then
		if(bg_obj.background~="Texture/whitedot.png") then
			bg_obj.background = "Texture/whitedot.png";
		end
		_guihelper.SetUIColor(bg_obj, bgcolor);
		if(bgalpha and bgalpha~=1) then
			bg_obj.colormask = format("255 255 255 %d", math.floor(bgalpha*255));
		else
			bg_obj.colormask = "255 255 255 255";
		end
	else
		bg_obj.background = "";
	end
end

-- return a value between [0,1]
local function GetAlphaFromAnimTime(anim, curTime, fromTime, toTime)
	local alpha;
	if(anim == "" or not anim) then
		
	elseif(anim == "fadein") then
		if((curTime-fromTime) < fadein_time) then
			alpha = (curTime-fromTime)/fadein_time;
		end
	elseif(anim == "fadeout") then
		if((toTime-curTime) < fadeout_time) then
			alpha = (toTime-curTime)/fadeout_time;
		end
	elseif(anim == "fadeinout") then
		if((curTime-fromTime) < fadein_time) then
			alpha = (curTime-fromTime)/fadein_time;
		elseif((toTime-curTime) < fadeout_time) then
			alpha = (toTime-curTime)/fadeout_time;
		end
	elseif(anim == "bigger") then
		alpha = math.max(1, (curTime-fromTime)/(fromTime-toTime));
	end
	return alpha or 1;
end

-- # is replaced with \n. 
-- %name% is replaced with user's name
function Actor:ReplaceVariablesInText(text)
	if(text) then
		text = text:gsub("#", "\n");
		text = text:gsub("%%name%%", System.User.NickName or System.User.username or "")
	end
	return text;
end

function Actor:FrameMovePlaying(deltaTime)
	local curTime = self:GetTime();
	if(not curTime or self:Islocked()) then
		return
	end
	local text, fontsize, fontcolor, textpos, bgalpha, textalpha, bgcolor;
	local values = self:GetValue("text", curTime);
	local var = self:GetVariable("text");
	if(var and values) then
		if(self:GetTextOrder() ~= self:GetCurrentTextOrder()) then
			return;
		end
		local fromTime, toTime = var:getTimeRange(1, curTime);
		
		local firstTime = var:GetFirstTime();
		local lastTime = var:GetLastTime();
		if(curTime>lastTime or lastTime == 0) then
			toTime = self:GetMaxLength();
		end

		if(firstTime <= curTime) then
			bgalpha = GetAlphaFromAnimTime(values.bganim, curTime, fromTime, toTime);
			textalpha = GetAlphaFromAnimTime(values.textanim, curTime, fromTime, toTime);
			
			text, fontsize, fontcolor, textpos, bgcolor = self:ReplaceVariablesInText(values.text), values.fontsize, values.fontcolor, values.textpos, values.bgcolor;
		end
		self:UpdateTextUI(text, fontsize, fontcolor, textpos, values.textbg, bgalpha, textalpha, bgcolor, values.voicenarrator);
	end
end

function Actor:PrePlayText()
	local var = self:GetVariable("text");
	if var then
		local lastTime = var:GetLastTime() or 0
		local key_table = var:GetKeys_Iter(1, -1, lastTime)
		if key_table then
			for index, values in key_table do
				if values.text and values.text ~= "" and values.voicenarrator and values.voicenarrator >= 0 then
					SoundManager:PrepareText(values.text,  values.voicenarrator)
				end
			end
		end
	end

end