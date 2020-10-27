--[[
Title: ParaWorldChunkGenerator
Author(s): LiXizhi
Date: 2013/8/27, refactored 2015.11.17
Desc: A flat grid world, where the center is 256*256, the outer is 128*128 grid.
-----------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/generators/ParaWorldChunkGenerator.lua");
local ParaWorldChunkGenerator = commonlib.gettable("MyCompany.Aries.Game.World.Generators.ParaWorldChunkGenerator");
ChunkGenerators:Register("paraworld", ParaWorldChunkGenerator);

local filename = nil;
local gen = GameLogic.GetBlockGenerator()
local x, y = gen:GetGridXYBy2DIndex(5,5)
local bx, by, bz = gen:GetBlockOriginByGridXY(x, y)
gen:LoadTemplateAtGridXY(x, y, filename)
GameLogic.EntityManager.GetPlayer():SetBlockPos(bx, by, bz)

NPL.load("(gl)script/apps/Aries/Creator/Game/World/generators/ParaWorldChunkGenerator.lua");
local ParaWorldChunkGenerator = commonlib.gettable("MyCompany.Aries.Game.World.Generators.ParaWorldChunkGenerator");
local x, y, z = GameLogic.EntityManager.GetPlayer():GetBlockPos()
ParaWorldChunkGenerator:LoadTemplate(x, y, z, GameLogic.GetWorldDirectory().."miniworld.template.xml")
-----------------------------------------------
]]
NPL.load("(gl)script/ide/IDE.lua");
NPL.load("(gl)script/ide/System/System.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/ChunkGenerator.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/Chunk.lua");
local Chunk = commonlib.gettable("MyCompany.Aries.Game.World.Chunk");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local names = commonlib.gettable("MyCompany.Aries.Game.block_types.names");
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")

local ParaWorldChunkGenerator = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.World.ChunkGenerator"), commonlib.gettable("MyCompany.Aries.Game.World.Generators.ParaWorldChunkGenerator"))

-- this is the host side ignore list, which could be different from ParaWorldMiniChunkGenerator's ignoreList
local ignoreList = {[9]=true,[253]=true,[110]=true,[216]=true,[217]=true,[196]=true,[218]=true,
	[219]=true,[215]=true,[254]=true,[189]=true, [221]=true,[212]=true, [22]=true,
};


function ParaWorldChunkGenerator:ctor()
	self:SetWorkerThreadCount(1)
end

-- @param world: WorldManager, if nil, it means a local generator. 
-- @param seed: a number
function ParaWorldChunkGenerator:Init(world, seed)
	ParaWorldChunkGenerator._super.Init(self, world, seed);
	return self;
end

function ParaWorldChunkGenerator:OnExit()
	ParaWorldChunkGenerator._super.OnExit(self);
end

function ParaWorldChunkGenerator:OnLoadWorld()
	GameLogic.RunCommand("/speedscale 2");
	GameLogic.options:SetViewBobbing(false, true)

	if(GameLogic.IsReadOnly() and GameLogic.options:GetProjectId() and KeepworkService:IsSignedIn()) then
		GameLogic.RunCommand("/ggs connect -silent=false");
	end

	NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
	local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
	if ((not GameLogic.IsReadOnly()) and KeepworkService:IsSignedIn() and (not WorldCommon.GetWorldTag("fromProjects"))) then
		keepwork.world.myschoolParaWorld({}, function(err, msg, data)
			if (data and data.schoolParaWorld and tostring(data.schoolParaWorld.projectId) == GameLogic.options:GetProjectId()) then
			else
				local ParaWorldSchools = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldSchools.lua");
				ParaWorldSchools.ShowPage(function(projectId)
					if (projectId) then
						WorldCommon.ReplaceWorld(projectId);
					end
				end);
			end
		end);
	end
end

-- get params for generating flat terrain
-- one can modify its properties before running custom chunk generator. 
function ParaWorldChunkGenerator:GetFlatLayers()
	if(self.flat_layers == nil) then
		self.flat_layers = {
			{y = 9, block_id = names.Bedrock},
			--{block_id = names.underground_default},
		};
	end
	return self.flat_layers;
end

function ParaWorldChunkGenerator:SetFlatLayers(layers)
	self.flat_layers = layers;
end

function ParaWorldChunkGenerator:GetWorldCenter()
	return 19200, 12, 19200
end

-- @param worldX, worldY:  world block position
function ParaWorldChunkGenerator:FromWorldPosToGridXY(worldX, worldY)
	local cx, _, cy = self:GetWorldCenter();
	return math.floor((worldX - cx)/128), math.floor((worldY - cy)/128)
end


