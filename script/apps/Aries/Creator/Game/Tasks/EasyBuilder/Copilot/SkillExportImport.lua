--[[
Title: Skill Export/Import UI
Author: auto-generated
Date: 2026/03/03
Desc: Provides UI for exporting skill directories to .zip and importing
      skills from local zip files or remote URLs.
      Imported skills are hot-loaded into the running BackgroundAgent.

Usage:
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/SkillExportImport.lua");
    local SkillExportImport = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.SkillExportImport");
    SkillExportImport:ShowPage()
]]

NPL.load("(gl)script/ide/OpenFileDialog.lua");
local OpenFileDialog = commonlib.gettable("CommonCtrl.OpenFileDialog");
local SkillManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/SkillManager.lua");

local SkillExportImport = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.SkillExportImport");

local page;

-- State
SkillExportImport.selectedSkill = "";
SkillExportImport.exportDir = "";
SkillExportImport.exportSkillDir = "";
SkillExportImport.exportDirOutputDir = "";
SkillExportImport.importUrl = "";
SkillExportImport.importZipPath = "";
SkillExportImport.statusText = "";
SkillExportImport.statusColor = "#888888";

function SkillExportImport.InitPage(Page)
    page = Page;
    -- Default to first registered skill
    local names = SkillManager.GetRegisteredNames();
    if names and #names > 0 and SkillExportImport.selectedSkill == "" then
        SkillExportImport.selectedSkill = names[1];
    end
end

function SkillExportImport:ShowPage()
    local width, height = 520, 560;
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/SkillExportImport.html",
        name = "SkillExportImport.ShowPage",
        isShowTitleBar = false,
        DestroyOnClose = true,
        bToggleShowHide = false,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        enable_esc_key = true,
        allowDrag = true,
        click_through = false,
        zorder = 3,
        directPosition = true,
        align = "_ct",
        x = -width / 2,
        y = -height / 2,
        width = width,
        height = height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    if params._page then
        page = params._page;
    end
end

function SkillExportImport.CloseWindow()
    if page then
        page:CloseWindow();
    end
end

function SkillExportImport.GetSkillNames()
    return SkillManager.GetRegisteredNames() or {};
end

function SkillExportImport.GetSkillNamesText()
    local names = SkillExportImport.GetSkillNames();
    return table.concat(names, ";");
end

function SkillExportImport.SetStatus(text, color)
    SkillExportImport.statusText = text or "";
    SkillExportImport.statusColor = color or "#888888";
    if page then
        page:SetValue("statusText", SkillExportImport.statusText);
    end
end

--------------------------------------------------------------------------------
-- Export
--------------------------------------------------------------------------------

function SkillExportImport.OnSelectSkill(name)
    SkillExportImport.selectedSkill = name;
end

function SkillExportImport.OnBrowseExportDir()
    local folder = OpenFileDialog.ShowOpenFolder_Win32();
    if folder and folder ~= "" then
        SkillExportImport.exportDir = folder;
        if page then
            page:SetValue("exportDir", folder);
        end
    end
end

function SkillExportImport.OnExport()
    local skillName = SkillExportImport.selectedSkill;
    if not skillName or skillName == "" then
        SkillExportImport.SetStatus("请先选择一个Skill", "#ff0000");
        return;
    end

    -- Read export dir from text input
    if page then
        local val = page:GetValue("exportDir");
        if val and val ~= "" then
            SkillExportImport.exportDir = val;
        end
    end

    local outputDir = SkillExportImport.exportDir;
    if not outputDir or outputDir == "" then
        SkillExportImport.SetStatus("请先选择导出目录", "#ff0000");
        return;
    end

    SkillExportImport.SetStatus("正在导出...", "#ffcc00");

    -- Export/import functions removed in SkillManager simplification
    SkillExportImport.SetStatus("导出功能暂未实现 (SkillManager已简化)", "#ff0000");
    _guihelper.MessageBox("导出功能暂未实现，SkillManager已简化为仅发现模块。");
end

--------------------------------------------------------------------------------
-- Export from Directory
--------------------------------------------------------------------------------

function SkillExportImport.OnBrowseSkillDir()
    local folder = OpenFileDialog.ShowOpenFolder_Win32();
    if folder and folder ~= "" then
        SkillExportImport.exportSkillDir = folder;
        if page then
            page:SetValue("exportSkillDir", folder);
        end
    end
end

