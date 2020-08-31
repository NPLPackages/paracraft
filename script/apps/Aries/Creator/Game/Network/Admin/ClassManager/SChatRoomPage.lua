--[[
Title: Class List 
Author(s): Chenjinxian
Date: 2020/7/6
Desc: 
use the lib:
-------------------------------------------------------
local SChatRoomPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/SChatRoomPage.lua");
SChatRoomPage.ShowPage()
-------------------------------------------------------
]]
local ClassManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/ClassManager.lua");
local StudentPanel = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/StudentPanel.lua");
local SChatRoomPage = NPL.export()

local page;

function SChatRoomPage.OnInit()
	page = document:GetPageCtrl();
end

function SChatRoomPage.ShowPage(bShow)
	if (page) then
		if (bShow and page:IsVisible()) then
			return;
		end
		if ((not bShow) and (not page:IsVisible())) then
			return;
		end
	end
	local params = {
		url = "script/apps/Aries/Creator/Game/Network/Admin/ClassManager/SChatRoomPage.html", 
		name = "SChatRoomPage.ShowPage", 
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
		x = -690 / 2,
		y = -533 / 2,
		width = 690,
		height = 533,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function SChatRoomPage.Refresh()
	if (page) then
		page:Refresh(0);
	end
end

function SChatRoomPage.OnClose()
	SChatRoomPage.ShowPage(false);
	StudentPanel.CloseChat();
end

function SChatRoomPage.GetClassName()
	return ClassManager.ClassNameFromId(ClassManager.CurrentClassId) or ClassManager.CurrentClassName;
end

function SChatRoomPage.GetClassPeoples()
	local onlineCount = ClassManager.GetOnlineCount();
	local text = string.format(L"班级成员 %d/%d", onlineCount, (#ClassManager.ClassMemberList));
	return text;
end

function SChatRoomPage.ClassItems()
	return ClassManager.ClassMemberList;
end

function SChatRoomPage.GetShortName(name)
	local len = commonlib.utf8.len(name);
	if (len > 2) then
		return commonlib.utf8.sub(name, len-1);
	else
		return name;
	end
	return name;
end

function SChatRoomPage.CanSpeak()
	return ClassManager.CanSpeak;
end

function SChatRoomPage.ShowOnlyTeacher()
end

function SChatRoomPage.ShowAll()
end

function SChatRoomPage.SendMessage()
	local text = page:GetValue("MessageText", nil);
	if (text and text ~= "") then
		ClassManager.SendMessage("msg:"..text);
		page:SetValue("MessageText", "");
		page:Refresh(0);
	else
		--_guihelper.MessageBox(L"");
	end
end

function SChatRoomPage.AppendChatMessage(chatdata, needrefresh)
	if(chatdata==nil or type(chatdata)~="table")then
		commonlib.echo("error: chatdata 不可为空 in SChatRoomPage.AppendChatMessage");
		return;
	end

	local ctl = SChatRoomPage.GetTreeView();
	local rootNode = ctl.RootNode;
	
	if(rootNode:GetChildCount() > ClassManager.ChatDataMax) then
		rootNode:RemoveChildByIndex(1);
	end

	rootNode:AddChild(CommonCtrl.TreeNode:new({
		Name = "text", 
		chatdata = chatdata,
	}));

	if(needrefresh)then
		SChatRoomPage.RefreshTreeView();
	end
end

function SChatRoomPage.CreateTreeView(param, mcmlNode)
	local _container = ParaUI.CreateUIObject("container", "SChatRoomPage_tvcon", "_lt", param.left,param.top,param.width,param.height);
	_container.background = "";
	_container:GetAttributeObject():SetField("ClickThrough", false);
	param.parent:AddChild(_container);
	
	-- create get the inner tree view
	local ctl = SChatRoomPage.GetTreeView(nil, _container, 0, 0, param.width, param.height);
	ctl:Show(true, nil, true);
end

function SChatRoomPage.DrawTextNodeHandler(_parent, treeNode)
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

function SChatRoomPage.GetTreeView(name, parent, left, top, width, height, NoClipping)
	name = name or "SChatRoomPage.TreeView"
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
			DrawNodeHandler = SChatRoomPage.DrawTextNodeHandler,
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

function SChatRoomPage.RefreshTreeView()
	if (page) then
		local ctl = SChatRoomPage.GetTreeView();
		if(ctl) then
			local parent = ParaUI.GetUIObject("SChatRoomPage_tvcon");
			if(parent:IsValid())then
				ctl.parent = parent;
				ctl:Update(true);
			end
		end
	end
end
