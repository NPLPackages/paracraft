--[[
Title: Find Block Task Command
Author(s): LiXizhi
Date: 2019/6/10
Desc: Ctrl+F to activate this dialog.

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/FindBlockTask.lua");
local FindBlockTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.FindBlockTask");
local task = MyCompany.Aries.Game.Tasks.FindBlockTask:new()
task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local FindBlockTask = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.FindBlockTask"));

-- whether to suppress any gui pop up. 
FindBlockTask:Property({"text", nil, "GetText", "SetText", auto=true});

FindBlockTask.resultDS = {};
FindBlockTask.selectedIndex = 1;
function FindBlockTask:ctor()
end

local page
function FindBlockTask.OnInit()
	page = document:GetPageCtrl();
end

function FindBlockTask:ShowPage(bShow)
	curInstance = self;
	FindBlockTask.filteredResultDS = nil;
	FindBlockTask.resultDS = {};
	FindBlockTask.selectedResultIndex = nil
	local width, height = 512, 400;
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Tasks/FindBlockTask.html", 
			name = "FindBlockTask.ShowPage", 
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			isShowTitleBar = false,
			bShow = bShow,
			DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
			style = CommonCtrl.WindowFrame.ContainerStyle,
			zorder = 1,
			allowDrag = true,
			enable_esc_key = true,
			directPosition = true,
				align = "_ctt",
				x = 0,
				y = 0,
				width = width,
				height = height,
		});
	if(bShow) then
		FindBlockTask.FindAll();
	end
end


-- @param bIsDataPrepared: true if data is prepared. if nil, we will prepare the data from input params.
function FindBlockTask:Run()
	self:ShowPage(true);
end

function FindBlockTask.FindAll()
	local entities = EntityManager.FindEntities({category="searchable", });
	FindBlockTask.SetResults(entities)
	FindBlockTask.UpdateResult();
end

local find_history_filename = "find_history.xml";
local find_history = {}
local lastHistoryFilename = nil;

