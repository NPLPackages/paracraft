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
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/TouchSession.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local CommonLib = NPL.load("(gl)script/ide/System/Util/CommonLib.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local TouchSession = commonlib.gettable("MyCompany.Aries.Game.Common.TouchSession");
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
local Screen = commonlib.gettable("System.Windows.Screen");

local OpenImageDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenImageDialog");
-- whether in save mode. 
OpenImageDialog.IsSaveMode = false;

local page;
OpenImageDialog.snapshotTimer = nil
function OpenImageDialog.OnInit()
	page = document:GetPageCtrl();
	if page then
		page.OnCreate = OpenImageDialog.OnCreated
	end
end

local function getRect(node)
    if node and node:IsValid() then
        local rect = {}
        rect.x,rect.y,rect.width,rect.height = node:GetAbsPosition()
        return rect
    end
    return {}
end

function OpenImageDialog.OnCreated()
	local objSnapshot = ParaUI.GetUIObject("btn_snapshot")
    if objSnapshot and objSnapshot:IsValid() then
        local data = {name="btn_snapshot",node = objSnapshot,rect = getRect(objSnapshot)}
		local name = data.name
        local node = data.node
        node:SetScript("onmousedown", function() 
            OpenImageDialog.OnMouseDown(name)
        end);
        node:SetScript("ontouch", function() 
            OpenImageDialog.OnTouch(msg,name)
        end);
        node:SetScript("onmouseup", function() 
            OpenImageDialog.OnMouseUp(name)
        end);
    end
end

-- simulate the touch event with id=-1
function OpenImageDialog.OnMouseDown(btnName)
	local touch = {type="WM_POINTERDOWN", x=mouse_x, y=mouse_y, id=-1, time=0};
	OpenImageDialog.OnTouch(touch,btnName);
end

-- simulate the touch event
function OpenImageDialog.OnMouseUp(btnName)
	local touch = {type="WM_POINTERUP", x=mouse_x, y=mouse_y, id=-1, time=0};
	OpenImageDialog.OnTouch(touch,btnName);
end

-- handleTouchEvent 
function OpenImageDialog.OnTouch(touch,btnName)
    local touch_session = TouchSession.GetTouchSession(touch);
	if(touch.type == "WM_POINTERDOWN") then
        if btnName == "btn_snapshot" then
			GameLogic.AddBBS(nil, L"开始连拍", 1000, "0 255 0")
			OpenImageDialog.snapshotIndex = 0
			OpenImageDialog.previews = {}
			page:CallMethod("item_gridview","SetDataSource", OpenImageDialog.previews);
			page:CallMethod("item_gridview","DataBind");
			OpenImageDialog.inSnapshot = true
			OpenImageDialog.onStartSnapshot()
		end
	elseif(touch.type == "WM_POINTERUP")then
		if btnName == "btn_snapshot" then
			OpenImageDialog.StopSnapshot()
		end
	end
end

-- @param filterName: "model", "bmax", "audio", "texture", "xml", "script"
function OpenImageDialog.GetFilters()
	return {
		{L"全部文件(*.png,*.jpg,*.dds,*.mp4)",  "*.png;*.jpg;*.dds,*.mp4"},
		{L"png(*.png)",  "*.png"},
		{L"jpg(*.jpg)",  "*.jpg"},
		{L"dds(*.dds)",  "*.dds"},
		{L"mp4(*.mp4)",  "*.mp4"},
	};
end

-- @param default_text: default text to be displayed. 
-- the callback function can return a new filename to be displayed. 
function OpenImageDialog.ShowPage(text, OnClose, default_text, not_support_change_design_resolution)
	OpenImageDialog.SetSearchText()
	OpenImageDialog.inSnapshot = nil
	OpenImageDialog.result = nil;
	OpenImageDialog.text = L"输入图片的名字或路径&nbsp;格式: 相对路径[;l t w h][:l t r b]<div>例如: preview.jpg;0 0 100 64&nbsp;$(tip hello)preview.jpg</div>"--text;
	OpenImageDialog.title = L"图片"
	OpenImageDialog.filters = OpenImageDialog.GetFilters();
	OpenImageDialog.UpdateExistingFiles();
	OpenImageDialog.start_text = default_text
	Screen:Connect("sizeChanged", OpenImageDialog, OpenImageDialog.OnScreenSizeChange, "UniqueConnection")
	GameLogic.GetCodeGlobal():RegisterTextEvent("captureVideoChange", OpenImageDialog.OnVideoCapturedChange);
	GameLogic.GetCodeGlobal():RegisterTextEvent("onClickTextSnapImage", OpenImageDialog.OnVideoCaptured);
	local params = {
			url = "script/apps/Aries/Creator/Game/GUI/OpenImageDialog.html", 
			name = "OpenImageDialog.ShowPage", 
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

	-- 默认支持更新分辨率
	if(not GameLogic.Macros:IsPlaying() and not not_support_change_design_resolution) then
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
		if OpenImageDialog.showCamera then
			GameLogic.RunCommand("/capture video stop")
		end
		OpenImageDialog.showCamera = nil
		OpenImageDialog.autoUseImg = nil
		OpenImageDialog.hasVideoImage = nil
		Screen:Disconnect("sizeChanged", OpenImageDialog, OpenImageDialog.OnScreenSizeChange)
		GameLogic.GetCodeGlobal():UnregisterTextEvent("captureVideoChange", OpenImageDialog.OnVideoCapturedChange);
		GameLogic.GetCodeGlobal():UnregisterTextEvent("onClickTextSnapImage", OpenImageDialog.OnVideoCaptured);
		
		if OpenImageDialog.snapshotTimer then
			OpenImageDialog.snapshotTimer:Change()
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

function OpenImageDialog.onClickTextSnapImage()
    GameLogic.RunCommand("/capture videoimage -format png -filename temp/camera.png -event onClickTextSnapImage")
end

function OpenImageDialog.OnVideoCapturedChange(_,event)
	OpenImageDialog.OnVideoCaptured(_,event,true)
end

function OpenImageDialog.OnVideoCaptured(_,event,fromClickVideo)
	if not OpenImageDialog.showCamera then
		return
	end
	if fromClickVideo then
		OpenImageDialog.inSnapshot = nil 
	end
	local filename = "temp/camera.png"
	ParaIO.CreateDirectory(ParaIO.GetWritablePath().."temp/snapshot_camera/");
	OpenImageDialog.hasVideoImage = true
	local temp_filename = OpenImageDialog.inSnapshot ~= nil and string.format("temp/snapshot_camera/camera_size_%03d.png",OpenImageDialog.snapshotIndex) or "temp/camera_size.png"
	ParaAsset.LoadTexture('',temp_filename, 1):UnloadAsset()
	if page then
		local text = page:GetValue("text")
		if OpenImageDialog.inSnapshot == nil then
			local directory = string.gsub(text or "", "([^\\/]*)$", "");
			if directory ~= nil and directory ~= "" and directory:match("^snapshot") then
				text = ""
			end
		end
		if text == nil or text == "" and OpenImageDialog.inSnapshot == nil then
			local name
			local find
			local extension = ".png"
			if OpenImageDialog.extension ~= nil and  OpenImageDialog.extension ~= "" then
				extension = OpenImageDialog.extension
			end
			for i = 1,200 do
				name = "camera_"..i..extension
				if not ParaIO.DoesFileExist(Files.WorldPathToFullPath(commonlib.Encoding.Utf8ToDefault(name))) then
					find = true
					break
				end
			end
			text = find and  name or "camera_snap"..extension
		end
		local resolution = page:GetValue("ImageResolution")
		local sizes =  commonlib.split_by_str(resolution,"x")
		local bResizeSuc = ParaMovie.ResizeImage(filename,tonumber(sizes[1]),tonumber(sizes[2]),temp_filename)
		if bResizeSuc == true then
			if OpenImageDialog.inSnapshot ~= nil then
			    table.insert(OpenImageDialog.previews,{icon = temp_filename})
				page:Refresh(0)
				page:SetUIValue("text",text)
				page:CallMethod("item_gridview","SetDataSource", OpenImageDialog.previews);
				page:CallMethod("item_gridview","DataBind");
			else
				page:Refresh(0)
				page:SetUIValue("text",text)
				if OpenImageDialog.autoUseImg then
					OpenImageDialog.autoUseImg = nil
					OpenImageDialog.OnOK()
				end
			end
		end
	end
end

function OpenImageDialog.openCamera()
	if page then
		local point_set = page:FindControl("point_set");
		if point_set and point_set:IsValid() then
			local tx, ty, twidth, theight = point_set:GetAbsPosition(); 
			local str = string.format("/capture video -x %s -y %s -width %s -height %s -scale 1 -event captureVideoChange -filename temp/camera.png",tx,ty,OpenImageDialog.imageW,OpenImageDialog.imageH)
			GameLogic.RunCommand(str)
		end
	end
end

function OpenImageDialog.OnScreenSizeChange()
	if not OpenImageDialog.showCamera then
		return
	end
	GameLogic.RunCommand("/capture video stop")
	if(page) then
		OpenImageDialog.openCamera()
	end
end

function OpenImageDialog.OnWorldUnload()
	OpenImageDialog.renderIndex = nil
	OpenImageDialog.StopTimer()
end

function OpenImageDialog.StopSnapshot()
	if OpenImageDialog.snapshotTimer then
		OpenImageDialog.snapshotTimer:Change()
	end
	OpenImageDialog.inSnapshot = false
	local text = page:GetValue("text")
	if(page) then
		page:Refresh(0)
		page:SetUIValue("text",text)
		page:CallMethod("item_gridview","SetDataSource", OpenImageDialog.previews);
		page:CallMethod("item_gridview","DataBind");
	end
end

OpenImageDialog.snapshotIndex = 0
function OpenImageDialog.onStartSnapshot()
	OpenImageDialog.snapshotTimer = OpenImageDialog.snapshotTimer or commonlib.Timer:new({callbackFunc = function(timer)
		if not ParaUI.IsMousePressed(0) then
			OpenImageDialog.StopSnapshot()
			return
		end
		if OpenImageDialog.snapshotIndex < 100 then
			OpenImageDialog.snapshotIndex = OpenImageDialog.snapshotIndex + 1
			OpenImageDialog.onClickTextSnapImage()
			OpenImageDialog.onStartSnapshot()
		else
			OpenImageDialog.StopSnapshot()
		end
	end})
	OpenImageDialog.snapshotTimer:Change(200);
end

function OpenImageDialog.OnOK()
	if(page) then
		if OpenImageDialog.showCamera then
			if not OpenImageDialog.hasVideoImage then
				OpenImageDialog.autoUseImg = true
				OpenImageDialog.onClickTextSnapImage()
			else
				if OpenImageDialog.inSnapshot == false then
					--copy snapshot image to world
					local text = page:GetValue("text")
					local directory = string.gsub(text or "", "([^\\/]*)$", "");
					local name,find,extension
					if directory ~= nil and directory ~= "" then
						if not ParaIO.DoesFileExist(directory) then
							ParaIO.CreateDirectory(directory)
						end
						name = directory
					else
						if text ~= nil and text ~= "" then
							name,extension =  commonlib.Files.splitText(text)
							name = name.."/"
						else
							name = "snapshot/"
							if find then
								ParaIO.CreateDirectory(Files.WorldPathToFullPath())
							end
						end
					end
					for i = 1, OpenImageDialog.snapshotIndex do
						local file_name = string.format("temp/snapshot_camera/camera_size_%03d.png",i)
						local world_path = name..string.format("camera_%s_fps10_a%03d.png",name:gsub("/",""),i)
						ParaAsset.LoadTexture('',world_path, 1):UnloadAsset()
						ParaIO.CopyFile(file_name,Files.WorldPathToFullPath(world_path),true)
					end
					OpenImageDialog.OnCloseWithResult(name..string.format("camera_%s_fps10_a%03d.png",name:gsub("/",""),OpenImageDialog.snapshotIndex))
					local result = commonlib.Files.Find({}, Files.WorldPathToFullPath(name), 2, 500, function(item)
						local sequenceTexName, maxSequenceIndex = item.filename:match("^(.*_fps%d+)_a(%d+).%w+$")
						if tonumber(maxSequenceIndex) > OpenImageDialog.snapshotIndex then
							ParaIO.DeleteFile(Files.WorldPathToFullPath(name..item.filename))
							return true
						end
					end);
				else
					local text = page:GetValue("text")
					if text ~= nil and text ~= "" then
						--copy temp/camera.jpg to world didrectory
						local destFile
						local extension
						if text:match("%.jpg$") or text:match("%.png$") then
							destFile = Files.WorldPathToFullPath(commonlib.Encoding.Utf8ToDefault(text))
						else
							extension = ".png"
							if OpenImageDialog.extension ~= nil and OpenImageDialog.extension ~= "" then
								extension = OpenImageDialog.extension
							end
							destFile = Files.WorldPathToFullPath(commonlib.Encoding.Utf8ToDefault(text)..extension)
						end
						ParaAsset.LoadTexture('',destFile, 1):UnloadAsset()
						local filename = "temp/camera_size.png"
						local function refresh()
							ParaIO.DeleteFile(filename)
							--OpenImageDialog.showCamera = nil
							OpenImageDialog.OnCloseWithResult(commonlib.Encoding.Utf8ToDefault(text..(extension and extension or "")))
						end
						local bCopySuc = ParaIO.CopyFile(filename,destFile,true)
						if bCopySuc then
							refresh()
						end
					end
				end
			end
		else
			local text = page:GetValue("text"):gsub("^?","")
			OpenImageDialog.OnCloseWithResult(commonlib.Encoding.Utf8ToDefault(text))
		end
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

function OpenImageDialog.BackToFileView()
	OpenImageDialog.inSnapshot = nil
	OpenImageDialog.hasVideoImage = nil
	GameLogic.RunCommand("/capture video stop")
	OpenImageDialog.showCamera = nil
	page:Refresh(0)
	commonlib.TimerManager.SetTimeout(function()
		OpenImageDialog.UpdateExistingFiles()
		OpenImageDialog.RefreshFileTreeView()
	end,100)
end

function OpenImageDialog.OnOpenFileDialog(name)	
	if OpenImageDialog.showCamera then
		OpenImageDialog.BackToFileView()
		return
	end
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
			if filename:match("^https?://") then
				page:SetValue("text", filename);
				OpenImageDialog.SetSearchText()
				return
			end
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

	if System.os.IsEmscripten() then
		if name == "opennet" then
			local WebImageFileDialog = NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/WebImageFileDialog.lua");
			local fileType = name == "opennet" and 2 or 1
			WebImageFileDialog.Show(fileType, function(filename)
				echo({filename,fileType})
				if filename and filename ~= "" then
					RefreshPage(filename)
				end
			end)
		else
			local EmscriptenAPI = NPL.load("(gl)script/apps/Aries/Creator/Game/Emscripten/EmscriptenAPI.lua");
			EmscriptenAPI.OpenFileDialog(function(data)
				local filename = (data and data.filepaths and data.filepaths[1] and data.filepaths[1] ~= "") and data.filepaths[1] or ""
				if filename and filename ~= "" then
					echo(filename)
					RefreshPage(filename)
				end
			end)
		end
		return
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
