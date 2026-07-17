--[[
Title: code block
Author(s): LiXizhi
Date: 2023/5/30
Desc: it will automatically create a code block from text. the first few lines of text may contain options like "-- lang: test"
option lines are removed when set to code block. Supported options:
-- language: optional, default to npl, can be "npl", "clang", "commands", "cad", "python", "microbit", "mcml", etc
-- title: the title of the code block
-- actor: boolean, default to false. if true, it will create an actor entity in nearby movie block.
-- projectId: project id in which the code block is created.
-- name: codeblock name of the code entity. if not specified, it will be automatically generated based on the code index.

e.g. 

```codeblock
-- language: npl
-- title: test
-- actor: true
-- projectId: 530
-- name: MyName

say("hello world")
print("success")
```

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/TextToWorld/TextCodeBlock.lua");
local TextCodeBlock = commonlib.gettable("MyCompany.Aries.Game.Code.TextToWorld.TextCodeBlock")
local block = TextCodeBlock:new():Init(parent, 1)
-------------------------------------------------------
]]
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local names = commonlib.gettable("MyCompany.Aries.Game.block_types.names")

local TextCodeBlock = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Code.TextToWorld.TextCodeBlock"));

-- "codeblock|codecpp|codepython|codenpl"
TextCodeBlock:Property({"type", "codeblock", "GetType", "SetType", auto=true});
TextCodeBlock:Property({"index", 1, "GetIndex", "SetIndex", auto=true});
TextCodeBlock:Property({"spacing", 4, "GetSpacing", "SetSpacing", auto=true});
TextCodeBlock:Property({"parentTitle", nil, "GetParentTitle", "SetParentTitle", auto=true});

function TextCodeBlock:ctor()
end

function TextCodeBlock:Init(parentTextToWorld, index)
	self.parentTextToWorld = parentTextToWorld;
	self:SetIndex(index or 1)
	self.name = format("_codeblock_%d", self.index);
	self.globalName = nil;
	return self;
end

function TextCodeBlock:GetParentTitle()
	if(self.parentTitle == nil or self.parentTitle == "") then
		return format("# %d", self.index);
	else
		return self.parentTitle;
	end
end

-- project id string or nil
function TextCodeBlock:GetProjectId()
	local projectId = self:GetOption("projectId") or self:GetOption("pid");
	if(projectId and projectId ~= "") then
		return projectId;
	end
end

function TextCodeBlock:SetProjectId(projectId)
	if(self.projectId and self.projectId ~= "") then
		self:SetOption("projectId", self.projectId);
	else
		self:SetOption("projectId", nil);
	end
	self:SetOption("pid", nil);
end

function TextCodeBlock:GetName()
	return self:GetOption("name") or self.name;
end

