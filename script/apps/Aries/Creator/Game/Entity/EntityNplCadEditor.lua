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


NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlock.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/InventoryBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeActorItemStack.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Physics/BoxTrigger.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CmdParser.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityBlockCodeBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserLoaderPage.lua");

local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
local BoxTrigger = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld.BoxTrigger")
local CodeActorItemStack = commonlib.gettable("MyCompany.Aries.Game.Code.CodeActorItemStack");
local InventoryBase = commonlib.gettable("MyCompany.Aries.Game.Items.InventoryBase");
local CodeBlock = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlock");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local names = commonlib.gettable("MyCompany.Aries.Game.block_types.names")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");

local NplBrowserLoaderPage = commonlib.gettable("NplBrowser.NplBrowserLoaderPage");
local NplCadEditorMenuPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplCad/NplCadEditorMenuPage.lua");

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


function Entity:GetBlockEngine()
	return self.blockEngine or BlockEngine;
end

function Entity:SetBlockEngine(blockEngine)
	self.blockEngine = blockEngine;
end


function Entity:AutoCreateMovieEntity()
	local movieEntity = self:FindNearByMovieEntity();
	if(not movieEntity) then
		local cx, cy, cz = self:GetBlockPos();
		local BlockEngine = self:GetBlockEngine();
	
		for side = 3, 0, -1 do
			local dx, dy, dz = Direction.GetOffsetBySide(side);
			local x,y,z = cx+dx, cy+dy, cz+dz;
			local blockTemplate = BlockEngine:GetBlock(x,y,z);
			if(not blockTemplate) then
				BlockEngine:SetBlock(x,y,z, names.MovieClip, 0, 3, nil);
				movieEntity = BlockEngine:GetBlockEntity(x,y,z);
				return movieEntity;
			end
		end
	end
	return movieEntity;
end

-- only search in 4 horizontal directions for a maximum distance of 16
-- find nearby movie entity, multiple code block next to each other can share the same movie block.
function Entity:FindNearByMovieEntity()
	local movieEntity = self:GetNearByMovieEntity();
	if(not movieEntity) then
		local cx, cy, cz = self.bx, self.by, self.bz;
		local id = self:GetBlockId();
		local blocks;
		local totalCodeBlockCount = 0;
		local BlockEngine = self:GetBlockEngine();
		for side = 0, 3 do
			local dx, dy, dz = Direction.GetOffsetBySide(side);
			local x,y,z = cx+dx, cy+dy, cz+dz;
			local blockTemplate = BlockEngine:GetBlock(x,y,z);
			if(blockTemplate and blockTemplate.id == id) then
				local codeEntity = BlockEngine:GetBlockEntity(x,y,z);
				if(codeEntity) then
					local idx = BlockEngine:GetSparseIndex(x,y,z);
					blocks = blocks or {};
					blocks[#blocks+1] = idx;
					totalCodeBlockCount = totalCodeBlockCount + 1;
				end
			end
		end
		if(blocks) then
			local entity_map = {};
			entity_map[BlockEngine:GetSparseIndex(cx,cy,cz)] = true;
			movieEntity = self:FindNearByMovieEntityImp(blocks, 1, entity_map, totalCodeBlockCount);
		end
	end
	return movieEntity;
end

-- return movieEntity, distance
function Entity:FindNearByMovieEntityImp(blocks, distance, entity_map, totalCodeBlockCount)
	local id = self:GetBlockId();
	local new_blocks;
	local BlockEngine = self:GetBlockEngine();
	for _, idx in ipairs(blocks) do
		local cx, cy, cz = BlockEngine:FromSparseIndex(idx);
		local movieEntity = self:GetNearByMovieEntity(cx, cy, cz);
		if(movieEntity) then
			return movieEntity, distance;
		end
		if(distance < 16) then
			for side = 0, 3 do
				local dx, dy, dz = Direction.GetOffsetBySide(side);
				local x,y,z = cx+dx, cy+dy, cz+dz;

				local blockTemplate = BlockEngine:GetBlock(x,y,z);
				if(blockTemplate and blockTemplate.id == id) then
					local idx = BlockEngine:GetSparseIndex(x,y,z);
					if(not entity_map[idx] and totalCodeBlockCount<maxConnectedCodeBlockCount) then
						entity_map[idx] = true;
						new_blocks = new_blocks or {};
						new_blocks[#new_blocks+1] = idx;
						totalCodeBlockCount = totalCodeBlockCount + 1;
					end
				end
			end
		end
	end
	if(new_blocks) then
		return self:FindNearByMovieEntityImp(new_blocks, distance+1, entity_map, totalCodeBlockCount);
	end
end

-- only search in 4 horizontal directions
function Entity:GetNearByMovieEntity(cx, cy, cz)
	local BlockEngine = self:GetBlockEngine();
	cx, cy, cz = cx or self.bx, cy or self.by, cz or self.bz;
	for side = 0, 3 do
		local dx, dy, dz = Direction.GetOffsetBySide(side);
		local x,y,z = cx+dx, cy+dy, cz+dz;
		local blockTemplate = BlockEngine:GetBlock(x,y,z);
		if(blockTemplate and blockTemplate.id == names.MovieClip) then
			local movieEntity = BlockEngine:GetBlockEntity(x,y,z);
			if(movieEntity) then
				return movieEntity;
			end
		end
	end
end