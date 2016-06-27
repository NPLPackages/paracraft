--[[
Title: Create a model or character task
Author(s): LiXizhi
Date: 2013/1/20
Desc: Create a single model/character at the given position.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateModelTask.lua");
local task = MyCompany.Aries.Game.Tasks.CreateModel:new({obj_params})
task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Assets/AssetsCommon.lua");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");

local CreateModel = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.CreateModel"));

function CreateModel:ctor()
end

function CreateModel:Run()
	self.finished = true;

	local add_to_history;

	if(self.obj_params) then
		-- this is very tricky: we will ensure all model has a name that begin with "s_" (which does not save to script file like "g_"), so that we can delete by name. 
		-- otherwise successive undo/redo operation will not be possible. 
		if(not self.obj_params.IsCharacter) then
			self.obj_params.name = "s_"..ParaGlobal.GenerateUniqueID();
		end
		self.obj_params.obj_id = nil;
		MyCompany.Aries.Creator.AssetsCommon.OnCreateObject(self.obj_params)
		if(self.obj_params.obj_id) then
			add_to_history = true;
		end
	end
	
	if(add_to_history) then
		UndoManager.PushCommand(self);
	end
end

function CreateModel:Redo()
	if(self.obj_params) then
		if(self.obj_params) then
			self.obj_params.obj_id = nil;
			MyCompany.Aries.Creator.AssetsCommon.OnCreateObject(self.obj_params)
		end
	end
end

function CreateModel:Undo()
	local obj_params = self.obj_params
	if(obj_params and obj_params.obj_id) then
		local obj = ParaScene.GetObject(obj_params.obj_id)
		if(obj and obj:IsValid()) then
			MyCompany.Aries.Creator.AssetsCommon.DeleteObject({
				obj=obj,
				name = obj_params.name,  
				IsCharacter = obj_params.IsCharacter,
			})
		end
		obj_params.obj_id = nil;
	end
end