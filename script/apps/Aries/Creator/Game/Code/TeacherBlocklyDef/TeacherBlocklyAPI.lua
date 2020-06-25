--[[
Title: Teacher Block 
Author(s): chenjinxian
Date: 2020/6/1
Desc: 
use the lib:
-------------------------------------------------------
local TeacherBlocklyAPI = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/TeacherBlocklyDef/TeacherBlocklyAPI.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/headon_speech.lua");
local TeachingQuestPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeachingQuest/TeachingQuestPage.lua");
local TeacherBlocklyAPI = commonlib.inherit(nil, NPL.export());

function TeacherBlocklyAPI:ctor()
	self.type = "program";
end

-- private:invoke code block API 
function TeacherBlocklyAPI:InvokeMethod(name, ...)
	return self.codeEnv[name](...);
end

local publicMethods = {
"BecomeTeacherNPC", "SetTeacherNPCTasks",
}

-- create short cut in code API
function TeacherBlocklyAPI:InstallAPIToCodeEnv(codeEnv)
	for _, func_name in ipairs(publicMethods) do
		local func = self[func_name];
		if(type(func) == "function") then
			codeEnv[func_name] = function(...)
				return func(self, ...);
			end
		end
	end
end

function TeacherBlocklyAPI:Init(codeEnv)
	local fileName = "script/UIAnimation/CommonBounce.lua.table";
	UIAnimManager.LoadUIAnimationFile(fileName);
	self.codeEnv = codeEnv;
	self:InstallAPIToCodeEnv(codeEnv);
		
	-- global functions for canvas
	return self;
end

-- @param penBlockId: default to 10
function TeacherBlocklyAPI:BecomeTeacherNPC(type)
	local actor = self:InvokeMethod("getActor", "myself");
	if (actor) then
		self.obj = actor:GetEntity():GetInnerObject();
	end

	self.type = TeachingQuestPage.TaskTypeIndex[type] or TeachingQuestPage.UnknowType;
end

function TeacherBlocklyAPI:SetTeacherNPCTasks(tasks)
	if (tasks and type(tasks) == "table") then
		TeachingQuestPage.RegisterTasksChanged(function(state)
			self:ShowHeadOn(state);
		end, self.type);
		TeachingQuestPage.AddTasks(tasks, self.type);
		self:InvokeMethod("registerClickEvent", function()
			TeachingQuestPage.ShowPage(self.type);
		end);
	end
end

function TeacherBlocklyAPI:ShowHeadOn(state)
	if (not self.obj) then return end
		local actor_name = {L"编程导师", L"动画导师", L"CAD导师", L"机器人导师"};
		if (state == TeachingQuestPage.AllFinished) then
			local headon_mcml = string.format(
				[[<div style="width:80px;height:20px;">
					<div style="margin-top:20px;width:80px;height:20px;text-align:center;color:#00ff00;font-size:14px;font-weight:bold">%s</div>
				</div>]],
				actor_name[self.type]);
			headon_speech.Speak(self.obj, headon_mcml, -1, nil, true, nil, -100);
		else
			local state_img = {"Texture/Aries/HeadOn/exclamation.png", "Texture/Aries/HeadOn/question.png"};
			local left = {"32px", "24px"};
			local width = {"16px", "32px"};
			local headon_mcml = string.format(
				[[<div style="width:80px;height:80px;">
					<img style="margin-left:%s;width:%s;height:64px;background:url(%s);" />
					<div style="margin-top:20px;width:80px;height:20px;text-align:center;color:#00ff00;font-size:14px;font-weight:bold">%s</div>
				</div>]],
				left[state], width[state], state_img[state], actor_name[self.type]);

			local ctl_name = headon_speech.Speak(self.obj, headon_mcml, -1, nil, true, nil, -100);
			local _parent = ParaUI.GetUIObject(ctl_name);
			local img = _parent:GetChildAt(0):GetChildAt(0);
			local fileName = "script/UIAnimation/CommonBounce.lua.table";
			UIAnimManager.PlayUIAnimationSequence(img, fileName, "ShakeUD", true);
		end
end
