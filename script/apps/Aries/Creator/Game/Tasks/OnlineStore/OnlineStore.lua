--[[
Title: OnlineStore
Author(s): LiXizhi
Date: 2019/8/13
Desc: online store at: https://keepwork.com/p/comp/system?port=8099

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/OnlineStore/OnlineStore.lua");
local OnlineStore = commonlib.gettable("MyCompany.Aries.Game.Tasks.OnlineStore");
local task = OnlineStore:new():Init();
task:Run();
-------------------------------------------------------
]]
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local OnlineStore = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.OnlineStore"));

local curInstance;
-- this is always a top level task. 
OnlineStore.is_top_level = true;

function OnlineStore:ctor()
end

function OnlineStore:Init()
	return self;
end

function OnlineStore.GetOnlineStoreUrl()
	return "https://keepwork.com/p/comp/system?port=8099";
end

local page;
function OnlineStore.InitPage(Page)
	page = Page;
end

-- get current instance
function OnlineStore.GetInstance()
	return curInstance;
end

function OnlineStore:RefreshPage()
	if(page) then
		page:Refresh(0.01);
	end
end

function OnlineStore:Run()
	if(curInstance) then
		-- always close the previous one
		curInstance:OnExit();
	end
	curInstance = self;
	self.finished = false;
	
	curInstance = self;
	self:ShowPage(true);
end

function OnlineStore:OnUnselect()
	if(not self.isExiting) then
		self:OnExit();
	end
end

function OnlineStore:OnExit()
	self.isExiting = true
	self:ClosePage();
	curInstance = nil;
	self.isExiting = nil;
end

function OnlineStore:ShowPage(bShow)
	do
		GameLogic.RunCommand(format("/open -name OnlineStore -title %s -width 1020 -height 680 -alignment _ct %s", L"在线元件库", OnlineStore.GetOnlineStoreUrl()));
		return
	end

	-- TODO:  use mcml window
	if(not page) then
		local width,height = 200, 330;
		local params = {
				url = "script/apps/Aries/Creator/Game/Tasks/OnlineStore/OnlineStore.html", 
				name = "OnlineStore.ShowPage", 
				isShowTitleBar = false,
				DestroyOnClose = true,
				bToggleShowHide=false, 
				style = CommonCtrl.WindowFrame.ContainerStyle,
				allowDrag = true,
				enable_esc_key = false,
				bShow = bShow,
				click_through = false, 
				zorder = 1,
				app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
				directPosition = true,
					align = "_fi",
					x = 10,
					y = 10,
					width = 10,
					height = 10,
			};
		System.App.Commands.Call("File.MCMLWindowFrame", params);
		if(params._page) then
			params._page.OnClose = function()
				page = nil;
			end
		end
	else
		if(bShow == false) then
			page:CloseWindow();
		else
			page:Refresh(0.1);
		end
	end
end

function OnlineStore:ClosePage()
	self:ShowPage(false);
end

function OnlineStore.OnClose()
	local self = OnlineStore.GetInstance();
	if(self) then
		self:OnExit()
	elseif(page) then
		page:CloseWindow();
	end
end
