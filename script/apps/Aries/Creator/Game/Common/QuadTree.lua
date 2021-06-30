--[[
Title: QuadTree
Author(s): wxa, refined and ported lxz
Date: 2020/6/10
Desc: it will split as new objects are added to the tree. And it will only split vertically or horizontally 
if the number of objects on the parent node is larger than splitThreshold (default to 20).
The minimum node size is defined by minWidth and minHeight, which all defaults to 16

use the lib: 
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/QuadTree.lua");
local QuadTree = commonlib.gettable("MyCompany.Aries.Game.Common.QuadTree")
local quadtree = QuadTree:new():Init({minWidth = 16, minHeight = 16, left = 0, top = 0, right = 100, bottom = 100, splitThreshold = 20});
-- object, left, top, right, bottom: where object can be any data type, except nil.
quadtree:AddObject("1", 10, 10, 10, 10);
quadtree:AddObject("2", 60, 10, 60, 10);
quadtree:AddObject("3", 10, 60, 10, 60);
quadtree:AddObject("4", 60, 60, 60, 60);
echo(quadtree:GetObjects(10, 10, 10, 60)); -- {"3", "1"}
quadtree:RemoveObject("1");
echo(quadtree:GetObjects(10, 10, 10, 60)); -- {"3"}
echo(quadtree:GetObjectsByPoint(60, 10)); -- {"2"}
-------------------------------------------------------
]]

local QuadTree = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Common.QuadTree"));
local QuadTreeNode = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), {});

-- when a quad object has less than this number of objects, we will not split.
QuadTree.splitThreshold = 20;

-- The minimum node size
QuadTree.minWidth = 16;
QuadTree.minHeight = 16;

local QuadTreeNodeNid = 0;

-- use the object itself as unique key
local function GetObjectKey(object)
    return object;
end

function QuadTreeNode:ctor()
    self.childNodes = nil;
    self.objects = {};       -- 区间对象集
    self.objectCount = 0;    -- 对象数
end

function QuadTreeNode:Init(left, top, right, bottom)
    self.left, self.top, self.right, self.bottom = left, top, right, bottom;
    return self;
end

function QuadTreeNode:IsSubArea(left, top, right, bottom)
    return not (left < self.left or right > self.right or top < self.top or bottom > self.bottom)
end

function QuadTreeNode:IsPointInSubArea(x, y)
	return not (x < self.left or x > self.right or y < self.top or y > self.bottom)
end

function QuadTreeNode:GetSubArea(left, top, right, bottom)
    left = left < self.left and self.left or left;
    top = top < self.top and self.top or top;
    right = right > self.right and self.right or right;
    bottom = bottom > self.bottom and self.bottom or bottom;
    return left, top, right, bottom, right >= left and bottom >= top;
end

function QuadTreeNode:Split(isSplitWidth, isSplitHeight)
    if (self.childNodes) then return end
    local left, top, right, bottom = self.left, self.top, self.right, self.bottom;
    local width, height = right - left, bottom - top;
    local centerX = left + math.floor(width / 2);
    local centerY = top + math.floor(height / 2);

    self.childNodes = {};
    if (isSplitWidth and isSplitHeight) then
        table.insert(self.childNodes, QuadTreeNode:new():Init(left, top, centerX, centerY));       -- 左上角
        table.insert(self.childNodes, QuadTreeNode:new():Init(centerX, top, right, centerY));      -- 右上角
        table.insert(self.childNodes, QuadTreeNode:new():Init(left, centerY, centerX, bottom));    -- 左下角
        table.insert(self.childNodes, QuadTreeNode:new():Init(centerX, centerY, right, bottom));   -- 右下角
    elseif (isSplitWidth and not isSplitHeight) then
        table.insert(self.childNodes, QuadTreeNode:new():Init(left, top, centerX, bottom));   -- 左区
        table.insert(self.childNodes, QuadTreeNode:new():Init(centerX, top, right, bottom));  -- 右区
    elseif (not isSplitWidth and isSplitHeight) then
        table.insert(self.childNodes, QuadTreeNode:new():Init(left, top, right, centerY));     -- 上区
        table.insert(self.childNodes, QuadTreeNode:new():Init(left, centerY, right, bottom));  -- 下区
    end
