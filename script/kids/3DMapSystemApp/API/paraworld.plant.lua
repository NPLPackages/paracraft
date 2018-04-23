--[[
Title: plant related api
Author(s): Spring
Date: 2010.2.24
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/paraworld.plant.lua");
-------------------------------------------------------
]]
-- create class
commonlib.setfield("paraworld.Plant", {});

--[[
        /// <summary>
        /// 种植植物
        /// 接收参数：
        ///     sessionkey 当前登录用户的SessionKey
        ///     guid 被种植的植物的GUID
        ///     bag 被种植的植物当前所在的包
        ///     clientdata 新种植的植物的ClientData
        /// 返回值：
        ///     issuccess
        ///     id 种植后新的GUID
        ///     bag 种植后新的Bag
        ///     position 种植后新的Position
        ///     level
        ///     isdroughted
        ///     isbuged
        ///     feedscnt
        ///     grownvalue
        ///     update
        ///     allowgaincnt：剩余的可收获次数
        ///     totallevel 总共有多少级
        ///     updatetime 距升级到下一级还需的分钟数
        ///     gaintime 距收获还需的分钟数
        ///     [ errorcode ]
        /// </summary>
--]]        
paraworld.create_wrapper("paraworld.Plant.Grow", "%MAIN%/API/Plant/Grow");

--[[
        /// <summary>
        /// 依据一组植物实例的ID取得相应的实例的数据
        /// 接收参数：
        ///     nid：植物所有者的数字ID
        ///     ids：植物实例的ID，多个ID之间用英文逗号分隔
        /// 返回值：
        ///     items[list]
        ///         id：唯一标识
        ///         level：当前级别
        ///         isDroughted：是否处于干旱状态
        ///         isBuged：是否处于虫害状态
        ///         allowRemove：是否允许当前用户铲除该植物
        ///         feedsCnt：果实数量
        ///         grownValue：当前成长值
        ///         update：升级到下一级别所需要的成长值
        ///         allowgaincnt：剩余的可收获次数
        ///         totallevel 总共有多少级
        ///         updatetime 距升级到下一级还需的分钟数
        ///         gaintime 距收获还需的分钟数
        ///         feedgsid 可摘果实的GSID
        /// </summary>
--]]
paraworld.create_wrapper("paraworld.Plant.GetByIDs", "%MAIN%/API/Plant/GetByIDs");

--[[
        /// <summary>
        /// 给指定的植物除虫
        /// 接收参数：
        ///     nid：植物的所有者的用户数字ID
        ///     id：指定的植物的ID
        /// 返回值：
        ///     isSuccess
        ///     [ id ]：唯一标识
        ///     [ level ]：当前级别
        ///     [ isDroughted ]：是否处于干旱状态
        ///     [ isBuged ]：是否处于虫害状态
        ///     [ allowRemove ]：是否允许当前用户铲除该植物
        ///     [ feedsCnt ]：果实数量
        ///     [ grownValue ]：当前成长值
        ///     [ update ]：升级到下一级别所需要的成长值
        ///     [ allowgaincnt ]：剩余的可收获次数
        ///     [ totallevel ] 总共有多少级
        ///     [ updatetime ] 距升级到下一级还需的分钟数
        ///     [ gaintime ] 距收获还需的分钟数
        ///     [ errorCode ]
        /// </summary>
--]]
paraworld.create_wrapper("paraworld.Plant.Debug", "%MAIN%/API/Plant/Debug");

