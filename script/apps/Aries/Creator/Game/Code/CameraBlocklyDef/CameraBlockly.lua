--[[
Title: 
Author(s): chenjinxian
Date: 
Desc: 
use the lib:
-------------------------------------------------------
local CameraBlockly = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CameraBlocklyDef/CameraBlockly.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeActor.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockWindow.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/VideoSharing.lua");
local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
local CodeActor = commonlib.gettable("MyCompany.Aries.Game.Code.CodeActor");
local VideoSharing = commonlib.gettable("MyCompany.Aries.Game.Movie.VideoSharing");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local CodeCompiler = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCompiler");
local Camera = NPL.load("./Camera.lua");
local Cameras = NPL.load("./Cameras.lua");
local CameraBlockly = NPL.export();
commonlib.setfield("MyCompany.Aries.Game.Code.CameraBlocklyDef.CameraBlockly", CameraBlockly);

local is_installed = false;
local all_cmds = {};
local all_cmds_map = {};
CameraBlockly.categories = {
	{name = "Camera", text = "摄影机", colour = "#0078d7", },
	--{name = "Motion", text = L"运动", colour="#0078d7", },
	--{name = "Control", text = L"控制", colour="#d83b01", },
	{name = "Subtitle", text = L"字幕", colour="#d83b01", },
};

function CameraBlockly.GetCategoryButtons()
	return CameraBlockly.categories;
end

function CameraBlockly.AppendAll()
	if(is_installed)then
		return
	end
	is_installed = true;

	local all_source_cmds = {
		NPL.load("./CameraBlocklyDef.lua"),
	}
	for k,v in ipairs(all_source_cmds) do
		CameraBlockly.AppendDefinitions(v);
	end
end

function CameraBlockly.AppendDefinitions(source)
	if(source)then
		for k,v in ipairs(source) do
			table.insert(all_cmds,v);
			all_cmds_map[v.type] = v;
		end
	end
end

function CameraBlockly.GetAllCmds()
	CameraBlockly.AppendAll();
	return all_cmds;
end

-- custom compiler here: 
-- @param codeblock: code block object here
function CameraBlockly.CompileCode(code, filename, codeblock)
	code = CameraBlockly.GetCode(code);

	local compiler = CodeCompiler:new():SetFilename(filename)
	if(codeblock and codeblock:GetEntity() and codeblock:GetEntity():IsAllowFastMode()) then
		compiler:SetAllowFastMode(true);
	end
	return compiler:Compile(code);
end

-- @param relativePath: can be nil, in which case filepath will be used. 
function CameraBlockly.GetCode(code)
--	if(not CameraBlockly.templateCode) then
--		CameraBlockly.templateCode = [[
--local Camera = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CameraBlocklyDef/Camera.lua");
--local subtitle = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CameraBlocklyDef/Subtitle.lua");
--Camera.init(codeblock);
--<code>
--]]
--		CameraBlockly.templateCode = CameraBlockly.templateCode:gsub("(\r?\n)", ""):gsub("<code>", "%%s")
--	end
--	local s = string.format(CameraBlockly.templateCode, code or "");
	
	return code
end

function CameraBlockly.OnTimeChanged(value)
	if (value > 0) then
		Cameras.setTimeTarget(value);
		CodeBlockWindow.OnClickCompileAndRun(function()
			Cameras.setTimeTarget(nil);
			Cameras.setCurrentTime(0);
		end);
	end
end

function CameraBlockly.GetAllCameras()
	if (CameraBlockly.cameras == nil) then
		CameraBlockly.cameras = {};
		for i = 1, 4 do
			CameraBlockly.cameras[i] = {name = "摄影机", id = i};
		end
	end
	return CameraBlockly.cameras;
end

function CameraBlockly.OnClickCamera(index)
	if (CameraBlockly.cameras and CameraBlockly.cameras[index]) then
		Camera.showCamera(CameraBlockly.cameras[index].id, CodeBlockWindow.GetCodeEntity());
	end
end

function CameraBlockly.RunAndExportVideo()
	CodeBlockWindow.CloseEditorWindow();
	VideoSharing.ToggleRecording(1, function()
		CodeBlockWindow.OnClickCompileAndRun(function()
			VideoSharing.StopRecording();
			Camera.reopen();
		end);
	end);
end

function CameraBlockly.GetCustomCodeUIUrl()
	return "script/apps/Aries/Creator/Game/Code/CameraBlocklyDef/CodeBlockWindowCamera.html"
end

function CameraBlockly.OnOpenCodeEditor(entity)
	Camera.showWithEditor(entity);
end

function CameraBlockly.OnCloseCodeEditor(entity)
	Camera.close();
end
