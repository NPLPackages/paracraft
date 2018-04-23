--[[
Title: power api inventory
Author(s): WangTian
Date: 2010/8/23
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/AriesPowerAPI/paraworld.PowerAPI.inventory.lua");
-------------------------------------------------------
]]

-- create class
commonlib.setfield("paraworld.PowerAPI.inventory", {});
commonlib.setfield("paraworld.PowerAPI.globalstore", {});

local isLogInventoryTraffic = true;

--[[
	/// <summary>
	/// get the global store description and template data according to the global store id
	/// </summary>
	/// <param name="msg">
	/// msg = {
	///		[ "gsids" ] = string  // global store ids separated with ","  maximum gsids per request is 10
	/// }
	/// </param>
	/// <returns>
	///		[ "issuccess" ] = boolean   // is success
	///		[ "globalstoreitems" ] = list{
	///			gsid = int
	///			assetfile = string
	///			descfile = string
	///			type = int
	///			category = string
	///			icon = string
	///			pbuyprice = int
	///			ebuyprice = int
	///			psellprice = int
	///			esellprice = int
	///			requirepayment = int
	///			template = {
	///				class = int
	///				subclass = int
	///				name = int
	///				inventorytype = int
	///				// and other template data fields
	///				}
	///			}  // item count depending on the gsids count
	///		[ "errorcode" ] = int   // errorcode if issuccess is false
	///		[ "info" ] = string  // error info if issuccess is false
	/// </returns>
-- TODO: put item description into global store
]] 
paraworld.createPowerAPI("paraworld.PowerAPI.globalstore.read", "Items.read", 
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	msg.nid = "1";
	msg._nid = "1";

	--if(isLogInventoryTraffic) then
		--LOG.std(nil, "debug", "PowerAPI", "paraworld.PowerAPI.globalstore.read msg_in: "..commonlib.serialize_compact(msg));
	--end
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg, originalMsg)
	--if(isLogInventoryTraffic) then
		--LOG.std(nil, "debug", "PowerAPI", "paraworld.PowerAPI.globalstore.read msg_out: "..commonlib.serialize_compact(msg));
	--end
end,
nil,nil, nil,nil, 100000);

--[[
        /// <summary>
        /// 取得指定的一组GlobalStore，与read的区别是：当所传的gsids参数为空字符串时，将返回所有已定义的物品，
        /// 并且不受每次可获取的数量的最大值的限制。限GameServer使用。
        /// </summary>
        /// <param name="msg">
        /// msg = {
        ///      [ "gsids" ] = string  // global store ids separated with ","  maximum gsids per request is 10
        /// }
        /// </param>
        /// <returns>
        ///      [ 与 Item.read 相同 ]
        /// </returns>
]] 
paraworld.createPowerAPI("paraworld.PowerAPI.globalstore.GetALLGS", "Items.GetALLGS", 
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	msg.nid = "1";
	msg._nid = "1";

	--if(isLogInventoryTraffic) then
		--LOG.std(nil, "debug", "PowerAPI", "paraworld.PowerAPI.globalstore.read msg_in: "..commonlib.serialize_compact(msg));
	--end
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg, originalMsg)
	--if(isLogInventoryTraffic) then
		--LOG.std(nil, "debug", "PowerAPI", "paraworld.PowerAPI.globalstore.read msg_out: "..commonlib.serialize_compact(msg));
	--end
end);


