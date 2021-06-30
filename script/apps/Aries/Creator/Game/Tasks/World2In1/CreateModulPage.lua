--[[
Title: CreateModulPage
Author(s): yangguiyi
Date: 2021/6/18
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/World2In1/CreateModulPage.lua").Show();
--]]
local CreateModulPage = NPL.export();
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandManager.lua");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local World2In1 = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/World2In1.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
local server_time = 0
local page

CreateModulPage.TypeData = {
    {name="全部", background="Texture/Aries/Creator/keepwork/World2In1/zi1_32X32_32bits.png#0 0 108 36", id_list = {

    }},
    {name="故事", background="Texture/Aries/Creator/keepwork/World2In1/zi2_32X32_32bits.png#0 0 108 36", id_list = {
        20664,
    }},
    {name="跑酷", background="Texture/Aries/Creator/keepwork/World2In1/zi3_32X32_32bits.png#0 0 108 36", id_list = {
        20674,
    }},
    {name="解密", background="Texture/Aries/Creator/keepwork/World2In1/zi4_32X32_32bits.png#0 0 108 36", id_list = {

    }},
    {name="交互游戏", background="Texture/Aries/Creator/keepwork/World2In1/zi5_61X14_32bits.png#0 0 108 36", id_list = {

    }},
}

CreateModulPage.WorldDataList = {}
function CreateModulPage.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = CreateModulPage.CloseView
    page.OnCreate = CreateModulPage.OnCreate
end

function CreateModulPage.OnCreate()
    if page and page:IsVisible() then
        local mcmlNode = page:GetNode("module_list");
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
end
function CreateModulPage.CloseView()
    CreateModulPage.WorldListData = nil
end

function CreateModulPage.Show(create_project_name, parent_id)
    CreateModulPage.parent_id = parent_id
    CreateModulPage.create_project_name = create_project_name
    CreateModulPage.ShowView()
end

