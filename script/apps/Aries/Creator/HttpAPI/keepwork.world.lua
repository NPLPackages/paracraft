--[[
Title: keepwork.world
Author(s): leio
Date: 2020/4/23
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.world.lua");
]]
NPL.load("(gl)script/ide/System/localserver/localserver.lua");

local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

--http://yapi.kp-para.cn/project/32/interface/api/1217
-- 获取自己创建的以及参与的世界列表
HttpWrapper.Create("keepwork.world.joined_list", "%MAIN%/core/v0/joinedWorlds", "GET", true)

--http://yapi.kp-para.cn/project/32/interface/api/1082
-- 只包含自己创建的世界，供旧的paracraft客户端使用
HttpWrapper.Create("keepwork.world.worlds_list", "%MAIN%/core/v0/worlds", "GET", true)

--http://yapi.kp-para.cn/project/32/interface/api/3357
-- 获取用户学校大世界
HttpWrapper.Create("keepwork.world.myschoolParaWorld", "%MAIN%/core/v0/3DCampus/my/schoolParaWorld", "GET", true)

--http://yapi.kp-para.cn/project/32/interface/api/3387
-- 获取随机并行世界填充
HttpWrapper.Create("keepwork.world.paraWorldFillings", "%MAIN%/core/v0/3DCampus/paraWorldFillings", "GET", true)

--http://yapi.kp-para.cn/project/32/interface/api/3487
-- 判断是否有权限管理三地世界座位
HttpWrapper.Create("keepwork.world.canManageParaWorldMinis", "%MAIN%/core/v0/3DCampus/canManageParaWorldMinis", "GET", true)

--http://yapi.kp-para.cn/project/32/interface/api/3492
-- 管理3d座位
HttpWrapper.Create("keepwork.world.paraWorldMinis", "%MAIN%/core/v0/3DCampus/paraWorldMinis", "POST", true)

--http://yapi.kp-para.cn/project/32/interface/api/2752
-- 上传paraMini世界
HttpWrapper.Create("keepwork.miniworld.upload", "%MAIN%/core/v0/3DCampus/paraMinis", "POST", true)

--http://yapi.kp-para.cn/project/32/interface/api/3052
-- 获取用户自己的paraMini列表
HttpWrapper.Create("keepwork.miniworld.mylist", "%MAIN%/core/v0/3DCampus/my/paraMinis", "GET", true)

--http://yapi.kp-para.cn/project/32/interface/api/2762
-- 获取paraMini世界列表
HttpWrapper.Create("keepwork.miniworld.list", "%MAIN%/core/v0/3DCampus/paraMinis", "GET", true)

--http://yapi.kp-para.cn/project/32/interface/api/2837
-- 获取我的paraWorld列表
-- 第一个世界为用户默认的世界
HttpWrapper.Create("keepwork.world.mylist", "%MAIN%/core/v0/3DCampus/my/paraWorlds", "GET", true)

--http://yapi.kp-para.cn/project/32/interface/api/2772
-- 获取paraWorld列表
HttpWrapper.Create("keepwork.world.list", "%MAIN%/core/v0/3DCampus/paraWorldsList", "GET", true)

--http://yapi.kp-para.cn/project/32/interface/api/2832
-- 获取单个paraWorld
HttpWrapper.Create("keepwork.world.get", "%MAIN%/core/v0/3DCampus/paraWorlds/:id", "GET", true)

--http://yapi.kp-para.cn/project/32/interface/api/2822
-- paraWorld锁座
--HttpWrapper.Create("keepwork.world.lock_seat", "%MAIN%/core/v0/3DCampus/paraWorlds/sites/lock", "POST", true)

--http://yapi.kp-para.cn/project/32/interface/api/2827
-- paraWorld解锁座
--HttpWrapper.Create("keepwork.world.unlock_seat", "%MAIN%/core/v0/3DCampus/paraWorlds/sites/unlock", "POST", true)

--http://yapi.kp-para.cn/project/32/interface/api/2807
-- paraWorld占座
HttpWrapper.Create("keepwork.world.take_seat", "%MAIN%/core/v0/3DCampus/paraWorlds/sites", "POST", true)

--http://yapi.kp-para.cn/project/32/interface/api/2812
-- paraWorld离座
HttpWrapper.Create("keepwork.world.leave_seat", "%MAIN%/core/v0/3DCampus/paraWorlds/sites", "DELETE", true)

--http://yapi.kp-para.cn/project/32/interface/api/2817
-- 提交paraWorld申请
HttpWrapper.Create("keepwork.world.apply", "%MAIN%/core/v0/3DCampus/paraWorlds/apply", "POST", true)

--http://yapi.kp-para.cn/project/32/interface/api/2777
-- 点赞paraMini
HttpWrapper.Create("keepwork.miniworld.like", "%MAIN%/core/v0/3DCampus/paraMiniStars", "POST", true)

--http://yapi.kp-para.cn/project/32/interface/api/2782
-- 取消点赞paraMini
HttpWrapper.Create("keepwork.miniworld.unlike", "%MAIN%/core/v0/3DCampus/paraMiniStars/:paraMiniId", "DELETE", true)

--http://yapi.kp-para.cn/project/32/interface/api/2787
-- 判断是否点过赞paraMini
HttpWrapper.Create("keepwork.miniworld.is_liked", "%MAIN%/core/v0/3DCampus/paraMiniStars/search", "POST", true)

--http://yapi.kp-para.cn/project/32/interface/api/2792
-- 点赞paraWorld
HttpWrapper.Create("keepwork.world.like", "%MAIN%/core/v0/3DCampus/paraWorldStars", "POST", true)

--http://yapi.kp-para.cn/project/32/interface/api/2797
-- 取消点赞paraWorld
HttpWrapper.Create("keepwork.world.unlike", "%MAIN%/core/v0/3DCampus/paraWorldStars/:paraWorldId", "DELETE", true)

--http://yapi.kp-para.cn/project/32/interface/api/2802
-- 判断是否点赞过paraWorld
HttpWrapper.Create("keepwork.world.is_liked", "%MAIN%/core/v0/3DCampus/paraWorldStars/search", "POST", true)


