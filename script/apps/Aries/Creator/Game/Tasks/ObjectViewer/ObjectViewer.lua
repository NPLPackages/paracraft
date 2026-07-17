--[[
Title: ObjectViewer
Author(s): wxa
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ObjectViewer/ObjectViewer.lua");
local ObjectViewer = commonlib.gettable("MyCompany.Aries.Game.Tasks.ObjectViewer");
-------------------------------------------------------
]] -- ObjectViewer
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityMovable.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
NPL.load("(gl)script/ide/timer.lua");
NPL.load("(gl)script/ide/Json.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
local Screen = commonlib.gettable("System.Windows.Screen");
local NPLJS = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NPLJS.lua");
local EntityMovable = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityMovable")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local ObjectViewer = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Tasks.ObjectViewer"));
local lfs = commonlib.Files.GetLuaFileSystem();

function ObjectViewer:ctor() 
end

function ObjectViewer:SendMsg(msgdata, msgid)
    NPLJS:SendMsg("ObjectViewer", msgdata, msgid);
end

function ObjectViewer:OnMsg(msgdata, msgid)
    msgdata = msgdata or {}
    local action = msgdata.action;
    if (action == "ModelInfo") then
        local model_info = self:GetModelInfo();
        model_info.action = "ModelInfo";
        self:SendMsg(model_info, msgid);
    elseif (action == "Close") then
        self:Close();
    elseif (action == "SelectModelFile") then
        self:SelectModelFile(function(filepath)
            self:SetModelFilePath(filepath);
        end)        
    elseif (action == "SetModelFilePath") then
        if (msgdata.filepath_base64) then
            msgdata.filepath = CommonLib.DecodeBase64(msgdata.filepath_base64);
        end
        self:SetModelFilePath(msgdata.filepath); 
    elseif (action == "SetLookAt") then
        self:SetLookAt(msgdata.lookat, msgid);
    elseif (action == "SetPosition") then
        self:SetPosition(msgdata.x, msgdata.y, msgdata.z);
    elseif (action == "SetRotation") then
        self:SetRotation(msgdata.rotation);
    elseif (action == "SetScaling") then
        self:SetScaling(msgdata.scaling);
    elseif (action == "SaveConfig") then
        self:SaveConfig();    
    elseif (action == "SaveModel") then
        local config_text = self:GetConfigByFilePath(self.m_filepath);
        if (ParaAsset.ConvertGLB) then
            ParaAsset.ConvertGLB(config_text);
            local fileitem = self.m_filemap[self.m_filepath] or {};
            fileitem.output = true;
        end
    elseif (action == "RefreshModelList") then
        self:LoadModelFileList(CommonLib.GetDirectory(self.m_filepath), true);
        self:SendMsg({filelist = self.m_filelist}, msgid); 
    elseif (action == "SetNameTags") then
        self:SetNameTags(msgdata.name, msgdata.tags);        
    end
end

function ObjectViewer:SetNameTags(name, tags)
    if (not self.m_filepath) then return end
    local fileitem = self:GetFileItemByFilePath(self.m_filepath);
    if (name) then name = self:JsStringToLuaString(name) end
    if (tags) then
        for i, tag in ipairs(tags) do
            tags[i] = self:JsStringToLuaString(tag);
        end
    end
    fileitem.name = name or fileitem.name;
    fileitem.tags = tags or fileitem.tags;
    self:SaveConfig();
end

function ObjectViewer:LuaStringToJsString(str)
    if (not str or str == "") then return str end
    local str_len = string.len(str);
    local text = "";
    for i = 1, str_len do
        local c = string.byte(str, i);
        local hex = string.format("%02X", c);
        text = text .. (text == "" and "" or ",") .. hex;
    end
    return text;
end

function ObjectViewer:JsStringToLuaString(text)
    if (not text or text == "") then return text end
    local bytes = CommonLib.String.Split(text, ",");
    local str = ""
    for _, byteValue in ipairs(bytes) do
        byteValue = tonumber("0x" .. byteValue, 16);
        str = str .. string.char(byteValue)
    end
    return str
