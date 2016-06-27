--[[
Title: MainToolBar.html code-behind script
Author(s): LiXizhi
Company: ParaEnging
Date: 2010/1/24
Desc: This is the main file for Aries Creator project. It contains entry functions for creator mode. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/MainToolBar.lua");
MyCompany.Aries.Creator.MainToolBar.EnterEditMode();
MyCompany.Aries.Creator.MainToolBar.ExitEditMode();
-- MyCompany.Aries.Creator.MainToolBar.IsEditMode
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/MainSideBar.lua");
NPL.load("(gl)script/apps/Aries/Creator/ContextMenu.lua");
NPL.load("(gl)script/apps/Aries/Creator/ToolTipsPage.lua");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
NPL.load("(gl)script/apps/Aries/Creator/EventHandler_Mouse.lua");

local MainToolBar = commonlib.gettable("MyCompany.Aries.Creator.MainToolBar")
local MainSideBar = commonlib.gettable("MyCompany.Aries.Creator.MainSideBar")
local ContextMenu = commonlib.gettable("MyCompany.Aries.Creator.ContextMenu");
local ToolTipsPage = commonlib.gettable("MyCompany.Aries.Creator.ToolTipsPage")
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local EventHandler = commonlib.gettable("MyCompany.Aries.Creator.EventHandler")
local Pet = commonlib.gettable("MyCompany.Aries.Pet");

local page;

-- a mapping from sub page name to a param table {visible=boolean}
local sub_pages = {};

local isEnterEditMode = false;

-------------------------------------
-- creator mode entry functions
-- TODO: maybe move all entry functions to MainCreator.lua file. 
-------------------------------------

-- call this function toggle to edit mode and hook all game controllers.  
-- hide all sub pages and display the main toolbar at the bottom. 
function MainToolBar.EnterEditMode()
	commonlib.echo("MyCompany.Aries.Creator.MainToolBar.EnterEditMode")
	
	if(type(commonlib.getfield("Map3DSystem.App.HomeLand.HomeLandGateway.GoWorld")) == "function") then
		Map3DSystem.App.HomeLand.HomeLandGateway.GoWorld();
	end
	
	-- find a better way to change modified status. Currently, we will always mark as modified when switched to edit mode. 
	-- and mark unmodified when leaving. 
	WorldCommon.SetModified(true);
	
	MainToolBar.ReturnToEditMode(true);
	
	EventHandler.Hook();
	
	isEnterEditMode = true;

	local QuestTrackerPane = commonlib.gettable("MyCompany.Aries.Quest.QuestTrackerPane");
    if(QuestTrackerPane.Show) then
        QuestTrackerPane.Show(false)
    end
end

-- return to edit mode, this function is usually called by sub page onclose event. 
-- @param bHideGameUI: true to hide game UI if any
function MainToolBar.ReturnToEditMode(bHideGameUI)
	if(not System.options.mc) then
		MainToolBar.ShowSubPages(false);
		MainToolBar.ShowPage(true);
		ToolTipsPage.ShowPage("getting_started");
	
		if(bHideGameUI) then
			-- hide the dock and monthly paid area
			if(type(commonlib.getfield("MyCompany.Aries.Desktop.Dock.Show")) == "function") then
				MyCompany.Aries.Desktop.Dock.Show(false);
			end
			if(type(commonlib.getfield("MyCompany.Aries.Desktop.Dock.HideBBSChatWnd")) == "function") then
				MyCompany.Aries.Desktop.Dock.HideBBSChatWnd();
			end
			if(type(commonlib.getfield("MyCompany.Aries.Desktop.TargetArea.Show")) == "function") then
				MyCompany.Aries.Desktop.TargetArea.Show(false);
			end
			if(type(commonlib.getfield("MyCompany.Aries.Desktop.HPMyPlayerArea.Show")) == "function") then
				MyCompany.Aries.Desktop.HPMyPlayerArea.Show(false);
			end
			if(type(commonlib.getfield("MyCompany.Aries.Desktop.EXPArea.Show")) == "function") then
				MyCompany.Aries.Desktop.EXPArea.Show(false);
			end
		end	
	
		MainSideBar.ShowPage(true);
		ContextMenu.CancelOperation();
		MainToolBar.IsEditMode = true;
	
		Pet.EnterIndoorMode(System.User.nid);
	end
end

-- play mode with the normal dock window. 
function MainToolBar.ReturnToPlayMode()
	MainToolBar.CancelEditMode()
	
	if(not System.options.mc) then
		if(isEnterEditMode == true) then
			-- show the dock paid area
			if(type(commonlib.getfield("MyCompany.Aries.Desktop.Dock.Show")) == "function") then
				MyCompany.Aries.Desktop.Dock.Show(true);
			end
			if(type(commonlib.getfield("MyCompany.Aries.Desktop.TargetArea.Show")) == "function") then
				MyCompany.Aries.Desktop.TargetArea.Show(true);
			end
			if(type(commonlib.getfield("MyCompany.Aries.Desktop.HPMyPlayerArea.Show")) == "function") then
				MyCompany.Aries.Desktop.HPMyPlayerArea.Show(true);
			end
			if(type(commonlib.getfield("MyCompany.Aries.Desktop.EXPArea.Show")) == "function") then
				MyCompany.Aries.Desktop.EXPArea.Show(true);
			end
		end
	
		Pet.LeaveIndoorMode(System.User.nid);
	end
end

function MainToolBar.CancelEditMode()
	MainToolBar.ShowSubPages(false);
	MainToolBar.ShowPage(false);
	
	MainToolBar.IsEditMode = false;
	
	ContextMenu.CancelOperation();
	
	ToolTipsPage.ShowPage(nil);
	ToolTipsPage.ShowPage(nil);
end

-- Exit edit mode, unhook all game editing controllers
-- hide everything. 
function MainToolBar.ExitEditMode()
	MainToolBar.ReturnToPlayMode()
	--MainToolBar.CancelEditMode()
	--Pet.LeaveIndoorMode(System.User.nid);
	
	MainSideBar.ShowPage(false);
	EventHandler.UnHook();

end

-------------------------------------
-- private functions
-------------------------------------

-- @param bShow: true to show. 
function MainToolBar.ShowPage(bShow)
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/MainToolBar.html", 
			name = "MainToolBar.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = false,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			bShow = bShow,
			directPosition = true,
				align = "_ctb",
				x = 0,
				y = 0,
				width = 720,
				height = 77,
		});
	
	EventHandler.EnableObjectEdit(bShow);
