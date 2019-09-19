--[[
Title: PacketMultiple
Author(s): LiXizhi
Date: 2019/9/17
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketMultiple.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketMultiple:new():Init();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local Packet_Types = commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet_Types");
local PacketMultiple = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketMultiple"));

function PacketMultiple:ctor()
end

function PacketMultiple:Init(packets)
	if(packets) then
		self.packets = packets;
		local ids = {};
		for i=1, #packets do
			ids[i] = packets[i].id;
		end
		self.ids = ids;
	end
	return self;
end

function PacketMultiple:WritePacket()
	local packets = self.packets;
	if(packets) then
		for i=1, #packets do
			packets[i] = packets[i]:WritePacket();
		end
	end
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketMultiple:ProcessPacket(net_handler)
	local packets = self.packets;
	if(packets) then
		local ids = self.ids;
		for i=1, #packets do
			local msg = packets[i];
			local id = ids[i];
			local packet = Packet_Types:GetNewPacket(id);
			if(packet) then
				packet:ReadPacket(msg);
				packet:ProcessPacket(net_handler);
			else
				net_handler:handleMsg(msg);
			end
		end
	end
end
