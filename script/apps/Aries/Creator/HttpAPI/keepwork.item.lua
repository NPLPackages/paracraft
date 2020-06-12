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
function(self, inputParams, callbackFunc, option)
   return HttpWrapper.default_prepFunc(self, inputParams, callbackFunc, option, "keepwork.globalstore.get")
end,
-- Post Processor
function(self, err, msg, data)
    return HttpWrapper.default_postFunc(self, err, msg, data, "keepwork.globalstore.get", callbackFunc); 
end
)

--http://yapi.kp-para.cn/project/109/interface/api/cat_327
-- get
HttpWrapper.Create("keepwork.extendedcost.get", "%MAIN%/gosys/v0/exchangeRules", "GET", true, nil,
-- PreProcessor
function(self, inputParams, callbackFunc, option)
   return HttpWrapper.default_prepFunc(self, inputParams, callbackFunc, option, "keepwork.extendedcost.get")
end,
-- Post Processor
function(self, err, msg, data)
    return HttpWrapper.default_postFunc(self, err, msg, data, "keepwork.extendedcost.get", callbackFunc); 
end
)

--http://yapi.kp-para.cn/project/109/interface/api/cat_292
-- get
HttpWrapper.Create("keepwork.bags.get", "%MAIN%/gosys/v0/bags", "GET", true, nil,
-- PreProcessor
function(self, inputParams, callbackFunc, option)
   return HttpWrapper.default_prepFunc(self, inputParams, callbackFunc, option, "keepwork.bags.get")
end,
-- Post Processor
function(self, err, msg, data)
    return HttpWrapper.default_postFunc(self, err, msg, data, "keepwork.bags.get", callbackFunc); 
end)

--http://yapi.kp-para.cn/project/109/interface/api/cat_337
-- get
HttpWrapper.Create("keepwork.items.get", "%MAIN%/gosys/v0/userGoods", "GET", true, nil,
-- PreProcessor
function(self, inputParams, callbackFunc, option)
   return HttpWrapper.default_prepFunc(self, inputParams, callbackFunc, option, "keepwork.items.get")
end,
-- Post Processor
function(self, err, msg, data)
    return HttpWrapper.default_postFunc(self, err, msg, data, "keepwork.items.get", callbackFunc); 
end
)

--http://yapi.kp-para.cn/project/109/interface/api/1392
-- post
HttpWrapper.Create("keepwork.items.exchange", "%MAIN%/gosys/v0/exchange", "POST", true, nil,
-- PreProcessor
function(self, inputParams, callbackFunc, option)
    -- no cache
    inputParams.cache_policy = "access plus 0"
   return HttpWrapper.default_prepFunc(self, inputParams, callbackFunc, option, "keepwork.items.exchange")
end,
-- Post Processor
function(self, err, msg, data)
    return HttpWrapper.default_postFunc(self, err, msg, data, "keepwork.items.exchange", callbackFunc); 
end
)

--http://yapi.kp-para.cn/project/109/interface/api/1397
-- get
HttpWrapper.Create("keepwork.items.checkExchange", "%MAIN%/gosys/v0/checkExchange", "GET", true, nil,
-- PreProcessor
function(self, inputParams, callbackFunc, option)
    -- no cache
    inputParams.cache_policy = "access plus 0"
   return HttpWrapper.default_prepFunc(self, inputParams, callbackFunc, option, "keepwork.items.checkExchange")
end,
-- Post Processor
function(self, err, msg, data)
    return HttpWrapper.default_postFunc(self, err, msg, data, "keepwork.items.checkExchange", callbackFunc); 
end
)

--http://yapi.kp-para.cn/project/109/interface/api/1472
-- put
HttpWrapper.Create("keepwork.items.setClientData", "%MAIN%/gosys/v0/userGoods/clientData", "PUT", true, nil,
-- PreProcessor
function(self, inputParams, callbackFunc, option)
    -- no cache
    inputParams.cache_policy = "access plus 0"
   return HttpWrapper.default_prepFunc(self, inputParams, callbackFunc, option, "keepwork.items.setClientData")
end,
-- Post Processor
function(self, err, msg, data)
    return HttpWrapper.default_postFunc(self, err, msg, data, "keepwork.items.setClientData", callbackFunc); 
end
)

--http://yapi.kp-para.cn/project/109/interface/api/1467
-- get
HttpWrapper.Create("keepwork.items.getClientData", "%MAIN%/gosys/v0/userGoods/clientData", "GET", true, nil,
-- PreProcessor
function(self, inputParams, callbackFunc, option)
    -- no cache
    inputParams.cache_policy = "access plus 0"
   return HttpWrapper.default_prepFunc(self, inputParams, callbackFunc, option, "keepwork.items.getClientData")
end,
-- Post Processor
function(self, err, msg, data)
    return HttpWrapper.default_postFunc(self, err, msg, data, "keepwork.items.getClientData", callbackFunc); 
end
)