end

-- init function. page script fresh is set to false.
function MainToolBar.OnInit()
	-- start timer
	page = document:GetPageCtrl();
end

-- show/hide all sub pages whose page_group is page_group
-- @param page_group: if nil, we will show/hide all pages. Otherwise, we will only show/hide the given page group.
function MainToolBar.ShowSubPages(bShow, page_group)
	local name, params;
	for name, params in pairs(sub_pages)  do
		if((not page_group or params.page_group == params.page_group)) then
			System.App.Commands.Call("File.MCMLWindowFrame", {url = params.url, name = params.name, bShow = bShow,});
		end
	end
end

-- get the sub page params. 
function MainToolBar.GetSubPageParams(name)
	local params = sub_pages[name];
	if(not params) then
		params = {name = name};
		sub_pages[name] = params;
	end	
	return params
end

-- hide the main page and display the sub page
-- @param params: this is the same set of params to be passed to "File.MCMLWindowFrame"
-- usually it is a table of {url, name, page_group, align, x, y, width, height}, where page_group is any value that we can group pages together 
-- so that they can be closed using MainToolBar.ShowSubPages(bShow, page_group);
function MainToolBar.ShowSubPage(params)
	local page_params = MainToolBar.GetSubPageParams(params.name);
	page_params.url = page_params.url or params.url;
	page_params.page_group = page_params.page_group or params.page_group;
	
	MainToolBar.ShowPage(false);
	MainSideBar.ShowPage(false);
	
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = params.url, 
			name = params.name, 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			directPosition = true,
				align = params.align,
				x = params.x,
				y = params.y,
				width = params.width,
				height = params.height,
		});
end


---------------------------
-- sub page event and page layout 
---------------------------
function MainToolBar.OnClickSkyBtn()
	MainToolBar.ShowSubPage({
		url = "script/apps/Aries/Creator/Env/SkyPage.html", 
		name = "Aries.Creator.Sky", 
		align = "_rt",
		x = -250,
		y = 110,
		width = 250,
		height = 480,
	})
	ToolTipsPage.ShowPage("sky_modify");
end

function MainToolBar.OnClickTerrainBtn()
	MainToolBar.ShowSubPage({
		url = "script/apps/Aries/Creator/Env/TerrainPage.html", 
		name = "Aries.Creator.Terrain", 
		align = "_rt",
		x = -250,
		y = 110,
		width = 250,
		height = 480,
	})
	ToolTipsPage.ShowPage("terra_paint");
end

function MainToolBar.OnClickOceanBtn()
	MainToolBar.ShowSubPage({
		url = "script/apps/Aries/Creator/Env/OceanPage.html", 
		name = "Aries.Creator.Ocean", 
		align = "_rt",
		x = -250,
		y = 110,
		width = 250,
		height = 480,
	})
	ToolTipsPage.ShowPage("ocean_modify");
end

