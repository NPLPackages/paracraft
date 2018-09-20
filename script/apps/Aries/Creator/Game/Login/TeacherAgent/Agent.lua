--[[
Title: agent base class
Author(s): LiXizhi
Date: 2018/9/18
Desc: An agent may be configured to teach any number of knowledge domains. 
An agent observes the user actions by examine the virtual worlds near the user avatar, especially those near the mouse cursor.
We wants to make sure the agent's attention matches the attention of the real user.
In addition to 3d, an agent also pays attention to text on 2D GUI interface. This is done by inserting annotations in mcml text code. 
`pe:annotation` is a special mcml tag that is only used by an agent. 
More over, an agent also hooks to user action filters, those user actions are recognized and converted to text for matching a note in knowledge domain. 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/TeacherAgent/Agent.lua");
local Agent = commonlib.gettable("MyCompany.Aries.Creator.Game.Teacher.Agent");
local agent = Agent:new()
agent:AddKnowledgeFromFile("script/apps/Aries/Creator/Game/Login/TeacherAgent/test/test.knowledgedomain.xml")
agent:BeginTeach()
agent:NewExperience("action", "setblock CodeBlock")
agent:EndTeach()
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Login/TeacherAgent/KnowledgeDomain.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/TeacherAgent/Experience.lua");
local Experience = commonlib.gettable("MyCompany.Aries.Creator.Game.Teacher.Experience");
local KnowledgeDomain = commonlib.gettable("MyCompany.Aries.Creator.Game.Teacher.KnowledgeDomain");
local Agent = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Creator.Game.Teacher.Agent"));
Agent:Property("Name", "Agent");
Agent:Signal("experienceAdded", function(exp) end)
Agent:Signal("noteActivated", function(note) end)

function Agent:ctor()
	-- mapping from knowledge domain name to knowledge domain
	self.knowledgeDomains = {};
	self.experiences = {};
	-- mapping from triggering experience key to array of notes
	self.triggerExpsToNotes = {};
	-- mapping from experience key to array of notes
	self.expsToNotes = {};
end

-- load static knowledge domain from file, one can call this multiple times to load from multiple files
-- the same domain may also be splitted into multiple files. 
function Agent:AddKnowledgeFromFile(filename)
	local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
	if(not xmlRoot) then
		LOG.std(nil, "warn", "agent", "file %s not found", filename);
	end
	local node = commonlib.XPath.selectNode(xmlRoot, "/KnowledgeDomains") or {};
	for k,v in ipairs(node) do
		if(v.name == "KnowledgeDomain") then
			local name = v.attr.name;
			local domain = self.knowledgeDomains[name]
			if(not domain) then
				domain = KnowledgeDomain:new():Init(self);
				self.knowledgeDomains[name] = domain;
			end
			domain:LoadFromXMLNode(v);
			LOG.std(nil, "info", "agent", "knowledge domain: %s loaded with %d notes", name, domain:GetNoteCount());
		end
	end
end

function Agent:GetKnowledgeDomain(name)
	return self.knowledgeDomains[name];
end

-- load all user experiences from a file
function Agent:LoadExperiences()
	-- TODO
end

-- reset and clear all user experiences
function Agent:ClearExperiences()
	self.experiences = {};
end

function Agent:GetExperiences()
	return self.experiences;
end

function Agent:NewExperience(type, data)
	self:AddExperience(Experience:new():Init(type, data));
end

function Agent:AddExperience(experience)
	local exp = self.experiences[experience:GetKey()];
	if(not exp) then
		exp = experience;
		self.experiences[experience:GetKey()] = experience;
	end
	exp:Activate();

	self:experienceAdded(exp);

	self:UpdateLearningWeightByExp(exp);

	if(self:IsTeaching()) then
		if(self:GetCurrentNode() and self:GetCurrentNode():IsLearned()) then
			self:DeactivateNote()
		end
		local note = self:PickTeachingNoteByExp(exp)
		if(note) then
			self:ActivateNote(note)
		end
	end
end

function Agent:ActivateNote(note)
	if(self.curNote ~= note) then
		self.curNote = note;
	end
	note:Activate();
	self:noteActivated(note);
	self:TeachNote(note);
end

function Agent:GetCurrentNode()
	return self.curNote;
end

-- @param exp: the newly added experience. notes containing this experience will 
--  have their learning weight rebuilt
function Agent:UpdateLearningWeightByExp(exp)
	local myExps = self:GetExperiences()
	local notes = self:GetNotesByExperience(exp)
	if(notes) then
		for _, note in ipairs(notes) do
			note:ComputeLearningWeight(myExps);
		end
	end
end

function Agent:DeactivateNote()
	local note = self.curNote;
	if(note) then
		self.curNote = nil;
	end
end

-- TeachNote will be called between BeginTeach() and EndTeach()
function Agent:BeginTeach()
	self.isTeaching = true;
	if(not self.isWeightTableBuilt) then
		self.isWeightTableBuilt = true;
		self:RebuildWeightTable();
	end
end

-- virtual function: a note is selected to teach
function Agent:TeachNote(note)
	LOG.std(nil, "debug", "agent", "note %s is taught", note.id or "");
end

function Agent:IsTeaching()
	return self.isTeaching;
end

function Agent:EndTeach()
	self:DeactivateNote();
	self.isTeaching = false;
end

function Agent:RebuildWeightTable()
	local myExperiences = self:GetExperiences();
	self.triggerExpsToNotes = {};
	local triggers = self.triggerExpsToNotes;
	local exps = self.expsToNotes;
	for _, domain in pairs(self.knowledgeDomains) do
		for _, note in domain:iterator_notes() do
			if(note:ComputeLearningWeight(myExperiences)>0) then
				note:AddToTriggers(triggers)
				note:AddToExps(exps)
			end
		end
	end
end

-- @param experience: only its key is used, so one can possibly use just a static experience class. 
-- return nil or an array of notes whose triggers contains the given experience.
function Agent:GetNotesByTriggeredExperience(experience)
	return self.triggerExpsToNotes[experience:GetKey()]
end

function Agent:GetNotesByExperience(experience)
	return self.expsToNotes[experience:GetKey()]
end

function Agent:PickTeachingNoteByExp(exp)
	local notes = self:GetNotesByTriggeredExperience(exp)
	if(notes) then
		local candidateNote, candidateWeight = nil, 0;
		for _, note in ipairs(notes) do
			if(not note:IsLearned()) then
				local noteWeight = note:GetLearningWeight()
				if(noteWeight > candidateWeight) then
					candidateNote = note;
					candidateWeight = noteWeight;
				end
			end
		end
		return candidateNote;
	end
end