--[[
	/// <summary>
	/// get all items in the specific bag
	/// </summary>
	/// <param name="msg">
	/// msg = {
	///		[ "nid" ] = int  // nid of the user, if nid is provided, sessionkey is omited
	///		[ "sessionkey" ] = string  // session key
	///		[ "bag" ] = string  // bag to be searched
	/// }
	/// </param>
	/// <returns>
	///		[ "items" ] = list{
	///			guid = int  // item instance id
	///			gsid = int
	///			obtaintime = string
	///			position = int
	///			clientdata = string
	///			serverdata = string
	///			copies = int
	///			}  // item count depending on the bag item count
	///		[ "errorcode" ] = int   // errorcode if issuccess is false
	///		[ "info" ] = string  // error info if issuccess is false
	/// </returns>
]] 
paraworld.createPowerAPI("paraworld.PowerAPI.inventory.GetItemsInBag", "Items.GetItemsInBag", 
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	msg.nid = tonumber(msg.nid);
	msg.bag = tonumber(msg.bag);
	
	if(not msg.nid) then
		LOG.std(nil, "error", "PowerAPI", "paraworld.PowerAPI.inventory.GetItemsInBag got nil nid");
		return true;
	elseif(not msg.bag) then
		LOG.std(nil, "error", "PowerAPI", "paraworld.PowerAPI.inventory.GetItemsInBag got nil bag");
		return true;
	end
	if(isLogInventoryTraffic) then
		LOG.std(nil, "debug", "PowerAPI", "paraworld.PowerAPI.inventory.GetItemsInBag msg_in: "..commonlib.serialize_compact(msg));
	end
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg, originalMsg)
	if(isLogInventoryTraffic) then
		LOG.std(nil, "debug", "PowerAPI", "paraworld.PowerAPI.inventory.GetItemsInBag msg_out: "..commonlib.serialize_compact(msg));
	end
end);

--[[
        /// <summary>
        /// 取得指定用户指定的一组包中的所有数据
        /// 接收参数：
        ///     nid
        ///     bags  包ID，多个包ID之间用英文逗号分隔
        /// 返回值：
        ///     list [list]
        ///         bag  包ID
        ///         items [list]
        ///             guid = int  // item instance id
        ///             gsid = int
        ///             obtaintime = string yyyy-MM-dd HH:mm:ss
        ///             position = int
        ///             clientdata = string
        ///             serverdata = string
        ///             copies = int
        ///      [ errorcode ]
        /// </summary>
]]
paraworld.createPowerAPI("paraworld.PowerAPI.inventory.GetItemsInBags", "Items.GetItemsInBags", 
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	msg.nid = tonumber(msg.nid);
	msg._nid = tonumber(msg.nid);
	
	if(not msg.nid) then
		LOG.std(nil, "error", "PowerAPI", "paraworld.PowerAPI.inventory.GetItemsInBags got nil nid");
		return true;
	elseif(not msg.bags) then
		LOG.std(nil, "error", "PowerAPI", "paraworld.PowerAPI.inventory.GetItemsInBags got nil bags");
		return true;
	end
	if(isLogInventoryTraffic) then
		LOG.std(nil, "debug", "PowerAPI", "paraworld.PowerAPI.inventory.GetItemsInBags msg_in: "..commonlib.serialize_compact(msg));
	end
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg, originalMsg)
	if(isLogInventoryTraffic) then
		LOG.std(nil, "debug", "PowerAPI", "paraworld.PowerAPI.inventory.GetItemsInBags msg_out: "..commonlib.serialize_compact(msg));
	end
end);


