--[[
Title: make app Command
Author(s): LiXizhi
Date: 2020/4/23
Desc: make current world into a standalone app file (zip)

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MakeAppTask.lua");
local MakeApp = commonlib.gettable("MyCompany.Aries.Game.Tasks.MakeApp");
local task = MyCompany.Aries.Game.Tasks.MakeApp:new()
task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local MakeApp = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.MakeApp"));

MakeApp.mode = {
	android = 0
}

function MakeApp:ctor()
end

function MakeApp:RunImp(mode, ...)
	if (mode == self.mode.android) then
		self:MakeAndroidApp(...)
		return
	end

	local name = WorldCommon.GetWorldTag("name");
	self.name = name
	local dirName = commonlib.Encoding.Utf8ToDefault(name)
	self.dirName = dirName
	local output_folder = ParaIO.GetWritablePath().."release/"..dirName.."/";
	self.output_folder = output_folder;

	_guihelper.MessageBox(format(L"是否将世界%s 发布为独立应用程序?", self.name), function(res)
		if(res and res == _guihelper.DialogResult.Yes) then
			self:MakeApp()
		end
	end, _guihelper.MessageBoxButtons.YesNo);
end

function MakeApp:Run(...)
	if(System.os.GetPlatform()~="win32") then
		_guihelper.MessageBox(L"此功能需要使用Windows操作系统");
		return
	end

	--[[
	GameLogic.IsVip("MakeApp", true, function(result) 
		if(result) then  
			self:RunImp()
		end
	end)
	]]
	self:RunImp(...);
end

function MakeApp:MakeApp()
	if(self:GenerateFiles()) then
		if(self:MakeZipInstaller()) then
			GameLogic.AddBBS(nil, L"恭喜！成功打包为独立应用程序", 5000, "0 255 0")
			System.App.Commands.Call("File.WinExplorer", self:GetOutputDir());
			return true;
		end
	end
end

function MakeApp:MakeAndroidApp(method)
	NPL.load("(gl)script/apps/Aries/Creator/Game/API/FileDownloader.lua");
	local FileDownloader = commonlib.gettable("MyCompany.Aries.Creator.Game.API.FileDownloader");

	local function downloadApk(callback)
		local apkUrl = 'https://cdn.keepwork.com/paracraft/android/paracraft.apk?ver=2.0.2';

		local fileDownloader = FileDownloader:new();
		fileDownloader.isSilent = true

		GameLogic.GetFilters():apply_filters('cellar.common.msg_box.show', L'正在获取基础文件，请稍候...', 30000, nil, 350)

		commonlib.TimerManager.SetTimeout(function()
			fileDownloader:Init('paracraft.apk', apkUrl, 'temp/paracraft.apk', function(result)
				if (result) then
					fileDownloader:DeleteCacheFile()
					ParaIO.MoveFile('temp/paracraft.apk', 'temp/paracraft.zip')

					GameLogic.GetFilters():apply_filters('cellar.common.msg_box.close')

					if (callback and type(callback) == 'function') then
						callback()
					end
				end
			end)
		end, 500)
	end

	local function unzipApk(callback)
		GameLogic.GetFilters():apply_filters('cellar.common.msg_box.show', L'正在解压，请稍候...', 30000, nil, 350)

		GameLogic.GetFilters():apply_filters(
			'service.local_service.move_zip_to_folder',
			'temp/paracraft_android/',
			'temp/paracraft.zip',
			function()
				ParaIO.DeleteFile('temp/paracraft_android/META-INF/')

				GameLogic.GetFilters():apply_filters('cellar.common.msg_box.close')

				if (callback and type(callback) == 'function') then
					callback()
				end
			end
		)
	end

	local function generateApk(callback)
		GameLogic.GetFilters():apply_filters('cellar.common.msg_box.show', L'正在打包，请稍候...', 30000, nil, 350)

		-- remove old generate apk
		ParaIO.DeleteFile('temp/paracraft_new.apk')

		local currentEnterWorld = GameLogic.GetFilters():apply_filters('store_get', 'world/currentEnterWorld')

		if currentEnterWorld then
			-- copy world
			local fileList = GameLogic.GetFilters():apply_filters('service.local_service.load_files', currentEnterWorld.worldpath, true, true)

			if not fileList or type(fileList) ~= 'table' or #fileList == 0 then
				return
			end

			local apkWorldPath = 'temp/paracraft_android/assets/worlds/DesignHouse/' ..
								 commonlib.Encoding.Utf8ToDefault(currentEnterWorld.foldername) .. '/'

			ParaIO.CreateDirectory(apkWorldPath)

			for key, item in ipairs(fileList) do
				local relativePath = commonlib.Encoding.Utf8ToDefault(item.filename)

				if item.filesize == 0 then
					local folderPath = apkWorldPath .. relativePath .. '/'

					ParaIO.CreateDirectory(folderPath)
				else
					local filePath = apkWorldPath .. relativePath

					ParaIO.CopyFile(item.file_path, filePath, true)
				end
			end

			-- update config.txt file
			local writeFile = ParaIO.open('temp/paracraft_android/assets/config.txt', "w")

			if (writeFile:IsValid()) then
				local content = 
					'cmdline=noupdate="true" mc="true" debug="main" bootstrapper="script/apps/Aries/main_loop.lua" ' .. 
					'world="' .. 'worlds/DesignHouse/' .. commonlib.Encoding.Utf8ToDefault(currentEnterWorld.foldername) .. '"'
				writeFile:write(content, #content)
				writeFile:close()
			end
		end

		GameLogic.GetFilters():apply_filters(
			'service.local_service.move_folder_to_zip',
			'temp/paracraft_android/',
			'temp/paracraft_new.apk',
			function()
				GameLogic.GetFilters():apply_filters('cellar.common.msg_box.close')

				if (callback and type(callback) == 'function') then
					callback()
				end
			end
		)
	end

	local function signApk()
		local function sign()
			if (not ParaIO.DoesFileExist('temp/sign_android_app.bat')) then
				local file = ParaIO.open('temp/sign_android_app.bat', "w")
	
				if (file:IsValid()) then
					file:WriteString("@echo off\n");
					file:WriteString("temp\\jre-windows\\bin\\jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore temp\\personal-key.keystore -storepass paracraft temp\\paracraft_new.apk paracraft\n");
					file:WriteString("echo APK SIGNED!GET APK FILE AT your_paracraft/temp/paracraft_new.apk \n")
					file:WriteString("pause\n")
					file:WriteString("exit\n")
				end
	
				file:close();
			end
	
			System.os.run('start temp\\sign_android_app.bat')
		end

		if (not ParaIO.DoesFileExist('temp/jre-windows/')) then
			local function downloadJre(callback)
				local jreTool = 'https://cdn.keepwork.com/paracraft/android/jre-windows.zip';
	
				local fileDownloader = FileDownloader:new();
				fileDownloader.isSilent = true;
	
				GameLogic.GetFilters():apply_filters('cellar.common.msg_box.show', L'正在获取Jre Runtime，请稍候...', 30000, nil, 400)
				commonlib.TimerManager.SetTimeout(function()
					fileDownloader:Init('jre-windows.zip', jreTool, 'temp/jre-windows.zip', function(result)
						if (result) then
							fileDownloader:DeleteCacheFile()
		
							GameLogic.GetFilters():apply_filters('cellar.common.msg_box.close')
							GameLogic.GetFilters():apply_filters('cellar.common.msg_box.show', L'正在解压Jre Runtime，请稍候...', 30000, nil, 400)
	
							GameLogic.GetFilters():apply_filters(
								'service.local_service.move_zip_to_folder',
								'temp/jre-windows/',
								'temp/jre-windows.zip',
								function()
									GameLogic.GetFilters():apply_filters('cellar.common.msg_box.close')
	
									if callback and type(callback) == 'function' then
										callback()
									end
								end
							)
						end
					end)
				end, 500)
			end

			local function downloadLicense(callback)
				local jreTool = 'https://cdn.keepwork.com/paracraft/android/personal-key.keystore';
	
				local fileDownloader = FileDownloader:new();
				fileDownloader.isSilent = true;
	
				GameLogic.GetFilters():apply_filters('cellar.common.msg_box.show', L'正在获取Certification，请稍候...', 30000, nil, 400)
				commonlib.TimerManager.SetTimeout(function()
					fileDownloader:Init('personal-key.keystore', jreTool, 'temp/personal-key.keystore', function(result)
						if (result) then
							fileDownloader:DeleteCacheFile()
		
							GameLogic.GetFilters():apply_filters('cellar.common.msg_box.close')
	
							if callback and type(callback) == 'function' then
								callback()
							end
						end
					end)
				end, 500)
			end

			downloadJre(function()
				downloadLicense(function()
					sign()
				end)
			end)
		else
			sign()
		end
	end

	local function clean()
		ParaIO.DeleteFile('temp/personal-key.keystore')
		ParaIO.DeleteFile('temp/jre-windows/')
		ParaIO.DeleteFile('temp/paracraft_android/')
		ParaIO.DeleteFile('temp/paracraft_new.apk')
		ParaIO.DeleteFile('temp/paracraft.zip')
		ParaIO.DeleteFile('temp/sign_android_app.bat')
		ParaIO.DeleteFile('temp/jre-windows.zip')
	end

	local function zip()
		if ParaIO.DoesFileExist('temp/paracraft_android/') then
			generateApk(function()
				signApk()
			end)
		else
			downloadApk(function()
				unzipApk(function()
					generateApk(function()
						signApk()
					end)
				end)
			end)
		end
	end

	if (method == 'zip') then
		zip()

		return
	end

	if (method == 'clean') then
		clean()
		return
	end

	GameLogic.GetFilters():apply_filters('cellar.common.msg_box.show', L'正在清理，请稍候...', 30000, nil, 400)
	commonlib.TimerManager.SetTimeout(function()
		clean()
		commonlib.TimerManager.SetTimeout(function()
			zip()
		end, 5000)
	end, 1000)
end

function MakeApp:GetOutputDir()
	return self.output_folder;
end

function MakeApp:GetBinDir()
	return self.output_folder.."bin/"
end

function MakeApp:GenerateFiles()
	ParaIO.CreateDirectory(self:GetBinDir())
	if(self:MakeStartupExe() and self:CopyWorldFiles() and self:GenerateHelpFile()) then
		if(self:CopyParacraftFiles()) then
			return true;
		end
	end
end

function MakeApp:GetBatFile()
	return self.output_folder.."start"..".bat";
end

function MakeApp:MakeStartupExe()
	local file = ParaIO.open(self:GetBatFile(), "w")
	if(file:IsValid()) then
		file:WriteString("@echo off\n");
		file:WriteString("cd bin\n");
		local worldPath = Files.ResolveFilePath(GameLogic.GetWorldDirectory()).relativeToRootPath or GameLogic.GetWorldDirectory()
		file:WriteString("start ParaEngineClient.exe noclientupdate=\"true\" world=\"%~dp0data/\"");
		file:close();
		return true;
	end
end

function MakeApp:GenerateHelpFile()
	local file = ParaIO.open(self.output_folder..commonlib.Encoding.Utf8ToDefault(L"使用指南")..".html", "w")
	if(file:IsValid()) then
		file:WriteString([[<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<META HTTP-EQUIV="Refresh" CONTENT="1; URL=https://keepwork.com/official/docs/tutorials/exe_Instruction">
<title>Paracraft App</title>
</head>
<body>
<p>Powered by NPL and paracraft</p>
<p>Page will be redirected in 3 seconds</p>
</body>
</html>
]]);
		file:close();
		return true;
	end
end

local excluded_files = {
	["log.txt"] = true,
	["paracraft.exe"] = true,
	["haqilauncherkids.exe"] = true,
	["haqilauncherkids.mem.exe"] = true,
	["auto_update_log.txt"] = true,
	["assets.log"] = true,
}

-- minimum paracraft files
local bin_files = {
	["ParaEngineClient.exe"] = true,
	["ParaEngineClient.dll"] = true,
	["physicsbt.dll"] = true,
	["ParaEngine.sig"] = true,
	["lua.dll"] = true,
	["FreeImage.dll"] = true,
	["libcurl.dll"] = true,
	["sqlite.dll"] = true,
	["assets_manifest.txt"] = true,
	["config/bootstrapper.xml"] = true,
	["config/GameClient.config.xml"] = true,
	["config/commands.xml"] = true,
	["config/config.txt"] = true,
	["caudioengine.dll"] = true,
	["config.txt"] = true,
	["d3dx9_43.dll"] = true,
	["main.pkg"] = true,
	["main_mobile_res.pkg"] = true,
	["main150727.pkg"] = true,
	["openal32.dll"] = true,
	["wrap_oal.dll"] = true,
	["database/characters.db"] = true,
	["database/extendedcost.db.mem"] = true,
	["database/globalstore.db.mem"] = true,
	["database/apps.db"] = true,
	["npl_packages/paracraftbuildinmod.zip"] = true,
}

function MakeApp:CopyParacraftFiles()
	local redist_root = self:GetBinDir();
	ParaIO.DeleteFile(redist_root)
	local sdk_root = ParaIO.GetCurDirectory(0);

	for filename, _ in pairs(bin_files) do
		ParaIO.CreateDirectory(sdk_root..filename);
		ParaIO.CopyFile(sdk_root..filename, redist_root..filename, true)
	end
	return true;
end

function MakeApp:CopyWorldFiles()
	WorldCommon.CopyWorldTo(self.output_folder.."data/")
	return true
end

function MakeApp:GetZipFile()
	return self.output_folder..self.dirName..".zip"
end

function MakeApp:MakeZipInstaller()
	local output_folder = self.output_folder;
	local result = commonlib.Files.Find({}, self.output_folder, 10, 5000, function(item)
		return true;
		--no need to check zipfile
		--[[
		local ext = commonlib.Files.GetFileExtension(item.filename);
		if(ext) then
			return (ext ~= "zip")
		end
		]]
	end)
	
	local zipfile = self:GetZipFile();
	ParaIO.DeleteFile(zipfile)
	local writer = ParaIO.CreateZip(zipfile,"");
	local appFolder = "ParacraftApp/";
	for i, item in ipairs(result) do
		local filename = item.filename;
		if(filename) then
			-- add all files
			local destFolder = (appFolder..filename):gsub("[/\\][^/\\]+$", "");
			writer:AddDirectory(destFolder, output_folder..filename, 0);
		end
	end
	writer:close();
	LOG.std(nil, "info", "MakeZipInstaller", "successfully generated package to %s", commonlib.Encoding.DefaultToUtf8(zipfile))
	return true;
end