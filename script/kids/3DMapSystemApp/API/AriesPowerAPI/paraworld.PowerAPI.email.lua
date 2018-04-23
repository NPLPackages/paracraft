--[[
Title: power api payment
Author(s): YAN DONGODNG
Date: 2013/4/10
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/AriesPowerAPI/paraworld.PowerAPI.email.lua");
-------------------------------------------------------
]]

-- create class
local email = commonlib.gettable("paraworld.PowerAPI.email"); 

-- here is a sample of creating payment API
--[[
/// <summary>
/// 发送邮件（非传统意义上Email，指游戏内部的邮件）
/// 接收参数：
///		nid     0  系统发送
///		_nid	0  系统发送
///     tonid 接收人的NID
///     title 标题
///     content 内容
///     attaches 附件。guid,cnt|guid,cnt|guid,cnt|.....。guid==0:E币；guid==-1:P币
/// 返回值：
///     issuccess
///     [ errorcode ] 493:参数不正确 419:用户不存在 427:物品不足 426:太频繁 433:邮箱已满
/// </summary>
]]
paraworld.createPowerAPI("paraworld.PowerAPI.email.Send", "Email.Send",
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	
	LOG.std(nil, "debug","PowerAPI", "paraworld.PowerAPI.email.send msg_in:");
	LOG.std(nil, "debug","PowerAPI", msg);
	
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg, originalMsg)
	LOG.std(nil, "debug","PowerAPI", "paraworld.PowerAPI.email.send return")
	LOG.std(nil, "debug","PowerAPI", msg);
end);
