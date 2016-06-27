--[[
Title: ToolTipsPage.html code-behind script
Author(s): LiXizhi
Date: 2010/1/27
Desc: Create new world based on predefined template and open existing world. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/ToolTipsPage.lua");
MyCompany.Aries.Creator.ToolTipsPage.ShowPage("getting_started");
local ToolTipsPage = commonlib.gettable("MyCompany.Aries.Creator.ToolTipsPage")
ToolTipsPage.ShowPage("terra_paint");
-------------------------------------------------------
]]
NPL.load("(gl)script/kids/3DMapSystemUI/MiniGames/SwfLoadingBarPage.lua");
local ToolTipsPage = commonlib.gettable("MyCompany.Aries.Creator.ToolTipsPage")

local page;

-- whether the tooltip is expanded. 
ToolTipsPage.isExpanded = true;

-- show a given toolpage page
-- @param tips_name: if nil, it will close the tooltip page or it will be the string name of the tip. 
--	possible values are "getting_started"
function ToolTipsPage.ShowPage(tips_name)
	do 
		-- just never need this. 
		return 
	end

	if(tips_name) then
		
		System.App.Commands.Call("File.MCMLWindowFrame", {
				url = "script/apps/Aries/Creator/ToolTipsPage.html?tab="..tips_name, 
				name = "ToolTipsPage.ShowPage", 
				isShowTitleBar = false,
				DestroyOnClose = true,
				style = CommonCtrl.WindowFrame.ContainerStyle,
				allowDrag = false,
				zorder = -2,
				click_through = true,
				directPosition = true,
					align = "_lt",
					x = 0,
					y = 156,
					width = 210,
					height = 256,
			});
	else
		System.App.Commands.Call("File.MCMLWindowFrame", {
				name = "ToolTipsPage.ShowPage", 
				bShow = false,
			});
	end
end

function ToolTipsPage.OnInit()
	page = document:GetPageCtrl();
end

function ToolTipsPage.OnClickToggleView()
	ToolTipsPage.isExpanded = not ToolTipsPage.isExpanded;
	page:Refresh(0.01);
end

function ToolTipsPage.OnClickMoreHelp()
	_guihelper.MessageBox("<div>哈奇领地 初级体验版0.2 刚刚发布, 更多精彩内容请关注我们的官方网站.</div><div>http://haqi.61.com</div>");
end