function CreateModulPage.ShowView()
    if page and page:IsVisible() then
        return
    end
    CreateModulPage.select_type_index = 1
    CreateModulPage.select_module_index = 1
    CreateModulPage.HandleData()
    
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/World2In1/CreateModulPage.html",
        name = "CreateModulPage.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 0,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,
        
        align = "_ct",
        x = -854/2,
        y = -573/2,
        width = 854,
        height = 573,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function CreateModulPage.HandleData(cb)
    local select_type_data = CreateModulPage.TypeData[CreateModulPage.select_type_index]
    if select_type_data.name == "全部" and #select_type_data.id_list == 0 then
        for i, v in ipairs(CreateModulPage.TypeData) do
            for i2, v2 in ipairs(v.id_list) do
                select_type_data.id_list[#select_type_data.id_list + 1] = v2
            end
        end
    end

    
    local id_list = select_type_data.id_list
    keepwork.world.search({
        type = 1,
        id = {["$in"] = id_list},
    },function(err, msg, data)
        -- print("获取关注列表结果", err, msg)
        -- commonlib.echo(data, true)
        CreateModulPage.WorldDataIdTable = {}
        CreateModulPage.WorldDataList = {}
        if err == 200 then
            for k, v in ipairs(data.rows) do
                CreateModulPage.WorldDataIdTable[v.id] = v

                local data = {}
                data.img_bg = v.extra.imageUrl
                data.name = v.name
                data.is_recommend = CreateModulPage.GetIsRecommendModule(v.id)
                data.is_vip_use = CreateModulPage.GetIsVipModule(v.id)
                data.is_show_vip_lock = data.is_vip_use and not GameLogic.IsVip()
                
                data.is_competition = CreateModulPage.GetIsCompetitionModule(v.id)
                data.has_used = CreateModulPage.GetHasUsed(v.id)
                data.id = v.id
                CreateModulPage.WorldDataList[#CreateModulPage.WorldDataList + 1] = data
            end

            -- for index = 1, 30 do
            --     CreateModulPage.WorldDataList[#CreateModulPage.WorldDataList + 1] = commonlib.copy(CreateModulPage.WorldDataList[#CreateModulPage.WorldDataList]);
            -- end
            CreateModulPage.select_module_index = 1
            CreateModulPage.FlushGridView()
            -- page:Refresh(0)
            if cb then
                cb()
            end
        end
    end)
end

function CreateModulPage.GetDesc1()
    return "欢迎来到创作区，你可以选择下面模板快速创建属于你的迷你地块，并入驻至课程世界与其他同学PK哦！"
end

function CreateModulPage.OnClickCreate()
    
    local select_module_data = CreateModulPage.WorldDataList[CreateModulPage.select_module_index]
    print("xxxx", select_module_data)
    if select_module_data == nil then
        return
    end
    local parent_id = CreateModulPage.parent_id or 0
    local region_id = select_module_data.id

    local project_name = page:GetValue("project_text") or ""
    if project_name == "" then
        GameLogic.AddBBS("create_module", L"请输入项目名称", 5000, "255 0 0");
        return
    end

    if string.len(project_name) > 40 then
        GameLogic.AddBBS("create_module", L"世界名字太长了, 请重新输入", 5000, "255 0 0");
        return
    end
    if CreateModulPage.project_file_path == nil then
        CreateModulPage.project_file_path = ParaIO.GetWritablePath() .. "worlds/DesignHouse/"
    end

    if parent_id ~= 0 then
        if ParaIO.DoesFileExist(CreateModulPage.project_file_path .. project_name, true) then
            _guihelper.MessageBox("模板已经存在了，是否直接使用该模板，否则请修改项目名称", function()	
                World2In1.SetCreatorWorldName(project_name)
                page:CloseWindow()
                CreateModulPage.CloseView()
                CommandManager:RunCommand(format([[/createworld -name "%s" -parentProjectId %d -update -fork %d]], project_name, parent_id,region_id))
            end)
        else
            page:CloseWindow()
            CreateModulPage.CloseView()
            CommandManager:RunCommand(format([[/createworld -name "%s" -parentProjectId %d -update -fork %d]], project_name, parent_id,region_id))
        end
    else

        if ParaIO.DoesFileExist(CreateModulPage.project_file_path .. project_name, true) then
            _guihelper.MessageBox("世界已经存在了，是否直接进入该世界", function()	
                page:CloseWindow()
                CreateModulPage.CloseView()
            end)
            return
        end
    end
    -- CommandManager:RunCommand(format([[/createworld -name "%s" -fork %d]], project_name,region_id))
end

function CreateModulPage.SelectType(index)
    CreateModulPage.select_type_index = index
    CreateModulPage.select_module_index = 1
    page:Refresh(0)

    CreateModulPage.HandleData(function()
        local mcmlNode = page:GetNode("module_list");
        pe_gridview.GotoPage(mcmlNode, "module_list", 1);
    end)
end

function CreateModulPage.GetIsRecommendModule(id)
    return true
end

function CreateModulPage.GetIsVipModule(id)
    return true
end

function CreateModulPage.GetHasUsed(id)
    return true
end

function CreateModulPage.GetIsCompetitionModule(id)
    return true
end

function CreateModulPage.SelectModule(index)
    CreateModulPage.select_module_index = index
    CreateModulPage.FlushGridView()
end

function CreateModulPage.FlushGridView()
    local node = page:GetNode("module_list");
    pe_gridview.DataBind(node, "module_list", false);

    local select_module_data = CreateModulPage.WorldDataList[CreateModulPage.select_module_index]
    local project_name = ""
    if select_module_data then
        project_name  = string.format("%s_%s_", System.User.username, select_module_data.name)
    end
    
    if CreateModulPage.create_project_name then
        project_name = CreateModulPage.create_project_name
        CreateModulPage.create_project_name = nil
    end

    page:SetValue("project_text", project_name)
end