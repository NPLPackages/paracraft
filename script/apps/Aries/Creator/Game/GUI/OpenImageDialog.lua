--[[
Title: Open File Dialog
Author(s): pbb
Date: 2022.5.10
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenImageDialog.lua");
local OpenImageDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenImageDialog");
OpenImageDialog.ShowPage("Please enter text", function(result)
	echo(result);
end, default_text)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");

local OpenImageDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenImageDialog");
-- whether in save mode. 
OpenImageDialog.IsSaveMode = false;

local page;
function OpenImageDialog.OnInit()
	page = document:GetPageCtrl();
end

-- @param filterName: "model", "bmax", "audio", "texture", "xml", "script"
function OpenImageDialog.GetFilters()
	return {
		{L"全部文件(*.png,*.jpg,*.dds)",  "*.png;*.jpg;*.dds"},
		{L"png(*.png)",  "*.png"},
		{L"jpg(*.jpg)",  "*.jpg"},
		{L"dds(*.dds)",  "*.dds"},
	};
end

-- @param default_text: default text to be displayed. 
-- the callback function can return a new filename to be displayed. 
function OpenImageDialog.ShowPage(text, OnClose,default_text)
	OpenImageDialog.SetSearchText()
	OpenImageDialog.result = nil;
	OpenImageDialog.text = L"输入图片的名字或路径&nbsp;格式: 相对路径[;l t w h][:l t r b]<div>例如: preview.jpg;0 0 100 64&nbsp;$(tip hello)preview.jpg</div>"--text;
	OpenImageDialog.title = L"图片"
	OpenImageDialog.filters = OpenImageDialog.GetFilters();
	OpenImageDialog.UpdateExistingFiles();
	OpenImageDialog.start_text = default_text
	local params = {
			url = "script/apps/Aries/Creator/Game/GUI/OpenImageDialog.html", 
			name = "OpenImageDialog.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			click_through = false, 
			enable_esc_key = true,
			bShow = true,
			isTopLevel = true,
			directPosition = true,
				align = "_ct",
				x = -300,
				y = -220,
				width = 600,
				height = 440,
		};
	if(not GameLogic.Macros:IsPlaying()) then
		params.DesignResolutionWidth = 1280
		params.DesignResolutionHeight = 720
	end
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	if(OpenImageDialog.start_text) then
		params._page:SetUIValue("text", commonlib.Encoding.DefaultToUtf8(OpenImageDialog.start_text));
	end
	params._page.OnClose = function()
		if(OnClose) then
			OnClose(OpenImageDialog.result);
			OpenImageDialog.renderIndex = nil
			OpenImageDialog.StopTimer()
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
	OpenImageDialog.GetRenderFiles()

	GameLogic:Connect("WorldUnloaded",OpenImageDialog,OpenImageDialog.OnWorldUnload, "UniqueConnection")
end

function OpenImageDialog.OnWorldUnload()
	OpenImageDialog.renderIndex = nil
	OpenImageDialog.StopTimer()
end

function OpenImageDialog.OnOK()
	if(page) then
		local text = page:GetValue("text"):gsub("^?","")
		OpenImageDialog.OnCloseWithResult(commonlib.Encoding.Utf8ToDefault(text))
	end
end

function OpenImageDialog.OnCloseWithResult(result)
	if(page) then
		OpenImageDialog.result = result
		page:CloseWindow();
		OpenImageDialog.StopTimer()
	end
end

function OpenImageDialog.OnClose()
	if(page) then
		if (OpenImageDialog.start_text and OpenImageDialog.start_text ~= "") then
			OpenImageDialog.OnCloseWithResult(commonlib.Encoding.Utf8ToDefault(OpenImageDialog.start_text))
			return
		end
		page:CloseWindow();
	end
end

function OpenImageDialog.StopTimer()
	if OpenImageDialog.renderTimer then
		OpenImageDialog.renderTimer:Change()
		OpenImageDialog.renderTimer = nil
	end
end

function OpenImageDialog.IsSelectedFromExistingFiles()
	return OpenImageDialog.lastSelectedFile == OpenImageDialog.result;
end

function OpenImageDialog.GetExistingFiles()
	return OpenImageDialog.dsExistingFiles or {};
end

function OpenImageDialog.GetSearchDirectory()
	local rootPath;
	if(OpenImageDialog.filters) then
		local filter = OpenImageDialog.filters[OpenImageDialog.curFilterIndex or 1];
		if(filter) then
			rootPath = filter.searchPath	
		end
	end
	return rootPath or ParaWorld.GetWorldDirectory()
end

function OpenImageDialog.UpdateExistingFiles()
	NPL.load("(gl)script/ide/Files.lua");
	local rootPath = OpenImageDialog.GetSearchDirectory();

	local filter, filterFunc;
	local searchLevel = 2;
	if(OpenImageDialog.filters) then
		filter = OpenImageDialog.filters[OpenImageDialog.curFilterIndex or 1];
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
	OpenImageDialog.dsExistingFiles = files;
	local result = commonlib.Files.Find({}, rootPath, searchLevel, 500, filterFunc);

	if(System.World.worldzipfile) then
		local localFiles = {};
		for i = 1, #result do
			localFiles[#localFiles+1] = {name="file", attr=result[i]};
		end
	
		if (localFiles and #localFiles > 0) then
			for _, item in ipairs(localFiles) do
				files[#files + 1] = item;
			end
		end

		local zip_archive = ParaEngine.GetAttributeObject():GetChild("AssetManager"):GetChild("CFileManager"):GetChild(System.World.worldzipfile);
		local zipParentDir = zip_archive:GetField("RootDirectory", "");
		if(zipParentDir~="") then
			if(rootPath:sub(1, #zipParentDir) == zipParentDir) then
				rootPath = rootPath:sub(#zipParentDir+1, -1)
				local result = commonlib.Files.Find({}, rootPath, searchLevel, 500, ":.", System.World.worldzipfile);
				for i = 1, #result do
					if(type(filterFunc) == "function" and filterFunc(result[i])) then
						result[i].filename = commonlib.Encoding.Utf8ToDefault(result[i].filename);
						local beExist = false;

						if (localFiles and #localFiles > 0) then
							for _, item in ipairs(localFiles) do
								if item and item.attr and item.attr.filename and
								   result[i] and result[i].filename and
								   item.attr.filename == result[i].filename then
									beExist = true;
									break;
								end
							end
						end

						if (not beExist) then
							files[#files+1] = {name="file", attr=result[i]};
						end
					end
				end
			end
		end
	else
		for i = 1, #result do
			files[#files + 1] = {name="file", attr=result[i]};
		end
	end
	-- table.sort(files, function(a, b)
	-- 	return (a.attr.writedate or 0) > (b.attr.writedate or 0);
	-- end);
end

function OpenImageDialog.GetRenderFiles()
	local num = #OpenImageDialog.GetExistingFiles()
	local curFiles = commonlib.copy(OpenImageDialog.GetExistingFiles())
	local renderFiles = {}
	if not OpenImageDialog.renderIndex then
		OpenImageDialog.renderIndex = 1
		renderFiles[#renderFiles + 1] = curFiles[OpenImageDialog.renderIndex]
	else
		OpenImageDialog.renderIndex = num
		renderFiles = curFiles
	end
	OpenImageDialog.renderTimer = OpenImageDialog.renderTimer or commonlib.Timer:new({callbackFunc = function(timer)
		if(page) then
			if OpenImageDialog.renderIndex < num then
				OpenImageDialog.renderIndex = OpenImageDialog.renderIndex + 1
				renderFiles[#renderFiles + 1] = curFiles[OpenImageDialog.renderIndex]
			else
				timer:Change()
			end
			OpenImageDialog.UpdateGView(renderFiles)
		end
	end})
	OpenImageDialog.renderTimer:Change(200,30);
end

function OpenImageDialog.UpdateGView(data)
	if data then
		page:CallMethod("gvFilterFiles","SetDataSource", data);
		page:CallMethod("gvFilterFiles","DataBind");
	end
end

function OpenImageDialog.OnOpenFileDialog()
	NPL.load("(gl)script/ide/OpenFileDialog.lua")

	local function copyFile(filename)
		if not GameLogic.IsReadOnly() then
			local fileItem1 = filename:match("[^/\\]+$")
			local destFile = OpenImageDialog.GetSearchDirectory() .. fileItem1
			local width, height, filesize = ParaMovie.GetImageInfo(filename)
			if width and width > 720 and height and height > 0 then --图片宽度大于720才需要重设分辨率
				if System.os.GetPlatform()~="win32" then
					destFile = ParaIO.GetWritablePath()..destFile
				end
				print("scale begin=====",width,height)
				local scale = 720 / width
				width = 720
				height = height * scale
				print("scale end=====",width,height,scale)
				local bResizeSuc = ParaMovie.ResizeImage(filename,width,height,destFile)
				if bResizeSuc == true then
					GameLogic.AddBBS(nil, destFile .. "  resize " ..width.."X"..height.. " success");
				end
				return bResizeSuc
			end 
			
			local bCopySuc = ParaIO.CopyFile(filename,destFile,true)
			if (bCopySuc and type(bCopySuc) == "string") then
				GameLogic.AddBBS(nil, destFile .. "  copy " .. bCopySuc);
			elseif (bCopySuc and type(bCopySuc) == "boolean") then
				if (bCopySuc) then
					GameLogic.AddBBS(nil, destFile .. "  copy " .. "success");
				else
					GameLogic.AddBBS(nil, destFile .. "  copy " .. "fail");
				end
			end
			return bCopySuc
		end
	end 

	local function RefreshPage(filename)
		if(filename and page) then
			-- we fixed win32 api to use unicode so that the following are not required. 
			-- filename = Files.GetFilePathTryMultipleEncodings(filename)
			local fileItem = Files.ResolveFilePath(filename);
			if(fileItem) then
				if not fileItem.isInWorldDirectory then
					local isCopy = copyFile(filename)
					if not isCopy  then
						return 
					end
				end
				if(fileItem.relativeToWorldPath) then
					local filename = fileItem.relativeToWorldPath;
					page:SetValue("text", commonlib.Encoding.DefaultToUtf8(filename));
				elseif(fileItem.relativeToRootPath) then
					if System.os.GetPlatform() == "win32" then
						local filename = fileItem.relativeToRootPath;
						page:SetValue("text", commonlib.Encoding.DefaultToUtf8(filename));
					else
						page:SetValue("text", commonlib.Encoding.DefaultToUtf8(filename:match("[^/\\]+$")));
					end
				else
					filename = filename:match("[^/\\]+$")
					page:SetValue("text", commonlib.Encoding.DefaultToUtf8(filename));
				end
				OpenImageDialog.SetSearchText()
				OpenImageDialog.UpdateExistingFiles()
				OpenImageDialog.RefreshFileTreeView()
			end
		end
	end

	if (System.os.GetPlatform() == "win32") then 
		local filename = CommonCtrl.OpenFileDialog.ShowDialog_Win32(OpenImageDialog.filters, 
		OpenImageDialog.title,
		OpenImageDialog.GetSearchDirectory(), 
		OpenImageDialog.IsSaveMode);
		RefreshPage(filename);
	elseif (System.os.GetPlatform() == "mac") then 
		local filename = CommonCtrl.OpenFileDialog.ShowDialog_Mac("image/*", 
		OpenImageDialog.title,
		OpenImageDialog.GetSearchDirectory(), 
		OpenImageDialog.IsSaveMode);
		RefreshPage(filename);
	elseif (System.os.GetPlatform() == "android") then
		CommonCtrl.OpenFileDialog.ShowDialog_Android("image/*", function(filepath)
			if (filepath and filepath ~= "") then
				RefreshPage(filepath);
			end
		end)
	elseif (System.os.GetPlatform() == "ios") then
		CommonCtrl.OpenFileDialog.ShowDialog_iOS("image/*", function(filepath)
			if (filepath and filepath ~= "") then
				RefreshPage(filepath);
			end
		end)
 	end 
end

function OpenImageDialog.GetText()
	return OpenImageDialog.text or L"请输入:";
end

local filteredFiles = nil;
function OpenImageDialog.GetAllFilesWithFilters()
	return filteredFiles and filteredFiles or OpenImageDialog.GetExistingFiles()
end

-- @param searchText: we will filter file names with the given text. if nil or "", we will not apply search filters. 
-- @return search text if text has been changed since last call.
function OpenImageDialog.SetSearchText(searchText)
	if(not searchText or searchText == "") then
		filteredFiles = nil;
		if(OpenImageDialog.searchText) then
			OpenImageDialog.searchText = nil
			return true;
		end
	else
		if(OpenImageDialog.searchText ~= searchText) then
			OpenImageDialog.searchText = searchText
			filteredFiles = {};
			for i, file in ipairs(OpenImageDialog.GetExistingFiles()) do
				if(file.attr.filename:find(searchText, 1, true) or (file.attr.text and file.attr.text:find(searchText, 1, true))) then
					filteredFiles[#filteredFiles+1] = file
				end
			end
			return true
		end
	end
end

function OpenImageDialog.Refresh()
	if(page) then
		page:Refresh(0);
	end
end

function OpenImageDialog.RefreshFileTreeView() 
	if(page) then
		OpenImageDialog.UpdateGView(OpenImageDialog.GetAllFilesWithFilters())
	end
end

function OpenImageDialog.OnTextChange(name, mcmlNode)
	local text = mcmlNode:GetUIValue()
	if(text and text:match("^[/?]")) then
		OpenImageDialog.searchTimer = OpenImageDialog.searchTimer or commonlib.Timer:new({callbackFunc = function(timer)
			if(page) then
				local text = page:GetUIValue("text") or ""
				local searchText = text:match("^[/?](.+)")
				if(OpenImageDialog.SetSearchText(searchText)) then
					OpenImageDialog.RefreshFileTreeView()
				end
			end
		end})
		OpenImageDialog.searchTimer:Change(500);
	else
		if(OpenImageDialog.SetSearchText()) then
			OpenImageDialog.RefreshFileTreeView()
		end
	end
end
-- local width, height, filesize = ParaMovie.GetImageInfo("abc.jpg")
function OpenImageDialog.OnClickIcon(name)
	if name then
        local filename = string.gsub(name,"OpenImageDialog.img","")
        if(filename) then
            if(System.options.isDevMode and not GameLogic.IsReadOnly() and mouse_button == "right" and filename~="preview.jpg") then
                _guihelper.MessageBox(L"是否需要删除此文件",function ()
					local filepath = ParaIO.GetWritablePath()..GameLogic.GetWorldDirectory()..filename
					if ParaIO.DoesFileExist(commonlib.Encoding.Utf8ToDefault(filepath)) then
						ParaIO.DeleteFile(commonlib.Encoding.Utf8ToDefault(filepath))
						OpenImageDialog.UpdateExistingFiles()
						OpenImageDialog.SetSearchText()
						OpenImageDialog.RefreshFileTreeView()
					end
				end)
				return
            end
            OpenImageDialog.lastSelectedFile = filename
            page:SetValue("text", OpenImageDialog.lastSelectedFile);
        end
    end
end

-- @return mini scene object
function OpenImageDialog.PrepareScene()
	local scene = ParaScene.GetMiniSceneGraph("openimage.miniscene")
	if scene and scene:IsValid() then
		return scene
	end
end

function OpenImageDialog.ReSaveImage(imagePath,width,height)
	local scene = OpenImageDialog.PrepareScene()
	scene:SetRenderTargetSize(width,height)
	local modelFile = "model/blockworld/BlockModel/block_model_one.x"
end

function OpenImageDialog.TrimNormUtf8TextByWidth(text, maxWidth, fontName)
	if(not text or text=="") then 
		return "" 
	end
	local width = _guihelper.GetTextWidth(text,fontName);
	
	if(width < maxWidth) then return text end
	--  Initialise numbers
	local nSize = ParaMisc.GetUnicodeCharNum(text);
	local iStart,iEnd = 1, nSize
	local curTextWidth = width
	local curText = text
	-- modified binary search
	while (curTextWidth > maxWidth) do
		if curTextWidth > 2*maxWidth then
			iEnd = math.floor((iStart + iEnd)/2)
		else
			iEnd = iEnd - 1
		end
		curText = ParaMisc.UniSubString(curText, iStart, iEnd)
		curTextWidth = _guihelper.GetTextWidth(curText,fontName);
	end
	local otherText = ParaMisc.UniSubString(text, iEnd, nSize)
	return curText,otherText
end
