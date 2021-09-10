--[[
Title: RedSummerCampCommonPage
Author(s): yangguiyi
Date: 2021/7/6
Desc:  the common page for red summer camp 2021
Use Lib:
-------------------------------------------------------
local RedSummerCampCommonPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCommonPage.lua");
RedSummerCampCommonPage.Show(name);
--]]

local RedSummerCampCommonPage = NPL.export();
RedSummerCampCommonPage.GridData = {}
RedSummerCampCommonPage.pageData = {
    summer_camp = {	
		title="帕拉卡红色夏令营",
		lb_bt_desc = "<<< 神通杯编程大赛集训营",
		rb_bt_desc = "进入夏令营",
		img = "Texture/Aries/Creator/keepwork/RedSummerCamp/common/bg_camp_602x374_32bits.png#0 0 602 374",
		begain_time = "开始日期：2021.7.1",
		end_time = "结束日期：2021.8.22",
		content=[[
				<div style="height: 20px;"></div>
				&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;七月伊始，在举国欢腾，为党庆生的红色浪潮中，在校学生也逐步进入到了暑假时间，为了在建党100周年之际，助力孩子及家长一同度过一个充实的暑假，帕拉卡推出了暑期红色夏令营活动。本次夏令营不仅将“一大会址”，“南湖红船”，“遵义会议会址”等象征着中国共产党伟大历程的红色建筑还原到夏令营中，更是将3D动画编程课的课堂迁移到红色场景中，在重温红色记忆的同时，学习人工智能相关知识与技能。
				真实还原的红色记忆，循序渐进的每日课程，清晰明了的学习指引，皆在帕拉卡红色夏令营，快来加入我们，与小伙伴们一同开启新征程吧！
				<div style="height: 20px;"></div>
				活动模块简介：
				<div style="height: 20px;"></div>
				梦回党的摇篮：<br/>
				在3D世界参观红色爱国主义教育基地，了解中国共产党的伟大历程。
				<div style="height: 20px;"></div>
				重走长征路：<br/>
				&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;3D世界里重走长征路，互动游戏闯关。
				<div style="height: 20px;"></div>
				3D动画编程课学习：<br/>
				&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;学习红色主题3D动画编程课，提升创作和编程的水平。
				<div style="height: 20px;"></div>
				共筑红旗渠：<br/>
				&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;签名点亮红旗渠，为祖国送祝福，邀请家长一起，读党史，参与互动。
				<div style="height: 20px;"></div>
				3D作品大赛：<br/>
				&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;征集以“我为祖国献礼”“讲好中国故事”为主题的3D动画编程作品，参与国务院新闻办主办的创意编程大赛。]]
	},
    ai_school = {	
		title="帕拉卡AI虚拟校园",
		lb_bt_desc = "<<< 家长指南",
		rb_bt_desc = "进入",
		img = "Texture/Aries/Creator/keepwork/RedSummerCamp/common/bg_ai_602x374_32bits.png#0 0 602 374",
		begain_time = "",
		end_time = "",
		content=[[
				&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;虚拟校园是帕拉卡基于青少年计算机综合学习工具Paracraft和课程学习平台Keepwork的终端体验解决方案。打破物理上校园间的壁垒，为每一所学校提供一个平等、有趣的免费展示平台。徜徉其间，宛如置身花车巡礼，尽享创造乐趣。学生在老师的带领下，可各展所长，共同完成展示校园风采作品。老师也可通过Keepwork开设自己的虚拟课堂，以卡通形象出现在校园中，向校内外学生传道授业，展现师资风采。<br/>
				<div style="height: 20px;"></div>
				&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;每一个参加虚拟校园的学校都会获得一块校园舞台，学校可以自拟主题进行建设。每所校园的建设成果会反映到创意空间中，发动学生各展所长，通过加入动画、机器人程序、课程……同学们分享智慧，协力创造，共同成长！快来加入虚拟校园，让母校更有特色，从万千校园中脱颖而出吧！
			]]
	},

    zhengcheng = {	
		title="征程",
		lb_bt_desc = "<<< 家长指南",
		rb_bt_desc = "进入",
		img = "Texture/Aries/Creator/keepwork/RedSummerCamp/common/bg_zhengcheng_602x374_32bits.png#0 0 602 374",
		begain_time = "",
		end_time = "",
		content=[[
			&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2021年，中国共产党将迎来建党100周年，回首百年，在中国共产党的正确领导下，中华各族儿女正昂首阔步，从一个胜利走向另一个胜利，从一个辉煌走向另一个辉煌。波澜壮阔的百年间，中国共产党经历了无数的磨难与考验，而长征便是党史上一段熠熠生辉的记忆，为了帮助当代青少年重温这段记忆，我们帕拉卡推出了红色题材系列3D动画编程趣味课——《征程》。开启《征程》不仅可以和小伙伴们一起体验那段峥嵘的长征岁月，还可以在身临其境地参与中学习编程知识，通过一条条命令，一行行代码，控制自己的角色完成长征路上的一个个目标。<br/>
			加入帕拉卡会员，即可同大家一起踏上重走长征路与人工智能相结合的新征程！
		]]
	},

    main_world = {	
		title="创意空间",
		lb_bt_desc = "<<< 家长指南",
		rb_bt_desc = "进入创意大厅",
		img = "Texture/Aries/Creator/keepwork/RedSummerCamp/common/bg_zhengcheng_602x374_32bits.png#0 0 602 374",
		begain_time = "",
		end_time = "",
		content=[[
《创意空间》是一种利用人工智能技术的全新的<b>自主学习</b>场所。物理上可以利用学校的计算机教室，或通过学生自带电脑(平板)在普通教室中完成。<br/><div style="height: 10px;"></div>
《创意空间》是对传统编程教育的软件工具、教学方法、教学内容的<b>全面升级</b>。在创意空间中，老师和学生可以一同学习和成长，老师可以最大化的发挥出自己的特长，例如语文、英语、数学、美术、编剧、口才等等。
		]]
	},
}

