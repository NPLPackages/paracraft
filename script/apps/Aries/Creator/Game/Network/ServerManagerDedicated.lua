--[[
Title: ServerManagerDedicated
Author(s): LiXizhi
Date: 2014/6/25
Desc: pure server possibly running on linux. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ServerManagerDedicated.lua");
local ServerManagerDedicated = commonlib.gettable("MyCompany.Aries.Game.Network.ServerManagerDedicated");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ServerManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ServerListener.lua");
local ServerManager = commonlib.gettable("MyCompany.Aries.Game.Network.ServerManager");
local ServerListener = commonlib.gettable("MyCompany.Aries.Game.Network.ServerListener");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local ServerManagerDedicated = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.ServerManagerDedicated"), commonlib.gettable("MyCompany.Aries.Game.Network.ServerManager"));

function ServerManagerDedicated:ctor()
end