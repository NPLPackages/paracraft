--[[
Title: Move Manipulator
Author(s): LiXizhi@yeah.net
Date: 2015/9/19
Desc: added middle key to translate to block world position. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/Manipulators/MoveManipContainer.lua");
local MoveManipContainer = commonlib.gettable("MyCompany.Aries.Game.Manipulators.MoveManipContainer");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Scene/Manipulators/MoveManipContainer.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local MoveManipContainer = commonlib.inherit(commonlib.gettable("System.Scene.Manipulators.MoveManipContainer"), commonlib.gettable("MyCompany.Aries.Game.Manipulators.MoveManipContainer"));
MoveManipContainer:Property({"Name", "MoveManipContainer", auto=true});


-- virtual: 
function MoveManipContainer:mouseReleaseEvent(event)
	if(event:button() == "middle") then
		local result = Game.SelectionManager:MousePickBlock(true, false, false);
		if(result and result.blockX) then
			local x, y, z = BlockEngine:real_top(result.blockX, result.blockY, result.blockZ);
			self.translateManip:SetField("position", {x, y, z});
		end
		event:accept();
	end
end