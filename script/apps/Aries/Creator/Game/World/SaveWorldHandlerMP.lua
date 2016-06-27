--[[
Title: SaveWorldHandlerMP
Author(s): LiXizhi
Date: 2014/6/30
Desc: user on client side when connected to a multiplayer server. 
This is actually a null World/Player handler, which does nothing. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/SaveWorldHandlerMP.lua");
local SaveWorldHandlerMP = commonlib.gettable("MyCompany.Aries.Game.SaveWorldHandlerMP")
local SaveWorldHandlerMP = SaveWorldHandlerMP:new();
-------------------------------------------------------
]]
local SaveWorldHandlerMP = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.SaveWorldHandlerMP"));

function SaveWorldHandlerMP:ctor()
end

function SaveWorldHandlerMP:GetPlayerSaveHandler()
	return self;
end

-- save world info to tag.xml under the world_path
function SaveWorldHandlerMP:SaveWorldInfo(world_info)
	return true;
end

-- load world info from tag.xml under the world_path
function SaveWorldHandlerMP:LoadWorldInfo()
	local world_info = WorldInfo:new();
	return world_info;
end

function SaveWorldHandlerMP:WritePlayerData(entity)
end

function SaveWorldHandlerMP:ReadPlayerData(entity)
end