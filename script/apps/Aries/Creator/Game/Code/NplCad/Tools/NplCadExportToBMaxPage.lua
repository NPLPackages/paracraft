--[[
Title: NplCadExportToBMaxPage
Author(s): leio
Date: 2019.9.24
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplCad/Tools/NplCadExportToBMaxPage.lua");
local NplCadExportToBMaxPage = commonlib.gettable("MyCompany.Aries.Game.Code.NplCad.Tools.NplCadExportToBMaxPage");
NplCadExportToBMaxPage.ShowPage();
------------------------------------------------------------
]]

local NplCadExportToBMaxPage = commonlib.gettable("MyCompany.Aries.Game.Code.NplCad.Tools.NplCadExportToBMaxPage");

NplCadExportToBMaxPage.size = 16;
NplCadExportToBMaxPage.page = nil;
NplCadExportToBMaxPage.input_filename = nil;
NplCadExportToBMaxPage.output_filename = nil;
NplCadExportToBMaxPage.temp_preview_filename = "temp/nplcad_to_bmax_preview.x"
NplCadExportToBMaxPage.is_waitting = false;

function NplCadExportToBMaxPage.OnInit()
    NplCadExportToBMaxPage.page = document.GetPageCtrl();
end
function NplCadExportToBMaxPage.ShowPage(input_filename,output_filename,callback)
    NplCadExportToBMaxPage.size = 16;
    NplCadExportToBMaxPage.input_filename = input_filename;
    NplCadExportToBMaxPage.output_filename = output_filename;
    NplCadExportToBMaxPage.callback = callback;
    local params = {
		url = "script/apps/Aries/Creator/Game/Code/NplCad/Tools/NplCadExportToBMaxPage.html", 
		name = "NplCadExportToBMaxPage.ShowPage", 
		app_key=MyCompany.Aries.app.app_key, 
		isShowTitleBar = false,
		DestroyOnClose = false, -- prevent many ViewProfile pages staying in memory
		bToggleShowHide = true,
		enable_esc_key = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = true,
		zorder = zorder,
		directPosition = true,
			align = "_ct",
            x = -500/2,
			y = -400/2,
			width = 500,
			height = 420,
			cancelShowAnimation = true,
	}
	System.App.Commands.Call("File.MCMLWindowFrame", params);	
    NplCadExportToBMaxPage.is_waitting = false;
    NplCadExportToBMaxPage.OnChange(NplCadExportToBMaxPage.size);
    
    NplCadExportToBMaxPage.OnPreview()
end
function NplCadExportToBMaxPage.OnChange(value)
        value = math.floor(value);
        NplCadExportToBMaxPage.page:SetValue("label_cnt",value);
        NplCadExportToBMaxPage.size = value;
end
 function NplCadExportToBMaxPage.BuildBMaxFile(callback)
        NPL.load("(gl)Mod/ModelVoxelizer/services/ModelVoxelizerService.lua");
        local ModelVoxelizerService = commonlib.gettable("Mod.ModelVoxelizer.services.ModelVoxelizerService");
        local file = ParaIO.open(NplCadExportToBMaxPage.input_filename, "r");
	    if(file:IsValid()) then
		    local text = file:GetText();
            -- convert "colorstl" to "bmax"
            ModelVoxelizerService.start(text,false, NplCadExportToBMaxPage.size,"colorstl","bmax",function(msg)
                local preview_stl_content = msg.preview_stl_content;
			    local content = msg.content;
                if(not content)then
                    return
                end
                local out_file = ParaIO.open(NplCadExportToBMaxPage.output_filename, "w");
			    if(out_file:IsValid())then
					out_file:WriteString(content);
				    out_file:close();

                    if(callback)then
                        callback();
                    end
			    end
            end)

        end
    end
function NplCadExportToBMaxPage.OnPreview(callback)
    if(NplCadExportToBMaxPage.is_waitting)then
        return
    end
    if(ParaIO.DoesFileExist(NplCadExportToBMaxPage.temp_preview_filename)) then
		ParaIO.DeleteFile(NplCadExportToBMaxPage.temp_preview_filename);
    end
    NplCadExportToBMaxPage.UpdateState(L"正在运行中,请稍等...")
    NplCadExportToBMaxPage.is_waitting = true;
    NplCadExportToBMaxPage.BuildBMaxFile(function()
        NPL.load("(gl)Mod/ParaXExporter/main.lua");
        local ParaXExporter = commonlib.gettable("Mod.ParaXExporter");
        ParaXExporter:ConvertFromBMaxToParaX(NplCadExportToBMaxPage.output_filename, NplCadExportToBMaxPage.temp_preview_filename);
        NplCadExportToBMaxPage.Refresh();
        NplCadExportToBMaxPage.is_waitting = false;
    end)
end
function NplCadExportToBMaxPage.OnExport()
    if(NplCadExportToBMaxPage.is_waitting)then
        return
    end
    NplCadExportToBMaxPage.UpdateState(L"正在运行中,请稍等...")
    NplCadExportToBMaxPage.is_waitting = true;
    NplCadExportToBMaxPage.BuildBMaxFile(function()
        local callback = NplCadExportToBMaxPage.callback;
        if(callback)then
            callback(true)
        end
        NplCadExportToBMaxPage.is_waitting = false;
        NplCadExportToBMaxPage.OnClose();
    end)
        
end
function NplCadExportToBMaxPage.OnClose()
    NplCadExportToBMaxPage.page:CloseWindow(true);
end
function NplCadExportToBMaxPage.UpdateState(s)
    NplCadExportToBMaxPage.page:SetValue("label_state",s);
end
function NplCadExportToBMaxPage.Refresh()
    NplCadExportToBMaxPage.page:Refresh(0);
    NplCadExportToBMaxPage.UpdateState("")
    NplCadExportToBMaxPage.page:SetValue("label_cnt",NplCadExportToBMaxPage.size);
    NplCadExportToBMaxPage.page:SetValue("block_cnt",NplCadExportToBMaxPage.size);
    NplCadExportToBMaxPage.UpdateModel();
end
function NplCadExportToBMaxPage.UpdateModel()
    local filename = NplCadExportToBMaxPage.temp_preview_filename;
    if(filename and ParaIO.DoesFileExist(filename)) then
		ParaAsset.LoadParaX("", filename):UnloadAsset()
        local ctl = NplCadExportToBMaxPage.page:FindControl("model_scene");
		if(ctl) then
			ctl:ShowModel({AssetFile = filename, IsCharacter=true, x=0, y=0, z=0 });
		end
	end
end