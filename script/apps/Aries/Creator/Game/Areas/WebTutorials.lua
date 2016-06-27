--[[
Title: Web tutorials
Author(s): LiXizhi
Date: 2015/10/1
Desc: singleton class that hook to global user events and show relevant tutorials to the user. 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/WebTutorials.lua");
local WebTutorials = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.WebTutorials");
WebTutorials:Show();
WebTutorials:Dismiss();
WebTutorials:Close();
WebTutorials:Play();
WebTutorials:ShowWebWiki(word);
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Window.lua");
local Window = commonlib.gettable("System.Windows.Window")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local WebTutorials = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.WebTutorials"));
WebTutorials:Property("Name", "WebTutorials");
WebTutorials:Property({"filename", "config/Aries/creator/WebTutorials.xml"});
WebTutorials:Property({"CurrentTutorial", nil, auto=true});
WebTutorials:Property({"wiki_root", "https://github.com/LiXizhi/ParaCraft/wiki/"});
WebTutorials:Property({"isDirty", true, "IsDirty", "SetDirty"});

-- whenever the current tutorial is changed
WebTutorials:Signal("tutorialChanged", function(tutorial) end)

function WebTutorials:ctor()
	-- key to tutorial map
	self.tutorial_keymap = {};
	-- list of all tutorials
	self.tutorials = {};
	
	self:LoadTranslations();
	self:LoadAllTutorials();
	self.window = Window:new();
	self.window:SetCanDrag(true);
end

-- from user action to display text
function WebTutorials:LoadTranslations()
	self.translations = {
		["introduction"] = L"新手帮助",
		["select blocks"] = L"选择方块",
	};
end

function WebTutorials:Translate(title)
	return self.translations[title or ""] or title;
end

function WebTutorials:Init()
	self:InitSingleton();
end

function WebTutorials:GetWindow()
	return self.window;
end

function WebTutorials:Show()
	if(System.options.IsMobilePlatform) then
		return;
	end
	self:InitSingleton();
	self:AutoSelectTutorial();
	GameLogic:Connect("userActed", self, self.OnUserAction, "UniqueConnection");

	self.window:Show({
			url="script/apps/Aries/Creator/Game/Areas/WebTutorials.html", 
			zorder = 10,
			alignment="_lt", left = 5, top = 70, width = 400, height = 80,
		});
	self.window:SetSizeToUsedSize();
end

function WebTutorials:Hide()
	self:GetWindow():hide();
end

function WebTutorials:Dismiss()
	if(self:GetCurrent()) then
		self:GetCurrent():Dismiss();
	end
	self:Hide();
end

function WebTutorials:Close()
	GameLogic:Disconnect("userActed", self, self.OnUserAction);
	self:Hide();
end

--@param word: wiki_word or url
function WebTutorials:ShowWebWiki(word)
	self:InitSingleton();

	local url;
	if(word:find("^http")) then
		url = word;
	else
		url = self.wiki_root..word;
	end
	ParaGlobal.ShellExecute("open", url, "", "", 1);
end

-- obsoleted, now everything is loaded from wiki site
function WebTutorials:LoadAllTutorials()
	do 
		return
	end
	local xmlRoot = ParaXML.LuaXML_ParseFile(self.filename);
	if(not xmlRoot) then
		LOG.std(nil, "warn", "WebTutorials", "failed to open file %s", self.filename);
	end
	for node in commonlib.XPath.eachNode(xmlRoot, "/WebTutorials/tutorial") do
		local attr = node.attr;
		local url = attr.url;
		if(not url and node[1]) then
			url = node[1][1];
		end
		attr.title = L(attr.title);
		attr.difficulty = tonumber(attr.difficulty) or 0;
		attr.url = url;
		self:AddTutorial(attr);
	end
	LOG.std(nil, "info", "WebTutorials", "opened file %s, load %d tutorials", self.filename, #(self.tutorials));
end

local Tutorial = commonlib.inherit(nil);

function Tutorial:ctor()
	self.showcount = 0;
end

function Tutorial:init(title, url, difficulty)
	self.title = title or self.title;
	self.difficulty = difficulty or self.difficulty;
	self.url = url or self.url;
	return self;
end

function Tutorial:AddShowCount()
	self.showcount = self.showcount + 1;
end

function Tutorial:GetID()
	return self.title or "";
end

function Tutorial:GetTitle()
	return self.title or "";
end

function Tutorial:IsDismissed()
	return self.isDismissed;
end

function Tutorial:Dismiss()
	self.isDismissed = true;
end

function Tutorial:GetDifficultyText()
	if(self.difficulty>=4) then
		return L"困难";
	elseif(self.difficulty>=2) then
		return L"普通";
	else
		return L"容易";
	end
end

function Tutorial:GetTimeLengthText()
	return format(L"%s分钟", self.length or "5");
end

function Tutorial:Play()
	WebTutorials:ShowWebWiki(self.url);
end

function WebTutorials:GetTutorialByKey(keyname)
	return self.tutorial_keymap[keyname];
end

-- get array of all tutorials.
function WebTutorials:GetTutorialList()
	return self.tutorials;
end

function WebTutorials:AddTutorial(attr)
	local tutorial = Tutorial:new(attr):init();
	if(tutorial.keywords) then
		for keyword in tutorial.keywords:gmatch("%s*([^,;]+)") do
			self.tutorial_keymap[keyword] = tutorial;
		end
		self.tutorials[#(self.tutorials)+1] = tutorial;
	end
end

function WebTutorials:SetWiki(wiki)
	if(self.wiki ~= wiki) then
		self.wiki = wiki;
		self:SetDirty(true);
	end
end

function WebTutorials:SetDirty(isDirty)
	self.isDirty = isDirty;
end

function WebTutorials:SetTutorial(tutorial)
	if(self.currentTutorial ~= tutorial) then
		if(tutorial and tutorial:IsDismissed()) then
			return;
		end
		self.currentTutorial = tutorial;
		self:SetDirty(true);
		self:Update();
		self:tutorialChanged(tutorial); -- signal
	end
end

function WebTutorials:Update()
	if(self.isDirty) then
		self:SetDirty(false);
		if(self.window) then
			self.window:resize(400, 80);
			self.window:RefreshUrlComponent();
			self.window:SetSizeToUsedSize();
			self.window:show();
		end
	end
end

function WebTutorials:GetCurrent()
	return self.currentTutorial;
end

function WebTutorials:AutoSelectTutorial()
	self:InitSingleton();
	-- use last action or intruduction as the current tutorial 
	self:OnUserAction(GameLogic:GetLastUserAction() or "introduction");
end

function WebTutorials:Play()
	local tutorial = self:GetCurrent();
	if(tutorial) then
		tutorial:Play();
	end
end

-- @param name: action name
-- @return: a table of {title=string, url=string, wikiword=string}
function WebTutorials:GetWikiTutorialFromUserAction(name)
	local wiki = Tutorial:new();
	wiki.title = name;
	local wikiword = name:gsub("[%s%W]+", "_");
	local part1, part2 = name:match("^(%w+)%s+(.*)$");
	if(part1 == "take") then
		local itemName = part2;
		if(itemName) then
			local item = ItemClient.GetItemByName(itemName);
			if(item) then
				wiki.title = item:GetDisplayName();
				wikiword = "item_"..itemName;
			end
		end
	elseif(part1 == "cmd") then
		local cmd_name = part2:match("%w+")
		if(cmd_name) then
			wiki.title = format(L"命令 /%s", cmd_name);
			wikiword = "cmd_"..cmd_name;
		else
			return;
		end
	end
	wiki.title = self:Translate(wiki.title);
	wiki.url = self.wiki_root..wikiword;
	return wiki;
end

-- user has just acted on a given action. 
function WebTutorials:OnUserAction(name)
	local tutorial = self:GetWikiTutorialFromUserAction(name);
	-- Note: we no longer show local tutorial, all tutorial is wiki based now. 
	-- tutorial = self:GetTutorialByKey(name or "")
	if(tutorial) then
		self:SetTutorial(tutorial);
	end
end
