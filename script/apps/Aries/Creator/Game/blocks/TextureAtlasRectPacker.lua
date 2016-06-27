--[[
Title: A single image in a texture atlas
Author(s): LiXizhi
Date: 2014/12/9
Desc: Implements different bin packer algorithms
reference: http://clb.demon.fi/projects/even-more-rectangle-bin-packing
Ported by LiXizhi to NPL

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/TextureAtlasRectPacker.lua");
local TextureAtlasRectPacker = commonlib.gettable("MyCompany.Aries.Game.blocks.TextureAtlasRectPacker")
local packer = TextureAtlasRectPacker:new():init(512, 512)
echo(packer:quickInsert(32,32));
echo(packer:quickInsert(511,32));
echo(packer:quickInsert(32,32));
echo(packer:quickInsert(32,32));
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");

---------------------------
-- Rectangle
---------------------------
local Rectangle = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Tools.Rectangle"));

Rectangle.x = 0; 
Rectangle.y = 0;
Rectangle.width = 0;
Rectangle.height = 0;

function Rectangle:ctor()
end

function Rectangle:init(x, y, width, height)
	self.x = x; 
	self.y = y;
	self.width = width;
	self.height = height;
	return self;
end

function Rectangle:clone()
	return Rectangle:new():init(self.x, self.y, self.width, self.height);
end

-- return boolean
function Rectangle:isContainedIn(b)
	return self.x >= b.x and self.y >= b.y and self.x + self.width <= b.x + b.width and self.y + self.height <= b.y + b.height;
end	

---------------------------
-- TextureAtlasRectPacker
---------------------------
local TextureAtlasRectPacker = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.blocks.TextureAtlasRectPacker"));
TextureAtlasRectPacker:Property("Name", "TextureAtlasRectPacker");
TextureAtlasRectPacker:Property("Dirty", false, "IsDirty");
TextureAtlasRectPacker:Property("Width", 512);
TextureAtlasRectPacker:Property("Height", 512);
-- whenever content is changed. 
TextureAtlasRectPacker:Signal("Changed");

function TextureAtlasRectPacker:ctor()
	self.freeRectangles = commonlib.UnorderedArray:new();
end

function TextureAtlasRectPacker:init(width, height)
	self:SetWidth(width);
	self:SetHeight(height);
	self.freeRectangles:add(Rectangle:new():init(0, 0, self:GetWidth(), self:GetHeight()));
	
	return self;
end

-- public slot
function TextureAtlasRectPacker:MakeDirty()
	self:SetDirty(true);
	self:Changed();
end


-- @return Rectangle: return the rectangle inserted. or nil if no more room for the rect. 
function TextureAtlasRectPacker:quickInsert(width, height)
	local newNode = self:quickFindPositionForNewNodeBestAreaFit(width, height);
	if (newNode.height == 0) then
		return nil;
	end
	local freeRectangles = self.freeRectangles;
	local numRectanglesToProcess = freeRectangles:size();
	local i = 1;
	while (i <= numRectanglesToProcess) do
		if (self:splitFreeNode(freeRectangles[i], newNode)) then
			freeRectangles:splice(i, 1);
			numRectanglesToProcess = numRectanglesToProcess - 1;
			i = i - 1;
		end
		i = i + 1;
	end
	self:pruneFreeList();
	self:MakeDirty();
	return newNode;
end

-- add the given rectangle to free list to be reused in future. 
function TextureAtlasRectPacker:FreeRectangle(rect)
	self.freeRectangles:add(rect);
end

-- find the smallest free rectangle
-- @return Rectangle
function TextureAtlasRectPacker:quickFindPositionForNewNodeBestAreaFit(width, height)
	local score = 99999999999;
	local bestNode = Rectangle:new();
	local freeRectangles = self.freeRectangles;

	for i = 1, freeRectangles:size() do
		local r = freeRectangles[i];
		-- Try to place the rectangle in upright (non-flipped) orientation.
		if (r.width >= width and r.height >= height) then
			local areaFit = r.width * r.height - width * height;
			if (areaFit < score) then
				bestNode.x = r.x;
				bestNode.y = r.y;
				bestNode.width = width;
				bestNode.height = height;
				score = areaFit;
			end
		end
	end
	return bestNode;
end

-- split the freeNode, if it intersact with the usedNode. 
-- @param freeNode: rectangle
-- @param usedNode: rectangle
-- @return true if succeed		
function TextureAtlasRectPacker:splitFreeNode(freeNode, usedNode)
	local newNode;
	-- Test with SAT if the rectangles even intersect.
	if (usedNode.x >= freeNode.x + freeNode.width or
		usedNode.x + usedNode.width <= freeNode.x or
		usedNode.y >= freeNode.y + freeNode.height or
		usedNode.y + usedNode.height <= freeNode.y) then
		return false;
	end
	if (usedNode.x < freeNode.x + freeNode.width and usedNode.x + usedNode.width > freeNode.x) then
		-- New node at the top side of the used node.
		if (usedNode.y > freeNode.y and usedNode.y < freeNode.y + freeNode.height) then
			newNode = freeNode:clone();
			newNode.height = usedNode.y - newNode.y;
			self.freeRectangles:add(newNode);
		end
		-- New node at the bottom side of the used node.
		if (usedNode.y + usedNode.height < freeNode.y + freeNode.height) then
			newNode = freeNode:clone();
			newNode.y = usedNode.y + usedNode.height;
			newNode.height = freeNode.y + freeNode.height - (usedNode.y + usedNode.height);
			self.freeRectangles:add(newNode);
		end
	end
	if (usedNode.y < freeNode.y + freeNode.height and usedNode.y + usedNode.height > freeNode.y) then
		-- New node at the left side of the used node.
		if (usedNode.x > freeNode.x and usedNode.x < freeNode.x + freeNode.width) then
			newNode = freeNode:clone();
			newNode.width = usedNode.x - newNode.x;
			self.freeRectangles:add(newNode);
		end
		-- New node at the right side of the used node.
		if (usedNode.x + usedNode.width < freeNode.x + freeNode.width) then
			newNode = freeNode:clone();
			newNode.x = usedNode.x + usedNode.width;
			newNode.width = freeNode.x + freeNode.width - (usedNode.x + usedNode.width);
			self.freeRectangles:add(newNode);
		end
	end
	return true;
end

-- protected: 
function TextureAtlasRectPacker:pruneFreeList()
	--- Go through each pair and remove any rectangle that is redundant.
	local i = 1;
	local j = 1;
	local freeRectangles = self.freeRectangles;
	local len = freeRectangles:size();
	while (i <= len) do
		j = i + 1;
		local tmpRect = freeRectangles[i];
		while (j <= len) do
			local tmpRect2 = freeRectangles[j];
			if (tmpRect:isContainedIn(tmpRect2)) then
				freeRectangles:splice(i, 1);
				i = i - 1;
				len = len - 1;
				break;
			end
			if (tmpRect2:isContainedIn(tmpRect)) then
				freeRectangles:splice(j, 1);
				len = len - 1;
				j = j - 1;
			end
			j = j + 1;
		end
		i = i + 1;
	end
end
	