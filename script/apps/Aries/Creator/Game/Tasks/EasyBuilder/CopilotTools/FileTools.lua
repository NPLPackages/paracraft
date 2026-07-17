--[[
Title: FILE Tool Manager for EasyAIChat
Author: Paracraft Assistant
Date: 2025/01/12
Desc: Instance-based file tool manager for BackgroundAgent.
Supports local filesystem and remote (PersonalPageStore) workspaces.
All tool file paths are sandboxed to the configured workspace directory.

UseLib:
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/FileTools.lua");
    local FileTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.FileTools");
    -- Create an instance and set workspace:
    local fileTools = FileTools:new();
    fileTools:SetWorkSpace("papa", false);     -- local: temp/workspace/papa/
    fileTools:SetWorkSpace("papa", true);      -- remote: workspace/papa
    -- Register tools on a BackgroundAgent:
    fileTools:RegisterTools(agent);
]]
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");

NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
local FileTools = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.FileTools"));

-- Default file name for memory operations
FileTools.DEFAULT_MEMORY_FILE = "memory.md";

-- Maximum file size for safety (256KB)
FileTools.MAX_FILE_SIZE = 256 * 1024;

-- Allowed file extensions for safety
FileTools.ALLOWED_EXTENSIONS = {
    [".md"] = true,
    [".txt"] = true,
    [".json"] = true,
    [".xml"] = true,
    [".lua"] = true,
    [".log"] = true,
};

-- Constructor
function FileTools:ctor()
    -- Workspace path: local filesystem dir or remote page name prefix
    self.workspace = nil;
    -- Whether this instance uses remote (PersonalPageStore) storage
    self.isRemote = false;
    -- Cached PersonalPageStore reference (lazy-loaded for remote mode)
    self.personalPageStore = nil;
    -- Lower (read-only source) layer path for overlay mode
    self.sourceDir = nil;
    -- Readonly glob patterns from config.md
    self.readonlyPatterns = {};
    -- Per-file readonly cache: relPath → true/false/nil
    self.readonlyCache = {};
end

--------------------------------------------------------------------------------
-- File Upload
--------------------------------------------------------------------------------

function FileTools.UpLoadVisionFile(filepath,callback)
    if not filepath then 
        if callback then
            callback("")
        end
        return;
    end
    local userId = Mod.WorldShare and Mod.WorldShare.Store and Mod.WorldShare.Store:Get('user/userId')
    local sUUID = System.Encoding.guid.uuid()
    local uuid = ParaMisc.md5(sUUID)
    local key = string.format("tempvision_%s_%s", userId or uuid, ParaMisc.md5(filepath))
    keepwork.shareBlock.getToken({
        router_params = {
            id = key,
        },
        bucketName = "tempvision"
    },function(err, msg, data)
		if err == 200 then
			local token = data.data.token
			local file_name = commonlib.Encoding.DefaultToUtf8(ParaIO.GetFileName(filepath));
			local file = ParaIO.open(filepath, "rb");
			if (not file:IsValid()) then
				file:close();
                if callback then
                    callback("")
                end
				return;
			end
			local content = file:GetText(0, -1);
			file:close();
			GameLogic.GetFilters():apply_filters(
				'qiniu_upload_file1',
				token,
				key,
				file_name,
				content,
				function(result, err)
                    if err ~= 200 then
                        if callback then
                            callback("")
                        end
                        return;
                    end
					local base_template_url = "https://tempvision.keepwork.com/"
					if HttpWrapper.GetDevVersion() == "STAGE" then
						base_template_url = "https://tempvision.kp-para.cn/"
					end
					local template_url = base_template_url .. key
                    if callback then
                        callback(template_url)
                    end
				end
			)
		end
    end)
end

-- Get Base directory .
function FileTools.GetBaseDir()
    local userId = Mod.WorldShare.Store:Get('user/userId');
    local userKey = userId and tostring(userId) or "anonymous";
    
    local worldDir = GameLogic.GetWorldDirectory();
    -- Derive a unique folder name from the world directory path
    local worldKey = "default";
    if worldDir and worldDir ~= "" then
        -- Use md5 of world path to create a unique but stable folder name
        worldKey = ParaMisc.md5(worldDir);
    end
    
    local baseDir = ParaIO.GetWritablePath() .. "temp/backgroundagent/" .. userKey .. "/" .. worldKey .. "/";
    if not ParaIO.DoesFileExist(baseDir) then
        ParaIO.CreateDirectory(baseDir);
    end
    return baseDir;
end

--[[
    Extract workspace name from a string that may be a name or a path.
    If the input contains path separators, the last non-empty segment is used as the name.
    @param workspace: string - Workspace name or path (e.g. "papa", "workspace/papa", "temp/workspace/papa")
    @return string - Extracted workspace name
]]
function FileTools.ExtractWorkspaceName(workspace)
    if not workspace or workspace == "" then
        return "";
    end
    workspace = string.gsub(workspace, "\\", "/");
    -- Strip trailing slashes
    workspace = string.gsub(workspace, "/+$", "");
    -- If it looks like a path (contains /), use the last segment as the name
    local lastSegment = workspace:match("([^/]+)$");
    return lastSegment or workspace;
end

--[[
    Set the workspace for this FileTools instance.
    Accepts a workspace name (not a full path). If a path is provided,
    the last segment is extracted as the workspace name.
    Local mode resolves to: temp/workspace/<name>/
    Remote mode resolves to: workspace/<name>
    @param workspace: string - Workspace name (e.g. "papa") or path (last segment used as name)
    @param isRemote: boolean - If true, operations delegate to PersonalPageStore
]]
function FileTools:SetWorkSpace(workspace, isRemote, sourceDir)
    self.isRemote = isRemote and true or false;
    self.sourceDir = nil;
    self.readonlyPatterns = {};
    self.readonlyCache = {};
    local name = FileTools.ExtractWorkspaceName(workspace);
    if self.isRemote then
        -- Remote mode: prefix is "workspace/<name>"
        if name ~= "" then
            self.workspace = "workspace/" .. name;
        else
            self.workspace = "";
        end
        -- Lazy-load PersonalPageStore
        if not self.personalPageStore then
            NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/PersonalPageStore.lua");
            self.personalPageStore = commonlib.gettable("MyCompany.Aries.Creator.Game.KeepWork.PersonalPageStore");
        end
        -- Sync workspace to PersonalPageStore so file ops (ReadFile/ListDir/GrepSearch) use it
        self.personalPageStore:SetFileOpsWorkspace(name);
    else
        -- Local mode: resolve to temp/workspace/<name>/
        if name ~= "" then
            local ws = ParaIO.GetWritablePath() .. "temp/workspace/" .. name .. "/";
            self.workspace = ws;
        else
            self.workspace = FileTools.GetBaseDir();
        end
        if not ParaIO.DoesFileExist(self.workspace) then
            ParaIO.CreateDirectory(self.workspace);
        end
        -- Initialize overlay if sourceDir provided (local mode only)
        if sourceDir and sourceDir ~= "" then
            if not string.match(sourceDir, "/$") then
                sourceDir = sourceDir .. "/";
            end
            self.sourceDir = sourceDir;
            self:_LoadReadonlyPatterns();
        end
    end
end

--[[
    Get the current workspace configuration.
    @return table - {workspace = string, isRemote = boolean}
]]
function FileTools:GetWorkSpace()
    return {
        workspace = self.workspace or FileTools.GetBaseDir(),
        isRemote = self.isRemote,
    };
end

