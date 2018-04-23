--[[
Title: world servers related api
Author(s): LiXizhi
Date: 2009.10.15
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/paraworld.worlds.lua");
-------------------------------------------------------
]]
-- create class
commonlib.setfield("paraworld.WorldServers", {});

--[[
/// <summary>
/// 返回指定页的服务器列表
/// 接收参数：
///    pageIndex  int 第几页，以0开始的索引，默认值为0
///    pageSize int 每页的数据量，默认值为20
/// 返回值：
///    pagecnt int 共多少页
///    items [list]
///       id string 编号
///       name string 服务器名称
///       max int 最大可容纳的人数
///       cur int 当前容纳的人数
///       level int 当前级别
///       lastupdate datetime 最后更新时间
///    [ errorCode ]
/// </summary>
--]]
paraworld.create_wrapper("paraworld.WorldServers.Get", "%MAIN%/API/WorldServers/Get");

--[[
/// <summary>
/// 返回指定的一组服务器列表
/// 接收参数：
///       ids string 用英文逗号分隔的一组服务器编号
/// 返回值：
///     items [list]
///         id string 编号
///         name string 服务器名称
///         max int 最大可容纳的人数
///         cur int 当前容纳的人数
///         level int 当前级别
///     [ errorCode ]
/// </summary>
--]]
paraworld.create_wrapper("paraworld.WorldServers.GetByIDs", "%MAIN%/API/WorldServers/GetByIDs");

--[[
/// <summary>
/// 返回推荐的服务器列表。
/// 推荐规则由配置文件中的 LibraryCenter / WorldServers [ recommend ] 决定，
/// 目前配置的推荐规则为：随机选择2个4星服务器、3个3星服务器、3个2星服务器、3个1星服务器
/// 若某一级的服务器数量不足（即所有服务器中都无法找到足够数量的同级服务器），则用星级最接近的服务器补足数量
/// 接收参数：
///    无
/// 返回值：
///     items [list]
///         id string 编号
///         name string 服务器名称
///         max int 最大可容纳的人数
///         cur int 当前容纳的人数
///         level int 当前级别
///     [ errorCode ]
/// </summary>
--]]
paraworld.create_wrapper("paraworld.WorldServers.GetRecommend", "%MAIN%/API/WorldServers/GetRecommend");

--[[
/// <summary>
/// 依据显示的序号ID查找WorldServer
/// 接收参数：
///     vid  int 显示的序号ID
/// 返回值：
///     id  查找到的WorldServer的服务ID
///     [ errorcode ]
/// </summary>
--]]
paraworld.create_wrapper("paraworld.WorldServers.GetByVID", "%MAIN%/API/WorldServers/GetByVID");

--[[
/// <summary>
/// 依据WorldServer名称查找WorldServer
/// 接收参数：
///     name  string 要查找的WorldServer的名称
/// 返回值：
///     id  查找到的WorldServer的服务ID
///     [ errorcode ]
/// </summary>
--]]
paraworld.create_wrapper("paraworld.WorldServers.GetByName", "%MAIN%/API/WorldServers/GetByName");

--[[
/// <summary>
/// 取得服务器定义的数据
/// 接收参数：
///     keys  多个KEY之间用英文逗号分隔，若为String.Empty，则返回全部数据
/// 返回值：
///     list [list]
///         key
///         value
///     [ errorcode ]
/// </summary>
---+++ case 4
_case_: paraworld.worlds.Test_WorldWorlds_GetServerObject

Input:
<verbatim>
{["keys"]="weather,sky",}
</verbatim>

_Result_:
<verbatim>
	{ list={ { key="sky", value="daytime" }, { key="weather", value="snowing" } } }
</verbatim>
--]]
paraworld.create_wrapper("paraworld.WorldServers.GetServerObject", "%MAIN%/API/WorldServers/GetServerObject");

