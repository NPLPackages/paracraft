--[[
Title: keepwork.rawfile
Author(s): leio
Date: 2020/7/16
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.rawfile.lua");
]]

local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");


--http://yapi.kp-para.cn/project/32/interface/api/452
--https://api.keepwork.com/core/v0/repos/zhanglei%2Fempty/files/zhanglei%2Fempty%2Ftest%2Emd
HttpWrapper.Create("keepwork.rawfile.get", "%MAIN%/core/v0/repos/:repoPath/files/:filePath", "GET", false, nil,
-- PreProcessor
HttpWrapper.default_prepFunc,
-- Post Processor
HttpWrapper.default_postFunc
)

--http://cdn.keepwork.com/NplCadCodeLib/nplcad3/assetList.json
HttpWrapper.Create("nplcad3.asset.get", "cdn.keepwork.com/NplCadCodeLib/nplcad3/:filepath", "GET", false, nil,
-- PreProcessor
HttpWrapper.default_prepFunc,
-- Post Processor
HttpWrapper.default_postFunc
)


