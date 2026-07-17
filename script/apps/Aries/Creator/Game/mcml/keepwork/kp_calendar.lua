-- 日期计算已抽取到共用模型 CalendarModel（O(1) 算月首星期，单趟填充网格，无死代码）
NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/keepwork/CalendarModel.lua");
local CalendarModel = commonlib.gettable("MyCompany.Aries.Game.mcml.CalendarModel");

local COL, ROW = 7, 6

-- 打印日历（调试用）
local function printMonthCalendar(year, month)
    local weekdays = {"日", "一", "二", "三", "四", "五", "六"}
    local cells = CalendarModel.build(year, month, ROW)

    print(table.concat(weekdays, " "))
    for i = 1, ROW do
        local str = ""
        for j = 1, COL do
            local cell = cells[(i - 1) * COL + j]
            if cell.monthOffset == 0 then
                str = str .. string.format("%3d ", cell.day)
            else
                str = str .. string.format("[%d] ", cell.day)
            end
        end
        print(str)
    end
end

local function CalculateFont(css)
	local font;
	if(css and (css["font-family"] or css["font-size"] or css["font-weight"]))then
		local font_family = css["font-family"] or "System";
		-- this is tricky. we convert font size to integer, and we will use scale if font size is either too big or too small. 
		local font_size = math.floor(tonumber(css["font-size"] or 12));
		local font_weight = css["font-weight"] or "norm";
		font = string.format("%s;%d;%s", font_family, font_size, font_weight);
	end
	return font;
end

