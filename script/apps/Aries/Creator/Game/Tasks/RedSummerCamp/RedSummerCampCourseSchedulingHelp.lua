--[[
Title: 
Author(s): pbb
Date: 2021/9/17
Desc: 
use the lib:
------------------------------------------------------------
local RedSummerCampCourseSchedulingHelp = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCourseSchedulingHelp.lua") 
RedSummerCampCourseSchedulingHelp.ShowView()
-------------------------------------------------------
]]
local RedSummerCampCourseSchedulingHelp = NPL.export()
RedSummerCampCourseSchedulingHelp.m_help_index = 1
RedSummerCampCourseSchedulingHelp.helpCnf = {
    {
        icon="Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/tupian1_567x222_32bits.png#0 0 567 222",
        title="简介",
        content=[[《创意空间》是一种利用人工智能技术的全新自主学习场所。物理上可以利用学校的计算机教室，或通过学生自带电脑（或平板）在普通教室中完成。<br/>
        《创意空间》是对传统编程教育软件工具、教学方法、教学内容的全面升级。在创意空间中，老师和学生可以一同学习和成长，老师可以最大化的发挥出自己的特长，例如语文、英语、数学、美术、编剧、口才等等。]],
    },
    {
        icon="Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/tupian2_567x222_32bits.png#0 0 567 222",
        title="教学指南",
        content=[[《创意空间》课程采用探索自学、人工智能教学、自由创造三步结合的方式，让学生在一节课中做到学与练一体，更好的巩固所学知识点。并且所有课程均采用趣味小项目实操的教学形式，让学生在学习的过程中不会感到枯燥乏味，实现快乐学习！]],
    },
}
local page = nil
function RedSummerCampCourseSchedulingHelp.OnInit()
    page = document:GetPageCtrl();
end

function RedSummerCampCourseSchedulingHelp.RefreshPage()
    if page then
        page:Refresh(0)
        RedSummerCampCourseSchedulingHelp.InitPage()
    end
end 

function RedSummerCampCourseSchedulingHelp.ClosePage()
    if page then
        page:CloseWindow(true)
        page = nil
    end
end

function RedSummerCampCourseSchedulingHelp.ShowView()
    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCourseSchedulingHelp.html",
        name = "RedSummerCampCourseSchedulingHelp.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = false,
        directPosition = true,
        DesignResolutionWidth = 1280,
		DesignResolutionHeight = 720,
        cancelShowAnimation = true,
        align = "_fi",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    RedSummerCampCourseSchedulingHelp.InitPage()
end

function RedSummerCampCourseSchedulingHelp.InitPage()
    local bg = ParaUI.GetUIObject("helpBg");
    bg:SetScript("onmousewheel", function()
        RedSummerCampCourseSchedulingHelp.m_help_index = RedSummerCampCourseSchedulingHelp.m_help_index + 1
        if RedSummerCampCourseSchedulingHelp.m_help_index > 2 then
            RedSummerCampCourseSchedulingHelp.m_help_index = 1
        end
        RedSummerCampCourseSchedulingHelp.RefreshPage()
    end)
end