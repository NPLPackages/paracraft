--[[
Title: EntityNplCadEditor
Author(s): leio
Date: 2020/12/8
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityNplCadEditor.lua");
local EntityNplCadEditor = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityNplCadEditor")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityBlockBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/Text3DDisplay.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserLoaderPage.lua");
NPL.load("(gl)script/ide/System/Windows/Keyboard.lua");
local NplCadEditorMenuPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplCad/NplCadEditorMenuPage.lua");

local Text3DDisplay = commonlib.gettable("MyCompany.Aries.Game.Effects.Text3DDisplay");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local NplBrowserLoaderPage = commonlib.gettable("NplBrowser.NplBrowserLoaderPage");
local Keyboard = commonlib.gettable("System.Windows.Keyboard");

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockBase"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityNplCadEditor"));

Entity:Property({"EditorType", "", "GetEditorType", "SetEditorType"})

-- class name
Entity.class_name = "EntityNplCadEditor";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);
Entity.is_persistent = true;
-- always serialize to 512*512 regional entity file
Entity.is_regional = true;
Entity.text_color = "0 0 0";
Entity.text_offset = {x=0,y=0.42,z=0.37};

function Entity:ctor()
end


function Entity:GetEditorType()
    return self.editor_type;
end
-- @param editor_type: "full_editor" or "lite_editor"
function Entity:SetEditorType(editor_type)
    self.editor_type = editor_type;
end
function Entity:OnClick(x, y, z, mouse_button, entity)
	if(mouse_button=="right" and GameLogic.GameMode:CanEditBlock()) then
		self:OpenEditor();
	end
	return true;
end

function Entity:SaveToXMLNode(node, bSort)
	node = Entity._super.SaveToXMLNode(self, node, bSort);
    if(self:GetIDEContent() and self:GetIDEContent() ~="")then
        local editorNode = { name="editor"};
		node[#node+1] = editorNode;
		editorNode[#editorNode+1] = {name = "data", self:GetIDEContent()}

    end
	node.attr.editor_type = self:GetEditorType();
	return node;
end

function Entity:LoadFromXMLNode(node)
	Entity._super.LoadFromXMLNode(self, node);
	self.editor_type = node.attr.editor_type;
    for i=1, #node do
        local editor_node = node[i];
		if(editor_node.name == "editor") then
            if(editor_node[1] and editor_node[1][1])then
                self:SetIDEContent(editor_node[1][1]);
            end
        end
    end
end
function Entity:GetIDEContent()
    return self.ide_content;
end
function Entity:SetIDEContent(content)
    self.ide_content = content;
end
function Entity:EndEdit()
	Entity._super.EndEdit(self);
	self:MarkForUpdate();
end
function Entity:OpenEditor()
	NplCadEditorMenuPage.ShowPage(self);
end
