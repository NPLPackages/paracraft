--[[
Title: ArduinoConfigPage
Author(s): LiXizhi
Date: 2024/1/3
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/Arduino/ArduinoConfigPage.lua");
local ArduinoConfigPage = commonlib.gettable("MyCompany.Aries.Game.Code.ArduinoConfigPage");
ArduinoConfigPage.Show(true)
ArduinoConfigPage.FetchValidArduinoCliPath(function(exe_full_path)
	GameLogic.AddBBS(nil, exe_full_path, 3000, "0 255 0");
end)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/API/FileDownloader.lua");
NPL.load("(gl)script/ide/System/os/Serial.lua");
NPL.load("(gl)script/ide/System/Util/ZipFile.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/SerialPort/SerialPortConnector.lua");
local SerialPortConnector = commonlib.gettable("MyCompany.Aries.Game.Code.SerialPortConnector");
local Serial = commonlib.gettable("System.os.Serial");
local FileDownloader = commonlib.gettable("MyCompany.Aries.Creator.Game.API.FileDownloader");
local ZipFile = commonlib.gettable("System.Util.ZipFile");
local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
local ArduinoConfigPage = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Code.ArduinoConfigPage"));

local page;

ArduinoConfigPage.config = {
	boardname = "arduino:avr:uno",
	port = "",
	library = "Weeemake", -- comma separated library names
}
ArduinoConfigPage.root  = "arduino-cli/"
ArduinoConfigPage.run_name  = "arduino-cli.exe";
ArduinoConfigPage.source_url = "https://cdn.keepwork.com/paracraft/arduino/arduino_local.zip?v=1";
ArduinoConfigPage.version = "v1.0"
ArduinoConfigPage.cache_policy = "access plus 1 month";
ArduinoConfigPage.maxFilesCnt = 100000;


function ArduinoConfigPage.Show()
	local width, height = 400, 300;
	local pageUrl = "script/apps/Aries/Creator/Game/Code/Arduino/ArduinoConfigPage.html"
	local params = {
			url = pageUrl, 
			name = "ArduinoConfigPage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			click_through = false, 
			enable_esc_key = true,
			bShow = true,
			isTopLevel = true,
			zorder = 200,
			---app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -width/2,
				y = -height/2,
				width = width,
				height = height,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function ArduinoConfigPage.OnInit()
	page = document:GetPageCtrl();
	ArduinoConfigPage.UpdatePortList();
	local entity = CodeBlockWindow.GetCodeEntity()
	if(entity) then
		page:SetValue("boardname", ArduinoConfigPage.config.boardname);
		if(ArduinoConfigPage.config.port ~= "") then
			page:SetValue("port", ArduinoConfigPage.config.port);
		end
		page:SetValue("library", ArduinoConfigPage.config.library);
	end
end

function ArduinoConfigPage.SetState(txt, duration)
	GameLogic.AddBBS("ArduinoConfigPage", txt, duration or 5000, "0 255 0");
end

local portNamesDS = {}

function ArduinoConfigPage.GetPortNameDS()
    return portNamesDS;
end

function ArduinoConfigPage.OnSelectPort(name, value)
	if(value == "installDriver") then
        ParaGlobal.ShellExecute("open", SerialPortConnector.driverUrl, "", "", 1);
        if(page) then
            page:SetValue(name, "");
        end
        return;
    end
end

function ArduinoConfigPage.onBeforeClickDropDownButton()
	ArduinoConfigPage.UpdatePortList()
end

function ArduinoConfigPage.UpdatePortList()
	portNamesDS = {}
    local portNames = Serial:GetPortNames()
	local hasPortName;
    for i, name in ipairs(portNames) do
		if(name == ArduinoConfigPage.config.port) then
			hasPortName = true
		end
        portNamesDS[#portNamesDS+1] = {value=name};
    end
	if(not hasPortName and #portNames > 0) then
		-- default to the last one
		ArduinoConfigPage.config.port = portNames[#portNames];
	end
	portNamesDS[#portNamesDS+1] = {{value="", text=L"自动"}}; -- {{value="COM1"}, {value="COM2"}};
    local selectedPortName = ArduinoConfigPage.config.port;
	for _, option in ipairs(portNamesDS) do
		option.selected = selectedPortName == option.value;
	end
	if(System.os.GetPlatform() == "win32") then
        portNamesDS[#portNamesDS+1] = {value="installDriver", text=L"安装驱动"};
    end
end

-- return globally unique name
function ArduinoConfigPage.GetBoardName()
	return ArduinoConfigPage.config.boardname;
end

-- @return "COM1", etc. without additional names
function ArduinoConfigPage.GetPort()
	local portNames = Serial:GetPortNames()
	local hasPortName;
    for i, name in ipairs(portNames) do
		if(name == ArduinoConfigPage.config.port) then
			hasPortName = true
			break;
		end
    end
	local port = ""
	if(hasPortName) then
		port = ArduinoConfigPage.config.port;
	elseif(#portNames > 0) then
		port = portNames[#portNames]; -- use the last one by default. 
	end
	if(port) then
		port = port:gsub("^(COM%d+):.*", "%1");
	end
	return port;
end

function ArduinoConfigPage.GetLibrary()
	return ArduinoConfigPage.config.library;
end

function ArduinoConfigPage.OpenSerialMonitor()
	SerialPortConnector.DisconnectAll();
	commonlib.TimerManager.SetTimeout(function()  
		ArduinoConfigPage.FetchValidArduinoCliPath(function(exe_full_path)
			-- arduino-cli monitor -p COM5 -c baudrate=115200
			local cmd = string.format("monitor -p %s -c baudrate=115200", ArduinoConfigPage.GetPort());
			ParaGlobal.ShellExecute("open", exe_full_path, cmd, "", 1);
		end);
	end, 100)
end

function ArduinoConfigPage.OpenArduinoCliFolder()
	ArduinoConfigPage.FetchValidArduinoCliPath(function(exe_full_path)
		_guihelper.MessageBox(string.format(L"已安装到:%s, 是否打开安装目录？", exe_full_path), function(res)
			if(res and res == _guihelper.DialogResult.Yes) then
				-- open containing directory of exe_full_path
				local dir = exe_full_path:gsub("[^/\\]+$", "");
				ParaGlobal.ShellExecute("open", dir, "", "", 1);
			end
		end, _guihelper.MessageBoxButtons.YesNo);
	end)
end

function ArduinoConfigPage.InstallArduinoCliFolder()
	ArduinoConfigPage.OpenArduinoCliFolder();
end

-- return example: "arduino-cli/versions/arduino_local_v1.0.zip"
function ArduinoConfigPage.GetCurVersionZipName()
	local localFile = string.format("%s%sversions/arduino_local_%s.zip", ParaIO.GetWritablePath(), ArduinoConfigPage.root, ArduinoConfigPage.version);
	return localFile;
end
-- return example: "arduino-cli/versions/arduino_local_v1.0"
function ArduinoConfigPage.GetCurVersionRoot()
	local filepath = string.format("%s%sversions/arduino_local_%s", ParaIO.GetWritablePath(), ArduinoConfigPage.root, ArduinoConfigPage.version);
	return filepath;
end

function ArduinoConfigPage.OnStartDownload(callbackFunc)
	if(ArduinoConfigPage.is_loading)then
		return 
	end
	ArduinoConfigPage.is_loading = true;
	local localFile = ArduinoConfigPage.GetCurVersionZipName();
	if(ParaIO.DoesFileExist(localFile))then
	    LOG.std(nil, "info", "ArduinoConfigPage", "current version : %s", localFile);
		local destFileName = commonlib.Files.splitText(localFile);
		ArduinoConfigPage.SetState(L"正在安装，请稍等");
		commonlib.TimerManager.SetTimeout(function()  
			ArduinoConfigPage.Decompress(localFile,destFileName);
			ArduinoConfigPage.SetState(L"安装成功");
			ArduinoConfigPage.is_loading = false;
			ArduinoConfigPage.FetchValidArduinoCliPath(callbackFunc, false)
		end, 1000)
		return
	end
	ArduinoConfigPage.SetState(string.format(L"开始下载", ArduinoConfigPage.version));
	ArduinoConfigPage.loader = ArduinoConfigPage.loader or FileDownloader:new();
	ArduinoConfigPage.loader:SetSilent();

	ArduinoConfigPage.loader:Init(nil, ArduinoConfigPage.source_url, localFile, function(b, msg)
		ArduinoConfigPage.OnStopDownload();
		ArduinoConfigPage.loader:Flush();
		ArduinoConfigPage.SetState(L"下载完成");
		if(b)then
			local destFileName = commonlib.Files.splitText(localFile);
			ArduinoConfigPage.SetState(L"正在安装，请稍等");
			commonlib.TimerManager.SetTimeout(function()  
				ArduinoConfigPage.Decompress(localFile,destFileName);
				ArduinoConfigPage.SetState(L"安装成功");
				ArduinoConfigPage.FetchValidArduinoCliPath(callbackFunc, false)
			end, 1000)
		else
			ArduinoConfigPage.SetState(L"下载失败");
		end
	end, ArduinoConfigPage.cache_policy);

	ArduinoConfigPage.timer = ArduinoConfigPage.timer or commonlib.Timer:new({callbackFunc = function(timer)
		local cur_size = ArduinoConfigPage.loader:GetCurrentFileSize() or 0;
		local total_size = ArduinoConfigPage.loader:GetTotalFileSize() or 0;
		local percent = 100;
		if(cur_size > 0 and total_size > 0)then
			percent = math.floor(10000 * (cur_size / total_size)) / 100;
		end
		if(percent == 100) then
			timer:Change();
		end
		ArduinoConfigPage.SetState(string.format(L"下载进度:%.2f%%", percent));
	end})

	ArduinoConfigPage.timer:Change(0, 1000);
end
function ArduinoConfigPage.OnStopDownload()
	if(ArduinoConfigPage.timer)then
		ArduinoConfigPage.timer:Change()
	end
	ArduinoConfigPage.is_loading = false;
end
function ArduinoConfigPage.Decompress(sourceFileName,destFileName)
	ArduinoConfigPage.OnStopDownload();
    if(not sourceFileName or not destFileName)then return end
	if(ParaIO.DoesFileExist(sourceFileName))then
        local zipFile = ZipFile:new();
        if(zipFile:open(sourceFileName)) then
			LOG.std(nil, "info", "ArduinoConfigPage", "Decompress: %s -> %s", sourceFileName, destFileName);
	        zipFile:unzip(destFileName .. "/", ArduinoConfigPage.maxFilesCnt);
	        zipFile:close();
		else
			LOG.std(nil, "error", "ArduinoConfigPage", "Open failed: %s", sourceFileName);
			ParaIO.DeleteFile(sourceFileName);
        end
	else
		LOG.std(nil, "error", "ArduinoConfigPage", "the file isn't existed: %s", sourceFileName);
    end
end
function ArduinoConfigPage.OnSearchRunExeName()
	local localFile = ArduinoConfigPage.GetCurVersionZipName();
	local root = commonlib.Files.splitText(localFile);
	LOG.std(nil, "debug", "ArduinoConfigPage", "search from : %s", root);
    local run_path;
    local result = commonlib.Files.Find({}, root, 2, ArduinoConfigPage.maxFilesCnt, "*.exe") or {}
    for k,item in ipairs(result) do
        local ext = commonlib.Files.GetFileExtension(item.filename);
        if(ext)then
            ext = string.lower(ext)
            if(ext == "exe")then
                local dir,name = commonlib.Files.splitPath(item.filename)
                if(string.lower(name) == ArduinoConfigPage.run_name)then
                    run_path = dir
                end
            end
        end
    end
    return run_path
end

function ArduinoConfigPage.OnClickOK()
	if(page) then
		ArduinoConfigPage.config.boardname = page:GetValue("boardname");
		ArduinoConfigPage.config.port = page:GetValue("port");
		ArduinoConfigPage.config.library = page:GetValue("library");
		page:CloseWindow()
		page = nil;
	end
end

-- @param isAutoInstall: false to disable, otherwise it will auto install if not found.
function ArduinoConfigPage.FetchValidArduinoCliPath(callbackFunc, isAutoInstall)
	ArduinoConfigPage.callbackFunc = callbackFunc;
	if(ArduinoConfigPage.is_loading)then
		return
	end
	if(ArduinoConfigPage.exe_full_path)then
        if(not ParaIO.DoesFileExist(ArduinoConfigPage.exe_full_path))then
            ArduinoConfigPage.exe_full_path = nil
        else
			if(ArduinoConfigPage.callbackFunc) then
				ArduinoConfigPage.callbackFunc(ArduinoConfigPage.exe_full_path)
			end
            return 
		end
    end
    local run_path = ArduinoConfigPage.OnSearchRunExeName();
    local filepath = string.format("%s/%s%s", ArduinoConfigPage.GetCurVersionRoot(), run_path or "", ArduinoConfigPage.run_name);
	LOG.std(nil, "info", "ArduinoConfigPage", "run: %s", filepath);
    if(not ParaIO.DoesFileExist(filepath))then
		LOG.std(nil, "info", "ArduinoConfigPage", "file not installed: %s", filepath);
		if(isAutoInstall~=false) then
			ArduinoConfigPage.OnStartDownload(callbackFunc);
		end
        return 
	end
    ArduinoConfigPage.exe_full_path = filepath;
    if(ArduinoConfigPage.callbackFunc) then
		ArduinoConfigPage.callbackFunc(ArduinoConfigPage.exe_full_path)
	end
end
