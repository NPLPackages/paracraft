--[[
Title: SkySpacePairBlock
Author(s): leio
Date: 2021/1/7
Desc: 
use the lib:
------------------------------------------------------------
local SkySpacePairBlock = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/BlockPositionAllocations/SkySpacePairBlock.lua");
------------------------------------------------------------
--]]

local SkySpacePairBlock = commonlib.inherit(nil, NPL.export());

function SkySpacePairBlock:ctor()
    self.start_x = 19200;
    self.start_y = 250;
    self.start_z = 19200;

    self.max_hight = 20;

    self.stride = 32;
    self.gap = 1;

    self.index = -1;

end
function SkySpacePairBlock:getNextPairPosition()
    
    local index = self.index + 1;
    local plane_size = self.stride * self.stride;
    local hight = math.floor(index / plane_size );

    if(hight > self.max_hight)then
	    LOG.std(nil, "error", "SkySpacePairBlock:getNextPairPosition failed by index:", index);
        return
    end
    -- start index as 0
    local row = math.floor((index - (hight * plane_size)) / self.stride);
    -- start index as 0
    local col = math.mod(index,self.stride);
    

    local next_x = self.start_x + col * (1 + self.gap);
    local next_z = self.start_z + row * (2 + self.gap);
    local next_y = self.start_y + hight  * (1 + self.gap);

    local block_pos_1 = { next_x, next_y, next_z }
    local block_pos_2 = { next_x, next_y, next_z + 1 }

    self.index = index;
    return block_pos_1,block_pos_2;
end