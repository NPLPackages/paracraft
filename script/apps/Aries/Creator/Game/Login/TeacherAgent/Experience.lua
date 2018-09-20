--[[
Title: Experience
Author(s): LiXizhi
Date: 2018/9/18
Desc: Experience is a record of performed user actions in the history. We will keep track of what experiences the
user already have, and only teach them new experiences. 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/TeacherAgent/Experience.lua");
local Experience = commonlib.gettable("MyCompany.Aries.Creator.Game.Teacher.Experience");
-------------------------------------------------------
]]
local Experience = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Creator.Game.Teacher.Experience"));
Experience:Property("Name", "Experience");
Experience:Property({"activationCount", 0, "GetActivationCount", "SetActivationCount", auto=true});

function Experience:ctor()
end

function Experience:Init(type, data)
	self.type = type;
	self.data = data;
	self.key = nil;
	return self;
end

function Experience:GetKey()
	if(not self.key) then
		self.key = format("%s %s", self.type or "", self.data or "");
	end
	return self.key;
end

function Experience:Activate()
	self.activationCount = self.activationCount + 1;
end

function Experience:GetActivationCount()
	return self.activationCount;
end