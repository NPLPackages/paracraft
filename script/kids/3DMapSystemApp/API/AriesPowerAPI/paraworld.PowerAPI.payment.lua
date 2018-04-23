--[[
Title: power api payment
Author(s): LiXizhi
Date: 2010/9/8
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/AriesPowerAPI/paraworld.PowerAPI.payment.lua");
-------------------------------------------------------
]]

-- create class
local payment = commonlib.gettable("paraworld.PowerAPI.payment"); 

-- here is a sample of creating payment API
--paraworld.createPowerAPI("paraworld.PowerAPI.payment.test", "Items.GetItemsInBags", 
paraworld.createPowerAPI("paraworld.PowerAPI.payment.GetState", "Power_Items.GetState", 
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	
	LOG.std(nil, "debug","PowerAPI", "paraworld.PowerAPI.payment.GetState msg_in:");
	LOG.std(nil, "debug","PowerAPI", msg);
	
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg, originalMsg)
	LOG.std(nil, "debug","PowerAPI", "paraworld.PowerAPI.payment.GetState return")
	LOG.std(nil, "debug","PowerAPI", msg);
end);



paraworld.createPowerAPI("paraworld.PowerAPI.payment.Pay", "Power_Items.Pay", 
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	
	LOG.std(nil, "debug","PowerAPI", "paraworld.PowerAPI.payment.Pay msg_in:");
	LOG.std(nil, "debug","PowerAPI", msg);
	
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg, originalMsg)
	LOG.std(nil, "debug","PowerAPI", "paraworld.PowerAPI.payment.Pay return")
	LOG.std(nil, "debug","PowerAPI", msg);
end);

