--[[
Title: CalendarModel
Author(s): auto
Date: 2026/07/07
Desc: 日历日期计算模型（v1 kp:calendar 与 v2 kp:calendar 共用）。
      纯数据、无 UI 依赖，O(1) 计算月首星期，O(rows*7) 单趟填充网格，无冗余分支/无死代码。
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/keepwork/CalendarModel.lua");
local CalendarModel = commonlib.gettable("MyCompany.Aries.Game.mcml.CalendarModel");
local cells, rows = CalendarModel.build(2026, 7, 6);
-- cells[i] = { day = <1..31>, monthOffset = -1|0|1 }  (0 表示当前月)
------------------------------------------------------------
]]

local CalendarModel = commonlib.gettable("MyCompany.Aries.Game.mcml.CalendarModel");

-- 每月天数查表（平年），二月单独处理闰年
local MONTH_DAYS = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};

function CalendarModel.isLeapYear(year)
	return year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0);
end

-- 获取该月天数
function CalendarModel.getDaysInMonth(year, month)
	if (month == 2 and CalendarModel.isLeapYear(year)) then
		return 29;
	end
	return MONTH_DAYS[month];
end

-- 该月 1 号是星期几：0=周日 .. 6=周六。基于泽勒公式，O(1)。
function CalendarModel.getStartWeekday(year, month)
	local y, m = year, month;
	if (m < 3) then
		m = m + 12;
		y = y - 1;
	end
	local k = y % 100;
	local j = math.floor(y / 100);
	-- 泽勒公式（h: 0=周六 .. 6=周五）；用 5*j 等价于 -2*j (mod 7) 以避免负数
	local h = (1 + math.floor(13 * (m + 1) / 5) + k + math.floor(k / 4) + math.floor(j / 4) + 5 * j) % 7;
	-- 转换为 0=周日 .. 6=周六
	return (h + 6) % 7;
end

-- 上一个月的 (year, month)
local function prevMonthOf(year, month)
	if (month == 1) then
		return year - 1, 12;
	end
	return year, month - 1;
end

-- 星期短名，按星期几 0..6 (周日..周六) 索引 1..7
CalendarModel.WEEKDAY_NAMES = {"日", "一", "二", "三", "四", "五", "六"};

-- 归一化每周起始：0=周日为第一列(默认)，1=周一为第一列(此时周日排在最后一列)
local function normWeekStart(weekStart)
	return (tonumber(weekStart) == 1) and 1 or 0;
end

-- 按每周起始返回一行星期短名（供 UI 表头使用）。
-- @param weekStart: 0=周日打头 {"日","一"..."六"}；1=周一打头 {"一"..."六","日"}
function CalendarModel.getWeekdayLabels(weekStart)
	weekStart = normWeekStart(weekStart);
	local labels = {};
	for i = 1, 7 do
		local wd = (weekStart + i - 1) % 7;   -- 该列对应的星期几(0..6)
		labels[i] = CalendarModel.WEEKDAY_NAMES[wd + 1];
	end
	return labels;
end

-- 构建日历网格。
-- @param year, month: 目标年月
-- @param numRows: 可选，固定行数（如 6，高度稳定）；缺省时按当月实际需要 4~6 行
-- @param weekStart: 可选，每周第一列是星期几：0=周日(默认)，1=周一(周日排在最后一列)
-- @return cells: 数组，cells[i] = { day = <1..31>, monthOffset = -1|0|1 }，从左到右、从上到下排列
-- @return rows: 实际行数
function CalendarModel.build(year, month, numRows, weekStart)
	weekStart = normWeekStart(weekStart);
	local startWeekday = CalendarModel.getStartWeekday(year, month);   -- 当月 1 号是星期几(0..6)
	local daysInMonth = CalendarModel.getDaysInMonth(year, month);
	local prevYear, prevMonth = prevMonthOf(year, month);
	local prevDays = CalendarModel.getDaysInMonth(prevYear, prevMonth);

	-- 当月 1 号前需要留出的空格数（随每周起始列变化）
	local leading = (startWeekday - weekStart + 7) % 7;
	local rows = numRows or math.ceil((leading + daysInMonth) / 7);

	local cells = {};
	for i = 1, rows * 7 do
		-- offset 为该格在当月中的“天序号”，<1 表示上月，>daysInMonth 表示下月
		local offset = i - leading;
		if (offset < 1) then
			cells[i] = { day = prevDays + offset, monthOffset = -1 };
		elseif (offset > daysInMonth) then
			cells[i] = { day = offset - daysInMonth, monthOffset = 1 };
		else
			cells[i] = { day = offset, monthOffset = 0 };
		end
	end
	return cells, rows;
end

-- 今天的 (year, month, day)，用于高亮
function CalendarModel.getToday()
	return tonumber(os.date("%Y")), tonumber(os.date("%m")), tonumber(os.date("%d"));
end
