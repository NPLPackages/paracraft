--[[
Title: ParaWorld Main Interface
Author(s): LiXizhi
Date: 2020/8/9
Desc:
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/CourseWorldMain.lua");
local CourseWorldMain = commonlib.gettable("Paracraft.Controls.CourseWorldMain");
CourseWorldMain:Init()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.world.lua");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/generators/ParaWorldMiniChunkGenerator.lua");
local ParaWorldMiniChunkGenerator = commonlib.gettable("MyCompany.Aries.Game.World.Generators.ParaWorldMiniChunkGenerator");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local CourseWorldMain = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("Paracraft.Controls.CourseWorldMain"));

CourseWorldMain:Property({"Size", 256});

function CourseWorldMain:ctor()
end

function CourseWorldMain:Init()
	if(not self.isInited) then
		self.isInited = true
	else
		return
	end
	self.AllMiniWorld = {{}, {}, {}};
	self:OnWorldLoaded();
	GameLogic:Connect("WorldUnloaded", CourseWorldMain, CourseWorldMain.OnWorldUnload, "UniqueConnection");
end

function CourseWorldMain:OnWorldLoaded()
	self:ShowAllAreas()
end

function CourseWorldMain:OnWorldUnload()
	self.isInited = false;
	self:Reset()
	self:CloseAllAreas()
end

function CourseWorldMain:ShowAllAreas()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/CourseWorldMinimapWnd.lua");
	local CourseWorldMinimapWnd = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaWorld.CourseWorldMinimapWnd");
	CourseWorldMinimapWnd:Show();
end

function CourseWorldMain:CloseAllAreas()
	local CourseWorldMinimapWnd = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaWorld.CourseWorldMinimapWnd");
	CourseWorldMinimapWnd:Close();
end

function CourseWorldMain:GetRegionCenter(typeIndex)
	self.centerPos = self.centerPos or {{19200, 12, 19200-512}, {19200+512, 12, 19200}, {19200, 12, 19200+512}};
	return self.centerPos[typeIndex];
end

function CourseWorldMain:FromWorldPosToGridXY(worldX, worldY, typeIndex)
	local center = self:GetRegionCenter(typeIndex);
	return math.floor((worldX - center[1])/128), math.floor((worldY - center[3])/128)
end

function CourseWorldMain:TypeToIndex(type)
	self.mapTypeIndex = self.mapTypeIndex or {grade = 1, school = 2, all = 3};
	return self.mapTypeIndex[type] or 1;
end

function CourseWorldMain:LoadMiniWorldOnPos(x, z)
	if (self.enterWorkWorld) then
		self.downloadTasks = {};
		local typeIndex = self:TypeToIndex(self.currentType);
		local gridX, gridY = self:FromWorldPosToGridXY(x, z, typeIndex);
		self:addTasks(typeIndex, gridX, gridY, true);
		for i = -1, 1, 2 do
			self:addTasks(typeIndex, gridX + i, gridY, false);
			self:addTasks(typeIndex, gridX, gridY + i, false);
		end

		self:loadMiniWorld(1, typeIndex);
	end
end

function CourseWorldMain:isValidGridXY(typeIndex, gridX, gridY)
	if (typeIndex == 1) then
		-- border: left 2, top 1, bottom 2
		return gridX <= 1 and gridX >= -2 and gridY <= 2;
	elseif (typeIndex == 2) then
		-- border: left 2, right 1, bottom 2
		return gridY <= 2 and gridY >= -1 and gridX >= -2;
	elseif (typeIndex == 3) then
		-- border: right 1, top 1, bottom 2
		return gridX <= 1 and gridX >= -2 and gridY >= -2;
	else
		return false;
	end
end

function CourseWorldMain:localGridXYToGlobal(gridX, gridY, typeIndex)
	if (typeIndex == 1) then
		gridX = gridX
		gridY = gridY - 4;
	elseif (typeIndex == 2) then
		gridX = gridX + 4;
		gridY = gridY;
	elseif (typeIndex == 3) then
		gridX = gridX
		gridY = gridY + 4;
	end
	return gridX, gridY;
end

