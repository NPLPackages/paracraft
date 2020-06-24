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



function MakeApp:ctor()
end


function MakeApp:RunImp()
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

function MakeApp:Run()
	if(System.os.GetPlatform()~="win32") then
		_guihelper.MessageBox(L"此功能需要使用Windows操作系统");
		return
	end
	GameLogic.IsVip("MakeApp", true, function(result) 
		if(result) then  
			self:RunImp()
		end
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
	if(self:MakeStartupExe() and self:CopyWorldFiles()) then
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
	local zipfile = self:GetZipFile();
	ParaIO.DeleteFile(zipfile)
	local writer = ParaIO.CreateZip(zipfile,"");
	local output_folder = self.output_folder;
	local result = commonlib.Files.Find({}, self.output_folder, 10, 5000, function(item)
		local ext = commonlib.Files.GetFileExtension(item.filename);
		if(ext) then
			return (ext ~= "zip")
		end
	end)
	
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