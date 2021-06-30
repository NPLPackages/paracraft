--[[
Title: Box Trigger
Author(s): LiXizhi
Date: 2021/6/4
Desc: When player entity enters or leaves the triggering quad area, it will fire 
signal enterTrigger(entity) and leaveTrigger(entity).
In a single physics frame move, there can be only one enter or leave event for a given colliding entity. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Physics/BoxTrigger.lua");
local BoxTrigger = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld.BoxTrigger")
local trigger = BoxTrigger:new():Init(19158,19206, 19160, 19210)
trigger:Attach();
trigger:Connect("enterTrigger", function(entity)  GameLogic.AddBBS(nil, "player entered", 2000) end)
trigger:Connect("leaveTrigger", function(entity)  GameLogic.AddBBS(nil, "player left", 2000) end)
-------------------------------------------------------
]]
local BoxTriggerEntity = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld.BoxTriggerEntity");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");

local BoxTrigger = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld.BoxTrigger"));

BoxTrigger:Signal("enterTrigger", function(playerEntity) end);
BoxTrigger:Signal("leaveTrigger", function(playerEntity) end);

function BoxTrigger:ctor()
	
end

function BoxTrigger:Init(left, top, right, bottom, fromHeight, toHeight)
	self.left = left;
	self.top = top;
	self.right = right;
	self.bottom = bottom;
	if(fromHeight) then
		self.fromHeight, self.toHeight = fromHeight, toHeight;
	end
	return self;
end

function BoxTrigger:Attach()
	self.isEnabled = true;
	PhysicsWorld:AddStaticTrigger(self)
end


function BoxTrigger:GetQuadSize()
	return self.left, self.top, self.right, self.bottom
end

function BoxTrigger:GetHeightMinMax()
	return self.fromHeight, self.toHeight
end

function BoxTrigger:Destroy()
	self.isEnabled = nil;
	PhysicsWorld:RemoveStaticTrigger(self);
end

function BoxTrigger:IsEnabled()
	return self.isEnabled;
end

-- we can call this function multiple times with the same triggering entity, mostly the main player. 
function BoxTrigger:AddTriggeringEntity(entity)
	if(entity) then
		
	end
end

-- in 3d world coordinates of (minX, 0, minY)
function BoxTrigger:GetLeftTopWorldPos()
	local x, y, z = BlockEngine:real_min(self.left, 0, self.top)
	return x, z
end

function BoxTrigger:GetRightBottomWorldPos()
	local x, y, z = BlockEngine:real_min(self.right+1, 0, self.bottom+1)
	return x, z
end

-- in 3d world coordinates of (minX, 0, minY)
function BoxTrigger:GetPosition()
	if(self.x) then
		return self.x, self.y, self.z
	else
		return BlockEngine:real_min(self.left, 0, self.top)
	end
end

-- set the center block position
function BoxTrigger:SetBlockPos(x, y, z)
	self.bx, self.by, self.bz = x, y, z;
	self.x, self.y, self.z = BlockEngine:real(self.bx, self.by, self.bz)
end

-- TODO: 
function BoxTrigger:Render(painter)
	
end


