--[[
Title: KeepWork Mall Item Component
Author(s): big
CreateDate: 2023.6.5
Desc:
Place: Foshan
use the lib:
------------------------------------------------------------
local ItemComponent = NPL.load('script/apps/Aries/Creator/Game/KeepWork/KeepWorkMallComponent/ItemComponent.lua');
------------------------------------------------------------
]]

local ItemComponent = NPL.export()

local self = ItemComponent
local count = 0;

function ItemComponent.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
    self.bindingContext = bindingContext;
    self.style = style;
    self.width = width;
    self.height = height;
    self.left = left;
    self.top = top;
    self.parentLayout = parentLayout;
    count = count + 1
    self.count = count;

    return mcmlNode:DrawDisplayBlock(
        rootName,
        bindingContext,
        _parent,
        left,
        top,
        width,
        height,
        parentLayout,
        style,
        self.RenderCallback
    )
end

function ItemComponent.RenderCallback(mcmlNode, rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)
    local xmlRoot

    if (not self.xmlRoot) then
        self.xmlRoot = ParaXML.LuaXML_ParseFile('script/apps/Aries/Creator/Game/KeepWork/KeepWorkMallComponent/ItemComponent.html');
        xmlRoot = commonlib.copy(self.xmlRoot);
    else
        xmlRoot = commonlib.copy(self.xmlRoot);
    end

    local buildClassXmlRoot = Map3DSystem.mcml.buildclass(xmlRoot)    
    local ItemComponentMcmlNode = commonlib.XPath.selectNode(buildClassXmlRoot, '//pe:mcml')
    ItemComponentMcmlNode:SetAttribute('page_ctrl', mcmlNode:GetPageCtrl())

    local ParacraftWorld = Map3DSystem.mcml_controls.create(
        'keepwork_mall_item_' .. self.count,
        ItemComponentMcmlNode,
        self.bindingContext,
        _parent,
        self.left,
        self.top,
        self.width,
        self.height,
        self.style,
        self.parentLayout
    )
end
