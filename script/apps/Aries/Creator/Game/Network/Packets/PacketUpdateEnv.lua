--[[
Title: PacketUpdateEnv
Author(s): LiXizhi
Date: 2014/6/29
Desc: update player name, or whether connected and ping speed
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketUpdateEnv.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketUpdateEnv:new():Init(reason);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
local PacketUpdateEnv = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketUpdateEnv"));

function PacketUpdateEnv:ctor()
end

-- @param texturePack: 
-- @param weather: 
function PacketUpdateEnv:Init(texturePack, weather, customBlocks)
	self.texturePack = texturePack;
	self.weather = weather;
	self.customBlocks = customBlocks;
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketUpdateEnv:ProcessPacket(net_handler)
	if(net_handler.handleUpdateEnv) then
		net_handler:handleUpdateEnv(self);
	end
end


