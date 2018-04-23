--[[
Title: auction service
Author(s): LiXizhi
Date: 2011/12/19
Desc: for GSL
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/ParaworldAPI.lua");
-------------------------------------------------------
]]

-- create class
commonlib.setfield("paraworld.auction", {});

--[[
/// 将指定的物品添加到商店出售
/// 接收参数：
///     sessionkey 当前登录用户
///     guid
///     expire 时限，如12表示12小时后过期
///     price 价格，魔豆
///     cnt 数量
///     showseller 是否公开卖家信息，0:否；1:是
/// 返回值：
///     issuccess
///     [ updates ]
///         guid
///         copies 最终值
///     [ svrdata ] 添加到商店的物品的ServerData数据
///     [ errorcode ] 493:参数错误；419:用户不存在；497:物品不存在；438:不可出售；411:E币不足；445:未验证安全密码
]] 
paraworld.create_wrapper("paraworld.auction.AppendToShop", "MAIN%/API/Items/AppendToShop.ashx",
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	LOG.std("", "debug","auction", "paraworld.auction.AppendToShop msg_in:");
	LOG.std("", "debug","auction", msg);
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
	LOG.std("", "debug","auction", "auction.AppendToShop");
	LOG.std("", "debug","auction", msg);
	if(msg.issuccess) then
		Map3DSystem.Item.ItemManager.UpdateBagItems(msg.updates, msg.adds);
	end
end);


--[[
/// <summary>
/// 从商店中购买
/// 接收参数：
///     sessionkey 当前登录用户
///     id 商品ID
/// 返回值：
///     issuccess
///     [ updates ]
///         guid
///         copies 最终值
///     [ errorcode ] 497:物品不存在；419:用户不存在；443:魔豆不足；
/// </summary>
]]
paraworld.create_wrapper("paraworld.auction.BuyFromShop", "MAIN%/API/Items/BuyFromShop.ashx", 
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	LOG.std("", "debug","auction", "paraworld.auction.BuyFromShop msg_in:");
	LOG.std("", "debug","auction", msg);
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
	LOG.std("", "debug","auction", "auction.BuyFromShop");
	LOG.std("", "debug","auction", msg);
	if(msg.issuccess) then
		Map3DSystem.Item.ItemManager.UpdateBagItems(msg.updates, msg.adds);
	end
end);


--[[
/// <summary>
/// 取消指定商品的出售
/// 接收参数：
///     sessionkey 当前登录用户
///     id 商品ID
/// 返回值：
///     issuccess
///     [ errorcode ] 497:物品不存在 438:无权限
/// </summary>
]]
paraworld.create_wrapper("paraworld.auction.CancelSell", "MAIN%/API/Items/CancelSell.ashx");


--[[
/// <summary>
/// 检查用户在商店中过期的物品，如果有，则做出售失败处理。
/// 用户登录后，每隔一段时间（如30分钟）调用一次此API
/// 接收参数：
///     sessionkey 当前登录用户
/// 返回值：
///     issuccess
/// </summary>
]]
paraworld.create_wrapper("paraworld.auction.CheckItemsInShop", "MAIN%/API/Items/CheckItemsInShop.ashx");


--[[
/// 取得用户在商店中在售的物品
/// 接收参数：
///     sessionkey
///     pindex 页码
///     psize 每页的数据量
/// 返回值：
///     [ list ]
///         id
///         gsid
///         name
///         price 出售价格
///         expire 过期时间，yyyy-MM-dd HH:mm:ss
///         cnt
///         svrdata
]]
paraworld.create_wrapper("paraworld.auction.GetInShopByMe", "MAIN%/API/Items/GetInShopByMe.ashx");



