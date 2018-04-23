--[[
Title: code behind page for SnapshotPage.html
Author(s): LiXizhi
Date: 2008/4/28
Desc: Take a screen shot. This is an sample MCML page for some commonly used MCML controls
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/ScreenShot/SnapshotPage.lua");
local SnapshotPage = commonlib.gettable("MyCompany.Apps.ScreenShot.SnapshotPage");
MyCompany.Apps.ScreenShot.SnapshotPage.TakeSnapshot(filepath,width,height, IncludeUI)
-------------------------------------------------------
]]

local SnapshotPage = commonlib.gettable("MyCompany.Apps.ScreenShot.SnapshotPage");

-- default snapshot
SnapshotPage.DefaultSnapShot = "Screen Shots/auto.jpg"

---------------------------------
-- page event handlers
---------------------------------

-- load default values.
function SnapshotPage.OnInit()
	local self = document:GetPageCtrl();

	local tabpage = self:GetRequestParam("tab");
    if(tabpage and tabpage~="") then
        self:SetNodeValue("SnapshotTabs", tabpage);
    end
    
	-- read from application config file
	local LastAction = MyCompany.Apps.ScreenShot.app:ReadConfig("SnapshotAction", "0")
	self:SetNodeValue("SnapshotAction", LastAction);
	
	if(not ParaIO.DoesFileExist(SnapshotPage.DefaultSnapShot)) then
		SnapshotPage.OnClickTakeSnapshot();
	end
	CommonCtrl.OneTimeAsset.Unload(SnapshotPage.DefaultSnapShot);
	self:SetNodeValue("CurrentSnapshot", SnapshotPage.DefaultSnapShot);
	
	local width = MyCompany.Apps.ScreenShot.app:ReadConfig("SnapshotWidth", 600)
	local height = MyCompany.Apps.ScreenShot.app:ReadConfig("SnapshotHeight", 400)
	self:SetNodeValue("Width", width);
	self:SetNodeValue("Height", height);
	
	self:SetNodeValue("IncludeUI", MyCompany.Apps.ScreenShot.app:ReadConfig("IncludeUI", false));
	self:SetNodeValue("IncludeHUD", MyCompany.Apps.ScreenShot.app:ReadConfig("IncludeHUD", false));
	self:SetNodeValue("IncludeWatermark", MyCompany.Apps.ScreenShot.app:ReadConfig("IncludeWatermark", false));
	self:SetNodeValue("ImageResolution", MyCompany.Apps.ScreenShot.app:ReadConfig("ImageResolution", ""));
end

-- user clicks the do action button, we will perform the action according to the radio box selection. 
function SnapshotPage.OnClickDoAction(name, values)
	local action = values["SnapshotAction"];
	MyCompany.Apps.ScreenShot.app:WriteConfig("SnapshotAction", action);
	local pageCtrl = document:GetPageCtrl()
	
	local imagename = values["SnapshotName"];
	if(action == "0") then
		-- save to local disk 
		local DestFile;
		if(imagename==nil or imagename=="") then
			imagename = "Snapshot_"..ParaGlobal.GenerateUniqueID()..".jpg";
			pageCtrl:SetUIValue("SnapshotName", imagename);
			DestFile = "Screen Shots/"..imagename;
		else
			local _,_, ext = string.find(imagename, "%.(%w+)$");
			if(ext == "jpg" or ext == "bmp" or ext == "png" or ext == "dds") then
				DestFile = "Screen Shots/"..imagename
			else
				DestFile = "Screen Shots/"..imagename..".jpg"
			end	
		end
		pageCtrl:SetUIValue("result", "");
		if(ParaIO.DoesFileExist(DestFile, true)) then
			_guihelper.MessageBox(string.format("截图文件 %s 已经存在, 你是否要覆盖它?", DestFile), function()
				if(ParaIO.CopyFile(SnapshotPage.DefaultSnapShot, DestFile, true)) then
				end
			end);
		else
			if(ParaIO.CopyFile(SnapshotPage.DefaultSnapShot, DestFile, true)) then
				pageCtrl:SetUIValue("result", "保存成功! "..imagename);
			else
				pageCtrl:SetUIValue("result", "保存失败了! 可能您没有权限. "..imagename);
			end
		end
	elseif(action == "1") then
		-- upload to web
		if(imagename == "") then imagename=nil end
		if(not ParaMovie.ResizeImage(SnapshotPage.DefaultSnapShot, 480,360, "")) then return end
		local file = ParaIO.open(SnapshotPage.DefaultSnapShot, "r");
		if(file:IsValid()) then
			pageCtrl:SetUIValue("result", "正在上传请稍候...");
			paraworld.actionfeed.UploadScreenshot({ImgIn = file}, "paraworld", 
			function(msg)
				if(msg and msg.fileURL) then
					commonlib.echo(msg.fileURL)
					paraworld.actionfeed.SubmitArticle({ImageURL = msg.fileURL, Title=imagename}, "paraworld", 
					function(msg)
						if(msg and msg.articleURL) then
							commonlib.echo(msg.articleURL)
							pageCtrl:SetUIValue("result", "成功上传到官网");
							Map3DSystem.App.Commands.Call("File.WebBrowser", msg.articleURL)
						else
							pageCtrl:SetUIValue("result", "您的截图暂时无法上传到社区网");
						end
					end)
				else
					pageCtrl:SetUIValue("result", "文件无法上传");
				end	
			end)
			file:close();
		end
	elseif(action == "2") then
		-- post to friends
		pageCtrl:SetUIValue("result", "暂时不支持");
	elseif(action == "3") then
		-- as world preview
		
		-- copy and resize image to worlddir/preview.jpg
		local DestFile = ParaWorld.GetWorldDirectory().."preview.jpg";
		
		local document = document;
		local function SaveAsWorldPreview()
			if(ParaIO.CopyFile(SnapshotPage.DefaultSnapShot, DestFile, true)) then
				if(ParaMovie.ResizeImage(DestFile, 300,200,"")) then
					pageCtrl:SetUIValue("result", "保存成功! "..DestFile);
					ParaAsset.LoadTexture("",DestFile,1):UnloadAsset();
				else
					pageCtrl:SetUIValue("result", "无法改变分辨率");
				end
			else
				pageCtrl:SetUIValue("result", "保存失败了! 可能您没有权限. ");
			end	
		end
		
		if(ParaIO.DoesFileExist(DestFile, true)) then
			_guihelper.MessageBox(string.format("截图文件 %s 已经存在, 你是否要覆盖它?", DestFile), function()
				SaveAsWorldPreview();
			end);
		else
			SaveAsWorldPreview();
		end	
		
	elseif(action == "4") then
		-- as login desktop background
		pageCtrl:SetUIValue("result", "暂时不支持");
	end
