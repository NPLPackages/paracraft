--[[
Title: Export Task Command
Author(s): LiXizhi
Date: 2015/9/28
Desc: allow the user to select to export as bmax model or block template. 

---++ plugins
To add your own filter, hook "GetExporters" like below
GameLogic.GetFilters():add_filter("GetExporters", function(exporters)
	exporters[#exporters+1] = {id="STL", title="STL exporter", desc="export stl files for 3d printing"}
	return exporters;
end);

To respond to user click event, hook "select_exporter" like below
GameLogic.GetFilters():add_filter("select_exporter", function(id)
	if(id == "STL") then
		id = nil; -- prevent other exporters
		_guihelper.MessageBox("STL exporter selected");
	end
	return id;
end);

When user has successfully exported a file, it is recommended to apply "file_exported" like below
GameLogic.GetFilters():apply_filters("file_exported", id, filename);

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ExportTask.lua");
local Export = commonlib.gettable("MyCompany.Aries.Game.Tasks.Export");
local task = MyCompany.Aries.Game.Tasks.Export:new({SilentMode = true})
task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/SelectionManager.lua");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local Export = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.Export"));

-- whether to suppress any gui pop up. 
Export:Property({"m_bSilentMode", nil, "IsSilentMode", "SetSilentMode", auto=true});
Export:Property({"FileName", nil, auto=true});

local curInstance;
local page;

-- one can append exporters here
Export.exporters = {
	{id="bmax", title=L"保存为bmax模型", desc=L"bmax是一种基于方块的模型格式, 支持骨骼动画。可用于构建可放缩的模型方块或电影演员。", order = 0},
	{id="template", title=L"保存为template模版", desc=L"template记录了方块的全部信息, 包括电影方块内部的演员。可以通过/loadtemplate等命令复制模版到场景中。", order = 0},
	{id="ply_point", title=L"保存为ply点云", desc=L"ply是一种通用的彩色点云格式，可以被第三方程序打开", order = 10},
	{id="gltf", title=L"保存为gltf模型文件", desc=L"gltf是一种通用的3D模型文件格式，支持贴图和动画，可以被大量第三方程序打开。", order = 10},
}

function Export:ctor()
	local exporters = {};
	for _, item in ipairs(Export.exporters) do
		exporters[#exporters+1] = item;
	end
	-- for plugin
	self.exporters = GameLogic.GetFilters():apply_filters("GetExporters", exporters);
	commonlib.algorithm.quicksort(self.exporters, function(a, b)
		return (a.order or 0) <= (b.order or 0);
	end);
end

function Export.OnInit()
	page = document:GetPageCtrl();
end

function Export:ShowPage(bShow)
	curInstance = self;
	local width, height = 680, 450;
	local params = {
		url = "script/apps/Aries/Creator/Game/Tasks/ExportTask.html", 
		name = "ExportTask.ShowPage", 
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		isShowTitleBar = false,
		bShow = bShow,
		DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
		style = CommonCtrl.WindowFrame.ContainerStyle,
		zorder = 1,
		allowDrag = true,
		directPosition = true,
			align = "_ct",
			x = -width/2,
			y = -height/2,
			width = width,
			height = height,
	}
	params =  GameLogic.GetFilters():apply_filters('GetUIPageHtmlParam',params,"ExportTask");
	
	--[[
	local IsMobileUIEnabled = GameLogic.GetFilters():apply_filters('MobileUIRegister.IsMobileUIEnabled',false)
	if not IsMobileUIEnabled then
		width, height = 680, 344;
		params.url = "script/apps/Aries/Creator/Game/KeepWorkMall/ExportTaskNew.html"
		params.x = -width/2
		params.y = -height/2
		params.width = width
		params.height = height
	end
	]]

	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

-- static function to retrieve the exporter database
function Export.GetExporterDB()
	local self = curInstance;
	return self.exporters;
end


-- @param bIsDataPrepared: true if data is prepared. if nil, we will prepare the data from input params.
function Export:Run()
	if(self:IsSilentMode()) then
		local filename = self:GetFileName();
		if(filename and filename ~= "") then
			self:ExportToFile(filename);
		else
			self:ShowPage(false);
		end
	else
		self:ShowPage(true);
	end
end

-- export selection as given file
-- this is mostly for silent mode exporting via command. 
function Export:ExportToFile(filename)
	filename = GameLogic.GetFilters():apply_filters("export_to_file", filename);
	if(not filename) then
		-- TODO: for buildin file types
	end
end

function Export.OnSelectExporter(id)
	if(page) then
		page:CloseWindow();
	end
	-- for plugins
	id = GameLogic.GetFilters():apply_filters("select_exporter", id);

	if(id) then
		local selected_blocks = SelectionManager:GetSelectedBlocks();
		if (not selected_blocks) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
			local SelectBlocks = commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectBlocks");
			local cx, cy, cz = EntityManager.GetPlayer():GetBlockPos();
			local selectedblocks = SelectBlocks.AutoSelectNearbyBlocks(cx, cy, cz, 7)
			if((selectedblocks or 0)== 0) then
				GameLogic.AddBBS("ExportTask", L"请先选择物体, Ctrl+左键多次点击场景可选择", 5000, "0 255 0");
				return
			else
				GameLogic.AddBBS("ExportTask", L"自动选择了附近方块，作为保存对象", 5000, "0 255 0");
			end
		end
		if(id == "bmax") then
			-- 没权限的话 不允许保存bmax
			local UserPermission = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/UserPermission.lua");
			UserPermission.CheckCanEditBlock("click_save_bmax", function()
				Export.ExportAsBMax();
			end)
		
		elseif(id == "template") then
			Export.ExportAsTemplate();
		elseif(id == "ply_point") then
			Export.ExportAsPlyPoint();
		elseif(id == "gltf") then
			Export.ExportAsGltf();
		end
	end
end

function Export.ExportAsTemplate()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
	local SelectBlocks = commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectBlocks");
	SelectBlocks.SaveToTemplate();
	GameLogic.GetFilters():apply_filters("user_event_stat", "model", "exportAsTemplate", 10, nil);
end

function Export.ExportAsBMax()
	NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/SaveFileDialog.lua");
	local SaveFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.SaveFileDialog");
	SaveFileDialog.ShowPage(L"请输入bmax文件名称", function(result)
		if(result and result~="") then
			local filename = result;
			local filenameUtf8 = commonlib.Encoding.DefaultToUtf8(filename);
			
			if(GameLogic.Macros:IsRecording()) then
				GameLogic.Macros:AddMacro("ConfirmNextMessageBoxClick");
			end
			-- we will force overwrite if user selected from existing file
			local opt = SaveFileDialog.IsSelectedFromExistingFiles() and "-f" or ""
			local bSuccess, filename = GameLogic.RunCommand("savemodel", format("-interactive %s \"%s\"", opt, filenameUtf8));
			if(bSuccess and filename) then
			end
		end
	end, nil, nil, "bmax");
end

function Export.ExportAsPlyPoint()
	NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/SaveFileDialog.lua");
	local SaveFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.SaveFileDialog");
	SaveFileDialog.ShowPage(L"请输入ply文件名称", function(result)
		if(result and result~="") then
			local filename = result;
			local filenameUtf8 = commonlib.Encoding.DefaultToUtf8(filename);

			if(GameLogic.Macros:IsRecording()) then
				GameLogic.Macros:AddMacro("ConfirmNextMessageBoxClick");
			end
			-- we will force overwrite if user selected from existing file
			local opt = SaveFileDialog.IsSelectedFromExistingFiles() and "-f" or ""
			local bSuccess, filename = GameLogic.RunCommand("savemodel", format("-ply -interactive %s \"%s\"", opt, filenameUtf8));
			if(bSuccess and filename) then
			end
		end
	end, nil, nil, "ply");
end

function Export.ExportAsGltf()
	NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/SaveFileDialog.lua");
	local SaveFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.SaveFileDialog");
	SaveFileDialog.ShowPage(L"请输入gltf或glb文件名称", function(result)
		if(result and result~="") then
			local filename = result;
			local filenameUtf8 = commonlib.Encoding.DefaultToUtf8(filename);

			if(GameLogic.Macros:IsRecording()) then
				GameLogic.Macros:AddMacro("ConfirmNextMessageBoxClick");
			end
			-- we will force overwrite if user selected from existing file
			local opt = SaveFileDialog.IsSelectedFromExistingFiles() and "-f" or ""
			local bSuccess, filename = GameLogic.RunCommand("exportgltf", format("%s \"%s\"", opt, filenameUtf8));
			if(bSuccess and filename) then
			end
		end
	end, nil, nil, "gltf");
end