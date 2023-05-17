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
		visible = false,
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
		visible = false,
		time = "2021年8月15日-2022年12月31日",
		signUpBtnInfo = {tooltip = "提交截止时间：2022年12月31日",endDay = "2022-12-31",endTime ="23:59:59"},
		timeRule = {
			startDay="2021-08-15",
			startTime="00:00:00",
			endDay="2022-12-31",
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
		visible = false,
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
		visible = false,
		time = "2022年3月 -2022年12月",
		signUpBtnInfo = {tooltip = "",endDay = "",endTime =""},
		timeRule = {
			startDay="2022-03-01",
			startTime="00:00:00",
			endDay="2022-12-31",
			endTime="23:59:59"
		},
		race="第十三届全国青少年科学影像节",
		content="第十三届全国青少年科学影像节申报作品分为科学探究纪录片、科学微电影和科普动画三个类别。推荐同学们使用帕拉卡软件制作动画短片申报科普动画类别，作品采用MP4格式文件。画面比例为4:3，分辨率为720×576（像素）或画面比例16:9，分辨率为1280×720（像素），作品的时长不得超过4分钟。个人或集体申报均可。每项作品辅导教师不得多于2人，每项作品主创人员不得多于5人，不得中途换人。作品须遵守国家有关法律法规，尊重文化传统、公共道德，符合民族政策，内容健康，主题鲜明。更多申报要求及详情请前往大赛官网。",
		ListData = {
			-- {name = "往届作品",node_name = "previous_works",url = L"https://v.qq.com/x/page/v090720dwvn.html",icon =[[<div zorder="-1" style="position:relative;left:13px;top:8px;width: 100px; height: 100px; background:url(Texture/Aries/Creator/keepwork/RedSummerCamp/common/tu2_98X98_32bits.png#0 0 98 98);"></div>]]}
		},
		leftTopBtnInfo = {btnText = "大赛官网",url = L"https://yxj.cacsi.org.cn/"},
		enterPage = {
			{name = "大赛官网", node_name = "enter_yxj_Official_web", url = L"https://yxj.cacsi.org.cn/ "}
		},
		name = "ke_xue_ying_xiang_jie",
		icon = "tu5_875X255_32bits"
	},
	{
		visible = false,
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
	},
	{
		visible = true,
		time = "2023年3月-2023年9月",
		signUpBtnInfo = {tooltip = "报名截止时间：2023年4月30日",endDay = "2023-04-30",endTime ="23:59:59"},
		timeRule = {
			startDay="2023-03-01",
			startTime="00:00:00",
			endDay="2023-09-31",
			endTime="23:59:59"
		},
		race="2023全国青少年信息素养大赛—3D动画编程赛",
		content="全国青少年信息素养大赛（以下简称大赛）是中国电子学会主办的“世界机器人大会青少年机器人设计与信息素养大赛”的重要赛事之一，根据《教育部办公厅关于公布2022-2025学年面向中小学生的全国性竞赛活动的通知》，大赛是“2022-2025学年面向中小学的全国竞赛名单”赛事之一。大赛自创立以来已连续成功举办七届，获得第二十九届、第三十届联合国国际科学与和平周“优秀获得奖”和“特别贡献奖”。<br/>&#10;3D动画编程赛项是为了让青少年通过国产自主研发的3D动画编程学习创作平台——帕拉卡（Paracraft），充分发挥想象力和创造力，展现青少年逻辑思考、算法实现和创意实现能力，开展科学与艺术的融合探索学习，培养青少年的创新精神与探索实践能力，全面提升信息素养。",
		ListData = {},
		leftTopBtnInfo = {btnText = "报名",url = L"https://ceic.kpcb.org.cn/comp/enrollMatch/38"},
		enterPage = {
			{name = "大赛官网", node_name = "enter_3ddhbcs_official_web", url = L"https://ceic.kpcb.org.cn/cms/cssc/7872.htm"}
		},
		name = "guo_ji_qing_shao_nian_bian_cheng",
		icon = "animation_race_875X255_32bits"
	},
	{
		visible = true,
		time = "2022年12月-2023年12月",
		signUpBtnInfo = {tooltip = "",endDay = "",endTime =""},
		timeRule = {
			startDay="2022-12-01",
			startTime="00:00:00",
			endDay="2023-12-31",
			endTime="23:59:59"
		},
		race="IYT-P国际青少年编程等级考试-3D动画编程",
		content="“IYT国际考级”项目英文名称为International Youth Test，简称“IYT”。由世界知名大学哈佛大学、哥伦比亚大学、加州大学伯克利分校、加州理工学院以及美国国家航空航天局喷气推进实验室、IBM、Facebook、RMDS Lab、中国数据中心等知名单位科学家、研究者共同发起的面向全球青少年的科技教育测评项目。“以考促学”推动全球青少年学习国际主流科技行业知识，为青少年发展、社会实践等提供统一、客观、公正的国际能力水平证明，提升青少年国际竞争力。证书可作为考生的科技特长证明及出国留学证明，针对通过8级及以上级别考试的优秀考生更可由RMDS专家出具留学推荐信。<br/>&#10;其中，国际青少年编程等级考试简称“IYT-P”面向全球6-18岁青少年编程能力水平的国际化评价项目自启动以来，得到国内外众多学校、考生及家长的积极参与及大力支持。 为更好地满足不同考生的考试需求，特增设3D动画编程考试项目。该项目考试对应使用工具为帕拉卡（Paracraft）3D动画编程教育平台。了解更多申报指南、要求等详情请前往大赛官网。",
		ListData = {},
		leftTopBtnInfo = {btnText = "大赛官网",url = L"www.iyttest.com"},
		enterPage = {
			{name = "大赛官网", node_name = "enter_zxxdnzzhd_Official_web", url = L"www.iyttest.com"}
		},
		name = "guo_ji_qing_shao_nian_bian_cheng",
		icon = "tu9_875X255_32bits"
	},
	{
		visible = true,
		time = "2022年12月-2023年4月",
		signUpBtnInfo = {tooltip = "",endDay = "",endTime =""},
		timeRule = {
			startDay="2022-12-01",
			startTime="00:00:00",
			endDay="2023-04-30",
			endTime="23:59:59"
		},
		race="2023年广东省科技劳动教育暨学生信息素养提升实践活动",
		content="由广东省教育厅主办，省教育厅事务中心(省电化教育馆)承办，以“创想、创作、创新、创造”为主题的“2023年广东省科技劳动教育暨学生信息素养提升实践活动”，旨在积极引导学生运用互联网、物联网、人工智能等信息科技，以项目化学习方式开展“创想、创新、创作、创造”等新型科技劳动实践探索活动，促进信息科技与跨学科知识的融合创新应用，提升实践能力，落实五育并举，促进学生德智体美劳全面发展。<br/>&#10;活动设有数字创作类、计算机思维类及科创实践类三大类。参赛者可以使用帕拉卡（Paracraft）平台创作作品送报数字创作类/计算机思维类。了解更多申报指南、要求等详情请前往大赛官网。",
		ListData = {},
		leftTopBtnInfo = {btnText = "大赛官网",url = L"https://srsc.gdedu.gov.cn/srsc/pub/tnotice/notice.do?act=notice&vccode=3386f0376f914954ae8edfb3a304560f"},
		enterPage = {
			{name = "大赛官网", node_name = "enter_zxxdnzzhd_Official_web", url = L"https://srsc.gdedu.gov.cn/srsc/pub/tnotice/notice.do?act=notice&vccode=3386f0376f914954ae8edfb3a304560f"}
		},
		name = "guang_dong_sheng_ke_ji_lao_dong_jiao_yu",
		icon = "tu10_875X255_32bits"
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
		local GeneralPage = NPL.load("script/ide/System/UI/Page.lua");
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
	else
		if RacePage.selectName == "quan_guo_qing_shao_nian_xin_xi_su_yang_da_sai" then
            GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.match.join", {
                useNoId = true
            });
        end
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
	local GeneralPage = NPL.load("script/ide/System/UI/Page.lua");
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
		if RacePage.selectName == "quan_guo_qing_shao_nian_xin_xi_su_yang_da_sai" then
            GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.match.officialweb", {
                useNoId = true
            });
        end
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