--[[
Title: save world page
Author(s): LiXizhi
Date: 2008/6/27
Desc: 
It can take snapshot for the current world. It can quick save or full save the world to local disk. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/worlds/SaveWorldPage.lua");
-------------------------------------------------------
]]

-- create class
local SaveWorldPage = commonlib.gettable("Map3DSystem.App.worlds.SaveWorldPage")
local page;

-- when no world info page is provided, we will show this one. 
-- it takes worldpath as parameter like WorldInfoPage.html?worldpath=worlds/MyWorlds/abc
SaveWorldPage.DefaultWorldInfoPage = "script/kids/3DMapSystemApp/worlds/WorldInfoPage.html"

-- show the default category page. 
function SaveWorldPage.OnInit()
	page = document:GetPageCtrl();
	page:SetNodeValue("worldpath", ParaWorld.GetWorldDirectory());
	if(not Map3DSystem.User.HasRight("Save"))then
		page:SetNodeValue("result", "您没有权限保存这个世界.");
	end
	
	local filepath = ParaWorld.GetWorldDirectory().."preview.jpg";
	if(ParaIO.DoesFileExist(filepath, true)) then
		page:SetNodeValue("WorldImage", filepath);
	else
		page:SetNodeValue("WorldImage", "Texture/3DMapSystem/brand/noimageavailable.dds");
	end	
end

-- take snapshot and use as current world preview image 
function Map3DSystem.App.worlds.SaveWorldPage.TakeWorldImage()
	NPL.load("(gl)script/kids/3DMapSystemUI/ScreenShot/SnapshotPage.lua");
	
	local filepath = ParaWorld.GetWorldDirectory().."preview.jpg";
	local page = document:GetPageCtrl();
	
	local function SaveAsWorldPreview()
		if(MyCompany.Apps.ScreenShot.SnapshotPage.TakeSnapshot(filepath,300,200, false)) then
			page:SetUIValue("result", string.format("世界截图保存成功:%s", filepath));
			page:SetUIValue("WorldImage", filepath);
		end
	end
	
	if(ParaIO.DoesFileExist(filepath, true)) then
		_guihelper.MessageBox(string.format("世界预览截图 %s 已经存在, 你是否要覆盖它?", filepath), function()
			SaveAsWorldPreview();
			ParaAsset.LoadTexture("",filepath,1):UnloadAsset();
		end);
	else
		SaveAsWorldPreview();
	end	
end

-- close the window
function SaveWorldPage.OnClose()
	-- Map3DSystem.App.Commands.Call("File.SaveAndPublish");
	if(page) then
		page:CloseWindow();
	end
end

-- save only changed content
function SaveWorldPage.OnQuickSave()
	SaveWorldPage.OnClose()
	
	Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.SCENE_SAVE, bQuickSave=true})
end

-- save all within 500 meters. 
function SaveWorldPage.OnSaveAll()
	SaveWorldPage.OnClose()
	
	Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.SCENE_SAVE})
end

-- save as a different world. 
function SaveWorldPage.OnSaveAs()
	local page = document:GetPageCtrl();
	if(not Map3DSystem.User.HasRight("Save"))then
		-- do not allow copying if world is ready only
		_guihelper.MessageBox("对不起, 您没有权限保存这个世界.");
		return 
	end
	
	NPL.load("(gl)script/ide/OpenFileDialog.lua");
	local ctl = CommonCtrl.OpenFileDialog:new{
		name = "OpenFileDialog1",
		alignment = "_ct",
		left=-256, top=-150,
		width = 512,
		height = 380,
		parent = nil,
		CheckFileExists = false,
		FileName = string.gsub(ParaWorld.GetWorldDirectory(), "[/\\]$", "_copy"),
		fileextensions = {"all files(*.)",},
		folderlinks = {
			{path = "worlds/MyWorlds", text = "我的世界"},
			{path = "worlds/Official", text = "官方世界"},
			{path = "worlds/Templates/", text = "模板世界"},
		},
		onopen = function(name, filepath)
			if(filepath == ParaWorld.GetWorldDirectory()) then
				page:SetUIValue("result", "请指定一个不同的名字");
				return
			end
			if(ParaIO.DoesFileExist(filepath)) then	
				page:SetUIValue("result", "另存为的目录文件已经存在, 请指定不同的文件");
				return
			end
			
			local res = Map3DSystem.CreateWorld(filepath, ParaWorld.GetWorldDirectory(), true, true);
			if(res == true) then
				SaveWorldPage.OnClose();
				autotips.AddMessageTips(string.format("世界成功复制到:%s 你现在可以打开它", filepath));
			elseif(type(res) == "string") then
				page:SetUIValue("result", res);
			end
		end
	};
	ctl:Show(true);
end

-- open current world directory in windows explorer.
function SaveWorldPage.OnOpenWorldDir()
	Map3DSystem.App.Commands.Call("File.WinExplorer", ParaWorld.GetWorldDirectory());
end
