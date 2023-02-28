--[[
Title: Paralife Buildin API for Live models
Author(s): LiXizhi
Date: 2022/3/30
Desc: please note, functions maybe called when the last one has not finished, please safe-guard this by code. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/API/ParaLifeAPI_clickable.lua");
------------------------------------------------------------
]]
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local API = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.API");

-- let camera look at (teleport to) the given player 
function API.LookAt(msg)
	local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity) then
		local x, y, z = entity:GetPosition()
		local player = GameLogic.EntityManager.GetPlayer()
		if(player) then
			player:SetPosition(x, y, z)
		end
	end
end

-- open toggle model: "xxxopen.bmax", "xxx.bmax"
function API.ToggleOpen(msg)
	local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity) then
        local filename = entity:GetModelFile()
        if(filename:match("open")) then
            filename = filename:gsub("open", "")
            entity:SetModelFile(filename)
        else
            filename = filename:gsub("(%.%w+)$", "open%1")
            entity:SetModelFile(filename)
        end
    end
end

-- toggle animation between 0 and GetTagField("anim")
function API.ToggleAnim(msg)
	local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity) then
        if(entity:GetCurrentAnimId() == 0) then
			local anim = tonumber(entity:GetTagField("anim") or 70)
            entity:SetAnimation(anim)
        else
            entity:SetAnimation(0)
        end
    end   
end

-- push/pull model out by GetTagField("length") or 1 meter
function API.PushPull(msg)
	local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity and not entity.isMoving_) then
		entity.isMoving_ = true;
        local facing = entity:GetFacing()
        local dirX, dirZ = math.cos(facing), -math.sin(facing);
        if(entity.tag == "open") then
            dirX, dirZ = -dirX, -dirZ;
            entity.tag = "close"
        else
            entity.tag = "open"
        end
        local x, y, z =  entity:GetPosition()
		local length = tonumber(entity:GetTagField("length") or 1)
        for i= 0, length, 0.1 do
            entity:SetPosition(x+dirX*i, y, z+dirZ*i)
            wait(0.01)
        end
		entity.isMoving_ = nil;
    end
end

-- Lift/Drop model by GetTagField("length") or 1 meter
function API.LiftDrop(msg)
	local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity and not entity.isMoving_) then
		entity.isMoving_ = true;
        local facing = entity:GetFacing()
        local x, y, z =  entity:GetPosition()
		local dir = 1;
        if(entity.tag == "open") then
			dir = -1;
            entity.tag = "close"
        else
            entity.tag = "open"
        end
		local length = tonumber(entity:GetTagField("length") or 1)
		local delta = length > 0 and 0.1 or -0.1;
		
        for i= 0, length, delta do
            entity:SetPosition(x, y + i*dir, z)
            wait(0.01)
        end
		entity.isMoving_ = nil;
    end
end
-- turn model GetTagField("angle") or 130 around axis GetTagField("axis") or "y"
function API.Door(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity and not entity.isMoving_) then
		entity.isMoving_ = true;
		local axis = entity:GetTagField("axis") or "y";

        local fromAngle = 0;
		if(axis == "x") then
			fromAngle = entity:GetPitch()
		elseif(axis == "z") then
			fromAngle = entity:GetRoll()
		else
			fromAngle = entity:GetFacing()
		end

        local dir = 1;
        if(entity.tag == "open") then
            entity.tag = "close"
            dir = -1;
        else
            entity.tag = "open"
        end

		local angle = tonumber(entity:GetTagField("angle") or 130)
		local axis = entity:GetTagField("axis") or "y";
        local deltaAngle = angle > 0 and 10 or -10
        for i = 0, angle, deltaAngle do
			if(axis == "x") then
				entity:SetPitch(fromAngle + dir*i /180*math.pi)
			elseif(axis == "z") then
				entity:SetRoll(fromAngle + dir*i /180*math.pi)
			else
				entity:SetFacing(fromAngle + dir*i /180*math.pi)
			end
            wait(0.01)
        end 
		entity.isMoving_ = nil;
    end
end

function API.ClickLight(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity) then
		local bx, by, bz = entity:GetBlockPos()
        local id = getBlock(bx, by, bz)
        local lightblockId = 270 -- invisible light block 
        if(entity.tag == "on") then
            entity.tag = nil
            if(id == lightblockId) then
                setBlock(bx, by, bz, 0)
            end
        else
            if(not id or id == 0 or id == lightblockId) then
                entity.tag = "on"
                setBlock(bx, by, bz, lightblockId)
            end
        end
    end
