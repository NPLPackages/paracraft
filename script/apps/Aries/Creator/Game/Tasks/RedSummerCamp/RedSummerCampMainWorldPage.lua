--[[
Title: RedSummerCampMainWorldPage
Author(s): yangguiyi
Date: 2021/9/9
Desc:  the common page for red summer camp 2021
Use Lib:
-------------------------------------------------------
local RedSummerCampMainWorldPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampMainWorldPage.lua");
RedSummerCampMainWorldPage.Show();
--]]

local RedSummerCampMainWorldPage = NPL.export();
RedSummerCampMainWorldPage.GridData = {}
RedSummerCampMainWorldPage.pageData = {
    main_world = {	
		title="创意空间",
		lb_bt_desc = "<<< 家长指南",
		rb_bt_desc = "进入创意大厅",
		img = "Texture/Aries/Creator/keepwork/RedSummerCamp/common/tu_602X454_32bits.png#0 0 602 454",
		begain_time = "",
		end_time = "",
		content=[[
《创意空间》是一种利用人工智能技术的全新的<b>自主学习</b>场所。物理上可以利用学校的计算机教室，或通过学生自带电脑(平板)在普通教室中完成。<br/><div style="height: 10px;"></div>
《创意空间》是对传统编程教育的软件工具、教学方法、教学内容的<b>全面升级</b>。在创意空间中，老师和学生可以一同学习和成长，老师可以最大化的发挥出自己的特长，例如语文、英语、数学、美术、编剧、口才等等。
		]]
	},
}

local page
function RedSummerCampMainWorldPage.OnInit()
	page = document:GetPageCtrl();
	page.OnClose = RedSummerCampMainWorldPage.OnClose
end

function RedSummerCampMainWorldPage.OnClose()
	RedSummerCampMainWorldPage.OpenFromCommandMenu = nil
end

function RedSummerCampMainWorldPage.SetOpenFromCommandMenu(flag)
	RedSummerCampMainWorldPage.OpenFromCommandMenu = flag
end

function RedSummerCampMainWorldPage.GetOpenFromCommandMenu()
	return RedSummerCampMainWorldPage.OpenFromCommandMenu
end

function RedSummerCampMainWorldPage.Show()
	local name = "main_world"
	RedSummerCampMainWorldPage.name = name
	RedSummerCampMainWorldPage.InitData(name)
	local enable_esc_key = System.options.isDevMode
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampMainWorldPage.html",
			name = "RedSummerCampMainWorldPage.Show", 
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

function RedSummerCampMainWorldPage.InitData(name)
	RedSummerCampMainWorldPage.GridData = {}
	local data = RedSummerCampMainWorldPage.pageData[name]

	table.insert(RedSummerCampMainWorldPage.GridData, data)
	
end


function RedSummerCampMainWorldPage.GetPageDt()
    return RedSummerCampMainWorldPage.pageData[RedSummerCampMainWorldPage.name]
end

function RedSummerCampMainWorldPage.ClickLBBt()
	if RedSummerCampMainWorldPage.name == "summer_camp" then
        local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua");
        Page.ShowShenTongBeiPage();
	elseif RedSummerCampMainWorldPage.name == "ai_school" then
		local RedSummerCampParentsPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampParentsPage.lua");
        RedSummerCampParentsPage.Show();
	elseif RedSummerCampMainWorldPage.name == "zhengcheng" then
        local RedSummerCampParentsPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampParentsPage.lua");
        RedSummerCampParentsPage.Show();
	end
end

function RedSummerCampMainWorldPage.ClickRBBt()
	local id_list = {
		ONLINE = 19759,
		RELEASE = 1296 ,
	};
	local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
	local project_id = id_list[HttpWrapper.GetDevVersion()]
	GameLogic.RunCommand(format('/loadworld -s -force %d', project_id))
end

function RedSummerCampMainWorldPage.IsAiSchoolType()
	return RedSummerCampMainWorldPage.name == "ai_school"
end

function RedSummerCampMainWorldPage.IsMainWorld()
	return RedSummerCampMainWorldPage.name == "main_world"
end

function RedSummerCampMainWorldPage.ClosePage()
    if page then
        page:CloseWindow();
        page = nil
    end
end

function RedSummerCampMainWorldPage.IsOpen()
	return page and page:IsVisible()
end