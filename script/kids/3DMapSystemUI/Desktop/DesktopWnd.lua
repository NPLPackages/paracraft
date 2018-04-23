--[[
Title: Desktop window for 3d map system
Author(s): WangTian, 
Date: 2008/1/23
Revised: 
   * 2008/1/28 exposed to external apps via Desktop.icons by LiXizhi. 
   * 2008.3.18 login page is now from a local MCML file. by LiXizhi.
   * 2008.6.17 mcml url icon is supported. LiXizhi. 
Desc:

---++ Add desktop icons
One can add commands icons to Startup, Online, Offline command groups. Each commands may contain a url or UICallback function. 
However, most desktop icons are advised to be mcml url only. 

*example*
<verbatim>
	Map3DSystem.UI.Desktop.AddDesktopItem({ButtonText="iconText", icon = "icon path", url="Some URL here"}, "Startup.Credits");
	Map3DSystem.UI.Desktop.AddDesktopItem({ButtonText="iconText", icon = "icon path", url="Some URL here"}, "Online.MyProfile");
	Map3DSystem.UI.Desktop.AddDesktopItem({ButtonText="iconText", icon = "icon path", url="Some URL here"}, "Offline.Tutorial");
</verbatim>

---++ Desktop Front page
goto a url page on the desktop front page. call below
<verbatim>
	Map3DSystem.UI.Desktop.GotoDesktopPage(url)
</verbatim>

change the desktop images
<verbatim>
	Map3DSystem.UI.Desktop.SetBackgroundImage(filename)
</verbatim>

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/Desktop/DesktopWnd.lua");
Map3DSystem.UI.Desktop.Show();
-- to add desktop icon that has a showUI callback at startup
Map3DSystem.UI.Desktop.AddDesktopItem({ButtonText="iconText", icon = "icon path", OnShowUICallback}, "Startup.Credits");
-- to add desktop icon that opens an url page.
Map3DSystem.UI.Desktop.AddDesktopItem({ButtonText="iconText", icon = "icon path", url}, "Startup.Credits");
-------------------------------------------------------
]]

-- common control library
NPL.load("(gl)script/kids/3DMapSystem_Data.lua");

local L = CommonCtrl.Locale("ParaWorld");

if(not Map3DSystem.UI.Desktop) then Map3DSystem.UI.Desktop = {}; end

local Desktop = Map3DSystem.UI.Desktop;

Desktop.LoginBarMCML = "script/kids/3DMapSystemUI/Desktop/LoginPage.html"
Desktop.NewAccountUrl = "http://www.minixyz.com/cn_01/register.aspx";

-- Themes and Images
Desktop.DesktopBG = "Texture/3DMapSystem/Desktop/BG.png";--"Texture/3DMapSystem/Desktop/DesktopBG.png";
Desktop.HeaderBG = ""; --"Texture/3DMapSystem/Desktop/TopFrameBG.png: 10 200 10 0"
Desktop.ParaWorldLogo = "Texture/3DMapSystem/brand/paraworld_text_256X128.png"; -- "Texture/3DMapSystem/Desktop/Logo_cn.png; 0 0 192 192"; -- TODO: locale
--Desktop.ParaWorldLogo128 = "Texture/3DMapSystem/Desktop/Logo_cn_128.png"; -- TODO: locale
Desktop.ParaWorldSlogen = ""; -- "Texture/3DMapSystem/Desktop/ParaEngineTenet.png"
Desktop.StartupBarBG = ""; -- "Texture/3DMapSystem/Desktop/StartupBarBG.png";
Desktop.LoginBarBG = ""; -- "Texture/3DMapSystem/Desktop/LoginBarBG.png";
--Desktop.LoginButton_Norm = "Texture/3DMapSystem/Desktop/LoginButton_Norm.png: 15 15 15 15";
--Desktop.LoginButton_HL = "Texture/3DMapSystem/Desktop/LoginButton_HL.png: 15 15 15 15";
Desktop.LoginButton_Norm = "Texture/3DMapSystem/Desktop/LoginPageButton3.png: 15 15 15 16";
Desktop.LoginButton_HL = "Texture/3DMapSystem/Desktop/LoginPageButton_HL3.png: 15 15 15 16";

