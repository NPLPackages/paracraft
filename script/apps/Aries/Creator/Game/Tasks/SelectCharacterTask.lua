--[[
Title: Show a character talk dialog page in game mode
Author(s): LiXizhi
Date: 2013/1/26
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectCharacterTask.lua");
local task = MyCompany.Aries.Game.Tasks.SelectCharacter:new({obj=result.obj})
task:Run();
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
local ObjEditor = commonlib.gettable("ObjEditor");

local SelectCharacter = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectCharacter"));

-- this is always a top level task. 
SelectCharacter.is_top_level = true;

local cur_instance;

function SelectCharacter:ctor()
end

function SelectCharacter.RegisterHooks()
	local self = cur_instance;
	self.sceneContext = self.sceneContext or Game.SceneContext.RedirectContext:new():RedirectInput(self);
	self.sceneContext:activate();
end

function SelectCharacter.UnregisterHooks()
	local self = cur_instance;
	if(self) then
		self.sceneContext:close();
	end
end

function SelectCharacter:Run()
	if(self.obj and not TaskManager.AddTask(self)) then
		-- ignore the task if there is other top-level tasks.
		return;
	end

	cur_instance = self;

	self.obj_params = ObjEditor.GetObjectParams(self.obj);
	self.IsCharacter = self.obj_params.IsCharacter;
	self.obj_id = self.obj:GetID();

	if(self.IsCharacter) then
		self.obj_params.name = nil;
		self.obj_params.facing = nil;
	end
	
	SelectCharacter.finished = false;
	SelectCharacter.RegisterHooks();

	SelectCharacter.ShowPage();
end

function SelectCharacter:OnExit()
	SelectCharacter.EndEditing();
end

function SelectCharacter.GetObjParams()
	if(cur_instance) then
		return cur_instance.obj_params;
	end
end

function SelectCharacter.GetObj()
	if(cur_instance) then
		return cur_instance.obj;
	end
end

-- @param bCommitChange: true to commit all changes made 
function SelectCharacter.EndEditing(bCommitChange)
	SelectCharacter.finished = true;
	SelectCharacter.ClosePage()
	SelectCharacter.UnregisterHooks();
	if(cur_instance) then
		local self = cur_instance;
		cur_instance = nil
	end
end

function SelectCharacter:mousePressEvent(event)
end

function SelectCharacter:mouseMoveEvent(event)
end

function SelectCharacter:mouseReleaseEvent(event)
end

function SelectCharacter:keyPressEvent(event)
	local dik_key = event.keyname;
	if(dik_key == "DIK_ESCAPE")then
		-- exit editing mode without commit any changes. 
		SelectCharacter.EndEditing(false);
	else
		-- next word
		SelectCharacter.OnNextTalkText();
	end	
end

function SelectCharacter:FrameMove()
end

------------------------
-- page function 
------------------------
local page;
function SelectCharacter.ShowPage()
	SelectCharacter.talk_index = 1;
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Tasks/SelectCharacterTask.html", 
			name = "SelectCharacterTask.ShowPage", 
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

function SelectCharacter.GetContent()
    local obj = SelectCharacter.GetObj();
    if(obj) then
        return LocalNPC:GetNextTalkText(obj, SelectCharacter.talk_index);
    end
end

function SelectCharacter.OnNextTalkText()
	SelectCharacter.talk_index = SelectCharacter.talk_index + 1;
	if(not SelectCharacter.GetContent()) then
		SelectCharacter.EndEditing();
	elseif(page) then
		page:Refresh(0.01);
	end
end

function SelectCharacter.ClosePage()
	if(page) then
		page:CloseWindow();
	end
end

function SelectCharacter.OnInit()
	page = document:GetPageCtrl();
end


