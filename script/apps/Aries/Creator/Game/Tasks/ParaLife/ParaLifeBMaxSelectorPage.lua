--[[
Title: ParaLifeBMaxSelectorPage
Author(s): hyz
Date: 2022/2/16
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeBMaxSelectorPage.lua");
local ParaLifeBMaxSelectorPage = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLifeBMaxSelectorPage");
ParaLifeBMaxSelectorPage.ShowPage(entity);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerAssetFile.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/CharGeosets.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerSkins.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/SkinPage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local SkinPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.SkinPage");
local PlayerSkins = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerSkins");
local CharGeosets = commonlib.gettable("MyCompany.Aries.Game.Common.CharGeosets");
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
local MouseEvent = commonlib.gettable("System.Windows.MouseEvent");
local ParaLifeBMaxSelectorPage = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLifeBMaxSelectorPage");
local Screen = commonlib.gettable("System.Windows.Screen");

local page;

function ParaLifeBMaxSelectorPage.OnInit()
	page = document:GetPageCtrl();
	GameLogic:Connect("WorldUnloaded", ParaLifeBMaxSelectorPage, ParaLifeBMaxSelectorPage.OnWorldUnload, "UniqueConnection");

	GameLogic.GetFilters():add_filter("DesktopModeChanged", ParaLifeBMaxSelectorPage.DesktopModeChanged);
	GameLogic.events:AddEventListener("ShowCreatorDesktop", ParaLifeBMaxSelectorPage.OnShowBuilderMenu, ParaLifeBMaxSelectorPage, "ParaLifeBMaxSelectorPage");
end

function ParaLifeBMaxSelectorPage.OnClosed()
	GameLogic.GetFilters():remove_filter("DesktopModeChanged", ParaLifeBMaxSelectorPage.DesktopModeChanged);
	GameLogic.events:RemoveEventListener("ShowCreatorDesktop", ParaLifeBMaxSelectorPage.Step6, ParaLifeBMaxSelectorPage);
end

function ParaLifeBMaxSelectorPage:DesktopModeChanged(mode)
	ParaLifeBMaxSelectorPage.ShowPage(false)
	return mode
end

function ParaLifeBMaxSelectorPage:OnShowBuilderMenu(event)
	if(event.bShow) then
		ParaLifeBMaxSelectorPage.ShowPage(false)
	end
end

function ParaLifeBMaxSelectorPage.OnPageLoaded()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeTouchController.lua");
	local ParaLifeTouchController = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLifeTouchController")

	local touchScreen = page:FindControl("touch_bg")
	if(touchScreen) then
		touchScreen:SetScript("onmousedown", function()
			local event = MouseEvent:init("mousePressEvent")
			ParaLifeTouchController.handleMouseEvent(event);
		end);
		touchScreen:SetScript("onmouseup", function()
			local event = MouseEvent:init("mouseReleaseEvent")
			ParaLifeTouchController.handleMouseEvent(event);
		end);
		touchScreen:SetScript("onmousemove", function()
			local event = MouseEvent:init("mouseMoveEvent")
			ParaLifeTouchController.handleMouseEvent(event);
		end);
		touchScreen:SetScript("ontouch", function()
			ParaLifeTouchController.handleTouchEvent(msg)
		end);
	end	

	if page and page:IsVisible() then
		local mcmlNode = page:GetNode("item_gridview");
		if ParaLifeBMaxSelectorPage.target_page then
			pe_gridview.GotoPage(mcmlNode, "item_gridview", ParaLifeBMaxSelectorPage.target_page);
			ParaLifeBMaxSelectorPage.target_page = nil
		end
		if mcmlNode==nil then 
			return
		end
		local tree_view = mcmlNode:GetChild("pe:treeview");
		if tree_view==nil then 
			return
		end
		local tree_view_control = tree_view.control
		local _parent = ParaUI.GetUIObject(tree_view_control.name);
		local main = _parent:GetChild(tree_view_control.mainName);
		main:SetScript("onmousewheel", function()
			local page_index = mcmlNode:GetAttribute("pageindex") or 1
			local target_page = page_index - mouse_wheel
			pe_gridview.GotoPage(mcmlNode, "item_gridview", target_page);
		end)
	end
	
	NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/CreatorDesktop.lua");
	local CreatorDesktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.CreatorDesktop");
	if(CreatorDesktop.IsExpanded) then
		CreatorDesktop.ShowNewPage(false);
	end
end

function ParaLifeBMaxSelectorPage.OnWorldUnload()
	GameLogic:Disconnect("WorldUnloaded", ParaLifeBMaxSelectorPage, ParaLifeBMaxSelectorPage.OnWorldUnload);
	ParaLifeBMaxSelectorPage.ShowPage(false)
end

function ParaLifeBMaxSelectorPage.ShowPage(bShow)
	if bShow==false then 
		if page then 
			page:CloseWindow()
			page = nil 
		end
		return 
	end
	ParaLifeBMaxSelectorPage.FindAll()
	
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeBMaxSelectorPage.html", 
			name = "ParaLifeBMaxSelectorPage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			enable_esc_key = true,
			bShow = true,
			click_through = false, 
			zorder = 0,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_rt",
				x = -362,
				y = -0,
				width = 362,
				height = 720,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	params._page.OnClose = ParaLifeBMaxSelectorPage.OnClosed;
    
end

function ParaLifeBMaxSelectorPage.FindAll()
	local entities = EntityManager.FindEntities({category="searchable",type = EntityManager.EntityLiveModel.class_name});
	if entities==nil then 
		return
	end
	for i=#entities,1,-1 do
		if entities[i]:IsOfType(EntityManager.EntityInvisibleClickSensor.class_name) then
			table.remove(entities,i)
		end
	end
	ParaLifeBMaxSelectorPage.SetResults(entities)
	ParaLifeBMaxSelectorPage.UpdateResult();
end

local find_history_filename = "find_liveModel_history.xml";
local find_history = {}
local lastHistoryFilename = nil;

function ParaLifeBMaxSelectorPage.SaveHistory()
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
				regionNode[#regionNode+1] = {name="entity", attr={text = entity.text,filename=entity.filename,scale=entity.scale, x = entity.x, y = entity.y, z = entity.z, id = entity.id}}
			end
		end
	end
	local xml_data = commonlib.Lua2XmlString(root, true, true) or "";
	local file = ParaIO.open(filename, "w");
	if(file:IsValid()) then
		file:WriteString(xml_data);
		file:close();
		LOG.std(nil, "info", "ParaLifeBMaxSelectorPage", "find block history saved to %s", filename);
	else
		LOG.std(nil, "error", "ParaLifeBMaxSelectorPage", "failed saved to %s", filename);
	end
	
	return true;
end

function ParaLifeBMaxSelectorPage:OnWorldUnload()
	lastHistoryFilename = nil;
	find_history = {}
end

-- return find history object.
function ParaLifeBMaxSelectorPage.GetHistory()
	local filename = GameLogic.GetWorldDirectory()..find_history_filename;
	if(lastHistoryFilename ~= filename) then
		lastHistoryFilename = filename;
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
							attr.scale = tonumber(attr.scale)
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
					ParaLifeBMaxSelectorPage.FindAll()
				end
			end, 1000)
		else
			LoadFromHistoryFile_(filename)
		end
	end
	return find_history;
end

function ParaLifeBMaxSelectorPage.GetRegionHistory(x, z)
	local history = ParaLifeBMaxSelectorPage.GetHistory()
	return history[x*1000+z];
end

function ParaLifeBMaxSelectorPage.SetRegionHistory(x, y, entities)
	local history = ParaLifeBMaxSelectorPage.GetHistory()
	history[x*1000+y] = entities;
end

--根据模型文件名去重
function ParaLifeBMaxSelectorPage._checkNeedAdd(resultDS,filename,skin)
	local filepath = PlayerAssetFile:GetValidAssetByString(filename);
	if not filepath then
		return false 
	end
	
	local contain = false
	for k,v in pairs(resultDS) do
		if v.attr.filename==filename then 
			if skin then
				if skin==v.attr.skin then 
					contain = true 
					break
				end
			else
				contain = true
				break
			end
		end
	end
	return not contain
end

-- set the results and merge with local file for unloaded regions
function ParaLifeBMaxSelectorPage.SetResults(entities)
	if(entities) then
		local resultDS = {};
		local results = {};
		local regions = {};
		for i, entity in ipairs(entities) do
			local item = entity:GetItemClass()
			local name = entity:GetDisplayName() or "";
			local filename = entity:GetModelFile()
			local scale = entity:GetScaling()

			local ReplaceableTextures, CCSInfoStr, CustomGeosets;
			local skin = nil
			if entity.HasCustomGeosets and entity:HasCustomGeosets() then 
				skin = entity:GetSkin()
			end

			if ParaLifeBMaxSelectorPage._checkNeedAdd(resultDS,filename,skin) then
				if(name == "" and entity.isPowered) then
					-- tricky: for unnamed, yet powered code block, we will list them
					name = "(powered)"
				end
				if(item and name~="") then
					name = name:gsub("\r?\n"," ")
					local index = #resultDS+1
					resultDS[index] = {name="block", attr={index=index,name=name, lowerText = string.lower(name),filename=filename,skin=skin,scale=scale, icon = item:GetIcon()}};
					results[index] = entity;
					local x, y, z = entity:GetBlockPos();
					local container = EntityManager.GetRegion(x, z);
					if(container) then
						local entitiesInRegion = regions[container];
						if(not entitiesInRegion) then
							entitiesInRegion = {}
							regions[container] = entitiesInRegion
						end
						entitiesInRegion[#entitiesInRegion+1] = {text=name,filename=filename,scale=scale,skin=skin, x=x, y=y, z=z, id=item.id, 
							sortKey = (x * 100000000 +  y * 1000000 + z)};
					end
				end
			end
		end
		ParaLifeBMaxSelectorPage.resultDS = resultDS;
		ParaLifeBMaxSelectorPage.results = results;

		if(not GameLogic.IsReadOnly() and not GameLogic.isRemote) then
			-- save to history file if anything in the region changes
			local history = ParaLifeBMaxSelectorPage.GetHistory()
			if(history) then
				local isHistoryModified;
				for region, entities in pairs(regions) do
					table.sort(entities, function(a, b)
						return a.sortKey < b.sortKey;
					end)
					local historyEntities = ParaLifeBMaxSelectorPage.GetRegionHistory(region.region_x, region.region_z)

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
						ParaLifeBMaxSelectorPage.SetRegionHistory(region.region_x, region.region_z, entities)
						isHistoryModified = true;
					end
				end
				if(isHistoryModified) then
					ParaLifeBMaxSelectorPage.SaveHistory();
				end
			end
		end
		local history = ParaLifeBMaxSelectorPage.GetHistory()
		if(history) then
			-- add entities that is in the history but not in regions
			local ids = {}
			for region, entities in pairs(regions) do
				ids[region.region_x*1000 + region.region_z] = true;
			end
			for id, entities in pairs(history) do
				if(not ids[id]) then
					for _, entity in ipairs(entities) do
						if ParaLifeBMaxSelectorPage._checkNeedAdd(resultDS,entity.filename,entity.skin) then
							local item = ItemClient.GetItem(entity.id)
							if(item) then
								local i = #results+1;
								results[i] = entity;
								resultDS[#resultDS+1] = {name="block", attr={index=i,name=entity.text,scale=entity.scale,skin=entity.skin,filename=entity.filename, lowerText = string.lower(entity.text), icon = item:GetIcon()}};
							end
						end
					end
				end
			end
		end
		table.sort(resultDS, function(a, b)
			return a.attr.lowerText < b.attr.lowerText;
		end);
	end
end

function ParaLifeBMaxSelectorPage.GetResultAt(index)
	if(index and ParaLifeBMaxSelectorPage.results) then
		return ParaLifeBMaxSelectorPage.results[index];
	end
end

function ParaLifeBMaxSelectorPage.FilterResult(text)
	
	if(text and text~="") then
		text = string.lower(text);
		local resultFiltered = {};
		for i, result in ipairs(ParaLifeBMaxSelectorPage.resultDS or {}) do
			if(result.attr.lowerText:find(text, 1, true)) then
				resultFiltered[#resultFiltered+1] = result;
			end
		end
		ParaLifeBMaxSelectorPage.filteredResultDS = resultFiltered;
	else
		ParaLifeBMaxSelectorPage.filteredResultDS = nil;
	end
	ParaLifeBMaxSelectorPage.SetSelectedIndex(1)
	ParaLifeBMaxSelectorPage.UpdateResult()
end

function ParaLifeBMaxSelectorPage.UpdateResult()
	ParaLifeBMaxSelectorPage.timerResult = ParaLifeBMaxSelectorPage.timerResult or commonlib.Timer:new({callbackFunc = function(timer)
		if(page) then
			page:CallMethod("item_gridview", "SetDataSource", ParaLifeBMaxSelectorPage.GetDataSource());
			page:CallMethod("item_gridview", "DataBind", true);
		end
	end})
	ParaLifeBMaxSelectorPage.timerResult:Change(10);
end

function ParaLifeBMaxSelectorPage.GetDataSource()
	return ParaLifeBMaxSelectorPage.filteredResultDS or ParaLifeBMaxSelectorPage.resultDS or {};
end

function ParaLifeBMaxSelectorPage.GetModelValue(index)
    local ds = ParaLifeBMaxSelectorPage.GetDataSource()
    local info = ds[index]
	local filepath = PlayerAssetFile:GetValidAssetByString(info.attr.filename);

	local ReplaceableTextures, CCSInfoStr, CustomGeosets;

	local skin = info.attr.skin
	if skin then
		CustomGeosets = skin
	elseif(PlayerAssetFile:IsCustomModel(filepath)) then
		CCSInfoStr = PlayerAssetFile:GetDefaultCCSString()
	elseif(PlayerSkins:CheckModelHasSkin(filepath)) then
		-- TODO:  hard code worker skin here
		ReplaceableTextures = {[2] = PlayerSkins:GetSkinByID(12)};
	end

    return {
        AssetFile = filepath, IsCharacter=true, x=0, y=0, z=0,
		ReplaceableTextures=ReplaceableTextures, CCSInfoStr=CCSInfoStr, CustomGeosets = CustomGeosets
    }
end

function ParaLifeBMaxSelectorPage.GetCameraDist(index)
    local ds = ParaLifeBMaxSelectorPage.GetDataSource()
    local info = ds[index]
	local dist = 3.5
	local scale = info and info.scale
	if scale then
		scale = mathlib.clamp(1/scale,0.6,1.8)
		-- dist = dist*scale
	end
    return dist
end

function ParaLifeBMaxSelectorPage.OnClickItem(index)
	local ds = ParaLifeBMaxSelectorPage.GetDataSource()
    local info = ds[index]
	index = info.attr.index
	local entity = ParaLifeBMaxSelectorPage.GetResultAt(index);

	local filepath = PlayerAssetFile:GetValidAssetByString(info.attr.filename);
	-- print("====filepath,class_name",info.attr.filename,entity.class_name)
	if entity then
		GameLogic.GetPlayerController():PickItemByEntity(entity,true);
	else
		--报错
	end
	ParaLifeBMaxSelectorPage.ShowPage(false)
end

function ParaLifeBMaxSelectorPage.OnDragEnd(name)
	local index = tonumber(name)
	
	local ds = ParaLifeBMaxSelectorPage.GetDataSource()
    local info = ds[index]
	index = info.attr.index
	local selectedEntity = ParaLifeBMaxSelectorPage.GetResultAt(index);
	if selectedEntity then 
		local newEntity = selectedEntity:CloneMe()
		newEntity:GetItemClass():StartDraggingEntity(newEntity)
		newEntity:GetItemClass():UpdateDraggingEntity(newEntity)
		newEntity:GetItemClass():DropDraggingEntity(newEntity,nil,nil,function()
			commonlib.TimerManager.SetTimeout(function()
				newEntity:SetDeadWithAllChildren()
			end,1)
		end);
	end
	
end