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
	local generatorName = WorldCommon.GetWorldTag("world_generator");
	return (generatorName == "paraworld" or generatorName == "paraworldMini");
end

function ParaWorldMain:IsMiniWorld()
	local generatorName = WorldCommon.GetWorldTag("world_generator");
	return (generatorName == "paraworldMini");
end

function ParaWorldMain:OnWorldLoaded()
	if(self:IsCurrentParaWorld()) then
		self:ShowAllAreas()
	end

	if (self:IsMiniWorld()) then
		local ParaWorldUserInfo = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldUserInfo.lua");
		ParaWorldUserInfo.ShowInMiniWorld();
	end
end

function ParaWorldMain:OnWorldUnload()
	if(self:IsCurrentParaWorld()) then
		self:CloseAllAreas()
	end
end

function ParaWorldMain:ShowAllAreas()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldMinimapWnd.lua");
	local ParaWorldMinimapWnd = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaWorld.ParaWorldMinimapWnd");
	ParaWorldMinimapWnd:Show();

	local ParaWorldSites = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldSites.lua");
	ParaWorldSites.Reset();
end

function ParaWorldMain:CloseAllAreas()
	local ParaWorldMinimapWnd = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaWorld.ParaWorldMinimapWnd");
	ParaWorldMinimapWnd:Close();
end


ParaWorldMain:InitSingleton();