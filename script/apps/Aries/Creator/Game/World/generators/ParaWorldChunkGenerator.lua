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
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
	
local ParaWorldChunkGenerator = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.World.ChunkGenerator"), commonlib.gettable("MyCompany.Aries.Game.World.Generators.ParaWorldChunkGenerator"))

-- this is the host side ignore list, which could be different from ParaWorldMiniChunkGenerator's ignoreList
local ignoreList = {[9]=true,[253]=true,[110]=true,[216]=true,[217]=true,[196]=true,[218]=true,
	-- [219]=true,[189]=true, [221]=true,[212]=true, 
	-- [22]=true,[254]=true,  -- bmax is supported
	-- [215]=true, -- chest
};

local lastGridParams = {};
-- mapping from x,y grid pos to code block pos {x, y, z}
local gridCodeBlocks = {};
-- mapping from x,y grid pos to true
local activeGrids = {};

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
	GameLogic.GetFilters():remove_filter("OnEnterParaWorldGrid", ParaWorldChunkGenerator.OnEnterParaWorldGrid);
	ParaWorldChunkGenerator.ClearStatic();
	if(self.lock_timer) then
		self.lock_timer:Change();
	end
end

-- for temporary world files
function ParaWorldChunkGenerator:GetWorldSearchPath()
	if(not self.worldSearchPath) then
		self.worldSearchPath = ParaIO.GetWritablePath().."temp/paraworld/temp/";
	end
	return self.worldSearchPath;
end

function ParaWorldChunkGenerator.ClearStatic()
	GridParams = {};
	gridCodeBlocks = {};
	activeGrids = {};
end

function ParaWorldChunkGenerator:OnLoadWorld()
	ParaWorldChunkGenerator.ClearStatic();
	local searchPath = self:GetWorldSearchPath();
	local result = commonlib.Files.Find({}, searchPath, 3, 10000, "*.*") or {};
	for i, file in ipairs(result) do
		ParaIO.DeleteFile(searchPath..file.filename)
	end
	
	Files.AddWorldSearchPath(searchPath)

	GameLogic.RunCommand("/speedscale 2");
	GameLogic.options:SetViewBobbing(false, true)


	if(GameLogic.IsReadOnly() and GameLogic.options:GetProjectId() and KeepworkService:IsSignedIn()) then
		GameLogic.options:SetLockedGameMode("game");
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
	
	self.code_timer = self.code_timer or commonlib.Timer:new({callbackFunc = function(timer)
		self:OnCodeTimer()
	end})
	self.code_timer:Change(1000, 1000);

	GameLogic.GetFilters():add_filter("OnEnterParaWorldGrid", ParaWorldChunkGenerator.OnEnterParaWorldGrid);
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

-- delete everything at x, y grid position. 
function ParaWorldChunkGenerator:ResetGridXY(x, y)
	ParaWorldChunkGenerator.EnableCodeBlocksInGrid(x, y, false)
	ParaWorldChunkGenerator.UnregisterCodeBlocksOnGrid(x, y);
	local minX, minY, minZ = self:GetBlockOriginByGridXY(x, y);
	self:ResetGridImp(minX, minY, minZ)
end

-- reset a grid
function ParaWorldChunkGenerator:ResetGridImp(minX, minY, minZ)
	size = size or 124;
	local ground_block_id = 62;

	for x = minX+4, minX + size - 1 do
		for z = minZ+4, minZ + size - 1 do
			local y = minY-1
			BlockEngine:SetBlock(x, y, z, ground_block_id)
			local dist = 1;
			while(dist > 0) do
				dist = ParaTerrain.FindFirstBlock(x,y,z, 4, 255-y, 0xffff);
				if(dist > 0) then
					y = y + dist;
					BlockEngine:SetBlockToAir(x, y, z);
				end
			end
		end
	end
end

-- static function:
-- @param bEnableLogics: true to enable logics like code block and movie block in the file
function ParaWorldChunkGenerator:LoadTemplateAtGridXY(x, y, filename, bEnableLogics)
	if(filename) then
		ParaWorldChunkGenerator.UnregisterCodeBlocksOnGrid(x, y);
		local minX, minY, minZ = self:GetBlockOriginByGridXY(x, y);
		if(ParaTerrain.LoadBlockAsync) then
			self:LoadTemplateAsync(minX, minY, minZ, filename, bEnableLogics)
		else
			self:LoadTemplate(minX, minY, minZ, filename, bEnableLogics)
		end
	end
end

-- call this function to use a worker thread to load the template file
-- @param bEnableLogics: true to enable logics like code block and movie block in the file
function ParaWorldChunkGenerator:LoadTemplateAsync(x, y, z, filename, bEnableLogics)
	self:InvokeCustomFuncAsync("LoadTemplateAsyncImp", {
			x=x, y=y, z=z, filename=filename, bEnableLogics = bEnableLogics, 
			worldDir = GameLogic.GetWorldDirectory(),
		})
