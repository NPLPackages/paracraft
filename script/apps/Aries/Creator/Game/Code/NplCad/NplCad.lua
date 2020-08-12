--[[
Title: NplCad
Author(s): leio
Date: 2018/12/12
Desc: NplCad is a blockly program to create shapes with nploce on web browser
use the lib:
-------------------------------------------------------
local NplCad = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplCad/NplCad.lua");
NplCad.MakeBlocklyFiles();
-------------------------------------------------------
]]
local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local CodeCompiler = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCompiler");
local NplCad = NPL.export();
commonlib.setfield("MyCompany.Aries.Game.Code.NplCad.NplCad", NplCad);

local is_installed = false;
local all_cmds = {};
local all_cmds_map = {};
NplCad.categories = {
    {name = "Shapes", text = L"图形", colour = "#764bcc", },
    {name = "ShapeOperators", text = L"修改", colour = "#0078d7", },
    {name = "ObjectName", text = L"名称", colour = "#ff8c1a", custom="VARIABLE", },
    {name = "Control", text = L"控制", colour = "#d83b01", },
    {name = "Math", text = L"运算", colour = "#569138", },
    {name = "Data", text = L"数据", colour = "#459197", },
    {name = "Skeleton", text = L"骨骼", colour = "#3c3c3c", },
    {name = "Animation", text = L"动画", colour = "#717171", },
    
};

-- make files for blockly 
function NplCad.MakeBlocklyFiles()
    local categories = NplCad.GetCategoryButtons();
    local all_cmds = NplCad.GetAllCmds()

    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyHelper.lua");
    local CodeBlocklyHelper = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyHelper");
    CodeBlocklyHelper.SaveFiles("block_configs_nplcad",categories,all_cmds);

    _guihelper.MessageBox("making blockly files finished");
	ParaGlobal.ShellExecute("open", ParaIO.GetCurDirectory(0).."block_configs_nplcad", "", "", 1); 
end
function NplCad.GetCategoryButtons()
    return NplCad.categories;
end
function NplCad.AppendAll()
	if(is_installed)then
		return
	end
	is_installed = true;

    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplCad/NplCadDef/NplCadDef_ShapeOperators.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplCad/NplCadDef/NplCadDef_Shapes.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplCad/NplCadDef/NplCadDef_Control.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplCad/NplCadDef/NplCadDef_Data.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplCad/NplCadDef/NplCadDef_Math.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplCad/NplCadDef/NplCadDef_Skeleton.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplCad/NplCadDef/NplCadDef_Animation.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplCad/NplCadDef/NplCadDef_Export.lua");

    local NplCadDef_ShapeOperators = commonlib.gettable("MyCompany.Aries.Game.Code.NplCad.NplCadDef_ShapeOperators");
    local NplCadDef_Shapes = commonlib.gettable("MyCompany.Aries.Game.Code.NplCad.NplCadDef_Shapes");
    local NplCadDef_Control = commonlib.gettable("MyCompany.Aries.Game.Code.NplCad.NplCadDef_Control");
    local NplCadDef_Data = commonlib.gettable("MyCompany.Aries.Game.Code.NplCad.NplCadDef_Data");
    local NplCadDef_Math = commonlib.gettable("MyCompany.Aries.Game.Code.NplCad.NplCadDef_Math");
    local NplCadDef_Skeleton = commonlib.gettable("MyCompany.Aries.Game.Code.NplCad.NplCadDef_Skeleton");
    local NplCadDef_Animation = commonlib.gettable("MyCompany.Aries.Game.Code.NplCad.NplCadDef_Animation");
    local NplCadDef_Export = commonlib.gettable("MyCompany.Aries.Game.Code.NplCad.NplCadDef_Export");
	

	local all_source_cmds = {
		NplCadDef_ShapeOperators.GetCmds(),
		NplCadDef_Shapes.GetCmds(),
		NplCadDef_Control.GetCmds(),
		NplCadDef_Data.GetCmds(),
		NplCadDef_Math.GetCmds(),
		NplCadDef_Skeleton.GetCmds(),
		NplCadDef_Animation.GetCmds(),
	}
	for k,v in ipairs(all_source_cmds) do
		NplCad.AppendDefinitions(v);
	end
end

function NplCad.OnSelect()
    if(CodeBlockWindow.GetSceneContext and CodeBlockWindow:GetSceneContext())then
        CodeBlockWindow:GetSceneContext():SetShowBones(true);
		CodeBlockWindow:GetSceneContext():ShowGrid(true);
    end
end

