--[[
Title: 创意大赛
Author(s):Wyx
Date: 2021/10/13
Desc:
Use Lib:
-------------------------------------------------------
local RacePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Race/RacePage.lua")
RacePage.Show()
--]]

local RacePage = NPL.export()
local LanQiaoBeiPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Race/LanQiaoBeiPage.lua")
local page
RacePage.ItemData = {
	{	
		visible = false,
		time = "2021年7月15日-2022年08月30日",
		signUpBtnInfo = {tooltip = "报名截止时间：2021年11月15日",endDay = "2021-11-15",endTime ="23:59:59"},
		timeRule = {
			startDay="2021-07-15",
			startTime="00:00:00",
			endDay="2022-08-30",
			endTime="23:59:59"
		},
		race="“神通杯” 第一届全国学校联盟中小学计算机编程大赛",
		content="大赛包含小学组图形化编程和中学组Python编程两个项目，比赛形式为理论知识（理论答题）+技能成果（作品创作）两项。大赛作品创作环节设有三大竞赛主题，分别为“编程与学科学习”、“人工智能创作”、“编程与未来生活”，同学们可创作3D动画或编程作品。例如将课本上的任意知识创作成动画，用动画或编程展示人类的未来生活等等。&#10备赛推荐课程：《盖世英雄》《长征》《孙子兵法》《征程》等系列主题课程。",
		ListData = {
			{name = "赛事章程",node_name = "constitution",icon =[[<div zorder="-1" style="position:relative;left:13px;top:8px;width: 100px; height: 100px; background:url(Texture/Aries/Creator/keepwork/RedSummerCamp/shentongbei/constitution_32bits.png#0 0 99 98);"></div>]]},
			{name = "课程安排",node_name = "arrange",icon =[[<div zorder="-1" style="position:relative;left:13px;top:8px;width: 100px; height: 100px; background:url(Texture/Aries/Creator/keepwork/RedSummerCamp/shentongbei/course_32bits.png#0 0 99 98);"></div>]]},
			{name = "赛事资质",node_name = "certificate",icon =[[<div zorder="-1" style="position:relative;left:13px;top:8px;width: 100px; height: 100px; background:url(Texture/Aries/Creator/keepwork/RedSummerCamp/shentongbei/qualification_32bits.png#0 0 99 98);"></div>]]}
		},
		leftTopBtnInfo = {btnText = "集训报名"},
		enterPage = {
			{name = "进入集训营", node_name = "enter_train_world", worldId = 72945}
		},
		name = "shen_tong_bei",
		icon = "tu1_875X255_32bits"
	},
	{
		visible = true,
		time = "2022年3月-2022年11月",
		signUpBtnInfo = {tooltip = "",endDay = "",endTime =""},
		timeRule = {
			startDay="2022-03-01",
			startTime="00:00:00",
			endDay="2022-11-30",
			endTime="23:59:59"
		},
		race="2022年度青少年人工智能综合素质测评",
		content="为了全面提高中国青少年的人工智能综合素质，北京理工大学和中国关心下一代工作委员会健康体育发展中心共同建立青少年人工智能基础教育人才培养基地，基地负责青少年人工智能综合素质测评的组织与实施工作，联合举办一年2-4次青少年人工智能综合素质测评。<br/>&#10;青少年人工智能综合素质测评内容有以下6个版块，人工智能基础认知能力、人工智能实体模块化编程能力、人工智能可视化编程能力、人工智能代码编程能力、人工智能技术认知及应用能力、人工智能创客素养能力等多个维度对4-18岁的青少年进行专业、多维度的能力测试。通过多维度的能力测试，展示青少年在人工智能基础教育阶段的学习成果，为青少年在人工智能领域的学习提供明确方向，为国家选拔人工智能人才提供重要依据。",
		ListData = {
		},
		leftTopBtnInfo = {btnText = "报名",url = L"http://www.chinaaitest.com/registration/onlinesignup/"},
		enterPage = {
			{name = "官网", node_name = "enter_rgzhsz_Official_web",url = L"http://www.chinaaitest.com/"}
		},
		name = "ren_gong_zong_he_su_zhi",
		icon = "zonghesuzhiceping_875X255_32bits"
	},
	{
		visible = false,
		time = "2021年9月10日-2022年5月",
		signUpBtnInfo = {tooltip = "报名截止时间：2022年3月",endDay = "2022-2-28",endTime ="23:59:59"},
		timeRule = {
			startDay="2021-09-10",
			startTime="00:00:00",
			endDay="2022-05-31",
			endTime="23:59:59"
		},
		race="第十三届蓝桥杯青少年创意编程组大赛",
		content="大赛设有帕拉卡（Paracraft）组竞赛，推荐同学们参与该组竞赛。帕拉卡（Paracraft）组编程竞赛包含STEMA考试（选拔赛）、省赛及国赛。试题形式包含选择题、搭建与动画题、现场编程题。竞赛所涉及的帕拉卡（Paracraft）编程基础知识包括：帕拉卡（Paracraft）基本操作，代码方块和电影方块的使用，顺序结构、选择结构和循环结构的使用，变量、随机数的使用，常用的数学运算，数学表达式，克隆、逻辑判断和逻辑运算；空间三维坐标等。操作机制包括：模型搭建和动画，任务分解机制，角色移动机制，与鼠标及键盘的互动机制。",
		ListData = {
		},
		leftTopBtnInfo = {btnText = "大赛报名"},
		enterPage = {
			{name = "大赛详情", node_name = "enter_lqb_Official_web"}
		},
		name = "lan_qiao_bei",
		icon = "tu2_875X255_32bits"
	},
	{
		visible = true,
		time = "2021年8月15日-2022年8月31日",
		signUpBtnInfo = {tooltip = "提交截止时间：2022年8月31日",endDay = "2022-8-31",endTime ="23:59:59"},
		timeRule = {
			startDay="2021-08-15",
			startTime="00:00:00",
			endDay="2022-8-31",
			endTime="23:59:59"
		},
		race="2021青少年“讲好中国故事”创意编程大赛",
		content="大赛面向全国各小学、初中、高中（含职高、中专技校），青年建筑师及广大创意编程爱好者。参赛者可使用帕拉卡围绕“百年新长征”主题创作3D动画作品和3D编程作品进行参赛，作品时长要求不少于2分钟，个人或集体创作均可，集体创作主创团队不超过3人，辅导教师不得多于2人，一个学生（团队）可申报多个作品。&#10备赛推荐课程：《盖世英雄》《长征》《孙子兵法》《征程》等系列主题课程。",
		ListData = {
		},
		leftTopBtnInfo = {btnText = "提交作品",worldId = 80682 },
		enterPage = {
			{name = "大赛官网", node_name = "enter_jhzggs_Official_web", url = L"https://keepwork.com/cp/csa"}
		},
		name = "zhong_guo_gu_shi",
		icon = "tu3_875X255_32bits"
	},
	{
		visible = true,
		time = "2021年8月-2022年12月",
		signUpBtnInfo = {tooltip = "",endDay = "",endTime =""},
		timeRule = {
			startDay="2021-08-01",
			startTime="00:00:00",
			endDay="2022-12-31",
			endTime="23:59:59"
		},
		race="第35届全国青少年科技创新大赛线上展示交流活动",
		content="大赛包含青少年科技创新成果竞赛、科技辅导员科技教育创新成果竞赛、青少年科技实践活动比赛、青少年科技创意比赛、少年儿童科学幻想绘画比赛五项赛事。可以以帕拉卡为研究基础申报青少年科技创新成果竞赛、科技辅导员科技教育创新成果竞赛、青少年科技创意比赛三项赛事。申报材料需包含项目说明文档及附件。更多申报要求可参考大赛官网。",
		ListData = {
		},
		leftTopBtnInfo = {btnText = "大赛官网",url = L"https://castic.cyscc.org/index.aspx"},
		enterPage = {
			{name = "大赛官网", node_name = "enter_kjcxds_Official_web", url = L"https://castic.cyscc.org/index.aspx"}
		},
		name = "ke_ji_da_sai",
		icon = "tu4_875X255_32bits"
	},
	{
		visible = true,
		time = "2021年8月 -2022年12月",
		signUpBtnInfo = {tooltip = "",endDay = "",endTime =""},
		timeRule = {
			startDay="2021-08-01",
			startTime="00:00:00",
			endDay="2022-12-31",
			endTime="23:59:59"
		},
		race="第十二届全国青少年科学影像节",
		content="第十二届全国青少年科学影像节申报作品分为科学探究纪录片、科学微电影和科普动画三个类别。推荐同学们使用帕拉卡制作动画短片申报科普动画类别，作品要求为采用MP4格式文件，画面比例为4:3或16:9，时长为5-8分钟。个人或集体创作均可，集体创作主创团队不超过8人，辅导教师不得多于2人，一个学生（团队）可申报多个作品。更多申报要求可参考往届作品及大赛官网。",
		ListData = {
			{name = "往届作品",node_name = "previous_works",url = L"https://v.qq.com/x/page/v090720dwvn.html",icon =[[<div zorder="-1" style="position:relative;left:13px;top:8px;width: 100px; height: 100px; background:url(Texture/Aries/Creator/keepwork/RedSummerCamp/common/tu2_98X98_32bits.png#0 0 98 98);"></div>]]}
		},
		leftTopBtnInfo = {btnText = "大赛官网",url = L"https://yxj.cyscc.org/"},
		enterPage = {
			{name = "大赛官网", node_name = "enter_yxj_Official_web", url = L"https://yxj.cyscc.org/ "}
		},
		name = "ke_xue_ying_xiang_jie",
		icon = "tu5_875X255_32bits"
	},
	{
		visible = true,
		time = "2022年4月10日-2022年5月10日",
		signUpBtnInfo = {tooltip = "报名截止时间：2022年5月10日",endDay = "2022-5-10",endTime ="23:59:59"},
		timeRule = {
			startDay="2022-04-10",
			startTime="00:00:00",
			endDay="2022-05-10",
			endTime="23:59:59"
		},
		race="第二十三届全国中小学生电脑制作活动",
		content="全国学生信息素养提升实践活动（全国中小学电脑制作活动）由中央电化教育馆主办，旨在促进中国基础教育信息化应用、展示中小学生信息技术实践成果的全国性展示交流活动。活动设置有数字创作、计算思维、科创实践三大类内容，同学们可以使用帕拉卡创作作品报送参加数字创作中的微视频/微动画类别，以及计算思维中的创意编程类别。",
		ListData = {},
		leftTopBtnInfo = {btnText = "大赛报名",url = L"http://huodong2000.ncet.edu.cn/news/2021930/n68061253.html"},
		enterPage = {
			{name = "大赛官网", node_name = "enter_zxxdnzzhd_Official_web", url = L"http://huodong2000.ncet.edu.cn/"}
		},
		name = "zhong_xiao_xue_dian_nao_zhi_zuo_huo_dong",
		icon = "tu6_875X255_32bits"
	}
}

