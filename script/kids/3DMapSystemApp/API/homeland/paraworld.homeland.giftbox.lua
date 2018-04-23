--[[
Title: giftbox info
Author(s): Leio
Date: 2009/6/8
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/homeland/paraworld.homeland.giftbox.lua");
-------------------------------------------------------
赠送物品时，分两步
第一步是调物品的DestroyItem
第二步是调礼物的Donate
这个步骤本来是应该是一个后端实现的，但这块是由XIZHI在做，还未做出来
你先在前台做类似的功能就行了
]]
local ItemManager = commonlib.gettable("Map3DSystem.Item.ItemManager");
-- create class
local giftbox = commonlib.gettable("paraworld.homeland.giftbox");
----------------------------------------------------------------------------------------------
--[[
AcceptGift
/// <summary>
    /// 指定的用户接受其收到的某个礼物
    /// 接收参数：
    ///     sessionkey
    ///     guid 礼物的GUID
    /// 返回值：
    ///     issuccess
    ///     [ errorcode ]
    /// </summary>
--]]
paraworld.create_wrapper("paraworld.homeland.giftbox.AcceptGift", "%MAIN%/API/Gift/AcceptGift");
--[[
ChuckGift
    /// <summary>
    /// 登录用户丢弃其收到的某个礼物
    /// 接收参数：
    ///     sessionkey
    ///     guid
    /// 返回值：
    ///     issuccess
    ///     [ errorcode ]
    /// </summary>

--]]
paraworld.create_wrapper("paraworld.homeland.giftbox.ChuckGift", "%MAIN%/API/Gift/ChuckGift");
--[[
Donate
    /// <summary>
	/// 当前登录用户向另一个用户赠送物品
	/// 接收参数：
	/// sessionkey
	/// guid
	/// bag
	/// tonid
	/// msg
	/// 返回值：
	/// issuccess
	/// [ errorcode ]
	/// </summary> 
--]]
paraworld.create_wrapper("paraworld.homeland.giftbox.Donate", "%MAIN%/API/Gift/Donate",
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	if(msg.guid) then
		local item = ItemManager.GetItemByGUID(msg.guid)
		if(item) then
			msg.log2db = 1;
			local log_remark = {gsid=item.gsid, tonid=msg.tonid};
			msg.logremark = commonlib.serialize_compact(log_remark);
		end
	end
	LOG.std("", "debug","gift.donate", msg);
end);
--[[
Get
   /// <summary>
    /// 取得指定的用户的礼品盒
    /// 接收参数：
    ///     nid
    /// 返回值：
    ///     boxcnt （所拥有的礼品盒数）
    ///     giftcnt （共收到了多少礼物）
    ///     sendcnt （共向别人赠送了多少礼品）
    ///     [ errorcode ]
    /// </summary>
--]]
paraworld.create_wrapper("paraworld.homeland.giftbox.Get", "%MAIN%/API/Gift/Get");
--[[
TakeHortation
  /// <summary>
    /// 指定的用户领取其因向其他人赠送礼物而应获得的奖励
    /// 接收参数：
    ///     nid
    /// 返回值：
    ///     issuccess
    ///     errorcode
    /// </summary>
--]]  
paraworld.create_wrapper("paraworld.homeland.giftbox.TakeHortation", "%MAIN%/API/Gift/TakeHortation");
--[[
GetHortation
    /// <summary>
    /// 取得指定用户因向其他人赠送礼物而应获取的奖励
    /// 接收参数：
    ///     nid
    /// 返回值：
    ///     boxcnt 可允许拥有的礼物盒的数量，若为0，表示不需要更新其礼物盒的数量
    ///     items[list]
    ///         gsid 可获取的物品的GSID
    ///         cnt 可获取的数量
    ///     [ errorcode ]
    /// </summary>
--]]  
paraworld.create_wrapper("paraworld.homeland.giftbox.GetHortation", "%MAIN%/API/Gift/GetHortation");
--[[
GetGifts
 /// <summary>
    /// 取得指定用户收到的所有礼物
    /// 接收参数：
    ///     nid
    /// 返回值：
    ///     gifts[list]
    ///         id
    ///         from
    ///         gsid
    ///         msg
    ///         adddate
    ///     [ errorcode ]
    /// </summary>

--]]  
paraworld.create_wrapper("paraworld.homeland.giftbox.GetGifts", "%MAIN%/API/Gift/GetGifts");


--[[
/// <summary>
/// 购买一个礼物盒子
/// 接收参数：
///     sessionkey
/// 返回值：
///     issuccess
///     [ errorcode ] 419:用户不存在；443:魔豆不足
/// </summary>
--]]  
paraworld.create_wrapper("paraworld.homeland.giftbox.BuyGiftBox", "%MAIN%/API/Gift/BuyGiftBox",
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	LOG.std("", "debug","giftbox.in", msg);
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
	LOG.std("", "debug","giftbox.out", msg);
	if(msg.issuccess) then
		Map3DSystem.Item.ItemManager.UpdateBagItems(msg.updates or msg.ups, msg.adds);
	elseif(msg.errorcode == 443) then
		LOG.std("", "debug","giftbox.out", "not enough money 984");
	end
end);