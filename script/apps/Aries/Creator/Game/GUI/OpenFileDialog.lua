--[[
Title: Open File Dialog
Author(s): LiXizhi
Date: 2015/9/20
Desc: Display a dialog with text that let user to enter filename in current world directory. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenFileDialog.lua");
local OpenFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenFileDialog");
OpenFileDialog.ShowPage("Please enter text", function(result)
	echo(result);
end, default_text, title, filters)

OpenFileDialog.ShowPage("Please enter text", function(result)
	echo(result);
end, default_text, title, filters, nil, function(filename) 
	echo(filename)
end)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");

local OpenFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenFileDialog");
-- whether in save mode. 
OpenFileDialog.IsSaveMode = false;

local page;
function OpenFileDialog.OnInit()
	page = document:GetPageCtrl();
end

-- @param filterName: "model", "bmax", "audio", "texture", "xml", "script"
function OpenFileDialog.GetFilters(filterName)
	if(filterName == "model") then
		return {
			-- {L"全部文件(*.fbx,*.x,*.bmax,*.xml)",  "*.fbx;*.x;*.bmax;*.xml", exclude="*.blocks.xml"},
			{L"全部文件(*.fbx,*.FBX,*.x,*.bmax)",  "*.fbx;*.FBX;*.x;*.bmax", exclude="*.blocks.xml"},
			{L"FBX模型(*.fbx)",  "*.fbx"},
			{L"bmax模型(*.bmax)",  "*.bmax"},
			{L"ParaX模型(*.x,*.xml)",  "*.x;*.xml"},
			{L"block模版(*.blocks.xml)",  "*.blocks.xml"},
		};
	elseif(filterName == "bmax") then
		return {
			{L"bmax模型(*.bmax)",  "*.bmax"},
		};
	elseif(filterName == "script" or filterName == "lua") then
		return {
			{L"(*.lua)",  "*.lua"},
			{"(*.npl)",  "*.npl"},
		};
	elseif(filterName == "npl") then
		return {
			{"(*.npl)",  "*.npl"},
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
	elseif(filterName == "localworlds") then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Login/LocalLoadWorld.lua");
		local LocalLoadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld")
		return {
			{L"Paracraft世界",  "*", searchPath = LocalLoadWorld.GetDefaultSaveWorldPath().."/", searchLevel=0, filterFunc = "*."},
		};
	end
end

-- @param default_text: default text to be displayed. 
-- @param filters: "model", "bmax", "audio", "texture", "xml", nil for any file, or filters table
-- @param editButton: this can be nil or a function(filename) end or {text="edit", callback=function(filename) end}
-- the callback function can return a new filename to be displayed. 
function OpenFileDialog.ShowPage(text, OnClose, default_text, title, filters, IsSaveMode, editButton)
	OpenFileDialog.result = nil;
	OpenFileDialog.text = text;
	OpenFileDialog.title = title;
	if(type(filters) == "string") then
		filters = OpenFileDialog.GetFilters(filters)
	end
	OpenFileDialog.filters = filters;
	OpenFileDialog.editButton = editButton;
	OpenFileDialog.IsSaveMode = IsSaveMode == true;
	OpenFileDialog.UpdateExistingFiles();

	local params = {
			url = "script/apps/Aries/Creator/Game/GUI/OpenFileDialog.html", 
			name = "OpenFileDialog.ShowPage", 
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
				x = -230,
				y = -220,
				width = 460,
				height = 400,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	if(default_text) then
		params._page:SetUIValue("text", commonlib.Encoding.DefaultToUtf8(default_text));
	end
	params._page.OnClose = function()
		if(OnClose) then
			OnClose(OpenFileDialog.result);
		end
	end
	
	params._page.OnDropFiles = function(filelist)
		if filelist then
			local _, firstFile = next(filelist);
			
			if(firstFile and page) then
				local fileItem = Files.ResolveFilePath(firstFile);
				if(fileItem and fileItem.relativeToWorldPath) then
					local filename = fileItem.relativeToWorldPath;
					params._page:SetValue("text", commonlib.Encoding.DefaultToUtf8(filename));
				end
			end
			
			return true;
		else
			return false;
		end
	end
end


function OpenFileDialog.OnOK()
	if(page) then
		OpenFileDialog.result = commonlib.Encoding.Utf8ToDefault(page:GetValue("text"));
		page:CloseWindow();
	end
end

function OpenFileDialog.IsSelectedFromExistingFiles()
	return OpenFileDialog.lastSelectedFile == OpenFileDialog.result;
end

function OpenFileDialog.GetExistingFiles()
	return OpenFileDialog.dsExistingFiles or {};
end

function OpenFileDialog.GetSearchDirectory()
	local rootPath;
	if(OpenFileDialog.filters) then
		local filter = OpenFileDialog.filters[OpenFileDialog.curFilterIndex or 1];
		if(filter) then
			rootPath = filter.searchPath	
		end
	end
	return rootPath or ParaWorld.GetWorldDirectory()
end

function OpenFileDialog.UpdateExistingFiles()
	NPL.load("(gl)script/ide/Files.lua");
	local rootPath = OpenFileDialog.GetSearchDirectory();

	local filter, filterFunc;
	local searchLevel = 2;
	if(OpenFileDialog.filters) then
		filter = OpenFileDialog.filters[OpenFileDialog.curFilterIndex or 1];
		if(filter) then
			searchLevel = filter.searchLevel or searchLevel
			if(filter.filterFunc) then
				filterFunc = filter.filterFunc;
			else
				local filterText = filter[2];
				if(filterText) then
					-- "*.fbx;*.x;*.bmax;*.xml"
					local exts = {};
					local excludes;
					for ext in filterText:gmatch("%*%.([^;]+)") do
						exts[#exts + 1] = "%."..ext.."$";
					end
					if(filter.exclude) then
						excludes = excludes or {};
						for ext in filter.exclude:gmatch("%*%.([^;]+)") do
							excludes[#excludes + 1] = "%."..ext.."$";
						end
					end
				
					-- skip these system files and all files under blockWorld.lastsave/
					local skippedFiles = {
						["LocalNPC.xml"] = true,
						["entity.xml"] = true,
						["players/0.entity.xml"] = true,
						["revision.xml"] = true,
						["tag.xml"] = true,
					}

					filterFunc = function(item)
						if(not skippedFiles[item.filename] and not item.filename:match("^blockWorld")) then
							if(excludes) then
								for i=1, #excludes do
									if(item.filename:match(excludes[i])) then
										return;
									end
								end
							end
							for i=1, #exts do
								if(item.filename:match(exts[i])) then
									return true;
								end
							end
						end
					end
				end
			end
		end
	end
	local files = {};
	OpenFileDialog.dsExistingFiles = files;
	local result = commonlib.Files.Find({}, rootPath, searchLevel, 500, filterFunc);
	for i = 1, #result do
		files[#files+1] = {name="file", attr=result[i]};
	end
	if(System.World.worldzipfile) then
		local zip_archive = ParaEngine.GetAttributeObject():GetChild("AssetManager"):GetChild("CFileManager"):GetChild(System.World.worldzipfile);
		local zipParentDir = zip_archive:GetField("RootDirectory", "");
		if(zipParentDir~="") then
			if(rootPath:sub(1, #zipParentDir) == zipParentDir) then
				rootPath = rootPath:sub(#zipParentDir+1, -1)
				local result = commonlib.Files.Find({}, rootPath, searchLevel, 500, ":.", System.World.worldzipfile);
				for i = 1, #result do
					if(type(filterFunc) == "function" and filterFunc(result[i])) then
						result[i].filename = commonlib.Encoding.Utf8ToDefault(result[i].filename);
						files[#files+1] = {name="file", attr=result[i]};
					end
				end
			end
		end
	end
	table.sort(files, function(a, b)
		return (a.attr.writedate or 0) > (b.attr.writedate or 0);
	end);
end

function OpenFileDialog.OnOpenFileDialog()
	NPL.load("(gl)script/ide/OpenFileDialog.lua");

	local filename = CommonCtrl.OpenFileDialog.ShowDialog_Win32(OpenFileDialog.filters, 
		OpenFileDialog.title,
		OpenFileDialog.GetSearchDirectory(), 
		OpenFileDialog.IsSaveMode);
		
	if(filename and page) then
		local fileItem = Files.ResolveFilePath(filename);
		if(fileItem) then
			if(fileItem.relativeToWorldPath) then
				local filename = fileItem.relativeToWorldPath;
				page:SetValue("text", commonlib.Encoding.DefaultToUtf8(filename));
			elseif(fileItem.relativeToRootPath) then
				local filename = fileItem.relativeToRootPath;
				page:SetValue("text", commonlib.Encoding.DefaultToUtf8(filename));
			else
				filename = filename:match("[^/\\]+$")
				page:SetValue("text", commonlib.Encoding.DefaultToUtf8(filename));
			end
		end
	end
end

function OpenFileDialog.GetText()
	return OpenFileDialog.text or L"请输入:";
end

function OpenFileDialog.OnClickEdit()
	local filename = commonlib.Encoding.Utf8ToDefault(page:GetValue("text"));
	local callback;
	if(type(OpenFileDialog.editButton) == "function") then
		callback = OpenFileDialog.editButton;
	elseif(type(OpenFileDialog.editButton) == "table") then
		callback = OpenFileDialog.editButton.callback;
	end
	if(callback) then
		local new_filename = callback(filename);
		if(new_filename and new_filename~=filename) then
			page:SetValue("text", commonlib.Encoding.DefaultToUtf8(new_filename));
		end
	end
end