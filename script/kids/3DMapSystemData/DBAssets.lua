--[[
Title: map 3d system database table for assets
Author(s): WangTian
Date: 2007/10/19
use the lib:
Note: call Map3DSystem.DB.ExportAllGroupsToAssetPackage() to export as asset file. 
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemData/DBAssets.lua");
------------------------------------------------------------

]]

if(not Map3DSystem.DB) then Map3DSystem.DB = {} end

-- items in groups, mapping from groupname to an array of items in that group. 
-- see DBAssets_backup_old_assetfile.lua for sample data. 
Map3DSystem.DB.Items = {};

-- predefined level 1 group. 
Map3DSystem.DB.Groups = {
	{
		["name"] = "Normal Model",
		["parent"] = "Root",
		["rootpath"] = "model/",
		["text"] = "普通模型", -- TODO: translation and the icon, text and tooltip set to normal model
		icon = "Texture/3DMapSystem/MainBarIcon/Creator/LargeBuilding.png",
		--tooltip = L"asset_tooltip_building",
	},
	{
		["name"] = "BCS",
		["parent"] = "Root",
		["rootpath"] = "model/v3/components/",
		["text"] = "建筑部件",  -- TODO: translation and the icon, text and tooltip set to BCS
		icon = "Texture/3DMapSystem/MainBarIcon/Creator/Chimney.png",
		--tooltip = L"asset_tooltip_character",
	},
	{
		["name"] = "Normal Character",
		["parent"] = "Root",
		["rootpath"] = "character/",
		["text"] = "普通人物", -- TODO: translation and the icon, text and tooltip set to normal character
		icon = "Texture/3DMapSystem/MainBarIcon/Creator/Avatar.png",
		--tooltip = L"asset_tooltip_character",
	},
};

-- add a creator command at given position.
-- if there is already an object at the position, the add command will insert at the given position and original object insert at the back
-- @param command; type of Map3DSystem.App.Command
-- @param position: this is a tree path string of folder names separated by dot
--  e.g. "Creator.Normal Model.TEST", ...
-- @param posIndex: if position is a item in another category, this is the index at which to add the item. 
-- if nil, it is added to end, if 1 it is the beginning. 
function Map3DSystem.DB.AddGroupCommand(command, position, posIndex)
	local _,_, level1, level2, level3 = string.find(position, "([^%.]*)%.([^%.]*)%.([^%.]*)");
	if(level3~=nil and string.lower(level1) == "creator") then
		if(level2 == "Normal Model" or level2 == "BCS" or level2 == "Normal Character") then
			Map3DSystem.DB.AddGroup(level2, command.group, command.items, true, posIndex);
		else
			log("warning: unknown level 2 name in creator bar icon "..position.." \n")
		end
	else	
		log("warning: unknown level 1 name in creator bar icon "..position.." \n")
	end
end
	
-- new group is added into the asset database table
-- @param groupParentName: the level1 category in the creation menu
-- @param group: group table containing a full description of this group
--				including: name, rootpath, text, icon, and tooltip
-- @param items: asset item description table inside the group
-- @param bAutoRefresh: if false the menu will not be autorefreshed, default(nil) autorefresh
-- Sample group table:
--{
	--["name"] = "NM_01building",
	--["rootpath"] = "model/01building/",
	--["text"] = "建筑",
	--icon = "Texture/3DMapSystem/MainBarIcon/Creator/LargeBuilding.png",
	--tooltip = "asset_tooltip_building",
--},
function Map3DSystem.DB.AddGroup(groupParentName, group, items, bAutoRefresh, posIndex)
	if(type(groupParentName) ~= "string") then
		log("waring: Map3DSystem.DB.AddGroup must specify groupParentName\n");
	end
	if(type(group) ~= "table") then
		log("waring: group in Map3DSystem.DB.AddGroup must be table\n");
	end
	if(type(items) ~= "table") then
		log("waring: items in Map3DSystem.DB.AddGroup must be table\n");
	end
	
	-- check for groupParentName validity
	local i, v;
	local parentValidity = false;
	for i, v in ipairs(Map3DSystem.DB.Groups) do
		if(v.name == groupParentName and v.parent == "Root") then
			parentValidity = true;
			break;
		end
	end
	-- insert the group and items
	if(parentValidity == true) then
		group.parent = groupParentName;
		
		if(posIndex ~= nil) then
			local nCount = Map3DSystem.DB.Groups;
			posIndex = nCount + 1;
			table.insert(Map3DSystem.DB.Groups, Map3DSystem.DB.Groups[posIndex]);
			Map3DSystem.DB.Groups[posIndex] = group;
		else
			table.insert(Map3DSystem.DB.Groups, group);
		end
		
		Map3DSystem.DB.Items[group.name] = items;
	else
		log("waring: no existing category name:"..groupParentName.."\n");
	end
