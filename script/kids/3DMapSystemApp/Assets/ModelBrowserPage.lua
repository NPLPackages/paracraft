--[[
Title: code behind page for ModelBrowserPage.html
Author(s): LiXizhi
Date: 2008/4/25
Desc: pick an model and add it to scene. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/Assets/ModelBrowserPage.lua");
-------------------------------------------------------
]]

-- require to use Map3DSystem.App.Assets.asset
NPL.load("(gl)script/kids/3DMapSystemApp/Assets/AssetData.lua");
NPL.load("(gl)script/ide/Encoding.lua");

local ModelBrowserPage = {};
commonlib.setfield("Map3DSystem.App.Assets.ModelBrowserPage", ModelBrowserPage)

---------------------------------
-- page event handlers
---------------------------------
local page;
-- first time init page
function ModelBrowserPage.OnInit()
	page = document:GetPageCtrl();
	local self = page;

	local assets = Map3DSystem.App.Assets.app:ReadConfig("RecentlyOpenedAssets", {})
	local index, value
	for index, value in ipairs(assets) do
		self:SetNodeValue("filepath", commonlib.Encoding.DefaultToUtf8(value));
	end
	self:SetNodeValue("filepath", "");
end

-- User clicks a file
function ModelBrowserPage.OnSelectFile(name, filepath)
	local old_path = commonlib.Encoding.Utf8ToDefault(page:GetUIValue("filepath"));
	if(old_path ~= filepath) then
		page:SetUIValue("filepath", commonlib.Encoding.DefaultToUtf8(filepath));
		ModelBrowserPage.OnClickRefreshPreview_Internal(true);
	end	
end

-- user doublle clicks a file, it will select it and add it to scene. 
function ModelBrowserPage.OnDoubleClickFile(name, filepath)
	ModelBrowserPage.OnClickAddToScene_internal(true);
end

-- user selects a new folder
function ModelBrowserPage.OnSelectFolder(name, folderPath)
	local filebrowserCtl = page:FindControl("FileBrowser");
	if(filebrowserCtl and folderPath) then
		filebrowserCtl:ChangeFolder(folderPath);
	end
end

-- user selects a new filter
function ModelBrowserPage.OnSelectFilter(name, filter)
	local filebrowserCtl = page:FindControl("FileBrowser");
	if(filebrowserCtl and filter) then
		filebrowserCtl.filter = filter;
		filebrowserCtl:ResetTreeView();
	end
end

-- add the current model to file. 
function ModelBrowserPage.OnClickAddToScene()
	ModelBrowserPage.OnClickAddToScene_internal()
end

