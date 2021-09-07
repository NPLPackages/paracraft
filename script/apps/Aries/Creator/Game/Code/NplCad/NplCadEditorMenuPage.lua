--[[
Title: NplCadEditorMenuPage
Author(s): leio
Date: 2021/8/16
Desc: show nplcad3 menus when click EntityNplCadEditor block
use the lib:
-------------------------------------------------------
local NplCadEditorMenuPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplCad/NplCadEditorMenuPage.lua");
NplCadEditorMenuPage.ShowPage(entity);
-------------------------------------------------------
]]
local NplExtensionsUpdater = NPL.load("(gl)script/apps/Aries/Creator/Game/NplExtensionsUpdater/NplExtensionsUpdater.lua");
NPL.load("(gl)script/ide/Encoding.lua");

NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
NPL.load("(gl)script/ide/System/Encoding/base64.lua");
local Encoding = commonlib.gettable("System.Encoding");

local NplCadEditorMenuPage = NPL.export();
local page;
NplCadEditorMenuPage.entity = nil;
NplCadEditorMenuPage.dep_packages = {
	{ mod = "npl_extensions/npl_packages/NplCadEditor.zip", path = "npl_extensions/npl_packages/NplCadEditor/"}
}
function NplCadEditorMenuPage.OnInit()
	page = document:GetPageCtrl();