-- Fonts
Desktop.LoginBarFont = "System;12;norm";
--Desktop.LoginBarFontBold = "Verdana;12;bold";

Desktop.LastShowGridViewName = nil;
Desktop.LastShowGridRow = nil;
Desktop.LastShowGridColumn = nil;
Desktop.LastUrl = nil;
	
-- preinstalled desktop icons. other applications may add to this icon list at startup time. 
Desktop.icons = {
name = "Desktop",
text = "Desktop",
Nodes={
	{
		-- "Startup" contains panel or command icons that are shown at startup.
		name = "Startup",
		text = "Startup",
		-- child objects
		Nodes = {},
	},
	{
		-- "Online" contains icons that are only shown when user is signed in. 
		name = "Online",
		text = "Online",
		-- child objects
		Nodes = {},
	},
	{
		-- "Offline" contains icons that are only shown when user is signed in as offline.  
		name = "Offline",
		text = "Offline",
		-- child objects
		Nodes = {},
	},
}};

-- Edited LXZ 2008.1.28. Add a desk top command at given position. This function is usually called during an application's startup connection event (not UISetup)
-- @param command; type of Map3DSystem.App.Command, or a new table that contains {ButtonText="iconText", icon = "icon path", OnShowUICallback = nil or function (bShow, _parent,parentWindow) .. end}
-- @param position: this is a tree path string of folder names separated by dot. The desktop has a predefined folder structure, which is 
--  "Startup.anyname": "Startup" contains panel or command icons that are shown at startup.
--  "Online.anyname": "Online" contains icons that are only shown when user is signed in. 
--  "Offline.anyname", "Offline" contains icons that are only shown when user is signed in as offline.  
-- @param posIndex: if position is a item in another folder, this is the index at which to add the item. if nil, it is added to end, if 1 it is the beginning. 
function Desktop.AddDesktopItem(command, position, posIndex)
	-- get the first occurance of first level child node whose name is name
	local function GetChildByName(parent, name)
		if(parent~=nil and parent.Nodes~=nil) then
			local nSize = table.getn(parent.Nodes);
			local i, node;
			for i=1, nSize do
				node = parent.Nodes[i];
				if(node~=nil and name == node.name) then
					return node;
				end
			end
		end	
	end

	-- search from the root icon node. 
	local node = Desktop.icons;
	local nodeName;
	
	for nodeName in string.gfind(position, "([^%.]+)") do
		local subnode = GetChildByName(node, nodeName);	
		if(subnode == nil) then
			-- command is added to the back
			node.Nodes = node.Nodes or {};
			node.Nodes[table.getn(node.Nodes)+1] = {
				name = nodeName,
				text = command.ButtonText,
				-- posIndex to be converted to column in the grid
				column = posIndex,
				-- if icon is not provided, we will use an empty icon
				icon = command.icon or "Texture/3DMapSystem/Desktop/Startup/Empty.png",
				OnShowUICallback = command.OnShowUICallback,
				AppCommand = command,
			};
			break;
		else
			node = subnode;
		end
	end
end

-- return a desktop icon index by its position. This function is mosted called before AddDesktopItem to determine where to insert a new command. 
-- @param position: this is a tree path string of folder names separated by dot e.g. "Startup.anyname"
-- @return nil if not found, other the item index integer is returned. please note that the index may change when new items are added later on. 
function Desktop.GetItemIndex(position)
	-- TODO: get position gridcell.column for the position. 
	return nil; 
end

