--[[
Title: PacketClientCommand
Author(s): LiXizhi
Date: 2014/7/31
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketClientCommand.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketClientCommand:new():Init();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local PacketClientCommand = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketClientCommand"));

function PacketClientCommand:ctor()
end

function PacketClientCommand:Init(cmd)
	self.cmd = cmd;
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketClientCommand:ProcessPacket(net_handler)
	if(net_handler.handleClientCommand) then
		net_handler:handleClientCommand(self);
	end
end