RacePage.Datas = {}
for key, value in pairs(RacePage.ItemData) do
	if value.visible then
		table.insert(RacePage.Datas,value)
	end
end

function RacePage.OnInit()
	page = document:GetPageCtrl()
	RacePage.ShowRaceDownTime()
	page.OnCreate = RacePage.OnCreate
	page.OnClose = RacePage.OnClose
end

function RacePage.Show()
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/Race/RacePage.html",
			name = "RacePage.Show",
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
				DesignResolutionWidth = 1280,
				DesignResolutionHeight = 720,
		}
	System.App.Commands.Call("File.MCMLWindowFrame", params)
end

function RacePage.OnClose()
	RacePage.ClearTimer()
	RacePage.InitIndex()
end

function RacePage.InitIndex()
	RacePage.index = 1
	RacePage.selectName = RacePage.GetNameByIndex(RacePage.index)
end

function  RacePage.CheckRaceEnd()
	local server_time = RacePage.GetServerTime()
	local itemData = RacePage.Datas[RacePage.index]
	local start_date_timestamp = RacePage.getTimeStamp(itemData.timeRule.startDay,itemData.timeRule.startTime)

	local end_date_timestamp = RacePage.getTimeStamp(itemData.timeRule.endDay,itemData.timeRule.endTime)
	local isEnd = server_time >= end_date_timestamp
	return isEnd
