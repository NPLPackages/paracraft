--[[
Title: kp:calendar (mcml v2)
Author(s): auto
Date: 2026/07/07
Desc: 简单日历控件的 mcml v2 版本。
      - 复用 System.Windows.Controls.Button 子控件池：控件只创建一次，切换月份仅更新文字/颜色/回调，不销毁重建；
      - 日期计算复用共用模型 CalendarModel（O(1) 算月首星期，单趟填充）；
      - 固定 6 行，控件高度稳定，切换月份不跳动；
      - 支持内部导航（点箭头自更新）并同时回调宿主页面事件，也可由宿主用 SetYearMonth 主动驱动。

    params:
        year_value:    初始年份（默认当前年）
        month_value:   初始月份（默认当前月）
        week_start:    每周起始列 0=周日打头(默认)，1=周一打头(周日排在最后一列)；也可运行时调 SetWeekStart 动态切换
        on_preyear/on_nextyear/on_premonth/on_nextmonth: 切换年/月的回调，签名 function(year, month, self) end
        on_click_day:  点击某天的回调，签名 function(buttonName, self) end，buttonName 形如 "2026-7-15"

    example:
        <kp:calendar year_value="<%=GetCurrYear()%>" month_value="<%=GetCurrMonth()%>"
            on_premonth="OnClickPreMonth" on_nextmonth="OnClickNextMonth" on_click_day="OnClickDay"
            style="width: 200px; height: 200px;
            background: url(Texture/Aries/Creator/paracraft/Educate/shurukuang_46x46_32bits.png#0 0 46 46: 20 20 20 20);">
        </kp:calendar>

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/mcml2/keepwork/kp_calendar.lua");
MyCompany.Aries.Game.mcml2.kp_calendar:RegisterAs("kp:calendar");
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Windows/mcml/PageElement.lua");
NPL.load("(gl)script/ide/System/Windows/Shapes/Rectangle.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/Button.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/keepwork/CalendarModel.lua");
local Button = commonlib.gettable("System.Windows.Controls.Button");
local Rectangle = commonlib.gettable("System.Windows.Shapes.Rectangle");
local CalendarModel = commonlib.gettable("MyCompany.Aries.Game.mcml.CalendarModel");

local kp_calendar = commonlib.inherit(commonlib.gettable("System.Windows.mcml.PageElement"), commonlib.gettable("MyCompany.Aries.Game.mcml2.kp_calendar"));
kp_calendar:Property({"class_name", "kp:calendar"});

local COL, ROW = 7, 6;
local MIN_WIDTH, MIN_HEIGHT = 140, 160;
local ARROW_LEFT = "Texture/Aries/Creator/keepwork/Window/arrow_left_32bits.png";
local ARROW_RIGHT = "Texture/Aries/Creator/keepwork/Window/arrow_right_32bits.png";

local COLOR_CUR = "#212121";      -- 当前月日期（近黑，保证在浅色背景上清晰）
local COLOR_OTHER = "#a0a0a0";    -- 上/下月日期（中灰，弱化但仍可见）
local COLOR_TODAY = "#1565ff";    -- 今天
local COLOR_HEADER = "#555555";   -- 年/月、星期表头

function kp_calendar:ctor()
	self.year = nil;
	self.month = nil;
	self.dayButtons = nil;        -- 42 个日期按钮的复用池
	self.weekdayLabels = nil;
end

function kp_calendar:LoadComponent(parentElem, parentLayout, style)
	local _this = self.control;
	if (not _this) then
		_this = Rectangle:new():init(parentElem);
		self:SetControl(_this);
	else
		_this:SetParent(parentElem);
	end
	kp_calendar._super.LoadComponent(self, _this, parentLayout, style);
end

function kp_calendar:OnLoadComponentBeforeChild(parentElem, parentLayout, css)
	-- 容器背景
	local bg = css.background or self:GetAttribute("background");
	if (bg) then
		parentElem:SetBackground(bg);
	end
	if (css["background-color"]) then
		parentElem:SetBackgroundColor(css["background-color"]);
	end

	-- 读取回调名（只读一次）
	self.on_preyear = self:GetString("on_preyear");
	self.on_nextyear = self:GetString("on_nextyear");
	self.on_premonth = self:GetString("on_premonth");
	self.on_nextmonth = self:GetString("on_nextmonth");
	self.on_click_day = self:GetString("on_click_day");

	self.offsety = self:GetNumber("offsety") or 2;
	self.padding = css.padding or 2;
	self.font = self:CalculateFont(css) or "System;12;norm";

	-- 每周起始列：0=周日打头(默认)，1=周一打头(周日排在最后一列)
	self.weekStart = tonumber(self:GetAttributeWithCode("week_start", nil, true)) or 0;

	-- 初始年月
	local year = tonumber(self:GetAttributeWithCode("year_value", nil, true) or os.date("%Y"));
	local month = tonumber(self:GetAttributeWithCode("month_value", nil, true) or os.date("%m"));

	-- 只创建一次子控件，随后复用
	if (not self.dayButtons) then
		self:BuildControls(parentElem);
	end

	self:SetYearMonth(year, month);

	kp_calendar._super.OnLoadComponentBeforeChild(self, parentElem, parentLayout, css);
end

-- 一次性创建全部子控件（导航按钮、年/月标签、星期标题、42 个日期按钮）
function kp_calendar:BuildControls(container)
	-- 导航按钮
	self.btnPreYear = self:NewIconButton(container, ARROW_LEFT, function() self:AddYears(-1); end);
	self.btnNextYear = self:NewIconButton(container, ARROW_RIGHT, function() self:AddYears(1); end);
	self.btnPreMonth = self:NewIconButton(container, ARROW_LEFT, function() self:AddMonths(-1); end);
	self.btnNextMonth = self:NewIconButton(container, ARROW_RIGHT, function() self:AddMonths(1); end);

	-- 年/月标签
	self.labelYear = self:NewLabel(container);
	self.labelMonth = self:NewLabel(container);

	-- 星期标题（文字在 UpdateCalendar 里按 weekStart 设置，支持动态切换）
	self.weekdayLabels = {};
	for i = 1, COL do
		self.weekdayLabels[i] = self:NewLabel(container);
	end

	-- 日期按钮池
	self.dayButtons = {};
	for i = 1, ROW * COL do
		local btn = Button:new():init(container);
		btn:SetPolygonStyle("none");
		btn:SetFont(self.font);
		btn.padding_left, btn.padding_top, btn.padding_right, btn.padding_bottom = 0, 0, 0, 0;
		btn:Connect("clicked", self, function() self:OnDayClicked(i); end, "UniqueConnection");
		self.dayButtons[i] = btn;
	end
end

-- 无点击的文字标签（用 polygon=none 的 Button 承载居中文字）
-- 注意：不要设 enabled=false —— 引擎会把禁用控件的文字置灰/透明，导致看不清；
--       标签只是不连接 clicked 信号即可，保持 enabled 才能正常显示颜色。
function kp_calendar:NewLabel(container)
	local label = Button:new():init(container);
	label:SetPolygonStyle("none");
	label:SetFont(self.font);
	label:SetColor(COLOR_HEADER);
	label.padding_left, label.padding_top, label.padding_right, label.padding_bottom = 0, 0, 0, 0;
	return label;
end

-- 背景为箭头图标的导航按钮
function kp_calendar:NewIconButton(container, iconBg, onClick)
	local btn = Button:new():init(container);
	btn:SetPolygonStyle("none");
	btn:SetBackground(iconBg);
	btn:Connect("clicked", self, onClick, "UniqueConnection");
	return btn;
end

-- 由 css 计算字体字符串
function kp_calendar:CalculateFont(css)
	if (css and (css["font-family"] or css["font-size"] or css["font-weight"])) then
		local family = css["font-family"] or "System";
		local size = math.floor(tonumber(css["font-size"] or 12));
		local weight = css["font-weight"] or "norm";
		return string.format("%s;%d;%s", family, size, weight);
	end
end

-- 公共接口：设置年月并刷新（不重建控件）
function kp_calendar:SetYearMonth(year, month)
	self.year, self.month = year, month;
	self:UpdateCalendar();
end

-- 公共接口：动态切换每周起始列（0=周日打头，1=周一打头/周日在最后一列），仅刷新不重建
function kp_calendar:SetWeekStart(weekStart)
	self.weekStart = (tonumber(weekStart) == 1) and 1 or 0;
	self:UpdateCalendar();
end

-- 仅在回调名非空时触发页面事件，避免空回调刷警告
function kp_calendar:FirePageEvent(handler, ...)
	if (handler and handler ~= "") then
		self:DoPageEvent(handler, ...);
	end
end

function kp_calendar:AddYears(delta)
	self.year = self.year + delta;
	self:UpdateCalendar();
	self:FirePageEvent(delta < 0 and self.on_preyear or self.on_nextyear, self.year, self.month, self);
end

function kp_calendar:AddMonths(delta)
	local m = self.month + delta;
	if (m < 1) then
		m = 12; self.year = self.year - 1;
	elseif (m > 12) then
		m = 1; self.year = self.year + 1;
	end
	self.month = m;
	self:UpdateCalendar();
	self:FirePageEvent(delta < 0 and self.on_premonth or self.on_nextmonth, self.year, self.month, self);
end

-- 用当前 year/month 刷新标签与日期按钮（复用控件，仅改文字/颜色/状态）
function kp_calendar:UpdateCalendar()
	if (not self.dayButtons) then return end
	local year, month = self.year, self.month;

	self.labelYear:SetText(tostring(year));
	self.labelMonth:SetText(tostring(month));

	-- 按 weekStart 刷新星期表头
	local weekLabels = CalendarModel.getWeekdayLabels(self.weekStart);
	for i = 1, COL do
		self.weekdayLabels[i]:SetText(weekLabels[i]);
	end

	local cells = CalendarModel.build(year, month, ROW, self.weekStart);
	local todayY, todayM, todayD = CalendarModel.getToday();

	for i = 1, ROW * COL do
		local cell = cells[i];
		local btn = self.dayButtons[i];
		btn:SetText(tostring(cell.day));
		-- 用 dayName 是否为空来控制“是否可点”，而不是用 enabled（enabled=false 会让引擎把文字置灰/看不清）
		if (cell.monthOffset == 0) then
			btn.dayName = string.format("%d-%d-%d", year, month, cell.day);
			if (year == todayY and month == todayM and cell.day == todayD) then
				btn:SetColor(COLOR_TODAY);
			else
				btn:SetColor(COLOR_CUR);
			end
		else
			btn.dayName = nil;
			btn:SetColor(COLOR_OTHER);
		end
	end
end

function kp_calendar:OnDayClicked(index)
	local btn = self.dayButtons and self.dayButtons[index];
	-- 只有当前月的格子有 dayName，其它月的格子点击忽略
	if (btn and btn.dayName) then
		self:FirePageEvent(self.on_click_day, btn.dayName, self);
	end
end

-- 布局：容器尺寸确定后，按容器内相对坐标摆放所有子控件
function kp_calendar:LayoutControls(w, h)
	local padding, offsety = self.padding, self.offsety;
	local single_w = (w - padding * 2) / COL;
	local single_h = (h - padding * 2 - offsety - 32) / ROW;

	-- 头部：年 [<] 年份 [>]    月 [<] 月份 [>]
	local headerX = w / 2 - 70;
	self.btnPreYear:setGeometry(headerX, offsety, 16, 16);
	self.labelYear:setGeometry(headerX + 18, offsety, 36, 16);
	self.btnNextYear:setGeometry(headerX + 54, offsety, 16, 16);
	self.btnPreMonth:setGeometry(headerX + 80, offsety, 16, 16);
	self.labelMonth:setGeometry(headerX + 96, offsety, 16, 16);
	self.btnNextMonth:setGeometry(headerX + 114, offsety, 16, 16);

	-- 星期标题行
	local weekY = offsety + 18;
	for i = 1, COL do
		self.weekdayLabels[i]:setGeometry((i - 1) * single_w, weekY, single_w, 16);
	end

	-- 日期网格
	local fontSize = math.floor(math.min(12, single_w));
	local dayFont = "System;" .. fontSize .. ";norm";
	local startY = offsety + 32;
	for i = 1, ROW do
		for j = 1, COL do
			local btn = self.dayButtons[(i - 1) * COL + j];
			btn:SetFont(dayFont);
			btn:setGeometry((j - 1) * single_w, startY + (i - 1) * single_h, single_w, single_h);
		end
	end
end

function kp_calendar:OnBeforeChildLayout(layout)
	-- 无 mcml 子节点，尺寸由 css/属性决定，直接放行
	return true;
end

function kp_calendar:OnAfterChildLayout(layout, left, top, right, bottom)
	if (not self.control) then return end
	local w = math.max(right - left, MIN_WIDTH);
	local h = math.max(bottom - top, MIN_HEIGHT);
	self.control:setGeometry(left, top, w, h);
	self:LayoutControls(w, h);
end
