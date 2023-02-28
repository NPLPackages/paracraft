--[[
Title: UserClassChange
Author(s): pbb
Date: 2022/9/20
Desc:  
Use Lib:
-------------------------------------------------------
local UserClassChange = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/UserClassChange.lua");
UserClassChange.GetGradeValue(grade)
UserClassChange.ShowPage();
--]]

local UserClassChange = NPL.export()
local page
UserClassChange.years = {}
UserClassChange.curYearStr = "" --年级
UserClassChange.curClassStr = "" --班级
UserClassChange.curLearnYearStr = "" --入学年份
UserClassChange.ClassOptions = {
    {text= "一年级", value = "1"},
    {text= "二年级", value ="2"},
    {text= "三年级", value ="3"},
    {text= "四年级", value ="4"},
    {text= "五年级", value ="5"},
    {text= "六年级", value ="6"},
    {text= "七年级", value ="7"},
    {text= "八年级", value ="8"},
    {text= "九年级", value ="9"},
    {text= "高一", value ="10"},
    {text= "高二", value ="11"},
    {text= "高三", value ="12"},
    {text= "往届学生", value ="13"},
    {text= "教师", value ="14"},
}

local closeFunc

function UserClassChange.OnInit()
    page = document:GetPageCtrl();
    if page then
        page.OnCreate = UserClassChange.OnCreate
    end
end

function UserClassChange.OnCreate()
    if page then
        page:SetValue("classOption", UserClassChange.curYearStr) -- 分辨率	
        page:SetValue("enterYears", UserClassChange.curLearnYearStr) -- 分辨率	
        page:SetValue("class_number",UserClassChange.curClassStr)
    end
end

function UserClassChange.ShowPage(classInfo,closefunc)
    closeFunc = closefunc
    local curYear = os.date("*t").year
    for i = 1, 50 do
        local yearstr =  curYear - i + 1
        UserClassChange.years[i] = {text=tostring(yearstr),value = yearstr}
    end
    UserClassChange.curYearStr = ""
    UserClassChange.curClassStr = ""
    UserClassChange.curLearnYearStr = ""
    if classInfo then
        UserClassChange.curClassStr = classInfo.classNo and tostring(classInfo.classNo) or ""
        UserClassChange.curYearStr = UserClassChange.GetGradeValue(classInfo.grade)
        UserClassChange.curLearnYearStr = tostring(classInfo.enrollmentYear) or ""
    end
    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/User/UserClassChange.html",
        name = "UserClassChange.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = false,
        directPosition = true,
        cancelShowAnimation = true,
        -- DesignResolutionWidth = 1280,
		-- DesignResolutionHeight = 720,
        align = "_fi",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function UserClassChange.GetGradeValue(grade)
    for k,v in pairs(UserClassChange.ClassOptions) do
        if tonumber(v.value) == tonumber(grade) then
            return v.text
        end
    end
    return ""
end

function UserClassChange.OnClickOk()
    local gradeValue = page:GetValue("classOption");
    local classNum = page:GetValue("class_number")
    local enrollmentYear = page:GetValue("enterYears")
    if gradeValue == "" or classNum == "" or enrollmentYear == "" then
        GameLogic.AddBBS(nil,"请将信息填写完整再保存哦。")
        return
    end
    if page then
        page:CloseWindow()
        page = nil
    end
    if closeFunc then
        closeFunc(gradeValue,classNum,enrollmentYear)
    end
end

function UserClassChange.OnChangeClassNum()
    if page then
        local classNum = page:GetValue("class_number")
        if classNum ~= "" then
            if tonumber(classNum) == nil then
                GameLogic.AddBBS(nil,"请输入正确的班级")
                local value = classNum:match("^%d+")
                page:SetValue("class_number",value)
            end
        end
    end
end