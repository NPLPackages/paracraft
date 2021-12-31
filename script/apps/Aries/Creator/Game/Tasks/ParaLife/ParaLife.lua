--[[
Title: Paralife main 
Author(s): LiXizhi
Date: 2021/12/31
Desc: ParaLife is a kids movie creator game. 
It can run directly inside a standard paracraft world with `/show paralife` command. 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLife.lua");
local ParaLife = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLife")
ParaLife:Init()
ParaLife:Show();
ParaLife:Hide();
-------------------------------------------------------
]]
local ParaLife = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLife"));

function ParaLife:ctor()
end

function ParaLife:Init()
	if(self.isInited) then
		return
	end
	self.isInited = true
end

function ParaLife:Show()
	self:Init()
	local ParalifeLiveModel = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParalifeLiveModel.lua");
    ParalifeLiveModel.ShowView()

	GameLogic.RunCommand("/show playertouch")
end

function ParaLife:Hide()
	local ParalifeLiveModel = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParalifeLiveModel.lua");
    ParalifeLiveModel.ClosePage()

	GameLogic.RunCommand("/hide playertouch")
end

ParaLife:InitSingleton()