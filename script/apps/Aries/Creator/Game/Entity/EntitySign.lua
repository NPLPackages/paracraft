--[[
Title: Sign
Author(s): LiXizhi
Date: 2013/12/17
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntitySign.lua");
local EntitySign = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntitySign")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityBlockBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/Text3DDisplay.lua");
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

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockBase"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntitySign"));
Entity:Property({"languageConfigFile", "mcml", "GetLanguageConfigFile", "SetLanguageConfigFile"})
Entity:Property({"isAllowClientExecution", false, "IsAllowClientExecution", "SetAllowClientExecution"})
Entity:Property({"isAllowFastMode", false, "IsAllowFastMode", "SetAllowFastMode"})

Entity:Signal("beforeRemoved")
Entity:Signal("editModeChanged")
Entity:Signal("remotelyUpdated")
Entity:Signal("inventoryChanged", function(slotIndex) end)

-- class name
Entity.class_name = "EntitySign";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);
Entity.is_persistent = true;
-- always serialize to 512*512 regional entity file
Entity.is_regional = true;
Entity.text_color = "0 0 0";
Entity.text_offset = {x=0,y=0.42,z=0.37};

function Entity:ctor()
	self:SetUseNplBlockly(true);
end

function Entity:OnBlockAdded(x,y,z, data)
	self.block_data = data or self.block_data or 0;
	self:Refresh();
end

function Entity:OnBlockLoaded(x,y,z, data)
	self.block_data = data or self.block_data or 0;
	-- backward compatibility, since we used to store facing instead of data in very early version. 
	-- this should never happen in versions after late 2014
	if(self.block_data == 0 and (self.facing or 0) ~= 0) then
		LOG.std(nil, "warn", "info", "fix BlockSign entity facing and block data incompatibility in early version: %d %d %d", self.bx, self.by, self.bz);
		self:UpdateBlockDataByFacing();
	end
	self:Refresh();
end

function Entity:OnRemoved()
	self:beforeRemoved();
	Entity._super.OnRemoved(self);
end

function Entity:UpdateBlockDataByFacing()
	local x,y,z = self:GetBlockPos();
	local dir_id = Direction.GetDirectionFromFacing(self.facing or 0);
	self.block_data = dir_id;
	BlockEngine:SetBlockData(x,y,z, dir_id);	
end

function Entity:GetDisplayName()
	return self.cmd or "";
end

function Entity:Refresh()
	local hasText = self:GetDisplayName() ~= ""
	if(hasText and not self.wasDeleted) then
		-- only create C++ object when cmd is not empty
		if(not self.obj) then
			-- Node: we do not draw the model, it is only used for drawing UI overlay. 
			local obj = self:CreateInnerObject("model/blockworld/TextFrame/TextFrame.x", nil, BlockEngine.half_blocksize, BlockEngine.blocksize);
			if(obj) then
				-- making it using custom renderer since we are using chunk buffer to render. 
				obj:SetAttribute(0x20000, true);
				-- make it solid, so that it is rendered before water blocks
				obj:SetField("HeadOnSolid", true);
			end	
		end
	end
	local obj = self:GetInnerObject();
	if(obj) then
		if(hasText) then
			-- update text rotation based on block data
			local data = self.block_data or 0;
			if(data < 4) then
				obj:SetFacing(Direction.directionTo3DFacing[data]);
			elseif(data < 12) then
				obj:SetFacing(0);
				obj:SetRotation(Direction.GetQuaternionByData(data));
			end
			local text = self.cmd or ""
			if(self:HasMCML()) then
				local xmlRoot = ParaXML.LuaXML_ParseString("<pe:mcml>"..text.."</pe:mcml>")
				if(xmlRoot) then
					local env = {
						_G = GameLogic.GetCodeGlobal():GetCurrentGlobals(),
					};
					setmetatable(env, GameLogic.GetCodeGlobal():GetCurrentMetaTable());

					self:SetHeadOnDisplay({url=xmlRoot, is3D = true, 
						offset=self.text_offset, facing=-1.57, 
						pageGlobalTable=env,
					})
				else
					text = L"mcml语法错误".."\n"..text;
					self:SetHeadOnDisplay(nil)
					Text3DDisplay.ShowText3DDisplay(true, obj, text, "255 0 0", self.text_offset, -1.57);
				end
			else
				self:SetHeadOnDisplay(nil)
				text = self:GetDisplayName() or text;
				Text3DDisplay.ShowText3DDisplay(true, obj, text, self.text_color, self.text_offset, -1.57);
			end
		else
			Text3DDisplay.ShowText3DDisplay(false, obj);
			self:SetHeadOnDisplay(nil)
		end
	end
end

function Entity:Destroy()
	self:DestroyInnerObject();
	Entity._super.Destroy(self);
end

-- Overriden in a sign to provide the text.
function Entity:GetDescriptionPacket()
	local x,y,z = self:GetBlockPos();
	return Packets.PacketUpdateEntitySign:new():Init(x,y,z, self.cmd, self.block_data);
end


-- whether it can be searched via Ctrl+F FindBlockTask
function Entity:IsSearchable()
	return true;
end

