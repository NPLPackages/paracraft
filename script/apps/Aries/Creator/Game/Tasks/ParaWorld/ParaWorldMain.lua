--[[
Title: ParaWorld Main Interface
Author(s): LiXizhi
Date: 2020/8/9
Desc:
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldMain.lua");
local ParaWorldMain = commonlib.gettable("Paracraft.Controls.ParaWorldMain");
ParaWorldMain:Init()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local ParaWorldMain = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("Paracraft.Controls.ParaWorldMain"));

ParaWorldMain:Property({"Size", 256});

function ParaWorldMain:ctor()
end

function ParaWorldMain:Init()
	if(not self.isInited) then
		self.isInited = true
	else
		return
	end
	GameLogic:Connect("WorldLoaded", ParaWorldMain, ParaWorldMain.OnWorldLoaded, "UniqueConnection");
	GameLogic:Connect("WorldUnloaded", ParaWorldMain, ParaWorldMain.OnWorldUnload, "UniqueConnection");
end

function ParaWorldMain:IsCurrentParaWorld()
	return (WorldCommon.GetWorldTag("world_generator") == "paraworld");
end

function ParaWorldMain:OnWorldLoaded()
	if(self:IsCurrentParaWorld()) then
		self:ShowAllAreas()
	end
end

function ParaWorldMain:OnWorldUnload()
	if(self:IsCurrentParaWorld()) then
		self:CloseAllAreas()
	end
end

function ParaWorldMain:ShowAllAreas()
	if(System.options.isAB_SDK)then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldMinimapWnd.lua");
		local ParaWorldMinimapWnd = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaWorld.ParaWorldMinimapWnd");
		ParaWorldMinimapWnd:Show();
	end
end

function ParaWorldMain:CloseAllAreas()
	if(System.options.isAB_SDK)then
		local ParaWorldMinimapWnd = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaWorld.ParaWorldMinimapWnd");
		ParaWorldMinimapWnd:Close();
	end
end


ParaWorldMain:InitSingleton();