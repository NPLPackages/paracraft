--[[
Title: quest data
Author(s): chenjinxian
Date: 2020/12/7
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/Quest.lua");
local Quest = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.Quest");
local quest = Quest:new():Init(extendedcost);
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/GraphHelp.lua");
NPL.load("(gl)script/ide/Graph.lua");
NPL.load("(gl)script/apps/Aries/Quest/QuestHelp.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestProvider.lua");
local QuestProvider = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestProvider");
local QuestHelp = commonlib.gettable("MyCompany.Aries.Quest.QuestHelp");
local Graph = commonlib.gettable("commonlib.Graph");
local GraphNode = commonlib.gettable("commonlib.GraphNode");
local GraphArc = commonlib.gettable("commonlib.GraphArc");
local GraphHelp = commonlib.gettable("commonlib.GraphHelp");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local Quest = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.Quest"));

local questStartId = 40001;
local questEndId = 49999;

function Quest:ctor()
	self.graphData = Graph:new{};
end

function Quest:Init(extendedcost)
	local extendedDatas = {};
	local nodes = {};
	for _, data in ipairs(extendedcost) do
		if (data.exId >= questStartId and data.exId <= questEndId) then
			extendedDatas[#extendedDatas + 1] = data;
			local name = data.name;
			local desc = data.desc;
			local exId = data.exId;
			local gsId = QuestProvider:GetInstance():SearchQuestGsidFromExid(exId);
			local node = self.graphData:AddNode();
			node.data = {name = name, desc = desc, exid = exId, gsId = gsId, templateData = {Id = exId, Title = string.format("%s（%d）", name, gsId)}};
			nodes[data.exId] = node;
		end
	end

	local arcs = {};
	function getArc(gsId, nodeId, targetId)
		if (not gsId) then
			return
		end
		for _, data in ipairs(extendedDatas) do
			if (data.exchangeTargets and #data.exchangeTargets > 0) then
				local hasArc = false;
				for _, target in ipairs(data.exchangeTargets) do
					for _, good in ipairs(target.goods) do
						if (good.goods.gsId == gsId) then
							local state = "invalid";
							if (KeepWorkItemManager.HasGSItem(gsId)) then
								state = "valid";
							end
							if (KeepWorkItemManager.HasGSItem(targetId)) then
								state = "finished";
							end
							arcs[#arcs + 1] = {preNodeId = nodeId, targetId = data.exId, tag = {condition = "and", state = state}};
							hasArc = true;
							break;
						end
					end
					if (hasArc) then break end
				end
			end
		end
	end
	for _, data in ipairs(extendedDatas) do
		if (data.preconditions and #data.preconditions > 0) then
			for _, condition in ipairs(data.preconditions) do
				if(condition.goods) then
					local bagNo = KeepWorkItemManager.SearchBagNo(condition.goods.bagId);
					if (QuestProvider:GetInstance():IsValidBag(bagNo)) then
						getArc(condition.goods.gsId, data.exId, targetId);
					end
				end
			end
		end
	end

	for _, arc in ipairs(arcs) do
		if (arc.preNodeId and arc.targetId) then
			self.graphData:AddArc(nodes[arc.preNodeId], nodes[arc.targetId], arc.tag);
		end
	end

	return self;
end

function Quest:GetQuestNodes()
	local questNodes = {};
	GraphHelp.Search_DepthFirst_FromRoot(self.graphData, function(node)
		if (node) then
			local data = node:GetData();
			if (data and data.exid and data.gsId) then
				local isValid = true;
				if (KeepWorkItemManager.HasGSItem(data.gsId)) then
					isValid = false;
				end
				local arc;
				for arc in node:NextArc() do
					local preNode = arc:GetNode();
					local preData = preNode:GetData();
					local bOwn = KeepWorkItemManager.HasGSItem(preData.gsId);
					if (not bOwn) then
						isValid = false;
						break;
					end
				end
				if (isValid) then
					questNodes[#questNodes + 1] = {exid = data.exid, gsId = data.gsId, name = data.name, desc = data.desc};
				end
			end
		end
	end);
	return questNodes;
end

function Quest:SaveQuestToDgml(filepath)
	QuestHelp.SaveToDgml(self.graphData, filepath);
end
