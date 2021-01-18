--[[
Title: CommandBlock Entity
Author(s): LiXizhi
Date: 2013/12/17
Desc: It also fire neuron activation. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityCommandBlock.lua");
local EntityCommandBlock = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCommandBlock")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityBlockBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Neuron/NeuronManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/InventoryBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ContainerView.lua");
local ContainerView = commonlib.gettable("MyCompany.Aries.Game.Items.ContainerView");
local InventoryBase = commonlib.gettable("MyCompany.Aries.Game.Items.InventoryBase");
local NeuronManager = commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronManager");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockBase"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCommandBlock"));
Entity:Property({"languageConfigFile", "commands", "GetLanguageConfigFile", "SetLanguageConfigFile"})
Entity:Property({"isAllowClientExecution", false, "IsAllowClientExecution", "SetAllowClientExecution"})
Entity:Property({"isAllowFastMode", false, "IsAllowFastMode", "SetAllowFastMode"})

Entity:Signal("beforeRemoved")
Entity:Signal("editModeChanged")
Entity:Signal("remotelyUpdated")
Entity:Signal("inventoryChanged", function(slotIndex) end)

-- class name
Entity.class_name = "EntityCommandBlock";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);
Entity.is_persistent = true;
-- always serialize to 512*512 regional entity file
Entity.is_regional = true;
-- command line text

function Entity:ctor()
	self.inventory = InventoryBase:new():Init();
	self.inventory:SetClient();
end

function Entity:Refresh()
end

function Entity:OnRemoved()
	self:beforeRemoved();
	Entity._super.OnRemoved(self);
end

-- virtual function: handle some external input. 
-- default is do nothing. return true is something is processed. 
function Entity:OnActivated(triggerEntity)
	return self:ExecuteCommand(triggerEntity, true);
end

-- the command block's variable is always the current player's variable
function Entity:GetVariables()
	local player = EntityManager.GetPlayer();
	if(player) then
		return player:GetVariables();
	end
end

-- @param entityPlayer: this is the triggering player or sometimes the command entity itself if /activate self is used. 
-- @param bIgnoreNeuronActivation: true to ignore neuron activation. 
-- @param bIgnoreOutput: ignore output
function Entity:ExecuteCommand(entityPlayer, bIgnoreNeuronActivation, bIgnoreOutput)
	if(self:IsInputDisabled()) then
		return
	end

	-- clear all time event
	self:ClearTimeEvent();

	-- just in case the command contains variables. 
	local variables = (entityPlayer or self):GetVariables();
	local last_result;
	local cmd_list = self:GetCommandList();
	if(cmd_list) then
		last_result = CommandManager:RunCmdList(cmd_list, variables, self);
	end

	local bIsInsideBracket;
	local bIsNegatingSign;
	for i = 1, self.inventory:GetSlotCount() do
		local itemStack = self.inventory:GetItem(i);
		if(itemStack) then
			if(bIsInsideBracket) then
				if(itemStack.id == block_types.names.Wire)then
					-- this is a logical OR
					bIsInsideBracket = false;
					bIsNegatingSign = false;
				end
			else
				if(itemStack.id == block_types.names.Electric_Torch_On)then
					bIsNegatingSign = not bIsNegatingSign;
				else
					-- if script return false, we will stop loading slots behind
					last_result = itemStack:OnActivate(self, entityPlayer);
					if( (not bIsNegatingSign and last_result==false) or  (bIsNegatingSign and last_result~=false) ) then
						if(not bIsInsideBracket) then
							bIsInsideBracket = true;
						else
							break;
						end
					end	
					if(bIsNegatingSign) then
						bIsNegatingSign = false;
					end
				end
			end
		end
	end

	if(not bIgnoreOutput) then
		self:SetLastCommandResult(last_result);
	end

	-- if the containing block is a neuron block, we will fire an activation. 
	if(not bIgnoreNeuronActivation) then
		local bx, by, bz = self:GetBlockPos();
		local neuron = NeuronManager.GetNeuron(bx, by, bz, false);
		if(neuron) then
			neuron:Activate({type="click", action="toggle"});
		end
	end