function TextCodeBlock:AddLine(line)
	self.source = self.source or {};
	self.source[#self.source + 1] = line;
	self.sourceText = nil
	self.optionsDirty = true;
end

function TextCodeBlock:GetCommentChar()
	local language = self:GetLanguage();
	if (language == "clang" or language == "arduino" or language == "cpp") then
		return "//";
	elseif (language == "python" or language == "micropython") then
		return "#";
	else
		return "--";
	end
end

function TextCodeBlock:GetSourceText()
	if(not self.sourceText) then
		local language = self:GetLanguage();
		if (language == "clang" or language == "cpp" or language == "arduino" or language == "python" or language == "micropython") then
			local comment_char = self:GetCommentChar();
			local source = {};
			for i, line in ipairs(self.source or {}) do
				source[i] = string.gsub(line, "^%s*%-%-", comment_char);
			end
			self.sourceText = table.concat(source, "\n");
		else
			self.sourceText = self.source and table.concat(self.source, "\n") or "";
		end
	end
	return self.sourceText;
end

function TextCodeBlock:GetLanguage() 
	local options = self:GetOptions();
	return options.lang or options.language or options.guessLanguage or "npl";
end

function TextCodeBlock:Log(...)
	if(self.parentTextToWorld) then
		self.parentTextToWorld:Log(...)
	end
end

-- @return nil if we can not determine the type of language by the provided line of code. 
-- usually it is "commands|macros|clang", etc. 
function TextCodeBlock:GuessLanguageByLine(line)
	local guessLanguage;
	if(line) then
		if(line:match("^/%w")) then
			guessLanguage = "commands";
		elseif(line:match("^#include") or line:match("^%s*/%*") or line:match("^%s*//")) then
			guessLanguage = "clang";
		elseif(line:match("^from mpython import") ) then
			guessLanguage = "micropython";
		else
			local macroCommand = line:match("^(Set%w+)%(")
			if(macroCommand and (macroCommand == "SetMacroOrigin" or macroCommand == "SetAutoPlay")) then
				guessLanguage = "commands"; -- "macros"
			end
		end
	end
	return guessLanguage;
end

function TextCodeBlock:GetOption(name)
	local options = self:GetOptions();
	if(options) then
		return options[name];
	end
end

function TextCodeBlock:SetOption(name, value)
	local options = self:GetOptions();
	if(options) then
		options[name] = value;
	end
end

-- the first few lines may contain name, value pairs, like "-- lang: test", "-- language: cpp"
-- @param bRemoveOptionLines: if true, it will remove the first few option lines from the source.
-- even if options are not dirty
function TextCodeBlock:GetOptions(bRemoveOptionLines)
	local options = self.options;
	if(not options) then
		options = {};
		self.options = options;
	end
	if(self.optionsDirty or bRemoveOptionLines) then
		self.optionsDirty = nil;
		if(self.source) then
			local optionLineCount = 0
			for _, line in ipairs(self.source) do
				local name, value = line:match("^%s*%-%-%s*([%w_]+)%s*[=:]%s*(.*)$");
				if(name and value) then
					options[name] = value;
					optionLineCount = optionLineCount + 1
				elseif(line ~= "" and not line:match("^%s*%-%-")) then
					self.firstCodeLine = line;
					options.guessLanguage = self:GuessLanguageByLine(line)
					break
				end
			end
			if(bRemoveOptionLines and optionLineCount > 0) then
				-- remove the first few option lines
				self.source = commonlib.slice(self.source, optionLineCount+1, nil, true)
			end
		end
	end
	return self.options;
end

function TextCodeBlock:GetCodeEntity()
	return self.codeEntity;
end

function TextCodeBlock:FindCodeEntity(name)
	local entities = EntityManager.FindEntities({category="b", type="EntityCode"});
	if(entities) then
		for i, entity in ipairs(entities) do
			if(entity:GetDisplayName() == name) then
				return entity;
			end
		end
	end
end

function TextCodeBlock:SetLeverState(bOn)
	if(self.bx) then
		if(BlockEngine:GetBlockId(self.bx, self.by, self.bz-1) == names.Lever) then
			BlockEngine:SetBlock(self.bx, self.by, self.bz-1, names.Lever, bOn and 13 or 3, 3)
		end
	end
end

function TextCodeBlock:CreateSceneBlocks()
	local x, y, z = GameLogic.GetHomePosition()
	x, y, z = BlockEngine:block(x,y+0.1,z);
	x = x + self.index * self:GetSpacing()
	local options = self:GetOptions(true)
	local name = self:GetName()
	if(options.title) then
		self:SetParentTitle(options.title)
	end
	local hasActor;
	if(options.actor and options.actor ~= "false") then
		hasActor = true;
	end
	local codeEntity;
	local isExistingNamedBlock;
	local codename = self:GetOption("name")
	if(codename) then
		codeEntity = self:FindCodeEntity(codename)
		isExistingNamedBlock = codeEntity ~= nil;
	end
	if(not codeEntity) then
		BlockEngine:SetBlock(x, y, z, names.CodeBlock, 0, 3)
		BlockEngine:SetBlock(x, y, z-1, names.Lever, 5, 3)
		local nextZ = z + 1;
		if(hasActor) then
			BlockEngine:SetBlock(x, y, nextZ, names.MovieClip, 0, 3)
			local movieEntity = EntityManager.GetBlockEntity(x, y, nextZ)
			if(movieEntity and not movieEntity:GetFirstActorStack()) then
				movieEntity:CreateNPC();
			end
			nextZ = nextZ + 1;
		end
		BlockEngine:SetBlock(x, y, nextZ, names.Fence, 3, 3)
		BlockEngine:SetBlock(x, y+1, nextZ, names.Fence, 1, 3)
		BlockEngine:SetBlock(x-1, y+1, nextZ, names.Sign_Post, 1, 3, {attr={}, {name="cmd", self:GetParentTitle()}})

		codeEntity = EntityManager.GetBlockEntity(x, y, z)
	end
	if(codeEntity) then
		codeEntity:BeginEdit()
		if(not isExistingNamedBlock) then
			local language = self:GetLanguage();
			if (language == "python") then
				codeEntity:SetLanguageConfigFile("npl");
				codeEntity:SetCodeLanguageType("python");
			else
				codeEntity:SetLanguageConfigFile(self:GetLanguage())
			end
			codeEntity:SetDisplayName(name)
		end
		codeEntity:SetNPLCode(self:GetSourceText())
		if(codeEntity and codeEntity.SetOpenSource) then
			codeEntity:SetOpenSource(true);
		end
		codeEntity:EndEdit()
		codeEntity:remotelyUpdated();
	end
	self.codeEntity = codeEntity;
	if(codeEntity) then
		self.bx, self.by, self.bz = codeEntity:GetBlockPos();
	end
	self.isCompiled = false
	return codeEntity;
end

function TextCodeBlock:SetOutput(text)
	self.output = text;
	self:Log(text);
end

function TextCodeBlock:SetError(errMsg)
	self.hasError = true;
	self:SetOutput(errMsg)
	if(self.parentTextToWorld) then
		self.parentTextToWorld:codeblockFinished(self, self.output)
	end
end

-- @return true if succeed
function TextCodeBlock:Compile()
	self.hasError = false;
	if(self.type == "codeblock") then
		local codeEntity = self:CreateSceneBlocks();
		if(codeEntity) then
			self:Log("compiling %s", self:GetGlobalName());
			if(codeEntity:Compile()) then
				self.isCompiled = true;
				return true
			else
				self:SetError(codeEntity:GetCodeBlock():GetLastMessage());
			end
		end
	end
end

function TextCodeBlock:GotoThisBlock()
	if(self.bx) then
		EntityManager.GetPlayer():SetBlockPos(self.bx-1, self.by-1, self.bz+2)
		GameLogic.RunCommand("lookat", "~6 ~-3 ~")
	end
end

function TextCodeBlock:GetGlobalName()
	if(not self.globalName) then
		local entity = self:GetCodeEntity()
		if(entity) then
			self.globalName = string.format("textblock %s %d/%d: %s", entity:GetLanguageConfigFile() or "npl", self.index or 1, self:GetParentTotalBlocks(), self:GetParentTitle() or "")
		end
	end
	return self.globalName;
end

function TextCodeBlock:GetParentTotalBlocks()
	return self.parentTextToWorld and self.parentTextToWorld.nRunTo or 1;
end
-- @param callbackFunc: function(bSucceed) end
function TextCodeBlock:Run(callbackFunc)
	local entity = self:GetCodeEntity()
	if(entity and entity:GetDisplayName() == "" or not entity:GetDisplayName()) then
		self:GotoThisBlock()
	end
	if(entity and self.isCompiled) then
		GameLogic.AddBBS("TextCodeBlock", format(L"执行 %d: %s", self.index or 1, self:GetParentTitle() or ""), 5000, "255 255 0")
		local logs = {};
		-- TODO: find a better way to capture log
		commonlib.log.SetWriteLogCallback(function(text)
			if(text) then
				logs[#logs + 1] = text;
			end
		end)
		self.hasError = false;
		
		entity:Restart(function()
			-- when code is finished
			commonlib.log.SetWriteLogCallback(nil);
			if(#logs > 0) then
				local logtext = table.concat(logs, "")
				self:SetOutput(logtext);
			end
			
			self:Log("finished %s", self:GetGlobalName())
			if(not entity:IsPowered()) then
				self:SetLeverState(true);
			end
			if(self.parentTextToWorld) then
				self.parentTextToWorld:codeblockFinished(self, self.output)
			end
			if(callbackFunc) then
				callbackFunc(true)
			end	
		end);
	end
end
