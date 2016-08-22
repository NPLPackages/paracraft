--[[
Title: NetHandler
Author(s): LiXizhi
Date: 2014/6/25
Desc: base class for net message handler
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NetHandler.lua");
local NetHandler = commonlib.gettable("MyCompany.Aries.Game.Network.NetHandler");
-------------------------------------------------------
]]
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local NetHandler = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Network.NetHandler"));

local address_to_nids = {};
local last_nid = 100;

function NetHandler:ctor()
end

-- static function: create get nid from ip address
-- @return nid, is_new: where is_new is true if nid is just created for the ip
function NetHandler:CheckGetNidFromIPAddress(ip, port)
	local is_new = false;
	local address_key = (ip or "127.0.0.1")..(port or "8099");
	local nid = address_to_nids[address_key];
	if(not nid) then
		last_nid = last_nid + 1;
		nid = tostring(last_nid);
		address_to_nids[address_key] = nid;
		is_new = true;
	end
	local params = {host = tostring(ip), port = tostring(port), nid = nid};
	NPL.AddNPLRuntimeAddress(params);
	-- LOG.std(nil, "debug", "AddRuntimeAddress", params);
	return nid, is_new;
end

-- static function:
function NetHandler:RemoveNidByIPAddress(ip, port)
	local address_key = (ip or "127.0.0.1")..(port or "8099");
	local nid = address_to_nids[address_key];
	if nid then
		address_to_nids[address_key] = nil;
	end
end

function NetHandler:Init(worldclient, host, ip)
	return self;
end

-- virtual function: handle ordinary messages
function NetHandler:handleMsg(msg)
	
end