function NplCad.OnDeselect()
    if(CodeBlockWindow.GetSceneContext and CodeBlockWindow:GetSceneContext())then
        CodeBlockWindow:GetSceneContext():SetShowBones(false);
		CodeBlockWindow:GetSceneContext():ShowGrid(false);
    end
end

function NplCad.AppendDefinitions(source)
	if(source)then
		for k,v in ipairs(source) do
			table.insert(all_cmds,v);
			all_cmds_map[v.type] = v;
		end
	end
end

function NplCad.GetAllCmds()
	NplCad.AppendAll();
	return all_cmds;
end

-- custom compiler here: 
-- @param codeblock: code block object here
function NplCad.CompileCode(code, filename, codeblock)
    local block_name = codeblock:GetBlockName();
    if(not block_name or block_name == "")then
        block_name = "default"
		GameLogic.AddBBS("error", L"请给CAD方块指定角色名称", 15000, "255 0 0")
	end
	local relativePath = format("blocktemplates/nplcad/%s.x",commonlib.Encoding.Utf8ToDefault(block_name));

	GameLogic.AddBBS("NPLCAD", format(L"CAD模型将保存到%s", relativePath), 5000, "255 0 0")

    local filepath = GameLogic.GetWorldDirectory()..relativePath;
	code = NplCad.GetCode(code, filepath, relativePath);

	NplCad.SetCodeBlockActorAsset(codeblock, relativePath);

	local compiler = CodeCompiler:new():SetFilename(filename)
	if(codeblock and codeblock:GetEntity() and codeblock:GetEntity():IsAllowFastMode()) then
		compiler:SetAllowFastMode(true);
	end
	return compiler:Compile(code);
end

-- set code block's nearby movie block's first actor's model to filepath if it is not. 
function NplCad.SetCodeBlockActorAsset(codeBlock, filepath)
	if(CodeBlockWindow.GetCodeBlock and CodeBlockWindow.GetCodeBlock() == codeBlock and CodeBlockWindow.IsVisible()) then
		local actor;
		local movieEntity = codeBlock:GetMovieEntity();
		if(movieEntity and not movieEntity:GetFirstActorStack()) then
			movieEntity:CreateNPC();
			CodeBlockWindow:GetSceneContext():UpdateCodeBlock();
		end

		local sceneContext = CodeBlockWindow:GetSceneContext();
		if(sceneContext) then
			actor = sceneContext:GetActor()
		end
		actor = actor or codeBlock:GetActor();
		if(actor) then
			local assetfile = actor:GetValue("assetfile", 0);
			if(assetfile ~= filepath) then
				actor:AddKeyFrameByName("assetfile", 0, filepath);
				actor:FrameMovePlaying(0);
			end
		end
	end
end

-- create short cut in code API, so that we can write cube() instead of ShapeBuilder.cube()
function NplCad.InstallMethods(codeAPI, shape)
	
	for func_name, func in pairs(shape) do
		if(type(func_name) == "string" and type(func) == "function") then
			codeAPI[func_name] = function(...)
				return func(...);
			end
		end
	end
end

function NplCad.RefreshFile(filename)
	filename = Files.FindFile(filename);
	if(filename and ParaIO.DoesFileExist(filename)) then
		local function filterFunc(shouldRefresh, fullname)
			if(shouldRefresh and filename:match("[^\\/]+$")==fullname:match("[^\\/]+$")) then
				LOG.std(nil, "debug", "NplCAD", "skip refresh disk file %s", fullname);
				return false
			else
				return shouldRefresh;
			end
		end
		GameLogic.GetFilters():add_filter("shouldRefreshWorldFile", filterFunc);
		ParaAsset.LoadParaX("", filename):UnloadAsset()
		commonlib.TimerManager.SetTimeout(function()  
			GameLogic.GetFilters():remove_filter("shouldRefreshWorldFile", filterFunc);	
		end, 5000)
	end
end

-- @param relativePath: can be nil, in which case filepath will be used. 
function NplCad.GetCode(code, filename, relativePath)
	if(not NplCad.templateCode) then
			NplCad.templateCode = [[
    local SceneHelper = NPL.load("Mod/NplCad2/SceneHelper.lua");
    local ShapeBuilder = NPL.load("Mod/NplCad2/Blocks/ShapeBuilder.lua");
	local isFinished = false;
	SceneHelper.LoadPlugin(co:MakeCallbackFuncAsync(function()
		isFinished = true;
		resume();
    end))
	if(not isFinished) then
		yield();
	end
    ShapeBuilder.create();
    local NplCad = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplCad/NplCad.lua");
    NplCad.InstallMethods(codeblock:GetCodeEnv(), ShapeBuilder);
    <code>
    local result = SceneHelper.saveSceneToParaX(%q,ShapeBuilder.getScene(), ShapeBuilder.liner, ShapeBuilder.angular);
    NplCad.ExportToFile(ShapeBuilder.getScene(),%q, ShapeBuilder.liner, ShapeBuilder.angular);
    if(result)then
	    setActorValue("assetfile", %q);
	    setActorValue("showBones", true);
        NplCad.RefreshFile(%q);
    end
	NplCad.StopCodeBlock(codeblock)
]]
		NplCad.templateCode = NplCad.templateCode:gsub("(\r?\n)", ""):gsub("<code>", "%%s")
	end
    local s = string.format(NplCad.templateCode, code or "", filename, filename, filename, relativePath or filepath, relativePath or filepath);
    return s
