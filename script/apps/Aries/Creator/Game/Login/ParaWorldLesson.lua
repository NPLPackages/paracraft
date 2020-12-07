--[[
Title: ParaWorldLesson
Author(s): LiXizhi
Date: 2018/10/12
Desc: represent a single lesson on keepwork.com

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ParaWorldLesson.lua");
local ParaWorldLesson = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ParaWorldLesson")
local lesson = ParaWorldLesson:new():Init(lessonId, packageId)
-------------------------------------------------------
]]
local ParaWorldLessons = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ParaWorldLessons")

local ParaWorldLesson = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.MainLogin.ParaWorldLesson"))

-- set this to true when keepwork `?token=` signin is fully supported. 
ParaWorldLesson.autoSigninWebUrl = true;

function ParaWorldLesson:ctor()
	self.finishedQuizCount = 0;
	self.clientData = {};
end

-- @param id: lesson id
function ParaWorldLesson:Init(lessonId, packageId)
	self.id = lessonId;
	self.packageId = packageId;
	self.startTime = commonlib.TimerManager.GetCurrentTime();
	return self;
end

function ParaWorldLesson:SetClassId(classId)
	self.classId = classId;
end

-- @param goals: text
function ParaWorldLesson:SetGoals(goals)
	self.goals = goals;
end

function ParaWorldLesson:GetGoals()
	return self.goals or "";
end

function ParaWorldLesson:SetContent(txtMarkdown)
	self.content = txtMarkdown;
end

function ParaWorldLesson:SetName(name)
	self.name = name;
end

function ParaWorldLesson:GetName()
	return self.name or "";
end

function ParaWorldLesson:SetUserName(username)
	if(username) then
		self.clientData.username = username;
		self.clientData.name = username;
	end
end

function ParaWorldLesson:GetUserName()
	return self.clientData.username;
end

function ParaWorldLesson:SetRecordId(recordId)
	self.recordId = recordId;
end

function ParaWorldLesson:GetRecordId()
	return self.recordId;
end

function ParaWorldLesson:GetClassId()
	return self.classId;
end

function ParaWorldLesson:SetUserId(userId)
	self.userId = userId;
end

function ParaWorldLesson:GetUserId()
	return self.userId;
end

function ParaWorldLesson:SetUserToken(userToken)
	self.userToken = userToken;
end

function ParaWorldLesson:GetUserToken()
	return self.userToken;
end

function ParaWorldLesson:SetClientData(data)
	if(data) then
		self.clientData = data;
	end
end

function ParaWorldLesson:GetClientData()
	return self.clientData;
end

-- @param callbackFunc: function(worldUrl) end
function ParaWorldLesson:GetFirstWorldUrl(callbackFunc)
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
					line = line:match("^%s*link:%s*(.+)%s*$")
					if(line) then
						line = line:gsub("^['\"](.+)['\"]$", "%1");
						url = line:match("(https?://[^\r\n]+)");
						if(url) then
							break
						else
							bSearchNextLine = true
						end
					end
				elseif(bSearchNextLine) then
					url = line:match("(https?://[^\r\n]+)");
					break;
				end
			end
		end	
		local projectMod = self.content:match("\n(```@[pP]roject[^`]+)");
		if(projectMod and (not url or url=="")) then
			for line in projectMod:gmatch("([^\r\n]+)\r?\n") do
				local projectId = line:match("^%s*projectId:%s*(.+)%s*$")
				if(projectId) then
					projectId = projectId:gsub("^['\"](.+)['\"]$", "%1");
					projectId = tonumber(projectId);
					if(projectId) then
						GameLogic.GetFilters():apply_filters('get_world_by_project_id', projectId, function(worldInfo)
							if worldInfo and worldInfo.archiveUrl then
								self.worldUrl = worldInfo.archiveUrl;
							end
							if(callbackFunc) then
								callbackFunc(self.worldUrl)
							end
						end);
					end
				end
			end
			return self.worldUrl;
		end
		self.worldUrl = url;
	end
	if(callbackFunc) then
		callbackFunc(self.worldUrl)
	end
	return self.worldUrl
end

function ParaWorldLesson:GetPackageId()
	return self.packageId or 0;
end

function ParaWorldLesson:GetLessonId()
	return self.id or 0;
