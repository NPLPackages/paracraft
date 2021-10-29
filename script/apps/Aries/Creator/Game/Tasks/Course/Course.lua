--[[
	Title: Course
	Author(s): cf
	Date: 2021/7/19
	Desc: 玩学课堂选择页
	Use Lib:
        local Course = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Course/Course.lua");
        Course.Show();
        Course.Hide();
--]]

local Course = NPL.export();
local page;
local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
local RedSummerCampMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampMainPage.lua");
local StudyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/StudyPage.lua");

Course.currentId = 1;
Course.DS = {
	-- 征程
	{
		texName = "btn6_289X55_32bits",
		highLightTexName = "btn5_289X55_32bits",
		isSelected = true,
		title = "征程",
		content = [[
			1934年10月，中央红军从瑞金出发，战湘江、翻雪山、过草地……跨越2万5千里征程，人类历史上一场伟大的奇迹就此拉开了序幕。使用编程，指挥红军完成长征吧！
		]],
		listOfImg_1 = "4.1_112X74_32bits",
		listOfImg_2 = "5.1_112X74_32bits",
		listOfImg_3 = "6.1_112X74_32bits",
		listOfImg_4 = "7.1_112X74_32bits",
		hightShowImg = "4_497X232_32bits",
		highLightImgList = {
			"4_497X232_32bits",
			"5_497X232_32bits",
			"6_497X232_32bits",
			"7_497X232_32bits",
		},
		id = 1,
		-- 底部会员ban图
		bannerTex = "zhencheng_508X_32bits",
		worldId = 73139,
		marLeft = 265,
	},
	-- 孙子兵法
	{
		texName = "btn2_289X55_32bits",
		highLightTexName = "btn1_289X55_32bits",
		isSelected = false,
		title = "孙子兵法",
		content = [[
			春秋战国，百家争鸣。在魏国和齐国，两位史上杰出的军事家拉开了一场扣人心弦的较量。与孙膑一起，通过编程，指挥千军万马，击败庞涓吧！
		]],
		listOfImg_1 = "1.1_112X74_32bits",
		listOfImg_2 = "2.1_112X74_32bits",
		listOfImg_3 = "3.1_112X74_32bits",
		listOfImg_4 = "8.1_112X74_32bits",
		hightShowImg = "8_497X232_32bits",
		highLightImgList = {
			"1_497X232_32bits",
			"2_497X232_32bits",
			"3_497X232_32bits",
			"8_497X232_32bits",
		},
		id = 2,
		-- 底部会员ban图
		bannerTex = "huiyuan_508X_32bits",
		worldId = 19405,
		marLeft = 265,
	},

	-- 盖世英雄
	{
		texName = "btn4_289X55_32bits",
		highLightTexName = "btn3_289X55_32bits",
		isSelected = false,
		title = "盖世英雄",
		content = [[
			扮演中国风少年，跋山涉水，见义勇为，一路挑战48个动画与编程关卡。人工智能导师全程配音提示，手把手教你掌握文本化编程。学习打字，在关卡项目中实践，直接掌握帕拉卡代码方块中的21个常用命令，最终学会编程，创造属于你自己的3D动画编程武侠世界。
		]],
		listOfImg_1 = "GS_1.1_112X74_32bits",
		listOfImg_2 = "GS_2.1_112X74_32bits",
		listOfImg_3 = "GS_3.1_112X74_32bits",
		listOfImg_4 = "GS_4.1_112X74_32bits",
		hightShowImg = "GS_1_497X232_32bits",
		highLightImgList = {
			"GS_1_497X232_32bits",
			"GS_2_497X232_32bits",
			"GS_3_497X232_32bits",
			"GS_4_497X232_32bits",
		},
		id = 3,
		-- 底部会员ban图
		bannerTex = "huiyuan_508X_32bits",
		worldId = 71346,
		marLeft = 265,
	},
}
Course.OldDS = commonlib.clone(Course.DS);
Course.CurrentItem = { Course.DS[Course.currentId] }

function Course.OnInit()
	commonlib.echo("OnInit");
	page = document:GetPageCtrl();
end

function Course.Show() 
	Course.DS = Course.OldDS;
	local params = {
		url = "script/apps/Aries/Creator/Game/Tasks/Course/Course.html",
		name = "Course.Show", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = true,
		enable_esc_key = true,
		zorder = 0,
		-- app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		directPosition = true,
		align = "_ct",
		x = -890/2,
		y = -675/2,
		width = 890,
		height = 675,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end;

function Course.HandleSelect(index)
	index = tonumber(index);
	for _, item in ipairs(Course.DS) do
		item.isSelected = (item.id == index);
	end
	Course.currentId = index;
	Course.CurrentItem = { Course.DS[Course.currentId] };

	Course.Update();
end

function Course.HandleImgClick(index)
	commonlib.echo(index);
	commonlib.echo(Course.CurrentItem);
	Course.DS[Course.currentId].hightShowImg = Course.DS[Course.currentId].highLightImgList[index];
	Course.Update();
end

function Course.Update()
	if(page) then
		page:Refresh(0)
	end

	local rightContainer = page:GetNode("right_container");
	pe_gridview.SetDataSource(
		rightContainer, 
		page.name, 
		Course.CurrentItem);
	pe_gridview.DataBind(rightContainer, page.name, false);
end

function Course.HandleVipBtnClick()
	local VipPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/VipPage.lua");
    VipPage.ShowPage("red_summer_camp_main");
end

function Course.GoTo()
	GameLogic.RunCommand(format('/loadworld -s -force %d', Course.DS[Course.currentId].worldId))
end