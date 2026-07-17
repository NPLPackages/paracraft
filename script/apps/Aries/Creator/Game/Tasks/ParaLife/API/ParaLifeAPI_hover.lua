--[[
Title: Paralife Buildin API for Live models
Author(s): wangyanxiang
Date: 2022/4/7
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/API/ParaLifeAPI_hover.lua");
------------------------------------------------------------
]]
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local API = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.API");

function API.HoverToPieces(msg)
	local entity = GameLogic.EntityManager.GetEntity(msg.hoverEntityName)
    if(entity) then
		entity:CreateBlockPieces()
	end
end

-- restore position if drag distance is greater than GetTagField("maxDragDist") or 3
function API.dragEndMaxDist(msg)
    msg = commonlib.LoadTableFromString(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity) then
        if(entity.restoreDragParams) then
            local old_x, old_y, old_z = unpack(entity.restoreDragParams.pos);
            local x, y, z = entity:GetPosition()
            local dist = math.sqrt((x-old_x)^2 + (y-old_y)^2 + (z-old_z)^2)
            local maxDragDist = tonumber(entity:GetTagField("maxDragDist") or 3);
            if(dist > maxDragDist) then
                entity:RestoreDragLocation()
            end
        end
    end
end

function API.DragEndToResetModel(msg)
    msg = commonlib.totable(msg);
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity) then
        entity:ResetModelLocalTransform()
    end
end