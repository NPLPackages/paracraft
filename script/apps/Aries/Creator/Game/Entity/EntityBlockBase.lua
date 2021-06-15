--[[
Title: EntityBlockBase 
Author(s): LiXizhi
Date: 2013/12/17
Desc: The base class for entity that is usually associated with a given block.
 It overwrite the Create() method to delay entity init() until the block is loaded. 
 Please note that a block entity saves to regional(512*512) xml file,  instead of global entity file.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityBlockBase.lua");
local EntityBlockBase = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockBase")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.Entity"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockBase"));

-- class name
Entity.class_name = "EntityBlockBase";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);
Entity.is_persistent = true;
-- always serialize to 512*512 regional entity file
Entity.is_regional = true;
-- block entity will only init when its belonging block is loaded from file. 
Entity.is_block_entity = true;

Entity:Property("NplBlocklyToolboxXmlText");

function Entity:ctor()
end

-- @param Entity: the half radius of the object. 
function Entity:init()
	Entity._super.init(self);
	if(BlockEngine:GetBlockId(self.bx, self.by, self.bz) == self:GetBlockId()) then
		self:UpdateBlockContainer();
		return self;
	else
		LOG.std(nil, "warn", "EntityBlock", "block (%d %d %d) of id %d not found", self.bx, self.by, self.bz, self:GetBlockId());
	end
end

function Entity:IsBlockEntity()
	return true;
end

function Entity:MountEntity(target)
end

function Entity:PushOutOfBlocks(x,y,z)
end

function Entity:GetBlockEntityName()
	local bx, by, bz = self:GetBlockPos();
	return format("%d,%d,%d", bx, by, bz);
end

-- call init when block is first loaded. 
function Entity:OnBlockLoaded(x,y,z)
end

-- virtual
function Entity:OnBlockAdded(x,y,z)
end

-- called when the user clicks on the block
-- @return: return true if it is an action block and processed . 
function Entity:OnClick(x, y, z, mouse_button, entity, side)
	if(GameLogic.isRemote) then
		if(mouse_button == "left") then
			-- GameLogic.GetPlayer():AddToSendQueue(GameLogic.Packets.PacketClickEntity:new():Init(entity or GameLogic.GetPlayer(), self, mouse_button, x, y, z));
		end
		return true;
	else
		if(mouse_button=="right" and GameLogic.GameMode:CanEditBlock()) then
			local ctrl_pressed = System.Windows.Keyboard:IsCtrlKeyPressed();
			if(ctrl_pressed) then
				-- ctrl+right click to activate the entity in editor mode, such as for CommandEntity. 
				self:OnActivated(entity);
			else
				self:OpenEditor("entity", entity);
			end
		end
	end
	return true;
end

-- virtual
function Entity:OnNeighborChanged(x,y,z, from_block_id)
end

-- ===================NPL Blockly Begin=====================
function Entity:IsUseNplBlockly()
	return self.isUseNplBlockly;
end

function Entity:SetUseNplBlockly(bEnabled)
	self.isUseNplBlockly = bEnabled;
end

function Entity:SetNPLBlocklyXMLCode(blockly_xmlcode)
	self.npl_blockly_xmlcode = blockly_xmlcode;
end

function Entity:GetNPLBlocklyXMLCode()
	return self.npl_blockly_xmlcode or "";
end

function Entity:SetNPLBlocklyNPLCode(blockly_nplcode)
	self.npl_blockly_nplcode = blockly_nplcode;
	self:SetCommand(blockly_nplcode);
end

function Entity:GetNPLBlocklyNPLCode()
	return self.npl_blockly_nplcode or "";
end
	
function Entity:SetBlocklyXMLCode(blockly_xmlcode)
	if (self:IsUseNplBlockly()) then
		self:SetNPLBlocklyXMLCode(blockly_xmlcode or "");
	else
		self.blockly_xmlcode = blockly_xmlcode;
	end
end

function Entity:GetBlocklyXMLCode()
	return self:IsUseNplBlockly() and (self.npl_blockly_xmlcode or "") or (self.blockly_xmlcode or "");
end

function Entity:SetBlocklyNPLCode(blockly_nplcode)
	if (self:IsUseNplBlockly()) then
		self:SetNPLBlocklyNPLCode(blockly_nplcode or "");
	else
		self.blockly_nplcode = blockly_nplcode;
		self:SetCommand(blockly_nplcode);
	end
end

function Entity:GetBlocklyNPLCode()
	return self:IsUseNplBlockly() and (self.npl_blockly_nplcode or "") or (self.blockly_nplcode or "");
end

function Entity:SetUseCustomBlock(bEnabled)
	self.isUseCustomBlock = bEnabled;
end

function Entity:IsUseCustomBlock()
	return self.isUseCustomBlock;
end

function Entity:IsBlocklyEditMode()
	return self.isBlocklyEditMode;
end

function Entity:SetBlocklyEditMode(bEnabled)
	if(self.isBlocklyEditMode~=bEnabled) then
		self.isBlocklyEditMode = bEnabled;
		if(bEnabled)  then
			self:SetCommand(self:IsUseNplBlockly() and self:GetNPLBlocklyNPLCode() or self:GetBlocklyNPLCode());
		else
			self:SetCommand(self:GetNPLCode());
		end
		self:editModeChanged();
	end
end

function Entity:TextToXmlInnerNode(text)
	if(text and commonlib.Encoding.HasXMLEscapeChar(text)) then
		return {name="![CDATA[", [1] = text};
	else
		return text or "";
	end
end

function Entity:SaveBlocklyToXMLNode(node)
	if(self:IsBlocklyEditMode()) then
		node.attr.isBlocklyEditMode = true;
	end
	if(self:IsUseNplBlockly()) then
		node.attr.isUseNplBlockly = true;
	end
	if(self:IsUseCustomBlock()) then
		node.attr.isUseCustomBlock = true;
	end
	if(self:GetBlocklyXMLCode() ~= "" or self:GetNPLBlocklyXMLCode() ~= "") then
		local blocklyNode = {name="blockly", };
		node[#node+1] = blocklyNode;
		blocklyNode[#blocklyNode+1] = {name="code", self:TextToXmlInnerNode(self:GetNPLCode())}
		blocklyNode[#blocklyNode+1] = {name="xmlcode", self:TextToXmlInnerNode(self:GetBlocklyXMLCode())}
		blocklyNode[#blocklyNode+1] = {name="nplcode", self:TextToXmlInnerNode(self:GetBlocklyNPLCode())}
		blocklyNode[#blocklyNode+1] = {name="npl_xmlcode", self:TextToXmlInnerNode(self:GetNPLBlocklyXMLCode())}
		blocklyNode[#blocklyNode+1] = {name="npl_nplcode", self:TextToXmlInnerNode(self:GetNPLBlocklyNPLCode())}
		blocklyNode[#blocklyNode+1] = {name="npl_toolbox_xml_text", self:TextToXmlInnerNode(self:GetNplBlocklyToolboxXmlText())}
	end

	if(self.includedFiles) then
		local includedFilesNode = {name="includedFiles", };
		node[#node+1] = includedFilesNode;
		for i, name in ipairs(self.includedFiles) do
			includedFilesNode[i] = {name="filename", name}
		end
	end
end

function Entity:LoadBlocklyFromXMLNode(node)
	self.isBlocklyEditMode = (node.attr.isBlocklyEditMode == "true" or node.attr.isBlocklyEditMode == true);
	self.isUseNplBlockly = (node.attr.isUseNplBlockly == "true" or node.attr.isUseNplBlockly == true); 
    self.isUseCustomBlock = (node.attr.isUseCustomBlock == "true" or node.attr.isUseCustomBlock == true);
	
	for i=1, #node do
		if(node[i].name == "blockly") then
			for j=1, #(node[i]) do
				local sub_node = node[i][j];
				local code = sub_node[1]
				if(code) then
					if(type(code) == "table" and type(code[1]) == "string") then
						-- just in case cmd.name == "![CDATA["
						code = code[1];
					end
				end
				if(type(code) == "string") then
					if(sub_node.name == "xmlcode") then
						self:SetBlocklyXMLCode(code);
					elseif(sub_node.name == "nplcode") then
						self:SetBlocklyNPLCode(code);
					elseif(sub_node.name == "npl_xmlcode") then
						self:SetNPLBlocklyXMLCode(code);
					elseif(sub_node.name == "npl_nplcode") then
						-- self:SetNPLBlocklyNPLCode(code);
					elseif(sub_node.name == "code") then
						self:SetNPLCode(code);
					elseif(sub_node.name == "npl_toolbox_xml_text") then
						self:SetNplBlocklyToolboxXmlText(code);
					end
				end
			end
		elseif(node[i].name == "includedFiles") then
			self.includedFiles = {};
			for j=1, #(node[i]) do
				local sub_node = node[i][j];
				local filename = sub_node[1]
				self.includedFiles[j] = filename;
			end
		end
	end
	if(not self.isBlocklyEditMode and not self.nplcode) then
		self.nplcode = self:GetCommand();
	end
	if(self.isBlocklyEditMode) then
		self:SetCommand(self.isUseNplBlockly and self:GetNPLBlocklyNPLCode() or self:GetBlocklyNPLCode());
	else
		self:SetCommand(self:GetNPLCode());
	end
end

function Entity:SetNPLCode(nplcode)
	self.nplcode = nplcode;
	self:SetCommand(nplcode);
end

function Entity:GetNPLCode()
	return self.nplcode or self:GetCommand();
end

function Entity:IsCodeEmpty()
	local cmd = self:GetCommand()
	if(not cmd or cmd == "") then
		return true;
	end
end
-- ===================NPL Blockly End=====================