end

-- take screen shot again using the current settings, and update the UI. 
function SnapshotPage.OnClickTakeSnapshot()
	local IncludeUI = MyCompany.Apps.ScreenShot.app:ReadConfig("IncludeUI", false)
	local width, height;
	local resolution = MyCompany.Apps.ScreenShot.app:ReadConfig("ImageResolution", "")
	if(resolution~=nil and resolution~="") then
		width = tonumber(MyCompany.Apps.ScreenShot.app:ReadConfig("SnapshotWidth", 600))
		height = tonumber(MyCompany.Apps.ScreenShot.app:ReadConfig("SnapshotHeight", 400))
	end
	if(SnapshotPage.TakeSnapshot(SnapshotPage.DefaultSnapShot,width,height, IncludeUI)) then
		-- TODO: push to action feed about a new screen shot. 
	end
end

-- open in windows explorer
function SnapshotPage.OnClickOpenSnapshotDir()
	MyCompany.Apps.ScreenShot.app:OpenInWinExplorer("Screen Shots/", true);
end


-- User clicks the drop down box to select a new image resolution, update the UI. 
function SnapshotPage.OnSelectImageSize(name, filepath)
	local resolution = document:GetPageCtrl():GetUIValue("ImageResolution");
	if(resolution== nil or resolution=="") then
		-- use current screen resolution
		local _, _, width, height = ParaUI.GetUIObject("root"):GetAbsPosition();
		document:GetPageCtrl():SetUIValue("Width", width);
		document:GetPageCtrl():SetUIValue("Height", height);
	else
		local _,_, width, height = string.find(resolution, "(%d+)[^%d]+(%d+)");
		if(width and height) then
			document:GetPageCtrl():SetUIValue("Width", width);
			document:GetPageCtrl():SetUIValue("Height", height);
		end	
	end	
end

-- Save settings.
function SnapshotPage.OnClickSaveSetting(name, values)
	-- batch write config file
	MyCompany.Apps.ScreenShot.app:BeginConfig()
		MyCompany.Apps.ScreenShot.app:WriteConfig("SnapshotWidth", values["Width"]);
		MyCompany.Apps.ScreenShot.app:WriteConfig("SnapshotHeight", values["Height"]);
		
		MyCompany.Apps.ScreenShot.app:WriteConfig("IncludeUI", values["IncludeUI"]);
		MyCompany.Apps.ScreenShot.app:WriteConfig("IncludeHUD", values["IncludeHUD"]);
		MyCompany.Apps.ScreenShot.app:WriteConfig("IncludeWatermark", values["IncludeWatermark"]);
		MyCompany.Apps.ScreenShot.app:WriteConfig("ImageResolution", values["ImageResolution"]);
	MyCompany.Apps.ScreenShot.app:EndConfig()
	document:GetPageCtrl():SetUIValue("settingresult", "保存成功!");
