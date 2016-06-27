--[[
Title: WorldTrackerClient
Author(s): LiXizhi
Date: 2014/7/18
Desc: tracking major client world changes like block and entity changes and send those changes to servers. 
Only WorldClient in edit mode can enable this kind of world trackers
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/WorldTrackerClient.lua");
local WorldTrackerClient = commonlib.gettable("MyCompany.Aries.Game.World.WorldTrackerClient")
local WorldTrackerClient = WorldTrackerClient:new():Init(world);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/World/WorldTracker.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

---------------------------
-- create class
---------------------------
local WorldTrackerClient = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.World.WorldTracker"), commonlib.gettable("MyCompany.Aries.Game.World.WorldTrackerClient"))

function WorldTrackerClient:ctor()
end

function WorldTrackerClient:Init(worldObj)
	self.worldObj = worldObj;
	return self;
end

-- called when the client modified the block world at given position.
function WorldTrackerClient:MarkBlockForUpdate(x, y, z)
	if(not self:IsEnabled()) then
		return;
	end
	self.worldObj:GetPlayerManager():MarkBlockForUpdate(x,y,z);
end