end

-- get the last electric output result. 
function Entity:GetLastOutput()
	return self.last_output;
end

-- get output from result. if result is a value larger than 1. 
-- value larger than 15 is clipped. 
-- @return nil or a value between [1,15]
function Entity:ComputeElectricOutput(last_result)
	if(type(last_result) == "number" and last_result>=1) then
		return math.min(15, math.floor(last_result));
	end
end

-- set the last result. 
function Entity:SetLastCommandResult(last_result)
	local output = self:ComputeElectricOutput(last_result)
	if(self.last_output ~= output) then
		self.last_output = output;
		local x, y, z = self:GetBlockPos();
		BlockEngine:NotifyNeighborBlocksChange(x, y, z, BlockEngine:GetBlockId(x, y, z));
	end
end

function Entity:OnNeighborChanged(x,y,z, from_block_id)
	if(not GameLogic.isRemote) then
		local isPowered = BlockEngine:isBlockIndirectlyGettingPowered(x,y,z);
		if(self.isPowered ~= isPowered) then
			self.isPowered = isPowered;
			if(isPowered) then
				self.timer = self.timer or commonlib.Timer:new({callbackFunc = function(timer)
					local x,y,z = self:GetBlockPos();
					local isPowered = BlockEngine:isBlockIndirectlyGettingPowered(x,y,z);
					if(isPowered) then
						self:ExecuteCommand();
					end
				end})
				self.timer:Change(30, nil);
			end
		end
	end
end

function Entity:ClearCommand()
	self.cmd = nil;
	self.blockly_xmlcode = nil
	self.blockly_nplcode = nil
	self.nplcode = nil
end

function Entity:LoadFromXMLNode(node)
	Entity._super.LoadFromXMLNode(self, node);
	self.isPowered = node.attr.isPowered == "true";
	self.isBlocklyEditMode = (node.attr.isBlocklyEditMode == "true" or node.attr.isBlocklyEditMode == true);
	if(node.attr.last_output) then
		self.last_output = tonumber(node.attr.last_output);
	end
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
					elseif(sub_node.name == "code") then
						self:SetNPLCode(code);
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
		self:SetCommand(self:GetBlocklyNPLCode());
	else
		self:SetCommand(self:GetNPLCode());
	end
end

