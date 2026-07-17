--[[
Title: LogAnalysis
Author(s): Copilot
Date: 2026/03/06
Desc: A log analysis page for viewing, filtering and searching log entries.
Supports loading log files, filtering by log level (debug/info/warn/error),
keyword search, auto-refresh, and detailed log entry inspection.

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/LogAnalysis.lua");
local LogAnalysis = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.LogAnalysis");
LogAnalysis.ShowPage();
------------------------------------------------------------
]]

local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");

local LogAnalysis = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.LogAnalysis");

local page;

-- State
LogAnalysis.allEntries = {};
LogAnalysis.filteredEntries = {};
LogAnalysis.searchText = "";
LogAnalysis.selectedIndex = nil;
LogAnalysis.currentFile = "";
LogAnalysis.autoRefresh = false;
LogAnalysis.autoRefreshTimer = nil;
LogAnalysis.filterLevel = "all"; -- "all", "debug", "info", "warn", "error"
LogAnalysis.totalDebug = 0;
LogAnalysis.totalInfo = 0;
LogAnalysis.totalWarn = 0;
LogAnalysis.totalError = 0;

function LogAnalysis.Init()
	page = document:GetPageCtrl();
end

function LogAnalysis.ShowPage()
	LogAnalysis.allEntries = {};
	LogAnalysis.filteredEntries = {};
	LogAnalysis.searchText = "";
	LogAnalysis.selectedIndex = nil;
	LogAnalysis.filterLevel = "all";

	local params = {
		url = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/LogAnalysis.html",
		name = "LogAnalysis.ShowPage",
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = true,
		enable_esc_key = true,
		zorder = 1,
		directPosition = true,
			align = "_ct",
			x = -400,
			y = -280,
			width = 800,
			height = 560,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	params._page.OnClose = function()
		LogAnalysis.StopAutoRefresh();
		page = nil;
	end;
end

function LogAnalysis.OnClose()
	LogAnalysis.StopAutoRefresh();
	if (page) then
		page:CloseWindow();
	end
end

function LogAnalysis.RefreshPage()
	if (page) then
		page:Refresh(0.01);
	end
end

-----------------------------------------------------------------------
-- Log level detection
-----------------------------------------------------------------------
local levelPatterns = {
	{ pattern = "error",   level = "error" },
	{ pattern = "fail",    level = "error" },
	{ pattern = "exception", level = "error" },
	{ pattern = "warn",    level = "warn" },
	{ pattern = "warning", level = "warn" },
	{ pattern = "info",    level = "info" },
	{ pattern = "debug",   level = "debug" },
	{ pattern = "trace",   level = "debug" },
}

function LogAnalysis.DetectLevel(line)
	local lower = string.lower(line);
	for _, lp in ipairs(levelPatterns) do
		if string.find(lower, lp.pattern) then
			return lp.level;
		end
	end
	return "info"; -- default
end

-----------------------------------------------------------------------
-- Parse a raw log text into entries
-----------------------------------------------------------------------
function LogAnalysis.ParseLogText(text)
	local entries = {};
	if not text or text == "" then
		return entries;
	end

	local index = 0;
	for line in string.gmatch(text, "([^\r\n]+)") do
		if line and line ~= "" then
			index = index + 1;
			local level = LogAnalysis.DetectLevel(line);
			-- Try to extract timestamp from common formats like [2026-03-06 10:00:00] or 2026/03/06 10:00:00
			local timestamp = string.match(line, "%d%d%d%d[%-%/]%d%d[%-%/]%d%d[%s%_T]%d%d:%d%d:%d%d") or "";
			entries[#entries + 1] = {
				index = index,
				text = line,
				level = level,
				timestamp = timestamp,
			};
		end
	end
	return entries;
end

-----------------------------------------------------------------------
-- Load log from file
-----------------------------------------------------------------------
function LogAnalysis.LoadFromFile(filepath)
	if not filepath or filepath == "" then
		return;
	end
	LogAnalysis.currentFile = filepath;
	local file = ParaIO.open(filepath, "r");
	if file:IsValid() then
		local text = file:GetText(0, -1);
		file:close();
		LogAnalysis.allEntries = LogAnalysis.ParseLogText(text);
		LogAnalysis.UpdateStats();
		LogAnalysis.ApplyFilter();
		LogAnalysis.RefreshPage();
	else
		GameLogic.AddBBS("LogAnalysis", L"无法打开文件: " .. filepath, 3000, "255 0 0");
	end
end

-----------------------------------------------------------------------
-- Load the default log.txt
-----------------------------------------------------------------------
function LogAnalysis.LoadDefaultLog()
	LogAnalysis.LoadFromFile("log.txt");
end

-----------------------------------------------------------------------
-- Update statistics
-----------------------------------------------------------------------
function LogAnalysis.UpdateStats()
	local deb, inf, wrn, err = 0, 0, 0, 0;
	for _, entry in ipairs(LogAnalysis.allEntries) do
		if entry.level == "debug" then
			deb = deb + 1;
		elseif entry.level == "info" then
			inf = inf + 1;
		elseif entry.level == "warn" then
			wrn = wrn + 1;
		elseif entry.level == "error" then
			err = err + 1;
		end
	end
	LogAnalysis.totalDebug = deb;
	LogAnalysis.totalInfo = inf;
	LogAnalysis.totalWarn = wrn;
	LogAnalysis.totalError = err;
end

-----------------------------------------------------------------------
-- Apply filter and search
-----------------------------------------------------------------------
function LogAnalysis.ApplyFilter()
	local result = {};
	local keyword = LogAnalysis.searchText and string.lower(LogAnalysis.searchText) or "";
	local level = LogAnalysis.filterLevel;

	for _, entry in ipairs(LogAnalysis.allEntries) do
		local levelMatch = (level == "all") or (entry.level == level);
		local searchMatch = (keyword == "") or string.find(string.lower(entry.text), keyword, 1, true);
		if levelMatch and searchMatch then
			result[#result + 1] = entry;
		end
	end
	LogAnalysis.filteredEntries = result;
	LogAnalysis.selectedIndex = nil;
end

-----------------------------------------------------------------------
-- DataSource for the gridview
-----------------------------------------------------------------------
function LogAnalysis.DS_Entries(index)
	if index == nil then
		return #(LogAnalysis.filteredEntries);
	else
		return LogAnalysis.filteredEntries[index];
	end
end

-----------------------------------------------------------------------
-- Events
-----------------------------------------------------------------------
function LogAnalysis.OnSearchChanged(value)
	LogAnalysis.searchText = value or "";
	LogAnalysis.ApplyFilter();
	LogAnalysis.RefreshPage();
end

function LogAnalysis.OnSelectEntry(name)
	LogAnalysis.selectedIndex = tonumber(name);
	LogAnalysis.RefreshPage();
end

function LogAnalysis.IsSelected(index)
	return LogAnalysis.selectedIndex == tonumber(index);
end

function LogAnalysis.GetSelectedDetail()
	if LogAnalysis.selectedIndex and LogAnalysis.filteredEntries[LogAnalysis.selectedIndex] then
		return LogAnalysis.filteredEntries[LogAnalysis.selectedIndex].text;
	end
	return L"点击日志条目查看详情";
end

function LogAnalysis.SetFilter(level)
	LogAnalysis.filterLevel = level or "all";
	LogAnalysis.ApplyFilter();
	LogAnalysis.RefreshPage();
end

function LogAnalysis.OnFilterAll()
	LogAnalysis.SetFilter("all");
end

function LogAnalysis.OnFilterDebug()
	LogAnalysis.SetFilter("debug");
end

function LogAnalysis.OnFilterInfo()
	LogAnalysis.SetFilter("info");
end

function LogAnalysis.OnFilterWarn()
	LogAnalysis.SetFilter("warn");
end

function LogAnalysis.OnFilterError()
	LogAnalysis.SetFilter("error");
end

function LogAnalysis.OnLoadFile()
	LogAnalysis.LoadDefaultLog();
end

function LogAnalysis.OnReload()
	if LogAnalysis.currentFile and LogAnalysis.currentFile ~= "" then
		LogAnalysis.LoadFromFile(LogAnalysis.currentFile);
	else
		LogAnalysis.LoadDefaultLog();
	end
end

function LogAnalysis.OnClear()
	LogAnalysis.allEntries = {};
	LogAnalysis.filteredEntries = {};
	LogAnalysis.selectedIndex = nil;
	LogAnalysis.searchText = "";
	LogAnalysis.totalDebug = 0;
	LogAnalysis.totalInfo = 0;
	LogAnalysis.totalWarn = 0;
	LogAnalysis.totalError = 0;
	LogAnalysis.RefreshPage();
end

-----------------------------------------------------------------------
-- Auto refresh
-----------------------------------------------------------------------
function LogAnalysis.ToggleAutoRefresh()
	if LogAnalysis.autoRefresh then
		LogAnalysis.StopAutoRefresh();
	else
		LogAnalysis.StartAutoRefresh();
	end
	LogAnalysis.RefreshPage();
end

function LogAnalysis.StartAutoRefresh()
	LogAnalysis.autoRefresh = true;
	if not LogAnalysis.autoRefreshTimer then
		LogAnalysis.autoRefreshTimer = commonlib.Timer:new({callbackFunc = function()
			LogAnalysis.OnReload();
		end});
		LogAnalysis.autoRefreshTimer:Change(3000, 3000); -- every 3 seconds
	end
end

function LogAnalysis.StopAutoRefresh()
	LogAnalysis.autoRefresh = false;
	if LogAnalysis.autoRefreshTimer then
		LogAnalysis.autoRefreshTimer:Change();
		LogAnalysis.autoRefreshTimer = nil;
	end
end

-----------------------------------------------------------------------
-- Get level color for display
-----------------------------------------------------------------------
function LogAnalysis.GetLevelColor(level)
	if level == "error" then
		return "#ff4444";
	elseif level == "warn" then
		return "#ffaa00";
	elseif level == "debug" then
		return "#888888";
	else
		return "#cccccc";
	end
end

function LogAnalysis.GetLevelLabel(level)
	if level == "error" then
		return "[ERROR]";
	elseif level == "warn" then
		return "[WARN] ";
	elseif level == "debug" then
		return "[DEBUG]";
	else
		return "[INFO] ";
	end
end

-----------------------------------------------------------------------
-- Summary info
-----------------------------------------------------------------------
function LogAnalysis.GetSummary()
	local total = #LogAnalysis.allEntries;
	local filtered = #LogAnalysis.filteredEntries;
	if total == 0 then
		return L"未加载日志文件";
	end
	local file = LogAnalysis.currentFile or "";
	return string.format(L"文件: %s | 共 %d 条 | 显示 %d 条 | D:%d I:%d W:%d E:%d",
		file, total, filtered,
		LogAnalysis.totalDebug, LogAnalysis.totalInfo, LogAnalysis.totalWarn, LogAnalysis.totalError);
end

function LogAnalysis.IsFilterActive(level)
	return LogAnalysis.filterLevel == level;
end

function LogAnalysis.GetFilterBtnStyle(level)
	if LogAnalysis.filterLevel == level then
		return "width:60px;height:24px;font-size:12px;color:#ffffff;background-color:#446688;";
	else
		return "width:60px;height:24px;font-size:12px;color:#aaaaaa;";
	end
end

-----------------------------------------------------------------------
-- Truncate long lines for display
-----------------------------------------------------------------------
function LogAnalysis.TruncateLine(text, maxLen)
	maxLen = maxLen or 120;
	if not text then return ""; end
	if #text > maxLen then
		return string.sub(text, 1, maxLen) .. "...";
	end
	return text;
end