--[[
        /// <summary>
        /// 采摘指定植物的果实
        /// 接收参数：
        ///     sessionkey：当前采摘用户的sessionKey
        ///     [ id ]：被采摘植物的ID
        ///     [ ids ]：被采摘植物的ID，多个ID之间用英文逗号分隔，若存在ids参数，则忽略id参数
        /// 返回值：
        ///     若不存在ids参数，存在id参数
        ///         issuccess
        ///         [ id ]：唯一标识
        ///         [ level ]：当前级别
        ///         [ isdroughted ]：是否处于干旱状态
        ///         [ isbuged ]：是否处于虫害状态
        ///         [ allowremove ]：是否允许当前用户铲除该植物
        ///         [ feedscnt ]：果实数量
        ///         [ grownvalue ]：当前成长值
        ///         [ update ]：升级到下一级别所需要的成长值
        ///         [ allowgaincnt ]：剩余的可收获次数
        ///         [ totallevel ] 总共有多少级
        ///         [ updatetime ] 距升级到下一级还需的分钟数
        ///         [ gaintime ] 距收获还需的分钟数
        ///         [ errorcode ]
        ///     若存在ids参数
        ///         issuccess
        ///         [ list ][list]
        ///             id：唯一标识
        ///             level：当前级别
        ///             isdroughted：是否处于干旱状态
        ///             isbuged：是否处于虫害状态
        ///             allowremove：是否允许当前用户铲除该植物
        ///             feedscnt：果实数量
        ///             grownvalue：当前成长值
        ///             update：升级到下一级别所需要的成长值
        ///             allowgaincnt：剩余的可收获次数
        ///             totallevel： 总共有多少级
        ///             updatetime： 距升级到下一级还需的分钟数
        ///             gaintime： 距收获还需的分钟数
        ///         [ errorcode ]
        /// </summary>
--]]
paraworld.create_wrapper("paraworld.Plant.GainFeeds", "%MAIN%/API/Plant/GainFeeds");

--[[
    /// <summary>
    /// 铲除指定的植物
    /// 接收参数：
    ///     sessionKey：当前登录用户的用户凭证
    ///     id：被铲除的植物的ID
    /// 返回值：
    ///     isSuccess
    ///     [ errorCode ]
    /// </summary>
--]]
paraworld.create_wrapper("paraworld.Plant.Remove", "%MAIN%/API/Plant/Remove");

--[[
        /// <summary>
        /// 给指定的植物浇水
        /// 接收参数：
        ///     nid：植物所有者的数字ID
        ///     id：指定的植物的ID
        /// 返回值：
        ///     isSuccess
        ///     [ id ]：唯一标识
        ///     [ level ]：当前级别
        ///     [ isDroughted ]：是否处于干旱状态
        ///     [ isBuged ]：是否处于虫害状态
        ///     [ allowRemove ]：是否允许当前用户铲除该植物
        ///     [ feedsCnt ]：果实数量
        ///     [ grownValue ]：当前成长值
        ///     [ update ]：升级到下一级别所需要的成长值
        ///     [ allowgaincnt ]：剩余的可收获次数
        ///     [ totallevel ] 总共有多少级
        ///     [ updatetime ] 距升级到下一级还需的分钟数
        ///     [ gaintime ] 距收获还需的分钟数
        ///     [ errorCode ]
        /// </summary>
--]]
paraworld.create_wrapper("paraworld.Plant.Water", "%MAIN%/API/Plant/Water");

--[[
        /// <summary>
        /// 给指定的一组植物浇水
        /// 接收参数：
        ///     nid  植物所有者的NID
        ///     ids  指定的一组植物的ID，多个ID之间用英文逗号分隔
        /// 返回值：
        ///     issuccess
        ///     list [list]
        ///         [ id ]：唯一标识
        ///         [ level ]：当前级别
        ///         [ isDroughted ]：是否处于干旱状态
        ///         [ isBuged ]：是否处于虫害状态
        ///         [ feedsCnt ]：果实数量
        ///         [ grownValue ]：当前成长值
        ///         [ update ]：升级到下一级别所需要的成长值
        ///         [ allowgaincnt ]：剩余的可收获次数
        ///         [ totallevel ] 总共有多少级
        ///         [ updatetime ] 距升级到下一级还需的分钟数
        ///         [ gaintime ] 距收获还需的分钟数
        ///     [ errorcode ]
        /// </summary>
--]]
paraworld.create_wrapper("paraworld.Plant.WaterPlants", "%MAIN%/API/Plant/WaterPlants");
