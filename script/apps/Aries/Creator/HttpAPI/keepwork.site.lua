--[[
Title: keepwork.site
Author(s): big
Date: 2025/6/3
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.site.lua");
]]

local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

-- 获取个人网站列表
HttpWrapper.Create("keepwork.site.getAllSites", "%MAIN%/core/v0/sites", "GET", true)

-- 根据用户ID获取个人网站列表
HttpWrapper.Create("keepwork.site.getAllSitesByName", "%MAIN%/core/v0/users/:id/sites", "GET", true)

-- https://yapi.kp-para.cn/project/32/interface/api/722
-- 新建网站
-- {router_params = { projectName = replacement, path = path, recursive = true }},
HttpWrapper.Create("keepwork.site.upsert", "%MAIN%/core/v0/sites", "POST", true)

-- https://yapi.kp-para.cn/project/32/interface/api/437
-- 获取项目文件列表
HttpWrapper.Create("keepwork.site.tree", "%MAIN%/core/v0/repos/:repoPath/tree?folderPath=:folderPath&recursive=:recursive", "GET", true)

-- https://yapi.kp-para.cn/project/32/interface/api/447
-- 获取文件信息
HttpWrapper.Create("keepwork.site.getFileInfo", "%MAIN%/core/v0/repos/:repoPath/files/:filePath/info", "GET", true)

-- https://yapi.kp-para.cn/project/32/interface/api/477
-- 创建文件夹
HttpWrapper.Create("keepwork.site.createFolder", "%MAIN%/core/v0/repos/:repoPath/folders/:folderPath", "POST", true)

-- https://yapi.kp-para.cn/project/32/interface/api/462
-- 添加文件
-- {router_params = { repoPath = repoPath, filePath = filePath }, content = "ddd"}
HttpWrapper.Create("keepwork.site.addFile", "%MAIN%/core/v0/repos/:repoPath/files/:filePath", "POST", true)

-- https://yapi.kp-para.cn/project/32/interface/api/512
-- 更新文件
HttpWrapper.Create("keepwork.site.editFile", "%MAIN%/core/v0/repos/:repoPath/files/:filePath", "PUT", true)

-- https://yapi.kp-para.cn/project/32/interface/api/1012
-- 获取文件内容
HttpWrapper.Create("keepwork.site.getFile", "%MAIN%/core/v0/repos/:repoPath/files/:filePath", "GET", true)

-- https://yapi.kp-para.cn/project/32/interface/api/467
-- 删除文件
HttpWrapper.Create("keepwork.site.removeFile", "%MAIN%/core/v0/repos/:repoPath/files/:filePath", "DELETE", true)

-----------------------------PageCache---------------------------
--https://yapi.kp-para.cn/project/32/interface/api/8191
--PageCache获取文件
HttpWrapper.Create("keepwork.site.getFileFromCache", "%MAIN%/core/v0/pageCache/:repoPath/files/:filePath", "GET", true)

--https://yapi.kp-para.cn/project/32/interface/api/8198
--PageCache新增/更新文件
HttpWrapper.Create("keepwork.site.upsertFileCache", "%MAIN%/core/v0/pageCache/:repoPath/files/:filePath", "PUT", true)

--https://yapi.kp-para.cn/project/32/interface/api/8205
--PageCache清除缓存
HttpWrapper.Create("keepwork.site.removeFileFromCache", "%MAIN%/core/v0/pageCache/:repoPath/files/:filePath/purge", "DELETE", true)
