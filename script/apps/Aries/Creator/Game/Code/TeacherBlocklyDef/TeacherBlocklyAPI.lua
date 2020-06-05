--[[
Title: Teacher Block 
Author(s): 
Date: 
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
	self.type = type;
end

function TeacherBlocklyAPI:SetTeacherNPCTasks(tasks)
	if (tasks and type(tasks) == "table") then
		TeachingQuestPage.RegisterTasksChanged(function(show)
			self:ShowHeadOn(show);
		end, self.type);
		TeachingQuestPage.AddTasks(tasks, self.type);
		self:InvokeMethod("registerClickEvent", function()
			TeachingQuestPage.ShowPage(self.type);
		end);
	end
end

function TeacherBlocklyAPI:ShowHeadOn(show)
	if (not self.obj) then return end

	if (show) then
		local name = headon_speech.Speek(self.obj, "<img style=\"margin-left:15px;width:13px;height:51px;background:url(Texture/Aries/HeadOn/exclamation.png#0 0 13 51);\" />", -1, nil, true);
		local control = ParaUI.GetUIObject(name);
		control.y = control.y - 10;
		local up = false;
		self.mytime = self.mytime or commonlib.Timer:new({callbackFunc = function(timer)
			if (up) then
				up = false;
				control.y = control.y + 5;
			else
				up = true;
				control.y = control.y - 5;
			end
			control:ApplyAnim();
		end});
		self.mytime:Change(100, 200);
	else
		headon_speech.SpeakClear(self.obj);
		self.mytime:Change();
		self.mytime = nil;
	end
end
