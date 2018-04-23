--[[
Title: Assets app for Paraworld
Author(s): LiXizhi
Date: 2008/1/31
Asset app allows users to upload and create photo and 3D model albums and share with friends. 
Users can also customize which photos or 3D models to be included in the mainbar:creation toolbar to be conviniently used to create or decorate its 3d world. 
Application developers can also publish its album on its application homepage for users of the application to be able to create stuffs using the assets. 
Desc: 
db registration insert script
INSERT INTO apps VALUES (NULL, 'Assets_GUID', 'Assets', '1.0.0', 'http://www.paraengine.com/apps/Assets_v1.zip', 'YourCompany', 'enUS', 'script/kids/3DMapSystemApp/Assets/IP.xml', '', 'script/kids/3DMapSystemApp/Assets/app_main.lua', 'Map3DSystem.App.Assets.MSGProc', 1);
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/Assets/app_main.lua");
------------------------------------------------------------
]]

-- requires

-- create class
commonlib.setfield("Map3DSystem.App.Assets", {});

-------------------------------------------
-- event handlers
-------------------------------------------

-- OnConnection method is the obvious point to place your UI (menus, mainbars, tool buttons) through which the user will communicate to the app. 
-- This method is also the place to put your validation code if you are licensing the add-in. You would normally do this before putting up the UI. 
-- If the user is not a valid user, you would not want to put the UI into the IDE.
-- @param app: the object representing the current application in the IDE. 
-- @param connectMode: type of Map3DSystem.App.ConnectMode. 
function Map3DSystem.App.Assets.OnConnection(app, connectMode)
	if(connectMode == Map3DSystem.App.ConnectMode.UI_Setup) then
		-- TODO: place your UI (menus,toolbars, tool buttons) through which the user will communicate to the app
		-- e.g. MainBar.AddItem(), MainMenu.AddItem().
		
		-- e.g. Create a Assets command link in the main menu 
		local commandName = "Profile.Assets";
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command == nil) then
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "相册 & 模型库", icon = "Texture/3DMapSystem/common/color_swatch.png", });
			-- add command to mainmenu control, using the same folder as commandName. But you can use any folder you like
			local pos_category = commandName;
			-- install before group2.
			command:AddControl("mainmenu", pos_category, Map3DSystem.UI.MainMenu.GetItemIndex("Profile.Group2"));
			
			-- TODO: local all packages in the local directory. we shall remove this
			NPL.load("(gl)script/kids/3DMapSystemApp/Assets/AssetManager.lua");
			Map3DSystem.App.Assets.LoadAllLocalPackages();
			local packages = Map3DSystem.App.Assets.AssetManager.Packages;
			local i, package;
			for i, package in ipairs(packages) do
				if(package.bDisplayInMainBar) then
					commandName = "Profile.Assets";
					
					local commandName = package.Category;
					local command = Map3DSystem.App.Commands.GetCommand(commandName);
					if(command == nil) then
						--
						-- build the items table for this package: 
						-- TODO: We can delay loading the item table until the command is executed.
						--
						NPL.load("(gl)script/kids/3DMapSystemData/DBAssets.lua");
						local itemTable = {};
						local k, asset;
						for k, asset in ipairs(package.assets) do
							Map3DSystem.DB.AddItem(itemTable, asset:ToItem());
						end
					
						--
						-- add the package as a group icon in the creator bar. 
						--
						command = Map3DSystem.App.Commands.AddNamedCommand({
								name = commandName, 
								app_key = app.app_key, 
								group = {
									-- use the last part in the commandName. e.g. if  commandName is "creator.Normal Model.NM_Trees", name is "NM_Trees"
									["name"] = string.gsub(commandName, "[^%.]*%.", ""),
									["rootpath"] = nil,
									["text"] = package.text,
									icon = package.icon,
									tooltip = package.tooltip,
									-- NOTE by Andy 2008/12/25: ID field is added indicating the itemindex,
									--		e.g. an item ID: 201003 suggests that the item is in group 201, and index 3
									--		this is useful in the aquarius quest system as a reward 
									--		currently this only a LOCAL reward that only the client and local quest server know the ID meaning
									--		extansible appication model files will not be included, the package is then with an ID nil
									--["ID"] = 201, 
									ID = package.ID,
								};
								-- the item table
								items = itemTable,
							});
						--	
						-- add command to creator category
						--
						local pos_category = commandName;
						-- add to back.
						command:AddControl("creator", pos_category);
					end
				end
			end
			
			commandName = "File.Open.Asset";
			command = Map3DSystem.App.Commands.AddNamedCommand(
				{name = commandName,app_key = app.app_key, ButtonText = "模型浏览器", icon = "Texture/3DMapSystem/AppIcons/assets_64.dds", });
			-- add command to mainmenu control, using the same folder as commandName. But you can use any folder you like
			local pos_category = commandName;
			-- install to menu
			command:AddControl("mainmenu", pos_category);
		end
			
	else
		-- TODO: place the app's one time initialization code here.
		-- during one time init, its message handler may need to update the app structure with static integration points, 
		-- i.e. app.about, HomeButtonText, HomeButtonText, HasNavigation, NavigationButtonText, HasQuickAction, QuickActionText,  See app template for more information.
		
		-- e.g. 
		app.about =  "your short scription of the application here using the current language"
		app.HideHomeButton = true;
		app.HomeButtonText = "相册 & 模型库";
		app.Title = "资源管理";
		app.icon = "Texture/3DMapSystem/AppIcons/assets_64.dds"
		--app.icon = "Texture/3DMapSystem/AppIcons/painter_64.dds"
		app.SubTitle = "美术资源创作工具";
				
		Map3DSystem.App.Assets.app = app; 
	end
