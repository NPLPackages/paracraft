--[[
Title: test block world api
Author(s): LiXizhi
Date: 2014/2/6
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Test/test_blockworld.lua");
local Test = commonlib.gettable("MyCompany.Aries.Game.Test")
Test.GetBlockWorld();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/block_types.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")


local Test = commonlib.gettable("MyCompany.Aries.Game.Test")

-- test basic block world function. 
function Test.GetBlockWorld()
	echo("==========testing Test.GetBlockWorld===============");
	
	block_types.init();
	
	local world1 = ParaBlockWorld.GetWorld("test1");

	block_types.update_registered_templates(world1);
	ParaBlockWorld.EnterWorld(world1, "worlds/DesignHouse/circuit/circuit.worldconfig.txt");

	local attr = ParaBlockWorld.GetBlockAttributeObject(world1);
	attr:SetField("OnLoadBlockRegion", ";MyCompany.Aries.Game.Test.OnLoadBlockRegion();");

	ParaBlockWorld.LoadRegion(world1, 19195,4,19226);
	ParaBlockWorld.GetBlockId(world1, 19195, 4, 19226);
	ParaBlockWorld.SetBlockId(world1, 19195, 5, 19226, 100);

	ParaBlockWorld.SaveBlockWorld(world1, true);

	ParaBlockWorld.LeaveWorld(world1); 
end

function Test.OnLoadBlockRegion()
	echo(msg);
end