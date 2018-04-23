--[[
Title: MiniGames
Author(s):  
Date: 2009/4/8
Desc: 
 
------------------------------------------------------------
db registration insert script
INSERT INTO apps VALUES (NULL, 'MiniGames_GUID', 'MiniGames', '1.0.0', 'http://www.paraengine.com/apps/MiniGames_v1.zip', 'YourCompany', 'enUS', 'script/kids/3DMapSystemUI/MiniGames/IP.xml', '', 'script/kids/3DMapSystemUI/MiniGames/app_main.lua', 'Map3DSystem.App.MiniGames.MSGProc', 1);
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/MiniGames/app_main.lua");
------------------------------------------------------------
]]

NPL.load("(gl)script/kids/3DMapSystemUI/MiniGames/MiniGameCommon.lua");
local MiniGameCommon = commonlib.gettable("Map3DSystem.App.MiniGames.MiniGameCommon")

-- create class
local MiniGames = commonlib.gettable("Map3DSystem.App.MiniGames");
-------------------------------------------
-- event handlers
-------------------------------------------

-- OnConnection method is the obvious point to place your UI (menus, mainbars, tool buttons) through which the user will communicate to the app. 
-- This method is also the place to put your validation code if you are licensing the add-in. You would normally do this before putting up the UI. 
-- If the user is not a valid user, you would not want to put the UI into the IDE.
-- @param app: the object representing the current application in the IDE. 
-- @param connectMode: type of Map3DSystem.App.ConnectMode. 
function Map3DSystem.App.MiniGames.OnConnection(app, connectMode)
	if(connectMode == Map3DSystem.App.ConnectMode.UI_Setup) then
		-- TODO: place your UI (menus,toolbars, tool buttons) through which the user will communicate to the app
		-- e.g. MainBar.AddItem(), MainMenu.AddItem().
		--获取人物焦点
		local commandName = "CameraControl.DoFindAvatar";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "", icon = "Texture/3DMapSystem/AppIcons/homepage_64.dds", });
		end
		--摄影机控制:界面显示
		local commandName = "CameraControl.ShowPage";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "", icon = "Texture/3DMapSystem/AppIcons/homepage_64.dds", });
		end
		--摄影机控制:开始
		local commandName = "CameraControl.DoPlay";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "", icon = "Texture/3DMapSystem/AppIcons/homepage_64.dds", });
		end
		--摄影机控制:暂停
		local commandName = "CameraControl.DoPause";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "", icon = "Texture/3DMapSystem/AppIcons/homepage_64.dds", });
		end
		--摄影机控制:继续
		local commandName = "CameraControl.DoResume";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "", icon = "Texture/3DMapSystem/AppIcons/homepage_64.dds", });
		end
		--摄影机控制:停止到最前
		local commandName = "CameraControl.DoStop";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "", icon = "Texture/3DMapSystem/AppIcons/homepage_64.dds", });
		end
		--摄影机控制:停止到最后
		local commandName = "CameraControl.DoEnd";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "", icon = "Texture/3DMapSystem/AppIcons/homepage_64.dds", });
		end
		--摄影机控制:快退
		local commandName = "CameraControl.DoPre";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "", icon = "Texture/3DMapSystem/AppIcons/homepage_64.dds", });
		end
		--摄影机控制:快进
		local commandName = "CameraControl.DoNext";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "", icon = "Texture/3DMapSystem/AppIcons/homepage_64.dds", });
		end
		local commandName = "Profile.MiniGames";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "", icon = "Texture/3DMapSystem/AppIcons/homepage_64.dds", });
		end
		--复制人物和 摄影机位置
		local commandName = "MiniGames.Get_AvatarCameraPos";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "", icon = "Texture/3DMapSystem/AppIcons/homepage_64.dds", });
		end

		--复制人物位置
		local commandName = "MiniGames.Get_AvatarPos";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "", icon = "Texture/3DMapSystem/AppIcons/homepage_64.dds", });
		end
		--复制人物位置 格式不同
		local commandName = "MiniGames.Get_AvatarPos2";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "", icon = "Texture/3DMapSystem/AppIcons/homepage_64.dds", });
		end
		--复制摄影机位置
		local commandName = "MiniGames.Get_CameraPos";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "", icon = "Texture/3DMapSystem/AppIcons/homepage_64.dds", });
		end
		
		--投掷水球
		local commandName = "MiniGames.Throw_ShuiQiu";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "", icon = "Texture/3DMapSystem/AppIcons/homepage_64.dds", });
		end
		--投掷果冻
		local commandName = "MiniGames.Throw_GuoDong";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "", icon = "Texture/3DMapSystem/AppIcons/homepage_64.dds", });
		end
		--投掷鞭炮
		local commandName = "MiniGames.Throw_BianPao";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "", icon = "Texture/3DMapSystem/AppIcons/homepage_64.dds", });
		end
		--投掷雪球
		local commandName = "MiniGames.Throw_SnowBall";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "", icon = "Texture/3DMapSystem/AppIcons/homepage_64.dds", });
		end
		--投掷糖豆豆
		local commandName = "MiniGames.Throw_CandyBall";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "", icon = "Texture/3DMapSystem/AppIcons/homepage_64.dds", });
		end
		
		--农场大作战
		local commandName = "MiniGames.FarmClip";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "", icon = "Texture/3DMapSystem/AppIcons/homepage_64.dds", });
		end
		--火龙怪大战
		local commandName = "MiniGames.FireMaster";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "", icon = "Texture/3DMapSystem/AppIcons/homepage_64.dds", });
		end
		--葱头菜头大战
		local commandName = "MiniGames.HitShrew";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "", icon = "Texture/3DMapSystem/AppIcons/homepage_64.dds", });
		end
		--穿云
		local commandName = "MiniGames.ChuanYun";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "", icon = "Texture/3DMapSystem/AppIcons/homepage_64.dds", });
		end
		--泡泡龙
		local commandName = "MiniGames.PaoPaoLong";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "", icon = "Texture/3DMapSystem/AppIcons/homepage_64.dds", });
		end
		--滚雪球
		local commandName = "MiniGames.SnowBall";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "", icon = "Texture/3DMapSystem/AppIcons/homepage_64.dds", });
		end
		--超级舞者
		local commandName = "MiniGames.SuperDancer";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "", icon = "Texture/3DMapSystem/AppIcons/homepage_64.dds", });
		end
		--雪山大挑战
		local commandName = "MiniGames.JumpFloor";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "", icon = "Texture/3DMapSystem/AppIcons/homepage_64.dds", });
		end
		--趣味表情祖玛
		local commandName = "MiniGames.Zuma";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "", icon = "Texture/3DMapSystem/AppIcons/homepage_64.dds", });
		end
		--眼里大比拼
		local commandName = "MiniGames.CrazySpots";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "", icon = "Texture/3DMapSystem/AppIcons/homepage_64.dds", });
		end
		--抽奖
		local commandName = "MiniGames.LuckyDial";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "", icon = "Texture/3DMapSystem/AppIcons/homepage_64.dds", });
		end
		--西瓜种子鉴定
		local commandName = "MiniGames.MelonSeedTest";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "", icon = "Texture/3DMapSystem/AppIcons/homepage_64.dds", });
		end
		--庄稼保卫战
		local commandName = "MiniGames.CropDefend";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "", icon = "Texture/3DMapSystem/AppIcons/homepage_64.dds", });
		end
		--美味蛋糕
		local commandName = "MiniGames.DeliciousCake";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "", icon = "Texture/3DMapSystem/AppIcons/homepage_64.dds", });
		end
		--萤火虫
		local commandName = "MiniGames.FireFly";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "", icon = "Texture/3DMapSystem/AppIcons/homepage_64.dds", });
		end
		--垃圾整理
		local commandName = "MiniGames.RecycleBin";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "", icon = "Texture/3DMapSystem/AppIcons/homepage_64.dds", });
		end
		--灌溉王
		local commandName = "MiniGames.Watering";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "", icon = "Texture/3DMapSystem/AppIcons/homepage_64.dds", });
		end
	else
		-- TODO: place the app's one time initialization code here.
		-- during one time init, its message handler may need to update the app structure with static integration points, 
		-- i.e. app.about, HomeButtonText, HomeButtonText, HasNavigation, NavigationButtonText, HasQuickAction, QuickActionText,  See app template for more information.
		
		-- e.g. 
		app.about =  "your short scription of the application here using the current language"
		app.icon =  "Texture/3DMapSystem/AppIcons/homepage_64.dds";
		Map3DSystem.App.MiniGames.app = app; -- keep a reference
		if(ParaEngine.GetLocale() == "zhCN") then
			app.HomeButtonText = "MiniGames in Chinese";
		else
			app.HomeButtonText = "MiniGames in English";
		end
	end
