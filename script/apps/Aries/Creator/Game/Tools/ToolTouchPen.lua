--[[
Title: touch tool
Author(s): LiXizhi
Date: 2014/11/25
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tools/ToolTouchPen.lua");
local ToolTouchPen = commonlib.gettable("MyCompany.Aries.Game.Tools.ToolTouchPen");
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tools/ToolTouchBase.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Tool = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Tools.ToolTouchBase"), commonlib.gettable("MyCompany.Aries.Game.Tools.ToolTouchPen"));
Tool:Property("Name", "ToolTouchPen");
-- whether to show touch track. 
Tool:Property("ShowTouchTrack", true);
-- whether to allow selecting multiple blocks. 
Tool:Property("AllowMultiSelection", true);

function Tool:ctor()
end

-- virtual function: handle all kinds of touch actions
function Tool:handleTouchUpAction(touch_session, touch)
	self:CreateBlocks(touch_session);
end

function Tool:CreateBlocks(touch_session)
	local blocks = touch_session:GetBlocks();
	if(blocks and #blocks >= 1) then
		-- create on the sides of all touched blocks using the block in hand. 
		local block_id = GameLogic.GetBlockInRightHand();
		if(block_id and block_id<4096) then
			local new_blocks = {};
			for i=1, #blocks do
				local b = blocks[i];
				local x,y,z = BlockEngine:GetBlockIndexBySide(b[1],b[2],b[3],b.side);
				-- TODO: how about block data according to side?
				new_blocks[#new_blocks+1] = {x,y,z, block_id, };
			end
			local task = MyCompany.Aries.Game.Tasks.CreateBlock:new({blocks=new_blocks, entityPlayer = EntityManager.GetPlayer(),});
			task:Run();
		end
	end
end