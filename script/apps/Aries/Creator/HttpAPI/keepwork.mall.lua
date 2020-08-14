--[[
Title: keepwork.mall
Author(s): leio
Date: 2020/7/14
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.mall.lua");
]]
NPL.load("(gl)script/ide/System/localserver/localserver.lua");

local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

local getInfo_cache_policy = System.localserver.CachePolicy:new("access plus 1 day");

--http://yapi.kp-para.cn/project/32/interface/api/2447
local api_name = "keepwork.mall.menus.get";
HttpWrapper.Create(api_name, "%MAIN%/core/v0/mall/classifies", "GET", false)

--http://yapi.kp-para.cn/project/32/interface/api/2452
HttpWrapper.Create("keepwork.mall.goods.get", "%MAIN%/core/v0/mall/products", "GET", false)

--http://yapi.kp-para.cn/project/32/interface/api/2457
HttpWrapper.Create("keepwork.mall.buy", "%MAIN%/core/v0/mall/products/buy", "POST", true)

--http://yapi.kp-para.cn/project/32/interface/api/2727
HttpWrapper.Create("keepwork.mall.orderResule", "%MAIN%/core/v0/mall/mOrders/", "GET", false)