--[[
Title: ClassContentPage
Author(s): pbb
Date: 2024/3/22
Desc:  
Use Lib:
-------------------------------------------------------
local ClassContentPage =  NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Project/ClassContentPage.lua")
ClassContentPage.ShowView();
--]]
local KeepworkWorldsApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/KeepworkWorldsApi.lua')
NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Project/EducateClassManager.lua");
local EducateClassManager = commonlib.gettable("MyCompany.Aries.Game.Educate.Class.Manager");
local ClassContentPage = NPL.export();

ClassContentPage.ProjectsData = {}
local page
function ClassContentPage.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = ClassContentPage.OnClose
end

--[[
--选中存在的世界
echo:return {
    classAt="2024-03-20T09:30:04.221Z",
    classroomId="",
    lessonName="教案",
    lessonPackageName="小学语文",
    materialName="测试素材1",
    projectId=22529,
    projectName="测试课程3",
    sectionContentId="4998" 
}
--选择新建私有
echo:return {
  classAt="2024-03-20T09:31:04.038Z",
  classroomId="",
  forkProjectId=22529,
  isVisibility=1,
  lessonName="教案",
  lessonPackageName="小学语文",
  materialName="测试素材1",
  projectName="测试课程",
  sectionContentId="4998" 
}
--选择新建普通
echo:return {
  classAt="2024-03-20T09:35:33.326Z",
  classroomId="",
  lessonName="教案",
  lessonPackageName="小学语文",
  materialName="cesai1111",
  projectId="",
  projectName="",
  sectionContentId="3786" 
}

]]

--[[
echo:return {
  classAt="2024-03-22T08:02:42.000Z",
  classroomId=787,
  forkProjectId=22518,
  isVisibility=1,
  lessonName="测评",
  lessonPackageName="小学语文",
  materialName="测试素材1",
  projectName="测试课程",
  sectionContentId="4998" 
}
]]

function ClassContentPage.IsSameWolrdName(name,homeworkName)
    if not name or not homeworkName then
        return false
    end
    local pattern =  "[%[#&*%-%+%.%(%)%$%'%,%]]"
    local homeworkName = homeworkName:gsub(pattern, "")
    local name = name:gsub(pattern, "")
    local regexStr = "^"..homeworkName;
    return name:find(regexStr)
end

function ClassContentPage.ShowView(data)
    if page and page:IsVisible() or not data then
        return
    end
    ClassContentPage.ContentData = data
    ClassContentPage.ProjectsData = {}
    local homeworkName = data.projectName
    ClassContentPage.GetRemoteWorldList(function(remoteWorlds)
        -- echo(remoteWorlds,true)
        -- echo(ClassContentPage.ContentData,true)
        -- print("ClassContentPage=====================")
        if not remoteWorlds or #remoteWorlds == 0 then
            EducateClassManager.SetEducateData(ClassContentPage.ContentData)
            return
        end
        for key, item in ipairs(remoteWorlds) do
            if ClassContentPage.IsSameWolrdName(item.worldName,homeworkName) or 
                (item.project 
                and item.project.extra 
                and item.project.extra.worldTagName 
                and ClassContentPage.IsSameWolrdName(item.project.extra.worldTagName,homeworkName)) then
                ClassContentPage.ProjectsData[#ClassContentPage.ProjectsData + 1] = item
            end
        end
        if #ClassContentPage.ProjectsData == 0 then
            EducateClassManager.SetEducateData(ClassContentPage.ContentData)
            return
        end
        table.sort(ClassContentPage.ProjectsData, function(a, b)
            local a_update_time = commonlib.timehelp.GetTimeStampByDateTime(a.updatedAt)
            local b_update_time = commonlib.timehelp.GetTimeStampByDateTime(b.updatedAt)
            return a_update_time > b_update_time
        end)
        ClassContentPage.ShowPage()
    end)
end

function ClassContentPage.ShowPage()
    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Educate/Project/ClassContentPage.html",
        name = "ClassContentPage.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        zorder = 1,
        directPosition = true,
        --withBgMask=true,
        align = "_fi",
        x = -view_width/2,
        y = -view_height/2,
        width = view_width,
        height = view_height,
        isTopLevel = true,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function ClassContentPage.GetRemoteWorldList(callback)
    KeepworkWorldsApi:GetWorldList(1000, 1, function(data, err)
        if err == 200 then
            local filtersData = {}
            for key, item in ipairs(data) do
                if item and
                    item.project and
                    type(item.project) == 'table' and
                    item.project.platform and
                    Mod.WorldShare.Utils.IsEducatePlatform(item.project.platform) then
                    filtersData[#filtersData + 1] = item
                end
            end

            callback(filtersData)
        else
            callback()
        end
    end)
end 

function ClassContentPage.CloseView()
    if page then
        page:CloseWindow()
        page = nil
    end
    ClassContentPage.ClearData()
    local CurClassPage =NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Project/CurClassPage.lua")
    CurClassPage.CloseView()
end

function ClassContentPage.ClearData()
    ClassContentPage.ContentData = nil
    ClassContentPage.ProjectsData = {}
end

function ClassContentPage.CreateWorld()
    if ClassContentPage.ContentData then
        EducateClassManager.SetEducateData(ClassContentPage.ContentData)
    end
    ClassContentPage.CloseView()
end

function ClassContentPage.OnClickProject(data)
    if not ClassContentPage.ContentData then
        return
    end
    if data and data.projectId then
        ClassContentPage.ContentData.projectId = data.projectId
        ClassContentPage.ContentData.projectName = data.worldName
        ClassContentPage.ContentData.forkProjectId = nil
        ClassContentPage.ContentData.isVisibility = nil
        EducateClassManager.SetEducateData(ClassContentPage.ContentData)
        ClassContentPage.CloseView()
    end
end

--[[
--选中存在的世界
echo:return {
    classAt="2024-03-20T09:30:04.221Z",
    classroomId="",
    lessonName="教案",
    lessonPackageName="小学语文",
    materialName="测试素材1",
    projectId=22529,
    projectName="测试课程3",
    sectionContentId="4998" 
}
--选择新建私有
echo:return {
  classAt="2024-03-20T09:31:04.038Z",
  classroomId="",
  forkProjectId=22529,
  isVisibility=1,
  lessonName="教案",
  lessonPackageName="小学语文",
  materialName="测试素材1",
  projectName="测试课程",
  sectionContentId="4998" 
}
--选择新建普通
echo:return {
  classAt="2024-03-20T09:35:33.326Z",
  classroomId="",
  lessonName="教案",
  lessonPackageName="小学语文",
  materialName="cesai1111",
  projectId="",
  projectName="",
  sectionContentId="3786" 
}

]]

--[[
echo:return {
  classAt="2024-03-22T08:02:42.000Z",
  classroomId=787,
  forkProjectId=22518,
  isVisibility=1,
  lessonName="测评",
  lessonPackageName="小学语文",
  materialName="测试素材1",
  projectName="测试课程",
  sectionContentId="4998" 
}
]]
