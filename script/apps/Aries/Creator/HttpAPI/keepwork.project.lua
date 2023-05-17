
--[[
Title: keepwork.project
Author(s): wxa
Date: 2020/7/14
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.project.lua");
]]

local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

-- https://api.keepwork.com/core/v0/projects?userId=3
HttpWrapper.Create("keepwork.project.list", "%MAIN%/core/v0/projects", "GET", true);

--https://api.keepwork.com/core/v0/projects/favorite
HttpWrapper.Create("keepwork.project.list_favorite", "%MAIN%/core/v0/projects/favorite", "GET", true);

--http://yapi.kp-para.cn/project/32/interface/api/3667
HttpWrapper.Create("keepwork.project.favorite_search", "%MAIN%/core/v0/favorites/search", "POST", true);

--http://yapi.kp-para.cn/project/32/interface/api/2767
--更新项目
HttpWrapper.Create("keepwork.project.update", "%MAIN%/core/v0/projects/:id", "PUT", true);

--http://yapi.kp-para.cn/project/32/interface/api/752
--获得项目信息
HttpWrapper.Create("keepwork.project.get", "%MAIN%/core/v0/projects/:id/detail", "GET", true);


--世界相关
--http://yapi.kp-para.cn/project/32/interface/api/1217
--获取所有参与的世界
HttpWrapper.Create("keepwork.project.worldlist", "%MAIN%/core/v0/joinedWorlds", "GET", true);

--http://yapi.kp-para.cn/project/32/interface/api/1082
--获取world列表，自己创建的世界 只包含自己创建的世界，供旧的paracraft客户端使用
HttpWrapper.Create("keepwork.project.authworlds", "%MAIN%/core/v0/worlds", "GET", true);

--http://yapi.kp-para.cn/project/32/interface/api/2512
--获取world列表_internal
HttpWrapper.Create("keepwork.project.internalworlds", "%MAIN%/core/v0/internal/worlds", "GET", true);

--http://yapi.kp-para.cn/project/655/interface/api/5642
--上传世界后上报课堂小节内容记录
--[[Body: 数据存在tag.xml中
classroomId	number	必须 课堂id
sectionContentId	number	必须 小节内容id
status	number	非必须 完成状态: 1.完成	
projectId	number	非必须 世界id]]
HttpWrapper.Create("keepwork.edu.updateSectionContents", "%MAIN%/edu/v0/classroomStudents/sectionContents", "POST", true);

--获取可用容量
--http://yapi.kp-para.cn/project/655/interface/api/5823
HttpWrapper.Create("keepwork.world.gettotalsize", "%MAIN%/edu/v0/users/onlineDisks", "GET", true);

--可用容量-检查是否可以上传
if System.options.isPapaAdventure then
    --[[fileSize]]
    --http://yapi.kp-para.cn/project/1952/interface/api/5946
    HttpWrapper.Create("keepwork.world.checkupload", "%MAIN%/client-marketing/users/onlineDisks/check", "GET", true);
else
    --http://yapi.kp-para.cn/project/655/interface/api/5824
    --[[projectId	无projectId则为创建新世界 fileSize]]
    HttpWrapper.Create("keepwork.world.checkupload", "%MAIN%/edu/v0/users/onlineDisks/check", "GET", true);
end