--[[
    Resolve a relative file path to an absolute path (local) or page name (remote).
    Prevents path traversal attacks.
    @param filePath: string - Relative file path (e.g., "memory.md" or "notes/todo.md")
    @return string|nil - Resolved absolute path or page name, or nil if path is invalid
    @return string|nil - Error message if path is invalid
]]
function FileTools:ResolvePath(filePath)
    local relPath = filePath or FileTools.DEFAULT_MEMORY_FILE;
    relPath = string.gsub(relPath, "\\", "/");

    -- Path traversal prevention
    if string.find(relPath, "%.%.") then
        return nil, "Path traversal (..) is not allowed";
    end
    -- Remove leading slashes
    relPath = string.gsub(relPath, "^/+", "");

    if self.isRemote then
        -- Remote mode: produce a page name from workspace prefix + file path (no extension)
        local pageName = relPath;
        -- Strip file extension for page name
        pageName = string.gsub(pageName, "%.[^%.]+$", "");
        local prefix = self.workspace or "";
        if prefix ~= "" then
            if not string.match(prefix, "/$") then
                prefix = prefix .. "/";
            end
            pageName = prefix .. pageName;
        end
        return pageName;
    else
        -- Local mode: prepend workspace directory
        local ws = self.workspace or FileTools.GetBaseDir();
        return ws .. relPath;
    end
end

-- Resolve relative path to Lower layer absolute path.
-- Returns nil if overlay mode is not active or path is invalid.
function FileTools:_ResolveSourcePath(filePath)
    if not self.sourceDir then return nil; end
    local relPath = filePath or FileTools.DEFAULT_MEMORY_FILE;
    relPath = string.gsub(relPath, "\\", "/");
    if string.find(relPath, "%.%.") then return nil; end
    relPath = string.gsub(relPath, "^/+", "");
    return self.sourceDir .. relPath;
end

-- Unified overlay read: Upper → Lower fallback.
-- Returns content, fromSource (boolean indicating Lower layer hit)
-- Returns nil, false if file not found in either layer.
function FileTools:_ReadRawContent(filePath)
    -- Try Upper layer first
    local absPath, err = self:ResolvePath(filePath);
    if absPath then
        local file = ParaIO.open(absPath, "r");
        if file:IsValid() then
            local content = file:GetText(0, -1);
            file:close();
            if content then
                return content, false;
            end
        else
            file:close();
        end
    end
    -- Fallback to Lower layer
    local sourcePath = self:_ResolveSourcePath(filePath);
    if sourcePath then
        local file = ParaIO.open(sourcePath, "r");
        if file:IsValid() then
            local content = file:GetText(0, -1);
            file:close();
            if content then
                return content, true;
            end
        else
            file:close();
        end
    end
    return nil, false;
end

-- Match a relative path against a simple glob pattern.
-- Supports: * (matches non-/ characters in a single path segment)
function FileTools:_MatchGlobPattern(path, pattern)
    local luaPattern = pattern:gsub("([%.%+%-%^%$%(%)%%])", "%%%1");
    luaPattern = luaPattern:gsub("%*", "[^/]*");
    luaPattern = "^" .. luaPattern .. "$";
    return string.find(path, luaPattern) ~= nil;
end

-- Load readonly patterns from sourceDir/config.md YAML frontmatter.
-- Always reads from Lower layer (sourceDir), never Upper.
function FileTools:_LoadReadonlyPatterns()
    self.readonlyPatterns = {};
    self.readonlyCache = {};
    if not self.sourceDir then return; end
    local configPath = self.sourceDir .. "config.md";
    local file = ParaIO.open(configPath, "r");
    if not file:IsValid() then
        file:close();
        return;
    end
    local content = file:GetText(0, -1);
    file:close();
    if not content then return; end
    local fm = content:match("^%-%-%-\r?\n(.-)\r?\n%-%-%-");
    if not fm then return; end
    local inReadonly = false;
    for line in fm:gmatch("[^\r\n]+") do
        if line:match("^readonly:") then
            inReadonly = true;
        elseif inReadonly then
            local item = line:match("^%s*%-%s*\"(.-)\"") or line:match("^%s*%-%s*'(.-)'") or line:match("^%s*%-%s*(%S+)");
            if item then
                table.insert(self.readonlyPatterns, item);
            else
                break;
            end
        end
    end
end

-- Check if a file is readonly. Uses frontmatter (priority) → config patterns (fallback).
-- Results are cached per relative path.
function FileTools:_CheckReadonly(filePath)
    if not self.sourceDir then return false; end
    local relPath = filePath or FileTools.DEFAULT_MEMORY_FILE;
    relPath = string.gsub(relPath, "\\", "/");
    relPath = string.gsub(relPath, "^/+", "");
    if self.readonlyCache[relPath] ~= nil then
        return self.readonlyCache[relPath];
    end
    local content = self:_ReadRawContent(relPath);
    if content then
        local fmVal = parseReadonlyFromContent(content);
        if fmVal ~= nil then
            self.readonlyCache[relPath] = fmVal;
            return fmVal;
        end
    end
    for _, pattern in ipairs(self.readonlyPatterns) do
        if self:_MatchGlobPattern(relPath, pattern) then
            self.readonlyCache[relPath] = true;
            return true;
        end
    end
    self.readonlyCache[relPath] = false;
    return false;
end

--[[
    Get list of allowed extensions as array of strings.
    @return table - Array of extension strings
]]
function FileTools.GetAllowedExtensionsList()
    local list = {};
    for ext, _ in pairs(FileTools.ALLOWED_EXTENSIONS) do
        table.insert(list, ext);
    end
    table.sort(list);
    return list;
end

--------------------------------------------------------------------------------
-- Internal Helpers
--------------------------------------------------------------------------------

