--[[
Title: RankHelp
Author(s): yangguiyi
Date: 2021/6/17
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Rank/RankHelp.lua").Show("role");
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
local RankHelp = NPL.export();
local page
local server_time = 0

RankHelp.RankDescList = {
    ["orgComprehensive"] = " 院校综合榜：院校综合榜是结合院校学生数量、学习情况、作品情况等多方面进行评分的榜单，学生数量越多、学习课程越多、作品量越多得分越高。<br/><br/>",
    ["orgPower"] = "院校人数榜：院校人数榜是学校完成注册并实名认证的学生人数，人数越多分数越高。<br/><br/>",
    ["orgCreate"] = "院校创作榜：院校创作榜是学校所有学生的作品总和，作品的数量越多得分就越高。<br/><br/>",
    ["orgStudy"] = "院校学习榜：院校学习榜是学校所有学生完成的课程学习总数，完成的课程数量越多，得分就越高。<br/><br/>",
    ["personTop"] = "作品达人榜：作品达人榜是计算所有作品的累计访问量总和，访问量越多得分越高。<br/><br/>",
    ["personWorld"] = "作品点赞榜：作品点赞榜是用户所有作品累计点赞数量总和，点赞的数量越多，得分越高。<br/><br/>",
    ["projectHot"] = "热门作品榜：热门作品榜是同学的某个作品的访问量的展示，访问量越高，排名就越高。<br/><br/>",
}

local ExtendDesc = [[
    &nbsp;<br/><br/>
    榜单规则<br/><br/>
    榜单显示前1000所院校、前1000名玩家、前1000名作品的名次的用户、院校、作品名称，并以上述计分方式根据分数由高到低排序，若出现分数相同情况，则以达到该分数的先后顺序进行排序，先达到的排名在前，后达到的排名在后，无同分同名次情况。若总统计数量不足1000，则统计至最末位名次。<br/><br/>
]]

function RankHelp.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = RankHelp.CloseView
end

function RankHelp.Show(help_type)
    RankHelp.help_type = help_type
    -- RankHelp.help_type = "create_world"
    RankHelp.InitData()
    RankHelp.ShowView()

end

function RankHelp.ShowView()
    if page and page:IsVisible() then
        RankHelp.OnRefresh()
        return
    end
    
    
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Rank/RankHelp.html",
        name = "RankHelp.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 2,
        -- app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,
        
        align = "_ct",
        x = -632/2,
        y = -352/2,
        width = 632,
        height = 352,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function RankHelp.FreshView()
end

function RankHelp.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
    RankHelp.FreshView()
end

function RankHelp.CloseView()
    RankHelp.ClearData()
end

function RankHelp.ClearData()
end

function RankHelp.InitData()
    if RankHelp.help_type == nil then
        return
    end

    local help_desc = RankHelp.RankDescList[RankHelp.help_type] .. ExtendDesc
    RankHelp.DataSource = {{help_desc = help_desc}}

    RankHelp.CourseData = {}
end

function RankHelp.HandleCourseData(data)
    RankHelp.ServerData = data
    RankHelp.CourseData = {}
    for i, v in ipairs(data) do
        local course_data = {}
        course_data.name = RankHelp.GetLimitLabel(v.name)
        course_data.id = v.id
        course_data.projectReleaseId = v.projectReleaseId
        RankHelp.CourseData[#RankHelp.CourseData + 1] = course_data
    end
end

function RankHelp.GetLimitLabel(text)
    local maxCharCount = 8;
    local len = ParaMisc.GetUnicodeCharNum(text);
    if(len >= maxCharCount)then
	    text = ParaMisc.UniSubString(text, 1, maxCharCount-2) or "";
        return text .. "...";
    else
        return text;
    end
end