-- if x, y == 0, 0, we will return the block containing the center. 
-- (0,0), (-1, 0), (0,1), (-1, 0)
-- @param x: [-4, 5]
-- @param y: [-4, 5]
-- @return: x, y, z
function ParaWorldChunkGenerator:GetBlockOriginByGridXY(x, y)
	local cx, cy, cz = self:GetWorldCenter();
	return cx + x*128, cy, cz + y*128;
end

-- get gridXY by a map 2d position's left, top coordinates
-- @param left: [0,9] 
-- @param right: [0,9]
function ParaWorldChunkGenerator:GetGridXYBy2DIndex(left, top)
	return 5-top, 5-left;
end

function ParaWorldChunkGenerator:Get2DIndexByGridXY(x, y)
	return 5-x, 5-y;
end

-- static function:
function ParaWorldChunkGenerator:LoadTemplateAtGridXY(x, y, filename)
	if(filename) then
		local minX, minY, minZ = self:GetBlockOriginByGridXY(x, y);
		if(ParaTerrain.LoadBlockAsync) then
			self:LoadTemplateAsync(minX, minY, minZ, filename)
		else
			self:LoadTemplate(minX, minY, minZ, filename)
		end
	end
end

-- call this function to use a worker thread to load the template file
function ParaWorldChunkGenerator:LoadTemplateAsync(x, y, z, filename)
	self:InvokeCustomFuncAsync("LoadTemplateAsyncImp", {x=x, y=y, z=z, filename=filename})
end

-- consider using LoadTemplateAsync instead. 
-- @param x, y, z: pivot origin. 
function ParaWorldChunkGenerator:LoadTemplate(x, y, z, filename)
	self:LoadTemplateImp({x=x, y=y, z=z, filename=filename})
--	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
--	local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
--	local task = BlockTemplate:new({operation = BlockTemplate.Operations.Load, filename = filename,
--			blockX = x,blockY = y, blockZ = z, bSelect=false, UseAbsolutePos = false, TeleportPlayer = false, nohistory=true})
--	task:Run();
end

-- generate flat terrain
function ParaWorldChunkGenerator:GenerateFlat(c, x, z)
	local layers = self:GetFlatLayers();
			
	local by = layers[1].y;
	for i = 1, #layers do
		by = by + 1;
		local block_id = layers[i].block_id;

		for bx = 0, 15 do
			for bz = 0, 15 do
				c:SetType(bx, by, bz, block_id, false);
			end
		end
	end
	-- Top layer with road
	by = by + 1;
	local road_block_id = 71;
	local road_pgc_block_id = 68;
	local ground_block_id = 62;
	local road_edge_id = 180;
	local road_light_id = 270;
	
	local worldCenterX, _, worldCenterZ  = self:GetWorldCenter();
	local gridOffsetX = (x*16 - worldCenterX) / 128;
	local gridOffsetZ = (z*16 - worldCenterZ) / 128;
	local isPGCArea = false
	if(-1 <= gridOffsetX  and gridOffsetX < 1 and -1 <= gridOffsetZ  and gridOffsetZ < 1) then
		-- PGC region uses a different ground block
		ground_block_id = 59;
		isPGCArea = true
	end
	local worldDX, worldDY, worldDZ = c.Coords.WorldX, c.Coords.WorldY, c.Coords.WorldZ

	for bx = 0, 15 do
		local worldX = bx + (x * 16);
		for bz = 0, 15 do
			local worldZ = bz + (z * 16);
			local offsetX, offsetZ = (worldX%128), (worldZ%128)
			if(offsetX < 4 or offsetZ < 4 or offsetX>123 or offsetZ>123) then
				if(isPGCArea) then
					c:SetType(bx, by, bz, road_pgc_block_id, false);
				else
					c:SetType(bx, by, bz, road_block_id, false);

					if( ((offsetX == 3 or offsetX==124) and (offsetZ>=3 and offsetZ<=124)) or 
						((offsetZ == 3 or offsetZ==124) and (offsetX>=3 and offsetX<=124))) then
						c:SetType(bx, by+1, bz, road_edge_id, false);
					end
					if (((offsetX == 3 or offsetX==124) and (offsetZ>=3 and offsetZ<=122) and ((offsetZ-3)%20 == 0)) or
						((offsetZ == 3 or offsetZ==124) and (offsetX>=3 and offsetX<=122) and ((offsetX-3)%20 == 0)) or
						(offsetX == 124 and offsetZ == 124)) then
						--c:SetType(bx, by+1, bz, road_pgc_block_id, false);
						c:SetType(bx, by+2, bz, road_light_id, false);
					end
				end
			else
				-- just in case we loaded template before generating terrain. we will ignore top grass layer
				if(ParaTerrain.GetBlockTemplateByIdx(worldDX + bx, worldDY + by, worldDZ + bz) == 0) then
					c:SetType(bx, by, bz, ground_block_id, false);
				end
			end
		end
	end
	if(isPGCArea) then
		-- road and road edge in PGC area
		for bx = 0, 15 do
			local worldX = bx + (x * 16);
			for bz = 0, 15 do
				local worldZ = bz + (z * 16);
				local offsetX, offsetZ = ((worldX-128)%256), ((worldZ-128)%256)
				if(offsetX < 4 or offsetZ < 4 or offsetX>251 or offsetZ>251) then
					c:SetType(bx, by, bz, road_block_id, false);
					if( ((offsetX == 3 or offsetX==252) and (offsetZ>=3 and offsetZ<=252)) or 
						((offsetZ == 3 or offsetZ==252) and (offsetX>=3 and offsetX<=252))) then
						c:SetType(bx, by+1, bz, road_edge_id, false);
					end
					if (((offsetX == 3 or offsetX==252) and (offsetZ>=3 and offsetZ<=122) and ((offsetZ-3)%20 == 0)) or
						((offsetZ == 3 or offsetZ==252) and (offsetX>=3 and offsetX<=122) and ((offsetX-3)%20 == 0)) or
						((offsetX == 3 or offsetX==252) and (offsetZ>=131 and offsetZ<=250) and ((offsetZ-131)%20 == 0)) or
						((offsetZ == 3 or offsetZ==252) and (offsetX>=131 and offsetX<=250) and ((offsetX-131)%20 == 0)) or
						(offsetX == 252 and offsetZ == 252) or ((offsetX == 3 or offsetX == 252) and offsetZ == 124) or ((offsetZ == 3 or offsetZ == 252) and offsetX == 124)) then
						--c:SetType(bx, by+1, bz, road_pgc_block_id, false);
						c:SetType(bx, by+2, bz, road_light_id, false);
					end
				end
			end
		end
		if(gridOffsetX  == 0 and gridOffsetZ == 0) then
			-- for center chunk, we will create paraworld initial code block. 
			local worldX = (x * 16);
			local worldZ = (z * 16);
			
			-- code block on ground?
			BlockEngine:SetBlock(worldX, by,worldZ, 219, 0, 3, {attr={}, {name="cmd",[[--tip('hello world')]]}})
			BlockEngine:SetBlock(worldX, by-1,worldZ, 157, 0, 3)
		end
	end
