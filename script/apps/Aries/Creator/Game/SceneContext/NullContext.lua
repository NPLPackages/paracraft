--[[
Title: Null Context
Author(s): LiXizhi
Date: 2020/3/30
Desc: A context that blocks everything
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/NullContext.lua");
local NullContext = commonlib.gettable("MyCompany.Aries.Game.SceneContext.NullContext");
------------------------------------------------------------
]]

local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local NullContext = commonlib.inherit(commonlib.gettable("System.Core.SceneContext"), commonlib.gettable("MyCompany.Aries.Game.SceneContext.NullContext"));

NullContext:Property({"Name", "NullContext"});


function NullContext:ctor()
end

-- virtual function: 
-- try to select this context. 
function NullContext:OnSelect()
	NullContext._super.OnSelect(self);
end

-- virtual function: 
-- return true if we are not in the middle of any operation and fire unselected signal. 
-- or false, if we can not unselect the scene tool context at the moment. 
function NullContext:OnUnselect()
	NullContext._super.OnUnselect(self);
	return true;
end
-- virtual: 
function NullContext:mousePressEvent(event)
	event:accept();
end

-- virtual: 
function NullContext:mouseMoveEvent(event)
	event:accept();
end

function NullContext:handleLeftClickScene(event, result)
	
end

-- virtual: 
function NullContext:mouseReleaseEvent(event)
	event:accept();
end

function NullContext:HandleGlobalKey(event)
	event:accept();
end