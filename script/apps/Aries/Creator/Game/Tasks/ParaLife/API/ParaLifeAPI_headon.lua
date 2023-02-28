--[[
Title: Paralife Buildin API for Live models
Author(s): LiXizhi
Date: 2022/3/30
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/API/ParaLifeAPI_headon.lua");
------------------------------------------------------------
]]
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local API = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.API");

-- show GetTagField("headon"), GetTagField("duration"), GetTagField("isAbove3D")
function API.ShowHeadon(msg)
	local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity) then
		local headon = entity:GetTagField("headon")
		if(headon) then
			local duration = tonumber(entity:GetTagField("duration") or 4)
			local isAbove3D = entity:GetTagField("isAbove3D")
			isAbove3D = (isAbove3D and (isAbove3D == "true" or isAbove3D == true));
			entity:Say(tostring(headon), duration, isAbove3D)
		end
    end
end

function API.HideHeadon(msg)
	local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity) then
        entity:Say()
    end
end

function API.ShowTag(msg)
	local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity and entity.tag) then
        entity:Say(entity.tag, 4)
    end
end


function API.ShowStaticTag(msg)
	API.ShowHeadon(msg)
end

function API.HideTag(msg)
	API.HideHeadon(msg)
end
