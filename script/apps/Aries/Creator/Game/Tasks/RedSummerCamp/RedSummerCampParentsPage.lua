--[[
Title: RedSummerCampParentsPage
Author(s): 
Date: 2021/7/6
Desc:  the parent's tutorial page for red summer camp 2021
Use Lib:
-------------------------------------------------------
local RedSummerCampParentsPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampParentsPage.lua");
RedSummerCampParentsPage.Show();
--]]

local RedSummerCampParentsPage = NPL.export();

local page
RedSummerCampParentsPage.ItemData={
	{name="非网络游戏",node_name="network",content="全球领先的三维虚拟校园理念，让孩子通过编程、动画，构建人工智能的世界。"},
	{name="费用详情",node_name="charge",content="成为帕拉卡会员，畅享全部课程和软件1对1服务，绝无其他任何内置的付费项目。"},
	{name="教育部门认证",node_name="certificate",content="中国自主研发计算机学习软件，多省市教育局指定计算机校本课配套学习软件。"}
}

function RedSummerCampParentsPage.OnInit()
	page = document:GetPageCtrl();
end

function RedSummerCampParentsPage.Show()
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampParentsPage.html",
			name = "RedSummerCampParentsPage.Show", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			enable_esc_key = false,
			cancelShowAnimation = true,
			--app_key = 0, 
			directPosition = true,
				align = "_fi",
				x = 0,
				y = 0,
				width = 0,
				height = 0,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end