end

-- virutal function: show bones in code block context
function NplCad.IsShowBones()
	return true;
end

function NplCad.StopCodeBlock(codeblock)
	commonlib.TimerManager.SetTimeout(function()  
		if(codeblock) then
			codeblock:StopAll();
		end
	end, 30)
end

-- custom toolbar UI's mcml on top of the code block window. return nil for default UI. 
-- return nil or a mcml string. 
function NplCad.GetCustomToolbarMCML()
	NplCad.toolBarMcmlText = NplCad.toolBarMcmlText or string.format([[
        <input type="button" value="%s" style="float:left;margin-left:5px;margin-top:7px;width:50px;height:25px;color:#ffffff;font-size:14px;background:url(Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png#179 89 21 21:8 8 8 8)" onclick="MyCompany.Aries.Game.Code.NplCad.NplCad.OnShowCodeLib"/>
        <div onclick="MyCompany.Aries.Game.Code.NplCad.NplCad.OnClickShowExport" style="float:left;margin-left:5px;margin-top:7px;"
                tooltip='page://script/apps/Aries/Creator/Game/Code/NplCad/NplCadToolMenus.html' use_mouse_offset="false" is_lock_position="true" tooltip_offset_x="-5" tooltip_offset_y="22" show_duration="10" enable_tooltip_hover="true" tooltip_is_interactive="true" show_height="200" show_width="230">
            <div style="background-color:#808080;color:#ffffff;padding:3px;font-size:12px;height:25px;min-width:20px;">%s</div>
        </div>
    
]],
		L"代码库",L"导出");
	return NplCad.toolBarMcmlText;
end
function NplCad.OnShowCodeLib()
    local NplCadLibPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplCadLibPage.lua");
    NplCadLibPage:ToggleVisible();
end
function NplCad.OnClickShowExport()
	if(CodeBlockWindow.IsNPLBrowserVisible()) then
		CodeBlockWindow.SetNplBrowserVisible(false)
	end
end

function NplCad.OnClickExport(type)
	local codeBlock = CodeBlockWindow.GetCodeBlock();
	if(codeBlock) then
		codeBlock:SetModified(true);
		NplCad.export_type = type;
		codeBlock:GetEntity():Restart();
	end
