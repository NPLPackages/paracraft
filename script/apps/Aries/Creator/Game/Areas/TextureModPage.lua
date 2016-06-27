--[[
Title: texture pack and mod page
Author(s): LiXizhi
Date: 2013/6/16
Desc:  Letting the user to change the mod and texture pack
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/TextureModPage.lua");
local TextureModPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.TextureModPage");
TextureModPage.ShowPage(true)
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/Files.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/block_types.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/API/FileDownloader.lua");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local FileDownloader = commonlib.gettable("MyCompany.Aries.Creator.Game.API.FileDownloader");
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local TextureModPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.TextureModPage");

TextureModPage.texture_pack_path = "worlds/BlockTextures/";
--TextureModPage.texture_pack_path_official = "worlds/BlockTextures/官方推荐材质/";
TextureModPage.texture_pack_path_official = "worlds/BlockTextures/official/";
TextureModPage.current_texturepack = "";
TextureModPage.last_texturepack = "";

local official_ds = {};
local local_ds = {};
local texture_package_files = {};
local zip_files_map = {};
local defaultPreviewImage = "worlds/BlockTextures/PreviewImage/defaultPreviewImage.png";

-- 0 is local ,1 is official
TextureModPage.current_texturepack_ds = 2;
TextureModPage.texture_index = 1;

NPL.load("(gl)script/apps/Aries/Creator/Game/Materials/TexturePackageList.lua");
local TexturePackageList = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.TexturePackageList");

function TextureModPage.OnInit()
	TextureModPage.OnInitDS();
	TextureModPage.page = document:GetPageCtrl();
end

function TextureModPage.OnInitDS(callbackfun)
	return TexturePackageList.Init(callbackfun);
end

function TextureModPage.ShowPage(bShow)
	local params = {
		url = "script/apps/Aries/Creator/Game/Areas/ChangeTexturePage.html", 
		name = "ChangeTexturePage.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		enable_esc_key = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		bShow = bShow,
		zorder = 1,
		directPosition = true,
			align = "_ct",
			x = -860/2,
			y = -500/2,
			width = 860,
			height = 500,
	};
	TextureModPage.OnInitDS(function (msg)
		if(msg) then
			System.App.Commands.Call("File.MCMLWindowFrame", params);
			TextureModPage.ScrollToSelection();	
		end
	end);
end

-- show the selection. 
function TextureModPage.ScrollToSelection()
	if(TextureModPage.page and TextureModPage.texture_index) then
		if(TextureModPage.CurrentTextureDSIsOfficial()) then
			TextureModPage.page:CallMethod("gvwOfficialTexturePackage", "ScrollToRow", TextureModPage.texture_index);
		elseif(TextureModPage.CurrentTextureDSIsLocal()) then
			TextureModPage.page:CallMethod("gvwLocalTexturePackage", "ScrollToRow", TextureModPage.texture_index);
		end
	end
end

function TextureModPage.CurrentTextureDSIsOfficial()
    if(TextureModPage.tex_type == "official") then
        return true;
    end
    return false;
end

function TextureModPage.CurrentTextureDSIsLocal()
    if(TextureModPage.tex_type == "local") then
        return true;
    end
    return false;
end

function TextureModPage.OnOpenTexturePackFolder()
	ParaIO.CreateDirectory(TextureModPage.texture_pack_path);
    ParaGlobal.ShellExecute("open", ParaIO.GetCurDirectory(0)..TextureModPage.texture_pack_path, "", "", 1); 
end

function TextureModPage.InstallTexturePack(filepath)
	local filename = filepath:match("[/\\]([^/\\]+%.zip)$");
	local name = filepath:match("[/\\]([^/\\]+)%.zip$");
	if(name) then
		name = commonlib.Encoding.DefaultToUtf8(name)
	
		local dest_filename = TextureModPage.texture_pack_path..filename;
		
		if(ParaIO.CopyFile(filepath, dest_filename, true)) then
			_guihelper.MessageBox(format(L"材质包【%s】 安装成功!", name));

			TexturePackageList.AddTexturePackFromFile(filename);
			if(TextureModPage.page) then
				TextureModPage.page:CallMethod("gvwLocalTexturePackage", "DataBind"); 	
			end
			
			--page:Refresh(0.01);
		else
			_guihelper.MessageBox(L"安装失败了, 是否已经有同名文件或者材质正在被使用?");
		end
	end
end

-- call this function to load the last opened texture pack. 
function TextureModPage.LoadTexturePack()
	if(TextureModPage.current_texturepack ~= "") then
		TextureModPage.OnApplyTexturePack(TextureModPage.current_texturepack)
	end
end

function TextureModPage.GetCurrentTexturePack()
	return TextureModPage.current_texturepack;
end

function TextureModPage.GetCurrentTexturePackName()
	return TextureModPage.current_texturepack_name or L"默认";
end

function TextureModPage.GetCurrentTexPackage()
	return TextureModPage.current_texturepackage;
end

function TextureModPage.ResetCurrentTexPackage(package)
	TextureModPage.current_texturepackage = package;
	TextureModPage.tex_type = package.type;
	TextureModPage.texture_index = package.index;
end

function TextureModPage.CloseLastZipPackage()
	if(TextureModPage.lastOpenArchiveDefaultFile) then
		ParaAsset.CloseArchive(TextureModPage.lastOpenArchiveDefaultFile);
		TextureModPage.lastOpenArchiveDefaultFile = nil;
	end
end

function TextureModPage.OnApplyTexturePack(type,path,url,package,text_name,callbackfun)
	if(package) then
		TextureModPage.ResetCurrentTexPackage(package);
		WorldCommon.SetTexturePackageInfo(package);
		package:ApplyTexturePackage();
		if(callbackfun) then
			callbackfun();
		end
	else
		local type = type or WorldCommon.GetWorldInfo().texture_pack_type;
		local path = path or WorldCommon.GetWorldInfo().texture_pack_path;
		local url = url  or WorldCommon.GetWorldInfo().texture_pack_url;
		-- used for fuzzy search
		local utf8_name = utf8_name  or WorldCommon.GetWorldInfo().texture_pack_text;
		TexturePackageList.GetTexturePackage(type,path,url,utf8_name, function (package)
			if(package) then
				TextureModPage.ResetCurrentTexPackage(package);
				WorldCommon.SetTexturePackageInfo(package);
				package:ApplyTexturePackage();
				if(callbackfun) then
					callbackfun();
				end
			end
		end);
	end
	
end

function TextureModPage.GetLocalTexturePackDS(beRefresh)
	local local_ds = TexturePackageList.ds.localDisk;
	return local_ds;
end

function TextureModPage.GetOfficialTexturePackDS()
	local official_ds = TexturePackageList.ds.official;
	return official_ds;
end

function TextureModPage.SelectTexture(name,mcmlNode)
	local package = mcmlNode:GetPreValue("this", true);
	local type = package.type;

    local needRefreshPage = (TextureModPage.tex_type ~= type);
	if(package:IsDownloaded()) then
		TextureModPage.OnApplyTexturePack(nil,nil,nil,package,nil, function ()
			if(needRefreshPage and TextureModPage.page) then
				TextureModPage.page:Refresh(0.01);
				return;
			end
			if(TextureModPage.page) then
				local gridview_name;
				if(TextureModPage.tex_type == "official") then
					gridview_name = "gvwOfficialTexturePackage"
				elseif(TextureModPage.tex_type == "local") then
					gridview_name = "gvwLocalTexturePackage";
				end
				TextureModPage.page:CallMethod(gridview_name, "DataBind"); 
			end
		end);
		
	else
		_guihelper.MessageBox(string.format(L"官方材质包【%s】还没有下载, 是否现在下载?",package.text),function(res)
			if(res == _guihelper.DialogResult.Yes) then
				--TexturePackageList.DownloadPackage(package,function (bSuccess)
				package:DownloadRemoteFile(function (bSuccess)
					if(bSuccess) then
						_guihelper.MessageBox(string.format(L"官方材质包【%s】下载完成",package.text));
						if(TextureModPage.page) then
							TextureModPage.page:Refresh(0.01);
						end
					else
						_guihelper.MessageBox(string.format(L"官方材质包【%s】下载失败",package.text));
					end	
				end);
			end
		end,_guihelper.MessageBoxButtons.YesNo);
	end
end

function TextureModPage.GetCurrentTexturePackDS()
	local ds;
	if(TextureModPage.tex_type == "local") then
		ds = TextureModPage.GetLocalTexturePackDS();
	elseif(TextureModPage.tex_type == "official") then
		ds = TextureModPage.GetOfficialTexturePackDS();
	end
	return ds;
end