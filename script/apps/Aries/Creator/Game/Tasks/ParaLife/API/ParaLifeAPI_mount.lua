--[[
Title: Paralife Buildin API for Live models
Author(s): LiXizhi
Date: 2022/3/30
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/API/ParaLifeAPI_mount.lua");
local Mount = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.API.Mount")
------------------------------------------------------------
]]
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local API = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.API");

function API.DragEndSameTag(msg)
	local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity) then
		if(msg.targetName) then
			local targetEntity = GameLogic.EntityManager.GetEntity(msg.targetName)
			if(targetEntity) then
				if((targetEntity.tag or "") ~= (entity.tag or "")) then
					entity:RestoreDragLocation();
					local errorTip = entity:GetTagField("dragSameTagTip")
					if errorTip ~= nil and errorTip ~= "" then
						entity:Say(errorTip,3)
					end
					-- prevent further processing
					return true;
				end
			end
		end
	end
end

function API.DragEndOnlyOne(msg)
	local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity) then
		if(msg.targetName) then
			local targetEntity = GameLogic.EntityManager.GetEntity(msg.targetName)
			if(targetEntity) then
				if(targetEntity:GetLinkChildCount() > (targetEntity:HasLinkChild(entity) and 1 or 0) ) then
					entity:RestoreDragLocation();
					local errorTip = entity:GetTagField("dragOnlyOneTip")
					if errorTip ~= nil and errorTip ~= "" then
						entity:Say(errorTip,3)
					end
					-- prevent further processing
					return true;
				end
			end
		end
	end
end

function API.MountSameTag(msg)
	local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity) then
		if(msg.mountedEntityName) then
			local mountedEntity = GameLogic.EntityManager.GetEntity(msg.mountedEntityName)
			if(mountedEntity) then
				if((mountedEntity.tag or "") ~= (entity.tag or "")) then
					mountedEntity:RestoreDragLocation();
					local errorTip = entity:GetTagField("mountSameTip")
					if errorTip ~= nil and errorTip ~= "" then
						entity:Say(errorTip,3)
					end
					-- prevent further processing
					return true;
				end
			end
		end
	end
end

function API.MountOnlyOne(msg)
	local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity) then
		if(msg.mountedEntityName) then
			local mountedEntity = GameLogic.EntityManager.GetEntity(msg.mountedEntityName)
			if(mountedEntity) then
				if(entity:GetLinkChildCount() > (entity:HasLinkChild(mountedEntity) and 1 or 0) ) then
					mountedEntity:RestoreDragLocation();
					local errorTip = entity:GetTagField("mountOnlyOneTip")
					if errorTip ~= nil and errorTip ~= "" then
						entity:Say(errorTip,3)
					end
					-- prevent further processing
					return true;
				end
			end
		end
	end
end

function API.MountSit(msg)
	if(msg.mountedEntityName) then
		local mountedEntity = GameLogic.EntityManager.GetEntity(msg.mountedEntityName)
		if(mountedEntity) then
			if(mountedEntity:HasCustomGeosets()) then
				mountedEntity:SetAnimation(235); -- sit looking front 
			else
				mountedEntity:SetAnimation(72); -- sit on ground
			end
		end
	end
end

-- mount on trash can
function API.MountDelete(msg)
    msg = commonlib.LoadTableFromString(msg)
    local mountedEntity = GameLogic.EntityManager.GetEntity(msg.mountedEntityName)
    if(mountedEntity) then
		mountedEntity:ForEachChildLinkEntity(function (entity)
			entity:Destroy()
		end)
        mountedEntity:Destroy()
    end
end

--mount on restore rotaion
function API.MountRestoreRotation(msg)
	msg = commonlib.totable(msg)
    local mountEntity = GameLogic.EntityManager.GetEntity(msg.mountedEntityName)
    if(mountEntity) then
        mountEntity:SetPitch(0)
        mountEntity:SetRoll(0)
        mountEntity:SetFacing(0)
    end
end

-- mount on to pack entity to gift
function API.MountPackToGift(msg)
	msg = commonlib.LoadTableFromString(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity) then
		if entity:HasMountPoints() then
			if(msg.mountname == "1") then
				local mountedEntity = GameLogic.EntityManager.GetEntity(msg.mountedEntityName)
				if(mountedEntity and mountedEntity.tag~="hasGift") then
					local boxes = {"character/v5/06quest/GiftBox/GiftBox_Pink.x","character/v5/06quest/GiftBox/GiftBox_Blue.x","character/v5/06quest/GiftBox/GiftBox_Orange.x"}
					local modefile = boxes[math.random(1,#boxes)]
					local box = mountedEntity:CloneMe()
					box:SetScaling(0.5)
					box:SetModelFile(modefile)
					box:SetOnClickEvent("API.ClickGiftBox")
					box:SetOnBeginDragEvent(nil)
					box:SetOnEndDragEvent(nil)
					box:SetOnHoverEvent(nil)
					box:SetOnMountEvent(nil)
					box.tag = "hasGift"
					box:CreateGetMountPoints():Clear()
					local mps = box:GetMountPoints()
					mps:AddMountPoint()
					local mp = mps:GetMountPoint(1)
					if mp then
						local aabb = box:GetCollisionAABB()
						local maxExtent = aabb:GetMaxExtent() * 3 or 2
						mp:SetAABBSize(maxExtent, maxExtent, maxExtent)
					end
					local x, y, z = mountedEntity:GetPosition();
					box:SetPosition(x, y, z);
					mountedEntity:SetScaling(mountedEntity:GetScaling()*0.1)
					mountedEntity:MountTo(box)
					mountedEntity:SetCanDrag(false)
				end
			end
		end
    end
end