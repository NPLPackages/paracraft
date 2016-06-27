--[[
Title: touch tool
Author(s): LiXizhi
Date: 2014/11/25
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tools/ToolTouchPick.lua");
local ToolTouchPick = commonlib.gettable("MyCompany.Aries.Game.Tools.ToolTouchPick");
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tools/ToolTouchBase.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Tool = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Tools.ToolTouchBase"), commonlib.gettable("MyCompany.Aries.Game.Tools.ToolTouchPick"));
Tool:Property("Name", "ToolTouchPick");

-- whether to show touch track. 
Tool:Property("ShowTouchTrack", true);
-- whether to allow selecting multiple blocks. 
Tool:Property("AllowMultiSelection", false);

function Tool:ctor()
end

-- virtual function: handle all kinds of touch actions
function Tool:handleTouchUpAction(touch_session, touch)
	self:PickBlocks(touch_session);
end

function Tool:PickBlocks(touch_session)
	local blocks = touch_session:GetBlocks();
	if(blocks and #blocks >= 1) then
		local block = blocks[#blocks];
		if(block) then
			if(GameLogic.GameMode:IsEditor()) then
				local block_id = BlockEngine:GetBlockId(block[1], block[2], block[3]);
				if(block_id) then
					GameLogic.SetBlockInRightHand(block_id);
				end
			end
		end
	end
end