-- update from packet. 
function Entity:OnUpdateFromPacket(packet_UpdateEntitySign)
	if(packet_UpdateEntitySign:isa(Packets.PacketUpdateEntitySign)) then
		self.blockly_nplcode = nil;
		self.nplcode = nil;
		self:SetCommand(packet_UpdateEntitySign.text);
		self.block_data = packet_UpdateEntitySign.data;
		self:Refresh();
		self:remotelyUpdated();
	end
end

function Entity:EndEdit()
	Entity._super.EndEdit(self);
	if(self:IsBlocklyEditMode() and self:GetCommand() ~= self.blockly_nplcode) then
		-- trickly: just in case we modified command directly, we will fallback to npl code instead. 
		self:SetNPLCode(self:GetCommand())
		self:SetBlocklyEditMode(false);
	end
	self:MarkForUpdate();
end

function Entity:OnNeighborChanged(x,y,z, from_block_id)
end

-- called every frame
function Entity:FrameMove(deltaTime)
end

function Entity:OnClick(x, y, z, mouse_button, entity)
	if(mouse_button=="right" and GameLogic.GameMode:CanEditBlock()) then
		self:OpenEditor("entity", entity);
	end
	return true;
end

function Entity:IsPowered()
	return true;
end

function Entity:Stop()
end

function Entity:Restart()
	self:Refresh()
end

function Entity:HasMCML()
	if(self.cmd) then
		return self.cmd:match("^%s*<.*</%w+>%s*$")~=nil;
	end
end

function Entity:GetLanguageConfigFile()
	return self.languageConfigFile or "";
end

function Entity:SetLanguageConfigFile(filename)
	if(self:GetLanguageConfigFile() ~= filename) then
		self.languageConfigFile = filename;
	end
end

-- set code language type
-- @param type: "npl" or "javascript" or "python"
function Entity:SetCodeLanguageType(type)
    type = type or "npl"
	if(self:GetCodeLanguageType() ~= type) then
		self.codeLanguageType = type;
	end
end
-- @return "npl" or "javascript" or "python"
function Entity:GetCodeLanguageType()
    return self.codeLanguageType;
end

function Entity:SaveToXMLNode(node, bSort)
	node = Entity._super.SaveToXMLNode(self, node, bSort);
	self:SaveBlocklyToXMLNode(node);
	return node;
end

function Entity:LoadFromXMLNode(node)
	Entity._super.LoadFromXMLNode(self, node);
	self:LoadBlocklyFromXMLNode(node);
end

function Entity:GetCodeBlock(bCreateIfNotExist)
	if(not self.codeBlock and bCreateIfNotExist) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlock.lua");
		local CodeBlock = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlock");
		self.codeBlock = CodeBlock:new():Init(self);
	end
	return self.codeBlock;
end

function Entity:IsCodeLoaded()
	return true;
end

function Entity:GetFilename()
	return "";
end

function Entity:OpenEditor(editor_name, entity)
	if(not self:HasMCML()) then
		Entity._super.OpenEditor(self, editor_name, entity)
	else
		self:OpenHtmlEditor()
	end
end

function Entity:OpenHtmlEditor()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockWindow.lua");
	local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
	CodeBlockWindow.Show(true);
	CodeBlockWindow.SetCodeEntity(self);
end


function Entity:CloseEditor()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockWindow.lua");
	local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
    CodeBlockWindow.Close()
	CodeBlockWindow.SetCodeEntity(nil);
end

function Entity:SetAllowClientExecution(bAllow)
end

function Entity:IsAllowClientExecution()
	return true;
end

function Entity:SetAllowFastMode(bAllow)
end

function Entity:IsAllowFastMode()
	return true;
end

function Entity:FindNearByMovieEntity()
	return nil
end

local EditorPanelMCML
-- the title text to display (can be mcml)
function Entity:GetCommandTitle()
	EditorPanelMCML = EditorPanelMCML or string.format([[
		<div style="float:left;margin-left:5px;margin-top:7px;">
			<input type="button" uiname="EditEntityPage.OpenHTMLEditor" value='<%%="%s"%%>' onclick="MyCompany.Aries.Game.EntityManager.EntitySign.OnClickAdvancedEditor" style="min-width:80px;color:#ffffff;font-size:12px;height:25px;background:url(Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png#179 89 21 21:8 8 8 8)" />
		</div>
	]], L"HTML编辑器...");
	return EditorPanelMCML;
end

function Entity.OnClickAdvancedEditor()
	NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EditEntityPage.lua");
	local EditEntityPage = commonlib.gettable("MyCompany.Aries.Game.GUI.EditEntityPage");
	local self = EditEntityPage.GetEntity()
	if(self and self:isa(Entity)) then
		EditEntityPage.CloseWindow();
		self:OpenHtmlEditor();
	end
end

function Entity:GetText()
	return self:GetNPLCode()
end

-- return the NPL code line containing the text
-- @param text: string to match
-- @param bExactMatch: if for exact match
-- return true, filename: if the file text is found. filename contains the full filename
function Entity:FindFile(text, bExactMatch)
	local code = self:GetText()
	if(code) then
		return mathlib.StringUtil.FindTextInLine(code, text, bExactMatch)
	end
end