end
function NplCad.ExportToFile(scene,filename, liner, angular)
    local type = NplCad.export_type;
	NplCad.export_type = nil;

    if(not type or not scene or not filename)then
        return
    end
    local SceneHelper = NPL.load("Mod/NplCad2/SceneHelper.lua");

    filename = string.match(filename, [[(.+).(.+)$]]);
    if(type == "stl")then
        filename = filename .. ".stl";
        local swapYZ = true;
        local bBinary = true;
        local bEncodeBase64 = true
        local bIncludeColor = false;
        SceneHelper.saveSceneToStl(filename,scene,false,swapYZ, bBinary, bEncodeBase64, bIncludeColor, liner, angular); -- binary
        NplCad.ShowMessageBox(filename)
    elseif(type == "iges")then
        filename = filename .. ".iges";
        SceneHelper.saveSceneToIGES(filename,scene,false);
        NplCad.ShowMessageBox(filename)
    elseif(type == "step")then
        filename = filename .. ".step";
        SceneHelper.saveSceneToStep(filename,scene,false);
        NplCad.ShowMessageBox(filename)
    elseif(type == "gltf")then
        filename = filename .. ".gltf";
        SceneHelper.saveSceneToGltf(filename,scene,false, liner, angular);
        NplCad.ShowMessageBox(filename)
    elseif(type == "bmax")then
        local input_filename = filename .. ".color.stl";
        local output_filename = filename .. ".bmax";
        local swapYZ = false;
        local bBinary = false;
        local bEncodeBase64 = false
        local bIncludeColor = true;
        SceneHelper.saveSceneToStl(input_filename,scene,false,swapYZ, bBinary, bEncodeBase64, bIncludeColor, liner, angular); -- text 
        NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplCad/Tools/NplCadExportToBMaxPage.lua");
        local NplCadExportToBMaxPage = commonlib.gettable("MyCompany.Aries.Game.Code.NplCad.Tools.NplCadExportToBMaxPage");
        NplCadExportToBMaxPage.ShowPage(input_filename,output_filename,function(result)
            if(result)then
                _guihelper.MessageBox(string.format(L"成功导出:%s, 是否拿在手中?", commonlib.Encoding.DefaultToUtf8(output_filename)), function(res)
				if(res and res == _guihelper.DialogResult.Yes) then
						local info = Files.ResolveFilePath(output_filename)
						if(info and info.relativeToWorldPath) then
							GameLogic.RunCommand(format("/take BlockModel {tooltip=\"%s\"}", commonlib.Encoding.DefaultToUtf8(info.relativeToWorldPath)));
						end
					end
				end, _guihelper.MessageBoxButtons.YesNo);
            end
        end);
	elseif(type == "parax")then
		local output_filename = filename .. ".x";
		_guihelper.MessageBox(string.format(L"成功导出:%s, 是否拿在手中?", commonlib.Encoding.DefaultToUtf8(output_filename)), function(res)
			if(res and res == _guihelper.DialogResult.Yes) then
					local info = Files.ResolveFilePath(output_filename)
					if(info and info.relativeToWorldPath) then
						GameLogic.RunCommand(format("/take BlockModel {tooltip=\"%s\"}", commonlib.Encoding.DefaultToUtf8(info.relativeToWorldPath)));
					end
				end
			end, _guihelper.MessageBoxButtons.YesNo);
    end
end
function NplCad.ShowMessageBox(filename)
    _guihelper.MessageBox(string.format(L"成功导出:%s, 是否打开所在目录", commonlib.Encoding.DefaultToUtf8(filename)), function(res)
		if(res and res == _guihelper.DialogResult.Yes) then
			local info = Files.ResolveFilePath(filename)
			if(info and info.relativeToRootPath) then
				local absPath = ParaIO.GetCurDirectory(0)..info.relativeToRootPath;
				local absPathFolder = absPath:gsub("[^/\\]+$", "")
				ParaGlobal.ShellExecute("open", absPathFolder, "", "", 1);
			end
		end
	end, _guihelper.MessageBoxButtons.YesNo);
end
-- open block xml code from disk
function NplCad.OnClickOpenFile()

    NPL.load("(gl)script/ide/OpenFileDialog.lua");
    local filename = CommonCtrl.OpenFileDialog.ShowDialog_Win32({{"All Files (*.xml)", "*.xml"}});
    if(filename) then
	    local file = ParaIO.open(filename, "r");
        if(file:IsValid()) then
			local blockly_xmlcode = file:GetText();
            local codeEntity = CodeBlockWindow.GetCodeEntity();
            if(codeEntity)then
                codeEntity:BeginEdit()
		        codeEntity:SetBlocklyEditMode(true);
		        codeEntity:SetBlocklyXMLCode(blockly_xmlcode);
		        codeEntity:EndEdit()

                CodeBlockWindow.OnClickEditMode("blockMode",true);
            end
	        file:close();
        else
	        LOG.std(nil, "error", "NplCad", "open file failed:%s",filename);
		end
    end
end
-- save blockly xml code to disk
function NplCad.OnClickSaveFile()
    NPL.load("(gl)script/ide/OpenFileDialog.lua");
    local filename = CommonCtrl.OpenFileDialog.ShowDialog_Win32({{"All Files (*.xml)", "*.xml"}},nil,nil,true);
    if(filename) then

        local __,postfix = string.match(filename,"(.+)%.(.+)$");
        if(not postfix or ( postfix and string.lower(postfix) ~= "xml" ))then
            filename = filename .. ".xml";
        end
	    local file = ParaIO.open(filename, "w");
        if(file:IsValid()) then
			local codeEntity = CodeBlockWindow.GetCodeEntity();
            if(codeEntity)then
                local block_xml_txt = codeEntity:GetBlocklyXMLCode();
	            file:WriteString(block_xml_txt);
            end
	        file:close();
        else
	        LOG.std(nil, "error", "NplCad", "save file failed:%s",filename);
		end
    end
end

function NplCad.OnClickLearn()
	ParaGlobal.ShellExecute("open", L"https://keepwork.com/official/docs/CAD/intro", "", "", 1);
end

function NplCad.GetCustomCodeUIUrl()
	return "script/apps/Aries/Creator/Game/Code/NplCad/CodeBlockWindowCAD.html"
end