-- obsoleted: no longer used
function Desktop.AddStartupBarApplication(appTable)
	local ctl = CommonCtrl.GetControl("Desktop_Startup_GridView");
	NPL.load("(gl)script/ide/GridView.lua");
	local cell = CommonCtrl.GridCell:new{
		GridView = nil,
		name = appTable.name,
		text = appTable.text,
		icon = appTable.icon,
		OnShowUICallback = appTable.OnShowUICallback,
		};
	ctl:InsertCell(cell, "Right");
end

-- public: set the background image: 1020*700
-- @param filename: nil or a file path
function Desktop.SetBackgroundImage(filename)
	ParaUI.GetUIObject("Main_Desktop").background = filename or Desktop.DesktopBG
end

function Desktop.Show()
	local _this,_parent;
	
	NPL.load("(gl)script/ide/UIAnim/UIAnimManager.lua");
	local fileName = "script/UIAnimation/DesktopStartupGridView.lua.table";
	file = UIAnimManager.LoadUIAnimationFile(fileName);
	
	_this = ParaUI.GetUIObject("Main_Desktop");
	if(_this:IsValid() == false) then
		
		-- Main_Desktop
		local _desktop = ParaUI.CreateUIObject("container", "Main_Desktop", "_fi", 0, 0, 0, 0);
		_desktop.background = Desktop.DesktopBG;
		_desktop:AttachToRoot();
		
		-- NOTE: change the canvas below the top frame
		-- AppCanvas
		local _appCanvas = ParaUI.CreateUIObject("container", "AppCanvas", "_fi", 0, 100, 0, 90);
		_appCanvas.background = "";
		_desktop:AddChild(_appCanvas);
		
		-- TopFrame
		-- NOTE: this container is a parent container that set to each application desktop
		if(Desktop.HeaderBG~=nil and Desktop.HeaderBG~="") then
			local _top = ParaUI.CreateUIObject("container", "TopFrame", "_fi", 0, 0, 0, 180);
			_top.background = Desktop.HeaderBG;
			_logo.enabled = false;
			_desktop:AddChild(_top);
		end	
		
		-- logo
		if(Desktop.ParaWorldLogo~=nil and Desktop.ParaWorldLogo~="") then
			local _logo = ParaUI.CreateUIObject("container", "Logo", "_lt", 10, 5, 200, 100);
			_logo.background = Desktop.ParaWorldLogo;
			_logo.enabled = false;
			_desktop:AddChild(_logo);
		end	
		
		-- slogen
		if(Desktop.ParaWorldSlogen~=nil and Desktop.ParaWorldSlogen~="") then
			local _tenet = ParaUI.CreateUIObject("container", "Tenet", "_rt", 0, 0, -1024, 64);
			_tenet.background = Desktop.ParaWorldSlogen;
			_tenet.enabled = false;
			_desktop:AddChild(_tenet);
		end	
		
		-- Startup
		local _startupBar = ParaUI.CreateUIObject("container", "StartupBar", "_rt", -460, 10, 440, 90);
		_startupBar.background = Desktop.StartupBarBG;
		_desktop:AddChild(_startupBar);
		
		Desktop.ShowStartup();
		
		
		
		-- Login
		local _login = ParaUI.CreateUIObject("container", "LoginBar", "_mb", 0, 0, 0, 90);
		_login.background = Desktop.LoginBarBG;
		_desktop:AddChild(_login);
	end
	
	Desktop.LastShowGridViewName = nil;
	Desktop.LastShowGridRow = nil;
	Desktop.LastShowGridColumn = nil;
	Desktop.LastUrl = nil;

	Desktop.ShowLogin();
	-- show the startup panel
	Desktop.ShowStartupPanel(true);
end

-- always show the first cell as the startup panel. 
-- @param bForceUpdate: if true, it will rebuilt the UI for the cell at row, column even it is the same as last click. 
function Desktop.ShowStartupPanel(bForceUpdate)
	Desktop.OnClickGridCell("Desktop_Startup_GridView", 1, 1, true, bForceUpdate);
	Desktop.LastShowGridViewName = "Desktop_Startup_GridView";
	Desktop.LastShowGridRow = 1;
	Desktop.LastShowGridColumn = 1;
