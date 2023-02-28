--[[
Title: UserProtocol
Author(s): wyx
Date: 2022/10/27
Desc:  
Use Lib:
-------------------------------------------------------
local UserProtocol = NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/UserProtocol.lua");
UserProtocol.ShowPage();
--]]
local HttpRequest = NPL.load('(gl)Mod/WorldShare/service/HttpRequest.lua')
local MdParser = NPL.load('(gl)Mod/WorldShare/parser/MdParser.lua')

local UserProtocol = NPL.export()
local page


UserProtocol.GridDs = {{}}

function UserProtocol.OnInit()
    page = document:GetPageCtrl();
	page.OnCreate = UserProtocol.OnCreate
end
function UserProtocol.GetPageCtrl()
    return page;
end
function UserProtocol.RefreshPage()
	if(page)then
		page:Refresh(0);
	end
end
function UserProtocol.ClosePage()
	if(page)then
		page:CloseWindow(true)
	end
end

function UserProtocol.ShowPage(index)
	UserProtocol.index = index
	local url = 'https://api.keepwork.com/core/v0/repos/official%2Fdocs/files/official%2Fdocs%2Freferences%2Flicense.md'
	if index == 2 then
		url = 'https://api.keepwork.com/core/v0/repos/official%2Fdocs/files/official%2Fdocs%2Freferences%2Fprivacy.md'
	end
	HttpRequest:Get(url, nil, nil, function(data, err)
		UserProtocol.htmlData = MdParser:MdToHtml(data, true)
		local params = {
			url = "script/apps/Aries/Creator/Game/Mobile/UserProtocol.html",
			name = "UserProtocol.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			enable_esc_key = true,
			directPosition = true,
			isTopLevel = true,
			zorder = 11,
			align = "_ct",
			x = -640/2,
			y = -672/2,
			width = 640,
			height = 672,
		};
		System.App.Commands.Call("File.MCMLWindowFrame", params)
	end)
end