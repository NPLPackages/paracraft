--[[
Title: Paracraft Context
Author(s): big
CreateDate: 2025.4.7
Desc: The ParacraftContext class provides a context for the ParacraftCopilot to interact with the game environment.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Agent/ParacraftContext.lua");
local ParacraftContext = commonlib.gettable("MyCompany.Aries.Game.Agent.ParacraftContext");
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Core/ObjectPath.lua");
local ObjectPath = commonlib.gettable("System.Core.ObjectPath");

local ParacraftContext = commonlib.gettable("MyCompany.Aries.Game.Agent.ParacraftContext");

local mcml1Pages = {};
local mcml2Windows = {};
local vueWindows = {};

-- step: 1
function ParacraftContext:GetAllContext()
    -- EDITABLE GUI / SCENE / USER ACTION / VISION CONTEXT
    -- GUI visiable / button / macro code / tooltip
    -- PLAYER level / vip / hand tool /
    
    -- E button menu /

    --  prompt size 2000 limit
end

function ParacraftContext:SetMcml1Page(id, page)
    if not id then
        return;
    end

    mcml1Pages[id] = page; -- if page is nil, remove the page.
end

function ParacraftContext:SetMcml2Window(id, window)
    if not id or not window or not window:Page() or not window:Page().mcmlNode then
        return;
    end

    mcml2Windows[id] = window; -- if window is nil, remove the page.
end

function ParacraftContext:SetVueWindow(id, window)
    if not id then
        return;
    end

    vueWindows[id] = window; -- if window is nil, remove the page.
end

function ParacraftContext:GetAllObjects()
    local objPath = ObjectPath:new():init("/all");
    return objPath:GetChildPathStrings() or {};
    -- local name = data:GetField("name", "");
    -- local ClassName = data:GetClassName();
end

function ParacraftContext:TraverseGuiElements(path, resultTable)
    resultTable = resultTable or {}
    
    local objPath = ObjectPath:new():init(path)
    local data = objPath:data()
    if data then
        -- Process the current element
        local elementInfo = {
            name = data:GetField("name", ""),
            path = path,
            className = data:GetClassName(),
            id = data:GetField("ID", ""),
        }
        table.insert(resultTable, elementInfo)
    end
    
    -- Get all children
    local children = objPath:GetChildPathStrings() or {}
    for _, childPath in ipairs(children) do
        -- Recursively traverse each child
        self:TraverseGuiElements(childPath, resultTable)
    end

    return resultTable
end

function ParacraftContext:GetGUI()
    local children = self:GetAllObjects();

    local guiPath = "";
    if (children and #children > 0) then
        for _, child in ipairs(children) do
            local childPath = ObjectPath:new():init(child);
            local childData = childPath:data();

            if (childData) then
                local name = childData:GetField("name", "");
                local ClassName = childData:GetClassName();
                if (ClassName == "CGUIRoot") then
                    guiPath = childPath.path;
                    break;
                end
            end
        end
    end

    local guiElements = self:TraverseGuiElements(guiPath) or {};
    
    -- get mcml1 elements.
    local filteredMcml1Elements = {};
    for key, item in pairs(mcml1Pages) do
        local path;
        for _, element in ipairs(guiElements) do
            if (not path) then
                if element.name == key then
                    path = element.path;
                    if (element.className == "CGUIButton") then
                        filteredMcml1Elements[key] = element;
                    end
                end
            else
                -- Check if element.path starts with the found path
                if string.find(element.path, "^" .. path) then
                    local obj = ParaUI.GetUIObject(element.id);
                    -- echo({ text = obj.text, tooltip = obj.tooltip })
                    local text = obj.text or "";
                    local tooltip = obj.tooltip or "";
                    if (text ~= "" or tooltip ~= "") then
                        element.text = text;
                        element.tooltip = tooltip;
                        filteredMcml1Elements[element.id] = element;
                    end
                end
            end
        end
    end

    -- echo(filteredMcml1Elements, true)

    -- get mcml2 elements.
    -- Local function to recursively retrieve all elements from mcmlNode while preserving hierarchy
    local function GetAllElementsFromMcmlNode(node)
        local result = {}
        for _, child in ipairs(node) do
            if type(child) == "table" then
                local childResult = {};
                local className = child.class_name;
                childResult.class_name = child.class_name;

                if (className == "text") then
                    childResult.text = child:GetValue() or "";
                elseif (className == "pe:button") then
                    childResult.text = child.control:GetText() or "";
                elseif (className == "pe:textarea") then
                    childResult.text = child.control:GetText() or "";
                end

                childResult.children = GetAllElementsFromMcmlNode(child) -- Recursively process child elements
                table.insert(result, childResult)
            else
                table.insert(result, child)
            end
        end
        return result
    end

    local filteredMcml2Elements = {};
    for _, element in ipairs(guiElements) do
        for key, window in pairs(mcml2Windows) do
            if (element.name == key) then
                local elements = GetAllElementsFromMcmlNode(window:Page().mcmlNode)
                filteredMcml2Elements[key] = elements;
            end
        end
    end

    -- echo(filteredMcml2Elements, true)

    -- get vue elements.
    local Window = NPL.load("script/ide/System/UI/Window/Window.lua");

    local vueElements = {};
    local function traverseChildren(children)
        if not children or type(children) ~= "table" then
            return
        end

        for i, child in ipairs(children) do
            local curChild = {};
            if type(child) == "table" then
                if (child:GetTagName() == "Blockly") then
                    local stageBlocks = {};
                    for _, block in ipairs(child.blocks) do
                        while (block) do
                            stageBlocks[#stageBlocks + 1] = { text = block:GetText(), type = "Block" };
                            block = block.nextConnection:GetConnectionBlock();
                        end
                    end

                    curChild["stageBlocks"] = stageBlocks;

                    local toolboxCategory = {};
                    local list = child:GetToolBox():GetCategoryList();
                    for _, tool in ipairs(list) do
                        toolboxCategory[#toolboxCategory + 1] = {
                            name = tool.name
                        }
                    end

                    curChild["toolboxCategory"] = toolboxCategory;

                    local toolboxBlocks = {};
                    local allBlocks = child:GetToolBox().blocks;
                    for _, block in ipairs(allBlocks) do
                        toolboxBlocks[#toolboxBlocks + 1] = { text = block:GetText(), type = "Block" };
                    end

                    curChild["toolboxBlocks"] = toolboxBlocks;
                    vueElements[#vueElements + 1] = curChild;
                end

                -- 递归遍历子元素（如果子元素本身也有 children）
                if child.childrens then
                    traverseChildren(child.childrens)
                end
            end
        end
    end

    local filteredVueElements = {};
    for _, element in ipairs(guiElements) do
        for key, window in pairs(vueWindows) do
            if (element.name == key) then
                echo({ "findkey", key })
                local childrens = window.childrens or {};
                -- 获取子元素并遍历
                vueElements = {};
                traverseChildren(childrens);
                filteredVueElements[#filteredVueElements + 1] =  vueElements;
                break;
            end
        end
    end

    echo({ "filteredVueElements", filteredVueElements }, true)

    return guiElements;
end

function ParacraftContext:GetEntities()

end

function ParacraftContext:GetUserAction()

end

function ParacraftContext:GetVisionContext()

end

-- step: 2
function ParacraftContext:RAG()
    -- LOAD TOOL 
end