end

function ObjectViewer:GetModelInfo() 
    local bx, by, bz = self.m_entity:GetBlockPos();
    local directory = CommonLib.GetDirectory(self.m_filepath);
    local fileitem = self:GetFileItemByFilePath(self.m_filepath);
    self:LoadModelFileList(directory);
    if (fileitem and fileitem.tags and not next(fileitem.tags)) then fileitem.tags = nil end
    local name = self:LuaStringToJsString(fileitem and fileitem.name);
    local tags = {};
    local fileitem_tags = fileitem and fileitem.tags or {};
    for i, tag in ipairs(fileitem_tags) do
        tags[i] = self:LuaStringToJsString(tag);
    end

    local info = {
        filepath = self.m_filepath,
        filelist = self.m_filelist,
        output_filemap = self.m_output_filemap,
        bx = bx, by = by, bz = bz,
        position_x = self.m_entity_position_x,
        position_y = self.m_entity_position_y,
        position_z = self.m_entity_position_z,
        rotation_y = self.m_entity_rotation_y,
        scaling = self.m_entity_scaling,
        name = name,
        tags = tags,
    };
    local attr = self.m_attr;
    if (attr) then
        info.poly_count = attr:GetField("PolyCount");  -- 多边形的数量
        info.bone_count = attr:GetChildCount(0); -- 骨骼数量
        info.texture_count = attr:GetChildCount(1); -- 纹理数量
        info.textures = {};  -- 纹理文件名列表
        for index = 1, info.texture_count do
            info.textures[index] = attr:GetChildAt(index, 1):GetField("LocalFileName", "");
        end
        info.animations = attr:GetField("strAnimIds"); -- 动画ID列表 xx;xx;xx
    end
    return info;
end

function ObjectViewer:SaveConfigToFileItem(filepath)
    local fileitem = self:GetFileItemByFilePath(filepath or self.m_filepath);
    if (not fileitem) then return end
    local zero = 0.0001;
    local is_change = math.abs(self.m_entity_position_x - self.m_entity_default_position_x) > zero;
    is_change = is_change or math.abs(self.m_entity_position_y - self.m_entity_default_position_y) > zero;
    is_change = is_change or math.abs(self.m_entity_position_z - self.m_entity_default_position_z) > zero;
    is_change = is_change or math.abs(self.m_entity_rotation_y - self.m_entity_default_rotation_y) > zero;
    is_change = is_change or math.abs(self.m_entity_scaling - self.m_entity_default_scaling) > zero;
    if (not is_change) then return end
    fileitem.position_x = self.m_entity_position_x - self.m_entity_default_position_x;
    fileitem.position_y = self.m_entity_position_y - self.m_entity_default_position_y;
    fileitem.position_z = self.m_entity_position_z - self.m_entity_default_position_z;
    fileitem.rotation_x = 0;
    fileitem.rotation_y = self.m_entity_rotation_y - self.m_entity_default_rotation_y;
    fileitem.rotation_z = 0;
    fileitem.scaling = self.m_entity_scaling;
end

