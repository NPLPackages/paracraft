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

--------- thread part ---------
NPL.load("(gl)script/ide/commonlib.lua")
NPL.load("(gl)script/ide/System/Concurrent/rpc.lua")

local rpc = commonlib.gettable('System.Concurrent.Async.rpc')

rpc:new():init(
    'MyCompany.Aries.Game.Tasks.MakeAppThread.MakeApk',
    function(self, msg)
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MakeAppTask.lua");
		local MakeApp = commonlib.gettable("MyCompany.Aries.Game.Tasks.MakeApp");
		MakeApp:SignApkThread();

        return true 
    end,
    'script/apps/Aries/Creator/Game/Tasks/MakeAppTask.lua'
)
--------- thread part ---------

NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/API/FileDownloader.lua");
NPL.load("(gl)script/ide/System/Encoding/crc32.lua");
local Encoding = commonlib.gettable("System.Encoding");
local FileDownloader = commonlib.gettable("MyCompany.Aries.Creator.Game.API.FileDownloader");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local MakeApp = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.MakeApp"));

MakeApp.mode = {
	android = 0,
	UI = 1,
}

MakeApp.curAndroidVersion = '2.0.6';
MakeApp.androidBuildRoot = 'temp/build_android_resource/';

function MakeApp:ctor()
	if (not MakeApp.localAndroidVersion) then
		if (ParaIO.DoesFileExist(self.androidBuildRoot .. 'version.txt')) then
			local readFile = ParaIO.open(self.androidBuildRoot .. 'version.txt', 'r');

			if (readFile:IsValid()) then
				local version = readFile:GetText(0, -1);
				readFile:close();

				MakeApp.localAndroidVersion = version;
			end
		end
	end
end

function MakeApp:RunImp(mode, ...)
	if (mode == self.mode.UI) then
		System.App.Commands.Call(
			"File.MCMLWindowFrame",
			{
				url = 'script/apps/Aries/Creator/Game/Tasks/MakeApp.html',
				name = 'Tasks.MakeApp',
				isShowTitleBar = false,
				DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
				style = CommonCtrl.WindowFrame.ContainerStyle,
				zorder = 0,
				allowDrag = true,
				bShow = nil,
				directPosition = true,
				align = "_ct",
				x = -250,
				y = -225,
				width = 500,
				height = 450,
				cancelShowAnimation = true,
				bToggleShowHide = true,
			}
		)

		return;
	end

	if (mode == self.mode.android) then
		local method = ...;
		GameLogic.IsVip("MakeApk", true, function(result) 
			if(result) then  
				self:MakeAndroidApp(method);
			end
		end)
	
		return;
	end

	self:MakeWindows();
end

function MakeApp:MakeWindows()
	local name = WorldCommon.GetWorldTag("name");
	self.name = name;
	local dirName = commonlib.Encoding.Utf8ToDefault(name);
	self.dirName = dirName;
	local output_folder = ParaIO.GetWritablePath().."release/"..dirName.."/";
	self.output_folder = output_folder;

	_guihelper.MessageBox(format(L"是否将世界%s 发布为独立应用程序?", self.name), function(res)
		if(res and res == _guihelper.DialogResult.Yes) then
			self:MakeApp();
		end
	end, _guihelper.MessageBoxButtons.YesNo);
end

function MakeApp:Run(...)
	if(System.os.GetPlatform()~="win32") then
		_guihelper.MessageBox(L"此功能需要使用Windows操作系统");
		return
	end

	self:RunImp(...);
end

function MakeApp:SignApk(callback)
	GameLogic.GetFilters():apply_filters('cellar.common.msg_box.show', L'正在签名APK，请稍候...', 120000, nil, 350);

	MyCompany.Aries.Game.Tasks.MakeAppThread.MakeApk(
        '(worker_sign_apk)',
        {},
        function(err, msg)
			GameLogic.GetFilters():apply_filters('cellar.common.msg_box.close');

			_guihelper.MessageBox(L'APK已生成(' .. self.androidBuildRoot .. 'paracraft_ver' .. self.curAndroidVersion .. '_pack.apk)');

			ParaIO.DeleteFile('temp/worker_sign_apk_temp.bat');
			ParaIO.DeleteFile('temp/main_temp.bat');

			Map3DSystem.App.Commands.Call("File.WinExplorer", {filepath = self.androidBuildRoot, silentmode = true});

            if callback and type(callback) == 'function' then
                callback();
            end
        end
    )
