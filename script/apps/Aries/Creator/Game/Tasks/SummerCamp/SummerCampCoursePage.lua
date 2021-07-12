--[[
author:yangguiyi
date:
Desc:
use lib:
local SummerCampCoursePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampCoursePage.lua") 
SummerCampCoursePage.ShowView()
]]
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local httpwrapper_version = HttpWrapper.GetDevVersion();
local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local SummerCampCoursePage = NPL.export()
local course_desc_data = {
    {name = "万水千山", point_desc = "学习搭建场景的基础操作", world_desc="到创作世界里，完善场景1的山脉，并为场景2的水池填充水。"},
    {name = "开启征程", point_desc = "学习动画制作的基本方法", world_desc="到创作世界里，修复场景1电影方块里的演员，让演员移动起来，并给演员添加行走动作。"},
    {name = "红军远征", point_desc = "学会改变演员属性，调整演员的大小、位置和朝向", world_desc="到创作世界里，给场景2的电影方块里添加新的演员，并让他向前行走。"},
    {name = "结伴前行", point_desc = "学习复制演员以及制作多演员动画的技巧。", world_desc="到创作世界里，给场景2电影方块中复制多个演员并更改演员模型；为动画添加字幕及配音，完成进军队伍的动画。"},
    {name = "五岭逶迤", point_desc = "复制、拉伸等快速搭建的技巧", world_desc="到创作世界里，利用镜像工具和画笔工具，美化和完善场景3。"},
    {},
    {},
    {name = "勇往直前", point_desc = "学会用画笔工具为红军开路", world_desc="到创作世界里，为场景3的动画添加小鸟，并让小鸟往前飞动，然后制作一段镜头移动的动画。"},
    {name = "乌蒙磅礴", point_desc = "画笔的进一步学习，为场景添加花草等装饰", world_desc="到创作世界里，完善场景4的山体，并为场景4的动画添加烟雾特效。"},
    {name = "浩月当空", point_desc = "学会通过参数修改，调整时间、天气和月亮的大小", world_desc="到创作世界里，调整场景4动画中的时间、天气和月亮大小。"},
    {name = "英勇无畏", point_desc = "通过复制和调整演员属性，创作红军过江动画", world_desc="到创作世界里，为场景5的江河注满水，并制作红军过江动画。"},
    {name = "红日西沉", point_desc = "学会通过参数修改，调整太阳大小并改变动画的渲染效果", world_desc="到创作世界里，改变太阳大小，并通过调整光影改变动画的渲染效果。"},
    {},
    {},
    {name = "十步芳草", point_desc = "通过制作一朵小花模型，理解Paracraft独有的Bmax模型的基本使用方法。", world_desc="到创作世界里，搭建一朵小花，并将小花保存为B-max模型，然后用小花的B-max装饰场景。"},
    {name = "浴血奋战", point_desc = "学习如何在电影方块里添加Bmax模型，并制作飞夺泸定桥场景动画。", world_desc="到创作世界里，为场景6中的电影方块添加木板桥B-max，然后再添加火焰特效，让场景更生动。"},
    {name = "瑞雪纷飞", point_desc = "通过对下雪、下雨指令的学习来给场景添加特殊天气", world_desc="到创作世界里，通过指令，将天气设置为下雨或下雪天。"},
    {name = "千里冰封", point_desc = "学习如何快速批量替换材质的方法。", world_desc="到创作世界里，为场景7制作一座雪山，并用代码将天气改为下雪天。"},
    {name = "众志成城", point_desc = "通过代码实现演员的克隆并将动画导出为mp4视频", world_desc="到创作世界里，利用代码指令克隆出一个红军方阵。"},
    {},
    {},
    {},
    -- {name = "功垂史册", point_desc = "添加片尾黑幕，并学习如何将动画导出为mp4格式的视频。", world_desc="到创作世界里，为动画添加黑幕片尾，并最终将动画输出为一个mp4格式的视频。"},
}

local page = nil
local course_begain_day = 12
function SummerCampCoursePage.OnInit()
    page = document:GetPageCtrl();
end

function SummerCampCoursePage.ShowView(parent)
    SummerCampCoursePage.CourseData = {}
    SummerCampCoursePage.InitTodayCourseData()
    local view_width = 1035
    local view_height = 623

    page = Map3DSystem.mcml.PageCtrl:new({ 
        url = "script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampCoursePage.html" ,
        click_through = false,
    } );
    SummerCampCoursePage._root = page:Create("SummerCampCoursePage.ShowView", parent, "_lt", 0, 0, view_width, view_height)
    SummerCampCoursePage._root.visible = true

    return page
end

function SummerCampCoursePage.CloseView()
    -- body
end

function SummerCampCoursePage.GoTo()
    local summer_day = QuestAction.GetSummerDay()
    if summer_day < course_begain_day then
        GameLogic.AddBBS("summer_course", L"尚未到开课时间，敬请期待");
        return
    end

    local SummerCampMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampMainPage.lua") 
    SummerCampMainPage.CloseView()
    local world_id_list = {
        ONLINE = 73104,
        RELEASE = 20666,
    }
    local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
    local httpwrapper_version = HttpWrapper.GetDevVersion();
    local world_id = world_id_list[httpwrapper_version]

	local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")
	CommandManager:RunCommand(string.format('/loadworld -force -s %s', world_id))
end

function SummerCampCoursePage.InitTodayCourseData()
    local summer_day = QuestAction.GetSummerDay()
    local course_day_index = summer_day - course_begain_day + 1
    local data = course_desc_data[course_day_index] or {}
    data.limit_point_desc = SummerCampCoursePage.GetLimitLabel(data.point_desc, 48)
    data.limit_world_desc = SummerCampCoursePage.GetLimitLabel(data.world_desc, 48)

    SummerCampCoursePage.CourseData = data
end

function SummerCampCoursePage.GetCourseData(name)
    local data = SummerCampCoursePage.CourseData
    return data[name] or ""
end

function SummerCampCoursePage.GetLimitLabel(text, maxCharCount)
    text = text or ""
    maxCharCount = maxCharCount or 13;
    local len = ParaMisc.GetUnicodeCharNum(text);
    if(len >= maxCharCount)then
	    text = ParaMisc.UniSubString(text, 1, maxCharCount-2) or "";
        return text .. "...";
    else
        return text;
    end
end

function SummerCampCoursePage.IsShowBuke()
    local profile = KeepWorkItemManager.GetProfile()
    if profile == nil or profile.school == nil then
        return true
    end

    local school = profile.school
    if school.marketingLevel == nil then
        return true
    end

    if school.marketingLevel and school.marketingLevel > 1 then
        return true
    end

    return false
end