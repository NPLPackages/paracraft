--[[
Title: Class List 
Author(s): Chenjinxian
Date: 2020/7/6
Desc: 
use the lib:
-------------------------------------------------------
local ChatRoomPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/ChatRoomPage.lua");
ChatRoomPage.ShowPage()
-------------------------------------------------------
]]
local TeacherPanel = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/TeacherPanel.lua");
local ChatRoomPage = NPL.export()

local page;

function ChatRoomPage.OnInit()
	page = document:GetPageCtrl();
end

function ChatRoomPage.ShowPage()
	local params = {
		url = "script/apps/Aries/Creator/Game/Network/Admin/ClassManager/ChatRoomPage.html", 
		name = "ChatRoomPage.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = true,
		enable_esc_key = true,
		click_through = true, 
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

function ChatRoomPage.OnClose()
	page:CloseWindow();
end

function ChatRoomPage.GetClassName()
	--return TeacherPanel.CurrentClassName;
	return L"编程1班";
end

function ChatRoomPage.GetClassPeoples()
	return L"班级成员 10/20";
end

function ChatRoomPage.InviteAll()
end

function ChatRoomPage.InviteOne()
end

function ChatRoomPage.ClassItems()
	local items = {{name="张三丰", teacher=true, online=true},
		{name="张飞", teacher=false, online=false},
		{name="关羽", teacher=false, online=false},
		{name="夏侯渊", teacher=false, online=true},
		{name="姜维", teacher=false, online=true},
		{name="孙策", teacher=false, online=false},
		{name="太史慈", teacher=false, online=true},
		{name="张辽", teacher=false, online=false},
		{name="张郃", teacher=false, online=true},
		{name="庞德", teacher=false, online=true},
		{name="魏延", teacher=false, online=true},
		{name="颜良", teacher=false, online=false},
		{name="吴三桂", teacher=false, online=true},
		{name="张无忌", teacher=false, online=true},
		{name="张翠山", teacher=false, online=false},
		{name="周芷若", teacher=false, online=true},
		{name="杨逍", teacher=false, online=true},
		{name="灭绝师太", teacher=false, online=true},
		{name="洪七公", teacher=false, online=true},
		{name="赵云", teacher=false, online=true}};
	return items;
end

function ChatRoomPage.ChatItems()
	local items = {{name="张三丰", time="15:03", content="春眠不觉晓，处处闻啼鸟。"},
		{name="张飞", time="", content="夜来风雨声，花落知多少。"},
		{name="关羽", time="", content="松下问童子，言师采药去。"},
		{name="夏侯渊", time="", content="只在此山中，云深不知处。"},
		{name="姜维", time="", content="朝辞白帝彩云间，千里江陵一日还。"},
		{name="孙策", time="", content="两岸猿声啼不住，轻舟已过万重山。"},
		{name="太史慈", time="", content="独在异乡为异客，每逢佳节倍思亲。"},
		{name="张辽", time="", content="遥知兄弟登高处，遍插茱萸少一人。"},
		{name="张郃", time="", content="葡萄美酒夜光杯，欲饮琵琶马上催。"},
		{name="庞德", time="", content="醉卧沙场君莫笑，古来征战几人回？"},
		{name="魏延", time="", content=""},
		{name="颜良", time="", content=""},
		{name="吴三桂", time="", content=""},
		{name="张无忌", time="", content=""},
		{name="张翠山", time="", content=""},
		{name="周芷若", time="", content=""},
		{name="杨逍", time="", content=""},
		{name="灭绝师太", time="", content=""},
		{name="洪七公", time="", content=""},
		{name="赵云", time="", content=""}};
	return items;
end

function ChatRoomPage.GetShortName(name)
	local len = commonlib.utf8.len(name);
	if (len > 2) then
		return commonlib.utf8.sub(name, len-1);
	else
		return name;
	end
	return name;
end

function ChatRoomPage.SendMessage()
end
