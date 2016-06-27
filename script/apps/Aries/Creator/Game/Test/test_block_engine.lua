--[[
Title: test block engine
Author(s): LiXizhi
Date: 2012/10/20
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Test/test_block_engine.lua");

local Test = commonlib.gettable("MyCompany.Aries.Game.BlockEngine.Test")
Test.TestInit()

-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/block_types.lua");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")

local Test = commonlib.gettable("MyCompany.Aries.Game.BlockEngine.Test")

-----------------------------------
-- a fake terrain engine just to emulate C++ ParaTerrain interface
-----------------------------------
local Fake_ParaTerrain = commonlib.gettable("MyCompany.Aries.Game.Fake_ParaTerrain")

Fake_ParaTerrain.Assets = {
	["solid_block"] = "model/common/editor/scalebox.x",
}

-- get block type at the given real world coordinate
-- @param x, y, z: real world coordinates.
-- @return -1 means nil, 0 means empty, 1 means opaque block, etc. 
function Fake_ParaTerrain.GetBlockType(x, y, z)
	return BlockEngine:GetBlockTypeInCache(x, y, z);
end

-- similar to GetBlockType except that index is block coordinates is uint16
-- @param x, y, z: block index
function Fake_ParaTerrain.GetBlockTypeIdx(x, y, z)
	return BlockEngine:GetBlockTypeInCacheIdx(x, y, z);
end

-- one can call this function to create or remove new block at the given index.
function Fake_ParaTerrain.SetBlockType(x, y, z, type_id)
	if(not x) then
		log("error setting block type, because x is nil\n")
	end
	
	BlockEngine:SetBlockAttributeInCache(x,y,z, "type", type_id);

	local function RemoveIfExist_(x,y,z)
		local obj_id = BlockEngine:GetBlockAttributeInCache(x, y, z, "obj_id");
		if(obj_id) then
			local obj = ParaScene.GetObject(obj_id);
			ParaScene.Delete(obj);
		end
	end
	
	local names = block_types.names;
	if(type_id == names.block) then
		RemoveIfExist_(x,y,z);
		-- use a real block to simulate it. 
		local x, y, z = BlockEngine:GetBlockCenter(x,y,z)

		local _asset = ParaAsset.LoadStaticMesh("", Fake_ParaTerrain.Assets["solid_block"]);
		obj = ParaScene.CreateMeshPhysicsObject("block", _asset, 1,1,1,false, "5,0,0,0,8,0,0,0,5,0,0,0");
		obj:SetFacing(0);
		obj:SetPosition(x, y, z);
		obj:GetAttributeObject():SetField("progress", 1);
		ParaScene.Attach(obj);
		BlockEngine:SetBlockAttributeInCache(x,y,z, "obj_id", obj:GetID());

	elseif(type_id == nil or type_id == names.null or type_id == names.empty) then
		-- remove it
		RemoveIfExist_(x,y,z);
	elseif(type_id == names.torch) then
		-- TODO: more
	end
end

-- @param name: supported attributes are like "type", "texture", ...
-- one can use this function to create or destroy a block. 
function Fake_ParaTerrain.GetBlockTemplateAtt(templateId, name,value)
	local params = block_types.create_get_type(templateId);
	return params[name];
end

-- set the block template. usually this function is only called when a game world is first loaded
-- when all block types are loaded before a game world start. 
function Fake_ParaTerrain.SetBlockTemplateAtt(templateId, name,value)
	local params = block_types.create_get_type(templateId);
	params[name] = value;
end

-- ray tracing from a given vector with length. 
-- return the block center position, hit side id(0-5), hit position, hit length.
--  such as: {pos={1,0,1}, side=2, hitpos={1,0,1}, length=10}
function Fake_ParaTerrain.BlockPicking(point, direction, length)
end

-- mouse picking the current location. 
function Fake_ParaTerrain.MousePick(fMaxDistance, sFilterFunc)
end

--get the highest block's y pos from x,z.
-- @return float number
function Fake_ParaTerrain.BlockGetElevation(x,z)
	
end

-- return a list of block positions that matches a search condition within a given radius of a point. 
-- @param search_name: 
--		"backtrace_nil": searching for the closest nil blocks. 
--		"portal": searching for the closest portal object.  the portal object emit sky light in the column it stays. (It can penetrate all blocks) 
-- @param search_params: nil or a table of search params
-- @return nil or an array of point {}
function Fake_ParaTerrain.SearchBlocks(point, radius, search_name, search_params)
end

-------------------------------------
-- below are test cases
-------------------------------------

-- test case: init
function Test.TestInit()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Test/test_block_engine.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua");
	local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
	local Fake_ParaTerrain = commonlib.gettable("MyCompany.Aries.Game.Fake_ParaTerrain")

	BlockEngine:Connect();
	
	BlockEngine:UpdateEyePosition(20001, 0, 20002);
	BlockEngine:Dump();
	
	echo("testing fake terrain");
	echo({Fake_ParaTerrain.GetBlockType(20000, 0, 20000)});
	Fake_ParaTerrain.SetBlockAttribute(20000, 0, 20000, "type", 1);
	Fake_ParaTerrain.SetBlockAttribute(20001.5, 0, 20000, "type", 0);
	echo({Fake_ParaTerrain.GetBlockType(20000, 0, 20000)});
	echo({Fake_ParaTerrain.GetBlockType(20001.5, 0, 20000)});

	BlockEngine:Disconnect();
end

-- test coordinate positions
function Test.TestConversion()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Test/test_block_engine.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua");
	local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
	local Fake_ParaTerrain = commonlib.gettable("MyCompany.Aries.Game.Fake_ParaTerrain")

	BlockEngine:Connect();

	echo({BlockEngine:block(20001, 0, 20002)});
	echo({BlockEngine:GetBlockCenter(20001, 0, 20002)});
	echo({BlockEngine:real(BlockEngine:block(20001, 0, 20002))});

	BlockEngine:Disconnect();
end

-- test coordinate positions
function Test.TestObjectCreation()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Test/test_block_engine.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua");
	local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
	local Fake_ParaTerrain = commonlib.gettable("MyCompany.Aries.Game.Fake_ParaTerrain")

	BlockEngine:Connect();

	NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
	local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
	GameLogic.Init();

	GameLogic.CreateObject("random_block");
	GameLogic.CreateObject("spawn_room");

	BlockEngine:Disconnect();
end

function Test.TestFrameMove()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Test/test_block_engine.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua");
	local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")

	BlockEngine:Connect();

	NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
	local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
	GameLogic.Init();
	local last_func = BlockEngine.GetNextDynamicTypeInColumn;

	local offset_y = 0;
	BlockEngine.GetNextDynamicTypeInColumn = function(self, x, y, z)
		offset_y = offset_y +0.01;
		x, y, z = BlockEngine:real(x, 0, z);
		GameLogic.CreateObject("random_block", x, 5+offset_y, z);
		return 0;
	end
	local x, y, z = ParaScene.GetPlayer():GetPosition();
	local eye_x, eye_y, eye_z = BlockEngine:block(x, y, z );
	BlockEngine:FrameMoveRegion(eye_x, eye_y, eye_z, 2, 0);
	BlockEngine:FrameMoveRegion(eye_x, eye_y, eye_z, 4, 4);
	BlockEngine:FrameMoveRegion(eye_x, eye_y, eye_z, 7, 6);

	BlockEngine.GetNextDynamicTypeInColumn = last_func;

	BlockEngine:Disconnect();
end