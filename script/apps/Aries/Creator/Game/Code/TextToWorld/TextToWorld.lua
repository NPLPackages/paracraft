--[[
Title: from text to world
Author(s): LiXizhi
Date: 2023/5/30
Desc: 
design doc: https://github.dev/tatfook/codelab3d/blob/main/paralab_design_doc.ipynb
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/TextToWorld/TextToWorld.lua");
local TextToWorld = commonlib.gettable("MyCompany.Aries.Game.Code.TextToWorld.TextToWorld")
local t2w = TextToWorld:new()
t2w:RunPage("https://keepwork.com/official/docs/tutorials/codelab")

cmd("/text2world https://keepwork.com/official/docs/tutorials/codelab")

local t2w = TextToWorld:new()
t2w:Connect("codeblockFinished", function(codeblock, textOutput)
	log(format(">>># %d: %s", codeblock:GetIndex(), (textOutput or "")))
end)
t2w:RunString("```codeblock\nprint('block1')\n```\n```codeblock\nprint('block2')\n```\n", 3) -- from pos 3

t2w:ResetWorld(function()  
	t2w:RunString("print('hello world')", 1)
end)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/TextToWorld/TextCodeBlock.lua");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon");
local TextCodeBlock = commonlib.gettable("MyCompany.Aries.Game.Code.TextToWorld.TextCodeBlock")

local TextToWorld = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Code.TextToWorld.TextToWorld"));
TextToWorld:Property({"logName", nil, "GetServiceLogName", "SetServiceLogName", auto=true})

-- when a single code block is finished
TextToWorld:Signal("codeblockFinished", function(textCodeBlock, outputText)  end)
-- wheh all code blocks are finished, when you call one of the runXXX function. 
TextToWorld:Signal("allFinished", function(allBlocks)  end)

-- default world name for temporary world, this is a readonly world. 
TextToWorld.prepareWorldName = "CodeLabTextWorld";

function TextToWorld:ctor()
end

function TextToWorld:Log(...)
	if(self.logName) then
		commonlib.servicelog(self.logName, ...);
	else
		LOG.std(nil, "info", "TextToWorld", ...)
	end
end

-- public method: run a page in markdown format.
function TextToWorld:RunPage(url) 
	self:Log("fetching: %s", url)
	GameLogic.KeepWork.GetRawFile(url, function(err, msg, data)
		if(data) then
			self:RunString(data)
		end
	end, "access plus 0 day")
	return self;
end

-- public method: parse a text string in markdown format into blocks.
-- @param text: it can be a single block without ``` or multiple blocks inside ```.
-- it is recommmended to wrap your code with ``` even for single block.
-- @param blocks: if nil, it will create a new table. otherwise it will append to the given table.
function TextToWorld:ParseText(text, blocks)
	blocks = blocks or {}
	local block = TextCodeBlock:new():Init(self, #blocks+1);
	local bInBlock = false;
	local nCount = 0;
	for line in text:gmatch("[^\r\n]+") do
		if(line:match("^```%w+")) then
			bInBlock = true;
			local codeType = line:match("^```(%w+)");
			block:SetType(codeType)
			blocks[#blocks+1] = block
			nCount = nCount + 1;
		elseif(line:match("^```%s*$")) then
			bInBlock = false;
			block = TextCodeBlock:new():Init(self, #blocks+1);
		elseif(bInBlock) then
			block:AddLine(line)
		elseif(line:match("^#+%s")) then
			local title = line:match("^#+%s*(.+)");
			block:SetParentTitle(title);
		end
	end
	if(nCount == 0) then
		-- for single block without ```
		local nIndex = #blocks+1
		blocks[nIndex] = block:Init(self, nIndex)
		
		block:SetType("codeblock") -- assume it is codeblock
		block:SetParentTitle(nil);

		for line in text:gmatch("[^\r\n]+") do
			block:AddLine(line)
		end
	end
	self.blocks = blocks;
	return blocks;
end

-- public: run a text string in markdown format. It may contain single or multiple text blocks.
-- @param nPosIndex: position index starting from 1, if nil, default to 1 
function TextToWorld:RunString(text, nPosIndex)
	nPosIndex = nPosIndex or 1;
	local blocks = {};
	if(nPosIndex > 1) then
		-- insert empty code text before nPosIndex
		for i = 1, nPosIndex-1 do
			blocks[i] = TextCodeBlock:new():Init(self, i)
		end
	end
	blocks = self:ParseText(text, blocks)
	if(blocks) then
		self:RunCodeBlocks(blocks, nPosIndex)
	end
	return self;
end

-- @param nFrom: from which block to run. default to 1
-- @param nTo: to which block to run. default to #blocks
function TextToWorld:RunCodeBlocks(blocks, nFrom, nTo)
	self.blocks = blocks or self.blocks;
	self.nRunFrom = nFrom or 1;
	self.nRunTo = nTo or #(self.blocks);

	self.curBlockIndex = self.nRunFrom;
	self:RunNextBlockImp();
	return self;
end

-- @param projectId: if nil, it will create a default empty world.
function TextToWorld:ResetWorld(callbackOnWorldLoaded, projectId)
	if(projectId) then
		self:PrepareProjectWorld(projectId, callbackOnWorldLoaded, true)
	else
		self:PrepareTextWorld(callbackOnWorldLoaded, true)
	end
end

-- only load the given project Id world if the current world is not the target world.
function TextToWorld:PrepareProjectWorld(projectId, callbackOnWorldLoaded, bForceRestart)
	projectId = tostring(projectId);
	if(not bForceRestart and projectId == tostring(GameLogic.options:GetProjectId())) then
		if(callbackOnWorldLoaded) then
			callbackOnWorldLoaded();
		end
		return
	end
	-- load the newly created empty flat world. 
	GameLogic.RunCommand(format('/loadworld -s %s', projectId));
	GameLogic.RunCommand("/clicktocontinue off");

	-- setup callback when world is fully loaded. 
	self.callbackOnWorldLoaded = callbackOnWorldLoaded;
	GameLogic:Connect("WorldInitialRegionsLoaded", self, self.OnWorldRegionLoaded, "UniqueConnection");

	self:Log("prepare and load world: %s", projectId)
end

-- only create a new world when the world is not created unless bForceRestart is true.
-- @param callbackOnWorldLoaded: called when world is loaded.
function TextToWorld:PrepareTextWorld(callbackOnWorldLoaded, bForceRestart)
	if(not bForceRestart and self.prepareWorldName == WorldCommon.GetWorldTag("name")) then
		if(callbackOnWorldLoaded) then
			callbackOnWorldLoaded();
		end
		return
	end

	-- create a new world replacing existing one
	local worldpath = ParaIO.GetWritablePath().."temp/"..self.prepareWorldName;
	GameLogic.RunCommand(format('/newworld %s -force', worldpath));
	
	-- load the newly created empty flat world. 
	GameLogic.RunCommand(format('/loadworld -e -s %s', worldpath));
	GameLogic.RunCommand("/clicktocontinue off");

	-- setup callback when world is fully loaded. 
	self.callbackOnWorldLoaded = callbackOnWorldLoaded;
	GameLogic:Connect("WorldInitialRegionsLoaded", self, self.OnWorldRegionLoaded, "UniqueConnection");

	self:Log("prepare and load world: %s", worldpath)
end

function TextToWorld:OnWorldRegionLoaded()
	GameLogic:Disconnect("WorldLoaded", self, self.OnWorldRegionLoaded, "UniqueConnection");
	if(self.prepareWorldName == WorldCommon.GetWorldTag("name")) then
		System.World.readonly = true;
	end

	GameLogic.Macros:PrepareInitialBuildState()

	-- tricky: we will allow anonymous user to edit the world.
	System.User.isAnonymousWorld = false;
	-- GameLogic.RunCommand("/mode edit");

	if(self.callbackOnWorldLoaded) then
		self.callbackOnWorldLoaded();
		self.callbackOnWorldLoaded = nil;
	end
	return true
end

function TextToWorld:RunNextBlockImp()
	local block = self.blocks[self.curBlockIndex]
	if(block) then
		local function onWorldPrepared_()
	
			System.options.InText2WorldMode = true;
			if(block:Compile()) then
				block:Run(function(bSucceed)
					if(bSucceed) then
						self.curBlockIndex = self.curBlockIndex + 1;
						if(not self.nRunTo or self.curBlockIndex <= self.nRunTo) then
							self:RunNextBlockImp();
						end
					end
					System.options.InText2WorldMode = nil;
				end);
			end
		end
		local projectId = block:GetProjectId();
		if(projectId) then
			self:PrepareProjectWorld(projectId, onWorldPrepared_);
		else
			self:PrepareTextWorld(onWorldPrepared_);
		end
	else
		self:allFinished(self.blocks);
	end
end
