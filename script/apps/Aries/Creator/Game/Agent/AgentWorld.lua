--[[
Title: Agent World
Author(s): LiXizhi
Date: 2021/3/8
Desc: a simulated world in memory, in which we can add code blocks and movie block. 
Entities from agent world are created into the real world, however, the agent world itself does not take any real world space. 
We can load agent world from agent file (template file). 

This is also base class for a virtual BlockEngine.

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Agent/AgentWorld.lua");
local AgentWorld = commonlib.gettable("MyCompany.Aries.Game.Agent.AgentWorld");
local world = AgentWorld:new():Init("Mod/Agents/MacroPlatform.xml");
local world = AgentWorld:new():Init();
world:Run()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Agent/AgentEntityCode.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Agent/AgentEntityMovieClip.lua");
local AgentEntityCode = commonlib.gettable("MyCompany.Aries.Game.EntityManager.AgentEntityCode");
local AgentEntityMovieClip = commonlib.gettable("MyCompany.Aries.Game.EntityManager.AgentEntityMovieClip");
local EntityCode = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCode")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local AgentWorld = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Agent.AgentWorld"));

AgentWorld:Property({"centerPos", {0,0,0}, "GetCenterPosition", "SetCenterPosition", auto=true});

function AgentWorld:ctor()
	self.blocks = {};
	self.codeblocks = {};
	self.codeblockNames = {}; -- container of code block entity that does not have coordinates.
	self:SetCenterPosition({0, 0, 0})
end

function AgentWorld:Clear()
	for _, b in ipairs(self.codeblocks) do
		local entityCode = b.blockEntity;
		if(entityCode) then
			entityCode:Stop();
		end
	end
	for _, entity in pairs(self.codeblockNames) do
		local codeblock = entity:GetCodeBlock()
		if(codeblock and codeblock:IsLoaded()) then
			codeblock:Stop();
		end
	end

	self.blocks = {};
	self.codeblocks = {};
	self.codeblockNames = {};
end

-- @param filename: block template file name, it can be nil for empty world
function AgentWorld:Init(filename)
	GameLogic:Connect("WorldUnloaded", self, self.OnWorldUnload, "UniqueConnection");

	if(filename) then
		self:LoadFromAgentFile(filename);
	end
	return self;
end

function AgentWorld:GetSparseIndex(x, y, z)
	return y*900000000+x*30000+z;
end

-- convert from sparse index to block x,y,z
-- @return x,y,z
function AgentWorld:FromSparseIndex(index)
	local x, y, z;
	y = math.floor(index / (900000000));
	index = index - y*900000000;
	x = math.floor(index / (30000));
	z = index - x*30000;
	return x,y,z;
end

-- @param filename: agent xml or bmax or block template file. 
-- @param cx, cy, cz: center position where the entities in the agent world are created into the real world. default to 0. 
function AgentWorld:LoadFromAgentFile(filename, cx, cy, cz)
	
	self:SetCenterPosition({cx or 0, cy or 0, cz or 0})
	local blocks = self.blocks;
	local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
	if(xmlRoot) then
		local root_node = commonlib.XPath.selectNode(xmlRoot, "/pe:blocktemplate");
		if(root_node) then
			local px, py, pz = 0, 0, 0;
			if(root_node.attr and root_node.attr.pivot) then
				px, py, pz = root_node.attr.pivot:match("^(%d+)%D(%d+)%D(%d+)")
				px, py, pz = tonumber(px), tonumber(py), tonumber(pz)
			end
			local node = commonlib.XPath.selectNode(root_node, "/pe:blocks");
			if(node and node[1]) then
				local blocks_ = NPL.LoadTableFromString(node[1]);

				if(blocks_ and #blocks_>=1) then
					for _, b in ipairs(blocks_) do
						local blockId = b[4];
						local x, y, z = px + b[1], py + b[2], pz + b[3]
						blocks[self:GetSparseIndex(x, y, z)] = b;
						if(blockId == block_types.names.CodeBlock) then
							local entity = AgentEntityCode:new();
							entity:LoadFromXMLNode(b[6])
							entity:SetBlockEngine(self);
							b.blockEntity = entity;
							
							local attr = b[6] and b[6].attr;
							if(attr) then
								if(attr.isPowered == true or attr.isPowered == "true") then
									self.codeblocks[#(self.codeblocks) + 1] = b;
								end
							end
						elseif(blockId == block_types.names.MovieClip) then
							local entity = AgentEntityMovieClip:new();
							entity:LoadFromXMLNode(b[6])
							b.blockEntity = entity;
						end
					end
				end
			end
		end
	else
		LOG.std(nil, "warn", "AgentWorld", "failed to load template from file: %s", filename or "");
	end
end

-- simulate a BlockEngine interface
function AgentWorld:GetBlock(x, y, z)
	local blockId = self:GetBlockId(x, y, z)
	if(blockId) then
		return block_types.get(blockId);
	end
end


function AgentWorld:GetBlockId(x, y, z)
	if(x) then
		local index = self:GetSparseIndex(x, y, z)
		local b = self.blocks[index]
		if(b) then
			return b[4];
		end
	end
end

function AgentWorld:GetBlockData(x, y, z)
	if(x) then
		local index = self:GetSparseIndex(x, y, z)
		local b = self.blocks[index]
		if(b) then
			return b[5];
		end
	end
end

function AgentWorld:SetBlockData(x, y, z, data)
	-- dummy
end

function AgentWorld:GetBlockEntity(x, y, z)
	local index = self:GetSparseIndex(x, y, z)
	local b = self.blocks[index]
	if(b) then
		return b.blockEntity;
	end
end

function AgentWorld:NotifyNeighborBlocksChange(x, y, z, blockId)
end

function AgentWorld:Reset()
	self:Clear();
end

function AgentWorld:Destroy()
	self:Clear()
	AgentWorld._super.Destroy(self);
end

-- run all code blocks in the agent world
function AgentWorld:Run()
	for _, b in ipairs(self.codeblocks) do
		local entityCode = b.blockEntity;
		if(entityCode) then
			entityCode:SetPowered(true);
		end
	end
end

function AgentWorld:OnWorldUnload()
	-- unload virtual entities and free memory
	self:Clear()
end

--@param name: if nil, we will always create an unnamed empty code entity
function AgentWorld:CreateGetCodeEntity(name)
	local entity = name and self.codeblockNames[name];
	
	if(not entity) then
		entity = AgentEntityCode:new();
		entity:SetBlockEngine(self);
		entity:SetAllowFastMode(true);
		if(name) then
			self.codeblockNames[name] = entity;
		end
	end
	return entity;
end