end

-- remove group from the asset database table
-- @param groupName: 
-- @param bAutoRefresh: if false the menu will not be autorefreshed, default(nil) autorefresh
function Map3DSystem.DB.RemoveGroup(groupName, bAutoRefresh)

	-- delete Map3DSystem.DB.Groups entry
	local i, v;
	for i, v in ipairs(Map3DSystem.DB.Groups) do
		if(v.name == groupName) then
			Map3DSystem.DB.Groups[i] = nil;
			break;
		end
	end

	-- delete Map3DSystem.DB.Items entry
	Map3DSystem.DB.Items[groupName] = nil;
end

-- add a new item into the itemTable
-- @param itemTable: indicated as a parameter in Map3DSystem.DB.AddGroup param#3
-- @param item: item tobe added, include: IconAssetName, ModelFilePath and IconFilePath
-- Sample Item:
--{
  --["Reserved4"] = "R4",
  --["Reserved3"] = "R3",
  --["Reserved1"] = "R1",
  --["Reserved2"] = "R2",
  --["Price"]=0,
  --["IconAssetName"] = "树",
  --["ModelFilePath"] = "model/05plants/02tree/01tree/tree02/tree020_v.x",
  --["IconFilePath"] = "model/05plants/02tree/01tree/tree02/tree020.x.png",
--}
function Map3DSystem.DB.AddItem(itemTable, item)
	if(type(itemTable) ~= "table") then
		log("waring: Map3DSystem.DB.AddItem(itemTable, item): itemTable must be table\n");
	end
	if(type(item.IconAssetName) ~= "string"
		or type(item.ModelFilePath) ~= "string"
		or type(item.IconFilePath) ~= "string") then
		log("waring: Map3DSystem.DB.AddItem(itemTable, item) item table must indicate the IconAssetName, ModelFilePath and IconFilePath in string\n");
		return;
	end
	-- default velue
	if(item.Price == nil) then item.Price = 0; end
	if(item.Reserved1 == nil) then item.Reserved1 = ""; end
	if(item.Reserved2 == nil) then item.Reserved2 = ""; end
	if(item.Reserved3 == nil) then item.Reserved3 = ""; end
	if(item.Reserved4 == nil) then item.Reserved4 = ""; end
	if(item.Reserved5 == nil) then item.Reserved5 = ""; end
	
	table.insert(itemTable, item);
end

-- get race and gender from full model path
-- @param modelPath: full model path
-- @return: race, gender in lowercase e.x. "human" "male"
function Map3DSystem.DB.GetRaceGenderFromModelPath(modelPath)

	local _path;
	
	local _dir = string.find(modelPath, "character/v3/")
	if(_dir ~= nil) then
		local _full = string.sub(modelPath, 14);
		local _slash1 = string.find(_full, '/');
		if(_slash1 ~= nil) then
			local _slash2 = string.find(_full, '/', _slash1 + 1);
			if(_slash2 ~= nil) then
				_path = string.sub(_full, 1, _slash2 - 1);
			end
		end
	end
	if(_path == nil) then
		return;
	end
	
	if(_path) then
		local index = string.find(_path, "/");
		if(index~=nil) then
			local _race = string.sub(_path, 1, index - 1);
			local _gender = string.sub(_path, index + 1);
			return string.lower(_race), string.lower(_gender);
		else
			log("warning: not valid race and gender from param modelPath in Map3DSystem.DB.GetRaceGenderFromModelPath\n")
		end			
	end
end

-- Current group structure 11-19:
-- NOTE: must in order so that the treeview will be init right
-- TODO: improve the treeview
--
--Normal Model
	--NM_01building
	--NM_02furniture
	--NM_03tools
	--NM_04deco
	--NM_05plants
	--NM_06props
	--NM_07trees
--Normal Character
	--NC_01human
	--NC_02animals
	--NC_03vehicles
	--NC_04particles
	--NC_05helpers
	--NC_06other
	--CCS_01original -- CCS info is merged into the normal character category
	--CCS_02test
--BCS
	--BCS_01base
	--BCS_02block
	--BCS_03blocktop
	--BCS_04stairs
	--BCS_05door
	--BCS_06window
	--BCS_07chimney
	--BCS_08deco
-------------------- DEPRACATED --------------------
-- CCS info is merged into the normal character category
--CCS
	--CCS_01original
	--CCS_02test
--My Favorites
	--TestLvl2
		--TestLvl3
			--TestLvl4
--My Wishlist
	--WishlistTest
-------------------- DEPRACATED --------------------


