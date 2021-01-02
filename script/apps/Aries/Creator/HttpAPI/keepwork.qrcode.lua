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