--[[
    Count lines in content string without splitting into a table.
    Uses string.find to scan for newlines - O(n) time, O(1) extra memory.
    @param content: string
    @return number - Total line count
]]
local function countLines(content)
    if not content or content == "" then return 0; end
    local count = 1;
    local pos = 1;
    while true do
        local found = string.find(content, "\n", pos, true);
        if not found then break; end
        count = count + 1;
        pos = found + 1;
    end
    -- If file ends with newline, the last empty "line" shouldn't count
    if string.byte(content, #content) == 10 then -- '\n'
        count = count - 1;
    end
    return count;
end

--[[
    Count total lines using readline() without loading entire file.
    @param absPath: string - Absolute file path
    @return number - Total line count
]]
local function countLinesFromFile(absPath)
    local file = ParaIO.open(absPath, "r");
    if not file:IsValid() then
        file:close();
        return 0;
    end
    local count = 0;
    local line = file:readline();
    while line ~= nil do
        count = count + 1;
        line = file:readline();
    end
    file:close();
    return count;
end

-- Parse readonly field from YAML frontmatter content.
-- Returns true, false, or nil (not declared).
local function parseReadonlyFromContent(content)
    if not content then return nil; end
    local fm = content:match("^%-%-%-\r?\n(.-)\r?\n%-%-%-");
    if not fm then return nil; end
    local val = fm:match("readonly:%s*(.-)%s*\r?\n") or fm:match("readonly:%s*(.-)%s*$");
    if val == "true" then return true; end
    if val == "false" then return false; end
    return nil;
end

--------------------------------------------------------------------------------
-- Remote Helpers
--------------------------------------------------------------------------------

--[[
    Write a page's "content" key via PersonalPageStore:SavePageData.
    SavePageData writes to in-memory cache synchronously (async only for remote sync),
    so subsequent LoadPageData calls will find the data in memory immediately.
    @param pageName: string - Normalized page name
    @param content: string - Content to write
]]
function FileTools:_WriteRemotePage(pageName, content)
    if not self.personalPageStore then return; end
    self.personalPageStore:SavePageData(pageName, "content", content);
end

--------------------------------------------------------------------------------
-- Core File Operations
--------------------------------------------------------------------------------

--[[
    Read a file's content, optionally by line range.
    Local mode: synchronous file read (also calls callback if provided).
    Remote mode: async via PersonalPageStore (result ONLY via callback).
    @param filePath: string - Relative file path
    @param startLine: number (optional) - 1-based start line (inclusive)
    @param endLine: number (optional) - 1-based end line (inclusive)
    @param callback: function (optional) - callback(result) for async support
    @return table|nil - {success, content, totalLines, startLine, endLine, error} (local mode only)
]]
function FileTools:ReadFile(filePath, startLine, endLine, callback)
    if self.isRemote then
        return self:_ReadFileRemote(filePath, startLine, endLine, callback);
    end
    local result = self:_ReadFileLocal(filePath, startLine, endLine);
    if callback then callback(result); end
    return result;
end

-- Local file read implementation
function FileTools:_ReadFileLocal(filePath, startLine, endLine)
    -- Full file read (no line range)
    if not startLine and not endLine then
        local absPath, err = self:ResolvePath(filePath);
        if not absPath then
            return {success = false, error = err};
        end
        -- Try Upper layer
        local file = ParaIO.open(absPath, "r");
        if file:IsValid() then
            local content = file:GetText(0, -1);
            file:close();
            if content then
                return {
                    success = true,
                    content = content,
                    totalLines = countLines(content),
                };
            end
        else
            file:close();
        end
        -- Fallback to Lower layer
        local sourcePath = self:_ResolveSourcePath(filePath);
        if sourcePath then
            local sfile = ParaIO.open(sourcePath, "r");
            if sfile:IsValid() then
                local content = sfile:GetText(0, -1);
                sfile:close();
                if content then
                    return {
                        success = true,
                        content = content,
                        totalLines = countLines(content),
                    };
                end
            else
                sfile:close();
            end
        end
        return {success = false, error = string.format("File '%s' does not exist or cannot be opened", filePath)};
    end

    -- Line-range read: use _ReadRawContent for overlay support
    local content, fromSource = self:_ReadRawContent(filePath);
    if not content then
        return {success = false, error = string.format("File '%s' does not exist or is empty", filePath)};
    end

    local totalLines = countLines(content);
    if totalLines == 0 then
        return {success = false, error = string.format("File '%s' does not exist or is empty", filePath)};
    end

    startLine = math.max(1, startLine or 1);
    endLine = math.min(totalLines, endLine or totalLines);

    if startLine > totalLines then
        return {
            success = true,
            content = "",
            totalLines = totalLines,
            startLine = startLine,
            endLine = endLine,
            error = string.format("Start line %d exceeds total lines %d", startLine, totalLines),
        };
    end

    -- Extract line range from in-memory content
    local selectedLines = {};
    local lineNum = 0;
    for line in (content .. "\n"):gmatch("([^\n]*)\n") do
        lineNum = lineNum + 1;
        if lineNum >= startLine and lineNum <= endLine then
            table.insert(selectedLines, line);
        end
        if lineNum > endLine then break; end
    end

    return {
        success = true,
        content = table.concat(selectedLines, "\n"),
        totalLines = totalLines,
        startLine = startLine,
        endLine = endLine,
    };
end

-- Remote file read implementation via PersonalPageStore
-- Supports both sync (no callback) and async (with callback) modes.
function FileTools:_ReadFileRemote(filePath, startLine, endLine, callback)
    local pageName, err = self:ResolvePath(filePath);
    if not pageName then
        local result = {success = false, error = err};
        if callback then callback(result); end
        return result;
    end

    local function processContent(content)
        if not content or content == "" then
            return {success = false, error = string.format("File '%s' does not exist on remote", filePath)};
        end

        local totalLines = countLines(content);

        if not startLine and not endLine then
            return {success = true, content = content, totalLines = totalLines};
        end

        -- Extract line range from content
        local sl = math.max(1, startLine or 1);
        local el = math.min(totalLines, endLine or totalLines);

        local lines = {};
        local lineNum = 0;
        for line in (content .. "\n"):gmatch("([^\n]*)\n") do
            lineNum = lineNum + 1;
            if lineNum >= sl and lineNum <= el then
                table.insert(lines, line);
            end
            if lineNum > el then break; end
        end

        return {
            success = true,
            content = table.concat(lines, "\n"),
            totalLines = totalLines,
            startLine = sl,
            endLine = el,
        };
    end

    -- LoadPageData checks in-memory cache first, then disk, then remote
    if callback then
        self.personalPageStore:LoadPageData(pageName, "content", function(content)
            local result = processContent(content);
            callback(result);
        end);
        return;
    end

    return {success = false, error = "Remote file read requires a callback"};
end

--[[
    Replace an exact string in a file. The oldString must appear exactly once.
    @param filePath: string - Relative file path
    @param oldString: string - Exact text to find (must match exactly once)
    @param newString: string - Replacement text
    @param callback: function (optional) - callback(result)
    @return table|nil - {success, error, matchCount} (local mode only)
]]
function FileTools:ReplaceStringInFile(filePath, oldString, newString, callback)
    if not oldString or oldString == "" then
        local result = {success = false, error = "oldString cannot be empty"};
        if callback then callback(result); end
        return result;
    end
    if newString == nil then
        newString = "";
    end
    
    if self.isRemote then
        return self:_ReplaceStringRemote(filePath, oldString, newString, callback);
    end
    local result = self:_ReplaceStringLocal(filePath, oldString, newString);
    if callback then callback(result); end
    return result;
end

-- Local replace implementation
function FileTools:_ReplaceStringLocal(filePath, oldString, newString)
    local absPath, err = self:ResolvePath(filePath);
    if not absPath then
        return {success = false, error = err};
    end

    -- Readonly check (overlay mode)
    if self:_CheckReadonly(filePath) then
        return {success = false, error = string.format("File '%s' is readonly and cannot be modified", filePath)};
    end

    -- Read content via overlay (Upper → Lower fallback)
    local content, fromSource = self:_ReadRawContent(filePath);
    if not content then
        return {success = false, error = string.format("File '%s' does not exist", filePath)};
    end

    local firstPos = string.find(content, oldString, 1, true);
    if not firstPos then
        return {
            success = false,
            error = "Failed: oldString not found in file. You may read the file again.",
            matchCount = 0,
        };
    end

    local secondPos = string.find(content, oldString, firstPos + #oldString, true);
    if secondPos then
        local matchCount = 2;
        local searchStart = secondPos + #oldString;
        while true do
            local pos = string.find(content, oldString, searchStart, true);
            if not pos then break; end
            matchCount = matchCount + 1;
            searchStart = pos + #oldString;
        end
        return {
            success = false,
            error = "Failed: oldString matches multiple locations in file. Make the string more specific.",
            matchCount = matchCount,
        };
    end

    local newContent = string.sub(content, 1, firstPos - 1) .. newString .. string.sub(content, firstPos + #oldString);

    if #newContent > FileTools.MAX_FILE_SIZE then
        return {
            success = false,
            error = string.format("Resulting file would exceed max size (%d bytes > %d bytes limit)", #newContent, FileTools.MAX_FILE_SIZE),
        };
    end

    -- Always write to Upper layer (copy-on-write if from Lower)
    local dir = string.match(absPath, "^(.*[/\\])");
    if dir then
        ParaIO.CreateDirectory(dir);
    end
    local writeFile = ParaIO.open(absPath, "w");
    if not writeFile:IsValid() then
        writeFile:close();
        return {success = false, error = "Failed to open file for writing"};
    end
    writeFile:WriteString(newContent);
    writeFile:close();

    -- Clear readonly cache for this file
    local relPath = string.gsub(filePath or "", "\\", "/");
    relPath = string.gsub(relPath, "^/+", "");
    self.readonlyCache[relPath] = nil;

    return {success = true, matchCount = 1};
end

-- Remote replace implementation
-- Supports both sync (no callback) and async (with callback) modes.
function FileTools:_ReplaceStringRemote(filePath, oldString, newString, callback)
    local pageName, err = self:ResolvePath(filePath);
    if not pageName then
        local result = {success = false, error = err};
        if callback then callback(result); end
        return result;
    end

    local function doReplace(content)
        if not content then
            return {success = false, error = string.format("File '%s' does not exist on remote", filePath)};
        end

        local firstPos = string.find(content, oldString, 1, true);
        if not firstPos then
            return {success = false, error = "Failed: oldString not found in file. You may read the file again.", matchCount = 0};
        end

        local secondPos = string.find(content, oldString, firstPos + #oldString, true);
        if secondPos then
            return {success = false, error = "Failed: oldString matches multiple locations in file. Make the string more specific.", matchCount = 2};
        end

        local newContent = string.sub(content, 1, firstPos - 1) .. newString .. string.sub(content, firstPos + #oldString);
        if #newContent > FileTools.MAX_FILE_SIZE then
            return {success = false, error = "Resulting file would exceed max size"};
        end

        self:_WriteRemotePage(pageName, newContent);
        return {success = true, matchCount = 1};
    end

    if callback then
        self.personalPageStore:LoadPageData(pageName, "content", function(content)
            local result = doReplace(content);
            callback(result);
        end);
        return;
    end

    return {success = false, error = "Remote file replace requires a callback"};
end

--[[
    Search for a pattern in a file or across all files.
    @param query: string - Search query (plain text or Lua pattern)
    @param filePath: string (optional) - Specific file to search, or nil to search all
    @param isPattern: boolean (optional) - If true, treat query as Lua pattern
    @param maxResults: number (optional) - Max matches to return (default 50)
    @param callback: function (optional) - callback(result)
    @return table|nil - {success, matches, totalMatches, error} (local mode only)
]]
function FileTools:GrepSearch(query, filePath, isPattern, maxResults, callback)
    if not query or query == "" then
        local result = {success = false, error = "Search query cannot be empty"};
        if callback then callback(result); end
        return result;
    end
    
    maxResults = maxResults or 50;
    
    if self.isRemote then
        return self:_GrepSearchRemote(query, filePath, isPattern, maxResults, callback);
    end
    local result = self:_GrepSearchLocal(query, filePath, isPattern, maxResults);
    if callback then callback(result); end
    return result;
end

-- Local grep implementation
function FileTools:_GrepSearchLocal(query, filePath, isPattern, maxResults)
    local lowerQuery = not isPattern and string.lower(query) or nil;

    -- Helper: search content string for matches
    local function searchContent(content, relPath, matches, totalMatches)
        local lineNum = 0;
        for line in (content .. "\n"):gmatch("([^\n]*)\n") do
            lineNum = lineNum + 1;
            local found = false;
            local matchText = nil;
            if isPattern then
                local ok, result = pcall(string.find, line, query);
                if ok and result then
                    found = true;
                    local ok2, captured = pcall(string.match, line, query);
                    matchText = (ok2 and captured) or nil;
                end
            else
                if string.find(string.lower(line), lowerQuery, 1, true) then
                    found = true;
                end
            end
            if found then
                totalMatches = totalMatches + 1;
                if #matches < maxResults then
                    table.insert(matches, {
                        file = relPath,
                        lineNumber = lineNum,
                        line = line,
                        matchText = matchText,
                    });
                end
            end
        end
        return totalMatches;
    end

    -- Single-file grep: use overlay read
    if filePath then
        local isDir = string.match(filePath, "/$");
        if not isDir then
            local content = self:_ReadRawContent(filePath);
            if not content then
                return {success = false, error = string.format("File '%s' does not exist", filePath)};
            end
            local matches = {};
            local totalMatches = searchContent(content, filePath, matches, 0);
            return {
                success = true,
                matches = matches,
                totalMatches = totalMatches,
                truncated = totalMatches > maxResults,
            };
        end
    end

    -- Directory or global grep
    local subDir = "";
    if filePath and string.match(filePath, "/$") then
        subDir = filePath;
    end

    local baseDir = self.workspace or FileTools.GetBaseDir();
    local searchDir = baseDir;
    if subDir ~= "" then
        local normSub = string.gsub(subDir, "\\", "/");
        if string.find(normSub, "%.%.") then
            return {success = false, error = "Path traversal (..) is not allowed"};
        end
        searchDir = baseDir .. normSub;
    end

    local upperFiles = {};
    local upperRelPaths = {};
    for ext, _ in pairs(FileTools.ALLOWED_EXTENSIONS) do
        local pattern = "*" .. ext;
        local found = commonlib.Files.Find({}, searchDir, 0, 100, pattern, "*.zip");
        if found and #found > 0 then
            for _, item in ipairs(found) do
                local fileName = item.filename;
                local relPath = subDir .. fileName;
                if not upperRelPaths[relPath] then
                    table.insert(upperFiles, {absPath = searchDir .. fileName, relPath = relPath});
                    upperRelPaths[relPath] = true;
                end
            end
        end
    end

    local matches = {};
    local totalMatches = 0;

    -- 1. Search Upper files
    for _, fileInfo in ipairs(upperFiles) do
        local file = ParaIO.open(fileInfo.absPath, "r");
        if file:IsValid() then
            local content = file:GetText(0, -1);
            file:close();
            if content then
                totalMatches = searchContent(content, fileInfo.relPath, matches, totalMatches);
            end
        else
            file:close();
        end
    end

    -- 2. Search Lower files (overlay mode only), skip Upper duplicates
    if self.sourceDir then
        NPL.load("(gl)script/ide/Files.lua");
        local lowerDir = self.sourceDir .. subDir;
        local lowerResult = commonlib.Files.Find({}, lowerDir, 0, 500, function(item)
            local ext = commonlib.Files.GetFileExtension(item.filename);
            if ext then
                return FileTools.ALLOWED_EXTENSIONS["." .. ext];
            end
        end, "*.zip");
        if lowerResult and #lowerResult > 0 then
            for _, item in ipairs(lowerResult) do
                local relPath = subDir .. item.filename;
                if not upperRelPaths[relPath] then
                    local sfile = ParaIO.open(lowerDir .. item.filename, "r");
                    if sfile:IsValid() then
                        local content = sfile:GetText(0, -1);
                        sfile:close();
                        if content then
                            totalMatches = searchContent(content, relPath, matches, totalMatches);
                        end
                    else
                        sfile:close();
                    end
                end
            end
        end
    end

    return {
        success = true,
        matches = matches,
        totalMatches = totalMatches,
        truncated = totalMatches > maxResults,
    };
end

-- Remote grep implementation: load content from PersonalPageStore and search in-memory.
-- Supports single-file search (filePath is a specific file) and global/directory search
-- (filePath is nil or ends with "/"). Global search scans all locally cached remote pages.
function FileTools:_GrepSearchRemote(query, filePath, isPattern, maxResults, callback)
    local lowerQuery = not isPattern and string.lower(query) or nil;

    -- Helper: search content string for matches
    local function searchContent(content, relPath, matches, totalMatches)
        local lineNum = 0;
        for line in (content .. "\n"):gmatch("([^\n]*)\n") do
            lineNum = lineNum + 1;
            local found = false;
            local matchText = nil;
            if isPattern then
                local ok, r = pcall(string.find, line, query);
                if ok and r then
                    found = true;
                    local ok2, captured = pcall(string.match, line, query);
                    matchText = (ok2 and captured) or nil;
                end
            else
                if string.find(string.lower(line), lowerQuery, 1, true) then
                    found = true;
                end
            end
            if found then
                totalMatches = totalMatches + 1;
                if #matches < maxResults then
                    table.insert(matches, {
                        file = relPath,
                        lineNumber = lineNum,
                        line = line,
                        matchText = matchText,
                    });
                end
            end
        end
        return totalMatches;
    end

    -- Single file search
    if filePath and not string.match(filePath, "/$") then
        local pageName, err = self:ResolvePath(filePath);
        if not pageName then
            local result = {success = false, error = err};
            if callback then callback(result); end
            return result;
        end

        if callback then
            self.personalPageStore:LoadPageData(pageName, "content", function(content)
                if not content or content == "" then
                    callback({success = false, error = string.format("File '%s' does not exist on remote", filePath)});
                    return;
                end
                local matches = {};
                local totalMatches = searchContent(content, filePath, matches, 0);
                callback({
                    success = true,
                    matches = matches,
                    totalMatches = totalMatches,
                    truncated = totalMatches > maxResults,
                });
            end);
            return;
        end
        return {success = false, error = "Remote file search requires a callback"};
    end

    -- Global / directory search: scan cached files and search each
    if not callback then
        return {success = false, error = "Remote file search requires a callback"};
    end

    local subDir = "";
    if filePath and string.match(filePath, "/$") then
        subDir = filePath;
    end

    -- Build cache directory path for scanning
    local prefix = self.workspace or "";
    if subDir ~= "" then
        local normSub = string.gsub(subDir, "\\", "/");
        normSub = string.gsub(normSub, "^/+", "");
        if prefix ~= "" then
            if not string.match(prefix, "/$") then prefix = prefix .. "/"; end
            prefix = prefix .. normSub;
        else
            prefix = normSub;
        end
    else
        if prefix ~= "" and not string.match(prefix, "/$") then
            prefix = prefix .. "/";
        end
    end

    local username = Mod.WorldShare and Mod.WorldShare.Store and Mod.WorldShare.Store:Get('user/username');
    username = (username and username ~= "") and username or "anonymous";
    local diskBase = ParaIO.GetWritablePath() .. "Database/PersonalPageStore/" .. username .. "/";
    local searchDir = diskBase;
    if prefix ~= "" then
        searchDir = diskBase .. prefix;
    end

    NPL.load("(gl)script/ide/Files.lua");
    local found = commonlib.Files.Find({}, searchDir, 5, 500, function(item)
        local ext = commonlib.Files.GetFileExtension(item.filename);
        return ext and ext == "md";
    end);

    if not found or #found == 0 then
        callback({success = true, matches = {}, totalMatches = 0, truncated = false});
        return;
    end

    local allMatches = {};
    local totalMatches = 0;
    local pending = #found;
    local done = 0;

    for _, item in ipairs(found) do
        local relPath = subDir .. item.filename;
        local pageName = self:ResolvePath(relPath);
        if pageName then
            self.personalPageStore:LoadPageData(pageName, "content", function(content)
                if content and content ~= "" then
                    totalMatches = searchContent(content, relPath, allMatches, totalMatches);
                end
                done = done + 1;
                if done >= pending then
                    callback({
                        success = true,
                        matches = allMatches,
                        totalMatches = totalMatches,
                        truncated = totalMatches > maxResults,
                    });
                end
            end);
        else
            done = done + 1;
            if done >= pending then
                callback({
                    success = true,
                    matches = allMatches,
                    totalMatches = totalMatches,
                    truncated = totalMatches > maxResults,
                });
            end
        end
    end
end

--[[
    Create or overwrite a file with content.
    @param filePath: string - Relative file path
    @param content: string - File content
    @param callback: function (optional) - callback(result)
    @return table|nil - {success, error} (local mode only)
]]
function FileTools:CreateFile(filePath, content, callback)
    if not content then
        content = "";
    end
    
    if self.isRemote then
        return self:_CreateFileRemote(filePath, content, callback);
    end
    local result = self:_CreateFileLocal(filePath, content);
    if callback then callback(result); end
    return result;
end

-- Local create implementation
function FileTools:_CreateFileLocal(filePath, content)
    local absPath, err = self:ResolvePath(filePath);
    if not absPath then
        return {success = false, error = err};
    end

    -- Check if file exists in either layer
    local existingContent, fromSource = self:_ReadRawContent(filePath);
    if existingContent then
        -- File exists: check readonly before allowing overwrite
        if self:_CheckReadonly(filePath) then
            return {success = false, error = string.format("File '%s' is readonly and cannot be modified", filePath)};
        end
    end

    if #content > FileTools.MAX_FILE_SIZE then
        return {
            success = false,
            error = string.format("Content exceeds max file size (%d bytes > %d bytes limit)", #content, FileTools.MAX_FILE_SIZE),
        };
    end

    -- Always write to Upper layer
    local dir = string.match(absPath, "^(.*[/\\])");
    if dir then
        ParaIO.CreateDirectory(dir);
    end

    local file = ParaIO.open(absPath, "w");
    if not file:IsValid() then
        file:close();
        return {success = false, error = "Failed to create file"};
    end
    file:WriteString(content);
    file:close();

    -- Clear readonly cache for this file
    local relPath = string.gsub(filePath or "", "\\", "/");
    relPath = string.gsub(relPath, "^/+", "");
    self.readonlyCache[relPath] = nil;

    return {success = true};
end

-- Remote create implementation
function FileTools:_CreateFileRemote(filePath, content, callback)
    local pageName, err = self:ResolvePath(filePath);
    if not pageName then
        local result = {success = false, error = err};
        if callback then callback(result); end
        return result;
    end
    
    if #content > FileTools.MAX_FILE_SIZE then
        local result = {success = false, error = "Content exceeds max file size"};
        if callback then callback(result); end
        return result;
    end
    
    self:_WriteRemotePage(pageName, content);
    local result = {success = true};
    if callback then callback(result); end
    return result;
end

--[[
    Append content to a file (creates if not exists).
    @param filePath: string - Relative file path
    @param content: string - Content to append
    @param callback: function (optional) - callback(result)
    @return table|nil - {success, error} (local mode only)
]]
function FileTools:AppendToFile(filePath, content, callback)
    if not content or content == "" then
        local result = {success = false, error = "Content to append cannot be empty"};
        if callback then callback(result); end
        return result;
    end
    
    if self.isRemote then
        return self:_AppendToFileRemote(filePath, content, callback);
    end
    local result = self:_AppendToFileLocal(filePath, content);
    if callback then callback(result); end
    return result;
end

-- Local append implementation
function FileTools:_AppendToFileLocal(filePath, content)
    local absPath, err = self:ResolvePath(filePath);
    if not absPath then
        return {success = false, error = err};
    end

    -- Readonly check
    if self:_CheckReadonly(filePath) then
        return {success = false, error = string.format("File '%s' is readonly and cannot be modified", filePath)};
    end

    -- Read existing content via overlay (for size check and copy-on-write)
    local existingContent, fromSource = self:_ReadRawContent(filePath);
    local existingSize = existingContent and #existingContent or 0;

    if existingSize + #content > FileTools.MAX_FILE_SIZE then
        return {
            success = false,
            error = string.format("Resulting file would exceed max size (%d bytes > %d bytes limit)", existingSize + #content, FileTools.MAX_FILE_SIZE),
        };
    end

    -- If content exists only in Lower, copy-on-write: write full content to Upper
    if fromSource and existingContent then
        local dir = string.match(absPath, "^(.*[/\\])");
        if dir then
            ParaIO.CreateDirectory(dir);
        end
        local writeFile = ParaIO.open(absPath, "w");
        if not writeFile:IsValid() then
            writeFile:close();
            return {success = false, error = "Failed to open file for writing"};
        end
        writeFile:WriteString(existingContent .. content);
        writeFile:close();
    else
        -- Upper file exists (or new file): use append mode
        local dir = string.match(absPath, "^(.*[/\\])");
        if dir then
            ParaIO.CreateDirectory(dir);
        end
        local writeFile = ParaIO.open(absPath, "a");
        if not writeFile:IsValid() then
            writeFile:close();
            return {success = false, error = "Failed to open file for appending"};
        end
        writeFile:WriteString(content);
        writeFile:close();
    end

    -- Clear readonly cache
    local relPath = string.gsub(filePath or "", "\\", "/");
    relPath = string.gsub(relPath, "^/+", "");
    self.readonlyCache[relPath] = nil;

    return {success = true};
end

-- Remote append implementation
-- Supports both sync (no callback) and async (with callback) modes.
function FileTools:_AppendToFileRemote(filePath, content, callback)
    local pageName, err = self:ResolvePath(filePath);
    if not pageName then
        local result = {success = false, error = err};
        if callback then callback(result); end
        return result;
    end
    
    local function doAppend(existing)
        existing = existing or "";
        if #existing + #content > FileTools.MAX_FILE_SIZE then
            return {success = false, error = "Resulting file would exceed max size"};
        end
        self:_WriteRemotePage(pageName, existing .. content);
        return {success = true};
    end
    
    if callback then
        self.personalPageStore:LoadPageData(pageName, "content", function(existing)
            local result = doAppend(existing);
            callback(result);
        end);
        return;
    end
    
    return {success = false, error = "Remote file append requires a callback"};
end

--[[
    Delete a file.
    @param filePath: string - Relative file path
    @param callback: function (optional) - callback(result)
    @return table|nil - {success, error} (local mode only)
]]
function FileTools:DeleteFile(filePath, callback)
    if self.isRemote then
        return self:_DeleteFileRemote(filePath, callback);
    end
    local result = self:_DeleteFileLocal(filePath);
    if callback then callback(result); end
    return result;
end

-- Local delete implementation
function FileTools:_DeleteFileLocal(filePath)
    local absPath, err = self:ResolvePath(filePath);
    if not absPath then
        return {success = false, error = err};
    end

    -- Readonly check
    if self:_CheckReadonly(filePath) then
        return {success = false, error = string.format("File '%s' is readonly and cannot be modified", filePath)};
    end

    -- Check if file exists in Upper layer
    local upperExists = ParaIO.DoesFileExist(absPath);

    if not upperExists then
        -- Check if file exists in Lower layer only
        local sourcePath = self:_ResolveSourcePath(filePath);
        if sourcePath then
            local file = ParaIO.open(sourcePath, "r");
            if file:IsValid() then
                file:close();
                return {success = false, error = string.format("File '%s' is a source file and cannot be deleted", filePath)};
            end
            file:close();
        end
        return {success = false, error = string.format("File '%s' does not exist", filePath)};
    end

    ParaIO.DeleteFile(absPath);

    if ParaIO.DoesFileExist(absPath) then
        return {success = false, error = "Failed to delete file"};
    end

    return {success = true};
end

-- Remote delete implementation
function FileTools:_DeleteFileRemote(filePath, callback)
    local pageName, err = self:ResolvePath(filePath);
    if not pageName then
        local result = {success = false, error = err};
        if callback then callback(result); end
        return result;
    end
    
    self.personalPageStore:DeletePageData(pageName, "content");
    local result = {success = true};
    if callback then callback(result); end
    return result;
end

--[[
    List files in the workspace directory.
    @param subDir: string (optional) - Subdirectory to list
    @param callback: function (optional) - callback(result)
    @return table|nil - {success, files = [{name}], error} (local mode only)
]]
function FileTools:ListFiles(subDir, callback)
    if self.isRemote then
        local result = self:_ListFilesRemote(subDir);
        if callback then callback(result); end
        return result;
    end
    local result = self:_ListFilesLocal(subDir);
    if callback then callback(result); end
    return result;
end

-- Local list implementation
function FileTools:_ListFilesLocal(subDir)
    local baseDir = self.workspace or FileTools.GetBaseDir();
    local subDirNorm = "";
    if subDir and subDir ~= "" then
        subDirNorm = string.gsub(subDir, "\\", "/");
        if string.find(subDirNorm, "%.%.") then
            return {success = false, error = "Path traversal (..) is not allowed"};
        end
        if not string.match(subDirNorm, "/$") then
            subDirNorm = subDirNorm .. "/";
        end
        baseDir = baseDir .. subDirNorm;
    end

    NPL.load("(gl)script/ide/Files.lua");
    -- Upper layer directories
    local dirEntries = commonlib.Files.Find({}, baseDir, 0, 500);
    -- Upper layer files
    local result = commonlib.Files.Find({}, baseDir, 0, 500, function(item)
        local ext = commonlib.Files.GetFileExtension(item.filename);
        if ext then
            return FileTools.ALLOWED_EXTENSIONS["." .. ext];
        end
    end);

    local files = {};
    local seen = {};
    if dirEntries and #dirEntries > 0 then
        for _, item in ipairs(dirEntries) do
            local name = type(item) == "table" and item.filename or tostring(item);
            if name ~= "." and name ~= ".." and name ~= "" then
                local dirName = name .. "/";
                table.insert(files, { name = dirName, filesize = 0 });
                seen[dirName] = true;
            end
        end
    end
    if result and #result > 0 then
        for _, item in ipairs(result) do
            table.insert(files, {
                name = item.filename,
                filesize = item.filesize,
            });
            seen[item.filename] = true;
        end
    end

    -- Merge Lower layer files (overlay mode only)
    if self.sourceDir then
        local lowerDir = self.sourceDir .. subDirNorm;
        local lowerDirEntries = commonlib.Files.Find({}, lowerDir, 0, 500);
        local lowerResult = commonlib.Files.Find({}, lowerDir, 0, 500, function(item)
            local ext = commonlib.Files.GetFileExtension(item.filename);
            if ext then
                return FileTools.ALLOWED_EXTENSIONS["." .. ext];
            end
        end, "*.zip");
        if lowerDirEntries and #lowerDirEntries > 0 then
            for _, item in ipairs(lowerDirEntries) do
                local name = type(item) == "table" and item.filename or tostring(item);
                if name ~= "." and name ~= ".." and name ~= "" then
                    local dirName = name .. "/";
                    if not seen[dirName] then
                        table.insert(files, { name = dirName, filesize = 0 });
                        seen[dirName] = true;
                    end
                end
            end
        end
        if lowerResult and #lowerResult > 0 then
            for _, item in ipairs(lowerResult) do
                if not seen[item.filename] then
                    table.insert(files, {
                        name = item.filename,
                        filesize = item.filesize,
                    });
                    seen[item.filename] = true;
                end
            end
        end
    end

    return {success = true, files = files};
end

-- Remote list implementation: scans local PersonalPageStore cache for immediate children.
-- Returns both directories and files (matching _ListFilesLocal structure and JS listDir behavior).
function FileTools:_ListFilesRemote(subDir)
    local prefix = self.workspace or "";
    if subDir and subDir ~= "" then
        subDir = string.gsub(subDir, "\\", "/");
        if string.find(subDir, "%.%.") then
            return {success = false, error = "Path traversal (..) is not allowed"};
        end
        subDir = string.gsub(subDir, "^/+", "");
        if not string.match(subDir, "/$") then
            subDir = subDir .. "/";
        end
        if prefix ~= "" then
            if not string.match(prefix, "/$") then
                prefix = prefix .. "/";
            end
            prefix = prefix .. subDir;
        else
            prefix = subDir;
        end
    else
        if prefix ~= "" and not string.match(prefix, "/$") then
            prefix = prefix .. "/";
        end
    end

    -- Scan local PersonalPageStore cache directory
    local username = Mod.WorldShare and Mod.WorldShare.Store and Mod.WorldShare.Store:Get('user/username');
    username = (username and username ~= "") and username or "anonymous";
    local diskBase = ParaIO.GetWritablePath() .. "Database/PersonalPageStore/" .. username .. "/";

    NPL.load("(gl)script/ide/Files.lua");
    local searchDir = diskBase;
    if prefix ~= "" then
        searchDir = diskBase .. prefix;
    end

    local files = {};
    local seen = {};

    -- Find directories (depth 0 = immediate children only)
    -- Only include a directory if it actually contains at least one .md file anywhere inside.
    -- This filters out empty artifact directories left behind after file deletions.
    local dirEntries = commonlib.Files.Find({}, searchDir, 0, 500);
    if dirEntries and #dirEntries > 0 then
        for _, item in ipairs(dirEntries) do
            local name = type(item) == "table" and item.filename or tostring(item);
            if name ~= "." and name ~= ".." and name ~= "" then
                local dirName = name .. "/";
                if not seen[dirName] then
                    -- Only include if there's at least one .md file inside (stops after 1 match)
                    local subSearch = commonlib.Files.Find({}, searchDir .. name .. "/", 1, 1, "*.md", "*.zip");
                    if subSearch and #subSearch > 0 then
                        table.insert(files, { name = dirName, filesize = 0 });
                        seen[dirName] = true;
                    end
                end
            end
        end
    end

    -- Find files (depth 0, .md extension = cached remote pages)
    local fileEntries = commonlib.Files.Find({}, searchDir, 0, 500, function(item)
        local ext = commonlib.Files.GetFileExtension(item.filename);
        return ext and ext == "md";
    end);
    if fileEntries and #fileEntries > 0 then
        for _, item in ipairs(fileEntries) do
            if not seen[item.filename] then
                table.insert(files, { name = item.filename, filesize = item.filesize });
                seen[item.filename] = true;
            end
        end
    end

    return {success = true, files = files};
end

--------------------------------------------------------------------------------
-- Tool Registration for BackgroundAgent
--------------------------------------------------------------------------------

--[[
    Register all file tools with a ToolRegistry instance.
    Uses this FileTools instance for all operations (respects workspace setting).
    @param registry: ToolRegistry - The registry to register tools on
    @param category: string (optional) - Category tag for all file tools, default "file_io"
]]
function FileTools:RegisterTools(registry, category)
    if not registry then
        LOG.std(nil, "error", "FileTools", "Cannot register tools: registry is nil");
        return;
    end
    
    category = category or "file_io";
    local fileTools = self;
    
    -- Tool: read_file
    registry:RegisterTool("read_file", {
        description = "Read content from a text file in the world directory. Supports reading full file or a specific line range. Use this to check existing content before making edits.",
        parameters = {
            type = "object",
            properties = {
                file_path = {
                    type = "string",
                    description = "Relative file path within the world directory (e.g., 'memory.md', 'notes/todo.md'). Default: 'memory.md'",
                },
                start_line = {
                    type = "number",
                    description = "1-based start line number (inclusive). Omit to read from beginning.",
                },
                end_line = {
                    type = "number",
                    description = "1-based end line number (inclusive). Omit to read to end.",
                },
            },
            required = {},
        },
    }, function(params, callback, services)
        local filePath = params.file_path or FileTools.DEFAULT_MEMORY_FILE;
        fileTools:ReadFile(filePath, params.start_line, params.end_line, function(result)
            if result.success then
                -- Return plain content string, matching JS readFile() return value
                result.llm_result = result.content or "";
            else
                -- File not found → return empty string (matches JS '' fallback)
                result.llm_result = "";
            end
            callback(result);
        end);
    end, category);
    
    -- Tool: replace_string_in_file
    registry:RegisterTool("replace_string_in_file", {
        description = "Replace an exact string in a text file. The oldString must appear exactly once in the file. Include surrounding context lines to ensure uniqueness. Use this to update specific sections of a file.",
        parameters = {
            type = "object",
            properties = {
                file_path = {
                    type = "string",
                    description = "Relative file path within the world directory. Default: 'memory.md'",
                },
                old_string = {
                    type = "string",
                    description = "The exact text to find and replace. Must match exactly once in the file, including whitespace and line endings. Include surrounding lines for uniqueness.",
                },
                new_string = {
                    type = "string",
                    description = "The text to replace old_string with. Can be empty string to delete the matched text.",
                },
            },
            required = {"old_string", "new_string"},
        },
    }, function(params, callback, services)
        local filePath = params.file_path or FileTools.DEFAULT_MEMORY_FILE;
        fileTools:ReplaceStringInFile(filePath, params.old_string, params.new_string, function(result)
            if result.success then
                result.llm_result = string.format("Successfully replaced text in '%s'", filePath);
            else
                result.llm_result = "Error: " .. (result.error or "unknown error");
            end
            callback(result);
        end);
    end, category);
    
    -- Tool: grep_search
    registry:RegisterTool("grep_search", {
        description = "Do a fast text search across files. Supports plain text (case-insensitive) or Lua pattern matching. Use include_pattern to filter files by glob (e.g. '*.md', 'src/**'). Search a specific file or all files in the workspace.",
        parameters = {
            type = "object",
            properties = {
                query = {
                    type = "string",
                    description = "The pattern to search for. Case-insensitive plain text by default, or Lua pattern if is_pattern is true.",
                },
                file_path = {
                    type = "string",
                    description = "Specific file to search (relative path). Omit to search all files.",
                },
                is_pattern = {
                    type = "boolean",
                    description = "If true, treat query as a Lua pattern (similar to regex). Default: false.",
                },
                include_pattern = {
                    type = "string",
                    description = "Glob pattern to filter which files are searched (e.g. '*.md', 'notes/**'). Applied to the file path. Omit to search all files.",
                },
                max_results = {
                    type = "number",
                    description = "Maximum number of matches to return. Default: 50.",
                },
            },
            required = {"query"},
        },
    }, function(params, callback, services)
        -- Resolve effective file_path from include_pattern
        local searchFilePath = params.file_path;
        local includePattern = params.include_pattern;
        local hasWildcard = includePattern and string.find(includePattern, "[*?%[%{]") ~= nil;
        if includePattern and includePattern ~= "" and not hasWildcard then
            -- Exact file name (no wildcards): treat as file_path, strip extension
            searchFilePath = string.gsub(includePattern, "%.[^%.]+$", "");
        end

        -- Helper: convert glob to Lua pattern (supports * and **)
        local function globToLuaPattern(glob)
            local p = glob:gsub("([%.%+%-%^%$%(%)%%])", "%%%1");
            p = p:gsub("%*%*", "\0");  -- placeholder for **
            p = p:gsub("%*", "[^/]*");
            p = p:gsub("%?", ".");
            p = p:gsub("\0", ".*");
            return "^" .. p .. "$";
        end

        fileTools:GrepSearch(params.query, searchFilePath, params.is_pattern, params.max_results, function(result)
            -- Post-filter by include_pattern glob when wildcards are present
            if result.success and result.matches and hasWildcard then
                local luaPat = globToLuaPattern(includePattern);
                local filtered = {};
                for _, match in ipairs(result.matches) do
                    if match.file and string.find(match.file, luaPat) then
                        table.insert(filtered, match);
                    end
                end
                result.matches = filtered;
                result.totalMatches = #filtered;
                result.truncated = false;
            end

            if result.success then
                if not result.matches or #result.matches == 0 then
                    result.llm_result = "No matches found.";
                else
                    local parts = {};
                    local currentFile = "";
                    for _, match in ipairs(result.matches) do
                        if match.file ~= currentFile then
                            currentFile = match.file;
                            table.insert(parts, string.format("\n%s:", currentFile));
                        end
                        table.insert(parts, string.format("  L%d: %s", match.lineNumber, match.line));
                    end
                    if result.truncated then
                        table.insert(parts, string.format("\n... truncated, showing %d of %d matches", #result.matches, result.totalMatches));
                    end
                    result.llm_result = table.concat(parts, "\n");
                end
            else
                result.llm_result = "Error: " .. (result.error or "unknown error");
            end
            callback(result);
        end);
    end, category);
    
    -- Tool: create_file
    registry:RegisterTool("create_file", {
        description = "Create a new file or overwrite an existing file in the workspace. Never use this tool to edit a file that already exists — use replace_string_in_file instead.",
        parameters = {
            type = "object",
            properties = {
                file_path = {
                    type = "string",
                    description = "Relative file path within the workspace. Default: 'memory.md'",
                },
                content = {
                    type = "string",
                    description = "The content to write to the file.",
                },
            },
            required = {"content"},
        },
    }, function(params, callback, services)
        local filePath = params.file_path or FileTools.DEFAULT_MEMORY_FILE;
        fileTools:CreateFile(filePath, params.content, function(result)
            if result.success then
                result.llm_result = string.format("Successfully created file '%s' (%d bytes)", filePath, #(params.content or ""));
            else
                result.llm_result = "Error: " .. (result.error or "unknown error");
            end
            callback(result);
        end);
    end, category);

    -- Tool: list_dir (aligned with JS list_dir)
    -- Helper: format files array into newline-separated string (folders end with /)
    local function formatDirListing(files)
        if not files or #files == 0 then return ""; end
        local parts = {};
        for _, f in ipairs(files) do
            table.insert(parts, f.name);
        end
        table.sort(parts);
        return table.concat(parts, "\n");
    end

    registry:RegisterTool("list_dir", {
        description = "List the contents of a directory. Result has one entry per line. If the name ends in /, it is a folder, otherwise a file. By default only lists direct children.",
        parameters = {
            type = "object",
            properties = {
                path = {
                    type = "string",
                    description = "The directory path to list (relative to workspace root). Use '.' or omit to list the root directory.",
                },
                recursive = {
                    type = "boolean",
                    description = "Whether to list recursively. Defaults to false.",
                },
            },
            required = {},
        },
    }, function(params, callback, services)
        local subDir = params.path;
        -- Normalise root markers (., ./, empty) to nil for ListFiles/ListDir
        if subDir == "." or subDir == "./" or subDir == "/" or subDir == "" then
            subDir = nil;
        end

        local function handleResult(result)
            local output;
            if result and result.success then
                local listing = formatDirListing(result.files);
                if listing == "" then
                    output = "Directory is empty.";
                else
                    output = listing;
                end
            else
                output = "Error: " .. (result and result.error or "unknown error");
            end
            local ret = result or {};
            ret.llm_result = output;
            callback(ret);
        end

        -- In remote mode, delegate to PersonalPageStore:ListDir for full mount-layer support
        if fileTools.isRemote and fileTools.personalPageStore and fileTools.personalPageStore.ListDir then
            fileTools.personalPageStore:ListDir(subDir, function(result)
                handleResult(result);
            end);
        else
            fileTools:ListFiles(subDir, function(result)
                handleResult(result);
            end);
        end
    end, category);

    -- Tool: multi_replace_string_in_file (aligned with JS multi_replace_string_in_file)
    registry:RegisterTool("multi_replace_string_in_file", {
        description = "Apply multiple replace_string_in_file operations in a single call. Each replacement is applied sequentially. Ideal for making multiple edits across different files or multiple edits in the same file.",
        parameters = {
            type = "object",
            properties = {
                explanation = {
                    type = "string",
                    description = "A brief explanation of what the multi-replace operation will accomplish.",
                },
                replacements = {
                    type = "array",
                    description = "An array of replacement operations to apply sequentially.",
                    items = {
                        type = "object",
                        properties = {
                            file_path = {
                                type = "string",
                                description = "Relative file path within the workspace.",
                            },
                            old_string = {
                                type = "string",
                                description = "The exact text to find. Must appear exactly once in the file.",
                            },
                            new_string = {
                                type = "string",
                                description = "The replacement text.",
                            },
                        },
                        required = {"file_path", "old_string", "new_string"},
                    },
                },
            },
            required = {"replacements"},
        },
    }, function(params, callback, services)
        local replacements = params.replacements;
        if not replacements or #replacements == 0 then
            local result = {success = false, error = "replacements array is required and must not be empty"};
            result.llm_result = "Error: " .. result.error;
            callback(result);
            return;
        end

        local results = {};
        local pending = #replacements;
        local succeeded = 0;
        local failed = 0;

        -- Sequential execution via recursive callback chain
        local function runNext(index)
            if index > #replacements then
                -- All done — build summary
                local summary;
                if params.explanation and params.explanation ~= "" then
                    summary = params.explanation .. "\n";
                else
                    summary = "";
                end
                summary = summary .. string.format("Multi-replace: %d succeeded, %d failed.", succeeded, failed);
                if failed > 0 then
                    summary = summary .. "\nFailures:";
                    for _, r in ipairs(results) do
                        if not r.success then
                            summary = summary .. string.format("\n  [%d] %s: %s", r.index, r.file_path or "?", r.error or "unknown");
                        end
                    end
                end
                callback({success = failed == 0, llm_result = summary, results = results});
                return;
            end

            local r = replacements[index];
            local filePath = r.file_path or FileTools.DEFAULT_MEMORY_FILE;
            if not r.old_string then
                table.insert(results, {index = index, file_path = filePath, success = false, error = "old_string is required"});
                failed = failed + 1;
                runNext(index + 1);
                return;
            end
            if r.new_string == nil then
                table.insert(results, {index = index, file_path = filePath, success = false, error = "new_string is required"});
                failed = failed + 1;
                runNext(index + 1);
                return;
            end

            fileTools:ReplaceStringInFile(filePath, r.old_string, r.new_string, function(res)
                if res and res.success then
                    table.insert(results, {index = index, file_path = filePath, success = true});
                    succeeded = succeeded + 1;
                else
                    local errMsg = res and res.error or "unknown error";
                    table.insert(results, {index = index, file_path = filePath, success = false, error = errMsg});
                    failed = failed + 1;
                end
                runNext(index + 1);
            end);
        end

        runNext(1);
    end, category);

    LOG.std(nil, "info", "FileTools", "Registered %d file tools", 6);
end