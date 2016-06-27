--[[
Title: save world page
Author(s): LiXizhi
Date: 2010/1/27
Desc: 
It can take snapshot for the current world. It can quick save or full save the world to local disk. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/SaveWorldPage.lua");
MyCompany.Aries.Creator.SaveWorldPage.ShowPage()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")

-- create class
local SaveWorldPage = commonlib.gettable("MyCompany.Aries.Creator.SaveWorldPage")


local page;

-- when no world info page is provided, we will show this one. 
-- it takes worldpath as parameter like WorldInfoPage.html?worldpath=worlds/MyWorlds/abc
SaveWorldPage.DefaultWorldInfoPage = "script/apps/Aries/Creator/WorldInfoPage.html"

-- show the page in mcml window
function SaveWorldPage.ShowPage()
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/SaveWorldPage.html",
			name = "SaveWorldPage.ShowPage",
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			isTopLevel = true,
			directPosition = true,
				align = "_ct",
				x = -265,
				y = -160,
				width = 530,
				height = 320,
		});
end


-- show the default category page. 
function SaveWorldPage.OnInit()
	page = document:GetPageCtrl();
	page:SetNodeValue("worldpath",  commonlib.Encoding.DefaultToUtf8(string.gsub(ParaWorld.GetWorldDirectory(), ".*DesignHouse[/\\]", "")));
	
	local filepath = ParaWorld.GetWorldDirectory().."preview.jpg";
	if(ParaIO.DoesFileExist(filepath, true)) then
		page:SetNodeValue("WorldImage", filepath);
	else
		page:SetNodeValue("WorldImage", "Texture/Aries/brand/noimageavailable.png");
	end
	
	local world_tag = WorldCommon.LoadWorldTag();
	SaveWorldPage.world_tag = world_tag;
	if(world_tag) then
		page:SetNodeValue("world_name", world_tag.name or "");
		-- page:SetNodeValue("world_desc", world_tag.desc or "");
		page:SetValue("world_size", world_tag.size or "1000");
	end
end

-- take snapshot and use as current world preview image 
function SaveWorldPage.TakeWorldImage()
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
		_guihelper.MessageBox(string.format("世界预览图已经存在, 是否要覆盖它?"), function()
			SaveAsWorldPreview();
			ParaAsset.LoadTexture("",filepath,1):UnloadAsset();
		end);
	else
		SaveAsWorldPreview();
	end	
end

-- open current world directory in windows explorer.
function SaveWorldPage.OnOpenWorldDir()
	Map3DSystem.App.Commands.Call("File.WinExplorer", {filepath = ParaWorld.GetWorldDirectory(), silentmode=true});
end

-- close the window
function SaveWorldPage.OnClose()
	page:CloseWindow();
end

-- save all within 500 meters. 
-- TODO: save modified places, if it is larger than 500 meters.  
function SaveWorldPage.OnSaveAll(name, values)
	if(values.world_name and string.len(values.world_name)>=20) then
		_guihelper.MessageBox([[<div style="margin-top:32px">您输入的领地名称太长了</div>]])
		return
	elseif(values.world_desc and string.len(values.world_desc)>=100) then
		_guihelper.MessageBox([[<div style="margin-top:32px">您输入的领地宣言太长了</div>]])
		return
	end
	local world_size = tonumber(values.world_size);
	if(world_size) then
		if(world_size ~= 0 and (world_size<100 or world_size>160000)) then
			_guihelper.MessageBox([[<div style="margin-top:32px">您输入的领地大小不合适</div>]])
		end
		WorldCommon.SetPlayerMovableRegion(world_size/2)
	end
	
	world_tag = SaveWorldPage.world_tag;
	world_tag.name = string.gsub(values.world_name, "[\"/\\]", "");
	world_tag.size = tonumber(values.world_size) or world_tag.size or 0;
	
	if(values.world_desc) then
		world_tag.desc = string.gsub(values.world_desc, "[\"/\\]", "");	
	end	
	
	if(WorldCommon.SaveWorldTag()) then
		SaveWorldPage.OnClose()
		WorldCommon.SaveWorld();
	end	
end



function SaveWorldPage.ShowSharePage()
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Areas/ShareWorldPage.html",
			name = "SaveWorldPage.ShowSharePage",
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			isTopLevel = true,
			directPosition = true,
				align = "_ct",
				x = -310/2,
				y = -270/2,
				width = 310,
				height = 270,
		});
	SaveWorldPage.TakeSharePageImage();
end

function SaveWorldPage.TakeSharePageImage()
	local page = SaveWorldPage.sharepage;
	NPL.load("(gl)script/kids/3DMapSystemUI/ScreenShot/SnapshotPage.lua");	
	local filepath = ParaWorld.GetWorldDirectory().."preview.jpg";
	
	local function SaveAsWorldPreview()
		if(MyCompany.Apps.ScreenShot.SnapshotPage.TakeSnapshot(filepath,300,200, false)) then
			--page:SetUIValue("result", string.format("世界截图保存成功:%s", filepath));
			page:SetUIValue("ShareWorldImage", filepath);
		end
	end
	
	if(ParaIO.DoesFileExist(filepath, true)) then
        SaveAsWorldPreview();
		ParaAsset.LoadTexture("",filepath,1):UnloadAsset();
        --[[
		_guihelper.MessageBox(string.format("世界预览图已经存在, 是否要覆盖它?"), function()
			SaveAsWorldPreview();
			ParaAsset.LoadTexture("",filepath,1):UnloadAsset();
		end);
        ]]
	else
		SaveAsWorldPreview();
	end

end