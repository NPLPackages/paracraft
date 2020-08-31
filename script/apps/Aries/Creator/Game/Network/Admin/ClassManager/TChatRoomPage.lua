--[[
Title: Class List 
Author(s): Chenjinxian
Date: 2020/7/6
Desc: 
use the lib:
-------------------------------------------------------
local TChatRoomPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/TChatRoomPage.lua");
TChatRoomPage.ShowPage()
-------------------------------------------------------
]]
local ClassManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/ClassManager.lua");
local TeacherPanel = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/TeacherPanel.lua");
local TChatRoomPage = NPL.export()

local page;

function TChatRoomPage.OnInit()
	page = document:GetPageCtrl();
end

function TChatRoomPage.ShowPage(bShow)
	if (page) then
		if (bShow and page:IsVisible()) then
			return;
		end
		if ((not bShow) and (not page:IsVisible())) then
			return;
		end
	end
	local params = {
		url = "script/apps/Aries/Creator/Game/Network/Admin/ClassManager/TChatRoomPage.html", 
		name = "TChatRoomPage.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = false,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = true,
		bShow = bShow,
		enable_esc_key = true,
		click_through = false, 
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		directPosition = true,
		align = "_ct",
		x = -750 / 2,
		y = -533 / 2,
		width = 750,
		height = 533,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function TChatRoomPage.Refresh()
	if (page) then
		page:Refresh(0);
	end
end

function TChatRoomPage.OnClose()
	TChatRoomPage.ShowPage(false);
	TeacherPanel.CloseChat();
end

function TChatRoomPage.GetClassName()
	return ClassManager.ClassNameFromId(ClassManager.CurrentClassId) or ClassManager.CurrentClassName;
end

function TChatRoomPage.GetClassPeoples()
	local onlineCount = ClassManager.GetOnlineCount();
	local text = string.format(L"班级成员 %d/%d", onlineCount, (#ClassManager.ClassMemberList));
	return text;
end

function TChatRoomPage.InviteAll()
	_guihelper.MessageBox(L"邀请所有未上课成员一起上课？", function(res)
		if(res == _guihelper.DialogResult.OK) then
			for i = 2, #ClassManager.ClassMemberList do
				local userInfo = ClassManager.ClassMemberList[i];
				if (userInfo.online and not userInfo.inclass) then
					local room = string.format("__user_%d__", userInfo.userId);
					ClassManager.SendMessage("invite:"..userInfo.userId..":"..ClassManager.CurrentClassroomId, room);
				end
			end
		end
	end, _guihelper.MessageBoxButtons.OKCancel);
end

function TChatRoomPage.InviteOne(userId)
	for i = 2, #ClassManager.ClassMemberList do
		local userInfo = ClassManager.ClassMemberList[i];
		if (userId == userInfo.userId) then
			local tip = string.format(L"邀请%s上课？", userInfo.name);
			_guihelper.MessageBox(tip, function(res)
				if(res == _guihelper.DialogResult.OK) then
					local room = string.format("__user_%d__", userId);
					ClassManager.SendMessage("invite:"..userId..":"..ClassManager.CurrentClassroomId, room);
				end
			end, _guihelper.MessageBoxButtons.OKCancel);
			return;
		end
	end
end

function TChatRoomPage.ClassItems()
	return ClassManager.ClassMemberList;
end

function TChatRoomPage.GetShortName(name)
	local len = commonlib.utf8.len(name);
	if (len > 2) then
		return commonlib.utf8.sub(name, len-1);
	else
		return name;
	end
	return name;
end

function TChatRoomPage.IsForbiddened()
	return not ClassManager.CanSpeak;
end

function TChatRoomPage.ForbiddenChat()
	_guihelper.MessageBox(L"确定要开户全员禁言吗（老师发言不受限制）？", function(res)
		if(res == _guihelper.DialogResult.OK) then
			ClassManager.SendMessage("cmd:nospeak");
			ClassManager.CanSpeak = false;
			page:Refresh(0);
		end
	end, _guihelper.MessageBoxButtons.OKCancel);
end

function TChatRoomPage.AllowChat()
	ClassManager.SendMessage("cmd:canspeak");
	ClassManager.CanSpeak = true;
	page:Refresh(0);
end

function TChatRoomPage.SendMessage()
	local text = page:GetValue("MessageText", nil);
	if (text and text ~= "") then
		ClassManager.SendMessage("msg:"..text);
		page:SetValue("MessageText", "");
		page:Refresh(0);
	else
		--_guihelper.MessageBox(L"");
	end
end

function TChatRoomPage.AppendChatMessage(chatdata, needrefresh)
	if(chatdata==nil or type(chatdata)~="table")then
		commonlib.echo("error: chatdata 不可为空 in TChatRoomPage.AppendChatMessage");
		return;
	end

	local ctl = TChatRoomPage.GetTreeView();
	local rootNode = ctl.RootNode;
	
	if(rootNode:GetChildCount() > ClassManager.ChatDataMax) then
		rootNode:RemoveChildByIndex(1);
	end

	rootNode:AddChild(CommonCtrl.TreeNode:new({
		Name = "text", 
		chatdata = chatdata,
	}));

	if(needrefresh)then
		TChatRoomPage.RefreshTreeView();
	end
end

function TChatRoomPage.CreateTreeView(param, mcmlNode)
	local _container = ParaUI.CreateUIObject("container", "TChatRoomPage_tvcon", "_lt", param.left,param.top,param.width,param.height);
	_container.background = "";
	_container:GetAttributeObject():SetField("ClickThrough", false);
	param.parent:AddChild(_container);
	
	-- create get the inner tree view
	local ctl = TChatRoomPage.GetTreeView(nil, _container, 0, 0, param.width, param.height);
	ctl:Show(true, nil, true);
end

function TChatRoomPage.DrawTextNodeHandler(_parent, treeNode)
	if(_parent == nil or treeNode == nil) then
		return;
	end

	local mcmlStr = ClassManager.MessageToMcml(treeNode.chatdata);
	if(mcmlStr ~= nil) then
		local xmlRoot = ParaXML.LuaXML_ParseString(mcmlStr);
		if(type(xmlRoot)=="table" and table.getn(xmlRoot)>0) then
			local xmlRoot = Map3DSystem.mcml.buildclass(xmlRoot);
							
			local height = 12; -- just big enough
			local nodeWidth = treeNode.TreeView.ClientWidth;
			local myLayout = Map3DSystem.mcml_controls.layout:new();
			myLayout:reset(0, 0, nodeWidth-5, height);
			Map3DSystem.mcml_controls.create("bbs_lobby", xmlRoot, nil, _parent, 0, 0, nodeWidth-5, height,nil, myLayout);
			local usedW, usedH = myLayout:GetUsedSize()
			if(usedH>height) then
				return usedH;
			end
		end
	end
end

function TChatRoomPage.GetTreeView(name, parent, left, top, width, height, NoClipping)
	name = name or "TChatRoomPage.TreeView"
	local ctl = CommonCtrl.GetControl(name);
	if(not ctl)then
		left = left or 0;
		left = left + 5;
		ctl = CommonCtrl.TreeView:new{
			name = name,
			alignment = "_lt",
			left = left,
			top = top or 0,
			width = width or 480,
			height = height or 330,
			parent = parent,
			container_bg = nil,
			DefaultIndentation = 2,
			NoClipping = NoClipping==true,
			ClickThrough = false,
			DefaultNodeHeight = 14,
			VerticalScrollBarStep = 14,
			VerticalScrollBarPageSize = 14 * 5,
			VerticalScrollBarWidth = 10,
			HideVerticalScrollBar = false,
			DrawNodeHandler = TChatRoomPage.DrawTextNodeHandler,
		};
	elseif(parent)then
		ctl.parent = parent;
	end

	if(width)then
		ctl.width = width;
	end

	if(height)then
		ctl.height= height;
	end

	if(left)then
		ctl.left= left;
	end

	if(top)then
		ctl.top = top;
	end
	return ctl;
end

function TChatRoomPage.RefreshTreeView()
	if (page) then
		local ctl = TChatRoomPage.GetTreeView();
		if(ctl) then
			local parent = ParaUI.GetUIObject("TChatRoomPage_tvcon");
			if(parent:IsValid())then
				ctl.parent = parent;
				ctl:Update(true);
			end
		end
	end
end

