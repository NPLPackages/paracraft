--[[
Title: Test World related api
Author(s): LiXizhi
Date: 2013/8/29
Desc: 
-----------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/test/test_world.lua");
local test_world = commonlib.gettable("MyCompany.Aries.Game.World.Tests.test_world");
test_world.test_WorldChunk();
test_world.test_WorldBasic()
test_world.test_UniversalCoords();
-----------------------------------------------
]]
	
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/UniversalCoords.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/World.lua");
local World = commonlib.gettable("MyCompany.Aries.Game.World.World");
local UniversalCoords = commonlib.gettable("MyCompany.Aries.Game.Common.UniversalCoords");

local test_world = commonlib.gettable("MyCompany.Aries.Game.World.Tests.test_world");

function test_world.test_UniversalCoords()
	local c1 = UniversalCoords:new():FromWorld(20000, 0, 20000)
	echo(c1);
	c1:FromBlock(16, 16, 1, 2, 3);
	echo(c1);
	c1:FromChunk(16, 16);
	echo(c1);
	c1:FromPackedChunk(0x00ff00ff);
	echo(c1);
end

function test_world.test_WorldBasic()
	local world = World:new():Init(nil,nil);

	local c1 = UniversalCoords:new():FromWorld(20000, 0, 20000)

	local chunk1 = world:GetChunk(c1:GetChunkX(), c1:GetChunkZ(), true);
	local chunk2 = world:GetChunkFromWorld(20000, 20000, true);
	assert(chunk1 == chunk2);

	local c2 = UniversalCoords:new():FromWorld(20000, 3, 20000)

	local b1 = world:GetBlock(c2);
	assert(b1.block_id == 0);

	-- set block id to 1
	world:SetBlock(c2, 1, true);
	-- set block id to 2
	world:SetBlockFromWorld(c2.WorldX, c2.WorldY, c2.WorldZ, 2, true);
	local b2 = world:GetBlockByPos(c2.WorldX, c2.WorldY, c2.WorldZ);
	assert(b2.block_id == 2 and b2.block_id ==world:GetBlockId(c2));

end

function test_world.test_WorldChunk()
	local world = World:new():Init(nil,nil);
	local coord = UniversalCoords:new():FromWorld(19203, 4, 19203)

	local chunk = world:GetChunk(coord:GetChunkX(), coord:GetChunkZ(), true);
	local chunkData = chunk:GetMapChunkData(true, 65535);
	echo(chunkData);
	chunk:FillChunk(chunkData, 65535, false);
end