--[[
    -- 简单的日历控件
    -- 注意事项：year_value必须是整数，且范围是 大于 1970
    -- 注意事项：如果需要设置年份和月份的初始值，请在初始化时设置 year_value 和 month_value 的值，否则默认使用当前年份和月份
    -- 如果需要动态刷新日历，请参照下面的示例，使用全局方法来刷新日历；如果使用类对象，可能会出现数据改变了，但是获取的数据没变化的bug
    -- 示例：
    --params:
        year_value: 初始年份
        month_value: 初始月份
        on_preyear: 点击上一年的回调方法
        on_nextyear: 点击下一年的回调方法
        on_premonth: 点击上一月的回调方法
        on_nextmonth: 点击下一月的回调方法
        on_click_day: 点击某一天的回调方法
        week_start: 每周起始列 0=周日打头(默认)，1=周一打头(周日排在最后一列)
    -- 运行时动态切换周起始列：MyCompany.Aries.Game.mcml.kp_calendar.SetWeekStart(mcmlNode, 0/1)
    --   （mcmlNode 可从 on_click_day 等回调的第二个参数取得，或 page:GetNode(name) 取得）
    -- example:
    <kp:calendar 
        year_value="<%=GetCurrYear()%>" 
        month_value="<%=GetCurrMonth()%>" 
        on_preyear="OnClickPreYear" 
        on_nextyear="OnClickNextYear" 
        on_premonth="OnClickPreMonth" 
        on_nextmonth="OnClickNextMonth" 
        on_click_day="OnClickDay"  
        style="width: 200px; 
        height: 200px; 
        background: url(Texture/Aries/Creator/paracraft/Educate/shurukuang_46x46_32bits.png#0 0 46 46: 20 20 20 20);">
    </kp:calendar>
]]

local kp_calendar = commonlib.gettable("MyCompany.Aries.Game.mcml.kp_calendar");

function kp_calendar.render_callback(mcmlNode, rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)
    kp_calendar.create_default(rootName, mcmlNode, bindingContext, _parent, left, top, right, bottom, myLayout, css);
    return true, true, true;
end

function kp_calendar.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
    return mcmlNode:DrawDisplayBlock(rootName, bindingContext, _parent, left, top, width, height, parentLayout, style, kp_calendar.render_callback);
end

function kp_calendar.create_default(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, parentLayout,css)
    local uiname = mcmlNode:GetAttributeWithCode("uiname", nil, true)
    local offsety = mcmlNode:GetNumber("offsety") or 2
    local year,month
    year = mcmlNode:GetAttributeWithCode("year_value",nil,true) or os.date("%Y");
    year = tonumber(year)

    month = mcmlNode:GetAttributeWithCode("month_value",nil,true) or os.date("%m");
    month = tonumber(month)

    local padding = css.padding or 2

    -- 每周起始列：0=周日打头(默认)，1=周一打头(周日排在最后一列)
    local weekStart = tonumber(mcmlNode:GetAttributeWithCode("week_start", nil, true)) or 0

    local min_width = 140
    local min_height = 160
    local w = mcmlNode:GetNumber("width") or (width-left);
    if css.width then
        w = css.width
    end
    local default_height = mcmlNode:GetNumber("height")
    local h = default_height or (height-top);
    if css.height then
        h = css.height
    end

    h = math.max(h, min_height)
    w = math.max(w, min_width)

    -- 用每个节点唯一且稳定的实例名做容器名（参考 pe_design.lua 的 GetInstanceName 用法）。
    -- 不能再用固定的 "calendar_container"：同一页面有多个日历时会重名，
    -- 导致后一个日历渲染时把前一个日历的容器（同名）销毁掉，第一个日历就显示异常。
    local calendar_container_name = uiname or mcmlNode:GetInstanceName(rootName)
    -- 原地重绘前销毁本节点上一次渲染留下的旧容器（原代码误用了字符串字面量 "calendar_container_name"，从未真正销毁）
    local calendar_container = ParaUI.GetUIObject(calendar_container_name)
    if calendar_container:IsValid() then
        ParaUI.DestroyUIObject(calendar_container)
    end

    local _this = ParaUI.CreateUIObject("container", calendar_container_name, "_lt", left, top, w, h);
	_this.background = css.background or "";
	_parent:AddChild(_this);
    mcmlNode:SetObjId(_this.id);

    -- 把重建日历内容所需的参数存在节点上，供 SetWeekStart 原地重建复用
    mcmlNode._calendarState = {
        container_id = _this.id,
        w = w, h = h, offsety = offsety, padding = padding, css = css,
        year = year, month = month, weekStart = weekStart,
        onpreyear = mcmlNode:GetString("on_preyear"),
        onpremonth = mcmlNode:GetString("on_premonth"),
        onnextyear = mcmlNode:GetString("on_nextyear"),
        onnextmonth = mcmlNode:GetString("on_nextmonth"),
        clickday = mcmlNode:GetString("on_click_day"),
    }

    kp_calendar.buildContent(mcmlNode, _this)
end

-- 在指定容器内创建日历内容（表头 + 星期 + 日期格）。
-- 抽出这层是为了 SetWeekStart 能复用它做原地重建（清空容器再重新创建），
-- 而不必销毁并重建外层容器。所有绘制参数从 mcmlNode._calendarState 读取。
-- @param mcmlNode: kp:calendar 的节点
-- @param container: 外层容器 ParaUI 对象
function kp_calendar.buildContent(mcmlNode, container)
    local st = mcmlNode._calendarState
    if (not st) then return end

    local w, h, offsety, padding, css = st.w, st.h, st.offsety, st.padding, st.css
    local year, month, weekStart = st.year, st.month, st.weekStart

    local col, row = COL, ROW
    local single_w = (w - padding * 2) / col
    local single_h = (h - padding * 2 - offsety - 32) / row
    local fontstr = CalculateFont(css) or "System;12;norm"
    local cells = CalendarModel.build(year, month, ROW, weekStart)

    local headerX = w/2 - 70
    local _header = ParaUI.CreateUIObject("container","calendar_header","_lt",headerX,offsety,140,20)
    _header.background = "";
    container:AddChild(_header)

    --创建显示年份
    local startx = 0
    local preYearbtn = ParaUI.CreateUIObject("button","pre_year","_lt",startx,offsety,16,16)
    preYearbtn.background = "Texture/Aries/Creator/keepwork/Window/arrow_left_32bits.png";
    preYearbtn:SetScript("onclick",function()
        Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, st.onpreyear, "pre_year", mcmlNode)
    end)
    _header:AddChild(preYearbtn)

    local yearLabel = ParaUI.CreateUIObject("text","year_label","_lt",startx+18,offsety,32,16)
    yearLabel.text = string.format("%d", year)
    yearLabel.font = fontstr
    _guihelper.SetUIFontFormat(yearLabel, 5);
    _header:AddChild(yearLabel)

    local nextYearbtn = ParaUI.CreateUIObject("button","next_year","_lt",startx + 54,offsety,16,16)
    nextYearbtn.background = "Texture/Aries/Creator/keepwork/Window/arrow_right_32bits.png";
    nextYearbtn:SetScript("onclick",function()
        Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, st.onnextyear, "next_year", mcmlNode)
    end)
    _header:AddChild(nextYearbtn)

    -- --显示月份
    startx = 80
    local preMonthbtn = ParaUI.CreateUIObject("button","pre_month","_lt",startx,offsety,16,16)
    preMonthbtn.background = "Texture/Aries/Creator/keepwork/Window/arrow_left_32bits.png";
    preMonthbtn:SetScript("onclick",function()
        Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, st.onpremonth, "pre_month", mcmlNode)
    end)
    _header:AddChild(preMonthbtn)

    local MonthLabel = ParaUI.CreateUIObject("text","month_label","_lt",startx+16,offsety,16,16)
    MonthLabel.text = string.format("%d",month)
    MonthLabel.font = fontstr
    _guihelper.SetUIFontFormat(MonthLabel, 5);
    _header:AddChild(MonthLabel)

    local nextMonthbtn = ParaUI.CreateUIObject("button","next_month","_lt",startx + 34,offsety,16,16)
    nextMonthbtn.background = "Texture/Aries/Creator/keepwork/Window/arrow_right_32bits.png";
    nextMonthbtn:SetScript("onclick",function()
        Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, st.onnextmonth, "next_month", mcmlNode)
    end)
    _header:AddChild(nextMonthbtn)

    --显示星期
    local weekday = CalendarModel.getWeekdayLabels(weekStart)
    for i = 1, col do
        local weekdayLabel = ParaUI.CreateUIObject("text","weekday_label_"..i,"_lt", (i-1)*single_w,offsety + 16 + 2,single_w,16)
        weekdayLabel.text = weekday[i]
        weekdayLabel.font = fontstr
        _guihelper.SetUIFontFormat(weekdayLabel, 5);
        container:AddChild(weekdayLabel)
    end

    local startY = offsety + 16 +16
    --显示日期
    local fontSize = math.floor(math.min(12, single_w))
    for i = 1, row do
        for j = 1, col do
            local cell = cells[(i - 1) * col + j]
            local day = cell.day
            local isCurrentMonth = cell.monthOffset == 0
            local buttonName = year.."-"..month.."-"..day
            local calendarBtn = ParaUI.CreateUIObject("button",buttonName,"_lt", (j-1)*single_w,startY + (i-1)*single_h,single_w,single_h)
            calendarBtn.background=""
            calendarBtn.font = "System;"..fontSize..";norm"
            calendarBtn.text = string.format("%d",day)
            container:AddChild(calendarBtn)

            if isCurrentMonth then
                calendarBtn:SetScript("onclick",function()
                    Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, st.clickday, buttonName, mcmlNode)
                end)
            else
                _guihelper.SetButtonFontColor(calendarBtn, "#dcdcdc");
                calendarBtn.enabled = false
            end
        end
    end
