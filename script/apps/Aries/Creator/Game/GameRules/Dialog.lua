--[[
Title: Dialog
Author(s): LiXizhi
Date: 2016/3/28
Desc: 
Dialog is a rule item, which is defined by an xml file. Dialog rule is usually associated with an NPC entity. 
When the NPC is clicked, the dialog rule is activated. It will display UI dialog to the user according to the 
internal rules defined, such as whether a given quest is active, accepted or finished, etc. 

There are three types of dialogs: gossips, quests and triggers:
* gossips: a randomly picked dialog will be shown when there is no other options
* quests: one or more quest related dialogs
   * startdialog: dialogs to show to the user, when pre-condition is met, but froms and goals are not met.
   * acceptdialog: dialogs to show to the user has already accepted the quest. 
   * enddialog: dialogs to show to the user, when froms and goals are met, before rule is executed. 
* triggers: one or more dialog that is only triggered when virtual item or precondition is found on the target NPC
            triggers themselves can be used to complete simple one-time tasks.
   * input: virtual items or real items before this trigger can be activated. Item listed will be removed after dialog is shown.
   * dialogs: dialogs to show when this item is triggered. 
   * output: virtual items or real items to be given to the user when the dialog is finished. 

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GameRules/Dialog.lua");
local Dialog = commonlib.gettable("MyCompany.Aries.Game.Rules.Dialog");
local dialog = Dialog:new():LoadFromFile("script/apps/Aries/Creator/Game/GameRules/test/1001_test.dialog.xml");
dialog:SaveToFile("1002_test.dialog.xml");
dialog:Print();
-------------------------------------------------------
]]
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");

local Dialog = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Rules.RuleBase"), commonlib.gettable("MyCompany.Aries.Game.Rules.Dialog"));

function Dialog:ctor()
	self.gossips = self.gossips or {};
	self.quests = self.quests or {};
	self.triggers = self.triggers or {};
end

function Dialog:Init(rule_name, rule_params)
	return self;
end

