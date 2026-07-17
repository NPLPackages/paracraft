--[[
Title: Open File Dialog
Author(s): pbb
Date: 2022.5.10
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/SimpleImageDialog.lua");
local SimpleImageDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.SimpleImageDialog");
SimpleImageDialog.ShowPage("Please enter text", function(result)
	echo(result);
end, default_text)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local CommonLib = NPL.load("(gl)script/ide/System/Util/CommonLib.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");

local SimpleImageDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.SimpleImageDialog");
-- whether in save mode. 
SimpleImageDialog.IsSaveMode = false;

local page;
SimpleImageDialog.snapshotTimer = nil
function SimpleImageDialog.OnInit()
	page = document:GetPageCtrl();
end

-- @param filterName: "model", "bmax", "audio", "texture", "xml", "script"
function SimpleImageDialog.GetFilters()
	return {
		{L"全部文件(*.png,*.jpg,*.dds)",  "*.png;*.jpg;*.dds"},
		{L"png(*.png)",  "*.png"},
		{L"jpg(*.jpg)",  "*.jpg"},
		{L"dds(*.dds)",  "*.dds"},
	};
end

-- @param default_text: default text to be displayed. 
-- the callback function can return a new filename to be displayed. 
function SimpleImageDialog.ShowPage(text, OnClose, default_text)
	SimpleImageDialog.SetSearchText()
	SimpleImageDialog.inSnapshot = nil
	SimpleImageDialog.result = nil;
	SimpleImageDialog.text = L"输入图片的名字或路径&nbsp;格式: 相对路径[;l t w h][:l t r b]<div>例如: preview.jpg;0 0 100 64&nbsp;$(tip hello)preview.jpg</div>"--text;
	SimpleImageDialog.title = L"图片"
	SimpleImageDialog.filters = SimpleImageDialog.GetFilters();
	SimpleImageDialog.UpdateExistingFiles();
	SimpleImageDialog.start_text = default_text
	local params = {
			url = "script/apps/Aries/Creator/Game/GUI/SimpleImageDialog.html", 
			name = "SimpleImageDialog.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
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
	
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	if(SimpleImageDialog.start_text) then
		params._page:SetUIValue("imgtext", commonlib.Encoding.DefaultToUtf8(SimpleImageDialog.start_text));
	end
	params._page.OnClose = function()
		if(OnClose and type(OnClose) == "function") then
			if SimpleImageDialog.result and SimpleImageDialog.result ~= "" then
				if SimpleImageDialog.result:match("^https?://") then
					OnClose({
						{
							url = SimpleImageDialog.result,
							width = 128,
							height = 128,
							filesize = 1024,
						}
					});
				else
					local isMultiple,filePaths = SimpleImageDialog.IsMultipleSlect(SimpleImageDialog.result)
					if not isMultiple then
						SimpleImageDialog.UpLoadFile(SimpleImageDialog.result,OnClose)
					else
						SimpleImageDialog.UploadMultipleFiles(filePaths,OnClose)
					end
				end
			end
			SimpleImageDialog.renderIndex = nil
			SimpleImageDialog.StopTimer()
		end
	end
	SimpleImageDialog.GetRenderFiles()
	GameLogic:Connect("WorldUnloaded",SimpleImageDialog,SimpleImageDialog.OnWorldUnload, "UniqueConnection")
end

function SimpleImageDialog.IsMultipleSlect(filepath)
	if not filepath or filepath == "" then
		return false
	end
	local files = commonlib.split(filepath, ";")
	if files and #files > 1 then
		return true ,files
	end
	return false
end

function SimpleImageDialog.UploadMultipleFiles(filePaths,OnClose)
	local num = #filePaths
	local uploadFunc = nil
	local fileUrls = {}
	uploadFunc = function(index)
		if index > num then
			OnClose(fileUrls)
		else
			local filePath = filePaths[index]
			SimpleImageDialog.UpLoadFileToQiniu(filePath,function(url)
				local width, height, filesize = ParaMovie.GetImageInfo(filePath)
				if url and url ~= "" then
					fileUrls[#fileUrls + 1] = {url = url, width = width, height = height, filesize = filesize}
					uploadFunc(index+1)
				else
					uploadFunc(index+1)
				end
			end)
		end
	end
	uploadFunc(1)
end

function SimpleImageDialog.UpLoadFile(filePath,OnClose)
	if not GameLogic.IsReadOnly() and not ParaIO.DoesFileExist(filePath) then
		return
	end
	local width, height, filesize = ParaMovie.GetImageInfo(filePath)
	if not width or not height or not filesize then
		LOG.std(nil, "error", "Failed to get image info for file: " .. filePath)
		return -- invalid file
	end
	SimpleImageDialog.UpLoadFileToQiniu(filePath,function(url)
		OnClose({
			{
				url = url,
				width = width,
				height = height,
				filesize = filesize,
			}
		});
	end)
end

function SimpleImageDialog.OnWorldUnload()
	SimpleImageDialog.renderIndex = nil
	SimpleImageDialog.StopTimer()
end

function SimpleImageDialog.OnOK()
	if(page) then
		local text = page:GetValue("imgtext"):gsub("^?","")
		SimpleImageDialog.OnCloseWithResult(commonlib.Encoding.Utf8ToDefault(text))
	end
end

function SimpleImageDialog.OnCloseWithResult(result)
	if(page) then
		SimpleImageDialog.result = result
		page:CloseWindow();
		SimpleImageDialog.StopTimer()
	end
end

function SimpleImageDialog.OnClose()
	if(page) then
		if (SimpleImageDialog.start_text and SimpleImageDialog.start_text ~= "") then
			SimpleImageDialog.OnCloseWithResult(commonlib.Encoding.Utf8ToDefault(SimpleImageDialog.start_text))
			return
		end
		page:CloseWindow();
	end
end

function SimpleImageDialog.StopTimer()
	if SimpleImageDialog.renderTimer then
		SimpleImageDialog.renderTimer:Change()
		SimpleImageDialog.renderTimer = nil
	end
end

function SimpleImageDialog.IsSelectedFromExistingFiles()
	return SimpleImageDialog.lastSelectedFile == SimpleImageDialog.result;
end

function SimpleImageDialog.GetExistingFiles()
	return SimpleImageDialog.dsExistingFiles or {};
end

function SimpleImageDialog.GetSearchDirectory()
	local rootPath;
	if(SimpleImageDialog.filters) then
		local filter = SimpleImageDialog.filters[SimpleImageDialog.curFilterIndex or 1];
		if(filter) then
			rootPath = filter.searchPath	
		end
	end
	return rootPath or ParaWorld.GetWorldDirectory()
end

function SimpleImageDialog.UpdateExistingFiles()
	NPL.load("(gl)script/ide/Files.lua");
	local rootPath = SimpleImageDialog.GetSearchDirectory();

	local filter, filterFunc;
	local searchLevel = 2;
	if(SimpleImageDialog.filters) then
		filter = SimpleImageDialog.filters[SimpleImageDialog.curFilterIndex or 1];
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
	SimpleImageDialog.dsExistingFiles = files;
	local result = commonlib.Files.Find({}, rootPath, searchLevel, 500, filterFunc);

	local snapshotMap = {}
	local function AddFile(fileItem)
		-- TODO: remove sequence texture here
		local directory,filename = commonlib.Files.splitPath(fileItem.attr.filename)
		local sequenceTexName, maxSequenceIndex = filename:match("^(.*_fps%d+)_a(%d+).%w+$")
		if sequenceTexName then
			if snapshotMap[directory] == nil then
				files[#files + 1] = fileItem
				snapshotMap[directory] = {fileIndex =#files,maxSequenceIndex = tonumber(maxSequenceIndex)}
			else
				if tonumber(maxSequenceIndex) > snapshotMap[directory].maxSequenceIndex then
					snapshotMap[directory].maxSequenceIndex= tonumber(maxSequenceIndex)
					files[snapshotMap[directory].fileIndex] = fileItem
				end
			end
		else
			files[#files + 1] = fileItem
		end	
	end

	if(System.World.worldzipfile) then
		local localFiles = {};
		for i = 1, #result do
			localFiles[#localFiles+1] = {name="file", attr=result[i]};
		end
	
		if (localFiles and #localFiles > 0) then
			for _, item in ipairs(localFiles) do
				AddFile(item)
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
							AddFile({name="file", attr=result[i]})
						end
					end
				end
			end
		end
	else
		for i = 1, #result do
			AddFile({name="file", attr=result[i]})
		end
	end
end

function SimpleImageDialog.GetRenderFiles()
	local num = #SimpleImageDialog.GetExistingFiles()
	local curFiles = commonlib.copy(SimpleImageDialog.GetExistingFiles())
	local renderFiles = {}
	if not SimpleImageDialog.renderIndex then
		SimpleImageDialog.renderIndex = 1
		renderFiles[#renderFiles + 1] = curFiles[SimpleImageDialog.renderIndex]
	else
		SimpleImageDialog.renderIndex = num
		renderFiles = curFiles
	end
	SimpleImageDialog.renderTimer = SimpleImageDialog.renderTimer or commonlib.Timer:new({callbackFunc = function(timer)
		if(page) then
			if SimpleImageDialog.renderIndex < num then
				SimpleImageDialog.renderIndex = SimpleImageDialog.renderIndex + 1
				renderFiles[#renderFiles + 1] = curFiles[SimpleImageDialog.renderIndex]
			else
				timer:Change()
			end
			SimpleImageDialog.UpdateGView(renderFiles)
		end
	end})
	SimpleImageDialog.renderTimer:Change(200,30);
end

function SimpleImageDialog.UpdateGView(data)
	if data then
		page:CallMethod("gvFilterFiles","SetDataSource", data);
		page:CallMethod("gvFilterFiles","DataBind");
	end
end

function SimpleImageDialog.UpLoadFileToQiniu(filename,callback)
	if not filename or filename == "" then
		return
	end
	Mod.WorldShare.MsgBox:Show(L'正在上传文件，请稍候...',nil,nil, 300, 120)
	local userId = Mod.WorldShare.Store:Get("user/userId") or 0
	local uuid = System.Encoding.guid.uuid()
	local key = string.format("tempfile_%s_%s", userId, ParaMisc.md5(filename..uuid))
    keepwork.shareBlock.getToken({
        router_params = {
            id = key,
        }
    },function(err, msg, data)
		if err == 200 then
			local token = data.data.token
			local file_name = commonlib.Encoding.DefaultToUtf8(ParaIO.GetFileName(filename));
			local file = ParaIO.open(filename, "rb");
			if (not file:IsValid()) then
				file:close();
				Mod.WorldShare.MsgBox:Close()
				GameLogic.AddBBS(nil,L"文件不存在，请重新选择！")
				return;
			end
			local content = file:GetText(0, -1);
			file:close();
			GameLogic.GetFilters():apply_filters(
				'qiniu_upload_file',
				token,
				key,
				file_name,
				content,
				function(result, uperr)
					if uperr ~= 200 then
						GameLogic.AddBBS(nil,L"文件上传失败，请稍后再试！")
						Mod.WorldShare.MsgBox:Close()
						return;
					end
					local base_template_url = "https://qiniu-public-temporary.keepwork.com/"
					local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
					if HttpWrapper.GetDevVersion() == "STAGE" then
						base_template_url = "https://qiniu-public-temporary-dev.keepwork.com/"
					end
					local template_url = base_template_url .. key
					if callback and type(callback) == "function" then
						callback(template_url)
					end
					Mod.WorldShare.MsgBox:Close()
			end)
		else
			Mod.WorldShare.MsgBox:Close()
			GameLogic.AddBBS(nil,L"获取上传凭证失败，请稍后再试！")
		end
    end)
end

function SimpleImageDialog.OnOpenFileDialog(name)	
	NPL.load("(gl)script/ide/OpenFileDialog.lua")

	local function RefreshPage(filename)
		if(filename and page) then
			if filename:match("^https?://") then
				SimpleImageDialog.SetText(filename);
				SimpleImageDialog.SetSearchText()
				return
			end
			-- we fixed win32 api to use unicode so that the following are not required. 
			-- filename = Files.GetFilePathTryMultipleEncodings(filename)
			local fileItem = Files.ResolveFilePath(filename);
			if(fileItem) then
				filename = filename:gsub("\\","/")
				SimpleImageDialog.SetText(commonlib.Encoding.DefaultToUtf8(filename));
				SimpleImageDialog.SetSearchText()
				SimpleImageDialog.UpdateExistingFiles()
				SimpleImageDialog.RefreshFileTreeView()
			end
		end
	end

	if System.os.IsEmscripten() then
		local EmscriptenAPI = NPL.load("(gl)script/apps/Aries/Creator/Game/Emscripten/EmscriptenAPI.lua");
		EmscriptenAPI.OpenFileDialog(function(data)
			local filepaths = data.filepaths
			if filepaths and #filepaths > 0 then
				local num = #filepaths
				local filepath = ""
				if num > 1 then
					filepath =  table.concat(filepaths,";")
				else
					filepath = filepaths[1]
				end
				RefreshPage(filepath)
			end
		end,true)
		return
	end

	if (System.os.GetPlatform() == "win32") then 
		local filename = CommonCtrl.OpenFileDialog.ShowDialog_Win32(SimpleImageDialog.filters, 
		SimpleImageDialog.title,
		SimpleImageDialog.GetSearchDirectory(), 
		SimpleImageDialog.IsSaveMode,true);
		local files = commonlib.split(filename, "|")
		if files and #files > 1 then -- multiple files selected
			local selectPath = files[1].."/"
			local allFiles = {}
			for i=2,#files do
				allFiles[#allFiles+1] = selectPath..files[i]
			end
			local filepath = table.concat(allFiles,";")
			RefreshPage(filepath)
			return
		end
		RefreshPage(filename);
	elseif (System.os.GetPlatform() == "mac") then 
		local filename = CommonCtrl.OpenFileDialog.ShowDialog_Mac("image/*", 
		SimpleImageDialog.title,
		SimpleImageDialog.GetSearchDirectory(), 
		SimpleImageDialog.IsSaveMode);
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

function SimpleImageDialog.GetText()
	return SimpleImageDialog.text or L"请输入:";
end

local filteredFiles = nil;
function SimpleImageDialog.GetAllFilesWithFilters()
	return filteredFiles and filteredFiles or SimpleImageDialog.GetExistingFiles()
end

-- @param searchText: we will filter file names with the given text. if nil or "", we will not apply search filters. 
-- @return search text if text has been changed since last call.
function SimpleImageDialog.SetSearchText(searchText)
	if(not searchText or searchText == "") then
		filteredFiles = nil;
		if(SimpleImageDialog.searchText) then
			SimpleImageDialog.searchText = nil
			return true;
		end
	else
		if(SimpleImageDialog.searchText ~= searchText) then
			SimpleImageDialog.searchText = searchText
			filteredFiles = {};
			for i, file in ipairs(SimpleImageDialog.GetExistingFiles()) do
				if(file.attr.filename:find(searchText, 1, true) or (file.attr.text and file.attr.text:find(searchText, 1, true))) then
					filteredFiles[#filteredFiles+1] = file
				end
			end
			return true
		end
	end
end

function SimpleImageDialog.Refresh()
	if(page) then
		page:Refresh(0);
	end
end

function SimpleImageDialog.RefreshFileTreeView() 
	if(page) then
		SimpleImageDialog.UpdateGView(SimpleImageDialog.GetAllFilesWithFilters())
	end
end

function SimpleImageDialog.OnTextChange(name, mcmlNode)
	local text = mcmlNode:GetUIValue()
	if(text and text:match("^[/?]")) then
		SimpleImageDialog.searchTimer = SimpleImageDialog.searchTimer or commonlib.Timer:new({callbackFunc = function(timer)
			if(page) then
				local text = page:GetUIValue("imgtext") or ""
				local searchText = text:match("^[/?](.+)")
				if(SimpleImageDialog.SetSearchText(searchText)) then
					SimpleImageDialog.RefreshFileTreeView()
				end
			end
		end})
		SimpleImageDialog.searchTimer:Change(500);
	else
		if(SimpleImageDialog.SetSearchText()) then
			SimpleImageDialog.RefreshFileTreeView()
		end
	end
end
-- local width, height, filesize = ParaMovie.GetImageInfo("abc.jpg")
function SimpleImageDialog.OnClickIcon(name)
	if name then
        local filename = string.gsub(name,"SimpleImageDialog.img","")
        if(filename) then
            if(not GameLogic.IsReadOnly() and mouse_button == "right" and filename~="preview.jpg") then
                _guihelper.MessageBox(L"是否需要删除此文件",function ()
					local filepath = ParaIO.GetWritablePath()..GameLogic.GetWorldDirectory()..filename
					if ParaIO.DoesFileExist(commonlib.Encoding.Utf8ToDefault(filepath)) then
						ParaIO.DeleteFile(commonlib.Encoding.Utf8ToDefault(filepath))
						SimpleImageDialog.UpdateExistingFiles()
						SimpleImageDialog.SetSearchText()
						SimpleImageDialog.RefreshFileTreeView()
					end
				end)
				return
            end
			local filename = Files.GetWorldFilePath(filename)
			if not GameLogic.IsReadOnly() then
				filename = ParaIO.GetWritablePath()..filename
			end
            SimpleImageDialog.lastSelectedFile = filename
            SimpleImageDialog.SetText(SimpleImageDialog.lastSelectedFile);
        end
    end
end

function SimpleImageDialog.SetText(text)
	if(text and page) then
		local _editbox = page:FindUIControl("imgtext");
		if(_editbox) then
			_editbox.text = text;
	        _editbox:Focus();
			_editbox:SetCaretPosition(-1);
		end
	end
end


