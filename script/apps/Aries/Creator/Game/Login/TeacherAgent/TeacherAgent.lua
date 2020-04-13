--[[
Title: Teacher agent
Author(s): LiXizhi
Date: 2018/9/18
Desc: singleton class that hook to global user events and show relevant tutorials to the user. 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/TeacherAgent/TeacherAgent.lua");
local TeacherAgent = commonlib.gettable("MyCompany.Aries.Creator.Game.Teacher.TeacherAgent");
TeacherAgent:SetEnabled(true)
TeacherAgent:AddKnowledgeFromFile("script/apps/Aries/Creator/Game/Login/TeacherAgent/test/test.knowledgedomain.xml")
TeacherAgent:BeginTeach()
TeacherAgent:NewExperience("action", "setblock CodeBlock")
TeacherAgent:EndTeach()
-- TeacherAgent:AddTaskButton("btnLesson", "Texture/Aries/AppIcons/summerswim.png", function()  end, 3)
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/headon_speech.lua");
NPL.load("(gl)script/ide/STL.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/TeacherAgent/TeacherIcon.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/TeacherAgent/Agent.lua");
local Agent = commonlib.gettable("MyCompany.Aries.Creator.Game.Teacher.Agent");
local TeacherIcon = commonlib.gettable("MyCompany.Aries.Creator.Game.Teacher.TeacherIcon");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")

local TeacherAgent = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Creator.Game.Teacher.Agent"), commonlib.gettable("MyCompany.Aries.Creator.Game.Teacher.TeacherAgent"));
TeacherAgent:Property("Name", "TeacherAgent");

function TeacherAgent:ctor()
	self.buttons = commonlib.ArrayMap:new();
	TeacherIcon.SetEmptyClickCallback(TeacherAgent.OnClickTeacherIcon);
end

function TeacherAgent:Init()
	if(self.inited) then
		return
	end
	self.inited = true
end

function TeacherAgent:SetEnabled(enabled)
	if(enabled) then
		self:Init()
	end
	if(self.enabled ~= enabled) then
		self.enabled = enabled;
		if(enabled) then
			self:ShowIcon(true);
		else
			self:RefreshUI(100);
		end
	end
end

function TeacherAgent:IsEnabled()
	return self.enabled;
end

-- make inactive for this amount of time
function TeacherAgent:Sleep(seconds)
end

function TeacherAgent:ShowIcon(bShow)
	TeacherIcon.Show(bShow)
end

function TeacherAgent:HasPendingTask()
	return self.buttons:size() > 0;
end

-- refresh UI
function TeacherAgent:RefreshUI(delayTime)
	if(not self:IsEnabled() and not self:HasPendingTask()) then
		commonlib.TimerManager.SetTimeout(function()  
			if(not self:IsEnabled() and not self:HasPendingTask()) then
				self:ShowIcon(false)
			end
		end, delayTime or 2000)
	else
		self:ShowIcon(true)
	end
end

-- @param max_duration: in seconds. if nil or -1 means always show
function TeacherAgent:ShowTipText(htmlText, max_duration)
	if(htmlText and htmlText~="") then
		TeacherIcon.Show(true)
		TeacherIcon.SetTipText(htmlText);

		if(max_duration and max_duration > 0) then
			self.mytimer = self.mytimer or commonlib.Timer:new({callbackFunc = function(timer)
				self:ShowTipText(nil);
			end})
			self.mytimer:Change(math.floor(max_duration*1000));
		elseif(self.mytimer) then
			self.mytimer:Change();
		end
	else
		TeacherIcon.SetTipText();
		self:RefreshUI(2000);
		if(self.mytimer) then
			self.mytimer:Change();
		end
	end
end

-- show tip on a given target player as headon display
function TeacherAgent:ShowTipOnTarget(target, text, duration)
	if(target) then
		if(text and text~="") then
			headon_speech.Speek(target, text, duration or 12, true);
		else
			headon_speech.Speek(target, "", 0, true);
		end
	end
end

function TeacherAgent:ShowDialog(url, max_duration)
end

function TeacherAgent:ShowUITracker(url)
end

-- return x,y screen position or nil if agent is not visible.
function TeacherAgent:GetIconPosition()
	return TeacherIcon.GetIconPosition();
end

function TeacherAgent:AddTaskButton(btnName, iconFilename, onclickCallbackFunc, count, priority, tooltip)
	local btn = self.buttons:contains(btnName)
	if(not btn) then
		self.buttons:add(btnName, {name=btnName, icon=iconFilename, onclick=onclickCallbackFunc, count = count, priority = priority or 0, tooltip = tooltip})
	end
	TeacherIcon.UpdateTaskButtons(self.buttons)
end

function TeacherAgent:UpdateTaskButtonCount(btnName, count)
	TeacherIcon.UpdateTaskButtons(self.buttons)
end

-- return true if btnName is found and removed
function TeacherAgent:RemoveTaskButton(btnName)
	if(self.buttons:contains(btnName)) then
		self.buttons:remove(btnName)
		TeacherIcon.UpdateTaskButtons(self.buttons)
		return true;
	end
end

function TeacherAgent:OnClickTeacherIcon()
	-- TODO: 
	-- GameLogic.RunCommand("/menu help.help");
end

-- virtual function: a note is selected to teach
function TeacherAgent:TeachNote(note)
end

TeacherAgent:InitSingleton();	