end

function RacePage.CheckSignUpEndTime()
	local itemData = RacePage.Datas[RacePage.index]
	if itemData.signUpBtnInfo.endDay ~= nil and itemData.signUpBtnInfo.endDay ~= "" then
		local server_time = RacePage.GetServerTime()
		local end_date_timestamp = RacePage.getTimeStamp(itemData.signUpBtnInfo.endDay,itemData.signUpBtnInfo.endTime)
		local isEnd = server_time >= end_date_timestamp
		return isEnd
	else
		return false
	end
end

function RacePage.getTimeStamp(dayStr,timeStr)
	local year,month,day = dayStr:match("^(%d+)%D(%d+)%D(%d+)")
	local hour,min,sec =  timeStr:match("^(%d+)%D(%d+)%D(%d+)")
	local timestamp = os.time({day=tonumber(day), month=tonumber(month), year=tonumber(year), hour=tonumber(hour), min=tonumber(min), sec=tonumber(sec)})
	return timestamp
end

function RacePage.ShowRaceDownTime()
	RacePage.ClearTimer()

	local isEnd = RacePage.CheckRaceEnd()
	if isEnd then
		page:SetValue("down_time_text", "已结束")
	else
		local itemData = RacePage.Datas[RacePage.index]
		local server_time = RacePage.GetServerTime()
		local end_date_timestamp = RacePage.getTimeStamp(itemData.timeRule.endDay,itemData.timeRule.endTime)
		local remained_sec = end_date_timestamp - server_time
		local day,hour,min,second = RacePage.SecondFormat(remained_sec)
		local s = string.format("%02d天 %02d时%02d分%02d秒",day,hour,min,second)
		page:SetValue("down_time_text", s)
		RacePage.updateTimer = commonlib.Timer:new({callbackFunc = function(timer)
			RacePage.ShowRaceDownTime()
		end})
		RacePage.updateTimer:Change(1000, nil)
	end