end
function NplCadEditorMenuPage.ShowPage(entity)
	NplCadEditorMenuPage.entity = entity;
	local params = {
			url = "script/apps/Aries/Creator/Game/Code/NplCad/NplCadEditorMenuPage.html", 
			name = "NplCadEditorMenuPage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			bShow = true,
			click_through = false, 
			zorder = -1,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_lt",
				x = 0,
				y = 0,
				width = 265,
				height = 420,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	local pageCtrl = params._page;
    
    if(pageCtrl)then
        pageCtrl.OnClose = function()
			NplCadEditorMenuPage.entity = nil;
        end
    end
	NplCadEditorMenuPage.Refresh();

	NplExtensionsUpdater.Check(function(v)
		if(v)then
			for k, item in ipairs(NplCadEditorMenuPage.dep_packages) do
				local mod = item.mod;
				local path = item.path;
				if(ParaIO.DoesFileExist(mod))then
					LOG.std(nil, "info", "NplCadEditorMenuPage", "load npl package: %s", mod);
					NPL.load(mod)
					ParaIO.AddSearchPath(path);
				else
					LOG.std(nil, "error", "NplCadEditorMenuPage", "load npl package faild: %s", mod);
				end
			end
		end
	end);

	if(GameLogic and GameLogic.GetFilters and GameLogic.GetFilters())then
		--GameLogic.GetFilters():add_filter("nplcad3_save", NplCadEditorMenuPage.OnNplCadSave);
		--GameLogic.GetFilters():add_filter("nplcad3_save_preview", NplCadEditorMenuPage.OnNplCadSavePreview);
		--GameLogic.GetFilters():add_filter("nplcad3_runcode", NplCadEditorMenuPage.OnNplCadRunCode);
	end
end
function NplCadEditorMenuPage.IsVisible()
	if(page and page:IsVisible())then
		return true;
	end
end
function NplCadEditorMenuPage.Refresh(DelayTime)
	if(DelayTime == nil)then
		DelayTime = 0;
	end
	if(page)then
		page:Refresh(DelayTime);
	end
end
function NplCadEditorMenuPage.GetBlockPos()
    if(NplCadEditorMenuPage.entity)then
        return NplCadEditorMenuPage.entity:GetBlockPos();
    end
end
function NplCadEditorMenuPage.GetName()
    local bx, by, bz = NplCadEditorMenuPage.GetBlockPos();
    local name = string.format("%d,%d,%d", bx or 0, by or 0, bz or 0)
    return name
end

function NplCadEditorMenuPage.OnNplCadSave(name, bx, by, bz, codeEntity)
	
end

function NplCadEditorMenuPage.OnNplCadSavePreview(name, bx, by, bz, content)
	local blockpos = string.format("%d,%d,%d", bx, by, bz);
	local filepath = NplCadEditorMenuPage.GetModelPreviewPath(blockpos);
	content = Encoding.unbase64(content);
	NplCadEditorMenuPage.SaveFile(filepath, content)
	NplCadEditorMenuPage.Refresh(1);
end

function NplCadEditorMenuPage.OnNplCadRunCode(input, output)
	input = input or {};
	output = output or {};
	local build_type = input.build_type;
	local blockpos = input.blockpos;

	if(not NplCadEditorMenuPage.entity or not NplCadEditorMenuPage.IsVisible())then
		return
	end
	if(build_type == "parax" and output.ok and output.result)then
		if(blockpos)then
            local bx, by, bz = NplCadEditorMenuPage.entity:GetBlockPos();
			if(bz)then
				local pos = string.format("%d,%d,%d", bx, by, bz);
				if(pos ~= blockpos)then
					return
				end

				local content = output.result;
				--input.blockpos format is like "19200,5,19200"
				local model_path = NplCadEditorMenuPage.GetModelPath(input.blockpos);
				content = Encoding.unbase64(content);
				NplCadEditorMenuPage.SaveFile(model_path, content)
				NplCadEditorMenuPage.Refresh();
			end
		end
		
	end

end
function NplCadEditorMenuPage.GetJsonPath(blockpos)
	blockpos = blockpos or "default"
	local model_path = string.format("%sblocktemplates/nplcad3/editor_%s/editor.json", GameLogic.GetWorldDirectory(), blockpos, blockpos);
	return model_path;
end
-- this is stage model
function NplCadEditorMenuPage.GetModelPath(blockpos)
	blockpos = blockpos or "default"
	local model_path = string.format("%sblocktemplates/nplcad3/editor_%s/%s.x", GameLogic.GetWorldDirectory(), blockpos, "stage");
	return model_path;
end
function NplCadEditorMenuPage.GetModelPreviewPath(blockpos)
	blockpos = blockpos or "default"
	local model_path = string.format("%sblocktemplates/nplcad3/editor_%s/preview.png", GameLogic.GetWorldDirectory(), blockpos);
	return model_path;
end
function NplCadEditorMenuPage.SaveFile(filepath, content)
	local SceneHelper = NPL.load("Mod/NplCad2/SceneHelper.lua");
	SceneHelper.saveFile(filepath, content);
end

function NplCadEditorMenuPage.OutputParax(entity)
	if(not entity)then
		return
	end
	local data = entity:GetIDEContent();
	if(not data)then
		return
	end
	local editorBean = {};
	if(NPL.FromJson(data, editorBean)) then
        local bx, by, bz = entity:GetBlockPos();
		local blockpos = string.format("%d,%d,%d", bx, by, bz);

		local asset = editorBean.asset;
		if(asset)then
			for k,asset_item in ipairs(asset) do
				local id = asset_item.id;
				local type = asset_item.type;
				local isBase64 = asset_item.isBase64;
				local isBinary = asset_item.isBinary;
				local isStage = asset_item.isStage;
				local content = asset_item.content;
				if(type == "parax")then
					local model_path;
					if(isStage)then
						-- this is stage model
						model_path = string.format("%sblocktemplates/nplcad3/editor_%s/%s.x", GameLogic.GetWorldDirectory(), blockpos, "stage");
					else
						local name = asset_item.name or id;
						name = commonlib.Encoding.Utf8ToDefault(name);
						model_path = string.format("%sblocktemplates/nplcad3/editor_%s/%s.x", GameLogic.GetWorldDirectory(), blockpos, name);
					end
					if(isBase64)then
						content = Encoding.unbase64(content);
					end
					NplCadEditorMenuPage.SaveFile(model_path, content)
				elseif(type == "png")then
					if(isStage)then
						local preview_path = string.format("%sblocktemplates/nplcad3/editor_%s/preview.png", GameLogic.GetWorldDirectory(), blockpos);
						if(isBase64)then
							content = Encoding.unbase64(content);
						end
						NplCadEditorMenuPage.SaveFile(preview_path, content)
					end
				end
			end
			NplCadEditorMenuPage.Refresh();
		end
	end
end