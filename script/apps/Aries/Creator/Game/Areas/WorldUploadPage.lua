--[[
Title: The dock page
Author(s): LiXizhi
Date: 2012/12/28
Desc:  
There dock has 2 mode: one for editor and one for creator
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/WorldUploadPage.lua");
local WorldUploadPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.WorldUploadPage");
WorldUploadPage.ShowPage(true)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/SaveWorldPage.lua");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local SaveWorldPage = commonlib.gettable("MyCompany.Aries.Creator.SaveWorldPage")
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ItemManager = commonlib.gettable("Map3DSystem.Item.ItemManager");
local EnterGamePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.EnterGamePage");
local WorldUploadPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.WorldUploadPage");
local Scene = commonlib.gettable("MyCompany.Aries.Scene");

-- user can only upload file size smaller than 10 MB.
WorldUploadPage.MaxTotalsize = 10240000; 

local upload_count = 0;
-- max number of times to upload to server per day. (currently it is per game startup)
WorldUploadPage.MaxUploadCount = 10;

-- singleton
local page;

-- each item means a saving record, teen is 17394
WorldUploadPage.ExtendedSlotCountGsid = 20054; 
WorldUploadPage.FreeSlotCount = 1;
-- free slot count bonus: additional slot count after user purchased the first slot. 
WorldUploadPage.FreeSlotCountBonus = 2;
-- its client data contains all record urls
WorldUploadPage.RecordGsid = 20901; -- this is for free, in bag 62 (world maps)

WorldUploadPage.save_records = {
    -- {worldname="AAAAA", type="save", date="2013/3/24"},
    {type="empty"},
    {type="empty"},
    {type="empty"},
    {type="empty"},
    {type="empty"},
    {type="empty"},
    {type="empty"},
    {type="empty"},
	{type="empty"},
    {type="empty"},
    {type="empty"},
	{type="empty"},
	{type="empty"},
	{type="empty"},
	{type="empty"},
	{type="empty"},
	{type="empty"},
	{type="empty"},
	{type="empty"},
	{type="empty"},
	{type="empty"},
	{type="empty"},
}

function WorldUploadPage.OnInit()
	if(System.options.version == "teen") then
		WorldUploadPage.ExtendedSlotCountGsid = 17394;
	end

	page = document:GetPageCtrl();
	SaveWorldPage.OnInit();
end

-- purchase it if not owned yet
function WorldUploadPage.CheckLoadRecordGsid()
	local bOwn, guid, bag, copies = ItemManager.IfOwnGSItem(WorldUploadPage.RecordGsid);
	if(not bOwn) then
		ItemManager.PurchaseItem(WorldUploadPage.RecordGsid, 1, function(msg) end, function(msg) end, nil, "none");
	end
end

-- get max slot count
function WorldUploadPage.GetMaxSlotCount()
	local bOwn, guid, bag, copies = ItemManager.IfOwnGSItem(WorldUploadPage.ExtendedSlotCountGsid);
	copies = (copies or 0)
	return WorldUploadPage.FreeSlotCount + copies + if_else(copies>0, WorldUploadPage.FreeSlotCountBonus, 0);
end

function WorldUploadPage.GetRecordData()
	local clientdata;
	local bOwn, guid, bag, copies = ItemManager.IfOwnGSItem(WorldUploadPage.RecordGsid);
	if(bOwn) then
		local item = ItemManager.GetItemByGUID(guid);
		if(item) then
			if(item.clientdata and item.clientdata~="") then
				clientdata = NPL.LoadTableFromString(item.clientdata);
			end
		end
	end
	return clientdata or {};
end

-- load record
function WorldUploadPage.LoadRecordData()
	local clientdata = WorldUploadPage.GetRecordData()
	local save_records = WorldUploadPage.save_records;
	local i
	local max_copies = WorldUploadPage.GetMaxSlotCount();
	for i = 1, math.min(max_copies,#save_records) do
		local record = save_records[i];
		local record_svr = clientdata[i];
		record.type = "save";
		if(record_svr) then
			record.worldname = record_svr.worldname or "空";
			record.revision = record_svr.revision or 0;
			record.url = record_svr.url;
			record.date = record_svr.date;
		else
			record.worldname = "空";
			record.revision = 0;
		end
	end
	return save_records;
end

function WorldUploadPage.SaveRecordData(callbackFunc)
	local bOwn, guid, bag, copies = ItemManager.IfOwnGSItem(WorldUploadPage.RecordGsid);
	if(bOwn) then
		local item = ItemManager.GetItemByGUID(guid);
		if(item) then
			local clientdata={};
			if(item.clientdata and item.clientdata~="") then
				clientdata = NPL.LoadTableFromString(item.clientdata) or {};
			end
			local save_records = WorldUploadPage.save_records;
			local i
			local max_copies = WorldUploadPage.GetMaxSlotCount();
			for i = 1, max_copies do
				local record = save_records[i];
				if(record and record.worldname and record.url) then
					clientdata[i] = {
						worldname = record.worldname,
						revision = record.revision,
						url = record.url,
						date = record.date,
					}
				end
			end
			local cdata = commonlib.serialize_compact(clientdata);
			if(cdata) then
				ItemManager.SetClientData(guid, cdata, function(msg)
					if(callbackFunc) then
						callbackFunc();
					end
				end);
			end
		end
	end
end

function WorldUploadPage.ShowPage(bShow)

	WorldUploadPage.CheckLoadRecordGsid();

	local width, height = 512, 512;
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Areas/WorldUploadPage.html", 
			name = "WorldUploadPage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			enable_esc_key = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			bShow = bShow,
			directPosition = true,
				align = "_ct",
				x = -width/2,
				y = -height/2,
				width = width,
				height = height,
		});
end

-- compress and generate zip package for the current world.
-- once succeed, the callbackFunc(zipfile) is called. 
function WorldUploadPage.OnGeneratePackage(callbackFunc)
	-- compress the world in self.source, if it is not already compressed
	local worldpath = ParaWorld.GetWorldDirectory();
	local zipfile = worldpath:gsub("[/\\]$", ".zip");
	local worldname = string.match(worldpath, "([^/\\]+)[/\\]$");

	local function MakePackage_()
		local writer = ParaIO.CreateZip(zipfile,"");
		writer:AddDirectory(worldname, worldpath.."*.*", 6);
		writer:close();
		if(callbackFunc) then
			callbackFunc(zipfile);
		else
			if(page) then
				page:SetUIValue("result", format("世界成功打包到%s", commonlib.Encoding.DefaultToUtf8(zipfile)));
			end
		end
	end
	
	if(ParaIO.DoesFileExist(zipfile)) then
		_guihelper.MessageBox(string.format("是否确定覆盖之前的世界:%s", commonlib.Encoding.DefaultToUtf8(zipfile)), function ()
			ParaAsset.CloseArchive(zipfile);
			ParaIO.DeleteFile(zipfile);
			MakePackage_()
		end)
	else
		MakePackage_();
	end
end


-- @param text: error message to be displayed in message box, it can be HTML.
function WorldUploadPage.OnUploadError(text)
	WorldUploadPage.IsUploading = false;
	LOG.std(nil, "error", "WorldUploadPage.OnUploadError", text);
	_guihelper.MessageBox(text);
end

---------------------------------------------
-- upload world logics: make zip, pkg and then upload to web. 
---------------------------------------------

-- display upload progress
function WorldUploadPage.ShowUploadProgress(text)
	page:SetUIValue("progress", text);
end


function WorldUploadPage.GetMySlot(slot_id)
	if(WorldUploadPage.save_records) then
		return WorldUploadPage.save_records[slot_id];
	end
end

function WorldUploadPage.GetMySlotValue(slot_id, name)
	if(WorldUploadPage.save_records) then
		local record = WorldUploadPage.save_records[slot_id];
		if(record) then
			if(name == "save_times") then
				local save_times = 0;
				if(record.date) then
					local date, times = record.date:match("^([^_]*)_(%d+)$");
					if(date and times) then
						local server_date = Scene.GetServerDate();
						if(date == server_date) then
							save_times = tonumber(times) + 1;
						end
					end
				end
				return save_times;
			elseif(not name) then
				return record;
			else
				return record[name];
			end
		end
	end
end

function WorldUploadPage.CloseWindow()
	page:CloseWindow();
end

-- @param slot_id: the slot index [1,8]
function WorldUploadPage.ClickOncePublish(slot_id)
	if(not EnterGamePage.CheckRight("uploadgame")) then
		return;
	end
	
	slot_id = tonumber(slot_id);
	if(slot_id and slot_id>=1 and slot_id<=100) then
		if(not WorldUploadPage.IsUploading) then
			if((WorldUploadPage.GetMySlotValue(slot_id, "save_times") or 0) >= WorldUploadPage.MaxUploadCount) then
				
				_guihelper.MessageBox(string.format("每个保存槽每天只能提交%d次,明天再提交吧", WorldUploadPage.MaxUploadCount))
				if(not System.options.isAB_SDK) then
					return;
				end
			end
			-- save current world
			if(GameLogic.SaveAll(false) == false) then
				-- just in case save failed such as a readonly world
				return;
			end

			-- compress first
			WorldUploadPage.OnGeneratePackage(function(zipfile)
				-- upload to file server
				if(System.User.nid == 0) then
					_guihelper.MessageBox("登录后才能上传存档到服务器");
					return;
				end
				WorldUploadPage.UploadToFileServer(slot_id, zipfile, function(progress)
					if(progress == 100) then
						upload_count = upload_count + 1;
						local record = WorldUploadPage.save_records[slot_id] or {revision=0};
						record.worldname = WorldCommon.GetWorldInfo().name;
						record.revision = record.revision + 1;
						record.url = WorldUploadPage.url;

						local server_date = Scene.GetServerDate();
						local save_times = WorldUploadPage.GetMySlotValue(slot_id, "save_times");
						record.date = format("%s_%d",  server_date or "", (save_times or 0)+1);

						-- record.date = 
						WorldUploadPage.save_records[slot_id] = record;
						WorldUploadPage.SaveRecordData(function() 
							WorldUploadPage.CloseWindow();
							_guihelper.MessageBox("上传成功！");
						end)
					end
				end);
			end)
		
		else
			_guihelper.MessageBox([[<div style="margin-top:20px">你刚刚提交的世界还在上传中，暂时不能上传新的世界，请稍候重试。</div>]]);
		end
	end
end

-- @param slot_id: to which slot to save to. usually value [1,100]. Each slot has a unique name on the server.
-- @param OnProgressCallbackFunc: function(progress, text) end
function WorldUploadPage.UploadToFileServer(slot_id, worldzipfile, OnProgressCallbackFunc)
	if(not slot_id) then
		return
	end
	WorldUploadPage.worldzipfile = worldzipfile;
	WorldUploadPage.worldname = string.gsub(worldzipfile, ".*/(.-)$", "%1");
	WorldUploadPage.totalsize = ParaIO.GetFileSize(worldzipfile);
	if(WorldUploadPage.totalsize>WorldUploadPage.MaxTotalsize) then
		WorldUploadPage.OnUploadError([[<div style="margin-top:20px">抱歉, 你的世界超出了最大尺寸, 目前暂时不提供大型世界的上传，请用手工分享功能</div>]]);
		return;
	end

	WorldUploadPage.IsUploading = true;
	WorldUploadPage.progress = 0;

	local function OnProgress_(text)
		WorldUploadPage.ShowUploadProgress(text);
		if(OnProgressCallbackFunc) then
			OnProgressCallbackFunc(WorldUploadPage.progress, text);
		end
	end 

	OnProgress_(string.format("正在上传: 大小%d KB", math.floor(WorldUploadPage.totalsize/1000)));
	local msg = {
		src = worldzipfile,
		-- upload to worlds folder on remote server
		filepath = format("persist/%d_%d", System.User.nid, slot_id),
		overwrite = 1, -- overwrite it.
	};
	local res = paraworld.file.UploadFileEx(msg, "worldupload", function(msg)
		if(msg~=nil and msg.size) then
			if(msg.url~=nil and  msg.size == WorldUploadPage.totalsize) then
				LOG.std(nil, "info", "WorldUploadPage", "world file successfully uploaded to url: %s\n", msg.url)
				WorldUploadPage.progress = 100;
				WorldUploadPage.IsUploading = false;
				WorldUploadPage.url = msg.url;
				OnProgress_("上传成功");
			else
				WorldUploadPage.progress = WorldUploadPage.progress + 5;
				if(WorldUploadPage.progress> 90) then
					WorldUploadPage.progress = 90;
				end
				OnProgress_(string.format("正在上传:%d/%d KB", math.floor(tonumber(msg.size)/1000),  math.floor(WorldUploadPage.totalsize/1000)));
			end	
		else
			WorldUploadPage.OnUploadError([[<div style="margin-top:20px">抱歉, 上传被终止了, 可能服务器繁忙, 改天再试试吧</div>]]);
			LOG.std(nil, "error", "WorldUploadPage.OnUploadError", msg);
		end	
	end)
	if(res == paraworld.errorcode.RepeatCall) then
		_guihelper.MessageBox([[<div style="margin-top:20px">你刚刚提交的世界还在上传中，暂时不能上传新的世界，请稍候重试。</div>]]);
	end
end