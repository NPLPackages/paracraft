--[[
Title: keepwork.user
Author(s): leio
Date: 2020/4/23
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.user.lua");
]]
NPL.load("(gl)script/ide/System/localserver/localserver.lua");

local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

--http://yapi.kp-para.cn/project/32/interface/api/cat_97
HttpWrapper.Create("keepwork.user.login", "%MAIN%/core/v0/users/login", "POST", false)

--http://yapi.kp-para.cn/project/32/interface/api/492
HttpWrapper.Create("keepwork.user.profile", "%MAIN%/core/v0/users/profile", "GET", true)

-- https://api.keepwork.com/core/v0/users/3   更新用户信息
HttpWrapper.Create("keepwork.user.setinfo", "%MAIN%/core/v0/users/:id", "PUT", true);

--http://yapi.kp-para.cn/project/32/interface/api/2552
HttpWrapper.Create("keepwork.user.getinfo", "%MAIN%/core/v0/users/:id/detail", "GET", true, nil,
-- PreProcessor
HttpWrapper.default_prepFunc,
-- Post Processor
HttpWrapper.default_postFunc
)

--http://yapi.kp-para.cn/project/32/interface/api/2477
HttpWrapper.Create("keepwork.user.school", "%MAIN%/core/v0/users/school", "GET", true)

-- 用户是否关注, 关注, 取消关注
-- https://api.keepwork.com/core/v0/favorites/exist?objectId=3&objectType=0
HttpWrapper.Create("keepwork.user.isfollow", "%MAIN%/core/v0/favorites/exist", "GET", true);
HttpWrapper.Create("keepwork.user.follow", "%MAIN%/core/v0/favorites", "POST", true);
HttpWrapper.Create("keepwork.user.unfollow", "%MAIN%/core/v0/favorites", "DELETE", true);


--http://yapi.kp-para.cn/project/32/interface/api/2892
-- 获取用户好友
HttpWrapper.Create("keepwork.user.friends", "%MAIN%/core/v0/users/friends", "GET", true)

--http://yapi.kp-para.cn/project/32/interface/api/2887
-- 获取用户关注
HttpWrapper.Create("keepwork.user.following", "%MAIN%/core/v0/users/following", "GET", true)

--http://yapi.kp-para.cn/project/32/interface/api/2882
-- 获取用户粉丝
HttpWrapper.Create("keepwork.user.followers", "%MAIN%/core/v0/users/followers", "GET", true)