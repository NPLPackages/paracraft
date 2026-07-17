--[[
Title: Arduino
Author(s): LiXizhi
Date: 2023/12/26
Desc: language configuration file for Arduino C. 
use the lib:
-------------------------------------------------------
local langConfig = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/Arduino/Arduino.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/SerialPort/SerialPortConnector.lua");
local SerialPortConnector = commonlib.gettable("MyCompany.Aries.Game.Code.SerialPortConnector");
local CodeCompiler = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCompiler");
local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
local Arduino = NPL.export();
commonlib.setfield("MyCompany.Aries.Game.Code.Arduino", Arduino);

-- disable auto create movie entity
Arduino.isAutoCreateMovieEntity = false
-- if we are using virtual port only.
Arduino.isVirtualPortOnly = true;
-- since we use arduino-cli to upload, real serial port is never used, we will not show serial connector. 
-- for log monitor use the one provided by arduino-cli. 
Arduino.isShowSerialConnector = false;

local all_cmds = {}
local cmdsMap = {};
local default_categories = {
	{name = "common", text = L"常用", colour="#cccc00", },
	{name = "IO", text = L"接口", colour="#6666ff", },
	{name = "Control", text = L"控制", colour="#d83b01", },
	{name = "Operators", text = L"运算", colour="#569138", },
	{name = "Data", text = L"数据", colour="#459197", },
};

local is_installed = false;
function Arduino.AppendAll()
	if(is_installed)then
		return
	end
	is_installed = true;
	
	local all_source_cmds = {
		NPL.load("./Arduino_Main.lua"),
		NPL.load("./Arduino_IO.lua"),
		NPL.load("./Arduino_Control.lua"),
		NPL.load("./Arduino_Data.lua"),
		NPL.load("./Arduino_Operators.lua"),
	}
	for k,v in ipairs(all_source_cmds) do
		Arduino.AppendDefinitions(v);
	end
end

function Arduino.AppendDefinitions(source)
	if(source)then
		for k,v in ipairs(source) do
			cmdsMap[v.type] = v;
			table.insert(all_cmds,v);
		end
	end
end
-- public:
function Arduino.GetCategoryButtons()
	return default_categories;
end

function Arduino.OnClickLearn()
	ParaGlobal.ShellExecute("open", L"https://keepwork.com/official/docs/tutorials/Arduino", "", "", 1);
end

-- public:
function Arduino.GetAllCmds()
	Arduino.AppendAll();
	return all_cmds;
end

function Arduino.CheckShowSerialConnector()
	if(Arduino.isShowSerialConnector) then
		SerialPortConnector.Show();
	end
end

function Arduino.EditorChangeCodeEntity(entity)
	Arduino.CheckShowSerialConnector()
	
	if(entity) then
		SerialPortConnector.SetCurrentPortByName(entity:GetDisplayName(), Arduino.isVirtualPortOnly)
	end
end

function Arduino.OnOpenCodeEditor(entity)
	Arduino.CheckShowSerialConnector()

	if(entity) then
		SerialPortConnector.SetCurrentPortByName(entity:GetDisplayName(), Arduino.isVirtualPortOnly)
	end
end

-- custom compiler here: 
-- @param codeblock: code block object here
-- @return code_func, errormsg
function Arduino.CompileCode(code, filename, codeblock)
	local name = codeblock:GetEntity():GetDisplayName();

	if(SerialPortConnector.IsConnected() or not Arduino.isShowSerialConnector) then
		local block_name = codeblock:GetBlockName();

		if(not CodeBlockWindow.IsVisible() or not Arduino.isShowSerialConnector) then
			SerialPortConnector.SetCurrentPortByName(codeblock:GetEntity():GetDisplayName(), Arduino.isVirtualPortOnly)
		end

		code = Arduino.GetCode(code, block_name, SerialPortConnector.GetCurrentPortName());
		local compiler = CodeCompiler:new():SetFilename(filename)
		compiler:SetAllowFastMode(true);
		return compiler:Compile(code);
	else
		Arduino.CheckShowSerialConnector()

		-- tricky: if the code block's display name is not empty, we will try and wait for available virtual port
		if(SerialPortConnector.SetCurrentPortByName(name, Arduino.isVirtualPortOnly)) then
			if(SerialPortConnector.IsConnected()) then
				return Arduino.CompileCode(code, filename, codeblock)
			end
		else
			return nil, L"没有找到虚拟串口，请先添加Arduino智能模组"
		end
	end
end

function Arduino:OnReceiveLog(text)
	-- log(text);
	GameLogic.GetCodeGlobal():logAdded(text);
	GameLogic.AppendChat(text);
end

--@param excludeNameMap: map of names to exclude. this can be nil.
function Arduino:GetGlobalVarsDefString(block, excludeNameMap)
	local global_vars = ""
	local variables = block:GetBlockly():GetAllVariables()
	if(variables and #variables > 0) then
		local vars = {}
		for i, var in ipairs(variables) do
			if(not excludeNameMap or not excludeNameMap[var]) then
				var = commonlib.Encoding.toValidParamName(var)
				if(var and var:match("^[_a-zA-Z]")) then
					vars[#vars + 1] = var
				end
			end
		end
		if(#vars > 0) then
			local block_indent = (block:GetIndent() or "").. block:GetBlockly().Const.Indent;
			global_vars = block_indent.."global "..table.concat(vars, ",").."\n";
		end
	end
	return global_vars
end

-- @param code: text of code string
function Arduino.GetCode(code, filename, preferredPortName)
	local text = string.format('NPL.load("(gl)script/apps/Aries/Creator/Game/Code/SerialPort/SerialPortConnector.lua");local SerialPortConnector = commonlib.gettable("MyCompany.Aries.Game.Code.SerialPortConnector");SerialPortConnector.SetRunArduinoMainCode([[%s]], %q, %q)', code, filename, preferredPortName or "")
	return text;
end

function Arduino.GetCustomToolbarMCML()
	Arduino.toolBarMcmlText = Arduino.toolBarMcmlText or string.format([[
<div style="float:left;margin-left:5px;margin-top:7px;">
	<input type="button" value='%s' tooltip='%s' name='openWithArduino' onclick="MyCompany.Aries.Game.Code.Arduino.OpenWithArduino" style="margin-top:0px;background:url(Texture/whitedot.png);background-color:#80cc80;color:#ffffff;height:25px;min-width:20px;" />
	<input type="button" value='%s' name='UploadWithArduinoCli' onclick="MyCompany.Aries.Game.Code.Arduino.UploadWithArduinoCli" style="margin-top:0px;margin-left:5px;background:url(Texture/whitedot.png);background-color:#6666cc;color:#ffffff;height:25px;min-width:20px;" />
	<input type="button" value='%s' name='ConfigWithArduinoCli' onclick="MyCompany.Aries.Game.Code.Arduino.ConfigWithArduinoCli" style="margin-top:0px;margin-left:5px;background:url(Texture/whitedot.png);background-color:#808080;color:#ffffff;height:25px;min-width:20px;" />
</div>
]], L"打开Arduino...", L"用Arduino IDE打开", L"上传", L"配置...");
	return Arduino.toolBarMcmlText;
end

function Arduino.ConfigWithArduinoCli()
	NPL.load("(gl)script/ide/System/os/run.lua");
	if(System.os.GetPlatform()=="win32") then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Code/Arduino/ArduinoConfigPage.lua");
		local ArduinoConfigPage = commonlib.gettable("MyCompany.Aries.Game.Code.ArduinoConfigPage");
		ArduinoConfigPage.Show(true)
	else
		_guihelper.MessageBox(L"请在windows平台上配置Arduino Cli")
	end
end

-- write current code data to to .ino file and return *.ino filename path
function Arduino.SyncProjectFile()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockWindow.lua");
	local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
	local entity = CodeBlockWindow.GetCodeEntity();
	local name = entity and entity:GetDisplayName() or "default";
	local filename = ParaIO.GetWritablePath()..format("temp/arduino/paracraft_%s/paracraft_%s.ino", name, name);
	
	ParaIO.CreateDirectory(filename);
	local file = ParaIO.open(filename, "w");
	if(file:IsValid()) then
		local code = CodeBlockWindow.GetCodeFromEntity()
		file:WriteString(code);
		file:close();
	end
	return filename;
end

function Arduino.OpenWithArduino()
	local filename = Arduino.SyncProjectFile()
	ParaGlobal.ShellExecute("open", filename or "", "", "", 1);
end


function Arduino.ResetMachineWithSerialPort(portname)
	-- just connect and disconnect will reset the device. 
	SerialPortConnector.Connect()
	-- set timeout 
	commonlib.TimerManager.SetTimeout(function()  
		SerialPortConnector.Disconnect()
	end, 1000)
end

function Arduino.UploadWithArduinoCli()
	NPL.load("(gl)script/ide/System/os/run.lua");
	if(System.os.GetPlatform()=="win32") then
		local filename = Arduino.SyncProjectFile()

		NPL.load("(gl)script/apps/Aries/Creator/Game/Code/Arduino/ArduinoConfigPage.lua");
		local ArduinoConfigPage = commonlib.gettable("MyCompany.Aries.Game.Code.ArduinoConfigPage");
		ArduinoConfigPage.FetchValidArduinoCliPath(function(exe_full_path)
			-- use relative path to support non-English install location. 
			Arduino.isUseRelativePath = true;
			if(Arduino.isUseRelativePath) then
				local writablePath = ParaIO.GetWritablePath()
				if(exe_full_path:sub(1, #writablePath) == writablePath) then
					exe_full_path = exe_full_path:sub(#writablePath+1, -1)
					local prePath = ""
					for w in exe_full_path:gmatch("[/\\]") do
						prePath = prePath.."..\\"
					end
					if(filename:sub(1, #writablePath) == writablePath) then
						filename = prePath..filename:sub(#writablePath+1, -1)
					end
				end
			end

			local parentExeDir = string.gsub(exe_full_path, "[^/\\]+$", "");
			if(exe_full_path and filename) then
				SerialPortConnector.DisconnectAll();
				local boardname = ArduinoConfigPage.GetBoardName();
				local port = ArduinoConfigPage.GetPort();
				if(not port or port == "") then
					port = "COM1"
				end
				local library = ArduinoConfigPage.GetLibrary();
				local cmd = string.format([[
@echo off
echo "building with local arduino-cli ..." >con
pushd "%s"
echo "compiling ..." >con
"%s" --config-file .\arduino-cli.yaml compile --library %s --fqbn %s %s > output.txt 2>&1
IF %%ERRORLEVEL%% NEQ 0 (
	echo "compile failed"
    echo "compile failed" >con
	REM timeout /t 5 >nul
) ELSE (
	echo "compile succeed"
    echo "compile succeed" >con

	echo "uploading via %s ..." >con
	"%s" --config-file .\arduino-cli.yaml upload -p %s --fqbn %s %s >> output.txt 2>&1
	IF %%ERRORLEVEL%% NEQ 0 (
		echo "upload failed"
		echo "upload failed" >con
	) ELSE (
		REM timeout /t 2 >nul
		REM echo "upload succeed"
		REM echo "upload succeed" >con
	)
)
popd
]], parentExeDir, ArduinoConfigPage.run_name, library, boardname, filename, port, ArduinoConfigPage.run_name, port, boardname, filename)

				LOG.std(nil, "info", "Arduino", "running arduino-cli cmd:\n%s\n", cmd);

				local function OnResult_(result)
					local filename = parentExeDir.."output.txt";
					local file = ParaIO.open(filename, "r");
					if(file:IsValid()) then
						local text = file:GetText();
						file:close();
						result = text;
					else
						LOG.std(nil, "error", "Arduino", "failed to open output file: %s ", filename);
					end
					if(result) then
						-- remove colored text in console 
						result = string.gsub(result, "\27%[%d+m", "");
						GameLogic.GetCodeGlobal():log(result); 
					end 
				end
				local isAsyncRun = false;
				if(isAsyncRun) then
					System.os.runAsync(cmd, function(err, result)  
						OnResult_(result)
						-- Arduino.ResetMachineWithSerialPort(port)
					end)
				else
					local result = System.os.run(cmd);
					OnResult_(result)
					-- Arduino.ResetMachineWithSerialPort(port)
					-- ArduinoConfigPage.OpenSerialMonitor()
				end
			end
		end)
	else
		_guihelper.MessageBox(L"你的版本只支持虚拟仿真。请下载Windows PC客户端上传硬件。是否现在下载？", function(res)
			if(res and res == _guihelper.DialogResult.Yes) then
				ParaGlobal.ShellExecute("open", "https://paracraft.cn/download", "", "", 1);
			end
		end, _guihelper.MessageBoxButtons.YesNo);
	end
end