--[[
Title: menu command
Author(s): LiXizhi
Date: 2014/11/14
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandMenu.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");

local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

Commands["menu"] = {
	name="menu", 
	quick_ref="/menu [menu_cmd_name]", 
	desc=[[menu commands
/menu file.settings
/menu file.openworlddir
/menu file.saveworld
/menu file.createworld
/menu file.loadworld
/menu file.worldrevision
/menu file.uploadworld
/menu file.export
/menu file.exit
/menu window.texturepack
/menu window.info
/menu window.pos
/menu online.server
/menu help.help
/menu help.help.shortcutkey
/menu help.help.tutorial.newusertutorial
/menu help.about
/menu help.npl_code_wiki
/menu help.actiontutorial
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local name, bIsShow;
		name, cmd_text = CmdParser.ParseString(cmd_text);
		if(not name) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/DesktopMenuPage.lua");
			local DesktopMenuPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.DesktopMenuPage");
			DesktopMenuPage.ActivateMenu(true);
			return;
		end
		LOG.std(nil, "debug", "menu", "menu command %s", name);

		if(name == "file.settings") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/SystemSettingsPage.lua");
			local SystemSettingsPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.SystemSettingsPage");
			SystemSettingsPage.ShowPage()
		elseif(name == "file.openworlddir") then
			if(not GameLogic.IsReadOnly() or GameLogic.IsRemoteWorld()) then
				Map3DSystem.App.Commands.Call("File.WinExplorer", ParaWorld.GetWorldDirectory());
			else
				Map3DSystem.App.Commands.Call("File.WinExplorer", ParaWorld.GetWorldDirectory():gsub("([^/\\]+)[/\\]?$",""));
			end
		elseif(name == "file.saveworld") then
			if(System.options.mc) then
				if(GameLogic.IsReadOnly()) then
					GameLogic.RunCommand("/menu file.saveworldas");
				else
					NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/SaveWorldPage.lua");
					local SaveWorldPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.Areas.SaveWorldPage");
					SaveWorldPage.ShowPage()
				end
			else
				NPL.load("(gl)script/apps/Aries/Creator/Game/GameMarket/SaveWorldPage.lua");
				local SaveWorldPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.SaveWorldPage");
				SaveWorldPage.ShowPage()
			end
		elseif(name == "file.saveworldas") then
			NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
			local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
			WorldCommon.SaveWorldAs()
		elseif(name == "file.createworld") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Login/CreateNewWorld.lua");
			local CreateNewWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.CreateNewWorld")
			CreateNewWorld.ShowPage()
		elseif(name == "file.loadworld") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Login/InternetLoadWorld.lua");
			local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld");
			InternetLoadWorld.ShowPage(true);
		elseif(name == "file.export") then
			GameLogic.RunCommand("export");
		elseif(name == "file.worldrevision") then
			if(not GameLogic.IsReadOnly()) then
				GameLogic.world_revision:Backup();
				GameLogic.world_revision:OnOpenRevisionDir();
			else
				_guihelper.MessageBox(L"世界是只读的，无需备份");
			end
		elseif(name == "file.openbackupfolder") then
			GameLogic.world_revision:OnOpenRevisionDir();
		elseif(name == "file.uploadworld") then
			if(System.options.mc) then
				NPL.load("(gl)script/apps/Aries/Creator/SaveWorldPage.lua");
				MyCompany.Aries.Creator.SaveWorldPage.ShowSharePage()
				--NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/SaveWorldPage.lua");
				--MyCompany.Aries.Creator.Game.Desktop.Areas.SaveWorldPage.ShowSharePage()
			else
				NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/EditorModeSwitchPage.lua");
				EditorModeSwitchPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.EditorModeSwitchPage");
				EditorModeSwitchPage.OnClickUpload();
			end
		elseif(name == "file.exit") then
			MyCompany.Aries.Creator.Game.Desktop.OnLeaveWorld(nil, true);
		elseif(name == "window.texturepack") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/TextureModPage.lua");
			local TextureModPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.TextureModPage");
			TextureModPage.ShowPage(true);
		elseif(name == "window.template") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/GoalTracker.lua");
			local GoalTracker = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.GoalTracker");
			GoalTracker.OnClickCody();
		elseif(name == "window.info") then
			CommandManager:RunCommand("/show info");
		elseif(name == "window.pos") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/TeleportListPage.lua");
			local TeleportListPage = commonlib.gettable("MyCompany.Aries.Game.GUI.TeleportListPage");
			TeleportListPage.ShowPage(nil, true);
		elseif(name == "window.find") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/FindBlockTask.lua");
			local FindBlockTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.FindBlockTask");
			local task = MyCompany.Aries.Game.Tasks.FindBlockTask:new()
			task:Run();
		elseif(name == "window.changeskin") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/SkinPage.lua");
			local SkinPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.SkinPage");
			SkinPage.ShowPage();
		elseif(name == "online.server") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ServerPage.lua");
			local ServerPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.ServerPage");
			ServerPage.ShowPage()
		elseif(name == "online.teacher_panel") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/TeacherPanel.lua");
			local TeacherPanel = commonlib.gettable("MyCompany.Aries.Game.Network.Admin.TeacherPanel");
			TeacherPanel.ShowPage()
		elseif(name:match("^help%.help")) then
			-- name can be "help.help", "help.help.tutorial", "help.help.shortcutkey"
			-- "help.help.tutorial.newusertutorial", "help.help.tutorial.MovieMaking", 
			-- "help.help.tutorial.circuit", "help.help.tutorial.programming"
			local category, subfolder;
			category = name:match("^help%.help%.(.+)$");
			if(category) then
				if(category:match("%.")) then
					category, subfolder = category:match("^([^%.]+)%.(.+)")
				end
			end
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/HelpPage.lua");
			local HelpPage = commonlib.gettable("MyCompany.Aries.Game.Tasks.HelpPage");
			HelpPage.ShowPage(category, subfolder);
		elseif(name == "help.actiontutorial") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Login/TeacherAgent/TeacherAgent.lua");
			local TeacherAgent = commonlib.gettable("MyCompany.Aries.Creator.Game.Teacher.TeacherAgent");
			TeacherAgent:SetEnabled(not TeacherAgent:IsEnabled())
		elseif(name == "help.userintroduction") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Login/UserIntroduction.lua");
			local UserIntroduction = commonlib.gettable("MyCompany.Aries.Game.MainLogin.UserIntroduction")
			UserIntroduction.ShowPage()
		elseif(name == "help.videotutorials") then
			GameLogic.RunCommand("/open "..L"https://keepwork.com/official/docs/videoguide");
		elseif(name == "help.learn") then
			GameLogic.RunCommand("/open "..L"https://keepwork.com/s");
		elseif(name == "help.ask") then
			GameLogic.RunCommand("/open "..L"https://keepwork.com/official/docs/FAQ/paracraft");
		elseif(name == "help.lessons") then
			GameLogic.RunCommand("/open "..L"https://keepwork.com/kecheng/cs/all");
		elseif(name == "help.npl_code_wiki") then
			-- open the npl code wiki site in external browser. 
			GameLogic.CommandManager:RunCommand("/open npl://");
		elseif(name == "help.about") then
			-- GameLogic.RunCommand("/open "..L"http://www.paracraft.cn/home/about-us");
			System.App.Commands.Call("File.MCMLWindowFrame", {
				url = "script/apps/Aries/Creator/Game/Login/AboutParacraft.html", 
				name = "aboutparacraft", 
				isShowTitleBar = false,
				DestroyOnClose = true,
				style = CommonCtrl.WindowFrame.ContainerStyle,
				zorder = 0,
				allowDrag = false,
				directPosition = true,
					align = "_ct",
					x = -600/2,
					y = -400/2,
					width = 600,
					height = 400,
				cancelShowAnimation = true,
			});
		elseif(name == "window.mall") then
			local KeepWorkMallPage = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/KeepWorkMallPage.lua");
			KeepWorkMallPage.Show();
		elseif(name == "window.userbag") then
            local UserBagPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/UserBagPage.lua");
            UserBagPage.ShowPage();
		elseif(name == "help.Credits") then
			GameLogic.RunCommand("/open "..L"https://keepwork.com/official/paracraft/credits");
		elseif(name == "help.ParacraftSDK") then
			GameLogic.RunCommand("/open https://github.com/LiXizhi/ParaCraftSDK/wiki");
		elseif(name == "help.bug") then
			GameLogic.RunCommand("/open https://github.com/LiXizhi/ParaCraft/issues");
		elseif(name == "help.donate") then
			GameLogic.RunCommand("/open "..L"http://www.nplproject.com/paracraft-donation");
		elseif(name:match("^community")) then
			local username = System.User.keepworkUsername
			if(username) then
				if(name == "community.myProfile") then
					GameLogic.RunCommand("/open "..format("https://keepwork.com/u/%s", username));
				elseif(name == "community.myProjects") then			
					GameLogic.RunCommand("/open "..format("https://keepwork.com/u/%s/project", username));
				end
			end
		end
	end,
};



