-- 根据泽勒公式计算出该月的第一天是星期几
local function getStartDay(year, month)
    if month < 3 then
        month = month + 12
        year = year - 1
    end
    local century = math.floor(year / 100)
    local yearOfCentury = year % 100
    local startDay = (1 + math.floor((13 * (month + 1)) / 5) + yearOfCentury + math.floor(yearOfCentury / 4) + math.floor(century / 4) - 2 * century) % 7
    return (startDay + 6) % 7  -- 转换为星期天（0）到星期六（6）的表示
end

-- 获取该月的天数
local function getDaysInMonth(year, month)
    if month == 2 then
        if year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0) then
            return 29  -- 闰年的二月有29天
        else
            return 28
        end
    elseif month == 4 or month == 6 or month == 9 or month == 11 then
        return 30
    else
        return 31
    end
end

-- 构建日历数据
local function buildCalendarData(year, month)
    local startDay = getStartDay(year, month)
    local daysInMonth = getDaysInMonth(year, month)

    local calendarData = {}
    local day = 1
    local currentDayOfWeek = startDay

    -- 填充上个月的日期
    local prevMonth = month - 1
    local prevYear = year
    if prevMonth == 0 then
        prevMonth = 12
        prevYear = year - 1
    end
    local prevMonthDays = getDaysInMonth(prevYear, prevMonth)
    for i = 1, 6 do
        calendarData[i] = {}
        for j = 1, 7 do
            if (i == 1 and j <= startDay) then
                calendarData[i][j] = {day = prevMonthDays - startDay + j, isCurrentMonth = false}
            elseif day > daysInMonth then
                --day = 1
                calendarData[i][j] = {day = day - daysInMonth, isCurrentMonth = false}
                day = day + 1
            else
                calendarData[i][j] = {day = day, isCurrentMonth = true}
                day = day + 1
            end
            currentDayOfWeek = (currentDayOfWeek + 1) % 7
        end
    end

    return calendarData
end

-- 打印日历
local function printMonthCalendar(year, month)
    local weekdays = {"日", "一", "二", "三", "四", "五", "六"}
    local calendarData = buildCalendarData(year, month)

    -- 打印星期标题
    local header = table.concat(weekdays, " ")
    print(header)

    -- 打印日历内容
    for i = 1, 6 do
        local str = ""
        for j = 1, 7 do
            local day = calendarData[i][j].day
            local isCurrentMonth = calendarData[i][j].isCurrentMonth
            if isCurrentMonth then
                str = str ..(string.format("%3d ", day))
            else
                str = str ..(string.format("[%d] ", day))
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
    local offsetx = mcmlNode:GetNumber("offsetx") or 6
    local offsety = mcmlNode:GetNumber("offsety") or 2
    local year,month
    year = mcmlNode:GetAttributeWithCode("year_value",nil,true) or os.date("%Y");
    year = tonumber(year)

    month = mcmlNode:GetAttributeWithCode("month_value",nil,true) or os.date("%m");
    month = tonumber(month)

    local padding = css.padding or 2
    local onpreyear = mcmlNode:GetString("on_preyear");
    local onpremonth = mcmlNode:GetString("on_premonth");
    local onnextyear = mcmlNode:GetString("on_nextyear");
    local onnextmonth = mcmlNode:GetString("on_nextmonth");
    local clickday = mcmlNode:GetString("on_click_day");

    local calendarData = buildCalendarData(year,month)
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

    local calendar_container_name = uiname or "calendar_container"
    local calendar_container = ParaUI.GetUIObject("calendar_container_name")
    if calendar_container:IsValid() then
        ParaUI.DestroyUIObject(calendar_container)
    end

   
    local _this = ParaUI.CreateUIObject("container", calendar_container_name, "_lt", left, top, w, h);
	_this.background = css.background or "";
	_parent:AddChild(_this);
    mcmlNode:SetObjId(_this.id);

    local col,row = 7,6
    local single_w = (w - padding * 2) / col
    local single_h = (h - padding * 2 - offsety - 32) / row

    local fontstr = CalculateFont(css) or "System;12;norm"
    
    local headerX = w/2 - 70
    local _header = ParaUI.CreateUIObject("container","calendar_container","_lt",headerX,offsety,140,20)
    _header.background = "";
    _this:AddChild(_header)

    --创建显示年份
    local startx = 0
    local preYearbtn = ParaUI.CreateUIObject("button","pre_year","_lt",startx,offsety,16,16)
    preYearbtn.background = "Texture/Aries/Creator/keepwork/Window/arrow_left_32bits.png";
    -- preYearbtn.text = "<"
    preYearbtn:SetScript("onclick",function()
        Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onpreyear, "pre_year", mcmlNode)
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
        Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onnextyear, "next_year", mcmlNode)
    end)
    -- nextYearbtn.text = ">"
    _header:AddChild(nextYearbtn)

    -- --显示月份
    startx = 80
    local preMonthbtn = ParaUI.CreateUIObject("button","pre_month","_lt",startx,offsety,16,16)
    preMonthbtn.background = "Texture/Aries/Creator/keepwork/Window/arrow_left_32bits.png";
    -- preMonthbtn.text = "<"
    preMonthbtn:SetScript("onclick",function()
        Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onpremonth, "pre_month", mcmlNode)
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
        Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onnextmonth, "next_month", mcmlNode)
    end)
    _header:AddChild(nextMonthbtn)

    --显示星期
    local weekday = {"日","一","二","三","四","五","六"}
    for i = 1, col do
        local weekdayLabel = ParaUI.CreateUIObject("text","weekday_label_"..i,"_lt", (i-1)*single_w,offsety + 16 + 2,single_w,16)
        weekdayLabel.text = weekday[i]
        weekdayLabel.font = fontstr
        _guihelper.SetUIFontFormat(weekdayLabel, 5);
        _this:AddChild(weekdayLabel)
    end
    
    local startY = offsety + 16 +16
    --显示日期
    local fontSize = math.floor(math.min(12, single_w))
    for i = 1, row do
        for j = 1, col do
            local day = calendarData[i][j].day
            local isCurrentMonth = calendarData[i][j].isCurrentMonth
            local buttonName = year.."-"..month.."-"..day
            local calendarBtn = ParaUI.CreateUIObject("button",buttonName,"_lt", (j-1)*single_w,startY + (i-1)*single_h,single_w,single_h)
            calendarBtn.background=""
            calendarBtn.font = "System;"..fontSize..";norm"
            calendarBtn.text = string.format("%d",day)
            _this:AddChild(calendarBtn)
            
            if isCurrentMonth then
                calendarBtn:SetScript("onclick",function()
                    Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, clickday, buttonName, mcmlNode)
                end)
            else
                _guihelper.SetButtonFontColor(calendarBtn, "#dcdcdc");
                calendarBtn.enabled = false
            end
        end
    end
end



