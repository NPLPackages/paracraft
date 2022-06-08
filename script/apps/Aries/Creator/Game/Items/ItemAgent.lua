--[[
Title: ItemAgent
Author(s): LiXizhi
Date: 2021/2/17
Desc: Agent item is a special item that is defined in code blocks. The appearance and functions of the agent item 
are implemented by registerAgentEvent in code blocks. Agent Item is usually listed in the inventory of agent sign block. 
If Agent Item's GetIcon function is implemented and has a valid icon file, we will also add the agent to the block lists' tools category. 

One can also define script based ItemAgent by deriving your class from ItemAgentBase class. 
We will automatically load agent from ItemAgent.searchpath folder on first use. 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemAgent.lua");
local ItemAgent = commonlib.gettable("MyCompany.Aries.Game.Items.ItemAgent");
local item = ItemAgent:new({icon,});
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/Identicon.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemAgentBase.lua");
local Identicon = commonlib.gettable("System.Windows.Controls.Identicon");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");

local ItemAgent = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.Item"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemAgent"));

-- where to search for buildin agents. "Examples/AgentDemo" will look for a file in "Examples/AgentDemo.lua" in following folder
ItemAgent.searchpath = "script/apps/Aries/Creator/Game/Tasks/ParaLife/Agent/";

block_types.RegisterItemClass("ItemAgent", ItemAgent);

function ItemAgent:ctor()
	self.m_bIsOwnerDrawIcon = true;
	self.referencedEntity = {};
	self.agentClasses = {};
end
 
 
-- return true if items are the same. 
-- @param left, right: type of ItemStack or nil. 
function ItemAgent:CompareItems(left, right)
	if(ItemAgent._super.CompareItems(self, left, right)) then
		if(left and right and left:GetDataField("name") == right:GetDataField("name")) then
			return true;
		end
	end
end

function ItemAgent:GetAgentName(itemStack)
	return itemStack and itemStack:GetDataField("name") or itemStack:GetDataField("tooltip");
end

function ItemAgent:SetAgentName(itemStack, name)
	if(itemStack) then
		itemStack:SetDataField("name", name);
	end
end

function ItemAgent:GetTooltipFromItemStack(itemStack)
	if(itemStack) then
		local name = itemStack:GetDataField("name");
		if(name) then
			local tooltip = GameLogic.GetCodeGlobal():BroadcastTextEvent(name..".GetTooltip")
			return tooltip or name
		end
	end
end

function ItemAgent:IsInited(itemStack)
	if(itemStack) then
		local name = self:GetAgentName(itemStack)
		if(not name or name == "") then
			return true
		end
	end
end

-- @return true if agent item has a name and initialized. 
function ItemAgent:TryInitAgent(itemStack)
	if(itemStack) then
		local name = self:GetAgentName(itemStack)
		if(not name or name == "") then
			self:OnOpenEditAgentNameDialog(itemStack)
			return;
		else
			return true
		end
	end
end

function ItemAgent:OnOpenEditAgentNameDialog(itemStack)
	NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
	local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
	EnterTextDialog.ShowPage(L"请输入智能人物的名字", function(result)
		if(result and result~="") then
			self:SetAgentName(itemStack, result)
		end
	end, self:GetAgentName(itemStack))
end

function ItemAgent:OnItemRightClick(itemStack, entityPlayer)
	if(self:TryInitAgent(itemStack)) then
		return itemStack, false;	
	else
		return itemStack, true;	
	end
end

function ItemAgent:GetIcon(itemStack)
	if(itemStack and type(itemStack) == "table") then
		local name = self:GetAgentName(itemStack)
		if(name and name~="") then
			local agentClass = self:CheckGetAgentClass(name)
			if(agentClass) then
				return agentClass:GetIcon(itemStack);
			else
				local icon = itemStack.icon_;
				if(not icon) then
					icon = GameLogic.GetCodeGlobal():BroadcastTextEvent(name..".GetIcon")
					if(icon) then
						icon = Files.GetWorldFilePath(icon)
						itemStack.icon_ = icon;
						return icon
					end
				elseif(icon ~= "") then
					return icon;
				end
			end
		end
	end
	return ItemAgent._super.GetIcon(self)
end

-- virtual: draw icon with given size at current position (0,0)
-- this function is only called when IsOwnerDrawIcon property is true. 
-- @param width, height: size of the icon
-- @param itemStack: this may be nil. or itemStack instance. 
function ItemAgent:DrawIcon(painter, width, height, itemStack)
	painter:SetPen(self:GetIconColor());
	painter:DrawRectTexture(0, 0, width, height, self:GetIcon(itemStack));
	if(itemStack and not itemStack.icon_) then
		local name = self:GetAgentName(itemStack)
		if(name and name~="") then
			-- render identi-icon
			local size = width;
			local hash = ParaMisc.md5(name);
			local margin = 4
			painter:SetPen("#000000");
			painter:DrawRect(0, 0, width, height);
			Identicon.drawIdentiIcon(painter, hash, size, margin)
		end
	end

	if(itemStack) then
		if(itemStack.count>1) then
			-- draw count at the corner: no clipping, right aligned, single line
			painter:SetPen("#000000");	
			painter:DrawText(0, height-15+1, width, 15, tostring(itemStack.count), 0x122);
			painter:SetPen("#ffffff");	
			painter:DrawText(0, height-15, width-1, 15, tostring(itemStack.count), 0x122);
		end
	end
