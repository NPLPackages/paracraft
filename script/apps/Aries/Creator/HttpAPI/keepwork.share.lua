--[[
Title: keepwork.share
Author(s): leio
Date: 2020/4/22
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.share.lua");
http://api-dev.kp-para.cn/storage/v0/qinius/uploadToken
]]
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

--http://yapi.kp-para.cn/project/151/interface/api/1967
-- get
HttpWrapper.Create("keepwork.shareToken.get", "%MAIN%/ts-storage/qinius/uploadToken", "GET", true, nil,
-- PreProcessor
HttpWrapper.default_prepFunc,
-- Post Processor
HttpWrapper.default_postFunc
)

--http://yapi.kp-para.cn/project/151/interface/api/1982
-- get
HttpWrapper.Create("keepwork.shareUrl.get", "%MAIN%/ts-storage/files/downloadUrl", "GET", true)

--http://yapi.kp-para.cn/project/32/interface/api/1872
-- get
HttpWrapper.Create("keepwork.shareFile.post", "%MAIN%/core/v0/shareFile", "POST", true)
