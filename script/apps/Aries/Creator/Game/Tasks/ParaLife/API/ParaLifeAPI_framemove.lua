--[[
Title: Paralife Buildin API for Live models
Author(s): LiXizhi
Date: 2022/6/6
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/API/ParaLifeAPI_framemove.lua");
------------------------------------------------------------
]]
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local API = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.API");

-- randomly walk within GetTagField("maxWalkRadius") at GetTagField("walkSpeed") for GetTagField("walkInterval")
-- if the current position is too far from the walk center, we will resetwalk center. 
function API.RandomWalk(msg)
	local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity) then
		local walkInterval = tonumber(entity:GetTagField("walkInterval") or 5);
		if(walkInterval) then
			-- whether we shall move around 
			local nTime = commonlib.TimerManager.GetCurrentTime();
			if(not entity.random_interval_second) then
				-- random interval
				entity.random_interval_second = math.random(0, walkInterval);
			end
			local LastWalkTime = entity.LastWalkTime or 0;

			if((nTime - LastWalkTime) > 1000 * entity.random_interval_second) then
				local maxWalkRadius = tonumber(entity:GetTagField("maxWalkRadius") or 3)
				local walkSpeed = tonumber(entity:GetTagField("walkSpeed") or 4);

				local cx = tonumber(entity:GetTagField("walkCenterX") or 0)
				local cz = tonumber(entity:GetTagField("walkCenterZ") or 0)

				if(maxWalkRadius and walkSpeed) then
					entity.LastWalkTime = commonlib.TimerManager.GetCurrentTime();
					entity.random_interval_second = nil;
					local bx, by, bz = entity:GetBlockPos()
					if(((cx - bx)^2 + (cz - bz)^2) > (maxWalkRadius+1)^2) then
						-- if the current position is too far from the walk center, we will resetwalk center. 
						cx, cz = bx, bz;
						entity:SetTagField("walkCenterX", cx)
						entity:SetTagField("walkCenterZ", cz)
					end
					local facing = math.random() * math.pi*2;
					local radius = math.random() * maxWalkRadius
					bx = math.floor(cx + math.cos(facing) * radius);
					bz = math.floor(cz + math.sin(facing) * radius);
					entity:SetWalkSpeed(walkSpeed);
					entity:UnLink()
					entity:MoveTo(bx, by, bz);
				end
			end
		end
	end
end

-- follow entity GetTagField("followTarget") at GetTagField("minDist") and GetTagField("maxDist")
-- we will teleport if target is at three times "maxDist"
-- entity will move at the same speed of target
function API.Follow(msg)
	local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity and not entity:IsDragging()) then
		local followTarget = entity:GetTagField("followTarget") or "";
		if(followTarget ~= "") then
			local targetEntity = GameLogic.EntityManager.GetEntity(followTarget)
			if(followTarget == "@p" or followTarget == "@a") then
				targetEntity = GameLogic.EntityManager.GetPlayer();
			end
			if(targetEntity) then
				-- whether we shall move around 
				local nTime = commonlib.TimerManager.GetCurrentTime();
				local LastWalkTime = entity.LastWalkTime or 0;
				if((nTime - LastWalkTime) > 1000) then
					entity.LastWalkTime = commonlib.TimerManager.GetCurrentTime();
					local minDist = tonumber(entity:GetTagField("minDist") or 1)
					local maxDist = tonumber(entity:GetTagField("maxDist") or 3)
					local walkSpeed = tonumber(entity:GetTagField("walkSpeed") or 4);
					local bx, by, bz = entity:GetBlockPos()
					local destX, destY, destZ = targetEntity:GetBlockPos()
					local destRealX, destRealY, destRealZ = targetEntity:GetPosition()
					local dist = (destX - bx)^2 + (destZ - bz)^2;
					local tx, ty, tz;
					if(dist == 0) then
						if(minDist > 0) then
							local facing = math.random() * math.pi*2;
							tx = math.floor(destX + math.cos(facing) * minDist);
							tz = math.floor(destZ + math.sin(facing) * minDist);
						end
					else
						dist = math.floor(math.sqrt(dist));
						if(dist >= maxDist * 3) then
							-- we will teleport if target is at three times "maxDist"
							local facing = math.random() * math.pi*2;
							tx = math.floor(destX + math.cos(facing) * minDist);
							tz = math.floor(destZ + math.sin(facing) * minDist);
							local realX, realY, realZ = BlockEngine:real_bottom(tx, destY, tz)
							realY = BlockEngine:GetTerrainHeight(tx, destY+1, tz) or realY;
							entity:SetPosition(realX, realY, realZ)
							tx, tz = nil, nil;
						elseif(dist>maxDist) then
							-- move towards target. 
							tx = bx + math.floor((destX - bx) / dist * (dist - maxDist) + 0.5)
							tz = bz + math.floor((destZ - bz) / dist * (dist - maxDist) + 0.5)
						elseif(dist>=minDist) then
							-- do nothing, maybe turning to target?
						else
							if(minDist > 0) then
								local facing = math.random() * math.pi*2;
								tx = math.floor(bx + math.cos(facing) * minDist);
								tz = math.floor(bz + math.sin(facing) * minDist);
							end
						end
					end
					if(math.abs(by - destY) >= 2) then
						-- tricky: try to teleport vertically if height diff is bigger than 2. 
						local x, y, z = entity:GetPosition()
						local realY = BlockEngine:GetTerrainHeight(bx, destY+1, bz);
						if(realY and math.abs(destRealY - realY) < BlockEngine.blocksize*2) then
							entity:SetPosition(x, realY, z)
						end
					end
					if(tx and tz) then
						entity:SetWalkSpeed(targetEntity:GetWalkSpeed());
						entity:UnLink()
						entity:MoveTo(tx, by, tz);
					end
				end
			end
		end
	end
end