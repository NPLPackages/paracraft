--[[
Title: Block Damage Progress
Author(s): LiXizhi
Date: 2016/3/14
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/BlockDamageProgress.lua");
local BlockDamageProgress = commonlib.gettable("MyCompany.Aries.Game.Common.BlockDamageProgress");
local blockProgress = BlockDamageProgress:new():init(x,y,z);
-------------------------------------------------------
]]

local BlockDamageProgress = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Common.BlockDamageProgress"));

-- damage ranges from 1 to 10. -1 causes the this to be deleted in world simulator.
BlockDamageProgress.progress = 1;

-- time at which the block progress is created. 
BlockDamageProgress.creationTime = 0;

function BlockDamageProgress:ctor()
	self.progress = 1;
end

function BlockDamageProgress:init(x,y,z)
	self.x = x;
    self.y = y;
    self.z = z;
	return self;
end

-- set damage progress. 
-- @param progress: ranges from 1 to 10, -1 for deletion
function BlockDamageProgress:SetProgress(progress)
    if (progress > 10) then
        progress = 10;
    end
    self.progress = progress;
end

function BlockDamageProgress:AddProgress(damage)
	self:SetProgress(self:GetProgress()+damage);
end

-- @return: ranges from 1 to 10, -1 for deletion
function BlockDamageProgress:GetProgress()
    return self.progress;
end

-- normalize progress to 0,1 range for rendering
function BlockDamageProgress:GetDamagedDegree()
	local progress = self:GetProgress();
	if(progress>=10) then
		return 1;
	elseif(progress<=0) then
		return 0;
	else
		return progress/10;
	end
end

function BlockDamageProgress:SetCreationTime(time)
	self.creationTime = time
end

function BlockDamageProgress:GetCreationTime(time)
	return self.creationTime;
end