function Entity:SaveToXMLNode(node, bSort)
	node = Entity._super.SaveToXMLNode(self, node, bSort);
	if(self.isPowered) then
		node.attr.isPowered = true;
	end
	if(self.last_output) then
		node.attr.last_output = self.last_output;
	end
	if(self:IsBlocklyEditMode()) then
		node.attr.isBlocklyEditMode = true;
	end

	if(self:GetBlocklyXMLCode() and self:GetBlocklyXMLCode()~="") then
		local blocklyNode = {name="blockly", };
		node[#node+1] = blocklyNode;
		blocklyNode[#blocklyNode+1] = {name="xmlcode", self:TextToXmlInnerNode(self:GetBlocklyXMLCode())}
		blocklyNode[#blocklyNode+1] = {name="nplcode", self:TextToXmlInnerNode(self:GetBlocklyNPLCode()) }
		if(self:GetNPLCode()~=self:GetBlocklyNPLCode()) then
			blocklyNode[#blocklyNode+1] = {name="code", self:TextToXmlInnerNode(self:GetNPLCode())}
		end
	end

	return node;
end

-- allow editing bag 
function Entity:HasBag()
	return true;
end

-- called when the user clicks on the block
-- @return: return true if it is an action block and processed . 
function Entity:OnClick(x, y, z, mouse_button, entity, side)
	if(GameLogic.isRemote) then
		if(mouse_button=="right" and GameLogic.GameMode:CanEditBlock()) then
			self:OpenEditor("entity", entity);	
		end
	else
		return Entity._super.OnClick(self, x, y, z, mouse_button, entity, side);
	end
	return true;
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
			self:LoadFromXMLNode(node)
			self:remotelyUpdated();
		end
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

-- virtual function: get array of item stacks that will be displayed to the user when user try to create a new item. 
-- @return nil or array of item stack.
function Entity:GetNewItemsList()
	local itemStackArray = Entity._super.GetNewItemsList(self) or {};
	local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
	itemStackArray[#itemStackArray+1] = ItemStack:new():Init(block_types.names.CommandLine,1);
	itemStackArray[#itemStackArray+1] = ItemStack:new():Init(block_types.names.Code,1);
	itemStackArray[#itemStackArray+1] = ItemStack:new():Init(block_types.names.Wire,1);
	return itemStackArray;
end

-- called every frame
function Entity:FrameMove(deltaTime)
	if(not self:IsPaused() and not self:AdvanceTime(deltaTime)) then
		-- stop ticking when there is no timed event. 
		self:SetFrameMoveInterval(nil);
	end
end

function Entity:IsPowered()
	return self.isPowered;
end

function Entity:Stop()
end

function Entity:Restart()
	self:ExecuteCommand(EntityManager.GetPlayer(), true, true);
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


function Entity:SetBlocklyXMLCode(blockly_xmlcode)
	self.blockly_xmlcode = blockly_xmlcode;
end

function Entity:GetBlocklyXMLCode()
	return self.blockly_xmlcode;
end


function Entity:SetBlocklyNPLCode(blockly_nplcode)
	self.blockly_nplcode = blockly_nplcode;
	self:SetCommand(blockly_nplcode);
end

function Entity:GetBlocklyNPLCode()
	return self.blockly_nplcode;
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

function Entity:TextToXmlInnerNode(text)
	if(text and commonlib.Encoding.HasXMLEscapeChar(text)) then
		return {name="![CDATA[", [1] = text};
	else
		return text;
	end
end


function Entity:IsBlocklyEditMode()
	return self.isBlocklyEditMode;
end

function Entity:SetBlocklyEditMode(bEnabled)
	if(self.isBlocklyEditMode~=bEnabled) then
		self.isBlocklyEditMode = bEnabled;
		if(bEnabled)  then
			self:SetCommand(self:GetBlocklyNPLCode());
		else
			self:SetCommand(self:GetNPLCode());
		end
		self:editModeChanged();
	end
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

function Entity:OpenCommandsEditor()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockWindow.lua");
	local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
	CodeBlockWindow.Show(true);
	CodeBlockWindow.SetCodeEntity(self);
end

function Entity:CloseEditor()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockWindow.lua");
	local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
    CodeBlockWindow.Close()
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
	-- return L"输入命令行(可以多行): <div>例如:/echo Hello</div>"
	EditorPanelMCML = EditorPanelMCML or string.format([[
		<div style="float:left;margin-left:5px;margin-top:7px;">
			<input type="button" uiname="EditEntityPage.CommandEditor" value='<%%="%s"%%>' onclick="MyCompany.Aries.Game.EntityManager.EntityCommandBlock.OnClickAdvancedEditor" style="min-width:80px;color:#ffffff;font-size:12px;height:25px;background:url(Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png#179 89 21 21:8 8 8 8)" />
		</div>
	]], L"命令编辑器...");
	return EditorPanelMCML;
end

function Entity.OnClickAdvancedEditor()
	NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EditEntityPage.lua");
	local EditEntityPage = commonlib.gettable("MyCompany.Aries.Game.GUI.EditEntityPage");
	local self = EditEntityPage.GetEntity()
	if(self and self:isa(Entity)) then
		EditEntityPage.CloseWindow();
		self:OpenCommandsEditor();
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