local page
function RedSummerCampCommonPage.OnInit()
	page = document:GetPageCtrl();
end

function RedSummerCampCommonPage.Show(name)
	name = name or "summer_camp"
	RedSummerCampCommonPage.name = name
	RedSummerCampCommonPage.InitData(name)
	local enable_esc_key = System.options.isDevMode
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCommonPage.html",
			name = "RedSummerCampCommonPage.Show", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			enable_esc_key = enable_esc_key,
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

function RedSummerCampCommonPage.InitData(name)
	RedSummerCampCommonPage.GridData = {}
	local data = RedSummerCampCommonPage.pageData[name]

	table.insert(RedSummerCampCommonPage.GridData, data)
	
end


function RedSummerCampCommonPage.GetPageDt()
    return RedSummerCampCommonPage.pageData[RedSummerCampCommonPage.name]
end

function RedSummerCampCommonPage.ClickLBBt()
	if RedSummerCampCommonPage.name == "summer_camp" then
        local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua");
        Page.ShowShenTongBeiPage();
	elseif RedSummerCampCommonPage.name == "ai_school" then
		local RedSummerCampParentsPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampParentsPage.lua");
        RedSummerCampParentsPage.Show();
	elseif RedSummerCampCommonPage.name == "zhengcheng" then
        local RedSummerCampParentsPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampParentsPage.lua");
        RedSummerCampParentsPage.Show();
	end
end

function RedSummerCampCommonPage.ClickRBBt()
	if RedSummerCampCommonPage.name == "summer_camp" then
		local id_list = {
			ONLINE = 70351,
			RELEASE = 20669,
		}
		local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
		local httpwrapper_version = HttpWrapper.GetDevVersion();
		local world_id = id_list[httpwrapper_version]
		GameLogic.RunCommand(format('/loadworld -s -force %d', world_id))
	elseif RedSummerCampCommonPage.name == "ai_school" then
		local id_list = {
			ONLINE = 52217,
			RELEASE = 20617,
		}
		local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
		local httpwrapper_version = HttpWrapper.GetDevVersion();
		local world_id = id_list[httpwrapper_version]
		GameLogic.RunCommand(format('/loadworld -s -force %d', world_id))
	elseif RedSummerCampCommonPage.name == "zhengcheng" then
		GameLogic.RunCommand(format('/loadworld -s -force %d', 73139))
	end
end

function RedSummerCampCommonPage.IsAiSchoolType()
	return RedSummerCampCommonPage.name == "ai_school"
end

function RedSummerCampCommonPage.IsMainWorld()
	return RedSummerCampCommonPage.name == "main_world"
end