end

function ParaWorldLesson:GetLessonUrl()
	if(not self.lessonUrl) then
		self.lessonUrl = format(
			"%s/l/visitor/package/%d/lesson/%d",
			GameLogic.GetFilters():apply_filters('get_keepwork_base_url'),
			self:GetPackageId(),
			self:GetLessonId()
		)
	end
	return self.lessonUrl;
end

function ParaWorldLesson:HasOpenedUrl()
	return self.hasOpenedUrl;
end

function ParaWorldLesson:OpenLessonUrl()
	self.hasOpenedUrl = true;
	local url = self:GetLessonUrl()
	if(url) then
		if(self:GetClassId()) then
			self:OpenLessonUrlDirect();	
		else
			NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ParaWorldLoginDocker.lua");
			local ParaWorldLoginDocker = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ParaWorldLoginDocker")
			ParaWorldLoginDocker.SignIn(L"登陆后才能访问课程系统, 请先登录", function(bSucceed)
				if(bSucceed) then
					self:OpenLessonUrlDirect();	
				end
			end)
		end
	end
end

function ParaWorldLesson:BuildUrlWithToken(url)
	if(self:GetClassId() or self.autoSigninWebUrl) then
		local token = self:GetUserToken() or (self.autoSigninWebUrl and System.User.keepworktoken);
		if(token) then
			url = format("%s?id=%d&key=%d&token=%s&device=paracraft", url, self:GetRecordId() or 0, self:GetClassId() or 0, token);
		end
	end
	return url;
end

function ParaWorldLesson:OpenLessonUrlDirect()
	local url = self:GetLessonUrl()
	if(url) then
		url = self:BuildUrlWithToken(url)
		ParaGlobal.ShellExecute("open", url, "", "", 1)
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

-- @param callbackFunc: function(bSucceed, localWorldPath)
function ParaWorldLesson:EnterWorld(callbackFunc)
	self:GetFirstWorldUrl(function(worldUrl) 
		if(worldUrl and worldUrl~="") then
			LOG.std(nil, "info", "ParaWorldLessons", "try entering world %s", worldUrl);

			NPL.load("(gl)script/apps/Aries/Creator/Game/Login/DownloadWorld.lua");
			local DownloadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.DownloadWorld")
			DownloadWorld.ShowPage(worldUrl);

			NPL.load("(gl)script/apps/Aries/Creator/Game/Login/RemoteWorld.lua");
			local RemoteWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.RemoteWorld");
			local world =RemoteWorld.LoadFromHref(worldUrl, "self");

			NPL.load("(gl)script/apps/Aries/Creator/Game/Login/InternetLoadWorld.lua");
			local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld");
			InternetLoadWorld.LoadWorld(world, nil, nil, function(bSucceed, localWorldPath)
				DownloadWorld.Close();
				if(callbackFunc) then
					callbackFunc(bSucceed, localWorldPath);
				end
			end)
		end
	end)
end

function ParaWorldLesson:GetSummaryMCML()
	if(not self.summary_mcml) then
		local text = format("<div style='color:#cc3300'>%s</div>", self:GetName()) 
		if(self:GetGoals()~="")then
			text = text..format("目标:%s<br/>", self:GetGoals());
		end
		local nQuizCount = self:GetQuizCount();
		if(nQuizCount>0) then
			text = text.."<br/>"..format(L"课程包含%d个问题", nQuizCount);
		end
		self.summary_mcml = text;
	end
	return self.summary_mcml;
end

-- obsoleted: update learning record from client to server
function ParaWorldLesson:SendRecord()
	local userId = self:GetUserId() or 0;
	local learnAPIUrl;
	if(self:GetRecordId()) then
		learnAPIUrl = format(
			"%s/lesson/v0/learnRecords/%d",
			GameLogic.GetFilters():apply_filters('get_keepwork_base_url'),
			self:GetRecordId()
		);
		learnAPIUrl = self:BuildUrlWithToken(learnAPIUrl)
		return ParaWorldLessons.UrlRequest(learnAPIUrl , "PUT", {id=userId, extra = self:GetClientData()}, function(err, msg, data)
			LOG.std(nil, "debug", "ParaWorldLessons", "send record returned:", err);
		end)
	end
end