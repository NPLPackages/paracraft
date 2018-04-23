--[[
Title: code behind page for StartAppPage.html
Author(s): LiXizhi
Date: 2008/5/28
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/Desktop/StartAppPage.lua");
Map3DSystem.UI.Desktop.StartAppPage.OnClickApp("worlds_GUID", "File.Open.LoadWorld")
-------------------------------------------------------
]]
local L = CommonCtrl.Locale("ParaWorld");


NPL.load("(gl)script/kids/3DMapSystemUI/Desktop/AppTaskBar.lua");

local StartAppPage = {};
commonlib.setfield("Map3DSystem.UI.Desktop.StartAppPage", StartAppPage)

---------------------------------
-- page event handlers
---------------------------------

-- switch to a given app. 
function StartAppPage.SwitchToApp(appkey)
	Map3DSystem.UI.AppTaskBar.SendMessage({type = Map3DSystem.UI.AppTaskBar.MSGTYPE.SWITCH_APP_DESKTOP, appkey = appkey});
end

-- user clicks the app button
-- @param appkey: [optional] if this is not empty, we will switch to the app. 
-- @param commandName: [optional] string, the named command to call after switching the app. 
-- @param commandParams: [optional], the command paramter of commandName
function StartAppPage.OnClickApp(appkey, commandName, commandParams)
	-- hide the start page
	Map3DSystem.UI.AppTaskBar.CancelAppList();
	
	-- switch to the app 
	if(appkey and appkey~="") then
		StartAppPage.SwitchToApp(appkey)
	end
	
	-- call command
	if(commandName) then
		Map3DSystem.App.Commands.Call (commandName, commandParams)
	end	
	
end

---------------------------------
-- data provider
---------------------------------

local dsOfficial = {
	{Title=L"创造", appkey="Creator_GUID", Icon="Texture/3DMapSystem/AppIcons/painter_64.dds", SubTitle=L"创造3D世界的工具集"},
	{Title=L"大自然", appkey="Env_GUID", Icon="Texture/3DMapSystem/AppIcons/Environment_64.dds", SubTitle=L"改变天空,陆地,海洋"},
	{Title=L"人物形象", appkey="CCS_GUID", Icon="Texture/3DMapSystem/AppIcons/People_64.dds", SubTitle=L"改变3D人物的形象"},
	{Title=L"世界", appkey="worlds_GUID", Icon="Texture/3DMapSystem/AppIcons/NewWorld_64.dds", SubTitle=L"创建、发布3D世界向导"},
	{Title=L"工程图", appkey="Blueprint_GUID", Icon="Texture/3DMapSystem/AppIcons/Blueprint_64.dds", SubTitle=L"创造、共享3D工程图纸"},
	--{Title="我的背包", appkey="Inventory_GUID", Icon="Texture/3DMapSystem/AppIcons/Inventory_64.dds", SubTitle="管理你的背包和资产"},
	{Title=L"资源管理", appkey="Assets_GUID", Icon="Texture/3DMapSystem/AppIcons/assets_64.dds", SubTitle=L"美术资源创作工具"},
}

local dsSocial = {
	--{Title="世界地图", appkey="Map_GUID", Icon="Texture/3DMapSystem/AppIcons/Map_64.dds", SubTitle="地球尺度的3D世界"},
	{Title=L"聊天", appkey="Chat_GUID", Icon="Texture/3DMapSystem/AppIcons/chat_64.dds", SubTitle=L"即时通讯;传送到朋友身边"},
	{Title=L"截图与录像", appkey="ScreenShot_GUID", Icon="Texture/3DMapSystem/AppIcons/VideoRecorder_64.dds", SubTitle=L"截图上传, 视频录像"},
	{Title=L"我的档案", appkey="profiles_GUID", Icon="Texture/3DMapSystem/AppIcons/Profiles_64.dds", SubTitle=L"个人信息, 交友"},
}

local dsGame = {
	{Title=L"宠物", appkey="Pet_GUID", Icon="Texture/3DMapSystem/AppIcons/Pet_64.dds", SubTitle=L"养宠物的游戏"},
	{Title=L"电子书", appkey="EBook_GUID", Icon="Texture/3DMapSystem/AppIcons/Intro_64.dds", SubTitle=L"制作3D电子书"},
}

local dsOthers = {
	{Title=L"帕拉巫开发", appkey="Developers_GUID", Icon="Texture/3DMapSystem/AppIcons/Debug_64.dds", SubTitle=L"PEDN 开发网与工具箱"},
}

-- data source function for official app. 
function StartAppPage.DS_Func_Official(index)
	if(dsOfficial) then
		if(index==nil) then
			return #dsOfficial;
		else
			return dsOfficial[index];
		end
	end
end

-- data source function for social  app. 
function StartAppPage.DS_Func_Social(index)
	if(dsSocial) then
		if(index==nil) then
			return #dsSocial;
		else
			return dsSocial[index];
		end
	end
end


-- data source function for game  app. 
function StartAppPage.DS_Func_Game(index)
	if(dsGame) then
		if(index==nil) then
			return #dsGame;
		else
			return dsGame[index];
		end
	end
end


-- data source function for others app. 
function StartAppPage.DS_Func_Others(index)
	if(dsOthers) then
		if(index==nil) then
			return #dsOthers;
		else
			return dsOthers[index];
		end
	end
end