--[[
        /// <summary>
        /// 修改指定用户的物品数量
        /// 接收参数：
        ///     nid
        ///     pres: 前提条件，若条件不满足，则不会执行。类似于：gsid~cnt|gsid~cnt|gsid~cnt....，GSID不能为负数，cnt为正数表示大于等于此值，cnt为负数表示小于等于此值
        ///     sets: 将指定的用户的数量设为指定的值。gsid~cnt|gsid~cnt.....GSID不能为负数
        ///     adds: 要修改的数据，类似于：gsid~cnt~serverdata~clientdata~isgreedy|gsid~cnt~serverdata~clientdata~isgreedy|gsid~cnt~serverdata~clientdata~isgreedy....，其中cnt表示要增加的
        ///                    数量，若为负数，表示减少的数量，clientData与serverData中不可包含有“~”和"|"特殊字符，也不可是“NULL”，若不指定，则传"NULL"。isgreedy指定针对这条数据是否是贪婪模式，
        ///                    0表示false，非0表示true，可不传递，若不传，则会以外部的isgreedy参数为默认值，若有传递，则忽略外部的isgreedy参数。
        ///     updates: 在指定的数据上增减数量的物品，类似于：guid~cnt~serverdata~clientdata~isgreedy|guid~cnt~serverdata~clientdata~isgreedy|guid~cnt~serverdata~clientdata~isgreedy....，
        ///                    其中cnt表示要增加的数量，若为负数，表示减少的数量，clientData与serverData中不可包含有“~”和"|"特殊字符，也不可是“NULL”，若不指定，
        ///                    则传"NULL"。注意这里的是GUID，不是GSID。如果update中指定的物品的数量与update中指定的增减数计算后小于0，则该数据将会被删除，
        ///                    如果大于GlobalStore中设定的MaxCopiesInStack，则会将多出的数量将会被忽略。isgreedy指定针对这条数据是否是贪婪模式，0表示false，非0表示true，可不传递，若不传，
        ///                    则会以外部的isgreedy参数为默认值，若有传递，则忽略外部的isgreedy参数。
        ///     isgreedy：boolean，是否是贪婪模式，如果是true，则adds和updates中若有不符合条件限制的，则忽略，其它继续执行，如果是false，则只要有任何一个不符合条件都将回滚。该值会被adds和updates中
        ///                     每条数据自己的isgreedy覆盖。
        /// 返回值：
        ///     issuccess
        ///     [ updates ][list] 输出叠加在旧数据上的物品
        ///         guid
        ///         bag
        ///         cnt
        ///     [ adds ][list] 输出新增的数据
        ///         guid
        ///         gsid
        ///         bag
        ///         cnt
        ///         position
        ///     [ stats ][list] 输出兑换后各属性值的变化，其中-12表示当前的健康状态（0：健康；1：生病；2：死亡），-1000表示抱抱龙升级到下一级所需的亲密度
        ///         gsid  -1:P币；0:E币；-2:亲密度；-3:爱心值；-4:力量值；-5:敏捷值；-6:智慧值；-7:建筑熟练度；-8:抱抱龙等级；-9:体力值；-10:清洁值；-11:心情值；-12:健康状态；-13:战斗经验值；-14:战斗等级；
        ///         cnt
        ///     [ errorcode ]
        /// </summary>
]] 
paraworld.createPowerAPI("paraworld.PowerAPI.inventory.ChangeItem", "Power_Items.ChangeItem", 
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	msg.nid = tonumber(msg.nid);
	
	if(not msg.nid) then
		LOG.std(nil, "error", "PowerAPI", "paraworld.PowerAPI.inventory.ChangeItem got nil nid");
		return true;
	elseif(not msg.adds and not msg.updates and not msg.sets) then
		LOG.std(nil, "error", "PowerAPI", "paraworld.PowerAPI.inventory.ChangeItem got nil adds or nil updates or nil sets");
		return true;
	end
	if(isLogInventoryTraffic) then
		LOG.std(nil, "debug", "PowerAPI", "paraworld.PowerAPI.inventory.ChangeItem msg_in: "..commonlib.serialize_compact(msg));
	end
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg, originalMsg)
	if(isLogInventoryTraffic) then
		LOG.std(nil, "debug", "PowerAPI", "paraworld.PowerAPI.inventory.ChangeItem msg_out: "..commonlib.serialize_compact(msg));
	end
end);

-- ExtendedCost is usually used in power version, not directly from user request.  
paraworld.createPowerAPI("paraworld.PowerAPI.inventory.ExtendedCost", "Items.ExtendedCost", 
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	msg.nid = tonumber(msg.nid);
	if(isLogInventoryTraffic) then
		LOG.std(nil, "debug", "PowerAPI", "paraworld.PowerAPI.inventory.ExtendedCost msg_in: "..commonlib.serialize_compact(msg));
	end
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg, originalMsg)
	if(isLogInventoryTraffic) then
		LOG.std(nil, "debug", "PowerAPI", "paraworld.PowerAPI.inventory.ExtendedCost msg_out: "..commonlib.serialize_compact(msg));
	end
