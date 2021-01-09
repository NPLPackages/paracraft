--[[
Title: ComponentFactory 
Author(s): leio
Date: 2021/1/7
Desc: 
use the lib:
------------------------------------------------------------
local ComponentFactory = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/ComponentFactory.lua");
ComponentFactory.registerComponents();
------------------------------------------------------------
--]]
local ComponentFactory = NPL.export();
ComponentFactory.register_components = false;

ComponentFactory.Components = {
    Transform = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/Components/Transform.lua"),
    Script = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/Components/Script.lua"),
    ScriptFromFile = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/Components/ScriptFromFile.lua"),
    MovieClipComponent = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/Components/MovieClipComponent.lua"),
    CodeComponent = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/Components/CodeComponent.lua"),

};
function ComponentFactory.registerComponents()
    if(ComponentFactory.register_components)then
        return
    end
    ComponentFactory.register_components = true;
    for k,v in ipairs(ComponentFactory.Components) do
        ComponentFactory.registerComponent(k,v);
    end
end
function ComponentFactory.registerComponent(name, component)
    if(not name or not component)then
        return 
    end
    ComponentFactory.Components[name] = component;
end
function ComponentFactory.unregisterComponent(name)
    if(not name)then
        return
    end
    ComponentFactory.Components[name] = nil;
end
function ComponentFactory.getComponent(name)
    if(not name)then
        return
    end
    return ComponentFactory.Components[name];
end




