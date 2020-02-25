--[[
Title: edit skins (replaceable textures) in ActorNPC
Author(s): LiXizhi
Date: 2020/2/11
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/EditSkinPage.lua");
local EditSkinPage = commonlib.gettable("MyCompany.Aries.Game.Movie.EditSkinPage");
EditSkinPage.ShowPage(function(value)
	
end, old_value, "custom title")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerSkins.lua");
local PlayerSkins = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerSkins");
			
local EditSkinPage = commonlib.gettable("MyCompany.Aries.Game.Movie.EditSkinPage");

-- data source 
local ds_skins = {
	{id=2, filename="", hasSkin=false},
	{id=3, filename="", hasSkin=false},
	{id=4, filename="", hasSkin=false},
	-- {id=0, filename="", hasSkin=false}, -- ParaX does not support R0 by design
	{id=1, filename="", hasSkin=false},
	{id=5, filename="", hasSkin=false},
}

local page;
function EditSkinPage.OnInit()
	page = document:GetPageCtrl();
end

function EditSkinPage.GetTitle()
	return EditSkinPage.title or "";
end

function EditSkinPage.GetSkinDS(index)
	if(not index) then
		return #ds_skins;
	else
		return ds_skins[index];
	end
end


function EditSkinPage.OnChangeFilename(id, mcmlNode, uiobj)
	EditSkinPage.SetSkin(tonumber(id), uiobj and uiobj:GetText())
end


function EditSkinPage.GetSkin(id)
	for _, skin in ipairs(ds_skins) do
		if(skin.id == id) then
			return skin;
		end
	end
end

function EditSkinPage.SetSkin(id, filename)
	local skin = EditSkinPage.GetSkin(id)
	if(skin) then
		skin.filename = filename or "";
	end
end

function EditSkinPage.UpdateDataSourceFromValue(old_value)
	for _, skin in ipairs(ds_skins) do
		skin.filename = "";
	end
	if(old_value:match("^(%d+):[^;+]")) then
		for id, filename in old_value:gmatch("(%d+):([^;]+)") do
			id = tonumber(id)
			EditSkinPage.SetSkin(id, filename)
		end
	else
		EditSkinPage.SetSkin(2, old_value)
	end
end

function EditSkinPage.GetValueFromDataSource()
	local value = ""
	for _, skin in ipairs(ds_skins) do
		if(skin.filename ~= "") then
			local filename = skin.filename;
			if(filename:match("^%d+$")) then
				filename = PlayerSkins:GetSkinByString(filename);
			end
			-- trim strings
			filename = filename:gsub("%s+$", "")
			filename = filename:gsub("^%s+", "")
			value = value..format("%d:%s;", skin.id, filename)
		end
	end
	value = value:gsub("^2:([^;]+);$", "%1")
	return value;
end

-- @param OnOK: function(values) end 
-- @param old_value: "id:filename;id:filename;" or just "filename"
-- @param title: custom title 
function EditSkinPage.ShowPage(OnOK, old_value, title, assetFilename)
	EditSkinPage.result = nil;
	EditSkinPage.title = title;
	old_value = old_value or "";
	EditSkinPage.last_value = old_value;
	EditSkinPage.assetFilename = assetFilename;

	for _, skin in ipairs(ds_skins) do
		skin.hasSkin = false;
	end

	if (assetFilename) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerSkins.lua");
		local PlayerSkins = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerSkins")
		local model = PlayerSkins:GetModel(assetFilename)
		if(model) then
			for id, skins in pairs(model) do
				for _, skin in ipairs(ds_skins) do
					if(skin.id == id) then
						skin.hasSkin = true;
					end
				end
			end
		end
	end
	
	EditSkinPage.UpdateDataSourceFromValue(old_value)
	
	local params = {
		url = "script/apps/Aries/Creator/Game/Movie/EditSkinPage.html", 
		name = "EditSkinPage.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		bToggleShowHide=false, 
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = true,
		click_through = false, 
		enable_esc_key = true,
		bShow = true,
		isTopLevel = true,
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		directPosition = true,
			align = "_ct",
			x = -256,
			y = -200,
			width = 512,
			height = 400,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	params._page.OnClose = function()
		if(EditSkinPage.result == "OK") then
			OnOK(EditSkinPage.last_value);
		end
	end

end


function EditSkinPage.OnOK()
	if(page) then
		EditSkinPage.last_value = EditSkinPage.GetValueFromDataSource() or "";
		EditSkinPage.result = "OK";
		page:CloseWindow();
	end
end

function EditSkinPage.OnClose()
	page:CloseWindow();
end


function EditSkinPage.OnClickOpenTexture(id)
	local skin = EditSkinPage.GetSkin(tonumber(id));
	if(skin) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenFileDialog.lua");
		local OpenFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenFileDialog");
		OpenFileDialog.ShowPage(title, function(result)
			if(result and result~="") then
				if(result:match("^%d+$")) then
					result = PlayerSkins:GetSkinByString(result);
				end
				-- trim strings
				result = result:gsub("%s+$", "")
				result = result:gsub("^%s+", "")
				if(skin.filename ~= result) then
					skin.filename = result;
					page:Refresh(0.01);
				end
			end
		end, skin.filename, L"贴图文件", "texture");
	end
end

function EditSkinPage.OnClickSelectSkin(id)
	id = tonumber(id:match("%d+"));
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerSkins.lua");
	local PlayerSkins = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerSkins")
	local skins = PlayerSkins:GetSkinsById(EditSkinPage.assetFilename, id)
	if(skins) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/SelectSkinPage.lua");
		local SelectSkinPage = commonlib.gettable("MyCompany.Aries.Game.Movie.SelectSkinPage");
		SelectSkinPage.ShowPage(function(value)
			if(type(value) == "table" and value.filename) then
				EditSkinPage.SetSkin(id, value.filename)
				if(page) then
					page:Refresh(0.01)
				end
			end
		end, skins)
	end
end

function EditSkinPage.OnClickHowToSkin()
	ParaGlobal.ShellExecute("open", L"https://keepwork.com/official/docs/tutorials/create_get_skins", "", "", 1)
end