end);

-- ExtendedCost2 is usually used in power version, not directly from user request.  
paraworld.createPowerAPI("paraworld.PowerAPI.inventory.ExtendedCost2", "Items.ExtendedCost2", 
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	msg.nid = tonumber(msg.nid);
	if(isLogInventoryTraffic) then
		LOG.std(nil, "debug", "PowerAPI", "paraworld.PowerAPI.inventory.ExtendedCost2 msg_in: "..commonlib.serialize_compact(msg));
	end
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg, originalMsg)
	if(isLogInventoryTraffic) then
		LOG.std(nil, "debug", "PowerAPI", "paraworld.PowerAPI.inventory.ExtendedCost2 msg_out: "..commonlib.serialize_compact(msg));
	end
end);

--[[
        /// <summary>
        /// 给指定的装备镶嵌指定的宝石
        /// 接收参数：
        ///     sessionkey : 
        ///     containerguid : 装备的GUID
        ///     gemguid : 要装备的宝石的GUID
        ///     cards : 一组使用的可以增加成功概率的镶嵌符的GUID与Cnt，多个镶嵌符之间用竖线分隔。guid,cnt|guid,cnt|.....。
        ///                 注意：不可有重复的guid，这样是错误的：1001,1|1002,1|1001,2。 这种情况应该写成：1001,3|1002,1
        /// 返回值：
        ///     issuccess : 是否成功
        ///     errorcode : 错误码。此API的错误码比较特殊。issuccess只是表示是否执行成功，并不表示镶嵌是否成功。
        ///                     只有当issuccess为true，并且errorcode是0时才表示镶嵌成功。
        ///                     当issuccess为true，但errorcode为492时，表示未命中概率，执行了未命中概率的逻辑
        ///     [ updates ][list] 输出叠加在旧数据上的物品
        ///         guid
        ///         bag
        ///         cnt
        ///         [ newsvrdata ]  新的ServerData。如果物品的ServerData已改动，则会有此节点输出。
        ///     [ adds ][list] 输出新增的数据
        ///         guid
        ///         gsid
        ///         bag
        ///         cnt
        ///         position
        ///     [ stats ][list] 输出兑换后各属性值的变化，其中-12表示当前的健康状态（0：健康；1：生病；2：死亡），-1000表示抱抱龙升级到下一级所需的亲密度
        ///         gsid  -1:P币；0:E币；-2:亲密度；-3:爱心值；-4:力量值；-5:敏捷值；-6:智慧值；-7:建筑熟练度；-8:抱抱龙等级；-9:体力值；-10:清洁值；
        ///                 -11:心情值；-12:健康状态；-13:战斗经验值；-14:战斗等级；-15:魔法星能量值；-16:魔法星M值；-17:魔法星等级
        ///         cnt
        /// </summary>
]] 
paraworld.createPowerAPI("paraworld.PowerAPI.inventory.EquipGem", "Items.EquipGem", 
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	msg.nid = tonumber(msg.nid);
	
	if(not msg.nid) then
		LOG.std(nil, "error", "PowerAPI", "paraworld.PowerAPI.inventory.EquipGem got nil nid");
		return true;
	elseif(not msg.containerguid or not msg.gemguid) then
		LOG.std(nil, "error", "PowerAPI", "paraworld.PowerAPI.inventory.EquipGem got nil containerguid or nil gemguid, msg: "..commonlib.serialize_compact(msg));
		return true;
	end
	if(isLogInventoryTraffic) then
		LOG.std(nil, "debug", "PowerAPI", "paraworld.PowerAPI.inventory.EquipGem msg_in: "..commonlib.serialize_compact(msg));
	end
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg, originalMsg)
	if(isLogInventoryTraffic) then
		LOG.std(nil, "debug", "PowerAPI", "paraworld.PowerAPI.inventory.EquipGem msg_out: "..commonlib.serialize_compact(msg));
	end
