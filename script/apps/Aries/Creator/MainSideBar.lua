--[[
Title: MainSideBar.html code-behind script
Author(s): LiXizhi
Date: 2010/1/25
Desc: Create new world based on predefined template and open existing world. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/MainSideBar.lua");
MyCompany.Aries.Creator.MainSideBar.ShowPage(true);
-------------------------------------------------------
]]
local MainSideBar = commonlib.gettable("MyCompany.Aries.Creator.MainSideBar")
local MainToolBar = commonlib.gettable("MyCompany.Aries.Creator.MainToolBar")

local page;

-- @param bShow: true to show. 
function MainSideBar.ShowPage(bShow)
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/MainSideBar.html", 
			name = "MainSideBar.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = false,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			bShow = bShow,
			directPosition = true,
				align = "_rt",
				x = -64,
				y = 100,
				width = 64,
				height = 300,
		});
end

-- init function. page script fresh is set to false.
function MainSideBar.OnInit()
	-- start timer
	page = document:GetPageCtrl();
end

function MainSideBar.OnClickWorldManager()
	NPL.load("(gl)script/apps/Aries/Creator/CreateOpenWorld.lua");
	MyCompany.Aries.Creator.CreateOpenWorld.ShowPage();
end

function MainSideBar.OnClickWikiBook()
	_guihelper.MessageBox("TODO: 百科全书， 用户帮助手册以及购买各种物品和道具的地方")
end

-- toggle edit/play mode
function MainSideBar.OnClickEdit()
	if(not MainToolBar.IsEditMode) then
		MainToolBar.ReturnToEditMode(true);
	else
		MainToolBar.ReturnToPlayMode();
	end	
end

function MainSideBar.OnClickSave()
	NPL.load("(gl)script/apps/Aries/Creator/SaveWorldPage.lua");
	MyCompany.Aries.Creator.SaveWorldPage.ShowPage()
end

function MainSideBar.OnClickShare()
	NPL.load("(gl)script/apps/Aries/Creator/SharePage.lua");
	MyCompany.Aries.Creator.SharePage.ShowPage()
end

