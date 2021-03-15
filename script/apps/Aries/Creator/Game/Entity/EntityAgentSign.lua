--[[
Title: Agent Sign block entity
Author(s): LiXizhi
Date: 2021/2/17
Desc: Agent sign block is a signature block for describing all scene blocks connected to it. 
Agent sign block have following functions:
1. as a sign block in the scene: it displays the name of the agent and possibly a version number. It is called agent sign block. 
2. A custom `agent editor` UI is shown once the user clicks the button.

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityAgentSign.lua");
local EntityAgentSign = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityAgentSign")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Agent/AgentWorld.lua");
local AgentWorld = commonlib.gettable("MyCompany.Aries.Game.Agent.AgentWorld");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntitySign"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityAgentSign"));
Entity:Property({"languageConfigFile", "mcml", "GetLanguageConfigFile", "SetLanguageConfigFile"})
Entity:Property({"version", "1.0", "GetVersion", "SetVersion", auto=true})
Entity:Property({"agentName", nil, "GetAgentName", "SetAgentName", auto=true})
Entity:Property({"agentDependencies", nil, "GetAgentDependencies", "SetAgentDependencies", auto=true})
Entity:Property({"agentExternalFiles", nil, "GetAgentExternalFiles", "SetAgentExternalFiles", auto=true})
-- agent url is [username]/[worldname]/agents/[agentfilename]
Entity:Property({"agentUrl", nil, "GetAgentUrl", "SetAgentUrl", auto=true})
Entity:Property({"isGlobal", false, "IsGlobal", "SetGlobal", auto=true})
Entity:Property({"isPhantom", false, "IsPhantom", "SetPhantom", auto=true})
-- value in "always", "manual", "auto"
Entity:Property({"updateMethod", "manual", "GetUpdateMethod", "SetUpdateMethod", auto=true})

-- class name
Entity.class_name = "EntityAgentSign";
Entity.text_color = "0 64 64";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);

function Entity:ctor()
	self:SetBagSize(16);
end

function Entity:OnBlockAdded(x,y,z, data)
	self:CheckUpdateAgent();
	Entity._super.OnBlockAdded(self, x,y,z, data)
end

function Entity:OnBlockLoaded(x,y,z, data)
	self:CheckUpdateAgent();
	Entity._super.OnBlockLoaded(self, x,y,z, data)
end

function Entity:OnRemoved()
	if(self.agentWorld) then
		self.agentWorld:Destroy()
		self.agentWorld = nil;
	end
	Entity._super.OnRemoved(self);
end

local EditorAgentMCML
-- the title text to display (can be mcml)
function Entity:GetCommandTitle()
	EditorAgentMCML = EditorAgentMCML or string.format([[
		<div style="float:left;margin-left:5px;margin-top:7px;">
			<input type="button" uiname="EditEntityPage.OnClickAgentEditor" value='<%%="%s"%%>' onclick="MyCompany.Aries.Game.EntityManager.EntityAgentSign.OnClickAgentEditor" style="min-width:80px;color:#ffffff;font-size:12px;height:25px;background:url(Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png#179 89 21 21:8 8 8 8)" />
			<input type="button" uiname="EditEntityPage.OnClickUpdateAgent" value='<%%="%s"%%>' onclick="MyCompany.Aries.Game.EntityManager.EntityAgentSign.OnClickUpdateAgent" style="min-width:80px;color:#ffffff;font-size:12px;height:25px;background:url(Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png#179 89 21 21:8 8 8 8);margin-left:10px" />
		</div>
	]], L"Agent编辑器...", L"下载更新");
	return EditorAgentMCML;
end

function Entity.OnClickUpdateAgent()
	NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EditEntityPage.lua");
	local EditEntityPage = commonlib.gettable("MyCompany.Aries.Game.GUI.EditEntityPage");
	local self = EditEntityPage.GetEntity()
	if(self and self:isa(Entity)) then
		EditEntityPage.CloseWindow();
		self:UpdateFromRemoteSource(true)
	end
end