end);

--[[
        /// <summary>
        /// 使用调羹将指定的装备上的指定的一组指定的宝石移除。移除的宝石将保存回用户的包中，宝石调羹消失。宝石调羹只可能是一条Instance数据，因为宝石调羹不会被移动到其它包
        /// 接收参数：
        ///     sessionkey : 当前登录用户的SessionKey
        ///     containerguid : 装备的GUID
        ///     gemgsids : 一组被移除的宝石的GSID列表，多个GSID之间以英语逗号分隔
        /// 返回值：
        ///     issuccess : 是否成功
        ///     errorcode : 错误码
        ///     [ updates ][list] 输出叠加在旧数据上的物品
        ///         guid
        ///         bag
        ///         cnt
        ///         [ newsvrdata ]  新的ServerData。如果物品的ServerData已改动，则会有此节点输出。
        ///     [ adds ][list] 输出新增的数据
        ///         guid
        ///         gsid
        ///         bag
        ///         cnt
        ///         position
        /// </summary>
]] 
paraworld.createPowerAPI("paraworld.PowerAPI.inventory.UnEquipGem", "Items.UnEquipGem", 
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	msg.nid = tonumber(msg.nid);
	
	if(not msg.nid) then
		LOG.std(nil, "error", "PowerAPI", "paraworld.PowerAPI.inventory.UnEquipGem got nil nid");
		return true;
	elseif(not msg.containerguid or not msg.gemgsids) then
		LOG.std(nil, "error", "PowerAPI", "paraworld.PowerAPI.inventory.UnEquipGem got nil containerguid or nil gemgsids, msg: "..commonlib.serialize_compact(msg));
		return true;
	end
	if(isLogInventoryTraffic) then
		LOG.std(nil, "debug", "PowerAPI", "paraworld.PowerAPI.inventory.UnEquipGem msg_in: "..commonlib.serialize_compact(msg));
	end
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg, originalMsg)
	if(isLogInventoryTraffic) then
		LOG.std(nil, "debug", "PowerAPI", "paraworld.PowerAPI.inventory.UnEquipGem msg_out: "..commonlib.serialize_compact(msg));
	end
end);


--[[
        /// 给指定的装备镶嵌指定的宝石（青年版）
        /// 接收参数：
        ///     sessioneky : 当前登录用户
        ///     containerguid : 装备的GUID
        ///     gemguid : 要装备的宝石的GUID
        ///     cards : 一组使用的可以增加成功概率的镶嵌符的GUID与Cnt，多个镶嵌符之间用竖线分隔。guid,cnt|guid,cnt|.....。
        ///                 注意：不可有重复的guid，这样是错误的：1001,1|1002,1|1001,2。 这种情况应该写成：1001,3|1002,1
        /// 返回值：
        ///     issuccess : 是否成功
        ///     errorcode : 错误码。此API的错误码比较特殊。issuccess只是表示是否执行成功，并不表示镶嵌是否成功。
        ///                     只有当issuccess为true，并且errorcode是0时才表示镶嵌成功。
        ///                     当issuccess为true，但errorcode为492时，表示未命中概率，执行了未命中概率的逻辑。
        ///                     433:没有足够的孔了；493:提供的某个参数不符合要求；427:PE币不足；497:参数中的某个物品不存在；417:已镶嵌了同类的宝石；
        ///     [ updates ][list] 输出叠加在旧数据上的物品
        ///         guid
        ///         bag
        ///         cnt
        ///         [ newsvrdata ]  新的ServerData。如果物品的ServerData已改动，则会有此节点输出。
        ///     [ adds ][list] 输出新增的数据
        ///         guid
        ///         gsid
        ///         bag
        ///         cnt
        ///         position
        ///     [ stats ][list] 输出兑换后各属性值的变化，其中-12表示当前的健康状态（0：健康；1：生病；2：死亡），-1000表示抱抱龙升级到下一级所需的亲密度
        ///         gsid  -1:P币；0:E币；-2:亲密度；-3:爱心值；-4:力量值；-5:敏捷值；-6:智慧值；-7:建筑熟练度；-8:抱抱龙等级；-9:体力值；-10:清洁值；
        ///                 -11:心情值；-12:健康状态；-13:战斗经验值；-14:战斗等级；-15:魔法星能量值；-16:魔法星M值；-17:魔法星等级
        ///         cnt
        /// </summary>
]] 
paraworld.createPowerAPI("paraworld.PowerAPI.inventory.EquipGem2", "Items.EquipGem2", 
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	msg.nid = tonumber(msg.nid);
	
	if(not msg.nid) then
		LOG.std(nil, "error", "PowerAPI", "paraworld.PowerAPI.inventory.EquipGem2 got nil nid");
		return true;
	elseif(not msg.containerguid or not msg.gemguid) then
		LOG.std(nil, "error", "PowerAPI", "paraworld.PowerAPI.inventory.EquipGem2 got nil containerguid or nil gemguid, msg: "..commonlib.serialize_compact(msg));
		return true;
	end
	if(isLogInventoryTraffic) then
		LOG.std(nil, "debug", "PowerAPI", "paraworld.PowerAPI.inventory.EquipGem2 msg_in: "..commonlib.serialize_compact(msg));
	end
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg, originalMsg)
	if(isLogInventoryTraffic) then
		LOG.std(nil, "debug", "PowerAPI", "paraworld.PowerAPI.inventory.EquipGem2 msg_out: "..commonlib.serialize_compact(msg));
	end
