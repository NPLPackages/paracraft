--[[
Title: Open Model Animations Dialog
Author(s): 
Date: 
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/ActorAnimationsDialog.lua");
local ActorAnimationsDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.ActorAnimationsDialog");
ActorAnimationsDialog.ShowPageForEntity(entity, function(animId)   end)
ActorAnimationsDialog.ShowPage(modelName, skin, options, OnClose, text)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/ActorAnimationsDialog.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerSkins.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/EntityAnimation.lua");
local EntityAnimation = commonlib.gettable("MyCompany.Aries.Game.Effects.EntityAnimation");
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
local PlayerSkins = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerSkins")
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local ActorAnimationsDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.ActorAnimationsDialog");

local page;
function ActorAnimationsDialog.OnInit()
	page = document:GetPageCtrl();
end

ActorAnimationsDialog.anims_ds = {
--	{name="anim", attr={text=L"待机", id=0, selected=true}},
--	{name="anim", attr={text=L"走路", id=4,}},
--	{name="anim", attr={text=L"跑步", id=5,}},
}

function ActorAnimationsDialog.GetModelAnimDs()
	return ActorAnimationsDialog.anims_ds;
end

--@param OnClose: function(animId) end 
function ActorAnimationsDialog.ShowPageForEntity(entity, OnClose, text)
	if(not entity) then
		return
	end
			
	-- get {{value, text}} array of all animations in the asset file. 
	local options = {alignment="_lt"};
	local assetfile = entity:GetMainAssetPath();
	local skin = entity:GetSkin();

	if(assetfile) then
		assetfile = PlayerAssetFile:GetFilenameByName(assetfile)
		NPL.load("(gl)script/ide/System/Scene/Assets/ParaXModelAttr.lua");
		local ParaXModelAttr = commonlib.gettable("System.Scene.Assets.ParaXModelAttr");
		local attr = ParaXModelAttr:new():initFromAssetFile(assetfile);
		local animations = attr:GetAnimations()
		if(animations) then
			for _, anim in ipairs(animations) do
				if(anim.animID) then
					options[#options+1] = {value = anim.animID, text = EntityAnimation.GetAnimTextByID(anim.animID, assetfile)}
				end
			end
			table.sort(options, function(a, b)
				return a.value < b.value;
			end)
		end
		if(assetfile:match("%.bmax$")) then
			-- we will add some more default values
			local hasAnims = {};
			for _, option in ipairs(options) do
				hasAnims[option.value] = true;
			end
			local default_anim_placeholders = {0,4,5,13, 37,38,39,41,42,43,44,45,91,135,153, 154, 155, 156,}
			for _, animId in ipairs(default_anim_placeholders) do
				if(not hasAnims[animId]) then
					options[#options+1] = {value = animId, text = EntityAnimation.GetAnimTextByID(animId, assetfile)};
				end
			end
		end
		text = text or L"请选择动画ID或名称";
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/ActorAnimationsDialog.lua");
		local ActorAnimationsDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.ActorAnimationsDialog");
		ActorAnimationsDialog.ShowPage(assetfile, skin, options, function(result)
			if(result and result ~= "") then
				result = EntityAnimation.CreateGetAnimId(result);	
				if( type(result) == "number") then
					result = tonumber(result);
					if(OnClose) then
						OnClose(result)
					end
				end
			end
		end, text);
	end
end

--@param options: array of animation text and id pairs. it can also contain options.alignment = "_lt", 
function ActorAnimationsDialog.ShowPage(modelName, skin, options, OnClose, text)
	ActorAnimationsDialog.result = nil;
	ActorAnimationsDialog.text = text;

	options = options or {};
	local width, height = 480, 360;
	local x, y;
	if(options.alignment == "_lt") then
		x, y = 20, 100;
	else
		x, y = - width / 2, - height / 2;
	end

	local params = {
			url = "script/apps/Aries/Creator/Game/GUI/ActorAnimationsDialog.html", 
			name = "ActorAnimationsDialog.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			click_through = false, 
			enable_esc_key = true,
			bShow = true,
			isTopLevel = true,
			---app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = options.alignment or "_ct",
				x = x,
				y = y,
				width = width,
				height = height,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	params._page.OnClose = function()
		if(OnClose) then
			OnClose(ActorAnimationsDialog.result);
		end
	end

	ActorAnimationsDialog.UpdateModel(modelName, skin, options);
end

function ActorAnimationsDialog.GetText()
	return ActorAnimationsDialog.text or L"请选择动画ID或名称:";
end

function ActorAnimationsDialog.OnOK()
	if(page) then
		page:CloseWindow();
	end
end

-- @param modelName: filename of the model, if nil, it is ActorAnimationsDialog.modelFilename
function ActorAnimationsDialog.UpdateModel(modelName, skin, options)
	local filepath = PlayerAssetFile:GetValidAssetByString(modelName);
	if(filepath) then
		local ctl = page:FindControl("AssetPreview");
		if(ctl) then
			local ReplaceableTextures, CCSInfoStr, CustomGeosets;
			if(PlayerAssetFile:IsCustomModel(filepath)) then
				CCSInfoStr = PlayerAssetFile:GetDefaultCCSString()
			elseif(PlayerAssetFile:HasCustomGeosets(filepath)) then
				CustomGeosets = skin or PlayerAssetFile:GetDefaultCustomGeosets();
			elseif(PlayerSkins:CheckModelHasSkin(filepath)) then
				-- TODO:  hard code worker skin here
				ReplaceableTextures = {[2] = skin or PlayerSkins:GetSkinByID(12)};
			end
			local skin_ = CustomCharItems:GetSkinByAsset(filepath);
			if (skin_) then
				filepath = CustomCharItems.defaultModelFile;
				CustomGeosets = CustomGeosets or skin_;
			end
			
			ctl:ShowModel({AssetFile = filepath, IsCharacter=true, x=0, y=0, z=0, ReplaceableTextures=ReplaceableTextures, CCSInfoStr=CCSInfoStr, CustomGeosets = CustomGeosets});

			ActorAnimationsDialog.RefreshAnims(filepath, options);
		end
	end	
end

function ActorAnimationsDialog.RefreshAnims(filepath, options)
	if(not page) then
		return
	end
	ActorAnimationsDialog.curModelAssetFile = filepath;
	local self = ActorAnimationsDialog;
	local asset = ParaAsset.LoadParaX(filepath, filepath);
	asset:LoadAsset();
	if(asset:IsValid() and asset:IsLoaded())then
		if(options) then
			local animIds = ActorAnimationsDialog.GetModelAnimDs();
			table.clear(animIds)
			for i, anim in ipairs(options) do
				animIds[i] = {name="anim", attr={text=anim.text, id=anim.value}}
			end
			page:CallMethod("tvwAnimIds", "DataBind", true);
			return true;
		end
	elseif(asset:IsValid()) then
		self.curFilePath = filepath;
		if(not tryCount) then
			-- only try 5 times
			self.tryCount = 5;
		end
		self.mytimer = self.mytimer or commonlib.Timer:new({callbackFunc = function(timer)
			if(self.tryCount and self.tryCount > 1) then
				ActorAnimationsDialog.RefreshAnims(self.curFilePath, self.tryCount - 1)
			end
		end})
		self.mytimer:Change(500);
	end
end

function ActorAnimationsDialog.OnSelectAnimId(id)
	if(page and type(id) == "number") then
		local ctl = page:FindControl("AssetPreview");
		if(ctl) then
			local obj = ctl:GetObject()
			if(obj and obj:IsValid()) then
				obj:SetField("AnimID", id);
				ActorAnimationsDialog.result = id;
			end
		end
	end
end
