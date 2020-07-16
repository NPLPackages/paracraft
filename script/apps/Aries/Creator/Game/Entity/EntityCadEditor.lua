--[[
Title: CadEditor
Author(s): leio
Date: 2020/7/5
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityCadEditor.lua");
local EntityCadEditor = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCadEditor")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityBlockBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/Text3DDisplay.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserLoaderPage.lua");
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

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockBase"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCadEditor"));

Entity:Property({"EditorType", "", "GetEditorType", "SetEditorType"})

-- class name
Entity.class_name = "EntityCadEditor";
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
    commonlib.echo("==============Entity:SaveToXMLNode");
    commonlib.echo(node);
	return node;
end

function Entity:LoadFromXMLNode(node)
	Entity._super.LoadFromXMLNode(self, node);
    commonlib.echo("==============Entity:LoadFromXMLNode");
    commonlib.echo(node);
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
    NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
    local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

    NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NPLWebServer.lua");
	local NPLWebServer = commonlib.gettable("MyCompany.Aries.Game.Network.NPLWebServer");
	local bStarted, site_url = NPLWebServer.CheckServerStarted(function(bStarted, site_url)	end)
    if(not bStarted)then
        GameLogic.AddBBS("statusBar", L"网络服务器正在启动，请稍等！", 5000, "255 0 0");
        return
    end
    if(not NplBrowserLoaderPage.IsLoaded())then
        GameLogic.AddBBS("statusBar", L"浏览器正在加载，请稍等！", 5000, "255 0 0");
        return
    end
    local blockpos;
    local bx, by, bz = self:GetBlockPos();
    if(bz) then
		blockpos = format("%d,%d,%d", bx, by, bz);
	end
    local url = string.format("%srouter/nplcad3_fulleditor?blockpos=%s",site_url,blockpos);
    local NplBrowserManager = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserManager.lua");
    NplBrowserManager:CreateOrGet("NplCadIDEBrowser"):Show(url, "NplCadEditor", true, true);
end