end

-- Receives notification that the Add-in is being unloaded.
function Map3DSystem.App.MiniGames.OnDisconnection(app, disconnectMode)
	if(disconnectMode == Map3DSystem.App.DisconnectMode.UserClosed or disconnectMode == Map3DSystem.App.DisconnectMode.WorldClosed)then
		-- TODO: remove all UI elements related to this application, since the IDE is still running. 
		
		-- e.g. remove command from mainbar
		local command = Map3DSystem.App.Commands.GetCommand("Profile.MiniGames");
		if(command == nil) then
			command:Delete();
		end
	end
	-- TODO: just release any resources at shutting down. 
end

-- This is called when the command's availability is updated
-- When the user clicks a command (menu or mainbar button), the QueryStatus event is fired. 
-- The QueryStatus event returns the current status of the specified named command, whether it is enabled, disabled, 
-- or hidden in the CommandStatus parameter, which is passed to the msg by reference (or returned in the event handler). 
-- @param commandName: The name of the command to determine state for. Usually in the string format "Category.SubCate.Name".
-- @param statusWanted: what status of the command is queried. it is of type Map3DSystem.App.CommandStatusWanted
-- @return: returns according to statusWanted. it may return an integer by adding values in Map3DSystem.App.CommandStatus.
function Map3DSystem.App.MiniGames.OnQueryStatus(app, commandName, statusWanted)
	if(statusWanted == Map3DSystem.App.CommandStatusWanted) then
		-- TODO: return an integer by adding values in Map3DSystem.App.CommandStatus.
		if(commandName == "Profile.MiniGames") then
			-- return enabled and supported 
			return (Map3DSystem.App.CommandStatus.Enabled + Map3DSystem.App.CommandStatus.Supported)
		end
	end
