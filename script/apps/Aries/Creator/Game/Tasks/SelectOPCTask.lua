--[[
Title: Select other player in the game mode. 
Author(s): LiXizhi
Date: 2013/8/15
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectOPCTask.lua");
local task = MyCompany.Aries.Game.Tasks.SelectOPC:new({nid=nid})
task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local SelectOPC = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectOPC"));

-- this is always a top level task. 
SelectOPC.is_top_level = true;

local cur_instance;

function SelectOPC:ctor()
end

function SelectOPC:Run()
	if(not TaskManager.AddTask(self)) then
		-- ignore the task if there is other top-level tasks.
		return;
	end
	cur_instance = self;

	SelectOPC.finished = false;

	SelectOPC.ShowPage();
end	

function SelectOPC:OnExit()
	SelectOPC.EndEditing();
end

-- @param bCommitChange: true to commit all changes made 
function SelectOPC.EndEditing()
	SelectOPC.finished = true;
	SelectOPC.ClosePage();
	
	if(cur_instance) then
		local self = cur_instance;
		cur_instance = nil;
	end
end

function SelectOPC.GetNid()
	if(cur_instance) then
		local self = cur_instance;
		return self.nid;
	end
end

function SelectOPC:FrameMove()
end
------------------------
-- page function 
------------------------
local page;
function SelectOPC.ShowPage()
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Tasks/SelectOPCTask.html", 
			name = "SelectOPCTask.ShowPage", 
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			isShowTitleBar = false,
			DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
			style = CommonCtrl.WindowFrame.ContainerStyle,
			zorder = 1,
			allowDrag = false,
			click_through = true,
			bShow = true,
			directPosition = true,
				align = "_lt",
				x = 0,
				y = 80,
				width = 128,
				height = 512,
		});
	MyCompany.Aries.Creator.ToolTipsPage.ShowPage(false);
end

function SelectOPC.ClosePage()
	if(page) then
		page:CloseWindow();
	end
end

function SelectOPC.OnInit()
	page = document:GetPageCtrl();
end

function SelectOPC.DoClick(name)
	local self = SelectOPC;
	local nid = SelectOPC.GetNid();

	if(name == "view_profile")then
		NPL.load("(gl)script/apps/Aries/NewProfile/NewProfileMain.lua");
		MyCompany.Aries.NewProfileMain.ShowPage(nid);
	elseif(name == "view_space")then	
		NPL.load("(gl)script/apps/Aries/Creator/Game/GameMarket/OtherPeopleWorlds.lua");
		local OtherPeopleWorlds = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.OtherPeopleWorlds");
		OtherPeopleWorlds.ShowPage(nid)
	end
end

function SelectOPC.do_view_profile()
	local self = cur_instance;
	if(self)then
		
	end
end