end

-- the middle application canvas
function Desktop.GetAppCanvas()
	local _desktop = ParaUI.GetUIObject("Main_Desktop");
	return _desktop:GetChild("AppCanvas");
end

-- show the current app display and hide the last app display
-- if the same current and last app display, hide current
-- @param bShow: true or nil to show, false to hide, 
-- @param bForceUpdate: if true, it will rebuilt the UI for the cell at row, column even it is the same as last click. 
function Desktop.OnClickGridCell(gridviewName, row, column, bShow, bForceUpdate)
	local ctl;
	if(gridviewName == "Desktop_Startup_GridView") then
		ctl = CommonCtrl.GetControl("Desktop_Startup_GridView");
	elseif(gridviewName == "Desktop_Login_Online_GridView") then
		ctl = CommonCtrl.GetControl("Desktop_Login_Online_GridView");
	elseif(gridviewName == "Desktop_Login_Offline_GridView") then
		ctl = CommonCtrl.GetControl("Desktop_Login_Offline_GridView");
	end
	if(ctl ~= nil) then
		-- get the grid cell according to gridview name and row&column position
		local gridcell = ctl:GetCellByRowAndColumn(row, column);
		if(gridcell ~= nil) then
			
			--------- DEBUG PURPOSE ---------
			if(gridcell.name == "Empty") then
				return;
			end
			---------------------------------
			
			local lastGridviewName = Desktop.LastShowGridViewName;
			local lastRow = Desktop.LastShowGridRow;
			local lastColumn = Desktop.LastShowGridColumn;
			local lastUrl = Desktop.LastUrl;
			local url = nil;
			if(gridcell.OnShowUICallback == nil and gridcell.AppCommand) then
				url = gridcell.AppCommand.url
			end
			
			if(lastGridviewName == gridviewName	and lastRow == row and lastColumn == column) then
				-- User clicks the same node twice
				if(bShow == false) then
					-- hide app panel if any
					if(lastUrl) then
						NPL.load("(gl)script/kids/3DMapSystemApp/Login/ParaworldStartPage.lua");
						Map3DSystem.App.Login.ParaworldStartPage.Show(false, Desktop.GetAppCanvas())
					end
					if(gridcell.OnShowUICallback ~= nil) then
						gridcell.OnShowUICallback(false, Desktop.GetAppCanvas());
					end	
					gridcell.highlight = false;
					gridcell.GridView:Update();
				end
			else
				-- User clicks a different node: show the node and hide the last. 
				
				if(lastUrl and url) then
				else
					-- close the last page
					Desktop.OnClickGridCell(lastGridviewName, lastRow, lastColumn, false);
				end	
				
				bForceUpdate = true;
			end
			
			if(bForceUpdate) then	
				-- show current icon
				if(url) then
					if(lastUrl == nil) then
						-- show the url window if it is not shown before. 
						NPL.load("(gl)script/kids/3DMapSystemApp/Login/ParaworldStartPage.lua");
						Map3DSystem.App.Login.ParaworldStartPage.Show(true, Desktop.GetAppCanvas())
					end
					if(url~="") then
						Map3DSystem.App.Login.GotoPage(url)
					end	
				elseif(gridcell.OnShowUICallback ~= nil) then
					-- if this icon is a panel, show the panel. 
					gridcell.OnShowUICallback(true, Desktop.GetAppCanvas());
				elseif(gridcell.AppCommand~=nil) then
					-- if this is a command, call the command. 
					if(gridcell.AppCommand.Call~=nil) then
						gridcell.AppCommand:Call();
					end	
				end	
				Desktop.LastShowGridViewName = gridviewName;
				Desktop.LastShowGridRow = row;
				Desktop.LastShowGridColumn = column;	
				Desktop.LastUrl = url;
				gridcell.highlight = true;
				gridcell.GridView:Update();
			else
				if(url and lastUrl)	then
					Map3DSystem.App.Login.GotoPage(url)
				end
			end
		end
	end
