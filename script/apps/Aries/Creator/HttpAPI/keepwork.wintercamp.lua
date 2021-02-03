--[[
    Title: keepwork.wintercamp
    Author(s): pbb
    Date: 2021/1/14
    Desc:  
    Use Lib:
    -------------------------------------------------------
    NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.wintercamp.lua");
]]

local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

-- 参加冬令营
--http://yapi.kp-para.cn/project/32/interface/api/3742
HttpWrapper.Create("keepwork.wintercamp.joincamp", "%MAIN%/core/v0/camp/joinCamp", "POST", true)

-- 完成课程
--http://yapi.kp-para.cn/project/32/interface/api/3747
HttpWrapper.Create("keepwork.wintercamp.finishcourse", "%MAIN%/core/v0/camp/finishCourse", "POST", true)

-- 完成证书
--http://yapi.kp-para.cn/project/32/interface/api/3752
HttpWrapper.Create("keepwork.wintercamp.finishcertificate", "%MAIN%/core/v0/camp/finishCertificate", "POST", true)

-- 获取排名
--http://yapi.kp-para.cn/project/32/interface/api/3757
HttpWrapper.Create("keepwork.wintercamp.rank", "%MAIN%/core/v0/camp/schools/rank", "GET", false)

--vip销售的剩余情况
--http://yapi.kp-para.cn/project/32/interface/api/3782
HttpWrapper.Create("keepwork.wintercamp.restvip", "%MAIN%/core/v0/camp/restVip", "GET", false)