-- creation: grass
function MainToolBar.OnClickGrassBtn()
	MainToolBar.ShowSubPage({
		url = "script/apps/Aries/Creator/Assets/BagTemplate.html?bagfile=temp/mybag/aries/grass.bag.xml", 
		name = "Aries.Creator.Bag", 
		align = "_rt",
		x = -250,
		y = 110,
		width = 250,
		height = 480,
	})
	ToolTipsPage.ShowPage("asset_create");
	EventHandler.EnableObjectEdit(true);
end

-- creation: building
function MainToolBar.OnClickBuildingBtn()
	MainToolBar.ShowSubPage({
		url = "script/apps/Aries/Creator/Assets/BagTemplate.html?bagfile=temp/mybag/aries/building.bag.xml", 
		name = "Aries.Creator.Bag", 
		align = "_rt",
		x = -250,
		y = 110,
		width = 250,
		height = 480,
	})
	ToolTipsPage.ShowPage("asset_create");
	EventHandler.EnableObjectEdit(true);
end

-- creation: deco
function MainToolBar.OnClickDecoBtn()
	MainToolBar.ShowSubPage({
		url = "script/apps/Aries/Creator/Assets/BagTemplate.html?bagfile=temp/mybag/aries/deco.bag.xml", 
		name = "Aries.Creator.Bag", 
		align = "_rt",
		x = -250,
		y = 110,
		width = 250,
		height = 480,
	})
	ToolTipsPage.ShowPage("asset_create");
	EventHandler.EnableObjectEdit(true);
end

-- creation: special and particles
function MainToolBar.OnClickSpecialBtn()
	MainToolBar.ShowSubPage({
		url = "script/apps/Aries/Creator/Assets/BagTemplate.html?bagfile=temp/mybag/aries/special.bag.xml", 
		name = "Aries.Creator.Bag", 
		align = "_rt",
		x = -250,
		y = 110,
		width = 250,
		height = 480,
	})
	ToolTipsPage.ShowPage("asset_create");
	EventHandler.EnableObjectEdit(true);
end

-- creation: furniture
function MainToolBar.OnClickFurnitureBtn()
	MainToolBar.ShowSubPage({
		url = "script/apps/Aries/Creator/Assets/BagTemplate.html?bagfile=temp/mybag/aries/furniture.bag.xml", 
		name = "Aries.Creator.Bag", 
		align = "_rt",
		x = -250,
		y = 110,
		width = 250,
		height = 480,
	})
	ToolTipsPage.ShowPage("asset_create");
	EventHandler.EnableObjectEdit(true);
end

-- creation: others
function MainToolBar.OnClickOthersBtn()
	MainToolBar.ShowSubPage({
		url = "script/apps/Aries/Creator/Assets/BagTemplate.html?bagfile=temp/mybag/aries/others.bag.xml", 
		name = "Aries.Creator.Bag", 
		align = "_rt",
		x = -250,
		y = 110,
		width = 250,
		height = 480,
	})
	ToolTipsPage.ShowPage("asset_create");
	EventHandler.EnableObjectEdit(true);
end

-- creation: character
function MainToolBar.OnClickCharacterBtn()
	MainToolBar.ShowSubPage({
		url = "script/apps/Aries/Creator/Assets/BagTemplate.html?bagfile=temp/mybag/aries/characters.bag.xml", 
		name = "Aries.Creator.Bag", 
		align = "_rt",
		x = -250,
		y = 110,
		width = 250,
		height = 480,
	})
	ToolTipsPage.ShowPage("role_edit");
	EventHandler.EnableObjectEdit(true);
end

-- creation: animal
function MainToolBar.OnClickAnimalBtn()
	MainToolBar.ShowSubPage({
		url = "script/apps/Aries/Creator/Assets/BagTemplate.html?bagfile=temp/mybag/aries/animals.bag.xml", 
		name = "Aries.Creator.Bag", 
		align = "_rt",
		x = -250,
		y = 110,
		width = 250,
		height = 480,
	})
	ToolTipsPage.ShowPage("role_edit");
	EventHandler.EnableObjectEdit(true);
end

function MainToolBar.OnClickScreenShot()	
	-- _guihelper.MessageBox("TODO: 1期： 管理用户的截图和上传官网； 2期 邮件发给好友以及其他产品的好友；3期 贺卡制作和邮件");
	
	NPL.load("(gl)script/apps/Aries/Creator/SharePhotosPage.lua");
	MyCompany.Aries.Creator.SharePhotosPage.TakeSnapshot()

	NPL.load("(gl)script/apps/Aries/Creator/SharePage.lua");
	MyCompany.Aries.Creator.SharePage.ShowPage()
end

function MainToolBar.OnClickEBook()
	_guihelper.MessageBox("TODO: 1期： 无； 2期： 活的书, 文文和图图； 3期：引入3D电影");
end

function MainToolBar.OnClickUpload()
	_guihelper.MessageBox("TODO: 1期： 上传图片到社区网站, 上传世界到客服； 2期：家族领地, 热门活动");
end