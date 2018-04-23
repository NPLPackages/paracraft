--[[
Title: this file will be loaded when a kidsmovie script sandbox environment is setup
Author(s): LiXizhi
Date: 2007/8/16
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/sandbox.lua");
local sandbox = ParaSandBox:GetSandBox("script/kids/pw_sandbox_file.lua");
sandbox:Reset();
ParaSandBox.ApplyToWorld(sandbox);
------------------------------------------------------------
]]
-- Note: localization are not included.
NPL.load("(gl)script/lang/lang.lua");
NPL.load("(gl)script/ide/common_control.lua");
NPL.load("(gl)script/ide/AI.lua");
NPL.load("(gl)script/ide/headon_speech.lua");
NPL.load("(gl)script/ide/commonlib.lua");
NPL.load("(gl)script/ide/ParaEngineExtension.lua");
NPL.load("(gl)script/ide/gui_helper.lua");
--NPL.load("(gl)script/kids/3DMapSystem_Data.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/API/ParaworldAPI.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/mcml.lua");

if(not ParaSandBox) then ParaSandBox={}; end
function ParaSandBox.SandboxFunction()
	log("warning: the function you are calling is not in the sandbox.\n");
end

-- disable NPL functions
NPL.activate = ParaSandBox.SandboxFunction;
NPL.call = ParaSandBox.SandboxFunction;
NPL.Download = ParaSandBox.SandboxFunction;
NPL.AsyncDownload = ParaSandBox.SandboxFunction;
NPL.RegisterWSCallBack = ParaSandBox.SandboxFunction;
NPL.UnregisterWSCallBack = ParaSandBox.SandboxFunction;
--NPL.DoString = ParaSandBox.SandboxFunction;
--NPL.load = ParaSandBox.SandboxFunction;
NPL.DoFile = ParaSandBox.SandboxFunction;
NPL.ActivateNeuronFile = ParaSandBox.SandboxFunction;
NPL.CreateNeuronFile = ParaSandBox.SandboxFunction;
NPL.DeleteNeuronFile = ParaSandBox.SandboxFunction;
NPL.DoNeuronSCode = ParaSandBox.SandboxFunction;
NPL.EnableNetwork = ParaSandBox.SandboxFunction;
NPL.SetDefaultChannel = ParaSandBox.SandboxFunction;
NPL.ResetChannelProperties = ParaSandBox.SandboxFunction;
NPL.CancelDownload = ParaSandBox.SandboxFunction;
NPL.SetTimer = ParaSandBox.SandboxFunction;
NPL.KillTimer = ParaSandBox.SandboxFunction;


-- disable ParaEngine functions
ParaIO = {};

ParaScene.Execute = ParaSandBox.SandboxFunction;

ParaWorld.NewWorld = ParaSandBox.SandboxFunction;
ParaWorld.DeleteWorld = ParaSandBox.SandboxFunction;
ParaWorld.NewEmptyWorld = ParaSandBox.SandboxFunction;
ParaWorld.SetAttributeProvider = ParaSandBox.SandboxFunction;
ParaWorld.SetWorldDB = ParaSandBox.SandboxFunction;
ParaWorld.SetNpcDB = ParaSandBox.SandboxFunction;
ParaWorld.SetServerState = ParaSandBox.SandboxFunction;
ParaWorld.GetScriptSandBox = ParaSandBox.SandboxFunction;
ParaWorld.SetScriptSandBox = ParaSandBox.SandboxFunction;

ParaNetwork = {};

ParaGlobal.WriteToConsole = ParaSandBox.SandboxFunction;
--ParaGlobal.WriteToLogFile = ParaSandBox.SandboxFunction;
ParaGlobal.SetGameStatus = ParaSandBox.SandboxFunction;
ParaGlobal.SetGameLoop = ParaSandBox.SandboxFunction;
--log = ParaSandBox.SandboxFunction;
ParaGlobal.SetGameLoop = ParaSandBox.SandboxFunction;
ParaGlobal.CreateProcess = ParaSandBox.SandboxFunction;
ParaGlobal.ShellExecute = ParaSandBox.SandboxFunction;

ParaBootStrapper = {};

ParaEngine.Sleep = ParaSandBox.SandboxFunction;
ParaEngine.SaveParaXMesh = ParaSandBox.SandboxFunction;
ParaEngine.GetProductKey = ParaSandBox.SandboxFunction;
ParaEngine.ActivateProduct = ParaSandBox.SandboxFunction;
ParaEngine.WriteConfigFile = ParaSandBox.SandboxFunction;
ParaEngine.SetAppCommandLine = ParaSandBox.SandboxFunction;


ParaTerrain.SaveTerrain = ParaSandBox.SandboxFunction;

ParaAsset.OpenArchive = ParaSandBox.SandboxFunction;
ParaAsset.CloseArchive = ParaSandBox.SandboxFunction;

luaopen_sqlite3 = nil;
luaopen_luaxml = nil;

-- disable base functions. TODO: how about getenv?
package = nil;
require = nil;
dofile = nil;
io = {};