--[[
/// <summary>
/// 取得所有的可作为家族服务器使用的WorldServer
/// 接收参数：
///    无
/// 返回值：
///     items [list]
///         vid int 供显示的序号
///         id string 编号
///         name string 服务器名称
///         max int 最大可容纳的人数
///         cur int 当前容纳的人数
///         level int 当前级别
///         isfamily  int 是否是家族服务器。0：不是；1：是
///     [ errorCode ]
/// </summary>
--]]
local getallfamily_cache_policy = "access plus 30 minutes";
paraworld.create_wrapper("paraworld.WorldServers.GetAllFamily", "%MAIN%/API/WorldServers/GetAllFamily",
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	if(not paraworld.use_game_server) then
		msg.sessionkey = msg.sessionkey or Map3DSystem.User.sessionkey;
	end	
	msg.nid = tonumber(msg.nid or Map3DSystem.User.nid);
	
	-- cache policy
	local cache_policy = msg.cache_policy or getallfamily_cache_policy;
	if(type(cache_policy) == "string") then
		cache_policy = System.localserver.CachePolicy:new(cache_policy);
	end
	msg.cache_policy = nil;
	
	local ls = System.localserver.CreateStore(nil, 3);
	if(not ls) then
		return;
	end
	
	-- if local server has an unexpired result, return the result to callbackFunc, otherwise continue. 
	local HasResult;
	-- make url
	local url = self.GetUrl();
	local item = ls:GetItem(url)
	if(item and item.entry and item.payload) then
		if(not cache_policy:IsExpired(item.payload.creation_date)) then
			-- we found an unexpired result, return the result to callbackFunc
			HasResult = true;
			-- make output msg
			local output_msg = commonlib.LoadTableFromString(item.payload.data);
				
			LOG.std("", "debug", "API", "unexpired local version for : %s", url)
				
			if(callbackFunc) then
				callbackFunc(output_msg, callbackParams)
			end	
		end
	end
	if(HasResult) then
		-- don't require web API call
		return true;
	end	
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg, originalMsg)
	if(msg and not msg.errorcode) then
		local ls = System.localserver.CreateStore(nil, 3);
		if(ls) then
			-- make output msg
			local output_msg = msg;
			-- make url
			local url = self.GetUrl();
			-- make entry
			local item = {
				entry = System.localserver.WebCacheDB.EntryInfo:new({
					url = url,
				}),
				payload = System.localserver.WebCacheDB.PayloadInfo:new({
					status_code = System.localserver.HttpConstants.HTTP_OK,
					data = commonlib.serialize_compact(output_msg),
				}),
			}
			-- save to database entry
			local res = ls:PutItem(item);
			if(res) then 
				LOG.std("", "debug", "API", "family servers saved to local server");
			else	
				LOG.warn("failed get family server via url %s", tostring(url))
				LOG.warn(output_msg);
			end
		end -- if(ls) then
	else
		LOG.std("", "warn", "API", "paraworld.Family.Get: unsupported message format:")	
		LOG.std("", "warn", "API", msg);
	end
end);


--[[
-- update user's ranking. Only used on client side for testing purposes. 
-- disable this at release time. 
/// <summary>
/// 当前登录用户的某个需要排名的数值发生变化后的更新排名的API
/// 接收参数：
///     sessionkey
///     [ rid ]  统计排名的ID，1:1v1。如果不传此参数，则表示不是更新特定的积分数值，而是更新会影响所有排名的属性值
///     begindt 排行榜起始时间。number。yyyyMMdd
///     guid 记录此排行榜积分的物品的GUID
///     [ score ]  最终积分
///     [ score2 ] 
///     [ energy ] 能量值，如果该值没有发生变化，则不传
///     [ m ] 魔法星M值，如果该值没有发生变化，则不传
///     [ popularity ] 人气值，如果该值没有发生变化，则不传
///     tag 自定义标记
/// 返回值：
///     issuccess
///     [ minscore ] 该榜单上的最小分数
///     [ errorcode ] 493:更新的是score2 
/// </summary>
]]
paraworld.create_wrapper("paraworld.WorldServers.AddRank", "%MAIN%/API/WorldServers/AddRank", -- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	msg.nid = tonumber(msg.nid or Map3DSystem.User.nid);
	LOG.std(nil, "debug", "paraworld.WorldServers.AddRank", msg);
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg, originalMsg)
	LOG.std(nil, "debug", "paraworld.WorldServers.AddRank", msg);
end);

--[[
/// <summary>
/// 取得指定用户在指定排行榜的排名
/// 接收参数：
///     sessionkey
///     rid
/// 返回值：
///     index 排名，如果小于0，则表示该用户不在榜单上
///     min 该排行榜的最小分数
/// </summary>
]]
local getrankindex_cache_policy = "access plus 5 minutes";
paraworld.create_wrapper("paraworld.WorldServers.GetRankIndex", "%MAIN%/API/WorldServers/GetRankIndex", 
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	msg.nid = tonumber(msg.nid or Map3DSystem.User.nid);
	LOG.std(nil, "debug", "paraworld.WorldServers.GetRankIndex", msg);

	-- cache policy
	local cache_policy = msg.cache_policy or getrankindex_cache_policy;
	if(type(cache_policy) == "string") then
		cache_policy = System.localserver.CachePolicy:new(cache_policy);
	end
	msg.cache_policy = nil;
	
	local ls = System.localserver.CreateStore(nil, 3);
	if(not ls) then
		return;
	end
	
	-- if local server has an unexpired result, return the result to callbackFunc, otherwise continue. 
	local HasResult;
	-- make url
	local url = self.GetUrl();
	url = NPL.EncodeURLQuery(url, {"format", 1, "rid", msg.rid})
	local item = ls:GetItem(url)
	if(item and item.entry and item.payload) then
		if(not cache_policy:IsExpired(item.payload.creation_date)) then
			-- we found an unexpired result, return the result to callbackFunc
			HasResult = true;
			-- make output msg
			local output_msg = commonlib.LoadTableFromString(item.payload.data);
				
			LOG.std("", "debug", "API", "unexpired local version for : %s", url)
				
			if(callbackFunc) then
				callbackFunc(output_msg, callbackParams)
			end	
		end
	end
	if(HasResult) then
		-- don't require web API call
		return true;
	end	
end,
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg, originalMsg)
	LOG.std(nil, "debug", "paraworld.WorldServers.GetRankIndex", msg);

	if(msg and not msg.errorcode) then
		local ls = System.localserver.CreateStore(nil, 3);
		if(ls) then
			-- make output msg
			local output_msg = msg;
			-- make url
			local url = self.GetUrl();
			url = NPL.EncodeURLQuery(url, {"format", 1, "rid", inputMsg.rid})
			-- make entry
			local item = {
				entry = System.localserver.WebCacheDB.EntryInfo:new({
					url = url,
				}),
				payload = System.localserver.WebCacheDB.PayloadInfo:new({
					status_code = System.localserver.HttpConstants.HTTP_OK,
					data = commonlib.serialize_compact(output_msg),
				}),
			}
			-- save to database entry
			local res = ls:PutItem(item);
			if(res) then 
				LOG.std("", "debug", "API", "GetRankIndex saved to local store");
				LOG.std("", "debug", "GetRankIndex", msg);
			else	
				LOG.warn("failed GetRankList via url %s", tostring(url))
				LOG.warn(output_msg);
			end
		end -- if(ls) then
	else
		LOG.std("", "warn", "API", "GetRankIndex: unsupported message format:")	
		LOG.std("", "warn", "API", msg);
	end