end

function RacePage.ClearTimer()
	if RacePage.updateTimer then
		RacePage.updateTimer:Change()
		RacePage.updateTimer = nil
	end
end

function RacePage.SecondFormat(seconds)
	local day = math.floor(seconds / 86400)
	local hour = math.floor((seconds - day * 86400) / 3600)
	local min = math.floor((seconds - day * 86400 - hour * 3600) / 60)
	local second = seconds - day * 86400 - hour * 3600 - min * 60
	return day,hour,min,second
end

function RacePage.GetServerTime()
    if System.options.isDevMode then
        return os.time()
    end
    local timp_stamp = GameLogic.GetFilters():apply_filters('store_get', 'world/currentServerTime')
    return timp_stamp
end

--[[ 点击集训报名/提交作品/大赛官网 ]]
function RacePage.ClickCompetition()
	if RacePage.selectName == "shen_tong_bei" then
		--神通杯
		local GeneralPage = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua")
		GeneralPage.ShowShenTongBeiCompetitionPage()
	elseif RacePage.selectName == "lan_qiao_bei" then
		--蓝桥杯
		LanQiaoBeiPage.SetSelectIndex(1)
        LanQiaoBeiPage.Show()
	elseif RacePage.selectName == "ren_gong_zong_he_su_zhi" then
		--2022年度青少年人工智能综合素质测评
		local url = RacePage.Datas[RacePage.index].leftTopBtnInfo.url
		ParaGlobal.ShellExecute("open", url, "", "", 1)
	elseif RacePage.selectName == "zhong_guo_gu_shi"then
		--讲好中国故事
		local worldId = RacePage.Datas[RacePage.index].leftTopBtnInfo.worldId
		GameLogic.RunCommand(string.format("/loadworld -s -force %d", worldId))
	elseif RacePage.selectName == "ke_ji_da_sai"then
		--全国青少年科技创新大赛
		local url = RacePage.Datas[RacePage.index].leftTopBtnInfo.url
		ParaGlobal.ShellExecute("open", url, "", "", 1)
	elseif  RacePage.selectName == "ke_xue_ying_xiang_jie" then
		--全国青少年科学影像节
		local url = RacePage.Datas[RacePage.index].leftTopBtnInfo.url
		ParaGlobal.ShellExecute("open", url, "", "", 1)
	elseif  RacePage.selectName == "zhong_xiao_xue_dian_nao_zhi_zuo_huo_dong" then
		--全国中小学生电脑制作活动
		local url = RacePage.Datas[RacePage.index].leftTopBtnInfo.url
		ParaGlobal.ShellExecute("open", url, "", "", 1)
	end
