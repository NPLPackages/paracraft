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
	{id="bmax", title=L"保存为bmax模型", desc=L"bmax是一种基于方块的模型格式, 支持骨骼动画。可用于构建可放缩的模型方块或电影演员。"},
	{id="template", title=L"保存为template模版", desc=L"template记录了方块的全部信息, 包括电影方块内部的演员。可以通过/loadtemplate等命令复制模版到场景中。"},
}

function Export:ctor()
	local exporters = {};
	for _, item in ipairs(Export.exporters) do
		exporters[#exporters+1] = item;
	end
	-- for plugin
	self.exporters = GameLogic.GetFilters():apply_filters("GetExporters", exporters);
end

function Export.OnInit()
	page = document:GetPageCtrl();
end

function Export:ShowPage(bShow)
	curInstance = self;
	local width, height = 512, 400;
	System.App.Commands.Call("File.MCMLWindowFrame", {
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
		});
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
		if(SelectionManager:GetSelectedBlocks()) then
			self:ShowPage(true);
		else
			GameLogic.AddBBS(nil, L"请先选择物体, Ctrl+左键多次点击场景可选择");
		end
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

	if(id == "bmax") then
		Export.ExportAsBMax();
	elseif(id == "template") then
		Export.ExportAsTemplate();
	end
end

function Export.ExportAsTemplate(id)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
	local SelectBlocks = commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectBlocks");
	SelectBlocks.SaveToTemplate();
end

function Export.ExportAsBMax()
	NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/SaveFileDialog.lua");
	local SaveFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.SaveFileDialog");
	SaveFileDialog.ShowPage(L"请输入bmax文件名称", function(result)
		if(result and result~="") then
			local filename = result;
			local bSuccess, filename = GameLogic.RunCommand("savemodel", filename);
			if(bSuccess and filename) then
				GameLogic.GetFilters():apply_filters("file_exported", "bmax", filename);
			end
		end
	end, nil, nil, "bmax");
end