end

function Desktop.OwnerDrawGridCellHandler(_parent, gridcell)
	if(_parent == nil or gridcell == nil) then
		return;
	end
	
	if(gridcell ~= nil) then
		if(gridcell.highlight == true) then
			local _this = ParaUI.CreateUIObject("container", gridcell.text.."_highlight", "_lt", 14, 4, 72, 72);
			_this.enable = false;
			-- disable the high light, the icon is of various shapes
			--_this.background = "Texture/3DMapSystem/Desktop/HighLight.png";
			_this.background = "";
			_parent:AddChild(_this);
		end
		
		local _this = ParaUI.CreateUIObject("button", gridcell.text.."_icon", "_lt", 18, 8, 64, 64);
		_this.background = gridcell.icon;
		_this.onclick = string.format(";Map3DSystem.UI.Desktop.OnClickGridCell(%q, %d, %d);", gridcell.GridView.name, gridcell.row, gridcell.column);
		_parent:AddChild(_this);
		
		_this = ParaUI.CreateUIObject("button", gridcell.text.."_text", "_lt", 0, 68, 100, 24);
		_this.onclick = string.format(";Map3DSystem.UI.Desktop.OnClickGridCell(%q, %d, %d);", gridcell.GridView.name, gridcell.row, gridcell.column);
		_this.text = gridcell.text;
		_this.background = "";
		_this.font = Desktop.LoginBarFont;
		if(gridcell.GridView.font_color) then
			_guihelper.SetFontColor(_this, gridcell.GridView.font_color)
			--_this:GetFont("text").color = "200 227 241";
		end	
		_parent:AddChild(_this);
		
	end
end

function Desktop.OnClickShiftLeft()
	local ctl = CommonCtrl.GetControl("Desktop_Startup_GridView");
	ctl:OnShiftLeftByCell();
end
		
function Desktop.OnClickShiftRight()
	local ctl = CommonCtrl.GetControl("Desktop_Startup_GridView");
	ctl:OnShiftRightByCell();
end

function Desktop.ShowStartup(bShow)
	local _desktop = ParaUI.GetUIObject("Main_Desktop");
	local _startupBar = _desktop:GetChild("StartupBar");
	local _startup = _startupBar:GetChild("Startup");
	
	if(_startup:IsValid() == false) then
		if(bShow == false) then
			return;
		end
		
		_startup = ParaUI.CreateUIObject("container", "Startup", "_fi", 0, 0, 0, 0);
		_startup.background = "";
		_startupBar:AddChild(_startup);
		
		-- TODO: need animation for the startup bar
		_pageleft = ParaUI.CreateUIObject("button", "PageLeft", "_lt", 0, 25, 32, 32);
		_pageleft.background = "Texture/3DMapSystem/common/PageLeft.png";
		_pageleft.onclick = ";Map3DSystem.UI.Desktop.OnClickShiftLeft();";
		_startupBar:AddChild(_pageleft);
		
		_pageright = ParaUI.CreateUIObject("button", "PageRight", "_rt", -27, 25, 32, 32);
		_pageright.background = "Texture/3DMapSystem/common/PageRight.png";
		_pageright.onclick = ";Map3DSystem.UI.Desktop.OnClickShiftRight();";
		_startupBar:AddChild(_pageright);
		
		-- show the application in IP in GridView
		
		NPL.load("(gl)script/ide/GridView.lua");
		
		local ctl = CommonCtrl.GetControl("Desktop_Startup_GridView");
		if(ctl==nil)then
			ctl = CommonCtrl.GridView:new{
				name = "Desktop_Startup_GridView",
				alignment = "_lt",
				container_bg = "",
				left = 15, top = 0,
				width = 400,
				height = 90,
				cellWidth = 100,
				cellHeight = 90,
				parent = _startup,
				columns = 7,
				rows = 1,
				DrawCellHandler = Desktop.OwnerDrawGridCellHandler,
			};
			
			-- insert all icons 
			local cell;
			local index, node;
			for index, node in ipairs(Desktop.icons.Nodes[1].Nodes) do
				-- fill default
				cell = CommonCtrl.GridCell:new(node);
				if(node.column == nil) then
					ctl:AppendCell(cell, "Right");
				else
					ctl:InsertCell(cell, "Right");
				end
			end
			
			---- TODO: test drag: remove this block. 
			--do
				--local i;
				--for i = 1, 7 do
					--cell = CommonCtrl.GridCell:new{
						--GridView = nil,
						--name = "Empty",
						--text = "Empty",
						--column = 10+i,
						--row = 1,
						--icon = "Texture/3DMapSystem/Desktop/Startup/Empty.png",
						--OnShowUICallback = nil,
						--};
					--ctl:InsertCell(cell, "Right");
				--end
			--end	
		else
			ctl.parent = _startup;
		end	
		
		ctl:Show();
	else
		if(bShow == nil) then
			_startup.visible = not _startup.visible;
		else
			_startup.visible = bShow;
		end
	end
