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
NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserLoaderPage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NPLWebServer.lua");

NPL.load("(gl)script/ide/math/Matrix4.lua");
NPL.load("(gl)script/ide/math/Quaternion.lua");
NPL.load("(gl)script/ide/Encoding.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
NPL.load("(gl)script/ide/System/Encoding/base64.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieManager.lua");

local Matrix4 = commonlib.gettable("mathlib.Matrix4");
local NplExtensionsUpdater = NPL.load("(gl)script/apps/Aries/Creator/Game/NplExtensionsUpdater/NplExtensionsUpdater.lua");
local Quaternion = commonlib.gettable("mathlib.Quaternion");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");

local Encoding = commonlib.gettable("System.Encoding");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")

local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local NplBrowserLoaderPage = commonlib.gettable("NplBrowser.NplBrowserLoaderPage");
local NPLWebServer = commonlib.gettable("MyCompany.Aries.Game.Network.NPLWebServer");

local NplCadEditorMenuPage = NPL.export();
local is_opening;
NplCadEditorMenuPage.entity = nil;
NplCadEditorMenuPage.page = nil;
NplCadEditorMenuPage.dep_packages = {
	{ mod = "npl_extensions/npl_packages/NplCadEditor.zip", path = "npl_extensions/npl_packages/NplCadEditor/"}
}
NplCadEditorMenuPage.asset_list = {};
NplCadEditorMenuPage.selected_asset = nil;

NplCadEditorMenuPage.editor_maps = {};

function NplCadEditorMenuPage.ShowPage(entity)
	NplCadEditorMenuPage.page = nil;
	NplCadEditorMenuPage.entity = entity;
	NplCadEditorMenuPage.asset_list = {};
	is_opening = false;
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
				align = "_ml",
				x = 0,
				y = 0,
				width = 265,
				height = 0,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	local pageCtrl = params._page;
	NplCadEditorMenuPage.page = pageCtrl;
    
    if(pageCtrl)then
        pageCtrl.OnClose = function()
			NplCadEditorMenuPage.page = nil;
			NplCadEditorMenuPage.entity = nil;
        end
    end
	NplCadEditorMenuPage.Refresh();
	NplCadEditorMenuPage.OutputParax(entity);

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
		GameLogic.GetFilters():add_filter("nplcad3_notify_update", NplCadEditorMenuPage.OnNotifyUpdate);
		GameLogic.GetFilters():add_filter("nplcad3_notify_preview", NplCadEditorMenuPage.OnNplCadSavePreview);
	end
end
function NplCadEditorMenuPage.IsVisible()
	if(NplCadEditorMenuPage.page and NplCadEditorMenuPage.page:IsVisible())then
		return true;
	end
end
function NplCadEditorMenuPage.Refresh(DelayTime)
	if(DelayTime == nil)then
		DelayTime = 0;
	end
	if(NplCadEditorMenuPage.page)then
		NplCadEditorMenuPage.page:Refresh(DelayTime);
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

function NplCadEditorMenuPage.OnNotifyUpdate(name, bx, by, bz, codeEntity, options)
	if(codeEntity and  NplCadEditorMenuPage.entity == codeEntity)then
		NplCadEditorMenuPage.OutputParax(codeEntity, true)
	end
end

function NplCadEditorMenuPage.OnNplCadSavePreview(name, bx, by, bz, codeEntity, content, options)
	if(not content)then
		return
	end
	local blockpos = string.format("%d,%d,%d", bx, by, bz);
	local filepath = NplCadEditorMenuPage.GetModelPreviewPath(blockpos);
    content = string.match(content, "data:image/png;base64,(.+)");
	if(content and content ~= "")then
		content = Encoding.unbase64(content);
		NplCadEditorMenuPage.SaveFile(filepath, content)
		NplCadEditorMenuPage.Refresh();
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

function NplCadEditorMenuPage.GetModelPathByAssetItem(entity, asset_item)
	if(not entity or not asset_item)then
		return
	end
	local bx, by, bz = entity:GetBlockPos();
	local blockpos = string.format("%d,%d,%d", bx, by, bz);

	local id = asset_item.id;
	local label = asset_item.label;
	local name = asset_item.name;
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
			local show_name = NplCadEditorMenuPage.GetModelNameByAssetItem(asset_item);
			show_name = commonlib.Encoding.Utf8ToDefault(show_name);
			model_path = string.format("%sblocktemplates/nplcad3/editor_%s/%s.x", GameLogic.GetWorldDirectory(), blockpos, show_name);
		end
		return model_path;
	end
end
function NplCadEditorMenuPage.GetPreviewPathByAssetItem(entity, asset_item)
	if(not entity or not asset_item)then
		return
	end
	local bx, by, bz = entity:GetBlockPos();
	local blockpos = string.format("%d,%d,%d", bx, by, bz);

	local id = asset_item.id;
	local type = asset_item.type;
	local isBase64 = asset_item.isBase64;
	local isBinary = asset_item.isBinary;
	local isStage = asset_item.isStage;
	local content = asset_item.content;
	if(type == "png")then
		if(isStage)then
			local preview_path = string.format("%sblocktemplates/nplcad3/editor_%s/preview.png", GameLogic.GetWorldDirectory(), blockpos);
			return preview_path;
		end
	end

end
-- get unique name for actor npc
-- check name first, id second
function NplCadEditorMenuPage.GetModelNameByAssetItem(asset_item)
	if(not asset_item)then	
		return
	end
	local show_name = asset_item.name;
	if(not show_name or show_name == "")then
		show_name = asset_item.id;
	end
	return show_name;
end
function NplCadEditorMenuPage.OutputParax(entity, bForce)
	if(not entity)then
		return
	end
    local bx, by, bz = entity:GetBlockPos();
	local blockpos = string.format("%d,%d,%d", bx, by, bz);


	if(not bForce)then
		local editor_info = NplCadEditorMenuPage.editor_maps[blockpos];
		if(editor_info and editor_info.asset_list)then
			local asset_list = editor_info.asset_list;
			NplCadEditorMenuPage.asset_list = asset_list;
			NplCadEditorMenuPage.OnFillMovieClip(entity, asset_list);
			NplCadEditorMenuPage.OnSelectedAsset(1)
			return
		end
	end

	NplCadEditorMenuPage.editor_maps[blockpos] = nil;
	NplCadEditorMenuPage.asset_list = {};
	local data = entity:GetIDEContent();
	if(not data)then
		return
	end

	local editorBean = {};
	if(NPL.FromJson(data, editorBean)) then

		local asset = editorBean.asset;
		if(asset)then

			local asset_list = {}
			for k,asset_item in ipairs(asset) do
				local id = asset_item.id;
				local type = asset_item.type;
				local isBase64 = asset_item.isBase64;
				local isBinary = asset_item.isBinary;
				local isStage = asset_item.isStage;
				local content = asset_item.content;

				if(type == "parax")then
					local model_path = NplCadEditorMenuPage.GetModelPathByAssetItem(entity, asset_item);
					if(isBase64)then
						content = Encoding.unbase64(content);
					end
					-- save parax file
					NplCadEditorMenuPage.SaveFile(model_path, content);

					if(isStage)then
						asset_item.temp_order = 1;
					else
						asset_item.temp_order = 0;
					end
					table.insert(asset_list, asset_item);
				end
			end
            GameLogic.AddBBS("statusBar", L"生成模型完毕", 5000, "0 255 0");
			table.sort(asset_list, function(a,b)
				return a.temp_order > b.temp_order;

			end)


			NplCadEditorMenuPage.editor_maps[blockpos] = {
				asset_list = asset_list,
			}
			NplCadEditorMenuPage.asset_list = asset_list;
			NplCadEditorMenuPage.OnFillMovieClip(entity, asset_list);
			NplCadEditorMenuPage.OnSelectedAsset(1)
		end
	end
end
function NplCadEditorMenuPage.OnFillMovieClip(entity, asset_list)
	if(not entity or not asset_list)then
		return
	end
	local movieEntity = entity:AutoCreateMovieEntity();

	for k,asset_item in ipairs(asset_list) do
		local id = asset_item.id;
		local type = asset_item.type;
		local isBase64 = asset_item.isBase64;
		local isBinary = asset_item.isBinary;
		local isStage = asset_item.isStage;
		local content = asset_item.content;
		if(type == "parax")then
			-- create ActorNPC to movieclip
			if(not isStage)then
				NplCadEditorMenuPage.OnFillModel(entity, movieEntity, asset_item);
			end
		end
	end
	movieEntity:OpenEditor();
--	MovieManager:SetActiveMovieClip(nil)
end
function NplCadEditorMenuPage.GetTransformByMatrix(matrix)
	if(not matrix)then
		return
	end
	local x = matrix[13];
	local y = matrix[14];
	local z = matrix[15];

	local scale_x = matrix[1];
	local scale_y = matrix[6];
	local scale_z = matrix[11];

	local q = Quaternion:new();
	q:FromRotationMatrix(matrix);

	local yaw_y, roll_z, pitch_x = q:ToEulerAngles();
	local transform = {
		x = x,
		y = y,
		z = z,
		scale_x = scale_x,
		scale_y = scale_y,
		scale_z = scale_z,

		pitch_x = pitch_x,
		yaw_y = yaw_y,
		roll_z = roll_z,
	}
	return transform;
end
function NplCadEditorMenuPage.OnFillModel(entity, movieEntity, asset_item)
	if(not entity or not movieEntity or not asset_item)then
		return
	end
	local model_path = NplCadEditorMenuPage.GetModelPathByAssetItem(entity, asset_item);
	local show_name = NplCadEditorMenuPage.GetModelNameByAssetItem(asset_item);

	local movieclip = movieEntity:GetMovieClip();
	movieclip:RefreshActors();
	

    local bx, by, bz = movieEntity:GetBlockPos();
	local center_x, center_y, center_z = BlockEngine:real_bottom(bx, by, bz)

	local matrix = asset_item.matrix;
	local worldMatrix = asset_item.worldMatrix;
	if(worldMatrix)then
		worldMatrix = Matrix4:new(worldMatrix);
	end
	
	local transform = NplCadEditorMenuPage.GetTransformByMatrix(worldMatrix);

	local actor = movieclip:FindActor(show_name);
	if(not actor)then
		--- this is a ActorNPC
		local itemStack = movieEntity:CreateNPC();
		actor = movieclip:GetActorFromItemStack(itemStack, true);
		actor:SetDisplayName(show_name);
	end
	actor:AddKeyFrameByName("assetfile", 0, model_path);
	if(transform)then
		
		actor:AddKeyFrameByName("x", 0, center_x + transform.x);
		actor:AddKeyFrameByName("y", 0, center_y + transform.y);
		actor:AddKeyFrameByName("z", 0, center_z + transform.z);

		--actor:AddKeyFrameByName("scaling", 0, { transform.scale_x, transform.scale_y, transform.scale_z, });

		actor:AddKeyFrameByName("pitch", 0, transform.pitch_x);
		actor:AddKeyFrameByName("facing", 0, transform.yaw_y);
		actor:AddKeyFrameByName("roll", 0, transform.roll_z);
	end
	actor:FrameMovePlaying(0);
end
function NplCadEditorMenuPage.OnSelectedAsset(index)
    local asset_item = NplCadEditorMenuPage.asset_list[index];
    NplCadEditorMenuPage.selected_asset = asset_item;
    NplCadEditorMenuPage.Refresh();
end
function NplCadEditorMenuPage.IsSelectedAsset(index)
    index = tonumber(index);
    local asset_item = NplCadEditorMenuPage.asset_list[index];
    if(asset_item == NplCadEditorMenuPage.selected_asset)then
        return true;
    end
end
function NplCadEditorMenuPage.OnOpen(type, entity)
	if(not NplExtensionsUpdater.IsLoaded())then
        GameLogic.AddBBS("statusBar", L"正在下载NPL代码库，请稍等片刻。。。", 5000, "255 0 0");
        return
    end
    if(not entity)then
        return
    end
    if(not NplBrowserLoaderPage.IsLoaded())then
        GameLogic.AddBBS("statusBar", L"浏览器正在加载，请稍等！", 5000, "255 0 0");
        return
    end
    if(is_opening)then
        return
    end
    is_opening = true;
    local bStarted, site_url = NPLWebServer.CheckServerStarted(function(bStarted, site_url)	
        is_opening = false;
        local bx, by, bz = NplCadEditorMenuPage.GetBlockPos();
        if(bz) then
            blockpos = string.format("%d,%d,%d", bx, by, bz);
        end
        local url = string.format("%snplcad3?blockpos=%s", site_url, blockpos);
        if(type == "web")then
            GameLogic.RunCommand("/open "..url);
        elseif(type == "local_web_cef3")then
            url = string.format("%s&r=%s", url, ParaGlobal.GenerateUniqueID())
            local NplBrowserManager = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserManager.lua");
            NplBrowserManager:CreateOrGet("NplCadEditorBrowser"):Show(url, "", false, true, { align = "_lt", left = 265, top = 0, right = 0, bottom = 0});
        elseif(type == "json")then
            if(entity)then
                local data = entity:GetIDEContent();
                local filepath = NplCadEditorMenuPage.GetJsonPath(blockpos)
                NplCadEditorMenuPage.SaveFile(filepath, data)
                local tips = string.format("成功导出数据到：%s，是否立即查看？", filepath)
                _guihelper.MessageBox(tips, function(res)
                    if(res and res == _guihelper.DialogResult.Yes) then
                        NplCadEditorMenuPage.OnOpenFolder();
                    else
                    end
                end, _guihelper.MessageBoxButtons.YesNo);
            end
        end
    end)
    if(not bStarted)then
        GameLogic.AddBBS("statusBar", L"网络服务器正在启动，请稍等！", 5000, "255 0 0");
    end
end

function NplCadEditorMenuPage.OnOpenFolder()
    local model_path = NplCadEditorMenuPage.GetModelPath(NplCadEditorMenuPage.GetName());
    if(not model_path)then
        return
    end
    local info = Files.ResolveFilePath(model_path)
    if(info and info.relativeToWorldPath) then
        local absPath = ParaIO.GetCurDirectory(0)..info.relativeToRootPath;
        local absPathFolder = absPath:gsub("[^/\\]+$", "")
        ParaGlobal.ShellExecute("open", absPathFolder, "", "", 1);
    end
end
function NplCadEditorMenuPage.OnTakeModel()
    local asset_item = NplCadEditorMenuPage.selected_asset;
    if(not asset_item)then
        return
    end

    local model_path = NplCadEditorMenuPage.GetModelPathByAssetItem(entity, asset_item);
    if(not model_path)then
        GameLogic.AddBBS("statusBar", L"文件不存在", 5000, "255 0 0");
        return
    end
    local info = Files.ResolveFilePath(model_path)
    if(info and info.relativeToWorldPath) then
        GameLogic.RunCommand(string.format("/take BlockModel {tooltip=\"%s\"}", commonlib.Encoding.DefaultToUtf8(info.relativeToWorldPath)));
    end
end