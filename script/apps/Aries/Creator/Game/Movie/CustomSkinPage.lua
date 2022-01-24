﻿--[[
Title: 
Author(s): chenjinxian
Date: 2020/1/11
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/CustomSkinPage.lua");
local CustomSkinPage = commonlib.gettable("MyCompany.Aries.Game.Movie.CustomSkinPage");
CustomSkinPage.ShowPage(entity)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerAssetFile.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/SkinPage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.avatar.lua");
NPL.load("(gl)script/ide/System/Encoding/guid.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local SkinPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.SkinPage");
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems");
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local guid = commonlib.gettable("System.Encoding.guid");

local CustomSkinPage = commonlib.gettable("MyCompany.Aries.Game.Movie.CustomSkinPage");

local page;
local currentModelFile;
local currentSkin;

CustomSkinPage.category_ds = {
	-- {tex1 = "zi_toushi1_28X14_32bits", tex2 = "zi_toushi2_28X14_32bits", name = "hair", ui_index = 2},
	-- {tex1 = "zi_yanjing2_28X14_32bits", tex2 = "zi_yanjing1_28X14_32bits", name = "eye", ui_index = 3},
	-- {tex1 = "zi_zuiba1_28X14_32bits", tex2 = "zi_zuiba2_28X14_32bits", name = "mouth", ui_index = 4},
	-- {tex1 = "zi_yifu1_28X14_32bits", tex2 = "zi_yifu2_28X14_32bits", name = "shirt", ui_index = 5},
	-- {tex1 = "zi_kuzi1_28X14_32bits", tex2 = "zi_kuzi2_28X14_32bits", name = "pants", ui_index = 6},
	-- {tex1 = "zi_shouchi1_28X14_32bits", tex2 = "zi_shouchi2_28X14_32bits", name = "right_hand_equipment", ui_index = 8},
	-- {tex1 = "zi_beibu1_28X14_32bits", tex2 = "zi_beibu2_28X14_32bits", name = "back", ui_index = 7},
	-- {tex1 = "zi_zuoqi1_28X14_32bits", tex2 = "zi_zuoqi2_28X14_32bits", name = "pet", ui_index = 1},

	{tex1 = "zi_toushi1_28X14_32bits", tex2 = "zi_toushi2_28X14_32bits", name = "hair", ui_index = 7},
	{tex1 = "zi_yanjing2_28X14_32bits", tex2 = "zi_yanjing1_28X14_32bits", name = "eye", ui_index = 1},
	{tex1 = "zi_zuiba1_28X14_32bits", tex2 = "zi_zuiba2_28X14_32bits", name = "mouth", ui_index = 2},
	{tex1 = "zi_yifu1_28X14_32bits", tex2 = "zi_yifu2_28X14_32bits", name = "shirt", ui_index = 3},
	{tex1 = "zi_kuzi1_28X14_32bits", tex2 = "zi_kuzi2_28X14_32bits", name = "pants", ui_index = 4},
	{tex1 = "zi_shouchi1_28X14_32bits", tex2 = "zi_shouchi2_28X14_32bits", name = "right_hand_equipment", ui_index = 6},
	{tex1 = "zi_beibu1_28X14_32bits", tex2 = "zi_beibu2_28X14_32bits", name = "back", ui_index = 5},
	{tex1 = "zi_zuoqi1_28X14_32bits", tex2 = "zi_zuoqi2_28X14_32bits", name = "pet", ui_index = 8},
};
CustomSkinPage.category_index = 1;
CustomSkinPage.model_index = 1;
CustomSkinPage.Current_Item_DS = {};
CustomSkinPage.Current_Model_DS = {};
CustomSkinPage.Current_Icon_DS = {};

function CustomSkinPage.OnInit()
	page = document:GetPageCtrl();
end

-- @param skinIdString: optional skin string
function CustomSkinPage.ShowPage(OnClose, skinIdString)
	currentModelFile = CustomCharItems.defaultModelFile;
	currentSkin = skinIdString or CustomCharItems:SkinStringToItemIds(CustomCharItems.defaultSkinString);
	CustomSkinPage.category_index = 2;
	CustomSkinPage.model_index = 1;
	CustomSkinPage.Current_Item_DS = {};
	CustomSkinPage.Current_Model_DS = {};
	CustomSkinPage.Current_Icon_DS = {};
	for i = 1, #CustomSkinPage.category_ds do
		CustomSkinPage.Current_Icon_DS[i] = {id = "", icon = "", name = ""}; 
	end

	local params = {
			url = "script/apps/Aries/Creator/Game/Movie/CustomSkinPage.html", 
			name = "CustomSkinPage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			bShow = true,
			click_through = false, 
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -1190/2,
				y = -580/2,
				width = 1190,
				height = 580,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	params._page.OnClose = function()
		if(OnClose) then
			OnClose(currentModelFile, currentSkin);
		end
	end;

	keepwork.actors.list(nil, function(err, msg, data)
		if (err == 200 and data and data.count > 0) then
			CustomSkinPage.model_index = -1;
			for i = 1, data.count do
				local actor = data.rows[i];
				CustomSkinPage.Current_Model_DS[i] = {asset = actor.equipment.asset, skin = actor.equipment.skin, id = actor.id, name = actor.name, alias = actor.equipment.alias or string.format(L"新建模型%d", actor.id)};
			end
			if (CustomSkinPage.Current_Model_DS[1].asset ~= currentModelFile) then
				currentModelFile = CustomSkinPage.Current_Model_DS[1].asset;
				page:CallMethod("MyPlayer", "SetAssetFile", currentModelFile);
			end
			if not currentSkin then
				CustomSkinPage.model_index = 1
				currentSkin = CustomSkinPage.Current_Model_DS[1].skin;
			end

			local items = CustomCharItems:GetUsedItemsBySkin(currentSkin);
			for _, item in ipairs(items) do
				local index = CustomSkinPage.GetIconIndexFromName(item.name);
				if (index > 0) then
					CustomSkinPage.Current_Icon_DS[index].id = item.id;
					CustomSkinPage.Current_Icon_DS[index].name = item.name;
					CustomSkinPage.Current_Icon_DS[index].icon = item.icon;
				end
			end

		--else
			--CustomSkinPage.Current_Model_DS[1] = {asset = currentModelFile, skin = currentSkin};
		end
		CustomSkinPage.OnChangeCategory(CustomSkinPage.category_index);
	end);
end

function CustomSkinPage.GetIconIndexFromName(name)
	for i = 1, #CustomSkinPage.category_ds do
		if (CustomSkinPage.category_ds[i].name == name) then
			return CustomSkinPage.category_ds[i].ui_index;
		end
	end
	return -1;
end

function CustomSkinPage.SelectModel(index)
	if (CustomSkinPage.model_index ~= index) then
		CustomSkinPage.model_index = index;
		CustomSkinPage.UpdateModel(CustomSkinPage.Current_Model_DS[index])
		CustomSkinPage.OnChangeCategory(2);
	end
end

function CustomSkinPage.DeleteModel(index)
	local model = CustomSkinPage.Current_Model_DS[index];
	keepwork.actors.delete({router_params = {id = model.id}}, function(err, msg, data)
		if (err == 200) then
			for i = index, #CustomSkinPage.Current_Model_DS-1 do
				CustomSkinPage.Current_Model_DS[index] = CustomSkinPage.Current_Model_DS[index + 1];
			end
			CustomSkinPage.Current_Model_DS[#CustomSkinPage.Current_Model_DS] = nil;
			CustomSkinPage.Refresh();
		end
	end);
end

function CustomSkinPage.UpdateModel(model)
	currentModelFile = model.asset;
	currentSkin = model.skin;
	for i = 1, #CustomSkinPage.category_ds do
		CustomSkinPage.Current_Icon_DS[i].id = "";
		CustomSkinPage.Current_Icon_DS[i].name = "";
		CustomSkinPage.Current_Icon_DS[i].icon = "";
	end
	local items = CustomCharItems:GetUsedItemsBySkin(currentSkin);
	for _, item in ipairs(items) do
		local index = CustomSkinPage.GetIconIndexFromName(item.name);
		if (index > 0) then
			CustomSkinPage.Current_Icon_DS[index].id = item.id;
			CustomSkinPage.Current_Icon_DS[index].name = item.name;
			CustomSkinPage.Current_Icon_DS[index].icon = item.icon;
		end
	end
end

function CustomSkinPage.Refresh()
	if (page) then
		page:Refresh(0);
		page:CallMethod("MyPlayer", "SetAssetFile", currentModelFile);
		page:CallMethod("MyPlayer", "SetCustomGeosets", currentSkin);
	end
end

function CustomSkinPage.OnChangeCategory(index)
	CustomSkinPage.category_index = index or CustomSkinPage.category_index;
	local category = CustomSkinPage.category_ds[CustomSkinPage.category_index];
	if (category) then
		CustomSkinPage.Current_Item_DS = CustomCharItems:GetModelItems(currentModelFile, category.name, currentSkin) or {};
	end
	CustomSkinPage.Refresh();
end

function CustomSkinPage.UpdateCustomGeosets(index)
	local item = CustomSkinPage.Current_Item_DS[index];
	local ui_index = CustomSkinPage.category_ds[CustomSkinPage.category_index].ui_index;
	if (CustomSkinPage.Current_Icon_DS[ui_index].id == item.id) then
		return;
	end

	currentSkin = CustomCharItems:AddItemToSkin(currentSkin, item);

	CustomSkinPage.Current_Icon_DS[ui_index].id = item.id;
	CustomSkinPage.Current_Icon_DS[ui_index].name= item.name;
	CustomSkinPage.Current_Icon_DS[ui_index].icon = item.icon;
	CustomSkinPage.Refresh();
end

function CustomSkinPage.RemoveSkin(index)
	local iconItem = CustomSkinPage.Current_Icon_DS[index];
	if (iconItem and iconItem.id and iconItem.id ~= "") then
		local skin = CustomCharItems:RemoveItemInSkin(currentSkin, iconItem.id);
		if (currentSkin ~= skin) then
			currentSkin = skin;
			iconItem.id = "";
			iconItem.name = "";
			iconItem.icon = "";
			CustomSkinPage.Refresh();
		end
	end
end

function CustomSkinPage.CreateNewActor()
	local index = #CustomSkinPage.Current_Model_DS+1;
	local model = {asset = CustomCharItems.defaultModelFile, skin = CustomCharItems:SkinStringToItemIds(CustomCharItems.defaultSkinString)};
	keepwork.actors.add({name = guid.uuid(), equipment = model}, function(err, msg, data)
		if (err == 200) then
			local model = {asset = data.equipment.asset, skin = data.equipment.skin, id = data.id, name = data.name, alias = string.format(L"新建模型%d", data.id)};
			CustomSkinPage.Current_Model_DS[index] = model;
			CustomSkinPage.Refresh();
		end
	end);
end

function CustomSkinPage.OnClickSave()
	local model = CustomSkinPage.Current_Model_DS[CustomSkinPage.model_index];
	if (model) then
		if (model.skin ~= currentSkin) then
			local equipment = {asset = currentModelFile, skin = currentSkin, alias = model.alias};
			keepwork.actors.modify({router_params = {id = model.id}, name = model.name, equipment = equipment}, function(err, msg, data)
				if (err == 200) then
					model.skin = currentSkin;
				end
			end);
		end
	end
end

function CustomSkinPage.OnClickOK()
	currentSkin = CustomCharItems:ChangeSkinStringToItems(currentSkin);
	CustomSkinPage.OnClickSave();
	GameLogic.IsVip("ChangeAvatarSkin", true, function(isVip) 
		if(isVip) then
			page:CloseWindow();
		end
	end)
end

function CustomSkinPage.OnClose()
	currentModelFile = nil;
	currentSkin = nil;
	page:CloseWindow();
end

function CustomSkinPage.RenameModel(name)
	local model = CustomSkinPage.Current_Model_DS[CustomSkinPage.model_index];
	if (model) then
		local equipment = {asset = model.asset, skin = model.skin, alias = name};
		keepwork.actors.modify({router_params = {id = model.id}, name = model.name, equipment = equipment}, function(err, msg, data)
			if (err == 200) then
				model.alias = name;
				CustomSkinPage.Refresh();
			end
		end);
	end
end