function FindBlockTask.SaveHistory()
	local filename = GameLogic.GetWorldDirectory()..find_history_filename;
	local root = {name='regions', attr={file_version="0.1"} }
	for id, region in pairs(find_history) do
		if(#region > 0) then
			local region_x = math.floor(id / 1000)
			local region_z = id%1000;
			local regionNode = {name="region", attr={region_x = region_x, region_z = region_z}}
			root[#root+1] = regionNode;
			for i=1, #region do 
				local entity = region[i];
				regionNode[#regionNode+1] = {name="entity", attr={text = entity.text, x = entity.x, y = entity.y, z = entity.z, id = entity.id}}
			end
		end
	end
	local xml_data = commonlib.Lua2XmlString(root, true, true) or "";
	local file = ParaIO.open(filename, "w");
	if(file:IsValid()) then
		file:WriteString(xml_data);
		file:close();
		LOG.std(nil, "info", "FindBlockTask", "find block history saved to %s", filename);
	else
		LOG.std(nil, "error", "FindBlockTask", "failed saved to %s", filename);
	end
	
	return true;
end

function FindBlockTask:OnWorldUnload()
	lastHistoryFilename = nil;
	find_history = {}
end

-- return find history object.
function FindBlockTask.GetHistory()
	local filename = GameLogic.GetWorldDirectory()..find_history_filename;
	if(lastHistoryFilename ~= filename) then
		lastHistoryFilename = filename;
		GameLogic:Connect("WorldUnloaded", FindBlockTask, FindBlockTask.OnWorldUnload, "UniqueConnection")
		find_history = {}

		local function LoadFromHistoryFile_(filename)
			local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
			if(xmlRoot) then
				for node in commonlib.XPath.eachNode(xmlRoot, "/regions/region") do
					local x, z = node.attr.region_x, node.attr.region_z;
					local region = {region_x = tonumber(x), region_z = tonumber(z)}
					find_history[x*1000+z] = region;
					for i=1, #node do 
						local attr = node[i].attr;
						if(attr) then
							attr.id = tonumber(attr.id)
							attr.x = tonumber(attr.x)
							attr.y = tonumber(attr.y)
							attr.z = tonumber(attr.z)
							region[#region+1] = attr;
						end
					end
				end
			end	
		end
		
		if(GameLogic.isRemote) then
			Files.GetRemoteWorldFile(find_history_filename);
			commonlib.TimerManager.SetTimeout(function()  
				LoadFromHistoryFile_(filename)
				if(page) then
					FindBlockTask.FindAll()
				end
			end, 1000)
		else
			LoadFromHistoryFile_(filename)
		end
	end
	return find_history;
end

function FindBlockTask.GetRegionHistory(x, z)
	local history = FindBlockTask.GetHistory()
	return history[x*1000+z];
end

function FindBlockTask.SetRegionHistory(x, y, entities)
	local history = FindBlockTask.GetHistory()
	history[x*1000+y] = entities;
end


-- set the results and merge with local file for unloaded regions
function FindBlockTask.SetResults(entities)
	if(entities) then
		local resultDS = {};
		local regions = {};
		for i, entity in ipairs(entities) do
			local item = entity:GetItemClass()
			local name = entity:GetDisplayName();
			if(item and name and name~="") then
				name = name:gsub("\r?\n"," ")
				resultDS[#resultDS+1] = {name="block", attr={index=i,name=name, lowerText = string.lower(name), icon = item:GetIcon()}};
				
				local x, y, z = entity:GetBlockPos();
				local container = EntityManager.GetRegion(x, z);
				if(container) then
					local entitiesInRegion = regions[container];
					if(not entitiesInRegion) then
						entitiesInRegion = {}
						regions[container] = entitiesInRegion
					end
					entitiesInRegion[#entitiesInRegion+1] = {text=name, x=x, y=y, z=z, id=item.id, 
						sortKey = (x * 100000000 +  y * 1000000 + z)};
				end
			end
		end
		FindBlockTask.resultDS = resultDS;
		FindBlockTask.results = entities;

		if(not GameLogic.IsReadOnly() and not GameLogic.isRemote) then
			-- save to history file if anything in the region changes
			local history = FindBlockTask.GetHistory()
			if(history) then
				local isHistoryModified;
				for region, entities in pairs(regions) do
					table.sort(entities, function(a, b)
						return a.sortKey < b.sortKey;
					end)
					local historyEntities = FindBlockTask.GetRegionHistory(region.region_x, region.region_z)

					local allMatch = true;
					if(historyEntities and #historyEntities==#entities) then
						for i=1, #entities do
							local a, b = entities[i], historyEntities[i]
							if(a.text ~= b.text or a.x~=b.x or a.y~=b.y or a.z~=b.z ) then
								allMatch = false;
								break;
							end
						end
					else
						allMatch = false
					end
					if(not allMatch) then
						FindBlockTask.SetRegionHistory(region.region_x, region.region_z, entities)
						isHistoryModified = true;
					end
				end
				if(isHistoryModified) then
					FindBlockTask.SaveHistory();
				end
			end
		end
		local history = FindBlockTask.GetHistory()
		if(history) then
			-- add entities that is in the history but not in regions
			local ids = {}
			for region, entities in pairs(regions) do
				ids[region.region_x*1000 + region.region_z] = true;
			end
			for id, entities in pairs(history) do
				if(not ids[id]) then
					for _, entity in ipairs(entities) do
						local i = #resultDS+1;
						local item = ItemClient.GetItem(entity.id)
						if(item) then
							resultDS[i] = {name="block", attr={index=i,name=entity.text, lowerText = string.lower(entity.text), icon = item:GetIcon()}};
							FindBlockTask.results[i] = entity;
						end
					end
				end
			end
		end
	end
end

function FindBlockTask.GetResultAt(index)
	if(index and FindBlockTask.results) then
		return FindBlockTask.results[index];
	end
end

function FindBlockTask.FilterResult(text)
	
	if(text and text~="") then
		text = string.lower(text);
		local resultFiltered = {};
		for i, result in ipairs(FindBlockTask.resultDS) do
			if(result.attr.lowerText:match(text)) then
				resultFiltered[#resultFiltered+1] = result;
			end
		end
		FindBlockTask.filteredResultDS = resultFiltered;
	else
		FindBlockTask.filteredResultDS = nil;
	end
	FindBlockTask.SetSelectedIndex(1)
	FindBlockTask.UpdateResult()
end

function FindBlockTask.UpdateResult()
	FindBlockTask.timerResult = FindBlockTask.timerResult or commonlib.Timer:new({callbackFunc = function(timer)
		if(page) then
			page:CallMethod("result", "SetDataSource", FindBlockTask.GetDataSource());
			page:CallMethod("result", "DataBind", true);
		end
	end})
	FindBlockTask.timerResult:Change(10);
end

function FindBlockTask.GetDataSource()
	return FindBlockTask.filteredResultDS or FindBlockTask.resultDS;
end

function FindBlockTask.OnClickItem(treenode)
	local index = treenode.mcmlNode:GetPreValue("this").index;

	FindBlockTask.SetSelectedResultIndex(index)
	FindBlockTask.OpenItemAtIndex(index);

	if(mouse_button == "left") then
		FindBlockTask.OnClose()
	end
end

function FindBlockTask.OpenItemAtIndex(index)
	local entity = FindBlockTask.GetResultAt(index);
	if(entity) then
		local x, y, z
		if(entity.GetBlockPos) then
			x, y, z = entity:GetBlockPos()
		elseif(entity.x and entity.y and entity.z) then
			x, y, z = entity.x, entity.y, entity.z
		end
		if(x) then
			GameLogic.RunCommand(string.format("/goto %d %d %d", x, y, z));
		end
	end
end

function FindBlockTask.OnClose()
	if(page) then
		page:CloseWindow();
		page = nil;
	end
end

function FindBlockTask.OnKeyUp()
	local selectedIndex;
	if(virtual_key == Event_Mapping.EM_KEY_UP) then
		selectedIndex = FindBlockTask.selectedIndex - 1;
	elseif(virtual_key == Event_Mapping.EM_KEY_DOWN) then	
		selectedIndex = FindBlockTask.selectedIndex + 1;
	end
	if(selectedIndex) then
		if(selectedIndex and selectedIndex<1) then
			selectedIndex = 1;
		elseif(selectedIndex > #FindBlockTask.GetDataSource()) then
			selectedIndex = #FindBlockTask.GetDataSource();
		end
		FindBlockTask.SetSelectedIndex(selectedIndex);
	end
end

function FindBlockTask.GetSelectedIndex()
	return FindBlockTask.selectedIndex or 1;
end

function FindBlockTask.SetSelectedIndex(selectedIndex)
	if(FindBlockTask.selectedIndex~=selectedIndex) then
		FindBlockTask.selectedIndex = selectedIndex
	end
	local ds = FindBlockTask.GetDataSource()
	if(ds and ds[FindBlockTask.GetSelectedIndex()]) then
		FindBlockTask.SetSelectedResultIndex(ds[FindBlockTask.GetSelectedIndex()].attr.index)
	else
		FindBlockTask.SetSelectedResultIndex(1)
	end
end

function FindBlockTask.SetSelectedResultIndex(index)
	if(FindBlockTask.selectedResultIndex ~= index) then
		FindBlockTask.selectedResultIndex = index;
		if(page) then
			page:CallMethod("result", "ScrollToRow", FindBlockTask.GetSelectedIndex());
		end
		FindBlockTask.UpdateResult();
	end
end

function FindBlockTask.GetSelectedResultIndex()
	return FindBlockTask.selectedResultIndex or 1;
end

function FindBlockTask.OnOpen()
	FindBlockTask.OpenItemAtIndex(FindBlockTask.GetSelectedResultIndex());
	FindBlockTask.OnClose();
end

function FindBlockTask.OnTextChange()
	FindBlockTask.timer = FindBlockTask.timer or commonlib.Timer:new({callbackFunc = function(timer)
		if(page) then
			FindBlockTask.FilterResult(page:GetValue("text"))
		end
	end})
	FindBlockTask.timer:Change(500);
end