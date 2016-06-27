--[[
Title: Base class for all Rules
Author(s): LiXizhi
Date: 2014/1/27
Desc: 
rule is an abstract virtual base object that can be loaded or activated. 
Unlike items, rules can be created at runtime by the editor in any way they like. 
We can use command to `/addrule` or activate a `/rule`. A rule can also be instantiated via 
a ItemRule object, and placed inside entity's inventory. When the entity is activated, 
the rule object will also be activated. 

* Some rules are simply attributes of the system: see `RulePlayer.lua`
* Some rules like `Quest.lua` have preconditions, exchange rules and even dialog interface when activated. 

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GameRules/RuleBase.lua");
local RuleBase = commonlib.gettable("MyCompany.Aries.Game.Rules.RuleBase");
-------------------------------------------------------
]]
local WorldManager = commonlib.gettable("MyCompany.Aries.WorldManager");
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local RuleBase = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Rules.RuleBase"));

function RuleBase:ctor()
end

-- virtual function: rule is loaded. 
function RuleBase:Init(rule_name, rule_value)
	return self;
end

function RuleBase:GetId()
	return self.id;
end

-- @param filename: recommended format is "config/quests/[id]_[name].xml"
-- if no id is found in the filename, we will use the entire filename as unique id. 
-- such as "1001_helloquest.quest.xml"
-- @return string id, such as "1001"
function RuleBase:GetIDFromFileName(filename)
	filename = filename:match("[^/\\]+$");
	if(filename) then
		local id = filename:match("^%d+");
		if(id) then
			return id;
		else
			return filename:match("[^%.]+")
		end
	end
end


function RuleBase:RewardXmlToTable(xmlnodes)
	if(not xmlnodes)then return end
	local result = {};
	for node in commonlib.XPath.eachNode(xmlnodes, "/items") do
		local items = {};
		for k,v in ipairs(node) do
			local attr = v.attr;
			if(attr)then
				attr.name = v.name;
				attr.id = tonumber(attr.id);
				attr.count = tonumber(attr.value or attr.count);
				attr.value = attr.count;
				table.insert(items, attr);
			end
		end
		local attr = node.attr;
		if(attr)then
			items.id = tonumber(attr.id);
			items.choice = tonumber(attr.choice);
		end
		items.choice = items.choice or -1;
		table.insert(result,items);
	end
	return result;
end

function RuleBase:DialogItemXmlToTable(node)
	local item = node.attr or {};
	for k,v in ipairs(node) do
		local name = v.name;
		if(name == "buttons")then
			local buttons = {};
			item[name] = buttons;
			for kk,vv in ipairs(v) do
				local button = vv.attr or {};
				button.label = button.label or (vv[1] and commonlib.Lua2XmlString(vv[1]));
				table.insert(buttons,button);
			end
		else
			local value;
			if(name == "avatar")then
				value = v.attr or {};
				value.title = value.title or v[1];
			elseif(name == "content")then
				value = commonlib.Lua2XmlString(v[1]);
			end
			item[name] = value;
		end
	end
	return item;
end

function RuleBase:DialogXmlToTable(xmlnodes)
	if(not xmlnodes)then return end
	local dialog = {};
	for node in commonlib.XPath.eachNode(xmlnodes, "/item") do
		local item = self:DialogItemXmlToTable(node);
		table.insert(dialog,item);
	end
	return dialog;
end

