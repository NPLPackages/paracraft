--[[
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
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local SkinPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.SkinPage");
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems");
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local CustomSkinPage = commonlib.gettable("MyCompany.Aries.Game.Movie.CustomSkinPage");

local page;
local currentModelFile;
local currentSkin;

CustomSkinPage.category_ds = {
	{tex1 = "zi_toubu2_28X14_32bits", tex2 = "zi_toubu1_28X14_32bits", name = "head"},
	{tex1 = "zi_yanjing2_28X14_32bits", tex2 = "zi_yanjing1_28X14_32bits", name = "eye"},
	{tex1 = "zi_zuiba1_28X14_32bits", tex2 = "zi_zuiba2_28X14_32bits", name = "mouth"},
	{tex1 = "zi_maozi1_28X14_32bits", tex2 = "zi_maozi2_28X14_32bits", name = "hat"},
	{tex1 = "zi_toushi1_28X14_32bits", tex2 = "zi_toushi2_28X14_32bits", name = "hair"},
	{tex1 = "zi_yifu1_28X14_32bits", tex2 = "zi_yifu2_28X14_32bits", name = "shirt"},
	{tex1 = "zi_kuzi1_28X14_32bits", tex2 = "zi_kuzi2_28X14_32bits", name = "pants"},
	{tex1 = "zi_shouchi1_28X14_32bits", tex2 = "zi_shouchi2_28X14_32bits", name = "right_hand_equipment"},
	{tex1 = "zi_beibu1_28X14_32bits", tex2 = "zi_beibu2_28X14_32bits", name = "back"},
	{tex1 = "zi_zuoqi1_28X14_32bits", tex2 = "zi_zuoqi2_28X14_32bits", name = "mount"},
};
CustomSkinPage.category_index = 1;
CustomSkinPage.model_index = 1;
CustomSkinPage.Current_Item_DS = {};
CustomSkinPage.Current_Model_DS = {};
CustomSkinPage.Current_Icon_DS = {};

function CustomSkinPage.OnInit()
	page = document:GetPageCtrl();
end

function CustomSkinPage.ShowPage(OnClose)
	currentModelFile = CustomCharItems.defaultModelFile;
	currentSkin = PlayerAssetFile:GetDefaultCustomGeosets();
	CustomSkinPage.category_index = 1;
	CustomSkinPage.model_index = 1;
	CustomSkinPage.Current_Item_DS = {};
	CustomSkinPage.Current_Model_DS = {};
	CustomSkinPage.Current_Icon_DS = {};

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
			OnClose();
		end
	end;

	keepwork.actors.list(nil, function(err, msg, data)
		if (err == 200 and data and data.count > 0) then
			for i = 1, data.count do
				local actor = data.rows[i];
				CustomSkinPage.Current_Model_DS[i] = {asset = actor.equipment.asset, skin = actor.equipment.skin};
			end
			if (CustomSkinPage.Current_Model_DS[1].asset ~= currentModelFile) then
				currentModelFile = CustomSkinPage.Current_Model_DS[1].asset;
				page:CallMethod("MyPlayer", "SetAssetFile", currentModelFile);
			end
			currentSkin = CustomSkinPage.Current_Model_DS[1].skin;
		else
			CustomSkinPage.Current_Model_DS[1] = {asset = currentModelFile, skin = currentSkin};
		end
		CustomSkinPage.OnChangeCategory(CustomSkinPage.category_index);
	end);
end

function CustomSkinPage.SelectModel(index)
	if (CustomSkinPage.model_index ~= index) then
		CustomSkinPage.model_index = index;
		CustomSkinPage.UpdateModel(CustomSkinPage.Current_Model_DS[index])
	end
end

function CustomSkinPage.DeleteModel(index)
end

function CustomSkinPage.UpdateModel(model)
	if (currentModelFile ~= model.asset) then
		currentModelFile = model.asset;
		page:CallMethod("MyPlayer", "SetAssetFile", currentModelFile);
	end
	page:CallMethod("MyPlayer", "SetCustomGeosets", model.skin);
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
	local skinTable = CustomCharItems:SkinStringToTable(currentSkin);
	local item = CustomSkinPage.Current_Item_DS[index];
	if (item.geoset) then
		skinTable.geosets[math.floor(item.geoset/100) + 1] = item.geoset % 100;
	end
	if (item.texture) then
		local id, filename = string.match(item.texture, "(%d+):(.*)");
		skinTable.textures[tonumber(id)] = filename;
	end
	if (item.attachment) then
		local id, filename = string.match(item.attachment, "(%d+):(.*)");
		skinTable.attachments[tonumber(id)] = filename;
	end

	currentSkin = CustomCharItems:SkinTableToString(skinTable);
	page:CallMethod("MyPlayer", "SetCustomGeosets", currentSkin);
end

function CustomSkinPage.CreateNewActor()
	CustomSkinPage.Current_Model_DS[#CustomSkinPage.Current_Model_DS+1] = {asset = CustomCharItems.defaultModelFile, skin = PlayerAssetFile:GetDefaultCustomGeosets()};
	CustomSkinPage.Refresh();
end

function CustomSkinPage.OnClickOK()
	local model = CustomSkinPage.Current_Model_DS[CustomSkinPage.model_index];
	model.skin = currentSkin;
end

function CustomSkinPage.OnClose()
	page:CloseWindow();
end
