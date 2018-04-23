--[[
Title: home info
Author(s): Leio
Date: 2009/4/24
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/homeland/paraworld.homeland.home.lua");
-------------------------------------------------------
]]

-- create class
commonlib.setfield("paraworld.homeland.home", {});

--[[
GetHomeInfo
   KM_Home.API.GetHomeInfo
    /// <summary>
    /// 取得指定用户的家园的基本数据
    /// 接收参数：
    ///     nid：指定的用户的用户ID
    /// 返回值：
    ///     name：家园名称
    ///     flowercnt：获得的鲜花数量
    ///     pugcnt：获得的泥巴数量
    ///     visitors：最近的访客用户ID集合，各用户ID之间用英文逗号分隔。nid|date,nid|date|nid,date
    ///     visitcnt：总访问量
    /// </summary>
--]]
paraworld.create_wrapper("paraworld.homeland.home.GetHomeInfo", "%MAIN%/API/Home/Get");
--[[
SendFlower
  KM_Home.API.SendFlower
    /// <summary>
    /// 当前登录用户向指定的用户的家园送鲜花
    /// 接收参数：
    ///     sessionkey：当前登录用户的用户凭证
    ///     homenid：接收鲜花的家园的主人的用户ID
    /// 返回值：
    ///     issuccess
    ///     [ errorcode ]
    /// </summary>
--]]
paraworld.create_wrapper("paraworld.homeland.home.SendFlower", "%MAIN%/API/Home/SendFlower");
--[[
SendPug
   KM_Home.API.SendPug
    /// <summary>
    /// 当前登录用户向指定的用户的家园投泥巴
    /// 接收参数：
    ///     sessionkey：当前登录用户的用户凭证
    ///     homenid：接收泥巴的家园的主人的用户ID
    /// 返回值：
    ///     issuccess
    ///     [ errorcode ]
    /// </summary>
--]]
paraworld.create_wrapper("paraworld.homeland.home.SendPug", "%MAIN%/API/Home/SendPug");
--[[
Update
  KM_Home.API.Update
    /// <summary>
    /// 当前登录用户修改自己的家园中的基本数据
    /// 接收参数：
    ///     sessionkey：当前登录用户的用户凭证
    ///     name：修改后的家园的名称
    /// 返回值：
    ///     issuccess：修改是否成功
    ///     [ errorcode ]：
    /// </summary>
--]]  
paraworld.create_wrapper("paraworld.homeland.home.Update", "%MAIN%/API/Home/Update");
--[[
Visit
 KM_Home.API.Visit
    /// <summary>
    /// 当前登录用户访问指定的用户的家园
    /// 接收参数：
    ///     sessionkey：当前登录用户的用户凭证
    ///     homenid：被访问的家园的主人的用户ID
    /// 返回值：
    ///     issuccess
    ///     [ errorcode ]
    /// </summary>
    --]]
--]]  
paraworld.create_wrapper("paraworld.homeland.home.Visit", "%MAIN%/API/Home/Visit");
--[[
ClearPug
 KM_Home.API.ClearPug
    /// <summary>
    /// 清除一次家园中的泥巴数
    /// 接收参数：
    ///     nid：当前登录用户的NID
    /// 返回值：
    ///     issuccess
    ///     [ cleared ] 清除了多少个泥巴
    ///     [ errorcode ] 428表示当天已经清除过了
    /// </summary>
    --]]
--]]  
paraworld.create_wrapper("paraworld.homeland.home.ClearPug", "%MAIN%/API/Home/ClearPug");
