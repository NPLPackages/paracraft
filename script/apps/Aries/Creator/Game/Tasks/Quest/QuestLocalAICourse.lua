--[[
Title: QuestLocalAICourse
Author(s): yangguiyi
Date: 2021/2/2
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestLocalAICourse.lua").Show();
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local QuestPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestPage.lua");
local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
local QuestLocalAICourse = NPL.export();
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

local page
local server_time = 0
local VersionToKey = {
	ONLINE = 1,
	RELEASE = 2,
	LOCAL = 3,
}

local SchoolClassIdList = {
    RELEASE = 33,
    ONLINE = 5
}
QuestLocalAICourse.AllCourseListData = {
    ai_course = {
        {name = "帕帕的家", world_id = 42457},
        {name = "拉拉的家", world_id = 42701},
        {name = "卡卡的家", world_id = 42670},
        {name = "乒乓球", world_id = 44453},
        {name = "小小建筑师", world_id = 46263},
        {name = "变速风扇", world_id = 47710},
        {name = "远方的客人", world_id = 46268},
        {name = "彩色光源", world_id = 46357},
        {name = "电路教学", world_id = 50735}, 
        {name = "四季之美", world_id = 49664},
        {name = "堆雪人", world_id = 49763},
        {name = "旋转木马", world_id = 49764},
        {name = "下雪啦", world_id = 49770},
        {name = "勇闯迷宫", world_id = 44676},
        {name = "快速移动的方法", world_id = 44620},
        {name = "如何选择一组方块", world_id = 44708},
        {name = "钢琴", world_id = 44631},
        {name = "更加精细的bmax模型", world_id = 44626},
    },
    world = {
        {name = "不畏将来不念过去", world_id = 81},
        {name = "肇庆市第一中学", world_id = 113},
        {name = "象形之美", world_id = 2769},
        {name = "木兰花令", world_id = 76},
        {name = "地球的颜色", world_id = 1066},
        {name = "火星探险", world_id = 1082},
        {name = "TypingGame", world_id = 867},
        {name = "父亲", world_id = 1073},
        {name = "爷爷的宝藏", world_id = 507},
        {name = "人力资源", world_id = 1562},
        {name = "99乘法口诀", world_id = 12642},
        {name = "BlockBot", world_id = 709},
    }

}
-- QuestLocalAICourse.TeacherListData = {}
QuestLocalAICourse.LevelListData = {}
QuestLocalAICourse.CourseListData = {}

QuestLocalAICourse.CourseWorldData = {}
QuestLocalAICourse.ExidToWorldId = {}

QuestLocalAICourse.SelectTeacherIndex = 1
QuestLocalAICourse.SelectLevelIndex = 1
QuestLocalAICourse.SelectCourseIndex = 0

QuestLocalAICourse.TeacherListData = {
    {course_type="ai_course", name="AI课程", desc="", icon="Texture/Aries/Creator/keepwork/AiCourse/ren1_48X54_32bits.png#0 0 55 55", order = -1},
    {course_type="world", name="推荐作品", desc="", icon="Texture/Aries/Creator/keepwork/AiCourse/ren1_46X50_32bits.png#0 0 55 55", order = -1},
}

function QuestLocalAICourse.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = QuestLocalAICourse.CloseView
end

function QuestLocalAICourse.GetPageCtrl()
    return page
end

function QuestLocalAICourse.Show(target_course_id)
    if page and page:IsVisible() then
        return
    end
    QuestLocalAICourse.RefreshLevelListData()
    QuestLocalAICourse.RefreshCourseListData()
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Quest/QuestLocalAICourse.html",
        name = "QuestLocalAICourse.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 0,
        -- app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,
        
        align = "_ct",
        x = -926/2,
        y = -562/2,
        width = 926,
        height = 562,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);

    commonlib.TimerManager.SetTimeout(function()
        if page and page:IsVisible() then
            local mcmlNode = page:GetNode("course_list");

            local tree_view = mcmlNode:GetChild("pe:treeview");
            local tree_view_control = tree_view.control
            local _parent = ParaUI.GetUIObject(tree_view_control.name);
            local main = _parent:GetChild(tree_view_control.mainName);
            main:SetScript("onmousewheel", function()
                local page_index = mcmlNode:GetAttribute("pageindex") or 1
                local target_page = page_index - mouse_wheel
                pe_gridview.GotoPage(mcmlNode, "course_list", target_page);
            end)
        end
    end, 100); 
end

function QuestLocalAICourse.FreshView()
end

function QuestLocalAICourse.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
    QuestLocalAICourse.FreshView()
end

function QuestLocalAICourse.CloseView()
    QuestLocalAICourse.ClearData()
end

function QuestLocalAICourse.ClearData()
    -- QuestLocalAICourse.TeacherListData = {}
    -- QuestLocalAICourse.LevelListData = {}
    -- QuestLocalAICourse.CourseListData = {}
    
    QuestLocalAICourse.SelectTeacherIndex = 1
    QuestLocalAICourse.SelectLevelIndex = 1
    QuestLocalAICourse.SelectCourseIndex = 0
    QuestLocalAICourse.target_course_id = nil
    QuestLocalAICourse.target_teacher_id = nil
    QuestLocalAICourse.target_level_id = nil
end

------------------------------------------------------------数据处理------------------------------------------------------------
function QuestLocalAICourse.RefreshAllData(callback)
end


function QuestLocalAICourse.RefreshLevelListData()
    QuestLocalAICourse.SelectLevelIndex = 1

    QuestLocalAICourse.LevelListData = {}
    local all_course_data = {}
    all_course_data.name = "全部"
    table.insert(QuestLocalAICourse.LevelListData, 1, all_course_data)
end

function QuestLocalAICourse.RefreshCourseListData(callback)
    
    local select_teacher_data = QuestLocalAICourse.TeacherListData[QuestLocalAICourse.SelectTeacherIndex]
    if select_teacher_data == nil or select_teacher_data.course_type == nil then
        return
    end
    QuestLocalAICourse.CourseListData = QuestLocalAICourse.AllCourseListData[select_teacher_data.course_type]
    if callback then
        callback()
    end
end
----------------------------------------------------------数据处理/end----------------------------------------------------------

------------------------------------------------------------点击事件------------------------------------------------------------

function QuestLocalAICourse.SelectTeacher(index)
    if index == QuestLocalAICourse.SelectTeacherIndex then
        return
    end
    QuestLocalAICourse.SelectTeacherIndex = index

    -- 刷新老师列表控件
    QuestLocalAICourse.FreshGridView("teacher_list")
    -- 刷新等级列表数据
    -- QuestLocalAICourse.RefreshLevelListData()
    
    -- 刷新等级列表控件
    -- QuestLocalAICourse.FreshGridView("level_list")
    -- 刷新课程列表数据
    QuestLocalAICourse.RefreshCourseListData(function()
        -- 刷新课程列表控件
        QuestLocalAICourse.FreshGridView("course_list")
        local mcmlNode = page:GetNode("course_list");
        pe_gridview.GotoPage(mcmlNode, "course_list", 1);
    end)



    -- QuestLocalAICourse.CreateTeacherNpc()
end

function QuestLocalAICourse.IsSelectTeacher(index)
    return QuestLocalAICourse.SelectTeacherIndex == index
end

function QuestLocalAICourse.SelectLevel(index)
    if index == QuestLocalAICourse.SelectLevelIndex then
        return
    end
    QuestLocalAICourse.SelectLevelIndex = index
    
    -- 刷新等级列表控件
    QuestLocalAICourse.FreshGridView("level_list")
    

    -- 刷新课程列表控件
    QuestLocalAICourse.RefreshCourseListData(function()
        -- 刷新课程列表控件
        QuestLocalAICourse.FreshGridView("course_list")
    end)
end

function QuestLocalAICourse.IsSelectLevel(index)
    return QuestLocalAICourse.SelectLevelIndex == index
end

function QuestLocalAICourse.SelectCourse(index)
    -- if index == QuestLocalAICourse.SelectCourseIndex then
    --     return
    -- end
    QuestLocalAICourse.SelectCourseIndex = index
    -- 刷新课程列表控件
    QuestLocalAICourse.FreshGridView("course_list")

    -- QuestLocalAICourse.RunCommand(index)
end

function QuestLocalAICourse.GotoClass(index, is_pre)
    -- if index == QuestLocalAICourse.SelectCourseIndex then
    --     return
    -- end
    QuestLocalAICourse.SelectCourseIndex = index
    -- 刷新课程列表控件
    QuestLocalAICourse.FreshGridView("course_list")

    QuestLocalAICourse.RunCommand(index, is_pre)
end

function QuestLocalAICourse.IsSelectCourse(index)
    return QuestLocalAICourse.SelectCourseIndex == index
end

function QuestLocalAICourse.RunCommand(index, is_pre)
    local course_data = QuestLocalAICourse.CourseListData[index]
    if course_data == nil then
        return false
    end

    CommandManager:RunCommand(format('/loadworld -e %d', course_data.world_id))
    
    -- local world_id_list = {course_data.world_id}
    -- keepwork.world.search({
    --     type = 1,
    --     id = {["$in"] = world_id_list},
    -- },function(err, msg, data)
    --     -- print("获取关注列表结果aaaaaa", data.world_id)
    --     -- commonlib.echo(data, true)
    --     if err == 200 then
    --         for k, v in pairs(data.rows) do
    --             System.os.GetUrl(v.extra.imageUrl, function(err2, msg2, data2)
    --                 if err2 == 200 then
    --                     local filename = v.id .. ".jpg"
    --                     local disk_folder = ParaIO.GetWritablePath().."temp/world_icon"
    --                     local file_path = string.format("%s/%s", disk_folder, filename)
    --                     ParaIO.CreateDirectory(file_path)
    --                     local file = ParaIO.open(file_path, "w");
    --                     if(file) then
    --                         file:write(data2, #data2);
    --                         file:close();
    --                     end
    --                 end
    --             end);
    --         end
            
    --         if callback then
    --             callback()
    --         end
    --     end
    -- end)
end

----------------------------------------------------------点击事件/end----------------------------------------------------------

function QuestLocalAICourse.SetSelectLevelIndex()
    if QuestLocalAICourse.target_level_id then
        for k2, v2 in pairs(QuestLocalAICourse.LevelListData) do
            if v2.id == QuestLocalAICourse.target_level_id then
                QuestLocalAICourse.SelectLevelIndex = k2
            end
        end
    end
    
end

function QuestLocalAICourse.FreshGridView(name)
    local node = page:GetNode(name);
    pe_gridview.DataBind(node, name, false);
end

function QuestLocalAICourse.HasWork(index)
    local data = QuestLocalAICourse.CourseListData[index]
    if data == nil then
        return false
    end

    return data.aiHomework ~= nil
end

function QuestLocalAICourse.GetWorldIconUrl(index)
    local data = QuestLocalAICourse.CourseListData[index]
    if data == nil then
        return string.format("Texture/Aries/Creator/keepwork/AiCourse/WorldIcon/%s.png", 50735)
    end

    local select_teacher_data = QuestLocalAICourse.TeacherListData[QuestLocalAICourse.SelectTeacherIndex]
    local file_path
    if select_teacher_data.course_type == "world" then
        file_path = string.format("Texture/Aries/Creator/keepwork/AiCourse/WorldIcon/%s.jpg", data.world_id)
    else
        file_path = string.format("Texture/Aries/Creator/keepwork/AiCourse/WorldIcon/%s.png", data.world_id)
    end
    -- if(ParaIO.DoesFileExist(file_path)) then
        
    -- end 

    return file_path
end