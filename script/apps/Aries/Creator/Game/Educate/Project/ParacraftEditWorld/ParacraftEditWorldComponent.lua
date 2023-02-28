--[[
Title:  ParacraftEditWorldComponent
Author(s): big,pbb
CreateDate: 2023.2.13
Desc: 
use the lib:
------------------------------------------------------------
local ParacraftEditWorldComponent = NPL.load('(gl)script/apps/Aries/Creator/Game/Educate/Project/ParacraftEditWorld/ParacraftEditWorldComponent.lua')
------------------------------------------------------------
]]

local ParacraftEditWorldComponent = NPL.export()

local self = ParacraftEditWorldComponent

function ParacraftEditWorldComponent.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
    self.width = width
    self.height = height
    self.parentLayout = parentLayout

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

function ParacraftEditWorldComponent.RenderCallback(mcmlNode, rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)
    local xmlRoot

    if not self.xmlRoot then
        self.xmlRoot = ParaXML.LuaXML_ParseFile('script/apps/Aries/Creator/Game/Educate/Project/ParacraftEditWorld/ParacraftEditWorldComponent.html')
        xmlRoot = commonlib.copy(self.xmlRoot)
    else
        xmlRoot = commonlib.copy(self.xmlRoot)
    end

    local buildClassXmlRoot = Map3DSystem.mcml.buildclass(xmlRoot)
    local ParacraftEditWorldComponentMcmlNode = commonlib.XPath.selectNode(buildClassXmlRoot, '//pe:mcml')

    ParacraftEditWorldComponentMcmlNode:SetAttribute('page_ctrl', mcmlNode:GetPageCtrl())

    Map3DSystem.mcml_controls.create(
        nil,
        ParacraftEditWorldComponentMcmlNode,
        nil,
        _parent,
        0,
        0,
        self.width,
        self.height,
        nil,
        self.parentLayout
    )

    return true, true, true
end
