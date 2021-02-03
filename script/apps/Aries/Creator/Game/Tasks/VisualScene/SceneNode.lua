--[[
Title: SceneNode 
Author(s): leio
Date: 2021/1/7
Desc: 
use the lib:
------------------------------------------------------------
local SceneNode = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/SceneNode.lua");
------------------------------------------------------------
--]]
local VisualSceneLogic = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/VisualSceneLogic.lua");
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
local SceneNode = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());
SceneNode:Property({"Uid", "", auto = true,  camelCase = true, });
SceneNode:Property({"Name", "", auto = true,  camelCase = true, });
SceneNode:Property({"IsRoot", false, auto = true,  camelCase = true, });
SceneNode:Property({"Scene", auto = true, type = "Scene", camelCase = true, });
SceneNode:Property({"Parent", auto = true, type = "SceneNode", camelCase = true, });

function SceneNode:ctor()
    self.components = {};
    self.Uid = ParaGlobal.GenerateUniqueID();
    self.Nodes = {};
    self.index = 0;
    self.Level = 0;
end
-- get first component by name
function SceneNode:getComponentByName(name)
    if(not name)then
        return
    end
    for k, v in ipairs(self.components) do
        if(v.Name == name)then
            return v;
        end
    end
end
function SceneNode:addComponent(component, index)
    if(not component)then
        return
    end
    if(type(component) == "string")then
        component = VisualSceneLogic.getComponent(component);
        if(not component)then
            return
        end
        component = component:new();
    end
    if(not component.Uid or component.Uid == "")then
        component.Uid = ParaGlobal.GenerateUniqueID();
    end
    component.Root = self;

    if(component.onAddedToNode)then
        component:onAddedToNode(self);
    end
    if(self.Scene)then
        if(component.onAddedToScene)then
            component:onAddedToScene(self.Scene);
        end
    end

    if(index == nil)then
        table.insert(self.components, component);
    else
        table.insert(self.components, index, component);
    end
    return component;
end
function SceneNode:removeComponent(component)
  if(not component)then
        return
    end
    if(type(component) == "string")then
        component = VisualSceneLogic.getComponent(component);
        if(not component)then
            return
        end
    end
    if(component.onRemovedFromNode)then
        component:onRemovedFromNode(self);
    end
    if(self.Scene)then
        if(component.onRemovedFromScene)then
            component:onRemovedFromScene(self.Scene);
        end
    end
    for k,v in ipairs(self.components) do
        if(v == component)then
            table.remove(self.components,k);
            break;
        end
    end
end
-- Get child count
function SceneNode:getChildCount()
	return table.getn(self.Nodes);
end
-- get child by index. index is 1 based. 
function SceneNode:getChild(index)
	return self.Nodes[index];
end

-- Clear all child nodes
function SceneNode:clearAllChildren()
	self.Nodes = {}
end
-- Add a new child node, the child node is returned
-- @param o: it can be a tree node object 
-- @param index: nil or index at which to insert the object. if nil, it will inserted to the last element. if 1, it will inserted to the first element.
function SceneNode:addChild(o, index)
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
function SceneNode:removeChildByIndex(index)
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
function SceneNode:removeChildByName(name)
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
function SceneNode:detach()
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
function SceneNode:getChildByName(name)
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
function SceneNode:toJson()
    local object = {};
    object.Uid = self.Uid;
    object.Name = self.Name;
    object.IsRoot = self.IsRoot;

    -- components 
    object.components = {};
    for k,v in ipairs(self.components) do
        table.insert(object.components,v:toJson());
    end
    -- Nodes
    object.Nodes = {};
    for k,v in ipairs(self.Nodes) do
        table.insert(object.Nodes,v:toJson());
    end
    return object;
end

function SceneNode:run()
    -- for creating entity
    self:runNode(self,"reload");
    self:runNode(self,"run");
end
function SceneNode:stop()
    self:runNode(self,"stop");
end
function SceneNode:reload()
    self:runNode(self,"reload");
end
function SceneNode:runNode(parent, action)
    if(not parent)then
        return 
    end
    if(parent.components)then
        for kk,vv in ipairs(parent.components) do
            if(vv[action])then
                vv[action](vv);
            end
        end
    end
    local len = parent:getChildCount();
    for k = 1, len do
        local child = parent:getChild(k);
        self:runNode(child,action);
    end
end