end

-- User clicks an image file, preview it
function SnapshotPage.OnSelectFile(name, filepath)
	local old_path = document:GetPageCtrl():GetUIValue("filepath");
	if(old_path ~= filepath) then
		document:GetPageCtrl():SetUIValue("filepath", filepath);
		document:GetPageCtrl():SetUIValue("LocalSnapshot", filepath);
	end	
end

-- user selects a new screenshot folder, update treeview
function SnapshotPage.OnSelectFolder(name, folderPath)
	local filebrowserCtl = document:GetPageCtrl():FindControl("FileBrowser");
	if(filebrowserCtl and folderPath) then
		filebrowserCtl.rootfolder = folderPath;
		filebrowserCtl:ResetTreeView();
	end
end

-- set selected file as current file, so that it can be send to friends, etc. 
function SnapshotPage.OnClickSetAsCurrent()
	local filepath = document:GetPageCtrl():GetUIValue("filepath") or "";
	if(filepath == nil or filepath == "") then
		_guihelper.MessageBox("请选择一个文件路径");
	elseif(not ParaIO.DoesFileExist(filepath, true)) then
		_guihelper.MessageBox(string.format("文件 %s 不存在", filepath));
	else
		-- TODO: 
	end
end


-- open current folder in external file browser
function SnapshotPage.OnClickOpenFolder()
	local filepath = document:GetPageCtrl():GetUIValue("filepath") or "";
	MyCompany.Apps.ScreenShot.app:OpenInWinExplorer(filepath, true);
end

-- delete the selected file
function SnapshotPage.OnClickDeleteFile()
	_guihelper.MessageBox("请用外部浏览器删除.");
end

-----------------------------------------------
-- public function
-----------------------------------------------
-- public function: call this function to take a new screen shot. 
-- @param filepath,width,height, IncludeUI, ShowHeadOnDisplay: all input can be nil.
-- @return: true if succeed
function SnapshotPage.TakeSnapshot(filepath,width,height, IncludeUI, ShowHeadOnDisplay)
	local result;
	if(filepath == nil) then
		filepath = SnapshotPage.DefaultSnapShot
	end
	
	local last_show_headon_display = ParaScene.GetAttributeObject():GetField("ShowHeadOnDisplay", true);
	if(ShowHeadOnDisplay ~= nil) then
		ParaScene.GetAttributeObject():SetField("ShowHeadOnDisplay", ShowHeadOnDisplay);
	end

	if(not IncludeUI) then
		-- save without GUI
		ParaUI.GetUIObject("root").visible = false;
		ParaUI.ShowCursor(false);
		ParaScene.EnableMiniSceneGraph(false);
		ParaEngine.ForceRender();ParaEngine.ForceRender(); -- since we take image on backbuffer, we will render it twice to make sure the backbuffer is updated
	else
		local _app = commonlib.getfield("MyCompany.Apps.ScreenShot.app._app");
		if(_app) then
			local _wnd = _app:FindWindow("SnapshotPage");
			if(_wnd) then
				_wnd:ShowWindowFrame(false);
				ParaEngine.ForceRender();ParaEngine.ForceRender(); -- since we take image on backbuffer, we will render it twice to make sure the backbuffer is updated
			end	
		end	
	end
	
	-- take a snapshot with defined resolution for the current screen
	if(not width and not height) then
		result = ParaMovie.TakeScreenShot(filepath)
	else
		if(width) then
			height = math.floor(width/ParaUI.GetUIObject("root").width * ParaUI.GetUIObject("root").height + 0.5);
		elseif(height) then
			width = math.floor(height/ParaUI.GetUIObject("root").height * ParaUI.GetUIObject("root").width + 0.5);
		end
		result = ParaMovie.TakeScreenShot(filepath, width, height);
	end
	-- copy to default snapshot if it isnot 
	if(filepath~=SnapshotPage.DefaultSnapShot)then
		ParaIO.CopyFile(filepath, SnapshotPage.DefaultSnapShot, true);
	end
	-- refresh texture
	ParaAsset.LoadTexture("",SnapshotPage.DefaultSnapShot,1):UnloadAsset();
	
	if(not IncludeUI) then
		-- restore UI
		ParaUI.ShowCursor(true);
		ParaUI.GetUIObject("root").visible = true;
		ParaScene.EnableMiniSceneGraph(true);
	else
		local _app = commonlib.getfield("MyCompany.Apps.ScreenShot.app._app");
		if(_app) then
			local _wnd = _app:FindWindow("SnapshotPage");
			if(_wnd) then
				_wnd:ShowWindowFrame(true);
			end	
		end	
	end	
	if(ShowHeadOnDisplay ~= nil) then
		ParaScene.GetAttributeObject():SetField("ShowHeadOnDisplay", last_show_headon_display);
	end
	return result;
end