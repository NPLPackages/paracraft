--[[
Title: a layout is used when positioning an mcml control. It emulate the standard HTML renderer bahaviors. 
it is usually started empty with newline position and preferred container size.
When new object is added, it will try to put in a line; if content on the current line overflows, it will start a new line. 
if a child control is larger than the client size of the layout, the container size of layout will be increased to best contain the child element. 
Author(s): LiXizhi
Date: 2008/2/15
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/mcml_controls_layout.lua");
-- clone child object
parentLayout:NewLine();
local myLayout = parentLayout:clone();
myLayout:SetUsedSize(0,0);

-- update parent
myLayout:NewLine();
local left, top = parentLayout:GetAvailablePos();
local width, height = myLayout:GetUsedSize();
width, height = width-left, height -top;
parentLayout:AddObject(width, height);
parentLayout:NewLine();
	
-- add full size
parentLayout:NewLine();
local left, top, width, height = parentLayout:GetPreferredRect();
parentLayout:AddObject(width-left, height-top);
parentLayout:NewLine();
-------------------------------------------------------
]]

if(not Map3DSystem.mcml_controls) then Map3DSystem.mcml_controls = {} end

local mcml_controls = Map3DSystem.mcml_controls;

---------------------------------------------
-- layout class: 
---------------------------------------------
local layout = {
	-- the next available renderable position 
	availableX = 0,
	availableY = 0,
	-- the next new line position
	newlineX = 0,
	newlineY = 0,
	-- the current preferred size of the container control. It may be enlarged by child controls. 
	width = 0,
	height = 0,
	-- the min region in the container control which is occupied by its child controls
	usedWidth = 0,
	usedHeight = 0,
}
mcml_controls.layout = layout;

function layout:new(o)
	o = o or {};
	setmetatable(o,self);
	self.__index = self;
	return o;
end

-- return a clone of this layout object. 
-- in most cases, one also calls SetUsedSize(0,0) to make the copy useful for a child layout. 
function layout:clone()
	return commonlib.deepcopy(self);
end


-- create a new layout, that is the same size of the preferred size but left, top is 0,0;
function layout:new_child()
	local o = layout:new()
	local width, height = self:GetPreferredSize();
	o:reset(0, 0, width, height);
	return o;
end

-- reset with newline position (left, top) and container size (width and height). 
function layout:reset(left, top, width, height)
	self.newlineX = left;
	self.newlineY = top;
	if(left<width) then
		self.width = width;
	else
		self.width = left;
	end	
	if(top<height) then
		self.height = height;
	else
		self.height = top;
	end	
	self:NewLine();
end

-- a control may call this function to check its preferred size. 
-- if the preferred size is big enough, it can use this size when calling AddObject,
-- otherwise, it can either call NewLine() or AddObject with a bigger size. 
-- return preferred width, height
function layout:GetPreferredSize()
	return self.width-self.availableX, self.height - self.availableY;
end

function layout:GetPreferredRect()
	return self.availableX, self.availableY, self.width, self.height;
end

function layout:GetPreferredPos()
	return self.availableX, self.availableY;
end

function layout:SetPreferredPos(x, y)
	self.availableX, self.availableY = x, y; 
end

-- get the max available size
function layout:GetMaxSize()
	return self.width-self.newlineX, self.height - self.newlineY;
end

-- get the size
function layout:GetSize()
	return self.width, self.height;
end
-- set the size
function layout:SetSize(width, height)
	self.width, self.height = width, height;
end

-- get used size
function layout:GetUsedSize()
	return self.usedWidth, self.usedHeight;
end

-- set used size
function layout:SetUsedSize(width, height)
	self.usedWidth, self.usedHeight = width, height;
end

-- clear the used size to currently available pos. 
function layout:ResetUsedSize()
	self.usedWidth, self.usedHeight = self.availableX, self.availableY;
end

-- get the available rect by left, top, right, bottom. 
function layout:GetAvailableRect()
	return self.availableX, self.availableY, self.width, self.height;
end

-- get the available rect by left, top
function layout:GetAvailablePos()
	return self.availableX, self.availableY;
end

-- get the newline position (left, top)
function layout:GetNewlinePos()
	return self.newlineX, self.newlineY;
end

-- offset the new line and available position of this layout. 
function layout:OffsetPos(dx, dy)
	if(dx) then
		self.newlineX = self.newlineX+dx;
		self.availableX = self.availableX+dx;
	end
	if(dy) then
		self.newlineY = self.newlineY+dy;
		self.availableY = self.availableY+dy;
	end
end
-- Set the new line and available absolute position of this layout. 
function layout:SetPos(x,y)
	if(x) then
		self.newlineX = x;
		self.availableX = x;
	end
	if(y) then
		self.newlineY = y;
		self.availableY = y;
	end
end

-- childLayout is usually cloned from this layout and this layout will expand to accommandate childLayout. 
function layout:AddChildLayout(childLayout)
	local left, top = self:GetAvailablePos();
	local width, height = childLayout:GetUsedSize();
	self:AddObject(width-left, height-top);
end

-- add object at the current available position. if available position is not big enough, it will start a new line. 
-- object still can not fit in a newline, it will increase its container size. 
-- THIS IS A TRICKY FUNCTION
-- return the left, top position of the added object. 
function layout:AddObject(width, height)
	local left, top;
	if((self.availableX+width)>self.width) then
		-- start a new line. 
		self:NewLine();
	end
	left, top = self.availableX, self.availableY;
	self.availableX = left+width;
	if((top+height)>self.newlineY) then
		self.newlineY = top+height
		if(self.newlineY>self.height) then
			-- increase height to best contain the child object
			self.height = self.newlineY;
		end
	end
	if(self.availableX>self.width) then
		-- increase width to best contain the child object
		self.width = self.availableX;
		-- start new line since it used up all horizontal spaces after object is added. 
		self:NewLine(); 
	end
	if(self.usedWidth<(left+width)) then
		self.usedWidth = left+width;
	end	
	if(self.usedHeight<(top+height)) then
		self.usedHeight = top+height;
	end
	return left, top;
end

-- make a new line in the layout
function layout:NewLine()
	self.availableX = self.newlineX
	self.availableY = self.newlineY
	--log("newline:"..self.newlineX.." "..self.newlineY.."\n")
end

-- increase preferred height of this layout
function layout:IncHeight(dHeight)
	self.height = self.height + dHeight;
end

-- increase preferred width of this layout
function layout:IncWidth(dWidth)
	self.width = self.width + dWidth;
end