end

function Desktop.ShowLogin()
	local _desktop = ParaUI.GetUIObject("Main_Desktop");
	local _loginBar = _desktop:GetChild("LoginBar");
	local _login = _loginBar:GetChild("Login");
	
	if(_login:IsValid() == false) then
		if(bShow == false) then
			return;
		end
		_login = ParaUI.CreateUIObject("container", "Login", "_fi", 0, 0, 0, 0);
		_login.background = "";
		_loginBar:AddChild(_login);
		--
		-- load from MCML page
		-- 
		NPL.load("(gl)script/kids/3DMapSystemApp/mcml/PageCtrl.lua");
		local MyPage = Map3DSystem.mcml.PageCtrl:new({url=Desktop.LoginBarMCML});
		MyPage:Create("Desktop.loginpage", _login, "_fi", 0, 0, 0, 0);
	else
		if(bShow == nil) then
			_login.visible = not _login.visible;
		else
			_login.visible = bShow;
		end
	end
	
	-- hide the offline and online container if valid
	local _offline = _loginBar:GetChild("Offline");
	local _online = _loginBar:GetChild("Online");
	if(_offline:IsValid()) then
		_offline.visible = false;
	end
	if(_online:IsValid()) then
		_online.visible = false;
	end
end

-- switch to login page. 
function Desktop.ShowOnline()
	local _desktop = ParaUI.GetUIObject("Main_Desktop");
	local _loginBar = _desktop:GetChild("LoginBar");
	local _online = _loginBar:GetChild("Online");
	
	if(_online:IsValid() == false) then
		if(bShow == false) then
			return;
		end
		
		-- Online container
		_online = ParaUI.CreateUIObject("container", "Online", "_fi", 0, 0, 0, 0);
		_online.background = "Texture/3DMapSystem/Desktop/LoginPageBottom.png: 15 55 15 8";
		_loginBar:AddChild(_online);
		
		--local _this = ParaUI.CreateUIObject("button", "b", "_mt", 0, 0, 0, 3);
		--_this.background = "Texture/3DMapSystem/Desktop/divider.png"
		--_this.enabled = false;
		--_online:AddChild(_this);
		--_guihelper.SetUIColor(_this, "255 255 255");
		
		local _welcome = ParaUI.CreateUIObject("text", "Welcome", "_lt", 20, 20, 200, 24);
		local name; 
		local profile = Map3DSystem.App.profiles.ProfileManager.GetProfile();
		if(profile) then
			name = profile:getFullName() or "";
		end	
		_welcome.text = string.format(L"欢迎 %s, 登录成功!", name or "");
		--_welcome:GetFont("text").color = "200 227 241";
		_welcome.font = Desktop.LoginBarFont;
		_online:AddChild(_welcome);
		
		local _back = ParaUI.CreateUIObject("button", "BackToLogin", "_lt", 20, 50, _guihelper.GetTextWidth(L"返回登陆页")+20, 33);
		_back.text = L"返回登陆页";
		_back.background = Desktop.LoginButton_HL;
		_back:GetFont("text").color = "4 55 89";
		_back.font = Desktop.LoginBarFont;
		_back.onclick = ";Map3DSystem.UI.Desktop.ShowLogin();";
		_online:AddChild(_back);
		
		
		NPL.load("(gl)script/ide/GridView.lua");
		
		local ctl = CommonCtrl.GetControl("Desktop_Login_Online_GridView");
		if(ctl==nil)then
			ctl = CommonCtrl.GridView:new{
				name = "Desktop_Login_Online_GridView",
				alignment = "_fi",
				container_bg = "",
				left = 280, top = 0,
				width = 20,
				height = 0,
				cellWidth = 100,
				cellHeight = 90,
				parent = _online,
				columns = 20,
				rows = 1,
				font_color = "#C8E3F1",
				DrawCellHandler = Desktop.OwnerDrawGridCellHandler,
			};
			
			local cell;
			local index, node;
			for index, node in ipairs(Desktop.icons.Nodes[2].Nodes) do
				-- fill default
				cell = CommonCtrl.GridCell:new(node);
				if(node.column == nil) then
					ctl:AppendCell(cell, "Right");
				else
					ctl:InsertCell(cell, "Right");
				end	
			end
		else
			ctl.parent = _online;
		end	
		
		
		ctl:Show();
	else
		if(bShow == nil) then
			_online.visible = not _online.visible;
		else
			_online.visible = bShow;
		end
	end
	
	-- hide the offline and login container if valid
	local _offline = _loginBar:GetChild("Offline");
	local _login = _loginBar:GetChild("Login");
	if(_offline:IsValid() == true) then
		_offline.visible = false;
	end
	if(_login:IsValid() == true) then
		_login.visible = false;
	end
	
	-- make sure that it switched to the first tab in online app.
	Desktop.OnClickGridCell("Desktop_Login_Online_GridView", 1, 1, true)
