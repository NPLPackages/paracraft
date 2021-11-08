--[[
Title: Macro Add Sub Title
Author(s): LiXizhi
Date: 2021/4/3
Desc: 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroAddSubTitle.lua");
local MacroAddSubTitle = commonlib.gettable("MyCompany.Aries.Game.Tasks.MacroAddSubTitle");
MacroAddSubTitle.ShowPage();
-------------------------------------------------------
]]
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local MacroAddSubTitle = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Tasks.MacroAddSubTitle"));
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/SoundManager.lua");
local SoundManager = commonlib.gettable("MyCompany.Aries.Game.Sound.SoundManager");
local page;

MacroAddSubTitle.lastVoiceType = 10012; -- default to girl voice

function MacroAddSubTitle.OnInit()
	page = document:GetPageCtrl();
end

-- @param duration: in seconds
function MacroAddSubTitle.ShowPage()
	Macros:Pause();
	local params = {
		url = "script/apps/Aries/Creator/Game/Macros/MacroAddSubTitle.html", 
		name = "MacroAddSubTitleTask.ShowPage", 
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		isShowTitleBar = false,
		bShow = true,
		DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
		style = CommonCtrl.WindowFrame.ContainerStyle,
		bShow = true,
		allowDrag = true,
		isTopLevel = true,
		-- enable_esc_key = true,
		directPosition = true,
			align = "_ct",
			x = -320,
			y = -250,
			width = 640,
			height = 300,
	}
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	params._page.OnClose = function()
		Macros:Resume();
		page = nil;
	end;

	-- restore last values
	page:SetValue("voiceType", MacroAddSubTitle.lastVoiceType or 4);
end

function MacroAddSubTitle.OnClose()
	if(page) then
		page:CloseWindow();
		page = nil;
	end
end

function MacroAddSubTitle.OnOK()
	local text = ""
	local duration
	local voiceType
	local position;
	if(page) then
		text = page:GetValue("text", "")
		duration = page:GetValue("duration", "")
		duration = tonumber(duration)
		position = page:GetValue("textpos")
		if(position == "") then
			position = nil;
		end
		
		voiceType = page:GetValue("voiceType", -1)
		if voiceType >= 0 then
			SoundManager:PlayText(text,  voiceType)
		end
	end
	MacroAddSubTitle.OnClose()
	MacroAddSubTitle.lastText = text;
	MacroAddSubTitle.lastVoiceType = voiceType;

	local lastMacro = Macros:GetLastMacro()
	if(lastMacro and lastMacro.name == "text") then
		-- replace last text if any
		--Macros:PopMacro();
		local lastMacro = Macros:GetLastMacro()
		if(lastMacro and lastMacro.name == "Idle") then
			Macros:PopMacro();
		end
	end
	-- we shall change idle time to 0
	Macros:ClearIdleTime()
	
	if(voiceType == 4) then
		voiceType = nil;
	end
	Macros:AddMacro("text", text, duration, position, voiceType);

	NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroShowSubTitle.lua");
	local MacroShowSubTitle = commonlib.gettable("MyCompany.Aries.Game.Tasks.MacroShowSubTitle");
	MacroShowSubTitle.ShowPage(text, duration, voiceType);
end

function MacroAddSubTitle.OnClickSelcetNarrator(name, value)
	-- if value == MacroAddSubTitle.lastVoiceType then
	-- 	return
	-- end

	-- if value >= 0 and not System.User.isVip then
	-- 	page:SetValue("voiceType", MacroAddSubTitle.lastVoiceType or -1);
	-- 	local VipToolNew = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VipToolTip/VipToolNew.lua")
	-- 	VipToolNew.Show("recorder")
	-- 	return
	-- end
end

function MacroAddSubTitle.OnTextChange()
	-- if not System.User.isVip then
	-- 	page:SetValue("voiceType", -1);
	-- end
end