function Entity.OnClickAgentEditor()
	NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EditEntityPage.lua");
	local EditEntityPage = commonlib.gettable("MyCompany.Aries.Game.GUI.EditEntityPage");
	local self = EditEntityPage.GetEntity()
	if(self and self:isa(Entity)) then
		EditEntityPage.CloseWindow();
		self:OpenAgentEditor();
	end
end


function Entity:GetAgentCachePath()
	local filename
	local projectId = self:GetSourceProjectId();
	if(projectId) then
		local url = self:GetAgentUrl();
		if(url) then
			local username, worldname, subpath = url:match("^@%d+:([^/]+)/([^/]+)/(.*)")
			if(username) then
				filename = ParaIO.GetWritablePath()..format("temp/agents/@%d/%s.xml", projectId, self:GetAgentName() or "");
			end
		end
	else
		-- local or official file
		filename = self:GetAgentFilename(true)
	end
	return filename;
end

-- get local agent path at all cost. 
-- @return nil if no agent is found locally
function Entity:GetExistingAgentFilename()
	local filename = self:GetAgentFilename()
	if(not ParaIO.DoesFileExist(filename, true)) then
		filename = self:GetAgentCachePath()
		if(not ParaIO.DoesFileExist(filename, true)) then
			return nil;
		end
	end
	return filename;
end