-- private function
-- @param silentMode : if true no UI alert is displayed. 
function ModelBrowserPage.OnClickAddToScene_internal(silentMode,filepath)
	filepath = filepath or commonlib.Encoding.Utf8ToDefault(page:GetUIValue("filepath"));
	local ext = string.match(filepath, "%.(%w+)$");
	if(ext ~= nil) then
		ext = string.lower(ext);
	end
	
	-- check for relative path texture or xmodel file reference
	if(ParaIO.DoesFileExist(filepath)) then
		local file = ParaIO.open(filepath, "r");
		if(file:IsValid() == true) then
			-- read a line 
			local line = file:readline();
			while(line) do
				if(string.find(line, ":")) then
					local file = string.match(line, [["(.-)"]]);
					if(file) then
						_guihelper.MessageBox("文件:"..filepath.."<br/>含有绝对路径引用:"..file);
					end
					break;
				end
				line = file:readline();
			end
			file:close();
		end
	end
	
	if(not ParaIO.DoesFileExist(filepath)) then
		if(not silentMode) then
			_guihelper.MessageBox(string.format("X文件 %s 不存在.", filepath));
		end
	elseif(ext == "x" or ext == "xml") then
		-- refresh the file. 
		local asset = Map3DSystem.App.Assets.asset:new({filename = filepath})
		
		local objParams = asset:getModelParams()
		if(objParams~=nil) then
			-- create object by sending a message
			Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_CreateObject, progress=1, obj_params=objParams});

			-- save to recently opened assets
			local assets = Map3DSystem.App.Assets.app:ReadConfig("RecentlyOpenedAssets", {})
			local bNeedSave;
			-- sort by order
			local index, value, found
			for index, value in ipairs(assets) do
				if(value == filepath) then
					if(index>1) then
						commonlib.moveArrayItem(assets, index, 1)
						bNeedSave = true;
					end	
					found = true;
					break;
				end
			end
			if(not found) then
				commonlib.insertArrayItem(assets, 1, filepath)
				bNeedSave = true;
			end
			if(bNeedSave) then
				if(#assets>50) then
					commonlib.resize(assets, 50)
				end
				Map3DSystem.App.Assets.app:WriteConfig("RecentlyOpenedAssets", assets)
				Map3DSystem.App.Assets.app:SaveConfig();
			end
		end
	elseif(ext == "raw") then	
		-- apply terrain height field file. 
		local x,y,z  = ParaScene.GetPlayer():GetPosition();
		local nSize = math.sqrt(ParaIO.GetFileSize(filepath) / 4);
		local tilesize = ParaTerrain.GetAttributeObjectAt(x,z):GetField("size", 533.333);
		
		local brush = {
			type = "AddHeightField",
			x = x,
			y = y,
			z = z,
			filename = filepath, 
			radius = tilesize/128*nSize, 
			smoothpixels = 10, -- number of pixels to smooth at the edge
		}
		--commonlib.echo({brush, tilesize, nSize})
		
		Map3DSystem.SendMessage_env({type = Map3DSystem.msg.TERRAIN_HeightField, brush=brush})
		
	else
		if(not silentMode) then
			_guihelper.MessageBox("请先选择一个X文件");
		end	
	end
end

-- refresh the current page. 
function ModelBrowserPage.OnClickRefreshPreview()
	ModelBrowserPage.OnClickRefreshPreview_Internal();
end

-- private function
-- @param silentMode : if true no UI alert is displayed. 
function ModelBrowserPage.OnClickRefreshPreview_Internal(silentMode)
	local filepath = commonlib.Encoding.Utf8ToDefault(page:GetUIValue("filepath") or "");
	local _,_, ext = string.find(filepath, "%.(%w+)$");
	if(ext ~= nil) then
		ext = string.lower(ext);
	end
	local IsUnknown;
	if(ext==nil or filepath == nil or filepath =="") then
		if(not silentMode) then
			_guihelper.MessageBox("请先选择一个X文件");
		end	
		IsUnknown = true;
	elseif(not ParaIO.DoesFileExist(filepath)) then
		if(not silentMode) then
			_guihelper.MessageBox(string.format("X文件 %s 不存在.", filepath));
		end
		IsUnknown = true;
	elseif(ext == "x" or ext == "xml") then
		-- refresh the file. 
		local asset = Map3DSystem.App.Assets.asset:new({filename = filepath})
		
		-- refresh the model in modelCanvas control. 
		local objParams = asset:getModelParams()
		if(objParams~=nil) then
			local canvasCtl = page:FindControl("modelCanvas");
			if(canvasCtl) then
				canvasCtl:ShowModel(objParams);
				
				local icon = asset:getIcon();
				if(ParaIO.DoesFileExist(icon)) then
					page:SetUIValue("ThumbnailImg", icon);
				end
			end
		else
			IsUnknown = true;	
		end
	elseif(ext == "png" or ext == "jpg" or ext == "tga" or ext == "bmp" or ext == "dds" ) then	
		local canvasCtl = page:FindControl("modelCanvas");
		if(canvasCtl) then
			canvasCtl:ShowImage(filepath);
			page:SetUIValue("ThumbnailImg", "");
		end
	elseif(ext == "raw") then
		local canvasCtl = page:FindControl("modelCanvas");
		if(canvasCtl) then
			canvasCtl:ShowImage("");
		end	
	else
		IsUnknown = true;
		if(not silentMode) then
			_guihelper.MessageBox("请先选择一个X文件");
		end	
	end
	
	-- unknown file format
	if(IsUnknown) then
		local canvasCtl = page:FindControl("modelCanvas");
		if(canvasCtl) then
			canvasCtl:ShowImage("");
			page:SetUIValue("ThumbnailImg", "");
		end	
	end	
end

-- take snapshot
function Map3DSystem.App.Assets.ModelBrowserPage.OnClickTakeSnapShot()
	local filepath = commonlib.Encoding.Utf8ToDefault(page:GetUIValue("filepath"));
	local _,_, ext = string.find(filepath, "%.(%w+)$");
	if(ext ~= nil) then
		ext = string.lower(ext);
	end
	
	if(not ParaIO.DoesFileExist(filepath)) then
		_guihelper.MessageBox(string.format("X文件 %s 不存在.", filepath));
	elseif(ext == "x" or ext == "xml") then
		-- refresh the file. 
		local asset = Map3DSystem.App.Assets.asset:new({filename = filepath})
		
		local icon = asset:getIcon();
		-- only save for Non-http icon to disk. 
		if(icon and string.find(icon,"^http")==nil) then
			icon = string.gsub(icon, ":.*$", "")
			local ctl = page:FindControl("modelCanvas");
			if(ctl) then
				local dlgText;
				if(ParaIO.DoesFileExist(icon, true)) then	
					dlgText = string.format("文件: %s 已经存在, 您确定要覆盖它么?", icon);
				else
					dlgText = string.format("您确定要保存到文件: %s 么?", icon);
				end
				local pageCtrl = page;
				_guihelper.MessageBox(dlgText, function ()
					log(icon.."is saved")
					ctl:SaveToFile(icon, 64)
					-- reload asset.
					CommonCtrl.OneTimeAsset.Unload(icon);
					-- refresh all control to reflect the changes. 
					pageCtrl:SetUIValue("ThumbnailImg", icon);
				end)
			end
		end	
	else
		_guihelper.MessageBox("请选择ParaX模型文件");	
	end
end