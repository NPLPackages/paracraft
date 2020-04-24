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

--http://yapi.kp-para.cn/project/109/interface/api/cat_292
-- get
HttpWrapper.Create("keepwork.bags", "%MAIN%/gosys/v0/bags")
-- create
HttpWrapper.Create("keepwork.bags.create", "%MAIN%/bags", "POST")
-- update
HttpWrapper.Create("keepwork.bags.update", "%MAIN%/bags", "POST")
-- delete
HttpWrapper.Create("keepwork.bags.delete", "%MAIN%/bags", "POST")

--http://yapi.kp-para.cn/project/109/interface/api/cat_282
-- get
HttpWrapper.Create("keepwork.goods", "%MAIN%/goods", "GET")
-- create
HttpWrapper.Create("keepwork.goods.create", "%MAIN%/goods", "POST")
-- update
HttpWrapper.Create("keepwork.goods.update", "%MAIN%/goods", "POST")
-- delete
HttpWrapper.Create("keepwork.goods.delete", "%MAIN%/goods", "POST")
