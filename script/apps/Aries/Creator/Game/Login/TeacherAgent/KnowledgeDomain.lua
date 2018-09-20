--[[
Title: knowledge domain
Author(s): LiXizhi
Date: 2018/9/18
Desc: Each domain of knowledge can be activated and taught via an agent interface. 
A knowledge domain contains a dynamic pool of persistent experiences per user and a static memory of Notes that should be taught to the user. 
Once all notes are experienced for enough number of times, we will mark the knowledge domain as mastered. 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/TeacherAgent/KnowledgeDomain.lua");
local KnowledgeDomain = commonlib.gettable("MyCompany.Aries.Creator.Game.Teacher.KnowledgeDomain");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/TeacherAgent/Note.lua");
local Note = commonlib.gettable("MyCompany.Aries.Creator.Game.Teacher.Note");
local KnowledgeDomain = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Creator.Game.Teacher.KnowledgeDomain"));

KnowledgeDomain:Property("Name", "KnowledgeDomain");
KnowledgeDomain:Property({"isMastered", false, "IsMastered", "SetMastered", auto=true});
-- the higher the more important and need to be learned first. typically 1-10
KnowledgeDomain:Property({"weight", 1, "GetWeight", "SetWeight", auto=true});

function KnowledgeDomain:ctor()
	self.notes = {};
end

function KnowledgeDomain:Init(agent)
	self.agent = agent;
	return self;
end

function KnowledgeDomain:GetNoteCount()
	return #self.notes;
end

function KnowledgeDomain:LoadFromXMLNode(node)
	local attr = node.attr;
	if(attr) then
		self.name = attr.name;
		if(attr.weight) then
			self:SetWeight(tonumber(attr.weight));
		end
	end
	for _, noteNode in ipairs(node) do
		local note = Note:new();
		note:LoadFromXMLNode(noteNode);
		self.notes[#self.notes + 1] = note;
	end
	return self;
end

-- iterator of all notes
function KnowledgeDomain:iterator_notes()
	return ipairs(self.notes);
end