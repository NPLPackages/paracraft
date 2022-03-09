--[[
    Title: keepwork.qrcode
    Author(s): pbb
    Date: 2020/12/24
    Desc:  
    Use Lib:
    -------------------------------------------------------
    NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.qrcode.lua");
]]

local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

-- 生产二维码图片
--http://yapi.kp-para.cn/project/32/interface/api/3682 
HttpWrapper.Create("keepwork.qrcode.generateQR", "%MAIN%/core/v0/keepworks/generateQR", "POST", true)

--[[
    生成的二维码图片是base64格式的图片数据，我们首先使用base64解码图片数据，
    然后将字符流写入到一个png文件当中，最后使用这个png文件渲染二维码图片
]]

-- 兑换Vip
-- http://yapi.kp-para.cn/project/130/interface/api/3077
HttpWrapper.Create("keepwork.paracraftVipCode.activate", "%MAIN%/accounting/paracraftVipCode/activate", "POST", true)

-- 兑换vip ,带英文字母
--http://10.28.18.44:3001/project/32/interface/api/4719
HttpWrapper.Create("keepwork.activateCodes.activate", "%MAIN%/core/v0/activateCodes/activate", "POST", true)


-- 兑换机构激活码
-- http://yapi.kp-para.cn/project/130/interface/api/3047
HttpWrapper.Create("keepwork.orgActivateCode.activate", "%MAIN%/accounting/orgActivateCode/activate", "POST", true)