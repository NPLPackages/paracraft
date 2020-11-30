--[[
Title: ParaWorldMiniChunkGenerator
Author(s): LiXizhi
Date: 2020.8.12
Desc: A mini 128*128 world 
-----------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/generators/ParaWorldMiniChunkGenerator.lua");
local ParaWorldMiniChunkGenerator = commonlib.gettable("MyCompany.Aries.Game.World.Generators.ParaWorldMiniChunkGenerator");
ChunkGenerators:Register("paraworldMini", ParaWorldMiniChunkGenerator);
-----------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/World/ChunkGenerator.lua");
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.world.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldMinimapSurface.lua");
local ParaWorldMinimapSurface = commonlib.gettable("Paracraft.Controls.ParaWorldMinimapSurface");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local names = commonlib.gettable("MyCompany.Aries.Game.block_types.names");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")

local ParaWorldMiniChunkGenerator = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.World.ChunkGenerator"), commonlib.gettable("MyCompany.Aries.Game.World.Generators.ParaWorldMiniChunkGenerator"))
local defaultFilename = "miniworld.template.xml"
-- dynamic blocks are not supported. 
local ignoreList = {[9]=true,[253]=true,[110]=true,[216]=true,[217]=true,[196]=true,[218]=true,
	-- [219]=true,[215]=true,[254]=true,[189]=true, [221]=true,[212]=true, [22]=true,
};
-- dynamic water to still water
local replaceList = {[75]=76,};
-- max allowed blocks
ParaWorldMiniChunkGenerator.MaxAllowedBlock = 200000;

local road_block_id = 71;
local ground_block_id = 62;
local road_edge_id = 180;

function ParaWorldMiniChunkGenerator:ctor()
end

-- @param world: WorldManager, if nil, it means a local generator. 
-- @param seed: a number
function ParaWorldMiniChunkGenerator:Init(world, seed)
	ParaWorldMiniChunkGenerator._super.Init(self, world, seed);
	return self;
end

function ParaWorldMiniChunkGenerator:OnExit()
	ParaWorldMiniChunkGenerator._super.OnExit(self);
	if(self.lock_timer) then
		self.lock_timer:Change();
	end
end


function ParaWorldMiniChunkGenerator:GetPivot()
	return 19136, 12, 19136
end

function ParaWorldMiniChunkGenerator:GetAllBlocks()
	local blocks = {};
	local originX, from_y, originZ = self:GetPivot();
	for x = 19140, 19259 do
		for z = 19140, 19259 do
			local block_id, y, block_data = BlockEngine:GetNextBlockOfTypeInColumn(x,255,z, 0xffff, 255-from_y-1);
			while(block_id and y >= (from_y-1)) do
				if(not ignoreList[block_id]) then
					if(y < from_y) then
						if(y == (from_y - 1) and block_id ~= ground_block_id) then
							-- ignore if the ground block does not change. 
						else
							break;
						end
					end
					block_id = replaceList[block_id] or block_id
					local block = block_types.get(block_id);
					local node;
					if(block) then
						local entity = block:GetBlockEntity(x,y,z);
						if(entity) then
							node = entity:SaveToXMLNode();
						end
					end
					if(block_data == 0) then
						block_data = nil
					end
					blocks[#blocks+1] = {x-originX, y-from_y, z-originX, block_id, block_data, node}
				end
				block_id, y = BlockEngine:GetNextBlockOfTypeInColumn(x,y,z, 0xffff)
			end
		end
	end
	return blocks;
end

function ParaWorldMiniChunkGenerator:GetTemplateFilepath()
	return GameLogic.GetWorldDirectory()..defaultFilename;
end

function ParaWorldMiniChunkGenerator:GetBlockCountInTemplate(filename)
	local count = 0;
	local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
	if(xmlRoot) then
		local node = commonlib.XPath.selectNode(xmlRoot, "/pe:blocktemplate");
		if(node and node.attr and node.attr.count) then
			count = tonumber(node.attr.count) or 0
		end
	end
	return count;
end

function ParaWorldMiniChunkGenerator:ShowBlockTip(count)
	count = count or self.count or 0;
	if(count < self.MaxAllowedBlock) then
		GameLogic.AddBBS("paraworld", format(L"剩余空间%d%%", math.floor((self.MaxAllowedBlock - count)/self.MaxAllowedBlock * 100)), 5000, "0 255 0");
	else
		GameLogic.AddBBS("paraworld", L"方块数量大于20万块，请删除一定方块后上传", 5000, "255 0 0");
	end
end

function ParaWorldMiniChunkGenerator:OnLoadWorld()
	local filename = self:GetTemplateFilepath();
	local count = self:GetBlockCountInTemplate(filename)
	if(count) then
		self.count = count;
		self:ShowBlockTip()
	end
	GameLogic.RunCommand("/speedscale 2");
	GameLogic.options:SetViewBobbing(false, true)
	
	if(self:GetTotalCount() < 10) then
		local revision = GameLogic.options:GetRevision();
		if (not GameLogic.IsReadOnly() and (not revision or revision < 2)) then
			self:ShowCreateFromTemplateWnd()
		end
	end

	self.lock_timer = self.lock_timer or commonlib.Timer:new({callbackFunc = function(timer)
		self:OnLockTimer()
	end})
	self.lock_timer:Change(1000, 1000);
end

function ParaWorldMiniChunkGenerator:ShowCreateFromTemplateWnd(delay)
	-- TODO: for chenjinxian, use following code to load template, Effie will provide all template bmax files as keepwork git url
	-- you need to download and load the selected one

	-- following code is tested by Xizhi
--	_guihelper.MessageBox(L"shall we load from a template?", function()
--		local filename = self:GetTemplateFilepath()
--		self:LoadFromTemplateFile(filename)
--	end)
	local ParaWorldTemplates = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldTemplates.lua");
	ParaWorldTemplates.ShowPage(function(filename)
		if (filename) then
			self:LoadFromTemplateFile(filename);
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldMinimapWnd.lua");
			local ParaWorldMinimapWnd = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaWorld.ParaWorldMinimapWnd");
			ParaWorldMinimapWnd:RefreshMap()
			-- player may be hided by the blocks from template
			--[[
			local x, y, z = GameLogic.GetHomePosition();
			if(x and y and z) then
				local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
				x, y, z = BlockEngine:ConvertToBlockIndex_float(x, y, z);
				y = ParaWorldMinimapSurface:GetHeightByWorldPos(x, z)
				if(y) then
					GameLogic.RunCommand(format("/goto %d %d %d", x, y+1, z))
				end
			end
			]]
		end
	end, delay);
end

-- please note: it does not clear the scene, it simply load template to pivot point
-- @param filename: bmax filename
function ParaWorldMiniChunkGenerator:LoadFromTemplateFile(filename)
	filename = filename or self:GetTemplateFilepath()

	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
	local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
	local minX, minY, minZ = self:GetPivot();
	minX = minX + 4;
	minZ = minZ + 4;
	local task = BlockTemplate:new({operation = BlockTemplate.Operations.Load, filename = filename,
			blockX = minX,blockY = minY, blockZ = minZ, bSelect=false, UseAbsolutePos = false, TeleportPlayer = false})
	task:Run();
end


function ParaWorldMiniChunkGenerator:OnLockTimer()
	local player = EntityManager.GetPlayer()
	local x, y, z = player:GetBlockPos();
	local minX, minY, minZ = self:GetPivot();
	local maxX = minX+128;
	local maxZ = minZ+128;
	local newX = math.min(maxX-5, math.max(minX+4, x));
	local newZ = math.min(maxZ-5, math.max(minZ+4, z));
	local newY = math.max(minY-1, y);
	if(x~=newX or y~=newY or z~=newZ) then
		player:SetBlockPos(newX, newY, newZ)
		if(y~=newY and not GameLogic.IsReadOnly()) then
			local blockTemplate = BlockEngine:GetBlock(newX, minY-2, newZ)	
			if(not blockTemplate) then
				BlockEngine:SetBlock(newX, minY-2, newZ, names.Bedrock);
			end
		end
	end
end

function ParaWorldMiniChunkGenerator:GetTotalCount()
	return self.count or 0;
end


function ParaWorldMiniChunkGenerator:OnSaveWorld()
	local blocks = self:GetAllBlocks();
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
	local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
	local filename = self:GetTemplateFilepath();
	
	local x, y, z = self:GetPivot();
	local params = {};
	params.pivot = string.format("%d,%d,%d", x, y, z)
	params.relative_motion = true;
	
	local task = BlockTemplate:new({operation = BlockTemplate.Operations.Save, filename = filename, 
		params = params,
		exportReferencedFiles = true,
		blocks = blocks})
	task:Run();
	self.count = params.count or 0
	self:ShowBlockTip()

	if(self.count > self.MaxAllowedBlock) then
		return
	end

	local myHomeWorldName = string.format(L"%s的家园", System.User.keepworkUsername);
	local currentWorldName = WorldCommon.GetWorldTag("name");
	if (myHomeWorldName == currentWorldName and WorldCommon.GetWorldTag("world_generator") == "paraworldMini") then
		local function uploadMiniWorld(projectId)
			keepwork.world.worlds_list({projectId = projectId}, function(err, msg, data)
				commonlib.echo(data);
				if (data and type(data) == "table") then
					for i = 1, #data do
						local world = data[i];
						if (world.projectId == projectId) then
							--[[
							local worldName = world.worldName;
							if (world.extra and world.extra.worldTagName) then
								worldName = world.extra.worldTagName;
							end
							]]
							local player = EntityManager.GetPlayer()
							local x, y, z = player:GetBlockPos();
							keepwork.miniworld.upload({projectId = projectId, name = myHomeWorldName, type="main", commitId = world.commitId,
								block = self:GetTotalCount(), bornAt = {math.floor(x), math.floor(y), math.floor(z)}}, function(err, msg, data)
								if (err == 200) then
									_guihelper.MessageBox(L"上传成功！");
								end
							end);
							break;
						end
					end
				end
			end);
		end

		_guihelper.MessageBox(L"世界已保存，是否要上传迷你世界？", function(res)
			if(res and res == _guihelper.DialogResult.Yes)then
				GameLogic.GetFilters():apply_filters("SaveWorldPage.ShowSharePage", true, function(res)
					if (res) then
						local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld');
						if (currentWorld and currentWorld.kpProjectId) then
							uploadMiniWorld(tonumber(currentWorld.kpProjectId));
						end
					end
				end);
			end
		end, _guihelper.MessageBoxButtons.YesNo);
	end
end

-- get params for generating flat terrain
-- one can modify its properties before running custom chunk generator. 
function ParaWorldMiniChunkGenerator:GetFlatLayers()
	if(self.flat_layers == nil) then
		self.flat_layers = {
			{y = 9, block_id = names.Bedrock},
			--{block_id = names.underground_default},
		};
	end
	return self.flat_layers;
end

function ParaWorldMiniChunkGenerator:SetFlatLayers(layers)
	self.flat_layers = layers;
end

-- generate flat terrain
function ParaWorldMiniChunkGenerator:GenerateFlat(c, x, z)
	
	local worldCenterX, worldCenterZ  = 19200, 19200;
	local gridOffsetX = (x*16 - worldCenterX) / 64;
	local gridOffsetZ = (z*16 - worldCenterZ) / 64;
	if(not (-1 <= gridOffsetX  and gridOffsetX < 1 and -1 <= gridOffsetZ  and gridOffsetZ < 1)) then
		-- do not generate anything outside the center
		return
	end

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

	for bx = 0, 15 do
		local worldX = bx + (x * 16);
		for bz = 0, 15 do
			local worldZ = bz + (z * 16);
			local offsetX, offsetZ = ((worldX+64)%128), ((worldZ+64)%128)
			if(offsetX < 4 or offsetZ < 4 or offsetX>123 or offsetZ>123) then
				c:SetType(bx, by, bz, road_block_id, false);

				if( ((offsetX == 3 or offsetX==124) and (offsetZ>=3 and offsetZ<=124)) or 
					((offsetZ == 3 or offsetZ==124) and (offsetX>=3 and offsetX<=124))) then
					c:SetType(bx, by+1, bz, road_edge_id, false);
				end
			else
				c:SetType(bx, by, bz, ground_block_id, false);
			end
		end
	end
end


-- protected virtual funtion:
-- generate chunk for the entire chunk column at x, z
function ParaWorldMiniChunkGenerator:GenerateChunkImp(chunk, x, z, external)
	self:GenerateFlat(chunk, x, z);
end

-- virtual function: this is run in worker thread. It should only use data in the provided chunk.
-- if this function returns false, we will use GenerateChunkImp() instead. 
function ParaWorldMiniChunkGenerator:GenerateChunkAsyncImp(chunk, x, z)
	return false
end

function ParaWorldMiniChunkGenerator:IsSupportAsyncMode()
	return false;
end

-- virtual function: get the class address for sending to worker thread. 
function ParaWorldMiniChunkGenerator:GetClassAddress()
	return {
		filename="script/apps/Aries/Creator/Game/World/generators/ParaWorldMiniChunkGenerator.lua", 
		classpath="MyCompany.Aries.Game.World.Generators.ParaWorldMiniChunkGenerator"
	};
end