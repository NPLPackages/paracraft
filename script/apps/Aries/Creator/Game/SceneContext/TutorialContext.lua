--[[
Title: Tutorial Context
Author(s): LiXizhi
Date: 2015/12/17
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/TutorialContext.lua");
local TutorialContext = commonlib.gettable("MyCompany.Aries.Game.SceneContext.TutorialContext");
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/EditContext.lua");
local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TutorialContext = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.SceneContext.EditContext"), commonlib.gettable("MyCompany.Aries.Game.SceneContext.TutorialContext"));

TutorialContext:Property({"Name", "TutorialContext"});
TutorialContext:Property("HelperBlockId", 155);
-- following property is used by GameMode 
TutorialContext:Property({"ModeHasJumpRestriction", true});

function TutorialContext:ctor()
	-- use the ending block (155) as the maker block
	-- mouse block picking is only valid when there is a marker block below. 
	self:SetEditMarkerBlockId(155);
end

-- virtual function: 
-- try to select this context. 
function TutorialContext:OnSelect()
	TutorialContext._super.OnSelect(self);
end

-- virtual function: 
-- return true if we are not in the middle of any operation and fire unselected signal. 
-- or false, if we can not unselect the scene tool context at the moment. 
function TutorialContext:OnUnselect()
	TutorialContext._super.OnUnselect(self);
	return true;
end

function TutorialContext:OnLeftLongHoldBreakBlock()
	self:TryDestroyBlock(SelectionManager:GetPickingResult());
end


-- virtual: 
function TutorialContext:mousePressEvent(event)
	TutorialContext._super.mousePressEvent(self, event);
	if(event:isAccepted()) then
		return
	end

	local click_data = self:GetClickData();
	
end

-- virtual: 
function TutorialContext:mouseMoveEvent(event)
	TutorialContext._super.mouseMoveEvent(self, event);
	if(event:isAccepted()) then
		return
	end
	local result = self:CheckMousePick();
end

function TutorialContext:handleLeftClickScene(event, result)
	TutorialContext._super.handleLeftClickScene(self, event, result);
	local click_data = self:GetClickData();
end

-- virtual: 
function TutorialContext:mouseReleaseEvent(event)
	TutorialContext._super.mouseReleaseEvent(self, event);
	if(event:isAccepted()) then
		return
	end
end

function TutorialContext:HandleGlobalKey(event)
	local dik_key = event.keyname;
	if(dik_key == "DIK_TAB") then
		-- disable tab and shift tab key in tutorial mode.
		event:accept();
	end
	return TutorialContext._super.HandleGlobalKey(self, event);
end