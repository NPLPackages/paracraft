--[[
Title: 
Author(s): chenjinxian
Date: 2020/1/11
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeSkinPage.lua");
local ParaLifeSkinPage = commonlib.gettable("MyCompany.Aries.Game.ParaLife.ParaLifeSkinPage");
ParaLifeSkinPage.ShowPage(entity)
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

local ParaLifeSkinPage = commonlib.gettable("MyCompany.Aries.Game.ParaLife.ParaLifeSkinPage");

local page;
local currentModelFile;
local currentSkin;

ParaLifeSkinPage.category_ds = {
	{tex1 = "zi_toushi1_28X14_32bits", tex2 = "zi_toushi2_28X14_32bits", name = "hair", ui_index = 7},
	{tex1 = "zi_yanjing2_28X14_32bits", tex2 = "zi_yanjing1_28X14_32bits", name = "eye", ui_index = 1},
	{tex1 = "zi_zuiba1_28X14_32bits", tex2 = "zi_zuiba2_28X14_32bits", name = "mouth", ui_index = 2},
	{tex1 = "zi_yifu1_28X14_32bits", tex2 = "zi_yifu2_28X14_32bits", name = "shirt", ui_index = 3},
	{tex1 = "zi_kuzi1_28X14_32bits", tex2 = "zi_kuzi2_28X14_32bits", name = "pants", ui_index = 4},
	{tex1 = "zi_shouchi1_28X14_32bits", tex2 = "zi_shouchi2_28X14_32bits", name = "right_hand_equipment", ui_index = 6},
	{tex1 = "zi_beibu1_28X14_32bits", tex2 = "zi_beibu2_28X14_32bits", name = "back", ui_index = 5},
	-- {tex1 = "zi_zuoqi1_28X14_32bits", tex2 = "zi_zuoqi2_28X14_32bits", name = "pet", ui_index = 8},
};

ParaLifeSkinPage.OPERATE_STATUS = {
	OPERATE_SAVE = 1,
	OPERATE_LOAD = 2,
	OPERATE_UPDATE = 3,
	OPERATE_DELETE = 4,
	OPERATE_NIL = 5
}
ParaLifeSkinPage.default_operate = ParaLifeSkinPage.OPERATE_STATUS.OPERATE_NIL
ParaLifeSkinPage.current_operate = ParaLifeSkinPage.OPERATE_STATUS.OPERATE_NIL

ParaLifeSkinPage.category_index = 1;
ParaLifeSkinPage.model_index = 1;
ParaLifeSkinPage.Current_Item_DS = {};
ParaLifeSkinPage.Current_Model_DS = {};
ParaLifeSkinPage.Current_Icon_DS = {};
ParaLifeSkinPage.bSelectCollocation = false

function ParaLifeSkinPage.OnInit()
	page = document:GetPageCtrl();
end

-- @param skinIdString: optional skin string
function ParaLifeSkinPage.ShowPage(OnClose, skinIdString)
	currentModelFile = CustomCharItems.defaultModelFile;
	currentSkin = skinIdString or CustomCharItems:SkinStringToItemIds(CustomCharItems.defaultSkinString);
	ParaLifeSkinPage.category_index = 2;
	ParaLifeSkinPage.model_index = 1;
	ParaLifeSkinPage.Current_Item_DS = {};
	ParaLifeSkinPage.Current_Model_DS = {};
	ParaLifeSkinPage.Current_Icon_DS = {};
	for i = 1, #ParaLifeSkinPage.category_ds do
		ParaLifeSkinPage.Current_Icon_DS[i] = {id = "", icon = "", name = ""}; 
	end

	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeSkinPage.html", 
			name = "ParaLifeSkinPage.ShowPage", 
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
			ParaLifeSkinPage.model_index = 1;
			for i = 1, data.count do
				local actor = data.rows[i];
				ParaLifeSkinPage.Current_Model_DS[i] = {asset = actor.equipment.asset, skin = actor.equipment.skin, id = actor.id, name = actor.name, alias = actor.equipment.alias or string.format(L"新建搭配%d", actor.id)};
			end
			if (ParaLifeSkinPage.Current_Model_DS[1].asset ~= currentModelFile) then
				currentModelFile = ParaLifeSkinPage.Current_Model_DS[1].asset;
				page:CallMethod("MyPlayer", "SetAssetFile", currentModelFile);
			end
			currentSkin = ParaLifeSkinPage.Current_Model_DS[1].skin;

			local items = CustomCharItems:GetUsedItemsBySkin(currentSkin);
			for _, item in ipairs(items) do
				local index = ParaLifeSkinPage.GetIconIndexFromName(item.name);
				if (index > 0) then
					ParaLifeSkinPage.Current_Icon_DS[index].id = item.id;
					ParaLifeSkinPage.Current_Icon_DS[index].name = item.name;
					ParaLifeSkinPage.Current_Icon_DS[index].icon = item.icon;
				end
			end
		end
		ParaLifeSkinPage.OnChangeCategory(ParaLifeSkinPage.category_index);
	end);
end

function ParaLifeSkinPage.GetIconIndexFromName(name)
	for i = 1, #ParaLifeSkinPage.category_ds do
		if (ParaLifeSkinPage.category_ds[i].name == name) then
			return ParaLifeSkinPage.category_ds[i].ui_index;
		end
	end
	return -1;
end

function ParaLifeSkinPage.SelectModel(index)
	if (ParaLifeSkinPage.model_index ~= index) then
		ParaLifeSkinPage.model_index = index;
		ParaLifeSkinPage.IsLoadModel = false
		-- ParaLifeSkinPage.UpdateModel(ParaLifeSkinPage.Current_Model_DS[index])
		-- ParaLifeSkinPage.OnChangeCategory(2);
	end
	ParaLifeSkinPage.current_operate = ParaLifeSkinPage.OPERATE_STATUS.OPERATE_NIL
	ParaLifeSkinPage.UpdateOperateStatus()
end

function ParaLifeSkinPage.LoadModel()
	if not ParaLifeSkinPage.IsLoadModel then
		ParaLifeSkinPage.UpdateModel(ParaLifeSkinPage.Current_Model_DS[ParaLifeSkinPage.model_index])
		ParaLifeSkinPage.OnChangeCategory(2);
		ParaLifeSkinPage.IsLoadModel = true
		ParaLifeSkinPage.current_operate = ParaLifeSkinPage.OPERATE_STATUS.OPERATE_LOAD
		ParaLifeSkinPage.UpdateOperateStatus()
	end
end

function ParaLifeSkinPage.DeleteModel(index)
	local delete_index = index or ParaLifeSkinPage.model_index
	local model = ParaLifeSkinPage.Current_Model_DS[delete_index];
	if not model then
		return 
	end
	ParaLifeSkinPage.current_operate = ParaLifeSkinPage.OPERATE_STATUS.OPERATE_DELETE
	ParaLifeSkinPage.UpdateOperateStatus()
	keepwork.actors.delete({router_params = {id = model.id}}, function(err, msg, data)
		if (err == 200) then
			for i = delete_index, #ParaLifeSkinPage.Current_Model_DS-1 do
				ParaLifeSkinPage.Current_Model_DS[delete_index] = ParaLifeSkinPage.Current_Model_DS[delete_index + 1];
			end
			ParaLifeSkinPage.Current_Model_DS[#ParaLifeSkinPage.Current_Model_DS] = nil;
			ParaLifeSkinPage.Refresh();
		end
	end);
end

function ParaLifeSkinPage.UpdateModel(model)
	currentModelFile = model.asset;
	currentSkin = model.skin;
	for i = 1, #ParaLifeSkinPage.category_ds do
		ParaLifeSkinPage.Current_Icon_DS[i].id = "";
		ParaLifeSkinPage.Current_Icon_DS[i].name = "";
		ParaLifeSkinPage.Current_Icon_DS[i].icon = "";
	end
	local items = CustomCharItems:GetUsedItemsBySkin(currentSkin);
	for _, item in ipairs(items) do
		local index = ParaLifeSkinPage.GetIconIndexFromName(item.name);
		if (index > 0) then
			ParaLifeSkinPage.Current_Icon_DS[index].id = item.id;
			ParaLifeSkinPage.Current_Icon_DS[index].name = item.name;
			ParaLifeSkinPage.Current_Icon_DS[index].icon = item.icon;
		end
	end
end

function ParaLifeSkinPage.Refresh()
	if (page) then
		page:Refresh(0);
		page:CallMethod("MyPlayer", "SetAssetFile", currentModelFile);
		page:CallMethod("MyPlayer", "SetCustomGeosets", currentSkin);
		ParaLifeSkinPage.UpdateOperateStatus()
		ParaLifeSkinPage.UpdatePageBg()
	end
end

function ParaLifeSkinPage.OnChangeCategory(index)
	ParaLifeSkinPage.category_index = index or ParaLifeSkinPage.category_index;
	local category = ParaLifeSkinPage.category_ds[ParaLifeSkinPage.category_index];
	if (category) then
		ParaLifeSkinPage.Current_Item_DS = CustomCharItems:GetModelItems(currentModelFile, category.name, currentSkin) or {};
	end
	ParaLifeSkinPage.Refresh();
end

function ParaLifeSkinPage.UpdateCustomGeosets(index)
	local item = ParaLifeSkinPage.Current_Item_DS[index];
	local ui_index = ParaLifeSkinPage.category_ds[ParaLifeSkinPage.category_index].ui_index;
	if (ParaLifeSkinPage.Current_Icon_DS[ui_index].id == item.id) then
		return;
	end

	currentSkin = CustomCharItems:AddItemToSkin(currentSkin, item);

	ParaLifeSkinPage.Current_Icon_DS[ui_index].id = item.id;
	ParaLifeSkinPage.Current_Icon_DS[ui_index].name= item.name;
	ParaLifeSkinPage.Current_Icon_DS[ui_index].icon = item.icon;
	ParaLifeSkinPage.Refresh();
end

function ParaLifeSkinPage.RemoveSkin(index)
	local iconItem = ParaLifeSkinPage.Current_Icon_DS[index];
	if (iconItem and iconItem.id and iconItem.id ~= "") then
		local skin = CustomCharItems:RemoveItemInSkin(currentSkin, iconItem.id);
		if (currentSkin ~= skin) then
			currentSkin = skin;
			iconItem.id = "";
			iconItem.name = "";
			iconItem.icon = "";
			ParaLifeSkinPage.Refresh();
		end
	end
end

--添加一个搭配
function ParaLifeSkinPage.CreateNewActor()
	local ParaLifeCreateSkinPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeCreateSkinPage.lua") 
    ParaLifeCreateSkinPage.ShowView(function(name)
		if (name == nil or name == "") then
			return;
		end
		if (commonlib.utf8.len(name) > 10) then
			_guihelper.MessageBox(L"输入的名称太长，请控制在10个字以内");
			return;
		end
		local clothes_name = name
		local index = #ParaLifeSkinPage.Current_Model_DS+1;
		local model = {asset = CustomCharItems.defaultModelFile, skin = CustomCharItems:SkinStringToItemIds(CustomCharItems.defaultSkinString)};
		keepwork.actors.add({name = clothes_name, equipment = model}, function(err, msg, data)
			echo(data,true)
			if (err == 200) then
				local model = {asset = data.equipment.asset, skin = data.equipment.skin, id = data.id, name = data.name, alias = data.name};
				ParaLifeSkinPage.Current_Model_DS[index] = model;
				ParaLifeSkinPage.Refresh();
			end
		end);
	end)
end

function ParaLifeSkinPage.OnClickSave()
	local model = ParaLifeSkinPage.Current_Model_DS[ParaLifeSkinPage.model_index];
	if (model) then
		ParaLifeSkinPage.current_operate = ParaLifeSkinPage.OPERATE_STATUS.OPERATE_SAVE
		ParaLifeSkinPage.UpdateOperateStatus()
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

function ParaLifeSkinPage.OnClickOK()
	currentSkin = CustomCharItems:ChangeSkinStringToItems(currentSkin);
	ParaLifeSkinPage.OnClickSave();
	GameLogic.IsVip("ChangeAvatarSkin", true, function(isVip) 
		if(isVip) then
			page:CloseWindow();
		end
	end)
end

function ParaLifeSkinPage.OnClickEdit()
	ParaLifeSkinPage.current_operate = ParaLifeSkinPage.OPERATE_STATUS.OPERATE_UPDATE
	ParaLifeSkinPage.UpdateOperateStatus()
	local model = ParaLifeSkinPage.Current_Model_DS[ParaLifeSkinPage.model_index];
	if not model then
		return 
	end
	local ParaLifeEditSkinPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeEditSkinPage.lua") 
    ParaLifeEditSkinPage.ShowView(model.alias,function(name)
		if (name == nil or name == "") then
			return;
		end
		if (commonlib.utf8.len(name) > 10) then
			_guihelper.MessageBox(L"输入的名称太长，请控制在10个字以内");
			return;
		end
		ParaLifeSkinPage.RenameModel(name)
	end)
end

function ParaLifeSkinPage.OnClose()
	currentModelFile = nil;
	currentSkin = nil;
	page:CloseWindow();
end

function ParaLifeSkinPage.RenameModel(name)
	local model = ParaLifeSkinPage.Current_Model_DS[ParaLifeSkinPage.model_index];
	if (model) then
		local equipment = {asset = model.asset, skin = model.skin, alias = name};
		keepwork.actors.modify({router_params = {id = model.id}, name = model.name, equipment = equipment}, function(err, msg, data)
			if (err == 200) then
				model.alias = name;
				ParaLifeSkinPage.Refresh();
			end
		end);
	end
end
--[[
	["kp_green_button"] = {background = "Texture/Aries/Creator/keepwork/Window/button/btn_lvse_32bits.png;0 0 38 64:16 16 16 16", ["text-offset-y"] = -4, ["font-size"] = 14, height = 64},
		["kp_yellow_button"] = {background = "Texture/Aries/Creator/keepwork/Window/button/btn_huangse_32bits.png;0 0 38 64:16 16 16 16", ["text-offset-y"] = -4, ["font-size"] = 14, height = 64},
		["kp_gray_button"] = {background = "Texture/Aries/Creator/keepwork/Window/button/btn_huise_32bits.png;0 0 38 64:16 16 16 16", ["text-offset-y"] = -4, ["font-size"] = 14, height = 64},
		
]]
function  ParaLifeSkinPage.UpdateOperateStatus()
	local btnSaveModel = ParaUI.GetUIObject("ParaLifeSkinPage.SaveModel")
	local btnLoadModel = ParaUI.GetUIObject("ParaLifeSkinPage.LoadModel")
	local btnEditModel = ParaUI.GetUIObject("ParaLifeSkinPage.EditModel")
	local btnDeleteModel = ParaUI.GetUIObject("ParaLifeSkinPage.DeleteModel")

	if not btnSaveModel:IsValid() or not btnLoadModel:IsValid() or not btnEditModel:IsValid() or not btnDeleteModel:IsValid() then
		return 
	end

	if not ParaLifeSkinPage.bSelectCollocation or ParaLifeSkinPage.current_operate == ParaLifeSkinPage.OPERATE_STATUS.OPERATE_NIL then
		btnSaveModel.background = "Texture/Aries/Creator/keepwork/Window/button/btn_huise_32bits.png;0 0 38 64:16 16 16 16"
		btnLoadModel.background = "Texture/Aries/Creator/keepwork/Window/button/btn_huise_32bits.png;0 0 38 64:16 16 16 16"
		btnEditModel.background = "Texture/Aries/Creator/keepwork/Window/button/btn_huise_32bits.png;0 0 38 64:16 16 16 16"
		btnDeleteModel.background = "Texture/Aries/Creator/keepwork/Window/button/btn_huise_32bits.png;0 0 38 64:16 16 16 16"
		return 
	end

	btnSaveModel.background = "Texture/Aries/Creator/keepwork/Window/button/btn_huise_32bits.png;0 0 38 64:16 16 16 16"
	btnLoadModel.background = "Texture/Aries/Creator/keepwork/Window/button/btn_huise_32bits.png;0 0 38 64:16 16 16 16"
	btnEditModel.background = "Texture/Aries/Creator/keepwork/Window/button/btn_huise_32bits.png;0 0 38 64:16 16 16 16"
	btnDeleteModel.background = "Texture/Aries/Creator/keepwork/Window/button/btn_huise_32bits.png;0 0 38 64:16 16 16 16"
	if ParaLifeSkinPage.current_operate == ParaLifeSkinPage.OPERATE_STATUS.OPERATE_DELETE then
		btnDeleteModel.background = "Texture/Aries/Creator/keepwork/Window/button/btn_huangse_32bits.png;0 0 38 64:16 16 16 16"
		return 
	end

	if ParaLifeSkinPage.current_operate == ParaLifeSkinPage.OPERATE_STATUS.OPERATE_LOAD then
		btnLoadModel.background = "Texture/Aries/Creator/keepwork/Window/button/btn_huangse_32bits.png;0 0 38 64:16 16 16 16"
		return 
	end

	if ParaLifeSkinPage.current_operate == ParaLifeSkinPage.OPERATE_STATUS.OPERATE_SAVE then
		btnSaveModel.background = "Texture/Aries/Creator/keepwork/Window/button/btn_huangse_32bits.png;0 0 38 64:16 16 16 16"
		return 
	end

	if ParaLifeSkinPage.current_operate == ParaLifeSkinPage.OPERATE_STATUS.OPERATE_UPDATE then
		btnEditModel.background = "Texture/Aries/Creator/keepwork/Window/button/btn_huangse_32bits.png;0 0 38 64:16 16 16 16"
		return 
	end
end

function ParaLifeSkinPage.UpdatePageBg()
	local bg = page:FindControl("skin_page")
	if bg and bg:IsValid() then
		local width = ParaLifeSkinPage.bSelectCollocation and 1190 or 960
		bg.width = width
	end
end

function ParaLifeSkinPage.ClickClothesBtn()
	ParaLifeSkinPage.bSelectCollocation = not ParaLifeSkinPage.bSelectCollocation
	print("ParaLifeSkinPage.bSelectCollocation============",ParaLifeSkinPage.bSelectCollocation)
	ParaLifeSkinPage.UpdatePageBg()
	ParaLifeSkinPage.Refresh();
end


