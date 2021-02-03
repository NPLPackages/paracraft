--[[
Title: NplModNode
Author(s): leio
Date: 2021/1/7
Desc: tree node for mod dependency
use the lib:
------------------------------------------------------------
local NplModNode = NPL.load("(gl)script/apps/Aries/Creator/Game/NplMod/NplModNode.lua");
------------------------------------------------------------
--]]
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
local NplModNode = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());
NplModNode:Property({"Uid", "", auto = true,  camelCase = true, });
NplModNode:Property({"Name", "", auto = true,  camelCase = true, });
NplModNode:Property({"IsRoot", false, auto = true,  camelCase = true, });
NplModNode:Property({"Parent", auto = true, type = "NplModNode", camelCase = true, });
NplModNode:Property({"NplmConfig", auto = true, type = "NplmConfig", camelCase = true, });

function NplModNode:ctor()
    self.Uid = ParaGlobal.GenerateUniqueID();
    self.Nodes = {};
    self.index = 0;
    self.Level = 0;
end
-- Get child count
function NplModNode:getChildCount()
	return table.getn(self.Nodes);
end
-- get child by index. index is 1 based. 
function NplModNode:getChild(index)
	return self.Nodes[index];
end

-- Clear all child nodes
function NplModNode:clearAllChildren()
	self.Nodes = {}
end
-- Add a new child node, the child node is returned
-- @param o: it can be a tree node object 
-- @param index: nil or index at which to insert the object. if nil, it will inserted to the last element. if 1, it will inserted to the first element.
function NplModNode:addChild(o, index)
	if(type(o) == "table") then
		local nodes = self.Nodes;
		local nSize = table.getn(nodes);
		if(index == nil or index>nSize or index<=0) then
			-- add to the end
			nodes[nSize+1] = o;
			o.index = nSize+1;
		else
			-- insert to the mid
			local i=nSize+1;
			while (i>index) do 
				nodes[i] = nodes[i-1];
				nodes[i].index = i;
				i = i - 1;
			end
			nodes[index] = o;
			o.index = index;
		end	
		-- for Parent
		o.Parent = self;
		o.Scene = self.Scene;
		o.Level = self.Level+1;
		--log(o.index.." added as "..tostring(o.Text).."\n")
		return o;
	end	
end

-- added by Andy 2008/12/21
-- remove all occurance of first level child node whose index is index
function NplModNode:removeChildByIndex(index)
	local nodes = self.Nodes;
	local nSize = table.getn(nodes);
	local i, node;
	
	if(nSize == 1) then
		nodes[1] = nil;
		return;
	end
	
	if(index < nSize) then
		local k;
		for k = index + 1, nSize do
			node = nodes[k];
			nodes[k-1] = node;
			if(node ~= nil) then
				node.index = k - 1;
				nodes[k] = nil;
			end	
		end
	else
		nodes[index] = nil;
	end	
end

-- remove all occurance of first level child node whose name is name
function NplModNode:removeChildByName(name)
	local nodes = self.Nodes;
	local nSize = table.getn(nodes);
	local i, node;
	
	if(nSize == 1) then
		nodes[1] = nil;
		return;
	end
	
	for i=1, nSize do
		node = nodes[i];
		if(node~=nil and name == node.Name) then
			if(i<nSize) then
				local k;
				for k=i+1, nSize do
					node = nodes[k];
					nodes[k-1] = node;
					if(node~=nil) then
						node.index = k-1;
						nodes[k] = nil;
					end	
				end
			else
				nodes[i] = nil;
			end	
		end
	end
end

-- detach this node from its Parent node. 
function NplModNode:detach()
	local parentNode = self.Parent
	if(parentNode == nil) then
		return
	end
	
	local nSize = table.getn(parentNode.Nodes);
	local i, node;
	
	if(nSize == 1) then
		parentNode.Nodes[1] = nil;
		return;
	end
	
	local i = self.index;
	local node;
	if(i<nSize) then
		local k;
		for k=i+1, nSize do
			node = parentNode.Nodes[k];
			parentNode.Nodes[k-1] = node;
			if(node~=nil) then
				node.index = k-1;
				parentNode.Nodes[k] = nil;
			end	
		end
	else
		parentNode.Nodes[i] = nil;
	end	
end

-- get the first occurance of first level child node whose name is name
function NplModNode:getChildByName(name)
	local nodes = self.Nodes;
	local nSize = table.getn(nodes);
	local i, node;
	for i=1, nSize do
		node = nodes[i];
		if(node~=nil and name == node.Name) then
			return node;
		end
	end
end
