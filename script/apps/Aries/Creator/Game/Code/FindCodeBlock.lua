--[[
Title: FindCodeBlock
Author(s): LiXizhi
Date: 2022/3/18
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/FindCodeBlock.lua");
local FindCodeBlock = commonlib.gettable("MyCompany.Aries.Game.Code.FindCodeBlock");
FindCodeBlock.Show(true, codeEntity, callbackFunc)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/FindBlockTask.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockWindow.lua");
local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local FindBlockTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.FindBlockTask");
local FindCodeBlock = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Code.FindCodeBlock"));

FindCodeBlock.resultDS = {};
FindCodeBlock.selectedIndex = 1;
FindCodeBlock.maxResultCount = 2000;

local page
function FindCodeBlock.OnInit()
	page = document:GetPageCtrl();
end

function FindCodeBlock.Show(bShow, codeEntity, callbackFunc)
	FindCodeBlock.filteredResultDS = nil;
	FindCodeBlock.resultDS = {};
	FindCodeBlock.selectedResultIndex = nil
	FindCodeBlock.lastGotoItemIndex = nil

	local width, height = 512, 400;
	local params = {
			url = "script/apps/Aries/Creator/Game/Code/FindCodeBlock.html", 
			name = "FindCodeBlock.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			zorder = 1,
			allowDrag = true,
			click_through = false, 
			enable_esc_key = true,
			bShow = true,
			---app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ctt",
				x = 0,
				y = 0,
				width = width,
				height = height,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	params._page.OnClose = function()
		page = nil;
		if(callbackFunc) then
			callbackFunc()
		end
	end
	if(bShow and not entities) then
		FindCodeBlock.FindAll();
	end
end

function FindCodeBlock.OnInit()
	page = document:GetPageCtrl();
end

function FindCodeBlock.FindAll()
	local entities = EntityManager.FindEntities({category="b", type="EntityCode"});
	FindCodeBlock.SetResults(entities)
	-- default to select the last code block if window is visible, otherwise select the current one. 
	FindCodeBlock.SetSelectedIndex(CodeBlockWindow.IsVisible() and 2 or 1)
	FindCodeBlock.UpdateResult();
end

-- set the results and merge with local file for unloaded regions
function FindCodeBlock.SetResults(entities)
	if(entities) then
		local resultDS = {};
		local results = {};
		local regions = {};
		local recentFiles = CodeBlockWindow.GetRecentOpenFiles()
		local showRecentFileCount = recentFiles and math.min(4, #recentFiles) or 0;
		for i, entity in ipairs(entities) do
			local item = entity:GetItemClass()
			local name = entity:GetDisplayName() or "";
			if(name == "" and entity.isPowered) then
				-- tricky: for unnamed, yet powered code block, we will list them
				name = "(powered)"
			end
			if(item and name~="") then
				local x, y, z = entity:GetBlockPos();
				local recentFileIndex;
				if(showRecentFileCount > 0) then
					for i=1, showRecentFileCount do
						local item = recentFiles[i]
						if(item.bx == x and item.by == y and item.bz==z) then
							recentFileIndex = i;
							break;
						end
					end
				end
				name = name:gsub("\r?\n"," ")
				if(recentFileIndex) then
					name = L"最近: "..name;
				end
				local index = #resultDS+1
				resultDS[index] = {name="block", attr={index=index,name=name, recentFileIndex = recentFileIndex, lowerText = string.lower(name), icon = item:GetIcon()}};
				results[index] = entity;
				
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
		FindCodeBlock.resultDS = resultDS;
		FindCodeBlock.results = results;
		
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
						local item = ItemClient.GetItem(entity.id)
						if(item and item.class_name == "ItemCodeBlock") then
							local i = #results+1;
							results[i] = entity;
							resultDS[#resultDS+1] = {name="block", attr={index=i,name=entity.text, lowerText = string.lower(entity.text), icon = item:GetIcon()}};
						end
					end
				end
			end
		end
		table.sort(resultDS, function(a, b)
			if(not a.attr.recentFileIndex and not b.attr.recentFileIndex) then
				return a.attr.lowerText < b.attr.lowerText;
			elseif(a.attr.recentFileIndex and b.attr.recentFileIndex) then
				return a.attr.recentFileIndex < b.attr.recentFileIndex;
			elseif(a.attr.recentFileIndex and not b.attr.recentFileIndex) then
				return true;
			else
				return false;
			end
		end);
	end
end

function FindCodeBlock.GetResultAt(index)
	if(index and FindCodeBlock.results) then
		return FindCodeBlock.results[index];
	end
end

function FindCodeBlock.FilterResult(text)
	if(text and text~="") then
		text = string.lower(text);
		local resultFiltered = {};
		for i, result in ipairs(FindCodeBlock.resultDS) do
			if(result.attr.lowerText:find(text, 1, true)) then
				resultFiltered[#resultFiltered+1] = result;
			end
		end
		FindCodeBlock.filteredResultDS = resultFiltered;
	else
		FindCodeBlock.filteredResultDS = nil;
	end
	FindCodeBlock.SetSelectedIndex(1)
	FindCodeBlock.UpdateResult()
end

function FindCodeBlock.UpdateResult()
	FindCodeBlock.timerResult = FindCodeBlock.timerResult or commonlib.Timer:new({callbackFunc = function(timer)
		if(page) then
			page:CallMethod("result", "SetDataSource", FindCodeBlock.GetDataSource());
			page:CallMethod("result", "DataBind", true);
		end
	end})
	FindCodeBlock.timerResult:Change(10);
end

function FindCodeBlock.GetDataSource()
	return FindCodeBlock.filteredResultDS or FindCodeBlock.resultDS;
end

function FindCodeBlock.OnClickItem(treenode)
	local item = treenode.mcmlNode:GetPreValue("this")
	local index = item.index;

	FindCodeBlock.SetSelectedIndexByResultIndex(index)
	local bTeleport = mouse_button == "right";
	FindCodeBlock.GotoItemAtIndex(index, bTeleport);
	
	FindCodeBlock.OnClose()
end


function FindCodeBlock.SetSelectedIndexByResultIndex(index)
	local ds = FindCodeBlock.GetDataSource()
	if(ds) then
		for i, item in ipairs(ds) do
			if(item.attr.index == index) then
				if(FindCodeBlock.selectedIndex ~= i) then
					FindCodeBlock.SetSelectedIndex(i)
				end
				break;
			end
		end
	end
end

function FindCodeBlock.GotoItemAtIndex(index, bTeleport)
	local entity = FindCodeBlock.GetResultAt(index);
	if(entity) then
		local x, y, z
		if(entity.GetBlockPos) then
			x, y, z = entity:GetBlockPos()
		elseif(entity.x and entity.y and entity.z) then
			x, y, z = entity.x, entity.y, entity.z
		end
		if(x) then
			if(bTeleport) then
				GameLogic.RunCommand(string.format("/goto %d %d %d", x, y, z));
			end
			if(entity.OpenEditor) then
				entity:OpenEditor("entity", EntityManager.GetPlayer())
				CodeBlockWindow.SetFocusToTextControl()
			end
		end
	end
end

function FindCodeBlock.OnClose()
	if(page) then
		page:CloseWindow();
		page = nil;
	end
end

function FindCodeBlock.OnKeyUp()
	local selectedIndex;
	if(virtual_key == Event_Mapping.EM_KEY_UP) then
		selectedIndex = FindCodeBlock.selectedIndex - 1;
	elseif(virtual_key == Event_Mapping.EM_KEY_DOWN) then	
		selectedIndex = FindCodeBlock.selectedIndex + 1;
	end
	if(selectedIndex) then
		if(selectedIndex and selectedIndex<1) then
			selectedIndex = 1;
		elseif(selectedIndex > #FindCodeBlock.GetDataSource()) then
			selectedIndex = #FindCodeBlock.GetDataSource();
		end
		FindCodeBlock.SetSelectedIndex(selectedIndex);
	end
end

function FindCodeBlock.GetSelectedIndex()
	return FindCodeBlock.selectedIndex or 1;
end

function FindCodeBlock.SetSelectedIndex(selectedIndex)
	if(FindCodeBlock.selectedIndex~=selectedIndex) then
		FindCodeBlock.selectedIndex = selectedIndex
	end
	local ds = FindCodeBlock.GetDataSource()
	if(ds and ds[FindCodeBlock.GetSelectedIndex()]) then
		FindCodeBlock.SetSelectedResultIndex(ds[FindCodeBlock.GetSelectedIndex()].attr.index)
	else
		FindCodeBlock.SetSelectedResultIndex(1)
	end
end

function FindCodeBlock.SetSelectedResultIndex(index)
	if(FindCodeBlock.selectedResultIndex ~= index) then
		FindCodeBlock.selectedResultIndex = index;
		if(page) then
			page:CallMethod("result", "ScrollToRow", FindCodeBlock.GetSelectedIndex());
		end
		FindCodeBlock.UpdateResult();
	end
end

function FindCodeBlock.GetSelectedResultIndex()
	return FindCodeBlock.selectedResultIndex or 1;
end

function FindCodeBlock.OnOpen()
	local bTeleport = mouse_button == "right";
	FindCodeBlock.GotoItemAtIndex(FindCodeBlock.GetSelectedResultIndex(), bTeleport);
	FindCodeBlock.OnClose();
end

function FindCodeBlock.OnTextChange()
	FindCodeBlock.timer = FindCodeBlock.timer or commonlib.Timer:new({callbackFunc = function(timer)
		if(page) then
			FindCodeBlock.FilterResult(page:GetValue("text"))
		end
	end})
	FindCodeBlock.timer:Change(500);
end