--[[ by LXZ 2008.2.4: porting groups to asset application's package file.  
A group in creator contains the group description and items in the group. 
A creator group is equavalent to asset package (as in the asset application)
]]
function Map3DSystem.DB.ExportAllGroupsToAssetPackage()
	local i, group;
	for i,group in ipairs(Map3DSystem.DB.Groups) do
		Map3DSystem.DB.ExportGroupToAssetPackage(group)
	end
end
-- by LXZ 2008.2.4: porting only a given group
-- @param group: it can be the group table or group name
-- @param filename: if nil, the asset application dir(temp/apps/assets_guid) + group.Category + ".asset" is used. 
function Map3DSystem.DB.ExportGroupToAssetPackage(group, filename)
	if(type(group) == "string") then
		group = Map3DSystem.DB.FindGroupByName(group)
	end
	if(group == nil) then 
		return 
	end
	NPL.load("(gl)script/kids/3DMapSystemApp/Assets/AssetManager.lua");
	
	local package = Map3DSystem.App.Assets.Package:new();
	package.text = group.text;
	package.icon = group.icon;
	package.tooltip = group.tooltip;
	-- always display in creator bar
	package.bDisplayInMainBar = true;
	parentGroup = Map3DSystem.DB.FindGroupByName(group.parent);
	if(parentGroup~=nil) then
		-- get the category name.i.e. where the group belongs. It is a unique name
		package.Category = "Creator."..parentGroup.name.."."..group.name;
		
		-- add items to assets
		local items = Map3DSystem.DB.Items[group.name];
		if(items ~=nil) then
			local i, item;
			for i, item in ipairs(items) do 
				local asset = {
					filename = item.ModelFilePath,
				}
				if(item.IconAssetName~=nil and item.IconAssetName~=ParaIO.GetFileName(asset.filename)) then
					asset.text = item.IconAssetName;
				end
				if(item.Price ~= nil or item.Price> 0) then
					asset.priceE = item.price;
				end 
				if(item.Price ~= nil or item.Price> 0) then
					asset.priceE = item.price;
				end 
				if(item.IconFilePath~=nil and item.IconFilePath~=(asset.filename..".png")) then
					asset.icon = item.IconFilePath;
				end
				local r;
				for r = 1,4 do 
					if(item["Reserved"..r]~=nil and item["Reserved"..r]~=("R"..r)) then
						asset["Reserved"..r] = item["Reserved"..r]
					end
				end
				package:AddAsset(Map3DSystem.App.Assets.asset:new(asset));
			end
		end
		
		-- add rootpath to folders if any
		if(group.rootpath~=nil) then
			package:AddFolder(Map3DSystem.App.Assets.folder:new({filename = group.rootpath}));
		end	
		
		-- save to default file file
		 Map3DSystem.App.Assets.SaveAsLocalPackage(package, filename);
	else
		log(group.name.." is skipped because it is not a leave node at level 2.\n")	
	end
end

-- get a group by its name
function Map3DSystem.DB.FindGroupByName(name)
	local i, group;
	for i,group in ipairs(Map3DSystem.DB.Groups) do
		if(group.name == name) then
			return group, i;
		end
	end
end

-- get item by ModelFilePath
-- @param ModelFilePath: normally the asset file name
-- @param RootPath: the root group to search from, can be "Normal Model", "BCS" or "Normal Character"
--		if nil, search all groups
-- @return the first item that match the ModelFilePath name.
function Map3DSystem.DB.GetItemByModelFilePath(ModelFilePath, RootPath)
	local i, group;
	local parent;
	if(RootPath == "Normal Model") then
		parent = "Normal Model";
	elseif(RootPath == "BCS") then
		parent = "BCS";
	elseif(RootPath == "Normal Character") then
		parent = "Normal Character";
	end
	for i, group in ipairs(Map3DSystem.DB.Groups) do
		if(parent == nil or group.parent == parent) then
			-- search item in group
			local i, item;
			for i, item in ipairs(Map3DSystem.DB.Items[group.name]) do
				if(string.lower(item.ModelFilePath) == string.lower(ModelFilePath)) then
					return item;
				end
				
				local modelFileName = ParaIO.GetFileName(item.ModelFilePath);
				local isXML = string.find(string.lower(modelFileName), ".xml");
				if(isXML ~= nil and ParaIO.DoesFileExist(modelFileName) == true) then
					local xmlRoot = ParaXML.LuaXML_ParseFile(item.ModelFilePath);
					local fileNode;
					for fileNode in commonlib.XPath.eachNode(xmlRoot, "//submesh") do
						if(fileNode.attr) then
							local fileInLOD = string.gsub(item.ModelFilePath, modelFileName, fileNode.attr["filename"]);
							if(string.lower(ModelFilePath) == string.lower(fileInLOD)) then
								return item;
							end
						end
					end
				end
			end
		end
	end
end