function SkillExportImport.OnBrowseExportDirOutput()
    local folder = OpenFileDialog.ShowOpenFolder_Win32();
    if folder and folder ~= "" then
        SkillExportImport.exportDirOutputDir = folder;
        if page then
            page:SetValue("exportDirOutputDir", folder);
        end
    end
end

function SkillExportImport.OnExportFromDir()
    -- Read skill directory from text input
    if page then
        local val = page:GetValue("exportSkillDir");
        if val and val ~= "" then
            SkillExportImport.exportSkillDir = val;
        end
    end

    local skillDir = SkillExportImport.exportSkillDir;
    if not skillDir or skillDir == "" then
        SkillExportImport.SetStatus("请先选择Skill目录", "#ff0000");
        return;
    end

    -- Read output directory from text input
    if page then
        local val = page:GetValue("exportDirOutputDir");
        if val and val ~= "" then
            SkillExportImport.exportDirOutputDir = val;
        end
    end

    local outputDir = SkillExportImport.exportDirOutputDir;
    if not outputDir or outputDir == "" then
        SkillExportImport.SetStatus("请先选择导出目录", "#ff0000");
        return;
    end

    SkillExportImport.SetStatus("正在导出目录...", "#ffcc00");

    -- Export/import functions removed in SkillManager simplification
    SkillExportImport.SetStatus("目录导出功能暂未实现 (SkillManager已简化)", "#ff0000");
    _guihelper.MessageBox("目录导出功能暂未实现，SkillManager已简化为仅发现模块。");
end

--------------------------------------------------------------------------------
-- Import from URL
--------------------------------------------------------------------------------

function SkillExportImport.OnImportFromUrl()
    -- Read URL from text input
    if page then
        local val = page:GetValue("importUrl");
        if val and val ~= "" then
            SkillExportImport.importUrl = val;
        end
    end

    local url = SkillExportImport.importUrl;
    if not url or url == "" then
        SkillExportImport.SetStatus("请输入Skill包的URL", "#ff0000");
        return;
    end

    SkillExportImport.SetStatus("正在下载...", "#ffcc00");

    -- Import functions removed in SkillManager simplification
    SkillExportImport.SetStatus("URL导入功能暂未实现 (SkillManager已简化)", "#ff0000");
    _guihelper.MessageBox("URL导入功能暂未实现，SkillManager已简化为仅发现模块。");
end

--------------------------------------------------------------------------------
-- Import from local zip
--------------------------------------------------------------------------------

function SkillExportImport.OnBrowseZipFile()
    local filename = OpenFileDialog.ShowDialog_Win32(
        {{"Skill Zip (*.zip)", "*.zip"}},
        "选择Skill压缩包",
        nil,  -- initial dir
        false -- not save mode
    );
    if filename and filename ~= "" then
        SkillExportImport.importZipPath = filename;
        if page then
            page:SetValue("importZipPath", filename);
        end
    end
end

function SkillExportImport.OnImportFromZip()
    -- Read path from text input
    if page then
        local val = page:GetValue("importZipPath");
        if val and val ~= "" then
            SkillExportImport.importZipPath = val;
        end
    end

    local zipPath = SkillExportImport.importZipPath;
    if not zipPath or zipPath == "" then
        SkillExportImport.SetStatus("请先选择Skill压缩包", "#ff0000");
        return;
    end

    SkillExportImport.SetStatus("正在导入...", "#ffcc00");

    -- Import functions removed in SkillManager simplification
    SkillExportImport.SetStatus("Zip导入功能暂未实现 (SkillManager已简化)", "#ff0000");
    _guihelper.MessageBox("Zip导入功能暂未实现，SkillManager已简化为仅发现模块。");
end

--------------------------------------------------------------------------------
-- Agent Hot-Load
--------------------------------------------------------------------------------

function SkillExportImport.HotLoadIntoAgent(skillName)
    if not skillName then return; end

    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/BackgroundAgent.lua");
    local BackgroundAgent = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.BackgroundAgent");
    local agent = BackgroundAgent:GetInstance();

    if agent then
        agent:HotLoadSkill(skillName, function(result)
            if result and result.success then
                LOG.std(nil, "info", "SkillExportImport", "Skill '%s' hot-loaded into agent", skillName);
            else
                LOG.std(nil, "warn", "SkillExportImport", "Failed to hot-load '%s': %s", skillName, tostring(result and result.error));
            end
        end);
    end
end