end


-- protected virtual funtion:
-- generate chunk for the entire chunk column at x, z
function ParaWorldChunkGenerator:GenerateChunkImp(chunk, x, z, external)
	self:GenerateFlat(chunk, x, z);
end

-- virtual function: this is run in worker thread. It should only use data in the provided chunk.
-- if this function returns false, we will use GenerateChunkImp() instead. 
function ParaWorldChunkGenerator:GenerateChunkAsyncImp(chunk, x, z)
	return false
end

function ParaWorldChunkGenerator:IsSupportAsyncMode()
	return false;
end

-- virtual function: get the class address for sending to worker thread. 
function ParaWorldChunkGenerator:GetClassAddress()
	return {
		filename="script/apps/Aries/Creator/Game/World/generators/ParaWorldChunkGenerator.lua", 
		classpath="MyCompany.Aries.Game.World.Generators.ParaWorldChunkGenerator"
	};
end


-- only call this in main thread. use LoadTemplateAsyncImp for async mode
function ParaWorldChunkGenerator:LoadTemplateImp(params)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
	local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
	local x, y, z, filename = params.x, params.y, params.z, params.filename
	
	local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
	if(xmlRoot) then
		local root_node = commonlib.XPath.selectNode(xmlRoot, "/pe:blocktemplate");
		if(root_node and root_node[1]) then
			local node = commonlib.XPath.selectNode(root_node, "/pe:blocks");
			if(node and node[1]) then
				local blocks = NPL.LoadTableFromString(node[1]);
				if(blocks and #blocks > 0) then
					local bx, by, bz = x, y, z;
					LOG.std(nil, "info", "BlockTemplate", "LoadTemplate from file: %s at pos:%d %d %d", filename, bx, by, bz);

					if(root_node.attr and root_node.attr.relative_motion == "true") then
						BlockTemplate:CalculateRelativeMotion(blocks, bx, by, bz);
					end

					local addList = {};
					local is_suspended_before = ParaTerrain.GetBlockAttributeObject():GetField("IsLightUpdateSuspended", false);
					if(not is_suspended_before) then
						ParaTerrain.GetBlockAttributeObject():CallField("SuspendLightUpdate");
					end
					for _, b in ipairs(blocks) do
						local x, y, z, block_id = b[1]+bx, b[2]+by, b[3]+bz, b[4];
						if(block_id and not ignoreList[block_id]) then
							local last_block_id = ParaTerrain.GetBlockTemplateByIdx(x,y,z);
							local last_block = block_types.get(last_block_id);
							if(last_block) then
								
							end
							if(block_id ~= last_block_id) then
								ParaTerrain.SetBlockTemplateByIdx(x,y,z, block_id);
							end
							
							if(b[5]) then
								ParaTerrain.SetBlockUserDataByIdx(x,y,z, b[5]);
							end
							local block = block_types.get(block_id);
							
							if(block and block.onload) then
								addList[#addList+1] = b;
							end
						end
					end
					if(not is_suspended_before) then
						ParaTerrain.GetBlockAttributeObject():CallField("ResumeLightUpdate");
					end
					if(#addList > 0) then
						self:ApplyOnLoadBlocks({addList=addList, x=bx, y=by, z=bz})
					end
					local attRegion = ParaTerrain.GetBlockAttributeObject():GetChild(format("region_%d_%d", math.floor(bx/512), math.floor(bz/512)))
					attRegion:SetField("RefreshLightChunkColumns", {math.floor(bx/16), math.floor(bz/16), 128/16});

					return true;
				end
			end
		end
	end
end

-- this function is called in worker thread
-- @param params: {x, y, z, filename}
function ParaWorldChunkGenerator:LoadTemplateAsyncImp(params, msg)
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/block_types.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
	local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
	local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
	block_types.init();
	block_types.RecomputeAttributeOfAllBlocks()

	local x, y, z, filename = params.x, params.y, params.z, params.filename
	
	local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
	if(xmlRoot) then
		local root_node = commonlib.XPath.selectNode(xmlRoot, "/pe:blocktemplate");
		if(root_node and root_node[1]) then
			local node = commonlib.XPath.selectNode(root_node, "/pe:blocks");
			if(node and node[1]) then
				local blocks = NPL.LoadTableFromString(node[1]);
				if(blocks and #blocks > 0) then
					local bx, by, bz = x, y, z;
					LOG.std(nil, "info", "BlockTemplate", "LoadTemplate from file: %s at pos:%d %d %d", filename, bx, by, bz);

					if(root_node.attr and root_node.attr.relative_motion == "true") then
						BlockTemplate:CalculateRelativeMotion(blocks, bx, by, bz);
					end

					local addList = {};
					local is_suspended_before = ParaTerrain.GetBlockAttributeObject():GetField("IsLightUpdateSuspended", false);
					if(not is_suspended_before) then
						ParaTerrain.GetBlockAttributeObject():CallField("SuspendLightUpdate");
					end
					local attRegion = ParaTerrain.GetBlockAttributeObject():GetChild(format("region_%d_%d", math.floor(bx/512), math.floor(bz/512)))
					attRegion:SetField("IsLocked", true)

					for _, b in ipairs(blocks) do
						local x, y, z, block_id = b[1]+bx, b[2]+by, b[3]+bz, b[4];
						if(block_id and not ignoreList[block_id]) then
							ParaTerrain.LoadBlockAsync(x,y,z, block_id, b[5] or 0)
							local block = block_types.get(block_id);
							if(block and block.onload) then
								addList[#addList+1] = b;
							end
						end
					end
					attRegion:SetField("IsLocked", false)
					if(not is_suspended_before) then
						ParaTerrain.GetBlockAttributeObject():CallField("ResumeLightUpdate");
					end
					NPL.activate("(main)script/apps/Aries/Creator/Game/World/ChunkGenerator.lua", {
						cmd="CustomFunc", funcName = "ApplyOnLoadBlocks", params= {addList=addList, x=bx, y=by, z=bz}, 
						gen_id = msg.gen_id, address = msg.address,
					});
					return true;
				end
			end
		end
	end
end

-- called in main thread, similar in Chunk:ApplyMapChunkData
function ParaWorldChunkGenerator:ApplyOnLoadBlocks(params)
	local addList = params.addList;
	local bx, by, bz = params.x, params.y, params.z
	local attRegion = ParaTerrain.GetBlockAttributeObject():GetChild(format("region_%d_%d", math.floor(bx/512), math.floor(bz/512)))
	attRegion:SetField("RefreshLightChunkColumns", {math.floor(bx/16), math.floor(bz/16), 128/16});

	if(addList and #addList > 0) then
		LOG.std(nil, "info", "ParaWorldChunkGenerator", "ApplyOnLoadBlocks: %d blocks", #addList)
		for _, b in ipairs(addList) do
			local x, y, z, block_id = b[1]+bx, b[2]+by, b[3]+bz, b[4];
			local block_template = block_types.get(block_id);
			if(block_template) then
				local block_data = b[5];
				if(not block_template.cubeMode and block_template.customModel) then
					block_template:UpdateModel(x,y,z, block_data)
				end
				block_template:OnBlockAdded(x,y,z, block_data, b[6]);
			end
		end
	end
end