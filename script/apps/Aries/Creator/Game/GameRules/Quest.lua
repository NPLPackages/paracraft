--[[
Title: Quest
Author(s): LiXizhi
Date: 2016/3/15
Desc: 
Quest is a complex rule item, which is defined by an xml file.
A quest rule contains:
* preconditions: such as how many items must be collected by the triggering entity before the quest is active. 
* goals: a list of goals to complete before the quest can be completed. 
* cost: a list of items to remove when rule is finished.  
* reward: a list of items to receive when rule is finished.
* startdialog: dialogs to show to the user, when pre-condition is met, but froms and goals are not met, 
* enddialog: dialogs to show to the user, when froms and goals are met, before rule is executed. 
* repeatable: if quest can be repeatly done.

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GameRules/Quest.lua");
local Quest = commonlib.gettable("MyCompany.Aries.Game.Rules.Quest");
local quest = Quest:new():LoadFromFile("script/apps/Aries/Creator/Game/GameRules/test/1001_test.quest.xml");
local triggerEntity = nil;
quest:WriteQuestLogToEntity(triggerEntity, nil, "finished");
assert(quest:IsFinishedByEntity(triggerEntity) == true)
quest:RemoveQuestLogFromEntity(triggerEntity, quest.id);
assert(not quest:IsFinishedByEntity(triggerEntity))
quest:WriteQuestLogToEntity(triggerEntity, "quest1000", "this is precondition log");
if(quest:IsActive(triggerEntity)) then
	echo("quest is active");
	if(quest:CanFinish(triggerEntity)) then
		echo({quest:DoFinish(triggerEntity), "finished"});
	end
end
-------------------------------------------------------
]]
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");

local Quest = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Rules.RuleBase"), commonlib.gettable("MyCompany.Aries.Game.Rules.Quest"));

function Quest:ctor()
end

function Quest:Init(rule_name, rule_params)
	return self;
end

-- load from a quest file. 
function Quest:LoadFromFile(filename)
	local filepath = Files.FindFile(filename);
	if(filepath) then
		self.id = self:GetIDFromFileName(filename);
		if(not self.id) then
			LOG.std(nil, "warn", "quest", "Id is not found %s", filename);
			return;
		end
		local xmlRoot = ParaXML.LuaXML_ParseFile(filepath);

		local node = commonlib.XPath.selectNode(xmlRoot, "/quest");
		for k,v in ipairs(node) do
			local name = v.name;
			if(name == "title" or name == "detail" or name == "icon")then
				self[name] = v[1] or "";
			elseif(name == "reward" or name == "cost")then
				self[name] = self:RewardXmlToTable(v);
			elseif(name == "startdialog" or name == "enddialog")then
				self[name] = self:DialogXmlToTable(v);
			elseif(name == "precondition")then
				self[name] = self:PreconditionXmlToTable(v);
			else
				self[name] = tonumber(v[1]);
			end
		end
	end
	return self;
end

-- if quest can be repeatly done. 
function Quest:IsRepeatable()
	return self.repeatable == 1;
end


-- it we verify if all precondition is met, including whether current quest is finished, previous quest
-- and item count. 
-- @return true, if quest is active
function Quest:CheckPrecondition(triggerEntity)
	if(not self:IsRepeatable() and self:IsFinishedByEntity(triggerEntity)) then
		-- already finished
		return false;
	end

	if(self.precondition) then
		for _, condition in ipairs(self.precondition) do
			if(condition.name == "quest") then
				if(not self:IsFinishedByEntity(triggerEntity, condition.id)) then
					return false;
				end
			elseif(condition.name == "item") then
				if( not self:VerifyItemByEntity(condition, triggerEntity)) then
					return false;
				end
			end
		end
	end
	return true;
end

-- whether quest is active. i.e. all condition is met, but it does not mean it can be finished. 
-- same as CheckPrecondition
function Quest:IsActive(triggerEntity)
	return self:CheckPrecondition(triggerEntity);
end

-- check if all goals are completed
-- goals are usually server site variables or actions that can not be easily represented by item. 
-- otherwise please use `cost` or `precondition`. 
function Quest:CheckGoals(triggerEntity)
	if(self.goals) then
		-- TODO: support goals. 
	end
	return true;
end

-- items inside `cost` will be removed in return of `reward`. So entity must already 
-- has at least those number of items. 
-- @param choice: default to nil. filter of choices.
function Quest:CheckCost(triggerEntity, choice)
	if(self.cost) then
		for _, items in ipairs(self.cost) do
			if(items.choice == -1 or items.choice == choice) then
				for _, item in ipairs(items) do
					if(item.name == "itemstack") then
						if( not self:VerifyItemByEntity(item, triggerEntity)) then
							return false;
						end
					end
				end
			end
		end
	end
	return true;
end

-- when all goals and cost are met, we can finish the quest. 
-- @return true, if we have collected everything to finish the quest. 
function Quest:CanFinish(triggerEntity)
	return self:CheckPrecondition(triggerEntity) 
		and self:CheckGoals(triggerEntity)
		and self:CheckCost(triggerEntity);
end

-- Execute to finish the quest and write quest log. 
-- it will substract cost items and give reward according to user's choice
-- @param choice: default to nil. user's choice
-- @return true if succeed
function Quest:DoFinish(triggerEntity, choice)
	local bSucceed = true;
	if(self:CanFinish(triggerEntity)) then
		local logs = {format("DoFinish quest `%s`: ", self.id)};
		-- TODO: this should be an transaction, but we just use naive implementation here. 
		if(self.cost) then
			for _, items in ipairs(self.cost) do
				if(items.choice == -1 or items.choice == choice) then
					for _, item in ipairs(items) do
						if(item.name == "itemstack") then
							local result = self:RemoveItemFromEntity(item, triggerEntity);
							logs[#logs+1] = format("-%d,%d:%s;", item.id, item.count or 1, result and "succeed" or "failed");
							bSucceed = result and bSucceed;
						end
					end
				end
			end
		end
		if(self.reward) then
			for _, items in ipairs(self.reward) do
				if(items.choice == -1 or items.choice == choice) then
					for _, item in ipairs(items) do
						if(item.name == "itemstack") then
							local result = self:AddItemToEntity(item, triggerEntity);
							logs[#logs+1] = format("+%d,%d:%s;", item.id, item.count or 1, result and "succeed" or "failed");
							bSucceed = result and bSucceed;
						end
					end
				end
			end
		end
		-- write final log
		local result = self:WriteQuestLogToEntity(triggerEntity);
		logs[#logs+1] = format("+log:%s;", result and "succeed" or "failed");

		-- output log
		bSucceed = result and bSucceed;
		logs[#logs+1] = bSucceed and "all_succeeded" or "some operation failed";
		LOG.std(nil, "info", "Quest", table.concat(logs));
	end
	return self:IsFinishedByEntity(triggerEntity) and bSucceed;
end

-- call this function if self:CheckPrecondition() returns true. 
-- return activate according to the current entity states
function Quest:ShowDialog(triggerEntity)
	
end