end

-- This is called when the command is invoked.The Exec is fired after the QueryStatus event is fired, assuming that the return to the statusOption parameter of QueryStatus is supported and enabled. 
-- This is the event where you place the actual code for handling the response to the user click on the command.
-- @param commandName: The name of the command to determine state for. Usually in the string format "Category.SubCate.Name".
function Map3DSystem.App.MiniGames.OnExec(app, commandName, params)
	NPL.load("(gl)script/kids/3DMapSystemUI/MiniGames/BeginGamePage.lua");
	NPL.load("(gl)script/apps/Aries/Inventory/Throwable.lua");

	NPL.load("(gl)script/ide/MotionEx/CameraMotions/CameraMotionPage.lua");
	local CameraMotionPage = commonlib.gettable("MotionEx.CameraMotionPage");
	--获取人物焦点
	if(commandName == "CameraControl.DoFindAvatar") then
		CameraMotionPage.DoFindAvatar();
	--摄影机控制:开始
	elseif(commandName == "CameraControl.ShowPage") then
		CameraMotionPage.ShowPage();
	--摄影机控制:开始
	elseif(commandName == "CameraControl.DoPlay") then
		CameraMotionPage.DoPlayFromFile();
	--摄影机控制:暂停
	elseif(commandName == "CameraControl.DoPause") then
		CameraMotionPage.DoPause();
	--摄影机控制:继续
	elseif(commandName == "CameraControl.DoResume") then
		CameraMotionPage.DoResume();
	--摄影机控制:停止到最前
	elseif(commandName == "CameraControl.DoStop") then
		CameraMotionPage.DoStop();
	--摄影机控制:停止到最后
	elseif(commandName == "CameraControl.DoEnd") then
		CameraMotionPage.DoEnd();
	--摄影机控制:快退
	elseif(commandName == "CameraControl.DoPre") then
		local t;
		if(params and params.t)then
			t = tonumber(params.t);
		end
		CameraMotionPage.DoPre(t);
	--摄影机控制:快进
	elseif(commandName == "CameraControl.DoNext") then
		local t;
		if(params and params.t)then
			t = tonumber(params.t);
		end
		CameraMotionPage.DoNext(t);
	--复制人物位置 和 摄影机位置
	elseif(commandName == "MiniGames.Get_AvatarCameraPos") then
		local player = ParaScene.GetPlayer();
		local x,y,z = player:GetPosition();

		--local x,y,z = ParaCamera.GetLookAtPos(); 
		local att = ParaCamera.GetAttributeObject();
		local CameraObjectDistance = att:GetField("CameraObjectDistance", 5);
		local CameraLiftupAngle = att:GetField("CameraLiftupAngle", 0.4);
		local CameraRotY = att:GetField("CameraRotY", 0);

		local pos = string.format("%.2f,%.2f,%.2f|%.2f,%.2f,%.2f",x,y,z,CameraObjectDistance,CameraLiftupAngle,CameraRotY);
		ParaMisc.CopyTextToClipboard(pos);
	--复制人物位置
	elseif(commandName == "MiniGames.Get_AvatarPos") then
		local player = ParaScene.GetPlayer();
		local x,y,z = player:GetPosition();
		local pos = string.format("{ %.2f, %.2f, %.2f, },",x,y,z);
		ParaMisc.CopyTextToClipboard(pos);
	--复制人物位置
	elseif(commandName == "MiniGames.Get_AvatarPos2") then
		local player = ParaScene.GetPlayer();
		local x,y,z = player:GetPosition();
		local pos = string.format("%.2f,%.2f,%.2f",x,y,z);
		ParaMisc.CopyTextToClipboard(pos);
	--复制摄影机位置
	elseif(commandName == "MiniGames.Get_CameraPos") then
		local x,y,z = ParaCamera.GetLookAtPos(); 
		local att = ParaCamera.GetAttributeObject();
		local CameraObjectDistance = att:GetField("CameraObjectDistance", 5);
		local CameraLiftupAngle = att:GetField("CameraLiftupAngle", 0.4);
		local CameraRotY = att:GetField("CameraRotY", 0);
		local pos = string.format("{ x = %f, y = %f, z = %f, CameraObjectDistance = %f, CameraLiftupAngle = %f, CameraRotY = %f, }",x,y,z,CameraObjectDistance,CameraLiftupAngle,CameraRotY);
		ParaMisc.CopyTextToClipboard(pos);
	--投掷水球
	elseif(commandName == "MiniGames.Throw_ShuiQiu") then
		MyCompany.Aries.Inventory.ThrowablePage.OpenedByCommand(1);
	--投掷果冻
	elseif(commandName == "MiniGames.Throw_GuoDong") then
		MyCompany.Aries.Inventory.ThrowablePage.OpenedByCommand(2);
	--投掷鞭炮
	elseif(commandName == "MiniGames.Throw_BianPao") then
		MyCompany.Aries.Inventory.ThrowablePage.OpenedByCommand(3);
	--投掷雪球
	elseif(commandName == "MiniGames.Throw_SnowBall") then
		MyCompany.Aries.Inventory.ThrowablePage.OpenedByCommand(4);
	--投掷糖豆豆
	elseif(commandName == "MiniGames.Throw_CandyBall") then
		MyCompany.Aries.Inventory.ThrowablePage.OpenedByCommand(5);
	--农场整理大挑战
	elseif(commandName == "MiniGames.FarmClip") then
		MiniGameCommon.ShowPageDialog("FarmClip")
	--火毛怪大战
	elseif(commandName == "MiniGames.FireMaster") then
		MiniGameCommon.ShowPage("FireMaster")
	--葱头菜头大战
	elseif(commandName == "MiniGames.HitShrew") then
		MiniGameCommon.ShowPageDialog("HitShrew")
	--穿云
	elseif(commandName == "MiniGames.ChuanYun") then
		MiniGameCommon.ShowPageDialog("ChuanYun")
	--泡泡龙
	elseif(commandName == "MiniGames.PaoPaoLong") then
		MiniGameCommon.ShowPageDialog("PaoPaoLong")
	--滚雪球
	elseif(commandName == "MiniGames.SnowBall") then
		MiniGameCommon.ShowPageDialog("SnowBall")
	--超级舞者
	elseif(commandName == "MiniGames.SuperDancer") then
		MiniGameCommon.ShowPageDialog("SuperDancer")
	--雪山大挑战
	elseif(commandName == "MiniGames.JumpFloor") then
		MiniGameCommon.ShowPageDialog("JumpFloor")
	--趣味表情祖玛
	elseif(commandName == "MiniGames.Zuma") then
		MiniGameCommon.ShowPageDialog("Zuma")
	--眼里大比拼
	elseif(commandName == "MiniGames.CrazySpots") then
		MiniGameCommon.ShowPageDialog("CrazySpots")
	--抽奖
	elseif(commandName == "MiniGames.LuckyDial") then
		MiniGameCommon.ShowPage("LuckyDial")
	--西瓜种子鉴定
	elseif(commandName == "MiniGames.MelonSeedTest") then
		MiniGameCommon.ShowPage("MelonSeedTest")
	--庄稼保卫战
	elseif(commandName == "MiniGames.CropDefend") then
		MiniGameCommon.ShowPageDialog("CropDefend")
	--美味蛋糕
	elseif(commandName == "MiniGames.DeliciousCake") then
		MiniGameCommon.ShowPageDialog("DeliciousCake")
	--萤火虫
	elseif(commandName == "MiniGames.FireFly") then
		MiniGameCommon.ShowPageDialog("FireFly")
	--垃圾整理
	elseif(commandName == "MiniGames.RecycleBin") then
		MiniGameCommon.ShowPageDialog("RecycleBin")
	--灌溉王
	elseif(commandName == "MiniGames.Watering") then
		MiniGameCommon.ShowPageDialog("Watering")
	end