end

function Desktop.ShowOffline()

	local _desktop = ParaUI.GetUIObject("Main_Desktop");
	local _loginBar = _desktop:GetChild("LoginBar");
	local _offline = _loginBar:GetChild("Offline");
	
	if(_offline:IsValid() == false) then
		if(bShow == false) then
			return;
		end
		
		-- Offline container
		_offline = ParaUI.CreateUIObject("container", "Offline", "_fi", 0, 0, 0, 0);
		_offline.background = "Texture/3DMapSystem/Desktop/LoginPageBottom.png: 15 55 15 8";
		_loginBar:AddChild(_offline);
		
		--local _this = ParaUI.CreateUIObject("button", "b", "_mt", 0, 0, 0, 3);
		--_this.background = "Texture/3DMapSystem/Desktop/divider.png"
		--_this.enabled = false;
		--_offline:AddChild(_this);
		--_guihelper.SetUIColor(_this, "255 255 255");
		
		local _loginOffline = ParaUI.CreateUIObject("text", "LoginSucceed", "_lt", 20, 10, 250, 24);
		_loginOffline.text = L"正在以单机模式运行!";--"Currently running in Offline Mode!";
		--_loginOffline:GetFont("text").color = "200 227 241";
		_loginOffline.font = Desktop.LoginBarFont;
		_offline:AddChild(_loginOffline);
		local _back = ParaUI.CreateUIObject("button", "BackToLogin", "_lt", 20, 40, 150, 32);
		_back.text = L"返回登陆页";
		_back.background = Desktop.LoginButton_HL;
		_back:GetFont("text").color = "4 55 89";
		_back.font = Desktop.LoginBarFont;
		_back.onclick = ";Map3DSystem.UI.Desktop.ShowLogin();";
		_offline:AddChild(_back);
		
		
		NPL.load("(gl)script/ide/GridView.lua");
		
		local ctl = CommonCtrl.GetControl("Desktop_Login_Offline_GridView");
		if(ctl==nil)then
			ctl = CommonCtrl.GridView:new{
				name = "Desktop_Login_Offline_GridView",
				alignment = "_fi",
				container_bg = "",
				left = 280, top = 0,
				width = 20,
				height = 0,
				cellWidth = 100,
				cellHeight = 90,
				parent = _offline,
				columns = 20,
				rows = 1,
				font_color = "#C8E3F1",
				DrawCellHandler = Desktop.OwnerDrawGridCellHandler,
			};
			
			local cell;
			local index, node;
			for index, node in ipairs(Desktop.icons.Nodes[3].Nodes) do
				-- fill default
				cell = CommonCtrl.GridCell:new(node);
				if(node.column == nil) then
					ctl:AppendCell(cell, "Right");
				else
					ctl:InsertCell(cell, "Right");
				end	
			end
		else
			ctl.parent = _offline;
		end	
		
		ctl:Show();
	else
		if(bShow == nil) then
			_offline.visible = not _offline.visible;
		else
			_offline.visible = bShow;
		end
	end
	
	-- hide the online and login container if valid
	local _online = _loginBar:GetChild("Online");
	local _login = _loginBar:GetChild("Login");
	if(_online:IsValid() == true) then
		_online.visible = false;
	end
	if(_login:IsValid() == true) then
		_login.visible = false;
	end
	
	
	-- make sure that it switched to the first tab in online app.
	Desktop.OnClickGridCell("Desktop_Login_Offline_GridView", 1, 1, true)
