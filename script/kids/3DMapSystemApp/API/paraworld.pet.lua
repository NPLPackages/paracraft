--[[
Title: pet related api
Author(s): Spring
Date: 2010.3.9
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/paraworld.pet.lua");
-------------------------------------------------------
]]
-- create class
commonlib.setfield("paraworld.Pet", {});

--[[
        /// <summary>
        /// 取得指定的宠物的资料
        /// 接收参数：
        ///     nid 宠物的所有者的数字ID
        ///     id 指定的宠物的ID
        /// 返回值：
        ///     petID 唯一标识
        ///     nickname 昵称
        ///     birthday 生日
        ///     level 级别
        ///     friendliness 亲密度
        ///     strong 体力值
        ///     cleanness 清洁值
        ///     mood 心情值
        ///     nextlevelfr 长级到下一级所需的亲密度
        ///     health 健康状态
        ///     health 健康状态
        ///     kindness 爱心值
        ///     intelligence 智慧值
        ///     agility 敏捷值
        ///     strength 力量值
        ///     archskillpts  建筑熟练度
        ///     isadopted  是否寄养状态
        ///     adopteddays  被寄养的天数，若isadopted为true，则有此字段，若是当天寄养，则反回1，若是前一天寄养，则返回2 ，以此类推
        ///     [ errorCode ]
        /// </summary>
--]]        
paraworld.create_wrapper("paraworld.Pet.Get", "%MAIN%/API/Pet/Get");

--[[
        /// <summary>
        /// 将寄养的宠物接回
        /// 接收参数：
        ///     sessionkey  当前登录用户的SessionKey
        ///     petid  宠物的ID
        /// 返回值：
        ///     issuccess
        ///     [ updates ][list] 输出兑换后叠加在旧数据上的物品
        ///         guid
        ///         bag
        ///         cnt
        ///     [ adds ][list] 输出兑换后新增的数据
        ///         guid
        ///         gsid
        ///         bag
        ///         cnt
        ///         position
        ///     [ stats ][list] 输出兑换后各属性值的变化
        ///         gsid  -1:P币；0:E币；-2:亲密度；-3:爱心值；-4:力量值；-5:敏捷值；-6:智慧值；-7:建筑熟练度；-8:抱抱龙等级；-9:体力值；-10:清洁值；-11:心情值；-12:健康状态
        ///         cnt
        ///     [ errorcode ]
        /// </summary>
--]]
paraworld.create_wrapper("paraworld.Pet.RetrieveAdoptedDragon", "%MAIN%/API/Pet/RetrieveAdoptedDragon");

--[[
        /// <summary>
        /// 寄养宠物
        /// 接收参数：
        ///     sessionkey  当前登录用户的SessionKey
        /// 返回值：
        ///     issuccess
        ///     [ updates ][list] 输出兑换后叠加在旧数据上的物品
        ///         guid
        ///         bag
        ///         cnt
        ///     [ adds ][list] 输出兑换后新增的数据
        ///         guid
        ///         gsid
        ///         bag
        ///         cnt
        ///         position
        ///     [ stats ][list] 输出兑换后各属性值的变化
        ///         gsid  -1:P币；0:E币；-2:亲密度；-3:爱心值；-4:力量值；-5:敏捷值；-6:智慧值；-7:建筑熟练度；-8:抱抱龙等级；-9:体力值；-10:清洁值；-11:心情值；-12:健康状态
        ///         cnt
        ///     [ errorcode ]
        /// </summary>
--]]
paraworld.create_wrapper("paraworld.Pet.Fosterage", "%MAIN%/API/Pet/Fosterage");

--[[
    /// <summary>
    /// 抚摸指定的宠物
    /// 接收参数：
    ///     sessionKey
    ///     petID
    /// 返回值：
    ///     isSuccess
    ///     [ errorCode ]
    /// </summary>
--]]
paraworld.create_wrapper("paraworld.Pet.Caress", "%MAIN%/API/Pet/Caress");

--[[
    /// <summary>
    /// 修改指定的宠物的资料
    /// 接收参数：
    ///     sessionKey
    ///     id
    ///     nickName
    /// 返回值：
    ///     isSuccess
    ///     [ errorCode ]
    /// </summary>
--]]
paraworld.create_wrapper("paraworld.Pet.Update", "%MAIN%/API/Pet/Update");

--[[
    /// <summary>
    /// 将指定的物品应用到指定的宠物身上
    /// 接收参数：
    ///     sessionKey 当前登录用户的sessionKey
    ///     nid 宠物所有者的数字ID
    ///     petID
    ///     itemGUID 使用的物品的GUID
    ///     bag 使用的物品所在的包
    /// 返回值：
    ///     isSuccess
    ///     level 级别
    ///     friendliness 亲密度
    ///     strong 体力值
    ///     nextlevelfr 长级到下一级所需的亲密度
    ///     health 健康状态
    ///     [ errorCode ]
    /// </summary>
--]]
paraworld.create_wrapper("paraworld.Pet.UseItem", "%MAIN%/API/Pet/UseItem");


