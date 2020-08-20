--[[
Title: Class List 
Author(s): Chenjinxian
Date: 2020/7/6
Desc: 
use the lib:
-------------------------------------------------------
local ShareUrlContext = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/ShareUrlContext.lua");
ShareUrlContext.ShowPage()
-------------------------------------------------------
]]
local ClassManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/ClassManager.lua");
local ShareUrlContext = NPL.export()

local page;

function ShareUrlContext.OnInit()
	page = document:GetPageCtrl();
end

function ShareUrlContext.ShowPage()
	local params = {
		url = "script/apps/Aries/Creator/Game/Network/Admin/ClassManager/ShareUrlContext.html", 
		name = "ShareUrlContext.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = false,
		click_through = false, 
		enable_esc_key = true,
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		directPosition = true,
		align = "_rt",
		x = -376,
		y = 40,
		width = 376,
		height = 286,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function ShareUrlContext.OnClose()
	if (page) then
		page:CloseWindow();
	end
end

function ShareUrlContext.Refresh()
	if (page) then
		page:Refresh(0);
	end
end
			
function ShareUrlContext.ClassItems()
	return ClassManager.ShareLinkList;
end


function ShareUrlContext.OnClickItem(index)
	local link = ClassManager.ShareLinkList[index].link;
	ParaGlobal.ShellExecute("open", link, "", "", 1);
end
