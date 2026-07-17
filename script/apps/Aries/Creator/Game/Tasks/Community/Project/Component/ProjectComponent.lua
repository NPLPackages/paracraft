--[[
Title:  ProjectComponent
Author(s): big,pbb
CreateDate: 2023.2.13
Desc: 
use the lib:
------------------------------------------------------------
local ProjectComponent = NPL.load('(gl)script/apps/Aries/Creator/Game/Tasks/Community/Project/Component/ProjectComponent.lua')
------------------------------------------------------------
]]

local ProjectComponent = NPL.export()

local self = ProjectComponent

function ProjectComponent.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
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

function ProjectComponent.RenderCallback(mcmlNode, rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)
    local xmlRoot

    if not self.xmlRoot then
        self.xmlRoot = ParaXML.LuaXML_ParseFile('script/apps/Aries/Creator/Game/Tasks/Community/Project/Component/ProjectComponent.html')
        xmlRoot = commonlib.copy(self.xmlRoot)
    else
        xmlRoot = commonlib.copy(self.xmlRoot)
    end

    local buildClassXmlRoot = Map3DSystem.mcml.buildclass(xmlRoot)
    local ProjectComponentMcmlNode = commonlib.XPath.selectNode(buildClassXmlRoot, '//pe:mcml')

    ProjectComponentMcmlNode:SetAttribute('page_ctrl', mcmlNode:GetPageCtrl())

    Map3DSystem.mcml_controls.create(
        nil,
        ProjectComponentMcmlNode,
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
