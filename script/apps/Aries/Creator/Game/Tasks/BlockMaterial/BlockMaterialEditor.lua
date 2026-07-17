--[[
Title: BlockMaterialEditor Task/Command
Author(s): wxa
Date: 2022/11/18
Desc: 
use the lib:
------------------------------------------------------------
local BlockMaterialEditor = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockMaterial/BlockMaterialEditor.lua");
BlockMaterialEditor:Show();
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/Color.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local Color = commonlib.gettable("System.Core.Color");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local BlockMaterialEditor = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

BlockMaterialEditor:Signal("BlockMaterialPicked", function(materialId) end)

function BlockMaterialEditor:ctor()

end

function BlockMaterialEditor:Init()
    self.window = nil;

    self:LoadDefaultMaterials();

    local __self__ = self;
    GameLogic.GetFilters():add_filter("OnWorldLoaded", function()
        -- print("=======================OnWorldLoaded=========================");
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockMaterial/BlockMaterialTask.lua");
        local BlockMaterialTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockMaterialTask");
        BlockMaterialTask.LoadMaterials(true);
        __self__:SetCurrentMaterialID(1);
    end);
    return self;
end

function BlockMaterialEditor:GetPageSize()
    return 18;
end

function BlockMaterialEditor:LoadDefaultMaterials()
    if (self.mDefaultMaterialMap) then return self.mDefaultMaterialMap end 

    -- print("===============LoadDefaultMaterials=================")
    local filename = "config/Aries/creator/block_materials.xml";
	local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
    local mDefaultMaterialMap = self.mDefaultMaterialMap or {};
    for node in commonlib.XPath.eachNode(xmlRoot, "/BlockMaterials/Material") do
        local attr = node.attr or {};
        local ID = math.floor(tonumber(attr.Id or 0));
        attr.BaseColor = attr.BaseColor or "#ffffffff";
        if (string.sub(attr.BaseColor, 1, 1) == "#") then
            attr.BaseColor = self:Color4ToColor3(attr.BaseColor);
        else
            attr.BaseColor = self:Color4ToColor3(self:Vector4ToColor(self:StringToVector4(attr.BaseColor)));
        end
        attr.EmissiveColor = attr.EmissiveColor or "#00000000";
        if (string.sub(attr.EmissiveColor, 1, 1) ~= "#") then
            attr.EmissiveColor = self:Vector4ToColor(self:StringToVector4(attr.EmissiveColor));
        end
        if (ID > 0) then
            mDefaultMaterialMap[ID] = mDefaultMaterialMap[ID] or {};
            -- 以现有默认材质为主
            commonlib.mincopy(mDefaultMaterialMap[ID], {
                ID = ID,
                CategoryName = attr.CategoryName or "未分类",
                MaterialName = attr.MaterialName or "",
                BaseColor = attr.BaseColor,
                Metallic = attr.Metallic or "0",
                Specular = attr.Specular or "0",
                Roughness = attr.Roughness or "0.2",
                Emissive = attr.Emissive or "",
                EmissiveColor = attr.EmissiveColor,
                Opacity = attr.Opacity or "1",
                Normal = attr.Normal or "",
                Diffuse = attr.Diffuse or "",
                MaterialUV = attr.MaterialUV or "1, 1, 0, 0",
            })
        end
    end
    local mDefaultCategoryMap = {};
    for id, material in pairs(mDefaultMaterialMap) do
        mDefaultCategoryMap[material.CategoryName] = mDefaultCategoryMap[material.CategoryName] or {};
        local category = mDefaultCategoryMap[material.CategoryName];
        category[#category + 1] = id;
    end 
    self.mDefaultCategoryMap = mDefaultCategoryMap;
    self.mDefaultMaterialMap = mDefaultMaterialMap;

end

function BlockMaterialEditor:GetDefaultCategoryMap()
    return self.mDefaultCategoryMap;
end

function BlockMaterialEditor:GetDefaultMaterialMap()
    return self.mDefaultMaterialMap;
end

function BlockMaterialEditor:ReplateCurrentMaterial(material)
    local copyMaterial = commonlib.copy(material);
    local ID = self:GetCurrentMaterialID();
    copyMaterial.ID = ID;
    self:UpdateMaterial(copyMaterial);
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockMaterial/BlockMaterialTask.lua");
    local BlockMaterialTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockMaterialTask");
    BlockMaterialTask.RefreshMaterials();
end

function BlockMaterialEditor:AddMaterial(material)
    local copyMaterial = commonlib.copy(material);
    copyMaterial.ID = #(self.mMaterialList) + 1;
    self:NewMaterial(copyMaterial);
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockMaterial/BlockMaterialTask.lua");
    local BlockMaterialTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockMaterialTask");
    BlockMaterialTask.Refresh();
end

function BlockMaterialEditor:ShowMaterialListPage(onCloseCallback)
    local Vue = NPL.load("script/ide/System/UI/Vue/Vue.lua");
    self.material_list_window = Vue:new();
    if (IsDevEnv) then
        if (_G.BlockMaterialListWindow) then _G.BlockMaterialListWindow:CloseWindow() end
        _G.BlockMaterialListWindow = self.material_list_window;
    end
    __self__ = self;
    self.material_list_window:Show({
		windowName = "BlockMaterialList", 
		url="script/apps/Aries/Creator/Game/Tasks/BlockMaterial/BlockMaterialList.html",
		width = 540, height = 580,
        G = {},
        -- draggable = false,
        OnClose = onCloseCallback,
	});
end

function BlockMaterialEditor:GetMaterialList()
    return self.mMaterialList;
end

function BlockMaterialEditor:GetMaterialMap()
    return self.mMaterialMap;
end

function BlockMaterialEditor:Close()
    if (not self.window) then return end 
    self.window:CloseWindow();
    self.window = nil;
end

function BlockMaterialEditor:Refresh()
    if (not self.window) then return end 
    self.window:GetG().RefreshMaterialList(self.mMaterialList);
end

function BlockMaterialEditor:Show(curMaterialId, onCloseCallback)
    local Vue = NPL.load("script/ide/System/UI/Vue/Vue.lua");

    self:SetCurrentMaterialID(curMaterialID);

    self:Close();
    self.window = Vue:new();

    if (IsDevEnv) then
        if (_G.BlockMaterialWindow) then _G.BlockMaterialWindow:CloseWindow() end
        _G.BlockMaterialWindow = self.window;
    end

    __self__ = self;
    self.window:Show({
		windowName = "BlockMaterial", 
		url="script/apps/Aries/Creator/Game/Tasks/BlockMaterial/BlockMaterialEditor.html",
        alignment = "_lt",
		width = 628, height = 720,
        x = 0, y = 0,
        G = {
            MaterialList = self.mMaterialList,
            MaterialId = self:GetCurrentMaterialID(),
            CreateMaterial = function(material) return __self__:NewMaterial(material) end, 
            UpdateMaterial = function(material) return __self__:UpdateMaterial(material) end, 
            DeleteMaterial = function(material) return __self__:DeleteMaterial(material) end, 
            SelectMaterial = function(material) return __self__:SelectMaterial(material) end, 
            OpenImageDialog = function(callback, old_value) BlockMaterialEditor:OpenImageDialog(callback, old_value) end,
            OnClose = onCloseCallback,
        },
        -- draggable = false,
	});

    self:Refresh();
end

function BlockMaterialEditor:GetTextureDiskFilePath(filename)
    if (not filename or filename == "") then return "" end 
	local filepath = Files.GetFilePath(commonlib.Encoding.Utf8ToDefault(filename));
    return filepath == "" and filename or filepath;
end

function BlockMaterialEditor:Vector4ToColor(v)
    v = v or {};
    return Color.RGBAfloat_TO_ColorStr(v[1] or 1.0, v[2] or 1.0, v[3] or 1.0, v[4] or 1.0);
end

function BlockMaterialEditor:ColorToVector4(color, defaultValue)
    local r, g, b, a = Color.ColorStr_TO_RGBAfloat(color or defaultValue or "#ffffffff");
    return {r, g, b, a or 1.0};
end

function BlockMaterialEditor:Color4ToColor3(color)
    local size = string.len("#ffffffff")
    color = color or "#ffffffff";
    return string.len(color) == size and (string.sub(color , 1, size - 2)) or color;
end

function BlockMaterialEditor:Color3ToColor4(color, alpha)
    if (type(alpha) == "number") then
        alpha = alpha > 255 and 255 or alpha;
        alpha = alpha < 0 and 0 or alpha;
        alpha = string.format("%02X", alpha);
    end
    local size = string.len("#ffffff")
    color = color or "#ffffff"
    return string.len(color) == size and (color .. (alpha or "ff")) or color;
end

function BlockMaterialEditor:StringToVector4(str)
    if (type(str) ~= "string") then return str or {} end 
    local vs = commonlib.split(str, ",");
    for i = 1, #vs do
        vs[i] = tonumber(vs[i]);
    end
    return vs;
end

function BlockMaterialEditor:Vector4ToString(v)
    if (type(v) ~= "table") then return v end
    -- return tostring(v[1]) .. "," .. tostring(v[2]) .. "," .. tostring(v[3]) .. "," .. tostring(v[4]); 
    return table.concat(v, ",");
end

function BlockMaterialEditor:FormatUV(uv)
    if (type(uv) ~= "string") then return uv end 
    local vs = commonlib.split(uv, ",");
    for i = 1, #vs do
        vs[i] = tonumber(vs[i]);
    end
    return table.concat(vs, ",");
end

function BlockMaterialEditor:MaterialToObject(material)
    if (not material) then return end
    local attr = material:GetAttributeObject();
    if (not attr:IsValid()) then return end 

    local obj = {
        ID = tonumber(material:GetKeyName()),
        MaterialName = attr:GetField("MaterialName"),
        BaseColor = self:Color4ToColor3(self:Vector4ToColor(attr:GetField("BaseColor"))),
        Metallic = attr:GetField("Metallic"),
        Specular = attr:GetField("Specular"),
        Roughness = attr:GetField("Roughness"),
		Emissive = attr:GetField("Emissive"),
        EmissiveColor = self:Vector4ToColor(attr:GetField("EmissiveColor")),
        Opacity = attr:GetField("Opacity"),
        Normal = attr:GetField("Normal"),
        Diffuse = attr:GetField("Diffuse"),
        MaterialUV = self:FormatUV(self:Vector4ToString(attr:GetField("MaterialUV"))),
        -- materialAsset = material,
        -- materialAssetAttr = attr;
    } 
    -- obj.NormalFullPath = self:GetTextureDiskFilePath(obj.Normal);
    -- obj.DiffuseFullPath = self:GetTextureDiskFilePath(obj.Diffuse);
	-- obj.EmissiveFullPath = self:GetTextureDiskFilePath(obj.Emissive);
    -- attr:SetField("NormalFullPath", obj.NormalFullPath);
    -- attr:SetField("DiffuseFullPath", obj.DiffuseFullPath);
	-- attr:SetField("EmissiveFullPath", obj.EmissiveFullPath);
    return obj;
end

function BlockMaterialEditor:LoadMaterials(defaultMaterialMap, reload)
    if (self.mMaterialList and not reload) then return self.mMaterialList; end 
    if (not ParaAsset.GetBlockMaterial) then return end 

    -- print("=====================BlockMaterialEditor:LoadMaterials======================");
    self.mMaterialMap = {};
    self.mMaterialList = {};
    local mDefaultMaterialMap = self.mDefaultMaterialMap;
    for id, material in pairs(defaultMaterialMap or {}) do
        mDefaultMaterialMap[id] = mDefaultMaterialMap[id] or {};
        commonlib.mincopy(mDefaultMaterialMap[id], material);  -- 以配置文件数据为主, 程序数据为默认值
    end

    local PageSize = self:GetPageSize();
    for i = 1, 10000 do
        local materialObject = self:MaterialToObject(ParaAsset.GetBlockMaterial(i));
        local defaultMaterialObject = mDefaultMaterialMap[i];
        if (materialObject ~= nil) then
            table.insert(self.mMaterialList, materialObject);
            self.mMaterialMap[materialObject.ID] = materialObject;
            self:UpdateMaterial(materialObject);
        elseif (defaultMaterialObject ~= nil and i <= PageSize) then
            self:NewMaterial(defaultMaterialObject);
        else
            break;
        end
    end
    return self.mMaterialList;
end

function BlockMaterialEditor:NewMaterial(material)
    if (self.mMaterialMap[material.ID]) then return end 

    local materialObject = nil;
    if (ParaAsset.CreateGetBlockMaterial) then
        materialObject = self:MaterialToObject(ParaAsset.CreateGetBlockMaterial(material.ID));
    else 
        materialObject = self:MaterialToObject(ParaAsset.CreateBlockMaterial());
    end
    if (not materialObject) then return end 
    table.insert(self.mMaterialList, materialObject);
    self.mMaterialMap[materialObject.ID] = materialObject;

    material.ID = materialObject.ID;
    self:UpdateMaterial(material, true);
    self:Refresh();
    return material;
end

function BlockMaterialEditor:DeleteMaterial(material)
    ParaAsset.DeleteBlockMaterial(ParaAsset.GetBlockMaterial(material.ID));
    self.mMaterialMap[material.ID] = nil;
    for i = 1, #self.mMaterialList do
        if (self.mMaterialList[i].ID == material.ID) then
            table.remove(self.mMaterialList, i);
            break;
        end
    end
    self:Refresh();
end

function BlockMaterialEditor:UpdateMaterial(material, isNewMaterial)
    if (not material) then return end
    local blockMaterial = ParaAsset.GetBlockMaterial(material.ID);
    if not blockMaterial then return end
    local attr = blockMaterial:GetAttributeObject();
    if (not attr:IsValid()) then return end 

	-- tricky: Metallic is an internal value to indicate if there is a normal map. 
    if (material.Normal and material.Normal ~= "") then
        material.Metallic = (tonumber(material.Metallic or 0) < 0.1) and 0.5 or material.Metallic;
    else
        material.Metallic = 0;
    end

	-- tricky: emissiveColor's alpha value must be possible if there is emissive texture. 
	local matEmissiveColor = self:ColorToVector4(material.EmissiveColor, "#00000000")
	if (material.Emissive and material.Emissive ~= "") then
		if(matEmissiveColor[4] == 0) then
			material.EmissiveColor = "#ffffffff";
		end
	else
		if(matEmissiveColor[4] ~= 0) then
			material.EmissiveColor = "#00000000";
		end
	end

    material.EmissiveFullPath = self:GetTextureDiskFilePath(material.Emissive);
    material.NormalFullPath = self:GetTextureDiskFilePath(material.Normal);
    material.DiffuseFullPath = self:GetTextureDiskFilePath(material.Diffuse);

    attr:SetField("MaterialName", material.MaterialName);
    attr:SetField("BaseColor", self:ColorToVector4(material.BaseColor, "#ffffff"));
    attr:SetField("Metallic", tonumber(material.Metallic));
    attr:SetField("Specular", tonumber(material.Specular));
    attr:SetField("Roughness", tonumber(material.Roughness));
	attr:SetField("Emissive", material.Emissive or "");
    attr:SetField("EmissiveFullPath", self:GetTextureDiskFilePath(material.Emissive));
    attr:SetField("EmissiveColor", self:ColorToVector4(material.EmissiveColor, "#00000000"));
    attr:SetField("Opacity", tonumber(material.Opacity));
    attr:SetField("Normal", material.Normal or "");
    attr:SetField("Diffuse", material.Diffuse or "");
    attr:SetField("NormalFullPath", self:GetTextureDiskFilePath(material.Normal));
    attr:SetField("DiffuseFullPath", self:GetTextureDiskFilePath(material.Diffuse));
    attr:SetField("MaterialUV", self:StringToVector4(material.MaterialUV));
    
    local obj = self.mMaterialMap[material.ID] or {};
    obj.ID = material.ID;
    obj.MaterialName = material.MaterialName;
    obj.BaseColor = self:Color4ToColor3(material.BaseColor);
    obj.Metallic = material.Metallic;
    obj.Specular = material.Specular;
    obj.Roughness = material.Roughness;
	obj.Emissive = material.Emissive;
	obj.EmissiveFullPath = self:GetTextureDiskFilePath(obj.Emissive);
    obj.EmissiveColor = material.EmissiveColor;
    obj.Opacity =  material.Opacity;
    obj.Normal = material.Normal;
    obj.Diffuse = material.Diffuse;
    obj.MaterialUV = material.MaterialUV;
    obj.NormalFullPath = self:GetTextureDiskFilePath(obj.Normal);
    obj.DiffuseFullPath = self:GetTextureDiskFilePath(obj.Diffuse);
    self.mMaterialMap[obj.ID] = obj;

    self:Refresh();
    local BlockMaterialTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockMaterialTask");
    if (not isNewMaterial) then
        BlockMaterialTask.OnClickMaterial(material.ID);
        BlockMaterialTask.RefreshMaterials(material.ID);
    end
end

function BlockMaterialEditor:OpenImageDialog(callback, old_value)
    NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenImageDialog.lua");
    local OpenImageDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenImageDialog");
    OpenImageDialog.ShowPage("选择纹理", callback, commonlib.Encoding.Utf8ToDefault(old_value));
end

function BlockMaterialEditor:SelectMaterial(material)
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockMaterial/BlockMaterialTask.lua");
    local BlockMaterialTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockMaterialTask");
    BlockMaterialTask.SetCurrentMaterialId(material.ID);
    self:SetCurrentMaterialID(material.ID);
end

function BlockMaterialEditor:SetCurrentMaterialID(id)
    if (not self.mMaterialMap[id]) then return end
    if (self.MaterialID == id) then return end
    self.MaterialID = id;
    if (self.window) then
        local G = self.window:GetG();
        if (type(G.OnMaterialIDChange) == "function") then
            G.OnMaterialIDChange(self.MaterialID);
        end
    end
end

function BlockMaterialEditor:GetCurrentMaterialID()
    return self.MaterialID or 1;
end

BlockMaterialEditor:InitSingleton():Init();
