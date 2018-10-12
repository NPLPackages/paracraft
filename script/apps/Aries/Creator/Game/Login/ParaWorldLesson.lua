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
end

-- @param id: class or lesson id
-- @param lessonUrl: lesson url address
-- @param content: markdown text
function ParaWorldLesson:Init(id, lessonUrl, content)
	self.id = id;
	self.lessonUrl = lessonUrl;
	self.content = content;
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