end

function QuadTreeNode:GetChildNodes()
    return self.childNodes;
end

function QuadTreeNode:GetObjects()
    return self.objects;
end

function QuadTreeNode:IsSplit()
    return self.childNodes and true or false;
end

function QuadTreeNode:AddObject(object)
    local key = GetObjectKey(object);
    if (self.objects[key] ~= nil) then return end

    self.objectCount = self.objectCount + 1;
    self.objects[key] = object;
end

function QuadTreeNode:RemoveObject(object)
    local key = GetObjectKey(object);
    if (not self.objects[key]) then return end

    self.objectCount = self.objectCount - 1;
    self.objects[key] = nil;
end

function QuadTreeNode:GetObjectCount()
    return self.objectCount;
end

function QuadTreeNode:GetWidthHeight()
    return self.right - self.left, self.bottom - self.top;
end


function QuadTree:ctor()

end

function QuadTree:Init(opts)
    self.objects = {};
    self.objectCount = 0;
    self.minWidth = opts.minWidth or self.minWidth;
    self.minHeight = opts.minHeight or self.minHeight;
    self.splitThreshold = opts.splitThreshold or self.splitThreshold;
    self.root = QuadTreeNode:new():Init(opts.left, opts.top, opts.right, opts.bottom);
    return self;
end

-- add object to quadtree according to its size and position. 
-- @param object: can be everything but nil. 
-- @param fromHeight, toHeight: optional third dimension. so that we can also filter objects as 3D AABB box. 
function QuadTree:AddObject(object, left, top, right, bottom, fromHeight, toHeight)
    local minWidth, minHeight, splitThreshold = self.minWidth, self.minHeight, self.splitThreshold;
    
    -- 添加前先移除旧对象
    self:RemoveObject(object);

    -- 添加新对象
    local function AddObjectToNode(node, object, left, top, right, bottom)
        local key = GetObjectKey(object);
        self.objects[key] = {node = node, left = left, right = right, top = top, bottom = bottom, fromHeight = fromHeight, toHeight = toHeight};
        self.objectCount = self.objectCount + 1;
        node:AddObject(object);
        -- echo({"------------------AddObjectToNode", object, node.left, node.top, node.right, node.bottom, node:GetObjects()});
        return node;
    end

    local function AddObject(node, object, left, top, right, bottom)
        -- echo({"------------------IsSubArea", object, node.left, node.top, node.right, node.bottom, node:IsSubArea(left, top, right, bottom), left, top, right, bottom});

        local width, height = right - left, bottom - top;
        local nodeWidth, nodeHeight = node:GetWidthHeight();
        local childNodeWidth, childNodeHeight = math.floor(nodeWidth / 2), math.floor(nodeHeight / 2);
        local splitThreshold, objectCount = self.splitThreshold, node:GetObjectCount();
        
        -- 不在当前节点区域内 直接返回
        if (not node:IsSubArea(left, top, right, bottom)) then return end

        -- 添加区域大于子区域, 子区域小于最小区域
        if ((childNodeWidth <= width and childNodeHeight <= height) or (childNodeWidth <= minWidth and childNodeHeight <= minHeight)) then
            return AddObjectToNode(node, object, left, top, right, bottom);
        end

        if (not node:IsSplit()) then
            -- 未分割,且节点对象小于阈值直接添加
            if (objectCount < splitThreshold) then
                return AddObjectToNode(node, object, left, top, right, bottom);
            end

            -- 已超过分割阈值 进行分割
            node:Split(childNodeWidth > minWidth, childNodeHeight > minHeight);  -- 子节点宽高大于最小宽高时才执行分割
            -- 分割完, 节点对象需进行重新分配
            local objects = node:GetObjects();
            for key, val in pairs(objects) do
                local ov = self.objects[key];
                node:RemoveObject(val);
                AddObject(node, val, ov.left, ov.top, ov.right, ov.bottom);
            end
        end

        -- 是否分割
        local childNodes = node:GetChildNodes();
        for i = 1, #childNodes do
            local childNode = childNodes[i];
            if (childNode:IsSubArea(left, top, right, bottom)) then
                return AddObject(childNode, object, left, top, right, bottom);
            end
        end

        -- 没有添加到子区域则添加到当前区域
        AddObjectToNode(node, object, left, top, right, bottom);
    end

    return AddObject(self.root, object, left, top, right, bottom);
