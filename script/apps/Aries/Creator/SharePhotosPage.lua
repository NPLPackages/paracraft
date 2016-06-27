--[[
Title: save world page
Author(s): LiXizhi
Date: 2010/2/7
Desc: 
It can take snapshot for the current world. It can quick save or full save the world to local disk. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/SharePhotosPage.lua");
MyCompany.Aries.Creator.SharePhotosPage.TakeSnapshot()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")

-- create class
local SharePhotosPage = commonlib.gettable("MyCompany.Aries.Creator.SharePhotosPage")

-- default snapshot
SharePhotosPage.DefaultSnapShot = "Screen Shots/auto.jpg"

-- default options
SharePhotosPage.DefaultOptions = {
	SnapshotWidth = 600,
	SnapshotHeight = 400,  
	SnapshotIncludeUI = false,
	SnapshotIncludeHUD = true,
	SnapshotIncludeWatermark = false, 
	SnapshotImageResolution = "600*400",
	
	SnapshotIsUploadToWeb = false,
	SnapshotIsSaveToDisk = true,
	SnapshotSaveDiskPath = "default",
};

-- current snapshot options.
SharePhotosPage.Options = {
	photo_name,
	disk_path = "Screen Shots/"
};
commonlib.partialcopy(SharePhotosPage.Options, SharePhotosPage.DefaultOptions);

local upload_count = 0;
-- max number of images to upload to server per day. (currently it is per game startup)
SharePhotosPage.MaxUploadCount = 100;

local page;

-- read from snapshot settings from configuration file. 
-- @return the options. 
function SharePhotosPage.ReadConfig()
	if(not SharePhotosPage.IsConfigRead) then
		SharePhotosPage.IsConfigRead = true;
		
		-- read config values
		local app = MyCompany.Aries.app;
		if(app) then
			local name, value;
			for name, value in pairs(SharePhotosPage.DefaultOptions) do
				SharePhotosPage.Options[name] = app:ReadConfig(name, value)
			end
		end	
		SharePhotosPage.Options.SnapshotIncludeUI = MyCompany.Aries.Player.LoadLocalData("SharePhotosPage.options.SnapshotIncludeUI", false, true);
		SharePhotosPage.Options.ShowHeadOnDisplay = MyCompany.Aries.Player.LoadLocalData("SharePhotosPage.options.ShowHeadOnDisplay", false, true);
	end

	return SharePhotosPage.Options;
end

function SharePhotosPage.ShowPage(default_image_path)
	SharePhotosPage.default_image_path = default_image_path;
	System.App.Commands.Call("File.MCMLWindowFrame", {
			-- Add uid to url
			url = if_else(System.options.version == "kids", "script/apps/Aries/Creator/SharePhotosPageStandalone.html", "script/apps/Aries/Creator/SharePhotosPageStandalone.teen.html"), 
			name = "Aries.SharePhotosPage",
			app_key = MyCompany.Aries.app.app_key, 
			isShowTitleBar = false,
			DestroyOnClose = true, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			--zorder = 200,
			allowDrag = true,
			enable_esc_key = true,
			-- click_through = true,
			directPosition = true,
				align = "_ct",
				x = -270,
				y = -170,
				width = 540,
				height = 330,
		});
end


-- TODO: save options to config file if changed. 
function SharePhotosPage.SaveConfig()
end

-- show the default category page. 
function SharePhotosPage.OnInit()
	page = document:GetPageCtrl();
	
	local options = SharePhotosPage.ReadConfig();
	
	page:SetNodeValue("checkUploadToWeb", options.SnapshotIsUploadToWeb);
	page:SetNodeValue("checkSaveToDisk", options.SnapshotIsSaveToDisk);
	page:SetNodeValue("screenshot_path", options.SnapshotSaveDiskPath);
	
	
	if(not ParaIO.DoesFileExist(SharePhotosPage.DefaultSnapShot)) then
		SharePhotosPage.OnClickTakeSnapshot();
	end
	
	page:SetNodeValue("CurrentSnapshot", SharePhotosPage.DefaultSnapShot);

	local photo_name = ParaGlobal.GetDateFormat("yyMMdd").."_"..ParaGlobal.GetTimeFormat("Hmmss");
	page:SetNodeValue("photo_name", photo_name);
end

-- take snapshot and use as current world preview image 
function SharePhotosPage.OnClickTakeSnapshot()
	SharePhotosPage.TakeSnapshotEx(nil);
end

-- this is called when F11 is called. 
function SharePhotosPage.TakeSnapshot()
	SharePhotosPage.TakeSnapshotEx("default");
end

-- @param filename: to which file to save as. if this is "default" it will be the default world path. 
-- if this is nil, it will overwrite the default file "auto.jpg"
function SharePhotosPage.TakeSnapshotEx(photo_filepath)
	NPL.load("(gl)script/kids/3DMapSystemUI/ScreenShot/SnapshotPage.lua");
	
	local options = SharePhotosPage.ReadConfig()
	
	-- take screen shot
	if(photo_filepath == "default") then
		photo_filepath = options.disk_path.."Snapshot_"..ParaGlobal.GenerateUniqueID()..".jpg";
	end
		
	if(MyCompany.Apps.ScreenShot.SnapshotPage.TakeSnapshot(SharePhotosPage.DefaultSnapShot, 
		options.SnapshotWidth, options.SnapshotHeight, options.SnapshotIncludeUI, options.ShowHeadOnDisplay)) then
		
		if(photo_filepath) then
			-- copy to disk location. 
			ParaIO.CopyFile(SharePhotosPage.DefaultSnapShot, photo_filepath, true);	
		end
		-- refresh image
		ParaAsset.LoadTexture("", SharePhotosPage.DefaultSnapShot,1):UnloadAsset();
	else
		_guihelper.MessageBox([[截图失败了, 请确定您有权限读写磁盘]])	
	end
end

-- open current world directory in windows explorer.
function SharePhotosPage.OnOpenWebDir()
	Map3DSystem.App.Commands.Call("File.WinExplorer", {filepath = paraworld.TranslateURL("%FILE%/UploadFiles/"), silentmode = true});
end

-- open current world directory in windows explorer.
function SharePhotosPage.OnOpenDiskDir()
	Map3DSystem.App.Commands.Call("File.WinExplorer", {filepath = SharePhotosPage.Options.disk_path, silentmode = true});
end

-- close the window
function SharePhotosPage.OnClose()
	page:CloseWindow();
end

-- save to disk or upload to web
function SharePhotosPage.OnClickSave(name, values)
	if(values.photo_name) then
		if(string.len(values.photo_name)>=16) then
			page:SetUIValue("result", "您输入的图片名称太长了");
			return
		elseif(string.len(values.photo_name)==0) then
			page:SetUIValue("result", "图片名称不能为空");
			return
		end	
	else
		return	
	end
	
	SharePhotosPage.Options.SnapshotIsSaveToDisk = values.checkSaveToDisk
	SharePhotosPage.Options.SnapshotIsUploadToWeb = values.checkUploadToWeb
	
	if(values.checkSaveToDisk) then
		local photo_filepath = SharePhotosPage.Options.disk_path..values.photo_name..".jpg";
		-- copy to disk file. 
		local function SaveToDisk()
			if(photo_filepath ~= SharePhotosPage.DefaultSnapShot) then
				ParaIO.CopyFile(SharePhotosPage.DefaultSnapShot, photo_filepath, true);	
				if(not values.checkUploadToWeb) then
					_guihelper.MessageBox([[<div style="margin-top:32px">你的图片已经成功保存在电脑上了。</div>]]);
				end	
			end	
		end
	
		if(ParaIO.DoesFileExist(photo_filepath)) then
			_guihelper.MessageBox(string.format([[<div style="margin-top:32px">图片: %s 已经存在了, 是否要覆盖它?</div>]], values.photo_name), function()
				SaveToDisk()
				SharePhotosPage.OnClose()
			end)
		else
			SaveToDisk();
			SharePhotosPage.OnClose()
		end
	end	
	
	if(values.checkUploadToWeb) then
		if(upload_count >= SharePhotosPage.MaxUploadCount) then
			_guihelper.MessageBox(string.format([[<div style="margin-top:32px">你今天已经提交过%d次图片了<br/>多谢你的参与，请明天再来提交吧！</div>]], SharePhotosPage.MaxUploadCount))
			return;
		end
		
		-- TODO: upload to official web site. 
		local msg = {
			src = SharePhotosPage.DefaultSnapShot,
			overwrite = 1,
			ispic = 1,
			filepath = "photos/"..values.photo_name..".jpg",
		};

		if(input and input.src) then	
			msg.src = input.src;
			msg.ispic = input.ispic;
			msg.filepath = input.filepath or msg.filepath;
		end

		log("begin uploading photo to official web site.\n")
		local res = paraworld.file.UploadFileEx(msg, "SharePhotos", function(msg)
			commonlib.echo(msg);
			if(msg) then
				if(msg.issuccess and msg.url and msg.is_finished) then
					upload_count = upload_count + 1;
					if(not values.checkSaveToDisk) then
						_guihelper.MessageBox([[<div style="margin-top:28px">你的图片已经提交，通过审核后就可以跟其他小哈奇分享了！</div>]]);
						SharePhotosPage.OnClose()
					else
						_guihelper.MessageBox([[<div style="margin-top:10px">你的图片已经成功保存在电脑上,同时提交到官网了，通过审核后就可以跟其他小哈奇分享了！</div>]]);
						SharePhotosPage.OnClose()
					end	
				end
			end
		end)
		if(res == paraworld.errorcode.RepeatCall) then
			_guihelper.MessageBox([[<div style="margin-top:20px">你刚刚分享到官网的图片还在上传中，暂时不能上传新的图片，请稍候重试。</div>]]);
		end
	end
end

-- only return the sub folders of the current folder
-- @param rootfolder: the folder which will be searched.
-- @param nMaxFilesNum: one can limit the total number of files in the search result. Default value is 50. the search will stop at this value even there are more matching files.
-- @param filter: if nil, it defaults to "*."
-- @return a table array containing relative to rootfolder file name.
function SharePhotosPage.SearchFiles(output, rootfolder,nMaxFilesNum, filter)
	if(rootfolder == nil) then return; end
	if(filter == nil) then filter = "*." end
	
	output = output or {};
	local sInitDir = ParaIO.GetCurDirectory(0)..rootfolder.."/";
	local search_result = ParaIO.SearchFiles(sInitDir,filter, "", 0, nMaxFilesNum or 50, 0);
	local nCount = search_result:GetNumOfResult();		
	local nextIndex = #output+1;
	local i;
	for i = 0, nCount-1 do 
		output[nextIndex] = search_result:GetItemData(i, {});
		local date = output[nextIndex].writedate;
		local year, month, day = string.match(date, "(%d+)%D+(%d+)%D+(%d+)")
		year, month, day = tonumber(year) or 0, tonumber(month) or 0, tonumber(day) or 0
		output[nextIndex].order = year*365+month*31+day
		nextIndex = nextIndex + 1;
	end
	-- sort output by file.writedate
	table.sort(output, function(a, b)
		return (a.order > b.order )
	end)
	search_result:Release();
	return output;	
end