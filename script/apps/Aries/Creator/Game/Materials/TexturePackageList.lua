--[[
Title: TexturePackageList
Author(s): LiPeng
Date: 2015/1/23
Desc: get texture package list from the wiki page and local files;

---++ how values in html page is parsed. 
---+++ texture package
	href="filename#server=1000#text=text#author=author#revision=author"

---++ example
	http://www.paraengine.com/twiki/pub/CCWeb/RecommendedTextureListData/Paracraft16xBlockConcept.zip#server=self#text=blocktexture#author=Jakob.z#revision=2

Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Materials/TexturePackageList.lua");
local TexturePackageList = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.TexturePackageList");
TexturePackageList.LoadTexturePackageList();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Materials/TexturePackage.lua");
local TexturePackage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.TexturePackage");
local TexturePackageList = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.TexturePackageList");

local info_path = "worlds/BlockTextures/PackagesInfo.xml";
-- official texture is always fetched remotely.
local wiki_url = "http://www.paraengine.com/twiki/bin/view/CCWeb/RecommendedTextureListData";
local official_text_cache_policy = "access plus 7 days";

local defaultPreviewImage = "worlds/BlockTextures/PreviewImage/defaultPreviewImage.png";


TexturePackageList.ds = {
	official = {},
	localDisk = {},
};

TexturePackageList.texture_pack_path = "worlds/BlockTextures/";

local tex_package_map = {};

local needRefreshInfoFile = false;
local hasInfoFile = false;
local callbackfunList = {};

--  @param callbackfun: function(bInited)   end
-- @return true if callbackFunc is invoked before the function returned
function TexturePackageList.Init(callbackfun)
	if(TexturePackageList.inited) then
		if(callbackfun) then
			callbackfun(true);
		end
		return true;
	else
		TexturePackageList.AddInitCallback(callbackfun);

		if(TexturePackageList.initing) then
			return false;
		else
			TexturePackageList.initing = true;
			TexturePackageList.LoadTexturePackageList(function ()
				LOG.std(nil, "info", "TexturePackageList", "TexturePackageList initialized");
				TexturePackageList.inited = true;
				TexturePackageList.InvokeInitCallbacks(true);
				return true;
			end)
		end
	end
end

local init_callbacks = {};
function TexturePackageList.AddInitCallback(callbackfun)
	if(callbackfun) then
		init_callbacks[#init_callbacks+1] = callbackfun;
	end
end

function TexturePackageList.InvokeInitCallbacks(bSucceed)
	for _, callbackfun in ipairs(init_callbacks) do
		callbackfun(bSucceed);
	end
	init_callbacks = {};
end

function TexturePackageList.LoadTexturePackageList(callbackfun)
	LOG.std(nil, "info", "TexturePackageList", "LoadTexturePackageList");

	ParaIO.CreateDirectory(TexturePackageList.texture_pack_path);
	if(not ParaIO.DoesFileExist(defaultPreviewImage, true)) then
		ParaIO.CopyFile("Texture/blocks/grass_top.png", defaultPreviewImage, true);
	end

	local local_ds = {};
	local official_ds = {};
	TexturePackageList.ds.localDisk = local_ds;
	TexturePackageList.ds.official = official_ds;
	if(not ParaIO.DoesFileExist(info_path, true)) then
		TexturePackageList.GetLocalTexturePackDS(local_ds);
		TexturePackageList.GetOfficialTexturePackDS(official_ds,function ()
			TexturePackageList.GenerateTexturePackagesInfo(nil, official_ds,local_ds)
			if(callbackfun) then
				callbackfun()
			end	
		end);
	else
		hasInfoFile = true;
		TexturePackageList.GetLocalTexturePackDS(local_ds);
		TexturePackageList.LoadTexturePackagesInfoFromFile(nil,official_ds,local_ds);
		TexturePackageList.GetOfficialTexturePackDS(official_ds,function ()
			TexturePackageList.RefreshTexturePackageDSInfo(true);
			if(callbackfun) then
				callbackfun()
			end
		end);		
	end
end

function TexturePackageList.GetTotalDS()
	if(not TexturePackageList.total_ds) then
		local ds = {};
		local local_ds = TexturePackageList.ds.localDisk;
		for i = 1,#local_ds do
			ds[#ds+1] = local_ds[i];
			ds[#ds]["new_index"] = #ds;
		end

		local official_ds = TexturePackageList.ds.official;
		for i = 1,#official_ds do
			ds[#ds+1] = official_ds[i];
			ds[#ds]["new_index"] = #ds;
		end

		TexturePackageList.total_ds = ds;
	end
	return TexturePackageList.total_ds;
end

function TexturePackageList.GetLocalTexturePackDS(ds)
	local str = commonlib.Encoding.Utf8ToDefault(L"默认材质");
	
	local default_tex = TexturePackage:new():Init("local", str, nil, false, str, nil, nil, true, L"默认材质", nil, L"默认材质");

	TexturePackageList.AddTexturePackage(default_tex);
	local dir_default = commonlib.Encoding.Utf8ToDefault(TexturePackageList.texture_pack_path);
	local result = commonlib.Files.Find({}, dir_default, 0, 1000, "*.*")
	local _, file
	for _, file in ipairs(result) do 
		local filename_utf8 = commonlib.Encoding.DefaultToUtf8(file.filename);
		if(filename_utf8 == L"官方推荐材质" or filename_utf8 == "official" or filename_utf8 == "PackagesInfo.xml" or filename_utf8 == "PreviewImage") then
			
		else
			--local dir = string.format();
			local package = TexturePackage.LoadFromLocalFile(dir_default,file.filename);
			if(package) then
				TexturePackageList.AddTexturePackage(package);
			end
		end
	end
end

-- load official list form HTTP url
function TexturePackageList.GetOfficialTexturePackDS(ds,callbackfun)
	local url = wiki_url;
	
	NPL.load("(gl)script/kids/3DMapSystemApp/localserver/URLResourceStore.lua");

	local ls = System.localserver.CreateStore(nil, 3, "userdata");
	if(ls) then
		local mytimer;
		local function get_url_(retry_count)
			local res = ls:GetURL(System.localserver.CachePolicy:new(official_text_cache_policy), url,
				function(msg)
					if(type(msg) == "table" and msg.rcode == 200) then
						TexturePackageList.LoadFromHTMLText(msg.data,ds,callbackfun);
					else
						TexturePackageList.LoadFromHTMLText(nil,ds,callbackfun);
					end
				end);
			if(not res) then
				-- retry 5 times before give up. 
				if(retry_count < 5) then
					if(not mytimer) then
						mytimer = commonlib.Timer:new({callbackFunc = function(timer)
							get_url_(retry_count+1);
						end})
					end
					-- 1 second per time. 
					mytimer:Change(1000, nil);
				else
					TexturePackageList.LoadFromHTMLText(nil,ds,callbackfun);
				end
			end
		end
		get_url_(0);
	end
end

function TexturePackageList.LoadFromHTMLText(text,ds,callbackfun)
	if(text) then
		for i = 1,#ds do
			ds[i] = nil;
		end

		for href in text:gmatch('href%s*=%s*"[^"]+"') do
			local package = TexturePackage.LoadFromHref(href);
			if(package) then
				local name = package.name;
				local url = package.url;
				if(tex_package_map[url]) then
					package["packagepath"] = tex_package_map[url]["packagepath"];
					package["parentfolder"] = tex_package_map[url]["parentfolder"];
					package["previewimgage"] = tex_package_map[url]["previewimgage"];
					tex_package_map[url] = nil;
				--else
					--TexturePackageList.AddTexturePackage(package);
				end	
				TexturePackageList.AddTexturePackage(package);
			end
		end
	end
	if(callbackfun) then	
		callbackfun();
	end
end

-- load from file if exist, otherwise refresh from disk. 
function TexturePackageList.LoadTexturePackagesInfo(bForceRefresh)
	local info_path = "worlds/BlockTextures/PackagesInfo.xml";
	if(not bForceRefresh and ParaIO.DoesFileExist(info_path, true)) then
		TexturePackageList.LoadTexturePackagesInfoFromFile(info_path);
	else
		TexturePackageList.GenerateTexturePackagesInfo(info_path);
	end
end

function TexturePackageList.RefreshTexturePackageDSInfo(beForceRefresh)
	if(needRefreshInfoFile or beForceRefresh) then
		TexturePackageList.GenerateTexturePackagesInfo(filename, TexturePackageList.ds.official,TexturePackageList.ds.localDisk);
	end
end

function TexturePackageList.SetPackageAttrValue(type,index,attr,value)
	local ds;
	if(type == "official") then
		ds = TexturePackageList.ds.official[index]
	elseif(type == "local") then
		ds = TexturePackageList.ds.localDisk[index]
	end
	ds[attr] = value;
end

function TexturePackageList.GenerateTexturePackagesInfo(filename, official_ds,local_ds)
	if(not TexturePackageList.inited) then
		return;
	end

	filename = filename or "worlds/BlockTextures/PackagesInfo.xml";
	official_ds = official_ds or TexturePackageList.ds.official;
	local_ds = local_ds or TexturePackageList.ds.localDisk;
	local file = ParaIO.open(filename, "w");
	if(file:IsValid()) then 
		local o = {name="packges",};
		for i = 1,2 do
			local packages_name,ds;
			if(i == 1) then
				packages_name = "official";
				ds = official_ds;
			elseif(i == 2) then
				packages_name = "local";
				ds = local_ds;
			end
			local packages = {name = packages_name,attr = {version = "2"}};
			for j = 1,#ds do
				if(ds[j][name] ~= L"默认材质") then
					local attr = {
						type = ds[j]["type"],
						name = ds[j]["name"],
						text = ds[j]["text"],
						bezip = tostring(ds[j]["bezip"]),
						previewimgage = commonlib.Encoding.DefaultToUtf8(ds[j]["previewimgage"] or ""),
					
						packagepath = commonlib.Encoding.DefaultToUtf8(ds[j]["packagepath"] or ""),
						parentfolder = commonlib.Encoding.DefaultToUtf8(ds[j]["parentfolder"] or ""),
						revision = ds[j]["revision"];
						name_r1 = ds[j]["name_r1"];
						url = ds[j]["url"];
						isdownload = tostring(ds[j]["isdownload"]);
					};
					local package = {name = "packge",attr = attr,};
					packages[#packages + 1] = package;
				end
			end
			o[i] = packages;
		end	
		file:WriteString(commonlib.Lua2XmlString(o, true));
		file:close();
		return true;
	end
end

function TexturePackageList.LoadTexturePackagesInfoFromFile(filename,official_ds,local_ds)
	filename = filename or "worlds/BlockTextures/PackagesInfo.xml";
	local rootXML = ParaXML.LuaXML_ParseFile(filename);
	local packagenode;
	for localnode in commonlib.XPath.eachNode(rootXML,"/packges/local") do
		if(localnode.attr and localnode.attr.version and localnode.attr.version == "2") then
			for packagenode in commonlib.XPath.eachNode(localnode,"/packge") do
				local package = TexturePackage.LoadFromXmlNode(packagenode)
				if(package) then
					TexturePackageList.AddTexturePackage(package);
				end
			end
		end
	end
	for officialnode in commonlib.XPath.eachNode(rootXML,"/packges/official") do
		if(officialnode.attr and officialnode.attr.version and officialnode.attr.version == "2") then
			for packagenode in commonlib.XPath.eachNode(officialnode,"/packge") do
				local package = TexturePackage.LoadFromXmlNode(packagenode)
				if(package) then
					TexturePackageList.AddTexturePackage(package);
				end
			end
		end
	end
end

function TexturePackageList.DownloadPackage(texturepackage,callbackfun)
	if(texturepackage and texturepackage.DownloadRemoteFile) then
		texturepackage:DownloadRemoteFile(function(bSuccess)
			if(bSuccess) then
				texturepackage.isdownload = true;
				TexturePackageList.SetPackageAttrValue(texturepackage.type,texturepackage.index,"isdownload",true);
				TexturePackageList.RefreshTexturePackageDSInfo(true);
				if(callbackfun) then
					callbackfun(bSuccess);
				end
			end		
		end);	
	end
	
end

function TexturePackageList.CloseLastZipPackage()
	if(TexturePackageList.lastOpenArchiveDefaultFile) then
		ParaAsset.CloseArchive(TexturePackageList.lastOpenArchiveDefaultFile);
	end
end

function TexturePackageList.GetDefaultTexturePackage()
	return TexturePackage.GetDefaultTexturePackage();
end

-- search package by filename, we will return the package that has the longest name match as filename. 
-- it has to match at least 50% of the text. 
-- @return package, max_len
function TexturePackageList.SearchPackage(utf8_filename)
	if(not utf8_filename or utf8_filename=="") then
		return;
	end
	utf8_filename = utf8_filename:match("[^/]*$");
	utf8_filename = utf8_filename:gsub("%.zip$", "");
	utf8_filename = utf8_filename:gsub("[pP]ara[Cc]raft", "");
	utf8_filename = utf8_filename:gsub("材质", "");
	utf8_filename = utf8_filename:gsub("资源包", "");
	NPL.load("(gl)script/ide/math/StringUtil.lua");
	local StringUtil = commonlib.gettable("mathlib.StringUtil");
	
	local best_package;
	local max_len = 0;
	local ds,package;
	ds = TexturePackageList.ds.official;
	for i = 1,#ds do
		package = ds[i];
		local match_count = StringUtil.LongestCommonSubstring(package.name_r1, utf8_filename);
		if(match_count > max_len) then
			max_len = match_count;
			best_package = package;
		end
	end
	if(max_len > 4 and max_len > (#utf8_filename)*0.5) then
		-- at least match 50% of the text
		return best_package, max_len;
	end
end

-- @param utf8_filename: if nil or "", default texture is returned. This has to be the filename without directory. 
function TexturePackageList.GetPackageFuzzyMatch(utf8_filename)
	package = TexturePackageList.SearchPackage(utf8_filename)
	if(package) then
		LOG.std(nil, "info", "TexturePackageList", "rough matching %s with %s", utf8_filename, package.name_r1 or "");
		return package;
	else
		LOG.std(nil, "info", "TexturePackageList", "no package found for %s. using the default one", utf8_filename);
		return TexturePackageList.GetDefaultTexturePackage();
	end
end

-- @param file: we will use a strict match based on filename. if not found, we will use a rough match. If still not found, we will use the default one. 
function TexturePackageList.GetPackageFromFile(file)	
	if(file) then
		local filename = string.match(file,"[^/]*$") or file;
		local utf8_filename = commonlib.Encoding.DefaultToUtf8(filename);
		local ds,package;
		ds = TexturePackageList.ds.official;
		for i = 1,#ds do
			package = ds[i];
			if(package.name_r1 == utf8_filename) then
				return package;
			end
		end

		ds = TexturePackageList.ds.localDisk;
		for i = 1,#ds do
			package = ds[i];
			if(string.match(package.packagepath,filename)) then
				return package;
			end
		end
	end
	return TexturePackageList.GetPackageFuzzyMatch(utf8_filename);
end

function TexturePackageList.GetLocalTexturePackage(path, utf8_filename)
	local ds = TexturePackageList.ds.localDisk;
	for i = 1,#ds do
		local package = ds[i];
		local path_value = package["packagepath"];
		if(path_value and path_value == path) then
			return package;
		end
	end
	return TexturePackageList.GetPackageFuzzyMatch(utf8_filename);
end

function TexturePackageList.GetOfficialTexturePackage(url, utf8_filename)
	local ds = TexturePackageList.ds.official;
	for i = 1,#ds do
		local package = ds[i];
		local url_value = package["url"];
		if(url_value and url_value == url) then
			return package;
		end
	end
	return TexturePackageList.GetPackageFuzzyMatch(utf8_filename);
end

-- get the TexturePackage object from world tags: type, path, url. 
-- for path: we will use a rough match. 
-- @param utf8_name_text: used for fuzzy search
-- @param callbackfun: function(package) end
function TexturePackageList.GetTexturePackage(type,path,url, utf8_name_text, callbackfun)
	local function _GetTexturePackage(_type,_path,_url)
		local package;
		if(not _type) then
			return TexturePackageList.GetPackageFromFile(_path);
		else
			local tag,ds,data;
			if(_type == "local") then
				return TexturePackageList.GetLocalTexturePackage(_path, utf8_name_text);
			elseif(type == "official") then
				return TexturePackageList.GetOfficialTexturePackage(_url, utf8_name_text);
			end
		end
	end
	TexturePackageList.Init(function(bInited)
		if(bInited) then
			local package = _GetTexturePackage(type,path,url);
			if(callbackfun) then
				callbackfun(package);
			end
		else
			-- this should never happen, unless for multiple calls at the same time
			LOG.std(nil,"warn", "TexturePackageList", "texture list is being updated. can not fetch for texture pack at the moment");
		end
	end);
end

function TexturePackageList.GetTexturePackageInfo(dir_default,filename)
	--local dir_default = commonlib.Encoding.Utf8ToDefault(dir);
	local filename_utf8 = commonlib.Encoding.DefaultToUtf8(filename);
	local name = filename:match("(.*)%.zip$");
	local newPreviewImgName;
	--[[
	@ zip_filter: zip 文件的匹配模式
	@ parent_folder: 材质包（当材质包已文件夹格式存在时）或者映射出来的材质包（当材质包已压缩包格式存在时）的父目录
	@ bezip：材质包是否已压缩包格式存在
	@ package_path: 压缩文件的路径（当材质包已压缩包格式存在时）或者材质包路径（当材质包已文件夹格式存在时）
	]]
	local zip_filter,parent_folder,bezip,package_path;
	local openArchiveFilename;

	if(name) then
		newPreviewImgName = name..".png";
		package_path = dir_default..filename;
		ParaAsset.OpenArchive(package_path,true);
		openArchiveFilename = package_path;
		zip_filter = "*.zip";
		local out = commonlib.Files.Find({}, dir_default, 0, 200, "*.", zip_filter);
		if(not out[1]) then
			return;
		end
		name = string.match(out[1]["filename"],"([^/]*)");
		parent_folder = dir_default..name;
		bezip = true;
		--zip_files_map[package_path] = {zip_map_path = parent_folder};
	else
		parent_folder = dir_default..filename;
		package_path = parent_folder;
		name = filename;
		newPreviewImgName = name..".png";
		bezip = false;
	end
	--value = parent_folder;
	local result = commonlib.Files.Find({}, parent_folder, 0, 200, "*.*", zip_filter);
	local utf8_package_path = commonlib.Encoding.DefaultToUtf8(package_path);

	local beUsedDefaultPreviewImg = true;
	local previewImg = parent_folder.."/preview.png";
	local newImgPath;
	if(not ParaIO.DoesAssetFileExist(previewImg, true)) then
		local _, texture_file;
		for _, texture_file in ipairs(result) do
			local block_id, part_name,  file_ext = texture_file.filename:match("^(%d+)([^%.]*)%.(%w+)$");
			if(block_id and file_ext=="png") then
				block_id = tonumber(block_id);
				if(block_id == 26 or block_id == 28 or block_id == 92) then
					previewImg = parent_folder.."/"..texture_file.filename;
					beUsedDefaultPreviewImg = false;
					newImgPath = "worlds/BlockTextures/PreviewImage/"..newPreviewImgName;
					if(ParaIO.CopyFile(previewImg, newImgPath, true)) then
						LOG.std(nil, "info", "TexturePackageList", "successfully create new prview image file in %s", newImgPath);
					end
					break;
				end
			end
		end
	else
		beUsedDefaultPreviewImg = false;
	end
	if(beUsedDefaultPreviewImg) then
		previewImg = defaultPreviewImage;
	else
		previewImg = newImgPath;
	end
	if(openArchiveFilename) then
		ParaAsset.CloseArchive(openArchiveFilename);
	end
	local ds = {
		type = "local",
		bezip = bezip,
		name = filename_utf8, 
		text = commonlib.Encoding.DefaultToUtf8(name), 
		previewimgage = commonlib.Encoding.DefaultToUtf8(previewImg),
		parentfolder = commonlib.Encoding.DefaultToUtf8(parent_folder), 
		packagepath = commonlib.Encoding.DefaultToUtf8(package_path),
		result = result,
	};
	return ds;
end

function TexturePackageList.AddTexturePackage(package_info,beImmediatelyRefresh)
	beImmediatelyRefresh = beImmediatelyRefresh or false;
	local ds,map_tag;
	if(package_info.type == "official") then
		ds = TexturePackageList.ds.official;
		map_tag = package_info["url"];
	elseif(package_info.type == "local") then
		ds = TexturePackageList.ds.localDisk;
		map_tag = package_info["packagepath"];
	else
		return;
	end
	if(not tex_package_map[map_tag]) then
		local index = #ds + 1;
		package_info.index = index;
		ds[index] = package_info;
		tex_package_map[map_tag] = package_info;
		TexturePackageList.RefreshTexturePackageDSInfo(beImmediatelyRefresh);
		--return true;
	end

end

function TexturePackageList.AddTexturePackFromFile(filename)
	local ds = TexturePackageList.ds.localDisk;
	local dir_default = commonlib.Encoding.Utf8ToDefault(TexturePackageList.texture_pack_path);
	local package = TexturePackage.LoadFromLocalFile(dir_default,filename);
	TexturePackageList.AddTexturePackage(package,true);
end

-- filename format is utf8
function TexturePackageList.GetTexturePackageInfoFromFile(file)
	local type,path,url;
	local filename = string.match(file,"[^/]*$") or file;
	local ds,package,HasFindTexturePackage;
	ds = TexturePackageList.ds.official;
	for i = 1,#ds do
		package = ds[i];
		if(not HasFindTexturePackage and packinfo.name_r1 == filename) then
			type = packinfo.type;
			path = packinfo.packagepath;
			url  = packinfo.remotefile;
			HasFindTexturePackage = true;
			--break;
		end
	end

	ds = TexturePackageList.ds.localDisk;
	for i = 1,#ds do
		package = ds[i];
		if(not HasFindTexturePackage and packinfo.packagepath == filename) then
			type = packinfo.type;
			path = packinfo.packagepath;
			url  = packinfo.remotefile;
			HasFindTexturePackage = true;
			break;
		end
	end
	if(not HasFindTexturePackage) then
		type = "local";
		path = commonlib.Encoding.Utf8ToDefault(TexturePackage.default_texture_path);
		url  = "";
	end
	return type,path,url;
end