end

-- Exit app button.
function Desktop.OnClickCallback_ExitApp()
	_guihelper.MessageBox(L"你确定要退出程序么?", Desktop.OnExitApp);
end
-- quick to windows
function Desktop.OnExitApp()
	ParaGlobal.ExitApp();
end

-- switch to in-game empty scene for testing. TODO: remove this. 
function Desktop.LoadEmptyScene()
	main_state="ingame";
end

-- switch to in-game demo scene for testing. TODO: remove this. 
function Desktop.LoadDemoScene()
	main_state="ingame2";
end

-- to offline mode. 
function Desktop.OnLoginOfflineMode()
	Desktop.ShowOffline()
	
end

-- click to create new account
function Desktop.OnClickNewAccount(ctrlName, values)
	-- switch to startup view
	Map3DSystem.App.Login.OnClickNewAccount();
end

-- Authenticate user and check client version. 
function Desktop.OnClickConnect(ctrlName, values)
	if(values.username == "" or values.password == "") then
		paraworld.ShowMessage(L"用户名和密码不能为空, 如果你尚未注册, 请点击新建用户按钮.")
		return;
	end	
		
	NPL.load("(gl)script/kids/3DMapSystemApp/Login/LoginProcedure.lua");
	paraworld.ShowMessage(L"正在验证用户身份, 请等待...", function()
		Desktop.OnClickConnect(ctrlName, values)
	end, _guihelper.MessageBoxButtons.RetryCancel)
	
	ParaEngine.ForceRender();
	
	--Map3DSystem.App.Login.Proc_Authentication(values, nil); -- do not switch at the moment. 
	Map3DSystem.App.Login.Proc_Authentication(values, Desktop.ShowOnline);
end

-- goto a url page on the desktop front page. 
-- @param url: url of the page
-- @param cachePolicy: nil or a cache policy. if nil, it defaults to 1 day.
function Desktop.GotoDesktopPage(url, cachepolicy)
	-- make sure that it switched to the first tab in online app.
	Desktop.OnClickGridCell("Desktop_Startup_GridView", 1, 1, true)
	-- go to page
	Map3DSystem.App.Login.GotoPage(url, cachepolicy)
end