-- @param bAskPermission: true to ask for user permission
function Entity:UpdateFromRemoteSource(bAskPermission)
	local function DoUpdate_(filename, bDeployLocally) 
		local function DoUpdateImp_()
			if(bDeployLocally and not GameLogic.IsReadOnly()) then
				local localFilename = self:GetAgentFilename(true)
				if(localFilename ~= filename) then
					if(not ParaIO.CopyFile(filename, localFilename, true)) then
						LOG.std(nil, "warn", "Agent", "failed to copy file: from %s to %s", filename, localFilename);
					end
				end
			end
			self:LoadFromAgentFile(filename)
		end

		if(bAskPermission) then
			_guihelper.MessageBox(format(L"你确定要用远程文件%s 更新本地数据么?",  commonlib.Encoding.DefaultToUtf8(filename)), function()
				DoUpdateImp_()
			end)
		else
			DoUpdateImp_()
		end
	end

	local filename
	local projectId = self:GetSourceProjectId();
	
	if(projectId) then
		local url = self:GetAgentUrl();
		if(url) then
			local username, worldname, subpath = url:match("^@%d+:([^/]+)/([^/]+)/(.*)")
			if(username) then
				GameLogic.GetFilters():apply_filters('get_single_file', projectId, subpath, function(content)
					if(content) then
						local tmpFolder = ParaIO.GetWritablePath()..format("temp/agents/@%d/", projectId);
						ParaIO.CreateDirectory(tmpFolder);
						local filename = tmpFolder..self:GetAgentName()..".xml";
						local file = ParaIO.open(filename, "w");
						if (file:IsValid()) then
							file:write(content, #content);
							file:close();
							DoUpdate_(filename, true)
						end
					else
						LOG.std(nil, "warn", "Agent", "failed to download remote file: %d:%s", projectId, subpath);
					end
				end)
			end
		end
	else
		-- local or official file
		filename = self:GetAgentFilename(true)
		if(filename) then
			DoUpdate_(filename) 
		end
	end
end


function Entity:OpenAgentEditor()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Agent/AgentEditorPage.lua");
	local AgentEditorPage = commonlib.gettable("MyCompany.Aries.Game.Agent.AgentEditorPage");
	AgentEditorPage.ShowPage(self);
end

-- bool: whether show the bag panel
function Entity:HasBag()
	return true;
end

-- virtual function: get array of item stacks that will be displayed to the user when user try to create a new item. 
-- @return nil or array of item stack.
function Entity:GetNewItemsList()
	local itemStackArray = Entity._super.GetNewItemsList(self) or {};
	local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
	itemStackArray[#itemStackArray+1] = ItemStack:new():Init(block_types.names.AgentItem,1);
	itemStackArray[#itemStackArray+1] = ItemStack:new():Init(block_types.names.Book,1);
	return itemStackArray;
end

-- get all connected blocks containing at least one code block. It will search for all blocks above the current block.
-- if no code block is found, it will search for one layer below the current block. 
-- @param bCodeBlockOnly: if true we will only return code blocks
-- @param max_new_count: max number of blocks to be added. default to 1000
-- @return table of blocks. it will return nil, if no code blocks is found
function Entity:GetConnectedBlocks(bCodeBlockOnly, max_new_count)
	max_new_count = max_new_count or 1000;
	
	local blocks = {};
	local codeblocks = {};
	local blockIndices = {}; -- mapping from block index to true for processed bones
	local cx, cy, cz = self:GetBlockPos();
	local min_y = cy;
	local max_y = 255;
	
	local function IsBlockProcessed(x, y, z)
		local boneIndex = BlockEngine:GetSparseIndex(x-cx,y-cy,z-cz);
		return blockIndices[boneIndex];
	end
	local newlyAddedCount = 0;
	local function AddBlock(x, y, z)
		local boneIndex = BlockEngine:GetSparseIndex(x-cx,y-cy,z-cz)
		if(not blockIndices[boneIndex]) then
			blockIndices[boneIndex] = true;
			local block_id = ParaTerrain.GetBlockTemplateByIdx(x,y,z);
			if(block_id > 0) then
				local block = block_types.get(block_id);
				if(block) then
					local block_data = ParaTerrain.GetBlockUserDataByIdx(x,y,z);
					local block = {x,y,z, block_id, block_data}
					blocks[#blocks+1] = block;
					if(block_id == block_types.names.CodeBlock ) then
						codeblocks[#codeblocks+1] = block;
					end
					newlyAddedCount = newlyAddedCount + 1;
					return true;
				end
			end
		end
	end

	local breadthFirstQueue = commonlib.Queue:new();
	local function AddConnectedBlockRecursive(cx,cy,cz)
		if(newlyAddedCount < max_new_count) then
			for side=0,5 do
				local dx, dy, dz = Direction.GetOffsetBySide(side);
				local x, y, z = cx+dx, cy+dy, cz+dz;
				if(y >= min_y and y<=max_y and AddBlock(x, y, z)) then
					breadthFirstQueue:pushright({x,y,z});
				end
			end
		end
	end
	
	local function AddAllBlocksAbove()
		local baseBlockCount = #blocks;
		for i = 1, baseBlockCount do
			local block = blocks[i];
			local x, y, z = block[1], block[2], block[3];
			AddConnectedBlockRecursive(x,y,z);
		end

		while (not breadthFirstQueue:empty()) do
			local block = breadthFirstQueue:popleft();
			AddConnectedBlockRecursive(block[1], block[2], block[3]);
		end		
	end

	-- add this block
	AddBlock(cx, cy, cz);
	AddAllBlocksAbove();
	
	
	if(#codeblocks == 0) then
		-- tricky: if no code block is found, we will also search for the layer below the current block. 
		min_y = min_y - 1;
		max_y = min_y;
		AddAllBlocksAbove()
	end
	if(#codeblocks ~= 0) then
		if(bCodeBlockOnly) then
			return codeblocks;
		else
			return blocks;
		end
	end
end

-- @param bHighlight: false to un-highlight all.
-- @return all blocks
function Entity:HighlightConnectedBlocks(bHighlight)
	if(bHighlight~=false) then
		local blocks = self:GetConnectedBlocks();
		if(blocks) then
			for _, b in ipairs(blocks) do
				ParaTerrain.SelectBlock(b[1], b[2], b[3], true);
			end
		end
		return blocks
	else
		ParaTerrain.DeselectAllBlock();
	end
end

function Entity:SaveToXMLNode(node, bSort)
	node = Entity._super.SaveToXMLNode(self, node, bSort);
	node.attr.version = self:GetVersion();
	node.attr.agentName = self:GetAgentName();
	node.attr.agentDependencies = self:GetAgentDependencies();
	node.attr.agentExternalFiles = self:GetAgentExternalFiles();
	node.attr.agentUrl = self:GetAgentUrl();
	node.attr.updateMethod = self:GetUpdateMethod();
	node.attr.isGlobal = self:IsGlobal();
	node.attr.isPhantom = self:IsPhantom();

	return node;
end

function Entity:LoadFromXMLNode(node)
	Entity._super.LoadFromXMLNode(self, node);
	local attr = node.attr;
	self:SetVersion(attr.version);
	self:SetAgentName(attr.agentName);
	self:SetAgentDependencies(attr.agentDependencies);
	self:SetAgentExternalFiles(attr.agentExternalFiles);
	self:SetAgentUrl(attr.agentUrl);
	self:SetUpdateMethod(attr.updateMethod);
	self:SetGlobal(attr.isGlobal == "true" or attr.isGlobal == true);
	self:SetPhantom(attr.isPhantom == "true" or attr.isPhantom == true);
end


function Entity:GetDisplayName()
	local agentName = self:GetAgentName();
	if(agentName and agentName~="") then
		return format("%s\nv%s\n%s", agentName, self:GetVersion() or "1.0", (self.cmd or ""));
	else
		return self.cmd or "";
	end
end

-- get local agent file name
-- @param bIsSaving: if true, we are saving agent file, if false, we are loading. 
function Entity:GetAgentFilename(bIsSaving)
	local name = self:GetAgentName();
	if(name and name~="") then
		local url = self:GetAgentUrl()
		if(url and url:match("^Mod/Agents/")) then
			if(bIsSaving) then
				return ParaIO.GetWritablePath().."npl_packages/Agents/"..url;
			else
				return url;
			end
		else
			return Files.WorldPathToFullPath("agents/"..name..".xml");
		end
	end
end

function Entity:SaveToAgentFile(filename)
	filename = filename or self:GetAgentFilename(true)
	
	if(filename) then
		-- save to local agent file
		local blocks = self:GetConnectedBlocks()
		if(blocks and #blocks>=1) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
			local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
			
			local pivot_x, pivot_y, pivot_z = self:GetBlockPos();
			local params = {relative_motion = true, pivot = string.format("%d,%d,%d", pivot_x, pivot_y, pivot_z)};
			for i = 1, #(blocks) do
				-- x,y,z,block_id, data, serverdata
				local b = blocks[i];
				b[6] = BlockEngine:GetBlockEntityData(b[1], b[2], b[3]);
				blocks[i] = {b[1]-pivot_x, b[2]-pivot_y, b[3]- pivot_z, b[4], if_else(b[5] == 0, nil, b[5]), b[6]};
			end

			local task = BlockTemplate:new({operation = BlockTemplate.Operations.Save, filename = filename, params = params, blocks = blocks})
			task:Run();
			return true;
		end
	end
end	

function Entity:GetAgentWorld()
	return self.agentWorld
end

function Entity:LoadFromAgentFile(filename, bAddToUndoHistory)
	filename = filename or self:GetAgentFilename()
	local bx, by, bz = self:GetBlockPos();
	if(filename and ParaIO.DoesFileExist(filename, true)) then
		LOG.std(nil, "info", "Agent", "update agent(%d,%d,%d) from file: %s", bx, by, bz, filename);

		local agentWorld = self:GetAgentWorld();
		if(agentWorld) then
			agentWorld:Destroy()
			self.agentWorld = nil;
		end
		if(self:IsPhantom()) then
			agentWorld = AgentWorld:new():Init(filename);
			if(agentWorld) then
				self.agentWorld = agentWorld;
				self.agentWorld:Run()
			end
		else
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
			local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
			local task = BlockTemplate:new({operation = BlockTemplate.Operations.Load, filename = filename,
				blockX = bx,blockY = by, blockZ = bz, bSelect=false, UseAbsolutePos = false, TeleportPlayer = false, nohistory = not bAddToUndoHistory})
			task:Run();
		end
	else
		LOG.std(nil, "warn", "Agent", "can not find agent (%d,%d,%d) file: %s", bx, by, bz, filename);
	end
end

--@param agentName: if nil, the current agent name is used. 
function Entity:ComputeAgentUrl(agentName, isGlobal)
	agentName = agentName or self:GetAgentName() or "";
	if(isGlobal == nil) then
		isGlobal = self:IsGlobal()
	end
	if(isGlobal) then
		local url = format("Mod/Agents/%s.xml", agentName);
		return url;
	else
		local remoteFolderName = GameLogic.options:GetRemoteWorldFolder();
		if(remoteFolderName) then
			local url = self:GetAgentUrl()
			if(url) then
				local projectid, username, worldname, subpath = url:match("^@(%d+):([^/]+)/([^/]+)/(.*)")
				if(projectid and projectid~="0") then
					url = format("@%s:%s/%s/agents/%s.xml", projectid, username, worldname, agentName);
					return url
				end
			end
			url = format("@%s:%sagents/%s.xml", GameLogic.options:GetProjectId() or 0, remoteFolderName, agentName);
			return url;
		end
	end
end

function Entity:GetSourceProjectId()
	local url = self:GetAgentUrl()
	if(url) then
		local projectid = url:match("^@(%d+)")
		if(projectid) then
			projectid = tonumber(projectid);
			if(projectid>0) then
				return projectid;
			end
		end
	end
end

-- agent url is [username]/[worldname]/agents/[agentfilename]
function Entity:ResetAgentUrl()
	local url = self:ComputeAgentUrl();
	if(url) then
		if(self:GetAgentUrl() ~= url) then
			self:SetAgentUrl(url);
			self:Refresh()
		end
	end
end

-- check if this agent belongs to the current world
function Entity:IsInCurrentWorld()
	local url = self:GetAgentUrl()
	if((not url or url== "") or self:GetSourceProjectId() == tonumber(GameLogic.options:GetProjectId() or 0)) then
		return true
	end
end

function Entity:Refresh()
	-- local and remote agent are displayed with different colors
	if(self:IsGlobal()) then
		self.text_color = "0 64 64";
	elseif(self:IsInCurrentWorld()) then
		self.text_color = "128 0 0";
	else
		self.text_color = "0 0 128";
	end

	return Entity._super.Refresh(self);
end

function Entity:CheckUpdateAgent()
	if(self:GetUpdateMethod() == "always") then
		self:UpdateAgent()
	end
end

function Entity:IsOfficialModAgents()
	local url = self:GetAgentUrl()
	if(url) then
		if(url:match("^Mod/Agents/")) then
			return true;
		end
	end
end

function Entity:UpdateAgent()
	if(Entity.isUpdating) then
		return
	end
	if(self:IsOfficialModAgents()) then
		local filename = self:GetAgentFilename()
		self:UpdateAgentFromDiskFile(filename)
	end
end

-- @return nil or {version="", agentName="", agentUrl="", ...}
function Entity:GetAgentInfoFromDiskFile(filename)
	local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
	if(xmlRoot) then
		local root_node = commonlib.XPath.selectNode(xmlRoot, "/pe:blocktemplate");
		if(root_node) then
			local node = commonlib.XPath.selectNode(root_node, "/pe:blocks");
			if(node and node[1]) then
				local blocks = NPL.LoadTableFromString(node[1]);
				if(blocks and #blocks>=1) then
					local b = blocks[1];
					if(b and b[4] == self:GetBlockId() and b[6]) then
						local serverData = b[6]
						if(serverData and serverData.attr) then
							return serverData.attr;
						end
					end
				end
			end
		end
	end
end

function Entity:IsNewerThanVersion(version)
	local myVersion = self:GetVersion();
	if(myVersion and version) then
		myVersion = tonumber(myVersion)
		version = tonumber(version)
		if(myVersion and version) then
			if(myVersion < version) then
				return false;
			end
		end
	end
	return true;
end

function Entity:UpdateAgentFromDiskFile(filename)
	if(ParaIO.DoesFileExist(filename, true)) then
		local agentInfo = self:GetAgentInfoFromDiskFile(filename);
		if(agentInfo and self:IsNewerThanVersion(agentInfo.version)) then
			-- do not update if current agent file is newer
			return;
		end
		commonlib.TimerManager.SetTimeout(function()  
			Entity.isUpdating = true;
			self:LoadFromAgentFile(filename);
			Entity.isUpdating = nil;
		end, 100)
	else
		LOG.std(nil, "warn", "Agent", "official mod agent file not found: %s", filename);
	end
end