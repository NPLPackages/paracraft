--[[
Title: Code Library
Author(s): LiXizhi
Date: 2022/5/2
Desc:  A library is a group of code blocks in the form of files. These files are usually organized in a folder with the same name of the library. 
for example, when import("abc"), we will load all files in ./lib/abc/*.* as code blocks. These code blocks are loaded only once in a given world, 
but can be imported multiple times. When the last code block that is importing a library is stopped, the imported libary will be unloaded. 
This also makes debugging a library easy by just restarting the code block that referenced it. 
When importing a lib, we will first search in the current world directory's ./lib folder for a given library, and then in system library folder, which is ..Game/Code/lib folder.
The advantage of using library is for making the scene cleaner than placing code blocks.

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeLibrary.lua");
local CodeLibrary = commonlib.gettable("MyCompany.Aries.Game.Code.CodeLibrary");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Agent/AgentWorld.lua");
local AgentWorld = commonlib.gettable("MyCompany.Aries.Game.Agent.AgentWorld");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local CodeLibrary = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Code.CodeLibrary"));

function CodeLibrary:ctor()
	-- all active code blocks referencing this library
	self.refCodeblocks = {};
end

function CodeLibrary:Init(libName)
	self.libName = libName;
	self:UpdateFiles()
	if(self:IsEmpty()) then
		LOG.std(nil, "warn", "CodeLibrary", "failed to find code block library %s", self:GetName());
	end
	return self;
end

function CodeLibrary:IsEmpty()
	return not self.files or (#(self.files) == 0);
end

function CodeLibrary:GetRootPath()
	return self.rootPath;
end

function CodeLibrary:GetFiles()
	return self.files;
end

function CodeLibrary:UpdateFiles()
	local rootPath = "lib/"..self.libName.."/";
	local files = Files:FindWorldFiles(nil, rootPath, 1, 500, "script");
	if(#files == 0) then
		-- TODO: search in bin folder as well: filepath = "bin/"..string.gsub(filename, "lua$", "o")
		rootPath = "script/apps/Aries/Creator/Game/Code/"..rootPath;
		files = Files:FindSystemFiles(nil, rootPath, 1, 500, "script");
	end	
	self.files = files;
	self.rootPath = rootPath;
end

-- add a referencing code block. when all code blocks are unloaded, the library is also unloaded. 
function CodeLibrary:AddReference(codeblock)
	if(codeblock and codeblock:IsLoaded() and not self.refCodeblocks[codeblock]) then
		self.refCodeblocks[codeblock] = true;
		codeblock:Connect("codeUnloaded", function()
			self.refCodeblocks[codeblock] = nil;
			if(next(self.refCodeblocks) == nil) then
				self:Stop();
			end
		end)
	end
	return self;
end

function CodeLibrary:GetName()
	return self.libName;
end

-- in in-memory agent block world, that only exists in memory and has nothing to do with the actual block world.
function CodeLibrary:GetAgentWorld()
	if(not self.agentWorld) then
		self.agentWorld = AgentWorld:new():Init();
	end
	return self.agentWorld;
end

-- memory code block has no position and only exists virtualy(not rendered)
-- @param name: default to "CodeGlobals". 
function CodeLibrary:CreateGetMemoryCodeBlock(name)
	name = name or "CodeGlobals"
	local world = self:GetAgentWorld()
	local entity = world:CreateGetCodeEntity(name)
	if(entity) then
		return entity:GetCodeBlock(true);
	end
end

function CodeLibrary:Start()
	if(not self.isStarted) then
		self.isStarted = true;
		if(self.files) then
			for i, item in ipairs(self.files) do
				local code;
				local filename = self.rootPath..item.filename;
				local file = ParaIO.open(filename, "r")
				if(file:IsValid()) then
					code = file:GetText(0, -1);
					file:close()
				end
				if(code) then
					local name = item.filename:gsub("%.%w%w%w$","")
					local codeblock = self:CreateGetMemoryCodeBlock(self:GetName().."."..name)
					codeblock:SetFilename(filename)
					codeblock:GetEntity():SetCommand(code)
					codeblock:Run();
				end
			end
			LOG.std(nil, "info", "CodeLibrary", "%s is loaded from %s with %d files", self:GetName(), self:GetRootPath(), #(self:GetFiles()));
		end
	end
end

function CodeLibrary:Restart()
	self:Stop()
	self:Start();
end

function CodeLibrary:IsStarted()
	return self.isStarted;
end

function CodeLibrary:Stop()
	if(self.isStarted) then
		self.isStarted = false;
		LOG.std(nil, "info", "CodeLibrary", "%s is unloaded", self:GetName());
		self:GetAgentWorld():Clear();
	end
end

