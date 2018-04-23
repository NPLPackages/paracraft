--[[
Title: power api userinfo
Author(s): WangTian
Date: 2010/8/23
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/AriesPowerAPI/paraworld.PowerAPI.users.lua");
-------------------------------------------------------
]]


-- create class
commonlib.setfield("paraworld.PowerAPI.users", {});

local isLogUsersTraffic = true;

--[[
        /// <summary>
        /// 获取指定用户的个人信息及其抱抱龙的信息
        /// 接收参数：
        ///     "nid" 
        ///   返回值：
        ///       user：返回的用户信息
        ///          nid
        ///          nickname  昵称
        ///          pmoney  P币
        ///          emoney  E币（奇豆）
        ///          birthday  生日（首次进入哈奇的时间）
        ///          popularity  人气值
        ///          family  所属家族的名称
        ///          introducer  推荐人的NID
        ///       [ dragon] : 返回的抱抱龙的信息，若该用户没有抱抱龙，则不会有此节点
        ///          petID 唯一标识
        ///          nickname 昵称
        ///          birthday 生日
        ///          level 级别
        ///          friendliness 亲密度
        ///          strong 体力值
        ///          cleanness 清洁值
        ///          mood 心情值
        ///          nextlevelfr 长级到下一级所需的亲密度
        ///          health 健康状态
        ///          kindness 爱心值
        ///          intelligence 智慧值
        ///          agility 敏捷值
        ///          strength 力量值
        ///          archskillpts  建筑熟练度
        ///          isadopted  是否寄养状态
        ///          combatexp  战斗经验值
        ///          combatlel  战斗等级
        ///          nextlevelexp  升级到下一个战斗等级所需的战斗经验值
        ///       [ errorCode ]：错误码，发生异常时有此节点
        /// </summary>
]] 
paraworld.createPowerAPI("paraworld.PowerAPI.users.GetUserAndDragonInfo", "Power_Users.GetUserAndDragonInfo", 
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	msg.nid = tonumber(msg.nid);
	
	if(not msg.nid) then
		LOG.std("", "error", "PowerAPI", "paraworld.PowerAPI.users.GetUserAndDragonInfo got nil nid");
		return true;
	end
	if(isLogUsersTraffic) then
		LOG.std("", "debug", "PowerAPI", "paraworld.PowerAPI.users.GetUserAndDragonInfo msg_in: "..commonlib.serialize_compact(msg));
	end
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg, originalMsg)
	if(isLogUsersTraffic) then
		LOG.std("", "debug", "PowerAPI", "paraworld.PowerAPI.users.GetUserAndDragonInfo msg_out: "..commonlib.serialize_compact(msg));
	end
end);

--[[
        /// <summary>
        /// 战斗结束后调用，以更新指定装备的耐久度
        /// </summary>
        /// 接收参数：
        ///     nid 战斗用户的NID
        ///     items 用户在战斗过程中身上的所有装备，多个GUID之间用|分隔
        ///     isdead [ number ]用户是否已经死了，0:未死；1:死了
        /// 返回值：
        ///     issuccess 是否成功
        ///     [ updates ] [list] 返回受影响的装备及其最终耐久度
        ///         guid  装备的GUID
        ///         dur  最终的耐久度，小于等于0表示数据已被删除
        ///     [ errorcode ]  493:参数不符合要求  500:发生了异常
]] 
paraworld.createPowerAPI("paraworld.PowerAPI.users.EndFight", "Power_Users.EndFight", 
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	msg.nid = tonumber(msg.nid);
	
	if(not msg.nid) then
		LOG.std("", "error", "PowerAPI", "paraworld.PowerAPI.users.EndFight got nil nid");
		return true;
	end
	if(isLogUsersTraffic) then
		LOG.std("", "debug", "PowerAPI", "paraworld.PowerAPI.users.EndFight msg_in: "..commonlib.serialize_compact(msg));
	end
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg, originalMsg)
	if(isLogUsersTraffic) then
		LOG.std("", "debug", "PowerAPI", "paraworld.PowerAPI.users.EndFight msg_out: "..commonlib.serialize_compact(msg));
	end
end);

-- delete a given user by nid
paraworld.createPowerAPI("paraworld.PowerAPI.users.delete", "Users.Delete", -- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	msg.nid = tonumber(msg.nid);
	
	if(not msg.nid) then
		LOG.std("", "error", "PowerAPI", "paraworld.PowerAPI.users.delete got nil nid");
		return true;
	end
	if(isLogUsersTraffic) then
		LOG.std("", "debug", "PowerAPI", "paraworld.PowerAPI.users.delete msg_in: "..commonlib.serialize_compact(msg));
	end
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg, originalMsg)
	if(isLogUsersTraffic) then
		LOG.std("", "debug", "PowerAPI", "paraworld.PowerAPI.users.delete msg_out: "..commonlib.serialize_compact(msg));
	end
end);


-- update user's ranking
paraworld.createPowerAPI("paraworld.PowerAPI.users.AddRank", "WorldServers.AddRank", -- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	msg.nid = tonumber(msg.nid);
	LOG.std(nil, "debug", "paraworld.PowerAPI.users.AddRank", msg);
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg, originalMsg)
	LOG.std(nil, "debug", "paraworld.PowerAPI.users.AddRank", msg);
end);

--[[
/// <summary>
/// 取得与指定平台的帐户所相关联的NID
/// 接收参数：
///     plat 平台ID，1:FB；2:QQ, 3:snsplus
///     oid 平台帐户
/// 返回值：
///     nid 多个NID之间用英文逗号分隔，若返回-1，表示该平台帐户未与任何NID关联
/// </summary>
]]
paraworld.createPowerAPI("paraworld.PowerAPI.users.GetNIDByOtherAccountID", "Users.GetNIDByOtherAccountID",
	function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
		LOG.std(nil, "debug", "GetNIDByOtherAccountID.begin", msg);
	end,
	function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg, originalMsg)
		LOG.std(nil, "debug", "GetNIDByOtherAccountID.end", msg);
	end
);