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
local CameraBlockly = NPL.export();
commonlib.setfield("MyCompany.Aries.Game.Code.CameraBlocklyDef.CameraBlockly", CameraBlockly);

local is_installed = false;
local all_cmds = {};
local all_cmds_map = {};
CameraBlockly.categories = {
	{name = "Camera", text = "摄影机", colour = "#0078d7", },
	{name = "Motion", text = L"运动", colour="#0078d7", },
	{name = "Control", text = L"控制", colour="#d83b01", },
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
	if(not CameraBlockly.templateCode) then
		CameraBlockly.templateCode = [[
local CameraBlockly = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CameraBlocklyDef/CameraBlockly.lua");
local camera = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CameraBlocklyDef/camera.lua");
local subtitle = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CameraBlocklyDef/subtitle.lua");
camera.init(codeblock);
<code>
]]
		CameraBlockly.templateCode = CameraBlockly.templateCode:gsub("(\r?\n)", ""):gsub("<code>", "%%s")
	end
	local s = string.format(CameraBlockly.templateCode, code or "");
	return s
end

function CameraBlockly.GetCustomToolbarMCML()
	CameraBlockly.toolBarMcmlText = CameraBlockly.toolBarMcmlText or string.format([[
		<div style="float:left;margin-top:8px;margin-left:4px;">
			<pe:sliderbar uiname="EnvFramePage.timeSlider" name="timeSlider" min="0" max="1" value='<%%=MyCompany.Aries.Game.Code.CameraBlocklyDef.CameraBlockly.GetCurrentTime()%%>' style="width:80px;height:22px;" onchange="MyCompany.Aries.Game.Code.CameraBlocklyDef.CameraBlockly.OnTimeChanged()"></pe:sliderbar>
		</div>
		<div style="float:left;margin-top:5px;margin-left:5px;">
			<pe:gridview style="width:135px;height:26px;" name="cameras" CellPadding="0" VerticalScrollBarStep="26" VerticalScrollBarOffsetX="0" AllowPaging="false" ItemsPerLine="4" DefaultNodeHeight="26" DataSource='<%%=MyCompany.Aries.Game.Code.CameraBlocklyDef.CameraBlockly.GetAllCameras()%%>'>
				<Columns>
					<input type="button" style="margin-left:5px;width:26px;height:26px;color:#ffffff;font-size:14px;background:url(Texture/blocks/items/ts_camera.png)" name='<%%=Eval("index")%%>' onclick="MyCompany.Aries.Game.Code.CameraBlocklyDef.CameraBlockly.OnClickCamera"/>
				</Columns>
				<EmptyDataTemplate>
				</EmptyDataTemplate>
			</pe:gridview>
		</div>
		<div style="float:left;margin-left:0px;margin-top:7px;color:#ffffff;font-size:12px;">
			<input type="button" uiname="CodeBlockWindow.record" name="record" value="%s" style="width:64px;height:25px;color:#ffffff;font-size:12px;" onclick="MyCompany.Aries.Game.Code.CameraBlocklyDef.CameraBlockly.RunAndExportVideo" class="mc_light_grey_button_with_fillet" />
		</div>
]], L"导出视频");
	return CameraBlockly.toolBarMcmlText;
end

function CameraBlockly.GetCurrentTime()
	return 0
end

function CameraBlockly.OnTimeChanged(value)
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
	local camera = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CameraBlocklyDef/camera.lua");
	if (CameraBlockly.cameras and CameraBlockly.cameras[index]) then
		camera.showCamera(CameraBlockly.cameras[index].id);
	end
end

function CameraBlockly.RunAndExportVideo()
	local camera = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CameraBlocklyDef/camera.lua");
	CodeBlockWindow.CloseEditorWindow();
	VideoSharing.ToggleRecording(1, function()
		CodeBlockWindow.OnClickCompileAndRun(function()
			VideoSharing.StopRecording();
			camera.reopen();
		end);
	end);
end

