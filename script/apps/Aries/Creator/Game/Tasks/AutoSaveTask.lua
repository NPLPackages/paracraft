--[[
Title: AutoSave Task Command
Author(s): LiXizhi
Date: 2023/5/14
Desc: 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/AutoSaveTask.lua");
local task = MyCompany.Aries.Game.Tasks.AutoSave:new({mode = "apply_staged_changes"})
task:Run();
-------------------------------------------------------
]]
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local AutoSave = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.AutoSave"));

local curInstance;
local page;


function AutoSave:ctor()
end

function AutoSave.OnInit()
	page = document:GetPageCtrl();
	GameLogic:Connect("WorldUnloaded", AutoSave, AutoSave.CloseWindow, "UniqueConnection");
	GameLogic:Connect("beforeWorldSaved", AutoSave, AutoSave.CloseWindow, "UniqueConnection");
end

function AutoSave.CloseWindow()
	if(page) then
		page:CloseWindow()
	end
end

function AutoSave:ShowPage()
	curInstance = self;
	local allowDrag = true;
	if System.options.isEducatePlatform then
		allowDrag = false;
	end
	local params = {
		url = "script/apps/Aries/Creator/Game/Tasks/AutoSaveTask.html", 
		name = "AutoSaveTask.ShowPage", 
		isShowTitleBar = false,
		bShow = true,
		DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
		style = CommonCtrl.WindowFrame.ContainerStyle,
		zorder = -10,
		allowDrag = allowDrag,
		directPosition = true,
			align = "_mt",
			x = 0,
			y = 0,
			width = 0,
			height = 48,
	}
	if System.options.isEducatePlatform then
		params.url = "script/apps/Aries/Creator/Game/Educate/Project/AutoSaveTask.431.html";
		params.align = "_fi"
		params.height = 0
	end
	GameLogic.world_revision:SetStageLocked(true)
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	params._page.OnClose = function()
		page = nil;
		GameLogic.world_revision:SetStageLocked(false)
	end
end

-- @param bIsDataPrepared: true if data is prepared. if nil, we will prepare the data from input params.
function AutoSave:Run()
	if(self.mode == "apply_staged_changes") then
		self:ShowPage();
	end
end

function AutoSave:DoApplyStagedChanges()
	AutoSave.CloseWindow()
	GameLogic.world_revision:ApplyChangesFromFolder();
end

function AutoSave:DoNotApplyStagedChanges()
	AutoSave.CloseWindow()
	GameLogic.world_revision:DeleteStagedChangesInFolder()
end

