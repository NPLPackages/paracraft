--[[
Title: BuildSomething Task
Author(s): LiXizhi
Date: 2025
Desc: A task that periodically suggests building something or accepts user requests to build objects.
It uses a mock LLM to select templates and modify them.

This task automatically discovers block templates from the current world's blocktemplates/ folder.
Only templates with user-defined display names (set via EasyLiveModel's "Set Display Name" feature) 
will be included in the build suggestions. This task reuses EasyLiveModel's display name system
for consistency across the application.

Build Modes:
- "standalone" (default): The copilot builds all by itself automatically.
- "guide": The copilot guides the user to build the target. It shows the block on its head,
  walks to the placement location, and asks the user to select and place the correct block.
  If the user places blocks correctly several times, the copilot will help build together.

To prepare templates for this task:
1. Build something in the world
2. Use /selectblock to select the blocks
3. Use /savetemplate blocktemplates/yourfile.bmax to save it
4. In EasyLiveModel (模型库), right-click the template file and select "设置显示名称" to set a display name
5. The template will now be available for BuildSomething suggestions

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotDragonPet.lua");
local CopilotDragonPet = commonlib.gettable("MyCompany.Aries.Game.Tasks.CopilotDragonPet");
local copilot = CopilotDragonPet.GetInstance()

NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/BuildSomething.task.lua");
local BuildSomething = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.BuildSomething");

-- Example 1: Interactive mode - copilot will periodically ask to build something
local task = BuildSomething:new():Init(copilot, {
    interval = 30,  -- Ask every 30 seconds
    silenceDuration = 60 * 1000,  -- Wait 60 seconds after denial
    maxFilesize = 3 * 1024,  -- Max template file size: 3KB (optional, defaults to 3KB)
});
copilot:AddTask(task, {
    name = L"建造助手",
    description = L"定期提议建造物品",
    enabled = true,
    autoStart = true
});

-- Example 2: Direct LLM generation mode - immediately generate and build based on user description
local task = BuildSomething:new():Init(copilot, {
    userDesc = "a red table",  -- Provide description to invoke LLM generator directly
    blockLimit = 100,  -- default to 100 blocks
    maxFilesize = 3 * 1024,  -- Optional: max template file size
});
copilot:AddTask(task, {
    name = L"建造助手",
    description = L"使用AI生成并建造指定物品",
    enabled = true,
    autoStart = true
});

-- Example 3: Direct filename mode with guide build mode
local task = BuildSomething:new():Init(copilot, {
    filename = "blocktemplates/chair.bmax",  -- Direct path to template file
    title = "一把椅子",  -- Optional title describing the content
    buildMode = "guide",  
});
copilot:AddTask(task, {
    name = L"建造椅子",
    description = L"建造一把椅子",
    enabled = true,
    autoStart = true
});
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotTaskBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyLiveModel.lua");
NPL.load("(gl)script/ide/System/Core/Color.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemColorBlock.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
local EasyLiveModel = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyLiveModel");
local CopilotTaskBase = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.CopilotTaskBase");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local Color = commonlib.gettable("System.Core.Color");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
local BuildSomething = commonlib.inherit(CopilotTaskBase, commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.BuildSomething"));

BuildSomething.name = "BuildSomething";

-- Templates will be dynamically loaded from the current world's blocktemplates/ folder
-- Only files with user-defined display names will be included
-- Uses EasyLiveModel's display name functions for consistency
BuildSomething.templates = nil;
BuildSomething.maxFilesize = 3 * 1024; -- Default max file size: 3KB

-- Build modes:
-- "standalone": copilot builds all by itself (default)
-- "guide": copilot guides the user to build the target, showing hints and observing user actions
BuildSomething.defaultBuildMode = "standalone";

function BuildSomething:ctor()
    BuildSomething._super.ctor(self);
    self.interval = 30; -- Ask every 30 seconds
    self.lastAskTime = 0;
    self.autoRemoveWhenStopped = true; 
    self.silenceDuration = 60 * 1000; -- Silence duration after denial
    self.allowQuickFinishBuild = true;
    self.buildMode = BuildSomething.defaultBuildMode;
    -- Guide mode settings
    self.consecutiveCorrectPlacements = 0; -- Track correct placements for auto-assist
    self.autoAssistThreshold = 3; -- After this many correct placements, copilot helps build
end

-- Register world unload event to clear templates cache
function BuildSomething.RegisterWorldEvents()
    GameLogic:Connect("WorldUnloaded", BuildSomething, BuildSomething.OnWorldUnload, "UniqueConnection");
end

-- Called when world is unloaded
function BuildSomething.OnWorldUnload()
    BuildSomething.templates = nil;
end

-- Load templates from the current world's blocktemplates/ folder
-- Only includes files with user-defined display names
-- Reuses EasyLiveModel's display name functions
-- Supports searching in zip files (similar to EasyLiveModel.UpdateExistingFiles)
function BuildSomething.LoadTemplates()
    NPL.load("(gl)script/ide/Files.lua");
    local rootPath = ParaWorld.GetWorldDirectory() .. "blocktemplates/";
    local templates = {};
    
    -- Check if blocktemplates directory exists
    if(not ParaIO.DoesFileExist(rootPath, true)) then
        LOG.std(nil, "warn", "BuildSomething", "Block templates directory not found: %s", rootPath);
        return templates;
    end
    
    -- Search for template files (bmax and blocks.xml)
    local filterFunc = function(item)
        if(item.filesize and item.filesize > 0) then
            local filename = item.filename;
            -- Match .bmax or .blocks.xml files
            if(filename:match("%.bmax$") or filename:match("%.blocks%.xml$")) then
                return true;
            end
        end
        return false;
    end
    
    local result = commonlib.Files.Find({}, rootPath, 2, 500, filterFunc);
    
    -- Get max file size setting
    local maxFilesize = BuildSomething.maxFilesize or (3 * 1024);
    
    -- Process local files first
    local localFiles = {};
    for _, fileAttr in ipairs(result or {}) do
        local filename = fileAttr.filename;
        local filesize = fileAttr.filesize or 0;
        
        -- Filter out files bigger than maxFilesize
        if(filesize <= maxFilesize) then
            localFiles[filename] = true;
            
            -- Use EasyLiveModel's GetDisplayName function
            local displayName = EasyLiveModel.GetDisplayName(filename);
            
            -- Only include if display name is different from filename (i.e., has a custom display name)
            if(displayName and displayName ~= filename) then
                -- Extract keywords from display name (split by spaces)
                local keywords = {};
                for word in displayName:gmatch("%S+") do
                    table.insert(keywords, word:lower());
                end
                
                -- Create template entry
                local template = {
                    name = EasyLiveModel.GetBaseFilename(filename),
                    file = "blocktemplates/" .. filename,
                    keywords = keywords,
                    description = displayName,
                };
                table.insert(templates, template);
            end
        end
    end
    
    -- Check for files in zip archive (similar to EasyLiveModel.UpdateExistingFiles)
    if(System.World.worldzipfile) then
        local zip_archive = ParaEngine.GetAttributeObject():GetChild("AssetManager"):GetChild("CFileManager"):GetChild(System.World.worldzipfile);
        local zipParentDir = zip_archive:GetField("RootDirectory", "");
        if(zipParentDir ~= "") then
            local worldDir = ParaWorld.GetWorldDirectory();
            if(worldDir:sub(1, #zipParentDir) == zipParentDir) then
                local zipRootPath = worldDir:sub(#zipParentDir + 1, -1) .. "blocktemplates/";
                local zipResult = commonlib.Files.Find({}, zipRootPath, 2, 500, ":.", System.World.worldzipfile);
                
                for _, fileAttr in ipairs(zipResult or {}) do
                    if(type(filterFunc) == "function" and filterFunc(fileAttr)) then
                        local filename = commonlib.Encoding.Utf8ToDefault(fileAttr.filename);
                        local filesize = fileAttr.filesize or 0;
                        
                        -- Skip if already found in local files or too large
                        if(not localFiles[filename] and filesize <= maxFilesize) then
                            -- Use EasyLiveModel's GetDisplayName function
                            local displayName = EasyLiveModel.GetDisplayName(filename);
                            
                            -- Only include if display name is different from filename (i.e., has a custom display name)
                            if(displayName and displayName ~= filename) then
                                -- Extract keywords from display name (split by spaces)
                                local keywords = {};
                                for word in displayName:gmatch("%S+") do
                                    table.insert(keywords, word:lower());
                                end
                                
                                -- Create template entry
                                local template = {
                                    name = EasyLiveModel.GetBaseFilename(filename),
                                    file = "blocktemplates/" .. filename,
                                    keywords = keywords,
                                    description = displayName,
                                };
                                table.insert(templates, template);
                            end
                        end
                    end
                end
            end
        end
    end
    
    LOG.std(nil, "info", "BuildSomething", "Loaded %d templates with display names from %s", #templates, rootPath);
    return templates;
end

-- Get templates (load on first access)
function BuildSomething.GetTemplates()
    if(not BuildSomething.templates) then
        BuildSomething.templates = BuildSomething.LoadTemplates();
        BuildSomething.RegisterWorldEvents();
    end
    return BuildSomething.templates;
end

function BuildSomething:Init(copilot, params)
    params = params or {};
    BuildSomething._super.Init(self, copilot, params);
    if params.interval then
        self.interval = params.interval;
    end
    if params.silenceDuration then
        self.silenceDuration = params.silenceDuration;
    end
    if params.maxFilesize then
        BuildSomething.maxFilesize = params.maxFilesize;
    end
    if params.welcomeMessage then
        self.welcomeMessage = params.welcomeMessage;
    end
    if params.userDesc then
        self.userDesc = params.userDesc;
    end
    if params.blockLimit then
        self.blockLimit = params.blockLimit;
    end
    if params.blocks then
        self.blocks = params.blocks;
    end
    if params.allowQuickFinishBuild ~= nil then
        self.allowQuickFinishBuild = params.allowQuickFinishBuild;
    end
    -- Build mode: "standalone" (default) or "guide"
    if params.buildMode then
        self.buildMode = params.buildMode;
    end
    -- Guide mode settings
    if params.autoAssistThreshold then
        self.autoAssistThreshold = params.autoAssistThreshold;
    end
    -- Direct filename mode: build a specific template file without search or selection
    if params.filename then
        self.filename = params.filename;
    end
    -- Title for the filename (optional, describes the content)
    if params.title then
        self.title = params.title;
    end

    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyModel.lua");
    local EasyModel = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyModel");
    EasyModel.Cancel()
    return self;
end

function BuildSomething:ExecuteTask(copilot)
    
    -- Show welcome message if provided
    if self.welcomeMessage then
        copilot:Say(self.welcomeMessage, 3);
        copilot:Wait(3);
    end
    
    if self:CheckStopRequested() then return end
    self:CheckPaused();

    if self.blocks then
        self:BuildBlocks(copilot, self.blocks);
        self.blocks = nil;
        return;
    end
    
    -- Direct filename mode: build a specific template file without search or selection
    if self.filename then
        local template = {
            file = self.filename,
            name = self.title or self.filename,
            description = self.title or self.filename,
        };
        
        if self.title then
            copilot:Say(string.format(L"让我们来建造%s吧！", self.title), 2);
            copilot:Wait(1);
        end
        
        if self:CheckStopRequested() then return end
        self:CheckPaused();

        local success = self:BuildObject(copilot, template);
        if success then
            copilot:Say(L"建造完成！", 2);
            self.state = self.STATE_COMPLETED;
        end
        self:SetTaskResult(success);
        self.filename = nil;
        return;
    end
    
    if self.userDesc then
        local result = self:GenerateAndBuild(copilot, self.userDesc);
        self:SetTaskResult(result);
        self.userDesc = nil;
        return result
    end
    
    -- Load templates from current world
    local templates = BuildSomething.GetTemplates();
    
    LOG.std(nil, "info", "BuildSomething", "Found %d templates with display names", #(templates or {}));
    
    while true do
        if self:CheckStopRequested() then return end
        self:CheckPaused();
        
        -- Wait for interval
        local currentTime = commonlib.TimerManager.GetCurrentTime();
        if currentTime - self.lastAskTime > self.interval then
            self.lastAskTime = currentTime;
            
            -- Ask user
            local proposal = self:GetRandomProposal();
            local btnIndex = 3;
            if proposal then
                local answer;
                answer, btnIndex = copilot:Ask(string.format(L"我们建造%s好吗？", proposal.description), 
                    {{text=L"好的", default=true}, L"不", L"我想造点别的"});
            end
            
            if btnIndex == 1 then
                local success = self:BuildObject(copilot, proposal);
                if not success then self.state = self.STATE_FAILED; end
                copilot:Say(success and L"建造完成！" or L"建造失败。", 2);
                self:SetTaskResult(success);
                return success;
            elseif btnIndex == 3 then
                local user_desc, btnIndex1 = copilot:Ask(L"你想造什么？", {{text="", type="text"}, {L"确定", default=true}, L"取消"});
                if btnIndex1 == 2 and user_desc and user_desc ~= "" then
                    local result = self:GenerateAndBuild(copilot, user_desc);
                    if not result then self.state = self.STATE_FAILED; end
                    self:SetTaskResult(result);
                    return result;
                end
                self.lastAskTime = commonlib.TimerManager.GetCurrentTime();
            else
                -- User said no, wait longer next time
                copilot:Say(L"好吧，以后再说。", 2);
                self.lastAskTime = commonlib.TimerManager.GetCurrentTime() + self.silenceDuration;
                return;
            end
        end
        copilot:Wait(1); -- Check every second
    end
end

function BuildSomething:GetRandomProposal()
    local templates = BuildSomething.GetTemplates();
    if not templates or #templates == 0 then
        return nil;
    end
    local index = math.random(1, #templates);
    return templates[index];
end

function BuildSomething:GenerateAndBuild(copilot, user_desc)
    copilot:Say(L"思考中...", 2);
    
    -- Try to find matching templates using LLM
    local template = self:LLMSearchLocalTemplates(user_desc);
    
    if template then
        -- Found a template, proceed to build
        local answer, btnIndex = copilot:Ask(
            string.format(L"我找到了%s的设计图。我们来建造它吧！", template.description or template.name), 
            {{text=L"确定", default=true}, L"取消"}
        );

        if btnIndex ~= 1 then
            copilot:Say(L"取消建造。", 2);
            return;
        end
   
        local modified_template = self:LLMChangeTemplateTextureByDesc(user_desc, template) or template;
        local success;
        if modified_template then
            success = self:BuildObject(copilot, modified_template);
        end
        copilot:Say((not success) and L"建造终止了。" or L"建造完成！", 2);
        return success
    else
        copilot:Say(L"没有找到匹配的模板，让我来设计一个...", 2);
        local radius = 3;
        local x, y, z = copilot:FindEmptySquareGround(radius, 30, 3);
        if(x) then
            copilot:WalkTo(x, y, z);
            local player = EntityManager.GetFocus();
            if(player) then
                copilot:TurnTo(player:GetPosition());
            end
        else
            copilot:Say(L"找不到足够的空地。", 5);
            return;
        end
        
        local result = self:LLMGenerateBlocksByDesc(user_desc);
        if result ~= true then
            copilot:Say(L"抱歉，生成失败了。", 2);
        end
        return result
    end
end

function BuildSomething:LLMSearchLocalTemplates(user_desc)
    local templates = BuildSomething.GetTemplates();
    if not templates or #templates == 0 then
        return nil;
    end
    
    -- Build a list of template names and descriptions for LLM
    local templateList = {};
    local templateMap = {}; -- Map from description to template object
    for _, template in ipairs(templates) do
        if(template.description) then
            table.insert(templateList, template.description);
            templateMap[template.description] = template;
        end
    end
    
    -- Create LLM prompt
    local prompt = string.format([[You are helping to find relevant 3D building templates.
User wants to build: "%s"

Available templates:
%s

Return up to 5 most relevant template descriptions (one per line), ordered by relevance.
Return ONLY the template descriptions exactly as shown above, nothing else.
If no relevant templates found, return "NONE".]], 
        user_desc, 
        table.concat(templateList, "\n"));
    -- Log the prompt for debugging
    -- LOG.std(nil, "debug", "BuildSomething", "LLM prompt for template search:\n%s", prompt);
    
    self.copilot:Say(L"正在搜索相关模板...", 2);
    
    -- Call LLM with streaming
    self.copilot:CallLLM(prompt, {stream = true});
    
    local matchedDescriptions = {};
    local matchedTemplates = {};
    
    while true do
        if self:CheckStopRequested() then return nil end
        self:CheckPaused();
        
        local line, fullResult = self.copilot:GetStreamedLLMResult(true);
        if line == false then break end
        
        if line and line ~= "" then
            -- Trim whitespace
            line = line:match("^%s*(.-)%s*$");
            
            -- Skip if NONE or empty
            if line ~= "NONE" and line ~= "" then
                -- Try to find matching template
                if templateMap[line] then
                    table.insert(matchedDescriptions, line);
                    table.insert(matchedTemplates, templateMap[line]);
                    -- Show all matched templates so far
                    local matchedDescText = table.concat(matchedDescriptions, "、");
                    self.copilot:Say(string.format(L"找到模板：%s", matchedDescText), 2);
                end
            end
        end
    end
    
    -- If no matches found, return nil
    if #matchedTemplates == 0 then
        self.copilot:Say(L"没有找到相关的模板。", 2);
        return nil;
    end
    
    -- If only one match, return it directly
    if #matchedTemplates == 1 then
        return matchedTemplates[1];
    end
    
    -- Multiple matches: let user choose
    -- Build choice buttons
    local choices = {};
    for i, desc in ipairs(matchedDescriptions) do
        table.insert(choices, {text = desc, default = (i == 1)});
    end
    table.insert(choices, L"取消");
    
    local answer, btnIndex = self.copilot:Ask(L"请选择要建造的模板：", choices);
    
    if btnIndex > 0 and btnIndex <= #matchedTemplates then
        return matchedTemplates[btnIndex];
    else
        return nil;
    end
end


-- Compute bounding box and placement radius for template blocks
function BuildSomething:ComputeTemplateBounds(blocks)
	local minX, minY, minZ = math.huge, math.huge, math.huge;
	local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge;
	for _, b in ipairs(blocks) do
		local x, y, z = b[1], b[2], b[3];
		minX = math.min(minX, x); minY = math.min(minY, y); minZ = math.min(minZ, z);
		maxX = math.max(maxX, x); maxY = math.max(maxY, y); maxZ = math.max(maxZ, z);
	end

	local width = maxX - minX + 1;
	local depth = maxZ - minZ + 1;
	local radius = math.ceil(math.max(width, depth) / 2 + 1);

	return {
		minX = minX, minY = minY, minZ = minZ,
		maxX = maxX, maxY = maxY, maxZ = maxZ,
		radius = radius,
	};
end


function BuildSomething:LLMChangeTemplateTextureByDesc(user_desc, template)
    -- 1. Check if color change is needed
    local prompt_check = string.format([[You are a voxel artist.
User description(wants): "%s"
User selected reference: "%s"
Does the user specified any colors or textures in its description?
Answer YES or NO.]], user_desc, template.description or template.name);

    self.copilot:Say(L"正在分析需求...", 2);
    local result = self.copilot:CallLLM(prompt_check);
    -- Log the prompt and result for debugging
    LOG.std(nil, "debug", "BuildSomething", "LLM prompt for color check:\n%s", prompt_check);
    LOG.std(nil, "debug", "BuildSomething", "LLM result for color check: %s", tostring(result));
    if not result or not result:match("YES") then
        self.copilot:Say(L"不需要修改颜色。", 2);
        return template;
    end

    -- 2. Load blocks
    local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
    local filename = template.file;
    local fullpath = Files and (Files.GetWorldFilePath(filename) 
        or (not filename:match("[/\\]") and Files.GetWorldFilePath("blocktemplates/"..filename)));
        
    if not fullpath or not ParaIO.DoesFileExist(fullpath, true) then
         self.copilot:Say(L"找不到模板文件。", 2);
         return nil;
    end

    local tmpl = BlockTemplate:new({filename = fullpath});
    local ok, blocks, liveEntities = tmpl:LoadTemplateToMemory(fullpath);
    
    if not ok or not blocks then
        self.copilot:Say(L"无法加载模板方块。", 2);
        return nil;
    end

    if (#blocks > 0) then
        local bounds = self:ComputeTemplateBounds(blocks);
        local cx = math.floor((bounds.minX + bounds.maxX) / 2);
        local cz = math.floor((bounds.minZ + bounds.maxZ) / 2);
        local cy = bounds.minY;
        for _, b in ipairs(blocks) do
            b[1] = b[1] - cx;
            b[2] = b[2] - cy;
            b[3] = b[3] - cz;
        end
    end

    -- 3. Convert blocks to text
    local block_lines = {};
    local block_map = {}; -- map "x,y,z" to index in blocks
    
    for i, b in ipairs(blocks) do
        local x, y, z, id, data = b[1], b[2], b[3], b[4], b[5];
        local color_hex = "#ffffff"; -- default
        
        local block = block_types.get(id);
        if block then
             local color_int = block:GetBlockColorByData(data);
             local r, g, b = Color.DWORD_TO_RGBA(color_int);
             color_hex = string.format("#%02x%02x%02x", r, g, b);
        end
        table.insert(block_lines, string.format("%d,%d,%d,%s", x, y, z, color_hex));
        block_map[string.format("%d,%d,%d", x, y, z)] = i;
    end
    
    local block_text = table.concat(block_lines, "\n");
    
    -- 4. Call LLM to generate changes
    local prompt_gen = string.format([[You are a voxel artist.
User wants: "%s"
All 3D coordinates are Y-up (x, y, z).
Original blocks (x,y,z,#color):
%s

Return ONLY the blocks that need to change color in format:
x,y,z,#newcolor
Do not return blocks that do not change.]], user_desc, block_text);

    self.copilot:Say(L"正在重新设计颜色...", 2);
    self.copilot:CallLLM(prompt_gen, {stream = true});
    
    -- 5. Process stream and update blocks
    local groupindex_preview = 2;
    
    -- Find a spot to visualize
    local radius = 5; 
    local originBX, originBY, originBZ = self.copilot:FindEmptySquareGround(radius, 30, 3);
    if originBX then
        self.copilot:WalkTo(originBX, originBY, originBZ);
        local player = EntityManager.GetFocus();
        if(player) then
            self.copilot:TurnTo(player:GetPosition());
        end
        -- Show original blocks first
        ParaTerrain.DeselectAllBlock(groupindex_preview);
        for _, b in ipairs(blocks) do
            local wx, wy, wz = originBX + b[1], originBY + b[2], originBZ + b[3];
            ParaTerrain.SelectBlock(wx, wy, wz, true, groupindex_preview);
        end
    end
    
    local changed_count = 0;
    
    while true do
        if self:CheckStopRequested() then return end
        self:CheckPaused();
        
        local line, fullResult = self.copilot:GetStreamedLLMResult(true);
        if line == false then break end
        
        if line and line ~= "" then
             local x, y, z, color_hex = line:match("([%-%d]+)%s*,%s*([%-%d]+)%s*,%s*([%-%d]+)%s*,%s*(#[%x]+)");
             if x and y and z and color_hex then
                 x, y, z = tonumber(x), tonumber(y), tonumber(z);
                 local key = string.format("%d,%d,%d", x, y, z);
                 local idx = block_map[key];
                 
                 if idx then
                     -- Update block
                     local r, g, b = color_hex:match("#(%x%x)(%x%x)(%x%x)");
                     if r and g and b then
                        r = tonumber(r, 16);
                        g = tonumber(g, 16);
                        b = tonumber(b, 16);
                        local color_int = Color.RGBA_TO_DWORD(r, g, b, 255);
                        
                        -- Only change block ID if the block doesn't support color data
                        local old_block_id = blocks[idx][4];
                        local old_block = block_types.get(old_block_id);
                        
                        if old_block and old_block:HasColorData() then
                            -- Block already supports color data, just update the data
                            local item = old_block:GetItem();
                            if item then
                                blocks[idx][5] = item:ColorToData(color_int);
                            end
                        elseif old_block and old_block.solid then
                            -- Solid cube block without color support, replace with ColorBlock
                            local block_id = block_types.names.ColorBlock;
                            local block = block_types.get(block_id);
                            if block then
                                local item = block:GetItem();
                                if item then
                                    blocks[idx][4] = block_id;
                                    blocks[idx][5] = item:ColorToData(color_int);
                                end
                            end
                        else
                            -- Other block types (stairs, slabs, etc.), leave unchanged
                            -- Don't modify this block
                        end
                        
                        changed_count = changed_count + 1;
                        
                        if changed_count % 5 == 0 then
                             self.copilot:Say(string.format(L"已修改 %d 个方块...", changed_count), 1);
                        end
                     end
                 end
             end
        end
    end
    
    if changed_count > 0 then
        self.copilot:Say(string.format(L"已修改 %d 个方块，开始建造！", changed_count), 2);
        
        local newTemplate = {
            name = template.name,
            blocks = blocks,
            liveEntities = liveEntities,
            buildOrigin = originBX and {originBX, originBY, originBZ} or nil,
        };
        return newTemplate;
    else
        self.copilot:Say(L"没有进行任何修改。", 2);
        return template;
    end
end

function BuildSomething:LLMGenerateBlocksByDesc(user_desc)
    local blockLimit = self.blockLimit or 100;
    local prompt = string.format([[[
You are a 3D voxel architect. Generate a design for "%s".
All 3D coordinates are Y-up (x, y, z).
Output format:
Line 1: bounding_xz=width,depth
Line 2+: x,y,z,#color
y must be >= 0. try finish within %d blocks.
Example:
bounding_xz:3,3
0,0,0,#ff0000
1,0,0,#ffffff
...
]], user_desc, blockLimit)

    self.copilot:CallLLM(prompt, {stream = true});
    
    local blocks = {};
    local originBX, originBY, originBZ;
    local groupindex_preview = 2;
    local firstLineProcessed = false;
    local width, depth;
    
    while true do
        if self:CheckStopRequested() then return end
        self:CheckPaused();
        
        local line, fullResult = self.copilot:GetStreamedLLMResult(true);
        if line == false then break end
        
        if line and line ~= "" then
            if not firstLineProcessed then
                -- Parse width, depth from "bounding_xz=width,depth" or "bounding_xz:width,depth"
                local w, d = line:match("bounding_xz[:=]%s*(%d+)%s*,%s*(%d+)");
                if w and d then
                    width = tonumber(w);
                    depth = tonumber(d);
                    firstLineProcessed = true;
                    
                    -- Find free location
                    local radius = math.ceil(math.max(width, depth) / 2 + 1);
                    originBX, originBY, originBZ = self.copilot:FindEmptySquareGround(radius, radius * 2 + 5, 3);
                    
                    if originBX then
                        self.copilot:WalkTo(originBX, originBY, originBZ);
                        local player = EntityManager.GetFocus();
                        if(player) then
                            self.copilot:TurnTo(player:GetPosition());
                        end
                        self.copilot:Say(L"我找到了一个空地，开始设计...", 2);
                        ParaTerrain.DeselectAllBlock(groupindex_preview);
                    else
                        self.copilot:Say(L"找不到足够的空地。", 2);
                        self.copilot:AbortLLM();
                        return nil;
                    end
                end
            else
                -- Parse x, y, z, #color
                local x, y, z, color_hex = line:match("([%-%d]+)%s*,%s*([%-%d]+)%s*,%s*([%-%d]+)%s*,%s*(#[%x]+)");
                if x and y and z and color_hex then
                    x = tonumber(x);
                    y = tonumber(y);
                    z = tonumber(z);
                    
                    -- Convert color to block_id and data
                    local block_id = block_types.names.ColorBlock; -- ID 10
                    local block_data = 0;
                    
                    local r, g, b = color_hex:match("#(%x%x)(%x%x)(%x%x)");
                    if r and g and b then
                        r = tonumber(r, 16);
                        g = tonumber(g, 16);
                        b = tonumber(b, 16);
                        local color_int = Color.RGBA_TO_DWORD(r, g, b, 255);
                        
                        local block = block_types.get(block_id);
                        if block then
                             local item = block:GetItem();
                             if item then
                                 block_data = item:ColorToData(color_int);
                             end
                        end
                    end
                    
                    if originBX then
                        local wx, wy, wz = originBX + x, originBY + y, originBZ + z;
                        ParaTerrain.SelectBlock(wx, wy, wz, true, groupindex_preview);
                        table.insert(blocks, {x, y, z, block_id, block_data});
                        
                        if #blocks % 5 == 0 then
                            self.copilot:Say(string.format(L"已设计 %d 个方块...", #blocks), 1);
                        end
                    end
                end
            end
        end
    end
    
    if #blocks > 0 and originBX then
        self.copilot:Say(L"设计完成，开始建造！", 2);
        
        -- Sort blocks by y first, then by x, z for more natural building order
        table.sort(blocks, function(a, b)
            if a[2] ~= b[2] then
                return a[2] < b[2]; -- Sort by y (height) first
            elseif a[1] ~= b[1] then
                return a[1] < b[1]; -- Then by x
            else
                return a[3] < b[3]; -- Finally by z
            end
        end);

        local newTemplate = {
            blocks = blocks,
            liveEntities = {},
            buildOrigin = {originBX, originBY, originBZ},
        };
        local success = self:BuildObject(self.copilot, newTemplate);
        if success then
             self.copilot:Say(L"建造完成！", 2);
             return true;
        else
             self.copilot:Say(L"建造被取消或失败。", 2);
             return false;
        end
    else
        if not originBX then
             -- Already handled error message
        else
             self.copilot:Say(L"生成失败或没有方块。", 2);
        end
        return nil;
    end
end

function BuildSomething:BuildBlocks(copilot, blocks)
    if not blocks or #blocks == 0 then return end
    
    -- Compute bounds using existing helper
    local bounds = self:ComputeTemplateBounds(blocks) or {};
    local minX, minY, minZ = bounds.minX or 0, bounds.minY or 0, bounds.minZ or 0;
    local maxX, maxY, maxZ = bounds.maxX or 0, bounds.maxY or 0, bounds.maxZ or 0;
    local radius = bounds.radius or 0;
    
    local template = {
        name = self.name or "FromBuildSomething",
        blocks = blocks,
        liveEntities = {},
    };
    
    local success = self:BuildObject(copilot, template);
    if success then
        copilot:Say(L"建造完成！", 2);
        self.state = self.STATE_COMPLETED;
        self:SetTaskResult(true);
    else
        copilot:Say(L"建造失败。", 2);
        self.state = self.STATE_FAILED;
        self:SetTaskResult(false);
    end
end

function BuildSomething:GetActionButtons(buttons)
    buttons = BuildSomething._super.GetActionButtons(self, buttons) or {};
    
    if self.allowQuickFinishBuild then
         table.insert(buttons, 1, {
            text = L"快速完成",
            name = "QuickFinishBuild",
        });
    end
    return buttons;
end

function BuildSomething:OnClickActionButton(actionName)
    if actionName == "QuickFinishBuild" and self.currentSubTask then
        self.currentSubTask:OnClickActionButton(actionName);
    else
        BuildSomething._super.OnClickActionButton(self, actionName);
    end
end

function BuildSomething:BuildObject(copilot, template)
    if not template then
        return false;
    end
    
    -- Use BuildBlockTemplate task for both standalone and guide modes
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/BuildBlockTemplate.task.lua");
    local BuildBlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.BuildBlockTemplate");
    
    local taskParams = {
        displayName = template.name,
        alwaysShowBuildTargetWireFrame = true,
        allowUserCancel = true,
        buildSpeed = 2.0,
        autoSaveToBmax = true,
        allowQuickFinishBuild = self.allowQuickFinishBuild,
        -- Forward build mode params to BuildBlockTemplate
        buildMode = self.buildMode,
        autoAssistThreshold = self.autoAssistThreshold,
    };

    if(template.blocks) then
        taskParams.template = {
            blocks = template.blocks,
            liveEntities = template.liveEntities or {},
        };
        if(template.buildOrigin) then
            taskParams.buildOrigin = template.buildOrigin;
        end
    elseif(template.file) then
        -- Check if template file exists
        NPL.load("(gl)script/ide/System/localserver/factory.lua");
        local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
        local fullpath = Files and (Files.GetWorldFilePath(template.file) 
            or (not template.file:match("[/\\]") and Files.GetWorldFilePath("blocktemplates/"..template.file)));
        
        if not fullpath or not ParaIO.DoesFileExist(fullpath, true) then
            copilot:Say(string.format(L"找不到模板文件：%s", template.file), 3);
            LOG.std(nil, "warn", "BuildSomething", "Template file not found: %s (fullpath: %s)", 
                template.file, tostring(fullpath));
            return false;
        end
        taskParams.filename = template.file;
    else
        copilot:Say(L"错误：模板信息不完整", 3);
        LOG.std(nil, "error", "BuildSomething", "Invalid template: %s", tostring(template));
        return false;
    end
    
    local task = BuildBlockTemplate:new():Init(copilot, taskParams);
    self.currentSubTask = task;
    local runStatus =self:StartSubTask(task);
    local result = self.currentSubTask:GetTaskResult();
    self.currentSubTask = nil;
    return result;
end

function BuildSomething:OnPauseByUser()
    if self.currentSubTask then
        self.currentSubTask:OnPauseByUser();
    end
end

function BuildSomething:OnStopByUser()
    if self.currentSubTask then
        self.currentSubTask:OnStopByUser();
    end
end
