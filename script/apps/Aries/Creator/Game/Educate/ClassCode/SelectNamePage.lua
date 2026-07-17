--[[
Title: SelectNamePage
Author(s): pbb
Date: 2023/11/18
Desc:  
Use Lib:
-------------------------------------------------------
local SelectNamePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/ClassCode/SelectNamePage.lua")
SelectNamePage.ShowPage()
--]]
local SelectNamePage = NPL.export();
SelectNamePage.code = nil
SelectNamePage.IsSearching = false
local page
function SelectNamePage.OnInit()
    page = document:GetPageCtrl();
    page.OnCreate = SelectNamePage.OnCreate;
end

function SelectNamePage.OnSearchKey(code,search_key,bOpen)
    keepwork.classrooms.students({
        code= code or SelectNamePage.code,
        keyword= search_key or "",
    },function(err,msg,data)
        if err ~= 200  then
            if type(data) == "string" then
                data = commonlib.Json.Decode(data)
            end
            local message = (data and data.message and data.message~="") and data.message or "请输入6位有效班级码"
            GameLogic.AddBBS(nil,message)
            return
        end
        SelectNamePage.server_data = data 
        SelectNamePage.class_data = nil
        SelectNamePage.select_index = 0
        SelectNamePage.select_key_index = 0
        SelectNamePage.HandleData();
        if bOpen then
            SelectNamePage.IsSearching = false
            SelectNamePage.ShowView()
        else
            SelectNamePage.OnRefresh()
            SelectNamePage.ResetTreeView()
        end
    end)
end

function SelectNamePage.ShowView()
    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Educate/ClassCode/SelectNamePage.html",
        name = "SelectNamePage.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = false,
        zorder = 0,
        directPosition = true,
        align = "_fi",
        x = -view_width/2,
        y = -view_height/2,
        width = view_width,
        height = view_height,
        isTopLevel = true,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function SelectNamePage.HidePage(bHide)
    if not page then
        return
    end
    local pageRoot = page:GetRootUIObject();
    if pageRoot and pageRoot:IsValid() then
        if bHide then
            pageRoot.visible = false
        else
            pageRoot.visible = true
        end
    end
end

function SelectNamePage.ShowPage(code)
    SelectNamePage.code = code or ""
    SelectNamePage.IsSearching = false
    SelectNamePage.select_index = 0
    SelectNamePage.select_key_index = 0
    SelectNamePage.OnSearchKey(code,nil,true)
end

function SelectNamePage.OnClickSearch(search_key)
    SelectNamePage.IsSearching = true
    if not SelectNamePage.SearchFunc then
        SelectNamePage.SearchFunc = commonlib.debounce(function(code,search_key)
            SelectNamePage.OnSearchKey(code,search_key)
        end,500)
    end
    SelectNamePage.SearchFunc(SelectNamePage.code,search_key)
end

function SelectNamePage.OnCreate()
    --page:CallMethod("item_gridview", "ScrollToRow", row);
end

function SelectNamePage.OnRefresh()
    if(page)then
        local oldSearchValue =  page:GetValue("SearchName")
        
        local oldPosY
        if page:GetNode("index_gridview") and page:GetNode("index_gridview").control then
            oldPosY = page:GetNode("index_gridview").control.ClientY
        end
        page:Refresh(0);

        if oldPosY then
            page:GetNode("index_gridview").control.ClientY = oldPosY
            page:GetNode("index_gridview").control:Update()
        end
        if oldSearchValue then
            page:SetValue("SearchName",oldSearchValue)
        end
        local searchNode = ParaUI.GetUIObject("SelectNamePage.SearchName")
        if searchNode and searchNode:IsValid() and SelectNamePage.IsSearching then
            searchNode:Focus()
            searchNode:SetCaretPosition(-1);
        end
    end
end

function SelectNamePage.ResetTreeView()
    if page and page:GetNode("index_gridview") and page:GetNode("index_gridview").control then
        page:GetNode("index_gridview").control.ClientY = 0
        page:GetNode("index_gridview").control:Update()
    end
end

function SelectNamePage.CloseView()
    if page then
        page:CloseWindow()
        page = nil
    end
    SelectNamePage.IsSearching = false
