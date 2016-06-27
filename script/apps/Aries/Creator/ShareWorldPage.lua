--[[
Title: save world page
Author(s): LiXizhi
Date: 2010/2/8
Desc: 
It can take snapshot for the current world. It can quick save or full save the world to local disk. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/ShareWorldPage.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/kids/3DMapSystemApp/API/litemail/paraworld.litemail.lua");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")

-- create class
local ShareWorldPage = commonlib.gettable("MyCompany.Aries.Creator.ShareWorldPage")


-- user can only upload file size smaller than 10 MB.
ShareWorldPage.MaxTotalsize = 10240000; 

local upload_count = 0;
-- max number of times to upload to server per day. (currently it is per game startup)
ShareWorldPage.MaxUploadCount = 5;

local page;

-- show the default category page. 
function ShareWorldPage.OnInit()
	page = document:GetPageCtrl();
	
	local filepath = ParaWorld.GetWorldDirectory().."preview.jpg";
	if(ParaIO.DoesFileExist(filepath, true)) then
		page:SetNodeValue("WorldImage", filepath);
	else
		page:SetNodeValue("WorldImage", "Texture/Aries/brand/noimageavailable.png");
	end
	
	local world_tag = WorldCommon.LoadWorldTag();
	ShareWorldPage.world_tag = world_tag;
	if(world_tag) then
		page:SetNodeValue("world_name", world_tag.name or "");
	end
end

-- close the window
function ShareWorldPage.OnClose()
	page:CloseWindow();
end

-- submit the world. 
function ShareWorldPage.OnClickSubmit(name, values)
	if(values.checkSaveWhenShare) then
		WorldCommon.SaveWorld();
	end
	ShareWorldPage.world_desc = values.world_desc or "";
	ShareWorldPage.StartUpload();
end

---------------------------------------------
-- upload world logics: make zip, pkg and then upload to web. 
---------------------------------------------

-- display upload progress
function ShareWorldPage.ShowUploadProgress(text)
	commonlib.echo(text)
	page:SetUIValue("result", text);
	if(ShareWorldPage.progress == 100) then
		upload_count = upload_count + 1;
		ShareWorldPage.OnClose();
		
		ParaAsset.CloseArchive(ShareWorldPage.worldzipfile);
		ParaIO.DeleteFile(ShareWorldPage.worldzipfile);
		
		
		-- sending a email to Minister Lord
		commonlib.echo({
			"upload succeed, sending an email to Minister Lord",
			url = ShareWorldPage.url,
			fileSize = ShareWorldPage.totalsize,
			world_desc = ShareWorldPage.world_desc,
		})
		local title = ShareWorldPage.url.."|"..ShareWorldPage.totalsize;
		local content = ShareWorldPage.world_desc;
		local msg = {
			nid = Map3DSystem.User.nid,
			cid = 100,
			title = title,
			msg = content,
		}
		commonlib.echo("=========before send mail in ShareWorldPage:");
		commonlib.echo(msg);
		paraworld.litemail.Add(msg,"ShareWorldPage",function(msg)
			commonlib.echo("=========after send mail in ShareWorldPage:");
			commonlib.echo(msg);
			if(msg and msg.issuccess)then
				_guihelper.MessageBox([[<div style="margin-top:28px">你的领地设计稿已经提交给罗德镇长了<br/>期待你更多更好的设计哦！</div>]]);
			else
				_guihelper.MessageBox("<div style='margin-left:15px;margin-top:35px;text-align:center'>投稿失败！</div>");
			end
			
		end);
	end
end

-- @param text: error message to be displayed in message box, it can be HTML.
function ShareWorldPage.OnUploadError(text)
	ShareWorldPage.IsUploading = false;
	log("world upload error: ");
	commonlib.echo(text);
	ShareWorldPage.OnClose();
	_guihelper.MessageBox(text);
end

-- start a new upload progress
function ShareWorldPage.StartUpload()
	if(not ShareWorldPage.IsUploading) then
		if(upload_count >= ShareWorldPage.MaxUploadCount) then
			_guihelper.MessageBox(string.format([[<div style="margin-top:32px">你今天已经提交过%d次设计方案了<br/>多谢你的参与，请明天再来提交吧！</div>]], ShareWorldPage.MaxUploadCount))
			return;
		end
		
		ShareWorldPage.IsUploading = true;
		ShareWorldPage.progress = 0;
		
		-- start the first stage
		ShareWorldPage.CompressWorld();
	else
		ShareWorldPage.OnUploadError([[<div style="margin-top:20px">你刚刚提交的领地还在上传中，暂时不能上传新的领地，请稍候重试。</div>]]);
	end
end

---------------------------------------
-- local stage: compress world to zip file
---------------------------------------
function ShareWorldPage.CompressWorld()
	
	-- compress the world
	local source = Map3DSystem.world.name;
	local worldpath = source.."/";
	local zipfile = source..".zip";
	local worldname = string.gsub(source, ".*/(.-)$", "%1");

	local function MakePackage_()
		local writer = ParaIO.CreateZip(zipfile,"");
		writer:AddDirectory(worldname, worldpath.."*.*", 6);
		writer:close();
		ShareWorldPage.ShowUploadProgress(string.format("世界成功打包到%s", zipfile));
		ShareWorldPage.worldzipfile = zipfile;
		
		-- goto next stage
		ShareWorldPage.UploadToFileServer()
	end
	
	if(ParaIO.DoesFileExist(zipfile)) then
		-- close and delete old file. 
		ParaAsset.CloseArchive(zipfile);
		ParaIO.DeleteFile(zipfile);
		log("old zip file exist, we will delete it before making a new one\n");
	end
		
	MakePackage_()
end

---------------------------------------
-- web stage: upload to space server
---------------------------------------
function ShareWorldPage.UploadToFileServer()
	local worldzipfile = ShareWorldPage.worldzipfile;
	ShareWorldPage.worldname = string.gsub(worldzipfile, ".*/(.-)$", "%1");
	ShareWorldPage.totalsize = ParaIO.GetFileSize(worldzipfile);
	if(ShareWorldPage.totalsize>ShareWorldPage.MaxTotalsize) then
		ShareWorldPage.OnUploadError([[<div style="margin-top:20px">抱歉, 你的领地超出了最大尺寸, 内测期间暂时不提供大型领地的上传</div>]]);
		return;
	end
	
	ShareWorldPage.ShowUploadProgress(string.format("正在上传领地; 文件大小%d KB", math.floor(ShareWorldPage.totalsize/1000)));
	local msg = {
		src = worldzipfile,
		-- upload to worlds folder on remote server
		filepath = "worlds/"..ShareWorldPage.worldname,

		overwrite = 1, -- overwrite it.
	};
	local res = paraworld.file.UploadFileEx(msg, "worldupload", function(msg)
		if(msg~=nil and msg.size) then
			if(msg.url~=nil and  msg.size == ShareWorldPage.totalsize) then
				commonlib.log("world file successfully uploaded to %s\n", msg.url)
				ShareWorldPage.progress = 100;
				ShareWorldPage.url = msg.url;
				ShareWorldPage.ShowUploadProgress("领地上传成功");
			else
				ShareWorldPage.progress = ShareWorldPage.progress + 5;
				if(ShareWorldPage.progress> 90) then
					ShareWorldPage.progress = 90;
				end
				ShareWorldPage.ShowUploadProgress(string.format("正在上传:%d/%d KB", math.floor(tonumber(msg.size)/1000),  math.floor(ShareWorldPage.totalsize/1000)));
			end	
		else
			commonlib.echo(msg)
			ShareWorldPage.OnUploadError([[<div style="margin-top:20px">抱歉, 领地上传被终止了, 可能服务器繁忙, 改天再试试吧</div>]]);
		end	
	end)
	if(res == paraworld.errorcode.RepeatCall) then
		ShareWorldPage.OnUploadError([[<div style="margin-top:20px">你刚刚提交的领地还在上传中，暂时不能上传新的领地，请稍候重试。</div>]]);
	end
end
