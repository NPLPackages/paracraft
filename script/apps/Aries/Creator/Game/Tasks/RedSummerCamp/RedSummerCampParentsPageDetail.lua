--[[
Title: RedSummerCampParentsPageDetail
Author(s): pbb
Date: 2021/7/9
Desc:  the parent's detail page for red summer camp 2021
Use Lib:
-------------------------------------------------------
local RedSummerCampParentsPageDetail = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampParentsPageDetail.lua");
RedSummerCampParentsPageDetail.Show();
--]]

local RedSummerCampParentsPageDetail = NPL.export();

local page
RedSummerCampParentsPageDetail.ItemData={{}}

function RedSummerCampParentsPageDetail.OnInit()
	page = document:GetPageCtrl();
end

local pageConfig = {
	["network"] = "RedSummerCampParentsPageDetailNetWork",
	["charge"] = "RedSummerCampParentsPageDetailCharge"
}

function RedSummerCampParentsPageDetail.Show(name)
	local pageName = pageConfig[name]
	if not pageName then
		return 
	end
	local params = {
			url = string.format("script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/%s.html",pageName),
			name = "RedSummerCampParentsPageDetail.Show", 
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

