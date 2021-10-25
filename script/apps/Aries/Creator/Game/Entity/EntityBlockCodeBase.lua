--[[
Title: EntityBlockCodeBase
Author(s): LiXizhi
Date: 2021/6/19
Desc: The base class for block entity that contains code.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityBlockCodeBase.lua");
local EntityBlockCodeBase = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockCodeBase")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityBlockBase.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockBase"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockCodeBase"));

-- class name
Entity.class_name = "EntityBlockCodeBase";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);

Entity:Property("NplBlocklyToolboxXmlText");
Entity:Signal("remotelyUpdated")

function Entity:ctor()
end

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
		return {name="![CDATA[", [1] = string.gsub(text, "%]%]>", "%]%]%]%]><!%[CDATA%[>")};
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
		local blocklyNode = {name="blockly"};
		node[#node+1] = blocklyNode;
		blocklyNode[#blocklyNode+1] = {name="code", self:TextToXmlInnerNode(self:GetNPLCode())}
		blocklyNode[#blocklyNode+1] = {name="xmlcode", self:TextToXmlInnerNode(self.blockly_xmlcode)}
		blocklyNode[#blocklyNode+1] = {name="nplcode", self:TextToXmlInnerNode(self.blockly_nplcode)}
		blocklyNode[#blocklyNode+1] = {name="npl_xmlcode", self:TextToXmlInnerNode(self.npl_blockly_xmlcode)}
		blocklyNode[#blocklyNode+1] = {name="npl_nplcode", self:TextToXmlInnerNode(self.npl_blockly_nplcode)}
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
	local isUseNplBlockly = (node.attr.isUseNplBlockly == "true" or node.attr.isUseNplBlockly == true); 
    self.isUseCustomBlock = (node.attr.isUseCustomBlock == "true" or node.attr.isUseCustomBlock == true);

	for i=1, #node do
		if(node[i].name == "blockly") then
			for j=1, #(node[i]) do
				local sub_node = node[i][j];
				local code = "";
				for i = 1, #sub_node do
					local sub_node_code = sub_node[i];
					code = code .. (type(sub_node_code) == "table" and sub_node_code[1] or sub_node_code);
				end
				
				-- 直接用SaveBlocklyToXMLNode生成的节点, 不经过xml解析则会无法解析之前的转换, 这里手动替换, 如果文本中含有]]]]><![CDATA[> 则会被误替换
				code = string.gsub(code, "%]%]%]%]><!%[CDATA%[>", "%]%]>");

				if(type(code) == "string") then
					if(sub_node.name == "xmlcode") then
						self.blockly_xmlcode = code;
					elseif(sub_node.name == "nplcode") then
						self.blockly_nplcode = code;
					elseif(sub_node.name == "npl_xmlcode") then
						self.npl_blockly_xmlcode = code;  -- 兼容已存在的代码
					elseif(sub_node.name == "npl_nplcode") then
						self.npl_blockly_nplcode = code;
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
	
	-- npl blockly should remain default value unless self.blockly_xmlcode has code 
	if(isUseNplBlockly or (self.blockly_xmlcode or "") ~= "") then
		self.isUseNplBlockly = isUseNplBlockly;	
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

-- virtual: this should be called when inventory itemstack or its values are changed
-- this function can be called many times per frame, but only one merged inventoryChanged signal is fired.
function Entity:OnInventoryChanged(slot_index)
end

-- Overriden to provide the network packet for this entity.
function Entity:GetDescriptionPacket()
	local x,y,z = self:GetBlockPos();
	return Packets.PacketUpdateEntityBlock:new():Init(x,y,z, self:SaveToXMLNode());
end

-- update from packet. 
function Entity:OnUpdateFromPacket(packet_UpdateEntityBlock)
	if(packet_UpdateEntityBlock:isa(Packets.PacketUpdateEntityBlock)) then
		local node = packet_UpdateEntityBlock.data1;
		if(node) then
			self.blockly_nplcode = nil;
			self.nplcode = nil;
			self.npl_blockly_nplcode = nil;
			self.blockly_nplcode = nil;
			self:LoadFromXMLNode(node)
			self:OnInventoryChanged();
			self:remotelyUpdated();
		end
	end
end