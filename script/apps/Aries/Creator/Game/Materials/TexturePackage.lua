--[[
Title: TexturePackage
Author(s): LiPeng, LiXizhi
Date: 2015/1/23
Desc: represent a single downloadable remote/local texturepackage
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Materials/TexturePackage.lua");
local TexturePackage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.TexturePackage");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/Files.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/block_types.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/API/FileDownloader.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Materials/TexturePackageList.lua");
local TexturePackageList = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.TexturePackageList");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local FileDownloader = commonlib.gettable("MyCompany.Aries.Creator.Game.API.FileDownloader");

local TexturePackage = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.TexturePackage"));

-- default texture_pack url and name. This is the package used for newly created world. 
-- we can safely change default texture package without breaking newly created world before. 
TexturePackage.default_texture_path = commonlib.Encoding.Utf8ToDefault("worlds/BlockTextures/official/Paracraft32xMixed.zip");
TexturePackage.default_texture_type = "official";
TexturePackage.default_texture_url  = "http://www.paraengine.com/twiki/pub/CCWeb/RecommendedTextureListData/Paracraft32xMixed.zip";
TexturePackage.default_texture_name = "default"

local defaultPreviewImage = commonlib.Encoding.Utf8ToDefault("worlds/BlockTextures/PreviewImage/defaultPreviewImage.png");

function TexturePackage:ctor()

end

function TexturePackage:Init(type, packagepath, url, bezip, parentfolder, previewimgage, revision, isdownload, name, name_r1, text, author)
	self.type = type;
	self.url = url;
	self.bezip = bezip;
	self.parentfolder = parentfolder;
	self.revision = revision;
	self.previewimgage = previewimgage or "";
	self.defaultPreviewImage = defaultPreviewImage;
	self.isdownload = isdownload or self:IsDownloaded();
	self.name = name or "";
	self.name_r1 = name_r1;
	self.text = text;
	self.author = author or "";
	self.packagepath = packagepath or self:ComputeFilePath();
	return self;
end

local default_package;
function TexturePackage.GetDefaultTexturePackage()
	if(not default_package) then
		default_package = TexturePackage:new():Init(TexturePackage.default_texture_type, TexturePackage.default_texture_path, TexturePackage.default_texture_url, true,
			nil, nil, nil, true, "default", TexturePackage.default_texture_name, nil);
	end
	return default_package;
end

function TexturePackage.CreateFromWorldTag(texture_pack_type, texture_pack_path, texture_pack_url, texture_pack_text)
	if(texture_pack_path and texture_pack_path~="") then
		-- TODO:
	end
end

-- create from a local zip file or folder
function TexturePackage.CreateFromLocal(bezip,name,text,packagepath,parentfolder,previewimgage)
	local type = "local";
	local url = "";
	local isdownload = true;
	local name_r1 = "";
	local revision = "";
	local author = "";
	return TexturePackage:new():Init(type, packagepath, url, bezip, parentfolder, previewimgage, revision, isdownload, name, name_r1, text, author);
end

-- create from a remote url
-- @param url: such as http://www.paraengine.com/twiki/pub/CCWeb/RecommendedTextureListData/Paracraft32xSummerfield.zip#server=self#text=夏日风情材质包#author=lithiumsound#revision=1
function TexturePackage.CreateFromUrl(url,text,revision, author)
	local type = "official";
	local bezip = true;
	local parentfolder = "";
	--local packagepath = _ComputeFilePath(url,revision);
	local name = url:match("([^/]+)%.zip$");
	if(name) then
		name = format("%s_r%s.zip", name, revision);
	end
	local name_r1 = text..".zip";
	return TexturePackage:new():Init(type, nil, url, bezip, parentfolder, nil, revision, nil, name, name_r1, text, author);
end

function TexturePackage.LoadFromHref(href)
	if(not href) then
		return 
	end
	if(href) then
		local url = href:match("(http://.*zip)#server[#=]");
		local revision = href:match("#revision[#=](%d+)") or "";
		local text = href:match("#text[#=]([^#=]+)") or "";
		local author = href:match("#author[#=]([^#=]+)");
		if(url and url~="" and revision and revision ~= "" and text and text ~= "") then
			return TexturePackage.CreateFromUrl(url,text,revision, author);
		end
	end
end

function TexturePackage.LoadFromXmlNode(node)
	local attr = node.attr;
	if(attr) then
		attr.packagepath = commonlib.Encoding.Utf8ToDefault(attr.packagepath or "");
		attr.parentfolder = commonlib.Encoding.Utf8ToDefault(attr.parentfolder or "");
		attr.previewimgage = commonlib.Encoding.Utf8ToDefault(attr.previewimgage or "");
		return TexturePackage:new():Init(attr.type, attr.packagepath, attr.url, attr.bezip, attr.parentfolder, attr.previewimgage, attr.revision, node.isdownload, node.name, node.name_r1, node.text);
	end
end

function TexturePackage:SetParentfolder()
	if(self.bezip) then
		local dir = self.packagepath:match("(.*/)");
		dir = commonlib.Encoding.Utf8ToDefault(dir);
		local result = commonlib.Files.Find({}, dir, 0, 200, "*.", "*.zip");
		if(not result[1]) then
			LOG.std(nil, "info", "TexturePackage", "no folder in dir %s", dir);
			return;
		end
		local name = string.match(result[1]["filename"],"([^/]*)");
		--local parentfolder = dir..name;
		self.parentfolder = dir..name;
		LOG.std(nil, "info", "TexturePackage", "Parent folder: %s", commonlib.Encoding.DefaultToUtf8(self.parentfolder or ""));
	end
end

function TexturePackage:GetTextureFileCount()
	if(self.files) then
		return #(self.files);
	else
		return 0;
	end
end

function TexturePackage:GetPackageTextureFiles()
	if(self.files) then
		return;
	else
		local out;
		if(self.bezip) then
			self:SetParentfolder();
			out = commonlib.Files.Find({}, self.parentfolder, 0, 1000, "*.*", "*.zip");
		else
			out = commonlib.Files.Find({}, self.parentfolder, 0, 1000, "*.*");
		end
		table.sort(out, function(a, b)
			return (a.filename > b.filename)
		end)
		self.files = out;
	end
end

function TexturePackage.LoadFromLocalFile(dir,filename)
	local bezip,packagename,text,packagepath,parentfolder,previewimgage;
	packagename = commonlib.Encoding.DefaultToUtf8(filename);
	text = packagename;
	--local filename_utf8 = commonlib.Encoding.DefaultToUtf8(filename);
	local name = filename:match("(.*)%.zip$");
	if(name) then
		bezip = true;
		previewimgage = name..".png";
		packagepath = dir..filename;
	else
		bezip = false;
		parentfolder = dir..filename;
		packagepath = parentfolder;
		name = filename;
		previewimgage = name..".png";
	end
	previewimgage = commonlib.Encoding.Utf8ToDefault("worlds/BlockTextures/PreviewImage/")..previewimgage;
	return TexturePackage.CreateFromLocal(bezip,packagename,text,packagepath,parentfolder,previewimgage);
end

-- get the preview image path, if nil then ruturn the default preview image;
function TexturePackage:GetPreviewIamge()
	return self.previewimgage or defaultPreviewImage;
end

-- compute preview image path according to the texture package name
function TexturePackage:ComputePreviewImagePath()
	local path = "";
	if(self.name) then
		local imagename = self.name:match("(.*)%.zip$") or self.name;
		path = format("worlds/BlockTextures/PreviewImage/%s.png",imagename);
		path = commonlib.Encoding.Utf8ToDefault(path);
		--previewimgage = "worlds/BlockTextures/PreviewImage/"..previewimgage;
	end
	return path;
end

function TexturePackage:SetPreviewImagePath(images)
	if(not self.previewimgage or (not ParaIO.DoesFileExist(self.previewimgage, true))) then
		local path = self:ComputePreviewImagePath()
		for i = 1,#images do
			if(ParaIO.CopyFile(images[i], path, true)) then
				--TexturePackageList.SetPreviewImage(package_info.type,package_info.index,newImgPath)
				local utf8_path = commonlib.Encoding.DefaultToUtf8(path);
				self.previewimgage = path;
				TexturePackageList.GenerateTexturePackagesInfo();
				LOG.std(nil, "info", "TexturePackage", "successfully create new prview image file in %s", utf8_path);
				break;
			end
		end
		--previewimgage = "worlds/BlockTextures/PreviewImage/"..previewimgage;
	end
end

-- compute local file name for the url
function TexturePackage:ComputeFilePath()
	if(self.type == "official" and self.url and self.url ~= "") then
		local filename = self.url:match("([^/]+)%.zip$");
		return format("worlds/BlockTextures/official/%s_r%s.zip", filename, self.revision);
	end
end

-- @param world: a table containing infor about the remote texturepackage. 
-- @param callbackFunc: function (bSucceed) end
function TexturePackage:DownloadRemoteFile(callbackFunc)
	if(self.isdownload) then
		if(callbackFunc) then
			callbackFunc(true)
		end
		return;
	end

	local function OnCallbackFunc(bSuccess, dest)
		if(bSuccess) then
			self.isdownload = true;
		end
		if(callbackFunc) then
			callbackFunc(bSuccess);
		end
	end

	local src = self.url;
	local dest = self.packagepath or self:ComputeFilePath();
	
	if(ParaIO.DoesFileExist(dest)) then
		LOG.std(nil, "info", "TexturePackage", "texturepackage %s already exist locally", dest);
		OnCallbackFunc(true, dest);
		return;
	else
		LOG.std(nil, "info", "TexturePackage", "downloading texture package from %s", self.url or "");
	end

	self.FileDownloader = self.FileDownloader or FileDownloader:new();
	self.FileDownloader:Init(L"材质包", src, dest, OnCallbackFunc, "access plus 5 mins");
end

function TexturePackage:GetTagType()
end

function TexturePackage.CloseLastPackageZip()
	if(TexturePackage.lastOpenArchiveDefaultFile) then
		ParaAsset.CloseArchive(TexturePackage.lastOpenArchiveDefaultFile);
		TexturePackage.lastOpenArchiveDefaultFile = nil;
	end
end

function TexturePackage:OpenCurrentPackageZip()
	if(self.bezip) then
		LOG.std(nil, "info", "TexturePackage", "open texture package: %s", self.packagepath);
		ParaAsset.OpenArchive(self.packagepath, true);
		TexturePackage.lastOpenArchiveDefaultFile = self.packagepath;
	end
end

function TexturePackage:ApplyTexturePackage()
	local function _ApplyTexturePackage()
		-- TODO: open zip and apply
		-- note: this fix a bug, where missing textures in the new texture pack now always defaults to default texture textures. 
		block_types.restore_texture_pack();
		TexturePackage.CloseLastPackageZip();

		if(self.name == "默认材质" or self.name=="default")  then
			return;
		end
		if(self.bezip) then
			self:OpenCurrentPackageZip()
		end
		self:GetPackageTextureFiles();

		LOG.std(nil, "info", "TexturePackage", "apply texture package: %s (%d textures)", self.name or "", self:GetTextureFileCount());
		
		local previewiamges = {};
		local block_ids = {};
		for _, file in ipairs(self.files) do
			local block_id, part_name,  file_ext = file.filename:match("^(%d+)([^%.]*)%.(%w+)$");
			if(block_id and (file_ext=="png" or file_ext=="jpg" or file_ext=="dds" or file_ext=="bmp")) then
				block_id = tonumber(block_id);

				if(file_ext=="png" and (block_id == 26 or block_id == 28 or block_id == 92)) then
					local previewImg = self.parentfolder.."/"..file.filename;
					table.insert(previewiamges,previewImg);
				end

				local filename = self.parentfolder.."/"..block_id..part_name.."."..file_ext;
				local texture_index = part_name:match("^_(%d+)_");
				if(texture_index) then
					texture_index = tonumber(texture_index);
				else
					texture_index = nil;
				end
				local isTexSequence = part_name:match("_a(%d%d%d)$");
				if(texture_index or not block_ids[block_id]) then
					block_ids[block_id] = true;
					local bReplaceAllBlocks;
					if(isTexSequence) then
						bReplaceAllBlocks = true;
					end
					block_types.replace_texture(block_id, filename, texture_index, bReplaceAllBlocks);
				end	
			end
		end

		self:SetPreviewImagePath(previewiamges);

		NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
		local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
		GameLogic.GetEvents():DispatchEvent({type = "block_texture_pack_changed" , data = {}});
		GameLogic:texturePackChanged();
	end

	self:DownloadRemoteFile(function(bSuccess)
		if(bSuccess) then
			_ApplyTexturePackage()
		end
	end);
end



function TexturePackage:IsDownloaded()
	if(self.type == "local") then
		return true;
	end
	return self:GetDownloadPercentage() == 100;
end

-- @return [-1,100]. return -1 if not downloaded. 100 if already downloaded.  
function TexturePackage:GetDownloadPercentage()
	if(self.isFinished) then
		return 100;
	end
	local filename = self.packagepath;
	if(filename) then
		if(ParaIO.DoesFileExist(filename)) then	
			self.isFinished = true;
			return 100;
		elseif(self.FileDownloader) then
			local curSize = self.FileDownloader:GetCurrentFileSize()
			local totalSize = self.FileDownloader:GetTotalFileSize()
			if(curSize > 0) then
				return math.floor((curSize / totalSize)*100);
			else
				return 0;
			end
		end
	end
	return -1;
end