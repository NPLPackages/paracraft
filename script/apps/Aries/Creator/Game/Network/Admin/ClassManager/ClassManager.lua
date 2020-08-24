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

ClassManager.CurrentOrgLoginUrl = nil;
ClassManager.CurrentClassId = nil;
ClassManager.CurrentWorldId = nil; 
ClassManager.CurrentClassroomId = nil;
ClassManager.CurrentClassName = nil;
ClassManager.CurrentWorldName = nil; 

ClassManager.OrgClassIdMap = {};
ClassManager.ClassList = {};
ClassManager.ProjectList = {};
ClassManager.ClassMemberList = {};
ClassManager.ShareLinkList = {};

ClassManager.ChatDataList = {};
ClassManager.ChatDataMax = 200;

local init = false;
function ClassManager.StaticInit()
	if (init) then return end

	GameLogic.GetFilters():add_filter("OnKeepWorkLogin", ClassManager.OnKeepWorkLogin_Callback);
	GameLogic.GetFilters():add_filter("OnKeepWorkLogout", ClassManager.OnKeepWorkLogout_Callback)
end

function ClassManager.OnKeepWorkLogin_Callback()
	if (KpChatChannel.client) then
		KpChatChannel.client:AddEventListener("OnMsg",ClassManager.OnMsg,ClassManager);
		commonlib.TimerManager.SetTimeout(function()
			--ClassManager.LoadAllClassesAndProjects();
			-- first load teacher classroom
			local roleId = 2;
			ClassManager.LoadOnlineClassroom(roleId, function(classId, projectId, classroomId)
				if (classId and projectId and classroomId) then
					if (ClassManager.IsTeacherInClass()) then
						_guihelper.MessageBox("你所在的班级正在上课，即将自动进入课堂！");
						commonlib.TimerManager.SetTimeout(function()
							ClassManager.InClass = true;
							TeacherPanel.StartClass();
						end, 2000);
					end
				else
					-- no teacher classroom, then load student classroom
					local roleId = 1;
					ClassManager.LoadOnlineClassroom(roleId, function(classId, projectId, classroomId)
						if (classId and projectId and classroomId) then
							_guihelper.MessageBox("你所在的班级正在上课，是否直接进入课堂？", function(res)
								if(res and res == _guihelper.DialogResult.Yes)then
									ClassManager.InClass = true;
									StudentPanel.StartClass();
								end
							end, _guihelper.MessageBoxButtons.YesNo);
						end
					end);
				end
			end);
		end, 1000)
	end
end

function ClassManager.OnKeepWorkLogout_Callback()
	if (KpChatChannel.client) then
		KpChatChannel.client:RemoveEventListener("OnMsg",ClassManager.OnMsg,ClassManager);
		ClassManager.LeaveClassroom(ClassManager.CurrentClassroomId);
	end
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
	local projectId = GameLogic.options:GetProjectId();
	if (projectId and tonumber(projectId)) then
		table.insert(ClassManager.ProjectList, {projectId = tonumber(projectId), projectName = WorldCommon.GetWorldTag("name")});
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
		commonlib.echo(data);
		local rooms = data and data.data and data.data.rows;
		if (rooms) then
			for i = 1, #rooms do
				if (rooms[i].status == 1) then
					ClassManager.CurrentClassName = rooms[i].class.name;
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
		ClassManager.ClassMemberList = room.classroomUser or {};
		if (callback) then
			callback(room.classId, room.projectId, classroomId);
		end
	end);
end