end

-- Change and render the 3D world with mcml data that is usually retrieved from the current user's profile page for this application. 
function Map3DSystem.App.MiniGames.OnRenderBox(mcmlData)
end


-- called when the user wants to nagivate to the 3D world location relavent to this application
function Map3DSystem.App.MiniGames.Navigate()
end

-- called when user clicks to check out the homepage of this application. Homepage usually includes:
-- developer info, support, developer worlds information, app global news, app updates, all community user rating, active users, trade, currency transfer, etc. 
function Map3DSystem.App.MiniGames.GotoHomepage()
end

-- called when user clicks the quick action for this application. 
function Map3DSystem.App.MiniGames.DoQuickAction()
end

-------------------------------------------
-- client world database function helpers.
-------------------------------------------

------------------------------------------
-- all related messages
------------------------------------------
-----------------------------------------------------
-- APPS can be invoked in many ways: 
--	Through app Manager 
--	mainbar or menu command or buttons
--	Command Line 
--  3D World installed apps
-----------------------------------------------------
function Map3DSystem.App.MiniGames.MSGProc(window, msg)
	----------------------------------------------------
	-- application plug-in messages here
	----------------------------------------------------
	if(msg.type == Map3DSystem.App.MSGTYPE.APP_CONNECTION) then	
		-- Receives notification that the Add-in is being loaded.
		Map3DSystem.App.MiniGames.OnConnection(msg.app, msg.connectMode);
		
	elseif(msg.type == Map3DSystem.App.MSGTYPE.APP_DISCONNECTION) then	
		-- Receives notification that the Add-in is being unloaded.
		Map3DSystem.App.MiniGames.OnDisconnection(msg.app, msg.disconnectMode);

	elseif(msg.type == Map3DSystem.App.MSGTYPE.APP_QUERY_STATUS) then
		-- This is called when the command's availability is updated. 
		-- NOTE: this function returns a result. 
		msg.status = Map3DSystem.App.MiniGames.OnQueryStatus(msg.app, msg.commandName, msg.statusWanted);
		
	elseif(msg.type == Map3DSystem.App.MSGTYPE.APP_EXEC) then
		-- This is called when the command is invoked.
		Map3DSystem.App.MiniGames.OnExec(msg.app, msg.commandName, msg.params);
				
	elseif(msg.type == Map3DSystem.App.MSGTYPE.APP_RENDER_BOX) then	
		-- Change and render the 3D world with mcml data that is usually retrieved from the current user's profile page for this application. 
		Map3DSystem.App.MiniGames.OnRenderBox(msg.mcml);
		
	elseif(msg.type == Map3DSystem.App.MSGTYPE.APP_NAVIGATION) then
		-- Receives notification that the user wants to nagivate to the 3D world location relavent to this application
		Map3DSystem.App.MiniGames.Navigate();
	
	elseif(msg.type == Map3DSystem.App.MSGTYPE.APP_HOMEPAGE) then
		-- called when user clicks to check out the homepage of this application. 
		Map3DSystem.App.MiniGames.GotoHomepage();
	
	elseif(msg.type == Map3DSystem.App.MSGTYPE.APP_QUICK_ACTION) then
		-- called when user clicks the quick action for this application. 
		Map3DSystem.App.MiniGames.DoQuickAction();
	elseif(msg.type == Map3DSystem.App.MSGTYPE.APP_ACTIVATE_DESKTOP) then

		
	elseif(msg.type == Map3DSystem.App.MSGTYPE.APP_DEACTIVATE_DESKTOP) then

		
		
	elseif(msg.type == Map3DSystem.App.MSGTYPE.APP_WORLD_CLOSING) then
	
	----------------------------------------------------
	-- normal windows messages here
	----------------------------------------------------
	elseif(msg.type == CommonCtrl.os.MSGTYPE.WM_CLOSE) then
		
		
	elseif(msg.type == CommonCtrl.os.MSGTYPE.WM_SIZE) then
		
		
	elseif(msg.type == CommonCtrl.os.MSGTYPE.WM_HIDE) then
		
		
	elseif(msg.type == CommonCtrl.os.MSGTYPE.WM_SHOW) then
		
	end
end
--记录当前被激活的flash窗口的名称
function Map3DSystem.App.MiniGames.SetCurWindow(msg)
	Map3DSystem.App.MiniGames.CurFlashWindowMsg= msg;
end

function Map3DSystem.App.MiniGames.InvokeFlashGameWindow(bShow)
	local msg = Map3DSystem.App.MiniGames.CurFlashWindowMsg;
	if(msg and msg.left and msg.top)then
		local name = msg.name;
		if(name)then
			local _app = Map3DSystem.App.AppManager.GetApp(MyCompany.Aries.app.app_key);
			if(_app) then
				_app = _app._app;
				local _wnd = _app:FindWindow(name);
				if(_wnd)then
					if(bShow)then
						_wnd:Reposition(nil, nil,nil,nil,nil);
						--ParaEngine.GetAttributeObject():SetField("Enable3DRendering", false);
					else
						_wnd:Reposition(nil, nil,100,nil,nil);
						--ParaEngine.GetAttributeObject():SetField("Enable3DRendering", true);
					end
				end
			end
		end
	end
end
