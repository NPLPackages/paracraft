--[[
Title: Open Model Animations Dialog
Author(s): 
Date: 
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/ActorAnimationsDialog.lua");
local ActorAnimationsDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.ActorAnimationsDialog");
ActorAnimationsDialog.ShowPage("", function(result)
	
end)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/ActorAnimationsDialog.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerSkins.lua");
local PlayerSkins = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerSkins")
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
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

function ActorAnimationsDialog.ShowPage(modelName, options, OnClose, text)
	ActorAnimationsDialog.result = nil;
	ActorAnimationsDialog.text = text;

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
				align = "_ct",
				x = -480/2,
				y = -360/2,
				width = 480,
				height = 360,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	params._page.OnClose = function()
		if(OnClose) then
			OnClose(ActorAnimationsDialog.result);
		end
	end

	ActorAnimationsDialog.UpdateModel(modelName, options);
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
function ActorAnimationsDialog.UpdateModel(modelName, options)
	local filepath = PlayerAssetFile:GetValidAssetByString(modelName);
	if(filepath) then
		local ctl = page:FindControl("AssetPreview");
		if(ctl) then
			local ReplaceableTextures, CCSInfoStr, CustomGeosets;
			if(PlayerAssetFile:IsCustomModel(filepath)) then
				CCSInfoStr = PlayerAssetFile:GetDefaultCCSString()
			elseif(PlayerAssetFile:HasCustomGeosets(filepath)) then
				CustomGeosets = PlayerAssetFile:GetDefaultCustomGeosets();
			elseif(PlayerSkins:CheckModelHasSkin(filepath)) then
				-- TODO:  hard code worker skin here
				ReplaceableTextures = {[2] = PlayerSkins:GetSkinByID(12)};
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
