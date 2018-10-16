--[[
Title: ParaWorldLesson
Author(s): LiXizhi
Date: 2018/10/12
Desc: represent a single lesson on keepwork.com

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ParaWorldLesson.lua");
local ParaWorldLesson = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ParaWorldLesson")
local lesson = ParaWorldLesson:new():Init(id, url, content)
-------------------------------------------------------
]]
local ParaWorldLesson = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.MainLogin.ParaWorldLesson"))

function ParaWorldLesson:ctor()
	self.finishedQuizCount = 0;
end

-- @param id: class or lesson id
-- @param lessonUrl: lesson url address
-- @param content: markdown text
function ParaWorldLesson:Init(id, lessonUrl, content)
	self.id = id;
	self.lessonUrl = lessonUrl;
	self.content = content;
	self.startTime = commonlib.TimerManager.GetCurrentTime();
	return self;
end

function ParaWorldLesson:GetFirstWorldUrl()
	if(not self.worldUrl) then
		local url = ""; 
		local paracraftMod = self.content:match("\n(```@[pP]aracraft[^`]+)");
		if(paracraftMod) then
			local bInsideDownload;
			local bSearchNextLine;
			for line in paracraftMod:gmatch("([^\r\n]+)\r?\n") do
				if(not bInsideDownload and line:match("^download")) then
					bInsideDownload = true;
				elseif(bInsideDownload and line:match("^%s*link:")) then
					url = line:match("(https?://[^\r\n]+)");
					if(url) then
						break
					else
						bSearchNextLine = true
					end
				elseif(bSearchNextLine) then
					url = line:match("(https?://[^\r\n]+)");
					break;
				end
			end
		end	
		self.worldUrl = url;
	end
	return self.worldUrl
end

function ParaWorldLesson:OpenLessonUrl()
	if(self.lessonUrl) then
		ParaGlobal.ShellExecute("open", self.lessonUrl, "", "", 1)
	end
end

function ParaWorldLesson:GetElapsedTime()
	return commonlib.TimerManager.GetCurrentTime() - self.startTime;
end

function ParaWorldLesson:GetAllQuizes()
	if(not self.quizes) then
		self.quizes = {};
		NPL.load("(gl)script/ide/System/Util/tinyyaml.lua");
		local tinyyaml = commonlib.gettable("System.Util.tinyyaml");
		for quiz in self.content:gmatch("\n```@[Qq]uiz([^`]+)") do
			local docs = tinyyaml.parse(quiz);
			if(docs and docs.quiz) then
				self.quizes[#self.quizes+1] = docs.quiz;
			end
		end
		-- echo(self.quizes)
	end
	return self.quizes;
end

function ParaWorldLesson:GetQuizCount()
	return #(self:GetAllQuizes());
end

-- @param index: if nil, it will be the next quiz
function ParaWorldLesson:ShowQuiz(index)
end

function ParaWorldLesson:SubmitAnswers()
end

function ParaWorldLesson:IsFinished()
end

function ParaWorldLesson:GetFinishedQuizCount()
	return self.finishedCount;
end
