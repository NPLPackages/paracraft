--[[
Title: Edit Code Block Context
Author(s): LiXizhi
Date: 2018/8/23
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/EditCodeBlockContext.lua");
local EditCodeBlockContext = commonlib.gettable("MyCompany.Aries.Game.SceneContext.EditCodeBlockContext");
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/EditContext.lua");
local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local EditCodeBlockContext = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.SceneContext.EditContext"), commonlib.gettable("MyCompany.Aries.Game.SceneContext.EditCodeBlockContext"));

EditCodeBlockContext:Property({"Name", "EditCodeBlockContext"});

function EditCodeBlockContext:ctor()
end

-- virtual function: 
-- try to select this context. 
function EditCodeBlockContext:OnSelect()
	EditCodeBlockContext._super.OnSelect(self);
end

-- virtual function: 
-- return true if we are not in the middle of any operation and fire unselected signal. 
-- or false, if we can not unselect the scene tool context at the moment. 
function EditCodeBlockContext:OnUnselect()
	EditCodeBlockContext._super.OnUnselect(self);
	return true;
end

-- virtual: 
function EditCodeBlockContext:mousePressEvent(event)
	EditCodeBlockContext._super.mousePressEvent(self, event);
	if(event:isAccepted()) then
		return
	end

	local click_data = self:GetClickData();
end

-- virtual: 
function EditCodeBlockContext:mouseMoveEvent(event)
	EditCodeBlockContext._super.mouseMoveEvent(self, event);
	if(event:isAccepted()) then
		return
	end
	local result = self:CheckMousePick();
end


function EditCodeBlockContext:handleLeftClickScene(event, result)
	EditCodeBlockContext._super.handleLeftClickScene(self, event, result);
	local click_data = self:GetClickData();
end

-- virtual: 
function EditCodeBlockContext:mouseReleaseEvent(event)
	EditCodeBlockContext._super.mouseReleaseEvent(self, event);
	if(event:isAccepted()) then
		return
	end
end

function EditCodeBlockContext:HandleGlobalKey(event)
	local dik_key = event.keyname;
	if(dik_key == "DIK_ESCAPE") then
		event:accept();
		GameLogic.AddBBS(nil, "code context");
	end
	return EditCodeBlockContext._super.HandleGlobalKey(self, event);
end