end

-- 运行时动态切换每周起始列（0=周日打头，1=周一打头/周日在最后一列）。
-- 只清空外层容器里的日历内容再重建，
-- 不销毁外层容器。用法：在日历任意回调里可拿到 mcmlNode（如 on_click_day 的第二个参数），
-- 或用 page:GetNode(name) 取节点，然后调用 kp_calendar.SetWeekStart(mcmlNode, 0/1)。
function kp_calendar.SetWeekStart(mcmlNode, weekStart)
    local st = mcmlNode and mcmlNode._calendarState
    if (not st) then return end
    weekStart = (tonumber(weekStart) == 1) and 1 or 0
    if (st.weekStart == weekStart) then return end   -- 没变化不重建

    st.weekStart = weekStart
    local container = ParaUI.GetUIObject(st.container_id)
    if (container:IsValid()) then
        container:RemoveAll()                        -- 删除现有 UI
        kp_calendar.buildContent(mcmlNode, container) -- 重新创建
    end
end

-- 读取当前每周起始列（运行时值优先，否则取属性，默认 0）
function kp_calendar.GetWeekStart(mcmlNode)
    local st = mcmlNode and mcmlNode._calendarState
    if (st) then
        return st.weekStart
    end
    return tonumber(mcmlNode and mcmlNode:GetAttributeWithCode("week_start", nil, true)) or 0
end