end

-- Receives notification that the Add-in is being unloaded.
function Map3DSystem.App.Assets.OnDisconnection(app, disconnectMode)
	if(disconnectMode == Map3DSystem.App.DisconnectMode.UserClosed or disconnectMode == Map3DSystem.App.DisconnectMode.WorldClosed)then
		-- TODO: remove all UI elements related to this application, since the IDE is still running. 
		
		-- e.g. remove command from mainbar
		local command = Map3DSystem.App.Commands.GetCommand("Profile.Assets");
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
function Map3DSystem.App.Assets.OnQueryStatus(app, commandName, statusWanted)
	if(statusWanted == Map3DSystem.App.CommandStatusWanted) then
		-- TODO: return an integer by adding values in Map3DSystem.App.CommandStatus.
		if(commandName == "Profile.Assets" or commandName=="File.Open.Asset") then
			-- return enabled and supported 
			return (Map3DSystem.App.CommandStatus.Enabled + Map3DSystem.App.CommandStatus.Supported)
		end
	end
end

-- This is called when the command is invoked.The Exec is fired after the QueryStatus event is fired, assuming that the return to the statusOption parameter of QueryStatus is supported and enabled. 
-- This is the event where you place the actual code for handling the response to the user click on the command.
-- @param commandName: The name of the command to determine state for. Usually in the string format "Category.SubCate.Name".
function Map3DSystem.App.Assets.OnExec(app, commandName, params)
	if(commandName == "Profile.Assets") then
		-- TODO: actual code of processing the command goes here. 
		-- e.g.
		--_guihelper.MessageBox("TODO: 用户可以上传和使用图片相册、3D模型，并和朋友共享。用户可以将图片和3D模型有选择的加入到自己的创作工具栏中，在3D世界中使用。应用程序开发者也可以将资源发布到自己的应用程序首页，推荐给应用程序的用户。");
		NPL.load("(gl)script/kids/3DMapSystemApp/Assets/AssetManager.lua");
		Map3DSystem.App.Assets.ShowAssetManager(app._app)
	elseif(commandName == "File.Open.Asset") then
		-- open asset window. 
		Map3DSystem.App.Commands.Call("File.MCMLBrowser", {url="script/kids/3DMapSystemApp/Assets/ModelBrowserPage.html", name="AssetBrowser", width=800, height=560, title="模型浏览器"});
		
	elseif(app:IsHomepageCommand(commandName)) then
		Map3DSystem.App.Assets.GotoHomepage();
	elseif(app:IsNavigationCommand(commandName)) then
		Map3DSystem.App.Assets.Navigate();
	elseif(app:IsQuickActionCommand(commandName)) then	
		Map3DSystem.App.Assets.DoQuickAction();
	end