-- load from a dialog file. 
function Dialog:LoadFromFile(filename)
	local filepath = Files.FindFile(filename);
	if(filepath) then
		self.id = self:GetIDFromFileName(filename);
		if(not self.id) then
			LOG.std(nil, "warn", "dialog", "Id is not found %s", filename);
			return;
		end
		local xmlRoot = ParaXML.LuaXML_ParseFile(filepath);

		local node = commonlib.XPath.selectNode(xmlRoot, "/dialogs") or {};
		if(node and node.attr) then
			self.title = node.attr.title
		end
		for k,v in ipairs(node) do
			local name = v.name;
			if(name == "gossips")then
				for _, gossip in ipairs(commonlib.XPath.selectNodes(v, "/dialog") or {}) do
					self.gossips[#self.gossips+1] = self:DialogXmlToTable(gossip);
				end
			elseif(name == "quests")then
				for _, quest in ipairs(commonlib.XPath.selectNodes(v, "/quest") or {}) do
					self.quests[#self.quests+1] = quest;
				end
			elseif(name == "triggers")then
				for _, trigger in ipairs(commonlib.XPath.selectNodes(v, "/trigger") or {}) do
					local triggerNode = trigger.attr or {};
					self.triggers[#self.triggers+1] = triggerNode;
					for _, node in ipairs(trigger) do
						if(node.name == "input" or node.name == "output") then
							triggerNode[node.name] = self:PreconditionXmlToTable(node);
						elseif(node.name == "dialog") then
							triggerNode[node.name] = self:DialogXmlToTable(node);
						else
							triggerNode[node.name] = node;
						end
					end
				end
			end
		end
	end
	
	return self;
end

-- @param filename: relative to current world directory path.
function Dialog:SaveToFile(filename)
	if(not filename) then
		return;
	end
	
	local gossips = {name="gossips", };
	local quests = {name="quests", };
	local triggers = {name="triggers", };
	local output = {name="dialogs", attr = {title=self:GetTitle()},
		 gossips,
		 quests,
		 triggers,
	};

	for i, gossip in ipairs(self.gossips) do
		local dialogNode = {name="dialog"};
		gossips[i] = dialogNode;
		for i, item in ipairs(gossip) do
			local itemNode = {name="item", attr = {name=item.name}}; 
			dialogNode[i] = itemNode;
			if(item.avatar) then
				itemNode[#itemNode+1] = {name="avatar", attr={name=item.avatar.name}, item.avatar.text};
			end
			if(item.content) then
				itemNode[#itemNode+1] = {name="content", item.content};
			end
			if(item.buttons) then
				local buttons = {name="buttons",};
				itemNode[#itemNode+1] = buttons;
				for i, button in ipairs(item.buttons) do
					buttons[i] = {name="button", attr={action=button.action}, button.label};
				end
			end
		end
	end

	for i, trigger in ipairs(self.triggers) do
		local triggerNode = {name="trigger"};
		triggers[i] = triggerNode;

		-- input
		if(trigger.input) then
			local inputNode = {name="input"};
			triggerNode[#triggerNode+1] = inputNode;
			for i, item in ipairs(trigger.input) do
				inputNode[i] = {name = item.name, attr={id = item.id, value = item.value or item.count}};
			end
		end

		-- dialog
		if(trigger.dialog) then
			local dialog = {name="dialog"};
			triggerNode[#triggerNode+1] = dialog;
			for i, item in ipairs(trigger.dialog) do
				local itemNode = {name="item", attr = {name=item.name}}; 
				dialog[i] = itemNode;
				if(item.avatar) then
					itemNode[#itemNode+1] = {name="avatar", attr={name=item.avatar.name}, item.avatar.text};
				end
				if(item.content) then
					itemNode[#itemNode+1] = {name="content", item.content};
				end
				if(item.buttons) then
					local buttons = {name="buttons",};
					itemNode[#itemNode+1] = buttons;
					for i, button in ipairs(item.buttons) do
						buttons[i] = {name="button", attr={action=button.action}, button.label};
					end
				end
			end
		end

		-- output
		if(trigger.output) then
			local outputNode = {name="output"};
			triggerNode[#triggerNode+1] = outputNode;
			for i, item in ipairs(trigger.output) do
				outputNode[i] = {name = item.name, attr={id = item.id, value = item.value or item.count}};
			end
		end
	end

	-- TODO: quest not supported yet

	-- write the disk file
	NPL.load("(gl)script/ide/LuaXML.lua");
	local fullpath = Files.FindFile(filename);
	if(not fullpath) then
		fullpath = GameLogic.GetWorldDirectory()..filename;
	end
	if(fullpath) then
		local file = ParaIO.open(fullpath, "w");
		if(file:IsValid()) then
			LOG.std(nil, "info", "Dialog", "successfully saved to %s", fullpath);
			file:WriteString(commonlib.Lua2XmlString(output, true, true));
			file:close();

			-- refresh filename
			NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
			local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
			local ItemDialog = ItemClient.GetItemByName("Dialog");
			if(ItemDialog) then
				ItemDialog:Reload(filename);
				LOG.std(nil, "info", "Dialog", "refreshed file: %s", filename);
			end
			return true;
		end
	end
end

function Dialog:ToJsonObject()
	return {title=self:GetTitle(), gossips = self.gossips, quests = self.quests, triggers = self.triggers};
end

-- @return title string or nil.
function Dialog:GetTitle()
	return self.title;
end


-- get the next random gossip dialog. 
function Dialog:GetGossipDialog()
	if(#self.gossips > 0) then
		self.last_gossip_index = self.last_gossip_index or math.random(1, #self.gossips);
		self.last_gossip_index = self.last_gossip_index + 1;
		if(self.last_gossip_index >  #self.gossips) then
			self.last_gossip_index = 1;
		end
		return self.gossips[self.last_gossip_index];
	end
end

function Dialog:VerifyTriggerInput(trigger)
	for _, condition in ipairs(trigger.input) do
		if(condition.name == "item") then
			if( not self:VerifyItemByEntity(condition, triggerEntity)) then
				return false;
			end
		elseif(condition.name == "virtualitem") then
			if( not self:VerifyVirtualItemByEntity(condition, triggerEntity)) then
				return false;
			end
		end
	end
	return true;
end

-- get the trigger or nil
function Dialog:GetActiveTrigger()
	for _, trigger in ipairs(self.triggers) do
		if(trigger and self:VerifyTriggerInput(trigger)) then
			return trigger;
		end
	end
end

function Dialog:DoTriggerRule(trigger, triggerEntity)
	-- remove input items and add output items
	if(trigger.input) then
		for _, item in ipairs(trigger.input) do
			if(item.name == "item") then
				self:RemoveItemFromEntity(item, triggerEntity);
			elseif(item.name == "virtualitem") then
				self:RemoveVirtualItemFromEntity(item, triggerEntity);
			end
		end
	end
	if(trigger.output) then
		for _, item in ipairs(trigger.output) do
			if(item.name == "item") then
				self:AddItemToEntity(item, triggerEntity);
			elseif(item.name == "virtualitem") then
				self:AddVirtualItemToEntity(item, triggerEntity);
			end
		end		
	end	
end

-- @return true if triggered a dialog.
function Dialog:ActivateTrigger(entityContainer, entityPlayer)
	local trigger = self:GetActiveTrigger();
	if(trigger and trigger.dialog) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/NPCDialogPage.lua");
		local NPCDialogPage = commonlib.gettable("MyCompany.Aries.Game.GUI.NPCDialogPage");
		NPCDialogPage.ShowPage(trigger.dialog, entityContainer, entityPlayer, function(action) 
			if(action=="do" or action=="run" or action=="doaccept" or action=="accept") then
				self:DoTriggerRule(trigger, entityPlayer);
			end
		end);
		return true;
	end
end

function Dialog:ActivateGossip(entityContainer, entityPlayer)
	local dialog = self:GetGossipDialog();
	if(dialog) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/NPCDialogPage.lua");
		local NPCDialogPage = commonlib.gettable("MyCompany.Aries.Game.GUI.NPCDialogPage");
		NPCDialogPage.ShowPage(dialog, entityContainer, entityPlayer, function(action) 
		end);
	end	
	return true
end

function Dialog:ActivateQuest(entityContainer, entityPlayer)
	if(self.quests) then
		-- TODO: 
	end
end

-- called when the entityContainer is activated by entityPlayer. 
-- @param entity: the container entity. this is usually a command block or entity. 
-- @param entityPlayer: the triggering entity
-- @return true if the entity should stop activating other items in its bag. 
function Dialog:OnActivate(entityContainer, entityPlayer)
	return self:ActivateTrigger(entityContainer, entityPlayer) or 
		   self:ActivateQuest(entityContainer, entityPlayer) or 
		   self:ActivateGossip(entityContainer, entityPlayer);
end