end

-- toggle playing music files in GetTagField("sound")
function API.ToggleMusic(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity) then
        local filename = entity:GetTagField("sound")
		if(filename) then
			if(entity.curMusic_ == filename) then
				filename = nil;
			end
			entity.curMusic_ = filename;
			playMusic(filename)
		end
    end
end

function API.ClickGiftBox(msg)
    msg = commonlib.LoadTableFromString(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity and entity.tag == "hasGift") then
        local x, y, z = entity:GetPosition()
        local mountedEntity = entity:GetMountedEntityAt(1)
        if(mountedEntity) then
            mountedEntity:SetPosition(x, y, z)
            local scale = mountedEntity:GetScaling() * 10
            mountedEntity:SetScaling(scale)
            mountedEntity:SetCanDrag(true)
        end
        entity:Destroy()
    end
end

function API.Flip(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity) then
        local pitch = entity:GetPitch()
        if(pitch == 0) then
            local aabb = entity:GetInnerObjectAABB()
            local dx, dy, dz = aabb:GetExtendValues();
            entity:SetPitch(math.pi)
            entity:SetBootHeight(dy*2)
        else
            entity:SetPitch(0)
            entity:SetBootHeight(0)
        end
    end
end

-- turn facing by GetTagField("angle") or 90
function API.Turn(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity) then
        local facing = entity:GetFacing()
		local angle = tonumber(entity:GetTagField("angle") or 90)
        entity:SetFacing(facing + angle * math.pi / 180);
    end
end

local directions = { {-1, 0}, {1, 0}, {0, 1}, {0, -1}, {-1, -1}, {1, 1}, {1, -1}, {-1, 1} }
-- return dx, dz: if not nil, we have found a new location (prefer block without entities)
local function GetRandomNearbyBlockOfType(bx, by, bz, blockId)
    local count = #directions;
    local i = math.random(1, count)
    local dx1, dz1;
    for _ = 1, count do
        i = (i % count) + 1
        local dx, dz = directions[i][1], directions[i][2]
        if(BlockEngine:GetBlockId(bx+dx, by, bz+dz) == blockId) then
            dx1, dz1 = dx, dz
            local entities = GameLogic.EntityManager.GetEntitiesInBlock(bx+dx, by, bz+dz)
            if(not entities or not next(entities)) then
                break;
            end
        end
    end
    return dx1, dz1
end


-- randomly walk to another block with the same block type in random directions. 
function API.RandomWalkToSameBlockType(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity and not entity.isMoving_) then
        entity.isMoving_ = true;
        -- local walkDistance = tonumber(entity:GetTagField("walkDistance") or 1)
        local x, y, z = entity:GetPosition()
        local bx, by, bz = entity:GetBlockPos()
        local lastBlockId = getBlock(bx, by, bz)
        local dx, dz = GetRandomNearbyBlockOfType(bx, by, bz, lastBlockId)
        if(dx and dz) then
            local newX, newY, newZ = GameLogic.BlockEngine:real(bx+dx, by, bz+dz)
            for i = 0, 1, 0.02 do
                local x1 = newX * i + x * (1 - i);
                local z1 = newZ * i + z * (1 - i);
                entity:SetPosition(x1, y, z1)
                wait(0.01)
            end
        end
        entity.isMoving_ = nil;
    end
end

-- GetTagField("inWaterDepth")
function API.FloatToWaterSurface(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity) then
        local x, y, z = entity:GetPosition()
        local bx, by, bz = entity:GetBlockPos()
        local y1 = by;
        while(true) do
            local blockId = getBlock(bx, y1, bz)
            local blockId2 = getBlock(bx, y1+1, bz)
            if(blockId == 76 and blockId2 == 0) then
                y1 = y1 + 1;
                break;
            elseif(blockId2 == 76) then
                y1 = y1 + 1;
            else
                y1 = nil
                break
            end
        end
        if(y1) then
            local inWaterDepth = tonumber(entity:GetTagField("inWaterDepth") or 0.4);
            local destY = GameLogic.BlockEngine:realY(y1)-0.2-inWaterDepth
            entity:SetPosition(x, destY, z);
            
            -- swing back and forth
            local maxAngle = 15;
            for i=0, math.pi*4, 0.1 do
                maxAngle = maxAngle * 0.98
                angle = math.sin(i) * maxAngle /180 * math.pi
                entity:SetRoll(angle)
                wait(0.01)
            end
            entity:SetRoll(0)
        end
    end
end
