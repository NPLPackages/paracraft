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
	UserProtocol.index = index;
	if System.options.isStrictGameMode then
		UserProtocol.ShowLocalPage(index)
		return
	end
	local url = "";
	local androidFlavor = System.os.GetAndroidFlavor();

	if index == 1 then
		-- agreement page
		if (androidFlavor == "xiaomi" or androidFlavor == "huawei") then
			url = "https://api.keepwork.com/core/v0/repos/official%2Fdocs/files/official%2Fdocs%2Freferences%2Flicense_app.md";
		else
			url = "https://api.keepwork.com/core/v0/repos/official%2Fdocs/files/official%2Fdocs%2Freferences%2Flicense.md";
		end
	elseif index == 2 then
		-- user privacy
		if (androidFlavor == "xiaomi" or androidFlavor == "huawei") then
			-- url = "https://api.keepwork.com/core/v0/repos/official%2Fprivacy_app/files/official%2Fprivacy_app%2Findex.md";
			url = "https://api.keepwork.com/core/v0/repos/official%2Fdocs/files/official%2Fdocs%2Freferences%2Fprivacy.md";
		else
			url = "https://api.keepwork.com/core/v0/repos/official%2Fdocs/files/official%2Fdocs%2Freferences%2Fprivacy.md";
		end
		if System.options.isEducatePlatform then
			url = "https://api.keepwork.com/core/v0/repos/official%2Fkeepwork/files/official%2Fkeepwork%2Flicense%2Fedu_cn.md"
			if Mod.WorldShare.Utils.IsEnglish() then
				url = "https://api.keepwork.com/core/v0/repos/official%2Fkeepwork/files/official%2Fkeepwork%2Flicense%2Fedu-en.md"
			end
		end
		if System.options.partner == "huawei" then
			url = "https://api.keepwork.com/core/v0/repos/official%2Fdocs/files/official%2Fdocs%2Freferences%2Fharmony_privacy_papaadventure.md"
			local privacy_name =  ParaEngine.GetAppCommandLineByParam("privacyname","")  
			if privacy_name and privacy_name ~= "" then
				--"https://api.keepwork.com/core/v0/repos/official%2Fkeepwork/files/official%2Fkeepwork%2Flicense%2Ftime2_harmony.md"
				local baseurl ="https://api.keepwork.com/core/v0/repos/official%2Fkeepwork/files/official%2Fkeepwork%2Flicense%2F"
				url = baseurl..privacy_name.."_harmony.md"
			end
		end
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
		if System.options.isCommunity then
			params.url = "script/apps/Aries/Creator/Game/Tasks/Community/Setting/UserProtocol.html"
			params.align = "_fi"
			params.x = 0
			params.y = 0
			params.width = 0
			params.height = 0
		end
		System.App.Commands.Call("File.MCMLWindowFrame", params)
	end)
end

function UserProtocol.ShowLocalPage(index)
	local UserProtocolConfig = NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/UserProtocolConfig.lua");
	if index == 1 then
		local mdData = UserProtocolConfig:GetUserLicense();
		UserProtocol.htmlData = MdParser:MdToHtml(mdData, true)
	elseif index == 2 then
		local mdData = UserProtocolConfig:GetUserPrivacy();
		UserProtocol.htmlData = MdParser:MdToHtml(mdData, true)
	end
	if UserProtocol.htmlData then
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
		if System.options.isCommunity then
			params.url = "script/apps/Aries/Creator/Game/Tasks/Community/Setting/UserProtocol.html"
			params.align = "_fi"
			params.x = 0
			params.y = 0
			params.width = 0
			params.height = 0
		end
		System.App.Commands.Call("File.MCMLWindowFrame", params)
	end
end