end

-- virtual function: use the item. 
function ItemAgent:OnUse()
end

-- virtual function: when selected in right hand
function ItemAgent:OnSelect(itemStack)
	if(self:TryInitAgent(itemStack)) then
		local name = self:GetAgentName(itemStack)
		if(name and name~="") then
			self.curItemStack = itemStack;
			
			local agentClass = self:CheckGetAgentClass(name)
			if(agentClass) then
				return agentClass:OnSelect(itemStack);
			else
				GameLogic.GetCodeGlobal():BroadcastTextEvent(name..".OnSelect")
			end
		end
	end
end

-- virtual function: when deselected in right hand
function ItemAgent:OnDeSelect()
	local itemStack = self.curItemStack;
	self.curItemStack = nil;
	if(self:TryInitAgent(itemStack)) then
		local name = self:GetAgentName(itemStack)
		if(name and name~="") then
			local agentClass = self:CheckGetAgentClass(name)
			if(agentClass) then
				return agentClass:OnDeSelect();
			else
				GameLogic.GetCodeGlobal():BroadcastTextEvent(name..".OnDeSelect")
			end
		end
	end
end

function ItemAgent:OnClickInHand(itemStack, entityPlayer)
	if(self:TryInitAgent(itemStack)) then
		local name = self:GetAgentName(itemStack)
		if(name and name~="") then
			local agentClass = self:CheckGetAgentClass(name)
			if(agentClass) then
				agentClass:OnClickInHand(itemStack, entityPlayer)
			else
				GameLogic.GetCodeGlobal():BroadcastTextEvent(name..".OnClickInHand")
			end
		end
	end
end

-- Right clicking in 3d world with the block in hand will trigger this function. 
-- Alias: OnUseItem;
-- @param itemStack: can be nil
-- @param entityPlayer: can be nil
-- @param side: this is OPPOSITE of the touching side
-- @return isUsed, entityCreated: isUsed is true if something happens.
function ItemAgent:TryCreate(itemStack, entityPlayer, x,y,z, side, data, side_region)
	if(self:TryInitAgent(itemStack)) then
		local name = self:GetAgentName(itemStack)
		if(name and name~="") then
			local agentClass = self:CheckGetAgentClass(name)
			if(agentClass) then
				agentClass:TryCreate(itemStack, entityPlayer, x,y,z, side, data, side_region)
			else
				GameLogic.GetCodeGlobal():BroadcastTextEvent(name..".TryCreate", {x=x,y=y,z=z, side=side, data=data, side_region=side_region})
			end
		end
	end
end

function ItemAgent:OnLeaveWorld()
	self.referencedEntity = {};
	self.agentClasses = {};
end

function ItemAgent:GetAllReferencedEntities(agentName)
	return self.referencedEntity[agentName]
end

function ItemAgent:SetReferencedEntity(agentName, entity, value)
	local entities = self.referencedEntity[agentName]
	if(not entities) then
		entities = {}
		self.referencedEntity[agentName] = entities;
	end
	entities[entity] = value;
end

function ItemAgent:FireLoadEventForAll(agentName)
	if(agentName) then
		local codeGlobal = GameLogic.GetCodeGlobal()
		local fullname = agentName..".OnLoadInEntity"
		-- TODO: we need to get itemstack in entity's bag, now it is nil. 
		local itemStack; 
		for entity, _ in pairs(self:GetAllReferencedEntities(agentName)) do
			codeGlobal:BroadcastTextEventTo(entity, fullname, {entity=entity, itemStack = itemStack}, true)
		end
	end
end

-- call this function to register a buildin agent class. 
-- @param agent: this is usually a class derived from ItemAgentBase class. 
function ItemAgent:RegisterAgentClass(name, agent)
	self.agentClasses[name] = agent;
end

-- we will look for the paralife's agent folder for buildin agent classes. 
function ItemAgent:CheckGetAgentClass(name)
	local agentClass = self.agentClasses[name]
	if(agentClass ~= nil) then
		return agentClass;
	else
		self.agentClasses[name] = false;
		agentClass = NPL.load(self.searchpath..name..".lua")
		if(agentClass) then
			agentClass = agentClass:new():Init(name);
			if(agentClass) then
				self:RegisterAgentClass(name, agentClass);
			end
		end
		return agentClass;
	end
