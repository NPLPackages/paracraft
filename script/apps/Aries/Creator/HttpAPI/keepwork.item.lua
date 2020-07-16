--[[
Title: keepwork.item
Author(s): leio
Date: 2020/4/22
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.item.lua");
]]
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

--http://yapi.kp-para.cn/project/109/interface/api/cat_282
-- get
HttpWrapper.Create("keepwork.globalstore.get", "%MAIN%/gosys/v0/goods", "GET", true, nil,

-- PreProcessor
HttpWrapper.default_prepFunc,
-- Post Processor
HttpWrapper.default_postFunc

)

--http://yapi.kp-para.cn/project/109/interface/api/cat_327
-- get
HttpWrapper.Create("keepwork.extendedcost.get", "%MAIN%/gosys/v0/exchangeRules", "GET", true, nil,

-- PreProcessor
HttpWrapper.default_prepFunc,
-- Post Processor
HttpWrapper.default_postFunc

)

--http://yapi.kp-para.cn/project/109/interface/api/cat_292
-- get
HttpWrapper.Create("keepwork.bags.get", "%MAIN%/gosys/v0/bags", "GET", true)

--http://yapi.kp-para.cn/project/109/interface/api/cat_337
-- get
HttpWrapper.Create("keepwork.items.get", "%MAIN%/gosys/v0/userGoods", "GET", true)

--http://yapi.kp-para.cn/project/109/interface/api/1392
-- post
HttpWrapper.Create("keepwork.items.exchange", "%MAIN%/gosys/v0/exchange", "POST", true)

--http://yapi.kp-para.cn/project/109/interface/api/1397
-- get
HttpWrapper.Create("keepwork.items.checkExchange", "%MAIN%/gosys/v0/checkExchange", "GET", true)

--http://yapi.kp-para.cn/project/109/interface/api/1472
-- put
HttpWrapper.Create("keepwork.items.setClientData", "%MAIN%/gosys/v0/userGoods/clientData", "PUT", true)

--http://yapi.kp-para.cn/project/109/interface/api/1467
-- get
HttpWrapper.Create("keepwork.items.getClientData", "%MAIN%/gosys/v0/userGoods/clientData", "GET", true)
