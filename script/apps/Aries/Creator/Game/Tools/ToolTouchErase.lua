--[[
Title: touch tool
Author(s): LiXizhi
Date: 2014/11/25
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tools/ToolTouchErase.lua");
local ToolTouchErase = commonlib.gettable("MyCompany.Aries.Game.Tools.ToolTouchErase");
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tools/ToolTouchBase.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Tool = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Tools.ToolTouchBase"), commonlib.gettable("MyCompany.Aries.Game.Tools.ToolTouchErase"));
Tool:Property("Name", "ToolTouchErase");

-- whether to show touch track. 
Tool:Property("ShowTouchTrack", true);
-- whether to allow selecting multiple blocks. 
Tool:Property("AllowMultiSelection", true);


function Tool:ctor()
end


function Tool:OnSelect()
	Tool._super.OnSelect(self);
	GameLogic.SetTouchMode("del");
end

function Tool:OnDeselect()
	Tool._super.OnDeselect(self);
	GameLogic.SetTouchMode("add");
end

-- virtual function: handle all kinds of touch actions
function Tool:handleTouchUpAction(touch_session, touch)
	self:DestroyBlocks(touch_session);
end

function Tool:DestroyBlocks(touch_session)
	local blocks = touch_session:GetBlocks();
	if(blocks and #blocks >= 1) then
		-- destroy all touched blocks
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DestroyNearbyBlocksTask.lua");
		local task = MyCompany.Aries.Game.Tasks.DestroyNearbyBlocks:new({
			explode_time=200, 
			destroy_blocks = blocks,
		})
		task:Run();
	end
end