end

-- virtual function: create agent controller interface for the parentEntity. 
-- this function is called when entity:GetAgent(agentName) is called for the first matching agent in rule bag. 
function ItemAgent:CreateAgentFromEntity(parentEntity, itemStack)
	local name = self:GetAgentName(itemStack)
	if(name and name~="") then
		local agentClass = self:CheckGetAgentClass(name)
		if(agentClass) then
			return agentClass:CreateAgentFromEntity(parentEntity, itemStack)
		else
			local fullname = name..".CreateAgentFromEntity"
			local codeGlobal = GameLogic.GetCodeGlobal()
			if(codeGlobal:GetTextEvent(fullname)) then
				return codeGlobal:BroadcastTextEventTo(parentEntity, fullname, {entity = parentEntity}, true);
			end
		end
	end
end

-- virtual function: this function is called when the item is placed inside an entity, as one of its bag item(component). 
-- this function is ALSO called when the parent entity is loaded from disk. 
function ItemAgent:OnLoadInEntity(parentEntity, itemStack)
	local name = self:GetAgentName(itemStack)
	if(name and name~="") then
		self:SetReferencedEntity(name, parentEntity, true)
		local agentClass = self:CheckGetAgentClass(name)
		if(agentClass) then
			agentClass:OnLoadInEntity(parentEntity, itemStack)
		else
			local fullname = name..".OnLoadInEntity"
			local codeGlobal = GameLogic.GetCodeGlobal()
			if(codeGlobal:GetTextEvent(fullname)) then
				return codeGlobal:BroadcastTextEventTo(parentEntity, fullname, {entity=parentEntity, itemStack = itemStack}, true)
			end
		end
	end
end

-- virtual function: this function is called when the item is removed from an entity, as one of its bag item (component). 
function ItemAgent:OnUnloadInEntity(parentEntity, itemStack)
	local name = self:GetAgentName(itemStack)
	if(name and name~="") then
		self:SetReferencedEntity(name, parentEntity, nil)
		local agentClass = self:CheckGetAgentClass(name)
		if(agentClass) then
			return agentClass:OnUnloadInEntity(parentEntity, itemStack)
		else
			return GameLogic.GetCodeGlobal():BroadcastTextEventTo(parentEntity, name..".OnUnloadInEntity", {entity=parentEntity, itemStack = itemStack}, true)
		end
	end
end

function ItemAgent:DispatchAgentEvent(itemStack, entity, eventName, msg)
	local name = self:GetAgentName(itemStack)
	if(name and name~="") then
		local agentClass = self:CheckGetAgentClass(name)
		if(agentClass) then
			return agentClass:DispatchAgentEvent(itemStack, entity, eventName, msg)
		else
			local fullname = name.."."..eventName;
			local codeGlobal = GameLogic.GetCodeGlobal()
			if(codeGlobal:GetTextEvent(fullname)) then
				return codeGlobal:BroadcastTextEventTo(entity, fullname, {entity=entity, msg = msg}, true)
			end
		end
	end
end

-- called when entity receives a custom event via one of its rule bag items. 
function ItemAgent:handleEntityEvent(itemStack, entity, event)
	local name = self:GetAgentName(itemStack)
	if(name and name~="") then
		local event_type = event:GetType()
		if(event_type == "ontick") then
			local agentClass = self:CheckGetAgentClass(name)
			if(agentClass) then
				agentClass:OnTick(itemStack, entity);
			else
				local codeGlobal = GameLogic.GetCodeGlobal()
				local fullname = name..".OnEntityTick"
				if(codeGlobal:GetTextEvent(fullname)) then
					return codeGlobal:BroadcastTextEventTo(entity, fullname, {entity=entity, itemStack = itemStack}, true)
				end
			end
		else
			local agentClass = self:CheckGetAgentClass(name)
			if(agentClass) then
				agentClass:OnEntityEvent(itemStack, entity, event);
				if(event_type == "onclick") then
					return agentClass:OnEntityClick(itemStack, entity, event);
				end
			else
				local codeGlobal = GameLogic.GetCodeGlobal()
				-- "OnEntityEvent" will receive all mouse related events except "ontick", including "mousePressedEvent", "onclick", etc. 
				local fullname = name..".OnEntityEvent"
				if(codeGlobal:GetTextEvent(fullname)) then
					codeGlobal:BroadcastTextEventTo(entity, fullname, {entity=entity, itemStack = itemStack, event = event}, true)
				end
				-- fire individule events, such as "OnEntityClick"
				if(event_type == "onclick" and codeGlobal:GetTextEvent(name..".OnEntityClick")) then
					return codeGlobal:BroadcastTextEventTo(entity, name..".OnEntityClick", {entity=entity, itemStack = itemStack}, true)
				end
			end
		end
	end
end