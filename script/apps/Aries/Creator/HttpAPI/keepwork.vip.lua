--[[
Title: keepwork.vip
Author(s): leio
Date: 2021/7/9
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.vip.lua");
]]
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

-- 获取商品信息
--http://yapi.kp-para.cn/project/32/interface/api/3687
-- post
HttpWrapper.Create("keepwork.pay.searchVipProducts", "%MAIN%/core/v0/pay/systemProducts/search", "POST", true)


-- 获取订单对象
-- 发起支付完成后，要轮询去获取订单的状态，当订单的状态 state 等于 2 或者3时即认为支付成功，前端再做后续的处理
--http://yapi.kp-para.cn/project/32/interface/api/1512
-- get
HttpWrapper.Create("keepwork.pay.systemOrders", "%MAIN%/core/v0/pay/systemOrders/:id", "GET", true)

-- 购买c端vip
--http://yapi.kp-para.cn/project/32/interface/api/1527
-- post
HttpWrapper.Create("keepwork.pay.clientVip", "%MAIN%/core/v0/pay/clientVip", "POST", true)


-- 请求二维码的输入参数
--http://yapi.kp-para.cn/project/88/interface/api/4302
-- 生成二维码
--http://yapi.kp-para.cn/project/32/interface/api/3682
-- post 
HttpWrapper.Create("keepwork.pay.generateQR", "%MAIN%/core/v0/keepworks/generateQR", "POST", true)