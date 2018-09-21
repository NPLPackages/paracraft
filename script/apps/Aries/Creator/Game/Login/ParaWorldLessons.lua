--[[
Title: ParaWorldLessons
Author(s): LiXizhi
Date: 2018/9/16
Desc: 

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ParaWorldLessons.lua");
local ParaWorldLessons = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ParaWorldLessons")
ParaWorldLessons.Show()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/DownloadWorld.lua");
NPL.load("(gl)script/ide/Files.lua");
local DownloadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.DownloadWorld")
local ParaWorldLessons = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ParaWorldLessons")

ParaWorldLessons.page = nil;

local app_install_details = {
	["paracraft"] = {
		title=L"paracraft创意空间", hasParacraft = true, 
		cmdLine = 'mc="true" bootstrapper="script/apps/Aries/main_loop.lua" noupdate="true"',
		redistFolder="haqi/", updaterConfigPath = "config/autoupdater/paracraft_win32.xml"
	},
	["haqi"] = {
		title=L"魔法哈奇", hasParacraft = true, 
		cmdLine = 'mc="false" bootstrapper="script/apps/Aries/main_loop.lua" noupdate="true" version="kids" partner="keepwork" config="config/GameClient.config.xml"',
		redistFolder="haqi/", updaterConfigPath = "config/autoupdater/paracraft_win32.xml"
	},
	["haqi2"] = {
		title=L"魔法哈奇-青年版", hasParacraft = false, 
		mergeParacraftPKGFiles = true, -- we will always apply the latest version of paracraft pkg on top of this one. 
		cmdLine = 'mc="false" bootstrapper="script/apps/Aries/main_loop.lua" noupdate="true" version="teen" partner="keepwork" config="config/GameClient.config.xml"',
		-- cmdLine = 'mc="false" bootstrapper="script/apps/Aries/main_loop.lua" noupdate="true" version="teen" config="config/GameClient.config.xml"',
		redistFolder="haqi2/", updaterConfigPath = "config/autoupdater/haqi2_win32.xml"
	},
}

function ParaWorldLessons.StaticInit()
	if(ParaWorldLessons.inited) then
		return;
	end
	ParaWorldLessons.inited = true;

end

-- init function. page script fresh is set to false.
function ParaWorldLessons.OnInit()
	ParaWorldLessons.StaticInit();
	ParaWorldLessons.page = document:GetPageCtrl();
end

-- show page
function ParaWorldLessons.ShowPage()
	local params;
	params = {
		url = "script/apps/Aries/Creator/Game/Login/ParaWorldLessons.html", 
		name = "ParaWorldLessons.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = false,
		bShow = true,
		zorder = 1,
		click_through = true, 
		directPosition = true,
			align = "_fi",
			x = 0,
			y = 0,
			width = 0,
			height = 0,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function ParaWorldLessons.OnClickWorld(name)
end

