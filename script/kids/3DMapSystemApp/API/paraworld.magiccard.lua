--[[
Title: MagicCard related api
Author(s): Spring
Date: 2010.3.3
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/paraworld.magiccard.lua");
-------------------------------------------------------
]]
-- create class
commonlib.setfield("paraworld.MagicCard", {});

--[[
				/// <summary>
        /// 查询神奇密码卡
        /// 接收参数：
        ///     sessionkey  当前登录用户的sessionkey
        ///     card  卡号
        /// 返回值：
        ///     gsids  该卡可兑换的物品，多个GSID之间用英文逗号分隔
        ///     [ errorcode ]  497：卡号不存在  421：已被使用  500：其它错误
        /// </summary>
--]]        
paraworld.create_wrapper("paraworld.MagicCard.Get", "%MAIN%/API/MagicCard/Get");

--[[
        /// <summary>
        /// 消费神奇密码卡
        /// 接收参数：
        ///     sessionkey  当前登录用户的sessionkey
        ///     card  卡号
        ///     ip  用户的IP
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
        ///     [ errorcode ]  497:兑换的物品不存在或卡号不存在  421：卡已被使用  424:拥有的物品数量超过限制  428:超过单日购买限制  429:超过周购买限制  417:该卡号正在被使用  500:其它错误
        /// </summary>
--]]
paraworld.create_wrapper("paraworld.MagicCard.Consume", "%MAIN%/API/MagicCard/Consume");
