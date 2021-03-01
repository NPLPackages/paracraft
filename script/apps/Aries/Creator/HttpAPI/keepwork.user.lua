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

-- 查询
HttpWrapper.Create("keepwork.user.search", "%MAIN%/core/v0/users/search", "POST", true)

-- 是否关注(多人)
HttpWrapper.Create("keepwork.user.focus", "%MAIN%/core/v0/favorites/search", "POST", true)

-- 获取作品列表
HttpWrapper.Create("keepwork.user.projects", "%MAIN%/core/v0/projects", "GET", true)

--http://yapi.kp-para.cn/project/32/interface/api/947
-- 新增举报投诉
HttpWrapper.Create("keepwork.user.complain", "%MAIN%/core/v0/feedbacks", "POST", true)

--http://yapi.kp-para.cn/project/32/interface/api/3127
-- 获取用户的禁言状态
HttpWrapper.Create("keepwork.user.mutings", "%MAIN%/core/v0/mutings", "GET", true)

--http://yapi.kp-para.cn/project/158/interface/api/2262
-- 活动列表
HttpWrapper.Create("keepwork.user.activity_list", "%MAIN%/online-quiz/v0/activity/home", "GET", false,nil,
-- PreProcessor
HttpWrapper.default_prepFunc,
-- Post Processor
HttpWrapper.default_postFunc
)


--http://yapi.kp-para.cn/project/32/interface/api/3212
-- 使用兑换码激活会员
HttpWrapper.Create("keepwork.user.takevip_bycode", "%MAIN%/core/v0/promoCodes/use", "POST", true)

--http://yapi.kp-para.cn/project/32/interface/api/3702
-- 获取服务器时间
HttpWrapper.Create("keepwork.user.server_time", "%MAIN%/core/v0/keepworks/currentTime", "GET", true)

-- 生成小程序码的图片
-- http://yapi.kp-para.cn/project/32/interface/api/3772
HttpWrapper.Create("keepwork.user.bindWxacode", "%MAIN%/core/v0/users/bindWxacode","POST",true)

-- 获取总学校 机构数
-- http://yapi.kp-para.cn/project/130/interface/api/3812
HttpWrapper.Create("keepwork.user.total_orgs", "%MAIN%/accounting/org/totalOrgs","GET",true)

-- 用户荣誉列表
-- http://yapi.kp-para.cn/project/32/interface/api/3817
HttpWrapper.Create("keepwork.user.honors", "%MAIN%/core/v0/users/honors","GET",true);

-- 获取socketio地址
-- http://yapi.kp-para.cn/project/60/interface/api/3862
HttpWrapper.Create("keepwork.app.availableHost", "%MAIN%/core/v0/app/availableHost","GET",true);