end

-- Change and render the 3D world with mcml data that is usually retrieved from the current user's profile page for this application. 
function Map3DSystem.App.Assets.OnRenderBox(mcmlData)
end


-- called when the user wants to nagivate to the 3D world location relavent to this application
function Map3DSystem.App.Assets.Navigate()
end

-- called when user clicks to check out the homepage of this application. Homepage usually includes:
-- developer info, support, developer worlds information, app global news, app updates, all community user rating, active users, trade, currency transfer, etc. 
function Map3DSystem.App.Assets.GotoHomepage()
end

-- called when user clicks the quick action for this application. 
function Map3DSystem.App.Assets.DoQuickAction()
end

function Map3DSystem.App.Assets.OnActivateDesktop()
	Map3DSystem.UI.AppTaskBar.AddAppMenuItemsToToolBar(Map3DSystem.App.Assets.app.app_key);
	-- change desktop mode
	Map3DSystem.UI.AppDesktop.ChangeMode("edit")
end

function Map3DSystem.App.Assets.OnDeactivateDesktop()
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
function Map3DSystem.App.Assets.MSGProc(window, msg)
	----------------------------------------------------
	-- application plug-in messages here
	----------------------------------------------------
	if(msg.type == Map3DSystem.App.MSGTYPE.APP_CONNECTION) then	
		-- Receives notification that the Add-in is being loaded.
		Map3DSystem.App.Assets.OnConnection(msg.app, msg.connectMode);
		
	elseif(msg.type == Map3DSystem.App.MSGTYPE.APP_DISCONNECTION) then	
		-- Receives notification that the Add-in is being unloaded.
		Map3DSystem.App.Assets.OnDisconnection(msg.app, msg.disconnectMode);

	elseif(msg.type == Map3DSystem.App.MSGTYPE.APP_QUERY_STATUS) then
		-- This is called when the command's availability is updated. 
		-- NOTE: this function returns a result. 
		msg.status = Map3DSystem.App.Assets.OnQueryStatus(msg.app, msg.commandName, msg.statusWanted);
		
	elseif(msg.type == Map3DSystem.App.MSGTYPE.APP_EXEC) then
		-- This is called when the command is invoked.
		Map3DSystem.App.Assets.OnExec(msg.app, msg.commandName, msg.params);
				
	elseif(msg.type == Map3DSystem.App.MSGTYPE.APP_RENDER_BOX) then	
		-- Change and render the 3D world with mcml data that is usually retrieved from the current user's profile page for this application. 
		Map3DSystem.App.Assets.OnRenderBox(msg.mcml);
		
	elseif(msg.type == Map3DSystem.App.MSGTYPE.APP_NAVIGATION) then
		-- Receives notification that the user wants to nagivate to the 3D world location relavent to this application
		Map3DSystem.App.Assets.Navigate();
	
	elseif(msg.type == Map3DSystem.App.MSGTYPE.APP_HOMEPAGE) then
		-- called when user clicks to check out the homepage of this application. 
		Map3DSystem.App.Assets.GotoHomepage();
	
	elseif(msg.type == Map3DSystem.App.MSGTYPE.APP_QUICK_ACTION) then
		-- called when user clicks the quick action for this application. 
		Map3DSystem.App.Assets.DoQuickAction();
	
	elseif(msg.type == Map3DSystem.App.MSGTYPE.APP_ACTIVATE_DESKTOP) then
		Map3DSystem.App.Assets.OnActivateDesktop();
		
	elseif(msg.type == Map3DSystem.App.MSGTYPE.APP_DEACTIVATE_DESKTOP) then
		Map3DSystem.App.Assets.OnDeactivateDesktop();
		
	----------------------------------------------------
	-- normal windows messages here
	----------------------------------------------------
	elseif(msg.type == CommonCtrl.os.MSGTYPE.WM_CLOSE) then
		
		
	elseif(msg.type == CommonCtrl.os.MSGTYPE.WM_SIZE) then
		
		
	elseif(msg.type == CommonCtrl.os.MSGTYPE.WM_HIDE) then
		
		
	elseif(msg.type == CommonCtrl.os.MSGTYPE.WM_SHOW) then
		
	end
end