end);

--[[
        /// <summary> TODO
]] 
paraworld.createPowerAPI("paraworld.PowerAPI.inventory.UnEquipGem2", "Items.UnEquipGem2", 
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	msg.nid = tonumber(msg.nid);
	
	if(not msg.nid) then
		LOG.std(nil, "error", "PowerAPI", "paraworld.PowerAPI.inventory.UnEquipGem2 got nil nid");
		return true;
	elseif(not msg.containerguid or not msg.gemgsids) then
		LOG.std(nil, "error", "PowerAPI", "paraworld.PowerAPI.inventory.UnEquipGem2 got nil containerguid or nil gemgsids, msg: "..commonlib.serialize_compact(msg));
		return true;
	end
	if(isLogInventoryTraffic) then
		LOG.std(nil, "debug", "PowerAPI", "paraworld.PowerAPI.inventory.UnEquipGem2 msg_in: "..commonlib.serialize_compact(msg));
	end
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg, originalMsg)
	if(isLogInventoryTraffic) then
		LOG.std(nil, "debug", "PowerAPI", "paraworld.PowerAPI.inventory.UnEquipGem2 msg_out: "..commonlib.serialize_compact(msg));
	end
end);

--[[
        /// <summary>
        /// 使用玄玉兑换指定的套装中的物件
        /// 接收参数：
        ///     sessionkey
        ///     gsid  套装中物件的GSID
        /// 返回值：
        ///     issuccess : 是否成功
        ///     [ updates ][list] 输出叠加在旧数据上的物品
        ///         guid
        ///         bag
        ///         cnt
        ///     [ adds ][list] 输出新增的数据
        ///         guid
        ///         gsid
        ///         bag
        ///         cnt
        ///         position
        ///     [ stats ][list] 输出兑换后各属性值的变化，其中-12表示当前的健康状态（0：健康；1：生病；2：死亡），-1000表示抱抱龙升级到下一级所需的亲密度
        ///         gsid  -1:P币；0:E币；-2:亲密度；-3:爱心值；-4:力量值；-5:敏捷值；-6:智慧值；-7:建筑熟练度；-8:抱抱龙等级；-9:体力值；-10:清洁值；
        ///                 -11:心情值；-12:健康状态；-13:战斗经验值；-14:战斗等级；-15:魔法星能量值；-16:魔法星M值；-17:魔法星等级
        ///         cnt
        ///     [ errorcode ] : 错误码。427:可用的玄石不足；493:参数错误或指定的GSID不是已定义的套装中的物品；497:指定的GSID不存在
        /// </summary>
]] 
paraworld.createPowerAPI("paraworld.PowerAPI.inventory.ItemSetExtendedCost", "Items.ItemSetExtendedCost", 
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	msg.nid = tonumber(msg.nid);
	
	if(not msg.nid) then
		LOG.std(nil, "error", "PowerAPI", "paraworld.PowerAPI.inventory.ItemSetExtendedCost got nil nid");
		return true;
	elseif(not msg.gsid) then
		LOG.std(nil, "error", "PowerAPI", "paraworld.PowerAPI.inventory.ItemSetExtendedCost got nil gsid, msg: "..commonlib.serialize_compact(msg));
		return true;
	end
	if(isLogInventoryTraffic) then
		LOG.std(nil, "debug", "PowerAPI", "paraworld.PowerAPI.inventory.ItemSetExtendedCost msg_in: "..commonlib.serialize_compact(msg));
	end
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg, originalMsg)
	if(isLogInventoryTraffic) then
		LOG.std(nil, "debug", "PowerAPI", "paraworld.PowerAPI.inventory.ItemSetExtendedCost msg_out: "..commonlib.serialize_compact(msg));
	end