function ObjectViewer:SetModelFilePath(filepath)
    if (not filepath or filepath == "") then return end
    filepath = CommonLib.ToCanonicalFilePath(filepath);
    if (self.m_filepath == filepath) then return end
    self:SaveConfigToFileItem();

    self.m_entity:SetMainAssetPath(filepath);
    self.m_entity:RefreshClientModel();
    if (self.m_bx and self.m_by and self.m_bz) then
        self.m_entity:SetBlockPos(self.m_bx, self.m_by, self.m_bz);
    else 
        self.m_entity:SetBlockPos(self.m_player:GetBlockPos());
    end

    self.m_entity_default_position_x, self.m_entity_default_position_y, self.m_entity_default_position_z = self.m_entity:GetPosition();
    self.m_entity_position_x, self.m_entity_position_y, self.m_entity_position_z = self.m_entity:GetPosition();
    self.m_entity_default_rotation_y = self.m_entity:GetFacing();
    self.m_entity_rotation_y = self.m_entity:GetFacing();
    self.m_entity_default_scaling = self.m_entity:GetScaling();
    self.m_entity_scaling = self.m_entity:GetScaling();
    self.m_filepath = filepath;
    self.m_attr = nil;

    local fileitem = self:GetFileItemByFilePath(filepath);
    if (fileitem and fileitem.position_x and fileitem.position_y and fileitem.position_z and fileitem.rotation_x and fileitem.rotation_y and fileitem.rotation_z and fileitem.scaling) then
        self:SetPosition(fileitem.position_x, fileitem.position_y, fileitem.position_z);
        self:SetRotation(fileitem.rotation_y);
        self:SetScaling(fileitem.scaling - self.m_entity_default_scaling);
    end

    self:LoadModelAttr(filepath, function()
        local model_info = self:GetModelInfo();
        model_info.action = "ModelInfo";
        self:SendMsg(model_info);
    end)

    Files:UnloadAllUnusedAssets();
end

function ObjectViewer:LoadModelAttr(filepath, callback)
	local asset = ParaAsset.LoadParaX(filepath, filepath);
	asset:LoadAsset();
	if(asset:IsLoaded()) then
        self.m_attr = asset:GetAttributeObject():GetChildAt(0);
        if (callback) then callback() end
    else
		local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
			if(asset:IsLoaded()) then
				timer:Change();
                self.m_attr = asset:GetAttributeObject():GetChildAt(0);
                if (callback) then callback() end
			elseif(not asset:IsValid()) then
				timer:Change();
			end
		end})
		mytimer:Change(0, 300);
	end
	return self;
end