end

--[[ 大赛列表条目点击 ]]
function RacePage.OnRaceClick(index)
	if index ==  RacePage.index then
		return
	end
	RacePage.index = index
	RacePage.selectName = RacePage.GetNameByIndex(RacePage.index)
	page:Refresh(0)
end

function RacePage.GetNameByIndex(index)
	local name = ""
	for k,v in pairs(RacePage.Datas) do 
		if k == index then
			name = v.name
			break
		end
	end
	return name
end

--[[ 右边大赛详情条目点击 ]]
function RacePage.OnClickRaceItem(index)
	local ListData = RacePage.Datas[RacePage.index].ListData
	if ListData == nil then
		return
	end
	local node_name = ListData[index].node_name
	local GeneralPage = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua")
	if node_name == "constitution" then
		-- 赛事章程
		GeneralPage.ShowShenTongBeiConstituionPage()
	elseif node_name == "arrange" then
		-- 课程安排
		GeneralPage.ShowShenTongBeiCourePage()
	elseif node_name == "certificate" then
		-- 赛事资质
		GeneralPage.ShowShenTongBeiZiZhiPage()
	elseif node_name == "previous_works" then
		-- 往届作品
		local url = ListData[index].url
		ParaGlobal.ShellExecute("open", url, "", "", 1)
	end
end

--[[ 大赛右下角点击进入]]
function RacePage.OnEnterPage(name)
	if name == "enter_train_world" then
		local worldId = RacePage.Datas[RacePage.index].enterPage[1].worldId
		GameLogic.RunCommand(string.format("/loadworld -s -force %d", worldId))
	elseif name == "enter_rgzhsz_Official_web" then
		local url = RacePage.Datas[RacePage.index].enterPage[1].url
		ParaGlobal.ShellExecute("open", url, "", "", 1)
	elseif name == "enter_lqb_Official_web" then
		LanQiaoBeiPage.SetSelectIndex(2)
		LanQiaoBeiPage.Show()
	else
		local url = RacePage.Datas[RacePage.index].enterPage[1].url
		ParaGlobal.ShellExecute("open", url, "", "", 1)
	end
end

function RacePage.OnCreate()
	local pNode = ParaUI.GetUIObject("mouse_enter_tip")
    if pNode then
        pNode.visible = false
    end
end

function RacePage.OnMouseEnter(tipUiName)
    local pNode = ParaUI.GetUIObject(tipUiName)
    if pNode then
        local tooltip = RacePage.Datas[RacePage.index].signUpBtnInfo.tooltip
        pNode.visible = tooltip ~= nil and tooltip ~= ""
    end
end

function RacePage.OnMouseLeave(tipUiName)
    local pNode = ParaUI.GetUIObject(tipUiName)
    if pNode then
        pNode.visible = false
    end
end

RacePage.InitIndex()