end

-- consider using LoadTemplateAsync instead. 
-- @param x, y, z: pivot origin. 
-- @param bEnableLogics: true to enable logics like code block and movie block in the file
function ParaWorldChunkGenerator:LoadTemplate(x, y, z, filename, bEnableLogics)
	self:LoadTemplateImp({x=x, y=y, z=z, filename=filename, bEnableLogics = bEnableLogics})
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
			local entity = EntityManager.GetEntity("player_spawn_point");
			if (not entity) then
				NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateBlockTask.lua");
				local task = MyCompany.Aries.Game.Tasks.CreateBlock:new({block_id = block_types.names.player_spawn_point, blockX=worldX, blockY=by+1, blockZ=worldZ})
				task:Run();

				local ParaWorldNPC = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldNPC.lua");
				ParaWorldNPC.CreateDefaultNPC(worldX, by+1, worldZ);
			end
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
	local x, y, z, filename, bEnableLogics = params.x, params.y, params.z, params.filename, params.bEnableLogics
	
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
						if(block_id and (bEnableLogics or not ignoreList[block_id])) then
							local last_block_id = ParaTerrain.GetBlockTemplateByIdx(x,y,z);
							local last_block = block_types.get(last_block_id);
							
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
						self:ApplyOnLoadBlocks({addList=addList, x=bx, y=by, z=bz, bEnableLogics=bEnableLogics})
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
-- @param params: {x, y, z, filename, worldDir}
function ParaWorldChunkGenerator:LoadTemplateAsyncImp(params, msg)
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/block_types.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
	local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
	local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
	block_types.init();
	block_types.RecomputeAttributeOfAllBlocks()

	local x, y, z, filename, bEnableLogics = params.x, params.y, params.z, params.filename, params.bEnableLogics
	
	local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
	if(xmlRoot) then
		local root_node = commonlib.XPath.selectNode(xmlRoot, "/pe:blocktemplate");
		if(root_node and root_node[1]) then
			local references = commonlib.XPath.selectNode(root_node, "/references");
			if(references) then
				-- "/pe:blocktemplate/references/file"
				local worldSearchDir = self:GetWorldSearchPath();
				NPL.load("(gl)script/ide/System/Encoding/base64.lua");
				for _, file in ipairs(commonlib.XPath.selectNodes(references, "/file") or {}) do
					if(file.attr) then
						local filename = file.attr.filename;
						if(file[1] and filename) then
							local fileData = System.Encoding.unbase64(file[1])
							if(fileData) then
								-- TODO: use a different search path than current world directory. 
								local filepath = worldSearchDir..commonlib.Encoding.Utf8ToDefault(filename);
								ParaIO.CreateDirectory(filepath)
								local file = ParaIO.open(filepath, "w")
								if(file:IsValid()) then
									LOG.std(nil, "info", "BlockTemplate", "bmax file saved to : %s", filepath);
									file:WriteString(fileData, #fileData);
									file:close();
								else
									LOG.std(nil, "warn", "BlockTemplate", "failed to write file to: %s", filepath);
								end
							end
						end
					end
				end
			end
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
						if(block_id and (not ignoreList[block_id])) then
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
						cmd="CustomFunc", funcName = "ApplyOnLoadBlocks", 
						params= {addList=addList, x=bx, y=by, z=bz, bEnableLogics=bEnableLogics}, 
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
	local bEnableLogics = params.bEnableLogics
	local gridX, gridY = self:FromWorldPosToGridXY(bx, bz)
	ParaWorldChunkGenerator.UnregisterCodeBlocksOnGrid(gridX, gridY)
	local attRegion = ParaTerrain.GetBlockAttributeObject():GetChild(format("region_%d_%d", math.floor(bx/512), math.floor(bz/512)))
	attRegion:SetField("RefreshLightChunkColumns", {math.floor(bx/16), math.floor(bz/16), 128/16});

	local hasDelayedCodeBlocks;
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
				if(block_id == 219) then
					-- for code blocks, 
					local serverData = b[6];
					if(serverData and serverData.attr and serverData.attr.isPowered) then
						serverData.attr.delayLoad = true;
						-- make open source by default, so that we can right click to view code content. 
						serverData.attr.isOpenSource = true;
						ParaWorldChunkGenerator.RegisterCodeBlocksOnGrid(gridX, gridY, {x=x, y=y, z=z}, bEnableLogics)
						hasDelayedCodeBlocks = true;
					end
				end
				block_template:OnBlockAdded(x,y,z, block_data, b[6]);
			end
		end
	end
	if(hasDelayedCodeBlocks and lastGridParams and lastGridParams.x == gridX and lastGridParams.y == gridY) then
		ParaWorldChunkGenerator.EnableCodeBlocksInGrid(gridX, gridY, true)
	end
end

-- static function: when user entered a paraworld grid. 
-- @params: {x, y} 2d index Y and X
function ParaWorldChunkGenerator.OnEnterParaWorldGrid(params)
	if(params.x and params.y) then
		local gridX, gridY = ParaWorldChunkGenerator:GetGridXYBy2DIndex(params.y, params.x)
		
		if(lastGridParams.userId == params.userId and lastGridParams.x == gridX and lastGridParams.y == gridY) then
			-- identical grid, do nothing
		else
			lastGridParams.userId = params.userId;
			lastGridParams.x = gridX;
			lastGridParams.y = gridY;
			ParaWorldChunkGenerator.EnableCodeBlocksInGrid(gridX, gridY, true)
		end
	end
	return params;
end

local function GetGridIndex(x, y)
	return 1000 * x + y
end

-- @param codeBlockPos: {x, y, z}
function ParaWorldChunkGenerator.RegisterCodeBlocksOnGrid(x, y, codeBlockPos, bEnableLogics)
	local index = GetGridIndex(x, y)
	local blockList = gridCodeBlocks[index];
	if(not blockList) then
		blockList = {bEnableLogics = bEnableLogics}
		gridCodeBlocks[index] = blockList
	end
	blockList[#blockList+1] = codeBlockPos;
end

function ParaWorldChunkGenerator.UnregisterCodeBlocksOnGrid(x, y)
	local index = GetGridIndex(x, y)
	if(gridCodeBlocks[index]) then
		gridCodeBlocks[index] = nil
		return true
	end
end

function ParaWorldChunkGenerator.EnableCodeBlocksInGridImp(x, y, bEnable)
	local index = GetGridIndex(x, y)
	if(gridCodeBlocks[index]) then
		if(bEnable) then
			activeGrids[index] = {x=x, y=y}
		else
			activeGrids[index] = nil;
		end
			
		local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
		local count = 0;
		for _, codeBlockPos in ipairs(gridCodeBlocks[index]) do
			local entity = EntityManager.GetBlockEntity(codeBlockPos.x, codeBlockPos.y, codeBlockPos.z)
			if(entity and entity:GetBlockId() == 219 and entity:IsPowered()) then
				if(bEnable) then
					if(not entity:IsCodeLoaded()) then
						entity:Restart();
						count = count + 1;
					end
				else
					if(entity:IsCodeLoaded()) then
						entity:Stop();
						count = count + 1;
					end
				end
			end
		end
		if(count > 0) then
			LOG.std(nil, "info", "ParaWorldChunkGenerator", "Enable (%d) CodeBlocks In Grid: %d %d %s", count, x, y, tostring(bEnable));
			if(bEnable) then
				GameLogic.AddBBS("ParaWorldEnableCode", format(L"加载了(%d)个代码方块，在%d,%d", count, x, y), 3000, "0 255 0");
			else
				GameLogic.AddBBS("ParaWorldDisableCode", format(L"卸载了(%d)个代码方块，在%d,%d", count, x, y), 3000, "0 255 0");
			end
		end
	end
end

function ParaWorldChunkGenerator.EnableCodeBlocksInGrid(x, y, bEnable)
	local index = GetGridIndex(x, y)
	if(gridCodeBlocks[index]) then
		if(bEnable) then
			if(gridCodeBlocks[index].bEnableLogics) then
				ParaWorldChunkGenerator.EnableCodeBlocksInGridImp(x, y, bEnable)
			else
				-- ask user for permission if logics are not enabled.
				_guihelper.MessageBox(format(L"是否加载当前地块中的代码?"), function(res)
					if(res and res == _guihelper.DialogResult.Yes) then
						ParaWorldChunkGenerator.EnableCodeBlocksInGridImp(x, y, bEnable)
					end
				end, _guihelper.MessageBoxButtons.YesNo);
			end
		else
			ParaWorldChunkGenerator.EnableCodeBlocksInGridImp(x, y, bEnable)
		end
	else
		activeGrids[index] = nil;
	end
end

function ParaWorldChunkGenerator:OnCodeTimer()
	local player = EntityManager.GetPlayer()
	if(not player) then
		return
	end
	local x, y, z = player:GetBlockPos();

	local leavingGridIndex;
	for index, grid in pairs(activeGrids) do
		local gx, _, gz = self:GetBlockOriginByGridXY(grid.x, grid.y);
		if( math.abs(x - gx - 64) > 80  or math.abs(z - gz - 64) > 80) then
			leavingGridIndex = index;
			break;
		end
	end
	if(leavingGridIndex) then
		local grid = activeGrids[leavingGridIndex]
		if(grid) then
			ParaWorldChunkGenerator.EnableCodeBlocksInGrid(grid.x, grid.y, false)
		end
	end
end