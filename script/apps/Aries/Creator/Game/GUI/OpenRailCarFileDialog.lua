--[[
Title: Open Asset File Dialog
Author(s): LiXizhi
Date: 2018/8/13
Desc: Open Asset File Dialog
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenRailCarFileDialog.lua");
local OpenRailCarFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenRailCarFileDialog");
OpenRailCarFileDialog.ShowPage("Please enter text", function(result)
	
end, default_text, title, filters)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenRailCarFileDialog.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerSkins.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
local PlayerSkins = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerSkins")
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");

local OpenRailCarFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenRailCarFileDialog");
-- whether in save mode. 
OpenRailCarFileDialog.IsSaveMode = false;

OpenRailCarFileDialog.category_index = 1;

OpenRailCarFileDialog.categories = {
	{name = "RailCar", text = L"全部", colour="#ffffff", },
};

OpenRailCarFileDialog.IndexLocal = 1;
OpenRailCarFileDialog.IndexCommon = 2;
OpenRailCarFileDialog.IndexPeople = 3;
OpenRailCarFileDialog.IndexAnimals = 4;
OpenRailCarFileDialog.IndexFantasy = 5;
OpenRailCarFileDialog.IndexVehicles = 6;
OpenRailCarFileDialog.IndexEffects = 7;


local page;
function OpenRailCarFileDialog.OnInit()
	page = document:GetPageCtrl();
end

-- @param filterName: "model", "bmax", "audio", "texture", "xml", "script"
function OpenRailCarFileDialog.GetFilters(filterName)
	if(filterName == "model") then
		return {
			-- {L"全部文件(*.fbx,*.x,*.bmax,*.xml)",  "*.fbx;*.x;*.bmax;*.xml", exclude="*.blocks.xml"},
			{L"全部文件(*.fbx,*.FBX,*.x,*.bmax)",  "*.fbx;*.FBX;*.x;*.bmax", exclude="*.blocks.xml"},
			{L"FBX模型(*.fbx)",  "*.fbx"},
			{L"bmax模型(*.bmax)",  "*.bmax"},
			{L"ParaX模型(*.x,*.xml)",  "*.x;*.xml", exclude="*.blocks.xml"},
			{L"block模版(*.blocks.xml)",  "*.blocks.xml"},
		};
	elseif(filterName == "modelStrict") then
		return {
			{L"全部文件(*.fbx,*.x,*.bmax)",  "*.fbx;*.x;*.bmax"},
		};
	elseif(filterName == "bmax") then
		return {
			{L"bmax模型(*.bmax)",  "*.bmax"},
		};
	elseif(filterName == "script" or filterName == "lua") then
		return {
			{L"(*.lua)",  "*.lua"},
		};
	elseif(filterName == "audio") then
		return {
			{L"全部文件(*.mp3,*.ogg,*.wav)",  "*.mp3;*.ogg;*.wav"},
			{L"mp3(*.mp3)",  "*.mp3"},
			{L"ogg(*.ogg)",  "*.ogg"},
			{L"wav(*.wav)",  "*.wav"},
		};
	elseif(filterName == "texture") then
		return {
			{L"全部文件(*.png,*.jpg)",  "*.png;*.jpg"},
			{L"png(*.png)",  "*.png"},
			{L"jpg(*.jpg)",  "*.jpg"},
		};
	elseif(filterName == "xml") then
		return {
			{L"全部文件(*.xml)",  "*.xml"},
		};
	end
end

function OpenRailCarFileDialog.GetCategoryButtons()
	return OpenRailCarFileDialog.categories;
end

OpenRailCarFileDialog.anims_ds = {
--	{name="anim", attr={text=L"待机", id=0, selected=true}},
--	{name="anim", attr={text=L"走路", id=4,}},
--	{name="anim", attr={text=L"跑步", id=5,}},
}

function OpenRailCarFileDialog.GetModelAnimDs()
	return OpenRailCarFileDialog.anims_ds;
end

-- @param OnClose: function(filename)
-- @param default_text: default text to be displayed. 
-- @param filters: "model", "bmax", "audio", "texture", "xml", nil for any file, or filters table
-- @param editButton: this can be nil or a function(filename) end or {text="edit", callback=function(filename) end}
-- @param categories: Custom Directory
-- the callback function can return a new filename to be displayed. 
function OpenRailCarFileDialog.ShowPage(text, OnClose, default_text, title, filters, IsSaveMode, editButton)
	OpenRailCarFileDialog.category_index = 1;
	OpenRailCarFileDialog.result = nil;
	OpenRailCarFileDialog.text = text;
	OpenRailCarFileDialog.title = title;
	OpenRailCarFileDialog.modelFilename = nil;
	if(type(filters) == "string") then
		filters = OpenRailCarFileDialog.GetFilters(filters)
	end
	OpenRailCarFileDialog.filters = filters;
	OpenRailCarFileDialog.editButton = editButton;
	OpenRailCarFileDialog.IsSaveMode = IsSaveMode == true;

	local params = {
			url = "script/apps/Aries/Creator/Game/GUI/OpenRailCarFileDialog.html", 
			name = "OpenRailCarFileDialog.ShowPage", 
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
				x = -680/2,
				y = -450/2,
				width = 680,
				height = 470,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	if(default_text) then
		OpenRailCarFileDialog.SetText(default_text);
	end
	params._page.OnClose = function()
		if(OnClose) then
			OnClose(OpenRailCarFileDialog.result);
		end
	end
	
	params._page.OnDropFiles = function(filelist)
		if filelist then
			local _, firstFile = next(filelist);
			
			if(firstFile and page) then
				local fileItem = Files.ResolveFilePath(firstFile);
				if(fileItem and fileItem.relativeToWorldPath) then
					local filename = fileItem.relativeToWorldPath;
					OpenRailCarFileDialog.SetText(filename);
				end
			end
			
			return true;
		else
			return false;
		end
	end
end

-- get model parameters. 
function OpenRailCarFileDialog.GetModelParams()
	
end

-- TODO: 
function OpenRailCarFileDialog.ShowModelInfo()
	if(OpenRailCarFileDialog.curModelAssetFile and OpenRailCarFileDialog.curModelAssetFile~="") then
		NPL.load("(gl)script/kids/3DMapSystemUI/Creator/Objects/ObjectInspectorPage.lua");
		-- display object inspector page to generate thumbnail icon, etc.  
		System.App.Commands.Call("File.MCMLWindowFrame", {
			url="script/apps/Aries/Creator/Assets/ObjectInspectorPage.html",
			name="Aries.ObjectInspectorPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			text = "查看物品",
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			zorder = 10,
			directPosition = true,
				align = "_ct",
				x = -140/2,
				y = -340/2,
				width = 140,
				height = 340,
		});
		Map3DSystem.App.Creator.ObjectInspectorPage.SetModel(OpenRailCarFileDialog.curModelAssetFile);
	end
end

function OpenRailCarFileDialog.OnOK()
	if(page) then
		local text = commonlib.Encoding.Utf8ToDefault(OpenRailCarFileDialog.select_file_name)
		local filepath = PlayerAssetFile:GetValidAssetByString(text);
		if(filepath) then
			local fileItem = Files.ResolveFilePath(filepath);
			if(fileItem and fileItem.relativeToWorldPath) then
				filepath = fileItem.relativeToWorldPath;
			end
		end
		if(not filepath and OpenRailCarFileDialog.IsSaveMode) then
			filepath = text;
		end
		OpenRailCarFileDialog.result = filepath;
		page:CloseWindow();
	end
end

function OpenRailCarFileDialog.OnClickEdit()
	local filename = commonlib.Encoding.Utf8ToDefault(OpenRailCarFileDialog.select_file_name)
	local callback;
	if(type(OpenRailCarFileDialog.editButton) == "function") then
		callback = OpenRailCarFileDialog.editButton;
	elseif(type(OpenRailCarFileDialog.editButton) == "table") then
		callback = OpenRailCarFileDialog.editButton.callback;
	end
	if(callback) then
		local new_filename = callback(filename);
		if(new_filename and new_filename~=filename) then
			OpenRailCarFileDialog.SetText(new_filename);
		end
	end
end

function OpenRailCarFileDialog.SetModelFilename(filename)
	if(OpenRailCarFileDialog.modelFilename ~= filename) then
		OpenRailCarFileDialog.modelFilename = filename;
		if(filename) then
			OpenRailCarFileDialog.UpdateModel();
		end
	end
end

function OpenRailCarFileDialog.GetModelFilename()
	return OpenRailCarFileDialog.modelFilename;
end

-- @param modelName: filename of the model, if nil, it is OpenRailCarFileDialog.modelFilename
function OpenRailCarFileDialog.UpdateModel(modelName)
	local filepath = PlayerAssetFile:GetValidAssetByString(modelName or OpenRailCarFileDialog.modelFilename);
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

			local skin = CustomCharItems:GetSkinByAsset(filepath);
			if (skin) then
				filepath = CustomCharItems.defaultModelFile;
				CustomGeosets = skin;
			end

			ctl:ShowModel({AssetFile = filepath, IsCharacter=true, x=0, y=0, z=0, ReplaceableTextures=ReplaceableTextures, CCSInfoStr=CCSInfoStr, CustomGeosets = CustomGeosets});

			OpenRailCarFileDialog.RefreshAnims(filepath);
		end
	end	
end

function OpenRailCarFileDialog.SetText(text)
	if(text) then
		OpenRailCarFileDialog.select_file_name = text
		OpenRailCarFileDialog.UpdateModel(text)
	end
end

function OpenRailCarFileDialog.RefreshAnims(filepath, tryCount)
	if(not page) then
		return
	end
	OpenRailCarFileDialog.curModelAssetFile = filepath;
	local self = OpenRailCarFileDialog;
	self.tryCount = tryCount;
	local asset = ParaAsset.LoadParaX(filepath, filepath);
	asset:LoadAsset();
	if(asset:IsValid() and asset:IsLoaded())then
		local polyCount = asset:GetAttributeObject():GetField("PolyCount", 0);
		if(page) then
			page:SetUIValue("PolyCount", polyCount);
		end
		local options = OpenRailCarFileDialog.GetAnimIdsByFilename(filepath);
		if(options) then
			local animIds = OpenRailCarFileDialog.GetModelAnimDs();
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
				OpenRailCarFileDialog.RefreshAnims(self.curFilePath, self.tryCount - 1)
			end
		end})
		self.mytimer:Change(500);
	end
end

local allFiles;
local filteredFiles;
function OpenRailCarFileDialog.GetAllFiles()
	if(not allFiles) then
		allFiles = {};
		
		-- fill all categories from PlayerAsset files
		NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerAssetFile.lua");
		local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
		
		for i=1, #OpenRailCarFileDialog.categories do
			local category = OpenRailCarFileDialog.categories[i];
			local idx = i;
			allFiles[idx] = allFiles[idx] or {};
			local commonFiles = allFiles[idx];
			commonFiles.name = "category";
			commonFiles.attr = {text=category.text, expanded=false, count=0};

			if(PlayerAssetFile:HasCategory(category.name)) then
				local items = PlayerAssetFile:GetCategoryItems(category.name);
				for i, item in ipairs(items) do
					local assetfile = item.filename;
					if(assetfile and assetfile~="") then
						commonFiles[#commonFiles+1] = {name="commonfile", attr={text=item.displayname or item.filename, filename=item.name or item.filename}};
					end
				end
			end
			commonFiles.attr.count = #commonFiles;
		end

		if allFiles[1] then
			allFiles[1].attr.expanded = true;
		end
		
	end
	return allFiles;
end


function OpenRailCarFileDialog.OnChangeCategory(index)
end

function OpenRailCarFileDialog.OnSelectAnimId(id)
	if(page and type(id) == "number") then
		local ctl = page:FindControl("AssetPreview");
		if(ctl) then
			local obj = ctl:GetObject()
			if(obj and obj:IsValid()) then
				obj:SetField("AnimID", id);
			end
		end
	end
end

function OpenRailCarFileDialog.GetAnimIdsByFilename(assetfile)
	NPL.load("(gl)script/ide/System/Scene/Assets/ParaXModelAttr.lua");
	local ParaXModelAttr = commonlib.gettable("System.Scene.Assets.ParaXModelAttr");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/EntityAnimation.lua");
	local EntityAnimation = commonlib.gettable("MyCompany.Aries.Game.Effects.EntityAnimation");

	local attr = ParaXModelAttr:new():initFromAssetFile(assetfile);
	local animations = attr:GetAnimations()
	if(animations) then
		local options = {};
		for _, anim in ipairs(animations) do
			if(anim.animID) then
				options[#options+1] = {value = anim.animID, text = EntityAnimation.GetAnimTextByID(anim.animID, assetfile)}
			end
		end
		table.sort(options, function(a, b)
			return a.value < b.value;
		end)
		return options;
	end
end

local filteredFiles = nil;
function OpenRailCarFileDialog.GetAllFilesWithFilters()
	return filteredFiles and filteredFiles or OpenRailCarFileDialog.GetAllFiles()
end

function OpenRailCarFileDialog.Refresh()
	if(page) then
		page:Refresh(0.01);
	end
end

function OpenRailCarFileDialog.OnTakeSnapShot()
	local ctl = page and page:FindControl("AssetPreview");
	if(ctl) then
		local text = commonlib.Encoding.Utf8ToDefault(OpenRailCarFileDialog.select_file_name)
		text = text or "default"
		text = text:match("[^/\\]+$") or "default";
		text = text:match("^[^%.]+") or text;
		text = text..".png"
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenFileDialog.lua");
		local OpenFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenFileDialog");
		OpenFileDialog.ShowPage("", function(result)
			if(result and result~="") then
				local filename = Files.WorldPathToFullPath(result)
				if(filename) then
					ctl:SaveToFile(filename, 64)
					GameLogic.AddBBS(nil, format("缩略图保存到: %s", filename, 4000, "0 255 0"));
				end
			end
		end, text, nil, "texture", true)
	end
end