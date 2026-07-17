--[[
Title: Custom Char Models and Skins
Author(s): 
Date: 2025/1/7
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditCCS/CustomCharSkinItems.lua");
local CustomCharSkinItems = commonlib.gettable("MyCompany.Aries.Game.Tasks.CustomCharSkinItems");
CustomCharSkinItems:Init();
]]

--[[
CS_HEAD =0,
CS_NECK = 1,
CS_SHOULDER = 2,
CS_BOOTS = 3,
CS_BELT = 4,
CS_SHIRT = 5,
CS_PANTS = 6,
CS_CHEST = 7,
CS_BRACERS = 8,
CS_GLOVES = 9,
CS_HAND_RIGHT = 10,
CS_HAND_LEFT = 11,
CS_CAPE = 12,
CS_TABARD = 13,
CS_FACE_ADDON = 14, // newly added by andy -- 2009.5.10, Item type: IT_MASK 26
CS_WINGS = 15, // newly added by andy -- 2009.5.11, Item type: IT_WINGS 27
CS_ARIES_CHAR_SHIRT = 16, // newly added by andy -- 2009.6.16, Item type: IT_WINGS 28
CS_ARIES_CHAR_PANT = 17,
CS_ARIES_CHAR_HAND = 18,
CS_ARIES_CHAR_FOOT = 19,
CS_ARIES_CHAR_GLASS = 20,
CS_ARIES_CHAR_WING = 21,
CS_ARIES_PET_HEAD = 22,
CS_ARIES_PET_BODY = 23,
CS_ARIES_PET_TAIL = 24,
CS_ARIES_PET_WING = 25,
CS_ARIES_CHAR_SHIRT_TEEN = 28,
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditCCS/CustomCharSkinItems.lua");
local CustomCharSkinItems = commonlib.gettable("MyCompany.Aries.Game.Tasks.CustomCharSkinItems");
local custom_skin_path = "config/Aries/creator/CustomCharSkinItems.xml"
local custom_teen_skin_path = "config/Aries/creator/CustomCharSkinItems.Teen.xml"

function CustomCharSkinItems:Init()
    if self.init then
        return
    end
    CustomCharSkinItems.customcharskin = {};
    CustomCharSkinItems.category_items = {};
    CustomCharSkinItems.teen_customcharskin = {};
    CustomCharSkinItems.teen_category_items = {};
    self.init = true
    local root = ParaXML.LuaXML_ParseFile(custom_skin_path);
    if root then
        for group in commonlib.XPath.eachNode(root, "/ccsskin/category") do
            local name = group.attr.name;
            local groups = {};
            local itemIndex = 1;
            for _, node in ipairs(group) do
                local item = {};
                item.gsid = node.attr.gsid;
                item.slot = node.attr.slot;
                item.name = node.attr.name or name.. "_".. itemIndex;
                item.icon = node.attr.icon;
                item.text = node.attr.text;
                groups[#groups+1] = item;
                if(item.gsid) then
                    CustomCharSkinItems.customcharskin[item.gsid] = item;
                end
                itemIndex = itemIndex + 1;
            end
            CustomCharSkinItems.category_items[name] = groups;
        end
    else
        LOG.std(nil, "error", "CustomCharSkinItems", "can not find file at %s", custom_skin_path);
    end
    root = ParaXML.LuaXML_ParseFile(custom_teen_skin_path);
    if root then
        for group in commonlib.XPath.eachNode(root, "/ccsskin/category") do
            local name = group.attr.name;
            local groups = {};
            local itemIndex = 1;
            for _, node in ipairs(group) do
                local item = {};
                item.gsid = node.attr.gsid;
                item.slot = node.attr.slot;
                item.name = node.attr.name or name.. "_".. itemIndex;
                item.icon = node.attr.icon;
                item.text = node.attr.text;
                groups[#groups+1] = item;
                if(item.gsid) then
                    CustomCharSkinItems.teen_customcharskin[item.gsid] = item;
                end
                itemIndex = itemIndex + 1;
            end
            CustomCharSkinItems.teen_category_items[name] = groups;
        end
    else
        LOG.std(nil, "error", "CustomCharSkinItems", "can not find file at %s", custom_teen_skin_path);
    end
    print("CustomCharSkinItems:Init()=============>OK")
    -- echo(CustomCharSkinItems.customcharskin,true)
    -- echo(CustomCharSkinItems.category_items,true)
    -- print("CustomCharSkinItems:Init()========teen=====>OK")
    -- echo(CustomCharSkinItems.teen_customcharskin,true)
    -- echo(CustomCharSkinItems.teen_category_items,true)
    return true
end

function CustomCharSkinItems:GetCategoryItems(category,isTeen)
    if isTeen then
        return CustomCharSkinItems.teen_category_items[category];
    else
        return CustomCharSkinItems.category_items[category];
    end
end

function CustomCharSkinItems:GetItem(gsid,isTeen)
    if isTeen then
        return CustomCharSkinItems.teen_customcharskin[gsid];
    else
        return CustomCharSkinItems.customcharskin[gsid];
    end
end

local assetfile = "character/v3/Elf/Female/ElfFemale.xml"
local assetfileMale = "character/v3/TeenElf/Male/TeenElfMale.xml"
local assetfileFemale = "character/v3/TeenElf/Female/TeenElfFemale.xml"

function CustomCharSkinItems:IsFemaleModel(assetfile)
    return assetfile == assetfileFemale
end

function CustomCharSkinItems:IsTeenModel(assetfile)
    return assetfile == assetfileMale or assetfile == assetfileFemale
end

