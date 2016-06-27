--[[
Title: Movie and movie subscript task
Author(s): LiXizhi
Date: 2013/8/18
Desc: Play a moive file or simply some fullscreen movie subscript text. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MovieTask.lua");
local task = MyCompany.Aries.Game.Tasks.Movie:new({filename=filename})
task:Run();
local task = MyCompany.Aries.Game.Tasks.Movie:new({
	camera = {
		block_target = {bx,by,bz},
	},
	subscripts={
		{"Welcome to my world!", attr = {duration=15, } },
		{"this is a movie file!", attr = {duration=10,} },
	},
})
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Assets/AssetsCommon.lua");
NPL.load("(gl)script/ide/Display3D/SceneNode.lua");
NPL.load("(gl)script/ide/Display3D/SceneManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/AI/LocalNPC.lua");
local LocalNPC = commonlib.gettable("MyCompany.Aries.Creator.AI.LocalNPC")
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");

local Movie = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.Movie"));

-- this is always a top level task. 
Movie.is_top_level = true;

local cur_instance;

function Movie:ctor()
end

function Movie.RegisterHooks()
	local self = cur_instance;
	self.sceneContext = self.sceneContext or Game.SceneContext.RedirectContext:new():RedirectInput(self);
	self.sceneContext:activate();
end

function Movie.UnregisterHooks()
	local self = cur_instance;
	if(self) then
		self.sceneContext:close();
	end
end

function Movie:Run()
	if(not TaskManager.AddTask(self)) then
		-- ignore the task if there is other top-level tasks.
		return;
	end

	cur_instance = self;
	
	Movie.finished = false;
	Movie.RegisterHooks();

	Movie.ShowPage();

	return true;
end

function Movie:OnExit()
	Movie.EndEditing();
end

-- @param bCommitChange: true to commit all changes made 
function Movie.EndEditing(bCommitChange)
	Movie.finished = true;
	Movie.ClosePage()
	Movie.UnregisterHooks();
	if(cur_instance) then
		local self = cur_instance;
		cur_instance = nil
	end
end

function Movie:mousePressEvent(event)
end

function Movie:mouseMoveEvent(event)
end

function Movie:mouseReleaseEvent(event)
end

function Movie:keyPressEvent(event)
	local dik_key = event.keyname;

	if(dik_key == "DIK_ESCAPE")then
		-- exit editing mode without commit any changes. 
		Movie.EndEditing(false);
	else
		-- next word
		-- Movie.OnNextTalkText();
	end	
end

function Movie:FrameMove()
end

------------------------
-- page function 
------------------------
local page;
function Movie.ShowPage()
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Tasks/MovieTask.html", 
			name = "MovieTask.ShowPage", 
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			isShowTitleBar = false, 
			DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
			style = CommonCtrl.WindowFrame.ContainerStyle,
			zorder = 10,
			allowDrag = false,
			-- click_through = false,
			directPosition = true,
				align = "_fi",
				x = 0,
				y = 0,
				width = 0,
				height = 0,
			cancelShowAnimation = true,
		});
end


function Movie.ClosePage()
	if(page) then
		page:CloseWindow();
	end
end

function Movie.OnInit()
	page = document:GetPageCtrl();
end


