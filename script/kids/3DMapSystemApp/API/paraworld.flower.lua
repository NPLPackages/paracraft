--[[
Title: flower info
Author(s): Leio
Date: 2008/2/25
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/paraworld.flower.lua");
-------------------------------------------------------
]]

-- create class
commonlib.setfield("paraworld.flower", {});

--[[
Add
    /// 接收参数：
    ///     sessionkey
    ///     flowertype
    ///     [ format ]  int  返回的数据格式（0:XML 1:JSON），默认值为0

--]]
paraworld.CreateRESTJsonWrapper("paraworld.flower.Add", "http://appflower.test.pala5.cn/Add");
--[[
Delete
    /// 接收参数：
    ///     sessionkey
    ///     [ format ]  int  返回的数据格式（0:XML 1:JSON），默认值为0

--]]
paraworld.CreateRESTJsonWrapper("paraworld.flower.Delete", "http://appflower.test.pala5.cn/Delete");
--[[
Get
    /// 接收参数：
    ///     uid：花所有者的用户ID
    ///     [ format ]  int  返回的数据格式（0:XML 1:JSON），默认值为0
--]]
paraworld.CreateRESTJsonWrapper("paraworld.flower.Get", "http://appflower.test.pala5.cn/Get");
--[[
Store
    /// 接收参数：
    ///     sessionkey
    ///     cnt  int  摘了多少个果实
    ///     [ format ]  int  返回的数据格式（0:XML 1:JSON），默认值为0
--]]
paraworld.CreateRESTJsonWrapper("paraworld.flower.Store", "http://appflower.test.pala5.cn/Store");
--[[
Water
    /// 接收参数：
    ///     sessionkey
    ///     [ format ]  int  返回的数据格式（0:XML 1:JSON），默认值为0
--]]  
paraworld.CreateRESTJsonWrapper("paraworld.flower.Water", "http://appflower.test.pala5.cn/Water");