end

function QuadTree:RemoveObject(object)
    local key = GetObjectKey(object);
    local value = self.objects[key];
    if (not value) then return end
    value.node:RemoveObject(object);
    self.objects[key] = nil;
    self.objectCount = self.objectCount - 1;
end

function QuadTree:GetObjectCount()
    return self.objectCount;
end


-- return nil or array of objects inside the given region
function QuadTree:GetObjects(left, top, right, bottom)
    local list
	local objects = self.objects;
    local function GetObjects(node, left, top, right, bottom)
        left, top, right, bottom, isValidArea = node:GetSubArea(left, top, right, bottom);
        -- 交集区域无效 直接返回
        if (not isValidArea) then return end;

        local nodeObjects = node:GetObjects();   -- 当前节点存的在对象都不在子区域内, 对象占多个子区域, 所以需加入遍历列表
        for key, val in pairs(nodeObjects) do
			local o = objects[key];
			if (o and o.left >= left and o.right <= right and o.top >= top and o.bottom <= bottom) then
				list = list or {};
				list[#list + 1] = val;
			end
        end
        if (not node:IsSplit()) then return end

        -- 已分割查找子区域
        local childNodes = node:GetChildNodes();
        for i = 1, #childNodes do
            GetObjects(childNodes[i], left, top, right, bottom);
        end
    end
    GetObjects(self.root, left, top, right, bottom);
    return list;
end

-- return nil or array of objects containing the given point
function QuadTree:GetObjectsByPoint(x, y)
	local list
	local objects = self.objects;
    local function GetObjectsByPoint(node)
        if(not node:IsPointInSubArea(x, y)) then
			return
		end
        local nodeObjects = node:GetObjects(); 
        for key, val in pairs(nodeObjects) do
			local o = objects[key];
			if (o and o.left <= x and o.right >= x and o.top <= y and o.bottom >= y) then
				list = list or {};
				list[#list + 1] = val;
			end
        end
        if (node:IsSplit()) then 
			local childNodes = node:GetChildNodes();
			for i = 1, #childNodes do
				GetObjectsByPoint(childNodes[i]);
			end
		end
    end
    GetObjectsByPoint(self.root);
    return list;
end

-- return nil or array of objects containing the given point
function QuadTree:GetObjectsBy3DPoint(x, y, z)
	local list
	local objects = self.objects;
    local function GetObjectsBy3DPoint(node)
        if(not node:IsPointInSubArea(x, z)) then
			return
		end
        local nodeObjects = node:GetObjects(); 
        for key, val in pairs(nodeObjects) do
			local o = objects[key];
			if (o and o.left <= x and o.right >= x and o.top <= z and o.bottom >= z and 
				(not o.fromHeight or (o.fromHeight <= y and y <= o.toHeight))) then
				list = list or {};
				list[#list + 1] = val;
			end
        end
        if (node:IsSplit()) then 
			local childNodes = node:GetChildNodes();
			for i = 1, #childNodes do
				GetObjectsBy3DPoint(childNodes[i]);
			end
		end
    end
    GetObjectsBy3DPoint(self.root);
    return list;
end