function ClassManager.CreateClassroom(classId, projectId, callback)
	keepwork.classroom.post({classId = classId, projectId = projectId}, function(err, msg, data)
		if (err == 200) then
			ClassManager.CurrentClassId = classId;
			ClassManager.CurrentWorldId = projectId;
			ClassManager.InClass = true;
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
		if (err == 200) then
			ClassManager.Reset();
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

function ClassManager.IsTeacherInClass()
	local userId = tonumber(Mod.WorldShare.Store:Get("user/userId"));
	for i = 1, #ClassManager.ClassMemberList do
		if (userId == ClassManager.ClassMemberList[i].userId) then
			local userInfo = ClassManager.ClassMemberList[i].user;
			return userInfo.tLevel == 1 and userInfo.student == 0;
		end
	end
	return false;
end

function ClassManager.GetClassTeacherInfo()
	for i = 1, #ClassManager.ClassMemberList do
		local userInfo = ClassManager.ClassMemberList[i].user;
		if (userInfo and userInfo.tLevel == 1 and userInfo.student == 0) then
			return userInfo;
		end
	end
end

function ClassManager.GetMemberUIName(userInfo, teacher)
	local name = userInfo.nickname;
	if (name == nil or name == "") then
		name = userInfo.username;
	end
	if (teacher and userInfo.tLevel == 1 and userInfo.student == 0) then
		name = name..L"老师";
	end
	return name;
end

function ClassManager.GetOnlineCount()
	local count = 0;
	for i = 1, #ClassManager.ClassMemberList do
		local userInfo = ClassManager.ClassMemberList[i].user;
		if (ClassManager.ClassMemberList[i].online and (userInfo.tLevel == 0 or userInfo.student == 1)) then
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
		LockDesktop.ShowPage(true, 60 * 60, cmd_text);
	elseif (command == "unlock") then
		LockDesktop.ShowPage(false, 0, cmd_text);
	elseif (command == "connect") then
		GameLogic.RunCommand("/connectGGS");
	end
end

function ClassManager.AddLink(link, name, timestamp)
	table.insert(ClassManager.ShareLinkList, {link = link, teacher = name, time = timestamp});
	ShareUrlContext.Refresh();
end

function ClassManager.ProcessMessage(payload, meta)
	local name = ClassManager.GetMemberUIName(payload, true)
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
		TChatRoomPage.Refresh();
		SChatRoomPage.Refresh();
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
			commonlib.echo(msg);
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
			ClassManager.LoadClassroomInfo(payload.classroomId, function(classId, projectId, classroomId)
				ClassManager.CurrentClassroomId = classroomId;
				local teacher = ClassManager.GetClassTeacherInfo();
				if (not teacher) then return end

				local userId = tonumber(Mod.WorldShare.Store:Get("user/userId"));
				if (userId == teacher.id) then
					TeacherPanel.StartClass();
				else
					local text = string.format(L"%s邀请你上课，是否加入课堂？", ClassManager.GetMemberUIName(teacher, true));
					_guihelper.MessageBox(text, function(res)
						if(res and res == _guihelper.DialogResult.Yes)then
							ClassManager.InClass = true;
							StudentPanel.StartClass();
						end
					end, _guihelper.MessageBoxButtons.YesNo);
				end
			end);
			return;
		end
		if (key == "app/msg" and payload and userInfo) then
			local room = string.format("__classroom_%s__", tostring(ClassManager.CurrentClassroomId));
			if (meta and meta.target == room) then
				ClassManager.ProcessMessage(payload, meta);
			end
		end
	end
end

function ClassManager.Reset()
	ClassManager.InClass = false;
	ClassManager.CurrentClassId = nil;
	ClassManager.CurrentWorldId = nil; 
	ClassManager.CurrentClassroomId = nil;
	ClassManager.CurrentClassName = nil;
	ClassManager.CurrentWorldName = nil; 

	ClassManager.OrgClassIdMap = {};
	ClassManager.ClassList = {};
	ClassManager.ProjectList = {};
	ClassManager.ClassMemberList = {};
	ClassManager.ShareLinkList = {};

	ClassManager.ChatDataList = {};
end

function ClassManager.SendMessage(content)
	local msgdata = {
		ChannelIndex = ChatChannel.EnumChannels.KpNearBy,
		target = string.format("__classroom_%s__", tostring(ClassManager.CurrentClassroomId)),
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

	SChatRoomPage.AppendChatMessage(msgdata, true);
	TChatRoomPage.AppendChatMessage(msgdata, true);
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
		commonlib.echo(words);
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