end);

--[[
        /// <summary>
        /// 取得指定用户拥有指定类物品的状态
        /// 接收参数：
        ///     nid
        ///     gsid
        /// 返回值：
        ///     allow： int 是否允许购买，0不允许，1允许
        ///     cnt:  int 已拥有此物品的数量
        ///     max:  int 最多可拥有此物品的数量
        ///     [ errorcode ]:  int 497:物品不存在
        /// </summary>

]] 
paraworld.createPowerAPI("paraworld.PowerAPI.inventory.GetState", "Power_Items.GetState", 
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	msg.nid = tonumber(msg.nid);
	msg.gsid = tonumber(msg.gsid);
	
	if(not msg.nid) then
		LOG.std(nil, "error", "PowerAPI", "paraworld.PowerAPI.inventory.GetState got nil nid");
		return true;
	elseif(not msg.gsid) then
		LOG.std(nil, "error", "PowerAPI", "paraworld.PowerAPI.inventory.GetState got gsid");
		return true;
	end
	if(isLogInventoryTraffic) then
		LOG.std(nil, "debug", "PowerAPI", "paraworld.PowerAPI.inventory.GetState msg_in: "..commonlib.serialize_compact(msg));
	end
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg, originalMsg)
	if(isLogInventoryTraffic) then
		LOG.std(nil, "debug", "PowerAPI", "paraworld.PowerAPI.inventory.GetState msg_out: "..commonlib.serialize_compact(msg));
	end
end);

