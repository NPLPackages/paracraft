--[[
Title: RedSummerCampParentsPageDetailConfig
Author(s): pbb
Date: 2021/7/9
Desc:  the parent's detail page for red summer camp 2021
Use Lib:
-------------------------------------------------------
local RedSummerCampParentsPageDetailConfig = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampParentsPageDetailConfig.lua");
--]]

local RedSummerCampParentsPageDetailConfig = NPL.export();

RedSummerCampParentsPageDetailConfig.network ={
	{
		desc = [[——为孩子营造一个学习&展示人工智能的舞台<br/>
	“游玩”、“学习”、“创造”构成了一个孩子日常的生活。<br/>
	如果只有“游玩”，那是消极而没有意义的；<br/>
	如果只有“学习”，那是枯燥而没有快乐的；<br/>
	如果只有“创造”，那是漫无目的的。<br/><br/>

	《帕拉卡》Paracraft正是这样一款将“游玩”、“学习”、“创造”整合于一体的寓教于乐学习工具。通过人工智能赋能，为中国青少年营造一个学习、展示人工智能的舞台。<br/>
	21世纪将是人工智能的时代，大量传统的工作正在逐步被AI和计算机所取代。《帕拉卡》Paracraft基于全球领先的STEAM和PBL等自主教育理念，结合帕拉卡在软件编程方面十多年的丰富经验，研发出大量自主学习内容和网上课程。<br/>
		]],
		icons={"636 662 300 170","318 662 300 170","0 662 300 170"},
		iconsdetail={"△各省教育局认可正规校本课软件","△从兴趣出发培养学生自主式学习","△PBL项目式小组化学习"}
	},
	{
		desc = [[——告诉孩子，什么是人工智能<br/>
哈尔滨工业大学，参与新中国第一颗卫星研制工作的李铁才教授，基于人工智能研究领域中最重要的仿生学习，提出“相似性与相似性原理”（并出版相关著作），对人工智能做出了如下的定义：<br/>
思维和记忆构成了人类的智能；<br/>
编程和动画构成了计算的智能，即人工智能<br/>
《帕拉卡》是全球极少数真正从人工智能的本质去思考未来计算机教育的软件，《帕拉卡》软件的重点从来都不是单纯教授某一种编程语言，而是让孩子在使用编程去控制动画的过程中体会人工智能，培养对人工智能的兴趣，为成为新时代中国前沿人才播下种子。<br/>
		]],
		icons={"0 475 300 170","318 475 300 170","636 475 300 170"},
		iconsdetail={"△三维电脑动画的学习","△使用程序控制动画","△模拟人脑结构学习人工智能编程"}
	},
	{
		desc = [[——学以致用，伴随一生<br/>
由中国人完全自主研发的NPL（神经元并行）计算机语言以及ParaEngine三维图形引擎，构成了《帕拉卡》的大脑和心脏。《帕拉卡》正是使用NPL语言进行开发，同时孩子学习的也正是相同的计算机语言，《帕拉卡》足以成为陪伴孩子从计算机入门直至成长为计算机人才的全过程。<br/>
持续输出“作品”，是让人保持不断“学习”和“创造”的源动力。让每个学习了《帕拉卡》的孩子不仅都能收获自己的动画作品和编程作品，更重要的是通过用编程去控制动画，使之成为能够有简单交互的人工智能。而这种简单的交互，正是所有电子游戏最初始的形态。<br/>
		]],
		icons={"636 475 300 170","318 288 300 170","0 288 300 170"},
		iconsdetail={"△创作高水准动画短片","△制作可以弹奏的钢琴","△创造人工智能虚拟校园"}
	},
	{
		desc = [[——创造一个基于人工智能的未来虚拟校园<br/>
编程不应该是孤独的，人工智能更不应该是孤独的。当一个人工智能与另一个人工智能相遇的时候，或许“她们”将碰撞出奇妙的火花，这就是《帕拉卡》的人工智能虚拟校园计划。同学与同学的人工智能融合成一个虚拟的班级；班级与班级的人工智能融合成一个虚拟的校园。当我们徜徉在虚拟的校园中，被它的乐趣深深吸引的时候，我们应当感到兴奋和惊奇。因为眼前的所见，大多出自学生的作品。<br/>
		]],
		icons={"0 0 1016 268"},
	}
}

RedSummerCampParentsPageDetailConfig.charge = {
	{
		desc = [[——成为《帕拉卡》会员畅享全部服务<br/>
成为《帕拉卡》会员后畅享全部在线课程及数款由帕拉卡教育联盟企业共同制作的精品软件以及在线一对一的软件技术解决服务。<br/>
每周《帕拉卡》都会有新课不断上线，只要在会员权益期限内，均可无限次享受新课程的学习体验。<br/>]],
		icons={"1355 3 300 170","1035 3 300 170","1675 3 300 170"},
		iconsdetail={"专项赛事赛点精讲课程","AI宏示教辅助教学功能","联盟企业特色精品课程"}
	}
}

local RedSummerCampParentsPageDetailConfig = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampParentsPageDetailConfig.lua");
function RedSummerCampParentsPageDetailConfig.GetNetConfigDesc(index)
	local desc = RedSummerCampParentsPageDetailConfig.network[index].desc
	--print("desc=================",desc)
	return desc
end

function RedSummerCampParentsPageDetailConfig.GetNetConfigImgDesc(index,idx)
	local data = RedSummerCampParentsPageDetailConfig.network[index]
	if data then
		local str = data.iconsdetail[idx]
		print("str================",str,index,idx)
		--echo(data)
		return str
	end
end