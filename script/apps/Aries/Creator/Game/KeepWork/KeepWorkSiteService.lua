--[[
Title: keepwork site service
Author(s): big
Date: 2025/6/4
Desc: script/apps/Aries/Creator/Game/KeepWork/KeepWorkSiteService.lua
Use Lib:
-------------------------------------------------------
local KeepworkSiteService = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/KeepWorkSiteService.lua");
KeepworkSiteService:AutoCreateSite("b3332/bbb/yyy/ccsccd", function(commitId) echo({ "commitId", commitId }) end)
KeepworkSiteService:EditMarkdownByFullPath("b3332/bbb/yyy/ccsccd", "9999", function(data) echo({ "data", data }) end)
KeepworkSiteService:GetMarkdownByFullPath("b3332/bbb/yyy/ccsccd", function(data) echo({ "data", data }) end)
KeepworkSiteService:DeleteMarkdownByFullPath("b3332/bbb/yyy/ccsccd", function(data) echo({ "data", data }) end)
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.site.lua");

local KeepworkSiteService = commonlib.inherit(nil, NPL.export());

KeepworkSiteService.personalSiteList = {};

function KeepworkSiteService:ctor()
    self.firstCreateSite = false; -- 是否第一次创建站点
    self.personalSiteList = {}; -- 个人站点列表

    local path = self.params and self.params.path or '';
    local parts = {};
    for part in string.gmatch(path, "[^/]+") do
        table.insert(parts, part);
    end

    if #parts == 0 then
        _guihelper.MessageBox("路径不能为空");
        return;
    end

    self.sitename = parts[1];
    self.folders = {};
    self.filename = nil;

    if #parts > 1 then
        -- The last part is the filename
        self.filename = parts[#parts];
        -- Folders are the parts between the sitename and the filename
        for i = 2, #parts - 1 do
            table.insert(self.folders, parts[i]);
        end
    end

    -- 检查是否以 .md 结尾，如果不是则加上
    if not string.match(path, "%.md$") then
        path = path .. ".md"
    end
    self.fullPath = path;

    return self;
end

-- 便捷方法：创建站点并创建文件夹和markdown
-- path 可以是 "mysite/folder/file.md" 或 "mysite/folder/file"（会自动加上 .md 后缀）
function KeepworkSiteService:AutoCreateSite(path, callback)
    local self = KeepworkSiteService:new({params = { path = path }});
    callback = callback or function() end;

    -- 创建站点
    self:CreateNewSite(self.sitename, function()
        -- 创建文件夹
        if #self.folders > 0 then
            self:CreateFolder(self.sitename, self.folders, function()
                -- 创建markdown
                self:CreateMarkdown(self.sitename, self.fullPath, callback);
            end);
        else
            -- 创建markdown
            self:CreateMarkdown(self.sitename, self.fullPath, callback);
        end
    end);
end

function KeepworkSiteService:IsUserStorePath()
    return self.sitename and self.sitename == "edunotes";
end

-- 便捷方法：只传 path（如 "mysite/folder/file.md"）
function KeepworkSiteService:EditMarkdownByFullPath(path, content, callback, bUseCache)
    local self = KeepworkSiteService:new({params = { path = path }});
    callback = callback or function() end;
    if bUseCache then
        local isUserStore = self:IsUserStorePath();
        if isUserStore then
            self:UpsertMarkdownToCache(self.sitename, self.fullPath, content, callback);
        else
            self:GetFileInfo(self.sitename, self.fullPath, function(data)
                if data.err and (data.err == 500 or data.err == 404) then
                    self:AutoCreateSite(self.fullPath, function(commitId)
                        self:UpsertMarkdownToCache(self.sitename, self.fullPath, content, callback)
                    end)
                    return
                end
                self:UpsertMarkdownToCache(self.sitename, self.fullPath, content, callback)
            end)
        end
        return
    end
    self:EditMarkdown(self.sitename, self.fullPath, content, function(data)
        if data.err and data.err == 404 then
            self:AutoCreateSite(self.fullPath, function(commitId)
                self:EditMarkdown(self.sitename, self.fullPath, content, callback)
            end)
            return
        end
        callback(data)
    end)
end

-- 便捷方法：获取markdown内容
-- path 可以是 "mysite/folder/file.md" 或 "mysite/folder/file"（会自动加上 .md 后缀）
-- @param path: string - Page path
-- @param callback: function(data) - Callback
-- @param bUseCache: boolean - Use page cache API
-- @param username: string|nil - Override username (for cross-user access). nil = current user.
-- @return data string
function KeepworkSiteService:GetMarkdownByFullPath(path, callback, bUseCache, username)
    local self = KeepworkSiteService:new({params = { path = path }});
    callback = callback or function() end;
    if bUseCache then
        self:GetMarkdownFromCache(self.sitename, self.fullPath, callback, username)
        return
    end
    self:GetMarkdown(self.sitename, self.fullPath, callback, username) 
end

-- 便捷方法：删除markdown文件
-- path 可以是 "mysite/folder/file.md" 或 "mysite/folder/file"（会自动加上 .md 后缀）
-- 注意：删除操作是不可逆的，请谨慎使用
-- @return delete result boolean
function KeepworkSiteService:DeleteMarkdownByFullPath(path, callback)
    local self = KeepworkSiteService:new({params = { path = path }});
    callback = callback or function() end;
    self:RemoveMarkdownFromCache(self.sitename, self.fullPath, function()
        self:DeleteMarkdown(self.sitename, self.fullPath, callback)  
    end)
end

function KeepworkSiteService:CreateNewSite(sitename, callback)
    callback = callback or function() end;

    if string.find(sitename, "/") then
        _guihelper.MessageBox("网站名称不能包含 / 字符");
        return;
    end

    self:PersonalSiteList(function()
        for _, site in ipairs(self.personalSiteList) do
            if site.sitename == sitename then
                callback();
                return;
            end
        end

        self.firstCreateSite = true;

        local extra = {
            categoryName = 'Basic',
            type = 'Basic',
            templateName = 'Basic',
            styleName = '默认样式',
            logoUrl = '//keepwork.com/wiki/assets/imgs/wiki_blank_template.png'
        }

        keepwork.site.upsert({ sitename = sitename, visibility = 0, extra = extra}, function(err, msg, data)
            if err ~= 200 then
                LOG.std("KeepworkSiteService", "error", "CreateNewSite", "err: %s, msg: %s, data: %s", err, msg, data);
            end
            callback(data);
        end)
    end);
end

function KeepworkSiteService:PersonalSiteList(callback)
    if not callback then
        return;
    end

    keepwork.site.getAllSites({}, function(err, msg, data)
        KeepworkSiteService.personalSiteList = data or {};
        callback();
    end)
end

function KeepworkSiteService:GetFileInfo(sitename,path, callback)
    local repoPath = System.User.username .. "/" .. sitename;
    repoPath  = Mod.WorldShare.Utils.EncodeURIComponent(repoPath)
    repoPath  = string.gsub(repoPath , "%%", "%%%%")

    local filePath = System.User.username .. "/" .. path;
    filePath = Mod.WorldShare.Utils.EncodeURIComponent(filePath)
    filePath = string.gsub(filePath, "%%", "%%%%")
    
    
    keepwork.site.getFileInfo({ router_params = { repoPath = repoPath, filePath = filePath }}, function(err,msg,data)
        if err ~= 200 then
            LOG.std("KeepworkSiteService", "error", "GetFileInfo", "err: %s, msg: %s, data: %s", err, msg, data);
        end
        callback({err = err, msg = msg, data = data});
    end)
end


function KeepworkSiteService:CreateFolder(sitename, folders, callback)
    callback = callback or function() end;
    local folderPath = System.User.username .. "/" .. sitename;
    local repoPath  = Mod.WorldShare.Utils.EncodeURIComponent(folderPath)
    repoPath  = string.gsub(repoPath , "%%", "%%%%")

    local function handle(data)
        -- 判断并递归创建缺失的文件夹
        local function find_child(children, name)
            if not children then return nil end
            for _, v in ipairs(children) do
                if v.name == name and v.isTree then
                    return v
                end
            end
            return nil
        end

        local cur = { children = data }
        local cur_path = ""
        local need_create = false
        local create_paths = {}
        for i, folder in ipairs(folders) do
            local next_node = find_child(cur.children, folder)
            if i == 1 then
                cur_path = folder
            else
                cur_path = cur_path .. "/" .. folder
            end

            if not next_node then
                need_create = true
            end
            if need_create then
                table.insert(create_paths, cur_path)
            end
            cur = next_node or { children = nil }
        end
        -- 依次创建缺失的文件夹
        local function create_next(idx)
            if idx > #create_paths then
                callback();
                return
            end
            local folderPath = Mod.WorldShare.Utils.EncodeURIComponent(folderPath .. "/" .. create_paths[idx])
            folderPath  = string.gsub(folderPath , "%%", "%%%%")
            keepwork.site.createFolder({ router_params = { repoPath = repoPath, folderPath = folderPath } }, function()
                create_next(idx + 1)
            end)
        end
        if #create_paths > 0 then
            create_next(1)
        else
            callback();
        end
    end

    if (self.firstCreateSite) then
        handle({}) -- 如果是第一次创建站点，直接返回空数据
    else
        keepwork.site.tree({router_params = { repoPath = repoPath, folderPath = folderPath, recursive = true }}, function(err, msg, data)
            if err ~= 200 then
                LOG.std("KeepworkSiteService", "error", "CreateFolder", "err: %s, msg: %s, data: %s", err, msg, data);
                data = {};
            end
            handle(data)
        end)
    end
end

function KeepworkSiteService:CreateMarkdown(sitename, path, callback)
    callback = callback or function() end;
    local repoPath = System.User.username .. "/" .. sitename;
    repoPath  = Mod.WorldShare.Utils.EncodeURIComponent(repoPath)
    repoPath  = string.gsub(repoPath , "%%", "%%%%")

    local filePath = System.User.username .. "/" .. path;
    filePath = Mod.WorldShare.Utils.EncodeURIComponent(filePath)
    filePath = string.gsub(filePath, "%%", "%%%%")
    keepwork.site.addFile({router_params = { repoPath = repoPath, filePath = filePath }, content = ""}, function(err, msg, data)
        callback(data)
    end)
end

function KeepworkSiteService:EditMarkdown(sitename, path, content, callback)
    callback = callback or function() end;
    local repoPath = System.User.username .. "/" .. sitename;
    repoPath  = Mod.WorldShare.Utils.EncodeURIComponent(repoPath)
    repoPath  = string.gsub(repoPath , "%%", "%%%%")

    local filePath = System.User.username .. "/" .. path;
    filePath = Mod.WorldShare.Utils.EncodeURIComponent(filePath)
    filePath = string.gsub(filePath, "%%", "%%%%")
    keepwork.site.editFile({router_params = { repoPath = repoPath, filePath = filePath }, content = content}, function(err, msg, data)
        if err ~= 200 then
            callback({err = err,data = data})
            return
        end
        callback(data)
    end)
end

function KeepworkSiteService:GetMarkdown(sitename, path, callback, username)
    callback = callback or function() end;
    username = username or System.User.username;
    local repoPath = username .. "/" .. sitename;
    repoPath  = Mod.WorldShare.Utils.EncodeURIComponent(repoPath)
    repoPath  = string.gsub(repoPath , "%%", "%%%%")

    local filePath = username .. "/" .. path;
    filePath = Mod.WorldShare.Utils.EncodeURIComponent(filePath)
    filePath = string.gsub(filePath, "%%", "%%%%")
    keepwork.site.getFile({router_params = { repoPath = repoPath, filePath = filePath }}, function(err, msg, data)
        if err ~= 200 then
            LOG.std(nil, "info", "KeepworkSiteService", "GetMarkdown err: %s", err);
            callback("")
            return
        end
        callback(data)
    end)
end

function KeepworkSiteService:DeleteMarkdown(sitename, path, callback)
    callback = callback or function() end;
    local repoPath = System.User.username .. "/" .. sitename;
    repoPath  = Mod.WorldShare.Utils.EncodeURIComponent(repoPath)
    repoPath  = string.gsub(repoPath , "%%", "%%%%")

    local filePath = System.User.username .. "/" .. path;
    filePath = Mod.WorldShare.Utils.EncodeURIComponent(filePath)
    filePath = string.gsub(filePath, "%%", "%%%%")
    keepwork.site.removeFile({router_params = { repoPath = repoPath, filePath = filePath }}, function(err, msg, data)
        callback(data)
    end)
end

-- use page cache
-- @param username: string|nil - Override username (for cross-user access). nil = current user.
function KeepworkSiteService:GetMarkdownFromCache(sitename, path, callback, username)
    callback = callback or function() end;
    username = username or System.User.username;
    local repoPath = username .. "/" .. sitename;
    repoPath  = Mod.WorldShare.Utils.EncodeURIComponent(repoPath)
    repoPath  = string.gsub(repoPath , "%%", "%%%%")

    local filePath = username .. "/" .. path;
    filePath = Mod.WorldShare.Utils.EncodeURIComponent(filePath)
    filePath = string.gsub(filePath, "%%", "%%%%")
    keepwork.site.getFileFromCache({router_params = { repoPath = repoPath, filePath = filePath }}, function(err, msg, data)
        if err ~= 200 then
            LOG.std(nil, "info", "KeepworkSiteService", "GetMarkdownFromCache err: %s, repoPath: %s, filePath: %s", err, repoPath, filePath);
            callback("")
            return
        end
        if type(data) == "string" then
            callback(data)
            return
        end
        local content = data and data.content or ""
        callback(content or "")
    end)
end

function KeepworkSiteService:UpsertMarkdownToCache(sitename, path, content, callback)
    callback = callback or function() end;
    local repoPath = System.User.username .. "/" .. sitename;
    repoPath  = Mod.WorldShare.Utils.EncodeURIComponent(repoPath)
    repoPath  = string.gsub(repoPath , "%%", "%%%%")

    local filePath = System.User.username .. "/" .. path;
    filePath = Mod.WorldShare.Utils.EncodeURIComponent(filePath)
    filePath = string.gsub(filePath, "%%", "%%%%")
    keepwork.site.upsertFileCache({router_params = { repoPath = repoPath, filePath = filePath }, content = content}, function(err, msg, data)
        if err ~= 200 then
            callback({err = err,data = data})
            return
        end
        callback(data)
    end)
end

function KeepworkSiteService:RemoveMarkdownFromCache(sitename, path, callback)
    callback = callback or function() end;
    local repoPath = System.User.username .. "/" .. sitename;
    repoPath  = Mod.WorldShare.Utils.EncodeURIComponent(repoPath)
    repoPath  = string.gsub(repoPath , "%%", "%%%%")

    local filePath = System.User.username .. "/" .. path;
    filePath = Mod.WorldShare.Utils.EncodeURIComponent(filePath)
    filePath = string.gsub(filePath, "%%", "%%%%")
    keepwork.site.removeFileFromCache({router_params = { repoPath = repoPath, filePath = filePath }}, function(err, msg, data)
        if err ~= 200 then
            callback({err = err,data = data})
            return
        end
        callback(data)
    end)
end