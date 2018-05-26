--[[
Title: Auto saver
Author(s): LiXizhi
Date: 2017/8/16
Desc: mostly a singleton class. 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/AutoSaver.lua");
local AutoSaver = commonlib.gettable("MyCompany.Aries.Creator.Game.AutoSaver");

GameLogic.CreateGetAutoSaver():SetInterval(10)
GameLogic.CreateGetAutoSaver():SetSaveMode();
GameLogic.CreateGetAutoSaver():SetTipMode();
GameLogic.CreateGetAutoSaver():SetAutoSaveOperationCount(15);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");

local AutoSaver = commonlib.inherit(nil,commonlib.gettable("MyCompany.Aries.Creator.Game.AutoSaver"));
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

-- default to 10 mins
AutoSaver.interval = 10 * 60 * 1000;
AutoSaver.autosave_operation_count = 15;
AutoSaver.mode = "tip";
AutoSaver.operation_count = 0;

function AutoSaver:ctor()
	GameLogic:Connect("WorldLoaded", self, self.OnEnterWorld, "UniqueConnection");
	GameLogic:Connect("WorldUnloaded", self, self.OnLeaveWorld, "UniqueConnection");
	GameLogic:Connect("WorldSaved", self, self.ResetTimer, "UniqueConnection");
	self:SetTipMode();
end

-- @param intervalMins: number mins to do auto save. default to 10
function AutoSaver:SetInterval(intervalMins)
	if(intervalMins) then
		self.interval = intervalMins * 1000 * 60;
		self:ResetTimer();
	end
end

-- each user operation will increase the count by 1. 
-- When the operation count reach autosave_operation_count, we will automatically save. 
-- @param nCount: default to 1
function AutoSaver:IncreaseOperation(nCount)
	self.operation_count = self.operation_count + (nCount or 1);
	if(self.autosave_operation_count > 0 and self.operation_count > self.autosave_operation_count) then
		self.operation_count = 1;
		self:DoAutoSave();
	end
end

-- When the operation count reach autosave_operation_count, we will automatically save. 
function AutoSaver:SetAutoSaveOperationCount(nCount)
	self.autosave_operation_count = nCount;
end

-- default to tip mode, which will only show tips to user. 
-- If save mode, it will really save world to disk.
function AutoSaver:SetSaveMode()
	self.mode = "save";
	LOG.std(nil, "info", "AutoSaver", "save mode is on");
end

-- default to tip mode, which will only show tips to user. 
-- If save mode, it will really save world to disk.
function AutoSaver:SetTipMode()
	self.mode = "tip";
	LOG.std(nil, "info", "AutoSaver", "tip mode is on");
end

function AutoSaver:IsSaveMode()
	return self.mode == "save";
end

function AutoSaver:Init()
	self.timer = self.timer or commonlib.Timer:new({callbackFunc = function(timer)
		self:DoAutoSave();
	end})
	self:ResetTimer();
end

function AutoSaver:DoAutoSave()
	if(GameLogic.GameMode:IsEditor()) then
		if (self:IsSaveMode()) then
			-- save mode
			GameLogic.QuickSave();
		else
			-- tip mode
			if(not GameLogic.IsRemoteWorld() and not ParaMovie.IsRecording()) then
				if(System.options.IsMobilePlatform) then
					GameLogic.AddBBS("UndoManager", L"记得保存你的世界～", 5000, "0 255 0");
				else
					GameLogic.AddBBS("UndoManager", L"记得保存你的世界哦～(Ctrl+S)", 5000, "0 255 0");
				end
			end
		end
	end
end

function AutoSaver:OnEnterWorld()
	UndoManager:Connect("commandAdded", self, self.IncreaseOperation, "UniqueConnection");
	self:Init();
end

function AutoSaver:OnLeaveWorld()
	UndoManager:Disconnect("commandAdded", self, self.IncreaseOperation);

	if(self:IsSaveMode()) then
		-- TODO: shall we save on leave, currently this is done manually by external logics. 
	end
	self.timer:Change();
	-- always revert to tip mode, this is safer
	self:SetTipMode(); 
end

-- when the user manually saved the world, we should reset timer. 
function AutoSaver:ResetTimer()
	if (self.timer) then
		self.timer:Change(self.interval, self.interval);
	end
end