-- all preconditions
function RuleBase:PreconditionXmlToTable(xmlnodes)
	if(not xmlnodes)then return end
	local result = {};
	for _, node in ipairs(xmlnodes) do
		local name = node.name;
		local item = node.attr;
		if(item) then
			item.name = name;
			if(name == "quest" or name=="virtualitem")then
				item.value = tonumber(item.value) or 1;
			elseif(name == "item")then
				item.id = item.id and tonumber(item.id);
				item.value = item.value and tonumber(item.value);
				item.topvalue = item.topvalue and tonumber(item.topvalue);
			end
			result[#result+1] = item;
		end			
	end
	return result;
end


-- @param item: {id, value}
-- @return true if entity's inventory has at least those number of items. 
function RuleBase:VerifyItemByEntity(item, triggerEntity)
	triggerEntity = triggerEntity or EntityManager.GetPlayer();
	if(not triggerEntity or not triggerEntity.inventory) then
		return;
	end
	if(item.id) then
		local expected_count = item.count or item.value or 1;
		local count = triggerEntity.inventory:GetItemCount(item.id);
		if(count >= expected_count) then
			return true;
		end
	end
end

-- check if virtual item exist. 
-- TODO: also verify item count
function RuleBase:VerifyVirtualItemByEntity(item, triggerEntity)
	return item and item.id and self:IsFinishedByEntity(triggerEntity, item.id);
end

-- @param item: {id, value}
-- @return true if succeed
function RuleBase:AddItemToEntity(item, triggerEntity)
	triggerEntity = triggerEntity or EntityManager.GetPlayer();
	if(not triggerEntity or not triggerEntity.inventory) then
		return;
	end
	if(item.id) then
		local count = item.count or item.value;
		local itemStack = ItemStack:new():Init(item.id, count);
		return triggerEntity.inventory:AddItemToInventory(itemStack);
	end
end

-- add virtual item
function RuleBase:AddVirtualItemToEntity(item, triggerEntity)
	return item and item.id and self:WriteQuestLogToEntity(triggerEntity, item.id, format("count:%d", item.count or item.value or 1));
end

-- @param item: {id, value}
-- @return true if succeed
function RuleBase:RemoveItemFromEntity(item, triggerEntity)
	triggerEntity = triggerEntity or EntityManager.GetPlayer();
	if(not triggerEntity or not triggerEntity.inventory) then
		return;
	end
	if(item.id) then
		local count = item.count or item.value;
		return triggerEntity.inventory:ClearItems(item.id, count) == count; 
	end
end

function RuleBase:RemoveVirtualItemFromEntity(item, triggerEntity)
	return item and item.id and self:RemoveQuestLogFromEntity(triggerEntity, item.id);
end


-- static function
-- quest log item is the place to store all virtual items, such as quest finished states, etc. 
-- @param bCreateGet: if true, we will create one if not exist. 
-- @return the QuestLog's itemstack if found or created. 
function RuleBase:GetQuestLogItemFromEntity(triggerEntity, bCreateGet)
	triggerEntity = triggerEntity or EntityManager.GetPlayer();
	if(not triggerEntity or not triggerEntity.inventory) then
		return;
	end
	local itemStack = triggerEntity.inventory:FindItem(block_types.names.QuestLog);
	if(not itemStack and bCreateGet) then
		itemStack = ItemStack:new():Init(block_types.names.QuestLog, 1);
		-- add from the 10th item so that it will not appear in hand tools. 
		local bSuccess, slot_index = triggerEntity.inventory:AddItemToInventory(itemStack, 10);
		if(bSuccess and slot_index) then
			itemStack = triggerEntity.inventory:GetItem(slot_index);
		else
			return;
		end
	end
	return itemStack;
end

-- finished quest is encoded in QuestLog item's text content. using `id`
-- @return a map table from finished quest id to true
function RuleBase:GetFinishedQuestsFromEntity(triggerEntity)
	local finished_map = {};
	local itemStack = self:GetQuestLogItemFromEntity(triggerEntity);
	if(itemStack) then
		local content = itemStack:GetData();
		if(type(content) == "string") then
			for quest_id in content:gmatch("`([^`]+)`") do
				finished_map[quest_id] = true;
			end
		end
	end
	return finished_map;
end

-- whether the given virtual quest id is finished.
-- @param quest_id: if nil, it it self.id. 
-- return true if quest is already finished by the entity. 
function RuleBase:IsFinishedByEntity(triggerEntity, quest_id)
	local finished_map = self:GetFinishedQuestsFromEntity(triggerEntity);
	if(finished_map[quest_id or self.id]) then
		-- already finished, skip 
		return true;
	end
end

-- static function:
-- when quest is completed, we can write a text log to the entity's quest log item. 
-- @param quest_id: if nil, it is self.id. 
-- @param text: optional text to write to the log, if nil, default string with quest title is used. 
-- @return true if log is written successfully
function RuleBase:WriteQuestLogToEntity(triggerEntity, quest_id, text)
	if(self:IsFinishedByEntity(triggerEntity, quest_id)) then
		return true;
	end

	local itemStack = self:GetQuestLogItemFromEntity(triggerEntity, true);
	if(itemStack) then
		local content = itemStack:GetData();
		if(type(content)~="string") then
			content = "";
		end

		if(not text) then
			text = format("finished quest: %s;date:%s;", self.title, ParaGlobal.GetDateFormat("yyyy-MM-dd"));
		end
		quest_id = quest_id or self.id;
		local full_text = format("`%s`%s", quest_id, text);
		if(content:match("#$") or content == "") then
			content = content..full_text;
		else
			content = content..("#"..full_text);
		end

		itemStack:SetData(content);
		return true;
	end
end

-- @param quest_id: if nil, it it current quest. 
-- @return true if found and removed
function RuleBase:RemoveQuestLogFromEntity(triggerEntity, quest_id)
	local itemStack = self:GetQuestLogItemFromEntity(triggerEntity);
	if(itemStack) then
		local content = itemStack:GetData();
		if(type(content) == "string") then
			quest_id = quest_id or self.id;
			local new_content = content:gsub("`"..quest_id.."`[^`]*", "")
			if(new_content ~= content) then
				itemStack:SetData(new_content);
				return true;
			end
		end
	end
end

function RuleBase:Print()
	echo(self, true);
end

-- helper function
function RuleBase:GetBool(isEnabled)
	return isEnabled == true or isEnabled=="true" or isEnabled=="on";
end

-- helper function parse number
function RuleBase:GetNumber(value)
	if(type(value) == "string") then
		value = value:match("%-?[%d%.]*");
		if(value) then
			return tonumber(value);
		end
	elseif(type(value) == "number") then
		return value;
	end
end

-- virtual function: when rule is removed from the system. 
function RuleBase:OnRemove()
end


-- try activate this rule by a triggering entity, usually by user clicking or a signal. 
function RuleBase:Activate(triggerEntity)
	if(self:CheckPrecondition(triggerEntity)) then
		self:OnActivated(triggerEntity);
	end
end

-- virtual function: return true, if the rule can be activated.
function RuleBase:CheckPrecondition(triggerEntity)
	return false;
end


-- virtual function: rule is being activated by a triggering entity, usually by user clicking or a signal. 
function RuleBase:OnActivated(triggerEntity)
end