--[[
/// <summary>
/// 分页取得所有用户寄售在商店中的物品
/// 接收参数：
///     gsid: 
///     itemclass 物品所属的Class:itemclass 和gsid 2者需要传一个
///     [ subclass ] 物品所属的SubClass
///     [ school ] 系别
///     [ orders ] 排序方式。示例：0,1,-1,0,0 。逗号分隔的每一项分别表示：[0]:品质,[1]:等级,[2]:剩余时间,[3]:出售者,[4]:单价。值0 1 -1分别表示：不排序、升序、降序
///     pindex 页码
///     psize 每页的数据量，最大20
/// 返回值：
///     [ list ]
///         id 编号
///         gsid 物品GSID
///         name 物品名称
///         lel 物品等级
///         [ nid ] 售卖者的NID
///         [ nname ] 售卖者的昵称
///         price 价格
///         expire 过期时间
///         cnt
///         svrdata
///     [ errorcode ] 493:参数错误
/// </summary>
]]
paraworld.create_wrapper("paraworld.auction.GetInShop", "MAIN%/API/Items/GetInShop.ashx",
-- pre validation function and use default inputs
function(self, msg, id, callbackFunc, callbackParams, postMsgTranslator) 
	if(not paraworld.use_game_server) then
		msg.sessionkey = Map3DSystem.User.sessionkey;
	end	
	local cache_policy = msg.cache_policy or "access plus 5 seconds";
	if(type(cache_policy) == "string") then
		cache_policy = System.localserver.CachePolicy:new(cache_policy);
	end
	msg.cache_policy = nil;

	if(cache_policy == nil) then
		return;
	end
	
	local ls = System.localserver.CreateStore(nil, 3);
	if(not ls) then
		return 
	end

	-- make url
	local url = NPL.EncodeURLQuery(self.GetUrl(), {"gsid", msg.gsid, "pindex", msg.pindex, "psize", msg.psize})
	local item = ls:GetItem(url)
	if(item and item.entry and item.payload) then
		if(not cache_policy:IsExpired(item.payload.creation_date)) then
			-- make output msg
			if(item.payload.data) then
				local output_msg = commonlib.LoadTableFromString(item.payload.data);
				if(output_msg) then
					if(callbackFunc) then
						callbackFunc(output_msg, callbackParams);
					end
					LOG.std(nil, "debug", "auction", "unexpired data used for %s", url);
					return true;
				end
			end
		end
	end
end,
-- Post Processor
function (self, msg, id,callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
	if(type(msg) == "table") then
		local ls = System.localserver.CreateStore(nil, 3);
		if(ls) then
			-- make input msg
			local url = NPL.EncodeURLQuery(self.GetUrl(), {"gsid", inputMsg.gsid, "pindex", inputMsg.pindex, "psize", inputMsg.psize })
			-- make entry
			local item = {
				entry = System.localserver.WebCacheDB.EntryInfo:new({
					url = url,
				}),
				payload = System.localserver.WebCacheDB.PayloadInfo:new({
					status_code = System.localserver.HttpConstants.HTTP_OK,
					data = msg,
				}),
			}
			-- save to database entry
			local res = ls:PutItem(item) 
			if(res) then 
				LOG.std(nil, "debug", "auction", "data saved to ls for %s", url);
			else	
				LOG.std(nil, "error", "auction", "data failed to save to ls for %s", url);
			end
		end
	end
end);


--[[ this is SLOW, call this sparingly
/// <summary>
/// 搜索正在出售中的物品
/// 接收参数：
///     sessionkey 当前用户
///     [ canuse ] 是否只搜当前用户可用的，0:否；1:是
///     [ minlel ] 最小等级
///     [ maxlel ] 最大等级
///     [ quality ] 品质
///     [ gsname ] 物品名
///     [ itemclass ] 类别ID
///     [ subclass ] 子类别ID
///     pindex 页码
///     psize 每页的数据量
/// 返回值：
///     [ list ]
///         id 编号
///         gsid 物品GSID
///         name 物品名称
///         lel 物品等级
///         [ nid ] 售卖者的NID
///         [ nname ] 售卖者的昵称
///         price 价格
///         expire 过期时间
///         cnt
///         svrdata
/// </summary>
]]
paraworld.create_wrapper("paraworld.auction.SearchFromShop", "MAIN%/API/Items/SearchFromShop.ashx",
-- pre validation function and use default inputs
function(self, msg, id, callbackFunc, callbackParams, postMsgTranslator) 
	if(not paraworld.use_game_server) then
		msg.sessionkey = Map3DSystem.User.sessionkey;
	end	
	local cache_policy = msg.cache_policy or "access plus 5 seconds";
	if(type(cache_policy) == "string") then
		cache_policy = System.localserver.CachePolicy:new(cache_policy);
	end
	msg.cache_policy = nil;

	if(cache_policy == nil) then
		return;
	end
	
	local ls = System.localserver.CreateStore(nil, 3);
	if(not ls) then
		return 
	end

	-- make url
	local url = NPL.EncodeURLQuery(self.GetUrl(), {"gsname", msg.gsname, "pindex", msg.pindex, "psize", msg.psize, "subclass", msg.subclass, "itemclass", msg.itemclass,"quality", msg.quality, "school", msg.school})
	local item = ls:GetItem(url)
	if(item and item.entry and item.payload) then
		if(not cache_policy:IsExpired(item.payload.creation_date)) then
			-- make output msg
			if(item.payload.data) then
				local output_msg = commonlib.LoadTableFromString(item.payload.data);
				if(output_msg) then
					if(callbackFunc) then
						callbackFunc(output_msg, callbackParams);
					end
					LOG.std(nil, "debug", "auction", "unexpired data used for %s", url);
					return true;
				end
			end
		end
	end
end,
-- Post Processor
function (self, msg, id,callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
	if(type(msg) == "table") then
		local ls = System.localserver.CreateStore(nil, 3);
		if(ls) then
			-- make input msg
			local url = NPL.EncodeURLQuery(self.GetUrl(), {"gsname", inputMsg.gsname, "pindex", inputMsg.pindex, "psize", inputMsg.psize, "subclass", inputMsg.subclass, "itemclass", inputMsg.itemclass,"quality", inputMsg.quality, "school", inputMsg.school })
			-- make entry
			local item = {
				entry = System.localserver.WebCacheDB.EntryInfo:new({
					url = url,
				}),
				payload = System.localserver.WebCacheDB.PayloadInfo:new({
					status_code = System.localserver.HttpConstants.HTTP_OK,
					data = msg,
				}),
			}
			-- save to database entry
			local res = ls:PutItem(item) 
			if(res) then 
				LOG.std(nil, "debug", "auction", "data saved to ls for %s", url);
			else	
				LOG.std(nil, "error", "auction", "data failed to save to ls for %s", url);
			end
		end
	end
end);


--[[study new skill for make item
/// <summary>
/// 学习制造技能
/// 接收参数:
///     sessionkey
///     skillgsid  技能的GSID
/// 返回值:
///     issuccess
///     [ guid ] 若成功,则会输出新技能的GUID
///     [ errorcode ] 0:正常 493:参数不正确 497:物品不存在 419:用户不存在 433:技能数已达最大数 417:已学过此技能
/// </summary>
]]
paraworld.create_wrapper("paraworld.auction.StudyMakeSkill", "MAIN%/API/Items/StudyMakeSkill.ashx");

