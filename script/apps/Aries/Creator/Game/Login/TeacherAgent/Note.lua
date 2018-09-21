--[[
Title: Signifcant Experience Expressed as a Note
Author(s): LiXizhi
Date: 2018/9/18
Desc: A note is text sentence that represent a significant experience that can be taught to the user. 
A note may be triggered by tags or user actions. In most cases, a note must be experienced in order to be learned by a user. 

Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/TeacherAgent/Note.lua");
local Note = commonlib.gettable("MyCompany.Aries.Creator.Game.Teacher.Note");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/TeacherAgent/Experience.lua");
local Experience = commonlib.gettable("MyCompany.Aries.Creator.Game.Teacher.Experience");

local Note = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Creator.Game.Teacher.Note"));
Note:Property("Name", "Note");
Note:Property({"maxRepeats", 4, auto=true});
Note:Property({"learnWeight", 1});
-- milliseconds to prevent the note from being activated again 
Note:Property({"inactiveTimeRange", 1000});
Note:Property({"shortMemoryTimeRange", 120000});
Note:Property({"content", "empty note", "GetContent", "SetContent", auto = true});

function Note:ctor()
	-- mapping from experience key to experience
	self.experiences = {}; 
	-- mapping from triggering experience key to experience
	self.triggers = {};
end

function Note:Init()
	return self;
end

function Note:LoadFromXMLNode(node)
	local attr = node.attr;
	if(attr) then
		self.id = attr.id;
		if(attr.maxRepeats) then
			self.maxRepeats = tonumber(attr.maxRepeats);
		end
	end

	for _, item in ipairs(node) do
		if(item.name == "content") then
			self:SetContent(L(item[1]));
		elseif(item.name == "triggers") then
			for _, exp in ipairs(item) do
				local experience = Experience:new():Init(exp.name, exp[1]);
				self.triggers[experience:GetKey()] = experience;
			end
		elseif(item.name == "experiences") then
			for _, exp in ipairs(item) do
				local experience = Experience:new():Init(exp.name, exp[1]);
				self.experiences[experience:GetKey()] = experience;
			end
		end
	end
end

-- compute learning weight, 0 means this note no longer needs to be learned. 
-- 1 means we still needs to practice and learn
function Note:ComputeLearningWeight(myExperiences)
	local weight = 0;
	for _, exp in pairs(self.experiences) do
		local existingExp = myExperiences[exp:GetKey()];
		if(not existingExp or existingExp:GetActivationCount() >= self.maxRepeats) then
			weight = 1;
			break;
		end
	end
	self.learnWeight = weight;
	return weight;
end

function Note:IsLearned()
	return self.learnWeight == 0;
end

-- return usually between 0 and 1
function Note:GetLearningWeight()
	if(self.lastTriggerTime) then
		local timeSinceLastActivation = commonlib.TimerManager.GetCurrentTime() - self.lastTriggerTime; 
		if(self.shortMemoryTimeRange <= timeSinceLastActivation) then
			self.lastTriggerTime = nil;
		elseif(timeSinceLastActivation < self.inactiveTimeRange) then
			return 0;
		else
			return self.learnWeight * (1 - timeSinceLastActivation / self.shortMemoryTimeRange);
		end
	end
	return self.learnWeight;
end

function Note:AddToTriggers(triggers)
	for _, exp in pairs(self.triggers) do
		local list = triggers[exp:GetKey()];
		if(not list) then
			list = {};
			triggers[exp:GetKey()] = list;
		end
		list[#list+1] = self;
	end
end

function Note:AddToExps(exps)
	for _, exp in pairs(self.experiences) do
		local list = exps[exp:GetKey()];
		if(not list) then
			list = {};
			exps[exp:GetKey()] = list;
		end
		list[#list+1] = self;
	end
end


function Note:Activate()
	self.lastTriggerTime = commonlib.TimerManager.GetCurrentTime();
end

function Note:HasExperience(exp)
	return self.experiences[exp:GetKey()] ~= nil;
end