end

function MakeApp:SignApkThread()
	System.os.run(
		'temp\\build_android_resource\\jre-windows\\bin\\jarsigner  -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore ' ..
		self.androidBuildRoot .. 'personal-key.keystore -storepass paracraft ' ..
		self.androidBuildRoot .. 'paracraft_ver' .. self.curAndroidVersion .. '_pack.apk paracraft');
end

function MakeApp:AndroidDownloadApk(callback)
	local apkUrl = 'https://cdn.keepwork.com/paracraft/android/paracraft.apk?ver=' .. self.curAndroidVersion;

	local fileDownloader = FileDownloader:new();
	fileDownloader.isSilent = true;

	GameLogic.GetFilters():apply_filters('cellar.common.msg_box.show', L'正在获取基础文件，请稍候...', 120000, nil, 350);

	local apkFile = self.androidBuildRoot .. 'paracraft_ver' .. self.curAndroidVersion .. '.apk';
	local zipFile = self.androidBuildRoot .. 'paracraft_ver' .. self.curAndroidVersion .. '.zip';

	commonlib.TimerManager.SetTimeout(function()
		fileDownloader:Init('paracraft.apk', apkUrl, apkFile, function(result)
			if (result) then
				fileDownloader:DeleteCacheFile();
				ParaIO.MoveFile(apkFile, zipFile);

				ParaIO.DeleteFile(self.androidBuildRoot .. 'version.txt');

				local writeFile = ParaIO.open(self.androidBuildRoot .. 'version.txt', 'w');

				if (writeFile:IsValid()) then
					writeFile:write(self.curAndroidVersion, #self.curAndroidVersion);
					writeFile:close();
					MakeApp.localAndroidVersion = self.curAndroidVersion;
				end

				GameLogic.GetFilters():apply_filters('cellar.common.msg_box.close');

				if (callback and type(callback) == 'function') then
					callback();
				end
			end
		end)
	end, 500);
end

function MakeApp:AndroidUpdateManifest(callback)
	GameLogic.GetFilters():apply_filters('cellar.common.msg_box.show', L'正在更新Manifest，请稍候...', 120000, nil, 350);
	local function handle()
		System.os.run(
			'temp\\build_android_resource\\jre-windows\\bin\\java -jar ' ..
			self.androidBuildRoot .. 'xml2axml.jar d ' ..
			self.androidBuildRoot .. 'paracraft_android_ver' .. self.curAndroidVersion .. '/AndroidManifest.xml ' ..
			self.androidBuildRoot .. 'AndroidManifest-decode.xml\n');

		local currentEnterWorld = GameLogic.GetFilters():apply_filters('store_get', 'world/currentEnterWorld');
		local fileRead = ParaIO.open(self.androidBuildRoot .. 'AndroidManifest-decode.xml', 'r');
		local content = '';

		if (fileRead:IsValid()) then
			local line = '';

			while (line) do
				line = fileRead:readline();

				if (line) then
					local mLine = string.match(line, '(.+android:label%=)%"');

					if (mLine) then
						content = content .. mLine .. '"' .. currentEnterWorld.foldername .. '"\n';
					else
						local pLine = string.match(line, '(.+package%=)%"');

						if (pLine) then
							content = content .. pLine .. '"com.tatfook.paracraft.world.c' .. Encoding.crc32(currentEnterWorld.foldername) .. '"\n' ;
						else
							content = content .. line .. '\n';
						end
					end
				end
			end

			fileRead:close();
		end

		local writeFile = ParaIO.open(self.androidBuildRoot .. 'AndroidManifest-decode.xml', 'w');

		if (writeFile:IsValid()) then
			writeFile:write(content, #content);
			writeFile:close();
		end

		System.os.run(
			'temp\\build_android_resource\\jre-windows\\bin\\java -jar ' ..
			self.androidBuildRoot .. 'xml2axml.jar e ' ..
			self.androidBuildRoot .. 'AndroidManifest-decode.xml ' ..
			self.androidBuildRoot .. 'paracraft_android_ver' .. self.curAndroidVersion .. '/AndroidManifest.xml\n');

		ParaIO.DeleteFile(self.androidBuildRoot .. 'AndroidManifest-decode.xml');

		GameLogic.GetFilters():apply_filters('cellar.common.msg_box.close');

		if (callback and type(callback) == 'function') then
			callback();
		end
	end

	if (ParaIO.DoesFileExist(self.androidBuildRoot .. 'xml2axml.jar')) then
		handle();
	else
		local xml2axmlUrl = 'https://cdn.keepwork.com/paracraft/android/xml2axml.jar';

		local fileDownloader = FileDownloader:new();
		fileDownloader.isSilent = true;

		fileDownloader:Init('xml2axml.jar', xml2axmlUrl, self.androidBuildRoot .. 'xml2axml.jar', function(result)
			if (result) then
				handle();
			end
		end)
	end
end

function MakeApp:AndroidUnzipApk(callback)
	GameLogic.GetFilters():apply_filters('cellar.common.msg_box.show', L'正在解压，请稍候...', 120000, nil, 350);

	GameLogic.GetFilters():apply_filters(
		'service.local_service.move_zip_to_folder',
		self.androidBuildRoot .. 'paracraft_android_ver' .. self.curAndroidVersion .. '/',
		self.androidBuildRoot .. 'paracraft_ver' .. self.curAndroidVersion .. '.zip',
		function()
			-- Delete META-INF
			ParaIO.DeleteFile(self.androidBuildRoot .. 'paracraft_android_ver' .. self.curAndroidVersion .. '/META-INF/');

			-- Add bat tools
			local testAssetsWin32BatPath = self.androidBuildRoot .. 'paracraft_android_ver' .. self.curAndroidVersion .. '/assets/test_assets_win32.bat';
			local removeUserDataBatPath = self.androidBuildRoot .. 'paracraft_android_ver' .. self.curAndroidVersion .. '/assets/remove_user_data.bat';

			local testAssetsWin32BatFile = ParaIO.open(testAssetsWin32BatPath, "w");

			if (testAssetsWin32BatFile:IsValid()) then
				local content = '@echo off\n' ..
							    'start %~dp0\\..\\..\\..\\..\\ParaEngineClient.exe single="false" httpdebug="true" debug="main" mc="true" IsTouchDevice="true"';

				testAssetsWin32BatFile:write(content, #content);
				testAssetsWin32BatFile:close();
			end

			local removeUserDataBatFile = ParaIO.open(removeUserDataBatPath, "w");

			if (removeUserDataBatFile:IsValid()) then
				local content = '@echo off\n' ..
								'rd /s /q _emptyworld "temp\tempdatabase" "Screen Shots"\n' ..
								'del log.txt Database\\creator_profile.db Database\\localserver.db Database\\localserver.ver Database\\userdata.db';

				removeUserDataBatFile:write(content, #content);
				removeUserDataBatFile:close();
			end

			GameLogic.GetFilters():apply_filters('cellar.common.msg_box.close');

			if (callback and type(callback) == 'function') then
				callback();
			end
		end
	)
end

function MakeApp:AndroidCopyWorld(compress, beAutoUpdate, loginEnable, callback)
	GameLogic.GetFilters():apply_filters('cellar.common.msg_box.show', L'正在拷贝世界，请稍候...', 120000, nil, 350);
	local currentEnterWorld = GameLogic.GetFilters():apply_filters('store_get', 'world/currentEnterWorld');

	if currentEnterWorld then
		if (compress) then
			-- copy world
			local fileList = GameLogic.GetFilters():apply_filters('service.local_service.load_files', currentEnterWorld.worldpath, true, true);
	
			if not fileList or type(fileList) ~= 'table' or #fileList == 0 then
				return;
			end

			for key, item in ipairs(fileList) do
				if item.filename == "icon.png" then
					local worldIcon = item.file_path;

					ParaIO.CreateDirectory(self.androidBuildRoot .. 'backup/');

					local drawableHdpiV4IconPath = self.androidBuildRoot ..
												   'paracraft_android_ver' .. self.curAndroidVersion ..
												   '/res/drawable-hdpi-v4/ic_launcher.png';
					local drawableXhdpiV4IconPath = self.androidBuildRoot ..
												   'paracraft_android_ver' .. self.curAndroidVersion ..
												   '/res/drawable-xhdpi-v4/ic_launcher.png';
					local drawableXxhdpiV4IconPath = self.androidBuildRoot ..
												   'paracraft_android_ver' .. self.curAndroidVersion ..
												   '/res/drawable-xxhdpi-v4/ic_launcher.png';

					local drawableHdpiV4BackupIconPath = self.androidBuildRoot .. 'backup/drawable_hdpi_v4_icon.png';
					local drawableXhdpiV4BackupIconPath = self.androidBuildRoot .. 'backup/drawable_xhdpi_v4_icon.png';
					local drawableXxhdpiV4BackupIconPath = self.androidBuildRoot .. 'backup/drawable_xxhdpi_v4_icon.png';

					if (not ParaIO.DoesFileExist(drawableHdpiV4BackupIconPath)) then
						ParaIO.CopyFile(drawableHdpiV4IconPath, drawableHdpiV4BackupIconPath, true);
					end

					if (not ParaIO.DoesFileExist(drawableXhdpiV4BackupIconPath)) then
						ParaIO.CopyFile(drawableXhdpiV4IconPath, drawableXhdpiV4BackupIconPath, true);
					end

					if (not ParaIO.DoesFileExist(drawableXxhdpiV4BackupIconPath)) then
						ParaIO.CopyFile(drawableXxhdpiV4IconPath, drawableXxhdpiV4BackupIconPath, true);
					end

					ParaIO.CopyFile(worldIcon, drawableHdpiV4IconPath, true);
					ParaIO.CopyFile(worldIcon, drawableXhdpiV4IconPath, true);
					ParaIO.CopyFile(worldIcon, drawableXxhdpiV4IconPath, true);

					break;
				end
			end
	
			local apkWorldPath = self.androidBuildRoot .. 'paracraft_android_ver' .. self.curAndroidVersion .. '/assets/worlds/DesignHouse/' ..
								 commonlib.Encoding.Utf8ToDefault(currentEnterWorld.foldername) .. '/' ..
								 commonlib.Encoding.Utf8ToDefault(currentEnterWorld.foldername) .. '/';

			ParaIO.CreateDirectory(apkWorldPath);

			for key, item in ipairs(fileList) do
				local relativePath = commonlib.Encoding.Utf8ToDefault(item.filename);
	
				if item.filesize == 0 then
					local folderPath = apkWorldPath .. relativePath .. '/';
	
					ParaIO.CreateDirectory(folderPath);
				else
					local filePath = apkWorldPath .. relativePath;
	
					ParaIO.CopyFile(item.file_path, filePath, true);
				end
			end

			local apkWorldPath1 = self.androidBuildRoot .. 'paracraft_android_ver' .. self.curAndroidVersion .. '/assets/worlds/DesignHouse/' ..
								 commonlib.Encoding.Utf8ToDefault(currentEnterWorld.foldername) .. '/';

			GameLogic.GetFilters():apply_filters(
				'service.local_service.move_folder_to_zip',
				apkWorldPath1,
				self.androidBuildRoot .. 'paracraft_android_ver' .. self.curAndroidVersion .. '/assets/worlds/DesignHouse/' .. commonlib.Encoding.Utf8ToDefault(currentEnterWorld.foldername) .. '.zip',
				function()
					GameLogic.GetFilters():apply_filters('cellar.common.msg_box.close');

					-- update config.txt file
					local writeFile = ParaIO.open(self.androidBuildRoot .. 'paracraft_android_ver' .. self.curAndroidVersion .. '/assets/config.txt', "w");

					if (writeFile:IsValid()) then
						local content = 
							'cmdline=mc="true" debug="main" bootstrapper="script/apps/Aries/main_loop.lua" ' .. 
							'world="' .. 'worlds/DesignHouse/' .. currentEnterWorld.foldername .. '.zip"';

						if (not beAutoUpdate) then
							content = content .. ' noclientupdate="true"';
						end

						if (loginEnable) then
							content = content .. ' login_enable="true"';
						end

						writeFile:write(content, #content);
						writeFile:close();
					end

					ParaIO.DeleteFile(apkWorldPath1);

					if (callback and type(callback) == 'function') then
						callback();
					end
				end
			)
		else
			-- copy world
			local fileList = GameLogic.GetFilters():apply_filters('service.local_service.load_files', currentEnterWorld.worldpath, true, true);
	
			if not fileList or type(fileList) ~= 'table' or #fileList == 0 then
				return;
			end

			for key, item in ipairs(fileList) do
				if item.filename == "icon.png" then
					local worldIcon = item.file_path;

					ParaIO.CreateDirectory(self.androidBuildRoot .. 'backup/');

					local drawableHdpiV4IconPath = self.androidBuildRoot ..
												   'paracraft_android_ver' .. self.curAndroidVersion ..
												   '/res/drawable-hdpi-v4/ic_launcher.png';
					local drawableXhdpiV4IconPath = self.androidBuildRoot ..
												   'paracraft_android_ver' .. self.curAndroidVersion ..
												   '/res/drawable-xhdpi-v4/ic_launcher.png';
					local drawableXxhdpiV4IconPath = self.androidBuildRoot ..
												   'paracraft_android_ver' .. self.curAndroidVersion ..
												   '/res/drawable-xxhdpi-v4/ic_launcher.png';

					local drawableHdpiV4BackupIconPath = self.androidBuildRoot .. 'backup/drawable_hdpi_v4_icon.png';
					local drawableXhdpiV4BackupIconPath = self.androidBuildRoot .. 'backup/drawable_xhdpi_v4_icon.png';
					local drawableXxhdpiV4BackupIconPath = self.androidBuildRoot .. 'backup/drawable_xxhdpi_v4_icon.png';

					if (not ParaIO.DoesFileExist(drawableHdpiV4BackupIconPath)) then
						ParaIO.CopyFile(drawableHdpiV4IconPath, drawableHdpiV4BackupIconPath, true);
					end

					if (not ParaIO.DoesFileExist(drawableXhdpiV4BackupIconPath)) then
						ParaIO.CopyFile(drawableXhdpiV4IconPath, drawableXhdpiV4BackupIconPath, true);
					end

					if (not ParaIO.DoesFileExist(drawableXxhdpiV4BackupIconPath)) then
						ParaIO.CopyFile(drawableXxhdpiV4IconPath, drawableXxhdpiV4BackupIconPath, true);
					end

					ParaIO.CopyFile(worldIcon, drawableHdpiV4IconPath, true);
					ParaIO.CopyFile(worldIcon, drawableXhdpiV4IconPath, true);
					ParaIO.CopyFile(worldIcon, drawableXxhdpiV4IconPath, true);

					break;
				end
			end
	
			local apkWorldPath = self.androidBuildRoot .. 'paracraft_android_ver' .. self.curAndroidVersion .. '/assets/worlds/DesignHouse/' ..
								 commonlib.Encoding.Utf8ToDefault(currentEnterWorld.foldername) .. '/';
	
			ParaIO.CreateDirectory(apkWorldPath);
	
			for key, item in ipairs(fileList) do
				local relativePath = commonlib.Encoding.Utf8ToDefault(item.filename);
	
				if item.filesize == 0 then
					local folderPath = apkWorldPath .. relativePath .. '/';
	
					ParaIO.CreateDirectory(folderPath);
				else
					local filePath = apkWorldPath .. relativePath;
	
					ParaIO.CopyFile(item.file_path, filePath, true);
				end
			end
	
			-- update config.txt file
			local writeFile = ParaIO.open(self.androidBuildRoot .. 'paracraft_android_ver' .. self.curAndroidVersion ..'/assets/config.txt', "w");
	
			if (writeFile:IsValid()) then
				local content = 
					'cmdline=mc="true" debug="main" bootstrapper="script/apps/Aries/main_loop.lua" ' .. 
					'world="' .. 'worlds/DesignHouse/' .. currentEnterWorld.foldername .. '"';

				if (not beAutoUpdate) then
					content = content .. ' noclientupdate="true"';
				end

				if (loginEnable) then
					content = content .. ' login_enable="true"';
				end

				writeFile:write(content, #content);
				writeFile:close();
			end
	
			GameLogic.GetFilters():apply_filters('cellar.common.msg_box.close');
	
			if (callback and type(callback) == 'function') then
				callback();
			end
		end
	end
end

function MakeApp:AndroidGenerateApk(callback)
	GameLogic.GetFilters():apply_filters('cellar.common.msg_box.show', L'正在打包，请稍候...', 120000, nil, 350);

	ParaIO.DeleteFile(self.androidBuildRoot .. 'paracraft_ver' .. self.curAndroidVersion .. '_pack.apk');

	GameLogic.GetFilters():apply_filters(
		'service.local_service.move_folder_to_zip',
		self.androidBuildRoot .. 'paracraft_android_ver' .. self.curAndroidVersion .. '/',
		self.androidBuildRoot .. 'paracraft_ver' .. self.curAndroidVersion .. '_pack.apk',
		function()
			GameLogic.GetFilters():apply_filters('cellar.common.msg_box.close');

			if (callback and type(callback) == 'function') then
				callback();
			end
		end
	);
end

function MakeApp:AndroidDownloadJre(callback)
	if (not ParaIO.DoesFileExist(self.androidBuildRoot .. 'jre-windows/')) then
		local jreTool = 'https://cdn.keepwork.com/paracraft/android/jre-windows.zip';

		local fileDownloader = FileDownloader:new();
		fileDownloader.isSilent = true;

		GameLogic.GetFilters():apply_filters('cellar.common.msg_box.show', L'正在获取Jre Runtime，请稍候...', 120000, nil, 400)
		commonlib.TimerManager.SetTimeout(function()
			fileDownloader:Init('jre-windows.zip', jreTool, self.androidBuildRoot .. 'jre-windows.zip', function(result)
				if (result) then
					fileDownloader:DeleteCacheFile();

					GameLogic.GetFilters():apply_filters('cellar.common.msg_box.close');
					GameLogic.GetFilters():apply_filters('cellar.common.msg_box.show', L'正在解压Jre Runtime，请稍候...', 120000, nil, 400);

					GameLogic.GetFilters():apply_filters(
						'service.local_service.move_zip_to_folder',
						self.androidBuildRoot .. 'jre-windows/',
						self.androidBuildRoot .. 'jre-windows.zip',
						function()
							GameLogic.GetFilters():apply_filters('cellar.common.msg_box.close');

							if callback and type(callback) == 'function' then
								callback();
							end
						end
					)
				end
			end)
		end, 500)
	else
		if callback and type(callback) == 'function' then
			callback()
		end
	end
end

function MakeApp:AndroidSignApk(callback)
	if (not ParaIO.DoesFileExist(self.androidBuildRoot .. 'personal-key.keystore')) then
		local function downloadLicense(downloadCallback)
			local jreTool = 'https://cdn.keepwork.com/paracraft/android/personal-key.keystore';

			local fileDownloader = FileDownloader:new();
			fileDownloader.isSilent = true;

			GameLogic.GetFilters():apply_filters('cellar.common.msg_box.show', L'正在获取Certification，请稍候...', 120000, nil, 400)
			commonlib.TimerManager.SetTimeout(function()
				fileDownloader:Init('personal-key.keystore', jreTool, self.androidBuildRoot .. 'personal-key.keystore', function(result)
					if (result) then
						fileDownloader:DeleteCacheFile();
	
						GameLogic.GetFilters():apply_filters('cellar.common.msg_box.close');

						if downloadCallback and type(downloadCallback) == 'function' then
							downloadCallback();
						end
					end
				end)
			end, 500)
		end

		downloadLicense(function()
			self:SignApk(callback)
		end)
	else
		self:SignApk(callback)
	end
end

function MakeApp:AndroidClean(callback)
	GameLogic.GetFilters():apply_filters('cellar.common.msg_box.show', L'正在清理，请稍候...', 120000, nil, 400);

	commonlib.TimerManager.SetTimeout(function()
		ParaIO.DeleteFile(self.androidBuildRoot);

		GameLogic.GetFilters():apply_filters('cellar.common.msg_box.close');

		if (callback and type(callback) == 'function') then
			callback();
		end
	end, 1000)
end

function MakeApp:AndroidZip()
	ParaIO.CreateDirectory(self.androidBuildRoot);

	if ParaIO.DoesFileExist(self.androidBuildRoot .. 'paracraft_android_ver' .. self.curAndroidVersion .. '/') then
		self:AndroidDownloadJre(function()
			self:AndroidUpdateManifest(function()
				self:AndroidCopyWorld(false, false, false, function()	
					self:AndroidGenerateApk(function()
						self:AndroidSignApk()
					end)
				end)
			end)
		end)
	else
		self:AndroidDownloadApk(function()
			self:AndroidUnzipApk(function()
				self:AndroidDownloadJre(function()
					self:AndroidUpdateManifest(function()
						self:AndroidCopyWorld(false, false, false, function()	
							self:AndroidGenerateApk(function()
								self:AndroidSignApk()
							end)
						end)
					end)
				end)
			end)
		end)
	end
end

function MakeApp:MakeAndroidApp(method)
	if (method == 'zip') then
		self:AndroidZip()
		return
	end

	if (method == 'clean') then
		self:AndroidClean()
		return
	end

	self:AndroidClean(function()
		commonlib.TimerManager.SetTimeout(function()
			self:AndroidZip()
		end, 5000)
	end)	
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