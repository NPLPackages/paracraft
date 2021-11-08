--[[
Title: building quest task
Author(s): LiXizhi, LiPeng
Date: 2013/11/13
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/HelpPage.lua");
local HelpPage = commonlib.gettable("MyCompany.Aries.Game.Tasks.HelpPage");
HelpPage.ShowPage();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildQuestTask.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildQuestProvider.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BuilderFramePage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandManager.lua");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BuilderFramePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BuilderFramePage");
local BuildQuest = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildQuest");
local BuildQuestProvider =  commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildQuestProvider");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local HelpPage = commonlib.gettable("MyCompany.Aries.Game.Tasks.HelpPage");

local type_ds = {
	{name = "type",attr = {text=L"新手教程",index = 1,category="tutorial", expanded = true}},
	--{name = "type",attr = {text=L"方块百科",index = 2,category="blockwiki"}},
	{name = "type",attr = {text=L"命令帮助",index = 2,category="command"}},
	{name = "type",attr = {text=L"快捷操作",index = 3,category="shortcutkey"}},
}
-- default to category="tutorial"
HelpPage.select_type_index = nil; -- can be nil 

local shortcurkey_ds = {};
local anim_ds = {};

local page;

-- @param category_name: can be nil, or "tutorial", "shortcutkey", etc
-- @param subfolder_name: can be nil or sub folder name, such as "MovieMaking", "newusertutorial", "programming", "circuit","smallstructure"
function HelpPage.ShowPage(category_name, subfolder_name)
	GameLogic.GetFilters():apply_filters("user_event_stat", "help", "browse:"..tostring(category_name)..":"..tostring(subfolder_name), 1, nil);

	System.App.Commands.Call("File.MCMLWindowFrame", {
		url = "script/apps/Aries/Creator/Game/Tasks/HelpPage.html", 
		name = "HelpPage.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = false,
		bShow = bShow,
		zorder = 1,
		directPosition = true,
		align = "_fi",
			x = 0,
			y = 0,
			width = 0,
			height = 0,
		DesignResolutionWidth = 1280,
		DesignResolutionHeight = 720,
	});

	local target_name
	if category_name == nil and subfolder_name == nil and HelpPage.OpenIndexStrList then
		target_name = HelpPage.OpenIndexStrList[1]

		category_name, subfolder_name = HelpPage.GetCategoryAndSubName(target_name);
		HelpPage.OpenIndexStrList = nil
	end

	HelpPage.SelectCategory(category_name, subfolder_name, target_name);

	if GameLogic.events then
		GameLogic.events:DispatchEvent({type = "ShowHelpPage"});
	end
end

function HelpPage.IsOpen()
	return page and page:IsVisible()
end

function HelpPage.ClosePage()
	if(page) then
		page:CloseWindow();
	end
end

-- @param index_or_name: category index number or string
-- @param subcategory_name: nil or sub category name
function HelpPage.SelectCategory(index_or_name, subcategory_name, grid_item_name)
	if(not index_or_name) then
		return
	end
	if(type(index_or_name) == "string") then
		local ds = HelpPage.GetHelpDS();
		if(ds) then
			for index, item in ipairs(ds) do
				if(item.attr and item.attr.category == index_or_name) then
					index_or_name = index;
				end
			end
		end
	end
	if(type(index_or_name) == "number") then
		local index = index_or_name;
		local ds = HelpPage.GetHelpDS();
		if(not ds or not ds[index]) then
			return;
		end
		if(HelpPage.select_type_index ~= index) then
			HelpPage.select_task_index = 1;
			HelpPage.select_item_index = 1;
		end

		HelpPage.select_type_index = index;

		-- instead of toggle, we will always select one category
		-- ds[index]["attr"]["expanded"] = not ds[index]["attr"]["expanded"];
		for i, item in ipairs(ds) do
			item.attr.expanded = (i == index)
		end
		
		

		if(subcategory_name) then
			for index, subitem in ipairs(ds[index]) do
				if(subitem and subitem.attr and subitem.attr.name == subcategory_name) then
					HelpPage.select_task_index = index;
					HelpPage.select_item_index = index;
				end
			end

			
			if grid_item_name then
				local grid_ds = BuildQuestProvider.GetTasks_DS(HelpPage.select_item_index,ds[index].attr.category)
				for i, grid_item in ipairs(grid_ds) do
					if grid_item.name == grid_item_name then
						HelpPage.select_task_index = i
						break
					end
				end
			end
		end
		HelpPage.OnTypeItemChanged();
		HelpPage.cur_category = HelpPage.GetCurrentCategory();

		-- GameLogic.GetFilters():apply_filters("user_event_stat", "help", "browse:"..tostring(HelpPage.cur_category), 1, nil);

		if(page) then
			page:Refresh(0.1);
		end
	end
end

function HelpPage.OnTypeItemChanged()
	HelpPage.cur_category = HelpPage.GetCurrentCategory();
	if(HelpPage.cur_category == "tutorial") then 
		BuildQuest.cur_theme_index = HelpPage.select_item_index or 1;
		BuildQuest.OnInit();
	end
end

function HelpPage.OnInit()
	page = document:GetPageCtrl();
	BuildQuestProvider.Init();

	HelpPage.cur_category = HelpPage.GetCurrentCategory();
	if(HelpPage.inited) then
		return;
	end
	
	HelpPage.select_type_index = HelpPage.select_type_index or 1;
	HelpPage.select_item_index = HelpPage.select_item_index or 1;
	HelpPage.OnInitDS();
	HelpPage.select_task_index = HelpPage.select_task_index or 1;
	HelpPage.inited = true;
end

--local blockTypes = {
	--{text="方块", index=1, name="static",     enabled=true},
	--{text="装饰", index=2, name="deco",       enabled=true},
	--{text="人物", index=3, name="character",  enabled=true},
	--{text="机关", index=4, name="gear",	     enabled=true},
--}

local function GetShortCutKeyDS()
	local filename = "config/Aries/creator/shortcutkey.xml";
	local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
	if(xmlRoot) then
		for node in commonlib.XPath.eachNode(xmlRoot, "/Items/Type") do
			if(node.attr and node.attr.name) then
				local type_ds = {name = L(node.attr.name)};
				shortcurkey_ds[#shortcurkey_ds + 1] = type_ds;
				local content = "";
				for itemnode in commonlib.XPath.eachNode(node, "/Item") do
					if(itemnode.attr and itemnode.attr.value and itemnode.attr.desc) then
						local text = string.format("<font style=';color:#ffc300;'>%s:</font>%s",L(itemnode.attr.value),L(itemnode.attr.desc));
						content = content..text.."<br/>";
					end
				end
				type_ds.content = content;
			end
		end
	end
	return shortcurkey_ds;
end

local function GetAnimDS()
	local filename = "config/Aries/creator/modelAnim.xml";
	local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
	if(xmlRoot) then
		for node in commonlib.XPath.eachNode(xmlRoot, "/anims/model") do
			if(node.attr and node.attr.text) then
				local type_ds = {name = L(node.attr.text)};
				anim_ds[#anim_ds + 1] = type_ds;
				local content = "";
				if(node.attr.desc) then
					local text = string.format("%s",L(node.attr.desc));
					content = content..text.."\n";
				end
				for itemnode in commonlib.XPath.eachNode(node, "/anim") do
					if(itemnode.attr and itemnode.attr.id and itemnode.attr.desc) then
						local text = string.format("%s:%s",L(itemnode.attr.id),L(itemnode.attr.desc));
						content = content..text.."\n";
					end
				end
				type_ds.content = content;
			end
		end
	end
	return anim_ds;
end

function HelpPage.OnInitDS()
	for i = 1,#type_ds do
		local typ = type_ds[i];
		local category;
		if(typ["attr"]) then
			typ["attr"]["select_item_index"] = 1;
			category = typ["attr"].category;
		end
		
		if(category == "tutorial" or category == "blockwiki") then
			local ds = BuildQuestProvider.GetThemes_DS(typ["attr"].category);
			for j = 1,#ds do
				local theme = ds[j];
				local item = {name="item",attr={name=theme.foldername, text=theme.name,item_index=j,type_index = i,category=typ["attr"]["category"]}}
				typ[#typ + 1] = item;
			end
		elseif(category == "command") then
			local ds = CommandManager:GetCmdTypeDS();
			local j = 1;
			for k,v in pairs(ds) do
				local item = {name="item",attr={name="cmd", text=k,item_index=j,type_index = i,category=typ["attr"]["category"],}}
				typ[#typ + 1] = item;
				j = j + 1;
			end
			-- add the model anim info;
			typ[#typ + 1] = {name="item",attr={name="actions", text=L"动作编号",item_index=j,type_index = i,category=typ["attr"]["category"],}};
		elseif(category == "shortcutkey") then
			typ[1] = {name="item",attr={name="shortcutkey", text=L"全部",item_index=1,type_index = i,category=typ["attr"]["category"],}}
		end
	end
end

function HelpPage.GetCurrentCategory(index)
	local ds = HelpPage.GetHelpDS();
	local category = ds[index or HelpPage.select_type_index or 1]["attr"]["category"];
	return category
end

function HelpPage.GetHelpDS()
	return type_ds;
end

function HelpPage.IsTutorialCategory()
    return (HelpPage.GetCurrentCategory() == "tutorial")
end

function HelpPage.IsBlockWikiCategory()
    return (HelpPage.GetCurrentCategory() == "blockwiki")
end

function HelpPage.IsCommandCategory()
    return (HelpPage.GetCurrentCategory() == "command")
end

function HelpPage.IsShortCutKeyCategory()
    return (HelpPage.GetCurrentCategory() == "shortcutkey")
end


function HelpPage.GetCurGridviewDS(name)
	local ds;
	if(HelpPage.IsCommandCategory()) then
		if(not name) then
			name = type_ds[HelpPage.select_type_index][1]["attr"]["text"];
		end
		local cmd_types = CommandManager:GetCmdTypeDS();
		ds = cmd_types[name] or {};
	else
		ds = {};
	end
	return ds;
end

function HelpPage.IsAnimItem(_index)
	local len = table.getn(type_ds[HelpPage.select_type_index]);
	local index = _index or HelpPage.select_item_index;
	if(len == index) then
		return true;
	end
	return false;
end

function HelpPage.GetGridview_DS(index)
	local ds;
	if(HelpPage.IsTutorialCategory() or HelpPage.IsBlockWikiCategory()) then
		ds = BuildQuestProvider.GetTasks_DS(HelpPage.select_item_index,HelpPage.cur_category);
	elseif(HelpPage.IsCommandCategory()) then
		if(HelpPage.IsAnimItem()) then
			if(not next(anim_ds)) then
				anim_ds = GetAnimDS(); 
			end
			ds = anim_ds;
		else
			if(not HelpPage.cur_gridview_ds) then
				HelpPage.cur_gridview_ds = HelpPage.GetCurGridviewDS();
			end
			ds = HelpPage.cur_gridview_ds;
		end
	elseif(HelpPage.IsShortCutKeyCategory()) then
		if(not next(shortcurkey_ds)) then
			shortcurkey_ds = GetShortCutKeyDS(); 
		end
		ds = shortcurkey_ds;
	end
	if(not ds) then
		return 0;
	end
	if(not index) then
		return #ds;
	else
		return ds[index];
	end
end

function HelpPage.ClosePage()
	if(page) then
		page:CloseWindow();
	end
end

function HelpPage.ChangeTask(name,mcmlNode)
    local attr = mcmlNode.attr;
    local task_index = tonumber(attr.param1);
    HelpPage.select_task_index = task_index;
	page:Refresh(0.1);
end

function HelpPage.GetShortCutKeyStr()
	local str = shortcurkey_ds[HelpPage.select_task_index or 1]["content"];
	return str;
end

function HelpPage.GetAnimStr()
	local str = anim_ds[HelpPage.select_task_index]["content"];
	return str;
end

-- 根据文本找索引
function HelpPage.SetSearchIndexStrList(str_list)
	-- str_list = { "新手小屋", "让角色向前行走" }
	HelpPage.SearchStrList = str_list
	HelpPage.OpenIndexStrList = str_list
end

-- 暂时只处理新手教程
function HelpPage.IsShowTypeLightFram(type_index,item_index)
	-- HelpPage.SearchStrList = { "新手小屋", "让角色向前行走" }
	if not HelpPage.SearchStrList or #HelpPage.SearchStrList == 0 then
		return false
	end
	local data_source = HelpPage.GetHelpDS()
	if not data_source[type_index] or data_source[type_index].attr.category ~= "tutorial" then
		return false
	end
	
	local ds = BuildQuestProvider.GetTasks_DS(item_index,"tutorial")
	for i, v in ipairs(ds) do
		for k2, v2 in pairs(HelpPage.SearchStrList) do
			if v.name == v2 then
				return true
			end
		end
	end
end

function HelpPage.IsShowGridLightFram(grid_index)
	-- HelpPage.SearchStrList = { "新手小屋", "让角色向前行走" }
	if not HelpPage.SearchStrList or #HelpPage.SearchStrList == 0 then
		return false
	end
	local data_source = HelpPage.GetHelpDS()
	local type_index = HelpPage.select_type_index
	if not type_index or not data_source[type_index] or data_source[type_index].attr.category ~= "tutorial" then
		return false
	end
	
	local item_index = HelpPage.select_item_index
	if not item_index then
		return false
	end

	local grid_ds = BuildQuestProvider.GetTasks_DS(item_index,"tutorial")
	local grid_item_data = grid_ds[grid_index]
	if not grid_item_data then
		return false
	end

	local name = grid_item_data.name
	for k2, v2 in pairs(HelpPage.SearchStrList) do
		if name == v2 then
			return true
		end
	end
end

function HelpPage.GetCategoryAndSubName(target_name)
	local data_source = HelpPage.GetHelpDS()
	-- 暂时只处理新手教程
	for i, v in ipairs(data_source) do
		if v.attr.category == "tutorial" then
			for i2, v2 in ipairs(v) do
				local grid_ds = BuildQuestProvider.GetTasks_DS(i2,"tutorial")
				for k, grid_item in pairs(grid_ds) do
					if grid_item.name == target_name then
						return i, v2.attr.name
					end
				end
			end
		end
	end
end