--[[
		/// <summary>
        /// 两个用户之间互换物品
        /// 接收参数：
        ///     nid0    第一个用户的NID
        ///     items0  第一个用户用来交换的物品，guid,cnt|guid,cnt|guid,cnt....。guid==-1表示P币
        ///     nid1    第二个用户的NID
        ///     items1  第二个用户用来交换的物品，guid,cnt|guid,cnt|guid,cnt....。guid==-1表示P币
        /// 返回值：
        ///     issuccess
        ///     [ ups0 ] [ list ] 执行成功后第一个用户被修改的数据
        ///         guid  被修改物品的GUID
        ///         copies  被修改的物品现在的数量
        ///     [ ups1 ] [ list ] 执行成功后第二个用户 被修改的数据
        ///         guid  被修改物品的GUID
        ///         copies  被修改的物品现在的数量
        ///     [ adds0 ] [ list ] 执行成功后第一个用户新增的数据
        ///         guid  新增物品的GUID
        ///         gsid  新增物品的GSID
        ///         bag   新增物品所在的包
        ///         pos   新增物品的Position值
        ///         copies 新增物品的Copies值
        ///         svrdata 新增物品的ServerData值
        ///     [ adds1 ] [ list ] 执行成功后第二个用户新增的数据
        ///         guid  新增物品的GUID
        ///         gsid  新增物品的GSID
        ///         bag   新增物品所在的包
        ///         pos   新增物品的Position值
        ///         copies 新增物品的Copies值
        ///         svrdata 新增物品的ServerData值
        ///     [ errorcode ] 493:参数错误  419:用户不存在  497:用来交换的物品不存在  424:超过了最多可拥有的数量  
        /// </summary>
]] 
paraworld.createPowerAPI("paraworld.PowerAPI.inventory.Transaction", "Items.Transaction", 
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	if(not msg.nid0 or not msg.nid1) then
		LOG.std(nil, "error", "PowerAPI", "paraworld.PowerAPI.inventory.Transaction got nil nid");
		return true;
	end
	if(isLogInventoryTraffic) then
		LOG.std(nil, "debug", "PowerAPI", "paraworld.PowerAPI.inventory.Transaction msg_in: "..commonlib.serialize_compact(msg));
	end
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg, originalMsg)
	if(isLogInventoryTraffic) then
		LOG.std(nil, "debug", "PowerAPI", "paraworld.PowerAPI.inventory.Transaction msg_out: "..commonlib.serialize_compact(msg));
	end
end);

--[[
/// <summary>
/// 设置装备的强化等级
/// 接收参数：
///     sessionkey
///     guid 要强化等级的装备的GUID
///     addlel 强化的等级
///     reqgsid 需要的物品的GSID
///     reqcnt 需要的物品的数量
/// 返回值：
///     issuccess
///     ups [ list ] 受影响的数据列表
///         guid 受影响的物品的GUID
///         copies 目前的Copies值
///         [ serverdata ] 目前的ServerData值，若没有影响此值，则不会返回此数据项
///     [ errorcode ] 419:用户不存在；497:物品不存在；427:条件不符
/// </summary>
]]
paraworld.createPowerAPI("paraworld.PowerAPI.inventory.SetItemAddonLevel", "Items.SetItemAddonLevel", 
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	if(not msg.guid or not msg.addlel) then
		LOG.std(nil, "error", "PowerAPI", "paraworld.PowerAPI.inventory.SetItemAddonLevel got nil guid or addlel");
		return true;
	end
	if(isLogInventoryTraffic) then
		LOG.std(nil, "debug", "PowerAPI", "paraworld.PowerAPI.inventory.SetItemAddonLevel msg_in: "..commonlib.serialize_compact(msg));
	end
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg, originalMsg)
	if(isLogInventoryTraffic) then
		LOG.std(nil, "debug", "PowerAPI", "paraworld.PowerAPI.inventory.SetItemAddonLevel msg_out: "..commonlib.serialize_compact(msg));
	end
end);


--[[
        /// <summary>
        /// 检测用户所获得的已经过期的物品，并将其清除
        /// 接收参数：
        ///     sessionkey
        /// 返回值：
        ///     [] [list] 如果清理成功，则会返回被清除物品的GUID列表
        ///     [ errorcode ] 如果清理失败，则返回错误码
        /// </summary>
]] 
paraworld.createPowerAPI("paraworld.PowerAPI.inventory.CheckExpire", "Power_Items.CheckExpire", 
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	msg.nid = tonumber(msg.nid);
	
	if(not msg.nid) then
		LOG.std(nil, "error", "PowerAPI", "paraworld.PowerAPI.inventory.CheckExpire got nil nid");
		return true;
	end
	if(isLogInventoryTraffic) then
		LOG.std(nil, "debug", "PowerAPI", "paraworld.PowerAPI.inventory.CheckExpire msg_in: "..commonlib.serialize_compact(msg));
	end
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg, originalMsg)
	if(isLogInventoryTraffic) then
		LOG.std(nil, "debug", "PowerAPI", "paraworld.PowerAPI.inventory.CheckExpire msg_out: "..commonlib.serialize_compact(msg));
	end
end);