function CourseWorldMain:addTasks(typeIndex, gridX, gridY, center)
	if (not self:isValidGridXY(typeIndex, gridX, gridY)) then
		return;
	end
	local currentWorldList = self.AllMiniWorld[typeIndex];
	local key = string.format("%d_%d", gridX, gridY);
	if (currentWorldList[key] and currentWorldList[key].loaded) then
		if (center and currentWorldList[key].projectName and currentWorldList[key].projectName ~= "") then
			GameLogic.AddBBS(nil, string.format(L"欢迎来到【%s】", currentWorldList[key].projectName), 3000, "0 255 0");
		end
		return;
	end

	local index = self.currentIndex;
	if (currentWorldList[key] and currentWorldList[key].worldIndex > 0) then
		index = currentWorldList[key].worldIndex;
	end
	local world = self.currentWorlds[index];
	if (world) then
		currentWorldList[key] = {loaded = false, worldIndex = index};
		self.currentIndex = self.currentIndex + 1;

		self.downloadTasks[#self.downloadTasks + 1] = {gridX = gridX, gridY = gridY, center = center, projectId = world.id, projectName = world.name, userId = world.userId};
	end
end

function CourseWorldMain:loadMiniWorld(index, typeIndex)
	local task = self.downloadTasks[index];
	if (task) then
		local currentWorldList = self.AllMiniWorld[typeIndex];
		local key = string.format("%d_%d", task.gridX, task.gridY);
		if (currentWorldList[key] == nil) then
			self:loadMiniWorld(index+1, typeIndex);
			return;
		end;

		function downloadFile(commitId)
			local path = ParaWorldMiniChunkGenerator:GetTemplateFilepath();
			local filename = ParaIO.GetFileName(path);
			GameLogic.GetFilters():apply_filters('get_single_file_by_commit_id',task.projectId, commitId, filename, function(content)
				if (not content) then
					currentWorldList[key].loaded = false;
					self:loadMiniWorld(index+1, typeIndex);
					return;
				end

				local miniTemplateDir = ParaIO.GetWritablePath().."temp/miniworlds/";
				ParaIO.CreateDirectory(miniTemplateDir);
				local template_file = miniTemplateDir..task.projectId..".xml";
				local file = ParaIO.open(template_file, "w");
				if (file:IsValid()) then
					file:write(content, #content);
					file:close();
					local gen = GameLogic.GetBlockGenerator();
					local x, y = self:localGridXYToGlobal(task.gridX, task.gridY, typeIndex);
					gen:LoadTemplateAtGridXY(x, y, template_file);
					currentWorldList[key].loaded = true;
					currentWorldList[key].projectName = task.projectName;
					currentWorldList[key].projectId = task.projectId;
					currentWorldList[key].userId = task.userId;
					if (task.center) then
						GameLogic.AddBBS(nil, string.format(L"欢迎来到【%s】", task.projectName), 3000, "0 255 0");
					end
				else
					currentWorldList[key].loaded = false;
				end
				self:loadMiniWorld(index+1, typeIndex);
			end, true);
		end

		keepwork.world.detail({router_params = {id = task.projectId}}, function(err, msg, data)
			if (data and data.world and data.world.commitId) then
				downloadFile(data.world.commitId);
			else
				currentWorldList[key].loaded = false;
				self:loadMiniWorld(index+1, typeIndex);
			end
		end);
	end
end

function CourseWorldMain:Reset()
	self.AllMiniWorld = nil;
	self.currentWorlds = nil;
	self.downloadTasks = nil;
	self.enterWorkWorld = false;
end

function CourseWorldMain:UpdateWorld(worldName)
	local blocks = ParaWorldMiniChunkGenerator:GetAllBlocks();
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
	local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
	local filename = ParaIO.GetWritablePath().."worlds/DesignHouse/"..commonlib.Encoding.Utf8ToDefault(worldName).."/miniworld.template.xml";
	
	local x, y, z = ParaWorldMiniChunkGenerator:GetPivot();
	local params = {};
	params.pivot = string.format("%d,%d,%d", x, y, z)
	params.relative_motion = true;
	
	local task = BlockTemplate:new({operation = BlockTemplate.Operations.Save, filename = filename, 
		params = params,
		exportReferencedFiles = true,
		blocks = blocks})
	task:Run();

	GameLogic.GetFilters():apply_filters("cellar.sync.sync_main.sync_to_data_source_by_world_name", worldName, function(res)
		if (res) then
		end
	end);
end

function CourseWorldMain:EnterWorksWord(type, parentId)
	self.currentType = type;
	self.currentIndex = 1;
	self.currentWorlds = {};
	keepwork.world.by_parent_id({type = type, parentId = parentId}, function(err, msg, data)
		if (data and data.count and data.rows) then
			for i = 1, #data.rows do
				self.currentWorlds[i] = data.rows[i];
			end
			self.enterWorkWorld = true;
		end
	end);
end

CourseWorldMain:InitSingleton();