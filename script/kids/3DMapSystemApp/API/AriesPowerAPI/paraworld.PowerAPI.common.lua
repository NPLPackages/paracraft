--[[
Title: power api common
Author(s): WangTian
Date: 2010/8/23
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/AriesPowerAPI/paraworld.PowerAPI.common.lua");
-------------------------------------------------------
]]

-- create class
local common = commonlib.gettable("paraworld.PowerAPI.common");

paraworld.createPowerAPI("paraworld.PowerAPI.common.test", "Items.GetItemsInBag", 
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	msg.nid = tonumber(msg.nid or Map3DSystem.User.nid);
	msg.bag = tonumber(msg.bag);
	
	if(isLogInventoryTraffic) then
		LOG.std("", "debug","PowerAPI", "paraworld.PowerAPI.inventory.GetItemsInBag msg_in:");
		LOG.std("", "debug","PowerAPI", msg);
	end
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg, originalMsg)
	if(msg and msg.items and inputMsg and inputMsg.bag) then
		LOG.std("", "debug","PowerAPI", "paraworld.PowerAPI.inventory.GetItemsInBag: return ")
		LOG.std("", "debug","PowerAPI", msg);
	else
		LOG.std("", "debug","PowerAPI", "paraworld.PowerAPI.inventory.GetItemsInBag: unsupported message format");
		LOG.std("", "debug","PowerAPI", msg);
		LOG.std("", "debug","PowerAPI", inputMsg);
	end
end);


