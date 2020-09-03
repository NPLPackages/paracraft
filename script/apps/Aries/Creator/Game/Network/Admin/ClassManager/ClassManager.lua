--[[
Title: Teacher Panel
Author(s): Chenjinxian
Date: 2020/8/6
Desc: 
use the lib:
-------------------------------------------------------
local ClassManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/ClassManager.lua");
ClassManager.StaticInit();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.class.lua");
NPL.load("(gl)script/apps/Aries/BBSChat/ChatSystem/ChatChannel.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/LockDesktop.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local ChatChannel = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatChannel");
local KpChatChannel = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/KpChatChannel.lua");
local TeacherPanel = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/TeacherPanel.lua");
local StudentPanel = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/StudentPanel.lua");
local TChatRoomPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/TChatRoomPage.lua");
local SChatRoomPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/SChatRoomPage.lua");
local ShareUrlContext = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/ShareUrlContext.lua");
local LockDesktop = commonlib.gettable("MyCompany.Aries.Game.Tasks.LockDesktop");
local ClassManager = NPL.export()

ClassManager.InClass = false;
ClassManager.IsLocking = false;
ClassManager.InGGS = false;
ClassManager.CanSpeak = true;

ClassManager.CurrentClassId = nil;
ClassManager.CurrentWorldId = nil; 
ClassManager.CurrentClassroomId = nil;
ClassManager.CurrentClassName = nil;
ClassManager.CurrentWorldName = nil; 

ClassManager.OrgClassIdMap = {};
ClassManager.ClassList = {};
ClassManager.ProjectList = {};
ClassManager.ShareLinkList = {};
-- {} userId, username, nickname, teacher, online, inclass
ClassManager.ClassMemberList = {};

ClassManager.ChatDataList = {};
ClassManager.ChatDataMax = 200;

local init = false;
function ClassManager.StaticInit()
	--GameLogic:Connect("WorldLoaded", ClassManager, ClassManager.OnWorldLoaded, "UniqueConnection");
	--GameLogic:Connect("WorldUnloaded", ClassManager, ClassManager.OnWorldUnload, "UniqueConnection");
	if (init) then return end
	init = true;

	GameLogic.GetFilters():add_filter("OnKeepWorkLogin", ClassManager.OnKeepWorkLogin_Callback);
	GameLogic.GetFilters():add_filter("OnKeepWorkLogout", ClassManager.OnKeepWorkLogout_Callback)
end

function ClassManager.OnWorldLoaded()
	if (KpChatChannel.client) then
		commonlib.TimerManager.SetTimeout(function()
			local projectId = GameLogic.options:GetProjectId();
			if (projectId and tonumber(projectId) == ClassManager.CurrentWorldId) then
				GameLogic.events:AddEventListener("OnWorldUnload", ClassManager.OnWorldUnload, ClassManager, "ClassManager");
				return;
			end

			-- first load teacher classroom
			local roleId = 2;
			ClassManager.LoadOnlineClassroom(roleId, function(classId, projectId, classroomId, userId)
				if (classId and projectId and classroomId) then
					_guihelper.MessageBox("你所在的班级正在上课，即将自动进入课堂！");
					commonlib.TimerManager.SetTimeout(function()
						ClassManager.InClass = true;
						TeacherPanel.StartClass();
					end, 2000);
				else
					-- no teacher classroom, then load student classroom
					roleId = 1;
					ClassManager.LoadOnlineClassroom(roleId, function(classId, projectId, classroomId)
						if (classId and projectId and classroomId) then
							_guihelper.MessageBox("你所在的班级正在上课，是否直接进入课堂？", function(res)
								if(res and res == _guihelper.DialogResult.Yes)then
									ClassManager.InClass = true;
									StudentPanel.StartClass();
								else
									ClassManager.Reset();
								end
							end, _guihelper.MessageBoxButtons.YesNo);
						end
					end);
				end
			end);
		end, 2000)
	end
end

function ClassManager.OnWorldUnload(self, event)
	local projectId = GameLogic.options:GetProjectId();
	if (projectId and tonumber(projectId) == ClassManager.CurrentWorldId) then
		if (not ClassManager.IsTeacherInClass() and ClassManager.InClas) then
			ClassManager.SendMessage("tip:leave");
			ClassManager.LeaveClassroom(ClassManager.CurrentClassroomId);
		end
		ClassManager.Reset();
	end
end

function ClassManager.OnExitApp()
	local projectId = GameLogic.options:GetProjectId();
	if (projectId and tonumber(projectId) == ClassManager.CurrentWorldId) then
		if (ClassManager.IsTeacherInClass()) then
			if (ClassManager.IsLocking) then
				TeacherPanel.UnLock();
			end
			if (not ClassManager.CanSpeak) then
				TChatRoomPage.AllowChat();
			end
		end
	end
end

function ClassManager.OnKeepWorkLogin_Callback()
	if (KpChatChannel.client) then
		KpChatChannel.client:AddEventListener("OnOpen",ClassManager.OnOpen,ClassManager);
		KpChatChannel.client:AddEventListener("OnMsg",ClassManager.OnMsg,ClassManager);
		KpChatChannel.client:AddEventListener("OnClose",ClassManager.OnClose,ClassManager);
	end
	local worldName = WorldCommon.GetWorldTag("name");
	if (worldName ~= nil and worldName ~= "") then
		ClassManager.OnWorldLoaded();
	end
end

function ClassManager.OnKeepWorkLogout_Callback()
	if (KpChatChannel.client) then
		--[[
		if (ClassManager.IsTeacherInClass()) then
			if (ClassManager.IsLocking) then
				TeacherPanel.UnLock();
			end
			if (not ClassManager.CanSpeak) then
				TChatRoomPage.AllowChat();
			end
		end
		if (ClassManager.InClass) then
			ClassManager.SendMessage("tip:leave");
			ClassManager.LeaveClassroom(ClassManager.CurrentClassroomId);
		end
		ClassManager.Reset();
		]]
		KpChatChannel.client:RemoveEventListener("OnOpen",ClassManager.OnOpen,ClassManager);
		KpChatChannel.client:RemoveEventListener("OnMsg",ClassManager.OnMsg,ClassManager);
		KpChatChannel.client:RemoveEventListener("OnClose",ClassManager.OnClose,ClassManager);
	end
end

function ClassManager.OnOpen(self)
end

function ClassManager.OnClose(self)
end

function ClassManager.LoadAllClasses(callback)
	if (#ClassManager.ClassList > 0) then
		ClassManager.ClassList = {};
	end
	if (#ClassManager.OrgClassIdMap > 0) then
		ClassManager.OrgClassIdMap = {};
	end
	keepwork.userOrgInfo.get(nil, function(err, msg, data)
		local orgs = data and data.data and data.data.allOrgs;
		if (orgs == nil) then return end

		for i = 1, #orgs do
			keepwork.classes.get({cache_policy = "access plus 0", organizationId = orgs[i].id, roleId=2}, function(err, msg, data)
				local classes = data and data.data;
				if (classes == nil) then return end

				ClassManager.OrgClassIdMap[orgs[i].loginUrl] = {}
				for j = 1, #classes do
					if (classes[j].classId and classes[j].name) then
						table.insert(ClassManager.ClassList, classes[j]);
						ClassManager.OrgClassIdMap[orgs[i].loginUrl][j] = classes[j].classId;
					end
				end

				if (i == #orgs) then
					if (callback) then
						callback();
					end
				end
			end);
		end
	end);
end

function ClassManager.LoadAllProjects(callback)
	if (#ClassManager.ProjectList > 0) then
		ClassManager.ProjectList = {};
	end
	local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld');
	if (currentWorld and currentWorld.kpProjectId) then
		table.insert(ClassManager.ProjectList, {projectId = tonumber(currentWorld.kpProjectId), projectName = WorldCommon.GetWorldTag("name")});
	end
	keepwork.classroom.get({cache_policy = "access plus 0", roleId = 2}, function(err, msg, data)
		local rooms = data and data.data and data.data.rows;
		if (rooms) then
			local function findProject(id)
				for j = 1, #ClassManager.ProjectList do
					if (id == ClassManager.ProjectList[j].projectId) then
						return true;
					end
				end
				return false;
			end
			for j = 1, #rooms do
				if (not findProject(rooms[j].projectId)) then
					table.insert(ClassManager.ProjectList, {projectId = rooms[j].projectId, projectName = rooms[j].projectName});
				end
			end
		end

		if (callback) then
			callback();
		end
	end);
end

function ClassManager.LoadOnlineClassroom(roleId, callback)
	keepwork.classroom.get({cache_policy = "access plus 0", status = 1, roleId = roleId}, function(err, msg, data)
		local rooms = data and data.data and data.data.rows;
		if (rooms) then
			for i = 1, #rooms do
				if (rooms[i].status == 1) then
					ClassManager.CurrentClassName = rooms[i].class.name;
					ClassManager.ClassMemberList = {};
					if (rooms[i].teacherInfo) then
						ClassManager.ClassMemberList[1] =
							{userId = rooms[i].teacherInfo.id, name = ClassManager.GetMemberUIName2(rooms[i].teacherInfo.username, rooms[i].teacherInfo.nickname),
								teacher = true, online = true, inclass = true};
					end
					ClassManager.LoadClassroomInfo(rooms[i].id, callback);
					return;
				end
			end
		end
		if (callback) then
			callback();
		end
	end);
end

function ClassManager.LoadClassroom(roomId, roleId, callback)
	keepwork.classroom.get({cache_policy = "access plus 0", status = 1, roleId = roleId}, function(err, msg, data)
		local rooms = data and data.data and data.data.rows;
		if (rooms) then
			for i = 1, #rooms do
				if (rooms[i].status == 1 and rooms[i].id == roomId) then
					ClassManager.CurrentClassName = rooms[i].class.name;
					ClassManager.ClassMemberList = {};
					if (rooms[i].teacherInfo) then
						local userId = tonumber(Mod.WorldShare.Store:Get("user/userId"));
						if (rooms[i].teacherInfo.id == userId) then
							return;
						end
						ClassManager.ClassMemberList[1] =
							{userId = rooms[i].teacherInfo.id, name = ClassManager.GetMemberUIName2(rooms[i].teacherInfo.username, rooms[i].teacherInfo.nickname),
								teacher = true, online = true, inclass = true};
					end
					ClassManager.LoadClassroomInfo(rooms[i].id, callback);
					return;
				end
			end
		end
		if (callback) then
			callback();
		end
	end);
end

function ClassManager.LoadClassroomInfo(classroomId, callback)
	keepwork.info.get({cache_policy = "access plus 0", classroomId = classroomId}, function(err, msg, data)
		local room = data and data.data;
		if (room == nil) then return end

		ClassManager.CurrentWorldId = room.projectId;
		ClassManager.CurrentClassId = room.classId;
		ClassManager.CurrentClassroomId = room.id;
		ClassManager.CurrentWorldName = room.project.name;

		if (#ClassManager.ClassMemberList < 1) then
			ClassManager.ClassMemberList = {
				{userId = room.userId, name = ClassManager.GetMemberUIName2(System.User.username, System.User.NickName), teacher = true, online = true, inclass = true}, 
			};
		end

		for i = 1, #(room.classroomUser) do
			local user = room.classroomUser[i];
			if (user.userId ~= room.userId and user.user ~= nil and user.user.tLevel == 1) then
				table.insert(ClassManager.ClassMemberList,
				{
					userId = user.userId,
					name = ClassManager.GetMemberUIName2(user.user.username, user.user.nickname),
					teacher = true,
					online = user.online,
					inclass = false,
				})
			end
		end
		for i = 1, #(room.classroomUser) do
			local user = room.classroomUser[i];
			if (user.userId ~= room.userId and user.user ~= nil and user.user.tLevel == 0) then
				table.insert(ClassManager.ClassMemberList,
				{
					userId = user.userId,
					name = ClassManager.GetMemberUIName2(user.user.username, user.user.nickname),
					teacher = false,
					online = user.online,
					inclass = false,
				})
			end
		end
		if (callback) then
			callback(room.classId, room.projectId, classroomId, room.userId);
		end
	end);
end

function ClassManager.CreateAndEnterClassroom(classId, projectId, callback)
	keepwork.classroom.post({classId = classId, projectId = projectId}, function(err, msg, data)
		if (err == 200) then
			ClassManager.InClass = true;
			local roleId = 2;
			ClassManager.LoadOnlineClassroom(roleId, function(classId, projectId, classroomId, userId)
				if (classId and projectId and classroomId) then
					ClassManager.InClass = true;
					TeacherPanel.StartClass();
				end
			end);
		end
		if (callback) then
			callback(err == 200, data);
		end
	end);
end

function ClassManager.DismissClassroom(classroomId, callback)
	keepwork.dismiss.post({classroomId = classroomId}, function(err, msg, data)
		if (callback) then
			callback(err == 200, data);
		end
	end);
end

function ClassManager.JoinClassroom(classroomId)
	if (not classroomId) then return end
	if (not KpChatChannel.IsConnected()) then return end

	local room = string.format("__classroom_%s__", tostring(classroomId));
	KpChatChannel.client:Send("app/join", { rooms = { room}, });
end

function ClassManager.LeaveClassroom(classroomId)
	if (not classroomId) then return end
	local room = string.format("__classroom_%s__", tostring(classroomId));
	KpChatChannel.client:Send("app/leave", { rooms = { room}, });
	ClassManager.Reset();
end

function ClassManager.ClassNameFromId(classId)
	for i = 1, #ClassManager.ClassList do
		local class = ClassManager.ClassList[i];
		if (class.classId == classId) then
			return class.name;
		end
	end
end

function ClassManager.GetMemberUIName(userInfo, teacher)
	if (not userInfo) then return end
	local name = userInfo.name;
	if (name == nil or name == "") then
		name = userInfo.nickname;
	end
	if (name == nil or name == "") then
		name = userInfo.username;
	end
	if (teacher) then
		name = name..L"老师";
	end
	return name;
end

function ClassManager.GetMemberUIName2(username, nickname, teacher)
	local name = nickname;
	if (name == nil or name == "") then
		name = username;
	end
	if (teacher) then
		name = name..L"老师";
	end
	return name;
end

function ClassManager.GetCurrentTeacher()
	if (#ClassManager.ClassMemberList > 0) then
		return ClassManager.ClassMemberList[1];
	end
end

function ClassManager.IsTeacherInClass()
	local teacher = ClassManager.GetCurrentTeacher();
	local userId = tonumber(Mod.WorldShare.Store:Get("user/userId"));
	return teacher and teacher.userId == userId;
end

function ClassManager.GetOnlineCount()
	local count = 0;
	for i = 1, #ClassManager.ClassMemberList do
		if (ClassManager.ClassMemberList[i].inclass) then
			count = count + 1;
		end
	end
	return count;
end

function ClassManager.GetCurrentOrgUrl()
	for orgUrl, classIds in pairs(ClassManager.OrgClassIdMap) do
		for i = 1, #classIds do
			if (classIds[i] == ClassManager.CurrentClassId) then
				return orgUrl;
			end
		end
	end
end

function ClassManager.RunCommand(command)
	if (command == "lock") then
		ClassManager.IsLocking = true;
		LockDesktop.ShowPage(true, 60 * 60, cmd_text);
	elseif (command == "unlock") then
		ClassManager.IsLocking = false;
		LockDesktop.ShowPage(false, 0, cmd_text);
	elseif (command == "connect") then
		ClassManager.InGGS = true;
		GameLogic.RunCommand("/connectGGS -isSyncBlock");
	elseif (command == "nospeak") then
		ClassManager.CanSpeak = false;
		SChatRoomPage.Refresh();
	elseif (command == "canspeak") then
		ClassManager.CanSpeak = true;
		SChatRoomPage.Refresh();
	end
end

function ClassManager.AddLink(link, name, timestamp)
	table.insert(ClassManager.ShareLinkList, {link = link, teacher = name, time = timestamp});
	ShareUrlContext.Refresh();
end

function ClassManager.RefreshChatRoomList(userId, inclass, online)
	for i = 1, #ClassManager.ClassMemberList do
		if (ClassManager.ClassMemberList[i].userId == userId) then
			ClassManager.ClassMemberList[i].inclass = inclass;
			ClassManager.ClassMemberList[i].online = online;
			break;
		end
	end
	if (ClassManager.IsTeacherInClass()) then
		TChatRoomPage.Refresh();
		TeacherPanel.Refresh();
		if (inclass) then
			local room = string.format("__user_%d__", userId);
			if (ClassManager.IsLocking) then
				ClassManager.SendMessage("cmd:lock:"..userId, room);
			end
			if (ClassManager.InGGS) then
				ClassManager.SendMessage("cmd:connect:"..userId, room);
			end
			if (not ClassManager.CanSpeak) then
				ClassManager.SendMessage("cmd:nospeak:"..userId, room);
			end
		end
	else
		SChatRoomPage.Refresh();
	end
end

function ClassManager.StudentJointClassroom(roomId)
	if (ClassManager.InClass) then
		return;
	end
	local roleId = 1;
	ClassManager.LoadClassroom(roomId, roleId, function(classId, projectId, classroomId)
		local userId = tonumber(Mod.WorldShare.Store:Get("user/userId"));
		local currentTeacher = ClassManager.GetCurrentTeacher();
		if (currentTeacher and currentTeacher.userId == userId) then
			return;
		end
		if (classId and projectId and classroomId) then
			local text = string.format(L"%s邀请你上课，是否要保存当前世界并加入课堂，或点击取消不进入课堂？", ClassManager.GetMemberUIName(currentTeacher, true));
			_guihelper.MessageBox(text, function(res)
				if(res and res == _guihelper.DialogResult.Yes)then
					if (not GameLogic.IsReadOnly()) then
						GameLogic.QuickSave();
					end
					ClassManager.InClass = true;
					StudentPanel.StartClass();
				elseif(res and res == _guihelper.DialogResult.No)then
					ClassManager.InClass = true;
					StudentPanel.StartClass();
				else
					ClassManager.Reset();
				end
			end, _guihelper.MessageBoxButtons.YesNoCancel);
		end
	end);
end

function ClassManager.ProcessMessage(payload, meta)
	local currentTeacher = ClassManager.GetCurrentTeacher();
	local name = ClassManager.GetMemberUIName(payload, currentTeacher ~= nil and currentTeacher.userId == payload.id)
	local result = commonlib.split(payload.content, ":");
	local type, content = result[1], result[2];
	if (#result > 2) then
		for i = 3, #result do
			content = content..":"..result[i];
		end
	end

	local userId = tonumber(Mod.WorldShare.Store:Get("user/userId"));
	if (type == "cmd") then
		if (userId ~= payload.id) then
			ClassManager.RunCommand(content);
		end
	elseif (type == "tip") then
		ClassManager.RefreshChatRoomList(payload.id, content=="join", true);
	elseif (type == "link") then
		if (userId ~= payload.id) then
			ClassManager.AddLink(content, name, meta.timestamp);
		end
	else
	end

	local _, time = string.match(meta.timestamp, "(.+)%s(.+)");
	local msgdata = {
		msgType = type,
		fromName = name,
		fromMyself = userId == payload.id,
		timestamp = time,
		words = content,
	};
	ChatChannel.ValidateMsg(msgdata, ClassManager.OnProcessMsg);
end

function ClassManager.OnMsg(self, msg)
	if (not msg or not msg.data) then return end

	local data = msg.data;
	local eio_pkt_name = data.eio_pkt_name;
	local sio_pkt_name = data.sio_pkt_name;
	if(eio_pkt_name == "message" and sio_pkt_name =="event")then
		local body = data.body or {};
		local key = body[1] or {};
		local info = body[2] or {};
		local payload = info.payload;
		local meta = info.meta;
		local userInfo = info.userInfo;
		local action = payload and payload.action;

		if (action == "classroom_start") then
			ClassManager.StudentJointClassroom(payload.classroomId);
		elseif (action == "classroom_dismiss") then
			if (not ClassManager.IsTeacherInClass()) then
				if (ClassManager.IsLocking) then
					ClassManager.RunCommand("unlock");
				end
				if (not ClassManager.CanSpeak) then
					ClassManager.RunCommand("canspeak");
				end
				ClassManager.Reset();
				StudentPanel.LeaveClass();
			else
				ClassManager.Reset();
			end
		elseif (action == "online") then
			ClassManager.RefreshChatRoomList(payload.userId, false, true);
		elseif (action == "offline") then
			ClassManager.RefreshChatRoomList(payload.userId, false, false);
		end
		if (key == "app/msg" and payload and userInfo) then
			local room = string.format("__classroom_%s__", tostring(ClassManager.CurrentClassroomId));
			if (not meta) then return end

			if (meta.target == room) then
				ClassManager.ProcessMessage(payload, meta);
			elseif (string.find(meta.target, "__user_") ~= nil) then
				-- invite msg send to __user_id__ room
				local result = commonlib.split(payload.content, ":");
				if (#result ~= 3) then return end
				if (result[1] == "invite") then
					local roomId = tonumber(result[3]);
					local id = tonumber(result[2]);
					local userId = tonumber(Mod.WorldShare.Store:Get("user/userId"));
					if (id == userId) then
						ClassManager.StudentJointClassroom(roomId);
					end
				elseif (result[1] == "cmd") then
					local cmd = result[2];
					local id = tonumber(result[3]);
					local userId = tonumber(Mod.WorldShare.Store:Get("user/userId"));
					if (id == userId) then
						ClassManager.RunCommand(cmd);
					end
				end
			end
		end
	end
end

function ClassManager.Reset()
	ClassManager.InClass = false;
	ClassManager.IsLocking = false;
	ClassManager.InGGS = false;
	ClassManager.CanSpeak = true;

	ClassManager.CurrentClassId = nil;
	ClassManager.CurrentWorldId = nil; 
	ClassManager.CurrentClassroomId = nil;
	ClassManager.CurrentClassName = nil;
	ClassManager.CurrentWorldName = nil; 

	ClassManager.OrgClassIdMap = {};
	ClassManager.ClassList = {};
	ClassManager.ProjectList = {};
	ClassManager.ShareLinkList = {};
	ClassManager.ClassMemberList = {};

	ClassManager.ChatDataList = {};
end

function ClassManager.SendMessage(content, target)
	local msgdata = {
		ChannelIndex = ChatChannel.EnumChannels.KpNearBy,
		target = target or string.format("__classroom_%s__", tostring(ClassManager.CurrentClassroomId)),
		worldId = ClassManager.CurrentWorldId,
		words = content,
		type = 2,
		is_keepwork = true,
	};

	if (ChatChannel.WordsFilter) then
		for i= 1, #(ChatChannel.WordsFilter) do
			local filter_func = ChatChannel.WordsFilter[i];
			if(filter_func and type(filter_func)=="function")then
				msgdata = filter_func(msgdata);
				if(msgdata == true) then
					return true;
				elseif(msgdata==nil or msgdata.words == nil or msgdata.words == "" )then
					return false;
				end
			end
		end
	end

	ChatChannel.ValidateMsg(msgdata, KpChatChannel.SendToServer);
	return true;
end

function ClassManager.OnProcessMsg(msgdata)
	table.insert(ClassManager.ChatDataList, msgdata);
	if(#(ClassManager.ChatDataList) > ClassManager.ChatDataMax)then
		table.remove(ClassManager.ChatDataList, 1); 
	end

	if (ClassManager.IsTeacherInClass()) then
		TChatRoomPage.AppendChatMessage(msgdata, true);
	else
		SChatRoomPage.AppendChatMessage(msgdata, true);
	end
end

function ClassManager.FilterURL(words)
	if(words) then
		local url = words:match("(http://%S+)");
		if(url) then
			local nid, slot_id = url:match("visit_url=(%d+)@?(.*)$");
			if(nid and slot_id) then
				words = words:gsub("(http://%S+)", format("<pe:mcworld nid='%s' slot='%s' class='linkbutton_yellow'/>", nid, slot_id));
			end
		end
	end
	return words;
end

function ClassManager.MessageToMcml(chatdata)
	local words = commonlib.Encoding.EncodeStr(chatdata.words or "");

	local fromName = chatdata.fromName;
	local fromMyself = chatdata.fromMyself;
	local timestamp = chatdata.timestamp;

	local mcmlStr;
	local type = chatdata.msgType;
	if (type == "msg") then
		words = words:gsub("\n", "<br/>")
		if(not System.options.mc) then
			words = SmileyPage.ChangeToMcml(words);
		end
		local width = _guihelper.GetTextWidth(words);
		local height = 36;
		local lineCount = math.floor(width / 390) + 1;
		if (lineCount > 1) then
			width = 396;
			height = (height - 12) * lineCount + 4;
		end
		width = width + 20;
		if (width < 32) then
			width = 32;
		end
		local offset = _guihelper.GetTextWidth(fromName, "System;12");
		if (chatdata.fromMyself) then
			mcmlStr = string.format(
				[[
				<div style="height:20px;">
					<div style="width:%dpx;position:relative;margin-right:0px;color:#a0a0a0;font-size:12px;" align="right">
						%s
					</div>
					<div style="width:36px;position:relative;margin-right:%dpx;color:#a0a0a0;font-size:12px;" align="right">
						%s
					</div>
				</div>
				<div style="height:%dpx;">
					<div style="width:%dpx;height:%dpx;position:relative;margin-right:0px;color:#000000;background:url(Texture/Aries/Creator/keepwork/ClassManager/message_bg_myself_32bits.png#0 0 32 32:8 8 8 8);" align="right">
						<div style="margin-left:10px;margin-top:6px;">%s</div>
					</div>
				</div>
				]],
			offset, fromName, offset+4, timestamp, height, width, height, words);
		else
			mcmlStr = string.format(
				[[
				<div style="height:20px;">
					<div style="width:%dpx;float:left;color:#a0a0a0;font-size:12px;">
						%s
					</div>
					<div style="width:36px;float:left;color:#a0a0a0;font-size:12px;">
						%s
					</div>
				</div>
				<div style="height:%dpx;">
					<div style="width:%dpx;height:%dpx;margin-right:0px;color:#000000;background:url(Texture/Aries/Creator/keepwork/ClassManager/message_bg_other_32bits.png#0 0 32 32:8 8 8 8);">
						<div style="margin-left:10px;margin-top:6px;">%s</div>
					</div>
				</div>
				]],
			offset+6, fromName, timestamp, height, width, height, words);
		end
	elseif (type == "cmd") then
		local text = L"";
		if (words == "lock") then
			text = fromName..L"开启了屏幕锁屏";
		elseif (words == "unlock") then
			text = fromName..L"关闭了屏幕锁屏";
		elseif (words == "connect") then
			text = fromName..L"开启了联机模式";
		elseif (words == "nospeak") then
			text = fromName..L"开启了全员禁言";
		elseif (words == "canspeak") then
			text = fromName..L"取消了全员禁言";
		else
			return;
		end
		local width = _guihelper.GetTextWidth(text, "System;12") + 10;
		mcmlStr = string.format(
			[[
			<div style="height:30px;">
				<div style="width:%dpx;height:22px;margin-top:4px;background:url(Texture/Aries/Creator/keepwork/ClassManager/message_bg_cmd_32bits.png#0 0 32 22:8 8 8 8);" align="center">
					<div style="margin-top:1px;text-align:center;font-size:12px;color:#a0a0a0;">
						%s
					</div>
				</div>
			</div>
			]],
		width, text);
	elseif (type == "link") then
		local text = string.format(L"%s分享链接：%s", fromName, words);
		local width = _guihelper.GetTextWidth(text, "System;12");
		local height = 22;
		if (width > 420) then
			text = string.format(L"%s分享链接：<br/>%s", fromName, words);
			width = _guihelper.GetTextWidth(words, "System;12");
			local lineCount = math.floor(width / 420) + 1;
			if (lineCount > 1) then
				width = 420;
			end
			height = (height - 2) * (lineCount + 1);
		end
		width = width + 10;
		mcmlStr = string.format(
			[[
			<div style="height:%dpx;">
				<div style="width:%dpx;height:%dpx;margin-top:4px;background:url(Texture/Aries/Creator/keepwork/ClassManager/message_bg_cmd_32bits.png#0 0 32 22:8 8 8 8);" align="center">
					<div style="margin-top:1px;text-align:center;font-size:12px;color:#a0a0a0;">
						%s
					</div>
				</div>
			</div>
			]],
		height+8, width, height, text);
	else
	end

	return mcmlStr;
end