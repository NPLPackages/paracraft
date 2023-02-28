--[[
Title: CodeSubtitle
Author(s): hyz
Date: 2022/10/17
Desc: 用程序控制在世界添加字幕
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandSubtitles.lua");
local CodeSubtitle = commonlib.gettable("MyCompany.Aries.Game.CodeSubtitle")
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/SoundManager.lua");
local SoundManager = commonlib.gettable("MyCompany.Aries.Game.Sound.SoundManager");
local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
local Screen = commonlib.gettable("System.Windows.Screen");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local CodeSubtitle = commonlib.gettable("MyCompany.Aries.Game.CodeSubtitle")

local _self = CodeSubtitle;

-- default text values. 
local default_values = {
	text = "", 
	fontsize = 25,
	fontcolor = "#ffffff",
	textpos = "bottom", -- center|bottom|headon
	textbg = nil,
	bgcolor = "",
	voicenarrator = -1,
	voicebelongto = "",
}
CodeSubtitle.default_values = default_values;

-- we will scale text if screen is big
CodeSubtitle.MaxScreenWidth = 1440;
CodeSubtitle.MaxScreenHeight = 960;
CodeSubtitle.MinScreenWidth = 1280;
CodeSubtitle.MinScreenHeight = 720;
CodeSubtitle.defaultTextScaling = 1.2

-- in ms seconds. 
local fadein_time = 1000;
local fadeout_time = 1000;

function CodeSubtitle:ctor()
end

function CodeSubtitle.OnScreenSizeChange()
	local _parent = ParaUI.GetUIObject("CodeSubtitle_Root");
    if _parent==nil then 
        return
    end
	local viewport = ViewportManager:GetSceneViewport();
	local margin_right = math.floor(viewport:GetMarginRight() / Screen:GetUIScaling()[1]);
	local margin_bottom = math.floor(viewport:GetMarginBottom() / Screen:GetUIScaling()[2])
	_parent.height = margin_bottom;
	_parent.width = margin_right;

	local width = Screen:GetWidth() - margin_right;
	local height = Screen:GetHeight() - margin_bottom;

	CodeSubtitle.textScaling = width / math.max(math.min(width, CodeSubtitle.MaxScreenWidth), CodeSubtitle.MinScreenWidth);
	local textCtrl = _parent:GetChild("text")
	textCtrl.scalingx = CodeSubtitle.textScaling * CodeSubtitle.defaultTextScaling;
	textCtrl.scalingy = CodeSubtitle.textScaling * CodeSubtitle.defaultTextScaling;
	if(CodeSubtitle.textpos ~= "center") then
		textCtrl:Reposition("_mb", 0, 45 * (CodeSubtitle.textScaling or 1), 0, 50 * (CodeSubtitle.textScaling or 1));
	end
end

function CodeSubtitle.removeTextObj()
    if(_self.uiobject_id) then
        local obj = _self.GetTextObj(false);
        if(obj) then
            ParaUI.Destroy(obj.parent.id);
        end
        -- ParaUI.Destroy(_self.uiobject_id);
    end
	
	_self.uiobject_id = nil;
    local viewport = ViewportManager:GetSceneViewport();
    viewport:Disconnect("sizeChanged", CodeSubtitle, CodeSubtitle.OnScreenSizeChange, "UniqueConnection");
    GameLogic:Disconnect("WorldUnloaded", CodeSubtitle, CodeSubtitle.OnWorldUnLoaded, "UniqueConnection");
    GameLogic.GetFilters():remove_filter("OnPlayMovieText",CodeSubtitle.OnPlayMovieText)
    GameLogic.GetFilters():remove_filter("OnPlayMacroText",CodeSubtitle.OnPlayMacroText)

    if _self.timeoutHandler then
        _self.timeoutHandler:Change()
        _self.timeoutHandler = nil 
    end
end

function CodeSubtitle.OnWorldUnLoaded()
    _self.removeTextObj()
end

function CodeSubtitle.OnPlayMovieText()
    _self.removeTextObj()
end

function CodeSubtitle.OnPlayMacroText()
    _self.removeTextObj()
end

-- return the text gui object or nil. 
function CodeSubtitle.GetTextObj(bCreateIfNotExist)
	if(_self.uiobject_id) then
		local _this = ParaUI.GetUIObject(_self.uiobject_id);
		if(_this:IsValid()) then
			return _this;
		end
	end
	if(bCreateIfNotExist) then
		local _parent = ParaUI.GetUIObject("CodeSubtitle_Root");
		if(not _parent:IsValid()) then
			_parent = ParaUI.CreateUIObject("container", "CodeSubtitle_Root", "_fi", 0, 0, 0, 0);
			_parent.background = ""
			_parent.enabled = false;
			_parent.zorder = -3;
			_parent:AttachToRoot();
			
			local viewport = ViewportManager:GetSceneViewport();
			viewport:Connect("sizeChanged", CodeSubtitle, CodeSubtitle.OnScreenSizeChange, "UniqueConnection");
            GameLogic:Connect("WorldUnloaded", CodeSubtitle, CodeSubtitle.OnWorldUnLoaded, "UniqueConnection");
            GameLogic.GetFilters():add_filter("OnPlayMovieText",CodeSubtitle.OnPlayMovieText)
            GameLogic.GetFilters():add_filter("OnPlayMacroText",CodeSubtitle.OnPlayMacroText)
			
			local _this = ParaUI.CreateUIObject("button", "text", "_mb", 0, 45, 0, 50);
			_this.background = "";
			_this.font = "System;20;bold";
			_guihelper.SetFontColor(_this, "#ffffffff");
			-- no clipping and vertical centered
			_guihelper.SetUIFontFormat(_this, 256+4+1);
			_this.shadow = true;
			_this.enabled = false;
			_parent:AddChild(_this);
			_self.uiobject_id = _this.id;
			CodeSubtitle.OnScreenSizeChange()
			return _this;
		else
			local _this = _parent:GetChild("text");
			_self.uiobject_id = _this.id;
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
function CodeSubtitle.GetTextImagePathByName(filename)
    print("filename",filename)
    print("image_path[filename]",image_path[filename])
	if(filename and filename~="") then
		return image_path[filename] or Files.GetWorldFilePath(filename) or filename;
	else
		return "";
	end
end

function CodeSubtitle.SetText(text,params)
    if text==nil or text=="" then
        CodeSubtitle.removeTextObj()
        return
    end
    params = params or {}
    local fontsize, fontcolor, textpos, textbg, bgalpha, textalpha, bgcolor = params.fontsize, params.fontcolor, params.textpos, params.textbg, params.bgalpha, params.textalpha, params.bgcolor
    local duration = params.duration
    if duration and duration>0 then
        if _self.timeoutHandler then
            _self.timeoutHandler:Change()
            _self.timeoutHandler = nil
        end
        _self.timeoutHandler = commonlib.TimerManager.SetTimeout(function()
            _self.timeoutHandler = nil
            CodeSubtitle.removeTextObj()
        end,duration)
    end
    
    local obj = _self.GetTextObj(true);
	if(not obj) then
		return
	end
	local bg_obj = obj.parent;

	if(text and text~="" ) then
		local play_text = GameLogic:GetText(text)
		obj.visible = true;
		
		_guihelper.SetFontColor(obj, fontcolor or default_values.fontcolor);
		
		if(textalpha and textalpha~=1) then
			obj.colormask = format("255 255 255 %d", math.floor(textalpha*255));
		else
			obj.colormask = "255 255 255 255";
		end
	else
		obj.visible = false;
	end
	
	obj.text = text;
	_self.textpos = textpos;
	if(textpos == "center") then
		obj:Reposition("_ct", -480, -100, 960, 200);
	else
		obj:Reposition("_mb", 0, 45 * (_self.textScaling or 1)+30, 0, 50 * (_self.textScaling or 1));
	end

	if(fontsize and fontsize~=default_values.fontsize) then
		obj.font = format("System;%d;bold", fontsize);
	else
		obj.font = format("System;%d;bold", default_values.fontsize);
	end

	if(textbg and textbg~="") then
		obj.background = _self.GetTextImagePathByName(textbg);
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



local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

--[[
    {
        text = "", 
        fontsize = 25,
        fontcolor = "#ffffff",
        textbg = nil, -- grey | white | black
        bgcolor = "",
    }
]]
Commands["subtitle"] = {
	name="subtitle", 
	quick_ref="/subtitle [-duration 5000] [-textbg black] [-fontsize 25] [-fontcolor #ffffff] [-bgcolor #ffffff] [-text 这是字幕内容]", 
	desc=[[
-- subtitle -textbg black -fontsize 25 -duration 30000 -text helloworld
@param -text :text content,close when text is nil 
@param -textbg: bg color type, [grey | white | black]
@param -fontsize 
@param -fontcolor
@param -duration 
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local fontcolor, duration, text,fontsize,textbg
		local option_name = "";
		while (option_name and cmd_text) do
			option_name, cmd_text = CmdParser.ParseOption(cmd_text);
			if(option_name == "fontcolor") then
				fontcolor, cmd_text = CmdParser.ParseColor(cmd_text);
            elseif(option_name == "bgcolor") then
				bgcolor, cmd_text = CmdParser.ParseColor(cmd_text);
			elseif(option_name == "duration") then
				duration, cmd_text = CmdParser.ParseInt(cmd_text);
			elseif(option_name == "fontsize") then
				fontsize, cmd_text = CmdParser.ParseInt(cmd_text);
            elseif(option_name == "textbg") then
				textbg, cmd_text = CmdParser.ParseString(cmd_text);
            elseif(option_name == "text") then
				text, cmd_text = CmdParser.ParseString(cmd_text);
			end
		end
        if text==nil then
		    text = cmd_text;
        end

        local params = {
            fontcolor = fontcolor,
            duration = duration,
            fontsize = fontsize,
            textbg = textbg,
        }
        echo(params,true)
        CodeSubtitle.SetText(text,params)
	end,
};