function ObjectViewer:SetLookAt(lookat, msgid)
    if (not self.m_filepath) then return end
    local pos = commonlib.split_by_str(lookat, ",");
    if (not pos or #pos ~= 3) then return end
    self.m_bx = tonumber(pos[1]);
    self.m_by = tonumber(pos[2]);
    self.m_bz = tonumber(pos[3]);
    self.m_entity:SetBlockPos(self.m_bx, self.m_by, self.m_bz);
    self.m_entity_default_position_x, self.m_entity_default_position_y, self.m_entity_default_position_z = self.m_entity:GetPosition();
    self.m_entity_position_x, self.m_entity_position_y, self.m_entity_position_z = self.m_entity:GetPosition();
end

function ObjectViewer:SetPosition(x, y, z) 
    if (not self.m_filepath) then return end
    self.m_entity_position_x = self.m_entity_position_x + (x or 0);
    self.m_entity_position_y = self.m_entity_position_y + (y or 0);
    self.m_entity_position_z = self.m_entity_position_z + (z or 0);
    self.m_entity:SetPosition(self.m_entity_position_x , self.m_entity_position_y, self.m_entity_position_z); 
end

function ObjectViewer:SetRotation(rotation)
    if (not self.m_filepath) then return end
    if (not rotation) then return end
    local angle = mathlib.ToStandardAngle(rotation * math.pi / 180)
    self.m_entity_rotation_y = self.m_entity_rotation_y + angle;
    self.m_entity:SetFacing(self.m_entity_rotation_y);
end

function ObjectViewer:SetScaling(scaling)
    if (not self.m_filepath) then return end
    if (not scaling) then return end
    self.m_entity_scaling = self.m_entity_scaling + scaling;
    self.m_entity:SetScaling(self.m_entity_scaling);
end

function ObjectViewer:Open(callback, env)
    if (self.m_opened) then return end
    self.m_opened = true;
    self.m_player = EntityManager.GetPlayer();
    self.m_entity = EntityMovable:new();
    self.m_entity:SetName("ObjectViewer");
    self.m_entity:SetBlockPos(self.m_player:GetBlockPos())
    self.m_entity:CreateInnerObject(self.m_entity:GetMainAssetPath(), true, 0, 1);
    self.m_entity:RefreshClientModel();
    self.m_entity:Attach();

    local screen_width = Screen:GetWidth();
    local screen_height = Screen:GetHeight();
    local ObjectViewerWidth = screen_width / 2;
    local ObjectViewerHeight = screen_height;

    local viewport = ViewportManager:GetSceneViewport();
    viewport:SetMarginRight(ObjectViewerWidth);
    viewport:SetMarginRightHandler(self);

    local url = "https://webparacraft.keepwork.com/object_viewer/index.html";
    if (env == "dev") then
        url = "https://emscripten.keepwork.com/object_viewer/index.html";
    elseif (env == "local") then
        url = "http://127.0.0.1:8088/npl/webparacraft/object_viewer/index.local.html";
    else 
        url = "https://webparacraft.keepwork.com/object_viewer/index.html";
    end
    NPLJS:Open(url, function()
        NPLJS:OnMsg("ObjectViewer", function(...)
            ObjectViewer:OnMsg(...)
        end);
        
        -- self:SelectModelFile(function(filepath)
        --     if (filepath) then
        --         self:SetModelFilePath(filepath);
        --     end
        --     if (type(callback) == "function") then
        --         callback();
        --     end
        -- end);

        if (type(callback) == "function") then
            callback();
        end
    end, screen_width - ObjectViewerWidth, screen_height - ObjectViewerHeight, ObjectViewerWidth, ObjectViewerHeight);
end

function ObjectViewer:Close()
    self.m_opened = false;
    self.m_directory = nil;
    self.m_filepath = nil;
    self.m_filemap = nil;
    self.m_attr = nil;
    self.m_filelist = {};
    if (self.m_entity) then
        self.m_entity:Destroy();
        self.m_entity = nil;
    end
    NPLJS:Close();
    local viewport = ViewportManager:GetSceneViewport();
    viewport:SetMarginRight(0);
    viewport:SetMarginRightHandler(nil);
end

function ObjectViewer:SelectModelFile(callback)
    NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenFileDialog.lua");
	local OpenFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenFileDialog");
    OpenFileDialog.ShowPage("模型文件路径:", function(filepath)
        if (filepath and filepath ~= "") then
            filepath = Files.WorldPathToFullPath(filepath, true) or filepath;
        else 
            filepath = nil;
        end
        callback(filepath);
    end, "", "选择模型", "glb");
end

function ObjectViewer:LoadModelFileList(directory, force)
    if (not directory or directory == "") then 
        directory = CommonLib.GetWorldDirectory() .. "blocktemplates/";
    end
    if (directory == self.m_directory and not force) then return end
    
    self:SaveConfig();
    print("==================ObjectViewer:LoadModelFileList================", directory);
    local list = CommonLib.GetFileList(directory);
    local filelist = {};
    local filemap = {};
    for _, file in ipairs(list) do
        if (CommonLib.EndsWith(file.file_path, ".glb")) then
            local fileitem = {filepath = file.file_path};
            fileitem.filename = CommonLib.GetFileName(file.file_path);
            fileitem.filepath_base64 = CommonLib.EncodeBase64(file.file_path);
            table.insert(filelist, fileitem);
            filemap[fileitem.filepath] = fileitem;
        end
    end

    self.m_directory = directory;
    self.m_filelist = filelist;
    self.m_filemap = filemap;

    local output_list = CommonLib.GetFileList(directory .. "output/");
    local output_filemap = {};
    for _, file in ipairs(output_list) do
        if (CommonLib.EndsWith(file.file_path, ".glb")) then
            local fileitem = {filepath = file.file_path};
            fileitem.filename = CommonLib.GetFileName(file.file_path);
            output_filemap[fileitem.filename] = fileitem;
        end
    end

    for _, file in pairs(filemap) do
        local filename = file.filename;
        local output_fileitem = output_filemap[filename];
        if (output_fileitem) then
            file.output_filepath = output_fileitem.filepath;
            file.output_filepath_base64 = CommonLib.EncodeBase64(output_fileitem.filepath);
            file.output = true;
        end
    end
    self.m_output_filemap = output_filemap;
    CommonLib.Table.Sort(filelist, function(a, b)
        if (a.output and not b.output) then
            return true;
        elseif (not a.output and b.output) then
            return false;
        else
            return string.lower(a.filename) > string.lower(b.filename);
        end
    end);
    ParaIO.CreateDirectory(self.m_directory .. "output/");

    self:LoadConfig();
end

function ObjectViewer:GetFileItemByFilePath(filepath)
    if (not filepath) then return end 
    self.m_filemap = self.m_filemap or {};
    return self.m_filemap[filepath];
end

function ObjectViewer:GetConfigByFilePath(filepath)
    self:SaveConfigToFileItem(filepath);
    local fileitem = self:GetFileItemByFilePath(filepath);
    if (not fileitem) then return end
    local output_filepath = CommonLib.ToCanonicalFilePath(CommonLib.GetDirectory(filepath) .. "output/" .. CommonLib.GetFileName(filepath));
    local config_text = "";
    if (fileitem.position_x and fileitem.position_y and fileitem.position_z and fileitem.rotation_x and fileitem.rotation_y and fileitem.rotation_z and fileitem.scaling) then
        config_text = config_text .. fileitem.filepath .. ",";
        config_text = config_text .. tostring(fileitem.position_x) .. " " .. tostring(fileitem.position_y) .. " " .. tostring(fileitem.position_z) .. " ";
        config_text = config_text .. tostring(fileitem.rotation_x) .. " " .. tostring(fileitem.rotation_y) .. " " .. tostring(fileitem.rotation_z) .. " ";
        config_text = config_text .. tostring(fileitem.scaling) .. "," .. output_filepath .. "\n";
    end
    return config_text;
end

function ObjectViewer:SaveConfig()
    if (not self.m_directory or not self.m_filemap) then return end
    self:SaveConfigToFileItem();
    local filemap = self.m_filemap or {};
    local json_config = self.m_all_config or {};
    for key, fileitem in pairs(filemap) do
        json_config[key] = {
            filename = fileitem.filename,
            name = fileitem.name,
            tags = fileitem.tags,
        }
    end
    local config_path = self.m_directory .. "output/object_viewer.json";
    local config_text = commonlib.Json.Encode(json_config, true);
    -- print("=============ObjectViewer:SaveConfig()=============")
    -- print(config_path)
    -- echo(json_config, true);
    CommonLib.WriteFile(config_path, config_text);
end

function ObjectViewer:LoadConfig()
    if (not self.m_directory or not self.m_filemap) then return end
    local filemap = self.m_filemap or {};
    local config_path = self.m_directory .. "output/object_viewer.json";
    local config_text = CommonLib.GetFileText(config_path);
    local json_config = commonlib.Json.Decode(config_text);
    -- print("=============ObjectViewer:LoadConfig()=============")
    -- echo(json_config, true)

    self.m_all_config = self.m_all_config or {};
    if (type(json_config) == "table") then
        for filepath, config in pairs(json_config) do
            local fileitem = filemap[filepath];
            if (fileitem) then
                fileitem.name = fileitem.name or config.name;
                fileitem.tags = fileitem.tags or config.tags;
            end
            self.m_all_config[filepath] = config;
        end
    end
end

-- 初始化成单列模式
ObjectViewer:InitSingleton();

-- local result = commonlib.Files.Find({}, "D:/workspace/program/ParacraftDev/worlds/DesignHouse/_user/xiaoyao/model/blocktemplates", 1, 500, function() return true end);
-- echo(result, true)



-- NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ObjectViewer/ObjectViewer.lua", true);
-- local ObjectViewer = commonlib.gettable("MyCompany.Aries.Game.Tasks.ObjectViewer");

-- ObjectViewer:Close();

-- ObjectViewer:Open(function()
--     --ObjectViewer:SetModelFilePath("D:/workspace/program/ParacraftDev/worlds/DesignHouse/_user/xiaoyao/model/blocktemplates/EAGLE.glb")
-- end, "local");
