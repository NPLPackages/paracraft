--[[
Title: MobPropertyPage
Author(s): LiXizhi
Date: 2014/1/10
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/MobPropertyPage.lua");
local MobPropertyPage = commonlib.gettable("MyCompany.Aries.Game.GUI.MobPropertyPage");
MobPropertyPage.ShowPage(entity);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerAssetFile.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/CharGeosets.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerSkins.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/SkinPage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local SkinPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.SkinPage");
local PlayerSkins = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerSkins");
local CharGeosets = commonlib.gettable("MyCompany.Aries.Game.Common.CharGeosets");
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local MobPropertyPage = commonlib.gettable("MyCompany.Aries.Game.GUI.MobPropertyPage");

local cur_entity;
local page;
local curAssetFile;

function MobPropertyPage.OnInit()
	page = document:GetPageCtrl();

	local entity = MobPropertyPage.GetEntity();
	
	local params = entity:GetPortaitObjectParams(true);

	if(entity.GetModelFile) then
		params.AssetFile = entity:GetModelFile() or params.AssetFile;
	end
	-- change character name directly. 
	page:SetNodeValue("name", entity:GetDisplayName() or "");
	page:SetNodeValue("showHeadonName", entity:IsShowHeadOnDisplay());
	page:SetNodeValue("canRandomWalk", entity.can_random_move == true);
	-- page:SetNodeValue("assetfile", params.AssetFile);
	curAssetFile = params.AssetFile;
end

function MobPropertyPage.GetEntity()
	return cur_entity;
end

function MobPropertyPage.GetContainerView()
	if(cur_entity) then
		return cur_entity:GetInventoryView();
	end
end

function MobPropertyPage.GetItemID()
	if(cur_entity) then
		return cur_entity:GetBlockId();
	else
		return 0;
	end
end

function MobPropertyPage.GetItemName()
	local block = block_types.get(MobPropertyPage.GetItemID())
    if(block) then
        return block:GetDisplayName();
    end
end

function MobPropertyPage.GetCommand()
	if(cur_entity) then
		return cur_entity:GetCommand();
	end
end

function MobPropertyPage.ShowPage(entity, triggerEntity, OnClose)
	if(not entity) then
		return;
	end
	local EntityMob = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityMob")
	if(not entity.isa or not entity:isa(EntityMob)) then
		return
	end

	entity:BeginEdit();
	cur_entity = entity;
	local params = {
			url = "script/apps/Aries/Creator/Game/GUI/MobPropertyPage.html", 
			name = "MobPropertyPage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			bShow = true,
			click_through = false, 
			zorder = -1,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -200,
				y = -190,
				width = 400,
				height = 380,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	params._page.OnClose = function()
		entity:EndEdit();
		if(OnClose) then
			OnClose();
		end
	end;
end

function MobPropertyPage.OnClickNextSkin()
	local entity = MobPropertyPage.GetEntity();
	if(entity and entity.ToggleNextSkin) then
		if(not entity:ToggleNextSkin(mouse_button=="right")) then
			_guihelper.MessageBox(L"这个模型没有随机皮肤;通用人物有随机皮肤");
		end
	end
end

function MobPropertyPage.ShowSkinPage()
	local entity = MobPropertyPage.GetEntity();
	if(entity) then
		local obj = entity:GetInnerObject();
		if(obj) then
			local assetFilename = entity:GetMainAssetPath();
			
			local old_value = entity:GetSkin();
			NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/EditSkinPage.lua");
			local EditSkinPage = commonlib.gettable("MyCompany.Aries.Game.Movie.EditSkinPage");
			EditSkinPage.ShowPage(function(result)
				if(result and result~=old_value) then
					entity:SetSkin(result);
				end
			end, old_value, "", assetFilename)
		end
	end
end

local asset_file_ds;

function MobPropertyPage.GetAssetFileDS()
	if(not asset_file_ds) then
		asset_file_ds = {};
		local ds = PlayerAssetFile:GetCategoryItems("common");
		for i, item in ipairs(ds) do
			local assetfile = item.filename;
			if(assetfile and assetfile~="") then
				asset_file_ds[#asset_file_ds+1] = {text=item.displayname or assetfile, value=assetfile};
			end
		end
	end
	-- ensure curAssetFile is selected. 
	local hasSelection=false;
	for i, item in ipairs(asset_file_ds) do
		if(item.value == curAssetFile) then
			item.selected = true;
			hasSelection = true;
		else
			item.selected = false;
		end
	end
	if(not hasSelection) then
		asset_file_ds[#asset_file_ds+1] = {text=curAssetFile, value=curAssetFile, selected=true};
	end
	return asset_file_ds;
end


function MobPropertyPage.OnChangeAssetFile(skin)
	MobPropertyPage.UpdateAssetFile(nil, nil, page:GetValue("assetfile"), skin);
end

function MobPropertyPage.UpdateAssetFile(entity, obj, assetfile, skin)
	entity = entity or MobPropertyPage.GetEntity();
	obj = obj or entity:GetInnerObject();
	
	if(obj and obj:IsCharacter()) then
		assetfile = assetfile or page:GetValue("assetfile");
		if(assetfile) then
			assetfile = assetfile:gsub("^%s+",""):gsub("%s+$","");
		end
		local old_filename = assetfile;
		assetfile = EntityManager.PlayerAssetFile:GetValidAssetByString(commonlib.Encoding.Utf8ToDefault(assetfile));
		if(assetfile and assetfile~=entity:GetMainAssetPath()) then
			if(entity.SetModelFile) then
				entity:SetModelFile(commonlib.Encoding.Utf8ToDefault(old_filename));
			else
				entity:SetMainAssetPath(assetfile);
			end
			
			if (PlayerAssetFile:HasCustomGeosets(assetfile) and skin) then
				entity:SetSkin(skin);
			else
				-- this ensure that at least one shirt is displayed if it contains geosets.
				entity:SetCharacterSlot(CharGeosets["shirt"], 1);
				-- this ensure that at least one default skin is selected
				if((not entity.GetSkin or not entity:GetSkin()) and entity.ToggleNextSkin) then
					entity:ToggleNextSkin();
				end
			end
			if(entity:IsServerEntity() and entity:IsRemote()) then
				if(entity.UpdateAndSendDataWatcher) then
					entity:UpdateAndSendDataWatcher();
				end
			end
		end
	end
end


function MobPropertyPage.OnClickOK()
	local name = page:GetValue("name");
	name = name and name:gsub("^%s+",""):gsub("%s+$","");
	local name_len = ParaMisc.GetUnicodeCharNum(name);
	if(name_len > 16)then
		_guihelper.MessageBox(L"名字不能超过16个字, 请重新输入");
		return
	end
	
	local entity = MobPropertyPage.GetEntity();
	local obj = entity:GetInnerObject();
	
	
	if(obj and obj:IsCharacter()) then
		entity:SetDisplayName(name);
		entity:SetName(name);

		local bShowHeadonName = page:GetValue("showHeadonName", false);
		entity:ShowHeadOnDisplay(bShowHeadonName);

		local canRandomWalk = page:GetValue("canRandomWalk", true);
		entity:SetCanRandomMove(canRandomWalk);

		if(entity:IsServerEntity() and entity:IsRemote()) then
			GameLogic.GetPlayer():AddToSendQueue(GameLogic.Packets.PacketEntityFunction:new():Init(entity, "mobProperty", {
				-- displayName = name, 
				-- name = name, 
				canRandomWalk = canRandomWalk==true,
			}));
		end

		MobPropertyPage.UpdateAssetFile(entity, obj, page:GetValue("assetfile"));
	end

	page:CloseWindow();
end

function MobPropertyPage.OnOpenAssetFile()
	local lastFilename = "";
	if(page) then
		lastFilename = page:GetValue("assetfile")
	end
	NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenAssetFileDialog.lua");
	local OpenAssetFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenAssetFileDialog");
	OpenAssetFileDialog.ShowPage("", function(filename)
		if(filename and page) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerAssetFile.lua");
			local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
			local filepath = PlayerAssetFile:GetValidAssetByString(filename);
			if(filepath or filename=="actor") then
				page:SetValue("assetfile", commonlib.Encoding.DefaultToUtf8(filename));
				MobPropertyPage.OnChangeAssetFile();
			end
		end
	end, commonlib.Encoding.Utf8ToDefault(lastFilename), L"选择模型文件", "model");
end

function MobPropertyPage.OnOpenCustomModel()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/CustomSkinPage.lua");
	local CustomSkinPage = commonlib.gettable("MyCompany.Aries.Game.Movie.CustomSkinPage");
	CustomSkinPage.ShowPage(function(filename, skin)
		if (filename and skin) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerAssetFile.lua");
			local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
			local filepath = PlayerAssetFile:GetValidAssetByString(filename);
			if(filepath) then
				page:SetValue("assetfile", commonlib.Encoding.DefaultToUtf8(filename));
				MobPropertyPage.OnChangeAssetFile(skin);
			end
		end
	end);
end