end

function SelectNamePage.HandleData()
    if not SelectNamePage.server_data then
        return
    end
    local lineNum = 6
    SelectNamePage.class_data = {}
    SelectNamePage.class_data_keys = {}
    SelectNamePage.class_data.className = SelectNamePage.server_data.className
    SelectNamePage.class_data.orgName = SelectNamePage.server_data.orgName
    local data = SelectNamePage.server_data.data
    if not data or #data == 0 then
        return
    end 
    local num = #data
    for i = 1, num do
        if data[i] and data[i].list and #data[i].list > 0 then
            SelectNamePage.class_data_keys[#SelectNamePage.class_data_keys + 1] = {key=data[i].key}
            local class_data = data[i].list
            local temp = class_data[1]
            local listNum = #class_data
            local placeNum =  lineNum - (listNum % lineNum)
            for j = 1, listNum do
                table.insert(SelectNamePage.class_data, class_data[j])
            end
            for k = 1, placeNum do
                table.insert(SelectNamePage.class_data, {id = -1, placeholder = true , key = temp.key})
            end
        end
    end
end

function SelectNamePage.ScrollToKey(key)
    if not key or key == "" or not SelectNamePage.class_data or #SelectNamePage.class_data == 0 then
        return
    end
    for i = 1, #SelectNamePage.class_data do
        if SelectNamePage.class_data[i].key == key then
            SelectNamePage.ScrollToIndex(i)
            break
        end
    end
end

function SelectNamePage.ScrollToIndex(index)
    if not page or not page:GetNode("index_gridview") then
        return 
    end
    if not SelectNamePage.class_data or not SelectNamePage.class_data[index] then
        return 
    end
    local maxRow = (#SelectNamePage.class_data) / 6 + 1
    local controlTreeview = page:GetNode("index_gridview").control
    if controlTreeview then
        
        local keyIndex = SelectNamePage.GetKeyIndex(index) or 0
        local row = index / 6 + 1
        if row < 0 then
            row = 0
        end
        if row < 3 then
            controlTreeview.ClientY = 0
            controlTreeview:Update()
            return
        end
        if row  + 3 > maxRow then
            controlTreeview.ClientY = controlTreeview.RootNode.LogicalBottom
            controlTreeview:Update()
            return
        end
        local keyHeight = keyIndex * 29
        local nodeHeight = (row - 2) * 57
        controlTreeview.ClientY = keyHeight + nodeHeight
        controlTreeview:Update()
    end
end


function SelectNamePage.GetKeyIndex(index)
    local key = SelectNamePage.class_data[index].key
    for i = 1, #SelectNamePage.class_data_keys do
        if SelectNamePage.class_data_keys[i].key == key then
            return i
        end
    end
end

function SelectNamePage.OnSelectName(index)
    if index and tonumber(index) then
        SelectNamePage.IsSearching = false
        SelectNamePage.select_index = tonumber(index)
        SelectNamePage.OnRefresh() 
    end
end

function SelectNamePage.OnSelectKey(index)
    if index and tonumber(index) then
        SelectNamePage.IsSearching = false
        SelectNamePage.select_key_index = tonumber(index)
        local key = SelectNamePage.class_data_keys[SelectNamePage.select_key_index].key
        SelectNamePage.OnRefresh() 
        SelectNamePage.ScrollToKey(key)
    end
end

function SelectNamePage.OnClickBack()
    SelectNamePage.CloseView()
end

function SelectNamePage.OnClickNext()
    if not SelectNamePage.select_index 
        or not SelectNamePage.class_data 
        or not SelectNamePage.class_data[SelectNamePage.select_index] then
        return
    end
    local classData = SelectNamePage.class_data[SelectNamePage.select_index]
    local className = SelectNamePage.class_data.className 
    local orgName = SelectNamePage.class_data.orgName 
    local data = classData
    data.className = className
    data.orgName = orgName
    data.code = SelectNamePage.code
    SelectNamePage.HidePage(true)
    local ClassCodeLoginLogin = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/ClassCode/ClassCodeLoginLogin.lua")
    ClassCodeLoginLogin.ShowPage(data)
end