end);

--[[
/// <summary>
/// 取得指定的排行榜列表（新）
/// 接收参数：
///     rid  1:1v1
///		pindex 
/// 返回值：
///     [] array
///         nid
///         score 积分
///         energy 能量值
///         m 魔法星M值
///         popularity 人气值
///         tag
/// </summary>
]]
local getranklist_cache_policy = "access plus 1 minutes";
paraworld.create_wrapper("paraworld.WorldServers.GetRankList", "%MAIN%/API/WorldServers/GetRankList", 
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	msg.nid = tonumber(msg.nid or Map3DSystem.User.nid);
	LOG.std(nil, "debug", "paraworld.WorldServers.GetRankList", msg);
	-- cache policy
	local cache_policy = msg.cache_policy or getranklist_cache_policy;
	if(type(cache_policy) == "string") then
		cache_policy = System.localserver.CachePolicy:new(cache_policy);
	end
	msg.cache_policy = nil;
	
	local ls = System.localserver.CreateStore(nil, 3);
	if(not ls) then
		return;
	end
	
	-- if local server has an unexpired result, return the result to callbackFunc, otherwise continue. 
	local HasResult;
	-- make url
	local url = self.GetUrl();
	url = NPL.EncodeURLQuery(url, {"format", 1, "rid", msg.rid, "pindex", msg.pindex})
	local item = ls:GetItem(url)
	if(item and item.entry and item.payload) then
		if(not cache_policy:IsExpired(item.payload.creation_date)) then
			-- we found an unexpired result, return the result to callbackFunc
			HasResult = true;
			-- make output msg
			local output_msg = commonlib.LoadTableFromString(item.payload.data);
				
			LOG.std("", "debug", "API", "unexpired local version for : %s", url)
				
			if(callbackFunc) then
				callbackFunc(output_msg, callbackParams)
			end	
		end
	end
	if(HasResult) then
		-- don't require web API call
		return true;
	end	
end,
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg, originalMsg)
	LOG.std(nil, "debug", "paraworld.WorldServers.GetRankList",{inputMsg, msg});

	if(msg and not msg.errorcode) then
		local ls = System.localserver.CreateStore(nil, 3);
		if(ls) then
			-- make output msg
			local output_msg = msg;
			-- make url
			local url = self.GetUrl();
			url = NPL.EncodeURLQuery(url, {"format", 1, "rid", inputMsg.rid, "pindex", inputMsg.pindex})
			-- make entry
			local item = {
				entry = System.localserver.WebCacheDB.EntryInfo:new({
					url = url,
				}),
				payload = System.localserver.WebCacheDB.PayloadInfo:new({
					status_code = System.localserver.HttpConstants.HTTP_OK,
					data = commonlib.serialize_compact(output_msg),
				}),
			}
			-- save to database entry
			local res = ls:PutItem(item);
			if(res) then 
				LOG.std("", "debug", "API", "GetRankList saved to local store %s", tostring(inputMsg.rid));
				LOG.std("", "debug", "GetRankList", msg);
			else	
				LOG.warn("failed GetRankList via url %s", tostring(url))
				LOG.warn(output_msg);
			end
		end -- if(ls) then
	else
		LOG.std("", "warn", "API", "GetRankList: unsupported message format:")	
		LOG.std("", "warn", "API", msg);
	end
end);

--[[
 /// 取得展示给当的所有充值送礼活动
 /// <summary>
        /// 
        /// 接收参数：
        ///     无
        /// 返回值：
        ///     single_rewards
        ///     sum_rewards
        ///     op_type
        ///     sex
		///		desc
        /// </summary>
--]]
paraworld.create_wrapper("paraworld.WorldServers.GetActRecharges", "%MAIN%/API/WorldServers/GetActRecharges",
	function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
		LOG.std(nil, "debug", "GetActRecharges", "begin binding");
	end,
	function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
		LOG.std(nil, "debug", "GetActRecharges", "end binding");
	end
);